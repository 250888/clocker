import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/engine/lorentz_engine.dart';
import '../providers/spacetime_provider.dart';

class CreateSpacetimeScreen extends StatefulWidget {
  const CreateSpacetimeScreen({super.key});

  @override
  State<CreateSpacetimeScreen> createState() => _CreateSpacetimeScreenState();
}

class _CreateSpacetimeScreenState extends State<CreateSpacetimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  double _v0 = 2.0;
  double _c = 8.0;
  int _advanceDays = 14;
  FlowMode _flowMode = FlowMode.relativistic;
  String _selectedEmoji = '🌌';

  final List<String> _emojis = ['🌌', '📚', '🎓', '💼', '🏋️', '🎨', '🎵', '💻', '🔬', '📝'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createSpacetime),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEmojiSelector(),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 20),
            _buildDeadlinePicker(),
            const SizedBox(height: 20),
            _buildV0Slider(),
            const SizedBox(height: 20),
            _buildCSlider(),
            const SizedBox(height: 20),
            _buildAdvanceDaysSlider(),
            const SizedBox(height: 20),
            _buildFlowModeSelector(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildCreateButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择图标', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojis.map((emoji) {
            final isSelected = emoji == _selectedEmoji;
            return GestureDetector(
              onTap: () => setState(() => _selectedEmoji = emoji),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '时空名称',
        hintText: '如：考研冲刺、期末复习、项目交付',
        prefixIcon: Icon(Icons.label),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入时空名称';
        }
        return null;
      },
    );
  }

  Widget _buildDeadlinePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _deadline,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (_, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _deadline = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: AppStrings.deadlineLabel,
          prefixIcon: Icon(Icons.event),
        ),
        child: Text(
          '${_deadline.year}年${_deadline.month}月${_deadline.day}日',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildV0Slider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.baseFlowRate, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_v0.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '完全摆烂时的流速倍率，越高惩罚越重',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: _v0,
          min: 1.0,
          max: 5.0,
          divisions: 8,
          onChanged: (v) => setState(() => _v0 = v),
        ),
      ],
    );
  }

  Widget _buildCSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.disciplineLimit, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_c.toStringAsFixed(0)}h',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '单日有效专注上限（光速不可超越）',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: _c,
          min: 2.0,
          max: 16.0,
          divisions: 14,
          onChanged: (v) => setState(() => _c = v),
        ),
      ],
    );
  }

  Widget _buildAdvanceDaysSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.advanceDays, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_advanceDays天',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _advanceDays.toDouble(),
          min: 0,
          max: 60,
          divisions: 12,
          onChanged: (v) => setState(() => _advanceDays = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildFlowModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.flowMode, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildModeChip('相对论标准', FlowMode.relativistic),
            const SizedBox(width: 8),
            _buildModeChip('线性模式', FlowMode.linear),
            const SizedBox(width: 8),
            _buildModeChip('指数模式', FlowMode.exponential),
          ],
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, FlowMode mode) {
    final isSelected = _flowMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _flowMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppColors.primary) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textHint,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final engine = LorentzEngine(v0: _v0, c: _c, flowMode: _flowMode);
    final daysRemaining = _deadline.difference(DateTime.now()).inDays;
    final fullSlack = engine.calculateFlowRate(0);
    final halfEffort = engine.calculateFlowRate(_c * 0.5);
    final fullEffort = engine.calculateFlowRate(_c * 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                '效果预览',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow('完全摆烂', '${fullSlack.toStringAsFixed(2)}x', AppColors.danger),
          _buildPreviewRow('50%自律', '${halfEffort.toStringAsFixed(2)}x', AppColors.warning),
          _buildPreviewRow('90%自律', '${fullEffort.toStringAsFixed(2)}x', AppColors.success),
          const Divider(color: AppColors.surfaceLight, height: 20),
          _buildPreviewRow(
            '摆烂时APP剩余',
            '${(daysRemaining * fullSlack).toStringAsFixed(0)}天',
            AppColors.danger,
          ),
          _buildPreviewRow(
            '90%自律APP剩余',
            '${(daysRemaining * fullEffort).toStringAsFixed(0)}天',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _createSpacetime,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('生成自律时空', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _createSpacetime() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SpacetimeProvider>();
    await provider.createSpacetime(
      name: _nameController.text.trim(),
      deadline: _deadline,
      v0: _v0,
      c: _c,
      flowMode: _flowMode,
      advanceDays: _advanceDays,
      emoji: _selectedEmoji,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('自律时空「${_nameController.text}」已创建！'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
