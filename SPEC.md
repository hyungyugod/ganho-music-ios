# Phase 5-1: 캐릭터 선택 UI 골격

## 개요
TitleScene 하단에 5명(김간호/정간호/건간호/임간호/이간호) 카드를 가로 일렬로 배치하고 탭으로 선택을 바꿀 수 있게 한다. 선택된 카드만 또렷이(alpha 1.0), 나머지는 흐림(alpha 0.5)으로 보인다. *게임 로직 변화 0* — 선택 결과는 다음 sprint(5-2)에서 GameScene에 전달.

## 변경 유형
**혼합** — 신규 모델 enum(`CharacterID`) + 신규 노드(`CharacterCardNode`) + TitleScene 확장 + GameConfig 상수. 게임플레이 변경 0, 비주얼 UI 추가만.

## 게임 경험 의도
TitleScene 진입 시 사용자는 화면 하단에서 5명 카드를 가로 일렬로 본다. 김간호(기본) 카드만 또렷, 나머지 4명은 흐림. 카드 영역 탭은 선택을 바꾸고(GameScene 전환 X), 카드 외 영역 탭은 *기존 동작*(GameScene fade 전환). 게임 시작 시 PlayerNode 색·외형은 4-R 그대로 — 선택 결과 적용은 다음 sprint.

## Sprint 범위 계약

### In Scope (모두 필수)
1. 새 파일 `Models/CharacterID.swift` (~25줄) — enum + displayName/color
2. 새 파일 `Nodes/CharacterCardNode.swift` (~50줄) — SKNode 컨테이너 + setSelected
3. `Config/GameConfig.swift` Character Card 섹션 +6 상수
4. `Scenes/TitleScene.swift` 확장 — 헤더 1 + properties 2 + setupCharacterCards/layoutCharacterCards/select 메서드 + touchesBegan hit test (~30줄)
5. `pbxproj` 등록 — 식별자 0022(CharacterID, Models) + 0023(CharacterCardNode, Nodes) 각 4곳

### Out of Scope (위반 시 P0)
- PlayerNode / EnemyNode / 기타 게임 노드 변경
- GameScene / GameScene+Setup 변경 (호출 측 0줄)
- ResultScene 변경
- 스킬 시스템 / 캐릭터별 게임 로직
- 선택 결과 GameScene 전달 (다음 sprint 5-2)
- 선택 영구 저장 (Repository 신설)
- 카드 펄스/페이드 애니메이션 / 테두리 / 하이라이트 노드
- 기존 4 라벨(title/best/plays/prompt) 위치 변경
- 기존 `layoutLabels` 본문 변경 (카드는 별도 `layoutCharacterCards`)
- 기존 `touchesBegan` 본문 변경 (앞에 hit test만 *추가*)
- 새 ColorTokens 토큰 신설 (기존 5색 재사용)
- 새 Repository / System / Manager
- macOS / tvOS Sources phase
- Test 코드 추가

### 판단 기준
"이 변경이 없으면 'TitleScene 하단 5 카드 + 탭 선택 변경 + 선택 시각 표시 + GameScene 전환은 카드 외 영역만'이 동작하는가?" → NO만 In Scope.

## 변경 범위
- 신설: `Models/CharacterID.swift`, `Nodes/CharacterCardNode.swift`
- 수정: `Config/GameConfig.swift`, `Scenes/TitleScene.swift`, `pbxproj`

## 기능 상세

### 기능 1: `CharacterID` enum

- **구현 위치**: `Models/CharacterID.swift` (신설)
- **핵심 코드**:
```swift
//
//  CharacterID.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 UI 골격 — 5명 enum (id/displayName/color)
//

import UIKit

/// 5 캐릭터 식별자. raw String — case 이름이 그대로 raw value("kim", "jung"...).
/// CaseIterable 채택으로 `.allCases` 자동 생성 — TitleScene이 5 카드 일괄 생성에 사용.
/// 본 sprint(5-1)는 *UI 골격*만 — 스킬·외형 적용은 5-2 이후.
enum CharacterID: String, CaseIterable {
    case kim, jung, geon, im, lee

    /// 카드 라벨에 표시되는 한국어 이름. GDD §4 기준.
    var displayName: String {
        switch self {
        case .kim:  return "김간호"
        case .jung: return "정간호"
        case .geon: return "건간호"
        case .im:   return "임간호"
        case .lee:  return "이간호"
        }
    }

    /// 카드 배경색. ColorTokens 기존 5색 재사용 — 새 토큰 신설 X.
    var color: UIColor {
        switch self {
        case .kim:  return .ganhoPaper
        case .jung: return .ganhoMint
        case .geon: return .ganhoPinkNote
        case .im:   return .ganhoYellowF
        case .lee:  return .ganhoBloodAccent
        }
    }
}
```

### 기능 2: `CharacterCardNode` 컨테이너 노드

