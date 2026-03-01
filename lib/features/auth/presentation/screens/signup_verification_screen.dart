import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_helper.dart';
import '../../providers/auth_provider.dart';

class SignupVerificationScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;
  final String password;

  const SignupVerificationScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<SignupVerificationScreen> createState() =>
      _SignupVerificationScreenState();
}

class _SignupVerificationScreenState
    extends ConsumerState<SignupVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ToastHelper.showError('6자리 인증번호를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    // Verify code
    final isCodeValid = await ref.read(authNotifierProvider.notifier).verifyCode(
          email: widget.email,
          code: code,
        );

    if (!isCodeValid) {
      setState(() => _isLoading = false);
      ToastHelper.showError(AppStrings.verificationCodeInvalid);
      return;
    }

    // Create account
    final success = await ref.read(authNotifierProvider.notifier).signUp(
          username: widget.username,
          email: widget.email,
          password: widget.password,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ToastHelper.showSuccess('회원가입이 완료되었습니다.');
      context.go('/onboarding');
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
    }
  }

  Future<void> _handleResendCode() async {
    setState(() => _isResending = true);

    final success = await ref.read(authNotifierProvider.notifier).sendVerificationCode(
          email: widget.email,
          purpose: 'signup',
        );

    setState(() => _isResending = false);

    if (success) {
      ToastHelper.showSuccess(AppStrings.verificationCodeSent);
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('이메일 인증'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${widget.email}로\n인증번호가 발송되었습니다.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이메일을 확인하고 6자리 인증번호를 입력해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verification code field
                  CustomTextField(
                    label: AppStrings.verificationCode,
                    hint: '6자리 인증번호',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    prefixIcon: const Icon(Icons.pin_outlined),
                    onSubmitted: (_) => _handleVerify(),
                  ),
                  const SizedBox(height: 24),

                  // Verify button
                  CustomButton(
                    text: AppStrings.verify,
                    onPressed: _isLoading ? null : _handleVerify,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Resend code button
                  CustomButton(
                    text: '인증번호 재발송',
                    type: ButtonType.text,
                    onPressed: _isResending ? null : _handleResendCode,
                    isLoading: _isResending,
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
