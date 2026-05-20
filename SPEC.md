# Sprint 7 Phase C — 난이도 카드 색 위계 (V3)

## 개요
난이도 선택 화면(`DifficultySelectScene`)의 3장 카드에 **색 위계**를 부여한다. v2까지는 모든 카드가 동일 톤(피치)이었으나, v3에서는 하=민트 / 중=골드 / 상=코랄 그라데이션으로 *카드 배경 자체가* 난이도 강도를 전달한다. 선택 카드 뒤에 라디얼 글로우 + 미선택 카드 opacity 0.78로 시선을 유도하고, 시작 버튼은 입체 그림자 +halo로 "마지막 결정"임을 시각적으로 약속한다.

## 변경 유형
**비주얼**

## 게임 경험 의도
1. 사용자가 난이도 선택 화면에 들어선 첫 0.5초 안에 "하=민트 / 중=골드 / 상=코랄"이 카드 색만으로 즉시 보이게 한다 — 라벨 안 읽어도 강도가 느껴진다.
2. 선택한 카드 한 장이 *글로우 + 상승 + opacity 1.0*으로 화면에서 가장 강한 시선 자석이 되고, 나머지 두 장은 0.78로 자연스럽게 물러난다.
3. 시작 버튼이 화면 중앙 하단에서 입체 그림자 + halo(선택 시)로 "이게 마지막 탭"임을 약속한다.

## Sprint 7 Phase C 범위 계약

### 허용
- `Nodes/DifficultyCardNode.swift`: 카드별 색 lookup 적용, 미선택/선택 fill·stroke를 난이도별 색으로 분기, 선택 글로우(radial blur 80% effect) 색을 카드별 강조색으로 갱신, 헤더 폰트 30pt + stroke 카드별 색 동기화, 선택 시 position.y 액션 추가
- `Scenes/DifficultySelectScene.swift`: 시작 버튼 뒤에 halo SKShapeNode 부착, 좌측 미니 캐릭터 영역 속도배율 칩 stroke 추가
- `Config/ColorTokens.swift`: 신규 6 토큰 추가
- `Config/GameConfig.swift`: 신규 V3 상수 14종 추가
- `Models/Difficulty.swift`: 카드별 색 lookup 4개 computed property 추가 (3 case exhaustive switch, default 미사용)

### 금지 (0줄 변경)
- `Difficulty` enum 값 / case 이름 / raw value("easy", "normal", "hard")
- `Difficulty` 기존 `color` computed property 값(.ganhoMint/.ganhoYellowF/.ganhoBloodAccent)
- `DifficultySelectScene.init(characterID:)` 시그니처
- `transitionToGame()` → `GameScene.newGameScene(characterID:difficulty:)` 호출 시그니처
- `transitionBack()` 분기 로직 (.kim vs 그 외)
- `difficultyRepo.current` / `difficultyRepo.save(id)` 호출 패턴
- `selectDifficulty(_:)`의 `card.id` 비교 + 일괄 `setSelected` 호출 순서
- `PrimaryButtonNode` **내부 0줄** — halo는 Scene이 외부에서 별도 SKShapeNode 부착
- Phase A·B 결과물 (CharacterCardNode / CharacterSelectScene / CharacterID / PlayerSkill / SkillExplanationScene / `skillExplanation*V3` 상수)
- ResultScene / GameScene / GameState / PhysicsCategory / Managers / Repositories / Systems / 게임 로직 일체
- 기존 `difficultyCard*` 상수 값 (V3 접미사 없는 것 모두). V3 신규 상수만 추가

## 신규 mockup HTML 시각 사양 (`mockups/difficulty-select-v3.html`)

배경·폰트·상단 바·좌측 미니 캐릭터 골격은 v2와 동일하되, **3장 카드와 시작 버튼만 v3로 갱신**한다. Phase A·B v3 mockup과 톤 일관성 유지.

### 디바이스 프레임
- aspect-ratio 19.5/9, border-radius 52, padding 14
- phone-screen radial gradient (Phase A·B와 동일 3-stop)
- 좌측 Dynamic Island

### 상단 바 (v2 그대로)
- 좌상단: `← 스킬 다시` 또는 `← 캐릭터 다시` GlassPill
- 우상단: `캐릭터 · 스킬 · 난이도` DarkContextChip, `난이도` 코랄 알약

