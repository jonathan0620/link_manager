import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/toast_helper.dart';
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
    _CategoryItem(
      id: 'technology',
      name: AppStrings.technology,
      icon: Icons.computer,
    ),
    _CategoryItem(
      id: 'design',
      name: AppStrings.design,
      icon: Icons.palette,
    ),
    _CategoryItem(
      id: 'business',
      name: AppStrings.business,
      icon: Icons.business_center,
    ),
    _CategoryItem(
      id: 'lifestyle',
      name: AppStrings.lifestyle,
      icon: Icons.self_improvement,
    ),
    _CategoryItem(
      id: 'entertainment',
      name: AppStrings.entertainment,
      icon: Icons.movie,
    ),
    _CategoryItem(
      id: 'news',
      name: AppStrings.news,
      icon: Icons.newspaper,
    ),
    _CategoryItem(
      id: 'education',
      name: AppStrings.education,
      icon: Icons.school,
    ),
    _CategoryItem(
      id: 'others',
      name: AppStrings.others,
      icon: Icons.more_horiz,
    ),
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
    if (_selectedCategories.isEmpty) {
      ToastHelper.showError('최소 1개 이상의 카테고리를 선택해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(authNotifierProvider.notifier).updateSelectedCategories(
          _selectedCategories.toList(),
        );

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/home');
    }
  }

  void _handleSkip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('관심 카테고리'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: const Text(
              AppStrings.skipOnboarding,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.selectCategories,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '선택한 카테고리를 기반으로 링크를 관리할 수 있습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategories.contains(category.id);

                    return _CategoryCard(
                      category: category,
                      isSelected: isSelected,
                      onTap: () => _toggleCategory(category.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: AppStrings.complete,
                onPressed: _isLoading ? null : _handleComplete,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String id;
  final String name;
  final IconData icon;

  const _CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 32,
                color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
