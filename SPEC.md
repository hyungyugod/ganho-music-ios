# Phase 6-12 — 콤보 끊김 피드백 (실망의 시각/햅틱)

## 개요
콤보 10+ 상태에서 F 피격이나 음표 놓침으로 콤보가 0으로 떨어지는 *그 순간* 시각/햅틱 반응을 추가한다. 6-10/6-11이 "환호(긍정)" 3감각을 완성했으니, 6-12는 그 대칭인 "실망(부정)"을 추가해 멀티모달 피드백 시스템의 양극을 완성한다. 콤보 변화 폴링 패턴(6-10 답습) + Set 기반 멱등 가드(6-10 답습) + 자가 소멸 노드 패턴(6-10 답습)을 그대로 재사용한다.

## 변경 유형
**혼합 (시각 + 햅틱)** — 새로운 자가 소멸 노드(시각) + HapticsManager 재사용(촉각). 사운드는 이번 sprint에서 제외 (Sprint 범위 최소화 + 환호와의 *비대칭 의도* — 실망은 청각보다 시각·촉각이 자연스러움).

## 게임 경험 의도
플레이어가 콤보 10+에 도달해 곡의 클라이맥스에 올라타는 순간, F 피격이나 음표 놓침으로 콤보가 0이 되면 *지금까지 쌓아온 흐름이 끊겼다*는 *체감*이 와야 한다. 환호(6-10/6-11)가 "잘하고 있어!"라면, 6-12는 "아, 끊겼다"의 *시각적 한숨*. 화면 중앙에 깨진 콤보 숫자가 *떨어지며* 푸르스름하게 사라지고, 동시에 묵직한 진동(heavy)이 신체에 즉시 도달 — 환호가 *위로 떠오름*이라면 실망은 *아래로 떨어짐*. 이 대칭이 멀티모달 피드백 시스템의 양극(긍정/부정)을 완성한다.

## Sprint 범위 계약
- **허용**:
  - `ComboBreakNode` (Nodes/) 신규 1개 — 자가 소멸 7호. SelfDismissingNode 채택.
  - `GameConfig` 콤보 끊김 관련 상수 5~6개 추가 (임계값/폰트/낙하거리/duration/색/zPosition).
  - `GameScene` Properties에 `lastComboValue: Int = 0` 추적 변수 1개 + Properties에 `triggeredComboBreaks: Set<Int>` 멱등 가드 1개.
  - `GameScene update()` 끝부분에 콤보 끊김 감지 폴링 5~8줄 추가 (`hud.update` 직후).
  - `HapticsManager.heavy()` 호출 (이미 존재 — 재사용).
  - pbxproj에 `ComboBreakNode.swift` 4지점 등록 (UUID 0032, HitFlashNode 0030 / ComboPopupNode 0031 답습).

- **금지**:
  - `triggeredComboMilestones` (6-11 환호 가드) **절대 미접촉**.
  - `ComboPopupNode` 시각 코드 미접촉 (6-10 산출물 보존).
  - `ScoreSystem` 시그니처/콜백 변경 **절대 금지** (6-10에서 옵션 B 폴링으로 확정된 정책 답습).
  - `ContactRouter` 변경 금지 — 끊김 감지는 GameScene이 폴링.
  - `AudioManager.SFX` 케이스 추가 금지 — 사운드는 본 sprint 범위 외 (다음 sprint에서 필요시 OCP 확장).
  - `endGame` 분기 추가 금지 — 콤보 끊김은 게임 종료가 아니라 *진행 중* 이벤트.
  - HUD `comboLabel` 깜빡임 추가 금지 — *정보(HUD) vs 임팩트(팝업)* 책임 분리 원칙(6-10 학습 노트 §"HUD 라벨 vs 팝업").
  - 새 ColorTokens 색 추가 금지 — 기존 색(`.ganhoCrimsonNurse` 또는 `.ganhoBloodAccent`) 재사용. Sprint 최소화.

