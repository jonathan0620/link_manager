import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/link_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/links_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/category_list.dart';
import '../widgets/link_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/add-link');
        break;
      case 2:
        context.push('/search');
        break;
    }
  }

  void _onCategorySelected(String? category) {
    // Trigger rebuild with new category filter
    ref.read(selectedCategoryProvider.notifier).state = category;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter list
          CategoryList(onCategorySelected: _onCategorySelected),

          // Links list
          Expanded(
            child: _buildLinksList(selectedCategory),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildLinksList(String? selectedCategory) {
    final AsyncValue<List<LinkModel>> linksAsync;

    if (selectedCategory == null) {
      linksAsync = ref.watch(recentLinksStreamProvider);
    } else if (selectedCategory == '__unread__') {
      linksAsync = ref.watch(unreadLinksStreamProvider);
    } else {
      linksAsync = ref.watch(linksByLabelStreamProvider(selectedCategory));
    }

    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return _buildEmptyState(selectedCategory);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(linksStreamProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return LinkCard(
                link: link,
                onTap: () {
                  // Mark as read when tapped
                  ref.read(linkActionsProvider.notifier).markAsRead(link.id);
                },
                onEdit: () {
                  context.push('/edit-link/${link.id}');
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(linksStreamProvider);
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? selectedCategory) {
    String message;
    IconData icon;

    if (selectedCategory == '__unread__') {
      message = '읽지 않은 링크가 없습니다';
      icon = Icons.check_circle_outline;
    } else if (selectedCategory != null) {
      message = '이 카테고리에 링크가 없습니다';
      icon = Icons.folder_open;
    } else {
      message = '저장된 링크가 없습니다\n첫 번째 링크를 추가해 보세요!';
      icon = Icons.link_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (selectedCategory == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/add-link'),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
