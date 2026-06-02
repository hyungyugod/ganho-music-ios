# Sprint 1 - Start Scene + Login Choice Overlay

## 목표

처음 화면을 "메인 비주얼 + 시작 버튼"만 남긴다. 사용자가 시작을 누르면 로그인 선택 오버레이가 뜨고, 거기서 `게스트로 시작` 또는 `Apple로 연동`을 고른 뒤 캐릭터 홈으로 이동한다.

## 현재 상태 요약

- `StartScene.swift`는 이미 Firebase Auth 상태 pill, Apple 로그인 pill, 계정 관리 pill, 통계 pill, 타이틀, 김간호 아바타, 시작 버튼을 모두 들고 있다.
- `AppDelegate.swift`는 앱 시작 시 `FirebaseAuthManager.shared.ensureAnonymousSession()`을 호출한다.
- `FirebaseAuthManager`와 `AccountMenuOverlayNode`는 이미 존재한다.
- 사용자 요청은 "처음화면에는 그냥 시작버튼과 메인화면만"이며, 로그인 UI는 시작 후 오버레이에서 고르는 흐름이다.

## 범위

포함:
- 첫 화면에서 계정/통계 pill 제거 또는 숨김.
- 신규 `LoginChoiceOverlayNode` 또는 동등한 SKNode 기반 오버레이 생성.
- 시작 버튼 탭 -> 로그인 오버레이 표시.
- 게스트 선택 -> 익명 세션 확보 후 `CharacterSelectScene`.
- Apple 선택 -> Apple Sign In/Link 완료 후 `CharacterSelectScene`.
- 실패/취소 시 오버레이 안에서 상태 메시지 표시.

제외:
- 계정 삭제/로그아웃 관리 UI 리디자인.
- 서버 리더보드, 클라우드 데이터 구조 변경.
- 캐릭터 홈 재디자인. 이것은 Sprint 2에서 처리한다.

## UX 흐름

1. 앱 첫 진입:
   - 배경, 메인 캐릭터, 제목, `시작` 버튼만 보인다.
   - BEST/PLAYS/Auth pill은 첫 화면에서 보이지 않는다.
2. `시작` 탭:
   - 화면 중앙에 로그인 선택 오버레이가 올라온다.
   - 뒤 배경은 어둡게 dim 처리하되 메인 화면 맥락은 남긴다.
3. `게스트로 시작`:
   - 기존 익명 세션이 있으면 그대로 사용한다.
   - 없으면 `ensureAnonymousSession()`을 호출한다.
   - 완료 후 `CharacterSelectScene.newCharacterSelectScene()`으로 이동한다.
4. `Apple로 연동`:
   - 현재 익명 계정이 있으면 기존 `signInOrLinkAppleCredential` 흐름으로 링크된다.
   - 성공 후 캐릭터 홈으로 이동한다.
   - 취소하면 오버레이를 유지하고 "취소됨" 메시지를 짧게 보여준다.

## 구현 계획

1. `StartScene` 정리
   - `setupStatPills()`와 `setupAuthControls()` 호출을 첫 화면에서 제거한다.
   - 기존 프로퍼티를 바로 삭제할지, Sprint 2 계정 관리 재사용을 위해 남길지는 구현 시 판단한다.
   - `touchesBegan` 우선순위는 `loginOverlay` -> `startButton` 순으로 단순화한다.

2. 로그인 오버레이 노드 추가
   - 후보 파일: `GanhoMusic/GanhoMusic Shared/Nodes/LoginChoiceOverlayNode.swift`
   - 구성:
     - dim background
     - panel
     - title: "시작 방법 선택"
     - primary: "게스트로 시작"
     - secondary: "Apple로 연동"
     - close/cancel
     - status label
   - `action(at:) -> LoginChoiceAction?` 형태로 터치 처리를 Scene 밖으로 분리한다.

3. Auth 흐름 연결
   - `handleGuestStartTap()`
   - `handleAppleStartTap()`
   - 비동기 작업 중에는 버튼 중복 탭을 막는다.
   - `Task { [weak self] in ... }` 패턴을 사용한다.

4. Scene 전환
   - 로그인 선택 성공 후 기존 전환 애니메이션과 비슷한 fade를 사용한다.
   - 로그인 오버레이 닫기 후에도 StartScene은 안정적으로 남아 있어야 한다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/LoginChoiceOverlayNode.swift` 신규
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`

## 수용 기준

- 첫 화면에서 인증/통계 pill이 보이지 않는다.
- 시작 버튼을 눌러야 로그인 선택 UI가 나타난다.
- 게스트 선택 후 캐릭터 홈으로 이동한다.
- Apple 취소/실패 시 앱이 멈추지 않고 오버레이 상태 메시지를 보여준다.
- 더블 탭으로 중복 전환되지 않는다.
- iPhone landscape safe area에서 오버레이 버튼 텍스트가 잘리지 않는다.

## 주요 위험

- 앱 시작 시 이미 익명 세션을 만드는 구조가 있다. Sprint 1에서는 이를 굳이 제거하지 않고, "게스트 선택 시 기존 익명 세션을 사용"하는 방향이 가장 안전하다.
- Apple 로그인은 실기기/프로비저닝 설정 영향을 받는다. 구현 후 실제 기기에서 최소 1회 확인해야 한다.
