//
//  HUDNode.swift
//  GanhoMusic Shared
//
//  Phase 2-4 · 점수/시간 라벨 컨테이너 (cameraNode 자식 — 화면 고정)
//  Phase 5-4 · HUD 우상단 캐릭터 이름 라벨 (단일 setter 주입)
//  Phase 8-5 · 원본 .game-hud (game.css L232-289) 상단 가로 4슬롯 + 2단 구조 이식
//

import SpriteKit

/// HUD 컨테이너 — 상단 가로 4슬롯(TIME / SCORE / COMBO / PLAYER).
/// 각 슬롯은 SKNode 컨테이너 + 라벨(위 10pt dim) + 값(아래 22pt text) 2단 구조.
/// 원본 web .game-hud (game.css L232-289) 1:1 시각 이식.
/// 외부 인터페이스(update/setCharacterName/startTensionBlink/stopTensionBlink) 시그니처는 *완전 보존*.
final class HUDNode: SKNode {

    // MARK: - Properties
    /// 4개 가로 슬롯. 각 슬롯이 SKNode 컨테이너 + 라벨/값 자식.
    private let timeSlot: HUDSlotNode
    private let scoreSlot: HUDSlotNode
    private let comboSlot: HUDSlotNode
    private let nameSlot: HUDSlotNode

    // MARK: - Init
    override init() {
        timeSlot  = HUDSlotNode(label: "TIME",   initialValue: "00:45")
        scoreSlot = HUDSlotNode(label: "SCORE",  initialValue: "0")
        comboSlot = HUDSlotNode(label: "COMBO",  initialValue: "0")
        nameSlot  = HUDSlotNode(label: "PLAYER", initialValue: "")
        super.init()

        // 가로 4 슬롯 중앙 정렬 — 슬롯 간격 80, 총 폭 240, 양옆 -120 / +120.
        // anchor (0,0) = 상단 중앙 (GameScene.layoutHUD가 (0, +halfH-margin)로 배치).
        let spacing = GameConfig.hudSlotSpacing
        timeSlot.position  = CGPoint(x: -spacing * 1.5, y: 0)
        scoreSlot.position = CGPoint(x: -spacing * 0.5, y: 0)
        comboSlot.position = CGPoint(x: +spacing * 0.5, y: 0)
        nameSlot.position  = CGPoint(x: +spacing * 1.5, y: 0)

        addChild(timeSlot)
        addChild(scoreSlot)
        addChild(comboSlot)
        addChild(nameSlot)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. 점수 + 남은 시간 + 콤보를 슬롯 값에 반영.
    /// remainingTime은 ceil로 올림 — 사용자가 시작 직후 "45"를 1초간 보도록.
    /// 콤보 hot: 3 이상 .ganhoUIBrandLight, 그 외 .ganhoUIText.
    func update(score: Int, remainingTime: TimeInterval, combo: Int) {
        scoreSlot.setValue("\(score)")
        let seconds = max(0, Int(ceil(remainingTime)))
        timeSlot.setValue(String(format: "00:%02d", seconds))
        comboSlot.setValue("\(combo)")
        comboSlot.setValueColor(combo >= 3 ? .ganhoUIBrandLight : .ganhoUIText)
    }

    // MARK: - Character Name
    /// Phase 5-4 — 선택 캐릭터 이름을 HUD nameSlot 값 라벨에 1회 주입.
    /// 한 판 안에서 호출은 1회만 권장 (런타임 변경 미지원).
    /// 빈 문자열을 넘기면 값 라벨이 비어 보이지 않는다(텍스트만 사라짐).
    func setCharacterName(_ name: String) {
        nameSlot.setValue(name)
    }

    // MARK: - Tension (Phase 6-14)
    /// timeSlot의 값 라벨을 .ganhoUIBrandLight ↔ .ganhoUIText 1초 주기로 깜빡이게 한다.
    /// Phase 8-5 — 원본 톤(.ganhoUIBrandLight) 채택. Phase 6-14의 .ganhoBloodAccent 대체.
    /// 같은 key(`tensionBlinkActionKey`)로 중복 호출 시 SpriteKit이 이전 액션을 자동 교체(자연 멱등).
    /// 콜백은 [weak self] 캡처 — 한 판 진행 중 씬 전환 가능성 대비.
    func startTensionBlink() {
        timeSlot.startBlink(color: .ganhoUIBrandLight)
    }

    /// 깜빡임 액션 제거 + 색 즉시 기본 색(.ganhoUIText) 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop) — 호출자가 startTensionBlink 호출 여부 추적 불필요.
    func stopTensionBlink() {
        timeSlot.stopBlink(restoreColor: .ganhoUIText)
    }
}

// MARK: - HUD Slot Node (Phase 8-5)

/// HUD 단일 슬롯 — 라벨(위 10pt dim) + 값(아래 22pt text) 2단 구조.
/// HUDNode 내부 구현 디테일이라 같은 파일에 둠 (외부 노출 X).
/// 원본 .game-hud__entry > .game-hud__label + .game-hud__value 1:1 매핑.
final class HUDSlotNode: SKNode {

