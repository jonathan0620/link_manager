import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class LabelSelector extends StatelessWidget {
  final String? selectedLabel;
  final ValueChanged<String?> onLabelSelected;

  const LabelSelector({
    super.key,
    this.selectedLabel,
    required this.onLabelSelected,
  });

  static const List<(String, String)> predefinedLabels = [
    ('🍳', '요리'),
    ('✈️', '여행'),
    ('🎮', '게임'),
    ('🎨', '취미'),
    ('🎯', '디자인'),
    ('💼', '업무'),
    ('🍲', '맛집'),
    ('🛒', '쇼핑'),
    ('💻', '개발'),
    ('🏃', '운동'),
    ('📰', '기사'),
    ('📈', '주식'),
    ('🎬', '영상'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.selectLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // None option
            _LabelChip(
              emoji: '✕',
              label: '없음',
              isSelected: selectedLabel == null,
              onTap: () => onLabelSelected(null),
            ),

            // Predefined labels
            ...predefinedLabels.map((label) => _LabelChip(
                  emoji: label.$1,
                  label: label.$2,
                  isSelected: selectedLabel == label.$2,
                  onTap: () => onLabelSelected(
                    selectedLabel == label.$2 ? null : label.$2,
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelChip({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
