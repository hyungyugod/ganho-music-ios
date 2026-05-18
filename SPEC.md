# Phase 8-5 — HUD 디자인 동일화 (상단 가로 슬롯)

## 개요
원본 웹게임 `.game-hud` (game.css L232-289)의 *상단 가로 슬롯 배치* + *2단 구조(라벨 위 + 값 아래)* + *코럴 톤 컬러*를 모바일 HUDNode에 이식. 현재 *좌상단 세로 스택*에서 *상단 가로 4슬롯*으로 재구성. 시각 토큰 적용.

## 변경 유형
**비주얼**

## Sprint 범위 계약

### 허용
1. `Config/GameConfig.swift` — HUD 신규 layout 상수 (slot spacing, value font 22, label font 10, top margin 등)
2. `Nodes/HUDNode.swift` — 가로 4 슬롯 구조 (TIME / SCORE / COMBO / 캐릭터). 각 슬롯이 SKNode 컨테이너 + 라벨 + 값 2개 자식. 콤보 3+ 시 brand-light 갈아 끼움.
3. `GameScene.swift layoutHUD` — 위치 좌상단 → 상단 중앙으로 변경. hud.position = (0, +halfH - margin).

### 금지
1. tensionBlink 코드 변경 (Phase 6-14 시퀀스 보존, 색만 갈아 끼움)
2. setCharacterName 시그니처 변경
3. 콤보 마일스톤 / NEW BEST / 졸업장 등 자가 소멸 노드 시각 변경 — 다음 sprint
4. TitleScene / ResultScene 미접촉
5. SKAction 콤보 bump 애니메이션 도입 — 다음 sprint (시각 토큰 우선)

### 판단 기준
"HUD가 상단 가로 4슬롯에 라벨+값 2단 구조로 표시되는가?" → YES만 허용.

## 변경 범위
- 수정: GameConfig.swift, HUDNode.swift, GameScene.swift (layoutHUD 1군데)
- 신규 파일 0개, pbxproj 0건.

## 기능 1: GameConfig 신규 상수

```swift
// MARK: - HUD Layout (Phase 8-5)
static let hudTopMargin: CGFloat = 28           // 화면 상단에서 hud anchor 거리
static let hudSlotSpacing: CGFloat = 80         // 슬롯 4개 간격 (수평)
static let hudValueFontSize: CGFloat = 22       // 원본 .game-hud__value 22px
static let hudLabelFontSize: CGFloat = 10       // 원본 .game-hud__label 10px
static let hudSlotInnerGap: CGFloat = 4         // 라벨 ↔ 값 세로 간격
static let hudLabelLetterSpacing: CGFloat = 2   // 원본 letter-spacing 2px (SKLabelNode 미지원, 기록만)
```

## 기능 2: HUDNode 가로 슬롯 재구성

기존 세로 스택 (scoreLabel/timeLabel/comboLabel) 폐기. 4개 *슬롯 SKNode* 자식 배치.