### 헤더 (v2 그대로)
- AccentLine 32×3 코랄 + Jua 26pt "난이도를 골라요" + Gowun 12pt 부제

### 좌측 미니 캐릭터 글래스 카드 (Phase C 보강)
- 폭 200 × 높이 260, border-radius 22, padding 16/14/14
- 배경 `rgba(255,255,255,0.85)` + backdrop blur 12, stroke `rgba(255,107,91,0.3)` 2pt
- 상단 -12 코랄 이름 뱃지
- CharacterFaceNode mini 90×90 가운데
- Jua 14pt 스킬명
- **속도 칩 강조**: 배경 `rgba(155,224,204,0.4)` + **stroke 1pt `#5EBFA3`** + box-shadow `0 2px 6px rgba(94,191,163,0.3)`

### 우측 난이도 3장 카드 (Phase C 핵심)
각 카드 폭 110 × 높이 약 124, border-radius 18, padding 14/8/16. 카드 간 gap 14.

**카드 배경 — 카드별 그라데이션**
- **하 (.easy)**: `linear-gradient(160deg, #9BE0CC, #5EBFA3)`
- **중 (.normal)**: `linear-gradient(160deg, #FFD27A, #E5A647)`
- **상 (.hard)**: `linear-gradient(160deg, #FF8E80, #FF6B5B)`
- stroke 미선택 시 카드별 stroke × 0.4, 선택 시 정색
- 미선택 alpha 0.78 / 선택 alpha 1.0

**카드 헤더 (이름)**
- v2 22pt → **v3 30pt** Jua, navy fill, 카드별 강조색 stroke 1pt (SpriteKit은 nameLabelStroke + nameLabel 2개 겹쳐 표현)

**카드 부제** v2 동일 (Gowun 11pt navy muted)

**카드 보조 라벨** v2 description Gowun 11pt 줄간격 1.4

**선택 상태**
- `transform: translateY(-8px) scale(1.05)` — 미세 상승 (v2 -6 → v3 **-8**)
- 카드 뒤 radial glow: 158 × 116, `id.cardGlowColor` α 0.8, filter blur 20px (SpriteKit은 SKShape ellipse + glowWidth 12pt 근사)
- 카드 stroke 미선택 0.4α → 선택 1.0
- 카드 alpha 0.78 → 1.0

### 시작 버튼 (Phase C 보강)
- 입체 그림자 6 → **8** (`0 8px 0 #C44A3D`)
- **halo 신규**: 240 × 90 ellipse, `#FF6B5B` α 0.35, filter blur 24px, 페이드 인 0.25s

### 음표 deco · annotation 박스 4개
1. "하·중·상 색만으로 강도 즉시 인지"
2. "선택 글로우 80% · 미선택 0.78 — 시선 자석"
3. "시작 버튼 halo = 마지막 결정"
4. SpriteKit 매핑 — Difficulty 4 lookup + Scene halo SKShape (PrimaryButtonNode 0줄)

## 기능 상세

### 기능 1: `Difficulty` 카드별 색 lookup 4개 computed property
**위치**: `Models/Difficulty.swift` 파일 끝 `// MARK: - Sprint 7 Phase C · Card hierarchy colors`

```swift
/// Sprint 7 Phase C — 카드 그라데이션 상단 색. lookup용. 게임 로직 분기 0.
var cardFillTop: UIColor {
    switch self {
    case .easy:   return .ganhoDifficultyEasyMint
    case .normal: return .ganhoDifficultyMidGold
    case .hard:   return .ganhoDifficultyHardCoral
    }
}

/// Sprint 7 Phase C — 카드 그라데이션 하단 색.
var cardFillBottom: UIColor {
    switch self {
    case .easy:   return .ganhoDifficultyEasyDeep
    case .normal: return .ganhoDifficultyMidDeep
    case .hard:   return .ganhoDifficultyHardDeep
    }
}

/// Sprint 7 Phase C — 카드 stroke 정색 (선택 시).
var cardStrokeColor: UIColor {
    switch self {
    case .easy:   return .ganhoDifficultyEasyDeep
    case .normal: return .ganhoDifficultyMidDeep
    case .hard:   return .ganhoDifficultyHardDeep
    }
}

/// Sprint 7 Phase C — 선택 카드 뒤 라디얼 글로우 색.
var cardGlowColor: UIColor {
    switch self {
    case .easy:   return .ganhoDifficultyEasyMint
    case .normal: return .ganhoDifficultyMidGold
    case .hard:   return .ganhoDifficultyHardCoral
    }
}
```

