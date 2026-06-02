# Device Feedback Sprint 1-6 Sequential Implementation

## 개요
실기기 피드백 계획서 `docs/sprints/2026-06-02-device-feedback-plan`의 Sprint 1~6을 순서대로 구현한다. 결과 화면 오작동, Apple 로그인 busy 고착, 계정별 캐릭터 해금, 중간 컷씬 제거, compact map/속도 조정, 병실 맵 가독성 개선을 한 흐름으로 묶되 각 Sprint의 책임 경계를 유지한다.

## 변경 유형
혼합 — 결과/로그인/캐릭터 홈 UX, 계정별 진행도 게임플레이 로직, 인게임 맵/속도 밸런스, 병실 비주얼 가독성이 함께 변경된다.

## 게임 경험 의도
플레이어가 실기기에서 의도치 않은 화면 전환이나 로그인 고착 없이 자연스럽게 시작하고, 자기 계정의 진행도에 따라 캐릭터가 순차적으로 열리는 구조를 체감하게 한다. 인게임은 중간 멘트로 끊기지 않고 45초 동안 계속 흐르며, 작아진 맵에서도 장애물과 배경이 즉시 구분되어 조작 피로가 줄어야 한다.

## Sprint 범위 계약
- **허용**: Sprint 1~6을 순서대로 구현하는 데 필요한 최소 연동 변경. 파일 추가 시 Xcode iOS 타겟 빌드에 필요한 `project.pbxproj` 등록 변경은 허용한다.
- **금지**: Sprint에 없는 독립 기능, 새 스킬, 새 난이도, 온라인 리더보드, HighScore/Statistics 전체 계정 분리, macOS/tvOS 타겟 수정, 기존 캐릭터/난이도 흐름 재설계.
- **판단 기준**: "이 변경이 없으면 현재 Sprint 수용 기준이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

### 순차 구현 계약
1. Sprint 1을 먼저 완료해 결과 화면의 빈 공간 탭 회귀를 제거한다.
2. Sprint 2를 완료해 Apple 로그인 실패/취소/timeout이 UI idle로 복구되게 한다.
3. Sprint 3을 완료해 계정별 scoped unlock과 locked preview를 적용한다.
4. Sprint 4를 적용해 중간 플레이 차단 컷씬을 끈다.
5. Sprint 5를 적용해 최종 맵 크기와 플레이어 속도를 튜닝한다.
6. Sprint 6을 Sprint 5의 최종 맵 크기 기준으로 적용해 색 대비와 병실 decor를 맞춘다.

### Sprint 1 계약: Result Navigation
- **포함**: 빈 공간 탭의 `StartScene` fallback 제거, 명시적 `메인으로` 버튼 추가, 하단 4버튼 레이아웃, `NEW BEST`/best pill 중복 위치 정리.
- **제외**: 공유 메시지 내용 변경, ScoreboardScene 구조 변경, 다시 시작/기록 보기/공유 흐름 재설계.
- **수용 기준**: 빈 공간 탭은 noop, `메인으로` 버튼만 StartScene 전환, 4개 버튼 모두 독립 동작, 작은 landscape에서 버튼 텍스트/배지가 겹치지 않음.

### Sprint 2 계약: Apple Login Hardening
- **포함**: `ASAuthorizationController` strong retain, Apple auth timeout, continuation 이중 resume 방지, 실패/취소/timeout 후 overlay idle 복구, 짧은 사용자 메시지.
- **제외**: Firebase/Apple Developer 콘솔 설정 자동 변경, Apple 로그인 UI 전면 재설계, 게스트 로그인 정책 변경.
- **수용 기준**: 성공 시 CharacterSelectScene 전환, 취소 시 `취소했어요`, timeout 시 `Apple 로그인이 지연돼요`, 실패 시 idle 복구, busy가 12초 이상 무한 지속되지 않음, 게스트 시작 회귀 없음.

