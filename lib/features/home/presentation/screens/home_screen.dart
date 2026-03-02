import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/zoop_logo.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/link_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/links_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0;
  String _selectedFilter = 'recent'; // 'recent' or 'unread'

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar
            _buildSidebar(isWideScreen),

            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isWideScreen) {
    final recentLinksAsync = ref.watch(recentLinksStreamProvider);
    final unreadLinksAsync = ref.watch(unreadLinksStreamProvider);
    final uniqueLabelsAsync = ref.watch(uniqueLabelsProvider);

    final recentCount = recentLinksAsync.valueOrNull?.length ?? 0;
    final unreadCount = unreadLinksAsync.valueOrNull?.length ?? 0;

    return Container(
      width: isWideScreen ? 280 : 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const ZoopLogo(size: 24),
                const Spacer(),
                // Logout button
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  color: AppColors.onSurfaceVariant,
                  onPressed: _showLogoutDialog,
                  tooltip: '로그아웃',
                ),
              ],
            ),
          ),

          // Navigation Icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildNavIcon(0, Icons.home_rounded, '홈'),
                _buildNavIcon(1, Icons.link_rounded, '링크 추가'),
                _buildNavIcon(2, Icons.search_rounded, '검색'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildFilterButton(
                  'recent',
                  '최근에 저장한 링크',
                  recentCount,
                ),
                const SizedBox(height: 8),
                _buildFilterButton(
                  'unread',
                  '안 읽은 링크',
                  unreadCount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Labels Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Label',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: uniqueLabelsAsync.when(
                      data: (labels) {
                        if (labels.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelItem('취미', 0),
                              _buildLabelItem('맛집', 0),
                              _buildLabelItem('주식', 0),
                            ],
                          );
                        }
                        return ListView.builder(
                          itemCount: labels.length,
                          itemBuilder: (context, index) {
                            return _buildLabelItem(labels[index], 0);
                          },
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '링크에서 라벨을 추가하면 자동으로 카테고리가 생성됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String tooltip) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          if (index == 1) {
            context.push('/add-link');
          } else if (index == 2) {
            context.push('/search');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filter);
        if (filter == 'recent') {
          ref.read(selectedCategoryProvider.notifier).state = null;
        } else {
          ref.read(selectedCategoryProvider.notifier).state = '__unread__';
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLabelItem(String label, int count) {
    final emoji = _getLabelEmoji(label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = label;
          setState(() => _selectedFilter = '');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$label ($count)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLabelEmoji(String label) {
    final emojiMap = {
      '취미': '🎨',
      '맛집': '🍽️',
      '주식': '📈',
      '요리': '🍳',
      '여행': '✈️',
      '게임': '🎮',
      '디자인': '🎯',
      '업무': '💼',
      '쇼핑': '🛒',
      '개발': '💻',
      '운동': '🏃',
      '스포츠': '⚽',
      '기사': '📰',
      '영상': '🎬',
      '영화': '🎬',
    };
    return emojiMap[label] ?? '📁';
  }

  Widget _buildMainContent() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final AsyncValue<List<LinkModel>> linksAsync;

    if (selectedCategory == null) {
      linksAsync = ref.watch(recentLinksStreamProvider);
    } else if (selectedCategory == '__unread__') {
      linksAsync = ref.watch(unreadLinksStreamProvider);
    } else {
      linksAsync = ref.watch(linksByLabelStreamProvider(selectedCategory));
    }

    return linksAsync.when(
      data: (links) => _buildLinksGrid(links),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('오류가 발생했습니다'),
            TextButton(
              onPressed: () => ref.invalidate(linksStreamProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksGrid(List<LinkModel> links) {
    final headerText = links.isEmpty
        ? '👋 링크가 기다리고 있어요.'
        : '👀 어떤 링크들을 저장하셨나요?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            headerText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),

        // Links Grid
        Expanded(
          child: links.isEmpty
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossAxisCount == 2 ? 2.2 : 2.8,
                        ),
                        itemCount: links.length,
                        itemBuilder: (context, index) {
                          return _buildLinkCard(links[index]);
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLinkCard(LinkModel link) {
    final dateStr = _formatDate(link.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          ref.read(linkActionsProvider.notifier).markAsRead(link.id);
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.url,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (!link.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '안 읽음',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: link.thumbnailUrl != null && link.thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          link.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => context.push('/edit-link/${link.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_outline, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {
                      // TODO: Bookmark functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 링크가 없습니다\n첫 번째 링크를 추가해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-link'),
            icon: const Icon(Icons.add),
            label: const Text('링크 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')} ($weekday)';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
