//
//  ProfileDetailOverlayNode.swift
//  GanhoMusic Shared
//
//  캐릭터 홈의 개인 프로필 상세/대표 초상화 설정 오버레이.
//

import SpriteKit
import UIKit

enum ProfileDetailAction {
    case editProfileName
    case chooseAvatar
    case selectAvatar(CharacterID)
    case choosePhoto
    case linkApple
    case signOut
    case requestDeleteConfirmation
    case close
}

enum ProfileDetailMode {
    case detail
    case avatarPicker
    case nicknamePrompt
    case busy
}

final class ProfileDetailOverlayNode: SKNode {

    // MARK: - Properties
    private let dimNode = SKShapeNode()
    private let panelShadowNode = SKShapeNode()
    private let panelNode = SKShapeNode()
    private let accentStripNode = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let avatarView = ProfileAvatarViewNode()
    private var dynamicNodes: [SKNode] = []
    private var actionTargets: [(node: SKNode, action: ProfileDetailAction)] = []
    private var panelSize = CGSize(
        width: GameConfig.profileDetailPanelWidth,
        height: GameConfig.profileDetailPanelHeight
    )
    private var panelFrame: CGRect = .zero
    private(set) var currentMode: ProfileDetailMode = .detail

    // MARK: - Init
    init(sceneSize: CGSize) {
        super.init()
        name = "profileDetailOverlay"
        zPosition = GameConfig.profileDetailOverlayZPosition
        configureNodes()
        updateDimPath(sceneSize: sceneSize)
    }