> Difficulty enum case 실제 이름은 코드에서 확인. easy/normal/hard가 아니라면 그에 맞게 3 case exhaustive switch.

### 기능 2: `ColorTokens.swift` 신규 6 토큰
**위치**: 파일 끝 새 MARK 섹션 `// MARK: - Sprint 7 Phase C · Difficulty hierarchy`

```swift
static let ganhoDifficultyEasyMint   = UIColor(hex: "#9BE0CC")
static let ganhoDifficultyEasyDeep   = UIColor(hex: "#5EBFA3")
static let ganhoDifficultyMidGold    = UIColor(hex: "#FFD27A")
static let ganhoDifficultyMidDeep    = UIColor(hex: "#E5A647")
static let ganhoDifficultyHardCoral  = UIColor(hex: "#FF6B5B")
static let ganhoDifficultyHardDeep   = UIColor(hex: "#C44A3D")
```

### 기능 3: `GameConfig.swift` Phase C V3 상수 14종
**위치**: 파일 끝 새 MARK 섹션 `// MARK: - Sprint 7 Phase C · Difficulty hierarchy v3`

```swift
static let difficultyCardNameFontSizePhaseC: CGFloat = 30
static let difficultyCardNameStrokeWidthPhaseC: CGFloat = 1.0
static let difficultyCardSelectedLiftY: CGFloat = 8
static let difficultyCardSelectedLiftDuration: TimeInterval = 0.18
static let difficultyCardSelectedGlowWidthPhaseC: CGFloat = 158
static let difficultyCardSelectedGlowHeightPhaseC: CGFloat = 116
static let difficultyCardSelectedGlowAlphaPhaseC: CGFloat = 0.80
static let difficultyCardSelectedGlowSpreadPhaseC: CGFloat = 12
static let difficultySelectStartButtonHaloWidth: CGFloat = 240
static let difficultySelectStartButtonHaloHeight: CGFloat = 90
static let difficultySelectStartButtonHaloAlpha: CGFloat = 0.35
static let difficultySelectStartButtonHaloSpread: CGFloat = 24
static let difficultySelectStartButtonHaloFadeInDuration: TimeInterval = 0.25
static let difficultySelectStartButtonHaloOffsetY: CGFloat = 0
```

### 기능 4: `DifficultyCardNode.setSelected(_:)` 카드별 색 lookup
- init / setSelected에서 `id.color` 일색 분기를 `id.cardFillTop`/`cardStrokeColor`/`cardGlowColor` 패턴으로 교체
- ringGlow.strokeColor를 `id.cardGlowColor` 사용
- 선택 시 position.y +8 lift 액션 — `liftCurrentOffset` 증분 추적
- 시그니처(`init(id:)`/`setSelected(_:)`) byte-identical

```swift
// 신규 프로퍼티
private let nameLabelStroke = SKLabelNode()
private var liftCurrentOffset: CGFloat = 0

// setSelected 핵심
background.fillColor = selected
    ? id.cardFillTop.withAlphaComponent(GameConfig.difficultyCardSelectedFillAlphaV3)
    : id.cardFillTop.withAlphaComponent(GameConfig.difficultyCardDeselectedFillAlphaV3)
background.strokeColor = selected
    ? id.cardStrokeColor
    : id.cardStrokeColor.withAlphaComponent(GameConfig.difficultyCardDeselectedStrokeAlphaV3)

ringGlow.strokeColor = id.cardGlowColor
let targetAlpha: CGFloat = selected
    ? GameConfig.difficultyCardSelectedGlowAlphaPhaseC : 0.0
// ... ringGlow fade 액션 ...

// lift 액션
removeAction(forKey: "cardLift")
let targetY: CGFloat = selected ? GameConfig.difficultyCardSelectedLiftY : 0
let lift = SKAction.moveBy(x: 0, y: targetY - liftCurrentOffset,
    duration: GameConfig.difficultyCardSelectedLiftDuration)
lift.timingMode = .easeOut
run(lift, withKey: "cardLift")
liftCurrentOffset = targetY
```

