import 'package:flutter/material.dart';

/// 时空图标映射：emoji 只作**持久化标识**（数据库里存的就是它），
/// 展示时统一走 Material 线性图标，保证与整体「仪器风」一致。
///
/// 创建时空页的选择器与仪表盘的左上角都用这里，避免两处各写一套。
class AppIcons {
  static const Map<String, IconData> byEmoji = {
    '🌌': Icons.auto_awesome_outlined,
    '📚': Icons.menu_book_outlined,
    '🎓': Icons.school_outlined,
    '💼': Icons.work_outline,
    '🏋️': Icons.fitness_center_outlined,
    '🎨': Icons.palette_outlined,
    '🎵': Icons.music_note_outlined,
    '💻': Icons.laptop_mac_outlined,
    '🔬': Icons.science_outlined,
    '📝': Icons.edit_note_outlined,
  };

  /// 未知 emoji 回退到「星芒」，绝不显示彩色 emoji。
  static IconData of(String? emoji) => byEmoji[emoji] ?? Icons.auto_awesome_outlined;
}
