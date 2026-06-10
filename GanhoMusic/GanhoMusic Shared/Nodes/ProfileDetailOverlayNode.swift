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
    private let titleLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let bodyLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private let avatarView = ProfileAvatarViewNode()
    private var dynamicNodes: [SKNode] = []
    private var actionTargets: [(node: SKNode, action: ProfileDetailAction)] = []
    private var panelSize = CGSize(
        width: UILayout.profileDetailPanelWidth,
        height: UILayout.profileDetailPanelHeight
    )
    private var panelFrame: CGRect = .zero
    private(set) var currentMode: ProfileDetailMode = .detail

    // MARK: - Init
    init(sceneSize: CGSize) {
        super.init()
        name = "profileDetailOverlay"
        zPosition = ZOrder.profileDetailOverlayZPosition
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
        dimNode.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.profileDetailDimAlpha)
        dimNode.strokeColor = .clear
        dimNode.lineWidth = 0
        dimNode.zPosition = ZOrder.profileDetailDimZPosition
        addChild(dimNode)

        // v2 그림자 톤: 묶음 A의 코랄 섀도 + glassPill 그림자 투명도로 통일.
        panelShadowNode.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(UILayout.glassPillShadowAlpha)
        panelShadowNode.strokeColor = .clear
        panelShadowNode.lineWidth = 0
        panelShadowNode.position = CGPoint(x: 0, y: UILayout.overlayButtonShadowOffsetY)
        panelShadowNode.zPosition = ZOrder.profileDetailPanelZPosition - 1
        addChild(panelShadowNode)

        panelNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.profileDetailPanelFillAlpha)
        // v2 테두리: 얇은 코랄.
        panelNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.profileDetailPanelStrokeAlpha)
        panelNode.lineWidth = UILayout.profileDetailPanelLineWidth
        panelNode.zPosition = ZOrder.profileDetailPanelZPosition
        addChild(panelNode)

        // v2 악센트 스트립: 골드 잔재 제거 → 코랄.
        accentStripNode.fillColor = .ganhoCoralPrimary
        accentStripNode.strokeColor = .clear
        accentStripNode.lineWidth = 0
        accentStripNode.zPosition = ZOrder.profileDetailLabelZPosition
        addChild(accentStripNode)

        titleLabel.fontSize = UILayout.profileDetailTitleFontSize
        titleLabel.fontColor = .ganhoNavyDeep
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.zPosition = ZOrder.profileDetailLabelZPosition
        addChild(titleLabel)

        bodyLabel.fontSize = UILayout.profileDetailBodyFontSize
        bodyLabel.fontColor = .ganhoNavyMuted
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.profileDetailBodyWidth
        bodyLabel.zPosition = ZOrder.profileDetailLabelZPosition
        addChild(bodyLabel)

        avatarView.zPosition = ZOrder.profileDetailLabelZPosition
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
            size: UILayout.profileDetailAvatarSize
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
        let panelWidth = sceneSize.width < UILayout.compactNarrowWidth
            ? UILayout.profileDetailPanelCompactWidth
            : UILayout.profileDetailPanelWidth
        panelSize = CGSize(
            width: panelWidth,
            height: UILayout.profileDetailPanelHeight
        )
        panelFrame = CGRect(
            x: -panelSize.width / 2,
            y: -panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
        let panelPath = CGPath(
            roundedRect: panelFrame,
            cornerWidth: UILayout.profileDetailPanelCornerRadius,
            cornerHeight: UILayout.profileDetailPanelCornerRadius,
            transform: nil
        )
        panelNode.path = panelPath
        panelShadowNode.path = panelPath
        accentStripNode.path = CGPath(
            roundedRect: CGRect(
                x: -panelSize.width / 2 + UILayout.profileDetailPanelHorizontalInset,
                y: panelSize.height / 2 - UILayout.profileDetailPanelTopInset / 2,
                width: UILayout.accentLineWidth,
                height: UILayout.overlayButtonHighlightHeight
            ),
            cornerWidth: UILayout.overlayButtonHighlightHeight / 2,
            cornerHeight: UILayout.overlayButtonHighlightHeight / 2,
            transform: nil
        )
    }

    private func configureDetail(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileDetailTitleText
        bodyLabel.text = snapshot.profileDetailIdentityText
        layoutHeader()
        addMetricRow(snapshot: snapshot)
        addDetailButtons(snapshot: snapshot)
    }

    private func configureAvatarPicker(avatar: ProfileAvatarSnapshot,
                                       unlockedCharacters: [CharacterID]) {
        titleLabel.text = UILayout.profileDetailAvatarPickerTitleText
        bodyLabel.text = UILayout.profileDetailAvatarPickerBodyText
        layoutHeader()

        let optionCharacters = unlockedCharacters.isEmpty ? [.kim] : unlockedCharacters
        let count = CGFloat(optionCharacters.count)
        let totalWidth = UILayout.profileDetailAvatarOptionSize.width * count
            + UILayout.profileDetailAvatarOptionGap * max(0, count - 1)
        var currentX = -totalWidth / 2 + UILayout.profileDetailAvatarOptionSize.width / 2

        for characterID in optionCharacters {
            addAvatarOption(
                characterID: characterID,
                selected: avatar.selectedID.characterID == characterID,
                position: CGPoint(x: currentX, y: UILayout.profileDetailAvatarOptionsOffsetY)
            )
            currentX += UILayout.profileDetailAvatarOptionSize.width
                + UILayout.profileDetailAvatarOptionGap
        }

        let photoButton = makeButton(
            text: UILayout.profileDetailChoosePhotoText,
            width: UILayout.profileDetailWideButtonWidth,
            action: .choosePhoto,
            style: .secondary
        )
        photoButton.position = CGPoint(
            x: -UILayout.profileDetailWideButtonWidth / 2 - UILayout.profileDetailButtonGap / 2,
            y: UILayout.profileDetailBottomButtonOffsetY
        )
        addDynamicNode(photoButton)

        let closeButton = makeButton(
            text: UILayout.profileDetailCloseText,
            width: UILayout.profileDetailButtonWidth,
            action: .close,
            style: .secondary
        )
        closeButton.position = CGPoint(
            x: UILayout.profileDetailButtonWidth / 2 + UILayout.profileDetailButtonGap / 2,
            y: UILayout.profileDetailBottomButtonOffsetY
        )
        addDynamicNode(closeButton)
    }

    private func configureBusy(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileDetailBusyTitleText
        bodyLabel.text = UILayout.profileDetailBusyBodyText
        layoutHeader()
        addMetricRow(snapshot: snapshot)
    }

    private func configureNicknamePrompt(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileNicknamePromptTitleText
        bodyLabel.text = UILayout.profileNicknamePromptBodyText
        layoutHeader()
        addMetricRow(snapshot: snapshot)

        let buttons = [
            makeButton(
                text: UILayout.profileNicknamePromptButtonText,
                width: UILayout.profileDetailWideButtonWidth,
                action: .editProfileName,
                style: .primary
            ),
            makeButton(
                text: UILayout.profileDetailCloseText,
                width: UILayout.profileDetailButtonWidth,
                action: .close,
                style: .secondary
            )
        ]
        layoutButtonRow(buttons, y: UILayout.profileDetailSecondButtonRowOffsetY)
    }

    private func layoutHeader() {
        let leftX = -panelSize.width / 2 + UILayout.profileDetailPanelHorizontalInset
        let topY = panelSize.height / 2 - UILayout.profileDetailPanelTopInset
        avatarView.position = CGPoint(
            x: leftX + UILayout.profileDetailAvatarSize.width / 2,
            y: topY - UILayout.profileDetailAvatarSize.height / 2
        )
        titleLabel.position = CGPoint(
            x: leftX + UILayout.profileDetailAvatarSize.width + UILayout.profileDetailHeaderTextGap,
            y: topY - UILayout.profileDetailTitleOffsetY
        )
        bodyLabel.position = CGPoint(
            x: titleLabel.position.x,
            y: titleLabel.position.y - UILayout.profileDetailBodyBelowTitleGap
        )
    }

    private func addMetricRow(snapshot: CharacterHomeSnapshot) {
        let labels = [
            (UILayout.characterHomePlayCountLabelText, "\(snapshot.playCount)\(UILayout.characterHomePlaySuffixText)"),
            (UILayout.characterHomeBestScoreLabelText, "\(snapshot.highScore)\(UILayout.characterHomePointSuffixText)"),
            (UILayout.characterHomeTotalScoreLabelText, "\(snapshot.totalScore)\(UILayout.characterHomePointSuffixText)")
        ]
        let totalWidth = UILayout.profileDetailMetricWidth * CGFloat(labels.count)
            + UILayout.profileDetailMetricGap * CGFloat(max(0, labels.count - 1))
        var currentX = -totalWidth / 2 + UILayout.profileDetailMetricWidth / 2
        for item in labels {
            let title = makeLabel(
                text: item.0,
                fontName: Typography.fontBody,
                fontSize: UILayout.profileDetailMetricTitleFontSize,
                color: .ganhoNavyMuted
            )
            title.position = CGPoint(x: currentX, y: UILayout.profileDetailMetricTitleOffsetY)
            addDynamicNode(title)

            let value = makeLabel(
                text: item.1,
                fontName: Typography.fontNumeric,
                fontSize: UILayout.profileDetailMetricValueFontSize,
                color: .ganhoNavyDeep
            )
            value.position = CGPoint(x: currentX, y: UILayout.profileDetailMetricValueOffsetY)
            addDynamicNode(value)
            currentX += UILayout.profileDetailMetricWidth + UILayout.profileDetailMetricGap
        }
    }

    private func addDetailButtons(snapshot: CharacterHomeSnapshot) {
        let firstRow = [
            makeButton(
                text: UILayout.profileDetailEditNameText,
                width: UILayout.profileDetailWideButtonWidth,
                action: .editProfileName,
                style: .primary
            ),
            makeButton(
                text: UILayout.profileDetailChooseAvatarText,
                width: UILayout.profileDetailWideButtonWidth,
                action: .chooseAvatar,
                style: .secondary
            ),
            makeButton(
                text: UILayout.profileDetailChoosePhotoText,
                width: UILayout.profileDetailWideButtonWidth,
                action: .choosePhoto,
                style: .secondary
            )
        ]

        let accountButton = snapshot.isAppleLinked
            ? makeButton(
                text: UILayout.accountMenuSignOutText,
                width: UILayout.profileDetailButtonWidth,
                action: .signOut,
                style: .secondary
            )
            : makeButton(
                text: UILayout.authAppleButtonText,
                width: UILayout.profileDetailWideButtonWidth,
                action: .linkApple,
                style: .primary
            )
        layoutButtonRow(firstRow, y: UILayout.profileDetailFirstButtonRowOffsetY)

        let secondRow = [
            accountButton,
            makeButton(
                text: UILayout.accountMenuDeleteText,
                width: UILayout.profileDetailButtonWidth,
                action: .requestDeleteConfirmation,
                style: .destructive
            ),
            makeButton(
                text: UILayout.profileDetailCloseText,
                width: UILayout.profileDetailButtonWidth,
                action: .close,
                style: .secondary
            )
        ]
        layoutButtonRow(secondRow, y: UILayout.profileDetailSecondButtonRowOffsetY)
    }

    private func addAvatarOption(characterID: CharacterID,
                                 selected: Bool,
                                 position: CGPoint) {
        let optionSize = UILayout.profileDetailAvatarOptionSize
        let card = SKShapeNode(
            rectOf: optionSize,
            cornerRadius: UILayout.profileDetailAvatarOptionCornerRadius
        )
        // v2 톤: 선택 = 부드러운 코랄 패드 + 코랄 테두리, 미선택 = 크림 + navyMuted 테두리.
        card.fillColor = selected
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.profileDetailAvatarOptionSelectedCoralFillAlpha)
            : UIColor.ganhoPaper.withAlphaComponent(UILayout.profileDetailAvatarOptionFillAlpha)
        card.strokeColor = selected
            ? .ganhoCoralPrimary
            : UIColor.ganhoNavyMuted.withAlphaComponent(UILayout.profileDetailPanelStrokeAlpha)
        card.lineWidth = selected
            ? UILayout.profileDetailAvatarOptionSelectedLineWidth
            : UILayout.profileDetailPanelLineWidth
        card.position = position
        card.zPosition = ZOrder.profileDetailButtonZPosition
        addDynamicNode(card, action: .selectAvatar(characterID))

        let portrait = CharacterPortraitNode(
            characterID: characterID,
            maxSize: UILayout.profileDetailAvatarOptionPortraitSize
        )
        portrait.position = CGPoint(
            x: position.x,
            y: position.y - UILayout.profileDetailAvatarOptionPortraitSize.height / 2
                + UILayout.profileDetailAvatarOptionPortraitOffsetY
        )
        portrait.zPosition = ZOrder.profileDetailButtonZPosition + 1
        addDynamicNode(portrait)

        let label = makeLabel(
            text: characterID.displayName,
            fontName: Typography.fontDisplay,
            fontSize: UILayout.profileDetailAvatarOptionLabelFontSize,
            color: selected ? .ganhoPaper : .ganhoNavyDeep
        )
        label.position = CGPoint(
            x: position.x,
            y: position.y + UILayout.profileDetailAvatarOptionLabelOffsetY
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
                height: UILayout.profileDetailButtonHeight
            ),
            style: style
        )
        button.zPosition = ZOrder.profileDetailButtonZPosition
        actionTargets.append((node: button, action: action))
        return button
    }

    private func layoutButtonRow(_ buttons: [OverlayActionButtonNode], y: CGFloat) {
        guard !buttons.isEmpty else { return }
        let totalWidth = buttons.reduce(CGFloat.zero) { result, button in
            result + button.calculateAccumulatedFrame().width
        } + UILayout.profileDetailButtonGap * CGFloat(max(0, buttons.count - 1))
        var currentX = -totalWidth / 2
        for button in buttons {
            let width = button.calculateAccumulatedFrame().width
            button.position = CGPoint(x: currentX + width / 2, y: y)
            currentX += width + UILayout.profileDetailButtonGap
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
        label.zPosition = ZOrder.profileDetailLabelZPosition
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