    @available(*, unavailable, message: "Use init(sceneSize:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Configure
    private func configureNodes() {
        // v2 dim: 순수 검정 대신 따뜻한 딥 네이비 — 풀스크린 오버레이 가독성 유지.
        dimNode.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.profileDetailDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = GameConfig.profileDetailDimZPosition
        addChild(dimNode)

        // v2 그림자 톤: 묶음 A의 코랄 섀도 + glassPill 그림자 투명도로 통일.
        panelShadowNode.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.glassPillShadowAlpha)
        panelShadowNode.strokeColor = .clear
        panelShadowNode.lineWidth = 0
        panelShadowNode.position = CGPoint(x: 0, y: GameConfig.overlayButtonShadowOffsetY)
        panelShadowNode.zPosition = GameConfig.profileDetailPanelZPosition - 1
        addChild(panelShadowNode)

        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.profileDetailPanelFillAlpha)
        // v2 테두리: 얇은 코랄.
        panelNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.profileDetailPanelStrokeAlpha)
        panelNode.lineWidth = GameConfig.profileDetailPanelLineWidth
        panelNode.zPosition = GameConfig.profileDetailPanelZPosition
        addChild(panelNode)

        // v2 악센트 스트립: 골드 잔재 제거 → 코랄.
        accentStripNode.fillColor = .ganhoCoralPrimary
        accentStripNode.strokeColor = .clear
        accentStripNode.lineWidth = 0
        accentStripNode.zPosition = GameConfig.profileDetailLabelZPosition
        addChild(accentStripNode)

        titleLabel.fontSize = GameConfig.profileDetailTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = GameConfig.profileDetailLabelZPosition
        addChild(titleLabel)

        bodyLabel.fontSize = GameConfig.profileDetailBodyFontSize
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = GameConfig.profileDetailBodyWidth
        bodyLabel.zPosition = GameConfig.profileDetailLabelZPosition
        addChild(bodyLabel)

        avatarView.zPosition = GameConfig.profileDetailLabelZPosition
        addChild(avatarView)
    }

    // MARK: - Update
    func update(sceneSize: CGSize,
                snapshot: CharacterHomeSnapshot,
                avatar: ProfileAvatarSnapshot,
                repository: ProfileAvatarRepository,
                unlockedCharacters: [CharacterID],
                mode: ProfileDetailMode) {
        currentMode = mode
        removeDynamicNodes()
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        updateDimPath(sceneSize: sceneSize)
        updatePanelPath(sceneSize: sceneSize)
        avatarView.update(
            snapshot: avatar,
            repository: repository,
            size: GameConfig.profileDetailAvatarSize
        )

        switch mode {
        case .detail:
            configureDetail(snapshot: snapshot)
        case .avatarPicker:
            configureAvatarPicker(
                avatar: avatar,
                unlockedCharacters: unlockedCharacters
            )
        case .nicknamePrompt:
            configureNicknamePrompt(snapshot: snapshot)
        case .busy:
            configureBusy(snapshot: snapshot)
        }
    }

    private func updateDimPath(sceneSize: CGSize) {
        dimNode.path = CGPath(
            rect: CGRect(
                x: -sceneSize.width / 2,
                y: -sceneSize.height / 2,
                width: sceneSize.width,
                height: sceneSize.height
            ),
            transform: nil
        )
    }

    private func updatePanelPath(sceneSize: CGSize) {
        let panelWidth = sceneSize.width < GameConfig.compactNarrowWidth
            ? GameConfig.profileDetailPanelCompactWidth
            : GameConfig.profileDetailPanelWidth
        panelSize = CGSize(
            width: panelWidth,
            height: GameConfig.profileDetailPanelHeight
        )
        panelFrame = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        let panelPath = CGPath(
            roundedRect: panelFrame,
            cornerWidth: GameConfig.profileDetailPanelCornerRadius,
            cornerHeight: GameConfig.profileDetailPanelCornerRadius,
            transform: nil
        )
        panelNode.path = panelPath
        panelShadowNode.path = panelPath
        accentStripNode.path = CGPath(
            roundedRect: CGRect(
                x: -panelSize.width / 2 + GameConfig.profileDetailPanelHorizontalInset,
                y: panelSize.height / 2 - GameConfig.profileDetailPanelTopInset / 2,
                width: GameConfig.accentLineWidth,
                height: GameConfig.overlayButtonHighlightHeight
            ),
            cornerWidth: GameConfig.overlayButtonHighlightHeight / 2,
            cornerHeight: GameConfig.overlayButtonHighlightHeight / 2,
            transform: nil
        )
    }

    private func configureDetail(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = GameConfig.profileDetailTitleText
        bodyLabel.text = snapshot.profileDetailIdentityText
        layoutHeader()
        addMetricRow(snapshot: snapshot)
        addDetailButtons(snapshot: snapshot)
    }

    private func configureAvatarPicker(avatar: ProfileAvatarSnapshot,
                                       unlockedCharacters: [CharacterID]) {
        titleLabel.text = GameConfig.profileDetailAvatarPickerTitleText
        bodyLabel.text = GameConfig.profileDetailAvatarPickerBodyText
        layoutHeader()

        let optionCharacters = unlockedCharacters.isEmpty ? [.kim] : unlockedCharacters
        let count = CGFloat(optionCharacters.count)
        let totalWidth = GameConfig.profileDetailAvatarOptionSize.width * count
            + GameConfig.profileDetailAvatarOptionGap * max(0, count - 1)
        var currentX = -totalWidth / 2 + GameConfig.profileDetailAvatarOptionSize.width / 2

        for characterID in optionCharacters {
            addAvatarOption(
                characterID: characterID,
                selected: avatar.selectedID.characterID == characterID,
                position: CGPoint(x: currentX, y: GameConfig.profileDetailAvatarOptionsOffsetY)
            )
            currentX += GameConfig.profileDetailAvatarOptionSize.width
                + GameConfig.profileDetailAvatarOptionGap
        }

        let photoButton = makeButton(
            text: GameConfig.profileDetailChoosePhotoText,
            width: GameConfig.profileDetailWideButtonWidth,
            action: .choosePhoto,
            style: .secondary
        )
        photoButton.position = CGPoint(
            x: -GameConfig.profileDetailWideButtonWidth / 2 - GameConfig.profileDetailButtonGap / 2,
            y: GameConfig.profileDetailBottomButtonOffsetY
        )
        addDynamicNode(photoButton)

        let closeButton = makeButton(
            text: GameConfig.profileDetailCloseText,
            width: GameConfig.profileDetailButtonWidth,
            action: .close,
            style: .secondary
        )
        closeButton.position = CGPoint(
            x: GameConfig.profileDetailButtonWidth / 2 + GameConfig.profileDetailButtonGap / 2,
            y: GameConfig.profileDetailBottomButtonOffsetY
        )
        addDynamicNode(closeButton)
    }

    private func configureBusy(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = GameConfig.profileDetailBusyTitleText
        bodyLabel.text = GameConfig.profileDetailBusyBodyText
        layoutHeader()
        addMetricRow(snapshot: snapshot)
    }

    private func configureNicknamePrompt(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = GameConfig.profileNicknamePromptTitleText
        bodyLabel.text = GameConfig.profileNicknamePromptBodyText
        layoutHeader()
        addMetricRow(snapshot: snapshot)

        let buttons = [
            makeButton(
                text: GameConfig.profileNicknamePromptButtonText,
                width: GameConfig.profileDetailWideButtonWidth,
                action: .editProfileName,
                style: .primary
            ),
            makeButton(
                text: GameConfig.profileDetailCloseText,
                width: GameConfig.profileDetailButtonWidth,
                action: .close,
                style: .secondary
            )
        ]
        layoutButtonRow(buttons, y: GameConfig.profileDetailSecondButtonRowOffsetY)
    }

    private func layoutHeader() {
        let leftX = -panelSize.width / 2 + GameConfig.profileDetailPanelHorizontalInset
        let topY = panelSize.height / 2 - GameConfig.profileDetailPanelTopInset
        avatarView.position = CGPoint(
            x: leftX + GameConfig.profileDetailAvatarSize.width / 2,
            y: topY - GameConfig.profileDetailAvatarSize.height / 2
        )
        titleLabel.position = CGPoint(
            x: leftX + GameConfig.profileDetailAvatarSize.width + GameConfig.profileDetailHeaderTextGap,
            y: topY - GameConfig.profileDetailTitleOffsetY
        )
        bodyLabel.position = CGPoint(
            x: titleLabel.position.x,
            y: titleLabel.position.y - GameConfig.profileDetailBodyBelowTitleGap
        )
    }

    private func addMetricRow(snapshot: CharacterHomeSnapshot) {
        let labels = [
            (GameConfig.characterHomePlayCountLabelText, "\(snapshot.playCount)\(GameConfig.characterHomePlaySuffixText)"),
            (GameConfig.characterHomeBestScoreLabelText, "\(snapshot.highScore)\(GameConfig.characterHomePointSuffixText)"),
            (GameConfig.characterHomeTotalScoreLabelText, "\(snapshot.totalScore)\(GameConfig.characterHomePointSuffixText)")
        ]
        let totalWidth = GameConfig.profileDetailMetricWidth * CGFloat(labels.count)
            + GameConfig.profileDetailMetricGap * CGFloat(max(0, labels.count - 1))
        var currentX = -totalWidth / 2 + GameConfig.profileDetailMetricWidth / 2
        for item in labels {
            let title = makeLabel(
                text: item.0,
                fontName: GameConfig.fontBody,
                fontSize: GameConfig.profileDetailMetricTitleFontSize,
                color: .ganhoNavyMuted
            )
            title.position = CGPoint(x: currentX, y: GameConfig.profileDetailMetricTitleOffsetY)
            addDynamicNode(title)

            let value = makeLabel(
                text: item.1,
                fontName: GameConfig.fontNumeric,
                fontSize: GameConfig.profileDetailMetricValueFontSize,
                color: .ganhoNavyDeep
            )
            value.position = CGPoint(x: currentX, y: GameConfig.profileDetailMetricValueOffsetY)
            addDynamicNode(value)
            currentX += GameConfig.profileDetailMetricWidth + GameConfig.profileDetailMetricGap
        }
    }

    private func addDetailButtons(snapshot: CharacterHomeSnapshot) {
        let firstRow = [
            makeButton(
                text: GameConfig.profileDetailEditNameText,
                width: GameConfig.profileDetailWideButtonWidth,
                action: .editProfileName,
                style: .primary
            ),
            makeButton(
                text: GameConfig.profileDetailChooseAvatarText,
                width: GameConfig.profileDetailWideButtonWidth,
                action: .chooseAvatar,
                style: .secondary
            ),
            makeButton(
                text: GameConfig.profileDetailChoosePhotoText,
                width: GameConfig.profileDetailWideButtonWidth,
                action: .choosePhoto,
                style: .secondary
            )
        ]

        let accountButton = snapshot.isAppleLinked
            ? makeButton(
                text: GameConfig.accountMenuSignOutText,
                width: GameConfig.profileDetailButtonWidth,
                action: .signOut,
                style: .secondary
            )
            : makeButton(
                text: GameConfig.authAppleButtonText,
                width: GameConfig.profileDetailWideButtonWidth,
                action: .linkApple,
                style: .primary
            )
        layoutButtonRow(firstRow, y: GameConfig.profileDetailFirstButtonRowOffsetY)

        let secondRow = [
            accountButton,
            makeButton(
                text: GameConfig.accountMenuDeleteText,
                width: GameConfig.profileDetailButtonWidth,
                action: .requestDeleteConfirmation,
                style: .destructive
            ),
            makeButton(
                text: GameConfig.profileDetailCloseText,
                width: GameConfig.profileDetailButtonWidth,
                action: .close,
                style: .secondary
            )
        ]
        layoutButtonRow(secondRow, y: GameConfig.profileDetailSecondButtonRowOffsetY)
    }

    private func addAvatarOption(characterID: CharacterID,
                                 selected: Bool,
                                 position: CGPoint) {
        let optionSize = GameConfig.profileDetailAvatarOptionSize
        let card = SKShapeNode(
            rectOf: optionSize,
            cornerRadius: GameConfig.profileDetailAvatarOptionCornerRadius
        )
        // v2 톤: 선택 = 부드러운 코랄 패드 + 코랄 테두리, 미선택 = 크림 + navyMuted 테두리.
        card.fillColor = selected
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.profileDetailAvatarOptionSelectedCoralFillAlpha)
            : UIColor.ganhoPaper.withAlphaComponent(GameConfig.profileDetailAvatarOptionFillAlpha)
        card.strokeColor = selected
            ? .ganhoCoralPrimary
            : UIColor.ganhoNavyMuted.withAlphaComponent(GameConfig.profileDetailPanelStrokeAlpha)
        card.lineWidth = selected
            ? GameConfig.profileDetailAvatarOptionSelectedLineWidth
            : GameConfig.profileDetailPanelLineWidth
        card.position = position
        card.zPosition = GameConfig.profileDetailButtonZPosition
        addDynamicNode(card, action: .selectAvatar(characterID))

        let portrait = CharacterPortraitNode(
            characterID: characterID,
            maxSize: GameConfig.profileDetailAvatarOptionPortraitSize
        )
        portrait.position = CGPoint(
            x: position.x,
            y: position.y - GameConfig.profileDetailAvatarOptionPortraitSize.height / 2
                + GameConfig.profileDetailAvatarOptionPortraitOffsetY
        )
        portrait.zPosition = GameConfig.profileDetailButtonZPosition + 1
        addDynamicNode(portrait)

        let label = makeLabel(
            text: characterID.displayName,
            fontName: GameConfig.fontDisplay,
            fontSize: GameConfig.profileDetailAvatarOptionLabelFontSize,
            color: selected ? .ganhoPaper : .ganhoNavyDeep
        )
        label.position = CGPoint(
            x: position.x,
            y: position.y + GameConfig.profileDetailAvatarOptionLabelOffsetY
        )
        addDynamicNode(label)
    }

    private func makeButton(text: String,
                            width: CGFloat,
                            action: ProfileDetailAction,
                            style: OverlayActionButtonStyle) -> OverlayActionButtonNode {
        let button = OverlayActionButtonNode(
            title: text,
            subtitle: nil,
            size: CGSize(
                width: width,
                height: GameConfig.profileDetailButtonHeight
            ),
            style: style
        )
        button.zPosition = GameConfig.profileDetailButtonZPosition
        actionTargets.append((node: button, action: action))
        return button
    }

    private func layoutButtonRow(_ buttons: [OverlayActionButtonNode], y: CGFloat) {
        guard !buttons.isEmpty else { return }
        let totalWidth = buttons.reduce(CGFloat.zero) { result, button in
            result + button.calculateAccumulatedFrame().width
        } + GameConfig.profileDetailButtonGap * CGFloat(max(0, buttons.count - 1))
        var currentX = -totalWidth / 2
        for button in buttons {
            let width = button.calculateAccumulatedFrame().width
            button.position = CGPoint(x: currentX + width / 2, y: y)
            currentX += width + GameConfig.profileDetailButtonGap
            addDynamicNode(button)
        }
    }

    private func makeLabel(text: String,
                           fontName: String,
                           fontSize: CGFloat,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = GameConfig.profileDetailLabelZPosition
        return label
    }

    private func addDynamicNode(_ node: SKNode, action: ProfileDetailAction? = nil) {
        dynamicNodes.append(node)
        if let action = action {
            actionTargets.append((node: node, action: action))
        }
        addChild(node)
    }

    private func removeDynamicNodes() {
        dynamicNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }
        dynamicNodes.removeAll()
        actionTargets.removeAll()
    }

    // MARK: - Action
    func action(at location: CGPoint) -> ProfileDetailAction? {
        guard !isHidden, currentMode != .busy else { return nil }
        guard let parent = parent else { return nil }
        let localLocation = convert(location, from: parent)
        for target in actionTargets.reversed() {
            if target.node.contains(localLocation) {
                (target.node as? OverlayActionButtonNode)?.playPressFeedback()
                return target.action
            }
        }
        if panelFrame.contains(localLocation) {
            return nil
        }
        return .close
    }
}
