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

class AddLinkScreen extends ConsumerStatefulWidget {
  const AddLinkScreen({super.key});

  @override
  ConsumerState<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends ConsumerState<AddLinkScreen> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Reset form on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(linkFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleUrlSubmit() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ref.read(linkFormProvider.notifier).updateUrl(url);
      // Update title controller with fetched title
      final formState = ref.read(linkFormProvider);
      if (formState.title.isNotEmpty && _titleController.text.isEmpty) {
        _titleController.text = formState.title;
      }
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
      ToastHelper.showSuccess(AppStrings.linkSaved);
      context.pop();
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(linkFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.addLink),
        backgroundColor: AppColors.background,
        elevation: 0,
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
              focusNode: _urlFocusNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.link),
              onSubmitted: (_) => _handleUrlSubmit(),
              onChanged: (value) {
                // Debounced URL fetch could be added here
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
                label: const Text('미리보기 가져오기'),
              ),
            ),
            const SizedBox(height: 16),

            // Link preview
            if (formState.url.isNotEmpty)
              LinkPreview(
                thumbnailUrl: formState.thumbnailUrl,
                title:
                    _titleController.text.isEmpty ? formState.title : _titleController.text,
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
              helperText: formState.title.isNotEmpty
                  ? '자동 추출: ${formState.title}'
                  : null,
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
