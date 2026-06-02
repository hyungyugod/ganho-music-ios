//
//  AccountMenuOverlayNode.swift
//  GanhoMusic Shared
//
//  StartScene 위에서 로그아웃/계정 삭제 확인을 처리하는 SpriteKit 오버레이.
//

import SpriteKit

enum AccountMenuOverlayMode {
    case menu
    case confirmDelete
    case busy
}

enum AccountMenuAction {
    case signOut
    case requestDeleteConfirmation
    case confirmDelete
    case cancel
}

final class AccountMenuOverlayNode: SKNode {

    // MARK: - Properties
    private let dimNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let signOutButton = GlassPillNode(
        text: GameConfig.accountMenuSignOutText,
        size: CGSize(
            width: GameConfig.accountMenuButtonWidth,
            height: GameConfig.accountMenuButtonHeight
        )
    )
    private let deleteButton = GlassPillNode(
        text: GameConfig.accountMenuDeleteText,
        size: CGSize(
            width: GameConfig.accountMenuButtonWidth,
            height: GameConfig.accountMenuButtonHeight
        )
    )
    private let cancelButton = GlassPillNode(
        text: GameConfig.accountMenuCancelText,
        size: CGSize(
            width: GameConfig.accountMenuCancelButtonWidth,
            height: GameConfig.accountMenuButtonHeight
        )
    )
    private var mode: AccountMenuOverlayMode
    private var isAppleLinked: Bool

