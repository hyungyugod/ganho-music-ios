# Phase 8-3 — 원본 디자인 토큰 + TitleScene 동일화

## 개요
원본 웹게임의 디자인 시스템(CSS 변수 + 카드 시각 + 패널 레이아웃)을 Swift 토큰으로 옮긴다. 사용자 의도: *조작·맵·카메라만 모바일, 디자인은 원본 그대로*. 이번 sprint는 *디자인 토큰 인프라* + TitleScene의 *시각 외관 동일화* (반투명 검정 배경 + 가운데 카드 패널 + 카드 시각 원본화).

## 변경 유형
**비주얼**

## Sprint 범위 계약

### 허용
1. `Config/ColorTokens.swift` — `// MARK: - Game UI Tokens (Phase 8-3)` 섹션 + 원본 CSS 변수 매핑 ~14색
2. `Config/GameConfig.swift` — `// MARK: - Game UI Tokens (Phase 8-3)` 섹션 + 패널/카드 디자인 상수 ~16개
3. `Scenes/TitleScene.swift` — 배경에 반투명 검정 사각형 + 가운데 가시 가능한 카드 패널 SKShapeNode 추가. 기존 라벨/카드 위치는 보존하되 패널 *안*에 들어가는 시각으로.
4. `Nodes/CharacterCardNode.swift` — 카드 시각 토큰 갈아 끼움 (배경 ganhoUIBgCard, 선택 시 ganhoUIBrandBorder, 텍스트 ganhoUIText). 카드 크기/위치는 그대로.
5. `Nodes/DifficultyCardNode.swift` — 동일 정책. 캡슐 모양(코너 반경 999) 적용.

### 금지
1. 카드 *위치*/크기 변경 — 7-5 핫픽스 결과 보존
2. ResultScene / GameScene / 컷씬 노드 변경 — 다음 sprint
3. HUD 디자인 변경 — Phase 8-5
4. 졸업장 디자인 변경 — Phase 8-4
5. 픽셀 캐릭터 카드 아바타 — Phase 8-3 후속 (시간 부족 시 다음 sprint)
6. 폰트 패밀리 변경 — SKLabelNode가 시스템 폰트만 안전 지원 → 색·크기만 변경
7. 신규 노드/매니저/리포지토리

### 판단 기준
"이 변경 없으면 TitleScene이 원본과 시각적으로 다른가?" → YES만 허용.

## 변경 범위

### 수정
- `Config/ColorTokens.swift` — 디자인 토큰 14색 추가
- `Config/GameConfig.swift` — 디자인 layout 상수 16개 추가
- `Scenes/TitleScene.swift` — 배경 사각형 + 카드 패널 SKShapeNode 추가 (didMove 안)
- `Nodes/CharacterCardNode.swift` — 시각 토큰 갈아 끼움
- `Nodes/DifficultyCardNode.swift` — 시각 토큰 갈아 끼움

### 신규 파일 0개, pbxproj 변경 0건.

---

## 기능 1: ColorTokens 디자인 토큰 14색 (원본 CSS L4-23)

```swift
// MARK: - Game UI Tokens (Phase 8-3)
/// 원본 웹게임 style.css :root CSS 변수 1:1 매핑.
static let ganhoUIBg = UIColor(hex: "#0f0e15")          // --bg
static let ganhoUIBgDark = UIColor(hex: "#09080f")      // --bg-dark
static let ganhoUIBgCard = UIColor(hex: "#17151e").withAlphaComponent(0.82)  // --bg-card rgba(23,21,30,0.82)
static let ganhoUIBrand = UIColor(hex: "#c4847a")       // --brand 코럴
static let ganhoUIBrandLight = UIColor(hex: "#d4a49c")  // --brand-light
static let ganhoUIBrand12 = UIColor(hex: "#c4847a").withAlphaComponent(0.12)
static let ganhoUIBrand20 = UIColor(hex: "#c4847a").withAlphaComponent(0.20)
static let ganhoUIBrand40 = UIColor(hex: "#c4847a").withAlphaComponent(0.40)
static let ganhoUIBrand60 = UIColor(hex: "#c4847a").withAlphaComponent(0.60)
static let ganhoUIText = UIColor(hex: "#eeeeee")        // --text
static let ganhoUITextMuted = UIColor(hex: "#aaaaaa")   // --text-muted
static let ganhoUITextDim = UIColor(hex: "#555555")     // --text-dim
static let ganhoUIBorder = UIColor.white.withAlphaComponent(0.07)  // --border
static let ganhoUIOverlayBg = UIColor(hex: "#09080f").withAlphaComponent(0.78)  // overlay 배경
```

