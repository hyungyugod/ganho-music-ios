# SPEC.md — Phase 6-15: 뉴베스트 폴리싱 (NEW BEST! 결과 화면 영광)

## 개요
ResultScene 진입 시점에 이번 판 점수가 기존 최고 기록을 초과했을 때, 화면 중앙 "NEW BEST!" 큰 황금 라벨 + heavy 햅틱 + NewMail 사운드 + 기존 bestLabel의 황금 깜빡임으로 *결과의 영광*을 3감각 멀티모달로 마감한다. Phase 6-13(시작 카운트다운) ↔ Phase 6-14(끝 긴박감)의 시작/끝 대칭에 이어, *판 결과*의 클라이맥스를 채운다.

## 변경 유형
**혼합** (시각 + 청각 + 촉각 + 결과 화면 임팩트)

## 게임 경험 의도
지금까지 신기록일 때 ResultScene은 `★ NEW BEST! ★` 텍스트로만 바뀌었다 — *조용한 갱신*. 6-15는 그 갱신을 *축포*로 바꾼다: 화면 중앙 큰 황금 라벨 등장 + heavy 햅틱(도달의 무게) + NewMail 사운드(긍정·묵직) + 기존 bestLabel 황금 깜빡임. 자전적 톤에서 *작곡 끝낸 새벽에 곡이 완성됐다는 자각의 순간*과 동형 — 한 판 끝에 *내가 새 기록을 세웠다*는 사실이 시각/청각/촉각으로 동시 통보된다.

## Sprint 범위 계약
- **허용**:
  - `ResultScene.swift` 내부에 `newBestLabel: SKLabelNode` 1개 신설 (옵션 B — 신규 파일 0건 정책)
  - `ResultScene.didMove` 진입 후 `isNewBest == true` 일 때만 발화하는 시퀀스 (시각 + 햅틱 + 사운드 + 기존 bestLabel 황금 전환)
  - `GameConfig.swift`에 NewBest 관련 상수 10개 신설 (`MARK: - New Best (Phase 6-15)` 섹션)
  - `ResultScene`이 `HapticsManager` / `AudioManager` 인스턴스 1개씩 신규 보유 (stored property)
  - `GameScene.endGame()`의 ResultScene 생성 인자 변경 0건 (`isNewBest` 이미 주입 중)
- **금지**:
  - 신규 노드 파일 신설 (NewBestNode 등 — 옵션 A 기각)
  - 신규 SFX 케이스 추가 (`AudioManager.SFX`에 `.newBest` 신설 금지 — `.comboMilestoneStrong` 재사용)
  - 신규 ColorTokens 추가 (`.ganhoYellowF` 재사용)
  - `HighScoreRepository.swift` API 변경 (현행 `record(_:) -> Bool` 그대로 활용 — 이미 신기록 신호 반환 중)
  - `GameScene.swift` / `TitleScene.swift` / `Models/*` / `Protocols/*` / 자가 소멸 노드 8개 / `HUDNode` / `Systems/*` 미접촉
  - `ResultScene.bestLabel.text` 분기 로직 변경 (현행 `isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"` 그대로 — 추가 시각만 얹음)
  - Timer / DispatchQueue.main.asyncAfter 사용 (Swift 규칙 9) — 지연은 SKAction.wait 패턴
- **판단 기준**: "이 변경이 없으면 NEW BEST 폴리싱이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지

## 핵심 결정 사항

### 1. 뉴베스트 감지 — 위치 결정
**결정: 기존 흐름 유지**. `GameScene.endGame()`에서 이미 `highScoreRepo.record(score)`가 `Bool`을 반환하고 그 값이 `isNewBest`로 `ResultScene`에 init 주입되고 있다. `ResultScene`은 새 비교 로직 0건 — `self.isNewBest` 프로퍼티만 보고 분기한다.
- 회귀 0: `HighScoreRepository.record(_:) -> Bool` API 미접촉
- 회귀 0: `GameScene.endGame()`의 record/current 4줄 미접촉
- ResultScene 책임은 *진입 시점 표현*에만 한정 (단일 책임)

