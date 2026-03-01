# Link Manager App

Flutter + Firebase 기반 링크 관리 앱 (Web/iOS/Android 지원)

## 기술 스택

- **Framework**: Flutter 3.x
- **State Management**: Riverpod 2.x
- **Backend**: Firebase (Auth, Firestore, Cloud Functions)
- **UI**: Material 3
- **Architecture**: Clean Architecture + Feature-first 구조

## 기능

### 인증
- 회원가입 (ID/PW/Email + 이메일 인증)
- 로그인 (자동 로그인 지원)
- 아이디 찾기
- 비밀번호 재설정

### 링크 관리
- 링크 추가 (URL 입력 시 썸네일/제목 자동 추출)
- 링크 수정/삭제
- 라벨(태그) 기반 분류
- 읽음/안읽음 상태 관리

### 검색
- 제목 및 URL 기반 검색

## 프로젝트 구조

```
lib/
├── main.dart
├── firebase_options.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── utils/
│   ├── widgets/
│   └── router/
└── features/
    ├── auth/
    ├── onboarding/
    ├── home/
    ├── link/
    └── search/
```

## 설정 방법

### 1. Flutter 설정

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod Generator 사용 시)
flutter pub run build_runner build
```

### 2. Firebase 설정

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결
flutterfire configure
```

### 3. Firebase Console 설정

1. **Authentication 활성화**
   - Email/Password 인증 활성화

2. **Firestore Database 생성**
   - Production 모드로 시작
   - `firestore.rules` 배포

3. **Cloud Functions 배포**
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

### 4. 환경 변수 설정 (Cloud Functions)

Cloud Functions에서 이메일 발송을 위해 환경 변수 설정:

```bash
firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"
```

## 실행

```bash
# Web
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

## 로컬 테스트 (Firebase Emulator)

```bash
# Emulator 시작
firebase emulators:start

# Flutter 앱 실행 (Emulator 연결)
flutter run
```

## Firestore 데이터 구조

### Collections

```
users/
  {userId}/
    - username: string
    - email: string
    - createdAt: timestamp
    - selectedCategories: string[]

links/
  {linkId}/
    - userId: string
    - url: string
    - title: string
    - thumbnailUrl: string?
    - label: string?
    - isRead: boolean
    - createdAt: timestamp
    - updatedAt: timestamp

categories/
  {categoryId}/
    - userId: string
    - name: string
    - linkCount: number
    - createdAt: timestamp

verification_codes/
  {email}/
    - code: string (6자리)
    - expiresAt: timestamp
    - purpose: 'signup' | 'find_id' | 'find_password'
```

## 유효성 검사 규칙

- **ID**: 영문+숫자 조합 10자 이내
- **PW**: 영문+숫자 조합 20자 이내
- **Email**: @ 포함

## 라이선스

MIT License