- **판단 기준**: "이 변경이 없으면 콤보 끊김의 *시각적 한숨*이 플레이어에게 전달되지 않는가?" → YES면 허용, NO면 금지.

## 핵심 결정

### D1. 콤보 끊김 감지 메커니즘: 폴링 (옵션 B 답습)

```
[옵션 A: ScoreSystem 콜백]                [옵션 B: GameScene 폴링] ← 채택
ScoreSystem.onComboBreak = { prev in ... }   매 프레임 update 끝에
                                              currentCombo < lastComboValue 검사
                                              (특히 currentCombo == 0 시)
```

**채택 이유**:
1. **6-10 정책 일관성**: 콤보 *증가* 마일스톤도 폴링으로 처리 → *감소* 끊김도 같은 패턴이 코드베이스 통일성.
2. **ScoreSystem 회귀 0**: 6-10에서 확정된 결정 — Score 시스템은 *순수 상태 보관*, 이벤트 발행 책임 없음. 콜백을 추가하면 6-10 결정을 뒤집는 셈.
3. **listener 1개**: 끊김 이벤트를 듣는 곳은 GameScene 한 곳뿐 — 다수 listener가 필요한 시점까지 콜백 도입 보류.
4. **결합도 ↓**: ScoreSystem이 "누가 듣는지" 알 필요 없음.

**폴링 위치**: `update()` 함수의 *마지막* (hud.update 직후). 이유:
- `scoreSystem.tickComboExpiry(currentTime:)`가 이미 update 안에서 콤보 0으로 떨어뜨림 → 그 *직후* 같은 프레임에서 감지해야 시점 일치.
- F 피격 분기(`onProjectileHitPlayer`)는 endGame을 호출 — 콤보가 직접 0이 되진 않지만, hud.update(combo: 0)이 endGame 안에서 호출됨. 그러나 endGame은 gameState를 .gameOver로 바꾸므로 `guard gameState == .playing else { return }` 이후 폴링은 *실행 안 됨*. → F 피격 시 끊김 피드백은 *별도 분기* 필요. **D6 참조**.

### D2. 임계값: 콤보 10 이상

```swift
static let comboBreakThreshold: Int = 10
```

**채택 이유**:
- 콤보 1→0, 2→0은 *늘 일어나는 자연스러운 흐름* — 시각 노이즈만 늘림.
- 6-10 마일스톤 배열 [3, 5, 10, 20] 중 *10*이 "황금기" 톤. 10 이상에서 끊겼을 때만 *체감되는 손실*.
- 마일스톤 배열과 *연동*하지 않는다 — 끊김은 임계값 1개로 단순화. (마일스톤은 등급별 시각이지만 끊김은 단일 톤.)

**구현**:
```swift
guard lastComboValue >= GameConfig.comboBreakThreshold,
      scoreSystem.combo == 0 else { ... }
```

### D3. 피드백 채널: 시각 + 햅틱 (2채널)

| 채널 | 발화 | 강도 | 톤 |
|---|---|---|---|
| 시각 | ComboBreakNode 자가 소멸 | 화면 중앙 큰 텍스트 | 푸르스름한 *떨어짐* |
| 촉각 | `haptics.heavy()` | 묵직한 한 방 | 게임오버와 동일 강도 |
| ~~청각~~ | 본 sprint 제외 | — | — |

**왜 사운드 제외?**
- **Sprint 범위 최소화**: AudioManager.SFX 케이스 추가는 OCP로 언제든 가능. 본 sprint는 *시각 + 촉각의 대칭 완성*에 집중.
- **환호와의 의도적 비대칭**: 환호(6-11)는 청각이 본질(BGM 위 환호음) — *축하*는 소리로 표현. 실망은 *침묵의 한숨*이 자연 — 사운드 추가 시 게임오버 사운드와 톤 충돌 우려.
- **다음 sprint 여지**: 6-13에서 *콤보 끊김 사운드*만 추가 가능 (enum 케이스 1 + helper 1줄). 단일 책임 sprint 분리.