### 2. 라벨 구조 — 옵션 B 채택
**결정: ResultScene 내부 라벨 (옵션 B)**.
- 신규 파일 0건 (Phase 6-14의 *가장 작은 sprint* 정책 답습)
- `NewBestNode`(옵션 A) 기각 이유: CountdownNode/ComboBreakNode는 *재사용 가능한 일반 위젯*이었지만 NewBest는 ResultScene *전용 1회 표현* — 별도 노드로 추출할 재사용성 없음
- 새 라벨 `newBestLabel: SKLabelNode`을 ResultScene stored property로 1개 추가, `isNewBest`일 때만 `addChild` + 애니메이션 발화

### 3. 시각 표현
- **텍스트**: `"NEW BEST!"` (영어, 기존 `★ NEW BEST! ★`와 동형 — 단 별 기호 제거 + 폰트 자체로 임팩트)
- **색**: `.ganhoYellowF` (황금 — `ComboPopupNode.color(for: 10)` 황금기와 동일 톤. Phase 6-10 색 어휘 재사용)
- **폰트 크기**: `GameConfig.newBestFontSize = 56` (resultTitleFontSize=32, resultScoreFontSize=24보다 큼 — 화면 중앙 단독 강조. countdownFontSize=96보단 작음 — ResultScene은 정적 표시이므로 카운트다운만큼 강조 불필요)
- **위치**: `frame.midY + GameConfig.newBestOffsetY = 0` — 화면 정중앙. 기존 5개 라벨(+115/+80/+40/0/-40/-80) 중 `bestLabel(0)`과 겹치는 좌표지만 zPosition을 높여 위에 띄움 + fade-in으로 등장 → bestLabel은 그대로 보이고 NewBest!가 그 위에 겹치며 영광 강조
- **zPosition**: `GameConfig.newBestZPosition = 150` (comboPopupZPosition=150과 동급 — ResultScene 라벨들의 기본 z=0 위)
- **애니메이션**: fade-in (alpha 0→1, 0.3s) + scale pulse (1.0→1.2→1.0, 0.8s) — 정적 표시(영구 노출), 자가 소멸 없음 (탭으로 TitleScene 복귀 시 씬 해제로 자동 정리)

### 4. 사운드/햅틱 채널 결정
- **햅틱**: `haptics.heavy()` 1회. 게임오버(endGame)도 heavy지만 이미 *씬 전환 시점*에 다른 씬에서 발화됨 → ResultScene 진입 시점은 *새 씬*에서 새 헵틱 인스턴스로 발화하므로 톤 충돌 없음. heavy = 도달의 무게감 정확.
- **사운드**: `audio.play(.comboMilestoneStrong)` — NewMail 1025 ID. 6-11(콤보 x20) / 6-13(GO!) 재사용. *긍정·묵직* 톤이 영광에 정확. 신규 SFX 케이스 0건 (Sprint 범위 최소화).
- **타이밍**: 햅틱 → 사운드 순서 (`onNoteCollected` 6-8 패턴 답습)

### 5. 기존 bestLabel 황금 전환
- `bestLabel`은 ResultScene에 이미 존재 (`init` 5개 라벨 중 1개)
- 신기록일 때 현재 `text = "★ NEW BEST! ★"`로 분기되어 있음 → 여기에 *황금 색 전환 + 깜빡임* 추가
- 구현: `isNewBest` 분기 안에서 `bestLabel.fontColor = .ganhoYellowF` 즉시 변경 + `SKAction.sequence([fadeAlpha, fadeAlpha])`을 `repeatForever`로 부착. `withKey: "newBestBlink"` — 멱등 + cleanup 필요 시 키로 제거 가능 (단 ResultScene은 한 판 1회만 표시되므로 cleanup 불필요)
- 깜빡임은 alpha만 변경 (1.0 ↔ `GameConfig.newBestBlinkMinAlpha = 0.5`) — 색은 황금 고정 유지. Phase 6-14 HUD `tensionBlink` 패턴(fontColor 직접 교체) 답습 변형
- 한 색 머무는 시간: `GameConfig.newBestBlinkHalfPeriod = 0.5` (6-14 `tensionBlinkHalfPeriod`와 동일 — 시간축 대칭)