## 기능 2: GameConfig UI Layout 상수 16개

```swift
// MARK: - Game UI Tokens (Phase 8-3)
/// 원본 game.css 패널/카드 layout. 1:1 매핑.
static let uiRadius: CGFloat = 10              // --radius
static let uiRadiusSm: CGFloat = 6             // --radius-sm
static let uiRadiusPill: CGFloat = 999          // 난이도 버튼 캡슐
static let uiPanelMaxWidth: CGFloat = 360      // 일반 패널
static let uiPanelCharacterMaxWidth: CGFloat = 480  // character 패널
static let uiPanelPaddingH: CGFloat = 20
static let uiPanelPaddingV: CGFloat = 22
static let uiPanelGap: CGFloat = 14             // 패널 안 요소 간 간격
static let uiTitleFontSize: CGFloat = 22
static let uiBodyFontSize: CGFloat = 12
static let uiHintFontSize: CGFloat = 11
static let uiHudValueFontSize: CGFloat = 22
static let uiHudLabelFontSize: CGFloat = 10
static let uiCardNameFontSize: CGFloat = 12
static let uiCardTagFontSize: CGFloat = 10
static let uiCardBestFontSize: CGFloat = 10
static let uiPanelLineWidth: CGFloat = 1        // border 두께
```

## 기능 3: TitleScene 패널 도입

현재 TitleScene에서 라벨 5개 + 캐릭터 카드 5장 + 난이도 카드 3장이 *씬에 직접* 부착되어 있다. 신규로 *배경 반투명* + *가운데 패널 카드*를 추가.

```swift
// TitleScene.didMove(to:) 안 setupLabels() 직전에 추가
private func setupOverlayPanel() {
    // 1) 화면 전체 반투명 검정 배경 (원본 .game-overlay 배경)
    let bg = SKSpriteNode(color: .ganhoUIOverlayBg, size: size)
    bg.position = CGPoint(x: frame.midX, y: frame.midY)
    bg.zPosition = -10
    addChild(bg)

    // 2) 가운데 카드 패널 (원본 .game-overlay__panel--character 480px)
    let panelWidth = GameConfig.uiPanelCharacterMaxWidth
    let panelHeight: CGFloat = 480  // 세로는 컨텐츠 기준 동적 — 임시 고정값
    let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight),
                            cornerRadius: GameConfig.uiRadius)
    panel.fillColor = .ganhoUIBgCard
    panel.strokeColor = .ganhoUIBorder
    panel.lineWidth = GameConfig.uiPanelLineWidth
    panel.position = CGPoint(x: frame.midX, y: frame.midY)
    panel.zPosition = -5
    addChild(panel)
}
```

`didMove` 안에서 `setupLabels()` *전*에 `setupOverlayPanel()` 호출. 패널이 *제일 뒤 (zPosition -5)*에 있어 라벨/카드가 그 위에 자연 표시.

## 기능 4: CharacterCardNode 시각 토큰 적용

현재 CharacterCardNode의 배경색 / 보더 / 라벨 색을 원본 디자인 토큰으로 교체:

```swift
// 배경 (선택 안 됨)
background.color = .ganhoUIBgCard
// 보더는 SKShapeNode로 변경 — SKSpriteNode는 stroke 없음.
// 또는 별도 SKShapeNode를 자식으로 추가해 stroke 라인 표시.

// 이름 라벨
nameLabel.fontColor = .ganhoUITextMuted   // 기본 muted
nameLabel.fontSize = GameConfig.uiCardNameFontSize

// 선택 시 setSelected(true):
nameLabel.fontColor = .ganhoUIBrandLight
// 배경 색 ganhoUIBrand12 (코럴 12% 알파)
// 보더 ganhoUIBrand60
```

근데 SKSpriteNode는 stroke 없으므로 **카드를 SKShapeNode로 전환**해야 정확한 원본 시각. 큰 변경.

