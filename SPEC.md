# Phase 6-13 — 게임 시작 카운트다운 (3 → 2 → 1 → GO!)

## 개요
TitleScene에서 GameScene으로 전환된 직후 게임이 *즉시* 시작하던 흐름을 바꾼다. 화면 중앙에 큰 숫자 3 → 2 → 1 → GO!가 1초 간격으로 차례로 떠올랐다 사라지고, GO! 직후에야 노트 스폰·45초 타이머·플레이어 입력·BGM·적 추적 AI가 본격 시동된다. 매 숫자에 light 햅틱, GO!에 heavy 햅틱 + 사운드(`comboMilestoneStrong` 재사용). 자가 소멸 노드 8호.

## 변경 유형
**게임플레이** — 게임 시작 흐름(상태 전환 + 시스템 가동 타이밍)이 바뀌므로. 비주얼 효과(카운트다운 노드)는 게임플레이 변경의 *수단*일 뿐, 본 sprint의 핵심 가치는 "GO! 이전에는 어떤 시스템도 돌지 않는다"는 **흐름 재설계**다.

## 게임 경험 의도
1. **개봉감**: 라운드 시작 직후 3초의 "심호흡" — TitleScene 탭 → 갑작스러운 음표 폭격이 아닌, 플레이어가 손가락을 D-Pad에 얹고 화면을 살피며 마음을 가다듬는 시간을 제공한다.
2. **명확한 출발 신호**: GO!가 떠야 게임이 시작됐다는 명시적 신호 — 노트 스폰·타이머 시작이 GO!와 청각·촉각으로 동기화돼 "이제부터 진짜다"가 신체로 전달된다.
3. **BGM의 예의 보존**: 자작 BGM이 GO!와 함께 페이드인되어 시작 — 카운트다운 동안 음악이 미리 켜지면 *심호흡*의 정적이 깨진다. 6-5에서 만든 1.5초 페이드인의 자연 안착점.

## Sprint 범위 계약

- **허용** (SPEC 기능의 정상 동작에 필수적인 최소 연동 변경):
  - `GameState.countdown` case 추가
  - `GameScene.didMove(to:)` 흐름 재구성 (모든 시스템 가동을 `startGameProperly()`로 이동)
  - `CountdownNode` 신규 (자가 소멸 노드 8호)
  - `GameConfig` 카운트다운 관련 상수 신규
  - `update()`의 `gameState == .playing` 가드는 그대로 유지 — `.countdown`에서도 자동 차단됨
- **금지** (SPEC에 없는 독립 기능):
  - 카운트다운 *스킵* 기능 (탭으로 건너뛰기) — 사용자 요청에 따라 강제 시청
  - 카운트다운 숫자 다국어/난이도별 차등
  - 카운트다운 동안 캐릭터 이름 우측 상단 라벨 변경
  - ColorTokens 신규 색 추가 (기존 토큰 재사용)
  - AudioManager.SFX 신규 케이스 추가 (`comboMilestoneStrong` 재사용)
  - BGMPlayer / SpawnSystem / ScoreSystem / HUDNode / DPadNode / EnemyNode / ContactRouter / Repositories / Models / ResultScene / TitleScene / 기존 자가 소멸 노드 7개 미접촉
- **판단 기준**: "이 변경이 없으면 카운트다운 → GO! 흐름이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

## 핵심 결정 1 — GameState 확장 (.countdown 추가)

**결정**: 새 case `countdown`을 `GameState` enum에 추가한다 (플래그 방식 거부).

**이유**:
- 기존 `update()` 가드는 `guard gameState == .playing else { return }` — `.countdown`은 자동으로 *모든 프레임별 로직 차단* (타이머 감소·플레이어 이동·카메라 follow·enemy 추적·콤보 만료 폴링·끊김 폴링까지 한 번에 멈춤).
- 플래그(`var isInCountdown: Bool`) 방식이라면 update 안에 새 가드 추가가 필요해 *6-12까지의 모든 회귀 영역 위험*. enum 확장은 *추가만 하고 기존 분기 미수정*이라 회귀 0.
- Spring 비유: 상태 머신(`@Getter State`)에 새 enum 값 추가 vs 보조 flag 추가. 단일 책임 원칙상 전자가 깔끔.

**변경**:
```swift
// Config/GameState.swift
enum GameState {
    case waiting
    case countdown   // ⭐ Phase 6-13 신규 — 카운트다운 진행 중. 모든 시스템 정지.
    case playing
    case paused
    case gameOver
}
```

## 핵심 결정 2 — 카운트다운 동안 정지되는 것들

