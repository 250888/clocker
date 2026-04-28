import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/spacetime_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacetimeProvider = context.watch<SpacetimeProvider>();
    final taskProvider = context.watch<TaskProvider>();

    if (spacetimeProvider.activeSpacetime == null) {
      return _buildNoSpacetime();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务星图'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '待办 (${taskProvider.pendingTasks.length + taskProvider.inProgressTasks.length})'),
            Tab(text: '已完成 (${taskProvider.completedTasks.length})'),
            Tab(text: '逾期 (${taskProvider.overdueTasks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(taskProvider),
          _buildCompletedList(taskProvider),
          _buildOverdueList(taskProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, spacetimeProvider.activeSpacetime!.id),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoSpacetime() {
    return const Center(child: Text('请先创建自律时空'));
  }

  Widget _buildPendingList(TaskProvider taskProvider) {
    final tasks = [...taskProvider.inProgressTasks, ...taskProvider.pendingTasks];
    if (tasks.isEmpty) {
      return _buildEmpty('暂无待办任务', '点击 + 添加新任务');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: tasks
          .map((t) => TaskCard(
                task: t,
                onComplete: () => taskProvider.completeTask(t),
                onTap: () => _showTaskDetail(context, t, taskProvider),
                onDelete: () => _confirmDelete(context, taskProvider, t.id),
              ))
          .toList(),
    );
  }

  Widget _buildCompletedList(TaskProvider taskProvider) {
    if (taskProvider.completedTasks.isEmpty) {
      return _buildEmpty('还没有完成的任务', '完成任务后将在这里显示');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: taskProvider.completedTasks
          .map((t) => TaskCard(
                task: t,
                onTap: () => _showTaskDetail(context, t, taskProvider),
              ))
          .toList(),
    );
  }

  Widget _buildOverdueList(TaskProvider taskProvider) {
    if (taskProvider.overdueTasks.isEmpty) {
      return _buildEmpty('没有逾期任务', '太棒了，继续保持！');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: taskProvider.overdueTasks
          .map((t) => TaskCard(
                task: t,
                onComplete: () => taskProvider.completeTask(t),
                onDelete: () => _confirmDelete(context, taskProvider, t.id),
              ))
          .toList(),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, String spacetimeId) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    double vValueWeight = 1.0;
    TaskPriority priority = TaskPriority.medium;
    List<String> subtasks = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('添加任务'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '任务名称',
                      hintText: '如：完成高数第三章习题',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: '描述（可选）',
                      hintText: '验收标准等',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('v值权重: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: vValueWeight,
                          min: 0.5,
                          max: 4.0,
                          divisions: 7,
                          onChanged: (v) => setDialogState(() => vValueWeight = v),
                        ),
                      ),
                      Text('${vValueWeight.toStringAsFixed(1)}h',
                          style: TextStyle(color: AppColors.accent, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('优先级: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 8),
                      ...TaskPriority.values.map((p) {
                        final isSelected = priority == p;
                        return GestureDetector(
                          onTap: () => setDialogState(() => priority = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.name == 'low'
                                  ? '低'
                                  : p.name == 'medium'
                                      ? '中'
                                      : p.name == 'high'
                                          ? '高'
                                          : '紧急',
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSubtaskInput(subtasks, (list) {
                    setDialogState(() => subtasks = list);
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                context.read<TaskProvider>().createTask(
                      spacetimeId: spacetimeId,
                      title: titleController.text.trim(),
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      vValueWeight: vValueWeight,
                      priority: priority,
                      subtasks: subtasks,
                    );
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskInput(List<String> subtasks, Function(List<String>) onUpdate) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('子任务（蔡格尼克效应拆解）', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        ...subtasks.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12))),
                  IconButton(
                    icon: Icon(Icons.close, size: 14, color: AppColors.textHint),
                    onPressed: () {
                      subtasks.removeAt(e.key);
                      onUpdate(List.from(subtasks));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '添加子任务',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    subtasks.add(value.trim());
                    controller.clear();
                    onUpdate(List.from(subtasks));
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 18, color: AppColors.primary),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  subtasks.add(controller.text.trim());
                  controller.clear();
                  onUpdate(List.from(subtasks));
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showTaskDetail(BuildContext context, Task task, TaskProvider taskProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(task.description!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailChip('v值: ${task.vValueWeight.toStringAsFixed(1)}h', AppColors.accent),
                const SizedBox(width: 8),
                _buildDetailChip(
                  task.priority.name == 'low'
                      ? '低优先级'
                      : task.priority.name == 'medium'
                          ? '中优先级'
                          : task.priority.name == 'high'
                              ? '高优先级'
                              : '紧急',
                  AppColors.danger,
                ),
              ],
            ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('子任务 (${task.completedSubtasks.length}/${task.subtasks.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...task.subtasks.map((s) => CheckboxListTile(
                    value: task.completedSubtasks.contains(s),
                    title: Text(s, style: const TextStyle(fontSize: 13)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (checked) {
                      if (checked == true) {
                        taskProvider.completeSubtask(task, s);
                      }
                    },
                  )),
            ],
            const SizedBox(height: 16),
            if (!task.isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    taskProvider.completeTask(task);
                    Navigator.pop(context);
                  },
                  child: const Text('完成任务'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  void _confirmDelete(BuildContext context, TaskProvider taskProvider, String taskId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('删除任务'),
        content: const Text('确定要删除这个任务吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              taskProvider.deleteTask(taskId);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