**왜 햅틱은 heavy?**
- light/medium은 이미 6-1/6-11에서 *긍정 이벤트*(노트 수집/콤보 마일스톤)에 점유됨.
- heavy는 게임오버에서 *부정 이벤트*에 점유됨 — 콤보 끊김도 부정 이벤트라 같은 강도 자연.
- 새 강도 도입 금지 (Apple 표준 3단 완성형 — 6-11 학습 노트 §4-2).

### D4. 시각 표현: 자가 소멸 7호 노드 (ComboBreakNode)

```
환호(6-10): ComboPopupNode "x5" 위로 떠오르며 페이드아웃 + 확대
실망(6-12): ComboBreakNode  "x12 BREAK" 아래로 떨어지며 페이드아웃 + 축소
                                                  ↑ 대칭점
```

**채택 이유 (HUD 깜빡임 vs 자가 소멸 노드)**:
1. **6-10 책임 분리 원칙 답습**: HUD = 항상 표시되는 정보, 자가 소멸 노드 = 일회성 임팩트. HUD 깜빡임은 *정보 채널에 임팩트 섞기*라 6-10 학습 노트 §"HUD 라벨 vs 팝업" 위반.
2. **자가 소멸 패턴 7회차 누적**: 6호(ComboPopupNode)와 정확히 대칭 — 같은 cameraNode 부모, 같은 SelfDismissingNode 채택, 같은 3단계 사용법(생성 → addChild → animate).
3. **회귀 0**: HUD 코드 1글자도 미접촉.

**ComboPopupNode와의 대칭 설계**:

| 항목 | ComboPopupNode (환호) | ComboBreakNode (실망) |
|---|---|---|
| 부모 | `cameraNode` | `cameraNode` (동일) |
| zPosition | `comboPopupZPosition` (150) | `comboBreakZPosition` (140, 마일스톤보다 낮게) |
| 이동 방향 | `+y` (위로) | `-y` (아래로) |
| 이동 거리 | `comboPopupFlyUpDistance` (80) | `comboBreakFallDistance` (60) |
| Scale 방향 | 1.0 → 1.4 (확대) | 1.0 → 0.7 (축소) |
| 페이드 | fadeOut | fadeOut (동일) |
| Duration | 1.0초 | 1.0초 (동일) |
| 색 | 등급별 4색 | 단일 톤 (`ganhoCrimsonNurse` 재사용) |
| 텍스트 | `"x{milestone}"` | `"x{prevCombo} BREAK"` |

**텍스트 결정**: `"x\(lastComboValue) BREAK"` — 끊긴 콤보 수치를 *증거*로 남겨 손실감 강화. 단순 "BREAK"보다 "x12 BREAK"가 *내가 잃은 것*을 명확히 보여줌.

**색 결정**: **옵션 A 채택** — `.ganhoCrimsonNurse` 재사용 (붉은 톤, 위험·손실 시그널). 색 추가 0건이 Sprint 최소화 원칙에 부합. 다음 sprint에서 색 분화 가능.

### D5. 멱등성 가드: triggeredComboBreaks (Set<Int>)

```swift
private var triggeredComboBreaks: Set<Int> = []
```

**왜 또 Set? 왜 그냥 Bool 플래그가 아닌가?**
- 한 판에서 콤보 10 도달 → 끊김 → 다시 10 도달 → 또 끊김 같은 마일스톤 *값*마다 1회 발화 정책.
- 단순 `hasComboBroken: Bool`로는 첫 끊김 이후 영영 재발화 불가.
- 그러나 한 판 안에서 콤보 *값별* 끊김은 의미 있음 — 10에서 끊겼다가 15까지 회복 후 또 끊기면 *15 BREAK*가 새 이벤트로 자연.

