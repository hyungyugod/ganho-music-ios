//
//  RunButtonNode.swift
//  GanhoMusic Shared
//
//  Sprint 11 · 쿨타임 없는 hold-to-run 버튼
//

import SpriteKit

/// 누르고 있는 동안만 플레이어 달리기 상태를 켜는 보조 조작 버튼.
final class RunButtonNode: SKNode {

    // MARK: - Properties
    var onPressedChanged: ((Bool) -> Void)?

    private let backgroundNode: SKShapeNode
    private let labelNode: SKLabelNode
    private let keyLabelChip: DarkContextChipNode
    private(set) var isPressed: Bool = false

    // MARK: - Init
    override init() {
        backgroundNode = SKShapeNode(circleOfRadius: UILayout.runButtonRadius)
        labelNode = SKLabelNode(fontNamed: Typography.fontDisplay)
        keyLabelChip = DarkContextChipNode(label: UILayout.runButtonKeyText)
        super.init()

        backgroundNode.fillColor = UIColor.ganhoDifficultyEasyDeep
            .withAlphaComponent(UILayout.runButtonReleasedAlpha)
        backgroundNode.strokeColor = UIColor.white.withAlphaComponent(UILayout.runButtonReleasedAlpha)
        backgroundNode.lineWidth = UILayout.runButtonStrokeWidth
        backgroundNode.zPosition = 100

        labelNode.text = UILayout.runButtonText
        labelNode.fontSize = UILayout.characterHomePanelBodyFontSize
        labelNode.fontColor = .white
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 101

        keyLabelChip.position = CGPoint(
            x: UILayout.skillButtonKeyLabelOffset,
            y: UILayout.skillButtonKeyLabelOffset
        )
        keyLabelChip.zPosition = 102

        addChild(backgroundNode)
        addChild(labelNode)
        addChild(keyLabelChip)

        alpha = GameplayTuning.skillButtonActiveAlpha
        isUserInteractionEnabled = true
        name = "runButton"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func contains(_ point: CGPoint) -> Bool {
        return hypot(point.x, point.y) <= UILayout.runButtonTouchRadius
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        setPressed(contains(touch.location(in: self)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(false)
    }

    func resetPressedState() {
        setPressed(false)
    }

    // MARK: - State
    private func setPressed(_ pressed: Bool) {
        guard isPressed != pressed else { return }
        isPressed = pressed
        applyVisualState()
        onPressedChanged?(pressed)
    }

    private func applyVisualState() {
        backgroundNode.fillColor = isPressed
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.runButtonPressedAlpha)
            : UIColor.ganhoDifficultyEasyDeep.withAlphaComponent(UILayout.runButtonReleasedAlpha)
        backgroundNode.strokeColor = isPressed
            ? .ganhoPixelHudYellow
            : UIColor.white.withAlphaComponent(UILayout.runButtonReleasedAlpha)
        let scale = isPressed ? UILayout.ingamePressScale : UILayout.dpadReleasedScale
        run(
            .scale(to: scale, duration: UILayout.ingamePressDuration),
            withKey: UILayout.ingamePressActionKey
        )
    }
}