> 기존 V3 상수(difficultyCardDeselectedFillAlphaV3, DeselectedStrokeAlphaV3, SelectedFillAlphaV3, StrokeLineWidthV3, RingGlowFadeIn/Out 등)는 코드에서 확인. 없는 상수면 SPEC §기능 3에 누락된 것 — Generator가 발견 시 GameConfig에 추가.

### 기능 5: 헤더(nameLabel) 폰트 30pt + 카드별 stroke 외곽선
- 베이스 stroke 라벨 + 위 nameLabel 2개 겹쳐 stroke 효과
- nameLabelStroke 폰트 = `30 + strokeWidth × 2` = 32pt, fontColor `id.cardStrokeColor`
- nameLabel 폰트 30pt, navy
- nameLabelStroke.zPosition = nameLabel.zPosition - 0.1

### 기능 6: `DifficultySelectScene` 시작 버튼 halo SKShapeNode
**위치**: `Scenes/DifficultySelectScene.swift` — `setupStartButton()` + `layoutStartButton()`

```swift
private var startButtonHalo: SKShapeNode?

private func setupStartButton() {
    let halo = SKShapeNode(ellipseOf: CGSize(
        width: GameConfig.difficultySelectStartButtonHaloWidth,
        height: GameConfig.difficultySelectStartButtonHaloHeight))
    halo.fillColor = UIColor.ganhoCoralPrimary
        .withAlphaComponent(GameConfig.difficultySelectStartButtonHaloAlpha)
    halo.strokeColor = .clear
    halo.lineWidth = 0
    halo.glowWidth = GameConfig.difficultySelectStartButtonHaloSpread
    halo.alpha = 0
    halo.zPosition = startButton.zPosition - 1
    halo.name = "difficultySelectStartButtonHalo"
    startButtonHalo = halo
    addChild(halo)
    halo.run(SKAction.fadeAlpha(to: 1.0,
        duration: GameConfig.difficultySelectStartButtonHaloFadeInDuration))
    addChild(startButton)
    layoutStartButton()
}

private func layoutStartButton() {
    let pos = CGPoint(x: frame.midX,
        y: frame.midY + GameConfig.difficultySelectStartButtonOffsetY)
    startButton.position = pos
    startButtonHalo?.position = CGPoint(x: pos.x,
        y: pos.y + GameConfig.difficultySelectStartButtonHaloOffsetY)
}
```

### 기능 7: 좌측 미니 캐릭터 속도배율 칩 stroke 보강
**위치**: `Scenes/DifficultySelectScene.swift` — `setupSummaryCard()` 안 속도 칩

```swift
chip.fillColor = UIColor.ganhoScrubMint
    .withAlphaComponent(GameConfig.difficultySelectSummarySpeedChipFillAlpha)
chip.strokeColor = .ganhoDifficultyEasyDeep   // = #5EBFA3
chip.lineWidth = 1
chip.zPosition = 110
```

## 합격 기준 (Sprint 7 Phase C 한정)

### 시각 합격 기준 (SPRINT_7_REQUEST.md §4.4)
- [ ] 시뮬레이터에서 .easy / .normal / .hard 3개 카드 fill 색이 즉시 구분됨
- [ ] 카드 헤더 폰트 30pt + 카드별 stroke 외곽선 시각 인지
- [ ] 미선택 카드 alpha 0.78 / 선택 카드 alpha 1.0 + 글로우 ON
- [ ] 선택 카드 +8pt 상승 + scale 1.05
- [ ] 시작 버튼 halo 페이드 인 0.25s 자연스러움
- [ ] 시작 버튼 입체 그림자 +2pt 강화

### 코드 합격 기준
- [ ] `DifficultySelectScene.init(characterID:)` 시그니처 0줄 변경
- [ ] `transitionToGame()` → `GameScene.newGameScene(characterID:difficulty:)` byte-identical
- [ ] `transitionBack()` .kim 분기 byte-identical
- [ ] `Difficulty` enum 기존 멤버(`color`/`displayName`/`subtitle`/`description`/`shortName`/raw value) 100% 보존
- [ ] `PrimaryButtonNode` 내부 0줄
- [ ] ResultScene / GameScene / Models 외 파일 / Managers / Repositories / Systems 0줄
- [ ] Phase A·B 결과물 0줄
- [ ] 강제 언래핑 0, Timer 0, update() 안 addChild 0, switch default 미사용
- [ ] 매직 넘버 0 — 모든 신규 수치는 V3 상수 참조
- [ ] 하드코딩 hex 0 — ColorTokens 경유