### Sprint 3 계약: Character Unlock And Rough Selection
- **포함**: 화면 좌/우 rough tap 전환, 순차 해금 규칙, locked silhouette preview, locked start 차단, `GraduationRepository`/`PerDifficultyScoreRepository`/`CharacterPreferenceRepository` 계정 scope, saved preference locked 보정.
- **해금 조건 고정**: 김간호는 기본 해금. 정간호는 김간호 졸업 후, 건간호는 정간호 졸업 후, 임간호는 건간호 졸업 후, 이간호는 임간호 졸업 후 해금한다. "졸업"은 현재 `GameScene.isGraduated`의 하/중/상 목표 점수 전체 달성 기준을 유지한다.
- **계정별 진행도 범위 고정**: unlock 판단에 직접 쓰이는 `GraduationRepository`, `PerDifficultyScoreRepository`, `CharacterPreferenceRepository`를 우선 scoped로 만든다. `HighScoreRepository`와 `StatisticsRepository` 전체 계정 분리는 이번 범위에서 제외한다.
- **Cloud progress 계약**: Firestore read/merge는 빌드 안정성을 해치지 않는 범위에서 포함한다. 구현 중 Firebase API/타입 매핑으로 빌드가 흔들리면 local scoped unlock을 우선하고 cloud read/merge는 SELF_CHECK에 보류로 기록한다.
- **제외**: unlock 조건 완화, 캐릭터 추가/삭제, HighScore/Statistics 계정별 전면 migration, 해금 보상 ResultScene 신규 연출 필수화.
- **수용 기준**: 좌/우 rough tap으로 preview 이동, locked 캐릭터는 검정 실루엣, locked 캐릭터로 시작 불가, unlocked 캐릭터만 preference 저장, 계정 A/B unlock이 섞이지 않음, Apple cloud 진행도가 안정적으로 읽히면 scoped local에 max/earliest merge.

### Sprint 4 계약: Remove Midgame Interruptions
- **포함**: mid1/mid2 컷씬 비활성화, `GameConfig.enableMidGameCutscenes` 상수 추가, `triggerMidCutsceneIfNeeded()` 가드.
- **제외**: intro cutscene, countdown, villain warning, 점수/콤보/피격 비차단 피드백 제거.
- **수용 기준**: 30초/15초 부근 mid overlay가 뜨지 않음, 게임이 `.cutscene`으로 멈추지 않음, intro/countdown/result 흐름은 유지.

### Sprint 5 계약: Compact Map And Motion Tuning
- **포함**: runtime compact cell size `28 -> 25`, map size `800 x 500`, 플레이어 runtime 속도 90% multiplier, camera/clamp/spawn/skill waypoint 참조 재확인.
- **제외**: `mapColumns`/`mapRows` 변경, 장애물 패턴 재설계, 적/F 밀도 재밸런싱, 카메라 zoom 도입.
- **수용 기준**: 월드가 기존 `896 x 560`보다 작음, 이동 체감이 살짝 느려짐, 검은 빈 영역 없음, easy/normal/hard 시작/스폰/NPC 이동 정상, 벽 내부 노트/변기 스폰 없음.

