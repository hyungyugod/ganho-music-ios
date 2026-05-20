# Sprint 7 Phase E — 카운트다운 오버레이 + dim 배경 + 코랄 GO! + Jua 폰트

## 개요
게임 시작 직전 약 1~2초간 입력이 막혀 있는 동안 시각 피드백이 부족해 "멈춘 줄 알았다"는 인상이 나오는 문제를 해결한다. 기존 Phase 6-13에서 이미 구현되어 있는 `CountdownNode`(3 → 2 → 1 → GO!)를 v2 디자인 시스템(Jua 폰트 / navy 숫자 / 코랄 GO! / navyDeep dim 오버레이)에 맞춰 보강하고, GameScene 시작 시퀀스에 dim 오버레이를 추가하여 카운트다운이 명확히 "준비 시간"임을 시각적으로 표현한다. 입력 게이트는 이미 `gameState == .playing` 가드로 완벽히 차단되어 있으므로 *게이트 시점만* 카운트다운 종료 콜백에 정확히 정렬한다.

## 변경 유형
**비주얼 + 입력 게이트 보강** — 게임 로직(점수/물리/적 AI) 변경 0건.

## 게임 경험 의도
- "지금은 준비 시간이다 — 입력은 곧 활성화된다"는 메시지가 즉시 전달
- dim 오버레이(navyDeep alpha 0.32)가 화면을 살짝만 덮어 게임 월드는 보이되 "아직 시작 전"임을 명확히
- 3·2·1은 차분한 navy 톤(긴장 누적), GO!는 따뜻한 코랄 톤(폭발적 시작)으로 색 대비를 통해 "준비 → 출발" 감정 전환

## Sprint 7 Phase E 범위 계약

### 허용
- CountdownNode 색/폰트/scale 갱신 (시그니처 byte-identical)
- GameScene.showCountdown에 dim 오버레이 attach·페이드·자가 소멸 시퀀스 추가
- GameConfig 신규 V3 상수 9개
- 신규 mockup HTML 1개

### 금지 (0줄)
- 게임 루프 update / 물리 / 점수 / 입력 처리 함수 자체 / AI / 저장 / 사운드 발화 신호
- DPadNode / SkillButtonNode / SkillSystem / SpawnSystem / ContactRouter / ScoreSystem
- Phase A·B·C·D 결과물 일체
- GameState enum / PhysicsCategory / Managers (AudioManager 포함) / Repositories / Systems
- 다른 Scenes (Character/Skill/Difficulty/Result/Scoreboard/Start)

## 현황 파악 (Generator 필수)

### 1) CountdownNode 현재 상태 — 이미 존재
- 파일: `Nodes/CountdownNode.swift` (Phase 6-13에서 신설)
- 시그니처: `init()` + `start(onTick:onGo:onComplete:)` — Sprint 7 사양과 가까움. **새로 만들지 말고 보강만**.
- 호출부: `GameScene.showCountdown()` 안 `let node = CountdownNode(); cameraNode.addChild(node); node.start(...)` 패턴 이미 사용 중.
- 현재 단점 4가지:
  1. `SKLabelNode(text: "")` — fontName 0 → 시스템 폰트 (Jua 미적용)
  2. 색 3=blood/2=yellow/1=pink/GO=mint — Sprint 7 v3 톤(navy + coral)과 불일치
  3. fontSize 96 — Sprint 7 사양 숫자 120 / GO 140
  4. GO scale 1.0→1.3 — Sprint 7 사양 1.2→1.8
- 한 단계 총 1.0s (fadeIn 0.1 + hold 0.7 + fadeOut 0.2) — SPRINT_7_REQUEST §6.2 "0.0s~1.0s : 3"와 정확히 일치 ✅ 변경 불필요

### 2) 입력 게이트 — 이미 차단됨
- DPadNode: isUserInteractionEnabled true 유지
- `GameScene.update()` 안 `guard gameState == .playing else { return }` 가드 — dpad→player 라인 차단
- gameState 전이: .cutscene → .countdown → .playing (startGameProperly 안 마지막)
- **결론**: 추가 게이트 코드 0줄. SPRINT_7_REQUEST §6.5 "D-pad 탭 무시" 이미 보장.