- **구현 위치**: `Nodes/CharacterCardNode.swift` (신설)
- **참고 패턴**: `HUDNode` / `AirforceOverlayNode` (SKNode 컨테이너 + 자식 노드)
- **핵심 코드**:
```swift
//
//  CharacterCardNode.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 카드 — 색 사각형 + 이름 라벨 + 선택 알파 토글
//

import SpriteKit

/// TitleScene 하단 캐릭터 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKSpriteNode(색 사각형) + SKLabelNode(이름) 2개 컨테이너.
/// HUDNode / AirforceOverlayNode 패턴 답습 — 부모 = 좌표·zPosition·name, 자식 = 시각 속성.
final class CharacterCardNode: SKNode {

    // MARK: - Properties
    let id: CharacterID
    private let background: SKSpriteNode
    private let nameLabel: SKLabelNode

    // MARK: - Init
    init(id: CharacterID) {
        self.id = id
        background = SKSpriteNode(
            color: id.color,
            size: CGSize(
                width: GameConfig.characterCardWidth,
                height: GameConfig.characterCardHeight
            )
        )
        nameLabel = SKLabelNode(text: id.displayName)
        super.init()
        name = "characterCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        addChild(background)
        configureLabel()
        addChild(nameLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Selection
    /// 선택 상태 시각 토글. true → alpha 1.0(또렷), false → 0.5(흐림).
    /// CSS opacity 패턴 — 별도 테두리/하이라이트 노드 없이 알파 1개로 표현.
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
    }

    // MARK: - Configure
    /// 이름 라벨 스타일 — 배경 사각형 위 정중앙.
    private func configureLabel() {
        nameLabel.fontSize = GameConfig.characterCardFontSize
        nameLabel.fontColor = .ganhoBgDeep
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = .zero
    }
}
```

### 기능 3: `GameConfig` Character Card 섹션 +6 상수

- **구현 위치**: `Config/GameConfig.swift` — `enemyFleeDuration` 다음 새 섹션
- **삽입 코드**:
```swift
    // MARK: - Character Card (Phase 5-1)
    /// 캐릭터 선택 카드 1장 가로 (pt). 5장 일렬 + 화면 폭에 맞춰 작게.
    static let characterCardWidth: CGFloat = 48
    /// 캐릭터 선택 카드 1장 세로 (pt). 가로보다 살짝 큼.
    static let characterCardHeight: CGFloat = 60
    /// 카드 사이 간격 (pt). 5장 일렬 — 전체 폭 = 5×48 + 4×10 = 280.
    static let characterCardSpacing: CGFloat = 10
    /// 카드 이름 라벨 폰트 크기 (pt). 카드 폭(48) 안에 한국어 3자 들어가야 함.
    static let characterCardFontSize: CGFloat = 12
    /// 카드 줄 y 오프셋 (pt). frame.midY 기준 아래쪽. promptLabel(-80)보다 더 아래.
    static let characterCardOffsetY: CGFloat = -160
    /// 선택되지 않은 카드 알파. 선택 카드(1.0)와 시각 대비.
    static let characterCardDeselectedAlpha: CGFloat = 0.5
```

### 기능 4: `TitleScene` 확장

- **구현 위치**: `Scenes/TitleScene.swift`
- **헤더 1줄 추가** (Phase 3-5 다음):
```swift
//  Phase 5-1 · 캐릭터 선택 카드 5장 추가 — selectedCharacterID + hit test
```

- **Properties 추가** (기존 4 라벨 다음):
```swift
private var selectedCharacterID: CharacterID = .kim
private var characterCards: [CharacterCardNode] = []
```

- **didMove**(`setupLabels()` 다음에 1줄 추가):
```swift
override func didMove(to view: SKView) {
    backgroundColor = .ganhoBgDeep
    setupLabels()
    setupCharacterCards()   // ← 추가
    startPromptBlink()
}
```

- **didChangeSize**(`layoutLabels()` 다음에 1줄 추가):
```swift
override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    layoutLabels()
    layoutCharacterCards()  // ← 추가
}
```

- **신규 메서드** (Setup 섹션 끝 또는 Touch 위에):
```swift
// MARK: - Character Cards
/// 5 캐릭터 카드 생성 + addChild + 초기 선택 상태 적용.
/// CharacterID.allCases (CaseIterable) — 5번 반복.
private func setupCharacterCards() {
    for id in CharacterID.allCases {
        let card = CharacterCardNode(id: id)
        card.setSelected(id == selectedCharacterID)
        characterCards.append(card)
        addChild(card)
    }
    layoutCharacterCards()
}

/// 5 카드 가로 일렬, frame.midX 기준 중앙 정렬.
private func layoutCharacterCards() {
    let count = characterCards.count
    guard count > 0 else { return }
    let width = GameConfig.characterCardWidth
    let spacing = GameConfig.characterCardSpacing
    let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
    let startX = frame.midX - totalWidth / 2 + width / 2
    let y = frame.midY + GameConfig.characterCardOffsetY
    for (index, card) in characterCards.enumerated() {
        card.position = CGPoint(
            x: startX + CGFloat(index) * (width + spacing),
            y: y
        )
    }
}

/// 선택 캐릭터 변경 + 5 카드 알파 일괄 갱신.
private func select(_ id: CharacterID) {
    selectedCharacterID = id
    for card in characterCards {
        card.setSelected(card.id == id)
    }
}
```

