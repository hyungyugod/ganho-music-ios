//
//  ProfileSummaryPanelNode.swift
//  GanhoMusic Shared
//
//  Sprint 2 - Character home profile summary panel.
//

import SpriteKit

/// 계정/누적 기록 요약 패널. Repository를 읽지 않고 CharacterHomeSnapshot만 표시한다.
final class ProfileSummaryPanelNode: SKNode {

    // MARK: - Properties
    private let background = SKShapeNode()
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let statusChip = SKShapeNode()
    private let statusLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let nameLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let subLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let playTitleLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let playValueLabel = SKLabelNode(fontNamed: GameConfig.fontNumeric)
    private let bestTitleLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let bestValueLabel = SKLabelNode(fontNamed: GameConfig.fontNumeric)
    private let totalTitleLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private let totalValueLabel = SKLabelNode(fontNamed: GameConfig.fontNumeric)
    private var layoutScale: CGFloat = 1.0
    private var isFocused = false

    // MARK: - Init
    override init() {
        super.init()
        zPosition = GameConfig.characterHomePanelZPosition
        setupPanel()
        setupLabels()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupPanel() {
        background.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        background.lineWidth = GameConfig.characterHomePanelLineWidth
        addChild(background)

        statusChip.fillColor = .ganhoNavyDeep
        statusChip.strokeColor = .clear
        statusChip.zPosition = 1
        addChild(statusChip)
    }

    private func setupLabels() {
        titleLabel.text = GameConfig.characterHomeProfileTitleText
        configure(label: titleLabel, fontSize: GameConfig.characterHomePanelTitleFontSize, color: .ganhoNavyDeep)
        configure(label: statusLabel, fontSize: GameConfig.characterHomePanelSmallFontSize, color: .ganhoMusicGold)
        configure(label: nameLabel, fontSize: GameConfig.characterHomePanelValueFontSize, color: .ganhoNavyDeep)
        configure(label: subLabel, fontSize: GameConfig.characterHomePanelBodyFontSize, color: .ganhoNavyMuted)
        configure(label: playTitleLabel, fontSize: GameConfig.characterHomePanelMetricFontSize, color: .ganhoNavyMuted)
        configure(label: playValueLabel, fontSize: GameConfig.characterHomePanelValueFontSize, color: .ganhoNavyDeep)
        configure(label: bestTitleLabel, fontSize: GameConfig.characterHomePanelMetricFontSize, color: .ganhoNavyMuted)
        configure(label: bestValueLabel, fontSize: GameConfig.characterHomePanelValueFontSize, color: .ganhoCoralPrimary)
        configure(label: totalTitleLabel, fontSize: GameConfig.characterHomePanelMetricFontSize, color: .ganhoNavyMuted)
        configure(label: totalValueLabel, fontSize: GameConfig.characterHomePanelValueFontSize, color: .ganhoNavyDeep)

        playTitleLabel.text = GameConfig.characterHomePlayCountLabelText
        bestTitleLabel.text = GameConfig.characterHomeBestScoreLabelText
        totalTitleLabel.text = GameConfig.characterHomeTotalScoreLabelText

        [
            titleLabel, statusLabel, nameLabel, subLabel,
            playTitleLabel, playValueLabel,
            bestTitleLabel, bestValueLabel,
            totalTitleLabel, totalValueLabel
        ].forEach { addChild($0) }
    }

    private func configure(label: SKLabelNode, fontSize: CGFloat, color: UIColor) {
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 2
    }

    // MARK: - Update
    func update(snapshot: CharacterHomeSnapshot) {
        statusLabel.text = snapshot.accountStatusText
        nameLabel.text = snapshot.profileNameText
        subLabel.text = snapshot.profileSubText
        playValueLabel.text = "\(snapshot.playCount)\(GameConfig.characterHomePlaySuffixText)"
        bestValueLabel.text = scoreText(snapshot.highScore)
        totalValueLabel.text = scoreText(snapshot.totalScore)
    }

    private func scoreText(_ score: Int) -> String {
        return "\(score)\(GameConfig.characterHomePointSuffixText)"
    }

    // MARK: - Layout
    func layout(size: CGSize) {
        background.path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: GameConfig.characterHomePanelCornerRadius,
            cornerHeight: GameConfig.characterHomePanelCornerRadius,
            transform: nil
        )
        statusChip.path = CGPath(
            roundedRect: CGRect(
                x: -GameConfig.characterHomeProfileStatusChipWidth / 2,
                y: -GameConfig.characterHomeProfileStatusChipHeight / 2,
                width: GameConfig.characterHomeProfileStatusChipWidth,
                height: GameConfig.characterHomeProfileStatusChipHeight
            ),
            cornerWidth: GameConfig.characterHomeProfileStatusChipHeight / 2,
            cornerHeight: GameConfig.characterHomeProfileStatusChipHeight / 2,
            transform: nil
        )

        let leftX = -size.width / 2 + GameConfig.characterHomePanelHorizontalInset
        var cursorY = size.height / 2 - GameConfig.characterHomePanelVerticalInset
        titleLabel.position = CGPoint(x: leftX, y: cursorY)
        cursorY -= GameConfig.characterHomePanelTitleFontSize + GameConfig.characterHomeDetailPanelGap

        statusChip.position = CGPoint(
            x: leftX + GameConfig.characterHomeProfileStatusChipWidth / 2,
            y: cursorY
        )
        statusLabel.position = CGPoint(
            x: statusChip.position.x - GameConfig.characterHomeProfileStatusChipWidth / 2
                + GameConfig.characterHomePanelHorizontalInset,
            y: cursorY
        )
        cursorY -= GameConfig.characterHomeProfileStatusChipHeight / 2
            + GameConfig.characterHomeDetailPanelGap
            + GameConfig.characterHomePanelValueFontSize / 2

        nameLabel.position = CGPoint(x: leftX, y: cursorY)
        cursorY -= GameConfig.characterHomePanelValueFontSize
            + GameConfig.characterHomeAchievementBadgeGap

        subLabel.preferredMaxLayoutWidth = size.width - GameConfig.characterHomePanelHorizontalInset * 2
        subLabel.position = CGPoint(x: leftX, y: cursorY)
        cursorY -= GameConfig.characterHomePanelBodyFontSize
            + GameConfig.characterHomeDetailPanelGap

        layoutMetric(
            title: playTitleLabel,
            value: playValueLabel,
            leftX: leftX,
            y: cursorY
        )
        cursorY -= GameConfig.characterHomeProfileMetricGap
        layoutMetric(
            title: bestTitleLabel,
            value: bestValueLabel,
            leftX: leftX,
            y: cursorY
        )
        cursorY -= GameConfig.characterHomeProfileMetricGap
        layoutMetric(
            title: totalTitleLabel,
            value: totalValueLabel,
            leftX: leftX,
            y: cursorY
        )

        fit(label: nameLabel, maxWidth: size.width - GameConfig.characterHomePanelHorizontalInset * 2)
        fit(label: subLabel, maxWidth: size.width - GameConfig.characterHomePanelHorizontalInset * 2)
    }

