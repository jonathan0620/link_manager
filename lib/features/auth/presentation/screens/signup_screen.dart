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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _emailController = TextEditingController();

  ValidationResult? _usernameValidation;
  ValidationResult? _passwordValidation;
  ValidationResult? _passwordConfirmValidation;
  ValidationResult? _emailValidation;

  bool _isLoading = false;
  bool _isUsernameChecking = false;
  bool _isUsernameAvailable = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateUsername(String value) async {
    final validation = Validators.validateUsername(value);
    setState(() {
      _usernameValidation = validation;
      _isUsernameAvailable = false;
    });

    if (validation.isValid) {
      setState(() => _isUsernameChecking = true);
      final isAvailable = await ref
          .read(authNotifierProvider.notifier)
          .isUsernameAvailable(value);
      setState(() {
        _isUsernameChecking = false;
        _isUsernameAvailable = isAvailable;
        if (!isAvailable) {
          _usernameValidation = const ValidationResult(
            false,
            AppStrings.errorUsernameAlreadyInUse,
          );
        }
      });
    }
  }

  void _validatePassword(String value) {
    setState(() {
      _passwordValidation = Validators.validatePassword(value);
      if (_passwordConfirmController.text.isNotEmpty) {
        _passwordConfirmValidation = Validators.validatePasswordConfirm(
          value,
          _passwordConfirmController.text,
        );
      }
    });
  }

  void _validatePasswordConfirm(String value) {
    setState(() {
      _passwordConfirmValidation = Validators.validatePasswordConfirm(
        _passwordController.text,
        value,
      );
    });
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValidation = Validators.validateEmail(value);
    });
  }

  bool get _isFormValid {
    return _usernameValidation?.isValid == true &&
        _isUsernameAvailable &&
        _passwordValidation?.isValid == true &&
        _passwordConfirmValidation?.isValid == true &&
        _emailValidation?.isValid == true;
  }

  Future<void> _handleNext() async {
    if (!_isFormValid) {
      _showSnackBar('입력 정보를 확인해 주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 이메일 인증 없이 바로 회원가입
      final success = await ref.read(authNotifierProvider.notifier).signUp(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSnackBar('회원가입이 완료되었습니다!', isError: false);
        context.go('/onboarding');
      } else {
        final authState = ref.read(authNotifierProvider);
        _showSnackBar(authState.errorMessage ?? '회원가입에 실패했습니다.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('오류: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ToastHelper.showSnackBar(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.signup),
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
                  // Username field
                  CustomTextField(
                    label: AppStrings.username,
                    hint: '영문 숫자 조합 10자 이내',
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    maxLength: 10,
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: _isUsernameChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onChanged: _validateUsername,
                    isValid: _usernameValidation?.isValid == true && _isUsernameAvailable,
                    errorText: _usernameValidation?.isValid == false
                        ? _usernameValidation!.message
                        : null,
                    helperText: _usernameValidation?.isValid == true && _isUsernameAvailable
                        ? _usernameValidation!.message
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    label: AppStrings.password,
                    hint: '영문 숫자 조합 20자 이내',
                    controller: _passwordController,
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

                  // Password confirm field
                  CustomTextField(
                    label: AppStrings.passwordConfirm,
                    hint: '비밀번호를 다시 입력하세요',
                    controller: _passwordConfirmController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    maxLength: 20,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: _validatePasswordConfirm,
                    isValid: _passwordConfirmValidation?.isValid == true,
                    errorText: _passwordConfirmValidation?.isValid == false
                        ? _passwordConfirmValidation!.message
                        : null,
                    helperText: _passwordConfirmValidation?.isValid == true
                        ? _passwordConfirmValidation!.message
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  CustomTextField(
                    label: AppStrings.email,
                    hint: 'example@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.email_outlined),
                    onChanged: _validateEmail,
                    isValid: _emailValidation?.isValid == true,
                    errorText: _emailValidation?.isValid == false
                        ? _emailValidation!.message
                        : null,
                    helperText: _emailValidation?.isValid == true
                        ? _emailValidation!.message
                        : null,
                  ),
                  const SizedBox(height: 32),

                  // Signup button
                  CustomButton(
                    text: AppStrings.signup,
                    onPressed: _isFormValid && !_isLoading ? _handleNext : null,
                    isLoading: _isLoading,
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