| 시스템 | 어떻게 정지하는가 | 비고 |
|---|---|---|
| **노트 스폰** (SpawnSystem) | `spawnSystem.start(...)` 호출을 GO! 콜백까지 지연 | SpawnSystem 미수정 — 시작 *시점*만 늦춤 |
| **F 투사체 발사** (SpawnSystem) | 동일 — `start()` 호출 자체를 지연 | spawnNotes + fireProjectiles 두 액션 모두 시작 안 됨 |
| **45초 타이머** | `update()` 안 `remainingTime -= dt`는 `guard .playing` 뒤에 있음 → `.countdown`에서 자동 정지 | HUD는 시작값 "00:45"을 표시 |
| **D-Pad 입력 → 플레이어 이동** | `update()` 안 `player.currentDirection = dpad.currentDirection`은 `guard .playing` 뒤 → 자동 정지 | DPadNode 자체는 정상 작동(스크롤 가능). 하지만 player에 반영 안 됨 |
| **카메라 follow** | `update()` 안 `cameraNode.position = player.position`은 `guard .playing` 뒤 → 자동 정지 | 카운트다운 동안 카메라는 시작 위치 고정 |
| **적 추적 AI** | `update()` 안 `enemy.update(...)`은 `guard .playing` 뒤 → 자동 정지 | enemy도 시작 위치 고정 (velocity 미부여) |
| **콤보 만료 폴링 + 끊김 폴링** | `update()` 안 폴링 코드도 `guard .playing` 뒤 → 자동 정지 | 카운트다운 중 `lastComboValue` 변동 0 → 안전 |
| **BGM** | `bgm.play()` 호출을 GO! 콜백까지 지연 | 6-5의 1.5초 페이드인이 GO! 시점부터 시작 — 첫 노트 스폰(1.5초 후)과 자연 동기 |

**핵심 통찰**: 기존 `guard gameState == .playing else { return }` 가드 *한 줄*이 자동으로 7개 시스템을 모두 차단한다. `.countdown` case 추가만으로 모든 정지가 공짜로 따라온다. *추가 가드 코드 한 줄도 안 쓴다.*

## 핵심 결정 3 — 카운트다운 노드 구조 (단일 노드 SKAction.sequence)

**결정**: 단일 `CountdownNode` 클래스가 3 → 2 → 1 → GO! 4단계를 *자체 SKAction.sequence*로 관리한다. GameScene은 노드 1개 생성 + `start(onComplete:)` 1회 호출만 한다.

**이유**:
- 자가 소멸 노드 7회차까지 누적된 fire-and-forget 패턴(`AirplaneNode.crossScreen` / `ComboPopupNode.animate` / `ComboBreakNode.animate`)을 *그대로* 답습. 호출자 책임 = `addChild` + `start(...)` 두 줄.
- 4개 독립 노드 + GameScene이 `SKAction.run`으로 차례 발화하는 방식은 *호출자가 시퀀스를 알아야* 하므로 책임 분산. 노드가 자기 시퀀스를 안다 = 응집도 높음.
- 단계별 햅틱·사운드 발화는 각 `SKAction.run` 안에서 *호출자가 주입한 콜백*으로 처리 (이유: 햅틱/사운드는 Manager에 의존 → 노드가 직접 알면 결합도 ↑).

**구조**:
```swift
// Nodes/CountdownNode.swift — 신규
final class CountdownNode: SKNode, SelfDismissingNode {
    private let label: SKLabelNode

    init() { /* zPosition 설정 + label 자식 추가 */ }

    /// 외부 진입점. 4단계 시퀀스를 자체 SKAction.sequence로 실행.
    /// - onTick: 매 숫자(3/2/1) 발화 직후 호출 — GameScene이 light 햅틱
    /// - onGo: GO! 표시 직후 호출 — GameScene이 heavy 햅틱 + 사운드
    /// - onComplete: GO! 페이드아웃 직후 호출 — GameScene이 startGameProperly()
    func start(
        onTick: @escaping (Int) -> Void,
        onGo: @escaping () -> Void,
        onComplete: @escaping () -> Void
    )
}
```

**SKAction.sequence 내부 구조** (의사코드):
```
sequence([
    showText("3", color: .ganhoBloodAccent), run { onTick(3) }, animateStep(),
    showText("2", color: .ganhoYellowF),    run { onTick(2) }, animateStep(),
    showText("1", color: .ganhoPinkNote),   run { onTick(1) }, animateStep(),
    showText("GO!", color: .ganhoMint),     run { onGo() },    animateGoStep(),
    .removeFromParent(),
    .run { onComplete() }
])
```