### Sprint 6 계약: Hospital Map Readability
- **포함**: 바닥/벽 색 대비 교체, `WallTileNode` 시각 대비 보강, 충돌 없는 병실 props 10개 이하 추가, props는 floor 위/wall 아래 시각 레이어에 배치.
- **제외**: 새 충돌체, 경로/스폰 장애물 추가, 노트/F/적 팔레트 변경, 메뉴 화면 색 재설계.
- **수용 기준**: 장애물과 바닥이 한눈에 구분됨, 병동/병실 분위기가 읽힘, props가 충돌/스폰을 방해하지 않음, 플레이어/노트/F/적이 배경에 묻히지 않음.

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift`: Sprint 1 메인 버튼, 4버튼 레이아웃, 빈 공간 noop, NEW BEST 위치 정리.
- `GanhoMusic/GanhoMusic Shared/Managers/FirebaseAuthManager.swift`: Sprint 2 Apple auth controller retain, timeout task, finish/clear flow 정리.
- `GanhoMusic/GanhoMusic Shared/Errors/AuthError.swift`: Sprint 2 Apple timeout/일반 실패 에러 케이스 추가.
- `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift`: Sprint 2 Apple 실패 메시지 매핑, Sprint 3 cloud sync trigger 또는 CharacterSelect 진입 전 안정화 확인.
- `GanhoMusic/GanhoMusic Shared/Nodes/LoginChoiceOverlayNode.swift`: 필요 시 busy/idle status 표시 보강 확인.
- `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift`: Sprint 3 scoped repositories, unlock state, locked preview/start 차단, rough side tap, cloud sync 후 refresh.
- `GanhoMusic/GanhoMusic Shared/Nodes/CharacterPortraitNode.swift`: Sprint 3 locked silhouette rendering.
- `GanhoMusic/GanhoMusic Shared/Models/CharacterHomeSnapshot.swift`: Sprint 3 unlock state/requirement text를 패널 노드에 전달할 수 있게 확장.
- `GanhoMusic/GanhoMusic Shared/Nodes/AchievementStripNode.swift`: Sprint 3 locked/unlock 진행 표시 문구가 필요하면 snapshot 기반으로 표시.
- `GanhoMusic/GanhoMusic Shared/Nodes/RecordSummaryPanelNode.swift`: Sprint 3 locked 캐릭터 preview 시 기록 패널 표현 확인.
- `GanhoMusic/GanhoMusic Shared/Repositories/GraduationRepository.swift`: Sprint 3 scoped factory, merge/record 보조 메서드.
- `GanhoMusic/GanhoMusic Shared/Repositories/PerDifficultyScoreRepository.swift`: Sprint 3 scoped factory, max merge 메서드.
- `GanhoMusic/GanhoMusic Shared/Repositories/CharacterPreferenceRepository.swift`: Sprint 3 scoped factory, locked preference 보정 호출부 지원.
- `GanhoMusic/GanhoMusic Shared/Repositories/CloudProgressRepository.swift`: Sprint 3 cloud progress summary read 구현 가능 시 추가.
- `GanhoMusic/GanhoMusic Shared/Managers/CloudSaveCoordinator.swift`: Sprint 3 scoped progress snapshot save/optional read merge 조율.
- `GanhoMusic/GanhoMusic Shared/Models/CloudProgressSnapshot.swift`: Sprint 3 Firestore read 결과 typed merge helper 필요 시 추가.
- `GanhoMusic/GanhoMusic Shared/GameScene.swift`: Sprint 3 `perDiffRepo`/`graduationRepo`를 account-scoped 저장소로 초기화.
- `GanhoMusic/GanhoMusic Shared/GameScene+GameState.swift`: Sprint 3 endGame 저장/졸업/cloud progress가 scoped repos를 사용하도록 확인.
- `GanhoMusic/GanhoMusic Shared/GameScene+Cutscene.swift`: Sprint 4 mid cutscene feature flag 가드.
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`: Sprint 1~6 신규 상수와 조정값.
- `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift`: Sprint 5 player speed runtime multiplier 적용.
- `GanhoMusic/GanhoMusic Shared/GameScene+Camera.swift`: Sprint 5 camera clamp가 작은 맵에서 중앙 고정 fallback 유지되는지 확인.
- `GanhoMusic/GanhoMusic Shared/Nodes/MapNode.swift`: Sprint 6 hospital props 부착 진입점 추가.
- `GanhoMusic/GanhoMusic Shared/Nodes/WallTileNode.swift`: Sprint 6 벽 highlight/shadow/outline 대비 보강.
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`: Sprint 6 floor 색 반영 확인, props를 MapNode 안에서 처리하지 않을 경우 setupWorld 연동.
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`: 신규 Swift 파일을 iOS target에 포함해야 할 때만 수정.