### 6. 회귀 0 영역 (Phase 6-14까지의 자산 미접촉 보장)
다음 영역은 본 sprint에서 1줄도 건드리지 않는다:
- `GameScene.swift` (endGame은 인자 변경 0건 — ResultScene 생성 시그니처 그대로)
- `HighScoreRepository.swift` API
- `StatisticsRepository.swift`, `CharacterPreferenceRepository.swift`
- `Models/GameStats.swift`, `Models/CharacterID.swift`
- `Protocols/SelfDismissingNode.swift`
- 자가 소멸 노드 8개 (Airplane/AirforceOverlay/BombFlash/Sparkle/HitFlash/ComboPopup/ComboBreak/Countdown)
- `TitleScene.swift` (BEST 표시는 그대로 — ResultScene 전용 폴리싱)
- `Managers/AudioManager.swift` API (`.comboMilestoneStrong` 재사용으로 SFX enum 미변경)
- `Managers/HapticsManager.swift` API (`heavy()` 재사용)
- `Managers/BGMPlayer.swift` (BGM은 endGame에서 이미 fadeOut 중)
- `Systems/*` 4개 파일
- Phase 6-14 tension 로직 (`tensionStarted`, `tensionWindow`, BGM rate 보간)
- Phase 6-13 카운트다운 로직 (`CountdownNode`, `gameState .countdown`, `startGameProperly`)
- `HUDNode.swift` (`startTensionBlink`/`stopTensionBlink` 그대로)
- `ColorTokens.swift` (`.ganhoYellowF` 재사용)
- `Config/PhysicsCategory.swift`, `Config/GameState.swift`
- `GameScene+Setup.swift`

### 7. 타이밍 — 지연 발화
**결정: scoreLabel 표시 후 0.3초 지연 후 발화** (드라마틱 타이밍).
- 이유: ResultScene fade transition(0.4s)이 끝나고 사용자가 *score 라벨을 인지한 후* "NEW BEST!"가 등장해야 임팩트. 즉시 발화 시 fade와 겹쳐 흐릿함.
- 구현: `didMove(to:) → setupLabels()` 끝에서 `isNewBest`이면 `run(SKAction.sequence([wait(0.3), run { showNewBestSequence() }]))` (씬 자체에 SKAction 부착 — `SKScene`도 SKNode이므로 가능). `Timer` / `DispatchQueue.main.asyncAfter` 사용 금지 (Swift 패턴 9 위반).
- `GameConfig.newBestRevealDelay: TimeInterval = 0.3`

## 변경 범위

### 수정할 파일
- **`GanhoMusic Shared/Scenes/ResultScene.swift`** (+약 60줄):
  - 헤더 주석에 Phase 6-15 줄 1개 추가
  - `private let newBestLabel = SKLabelNode(text: "NEW BEST!")` stored property 추가
  - `private let haptics = HapticsManager()` + `private let audio = AudioManager()` 2개 추가
  - `setupLabels()` 끝에서 `if isNewBest { configureNewBestLabel(); scheduleNewBestReveal() }` 분기 1개
  - `private func configureNewBestLabel()` 메서드 신설 — newBestLabel 스타일 설정 (font/color/position/alpha=0)
  - `private func scheduleNewBestReveal()` 메서드 신설 — `SKAction.sequence([wait, run])` 부착
  - `private func revealNewBest()` 메서드 신설 — fade-in/scale pulse 액션 + haptics.heavy() + audio.play(.comboMilestoneStrong) + bestLabel 황금 전환 + 깜빡임 시작
  - `private func startBestLabelGoldBlink()` 메서드 신설
  - `layoutLabels()`에 newBestLabel 위치 1줄 추가
- **`GanhoMusic Shared/Config/GameConfig.swift`** (+약 12줄):
  - `// MARK: - New Best (Phase 6-15)` 섹션 신설, 상수 10개

### 추가할 파일
**없음** (Phase 6-14의 신규 파일 0건 정책 답습).

## 기능 상세

