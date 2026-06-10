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
    private let panelShadowNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let accentStripNode = SKShapeNode()
    private let heroFrameNode = SKShapeNode()
    private let portraitNode = CharacterPortraitNode(
        characterID: .kim,
        maxSize: UILayout.loginChoiceHeroPortraitMaxSize
    )
    private let heroCaptionLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let titleLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let statusLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let guestButton = OverlayActionButtonNode(
        title: UILayout.loginChoiceGuestCardTitleText,
        subtitle: UILayout.loginChoiceGuestCardSubtitleText,
        size: CGSize(
            width: UILayout.loginChoiceCardWidth,
            height: UILayout.loginChoiceCardHeight
        ),
        style: .secondary
    )
    private let appleButton = OverlayActionButtonNode(
        title: UILayout.loginChoiceAppleCardTitleText,
        subtitle: UILayout.loginChoiceAppleCardSubtitleText,
        size: CGSize(
            width: UILayout.loginChoiceCardWidth,
            height: UILayout.loginChoiceCardHeight
        ),
        style: .primary
    )
    private let cancelButton = OverlayActionButtonNode(
        title: UILayout.loginChoiceCancelButtonText,
        subtitle: nil,
        size: CGSize(
            width: UILayout.loginChoiceCancelButtonWidth,
            height: UILayout.loginChoiceButtonHeight
        ),
        style: .secondary
    )
    private var mode: LoginChoiceOverlayMode

    // MARK: - Init
    init(sceneSize: CGSize, mode: LoginChoiceOverlayMode = .idle) {
        self.mode = mode
        super.init()
        name = "loginChoiceOverlay"
        zPosition = ZOrder.loginChoiceOverlayZPosition
        configureNodes()
        setMode(mode, statusText: "")
        update(sceneSize: sceneSize)
    }

    @available(*, unavailable, message: "Use init(sceneSize:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Configure
    private func configureNodes() {
        dimNode.fillColor = UIColor.ganhoBgDeep.withAlphaComponent(UILayout.loginChoiceDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = ZOrder.loginChoiceDimZPosition
        addChild(dimNode)

        // 패널 그림자 — 따뜻한 코랄 톤으로(라이트 카드에 어울리게). 어둠→따뜻한 그림자.
        panelShadowNode.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(UILayout.glassPillShadowAlpha)
        panelShadowNode.strokeColor = .clear
        panelShadowNode.lineWidth = 0
        panelShadowNode.position = CGPoint(x: 0, y: UILayout.overlayButtonShadowOffsetY)
        panelShadowNode.zPosition = ZOrder.loginChoicePanelZPosition - 1
        addChild(panelShadowNode)

        // 패널 본체 — 어두운 남보라 → 밝은 크림 카드 + 코랄 테두리(다크→라이트 v2화).
        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.loginChoicePanelFillAlpha)
        panelNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.loginChoicePanelStrokeAlpha)
        panelNode.lineWidth = UILayout.loginChoicePanelLineWidth
        panelNode.zPosition = ZOrder.loginChoicePanelZPosition
        addChild(panelNode)

        // 악센트 스트립 — 골드 → 코랄.
        accentStripNode.fillColor = .ganhoCoralPrimary
        accentStripNode.strokeColor = .clear
        accentStripNode.lineWidth = 0
        accentStripNode.zPosition = ZOrder.loginChoiceLabelZPosition
        addChild(accentStripNode)

        // hero 프레임 — 어두운 바닥톤 → 부드러운 라벤더 + 코랄 테두리.
        heroFrameNode.fillColor = UIColor.ganhoLavenderSoft.withAlphaComponent(UILayout.loginChoicePanelStrokeAlpha)
        heroFrameNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.loginChoicePanelStrokeAlpha)
        heroFrameNode.lineWidth = UILayout.loginChoicePanelLineWidth
        heroFrameNode.zPosition = ZOrder.loginChoiceLabelZPosition
        addChild(heroFrameNode)

        portraitNode.zPosition = ZOrder.loginChoiceLabelZPosition + 1
        addChild(portraitNode)

        heroCaptionLabel.text = UILayout.loginChoiceHeroCaptionText
        heroCaptionLabel.fontSize = UILayout.loginChoiceHeroCaptionFontSize
        // 밝은 카드 위 가독 — 흰계열 → 네이비 muted.
        heroCaptionLabel.fontColor = .ganhoNavyMuted
        heroCaptionLabel.horizontalAlignmentMode = .center
        heroCaptionLabel.verticalAlignmentMode = .center
        heroCaptionLabel.zPosition = ZOrder.loginChoiceLabelZPosition + 2
        addChild(heroCaptionLabel)

        titleLabel.text = UILayout.loginChoiceTitleText
        titleLabel.fontSize = UILayout.loginChoiceTitleFontSize
        // 타이틀 위계 최상 — 골드 → 네이비 deep(본문 대비 또렷).
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = ZOrder.loginChoiceLabelZPosition
        addChild(titleLabel)

        bodyLabel.text = UILayout.loginChoiceBodyText
        bodyLabel.fontSize = UILayout.loginChoiceBodyFontSize
        // 본문 — 흰계열 → 네이비 muted.
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.loginChoiceBodyWidth
        bodyLabel.zPosition = ZOrder.loginChoiceLabelZPosition
        addChild(bodyLabel)

        statusLabel.fontSize = UILayout.loginChoiceStatusFontSize
        // 상태/피드백 강조 — 골드 → 코랄.
        statusLabel.fontColor = .ganhoCoralPrimary
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = ZOrder.loginChoiceLabelZPosition
        addChild(statusLabel)

        guestButton.zPosition = ZOrder.loginChoiceButtonZPosition
        addChild(guestButton)
        appleButton.zPosition = ZOrder.loginChoiceButtonZPosition
        addChild(appleButton)
        cancelButton.zPosition = ZOrder.loginChoiceButtonZPosition
        addChild(cancelButton)
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
        removeAction(forKey: UILayout.loginChoiceStatusMessageActionKey)
        statusLabel.text = statusText
        let enabled = mode != .busy
        guestButton.setEnabled(enabled)
        appleButton.setEnabled(enabled)
        cancelButton.setEnabled(enabled)
    }

    func setStatus(_ text: String) {
        removeAction(forKey: UILayout.loginChoiceStatusMessageActionKey)
        statusLabel.text = text
        guard !text.isEmpty else { return }

        let wait = SKAction.wait(forDuration: UILayout.loginChoiceStatusMessageDuration)
        let clear = SKAction.run { [weak self] in
            self?.statusLabel.text = nil
        }
        run(
            SKAction.sequence([wait, clear]),
            withKey: UILayout.loginChoiceStatusMessageActionKey
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
        let panelWidth = sceneSize.width < UILayout.compactNarrowWidth
            ? UILayout.loginChoicePanelCompactWidth
            : UILayout.loginChoicePanelWidth
        let panelSize = CGSize(
            width: panelWidth,
            height: UILayout.loginChoicePanelHeight
        )
        let rect = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        let panelPath = CGPath(
            roundedRect: rect,
            cornerWidth: UILayout.loginChoicePanelCornerRadius,
            cornerHeight: UILayout.loginChoicePanelCornerRadius,
            transform: nil
        )
        panelNode.path = panelPath
        panelShadowNode.path = panelPath
        accentStripNode.path = CGPath(
            roundedRect: CGRect(
                x: -panelSize.width / 2 + UILayout.loginChoicePanelCornerRadius,
                y: panelSize.height / 2 - UILayout.loginChoicePanelCornerRadius,
                width: UILayout.accentLineWidth,
                height: UILayout.overlayButtonHighlightHeight
            ),
            cornerWidth: UILayout.overlayButtonHighlightHeight / 2,
            cornerHeight: UILayout.overlayButtonHighlightHeight / 2,
            transform: nil
        )
        heroFrameNode.path = CGPath(
            roundedRect: CGRect(
                x: -UILayout.loginChoiceHeroFrameWidth / 2,
                y: -UILayout.loginChoiceHeroFrameHeight / 2,
                width: UILayout.loginChoiceHeroFrameWidth,
                height: UILayout.loginChoiceHeroFrameHeight
            ),
            cornerWidth: UILayout.loginChoiceHeroFrameCornerRadius,
            cornerHeight: UILayout.loginChoiceHeroFrameCornerRadius,
            transform: nil
        )
    }

    private func layoutContent() {
        let contentX = UILayout.loginChoiceContentOffsetX
        heroFrameNode.position = CGPoint(x: UILayout.loginChoiceHeroFrameOffsetX, y: 0)
        portraitNode.position = CGPoint(
            x: UILayout.loginChoiceHeroFrameOffsetX,
            y: -UILayout.loginChoiceHeroPortraitMaxSize.height / 2
        )
        heroCaptionLabel.position = CGPoint(
            x: UILayout.loginChoiceHeroFrameOffsetX,
            y: UILayout.loginChoiceHeroCaptionOffsetY
        )
        titleLabel.position = CGPoint(x: contentX - UILayout.loginChoiceBodyWidth / 2, y: UILayout.loginChoiceTitleOffsetY)
        bodyLabel.position = CGPoint(x: contentX - UILayout.loginChoiceBodyWidth / 2, y: UILayout.loginChoiceBodyOffsetY)
        statusLabel.position = CGPoint(x: 0, y: UILayout.loginChoiceStatusOffsetY)
        layoutChoiceButtons()
        cancelButton.position = CGPoint(x: contentX, y: UILayout.loginChoiceCancelButtonOffsetY)
    }

    private func layoutChoiceButtons() {
        let contentX = UILayout.loginChoiceContentOffsetX
        guestButton.position = CGPoint(
            x: contentX,
            y: UILayout.loginChoiceCardFirstOffsetY
        )
        appleButton.position = CGPoint(
            x: contentX,
            y: UILayout.loginChoiceCardFirstOffsetY
                - UILayout.loginChoiceCardHeight
                - UILayout.loginChoiceCardGap
        )
    }

    // MARK: - Action
    func action(at location: CGPoint) -> LoginChoiceAction? {
        guard !isHidden, mode != .busy else { return nil }
        guard let parent = parent else { return nil }
        let localLocation = convert(location, from: parent)

        if cancelButton.contains(localLocation) {
            cancelButton.playPressFeedback()
            return .cancel
        }
        if guestButton.contains(localLocation) {
            guestButton.playPressFeedback()
            return .guest
        }
        if appleButton.contains(localLocation) {
            appleButton.playPressFeedback()
            return .apple
        }
        return nil
    }
}
