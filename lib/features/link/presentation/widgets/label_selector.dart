import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../home/providers/links_provider.dart';

class LabelSelector extends ConsumerStatefulWidget {
  final String? selectedLabel;
  final ValueChanged<String?> onLabelSelected;

  const LabelSelector({
    super.key,
    this.selectedLabel,
    required this.onLabelSelected,
  });

  @override
  ConsumerState<LabelSelector> createState() => _LabelSelectorState();
}

class _LabelSelectorState extends ConsumerState<LabelSelector> {
  final _newLabelController = TextEditingController();
  bool _isAddingNew = false;

  @override
  void dispose() {
    _newLabelController.dispose();
    super.dispose();
  }

  void _addNewLabel() {
    final newLabel = _newLabelController.text.trim();
    if (newLabel.isNotEmpty) {
      widget.onLabelSelected(newLabel);
      _newLabelController.clear();
      setState(() => _isAddingNew = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelsAsync = ref.watch(uniqueLabelsProvider);

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

        // Existing labels
        labelsAsync.when(
          data: (labels) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // None option
              _LabelChip(
                label: '없음',
                isSelected: widget.selectedLabel == null,
                onTap: () => widget.onLabelSelected(null),
              ),

              // Existing labels
              ...labels.map((label) => _LabelChip(
                    label: label,
                    isSelected: widget.selectedLabel == label,
                    onTap: () => widget.onLabelSelected(label),
                  )),

              // Add new label button
              if (!_isAddingNew)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.addLabel),
                  onPressed: () {
                    setState(() => _isAddingNew = true);
                  },
                ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('라벨을 불러올 수 없습니다'),
        ),

        // New label input
        if (_isAddingNew) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newLabelController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '새 라벨 이름',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _addNewLabel(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check),
                color: AppColors.primary,
                onPressed: _addNewLabel,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.onSurfaceVariant,
                onPressed: () {
                  _newLabelController.clear();
                  setState(() => _isAddingNew = false);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LabelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
      ),
    );
  }
}