### 3) GO! 종료 직후 음표 첫 발생 — 이미 일치
- `startGameProperly()`가 CountdownNode onComplete에서 호출. 안에서 `spawnSystem.start(...)` 호출 후 `gameState = .playing` 전환.
- **결론**: 시점 이미 정확. 호출 순서 0줄 변경.

### 4) AudioManager tick/chime 키 — 부재
- 현재 4개 키 (.noteCollected/.gameOver/.comboMilestoneSoft/.comboMilestoneStrong). tick/chime 0건.
- SPRINT_7_REQUEST §6.3 "사운드 추가는 후속" 명시 → 본 Phase E 사운드 코드 변경 0.

## 변경 범위

### 수정 파일
- `Nodes/CountdownNode.swift` — 폰트(Jua) 부여 / 색 4개 갱신 / fontSize 분기 (숫자 120 / GO 140) / scale 1.2→1.8
- `GameScene.swift` — `showCountdown()`에 dim 오버레이 attach + 페이드인 + onComplete에서 페이드아웃·제거·startGame 시퀀스
- `Config/GameConfig.swift` — V3 신규 상수 9개

### 추가 파일
- `mockups/countdown-overlay-v1.html` — 4프레임 시각 시안 (3·2·1·GO!)

### 절대 변경 금지
- DPadNode / SkillButtonNode / SkillSystem / SpawnSystem / ContactRouter / ScoreSystem / GameScene+Setup
- GameState / PhysicsCategory / 모든 Repositories / 모든 Managers
- Phase A·B·C·D에서 만진 모든 Scenes·Nodes

## 기능 상세

### 기능 1: CountdownNode 시각 v3 보강

**변경점 4개**:
1. init의 `SKLabelNode(text: "")`를 `SKLabelNode(fontNamed: GameConfig.fontDisplay)`로 교체 (Jua-Regular)
2. `start(...)` 안 색 인자 3개: blood/yellow/pink → 모두 `.ganhoNavyDeep`
3. `stepAction` setup 액션에 `self.label.fontSize = GameConfig.countdownNumberFontSizeV3` (120pt) 갱신 추가; `goAction` setup에 `self.label.fontSize = GameConfig.countdownGoFontSizeV3` (140pt) 갱신 추가
4. `goAction`의 색 `.ganhoMint` → `.ganhoCoralPrimary`, setup의 `setScale(1.0)` → `setScale(GameConfig.countdownGoStartScaleV3)` (1.2), `SKAction.scale(to: ..., duration:)` 인자를 `GameConfig.countdownGoEndScaleV3` (1.8)로 교체

**핵심 코드 (의사코드)**:
```swift
// init() 변경
override init() {
    self.label = SKLabelNode(fontNamed: GameConfig.fontDisplay)  // Jua
    super.init()
    // ...
}

// start(...) 안 — 색 3개 통일
let step3 = stepAction(text: "3", color: .ganhoNavyDeep) { onTick(3) }
let step2 = stepAction(text: "2", color: .ganhoNavyDeep) { onTick(2) }
let step1 = stepAction(text: "1", color: .ganhoNavyDeep) { onTick(1) }

// stepAction 안 setup 액션에 fontSize 갱신
let setup = SKAction.run { [weak self] in
    guard let self = self else { return }
    self.label.text = text
    self.label.fontColor = color
    self.label.fontSize = GameConfig.countdownNumberFontSizeV3   // 신규 1줄
    self.label.alpha = 0
    self.label.setScale(1.0)
    onTick()
}

// goAction 안 setup
let setup = SKAction.run { [weak self] in
    guard let self = self else { return }
    self.label.text = "GO!"
    self.label.fontColor = .ganhoCoralPrimary                      // 변경
    self.label.fontSize = GameConfig.countdownGoFontSizeV3         // 신규
    self.label.alpha = 0
    self.label.setScale(GameConfig.countdownGoStartScaleV3)        // 1.2
    onGo()
}
let scaleUp = SKAction.scale(to: GameConfig.countdownGoEndScaleV3, // 1.8
                             duration: GameConfig.countdownGoHoldDuration)
```

