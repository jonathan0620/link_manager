import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_helper.dart';
import '../../../home/providers/links_provider.dart';
import '../../providers/link_form_provider.dart';
import '../widgets/label_selector.dart';
import '../widgets/link_preview.dart';

class EditLinkScreen extends ConsumerStatefulWidget {
  final String linkId;

  const EditLinkScreen({
    super.key,
    required this.linkId,
  });

  @override
  ConsumerState<EditLinkScreen> createState() => _EditLinkScreenState();
}

class _EditLinkScreenState extends ConsumerState<EditLinkScreen> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    if (_isInitialized) return;

    final linkAsync = await ref.read(linkProvider(widget.linkId).future);
    if (linkAsync != null) {
      ref.read(linkFormProvider.notifier).initWithLink(linkAsync);
      _urlController.text = linkAsync.url;
      _titleController.text = linkAsync.title;
      _isInitialized = true;
    }
  }

  Future<void> _handleSave() async {
    final formState = ref.read(linkFormProvider);

    if (formState.url.isEmpty) {
      ToastHelper.showError('URL을 입력해 주세요.');
      return;
    }

    ref.read(linkFormProvider.notifier).setLoading(true);

    final title = _titleController.text.trim().isEmpty
        ? '제목 없음'
        : _titleController.text.trim();

    final success = await ref.read(linkActionsProvider.notifier).updateLink(
          linkId: widget.linkId,
          url: formState.url,
          title: title,
          thumbnailUrl: formState.thumbnailUrl,
          label: formState.label,
        );

    ref.read(linkFormProvider.notifier).setLoading(false);

    if (success && mounted) {
      ToastHelper.showSuccess(AppStrings.linkUpdated);
      context.pop();
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('링크 삭제'),
        content: const Text('이 링크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(linkActionsProvider.notifier).deleteLink(widget.linkId);

      if (success && mounted) {
        ToastHelper.showSuccess(AppStrings.linkDeleted);
        context.pop();
      } else {
        ToastHelper.showError(AppStrings.errorGeneric);
      }
    }
  }

  Future<void> _handleUrlSubmit() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ref.read(linkFormProvider.notifier).updateUrl(url);
      // Update title controller with fetched title if empty
      final formState = ref.read(linkFormProvider);
      if (formState.title.isNotEmpty && _titleController.text.isEmpty) {
        _titleController.text = formState.title;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkAsync = ref.watch(linkProvider(widget.linkId));

    return linkAsync.when(
      data: (link) {
        if (link == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.editLink)),
            body: const Center(child: Text('링크를 찾을 수 없습니다')),
          );
        }

        // Initialize form with link data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeForm();
        });

        return _buildEditForm();
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editLink)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editLink)),
        body: Center(child: Text('오류: $error')),
      ),
    );
  }

  Widget _buildEditForm() {
    final formState = ref.watch(linkFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editLink),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL input
            CustomTextField(
              label: 'URL',
              hint: AppStrings.urlPlaceholder,
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.link),
              onSubmitted: (_) => _handleUrlSubmit(),
              onChanged: (value) {
                ref.read(linkFormProvider.notifier).updateUrl(value);
              },
            ),
            const SizedBox(height: 8),

            // Fetch metadata button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    formState.isFetchingMetadata ? null : _handleUrlSubmit,
                icon: formState.isFetchingMetadata
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('미리보기 새로고침'),
              ),
            ),
            const SizedBox(height: 16),

            // Link preview
            if (formState.url.isNotEmpty)
              LinkPreview(
                thumbnailUrl: formState.thumbnailUrl,
                title: _titleController.text.isEmpty
                    ? formState.title
                    : _titleController.text,
                url: formState.url,
                isLoading: formState.isFetchingMetadata,
              ),
            const SizedBox(height: 24),

            // Title input
            CustomTextField(
              label: '제목',
              hint: AppStrings.titlePlaceholder,
              controller: _titleController,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.title),
            ),
            const SizedBox(height: 24),

            // Label selector
            LabelSelector(
              selectedLabel: formState.label,
              onLabelSelected: (label) {
                ref.read(linkFormProvider.notifier).updateLabel(label);
              },
            ),
            const SizedBox(height: 32),

            // Save button
            CustomButton(
              text: AppStrings.save,
              onPressed: formState.isLoading ? null : _handleSave,
              isLoading: formState.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