### 추가할 파일
- `GanhoMusic/GanhoMusic Shared/Models/AccountProgressScope.swift`: 현재 auth profile에서 UserDefaults key scope suffix를 계산한다.
- `GanhoMusic/GanhoMusic Shared/Models/CharacterUnlockState.swift`: 캐릭터별 unlocked/locked/requirement 표시 모델.
- `GanhoMusic/GanhoMusic Shared/Models/CharacterUnlockRules.swift`: 순차 해금 규칙과 previous/next character 계산.
- `GanhoMusic/GanhoMusic Shared/Nodes/HospitalPropNode.swift`: 충돌 없는 병실 bed/curtain/cabinet/cart visual node.

## 기능 상세

### 기능 1: Sprint 1 결과 화면 명시 네비게이션
- 설명: 결과 화면은 버튼만 화면 전환을 담당한다. 빈 공간 탭은 아무 일도 하지 않고, `메인으로` 보조 버튼이 StartScene 전환을 담당한다.
- 구현 위치: `ResultScene.swift` `MARK: - Properties`, `MARK: - Setup`, `layoutButtons()`, `touchesBegan`
- 핵심 코드 구조:
  ```swift
  private var mainButton: GlassPillNode?

  private func setupMainButton() {
      let pill = GlassPillNode(
          text: GameConfig.resultMainButtonText,
          size: CGSize(
              width: GameConfig.resultMainButtonWidth,
              height: GameConfig.resultShareButtonHeightV2
          )
      )
      pill.name = "mainButton"
      mainButton = pill
      addChild(pill)
  }

  private func layoutButtons() {
      let scale = resultButtonScale()
      scoreboardButton?.setScale(scale)
      shareButton?.setScale(scale)
      restartButton.setScale(scale)
      mainButton?.setScale(scale)

      // [기록 보기] [공유/자랑하기] [다시 시작] [메인으로]
      // total width에는 4개 폭과 gap 3개를 포함한다.
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      guard !isTransitioning else { return }
      if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
      guard let view = self.view, let touch = touches.first else { return }
      let location = touch.location(in: self)

      if let pill = shareButton, pill.contains(location) { presentShareSheet(); return }
      guard !isShareSheetPresenting else { return }
      if restartButton.contains(location) { transitionToRetryGame(in: view); return }
      if let pill = scoreboardButton, pill.contains(location) { transitionToScoreboard(in: view); return }
      if let pill = mainButton, pill.contains(location) { transitionToStart(in: view); return }

      return
  }
  ```
- 세부 지시:
  - 기존 scoreboard 전환 코드는 `transitionToScoreboard(in:)`로 추출해 `touchesBegan`을 짧게 유지한다.
  - 기존 마지막 fallback StartScene 전환은 삭제한다.
  - `resultButtonTotalWidth(scale:)`는 `mainButtonWidth`와 gap 3개를 반영한다.
  - `newBestLabel`은 노드 트리에는 붙이지 않는 현재 정책을 유지하되, 중복 문구가 필요하면 `bestPill` 중심으로 보상 정보를 집중한다. 별도 중앙 라벨을 다시 addChild하지 않는다.