```swift
final class HUDNode: SKNode {
    // 각 슬롯 — SKNode 컨테이너 + 라벨(위) + 값(아래)
    private let timeSlot: HUDSlotNode
    private let scoreSlot: HUDSlotNode
    private let comboSlot: HUDSlotNode
    private let nameSlot: HUDSlotNode

    override init() {
        timeSlot = HUDSlotNode(label: "TIME", initialValue: "00:45")
        scoreSlot = HUDSlotNode(label: "SCORE", initialValue: "0")
        comboSlot = HUDSlotNode(label: "COMBO", initialValue: "0")
        nameSlot = HUDSlotNode(label: "PLAYER", initialValue: "")
        super.init()
        // 가로 4 슬롯, 중앙 정렬 — 슬롯 1개 폭 80, 총 240, 양옆에 -120/+120
        let spacing = GameConfig.hudSlotSpacing
        timeSlot.position = CGPoint(x: -spacing * 1.5, y: 0)
        scoreSlot.position = CGPoint(x: -spacing * 0.5, y: 0)
        comboSlot.position = CGPoint(x: +spacing * 0.5, y: 0)
        nameSlot.position = CGPoint(x: +spacing * 1.5, y: 0)
        addChild(timeSlot); addChild(scoreSlot); addChild(comboSlot); addChild(nameSlot)
    }

    func update(score: Int, remainingTime: TimeInterval, combo: Int) {
        scoreSlot.setValue("\(score)")
        let seconds = max(0, Int(ceil(remainingTime)))
        timeSlot.setValue(String(format: "00:%02d", seconds))
        comboSlot.setValue("\(combo)")
        // 콤보 hot — 3 이상 brand-light, 그 외 text
        comboSlot.setValueColor(combo >= 3 ? .ganhoUIBrandLight : .ganhoUIText)
    }

    func setCharacterName(_ name: String) {
        nameSlot.setValue(name)
    }

    // tensionBlink — timeSlot의 값 라벨에 적용 (기존 timeLabel과 동일 효과)
    func startTensionBlink() {
        timeSlot.startBlink(color: .ganhoUIBrandLight)
    }

    func stopTensionBlink() {
        timeSlot.stopBlink(restoreColor: .ganhoUIText)
    }
}

/// HUD 단일 슬롯 — 라벨(위 10pt dim) + 값(아래 22pt bold text).
final class HUDSlotNode: SKNode {
    private let labelNode: SKLabelNode
    private let valueNode: SKLabelNode

    init(label: String, initialValue: String) {
        labelNode = SKLabelNode(text: label)
        valueNode = SKLabelNode(text: initialValue)
        super.init()
        labelNode.fontSize = GameConfig.hudLabelFontSize
        labelNode.fontColor = .ganhoUITextDim
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.position = CGPoint(x: 0, y: GameConfig.hudValueFontSize / 2 + GameConfig.hudSlotInnerGap)
        valueNode.fontSize = GameConfig.hudValueFontSize
        valueNode.fontColor = .ganhoUIText
        valueNode.verticalAlignmentMode = .center
        valueNode.horizontalAlignmentMode = .center
        valueNode.position = CGPoint(x: 0, y: -GameConfig.hudLabelFontSize / 2 - GameConfig.hudSlotInnerGap)
        addChild(labelNode); addChild(valueNode)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ s: String) { valueNode.text = s }
    func setValueColor(_ c: UIColor) { valueNode.fontColor = c }

    func startBlink(color: UIColor) {
        let toAccent = SKAction.run { [weak self] in self?.valueNode.fontColor = color }
        let toBase = SKAction.run { [weak self] in self?.valueNode.fontColor = .ganhoUIText }
        let wait = SKAction.wait(forDuration: GameConfig.tensionBlinkHalfPeriod)
        let cycle = SKAction.sequence([toAccent, wait, toBase, wait])
        valueNode.run(.repeatForever(cycle), withKey: GameConfig.tensionBlinkActionKey)
    }

    func stopBlink(restoreColor: UIColor) {
        valueNode.removeAction(forKey: GameConfig.tensionBlinkActionKey)
        valueNode.fontColor = restoreColor
    }
}
```

## 기능 3: GameScene.layoutHUD 위치 변경

좌상단 → 상단 중앙:

```swift
func layoutHUD() {
    let halfH = size.height / 2
    hud.position = CGPoint(
        x: 0,                                   // 가로 중앙
        y: +(halfH - GameConfig.hudTopMargin)   // 상단에서 28pt 아래
    )
}
```

기존 hudMarginX는 미사용.

---

## 회귀 0 자연 차단

1. **HUDNode 외부 인터페이스 보존** — `update(score:remainingTime:combo:)`, `setCharacterName(_:)`, `startTensionBlink()`, `stopTensionBlink()` 시그니처 그대로
2. **GameScene 호출자 미변경** — hud 메서드 호출 전부 동일 시그니처
3. **TitleScene / ResultScene 미접촉** — 다음 sprint
4. **tensionBlink 액션 키 유지** — `GameConfig.tensionBlinkActionKey` 재사용
5. **신규 색 0** — `.ganhoUIText`/`.ganhoUITextDim`/`.ganhoUIBrandLight` 모두 Phase 8-3 추가됨

## 주의사항

1. **HUDSlotNode 신규 클래스** — HUDNode.swift 안에 같이 둘지 별도 파일 둘지. *같은 파일 안* 권장 (HUDNode 내부 구현 디테일).
2. **이모지 제거** — 기존 "🎵 0", "⏱ 00:45", "🔥 0"의 이모지 제거. 원본은 라벨(TIME/SCORE/COMBO) 텍스트만. 더 깨끗.
3. **위치 변환** — 좌상단 anchor에서 상단 중앙으로. hudMarginX/Y 의미 변경. hudMarginX는 deprecated, 신규 hudTopMargin 사용.
4. **콤보 핫 색** — combo >= 3 시 valueNode.fontColor = .ganhoUIBrandLight. 3 미만은 .ganhoUIText.
5. **tensionBlink 색** — Phase 6-14의 빨강(.ganhoBloodAccent)에서 원본 톤(.ganhoUIBrandLight) 또는 그대로 유지? 사용자 의도가 *원본 동일*이라 원본 토큰(.ganhoUIBrandLight) 채택.
6. **landscape 1024 폭에서 슬롯 4 × 80 = 320 폭** — 중앙 ±160. 화면 안.
7. **GameConfig.hudFontSize 18 (기존)** — 더 이상 HUDNode가 직접 사용 안 함. 그대로 두되 deprecated 명시 또는 제거. 본 sprint는 *유지* (안전).