**채택: 마일스톤 *값별* 1회 발화 (Set<Int>)** — 6-11 환호 가드와 대칭. 같은 *값*은 한 판 1회만 발화.
- 임계값(10) 단일이지만 *끊겼을 때의 콤보 값*은 10, 11, 12, ..., 20+ 다양 — 각 값을 키로 사용.
- 예: 콤보 12에서 끊김 → "x12 BREAK" 발화 → Set에 12 insert. 다시 콤보 12 도달 후 끊김 → 차단. 그러나 콤보 15까지 회복 후 끊김 → "x15 BREAK" 발화 (12와 다른 값).

### D6. F 피격 분기: 별도 발화 경로

`onProjectileHitPlayer`는 endGame을 호출 → gameState .gameOver → update의 폴링 비실행. 따라서 F 피격 시점에 *직접* ComboBreakNode 발화 필요.

**구현 위치**: `configureContactRouter()` 안 `onProjectileHitPlayer` 클로저, `self.endGame()` *직전*:

```swift
contactRouter.onProjectileHitPlayer = { [weak self] in
    guard let self = self else { return }
    // Phase 6-9 셰이크/플래시는 유지
    self.cameraNode.run(CameraShakeAction.make())
    let flash = HitFlashNode()
    self.cameraNode.addChild(flash)
    flash.flash(sceneSize: self.size)
    // Phase 6-12 — F 피격 시점에 콤보 10+이면 BREAK 발화 (endGame 직전).
    // gameState .gameOver 전환되면 update 폴링이 멈추므로 여기서 강제 발화.
    self.checkAndTriggerComboBreak()
    self.endGame()
}
```

**6-11 패턴 일관성**: 콤보 마일스톤도 가드 *안쪽*에서 발화 → 끊김도 *조건 검사 후 발화* helper로 단일화. 폴링과 F 피격 두 경로가 같은 helper 호출 → DRY.

### D7. 6-11 멱등성 가드와의 관계

**완전 분리**. 두 Set은 독립:
- `triggeredComboMilestones: Set<Int>` — 환호 가드 (6-10/6-11). 콤보 3/5/10/20 *증가 도달* 시 발화 차단.
- `triggeredComboBreaks: Set<Int>` — 실망 가드 (6-12 신설). 콤보 10+ *끊김* 시 발화 차단.

**상호 영향 0**: 환호 발화 시 끊김 가드 변경 0건, 끊김 발화 시 환호 가드 변경 0건. 두 이벤트는 시간축에서 *교차*하지만 (콤보 10 도달→환호 → 끊김 →실망 → 다시 콤보 10 도달→환호 차단 / 끊김 시 같은 값 차단), 각 Set는 *자기 사건만* 추적.

**새 게임 시작 시 리셋**: 두 Set 모두 GameScene 인스턴스 프로퍼티 → 새 인스턴스 자동 빈 Set. 별도 reset 코드 0.

## 변경 범위

### 수정할 파일
- `Config/GameConfig.swift`: 콤보 끊김 관련 상수 6개 추가 (`comboBreakThreshold`, `comboBreakFontSize`, `comboBreakFallDistance`, `comboBreakDuration`, `comboBreakEndScale`, `comboBreakZPosition`).
- `GameScene.swift`:
  - Properties: `lastComboValue: Int = 0` + `triggeredComboBreaks: Set<Int> = []` 추가.
  - `update()` 마지막에 폴링 5~8줄 (hud.update 직후).
  - `configureContactRouter()`의 `onProjectileHitPlayer` 클로저에 `checkAndTriggerComboBreak()` 호출 1줄 (endGame 직전).
  - 새 private helper `triggerComboBreak(brokenAt:)` + `checkAndTriggerComboBreak()` 메서드 (15~20줄).
  - 헤더 주석에 `Phase 6-12` 1줄 추가.
- `GanhoMusic.xcodeproj/project.pbxproj`: ComboBreakNode.swift 4지점 등록 (UUID 0032, ComboPopupNode 0031 패턴 답습).

### 추가할 파일
- `Nodes/ComboBreakNode.swift`: 자가 소멸 7호 노드. SelfDismissingNode 채택. SKNode + SKLabelNode 자식 구조.

## 기능 상세

