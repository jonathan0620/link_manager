# ZOOP - Link Manager App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

**ZOOP**은 웹 링크를 저장하고 관리할 수 있는 Flutter 기반 크로스플랫폼 앱입니다.

**Live Demo**: [https://zoop-36b4f.web.app](https://zoop-36b4f.web.app)

## Screenshots

| 홈 화면 | 링크 추가 | 검색 |
|:---:|:---:|:---:|
| 저장한 링크 목록 | URL 자동 메타데이터 추출 | 제목/URL 검색 |

## 기술 스택

| 분류 | 기술 |
|------|------|
| **Framework** | Flutter 3.x |
| **Language** | Dart |
| **State Management** | Riverpod 2.x |
| **Backend** | Firebase (Auth, Firestore) |
| **Hosting** | Firebase Hosting |
| **Design System** | Material Design 3 |
| **Architecture** | Clean Architecture + Feature-first |

## 주요 기능

### 인증 (Authentication)
- 회원가입 (아이디/비밀번호/이메일)
- 로그인 (자동 로그인 지원)
- 아이디 찾기
- 비밀번호 재설정

### 링크 관리
- **링크 추가**: URL 입력 시 썸네일/제목 자동 추출
- **링크 수정**: 슬라이딩 패널에서 인라인 편집
- **링크 삭제**: 확인 다이얼로그 후 삭제
- **즐겨찾기**: 북마크 기능으로 중요 링크 관리
- **읽음/안읽음**: 클릭 시 자동 읽음 처리
- **라벨링**: 13가지 프리셋 라벨로 분류
  - 🍳 요리, ✈️ 여행, 🎮 게임, 🎨 취미, 🎯 디자인
  - 💼 업무, 🍲 맛집, 🛒 쇼핑, 💻 개발, 🏃 운동
  - 📰 기사, 📈 주식, 🎬 영상

### 필터 & 검색
- **최근 저장한 링크**: 최신 10개 링크
- **안 읽은 링크**: 아직 클릭하지 않은 링크
- **즐겨찾기**: 북마크한 링크
- **라벨별 필터**: 각 라벨별 링크 보기
- **검색**: 제목 및 URL 기반 검색

### UX 기능
- **Pull to Refresh**: 당겨서 새로고침
- **링크 개수 표시**: 사이드바에 필터별 링크 개수
- **센터 토스트**: 화면 중앙 알림 메시지
- **링크 복사**: 원클릭 URL 복사
- **반응형 그리드**: 화면 크기에 따라 1~2열 레이아웃

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── firebase_options.dart     # Firebase 설정
├── app.dart                  # MaterialApp 설정
│
├── core/                     # 공통 모듈
│   ├── constants/
│   │   ├── app_colors.dart   # 색상 정의
│   │   └── app_strings.dart  # 문자열 상수
│   ├── utils/
│   │   ├── validators.dart   # 유효성 검사
│   │   └── share_helper.dart # 공유/복사 유틸
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── toast_helper.dart # 센터 토스트
│   │   └── zoop_logo.dart
│   └── router/
│       └── app_router.dart   # GoRouter 설정
│
└── features/                 # 기능별 모듈
    ├── auth/                 # 인증
    │   ├── data/
    │   │   ├── repositories/auth_repository.dart
    │   │   └── models/user_model.dart
    │   ├── providers/auth_provider.dart
    │   └── presentation/screens/
    │       ├── login_screen.dart
    │       ├── signup_screen.dart
    │       ├── find_id_screen.dart
    │       └── find_password_screen.dart
    │
    ├── onboarding/           # 온보딩
    │   └── presentation/screens/
    │       └── category_selection_screen.dart
    │
    ├── home/                 # 홈 (메인)
    │   ├── data/
    │   │   ├── repositories/link_repository.dart
    │   │   └── models/link_model.dart
    │   ├── providers/
    │   │   ├── links_provider.dart
    │   │   └── categories_provider.dart
    │   └── presentation/screens/
    │       └── home_screen.dart
    │
    ├── link/                 # 링크 추가/수정
    │   ├── providers/link_form_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       └── widgets/label_selector.dart
    │
    └── search/               # 검색
        ├── providers/search_provider.dart
        └── presentation/screens/
            └── search_screen.dart
```

## 설치 및 실행

### 사전 요구사항
- Flutter 3.x
- Dart 3.x
- Firebase CLI
- Node.js (Cloud Functions용)

### 1. 프로젝트 클론

```bash
git clone https://github.com/jonathan0620/link_manager.git
cd link_manager
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. Firebase 설정

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 연결
flutterfire configure
```

### 4. 실행

```bash
# Web
flutter run -d chrome

# iOS 시뮬레이터
flutter run -d ios

# Android 에뮬레이터
flutter run -d android
```

### 5. 빌드 & 배포

```bash
# Web 빌드
flutter build web --release

# Firebase Hosting 배포
firebase deploy --only hosting
```

## Firestore 데이터 구조

```
users/{userId}
├── username: string        # 사용자 아이디
├── email: string           # 이메일
├── createdAt: timestamp    # 가입일
└── selectedCategories: []  # 온보딩 선택 카테고리

links/{linkId}
├── userId: string          # 소유자 ID
├── url: string             # 링크 URL
├── title: string           # 제목
├── thumbnailUrl: string?   # 썸네일 이미지 URL
├── label: string?          # 라벨 (단일 선택)
├── isRead: boolean         # 읽음 여부
├── isFavorite: boolean     # 즐겨찾기 여부
├── createdAt: timestamp    # 생성일
└── updatedAt: timestamp    # 수정일
```

## 유효성 검사 규칙

| 필드 | 규칙 |
|------|------|
| **아이디** | 영문+숫자 조합, 10자 이내 |
| **비밀번호** | 영문+숫자 조합, 20자 이내 |
| **이메일** | @ 포함 |

## API 사용 (메타데이터 추출)

링크 메타데이터 추출을 위해 다음 API를 순차적으로 시도합니다:

1. **Microlink API** (Primary)
2. **jsonlink.io** (Fallback)
3. **thum.io** (Screenshot Fallback)

## 라이선스

MIT License

---

Made with Flutter
