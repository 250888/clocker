import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/spacetime_provider.dart';
import '../providers/task_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/flow_rate_gauge.dart';
import '../widgets/countdown_display.dart';
import '../widgets/task_card.dart';
import '../widgets/achievement_badge.dart';
import 'create_spacetime_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SpacetimeProvider>(
        builder: (context, provider, _) {
          if (provider.activeSpacetime == null) {
            return _buildEmptyState(context);
          }
          return _buildDashboard(context, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🌌',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.slogan,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateSpacetimeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createSpacetime),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, SpacetimeProvider provider) {
    final st = provider.activeSpacetime!;

    return RefreshIndicator(
      onRefresh: () => provider.loadSpacetimes(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (st.emoji != null) ...[
                    Text(st.emoji!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    st.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.cosmicGradient),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateSpacetimeScreen(),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'switch') {
                    _showSpacetimeSwitcher(context, provider);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider, st.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'switch', child: Text('切换时空')),
                  const PopupMenuItem(value: 'delete', child: Text('删除时空')),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlowRateGauge(
                    flowRate: st.currentFlowRate,
                    v0: st.v0,
                    vValue: st.currentV,
                    c: st.c,
                    disciplinePercentage: st.disciplinePercentage,
                    isInFlowState: st.isInFlowState,
                  ),
                  const SizedBox(height: 16),
                  CountdownDisplay(
                    appDaysRemaining: st.appDaysRemaining,
                    realDaysRemaining: st.realDaysRemaining,
                    flowRate: st.currentFlowRate,
                    timeEarned: st.timeEarned,
                    timeLost: 0,
                  ),
                  const SizedBox(height: 24),
                  _buildLossWarning(context, st),
                  const SizedBox(height: 16),
                  _buildMiniTasks(context),
                  const SizedBox(height: 16),
                  _buildRecentAchievements(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLossWarning(BuildContext context, dynamic st) {
    if (st.currentFlowRate <= 1.0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_down, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.keepGoing,
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.dontSlack,
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMiniTasks(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final miniTasks = taskProvider.getMiniTasks();
        if (miniTasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日待办',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(2);
                  },
                  child: Text('查看全部', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...miniTasks.map((task) => TaskCard(
                  task: task,
                  onComplete: () => taskProvider.completeTask(task),
                )),
          ],
        );
      },
    );
  }

  Widget _buildRecentAchievements(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, _) {
        final recent = achievementProvider.unlockedAchievements.take(4).toList();
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近成就',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    SizedBox(width: 100, child: AchievementBadge(achievement: recent[i])),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷操作',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildActionChip(
              context,
              Icons.ac_unit,
              '时空冻结',
              AppColors.info,
              () {
                context.read<SpacetimeProvider>().useTimeFreeze();
              },
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              context,
              Icons.history,
              '时间回溯',
              AppColors.cosmic4,
              () {
                context.read<SpacetimeProvider>().useTimeRewind();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpacetimeSwitcher(BuildContext context, SpacetimeProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: provider.spacetimes
            .map((st) => ListTile(
                  leading: Text(st.emoji ?? '🌌', style: const TextStyle(fontSize: 24)),
                  title: Text(st.name),
                  subtitle: Text('剩余${st.realDaysRemaining}天'),
                  trailing: st.id == provider.activeSpacetime?.id
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                  onTap: () {
                    provider.setActiveSpacetime(st);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SpacetimeProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这个时空吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSpacetime(id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
