import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/task.dart';

/// 任务行（仪器风）：勾选圈 + 优先级点 + 标题 + 等宽元信息 + 删除。
///
/// 用 1px 发丝线分隔，不用卡片堆叠——列表页保持密度与秩序。
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.danger;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.info;
      case TaskPriority.low:
        return AppColors.textHint;
    }
  }

  String get _priorityLabel {
    switch (task.priority) {
      case TaskPriority.urgent:
        return '紧急';
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }

  String get _meta {
    final parts = <String>['v ${task.vValueWeight.toStringAsFixed(1)}h'];
    if (task.subtasks.isNotEmpty) {
      parts.add('${task.completedSubtasks.length}/${task.subtasks.length} 子任务');
    }
    if (task.dueDate != null) {
      final due = task.dueDate!;
      parts.add('${due.month}/${due.day} 截止');
    }
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.hairline, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onComplete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: completed
                          ? AppColors.primary
                          : AppColors.hairlineStrong,
                      width: 1.2,
                    ),
                  ),
                  child: completed
                      ? const Icon(
                          Icons.check,
                          size: 13,
                          color: Color(0xFF0E0F12),
                        )
                      : null,
                ),
              ),
            ),
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: completed ? AppColors.hairlineStrong : _priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: completed
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.3,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _meta,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      letterSpacing: 0.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (task.isOverdue && !completed)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '逾期',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _priorityLabel,
                  style: TextStyle(
                    color: completed ? AppColors.textHint : _priorityColor,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
