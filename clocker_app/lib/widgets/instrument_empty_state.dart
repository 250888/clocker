import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'dawn_backdrop.dart';

/// 统一空状态：发丝线 + 标题 + 一行说明 + 可选单主按钮。
///
/// 刻意不放 emoji/大图标：空状态的作用是「指出下一步」，不是装饰。
class InstrumentEmptyState extends StatelessWidget {
  const InstrumentEmptyState({
    super.key,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 1, color: AppColors.hairline),
            const SizedBox(height: 26),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 带「晨昏线」背景与标题栏的空状态整页。
///
/// 用于专注 / 任务 / 报告等尚未创建时空时的页面，保证与首页同一视觉。
class DawnEmptyPage extends StatelessWidget {
  const DawnEmptyPage({
    super.key,
    required this.appBarTitle,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String appBarTitle;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DawnBackdrop(showTrails: false)),
          InstrumentEmptyState(
            title: title,
            hint: hint,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ],
      ),
    );
  }
}
