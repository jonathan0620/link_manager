import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0; // 0: email, 1: verify, 2: new password, 3: complete
  ValidationResult? _emailValidation;
  ValidationResult? _passwordValidation;
  ValidationResult? _confirmPasswordValidation;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValidation = Validators.validateEmail(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordValidation = Validators.validatePassword(value);
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordValidation = Validators.validatePasswordConfirm(
          value,
          _confirmPasswordController.text,
        );
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _confirmPasswordValidation = Validators.validatePasswordConfirm(
        _newPasswordController.text,
        value,
      );
    });
  }

  Future<void> _handleSendCode() async {
    if (_emailValidation?.isValid != true) {
      ToastHelper.showError(AppStrings.emailInvalid);
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authNotifierProvider.notifier).sendVerificationCode(
          email: _emailController.text.trim(),
          purpose: 'find_password',
        );

    setState(() {
      _isLoading = false;
      if (success) _currentStep = 1;
    });

    if (success) {
      ToastHelper.showSuccess(AppStrings.verificationCodeSent);
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
    }
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ToastHelper.showError('6자리 인증번호를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    final isCodeValid = await ref.read(authNotifierProvider.notifier).verifyCode(
          email: _emailController.text.trim(),
          code: code,
        );

    setState(() {
      _isLoading = false;
      if (isCodeValid) _currentStep = 2;
    });

    if (!isCodeValid) {
      ToastHelper.showError(AppStrings.verificationCodeInvalid);
    }
  }

  Future<void> _handleResetPassword() async {
    if (_passwordValidation?.isValid != true ||
        _confirmPasswordValidation?.isValid != true) {
      ToastHelper.showError('비밀번호를 확인해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authNotifierProvider.notifier).resetPassword(
          _emailController.text.trim(),
        );

    setState(() {
      _isLoading = false;
      if (success) _currentStep = 3;
    });

    if (success) {
      ToastHelper.showSuccess('비밀번호가 재설정되었습니다.');
    } else {
      ToastHelper.showError(AppStrings.errorGeneric);
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
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildVerifyStep();
      case 2:
        return _buildNewPasswordStep();
      case 3:
        return _buildCompleteStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '가입 시 등록한 이메일을 입력해 주세요.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
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
          text: AppStrings.sendVerificationCode,
          onPressed:
              _emailValidation?.isValid == true && !_isLoading ? _handleSendCode : null,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_emailController.text}로\n인증번호가 발송되었습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
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
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: AppStrings.verify,
          onPressed: _isLoading ? null : _handleVerify,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: '인증번호 재발송',
          type: ButtonType.text,
          onPressed: _handleSendCode,
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '새로운 비밀번호를 입력해 주세요.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: '새 비밀번호',
          hint: '영문 숫자 조합 20자 이내',
          controller: _newPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          maxLength: 20,
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: _validatePassword,
          isValid: _passwordValidation?.isValid == true,
          errorText: _passwordValidation?.isValid == false
              ? _passwordValidation!.message
              : null,
          helperText: _passwordValidation?.isValid == true
              ? _passwordValidation!.message
              : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: '새 비밀번호 확인',
          hint: '비밀번호를 다시 입력하세요',
          controller: _confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          maxLength: 20,
          prefixIcon: const Icon(Icons.lock_outline),
          onChanged: _validateConfirmPassword,
          isValid: _confirmPasswordValidation?.isValid == true,
          errorText: _confirmPasswordValidation?.isValid == false
              ? _confirmPasswordValidation!.message
              : null,
          helperText: _confirmPasswordValidation?.isValid == true
              ? _confirmPasswordValidation!.message
              : null,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: '비밀번호 변경',
          onPressed: _passwordValidation?.isValid == true &&
                  _confirmPasswordValidation?.isValid == true &&
                  !_isLoading
              ? _handleResetPassword
              : null,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        const Text(
          '비밀번호가 변경되었습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '새로운 비밀번호로 로그인해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: AppStrings.login,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
