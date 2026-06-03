//
//  DPadNode.swift
//  GanhoMusic Shared
//
//  Phase 1-3 · 반투명 4방향 D-Pad
//  Sprint 3 · v2 디자인 시스템
//  Sprint 11 · 아날로그형 thumb 입력
//

import SpriteKit

/// 원형 터치 영역과 thumb 위치로 이동 벡터를 만드는 D-Pad.
/// 외부에는 magnitude를 가진 `currentDirection`만 노출하고 PlayerNode를 직접 알지 않는다.
final class DPadNode: SKNode {

    // MARK: - Properties
    private let baseRing: SKShapeNode
    private let upButton: SKShapeNode
    private let downButton: SKShapeNode
    private let leftButton: SKShapeNode
    private let rightButton: SKShapeNode
    private let centerDeadzone: SKShapeNode
    private let thumbNode: SKShapeNode
    private let upIcon: SKLabelNode
    private let downIcon: SKLabelNode
    private let leftIcon: SKLabelNode
    private let rightIcon: SKLabelNode
    private var activePressedDirection: Direction?

    /// 지금 누르고 있는 방향 벡터. 안 누르면 .zero, 누르면 0...1 magnitude를 가진다.
    private(set) var currentDirection: CGVector = .zero

    // MARK: - Callbacks
    /// 방향 입력이 비-제로로 갱신된 직후 발화된다. 정지 시 마지막 facing은 유지한다.
    var onDirectionChanged: ((Direction) -> Void)?

    // MARK: - Init
    override init() {
        baseRing = SKShapeNode(circleOfRadius: GameConfig.dpadTouchRadius)

        let buttonSize = CGSize(
            width: GameConfig.dpadButtonSize,
            height: GameConfig.dpadButtonSize
        )
        upButton = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        downButton = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        leftButton = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        rightButton = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)

        centerDeadzone = SKShapeNode(
            circleOfRadius: GameConfig.dpadAnalogDeadzoneRadius
        )
        thumbNode = SKShapeNode(circleOfRadius: GameConfig.dpadThumbRadius)

        upIcon = SKLabelNode(fontNamed: GameConfig.fontPixel)
        downIcon = SKLabelNode(fontNamed: GameConfig.fontPixel)
        leftIcon = SKLabelNode(fontNamed: GameConfig.fontPixel)
        rightIcon = SKLabelNode(fontNamed: GameConfig.fontPixel)

        super.init()

        let offset = GameConfig.dpadButtonSize
        upButton.position = CGPoint(x: 0, y: offset)
        downButton.position = CGPoint(x: 0, y: -offset)
        leftButton.position = CGPoint(x: -offset, y: 0)
        rightButton.position = CGPoint(x: offset, y: 0)

        configureBaseRing()
        configureButtons()
        configureIcon(upIcon, text: GameConfig.dpadUpIconText, position: upButton.position)
        configureIcon(downIcon, text: GameConfig.dpadDownIconText, position: downButton.position)
        configureIcon(leftIcon, text: GameConfig.dpadLeftIconText, position: leftButton.position)
        configureIcon(rightIcon, text: GameConfig.dpadRightIconText, position: rightButton.position)
        configureCenterDeadzone()
        configureThumb()

        addChild(baseRing)
        addChild(upButton)
        addChild(downButton)
        addChild(leftButton)
        addChild(rightButton)
        addChild(centerDeadzone)
        addChild(upIcon)
        addChild(downIcon)
        addChild(leftIcon)
        addChild(rightIcon)
        addChild(thumbNode)

        alpha = GameConfig.ingameControlReadableAlpha
        isUserInteractionEnabled = true