### 기능 1: NewBest 라벨 등장 (시각 1채널)
- 설명: ResultScene 진입 후 0.3초 지연 → 화면 정중앙에 "NEW BEST!" 황금 라벨이 fade-in (alpha 0→1, 0.3s) + scale pulse (1.0→1.2→1.0, 0.8s).
- 구현 위치: `ResultScene.swift` `// MARK: - New Best (Phase 6-15)` 새 섹션
- 핵심 코드 구조:
  ```swift
  // MARK: - New Best (Phase 6-15)

  /// 신기록 진입 시점에만 발화. setupLabels() 끝에서 isNewBest 분기로 호출됨.
  /// 라벨 스타일(font/color/alpha=0)을 미리 설정만 하고, 등장은 scheduleNewBestReveal이 담당.
  private func configureNewBestLabel() {
      newBestLabel.fontSize = GameConfig.newBestFontSize
      newBestLabel.fontColor = .ganhoYellowF      // 황금 — ComboPopup x10 황금기와 동일 톤
      newBestLabel.horizontalAlignmentMode = .center
      newBestLabel.verticalAlignmentMode = .center
      newBestLabel.alpha = 0                      // fade-in 시작점
      newBestLabel.zPosition = GameConfig.newBestZPosition  // bestLabel 위로 겹침
      newBestLabel.position = CGPoint(
          x: frame.midX,
          y: frame.midY + GameConfig.newBestOffsetY
      )
      addChild(newBestLabel)
  }

  /// SKScene 자체에 SKAction 부착 — Timer/DispatchQueue 사용 금지(Swift 규칙 9).
  /// [weak self] 캡처 — 씬 해제 가능성 대비.
  private func scheduleNewBestReveal() {
      let wait = SKAction.wait(forDuration: GameConfig.newBestRevealDelay)
      let reveal = SKAction.run { [weak self] in
          self?.revealNewBest()
      }
      run(.sequence([wait, reveal]))
  }
  ```

### 기능 2: heavy 햅틱 + NewMail 사운드 + 시각 발화 (3채널 동시)
- 설명: revealNewBest() 진입 즉시 햅틱→사운드 발화 (`onNoteCollected` 순서 답습), 동시에 fade-in + scale pulse.
- 구현 위치: `ResultScene.swift` `revealNewBest()` 메서드
- 핵심 코드 구조:
  ```swift
  /// 0.3초 지연 후 호출. 시각 등장 + 햅틱 + 사운드 + bestLabel 황금 전환을 한 묶음으로 발화.
  /// 자가 소멸 노드와 달리 newBestLabel은 ResultScene 자체와 함께 정리됨 — 씬 해제 시 ARC가 처리.
  private func revealNewBest() {
      // 1) 촉각: heavy = 도달의 무게감. ResultScene 새 인스턴스라 endGame heavy와 톤 충돌 없음.
      haptics.heavy()
      // 2) 청각: NewMail 1025 — 긍정·묵직. 6-11/6-13 재사용으로 신규 SFX 0건.
      audio.play(.comboMilestoneStrong)
      // 3) 시각: fade-in + scale pulse. group으로 동시 실행.
      let fadeIn = SKAction.fadeIn(withDuration: GameConfig.newBestFadeInDuration)
      let scaleUp = SKAction.scale(to: GameConfig.newBestEndScalePeak,
                                    duration: GameConfig.newBestScalePulseDuration / 2)
      let scaleDown = SKAction.scale(to: 1.0,
                                      duration: GameConfig.newBestScalePulseDuration / 2)
      let pulse = SKAction.sequence([scaleUp, scaleDown])
      newBestLabel.run(SKAction.group([fadeIn, pulse]))
      // 4) bestLabel 황금 전환 + 깜빡임 시작
      startBestLabelGoldBlink()
  }
  ```

