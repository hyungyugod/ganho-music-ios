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
    case linkApple
    case signOut
    case requestDeleteConfirmation
    case confirmDelete
    case cancel
}

final class AccountMenuOverlayNode: SKNode {

    // MARK: - Properties
    private let dimNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let appleButton = GlassPillNode(
        text: UILayout.authAppleButtonText,
        size: CGSize(
            width: UILayout.accountMenuButtonWidth,
            height: UILayout.accountMenuButtonHeight
        )
    )
    private let signOutButton = GlassPillNode(
        text: UILayout.accountMenuSignOutText,
        size: CGSize(
            width: UILayout.accountMenuButtonWidth,
            height: UILayout.accountMenuButtonHeight
        )
    )
    private let deleteButton = GlassPillNode(
        text: UILayout.accountMenuDeleteText,
        size: CGSize(
            width: UILayout.accountMenuButtonWidth,
            height: UILayout.accountMenuButtonHeight
        )
    )
    private let cancelButton = GlassPillNode(
        text: UILayout.accountMenuCancelText,
        size: CGSize(
            width: UILayout.accountMenuCancelButtonWidth,
            height: UILayout.accountMenuButtonHeight
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
        zPosition = ZOrder.accountMenuOverlayZPosition
        configureNodes()
        update(sceneSize: sceneSize, isAppleLinked: isAppleLinked, mode: mode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    private func configureNodes() {
        dimNode.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.accountMenuDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = ZOrder.accountMenuDimZPosition
        addChild(dimNode)

        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.accountMenuPanelFillAlpha)
        panelNode.strokeColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.accountMenuPanelStrokeAlpha)
        panelNode.lineWidth = UILayout.accountMenuPanelLineWidth
        panelNode.zPosition = ZOrder.accountMenuPanelZPosition
        addChild(panelNode)

        titleLabel.fontSize = UILayout.accountMenuTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = ZOrder.accountMenuLabelZPosition
        addChild(titleLabel)

        bodyLabel.fontSize = UILayout.accountMenuBodyFontSize
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.accountMenuBodyWidth
        bodyLabel.zPosition = ZOrder.accountMenuLabelZPosition
        addChild(bodyLabel)

        [appleButton, signOutButton, deleteButton, cancelButton].forEach { button in
            button.zPosition = ZOrder.accountMenuButtonZPosition
            addChild(button)
        }

        // 계정 삭제만 destructive 톤(딥코랄 + 흰 글자)으로 위험 액션을 시각 분리.
        // setText(_:)가 fontColor 미변경이라 confirmDelete 모드("삭제")에서도 톤 유지.
        deleteButton.applyDestructiveStyle()
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
        let panelWidth = sceneSize.width < UILayout.compactNarrowWidth
            ? UILayout.accountMenuPanelCompactWidth
            : UILayout.accountMenuPanelWidth
        let panelSize = CGSize(width: panelWidth, height: UILayout.accountMenuPanelHeight)
        let rect = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        panelNode.path = CGPath(
            roundedRect: rect,
            cornerWidth: UILayout.accountMenuPanelCornerRadius,
            cornerHeight: UILayout.accountMenuPanelCornerRadius,
            transform: nil
        )
    }

    private func updateText() {
        switch mode {
        case .menu:
            titleLabel.text = UILayout.accountMenuMenuTitleText
            bodyLabel.text = isAppleLinked
                ? UILayout.accountMenuLinkedBodyText
                : UILayout.accountMenuGuestBodyText
            appleButton.setText(UILayout.authAppleButtonText)
            deleteButton.setText(UILayout.accountMenuDeleteText)
        case .confirmDelete:
            titleLabel.text = UILayout.accountMenuConfirmTitleText
            bodyLabel.text = UILayout.accountMenuConfirmBodyText
            deleteButton.setText(UILayout.accountMenuConfirmDeleteText)
        case .busy:
            titleLabel.text = UILayout.accountMenuBusyTitleText
            bodyLabel.text = UILayout.accountMenuBusyBodyText
            deleteButton.setText(UILayout.accountMenuConfirmDeleteText)
        }
        signOutButton.setText(UILayout.accountMenuSignOutText)
        cancelButton.setText(UILayout.accountMenuCancelText)
    }

    private func layoutContent() {
        titleLabel.position = CGPoint(x: 0, y: UILayout.accountMenuTitleOffsetY)
        bodyLabel.position = CGPoint(x: 0, y: UILayout.accountMenuBodyOffsetY)

        switch mode {
        case .menu:
            let buttons = menuButtons()
            setButtonsHidden(buttonsToShow: buttons.map { $0.node })
            layoutButtons(buttons)
        case .confirmDelete:
            let buttons = [
                (node: deleteButton, width: UILayout.accountMenuButtonWidth),
                (node: cancelButton, width: UILayout.accountMenuCancelButtonWidth)
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
                (node: signOutButton, width: UILayout.accountMenuButtonWidth),
                (node: deleteButton, width: UILayout.accountMenuButtonWidth),
                (node: cancelButton, width: UILayout.accountMenuCancelButtonWidth)
            ]
        }

        return [
            (node: appleButton, width: UILayout.accountMenuButtonWidth),
            (node: deleteButton, width: UILayout.accountMenuButtonWidth),
            (node: cancelButton, width: UILayout.accountMenuCancelButtonWidth)
        ]
    }

    private func setButtonsHidden(buttonsToShow: [GlassPillNode]) {
        let allButtons = [appleButton, signOutButton, deleteButton, cancelButton]
        allButtons.forEach { button in
            button.isHidden = !buttonsToShow.contains(where: { $0 === button })
        }
    }

    private func layoutButtons(_ buttons: [(node: GlassPillNode, width: CGFloat)]) {
        guard !buttons.isEmpty else { return }
        let gapTotal = UILayout.accountMenuButtonGap * CGFloat(max(0, buttons.count - 1))
        let totalWidth = buttons.reduce(CGFloat.zero) { result, item in
            result + item.width
        } + gapTotal
        var currentX = -totalWidth / 2

        for item in buttons {
            item.node.position = CGPoint(
                x: currentX + item.width / 2,
                y: UILayout.accountMenuButtonOffsetY
            )
            currentX += item.width + UILayout.accountMenuButtonGap
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
        if !appleButton.isHidden, appleButton.contains(localLocation) {
            return .linkApple
        }
        if !signOutButton.isHidden, signOutButton.contains(localLocation) {
            return .signOut
        }
        return nil
    }
}