### 기능 1: ComboBreakNode (자가 소멸 7호)
- **설명**: 콤보 끊김 시 화면 중앙에서 *아래로 떨어지며* 페이드아웃 + 축소되는 텍스트 노드. ComboPopupNode와 완전 대칭 (방향만 반전).
- **구현 위치**: `GanhoMusic Shared/Nodes/ComboBreakNode.swift` (신규)
- **핵심 코드 구조**:
  ```swift
  // ComboBreakNode.swift
  final class ComboBreakNode: SKNode, SelfDismissingNode {
      private let label: SKLabelNode

      init(brokenCombo: Int) {
          self.label = SKLabelNode(text: "x\(brokenCombo) BREAK")
          super.init()
          name = "comboBreak"
          zPosition = GameConfig.comboBreakZPosition
          configureLabel()
          addChild(label)
      }

      required init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
      }

      // 부모(cameraNode)에 addChild 직후 호출. group(move + fade + scale) 동시 → 자가 제거.
      // self 미사용 — [weak self] 캡처 불필요.
      func animate() {
          let moveDown = SKAction.moveBy(x: 0,
                                          y: -GameConfig.comboBreakFallDistance,
                                          duration: GameConfig.comboBreakDuration)
          let fadeOut  = SKAction.fadeOut(withDuration: GameConfig.comboBreakDuration)
          let scaleDown = SKAction.scale(to: GameConfig.comboBreakEndScale,
                                          duration: GameConfig.comboBreakDuration)
          let group   = SKAction.group([moveDown, fadeOut, scaleDown])
          let cleanup = SKAction.removeFromParent()
          run(.sequence([group, cleanup]))
      }

      private func configureLabel() {
          label.fontSize = GameConfig.comboBreakFontSize
          label.fontColor = .ganhoCrimsonNurse   // 손실/위험 시그널 재사용 (색 추가 0)
          label.verticalAlignmentMode = .center
          label.horizontalAlignmentMode = .center
          label.position = .zero
      }
  }
  ```

### 기능 2: GameConfig 상수 추가
- **설명**: 끊김 임계값 + 시각 파라미터 6개. ComboPopup 상수와 대칭 위치(`// MARK: - Combo Break (Phase 6-12)`).
- **구현 위치**: `GanhoMusic Shared/Config/GameConfig.swift` (수정)
- **핵심 코드 구조**:
  ```swift
  // MARK: - Combo Break (Phase 6-12)
  /// 콤보 끊김 시 BREAK 시각 발화 임계값. 이 값 이상의 콤보에서 0으로 떨어졌을 때만 발화.
  /// 1→0, 2→0은 평범한 흐름이라 무시. 10 = 콤보 마일스톤 "황금기" 톤과 일치.
  static let comboBreakThreshold: Int = 10
  /// BREAK 라벨 폰트 크기 (pt). comboPopupFontSize(48)와 동일 — 환호/실망 시각 강도 대칭.
  static let comboBreakFontSize: CGFloat = 48
  /// BREAK가 아래로 떨어지는 거리 (pt). comboPopupFlyUpDistance(80)보다 짧음 — *떨어짐*은 짧고 단호.
  static let comboBreakFallDistance: CGFloat = 60
  /// BREAK 1회 표시 총 길이 (초). comboPopupDuration(1.0)과 동일 — 환호/실망 시간축 대칭.
  static let comboBreakDuration: TimeInterval = 1.0
  /// BREAK 끝 스케일. 1.0 시작 → 0.7 끝. comboPopupEndScale(1.4 확대)와 반대 — 실망은 *축소*.
  static let comboBreakEndScale: CGFloat = 0.7
  /// BREAK zPosition. comboPopupZPosition(150) 아래 — 환호 위에 끊김이 덮이지 않도록.
  /// HUD(100) 위는 유지 — 임팩트 강조.
  static let comboBreakZPosition: CGFloat = 140
  ```