### 기능 2: Sprint 2 Apple 로그인 실패 복구
- 설명: Apple 로그인 성공/취소/실패/timeout 어느 경우에도 continuation이 끝나고 overlay busy가 해제되어야 한다.
- 구현 위치: `FirebaseAuthManager.swift`, `AuthError.swift`, `StartScene.swift`, `GameConfig.swift`
- 핵심 코드 구조:
  ```swift
  enum AccountActionResult {
      case success
      case cancelled
      case failure(AuthError?)
  }

  private var appleAuthorizationController: ASAuthorizationController?
  private var appleTimeoutTask: Task<Void, Never>?

  private func performAppleAuthorization(
      request: ASAuthorizationAppleIDRequest,
      anchor: ASPresentationAnchor
  ) async throws -> AppleAuthorizationPayload {
      try await withCheckedThrowingContinuation { continuation in
          guard appleContinuation == nil else {
              continuation.resume(throwing: AuthError.appleAuthorizationAlreadyInProgress)
              return
          }
          appleContinuation = continuation
          let provider = ApplePresentationContextProvider(anchor: anchor)
          applePresentationProvider = provider
          let controller = ASAuthorizationController(authorizationRequests: [request])
          appleAuthorizationController = controller
          controller.delegate = self
          controller.presentationContextProvider = provider
          startAppleAuthorizationTimeout()
          controller.performRequests()
      }
  }

  private func finishAppleAuthorization(with result: Result<AppleAuthorizationPayload, Error>) {
      guard let continuation = appleContinuation else { return }
      appleContinuation = nil
      appleTimeoutTask?.cancel()
      appleTimeoutTask = nil
      appleAuthorizationController = nil
      applePresentationProvider = nil
      continuation.resume(with: result)
  }
  ```
- 세부 지시:
  - `GameConfig.authAppleRequestTimeout`은 `12.0`초로 둔다.
  - timeout task는 `[weak self]`를 사용하고 MainActor에서 `finishAppleAuthorization(.failure(AuthError.appleAuthorizationTimedOut))`를 호출한다.
  - `clearAppleFlowState()`는 nonce, continuation, provider, controller, timeout task를 모두 정리한다.
  - `signInWithApple` catch는 취소/timeout/일반 실패를 구분해 `AccountActionResult`로 반환한다.
  - `StartScene.handleAppleStartTap()`는 `defer` 성격으로 `isLoginRequestInFlight = false`를 보장하고, `.failure(.appleAuthorizationTimedOut)`은 `GameConfig.loginChoiceAppleTimeoutText`, 나머지는 `GameConfig.loginChoiceFailureText`를 표시한다.
  - `view?.window`가 nil이면 busy 진입 전에 overlay idle 상태로 실패 메시지만 표시한다.

### 기능 3: Sprint 3 계정별 순차 해금과 rough selection
- 설명: 현재 계정의 졸업 기록으로 캐릭터 해금을 계산한다. 잠긴 캐릭터도 preview는 가능하지만 preference 저장과 게임 시작은 unlocked 캐릭터만 가능하다.
- 구현 위치: `AccountProgressScope.swift`, `CharacterUnlockState.swift`, `CharacterUnlockRules.swift`, `CharacterSelectScene.swift`, `CharacterPortraitNode.swift`, scoped repositories, `GameScene.swift`
- 핵심 코드 구조:
  ```swift
  struct AccountProgressScope {
      let uid: String
      let isAnonymous: Bool

      var storageSuffix: String {
          return isAnonymous ? "guest.\(uid)" : "user.\(uid)"
      }
  }

  enum AccountProgressScopeProvider {
      static func current(authProfile: AuthProfileSnapshot?) -> AccountProgressScope {
          guard let profile = authProfile, !profile.uid.isEmpty else {
              return AccountProgressScope(uid: "local", isAnonymous: true)
          }
          return AccountProgressScope(uid: profile.uid, isAnonymous: profile.isAnonymous)
      }
  }

  enum CharacterUnlockRules {
      static func previousCharacter(for id: CharacterID) -> CharacterID? { ... }

      static func isUnlocked(_ id: CharacterID, graduations: [CharacterID: Date]) -> Bool {
          guard let previous = previousCharacter(for: id) else { return true }
          return graduations[previous] != nil
      }
  }
  ```
