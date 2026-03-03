import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_helper.dart';
import '../../providers/auth_provider.dart';

class FindPasswordScreen extends ConsumerStatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  ConsumerState<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends ConsumerState<FindPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  ValidationResult? _emailValidation;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValidation = Validators.validateEmail(value);
    });
  }

  Future<void> _handleSendResetLink() async {
    if (_emailValidation?.isValid != true) {
      ToastHelper.showError(AppStrings.emailInvalid);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(
            _emailController.text.trim(),
          );

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      ToastHelper.showSuccess('비밀번호 재설정 링크가 발송되었습니다.');
    } catch (e) {
      setState(() => _isLoading = false);

      // Handle specific Firebase errors
      String errorMessage = '이메일 발송에 실패했습니다.';
      if (e.toString().contains('user-not-found')) {
        errorMessage = '등록되지 않은 이메일입니다.';
      }
      ToastHelper.showError(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.findPassword),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _emailSent ? _buildSuccessStep() : _buildEmailStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.lock_reset,
          size: 64,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        const Text(
          '비밀번호를 잊으셨나요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '가입 시 등록한 이메일을 입력하시면\n비밀번호 재설정 링크를 보내드립니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: AppStrings.email,
          hint: 'example@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.email_outlined),
          onChanged: _validateEmail,
          isValid: _emailValidation?.isValid == true,
          errorText:
              _emailValidation?.isValid == false ? _emailValidation!.message : null,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: '재설정 링크 보내기',
          onPressed:
              _emailValidation?.isValid == true && !_isLoading ? _handleSendResetLink : null,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: '로그인으로 돌아가기',
          type: ButtonType.text,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        const Text(
          '이메일을 확인해 주세요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_emailController.text}로\n비밀번호 재설정 링크를 보냈습니다.\n\n이메일의 링크를 클릭하여\n새 비밀번호를 설정해 주세요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: '로그인으로 돌아가기',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: '이메일 다시 보내기',
          type: ButtonType.secondary,
          onPressed: _isLoading ? null : _handleSendResetLink,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
