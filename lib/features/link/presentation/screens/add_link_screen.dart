import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/toast_helper.dart';
import '../../../../core/widgets/zoop_logo.dart';
import '../../../home/providers/links_provider.dart';
import '../../providers/link_form_provider.dart';

class AddLinkScreen extends ConsumerStatefulWidget {
  const AddLinkScreen({super.key});

  @override
  ConsumerState<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends ConsumerState<AddLinkScreen> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(linkFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleUrlChange(String url) async {
    if (url.isNotEmpty) {
      await ref.read(linkFormProvider.notifier).updateUrl(url);
      final formState = ref.read(linkFormProvider);
      if (formState.title.isNotEmpty && _titleController.text.isEmpty) {
        _titleController.text = formState.title;
      }
    }
  }

  Future<void> _handleSave() async {
    final formState = ref.read(linkFormProvider);

    if (formState.url.isEmpty) {
      _showSnackBar('URL을 입력해 주세요.', isError: true);
      return;
    }

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
      context.pop();
    } else {
      _showSnackBar('오류가 발생했습니다.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ToastHelper.showSnackBar(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(linkFormProvider);
    final isValid = formState.url.isNotEmpty && formState.error == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar
            _buildSidebar(),
            // Main Content
            Expanded(
              child: _buildContent(formState, isValid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const ZoopLogo(size: 20),
          const SizedBox(height: 24),
          _buildNavIcon(Icons.home_rounded, false, () => context.go('/home')),
          _buildNavIcon(Icons.link_rounded, true, () {}),
          _buildNavIcon(Icons.search_rounded, false, () => context.push('/search')),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
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

  Widget _buildContent(LinkFormState formState, bool isValid) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // URL Field
                  _buildLabel('링크 주소', isRequired: true),
                  const SizedBox(height: 8),
                  _buildUrlField(formState),
                  const SizedBox(height: 16),

                  // Thumbnail Preview
                  if (formState.thumbnailUrl != null && formState.thumbnailUrl!.isNotEmpty)
                    _buildThumbnailPreview(formState.thumbnailUrl!),

                  // Title Field
                  _buildLabel('제목'),
                  const SizedBox(height: 8),
                  _buildTitleField(),
                  const SizedBox(height: 24),

                  // Label Section
                  _buildLabel('라벨링'),
                  const SizedBox(height: 12),
                  _buildLabelGrid(formState.label),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(formState.isLoading, isValid),
                  const SizedBox(height: 32),
                ],
              ),
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
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
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
            border: hasError
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
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
                  onChanged: _handleUrlChange,
                  onSubmitted: (_) => _handleUrlChange(_urlController.text),
                ),
              ),
              if (_urlController.text.isNotEmpty || formState.isFetchingMetadata)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: formState.isFetchingMetadata
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _urlController.clear();
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
              Text(
                formState.error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnailPreview(String thumbnailUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          thumbnailUrl,
          width: double.infinity,
          height: 200,
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
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLabelGrid(String? selectedLabel) {
    final labels = [
      ('🍳', '요리'),
      ('✈️', '여행'),
      ('🎮', '게임'),
      ('🎨', '취미'),
      ('🎯', '디자인'),
      ('💼', '업무'),
      ('🍽️', '맛집'),
      ('🛒', '쇼핑'),
      ('💻', '개발'),
      ('🏃', '운동'),
      ('📰', '기사'),
      ('📈', '주식'),
      ('🎬', '영상'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final isSelected = selectedLabel == label.$2;
        return InkWell(
          onTap: () {
            ref.read(linkFormProvider.notifier).updateLabel(
              isSelected ? null : label.$2,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(label.$1, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(bool isLoading, bool isValid) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : (isValid ? _handleSave : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? AppColors.primary : AppColors.buttonDisabled,
          foregroundColor: isValid ? Colors.white : AppColors.buttonTextDisabled,
          disabledBackgroundColor: AppColors.buttonDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                '링크 저장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