    // MARK: - Properties
    private let labelNode: SKLabelNode
    private let valueNode: SKLabelNode

    // MARK: - Init
    /// - Parameters:
    ///   - label: 위쪽 캡션 텍스트 ("TIME"/"SCORE"/"COMBO"/"PLAYER").
    ///   - initialValue: 아래쪽 값 텍스트 초기값.
    init(label: String, initialValue: String) {
        labelNode = SKLabelNode(text: label)
        valueNode = SKLabelNode(text: initialValue)
        super.init()

        // 위쪽 라벨 — 10pt dim, 가운데 정렬.
        // y는 값 폰트의 절반 + 간격만큼 위로 — 값과 라벨 사이 시각 분리.
        labelNode.fontSize = GameConfig.hudLabelFontSize
        labelNode.fontColor = .ganhoUITextDim
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 100
        labelNode.position = CGPoint(
            x: 0,
            y: GameConfig.hudValueFontSize / 2 + GameConfig.hudSlotInnerGap
        )

        // 아래쪽 값 — 22pt text, 가운데 정렬.
        // y는 라벨 폰트의 절반 + 간격만큼 아래로.
        valueNode.fontSize = GameConfig.hudValueFontSize
        valueNode.fontColor = .ganhoUIText
        valueNode.horizontalAlignmentMode = .center
        valueNode.verticalAlignmentMode = .center
        valueNode.zPosition = 100
        valueNode.position = CGPoint(
            x: 0,
            y: -GameConfig.hudLabelFontSize / 2 - GameConfig.hudSlotInnerGap
        )

        addChild(labelNode)
        addChild(valueNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setters
    /// 값 라벨 텍스트 갱신. HUDNode.update가 매 프레임 호출.
    func setValue(_ s: String) {
        valueNode.text = s
    }

    /// 값 라벨 색 갱신. 콤보 hot 색 갈아 끼움(3+ brand-light, 그 외 text).
    func setValueColor(_ c: UIColor) {
        valueNode.fontColor = c
    }

    // MARK: - Tension Blink (Phase 6-14, Phase 8-5)
    /// 값 라벨을 지정 색 ↔ 기본 색(.ganhoUIText) 1초 주기로 깜빡인다.
    /// SKLabelNode의 `colorize` 액션은 `colorBlendFactor` 이슈로 일관성 ↓ → fontColor 직접 교체 패턴 채택.
    /// 콜백은 [weak self] 캡처 — 씬 전환 시 액션 잔존 시 안전.
    func startBlink(color: UIColor) {
        let toAccent = SKAction.run { [weak self] in self?.valueNode.fontColor = color }
        let toBase = SKAction.run { [weak self] in self?.valueNode.fontColor = .ganhoUIText }
        let wait = SKAction.wait(forDuration: GameConfig.tensionBlinkHalfPeriod)
        let cycle = SKAction.sequence([toAccent, wait, toBase, wait])
        valueNode.run(.repeatForever(cycle), withKey: GameConfig.tensionBlinkActionKey)
    }

    /// 깜빡임 액션 제거 + 색 즉시 복원 (잔상 0).
    /// removeAction은 키가 없어도 안전(noop).
    func stopBlink(restoreColor: UIColor) {
        valueNode.removeAction(forKey: GameConfig.tensionBlinkActionKey)
        valueNode.fontColor = restoreColor
    }
}
