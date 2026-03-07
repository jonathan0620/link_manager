import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/share_helper.dart';
import '../../../../core/widgets/toast_helper.dart';
import '../../../../core/widgets/zoop_logo.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../link/providers/link_form_provider.dart';
import '../../data/models/link_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/links_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0: Home, 1: Add Link, 2: Search, 3: Edit Link
  int _selectedNavIndex = 0;
  String _selectedFilter = 'recent';

  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();

  List<LinkModel> _searchResults = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  // Edit mode state
  LinkModel? _editingLink;
  String _originalUrl = '';
  String _originalTitle = '';
  String? _originalLabel;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startEditingLink(LinkModel link) {
    setState(() {
      _selectedNavIndex = 3; // Edit mode
      _editingLink = link;
      _originalUrl = link.url;
      _originalTitle = link.title;
      _originalLabel = link.label;
      _urlController.text = link.url;
      _titleController.text = link.title;
    });
    ref.read(linkFormProvider.notifier).initWithLink(link);
  }

  bool get _hasChanges {
    if (_editingLink == null) return false;
    final formState = ref.read(linkFormProvider);
    return _urlController.text != _originalUrl ||
        _titleController.text != _originalTitle ||
        formState.label != _originalLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with ZOOP logo
            _buildTopBar(),

            // Main area: Icon sidebar + Panel + Content
            Expanded(
              child: Row(
                children: [
                  // 1. Icon Sidebar (thin, always visible)
                  _buildIconSidebar(),

                  // 2. Sliding Panel (Home/Add Link/Search)
                  _buildSlidingPanel(),

                  // 3. Main Content (always visible - links grid)
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ TOP BAR ============
  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: const ZoopLogo(size: 24),
    );
  }

  // ============ ICON SIDEBAR ============
  Widget _buildIconSidebar() {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          _buildNavIcon(0, Icons.home_rounded),
          _buildNavIcon(1, Icons.link_rounded),
          _buildNavIcon(2, Icons.search_rounded),

          const Spacer(),

          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            color: AppColors.onSurfaceVariant,
            onPressed: _showLogoutDialog,
            tooltip: '로그아웃',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_selectedNavIndex == index) {
              // Toggle off if same button clicked
              _selectedNavIndex = -1;
            } else {
              _selectedNavIndex = index;
              // Reset states when switching
              if (index == 1) {
                ref.read(linkFormProvider.notifier).reset();
                _urlController.clear();
                _titleController.clear();
              } else if (index == 2) {
                _searchController.clear();
                _searchResults = [];
                _hasSearched = false;
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ============ SLIDING PANEL ============
  Widget _buildSlidingPanel() {
    final isOpen = _selectedNavIndex >= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isOpen ? 320 : 0,
      child: isOpen
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.outlineVariant, width: 1),
                ),
              ),
              child: ClipRect(
                child: _buildPanelContent(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPanelContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomePanel();
      case 1:
        return _buildAddLinkPanel();
      case 2:
        return _buildSearchPanel();
      case 3:
        return _buildEditLinkPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  // ============ HOME PANEL ============
  Widget _buildHomePanel() {
    final recentLinksAsync = ref.watch(recentLinksStreamProvider);
    final unreadLinksAsync = ref.watch(unreadLinksStreamProvider);
    final favoriteLinksAsync = ref.watch(favoriteLinksStreamProvider);
    final uniqueLabelsAsync = ref.watch(uniqueLabelsProvider);
    final labelCountsAsync = ref.watch(labelCountsProvider);

    final recentCount = recentLinksAsync.valueOrNull?.length ?? 0;
    final unreadCount = unreadLinksAsync.valueOrNull?.length ?? 0;
    final favoriteCount = favoriteLinksAsync.valueOrNull?.length ?? 0;
    final labelCounts = labelCountsAsync.valueOrNull ?? {};

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedNavIndex = -1),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildFilterButton('recent', '최근에 저장한 링크', recentCount),
                const SizedBox(height: 10),
                _buildFilterButton('unread', '안 읽은 링크', unreadCount),
                const SizedBox(height: 10),
                _buildFavoriteFilterButton(favoriteCount),

                const SizedBox(height: 32),

                const Text(
                  'Label',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                uniqueLabelsAsync.when(
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: labels.map((label) => _buildLabelItem(label, labelCounts[label] ?? 0)).toList(),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),
                Text(
                  '링크에서 라벨을 추가하면\n자동으로 카테고리가 생성됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        } else if (filter == 'unread') {
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
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteFilterButton(int count) {
    final isSelected = _selectedFilter == 'favorite';

    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = 'favorite');
        ref.read(selectedCategoryProvider.notifier).state = '__favorite__';
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 16, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '즐겨찾기 ($count)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelItem(String label, int count) {
    final emoji = _getLabelEmoji(label);
    final isSelected = ref.watch(selectedCategoryProvider) == label;

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
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
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
      '취미': '🎨', '맛집': '🍲', '주식': '📈', '요리': '🍳',
      '여행': '✈️', '게임': '🎮', '디자인': '🎯', '업무': '💼',
      '쇼핑': '🛒', '개발': '💻', '운동': '🏃', '기사': '📰', '영상': '🎬',
    };
    return emojiMap[label] ?? '📁';
  }

  // ============ ADD LINK PANEL ============
  Widget _buildAddLinkPanel() {
    final formState = ref.watch(linkFormProvider);

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedNavIndex = -1),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildLabel('링크 주소', isRequired: true),
                const SizedBox(height: 8),
                _buildUrlField(formState),
                const SizedBox(height: 20),

                if (formState.thumbnailUrl != null && formState.thumbnailUrl!.isNotEmpty)
                  _buildThumbnailPreview(formState.thumbnailUrl!),

                _buildLabel('제목'),
                const SizedBox(height: 8),
                _buildTitleField(),
                const SizedBox(height: 20),

                _buildLabel('라벨링'),
                const SizedBox(height: 12),
                _buildLabelGrid(formState.label),
                const SizedBox(height: 24),

                _buildSaveButton(formState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
      ],
    );
  }

  Widget _buildUrlField(LinkFormState formState) {
    final hasError = formState.error != null && formState.error!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: hasError ? Border.all(color: AppColors.error, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                  decoration: const InputDecoration(
                    hintText: '링크를 입력해 주세요..',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (url) async {
                    await ref.read(linkFormProvider.notifier).updateUrl(url);
                    final state = ref.read(linkFormProvider);
                    if (state.title.isNotEmpty && _titleController.text.isEmpty) {
                      _titleController.text = state.title;
                    }
                  },
                ),
              ),
              if (_urlController.text.isNotEmpty || formState.isFetchingMetadata)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: formState.isFetchingMetadata
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _urlController.clear();
                            _titleController.clear();
                            ref.read(linkFormProvider.notifier).reset();
                          },
                        ),
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(formState.error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnailPreview(String thumbnailUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          thumbnailUrl,
          width: double.infinity,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
        decoration: const InputDecoration(
          hintText: '제목을 입력해 주세요. (미입력 시 자체 링크 제목 입력)',
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 11),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLabelGrid(String? selectedLabel) {
    final labels = [
      ('🍳', '요리'), ('✈️', '여행'), ('🎮', '게임'), ('🎨', '취미'), ('🎯', '디자인'),
      ('💼', '업무'), ('🍲', '맛집'), ('🛒', '쇼핑'), ('💻', '개발'), ('🏃', '운동'),
      ('📰', '기사'), ('📈', '주식'), ('🎬', '영상'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final isSelected = selectedLabel == label.$2;
        return InkWell(
          onTap: () => ref.read(linkFormProvider.notifier).updateLabel(isSelected ? null : label.$2),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            child: Center(child: Text(label.$1, style: const TextStyle(fontSize: 18))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(LinkFormState formState) {
    final isValid = formState.url.isNotEmpty && formState.error == null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: formState.isLoading || !isValid ? null : _handleSaveLink,
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppColors.primary : AppColors.buttonDisabled,
          foregroundColor: isValid ? Colors.white : AppColors.buttonTextDisabled,
          disabledBackgroundColor: AppColors.buttonDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: formState.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('링크 저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _handleSaveLink() async {
    final formState = ref.read(linkFormProvider);
    ref.read(linkFormProvider.notifier).setLoading(true);

    final title = _titleController.text.trim().isEmpty
        ? (formState.title.isEmpty ? '제목 없음' : formState.title)
        : _titleController.text.trim();

    final link = await ref.read(linkActionsProvider.notifier).addLink(
      url: formState.url,
      title: title,
      thumbnailUrl: formState.thumbnailUrl,
      label: formState.label,
    );

    ref.read(linkFormProvider.notifier).setLoading(false);

    if (link != null && mounted) {
      _showSnackBar('링크 ZOOP 완료!');
      setState(() => _selectedNavIndex = 0);
      _urlController.clear();
      _titleController.clear();
      ref.read(linkFormProvider.notifier).reset();
    } else {
      _showSnackBar('오류가 발생했습니다.', isError: true);
    }
  }

  // ============ EDIT LINK PANEL ============
  Widget _buildEditLinkPanel() {
    final formState = ref.watch(linkFormProvider);
    final hasChanges = _editingLink != null &&
        (_urlController.text != _originalUrl ||
            _titleController.text != _originalTitle ||
            formState.label != _originalLabel);

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedNavIndex = 0;
                  _editingLink = null;
                });
                _urlController.clear();
                _titleController.clear();
                ref.read(linkFormProvider.notifier).reset();
              },
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildLabel('링크 주소', isRequired: true),
                const SizedBox(height: 8),
                _buildUrlField(formState),
                const SizedBox(height: 20),

                if (formState.thumbnailUrl != null && formState.thumbnailUrl!.isNotEmpty)
                  _buildThumbnailPreview(formState.thumbnailUrl!),

                _buildLabel('제목'),
                const SizedBox(height: 8),
                _buildTitleField(),
                const SizedBox(height: 20),

                _buildLabel('라벨링'),
                const SizedBox(height: 12),
                _buildLabelGrid(formState.label),
                const SizedBox(height: 32),

                // Delete and Edit buttons
                Row(
                  children: [
                    // Delete button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: formState.isLoading ? null : _handleDeleteLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('링크 삭제', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Edit button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (formState.isLoading || !hasChanges) ? null : _handleUpdateLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasChanges ? AppColors.primary : AppColors.buttonDisabled,
                            foregroundColor: hasChanges ? Colors.white : AppColors.buttonTextDisabled,
                            disabledBackgroundColor: AppColors.buttonDisabled,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: formState.isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('링크 수정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateLink() async {
    if (_editingLink == null) return;

    final formState = ref.read(linkFormProvider);
    ref.read(linkFormProvider.notifier).setLoading(true);

    final title = _titleController.text.trim().isEmpty
        ? (formState.title.isEmpty ? '제목 없음' : formState.title)
        : _titleController.text.trim();

    final success = await ref.read(linkActionsProvider.notifier).updateLink(
      linkId: _editingLink!.id,
      url: formState.url,
      title: title,
      thumbnailUrl: formState.thumbnailUrl,
      label: formState.label,
    );

    ref.read(linkFormProvider.notifier).setLoading(false);

    if (success && mounted) {
      _showSnackBar('ZOOP한 링크 수정 완료!');
      setState(() {
        _selectedNavIndex = 0;
        _editingLink = null;
      });
      _urlController.clear();
      _titleController.clear();
      ref.read(linkFormProvider.notifier).reset();
    } else {
      _showSnackBar('오류가 발생했습니다.', isError: true);
    }
  }

  Future<void> _handleDeleteLink() async {
    if (_editingLink == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크 삭제'),
        content: Text('\'${_editingLink!.title}\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(linkActionsProvider.notifier).deleteLink(_editingLink!.id);

      if (success && mounted) {
        _showSnackBar('ZOOP한 링크 삭제 완료!');
        setState(() {
          _selectedNavIndex = 0;
          _editingLink = null;
        });
        _urlController.clear();
        _titleController.clear();
        ref.read(linkFormProvider.notifier).reset();
      } else {
        _showSnackBar('오류가 발생했습니다.', isError: true);
      }
    }
  }

  // ============ SEARCH PANEL ============
  Widget _buildSearchPanel() {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedNavIndex = -1),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('검색', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
                      decoration: const InputDecoration(
                        hintText: '검색어 입력',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults = [];
                          _hasSearched = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final repository = ref.read(linkRepositoryProvider);
    final results = await repository.searchLinks(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const SizedBox();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('검색 결과가 없어요.', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('키워드를 다시 한 번 확인해 주세요.', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildSearchResultItem(_searchResults[index]),
    );
  }

  Widget _buildSearchResultItem(LinkModel link) {
    return InkWell(
      onTap: () async {
        ref.read(linkActionsProvider.notifier).markAsRead(link.id);
        final uri = Uri.parse(link.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: AppColors.surfaceVariant,
                child: link.thumbnailUrl != null && link.thumbnailUrl!.isNotEmpty
                    ? Image.network(link.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.link, size: 20, color: AppColors.onSurfaceVariant))
                    : const Icon(Icons.link, size: 20, color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(link.url, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ MAIN CONTENT ============
  Widget _buildMainContent() {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final AsyncValue<List<LinkModel>> linksAsync;

    if (selectedCategory == null) {
      linksAsync = ref.watch(recentLinksStreamProvider);
    } else if (selectedCategory == '__unread__') {
      linksAsync = ref.watch(unreadLinksStreamProvider);
    } else if (selectedCategory == '__favorite__') {
      linksAsync = ref.watch(favoriteLinksStreamProvider);
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
            TextButton(onPressed: () => ref.invalidate(linksStreamProvider), child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksGrid(List<LinkModel> links) {
    if (links.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👀 어떤 링크들을 저장하셨나요?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Invalidate providers to refresh data
                ref.invalidate(recentLinksStreamProvider);
                ref.invalidate(unreadLinksStreamProvider);
                ref.invalidate(favoriteLinksStreamProvider);
                ref.invalidate(uniqueLabelsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primary,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                  return GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 8,
                      childAspectRatio: crossAxisCount == 2 ? 1.8 : 2.2,
                    ),
                    itemCount: links.length,
                    itemBuilder: (context, index) => _buildLinkCard(links[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(LinkModel link) {
    final dateStr = _formatDate(link.createdAt);
    final isEditing = _editingLink?.id == link.id;

    return Column(
      children: [
        // Link card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: isEditing ? Border.all(color: AppColors.primary, width: 2) : null,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left content: title, url, date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(link.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(link.url, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(dateStr, style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            if (!link.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('안 읽음', style: TextStyle(fontSize: 10, color: AppColors.primary)),
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
                          ? Image.network(link.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholderImage())
                          : _buildPlaceholderImage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Action buttons below the card
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildCircleActionButton(
                icon: Icons.edit_outlined,
                onTap: () => _startEditingLink(link),
              ),
              const SizedBox(width: 8),
              _buildCircleActionButton(
                icon: Icons.copy_outlined,
                onTap: () async {
                  final success = await ShareHelper.copyToClipboard(link.url);
                  if (success && mounted) _showSnackBar('링크가 복사되었습니다!');
                },
              ),
              const SizedBox(width: 8),
              _buildCircleActionButton(
                icon: link.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                color: link.isFavorite ? AppColors.primary : null,
                onTap: () async {
                  await ref.read(linkActionsProvider.notifier).toggleFavorite(link.id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.image_outlined, color: AppColors.onSurfaceVariant, size: 28),
    );
  }

  Widget _buildEmptyState() {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // 안 읽은 링크 필터일 때
    if (selectedCategory == '__unread__') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('모든 링크를 다 읽었습니다!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    // 즐겨찾기 필터일 때
    if (selectedCategory == '__favorite__') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('즐겨찾기한 링크가 없습니다', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    // 라벨 필터일 때
    if (selectedCategory != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.label_outline, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('\'$selectedCategory\' 라벨의 링크가 없습니다', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          ],
        ),
      );
    }

    // 기본 (최근 저장한 링크)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('저장된 링크가 없습니다\n첫 번째 링크를 추가해 보세요!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedNavIndex = 1),
            icon: const Icon(Icons.add),
            label: const Text('링크 추가'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')} (${weekdays[date.weekday - 1]})';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ToastHelper.showSnackBar(context, message, isError: isError);
  }

  void _showShareBottomSheet(LinkModel link) {
    // 제목이 비어있거나 "제목 없음"이면 URL에서 도메인 추출
    String displayTitle = link.title;
    if (displayTitle.isEmpty || displayTitle == '제목 없음') {
      try {
        final uri = Uri.parse(link.url);
        displayTitle = uri.host;
      } catch (_) {
        displayTitle = link.url;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShareOption(icon: Icons.copy, label: '복사', color: AppColors.primary, onTap: () async {
                    Navigator.of(context).pop();
                    final success = await ShareHelper.copyToClipboard(link.url);
                    if (success && mounted) _showSnackBar('링크가 복사되었습니다.');
                  }),
                  const SizedBox(width: 32),
                  _buildShareOption(icon: Icons.delete_outline, label: '삭제', color: AppColors.error, onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteDialog(link);
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({required IconData icon, required String label, required Color color, Color? iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconColor ?? color, size: 24)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(LinkModel link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크 삭제'),
        content: Text('\'${link.title}\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(linkActionsProvider.notifier).deleteLink(link.id);
              if (mounted) _showSnackBar('ZOOP한 링크 삭제 완료!');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
