# 백엔드 설계서 - GanhoMusic iOS

Firebase 무료 티어로 시작하는 개인 계정/기록 저장 설계.

## 1. 기술 스택

| 역할 | 선택 | 이유 |
|---|---|---|
| 인증 | Firebase Authentication | 익명 로그인으로 즉시 시작하고, 나중에 Apple 로그인 연결 가능 |
| DB | Cloud Firestore | 사용자별 기록 저장과 리더보드 쿼리에 충분 |
| iOS SDK | Firebase Apple SDK | Swift/iOS 지원이 안정적이고 Xcode SPM 설치 가능 |
| 서버 코드 | 없음 | MVP는 Auth + Firestore 보안 규칙으로 처리 |

초기 UX는 "익명 계정 + 닉네임 등록"으로 간다. 사용자는 로그인 화면을 만나지 않고도 바로 플레이하고, 기록 화면에서는 `00님의 기록`처럼 개인화된 문구를 본다. 이후 계정 복구가 필요해지면 같은 Firebase Auth 계정에 Apple 로그인을 연결한다.

## 2. 콘솔 설정 순서

1. Firebase 콘솔에서 프로젝트 생성
2. iOS 앱 추가
3. Bundle ID 입력: Xcode의 GanhoMusic iOS target 값 사용
4. `GoogleService-Info.plist` 다운로드
5. Xcode에서 `GanhoMusic/GanhoMusic iOS` target 리소스로 추가
6. Authentication에서 Anonymous provider 활성화
7. Firestore Database 생성
8. 아래 보안 규칙 적용

`GoogleService-Info.plist`는 앱별 설정 파일이다. 공개 저장소에 올릴 때는 프로젝트 정책을 먼저 정해야 한다.

## 3. Firestore 구조

```text
profiles/{uid}
  nickname: "하은"
  createdAt: serverTimestamp
  updatedAt: serverTimestamp

profiles/{uid}/records/{recordId}
  characterId: "kim"
  difficulty: "normal"
  score: 42
  playCount: 1
  totalScore: 42
  graduated: false
  playedAt: serverTimestamp
```

전체 리더보드가 필요해지면 중복 저장 컬렉션을 추가한다.

```text
leaderboard/{characterId}_{difficulty}_{uid}
  uid: "{uid}"
  nickname: "하은"
  characterId: "kim"
  difficulty: "normal"
  bestScore: 88
  updatedAt: serverTimestamp
```

## 4. 보안 규칙

Firebase 콘솔의 Firestore Rules에는 `firebase/firestore.rules` 내용을 적용한다.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return signedIn() && request.auth.uid == uid;
    }

    match /profiles/{uid} {
      allow read, create, update: if isOwner(uid);
      allow delete: if false;

      match /records/{recordId} {
        allow read, create: if isOwner(uid);
        allow update, delete: if false;
      }
    }

    match /leaderboard/{entryId} {
      allow read: if true;
      allow create, update: if signedIn()
        && request.resource.data.uid == request.auth.uid;
      allow delete: if false;
    }
  }
}
```

## 5. iOS 연결 계획

### Phase 1 - 로컬 개인화 완료

현재 코드에 `UserProfile`과 `UserProfileRepository`를 추가했다. Firebase가 없어도 앱은 게스트 프로필을 만들고 기록 화면 제목을 `간호사님의 기록`으로 표시한다.

### Phase 2 - Firebase SDK 설치 완료

Xcode 프로젝트에 Firebase Apple SDK 12.14.0을 Swift Package Manager로 추가했다.

```text
https://github.com/firebase/firebase-ios-sdk
```

필요 제품:

```text
FirebaseAuth
FirebaseFirestore
FirebaseCore
```

`AppDelegate.application(_:didFinishLaunchingWithOptions:)`에서 `FirebaseBootstrap.configureIfAvailable()`를 호출한다. `GoogleService-Info.plist`가 아직 없으면 앱은 Firebase 초기화를 건너뛰고 로컬 모드로 동작한다.

```swift
FirebaseBootstrap.configureIfAvailable()
```

### Phase 3 - 익명 로그인 완료

앱 시작 시 현재 Firebase 사용자가 없으면 익명 로그인한다.

```swift
await FirebaseAccountRepository().bootstrapProfile()
```

### Phase 4 - 프로필 동기화 완료

로컬 `UserProfile.id`는 Firebase 연결 전 임시 id다. 익명 로그인 후에는 `profiles/{uid}`를 읽고, 없으면 로컬 닉네임으로 생성한다.

### Phase 5 - 점수 업로드 완료

게임 종료 시 기존 UserDefaults 저장은 유지한다. 동시에 `profiles/{uid}/records`에 판별 기록을 비동기로 추가한다. 업로드 실패는 결과 화면 전환을 막지 않는다.

## 6. 비용 전략

MVP에서 저장하는 데이터는 문자열과 숫자뿐이라 무료 티어로 충분하다. 비용이 늘어나는 지점은 리더보드 화면에서 전체 데이터를 너무 자주 읽는 경우다. 그래서 리더보드는 `limit(100)`과 캐시를 기본 정책으로 둔다.

## 7. 다음 구현 단위

1. Firebase 콘솔에서 `GoogleService-Info.plist` 다운로드 후 iOS target 리소스로 추가
2. Authentication > Sign-in method에서 Anonymous 활성화
3. Firestore Database 생성 후 `firebase/firestore.rules` 적용
4. 닉네임 입력 화면 추가
5. 로컬 과거 기록을 첫 로그인 시 서버로 마이그레이션
6. 리더보드 컬렉션 갱신 로직 추가