### 기능 2: GameScene.showCountdown에 dim 오버레이

```swift
private func showCountdown() {
    // 1) dim 오버레이 — cameraNode 자식, navyDeep × 0.32, 자연 페이드인
    let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
    dim.alpha = 0
    dim.zPosition = GameConfig.countdownDimZPosition  // 240 (CountdownNode 250 아래)
    dim.name = GameConfig.countdownDimNodeName
    cameraNode.addChild(dim)
    dim.run(.fadeAlpha(to: GameConfig.countdownDimAlpha,
                       duration: GameConfig.countdownDimFadeInDuration))

    // 2) 기존 CountdownNode attach + start
    let node = CountdownNode()
    cameraNode.addChild(node)
    node.start(
        onTick: { [weak self] _ in self?.haptics.light() },
        onGo: { [weak self] in
            guard let self = self else { return }
            self.haptics.heavy()
            self.audio.play(.comboMilestoneStrong)
        },
        onComplete: { [weak self] in
            guard let self = self else { return }
            // 3) dim 페이드아웃 → 제거 → startGameProperly
            let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownDimFadeOutDuration)
            let cleanup = SKAction.removeFromParent()
            let startGame = SKAction.run { [weak self] in self?.startGameProperly() }
            dim.run(.sequence([fadeOut, cleanup, startGame]))
        }
    )
}
```

**주의**: `startGameProperly()` 호출이 dim fadeOut *후*로 0.2초 미뤄지므로 총 카운트다운 4.0s = 1.0(3) + 1.0(2) + 1.0(1) + 0.8(GO!) + 0.2(dim) 일치. 첫 음표 spawn은 dim 사라진 직후로 시각 연속감 확보.

### 기능 3: GameConfig V3 신규 상수 9개

**위치**: `Config/GameConfig.swift` MARK `Countdown (Phase 6-13)` 아래 새 sub-section `// MARK: - Countdown V3 (Sprint 7 Phase E)`

```swift
/// V3 카운트다운 숫자(3·2·1) 폰트 크기. V2 96 → 120 (화면 중앙 단독 강조).
static let countdownNumberFontSizeV3: CGFloat = 120
/// V3 GO! 폰트 크기. 숫자보다 큼 — "출발의 폭발" 톤.
static let countdownGoFontSizeV3: CGFloat = 140
/// V3 GO! scale 시작값. V2 1.0 → 1.2 — 등장부터 임팩트.
static let countdownGoStartScaleV3: CGFloat = 1.2
/// V3 GO! scale 끝값. V2 1.3 → 1.8 — 더 큰 펄스.
static let countdownGoEndScaleV3: CGFloat = 1.8
/// V3 dim 오버레이 알파. navyDeep × 0.32.
static let countdownDimAlpha: CGFloat = 0.32
/// V3 dim 페이드인 길이(초). 카운트다운 등장 동기.
static let countdownDimFadeInDuration: TimeInterval = 0.2
/// V3 dim 페이드아웃 길이(초). GO! 종료 직후 0.2초로 자연 밝아짐.
static let countdownDimFadeOutDuration: TimeInterval = 0.2
/// V3 dim zPosition. 240 (CountdownNode 250 아래, HUD/Combo/HitFlash 위).
static let countdownDimZPosition: CGFloat = 240
/// V3 dim 노드 name — 디버그/회귀 검증용.
static let countdownDimNodeName: String = "countdownDim"
```

### 기능 4: mockups/countdown-overlay-v1.html