- `animateStep()` = fadeIn(0.1) → wait(0.7) → fadeOut(0.2) = 1.0초/단계
- `animateGoStep()` = fadeIn(0.1) → scale 펄스(1.0 → 1.3) → wait(0.5) → fadeOut(0.4) = 1.0초

**왜 `onComplete`는 `removeFromParent` *뒤*?**: 노드 제거 직후 호출돼야 GameScene이 새 시스템을 켤 때 카운트다운 노드가 *이미 트리에서 빠진* 상태가 보장됨 (시각 잔상 0).

## 핵심 결정 4 — 시각 디자인

| 항목 | 값 | 근거 |
|---|---|---|
| **폰트 크기** | 96pt (GameConfig.countdownFontSize) | comboPopup(48)의 2배 — 화면 중앙 단독 강조. HUD/콤보팝업과 위계 차별. |
| **색 (3)** | `.ganhoBloodAccent` (#D8315B 빨강) | "주의 환기" — 가장 강한 색을 첫 단계에. |
| **색 (2)** | `.ganhoYellowF` (#FFD23F 노랑) | "준비 완료" — F 투사체와 같은 색이지만 다른 맥락(시작 직전). |
| **색 (1)** | `.ganhoPinkNote` (#F6A6B2 분홍) | "직전" — 음악 본체 색 (1 다음이 음악 시작). |
| **색 (GO!)** | `.ganhoMint` (#7DCFB6 민트) | "출발" — 김간호 머리띠 색, 긍정/시작 톤. |
| **펄스 애니메이션** | fadeIn(0.1) + wait(0.7) + fadeOut(0.2) per 숫자 | 총 1초 — 사용자 요청 "1초씩". GO!는 scale 펄스 추가(0.5초 holding) → 임팩트 강조. |
| **zPosition** | 250 (GameConfig.countdownZPosition) | HitFlash(200) 위, HUD(100) 위 — 카운트다운 동안 모든 UI를 덮는다. BombFlash와 충돌 안 함 (이스터에그는 게임 진행 중이라 시간상 겹침 0). |
| **부모** | `cameraNode` 자식 | 화면 중앙 고정 — worldNode 좌표계의 카메라 변동과 무관. ComboPopupNode와 같은 부착 정책. |

**ColorTokens 추가 0건** — 기존 4색을 *기능적 의미*에 맞춰 재사용. Sprint 범위 최소화. **단**, 위 4색이 실제로 `ColorTokens.swift`에 정의되어 있는지 Generator가 사전 확인할 것 — 만약 `.ganhoMint`나 `.ganhoBloodAccent` 등이 없으면 가장 가까운 기존 색으로 대체 (예: `.ganhoMint` 부재 시 `.ganhoYellowF` 또는 `.ganhoPaper`).

## 핵심 결정 5 — 사운드 / 햅틱 채널

| 단계 | 햅틱 | 사운드 |
|---|---|---|
| 3 / 2 / 1 | `haptics.light()` (3회) | (없음 — *조용한 카운팅* 톤) |
| GO! | `haptics.heavy()` (1회) | `audio.play(.comboMilestoneStrong)` (1회) |

**왜 GO!에 `comboMilestoneStrong` 재사용?**:
- 기존 SFX 케이스: `noteCollected`(Tink 1057) / `gameOver`(Boop 1073) / `comboMilestoneSoft`(Tink 1057) / `comboMilestoneStrong`(NewMail 1025).
- `gameOver`는 1073(Boop) → 부정/종료 톤이라 *부적합*.
- `comboMilestoneStrong`은 NewMail 1025 → 긍정·묵직 톤. *출발* 의도와 정확히 일치.
- AudioManager.SFX 신규 케이스 추가는 *Sprint 범위 외* — 6-12의 학습 노트 §3 정책(채널 추가는 단일 책임 sprint에서) 답습.

**왜 3/2/1에는 사운드 없음?**:
- 햅틱만으로 *카운팅* 채널 분리. 시각(숫자) + 촉각(light) = 2채널.
- GO!에서야 청각이 추가돼 3채널 → 첫 음악 시작의 *임팩트 강조*.

## 핵심 결정 6 — 호출 흐름

### Before (현재)
```
didMove(to:)
├── setupBackground()
├── setupWorld()
├── setupPlayer()
├── setupCamera()
├── setupDPad()
├── setupHUD()
├── setupEnemy()
├── setupStoneGuard()
├── physicsWorld.gravity = .zero
├── configureContactRouter()
├── physicsWorld.contactDelegate = contactRouter
├── spawnSystem.start(...)        ⬅ 시작
├── gameState = .playing          ⬅ 게임 시작
└── bgm.play()                    ⬅ 음악 시작
```

### After (Phase 6-13)
```
didMove(to:)
├── setupBackground()
├── setupWorld()
├── setupPlayer()
├── setupCamera()
├── setupDPad()
├── setupHUD()
├── setupEnemy()
├── setupStoneGuard()
├── physicsWorld.gravity = .zero
├── configureContactRouter()
├── physicsWorld.contactDelegate = contactRouter
├── gameState = .countdown        ⬅ 카운트다운 상태 (모든 update 로직 차단)
└── showCountdown()               ⬅ CountdownNode 생성 + 시작

showCountdown()
└── CountdownNode 생성 + cameraNode.addChild
    └── node.start(
            onTick: { [weak self] _ in self?.haptics.light() },
            onGo:   { [weak self] in
                self?.haptics.heavy()
                self?.audio.play(.comboMilestoneStrong)
            },
            onComplete: { [weak self] in self?.startGameProperly() }
        )

startGameProperly()      ⬅ 신규 메서드 — GO! 이후 실제 게임 시동
├── spawnSystem.start(...)        ⬅ 노트/F 스폰 시작
├── gameState = .playing          ⬅ update의 모든 시스템 해방
└── bgm.play()                    ⬅ 1.5초 페이드인으로 BGM 시작
```

**핵심 통찰**: `setupBackground` ~ `configureContactRouter`까지의 13줄은 *위치 미변경*. 마지막 3줄(`spawnSystem.start` + `gameState = .playing` + `bgm.play`)만 새 helper `startGameProperly()`로 이동 + `gameState = .countdown` + `showCountdown()` 2줄이 그 자리에 들어간다. 변경량 최소.

## 핵심 결정 7 — 카운트다운 중 *터치 처리*

**결정**: 강제 시청 (3초 통째로 봐야 한다). 카운트다운 중 화면 탭은 noop.

**이유**:
- 사용자 요청에서 명시: "강제 시청 (3초가 게임의 *심호흡* 시간)".
- DPadNode는 `isUserInteractionEnabled = true`인 채로 둔다 — touch 자체는 받지만 `update()`의 `guard .playing`이 player 반영을 차단.
- 추가 가드 코드 0줄. 자연 차단.
- 만약 미래에 *스킵* 기능이 필요해지면 별도 sprint(6-14 후보)에서 `touchesBegan`에 카운트다운 노드의 `removeAllActions()` + `startGameProperly()` 즉시 호출을 추가하면 됨. 본 sprint는 미포함.

## 핵심 결정 8 — 6-12까지의 회귀 0 영역

본 sprint 미접촉 (회귀 0 보장):

| 영역 | 보존 사유 |
|---|---|
| **ComboBreakNode** (6-12) | 자가 소멸 7호 그대로. CountdownNode가 8호로 *다음 자리*에 들어옴. |
| **ComboPopupNode** (6-10) | 6-10 색 매핑 / animate 메서드 그대로. CountdownNode 시각 디자인은 *별도 GameConfig*. |
| **콤보 마일스톤 환호 / 끊김 실망 폴링** | `update()` 안 폴링 코드 그대로. `.countdown` 상태에서는 `guard .playing`이 자동 차단. |
| **SparkleEffectNode / HitFlashNode** (6-8/6-9) | 음표 수집 / F 피격 시 시각 효과 그대로. 카운트다운 중에는 *발생 자체 0*이라 충돌 0. |
| **BGMPlayer** (6-4 ~ 6-7) | 페이드인/페이드아웃/Interruption/Background 처리 그대로. `bgm.play()` 호출 시점만 *늦춤*. |
| **HapticsManager / AudioManager** (6-1 ~ 6-3 + 6-11) | API 미수정. `light()` / `heavy()` / `play(.comboMilestoneStrong)` *재사용*. |
| **SpawnSystem / ContactRouter / ScoreSystem** | API 미수정. SpawnSystem.start() 호출 *시점*만 늦춤. |
| **HUDNode** | 라벨 위치/스타일/setCharacterName 그대로. 카운트다운 중 HUD는 *그대로 노출*(시간 00:45, 점수 🎵 0). |
| **TitleScene / ResultScene** | 미접촉. TitleScene→GameScene 전환 후 GameScene 내부에서만 변경. |
| **Repositories / Models / Protocols** | 미접촉. |
| **EnemyNode / PlayerNode / StoneGuardNode / NoteNode / ProjectileNode / DPadNode** | API + 본문 미접촉. `.countdown` 상태에서는 update가 자동 차단. |
| **AIRFORCE 이스터에그 체계** (4-3 ~ 4-7) | 미접촉. `airforceTriggered` 가드 그대로. |
| **CharacterID / 캐릭터 카드** (5-1 ~ 5-7) | 미접촉. |

## 변경 범위

### 수정할 파일

- **`Config/GameState.swift`** (+1줄): `countdown` case 1개 추가.
- **`Config/GameConfig.swift`** (+10줄): 카운트다운 관련 상수 8개 추가 (MARK 섹션 1개).
- **`GameScene.swift`** (~+25줄, -3줄): `didMove`의 마지막 3줄(spawnSystem.start / gameState=playing / bgm.play)을 `startGameProperly()` helper로 이동 + `gameState = .countdown` + `showCountdown()` 2줄 추가. 헤더 주석에 Phase 6-13 한 줄 추가.

### 추가할 파일

- **`Nodes/CountdownNode.swift`** (신규, ~75줄): 자가 소멸 노드 8호. `SelfDismissingNode` 채택. `start(onTick:onGo:onComplete:)` 진입점 1개.
- **`GanhoMusic.xcodeproj/project.pbxproj`** (+4줄): UUID 0033 4지점 (ComboBreakNode UUID 0032 패턴 답습).

### 미접촉 파일 (회귀 0)

- 모든 Systems / Managers / Repositories / Models / Protocols / Errors
- TitleScene / ResultScene
- 기존 Nodes 14개 (PlayerNode / EnemyNode / NoteNode / ProjectileNode / StoneGuardNode / DPadNode / HUDNode / AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode / ComboPopupNode / ComboBreakNode / CharacterCardNode)
- ColorTokens / PhysicsCategory

## 기능 상세

### 기능 1: GameState.countdown case 추가

- **설명**: 카운트다운 진행 중 상태. update()의 모든 프레임별 로직을 자동 차단한다.
- **구현 위치**: `Config/GameState.swift`
- **핵심 코드**:
  ```swift
  enum GameState {
      case waiting
      case countdown   // Phase 6-13 — 3→2→1→GO! 진행 중. update의 모든 시스템 정지.
      case playing
      case paused
      case gameOver
  }
  ```

**주의 — exhaustive switch 검증**: GameState를 exhaustive하게 다루는 switch가 있으면 `.countdown` 처리 강제됨. Generator는 `grep -rn "case .playing" --include="*.swift"`로 모든 switch 위치를 확인하고, `default` 없는 switch에는 `.countdown` 케이스 추가(noop으로 처리하거나 `.waiting`과 동일 동작).

### 기능 2: GameConfig 카운트다운 상수 8개 추가

- **설명**: CountdownNode의 폰트 크기·각 단계 길이·페이드 시간·zPosition을 매직 넘버 회피로 분리.
- **구현 위치**: `Config/GameConfig.swift` — MARK 섹션 `// MARK: - Countdown (Phase 6-13)` 신규 (Combo Break 다음 위치).
- **핵심 상수**:
  ```swift
  // MARK: - Countdown (Phase 6-13)
  /// 카운트다운 숫자/GO! 폰트 크기 (pt). comboPopup(48)의 2배 — 화면 중앙 단독 강조.
  static let countdownFontSize: CGFloat = 96
  /// 한 단계(3/2/1/GO!) fadeIn 길이 (초). 빠르게 등장.
  static let countdownFadeInDuration: TimeInterval = 0.1
  /// 한 단계 *holding* 길이 (초). 또렷이 보이는 구간.
  static let countdownHoldDuration: TimeInterval = 0.7
  /// 한 단계 fadeOut 길이 (초). 다음 단계 등장 전 사라짐.
  static let countdownFadeOutDuration: TimeInterval = 0.2
  /// GO! 단계의 scale 펄스 끝값. 1.0 → 1.3 확대 → 페이드아웃과 동시 종료.
  static let countdownGoEndScale: CGFloat = 1.3
  /// GO! 단계 fadeOut 길이 (초). 일반 단계보다 살짝 길게 — 시작의 잔향.
  static let countdownGoFadeOutDuration: TimeInterval = 0.4
  /// GO! holding 길이 (초). 일반(0.7)보다 짧게 — 스케일 펄스 + 빠른 페이드아웃이 시간 채움.
  static let countdownGoHoldDuration: TimeInterval = 0.5
  /// CountdownNode zPosition. HitFlash(200) 위, BombFlash(250)와 동급/이하.
  /// 카운트다운 동안 어떤 UI도 덮는다 — 게임이 아직 시작 안 했으므로.
  static let countdownZPosition: CGFloat = 250
  ```

### 기능 3: CountdownNode 신규 (자가 소멸 노드 8호)

- **설명**: 3 → 2 → 1 → GO! 4단계를 단일 SKNode가 자체 SKAction.sequence로 진행한다. 매 단계 텍스트/색이 바뀌고, GO!는 scale 펄스 추가. 외부 콜백 3개(onTick / onGo / onComplete)로 햅틱·사운드·완료 알림.
- **구현 위치**: `Nodes/CountdownNode.swift` (신규 파일)
- **핵심 코드 구조**:
  ```swift
  final class CountdownNode: SKNode, SelfDismissingNode {

      // MARK: - Properties
      private let label: SKLabelNode

      // MARK: - Init
      override init() {
          self.label = SKLabelNode(text: "")
          super.init()
          name = "countdown"
          zPosition = GameConfig.countdownZPosition
          configureLabel()
          addChild(label)
      }

      required init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
      }

      // MARK: - Start
      /// 부모(cameraNode)에 addChild 직후 호출. 4단계 시퀀스를 자체 실행.
      /// - onTick(n): 숫자 n(3/2/1) 표시 직후. 호출자가 light 햅틱.
      /// - onGo: GO! 표시 직후. 호출자가 heavy 햅틱 + 사운드.
      /// - onComplete: GO! 페이드아웃 + 노드 제거 직후. 호출자가 startGameProperly().
      func start(
          onTick: @escaping (Int) -> Void,
          onGo: @escaping () -> Void,
          onComplete: @escaping () -> Void
      ) {
          let step3 = stepAction(text: "3", color: .ganhoBloodAccent,
                                  beforeAnimate: { [weak self] in
                                      self?.label.setScale(1.0)
                                      onTick(3)
                                  })
          let step2 = stepAction(text: "2", color: .ganhoYellowF,
                                  beforeAnimate: { [weak self] in
                                      self?.label.setScale(1.0)
                                      onTick(2)
                                  })
          let step1 = stepAction(text: "1", color: .ganhoPinkNote,
                                  beforeAnimate: { [weak self] in
                                      self?.label.setScale(1.0)
                                      onTick(1)
                                  })
          let stepGo = goAction(onGo: onGo)
          let cleanup = SKAction.removeFromParent()
          let notify = SKAction.run(onComplete)
          run(.sequence([step3, step2, step1, stepGo, cleanup, notify]))
      }

      // MARK: - Step Actions
      /// 일반 단계(3/2/1) 한 묶음 — 텍스트/색 세팅 + 콜백 + 페이드인/홀드/페이드아웃.
      private func stepAction(text: String,
                               color: UIColor,
                               beforeAnimate: @escaping () -> Void) -> SKAction {
          let setup = SKAction.run { [weak self] in
              guard let self = self else { return }
              self.label.text = text
              self.label.fontColor = color
              self.label.alpha = 0
              beforeAnimate()
          }
          let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.countdownFadeInDuration)
          let hold    = SKAction.wait(forDuration: GameConfig.countdownHoldDuration)
          let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownFadeOutDuration)
          return .sequence([setup, fadeIn, hold, fadeOut])
      }

      /// GO! 단계 — scale 펄스 추가. fadeOut과 scale은 group으로 동시 진행.
      private func goAction(onGo: @escaping () -> Void) -> SKAction {
          let setup = SKAction.run { [weak self] in
              guard let self = self else { return }
              self.label.text = "GO!"
              self.label.fontColor = .ganhoMint
              self.label.alpha = 0
              self.label.setScale(1.0)
              onGo()
          }
          let fadeIn = SKAction.fadeIn(withDuration: GameConfig.countdownFadeInDuration)
          let scaleUp = SKAction.scale(to: GameConfig.countdownGoEndScale,
                                        duration: GameConfig.countdownGoHoldDuration)
          let hold   = SKAction.wait(forDuration: GameConfig.countdownGoHoldDuration)
          // hold와 scaleUp을 group으로 동시 — *커지면서 잠시 홀딩*
          let holdGroup = SKAction.group([hold, scaleUp])
          let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownGoFadeOutDuration)
          return .sequence([setup, fadeIn, holdGroup, fadeOut])
      }

      // MARK: - Configure
      private func configureLabel() {
          label.fontSize = GameConfig.countdownFontSize
          label.verticalAlignmentMode = .center
          label.horizontalAlignmentMode = .center
          label.position = .zero
      }
  }
  ```

**자가 소멸 노드 8호 패턴 답습 — 7호(ComboBreakNode)와의 차이**:
| 항목 | 7호 ComboBreakNode | 8호 CountdownNode |
|---|---|---|
| 진입점 | `animate()` 0인자 | `start(onTick:onGo:onComplete:)` 콜백 3개 |
| SKAction 구조 | `group([move, fade, scale])` | `sequence([step3, step2, step1, stepGo, cleanup, notify])` |
| 라벨 변경 | init에서 고정 | 단계마다 text/color 갱신 |
| 콜백 | 없음 | onTick/onGo/onComplete (햅틱·사운드·완료 전달) |
| weak self | 미사용 (self 미사용) | 사용 (label 갱신 + onComplete가 GameScene 호출) |

**weak self 캡처 정책**:
- `beforeAnimate` / `onGo` / `onComplete` 클로저는 외부에서 주입받은 *콜백*이라 그대로 호출만 — CountdownNode 내부에서 `[weak self]` 캡처 필요 0.
- 단, `setup` 액션 내부 `self.label.text = ...`는 self 사용 → `[weak self]` 캡처 필수.

### 기능 4: GameScene 흐름 재구성

- **설명**: `didMove(to:)`의 마지막 3줄(spawnSystem.start / gameState=playing / bgm.play)을 `startGameProperly()` helper로 분리. 그 자리에 `gameState = .countdown` + `showCountdown()` 추가.
- **구현 위치**: `GameScene.swift`
- **MARK 섹션 변경**:
  - `// MARK: - Lifecycle`의 `didMove(to:)` 끝부분 수정
  - `// MARK: - Game State` 위에 `// MARK: - Countdown (Phase 6-13)` 신규 섹션 추가
- **핵심 코드 구조**:

  ```swift
  // didMove(to:) 끝부분 — 기존 3줄 제거 후:
  override func didMove(to view: SKView) {
      // ... (기존 setup* 메서드들 변경 없음) ...
      physicsWorld.gravity = .zero
      configureContactRouter()
      physicsWorld.contactDelegate = contactRouter

      // Phase 6-13 — 게임 시작 전 카운트다운. .countdown 상태는 update의 모든
      // 시스템 로직(스폰/타이머/이동/카메라/적/콤보 폴링)을 자동 차단한다
      // (기존 `guard gameState == .playing` 가드 1개로 7개 시스템 동시 정지).
      // SpawnSystem.start / bgm.play / gameState = .playing 3개는 GO! 콜백
      // 시점(startGameProperly)에 이전.
      gameState = .countdown
      showCountdown()
  }

  // MARK: - Countdown (Phase 6-13)
  /// CountdownNode 생성 + cameraNode 부착 + start 진입점 호출.
  /// onTick(매 숫자): light 햅틱. onGo: heavy 햅틱 + comboMilestoneStrong 사운드.
  /// onComplete: startGameProperly()로 실제 게임 시동.
  /// weak self 캡처 필수 — onComplete가 self.startGameProperly 호출.
  private func showCountdown() {
      let node = CountdownNode()
      cameraNode.addChild(node)
      node.start(
          onTick: { [weak self] _ in
              self?.haptics.light()
          },
          onGo: { [weak self] in
              guard let self = self else { return }
              self.haptics.heavy()
              self.audio.play(.comboMilestoneStrong)
          },
          onComplete: { [weak self] in
              self?.startGameProperly()
          }
      )
  }

  /// GO! 카운트다운 종료 직후 호출. 실제 게임 시스템을 가동.
  /// 기존 didMove 끝의 3줄을 이쪽으로 이동 — 코드 자체는 동일.
  /// gameState .countdown → .playing 전환 시 update의 모든 가드가 해제됨.
  private func startGameProperly() {
      spawnSystem.start(
          scene: self,
          world: worldNode,
          player: player,
          enemy: enemy,
          progressProvider: { [weak self] in
              guard let self = self else { return 0 }
              return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
          }
      )
      gameState = .playing
      bgm.play()
  }
  ```

**주의 — spawnSystem.start 시그니처 일치**: Generator는 현재 `spawnSystem.start(...)` 호출의 인자(scene/world/player/enemy/progressProvider 등)를 *그대로* 이동만 한다. 인자 이름·순서 변경 금지.

## 주의사항

### 1. 기존 코드와 충돌 가능성
- **`update()`의 `guard gameState == .playing else { return }`**: 본 sprint의 핵심 안전망. `.countdown` 상태에서 자동 차단되어 7개 시스템이 정지하므로 *update 본문 수정 0줄*.
- **`endGame()`의 `gameState == .gameOver` 가드**: `.countdown` 상태에서는 `endGame` 호출 경로가 없음(스폰/적/F 모두 정지) → 안전.
- **`didChangeSize(_:)`**: layoutDPad / layoutHUD만 호출 — CountdownNode는 cameraNode 자식 좌표계 (0,0) 고정이라 viewport 리사이즈에 영향 없음. *추가 layout 코드 0줄*.

### 2. SpriteKit 특성상 주의할 점
- **SKAction.run 안에서 `self` 사용 시 `[weak self]` 필수**: CountdownNode의 `setup` 액션에서 `self.label.text` 갱신이 필요. 반드시 `SKAction.run { [weak self] in guard let self = self else { return }; ... }` 패턴.
- **cameraNode 자식 좌표계**: CountdownNode는 cameraNode 자식이라 (0,0) = 화면 중앙. label.position = .zero로 충분. worldNode 자식으로 잘못 부착하면 카메라 follow와 어긋남.
- **SKAction.sequence는 *순차 보장***: 4단계가 정확히 1초씩 차례 진행. 각 단계 내부의 setup(즉시) → fadeIn → hold → fadeOut도 직렬. group 안에 들어간 hold + scaleUp만 동시.
- **SelfDismissingNode 채택**: marker protocol이라 컴파일러 강제 사항 없음. 자가 소멸 노드 8호임을 *문서화*하는 용도.

### 3. 빌드 에러 가능성
- **GameState case 추가는 break 가능**: switch문이 GameState를 exhaustive하게 다루는 곳이 있으면 `.countdown` case 처리 강제. **수동 검증 필요**: `grep -rn "case .playing" --include="*.swift"`, `grep -rn "switch.*gameState" --include="*.swift"` — Generator가 모든 switch를 찾아 default가 있는지 또는 .countdown 명시가 필요한지 확인.
- **ColorTokens 4색 부재 가능성**: `.ganhoBloodAccent`, `.ganhoYellowF`, `.ganhoPinkNote`, `.ganhoMint` 4색이 `ColorTokens.swift`에 있는지 확인. 없으면 가장 가까운 색으로 대체 (`.ganhoMint` 부재 시 `.ganhoYellowF`).
- **pbxproj 4지점 등록**: 신규 파일 1개(`CountdownNode.swift`)는 UUID 0033(0032 ComboBreakNode 답습) 4지점(PBXBuildFile / PBXFileReference / PBXSourcesBuildPhase / PBXGroup) 등록 필수.
- **시뮬레이터 햅틱**: light/heavy 모두 시뮬레이터 noop — 실기기 검증 필요. 사용자가 직접 확인.
- **사운드 `comboMilestoneStrong`**: Bundle에 자작 음원 부재 시 NewMail 1025 systemSoundID 폴백 (AudioManager init이 graceful 처리) — 회귀 0.

### 4. 테스트 시나리오 (사용자 시뮬레이터 검증)
- [ ] TitleScene 탭 → GameScene 진입 → 0.4초 페이드 후 "3"이 빨강으로 화면 중앙에 등장 (≈1초 표시)
- [ ] "2"가 노랑으로 등장 (≈1초)
- [ ] "1"이 분홍으로 등장 (≈1초)
- [ ] "GO!"가 민트로 등장하며 *살짝 커지고* heavy 진동 + NewMail 사운드
- [ ] GO! 페이드아웃 직후 음표 스폰 시작 + 45초 타이머 시작 + BGM 페이드인 시작
- [ ] **카운트다운 중 D-Pad를 누르면 캐릭터 *이동 안 함*** (gameState != .playing)
- [ ] **카운트다운 중 적이 *추적 안 함***
- [ ] **카운트다운 중 F 투사체 *발사 안 됨***
- [ ] **카운트다운 중 음표 *스폰 안 됨***
- [ ] **카운트다운 중 타이머 *감소 안 함*** — HUD 시간 라벨이 00:45 유지
- [ ] **카운트다운 중 BGM *재생 안 됨*** — GO! 직후부터 페이드인
- [ ] GO! 이후 정상적으로 한 판 진행 → 콤보 10+ 끊김 시 6-12 ComboBreak 정상 동작 (회귀 0)
- [ ] 게임오버 후 ResultScene → TitleScene 복귀 → 다시 진입 시 카운트다운 *처음부터* 재발화