- Repository 지시:
  ```swift
  extension GraduationRepository {
      static func scoped(scope: AccountProgressScope,
                         defaults: UserDefaults = .standard) -> GraduationRepository {
          return GraduationRepository(
              defaults: defaults,
              key: "\(GameConfig.graduationUserDefaultsKey).\(scope.storageSuffix)"
          )
      }
  }
  ```
  - 같은 패턴을 `PerDifficultyScoreRepository`, `CharacterPreferenceRepository`에 적용한다.
  - 기존 기본 init은 유지해 다른 호출부 컴파일을 깨지 않는다.
  - Apple scope에는 기존 전역 진행도를 자동 복사하지 않는다.
  - local fallback은 필요 시 기존 global key 보존을 우선하고, guest/user scope는 suffix key를 사용한다.
- `GameScene` 지시:
  ```swift
  let accountScope: AccountProgressScope
  let perDiffRepo: PerDifficultyScoreRepository
  let graduationRepo: GraduationRepository

  init(size: CGSize, characterID: CharacterID, difficulty: Difficulty) {
      self.characterID = characterID
      self.difficulty = difficulty
      let scope = AccountProgressScopeProvider.current(
          authProfile: AuthProfileRepository().current
      )
      self.accountScope = scope
      self.perDiffRepo = PerDifficultyScoreRepository.scoped(scope: scope)
      self.graduationRepo = GraduationRepository.scoped(scope: scope)
      super.init(size: size)
  }
  ```
- `CharacterSelectScene` 지시:
  ```swift
  private var accountScope = AccountProgressScopeProvider.current(authProfile: nil)
  private var perDifficultyScoreRepo = PerDifficultyScoreRepository()
  private var graduationRepo = GraduationRepository()
  private var preferenceRepo = CharacterPreferenceRepository()

  private var unlockStates: [CharacterID: CharacterUnlockState] = [:]

  private var isSelectedCharacterUnlocked: Bool {
      return unlockStates[selectedCharacterID]?.isUnlocked ?? false
  }

  private func configureScopedRepositories() {
      let scope = AccountProgressScopeProvider.current(authProfile: authProfileRepo.current)
      accountScope = scope
      perDifficultyScoreRepo = .scoped(scope: scope)
      graduationRepo = .scoped(scope: scope)
      preferenceRepo = .scoped(scope: scope)
      rebuildUnlockStates()
  }
  ```
  - `didMove(to:)`에서 `configureScopedRepositories()`를 먼저 호출한 뒤 saved preference를 읽는다.
  - saved preference가 locked면 첫 unlocked 캐릭터로 보정하고 scoped preference에 저장한다.
  - `selectCharacter(at:animated:)`는 locked preview 이동을 허용하지만 unlocked일 때만 preference를 저장한다.
  - `transitionToNext()`는 `guard isSelectedCharacterUnlocked else { showLockedStartFeedback(); return }`로 차단한다.
  - `touchesBegan` 순서는 back → home menu → rail/arrow → start button → rough side zone 순서로 유지한다.
  - `handleRoughCharacterSideTap(at:)`는 `characterStageFrame` 좌/우 35%를 1차 hit zone으로 쓰고, UI 버튼 hit-test 이후에만 실행한다.
- `CharacterPortraitNode` 지시:
  ```swift
  func update(characterID: CharacterID, isLocked: Bool) {
      update(characterID: characterID)
      setLocked(isLocked)
  }

  func setLocked(_ locked: Bool) {
      sprite.color = locked ? .black : .clear
      sprite.colorBlendFactor = locked ? 1.0 : 0.0
      sprite.alpha = locked ? GameConfig.characterHomeLockedPortraitAlpha : 1.0
  }
  ```
- Cloud read/merge 지시:
  - `CloudProgressRepository.fetchProgress(uid:) async throws -> CloudProgressSnapshot?`를 추가할 수 있다.
  - `CloudSaveCoordinator.syncProgressForCurrentUser() async -> CloudProgressSyncResult`를 추가할 수 있다.
  - merge 정책은 per difficulty score는 max, graduation date는 더 이른 날짜 우선이다.
  - `HighScoreRepository`와 `StatisticsRepository`는 이번 Sprint에서 scoped merge하지 않는다.
  - sync 실패는 UI를 막지 않고 local scoped cache로 계속 진행한다.