**핵심 사양**:
- 4프레임 (3·2·1·GO!) 가로 4열, 각 카드 240×135 (16:9 미니 게임 화면)
- 각 카드 = "게임 월드 일부 + navyDeep alpha 0.32 dim + 중앙 숫자"
- 폰트: Jua / fallback sans-serif
- 색: 3·2·1 navy `#2D2A4A` / GO! 코랄 `#FF6B5B`
- 사이즈: 숫자 72pt 축소 / GO! 84pt
- 캡션: "0.0~1.0s : 3" / "1.0~2.0s : 2" / "2.0~3.0s : 1" / "3.0~3.8s : GO!"
- 상단 타이틀 + 하단 메모 ("총 4.0s · 3.8~4.0s dim 페이드아웃 + 입력 활성화")
- CSS 인라인, JS 0줄

## 합격 기준 (SPRINT_7_REQUEST.md §6.5)

- 시뮬레이터에서 게임 시작 후 4초 안에 "3 → 2 → 1 → GO!" 4단계 모두 보임
- GO! 종료 즉시(<0.2s) 음표 첫 발생 (이미 보장)
- 카운트다운 도중 D-pad 탭 무시 (이미 보장)
- dim 오버레이 navyDeep alpha 0.32 — GO! 종료 직후 0.2초로 자연 사라짐
- 3·2·1 navy, GO! 코랄 색 대비
- 폰트 Jua-Regular
- 숫자 120pt, GO! 140pt
- mockup 4프레임 시각 확인

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 |
| Swift 패턴 | 20% | 7.0 |
| 비주얼 일관성 | 25% | 7.0 (mockup 매칭 ≥ 85%) |
| 가독성 & UX | 15% | 7.0 |

가중 평균 7.5 이상 합격.

## 변경 LOC 추정치

| 파일 | LOC | 비고 |
|---|---|---|
| `CountdownNode.swift` | ~12 | init 1 / setup fontSize 2 / start 색 3 / goAction 색·scale 3 |
| `GameScene.swift` | ~20 | showCountdown dim 시퀀스 |
| `GameConfig.swift` | ~30 | V3 상수 9개 + MARK |
| `mockups/countdown-overlay-v1.html` | ~140 | 4프레임 CSS + SVG 미니 |
| **합계** | **~200** | Swift만 ~62 (사양 ~100 부합) |

## OPEN_QUESTION (모두 결정됨)

**OQ-1**: CountdownNode 시그니처 — 기존 `init()` + `start(onTick:onGo:onComplete:)` 그대로 유지. Sprint 7 사양 "static func bigCenter / func start(completion:)"는 기존이 *더 풍부*하므로 채택 안 함.

**OQ-2**: 입력 게이트 — 이미 `gameState == .playing` 가드 차단. 추가 코드 0줄.

**OQ-3**: GO! 종료 직후 첫 음표 — 이미 정확. dim fadeOut 0.2s가 startGameProperly 직전이라 첫 spawn은 dim 사라진 직후.

**OQ-4**: AudioManager 키 — tick/chime 부재. 본 Phase E 사운드 코드 변경 0.

## 주의사항

- 회귀 0 1순위: CountdownNode.start 시그니처 변경 금지.
- dim zPosition 정합: 240 (CountdownNode 250 아래).
- CountdownNode 자가 소멸 + dim 자가 소멸 별도 보장.
- `.run { [weak self] in self?.startGameProperly() }` weak self 캡처 필수.
- fontName 누락 시 SKLabelNode 시스템 폰트 fallback — Jua-Regular ttf 번들 의존.
- `.ganhoNavyDeep`은 ColorTokens.swift 정의.
- Phase E 절대 금기 재확인: SkillButtonNode / SkillSystem / SpawnSystem / ContactRouter / ScoreSystem / 모든 Repositories / AudioManager / GameState / PhysicsCategory / 다른 Scenes — 0줄.

## 관련 파일 (절대 경로)

- 수정: `GanhoMusic/GanhoMusic Shared/Nodes/CountdownNode.swift`, `GameScene.swift`, `Config/GameConfig.swift`
- 신규: `mockups/countdown-overlay-v1.html`
- 참조: `Config/ColorTokens.swift`, `mockups/game-map-v2.html`
