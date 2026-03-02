class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'ZOOP';

  // Auth
  static const String login = '로그인';
  static const String signup = '회원가입';
  static const String logout = '로그아웃';
  static const String findId = '아이디 찾기';
  static const String findPassword = '비밀번호 찾기';

  // Input Labels
  static const String username = '아이디';
  static const String password = '비밀번호';
  static const String passwordConfirm = '비밀번호 확인';
  static const String email = '이메일';
  static const String verificationCode = '인증번호';

  // Validation Messages
  static const String usernameValid = '사용 가능한 아이디 입니다.';
  static const String usernameInvalid = '영문 숫자 조합 10자 이내만 가능합니다.';
  static const String passwordValid = '사용 가능한 비밀번호 입니다.';
  static const String passwordInvalid = '영문 숫자 조합 20자 이내만 가능합니다.';
  static const String passwordMismatch = '비밀번호가 일치하지 않습니다.';
  static const String emailValid = '사용 가능한 이메일 입니다.';
  static const String emailInvalid = '이메일 주소를 다시 한 번 확인해 주세요.';
  static const String verificationCodeInvalid = '인증번호가 일치하지 않습니다.';
  static const String verificationCodeSent = '인증번호가 발송되었습니다.';

  // Buttons
  static const String sendVerificationCode = '인증번호 발송';
  static const String verify = '인증하기';
  static const String next = '다음';
  static const String complete = '완료';
  static const String save = '저장';
  static const String cancel = '취소';
  static const String edit = '수정';
  static const String delete = '삭제';

  // Home
  static const String recentLinks = '최근 저장한 링크';
  static const String unreadLinks = '읽지 않은 링크';
  static const String allLinks = '전체 링크';

  // Link
  static const String addLink = '링크 추가';
  static const String editLink = '링크 수정';
  static const String urlPlaceholder = 'URL을 입력하세요';
  static const String titlePlaceholder = '제목';
  static const String noTitle = '제목 없음';
  static const String selectLabel = '라벨 선택';
  static const String addLabel = '라벨 추가';
  static const String linkSaved = '링크가 저장되었습니다.';
  static const String linkUpdated = '링크가 수정되었습니다.';
  static const String linkDeleted = '링크가 삭제되었습니다.';

  // Search
  static const String search = '검색';
  static const String searchPlaceholder = '제목 또는 URL로 검색';
  static const String noResults = '검색 결과가 없습니다.';

  // Onboarding
  static const String selectCategories = '관심 있는 카테고리를 선택하세요';
  static const String skipOnboarding = '건너뛰기';

  // Categories
  static const String technology = '기술';
  static const String design = '디자인';
  static const String business = '비즈니스';
  static const String lifestyle = '라이프스타일';
  static const String entertainment = '엔터테인먼트';
  static const String news = '뉴스';
  static const String education = '교육';
  static const String others = '기타';

  // Errors
  static const String errorGeneric = '오류가 발생했습니다. 다시 시도해 주세요.';
  static const String errorNetwork = '네트워크 연결을 확인해 주세요.';
  static const String errorInvalidCredentials = '아이디 또는 비밀번호가 올바르지 않습니다.';
  static const String errorUserNotFound = '사용자를 찾을 수 없습니다.';
  static const String errorEmailAlreadyInUse = '이미 사용 중인 이메일입니다.';
  static const String errorUsernameAlreadyInUse = '이미 사용 중인 아이디입니다.';
}