    private func layoutMetric(title: SKLabelNode, value: SKLabelNode, leftX: CGFloat, y: CGFloat) {
        title.position = CGPoint(x: leftX, y: y)
        value.position = CGPoint(
            x: leftX,
            y: y - GameConfig.characterHomePanelMetricFontSize
                - GameConfig.characterHomeAchievementBadgeGap
        )
    }

    private func fit(label: SKLabelNode, maxWidth: CGFloat) {
        label.setScale(1.0)
        let width = label.calculateAccumulatedFrame().width
        guard width > maxWidth, width > 0 else { return }
        label.setScale(max(GameConfig.labelMinimumScale, maxWidth / width))
    }

    // MARK: - Focus
    func setLayoutScale(_ scale: CGFloat) {
        layoutScale = scale
        applyFocus(animated: false)
    }

    func setFocused(_ focused: Bool, animated: Bool) {
        isFocused = focused
        applyFocus(animated: animated)
    }

    private func applyFocus(animated: Bool) {
        alpha = isFocused ? 1.0 : GameConfig.characterHomeUnfocusedAlpha
        background.strokeColor = isFocused
            ? UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        let targetScale = layoutScale * (isFocused ? GameConfig.characterHomeFocusedScale : 1.0)
        removeAction(forKey: GameConfig.characterHomeSectionFocusActionKey)
        if animated {
            let action = SKAction.scale(
                to: targetScale,
                duration: GameConfig.characterHomeFocusAnimationDuration
            )
            action.timingMode = .easeInEaseOut
            run(action, withKey: GameConfig.characterHomeSectionFocusActionKey)
        } else {
            setScale(targetScale)
        }
    }
}