### 평가 4-카테고리 통과선
| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 |
| Swift 패턴 | 20% | 7.0 |
| 비주얼 일관성 (mockup) | 25% | 7.0 (difficulty-select-v3.html 매칭 ≥ 85%) |
| 가독성 & UX | 15% | 7.0 |

가중 평균 **7.5 이상**이면 ✅ 합격.

## 변경 LOC 추정치

| 파일 | 신규 | 수정 | 합계 |
|---|---|---|---|
| `Config/ColorTokens.swift` | ~12 | 0 | ~12 |
| `Config/GameConfig.swift` | ~38 | 0 | ~38 |
| `Models/Difficulty.swift` | ~32 | 0 | ~32 |
| `Nodes/DifficultyCardNode.swift` | ~25 | ~12 | ~37 |
| `Scenes/DifficultySelectScene.swift` | ~28 | ~6 | ~34 |
| `mockups/difficulty-select-v3.html` | ~350 | 0 | ~350 |
| **Swift 합계** | **~135** | **~18** | **~153** |

SPRINT_7_REQUEST.md §1 Phase C 예상치 ~200 — 합리적 범위 (-47).

## OPEN_QUESTION

**OQ-1 (결정됨)**: `DifficultyCardNode`는 별도 파일 (`Nodes/DifficultyCardNode.swift` ~185 LOC). 기존 V3 1.4배 확장 완료. Phase C는 색 lookup 추가만.

**OQ-2 (결정됨)**: 좌측 미니 캐릭터 `CharacterFaceNode mini factory` 재사용 — 기존 `setScale(GameConfig.difficultySelectSummaryFaceScale = 0.65)` 패턴 그대로. mini factory 신설 0건. ScoreboardScene(Phase D) 가서 도입.

**OQ-3 (결정됨)**: 시작 버튼 halo는 **Scene에서 별도 SKShapeNode 부착**. PrimaryButtonNode 0줄 변경. 다른 화면 회귀 위험 0.

**OQ-4 (결정됨)**: 선택 카드 -8pt 상승은 카드 노드 전체 position 이동 + `liftCurrentOffset` 증분 추적. mockup CSS `transform: translateY(-8px)`와 일관(모든 자식 함께 올라감).

## 주의사항

### Phase C 특유 위험
1. **`Difficulty.color` 기존 computed property 보존** — 새 `cardFillTop`은 별도. 기존 `.color` 사용처 회귀 0.
2. **`liftCurrentOffset` 증분 패턴** — setSelected 중복 호출 시 position 누적 방지.
3. **`ringGlow.strokeColor`는 setSelected에서 매번 재설정** — 카드 인스턴스 자체는 id 고정이라 init에서 1회로 충분하나 가독성 위해 명시.
4. **`nameLabelStroke` zPosition** — nameLabel zPos 그대로(기존 5), strokeLabel은 z=4.9 (뒤).
5. **시작 버튼 halo zPosition** — startButton보다 -1. hit-test는 startButton이 먼저 받음.
6. **`SKShapeNode.glowWidth` 한계** — 진정한 Gaussian blur는 없음. stroke를 확장하는 효과. mockup `filter: blur(24px)`는 근사.

### 일반 Swift / SpriteKit
7. **`default` case 미사용** — 4개 신규 computed property 모두 3 case exhaustive.
8. **하드코딩 hex 0** — 모든 색은 ColorTokens 경유.
9. **클로저 self 캡처** — SKAction 안 self 접근 시 `[weak self]`. Phase C 신규 클로저 없음.

---

## 관련 파일 (절대 경로)

- 수정 대상:
  - `GanhoMusic/GanhoMusic Shared/Models/Difficulty.swift`
  - `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift`
  - `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
  - `GanhoMusic/GanhoMusic Shared/Nodes/DifficultyCardNode.swift`
  - `GanhoMusic/GanhoMusic Shared/Scenes/DifficultySelectScene.swift`
- 신규:
  - `mockups/difficulty-select-v3.html`
- 시각 레퍼런스 (읽기):
  - `mockups/difficulty-select-v2.html`
  - `mockups/character-select-v3.html`, `mockups/skill-explanation-v3.html`
