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
        maxSize: GameConfig.loginChoiceHeroPortraitMaxSize
    )
    private let heroCaptionLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let statusLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let guestButton = OverlayActionButtonNode(
        title: GameConfig.loginChoiceGuestCardTitleText,
        subtitle: GameConfig.loginChoiceGuestCardSubtitleText,
        size: CGSize(
            width: GameConfig.loginChoiceCardWidth,
            height: GameConfig.loginChoiceCardHeight
        ),
        style: .secondary
    )
    private let appleButton = OverlayActionButtonNode(
        title: GameConfig.loginChoiceAppleCardTitleText,
        subtitle: GameConfig.loginChoiceAppleCardSubtitleText,
        size: CGSize(
            width: GameConfig.loginChoiceCardWidth,
            height: GameConfig.loginChoiceCardHeight
        ),
        style: .primary
    )
    private let cancelButton = OverlayActionButtonNode(
        title: GameConfig.loginChoiceCancelButtonText,
        subtitle: nil,
        size: CGSize(
            width: GameConfig.loginChoiceCancelButtonWidth,
            height: GameConfig.loginChoiceButtonHeight
        ),
        style: .secondary
    )
    private var mode: LoginChoiceOverlayMode

    // MARK: - Init
    init(sceneSize: CGSize, mode: LoginChoiceOverlayMode = .idle) {
        self.mode = mode
        super.init()
        name = "loginChoiceOverlay"
        zPosition = GameConfig.loginChoiceOverlayZPosition
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
        dimNode.fillColor = UIColor.ganhoBgDeep.withAlphaComponent(GameConfig.loginChoiceDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = GameConfig.loginChoiceDimZPosition
        addChild(dimNode)

        // 패널 그림자 — 따뜻한 코랄 톤으로(라이트 카드에 어울리게). 어둠→따뜻한 그림자.
        panelShadowNode.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.glassPillShadowAlpha)
        panelShadowNode.strokeColor = .clear
        panelShadowNode.lineWidth = 0
        panelShadowNode.position = CGPoint(x: 0, y: GameConfig.overlayButtonShadowOffsetY)
        panelShadowNode.zPosition = GameConfig.loginChoicePanelZPosition - 1
        addChild(panelShadowNode)

        // 패널 본체 — 어두운 남보라 → 밝은 크림 카드 + 코랄 테두리(다크→라이트 v2화).
        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.loginChoicePanelFillAlpha)
        panelNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.loginChoicePanelStrokeAlpha)
        panelNode.lineWidth = GameConfig.loginChoicePanelLineWidth
        panelNode.zPosition = GameConfig.loginChoicePanelZPosition
        addChild(panelNode)

        // 악센트 스트립 — 골드 → 코랄.
        accentStripNode.fillColor = .ganhoCoralPrimary
        accentStripNode.strokeColor = .clear
        accentStripNode.lineWidth = 0
        accentStripNode.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(accentStripNode)

        // hero 프레임 — 어두운 바닥톤 → 부드러운 라벤더 + 코랄 테두리.
        heroFrameNode.fillColor = UIColor.ganhoLavenderSoft.withAlphaComponent(GameConfig.loginChoicePanelStrokeAlpha)
        heroFrameNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.loginChoicePanelStrokeAlpha)
        heroFrameNode.lineWidth = GameConfig.loginChoicePanelLineWidth
        heroFrameNode.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(heroFrameNode)

        portraitNode.zPosition = GameConfig.loginChoiceLabelZPosition + 1
        addChild(portraitNode)

        heroCaptionLabel.text = GameConfig.loginChoiceHeroCaptionText
        heroCaptionLabel.fontSize = GameConfig.loginChoiceHeroCaptionFontSize
        // 밝은 카드 위 가독 — 흰계열 → 네이비 muted.
        heroCaptionLabel.fontColor = .ganhoNavyMuted
        heroCaptionLabel.horizontalAlignmentMode = .center
        heroCaptionLabel.verticalAlignmentMode = .center
        heroCaptionLabel.zPosition = GameConfig.loginChoiceLabelZPosition + 2
        addChild(heroCaptionLabel)

        titleLabel.text = GameConfig.loginChoiceTitleText
        titleLabel.fontSize = GameConfig.loginChoiceTitleFontSize
        // 타이틀 위계 최상 — 골드 → 네이비 deep(본문 대비 또렷).
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(titleLabel)

        bodyLabel.text = GameConfig.loginChoiceBodyText
        bodyLabel.fontSize = GameConfig.loginChoiceBodyFontSize
        // 본문 — 흰계열 → 네이비 muted.
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = GameConfig.loginChoiceBodyWidth
        bodyLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(bodyLabel)

        statusLabel.fontSize = GameConfig.loginChoiceStatusFontSize
        // 상태/피드백 강조 — 골드 → 코랄.
        statusLabel.fontColor = .ganhoCoralPrimary
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = GameConfig.loginChoiceLabelZPosition
        addChild(statusLabel)

        guestButton.zPosition = GameConfig.loginChoiceButtonZPosition
        addChild(guestButton)
        appleButton.zPosition = GameConfig.loginChoiceButtonZPosition
        addChild(appleButton)
        cancelButton.zPosition = GameConfig.loginChoiceButtonZPosition
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
        removeAction(forKey: GameConfig.loginChoiceStatusMessageActionKey)
        statusLabel.text = statusText
        let enabled = mode != .busy
        guestButton.setEnabled(enabled)
        appleButton.setEnabled(enabled)
        cancelButton.setEnabled(enabled)
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
        let panelPath = CGPath(
            roundedRect: rect,
            cornerWidth: GameConfig.loginChoicePanelCornerRadius,
            cornerHeight: GameConfig.loginChoicePanelCornerRadius,
            transform: nil
        )
        panelNode.path = panelPath
        panelShadowNode.path = panelPath
        accentStripNode.path = CGPath(
            roundedRect: CGRect(
                x: -panelSize.width / 2 + GameConfig.loginChoicePanelCornerRadius,
                y: panelSize.height / 2 - GameConfig.loginChoicePanelCornerRadius,
                width: GameConfig.accentLineWidth,
                height: GameConfig.overlayButtonHighlightHeight
            ),
            cornerWidth: GameConfig.overlayButtonHighlightHeight / 2,
            cornerHeight: GameConfig.overlayButtonHighlightHeight / 2,
            transform: nil
        )
        heroFrameNode.path = CGPath(
            roundedRect: CGRect(
                x: -GameConfig.loginChoiceHeroFrameWidth / 2,
                y: -GameConfig.loginChoiceHeroFrameHeight / 2,
                width: GameConfig.loginChoiceHeroFrameWidth,
                height: GameConfig.loginChoiceHeroFrameHeight
            ),
            cornerWidth: GameConfig.loginChoiceHeroFrameCornerRadius,
            cornerHeight: GameConfig.loginChoiceHeroFrameCornerRadius,
            transform: nil
        )
    }

    private func layoutContent() {
        let contentX = GameConfig.loginChoiceContentOffsetX
        heroFrameNode.position = CGPoint(x: GameConfig.loginChoiceHeroFrameOffsetX, y: 0)
        portraitNode.position = CGPoint(
            x: GameConfig.loginChoiceHeroFrameOffsetX,
            y: -GameConfig.loginChoiceHeroPortraitMaxSize.height / 2
        )
        heroCaptionLabel.position = CGPoint(
            x: GameConfig.loginChoiceHeroFrameOffsetX,
            y: GameConfig.loginChoiceHeroCaptionOffsetY
        )
        titleLabel.position = CGPoint(x: contentX - GameConfig.loginChoiceBodyWidth / 2, y: GameConfig.loginChoiceTitleOffsetY)
        bodyLabel.position = CGPoint(x: contentX - GameConfig.loginChoiceBodyWidth / 2, y: GameConfig.loginChoiceBodyOffsetY)
        statusLabel.position = CGPoint(x: 0, y: GameConfig.loginChoiceStatusOffsetY)
        layoutChoiceButtons()
        cancelButton.position = CGPoint(x: contentX, y: GameConfig.loginChoiceCancelButtonOffsetY)
    }

    private func layoutChoiceButtons() {
        let contentX = GameConfig.loginChoiceContentOffsetX
        guestButton.position = CGPoint(
            x: contentX,
            y: GameConfig.loginChoiceCardFirstOffsetY
        )
        appleButton.position = CGPoint(
            x: contentX,
            y: GameConfig.loginChoiceCardFirstOffsetY
                - GameConfig.loginChoiceCardHeight
                - GameConfig.loginChoiceCardGap
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