### 기능 3: 기존 bestLabel 황금 깜빡임 (시각 보조 채널)
- 설명: bestLabel을 황금 색으로 즉시 전환 + alpha 1.0↔0.5 깜빡임 무한 반복. Phase 6-14 `tensionBlink` 패턴 답습.
- 구현 위치: `ResultScene.swift` `startBestLabelGoldBlink()` 신설
- 핵심 코드 구조:
  ```swift
  /// bestLabel을 황금으로 전환 + alpha 깜빡임 무한 반복.
  /// withKey 패턴(6-14 tensionBlink 답습) — 같은 키 재호출 시 자동 교체로 자연 멱등.
  /// 씬 해제 시 ARC가 액션 정리하므로 명시적 stop 불필요.
  private func startBestLabelGoldBlink() {
      bestLabel.fontColor = .ganhoYellowF   // 황금 색 즉시 전환
      let fadeOut = SKAction.fadeAlpha(to: GameConfig.newBestBlinkMinAlpha,
                                        duration: GameConfig.newBestBlinkHalfPeriod)
      let fadeIn  = SKAction.fadeAlpha(to: 1.0,
                                        duration: GameConfig.newBestBlinkHalfPeriod)
      let cycle = SKAction.sequence([fadeOut, fadeIn])
      bestLabel.run(.repeatForever(cycle), withKey: GameConfig.newBestBlinkActionKey)
  }
  ```

### 기능 4: setupLabels 분기 + Managers 보유
- 설명: ResultScene에 HapticsManager / AudioManager 인스턴스 1개씩 stored property로 보유. setupLabels() 끝에서 `isNewBest`일 때만 NewBest 시퀀스 시작.
- 구현 위치: `ResultScene.swift` Properties 섹션 + setupLabels() 끝부분
- 핵심 코드 구조:
  ```swift
  // MARK: - Properties (기존 섹션 마지막에 추가)
  private let haptics = HapticsManager()   // Phase 6-15 — 신기록 heavy 발화
  private let audio = AudioManager()       // Phase 6-15 — NewMail 사운드 발화
  private let newBestLabel = SKLabelNode(text: "NEW BEST!")   // Phase 6-15

  // MARK: - Setup (기존 setupLabels 마지막에 분기 추가)
  private func setupLabels() {
      // ... 기존 라벨 6개 setup 그대로 ...
      addChild(promptLabel)
      layoutLabels()
      // Phase 6-15 — 신기록일 때만 NewBest 시퀀스 시작.
      if isNewBest {
          configureNewBestLabel()
          scheduleNewBestReveal()
      }
  }
  ```

### 기능 5: layoutLabels 확장
- 설명: `didChangeSize` 시 newBestLabel 위치도 재계산. 단 newBestLabel은 isNewBest일 때만 addChild되므로 parent 검사 후 위치 갱신.
- 구현 위치: `ResultScene.swift` `layoutLabels()`
- 핵심 코드 구조:
  ```swift
  private func layoutLabels() {
      // ... 기존 6개 라벨 position 6줄 그대로 ...
      // Phase 6-15 — newBestLabel은 isNewBest일 때만 부착됨. 부착 여부 무관하게 위치 set 안전(SKNode 기본 동작).
      newBestLabel.position = CGPoint(
          x: frame.midX,
          y: frame.midY + GameConfig.newBestOffsetY
      )
  }
  ```

### 기능 6: GameConfig 상수 10개
- 구현 위치: `Config/GameConfig.swift` 끝부분
- 핵심 코드 구조:
  ```swift
  // MARK: - New Best (Phase 6-15)
  /// 화면 중앙 "NEW BEST!" 폰트 크기 (pt). resultScoreFontSize(24)보다 큼, countdownFontSize(96)보단 작음.
  static let newBestFontSize: CGFloat = 56
  /// frame.midY 기준 NewBest! 라벨 Y 오프셋. 0 = 정중앙. bestLabel과 같은 y지만 zPosition으로 위에 겹침.
  static let newBestOffsetY: CGFloat = 0
  /// NewBest! 라벨 zPosition. comboPopupZPosition(150)과 동급 — ResultScene 기본 z=0 위.
  static let newBestZPosition: CGFloat = 150
  /// ResultScene 진입 후 NewBest! 발화까지 지연 (초). fade transition(0.4s) 끝나고 score 인지 후 등장.
  static let newBestRevealDelay: TimeInterval = 0.3
  /// NewBest! fade-in 길이 (초).
  static let newBestFadeInDuration: TimeInterval = 0.3
  /// NewBest! scale pulse 한 사이클 총 길이 (초). up(0.4) + down(0.4) = 0.8.
  static let newBestScalePulseDuration: TimeInterval = 0.8
  /// NewBest! scale pulse 정점 스케일 (1.0 → 1.2 → 1.0).
  static let newBestEndScalePeak: CGFloat = 1.2
  /// bestLabel 황금 깜빡임 최소 alpha. 1.0 ↔ 0.5 사이 보간.
  static let newBestBlinkMinAlpha: CGFloat = 0.5
  /// bestLabel 황금 깜빡임 한 색 머무는 시간 (초). tensionBlinkHalfPeriod(0.5)와 동일.
  static let newBestBlinkHalfPeriod: TimeInterval = 0.5
  /// bestLabel 황금 깜빡임 SKAction 키. 같은 키 재호출 시 자동 교체로 자연 멱등.
  static let newBestBlinkActionKey: String = "newBestBlink"
  ```