### 기능 4: Sprint 4 중간 차단 컷씬 제거
- 설명: 인트로/카운트다운은 유지하고, 플레이 중 30초/15초 부근의 mid1/mid2만 끈다.
- 구현 위치: `GameConfig.swift`, `GameScene+Cutscene.swift`
- 핵심 코드 구조:
  ```swift
  static let enableMidGameCutscenes: Bool = false

  func triggerMidCutsceneIfNeeded() -> Bool {
      guard GameConfig.enableMidGameCutscenes else { return false }
      // 기존 mid1/mid2 로직 유지
  }
  ```
- 세부 지시:
  - `GameScene.update` 호출부는 그대로 둬도 된다. 가드가 false를 반환하면 플레이 흐름이 멈추지 않는다.
  - `MidCutsceneNode`, `CutsceneTexts`는 삭제하지 않는다.
  - 주석은 mid cutscene이 feature flag로 비활성화된 상태임을 반영한다.

### 기능 5: Sprint 5 compact map과 플레이어 속도 튜닝
- 설명: runtime map을 `32 x 20 x 25pt`로 줄이고 플레이어 속도에 0.9 multiplier를 적용한다.
- 구현 위치: `GameConfig.swift`, `PlayerNode.swift`, 확인 대상 `GameScene+Camera.swift`, `SpawnSystem.swift`, `SkillSystem.swift`
- 핵심 코드 구조:
  ```swift
  static let compactMapCellSize: CGFloat = 25.0
  static let playerSpeedRuntimeMultiplier: CGFloat = 0.9

  func apply(_ difficulty: Difficulty) {
      let start = GameConfig.playerSpeedStartByDifficulty[difficulty] ?? GameConfig.playerBaseSpeed
      let end = GameConfig.playerSpeedEndByDifficulty[difficulty] ?? GameConfig.playerBaseSpeed
      baseSpeedStart = start * GameConfig.playerSpeedRuntimeMultiplier
      baseSpeedEnd = end * GameConfig.playerSpeedRuntimeMultiplier
  }
  ```
- 세부 지시:
  - `mapColumns`와 `mapRows`는 변경하지 않는다.
  - `mapWidth` 주석은 `25 x 32 = 800`, `mapHeight` 주석은 `25 x 20 = 500`으로 갱신한다.
  - `GameScene+Camera.updateCameraFollow()`의 `upper < lower` 중앙 고정 fallback은 유지한다.
  - `SpawnSystem.randomOpenMapPosition`, `SkillSystem` teleport/dash clamp, enemy/professor/stoneGuard waypoints는 모두 `GameConfig.mapWidth/mapHeight/tileSize/scaledMapPoint/cellPoint` 기반이어야 한다.
  - 원본 속도 dict 값은 보존하고 runtime multiplier만 적용한다.

### 기능 6: Sprint 6 병실 맵 가독성
- 설명: 바닥/벽 대비를 높이고, 충돌 없는 병실 소품을 맵 외곽에 배치해 장소감을 만든다.
- 구현 위치: `GameConfig.swift`, `WallTileNode.swift`, `HospitalPropNode.swift`, `MapNode.swift`, `GameScene+Setup.swift`
- 핵심 코드 구조:
  ```swift
  static let ingameFloorAHex: String = "#E7F0F2"
  static let ingameFloorBHex: String = "#D4E2E6"
  static let ingameWallFillHex: String = "#2F5D68"
  static let ingameWallHighlightHex: String = "#6FA8A7"
  static let ingameWallShadowHex: String = "#17343C"

  enum HospitalPropKind {
      case bed
      case curtain
      case cabinet
      case cart
  }

  final class HospitalPropNode: SKNode {
      init(kind: HospitalPropKind, size: CGSize) {
          super.init()
          name = "hospitalProp"
          zPosition = GameConfig.hospitalPropZPosition
          // SKShapeNode/SKSpriteNode 조합으로 visual-only 구성
          // physicsBody는 절대 설정하지 않는다.
      }
  }
  ```