- **touchesBegan 수정** (맨 앞에 hit test 추가):
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1) 카드 hit test 먼저 — 카드 탭은 선택 변경, GameScene 전환 X
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    for card in characterCards {
        if card.contains(location) {
            select(card.id)
            return
        }
    }
    // 2) 그 외 영역 — 기존 동작
    guard !isTransitioning else { return }
    guard let view = self.view else { return }
    isTransitioning = true
    let gameScene = GameScene.newGameScene()
    let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
    view.presentScene(gameScene, transition: fade)
}
```

### 기능 5: `project.pbxproj` 등록 (8곳)

#### 5-1. PBXBuildFile (0021 다음)
```
		A1C0F1B00000000000000022 /* CharacterID.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000022 /* CharacterID.swift */; };
		A1C0F1B00000000000000023 /* CharacterCardNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000023 /* CharacterCardNode.swift */; };
```

#### 5-2. PBXFileReference (0021 다음)
```
		A1C0F1A00000000000000022 /* CharacterID.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterID.swift; sourceTree = "<group>"; };
		A1C0F1A00000000000000023 /* CharacterCardNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CharacterCardNode.swift; sourceTree = "<group>"; };
```

#### 5-3. PBXGroup children
- Nodes 그룹 (BombFlashNode 다음):
```
				A1C0F1A00000000000000023 /* CharacterCardNode.swift */,
```
- Models 그룹 (GameStats 다음):
```
				A1C0F1A00000000000000022 /* CharacterID.swift */,
```

#### 5-4. iOS Sources phase (SelfDismissingNode 0021 다음)
```
				A1C0F1B00000000000000022 /* CharacterID.swift in Sources */,
				A1C0F1B00000000000000023 /* CharacterCardNode.swift in Sources */,
```

#### 5-5. tvOS / macOS Sources phase
**그대로 — files = () 빈 채로 유지**.

## 검증 시나리오 (a)~(h)

| # | 시나리오 | 정적 검증 |
|---|---|---|
| (a) | 5 카드 초기 상태 | `setupCharacterCards`에 `for id in CharacterID.allCases` 5 인스턴스 생성, 기본 `selectedCharacterID = .kim` 확인 |
| (b) | 정간호 탭 → 선택 갱신 | `touchesBegan` 본문 맨 앞에 hit test 루프 + `select(card.id)` + return |
| (c) | 다른 카드 탭 시 이전 선택 해제 | `select(_:)`가 *모든* 카드 순회, alpha 갱신 |
| (d) | 카드 외 탭 → GameScene 전환 | hit test 매치 X → 기존 isTransitioning/presentScene 그대로 실행 |
| (e) | GameScene 시작 — PlayerNode 변경 0 | GameScene/GameScene+Setup/노드 0줄 변경. newGameScene() 호출 인자 변경 0 |
| (f) | ResultScene → TitleScene 복귀 — kim 리셋 | TitleScene.newTitleScene() 매번 새 인스턴스 |
| (g) | didChangeSize — 카드 재계산 | `layoutLabels()` 다음 `layoutCharacterCards()` 호출 |
| (h) | 빌드 SUCCEEDED + 경고 0 | import UIKit (CharacterID), import SpriteKit (CharacterCardNode), 매직 넘버 0 |

## 학습 가치
- Swift `enum` 첫 도입 (5 case, raw String, CaseIterable)
- `.allCases` 자동 생성 — Java `values()` 동치
- SKNode 컨테이너 패턴 3회차 (HUD/AirforceOverlay/CharacterCard)
- `touchesBegan` hit test (`SKNode.contains`)
- 선택 시각 표시 = 알파 1.0/0.5
- GameScene 호출 측 변경 0 정책 9 sprint 연속

## 주의사항
- **import**: CharacterID → UIKit (UIColor), CharacterCardNode → SpriteKit
- **PhysicsBody 0**: CharacterCardNode 순수 UI
- **`[weak self]`**: 본 sprint 클로저 미사용 — 캡처 불필요
- **layoutLabels 본문 변경 금지** — 별도 layoutCharacterCards
- **setupLabels 본문 변경 금지** — didMove에서 호출만 추가
- **touchesBegan 본문 변경 금지** — hit test 맨 앞에 *추가*만
- **카드 위치 계산**: 전체 폭 5×48 + 4×10 = 280pt. midX 기준 -140 ~ +140
- **characterCardOffsetY = -160**: scene.size 768 기준 viewport 클리핑 X
- **pbxproj 0022/0023**: BombFlash 0020, SelfDismissing 0021 다음 자유 식별자
- **ColorTokens 신설 절대 금지**: 5색 모두 기존 재사용
- **nameLabel 색 .ganhoBgDeep**: 밝은 배경 위 가독성 — 새 토큰 X
- **GameScene 호출 측 0줄 정책 9 sprint 연속** — 위반 시 P0