## 주의사항

### Swift / SpriteKit 패턴
- **Timer 금지 (Swift 규칙 9)**: 0.3초 지연은 반드시 `SKAction.wait(forDuration:)` + `SKAction.run` 시퀀스로 구현. `Timer.scheduledTimer` / `DispatchQueue.main.asyncAfter` 사용 시 자동 감점.
- **매직 넘버 금지**: 0.3 / 0.5 / 0.8 / 56 / 1.2 등 모든 수치는 `GameConfig` 상수로 정의 후 참조.
- **`[weak self]` 캡처**: `SKAction.run { ... }` 안에서 self 사용 시 반드시 `[weak self]` + `self?.` 또는 `guard let self = self else { return }`.
- **`SKScene`도 SKNode**: `self.run(SKAction.sequence([wait, run]))` 호출이 합법 — `cameraNode` 부착 불필요(ResultScene은 카메라 없음).
- **강제 언래핑(`!`) 금지**: `bestLabel`, `newBestLabel` 등은 stored property로 non-optional이라 언래핑 자체가 불필요.

### 회귀 위험 차단
- `HighScoreRepository.record(_:) -> Bool` API 호출은 `GameScene.endGame()`에 이미 있고 `isNewBest`로 주입 중 — ResultScene은 *수신만* (DTO 패턴 답습).
- `bestLabel.text`의 기존 분기 (`isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"`)는 *그대로 유지*. 색만 황금으로 변경 + 깜빡임 추가 → 텍스트는 미접촉.
- `setupLabels()`의 기존 6개 라벨(title/score/best/stats/character/prompt)의 폰트/색/정렬/위치 일체 미접촉. NewBest 분기는 *마지막 줄에 추가*만.
- `layoutLabels()`의 기존 6개 라벨 position 6줄 미접촉. newBestLabel 1줄만 *마지막에 추가*.

### 빌드 에러 가능성
- `HapticsManager()` / `AudioManager()` init는 인자 없음. ResultScene에 stored property로 추가 시 `let` 기본값 형태 (`private let haptics = HapticsManager()`)로 추가.
- 기존 `init(size:score:bestScore:isNewBest:stats:characterName:)` 시그니처 변경 0건 — `GameScene.endGame()` 호출부 미접촉 보장.

### 시뮬레이터/실기기 검증 포인트
- 햅틱 heavy는 실기기에서만 체감 — 시뮬레이터에서는 noop.
- NewMail 1025 사운드는 시뮬레이터/실기기 모두 발화.
- 깜빡임은 `repeatForever` — ResultScene이 TitleScene으로 전환되며 ARC로 정리됨. 명시적 `removeAction(forKey:)` 불필요.
- 신기록 아닐 때 (`isNewBest == false`): NewBest 시퀀스 0건 발화 — `setupLabels()` 분기에서 자연 차단. 회귀 0 자동 보장.

### 멀티모달 가족 확장 (참고)
| 이벤트 | 촉각 | 청각 | 시각 |
|---|---|---|---|
| 시작 카운트다운 (6-13) | light×3 + heavy | NewMail (GO!) | CountdownNode |
| 5초 긴박감 (6-14) | light×4 (매초) | BGM rate 1.0→1.15 | HUD 빨강 깜빡임 |
| **신기록 (6-15)** | **heavy×1** | **NewMail** | **NEW BEST! 황금 + bestLabel 깜빡임** |

6-13/6-14/6-15가 *시작·끝·결과*의 3대 클라이맥스로 자리잡으며 Phase 6의 *피드백 시스템*이 의도된 형태로 완성된다.