### 기능 3: GameScene 폴링 + F 피격 분기 + helper
- **설명**: 매 프레임 update 끝에서 콤보 끊김 감지 + F 피격 시점 강제 발화 + 공통 helper.
- **구현 위치**: `GanhoMusic Shared/GameScene.swift` (수정)
- **핵심 코드 구조**:

  **Properties 추가** (6-11 `triggeredComboMilestones` 바로 아래):
  ```swift
  // Phase 6-12 — 콤보 끊김 발화 추적. 같은 콤보 값 끊김은 한 판 1회만 발화 (멱등).
  // 6-11 triggeredComboMilestones와 완전 분리 — 환호와 실망은 독립 가드.
  // 콤보 0 감지를 위해 직전 프레임의 콤보값 추적도 필요.
  private var lastComboValue: Int = 0
  private var triggeredComboBreaks: Set<Int> = []
  ```

  **update() 끝부분 (hud.update 직후)**:
  ```swift
  // ... 기존 hud.update(...) ...

  // Phase 6-12 — 콤보 끊김 폴링. tickComboExpiry(콤보 윈도우 만료)로 같은 프레임에
  // 콤보가 0으로 떨어진 직후를 캡처. F 피격 경로는 별도 분기(configureContactRouter).
  // playing 상태에서만 실행 — gameOver 전환 후엔 의미 없음(이미 guard로 차단됨).
  let currentCombo = scoreSystem.combo
  if lastComboValue >= GameConfig.comboBreakThreshold, currentCombo == 0 {
      triggerComboBreak(brokenAt: lastComboValue)
  }
  lastComboValue = currentCombo
  ```

  **새 helper (Combo Milestone Feedback MARK 섹션 아래)**:
  ```swift
  // MARK: - Combo Break Feedback (Phase 6-12)
  /// 콤보 10+ 상태에서 0으로 떨어진 순간 호출. 시각(ComboBreakNode) + 햅틱(heavy) 2채널 발화.
  /// 멱등 가드: 같은 끊김 값은 한 판 1회만 발화. 6-11 멱등 가드와 동일 패턴.
  /// 호출 경로 2개: update 폴링 / onProjectileHitPlayer 클로저 (endGame 직전).
  private func triggerComboBreak(brokenAt brokenValue: Int) {
      if triggeredComboBreaks.contains(brokenValue) { return }
      triggeredComboBreaks.insert(brokenValue)
      haptics.heavy()   // 부정 이벤트 → 게임오버와 동일 강도. 6-11 환호와 의도적 대칭(실망).
      let breakNode = ComboBreakNode(brokenCombo: brokenValue)
      cameraNode.addChild(breakNode)
      breakNode.animate()
  }

  /// F 피격 분기에서 호출. 콤보 임계값 미달이면 noop.
  /// endGame() 전 *마지막* 발화 기회 — endGame이 gameState를 .gameOver로 바꾸면
  /// update 폴링이 차단되므로 여기서 강제 검사.
  private func checkAndTriggerComboBreak() {
      let combo = scoreSystem.combo
      if combo >= GameConfig.comboBreakThreshold {
          triggerComboBreak(brokenAt: combo)
      }
  }
  ```

  **configureContactRouter() 안 onProjectileHitPlayer 수정**:
  ```swift
  contactRouter.onProjectileHitPlayer = { [weak self] in
      guard let self = self else { return }
      // Phase 6-9 — 카메라 셰이크 + 빨간 플래시
      self.cameraNode.run(CameraShakeAction.make())
      let flash = HitFlashNode()
      self.cameraNode.addChild(flash)
      flash.flash(sceneSize: self.size)
      // Phase 6-12 — F 피격으로 콤보가 끊기는 시점 (endGame 전 강제 발화).
      // endGame이 .gameOver로 전환하면 update 폴링이 차단되므로 여기서 검사.
      self.checkAndTriggerComboBreak()
      self.endGame()
  }
  ```