- `MapNode` 지시:
  ```swift
  func buildWalls(difficulty: Difficulty) {
      buildOuterWall()
      switch difficulty { ... }
      buildExtraObstacles(difficulty: difficulty)
      attachHospitalProps()
  }

  private func attachHospitalProps() {
      let placements: [(HospitalPropKind, CGPoint, CGSize)] = [
          (.bed, GameConfig.tileCenter(col: 4, row: 16), GameConfig.hospitalBedSize),
          (.curtain, GameConfig.tileCenter(col: 7, row: 16), GameConfig.hospitalCurtainSize)
      ]
      for placement in placements {
          let prop = HospitalPropNode(kind: placement.0, size: placement.2)
          prop.position = placement.1
          addChild(prop)
      }
  }
  ```
- 세부 지시:
  - props는 10개 이하로 시작한다.
  - props는 `physicsBody = nil`, wall/category/contact/collision 설정 없음.
  - props zPosition은 MapNode 자식 기준 wall tile보다 낮게, floor보다 높게 둔다.
  - props 위치는 외곽 1~2타일 근처로 두고 player start, main corridor, enemy/professor/stoneGuard 주요 waypoint를 피한다.
  - `WallTileNode.physicsBody`와 category/collision 정책은 변경하지 않는다.

## 주의사항
- 강제 언래핑(`!`) 설계/구현 금지. 모든 optional은 `guard let` 또는 `if let`로 처리한다.
- 게임 내 지연/반복은 `Timer`/`DispatchQueue.main.asyncAfter`가 아니라 `SKAction.wait`를 사용한다. 단, Sprint 2 인증 timeout은 SpriteKit 게임 루프가 아닌 manager 영역이므로 Swift concurrency `Task` 사용을 허용한다.
- 매직 넘버는 `GameConfig` 상수로 분리한다. 특히 timeout, rough tap ratio, locked alpha, map cell size, speed multiplier, hospital prop size/zPosition/text는 직접 하드코딩하지 않는다.
- SpriteKit 초기화는 `didMove(to:)` 또는 기존 setup 메서드에서 수행한다. `update()` 안에서 새 노드를 반복 생성하지 않는다.
- 물리 카테고리는 기존 `PhysicsCategory` 비트마스크를 유지한다. Sprint 6 hospital props에는 physicsBody를 붙이지 않는다.
- `ResultScene`에서 share sheet 표시 중에는 기존처럼 다른 전환을 차단한다.
- `FirebaseAuthManager.finishAppleAuthorization`은 continuation을 지역 상수로 뽑고 즉시 nil 처리한 뒤 resume해 이중 resume을 막는다.
- `CharacterSelectScene`에서 locked preview는 가능하지만 locked 상태로 `preferenceRepo.save`나 `DifficultySelectScene`/`SkillExplanationScene` 전환을 하면 안 된다.
- `HighScoreRepository`와 `StatisticsRepository`는 이번 범위에서 전역 유지한다. scoped unlock 구현을 위해 이 둘을 전면 변경하지 않는다.
- Cloud read/merge가 빌드 안정성을 위협하면 로컬 scoped unlock을 우선한다. 이 경우 `SELF_CHECK.md`에 cloud read/merge 보류 사유를 명시한다.
- 신규 Swift 파일을 만들면 `GanhoMusic.xcodeproj`의 iOS target 빌드 파일에 포함되었는지 확인한다.
- tvOS/macOS 템플릿 잔여물은 수정하지 않는다.
- 검증 명령:
  ```bash
  xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -configuration Debug build
  ```
