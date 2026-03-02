import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/zoop_logo.dart';
import '../../../auth/providers/auth_provider.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  ConsumerState<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState
    extends ConsumerState<CategorySelectionScreen> {
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;

  static const List<_CategoryItem> _categories = [
    _CategoryItem(id: '요리', emoji: '🍳'),
    _CategoryItem(id: '여행', emoji: '✈️'),
    _CategoryItem(id: '게임', emoji: '🎮'),
    _CategoryItem(id: '취미', emoji: '🎨'),
    _CategoryItem(id: '디자인', emoji: '🎯'),
    _CategoryItem(id: '업무', emoji: '💼'),
    _CategoryItem(id: '맛집', emoji: '🍽️'),
    _CategoryItem(id: '쇼핑', emoji: '🛒'),
    _CategoryItem(id: '개발', emoji: '💻'),
    _CategoryItem(id: '운동·스포츠', emoji: '🏃'),
    _CategoryItem(id: '기사·글', emoji: '📰'),
    _CategoryItem(id: '주식', emoji: '📈'),
    _CategoryItem(id: '영상·영화', emoji: '🎬'),
  ];

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);

    if (_selectedCategories.isNotEmpty) {
      await ref.read(authNotifierProvider.notifier).updateSelectedCategories(
            _selectedCategories.toList(),
          );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                children: [
                  // Logo
                  const ZoopLogo(size: 48),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    '어떤 종류의 링크를 저장하시나요?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    '자주 저장하는 링크에 따라 카테고리를 생성해 드려요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Category Chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _categories.map((category) {
                          final isSelected =
                              _selectedCategories.contains(category.id);
                          return _CategoryChip(
                            category: category,
                            isSelected: isSelected,
                            onTap: () => _toggleCategory(category.id),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Complete Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDisabled,
                        foregroundColor: AppColors.buttonTextDisabled,
                        disabledBackgroundColor: AppColors.buttonDisabled,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.buttonTextDisabled,
                              ),
                            )
                          : const Text(
                              '완료',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String id;
  final String emoji;

  const _CategoryItem({
    required this.id,
    required this.emoji,
  });
}

class _CategoryChip extends StatelessWidget {
  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                category.id,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