**대안 (본 sprint)**: 카드의 *기본 색만* 갈아 끼우고 *보더는 자식 SKShapeNode*로 추가. 카드 자체 구조 보존.

```swift
final class CharacterCardNode: SKNode {
    // ...
    private let border: SKShapeNode  // 신규 — 카드 외곽 보더

    init(id: CharacterID) {
        background = SKSpriteNode(color: .ganhoUIBgCard, size: cardSize)
        border = SKShapeNode(rectOf: cardSize, cornerRadius: GameConfig.uiRadiusSm)
        border.fillColor = .clear
        border.strokeColor = .ganhoUIBorder
        border.lineWidth = GameConfig.uiPanelLineWidth
        // ...
        addChild(background)
        addChild(border)
    }

    func setSelected(_ selected: Bool) {
        background.color = selected ? .ganhoUIBrand12 : .ganhoUIBgCard
        border.strokeColor = selected ? .ganhoUIBrand60 : .ganhoUIBorder
        nameLabel.fontColor = selected ? .ganhoUIBrandLight : .ganhoUITextMuted
        // 스케일/알파는 기존 Phase 5-5 정책 그대로
    }
}
```

## 기능 5: DifficultyCardNode 캡슐 모양

원본 `.game-difficulty__btn`은 `border-radius: 999px` 캡슐. DifficultyCardNode를 SKShapeNode 캡슐로 전환:

```swift
final class DifficultyCardNode: SKNode {
    private let background: SKShapeNode  // 캡슐 모양 — SKSpriteNode → SKShapeNode

    init(id: Difficulty) {
        background = SKShapeNode(rectOf: CGSize(width: GameConfig.difficultyCardWidth,
                                                  height: GameConfig.difficultyCardHeight),
                                 cornerRadius: GameConfig.difficultyCardHeight / 2)  // 캡슐
        background.fillColor = .clear  // 원본은 transparent 배경
        background.strokeColor = .ganhoUIBorder
        background.lineWidth = GameConfig.uiPanelLineWidth
        // ...
    }

    func setSelected(_ selected: Bool) {
        background.fillColor = selected ? id.color.withAlphaComponent(0.2) : .clear
        background.strokeColor = selected ? id.color : .ganhoUIBorder
        nameLabel.fontColor = selected ? .ganhoUIText : .ganhoUITextMuted
    }
}
```

---

## 회귀 0 자연 차단

1. **카드 크기/위치 미변경** — Phase 7-5 핫픽스 layout 결과 보존
2. **카드 자체 구조 변형 최소화** — SKNode 컨테이너 유지, *시각만* 갈아 끼움
3. **CharacterCardNode 인터페이스 보존** — `init(id:)`, `setSelected(_:)` 시그니처 그대로
4. **ResultScene / GameScene / 컷씬 미접촉** — 다음 sprint
5. **GameConfig.characterCardOffsetY 등 layout 상수 미변경** — 7-5 그대로
6. **UIColor(hex:) 확장 재사용** — Phase 8-1에서 추가됨

## 주의사항

1. **SKSpriteNode → SKShapeNode 전환** — DifficultyCardNode 배경을 SKShapeNode 캡슐로. CharacterCardNode는 background는 SKSpriteNode 유지 + 보더 자식 SKShapeNode 추가 (이중 구조).
2. **zPosition 위계** — 배경 -10, 패널 -5, 라벨/카드 0+ (기본). 충돌 0.
3. **frame.midX/midY 계산** — TitleScene이 scene size 1024×768 기준. 패널 (frame.midX, frame.midY) = (512, 384). 작은 화면에서 자동 비례.
4. **반투명 검정 배경** — `.ganhoUIOverlayBg` = `#09080f` α=0.78. 게임 영역 차단. 카드/라벨이 위에 떠 보임.
5. **stroke로 보더 표현** — SKShapeNode lineWidth=1 = 원본 1px 보더와 동일.
6. **카드 색 변경 점진** — 본 sprint는 background.color 갈아 끼움만. 폰트 변경 0(시스템 기본).
7. **CharacterCardNode 픽셀 아바타 도입은 다음 sprint** — 본 sprint는 텍스트 라벨로 캐릭터 이름만.
