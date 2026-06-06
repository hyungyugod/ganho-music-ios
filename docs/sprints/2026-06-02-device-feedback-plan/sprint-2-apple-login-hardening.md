# Sprint 2 - Apple Login Hardening

## 목표

Apple 로그인을 누르면 "잠시 기다려" 또는 "Apple 확인 중" 상태에 머무르고 로그인이 완료되지 않는 문제를 해결한다. 인증 요청이 실패해도 UI가 반드시 idle로 돌아오고, 실패 원인이 사용자에게 짧게 보이도록 만든다.

## 현재 상태

- `StartScene.handleAppleStartTap()`은 `FirebaseAuthManager.shared.signInWithApple(presentationAnchor:)` 결과를 기다린다.
- `FirebaseAuthManager.performAppleAuthorization`은 `ASAuthorizationController`를 지역 변수로 만들고 `performRequests()`를 호출한다.
- `appleContinuation`이 resume되지 않으면 StartScene의 `isLoginRequestInFlight`가 계속 true로 남고 overlay는 busy 상태에서 풀리지 않는다.
- `currentNonce`, `appleContinuation`, `applePresentationProvider`는 있지만 `ASAuthorizationController` 자체를 강하게 보관하는 프로퍼티는 없다.
- timeout, 상세 에러 메시지, debug-safe logging이 없다.
- `GanhoMusic.entitlements`에는 `com.apple.developer.applesignin`이 있고, iOS bundle id와 Firebase plist는 `com.hyungyu.GanhoMusic`로 맞아 있다.

## 변경 의도

인증 플로우는 "성공/취소/실패/응답 없음" 모두 UI가 복구되어야 한다. 실기기 Apple 로그인은 외부 설정 영향도 있으므로, 앱 내부에서는 controller 생명주기와 실패 복구를 먼저 안정화하고, 외부 설정 확인 항목을 분리한다.

## 구현 범위

### Phase A - ASAuthorizationController 생명주기 보강

`FirebaseAuthManager`에 controller 보관 프로퍼티를 추가한다.

```swift
private var appleAuthorizationController: ASAuthorizationController?
```

- `performAppleAuthorization`에서 생성한 controller를 이 프로퍼티에 저장한다.
- `clearAppleFlowState()`에서 nil 처리한다.
- delegate callback에서 continuation resume 후 controller도 해제한다.

의심 원인:

- controller가 지역 변수로만 존재하면 delegate callback이 오기 전에 해제될 가능성이 있다.
- callback이 오지 않으면 continuation이 영원히 대기하고 StartScene busy가 풀리지 않는다.

### Phase B - Timeout 안전망

Apple 인증 요청에 timeout을 둔다.

권장 정책:

- timeout: `GameConfig.authAppleRequestTimeout = 12.0`
- timeout 도달 시 continuation이 아직 있으면 `.failure(AuthError.appleAuthorizationTimedOut)`로 resume한다.
- 이후 `clearAppleFlowState()` 호출.

구현 방식 후보:

- `Task`로 timeout action을 저장하고, 성공/실패 시 cancel한다.
- 또는 `withThrowingTaskGroup`으로 authorization task와 sleep task 중 먼저 끝난 것을 사용한다.

권장:

- `FirebaseAuthManager` 내부에 `appleTimeoutTask: Task<Void, Never>?`를 둔다.
- SpriteKit 액션이 아닌 인증 manager 영역이므로 Swift concurrency timeout이 더 적합하다.

### Phase C - 에러 타입 확장

`AuthError.swift`에 다음 케이스를 추가한다.

- `appleAuthorizationTimedOut`
- `appleAuthorizationNoPresentationAnchor` 또는 StartScene에서만 처리
- `appleSignInFailed`

사용자 메시지는 긴 설명이 아니라 짧게:

- 취소: `취소했어요`
- timeout: `Apple 로그인이 지연돼요`
- 설정/권한 실패: `Apple 로그인 설정을 확인해 주세요`
- 일반 실패: `잠시 후 다시 시도`

### Phase D - StartScene UI 복구 강화

- `handleAppleStartTap()`에서 결과가 `.failure`여도 무조건:
  - `isLoginRequestInFlight = false`
  - overlay mode `.idle`
  - status text 표시
- view/window가 nil인 경우도 `isLoginRequestInFlight`가 true로 남지 않게 한다.
- Apple 버튼 busy text는 `Apple 확인 중`보다 실제 상태가 보이도록 `Apple 로그인 중` 정도로 바꿀 수 있다.

### Phase E - Firebase/Auth 외부 설정 체크리스트

앱 코드로 직접 검증 불가능한 항목은 계획/QA에 명시한다.

- Apple Developer App ID에 Sign in with Apple capability가 켜져 있는지.
- Xcode Signing & Capabilities에 Sign in with Apple이 iOS target에 적용되어 있는지.
- Firebase Authentication에서 Apple provider가 enabled인지.
- Firebase iOS app bundle id가 `com.hyungyu.GanhoMusic`인지.
- 실기기에서 Apple ID 로그인 상태와 네트워크 상태가 정상인지.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Managers/FirebaseAuthManager.swift`
- `GanhoMusic/GanhoMusic Shared/Errors/AuthError.swift`
- `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/LoginChoiceOverlayNode.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`

## 보존할 것

- 게스트 로그인 흐름.
- anonymous user를 Apple credential에 link하는 정책.
- credential already in use/account exists fallback sign-in 정책.
- AuthProfileRepository 저장 방식.
- FirebaseApp.configure() 초기화 위치.

## 수용 기준

- Apple 로그인 성공 시 캐릭터 홈으로 이동한다.
- Apple 로그인 취소 시 overlay가 idle로 돌아오고 "취소했어요"가 보인다.
- Apple 로그인 실패/timeout 시 overlay가 idle로 돌아온다.
- busy 상태가 12초 이상 무한 지속되지 않는다.
- 재시도 버튼 탭이 정상 동작한다.
- 게스트 시작 흐름은 회귀하지 않는다.

## 리스크와 대응

- 리스크: 외부 Apple Developer/Firebase 설정이 잘못되어 코드 수정 후에도 실패할 수 있다.
  - 대응: 앱 내부 busy 복구와 외부 설정 체크리스트를 분리해 QA한다.
- 리스크: timeout이 정상 로그인 중 너무 빨리 실패시킬 수 있다.
  - 대응: 12초를 1차값으로 두고, 실기기에서 느리면 15초로 조정한다.
- 리스크: continuation 이중 resume.
  - 대응: `finishAppleAuthorization`에서 continuation을 지역 상수로 뽑고 즉시 nil 처리한 뒤 resume한다.