### 기능 4: pbxproj 등록 (UUID 0032)
- **설명**: ComboBreakNode.swift를 Xcode 프로젝트에 4지점 등록 (PBXBuildFile / PBXFileReference / PBXSourcesBuildPhase / PBXGroup).
- **구현 위치**: `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` (수정)
- **참고 패턴**: HitFlashNode(UUID 0030), ComboPopupNode(UUID 0031)의 4지점 등록을 그대로 답습. UUID는 0032로 부여.

## 주의사항

### SpriteKit 특성
- **ComboBreakNode는 cameraNode 자식**: ComboPopupNode와 동일 — 화면 중앙 고정. worldNode 자식으로 두면 카메라 이동 시 어긋남.
- **noteNode 좌표계와 무관**: 끊김은 노트 위치와 무관 (콤보 윈도우 만료는 *시간*만 의존). cameraNode 좌표계 (0,0)에 부착.
- **zPosition 위계**: HUD(100) < ComboBreak(140) < ComboPopup(150) < HitFlash(200) < BombFlash(250). 환호가 실망보다 위 — 콤보 도달과 끊김이 한 프레임에 동시 발생할 일은 없지만 안전망.

### 폴링 타이밍 함정
- `tickComboExpiry()`가 update *초반*에 콤보 0으로 떨어뜨림. *그 직후 같은 프레임에서* 폴링해야 1프레임 지연 없음.
- `lastComboValue` 갱신 시점이 *폴링 후*인 것이 중요 — 갱신 전이면 이전 프레임 값 손실.
- F 피격은 update 흐름 *밖*(SpriteKit physics callback) → update 폴링으로 못 잡힘 → D6의 별도 분기 필수.

### 멱등 가드 분리
- 6-11 `triggeredComboMilestones` 절대 미접촉 — 환호 가드와 실망 가드는 *완전 독립*.
- 두 Set의 변경 라인이 서로 한 줄도 겹치지 않도록 코드 위치 분리 (MARK 섹션 다름).

### 빌드 에러 가능성
- ComboBreakNode 신규 파일은 pbxproj 4지점 등록 누락 시 *Cannot find type 'ComboBreakNode' in scope* 에러. UUID 0032로 ComboPopupNode 0031 등록 패턴 한 줄씩 비교하며 추가.
- `lastComboValue` 첫 프레임 = 0 → 첫 콤보 도달 시 lastComboValue=0, currentCombo=1 → 끊김 감지 노이즈 없음 (임계값 10 가드).
- `triggerComboBreak`가 호출되는 두 경로 모두에서 `triggeredComboBreaks.contains` 가드 통과 — 같은 값 2회 발화 방지 (예: 폴링과 피격이 같은 프레임에 발생할 가능성은 0이지만 안전망).

### Swift 패턴
- 강제 언래핑 없음 — `cameraNode`, `scoreSystem`은 GameScene let 프로퍼티 (옵셔널 아님).
- 매직 넘버 없음 — 모든 수치 GameConfig.
- `[weak self]` 캡처는 onProjectileHitPlayer 기존 그대로 유지. ComboBreakNode 내부는 self 미사용 (캡처 불필요).
- helper 2개 (`triggerComboBreak`, `checkAndTriggerComboBreak`) — 단일 책임 분리. 폴링 경로와 피격 경로의 *공통 동작*은 `triggerComboBreak`로 통합.

### Sprint 회귀 0 보장 영역
이 sprint가 절대 건드리면 안 되는 곳: ScoreSystem / ContactRouter / SpawnSystem / HUDNode / BGMPlayer / AudioManager / Repositories / Models / Protocols / 기존 Nodes (PlayerNode/EnemyNode/NoteNode/ProjectileNode/StoneGuardNode/DPadNode/AirplaneNode/AirforceOverlayNode/BombFlashNode/HitFlashNode/SparkleEffectNode/CharacterCardNode/ComboPopupNode) / TitleScene / ResultScene / ColorTokens / SelfDismissingNode / triggeredComboMilestones Set 의미·위치·리셋 정책 — **22개 영역 미접촉 검증 필수**.
