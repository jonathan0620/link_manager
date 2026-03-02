import '../constants/app_strings.dart';

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult(this.isValid, this.message);
}

class Validators {
  Validators._();

  /// ID: 영문+숫자 조합 10자 이내
  static ValidationResult validateUsername(String value) {
    if (value.isEmpty) {
      return const ValidationResult(false, '아이디를 입력해 주세요.');
    }

    final regex = RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)[a-zA-Z\d]{1,10}$');
    if (regex.hasMatch(value)) {
      return const ValidationResult(true, AppStrings.usernameValid);
    }
    return const ValidationResult(false, AppStrings.usernameInvalid);
  }

  /// PW: 6자 이상
  static ValidationResult validatePassword(String value) {
    if (value.isEmpty) {
      return const ValidationResult(false, '비밀번호를 입력해 주세요.');
    }

    if (value.length >= 6) {
      return const ValidationResult(true, '사용 가능한 비밀번호입니다.');
    }
    return const ValidationResult(false, '비밀번호는 6자 이상이어야 합니다.');
  }

  /// Password confirmation
  static ValidationResult validatePasswordConfirm(String password, String confirm) {
    if (confirm.isEmpty) {
      return const ValidationResult(false, '비밀번호 확인을 입력해 주세요.');
    }

    if (password == confirm) {
      return const ValidationResult(true, '비밀번호가 일치합니다.');
    }
    return const ValidationResult(false, AppStrings.passwordMismatch);
  }

  /// Email: @ 포함
  static ValidationResult validateEmail(String value) {
    if (value.isEmpty) {
      return const ValidationResult(false, '이메일을 입력해 주세요.');
    }

    if (value.contains('@') && value.contains('.')) {
      return const ValidationResult(true, AppStrings.emailValid);
    }
    return const ValidationResult(false, AppStrings.emailInvalid);
  }

  /// Verification code: 6자리 숫자
  static ValidationResult validateVerificationCode(String value) {
    if (value.isEmpty) {
      return const ValidationResult(false, '인증번호를 입력해 주세요.');
    }

    final regex = RegExp(r'^\d{6}$');
    if (regex.hasMatch(value)) {
      return const ValidationResult(true, '');
    }
    return const ValidationResult(false, '6자리 인증번호를 입력해 주세요.');
  }

  /// URL validation
  static ValidationResult validateUrl(String value) {
    if (value.isEmpty) {
      return const ValidationResult(false, 'URL을 입력해 주세요.');
    }

    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (urlPattern.hasMatch(value)) {
      return const ValidationResult(true, '');
    }
    return const ValidationResult(false, '올바른 URL 형식이 아닙니다.');
  }
}
