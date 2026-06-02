//
//  LoginChoiceOverlayNode.swift
//  GanhoMusic Shared
//
//  StartScene 시작 버튼 이후 게스트/Apple 시작 방식을 고르는 SpriteKit 오버레이.
//

import SpriteKit

enum LoginChoiceAction {
    case guest
    case apple
    case cancel
}

enum LoginChoiceOverlayMode {
    case idle
    case busy
}

final class LoginChoiceOverlayNode: SKNode {

    // MARK: - Properties
    private let dimNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let statusLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let guestButton = GlassPillNode(
        text: GameConfig.loginChoiceGuestButtonText,
        size: CGSize(
            width: GameConfig.loginChoiceButtonWidth,
            height: GameConfig.loginChoiceButtonHeight
        )
    )
    private let appleButton = GlassPillNode(
        text: GameConfig.loginChoiceAppleButtonText,
        size: CGSize(
            width: GameConfig.loginChoiceButtonWidth,
            height: GameConfig.loginChoiceButtonHeight
        )
    )
    private let cancelButton = GlassPillNode(
        text: GameConfig.loginChoiceCancelButtonText,
        size: CGSize(
            width: GameConfig.loginChoiceCancelButtonWidth,
            height: GameConfig.loginChoiceButtonHeight
        )
    )
    private var mode: LoginChoiceOverlayMode

    // MARK: - Init
    init(sceneSize: CGSize, mode: LoginChoiceOverlayMode = .idle) {
        self.mode = mode
        super.init()
        name = "loginChoiceOverlay"
        zPosition = GameConfig.loginChoiceOverlayZPosition
        configureNodes()
        update(sceneSize: sceneSize)
    }

    @available(*, unavailable, message: "Use init(sceneSize:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Configure
    private func configureNodes() {
        dimNode.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.loginChoiceDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = GameConfig.loginChoiceDimZPosition
        addChild(dimNode)

        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.loginChoicePanelFillAlpha)
        panelNode.strokeColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.loginChoicePanelStrokeAlpha)
        panelNode.lineWidth = GameConfig.loginChoicePanelLineWidth
        panelNode.zPosition = GameConfig.loginChoicePanelZPosition
        addChild(panelNode)

        titleLabel.text = GameConfig.loginChoiceTitleText
        titleLabel.fontSize = GameConfig.loginChoiceTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(titleLabel)

        bodyLabel.text = GameConfig.loginChoiceBodyText
        bodyLabel.fontSize = GameConfig.loginChoiceBodyFontSize
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = GameConfig.loginChoiceBodyWidth
        bodyLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(bodyLabel)

        statusLabel.fontSize = GameConfig.loginChoiceStatusFontSize
        statusLabel.fontColor = .ganhoNavyMuted
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(statusLabel)

        [guestButton, appleButton, cancelButton].forEach { button in
            button.zPosition = GameConfig.loginChoiceButtonZPosition
            addChild(button)
        }
    }

    // MARK: - Update
    func update(sceneSize: CGSize) {
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        updateDimPath(sceneSize: sceneSize)
        updatePanelPath(sceneSize: sceneSize)
        layoutContent()
    }

    func setMode(_ mode: LoginChoiceOverlayMode, statusText: String) {
        self.mode = mode
        removeAction(forKey: GameConfig.loginChoiceStatusMessageActionKey)
        statusLabel.text = statusText
    }

    func setStatus(_ text: String) {
        removeAction(forKey: GameConfig.loginChoiceStatusMessageActionKey)
        statusLabel.text = text
        guard !text.isEmpty else { return }

        let wait = SKAction.wait(forDuration: GameConfig.loginChoiceStatusMessageDuration)
        let clear = SKAction.run { [weak self] in
            self?.statusLabel.text = nil
        }
        run(
            SKAction.sequence([wait, clear]),
            withKey: GameConfig.loginChoiceStatusMessageActionKey
        )
    }

    private func updateDimPath(sceneSize: CGSize) {
        let rect = CGRect(
            x: -sceneSize.width / 2,
            y: -sceneSize.height / 2,
            width: sceneSize.width,
            height: sceneSize.height
        )
        dimNode.path = CGPath(rect: rect, transform: nil)
    }

    private func updatePanelPath(sceneSize: CGSize) {
        let panelWidth = sceneSize.width < GameConfig.compactNarrowWidth
            ? GameConfig.loginChoicePanelCompactWidth
            : GameConfig.loginChoicePanelWidth
        let panelSize = CGSize(
            width: panelWidth,
            height: GameConfig.loginChoicePanelHeight
        )
        let rect = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        panelNode.path = CGPath(
            roundedRect: rect,
            cornerWidth: GameConfig.loginChoicePanelCornerRadius,
            cornerHeight: GameConfig.loginChoicePanelCornerRadius,
            transform: nil
        )
    }

    private func layoutContent() {
        titleLabel.position = CGPoint(x: 0, y: GameConfig.loginChoiceTitleOffsetY)
        bodyLabel.position = CGPoint(x: 0, y: GameConfig.loginChoiceBodyOffsetY)
        statusLabel.position = CGPoint(x: 0, y: GameConfig.loginChoiceStatusOffsetY)
        layoutChoiceButtons()
        cancelButton.position = CGPoint(x: 0, y: GameConfig.loginChoiceCancelButtonOffsetY)
    }

    private func layoutChoiceButtons() {
        let buttons = [
            (node: guestButton, width: GameConfig.loginChoiceButtonWidth),
            (node: appleButton, width: GameConfig.loginChoiceButtonWidth)
        ]
        let gapTotal = GameConfig.loginChoiceButtonGap * CGFloat(max(0, buttons.count - 1))
        let totalWidth = buttons.reduce(CGFloat.zero) { result, item in
            result + item.width
        } + gapTotal
        var currentX = -totalWidth / 2

        for item in buttons {
            item.node.position = CGPoint(
                x: currentX + item.width / 2,
                y: GameConfig.loginChoiceButtonOffsetY
            )
            currentX += item.width + GameConfig.loginChoiceButtonGap
        }
    }

    // MARK: - Action
    func action(at location: CGPoint) -> LoginChoiceAction? {
        guard !isHidden, mode != .busy else { return nil }
        guard let parent = parent else { return nil }
        let localLocation = convert(location, from: parent)

        if cancelButton.contains(localLocation) {
            return .cancel
        }
        if guestButton.contains(localLocation) {
            return .guest
        }
        if appleButton.contains(localLocation) {
            return .apple
        }
        return nil
    }
}