    // MARK: - Init
    init(sceneSize: CGSize, isAppleLinked: Bool, mode: AccountMenuOverlayMode) {
        self.mode = mode
        self.isAppleLinked = isAppleLinked
        super.init()
        name = "accountMenuOverlay"
        zPosition = GameConfig.accountMenuOverlayZPosition
        configureNodes()
        update(sceneSize: sceneSize, isAppleLinked: isAppleLinked, mode: mode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    private func configureNodes() {
        dimNode.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.accountMenuDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = GameConfig.accountMenuDimZPosition
        addChild(dimNode)

        panelNode.fillColor = UIColor.white.withAlphaComponent(GameConfig.accountMenuPanelFillAlpha)
        panelNode.strokeColor = UIColor.white.withAlphaComponent(GameConfig.accountMenuPanelStrokeAlpha)
        panelNode.lineWidth = GameConfig.accountMenuPanelLineWidth
        panelNode.zPosition = GameConfig.accountMenuPanelZPosition
        addChild(panelNode)

        titleLabel.fontSize = GameConfig.accountMenuTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = GameConfig.accountMenuLabelZPosition
        addChild(titleLabel)

        bodyLabel.fontSize = GameConfig.accountMenuBodyFontSize
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = GameConfig.accountMenuBodyWidth
        bodyLabel.zPosition = GameConfig.accountMenuLabelZPosition
        addChild(bodyLabel)

        [signOutButton, deleteButton, cancelButton].forEach { button in
            button.zPosition = GameConfig.accountMenuButtonZPosition
            addChild(button)
        }
    }

    // MARK: - Update
    func update(sceneSize: CGSize, isAppleLinked: Bool, mode: AccountMenuOverlayMode) {
        self.mode = mode
        self.isAppleLinked = isAppleLinked
        update(sceneSize: sceneSize)
    }

    func update(sceneSize: CGSize, isAppleLinked: Bool) {
        self.isAppleLinked = isAppleLinked
        update(sceneSize: sceneSize)
    }

    private func update(sceneSize: CGSize) {
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        updateDimPath(sceneSize: sceneSize)
        updatePanelPath(sceneSize: sceneSize)
        updateText()
        layoutContent()
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
            ? GameConfig.accountMenuPanelCompactWidth
            : GameConfig.accountMenuPanelWidth
        let panelSize = CGSize(width: panelWidth, height: GameConfig.accountMenuPanelHeight)
        let rect = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        panelNode.path = CGPath(
            roundedRect: rect,
            cornerWidth: GameConfig.accountMenuPanelCornerRadius,
            cornerHeight: GameConfig.accountMenuPanelCornerRadius,
            transform: nil
        )
    }

    private func updateText() {
        switch mode {
        case .menu:
            titleLabel.text = GameConfig.accountMenuMenuTitleText
            bodyLabel.text = isAppleLinked
                ? GameConfig.accountMenuLinkedBodyText
                : GameConfig.accountMenuGuestBodyText
            deleteButton.setText(GameConfig.accountMenuDeleteText)
        case .confirmDelete:
            titleLabel.text = GameConfig.accountMenuConfirmTitleText
            bodyLabel.text = GameConfig.accountMenuConfirmBodyText
            deleteButton.setText(GameConfig.accountMenuConfirmDeleteText)
        case .busy:
            titleLabel.text = GameConfig.accountMenuBusyTitleText
            bodyLabel.text = GameConfig.accountMenuBusyBodyText
            deleteButton.setText(GameConfig.accountMenuConfirmDeleteText)
        }
        signOutButton.setText(GameConfig.accountMenuSignOutText)
        cancelButton.setText(GameConfig.accountMenuCancelText)
    }

    private func layoutContent() {
        titleLabel.position = CGPoint(x: 0, y: GameConfig.accountMenuTitleOffsetY)
        bodyLabel.position = CGPoint(x: 0, y: GameConfig.accountMenuBodyOffsetY)

        switch mode {
        case .menu:
            let buttons = menuButtons()
            setButtonsHidden(buttonsToShow: buttons.map { $0.node })
            layoutButtons(buttons)
        case .confirmDelete:
            let buttons = [
                (node: deleteButton, width: GameConfig.accountMenuButtonWidth),
                (node: cancelButton, width: GameConfig.accountMenuCancelButtonWidth)
            ]
            setButtonsHidden(buttonsToShow: buttons.map { $0.node })
            layoutButtons(buttons)
        case .busy:
            setButtonsHidden(buttonsToShow: [])
        }
    }

    private func menuButtons() -> [(node: GlassPillNode, width: CGFloat)] {
        if isAppleLinked {
            return [
                (node: signOutButton, width: GameConfig.accountMenuButtonWidth),
                (node: deleteButton, width: GameConfig.accountMenuButtonWidth),
                (node: cancelButton, width: GameConfig.accountMenuCancelButtonWidth)
            ]
        }

        return [
            (node: deleteButton, width: GameConfig.accountMenuButtonWidth),
            (node: cancelButton, width: GameConfig.accountMenuCancelButtonWidth)
        ]
    }

    private func setButtonsHidden(buttonsToShow: [GlassPillNode]) {
        let allButtons = [signOutButton, deleteButton, cancelButton]
        allButtons.forEach { button in
            button.isHidden = !buttonsToShow.contains(where: { $0 === button })
        }
    }

    private func layoutButtons(_ buttons: [(node: GlassPillNode, width: CGFloat)]) {
        guard !buttons.isEmpty else { return }
        let gapTotal = GameConfig.accountMenuButtonGap * CGFloat(max(0, buttons.count - 1))
        let totalWidth = buttons.reduce(CGFloat.zero) { result, item in
            result + item.width
        } + gapTotal
        var currentX = -totalWidth / 2

        for item in buttons {
            item.node.position = CGPoint(
                x: currentX + item.width / 2,
                y: GameConfig.accountMenuButtonOffsetY
            )
            currentX += item.width + GameConfig.accountMenuButtonGap
        }
    }

    // MARK: - Action
    func action(at location: CGPoint) -> AccountMenuAction? {
        guard !isHidden, mode != .busy else { return nil }
        guard let parent = parent else { return nil }
        let localLocation = convert(location, from: parent)

        if cancelButton.contains(localLocation) {
            return .cancel
        }
        if deleteButton.contains(localLocation) {
            return mode == .confirmDelete ? .confirmDelete : .requestDeleteConfirmation
        }
        if !signOutButton.isHidden, signOutButton.contains(localLocation) {
            return .signOut
        }
        return nil
    }
}
