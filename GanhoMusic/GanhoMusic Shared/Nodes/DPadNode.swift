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
/// 외부에는 데드존 밖에서 즉시 최대 크기로 정규화된 `currentDirection`만 노출하고 PlayerNode를 직접 알지 않는다.
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

    /// 지금 누르고 있는 방향 벡터. 안 누르면 .zero, 누르면 즉시 최대 속도용 단위 벡터를 가진다.
    private(set) var currentDirection: CGVector = .zero

    /// [#9] 이동 전용 raw 아날로그 방향 벡터. currentDirection과 달리 축스냅
    /// (axisCorrectedUnitVector) 미경유 — 축보정 *이전* 원시 unit을 normalizedGameplayVector로
    /// 정규화한 단위 벡터(크기 1) 또는 .zero. 곡선/임의각 이동 전용 채널이다.
    /// dash 조준·facing·스킬은 currentDirection을 그대로 읽으므로 밸런스/행동 불변.
    private(set) var analogMoveDirection: CGVector = .zero

    // MARK: - Callbacks
    /// 방향 입력이 비-제로로 갱신된 직후 발화된다. 정지 시 마지막 facing은 유지한다.
    var onDirectionChanged: ((Direction) -> Void)?

    // MARK: - Init
    override init() {
        baseRing = SKShapeNode(circleOfRadius: GameplayTuning.dpadTouchRadius)

        let buttonSize = CGSize(
            width: GameplayTuning.dpadButtonSize,
            height: GameplayTuning.dpadButtonSize
        )
        upButton = SKShapeNode(rectOf: buttonSize, cornerRadius: UILayout.dpadButtonCornerRadius)
        downButton = SKShapeNode(rectOf: buttonSize, cornerRadius: UILayout.dpadButtonCornerRadius)
        leftButton = SKShapeNode(rectOf: buttonSize, cornerRadius: UILayout.dpadButtonCornerRadius)
        rightButton = SKShapeNode(rectOf: buttonSize, cornerRadius: UILayout.dpadButtonCornerRadius)

        centerDeadzone = SKShapeNode(
            circleOfRadius: GameplayTuning.dpadAnalogDeadzoneRadius
        )
        thumbNode = SKShapeNode(circleOfRadius: GameplayTuning.dpadThumbRadius)

        upIcon = SKLabelNode(fontNamed: Typography.fontPixel)
        downIcon = SKLabelNode(fontNamed: Typography.fontPixel)
        leftIcon = SKLabelNode(fontNamed: Typography.fontPixel)
        rightIcon = SKLabelNode(fontNamed: Typography.fontPixel)

        super.init()

        let offset = GameplayTuning.dpadButtonSize
        upButton.position = CGPoint(x: 0, y: offset)
        downButton.position = CGPoint(x: 0, y: -offset)
        leftButton.position = CGPoint(x: -offset, y: 0)
        rightButton.position = CGPoint(x: offset, y: 0)

        configureBaseRing()
        configureButtons()
        configureIcon(upIcon, text: UILayout.dpadUpIconText, position: upButton.position)
        configureIcon(downIcon, text: UILayout.dpadDownIconText, position: downButton.position)
        configureIcon(leftIcon, text: UILayout.dpadLeftIconText, position: leftButton.position)
        configureIcon(rightIcon, text: UILayout.dpadRightIconText, position: rightButton.position)
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

        alpha = UILayout.ingameControlReadableAlpha
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
        return hypot(point.x, point.y) <= GameplayTuning.dpadTouchRadius
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
        analogMoveDirection = .zero   // [#9] raw 아날로그 채널을 currentDirection과 동일 지점에서 동기 리셋
        updateThumb(position: .zero)
        applyPressedState(for: nil)
    }

    // MARK: - Direction Resolution
    private func updateDirection(forTouchLocation location: CGPoint) {
        let distance = hypot(location.x, location.y)
        guard distance >= GameplayTuning.dpadAnalogDeadzoneRadius else {
            currentDirection = .zero
            analogMoveDirection = .zero   // [#9] 데드존 안 — raw 아날로그 채널 동기 리셋
            updateThumb(position: .zero)
            applyPressedState(for: nil)
            return
        }

        let clampedDistance = min(distance, GameplayTuning.dpadAnalogMaxRadius)
        let unit = CGVector(dx: location.x / distance, dy: location.y / distance)
        let correctedUnit = axisCorrectedUnitVector(from: unit)
        currentDirection = normalizedGameplayVector(from: correctedUnit)
        // [#9] 축보정 *이전* 원시 unit(location/distance 방향)을 정규화한 raw 아날로그 방향 —
        // axisCorrectedUnitVector 미경유(dominance 스냅 없음). 크기는 항상 1(비제로) 또는 정확히 0.
        analogMoveDirection = normalizedGameplayVector(from: unit)
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

    private func normalizedGameplayVector(from vector: CGVector) -> CGVector {
        let length = hypot(vector.dx, vector.dy)
        guard length >= GameplayTuning.dpadInputSnapEpsilon else { return .zero }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }

    private func axisCorrectedUnitVector(from unit: CGVector) -> CGVector {
        let absDx = abs(unit.dx)
        let absDy = abs(unit.dy)
        let ratio = GameplayTuning.dpadAxisSnapDominanceRatio

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
            .withAlphaComponent(UILayout.ingameHalfAlphaMultiplier)
        baseRing.strokeColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.dpadButtonStrokeAlpha)
        baseRing.lineWidth = UILayout.dpadButtonStrokeLineWidth
        baseRing.zPosition = 0
    }

    private func configureButtons() {
        for button in [upButton, downButton, leftButton, rightButton] {
            button.fillColor = UIColor.ganhoIngameControlFill
                .withAlphaComponent(UILayout.dpadButtonFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep
                .withAlphaComponent(UILayout.dpadButtonStrokeAlpha)
            button.lineWidth = UILayout.dpadButtonStrokeLineWidth
            button.zPosition = 1
        }
    }

    private func configureCenterDeadzone() {
        centerDeadzone.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(UILayout.dpadCenterDeadzoneAlpha)
        centerDeadzone.strokeColor = .clear
        centerDeadzone.zPosition = 2
    }

    private func configureThumb() {
        thumbNode.fillColor = UIColor.ganhoCoralPrimary
            .withAlphaComponent(GameplayTuning.dpadThumbAlpha)
        thumbNode.strokeColor = .ganhoPixelHudYellow
        thumbNode.lineWidth = UILayout.dpadButtonStrokeLineWidth
        thumbNode.zPosition = 4
    }

    private func configureIcon(_ icon: SKLabelNode, text: String, position: CGPoint) {
        icon.text = text
        icon.fontSize = UILayout.dpadIconFontSize
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
            .withAlphaComponent(UILayout.dpadPressedFillAlpha)
        button.strokeColor = .ganhoPixelHudYellow
        icon.fontColor = .ganhoPixelOutlineBlack
        button.run(
            .scale(to: UILayout.ingamePressScale, duration: UILayout.ingamePressDuration),
            withKey: UILayout.ingamePressActionKey
        )
        icon.run(
            .scale(to: UILayout.ingamePressScale, duration: UILayout.ingamePressDuration),
            withKey: UILayout.ingamePressActionKey
        )
    }

    private func resetButtonStyles() {
        for button in [upButton, downButton, leftButton, rightButton] {
            button.fillColor = UIColor.ganhoIngameControlFill
                .withAlphaComponent(UILayout.dpadButtonFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep
                .withAlphaComponent(UILayout.dpadButtonStrokeAlpha)
            button.run(
                .scale(to: UILayout.dpadReleasedScale, duration: UILayout.ingamePressDuration),
                withKey: UILayout.ingamePressActionKey
            )
        }
        for icon in [upIcon, downIcon, leftIcon, rightIcon] {
            icon.fontColor = .ganhoNavyDeep
            icon.run(
                .scale(to: UILayout.dpadReleasedScale, duration: UILayout.ingamePressDuration),
                withKey: UILayout.ingamePressActionKey
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
