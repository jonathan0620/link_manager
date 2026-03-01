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

class FindIdScreen extends ConsumerStatefulWidget {
  const FindIdScreen({super.key});

  @override
  ConsumerState<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends ConsumerState<FindIdScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isVerified = false;
  String? _foundUsername;
  ValidationResult? _emailValidation;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValidation = Validators.validateEmail(value);
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
          purpose: 'find_id',
        );

    setState(() {
      _isLoading = false;
      _isCodeSent = success;
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

    if (!isCodeValid) {
      setState(() => _isLoading = false);
      ToastHelper.showError(AppStrings.verificationCodeInvalid);
      return;
    }

    // Find username
    final username = await ref
        .read(authNotifierProvider.notifier)
        .findUsername(_emailController.text.trim());

    setState(() {
      _isLoading = false;
      _isVerified = true;
      _foundUsername = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.findId),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isVerified ? _buildResultView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
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

        // Email field
        CustomTextField(
          label: AppStrings.email,
          hint: 'example@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !_isCodeSent,
          prefixIcon: const Icon(Icons.email_outlined),
          onChanged: _validateEmail,
          isValid: _emailValidation?.isValid == true,
          errorText:
              _emailValidation?.isValid == false ? _emailValidation!.message : null,
        ),

        if (!_isCodeSent) ...[
          const SizedBox(height: 24),
          CustomButton(
            text: AppStrings.sendVerificationCode,
            onPressed:
                _emailValidation?.isValid == true && !_isLoading ? _handleSendCode : null,
            isLoading: _isLoading,
          ),
        ],

        if (_isCodeSent) ...[
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
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        if (_foundUsername != null) ...[
          const Text(
            '아이디를 찾았습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _foundUsername!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ] else ...[
          const Text(
            '해당 이메일로 가입된 계정이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 32),
        CustomButton(
          text: AppStrings.login,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: AppStrings.findPassword,
          type: ButtonType.secondary,
          onPressed: () => context.pushReplacement('/find-password'),
        ),
      ],
    );
  }
}
