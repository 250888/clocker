import 'package:uuid/uuid.dart';

enum AchievementTier { restFrame, sublight, lightSpeed, tachyon }
enum AchievementCategory { focus, task, streak, special }

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementTier tier;
  final AchievementCategory category;
  final String icon;
  final double requiredValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? reward;

  Achievement({
    String? id,
    required this.name,
    required this.description,
    required this.tier,
    required this.category,
    this.icon = '⭐',
    this.requiredValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.reward,
  }) : id = id ?? const Uuid().v4();

  String get tierName {
    switch (tier) {
      case AchievementTier.restFrame:
        return '静止参考系';
      case AchievementTier.sublight:
        return '亚光速飞行';
      case AchievementTier.lightSpeed:
        return '光速极限';
      case AchievementTier.tachyon:
        return '超光速粒子';
    }
  }

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      tier: tier,
      category: category,
      icon: icon,
      requiredValue: requiredValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      reward: reward,
    );
  }

  static List<Achievement> defaultAchievements() {
    return [
      Achievement(
        name: '初入时空',
        description: '完成第一次专注',
        tier: AchievementTier.restFrame,
        category: AchievementCategory.focus,
        icon: '🌌',
        requiredValue: 1,
        reward: '解锁基础主题',
      ),
      Achievement(
        name: '时间旅行者',
        description: '累计专注10小时',
        tier: AchievementTier.restFrame,
        category: AchievementCategory.focus,
        icon: '⏳',
        requiredValue: 10,
        reward: '解锁星空主题',
      ),
      Achievement(
        name: '亚光速巡航',
        description: '单日自律速度达到c的50%',
        tier: AchievementTier.sublight,
        category: AchievementCategory.focus,
        icon: '🚀',
        requiredValue: 0.5,
        reward: '解锁自定义流速权重',
      ),
      Achievement(
        name: '心流探索者',
        description: '首次进入心流状态',
        tier: AchievementTier.sublight,
        category: AchievementCategory.special,
        icon: '🧘',
        requiredValue: 1,
        reward: '解锁心流主题音效',
      ),
      Achievement(
        name: '任务终结者',
        description: '完成10个任务',
        tier: AchievementTier.restFrame,
        category: AchievementCategory.task,
        icon: '✅',
        requiredValue: 10,
        reward: '解锁任务统计面板',
      ),
      Achievement(
        name: '连续7天',
        description: '连续7天保持自律',
        tier: AchievementTier.sublight,
        category: AchievementCategory.streak,
        icon: '🔥',
        requiredValue: 7,
        reward: '解锁时空冻结+1',
      ),
      Achievement(
        name: '光速突破',
        description: '单日自律速度达到c的90%',
        tier: AchievementTier.lightSpeed,
        category: AchievementCategory.focus,
        icon: '⚡',
        requiredValue: 0.9,
        reward: '解锁光速主题',
      ),
      Achievement(
        name: '时空大师',
        description: '累计赚取30天APP时间',
        tier: AchievementTier.lightSpeed,
        category: AchievementCategory.special,
        icon: '👑',
        requiredValue: 30,
        reward: '解锁全部自定义规则',
      ),
      Achievement(
        name: '连续30天',
        description: '连续30天保持自律',
        tier: AchievementTier.lightSpeed,
        category: AchievementCategory.streak,
        icon: '💫',
        requiredValue: 30,
        reward: '解锁传说主题',
      ),
      Achievement(
        name: '超光速粒子',
        description: '完成所有其他成就',
        tier: AchievementTier.tachyon,
        category: AchievementCategory.special,
        icon: '🌟',
        requiredValue: 9,
        reward: '终极称号：时空之主',
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tier': tier.index,
      'category': category.index,
      'icon': icon,
      'requiredValue': requiredValue,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'reward': reward,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      tier: AchievementTier.values[map['tier']],
      category: AchievementCategory.values[map['category']],
      icon: map['icon'],
      requiredValue: map['requiredValue'],
      isUnlocked: map['isUnlocked'] == 1,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
      reward: map['reward'],
    );
  }
}