        upButton.name = "dpadUp"
        downButton.name = "dpadDown"
        leftButton.name = "dpadLeft"
        rightButton.name = "dpadRight"
        thumbNode.name = "dpadThumb"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func contains(_ point: CGPoint) -> Bool {
        return hypot(point.x, point.y) <= GameConfig.dpadTouchRadius
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateDirection(forTouchLocation: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateDirection(forTouchLocation: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDirection()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDirection()
    }

    func resetDirection() {
        currentDirection = .zero
        updateThumb(position: .zero)
        applyPressedState(for: nil)
    }

    // MARK: - Direction Resolution
    private func updateDirection(forTouchLocation location: CGPoint) {
        let distance = hypot(location.x, location.y)
        guard distance >= GameConfig.dpadAnalogDeadzoneRadius else {
            currentDirection = .zero
            updateThumb(position: .zero)
            applyPressedState(for: nil)
            return
        }

        let clampedDistance = min(distance, GameConfig.dpadAnalogMaxRadius)
        let range = GameConfig.dpadAnalogMaxRadius - GameConfig.dpadAnalogDeadzoneRadius
        let unit = CGVector(dx: location.x / distance, dy: location.y / distance)
        let strength = min(
            1,
            (clampedDistance - GameConfig.dpadAnalogDeadzoneRadius) / range
        )
        let correctedUnit = axisCorrectedUnitVector(from: unit)
        currentDirection = CGVector(
            dx: correctedUnit.dx * strength,
            dy: correctedUnit.dy * strength
        )
        updateThumb(
            position: CGPoint(
                x: unit.dx * clampedDistance,
                y: unit.dy * clampedDistance
            )
        )

        if let direction = Direction(vector: currentDirection) {
            applyPressedState(for: direction)
            onDirectionChanged?(direction)
        } else {
            applyPressedState(for: nil)
        }
    }

    private func axisCorrectedUnitVector(from unit: CGVector) -> CGVector {
        let absDx = abs(unit.dx)
        let absDy = abs(unit.dy)
        let ratio = GameConfig.dpadAxisSnapDominanceRatio

        if absDx >= absDy * ratio {
            return CGVector(dx: unit.dx >= 0 ? 1 : -1, dy: 0)
        }
        if absDy >= absDx * ratio {
            return CGVector(dx: 0, dy: unit.dy >= 0 ? 1 : -1)
        }
        return unit
    }

    // MARK: - Visual State
    private func configureBaseRing() {
        baseRing.fillColor = UIColor.ganhoIngameControlFill
            .withAlphaComponent(GameConfig.ingameHalfAlphaMultiplier)
        baseRing.strokeColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.dpadButtonStrokeAlpha)
        baseRing.lineWidth = GameConfig.dpadButtonStrokeLineWidth
        baseRing.zPosition = 0
    }

    private func configureButtons() {
        for button in [upButton, downButton, leftButton, rightButton] {
            button.fillColor = UIColor.ganhoIngameControlFill
                .withAlphaComponent(GameConfig.dpadButtonFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep
                .withAlphaComponent(GameConfig.dpadButtonStrokeAlpha)
            button.lineWidth = GameConfig.dpadButtonStrokeLineWidth
            button.zPosition = 1
        }
    }

    private func configureCenterDeadzone() {
        centerDeadzone.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.dpadCenterDeadzoneAlpha)
        centerDeadzone.strokeColor = .clear
        centerDeadzone.zPosition = 2
    }

    private func configureThumb() {
        thumbNode.fillColor = UIColor.ganhoCoralPrimary
            .withAlphaComponent(GameConfig.dpadThumbAlpha)
        thumbNode.strokeColor = .ganhoPixelHudYellow
        thumbNode.lineWidth = GameConfig.dpadButtonStrokeLineWidth
        thumbNode.zPosition = 4
    }

    private func configureIcon(_ icon: SKLabelNode, text: String, position: CGPoint) {
        icon.text = text
        icon.fontSize = GameConfig.dpadIconFontSize
        icon.fontColor = .ganhoNavyDeep
        icon.horizontalAlignmentMode = .center
        icon.verticalAlignmentMode = .center
        icon.position = position
        icon.zPosition = 3
    }

    private func updateThumb(position: CGPoint) {
        thumbNode.position = position
    }

    private func applyPressedState(for direction: Direction?) {
        guard activePressedDirection != direction else { return }
        activePressedDirection = direction
        resetButtonStyles()
        guard let direction = direction else { return }
        let button = buttonNode(for: direction)
        let icon = iconNode(for: direction)
        button.fillColor = UIColor.ganhoIngameControlPressed
            .withAlphaComponent(GameConfig.dpadPressedFillAlpha)
        button.strokeColor = .ganhoPixelHudYellow
        icon.fontColor = .ganhoPixelOutlineBlack
        button.run(
            .scale(to: GameConfig.ingamePressScale, duration: GameConfig.ingamePressDuration),
            withKey: GameConfig.ingamePressActionKey
        )
        icon.run(
            .scale(to: GameConfig.ingamePressScale, duration: GameConfig.ingamePressDuration),
            withKey: GameConfig.ingamePressActionKey
        )
    }

    private func resetButtonStyles() {
        for button in [upButton, downButton, leftButton, rightButton] {
            button.fillColor = UIColor.ganhoIngameControlFill
                .withAlphaComponent(GameConfig.dpadButtonFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep
                .withAlphaComponent(GameConfig.dpadButtonStrokeAlpha)
            button.run(
                .scale(to: GameConfig.dpadReleasedScale, duration: GameConfig.ingamePressDuration),
                withKey: GameConfig.ingamePressActionKey
            )
        }
        for icon in [upIcon, downIcon, leftIcon, rightIcon] {
            icon.fontColor = .ganhoNavyDeep
            icon.run(
                .scale(to: GameConfig.dpadReleasedScale, duration: GameConfig.ingamePressDuration),
                withKey: GameConfig.ingamePressActionKey
            )
        }
    }

    private func buttonNode(for direction: Direction) -> SKShapeNode {
        switch direction {
        case .back:
            return upButton
        case .front:
            return downButton
        case .left:
            return leftButton
        case .right:
            return rightButton
        }
    }

    private func iconNode(for direction: Direction) -> SKLabelNode {
        switch direction {
        case .back:
            return upIcon
        case .front:
            return downIcon
        case .left:
            return leftIcon
        case .right:
            return rightIcon
        }
    }
}
