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
    // 묶음 B 위계 강화용 추가 노드 — 메트릭 3종을 "한 덩어리"로 시각화.
    private let metricGroupBox = SKShapeNode()      // 라벤더 패드 (배경)
    private let metricDividerTop = SKShapeNode()    // 플레이↔최고
    private let metricDividerBottom = SKShapeNode() // 최고↔총점
    private let avatarView = ProfileAvatarViewNode()
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

        // 메트릭 그룹 박스(라벤더 패드) — 배경 위(zPosition 1), 라벨(zPosition 2) 아래.
        metricGroupBox.fillColor = UIColor.ganhoLavenderSoft
            .withAlphaComponent(GameConfig.summaryMetricGroupFillAlpha)
        metricGroupBox.strokeColor = .clear
        metricGroupBox.zPosition = 1
        addChild(metricGroupBox)

        // 메트릭 행 구분선 2개 — 라벤더 패드 위에 얇은 navyMuted 라인.
        [metricDividerTop, metricDividerBottom].forEach { divider in
            divider.fillColor = .clear
            divider.strokeColor = UIColor.ganhoNavyMuted
                .withAlphaComponent(GameConfig.summaryMetricDividerAlpha)
            divider.lineWidth = GameConfig.summaryMetricDividerLineWidth
            divider.zPosition = 1
            addChild(divider)
        }

        statusChip.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        statusChip.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        statusChip.lineWidth = GameConfig.characterHomePanelLineWidth
        statusChip.zPosition = 1
        addChild(statusChip)

        avatarView.zPosition = 2
        addChild(avatarView)
    }

    private func setupLabels() {
        titleLabel.text = GameConfig.characterHomeProfileTitleText
        configure(label: titleLabel, fontSize: GameConfig.characterHomePanelTitleFontSize, color: .ganhoNavyDeep)
        configure(label: statusLabel, fontSize: GameConfig.characterHomePanelSmallFontSize, color: .ganhoNavyDeep)
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

    func update(snapshot: CharacterHomeSnapshot,
                avatar: ProfileAvatarSnapshot,
                repository: ProfileAvatarRepository) {
        update(snapshot: snapshot)
        avatarView.update(
            snapshot: avatar,
            repository: repository,
            size: GameConfig.profileAvatarSummarySize
        )
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
        let avatarX = size.width / 2
            - GameConfig.characterHomePanelHorizontalInset
            - GameConfig.profileAvatarSummarySize.width / 2
        let avatarY = size.height / 2
            - GameConfig.characterHomePanelVerticalInset
            - GameConfig.profileAvatarSummarySize.height / 2
        avatarView.position = CGPoint(x: avatarX, y: avatarY)

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

        let textMaxWidth = avatarX
            - GameConfig.profileAvatarSummarySize.width / 2
            - GameConfig.characterHomeDetailPanelGap
            - leftX
        subLabel.preferredMaxLayoutWidth = max(
            GameConfig.characterHomeProfileStatusChipWidth,
            textMaxWidth
        )
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

        // 메트릭 3행이 모두 배치된 뒤, 그 Y 범위로 그룹 박스·구분선을 1회 구성.
        layoutMetricGroup(leftX: leftX, contentWidth: textMaxWidth)

        fit(label: nameLabel, maxWidth: subLabel.preferredMaxLayoutWidth)
        fit(label: subLabel, maxWidth: subLabel.preferredMaxLayoutWidth)
    }

    /// 메트릭 그룹 박스(라벤더 패드)와 행 구분선 2개의 path를 현재 메트릭 라벨 위치로 구성한다.
    /// 매 프레임이 아니라 `layout(size:)`에서 cursorY가 확정된 뒤 1회만 호출된다.
    /// - Parameters:
    ///   - leftX: 메트릭 텍스트 좌측 기준 X.
    ///   - contentWidth: 좌측 텍스트 열 폭(name/sub 라벨과 동일 기준).
    private func layoutMetricGroup(leftX: CGFloat, contentWidth: CGFloat) {
        let padding = GameConfig.summaryMetricGroupPadding
        let verticalPadding = GameConfig.summaryMetricGroupVerticalPadding
        let titleHalf = GameConfig.characterHomePanelMetricFontSize / 2
        let valueHalf = GameConfig.characterHomePanelValueFontSize / 2

        // 박스 세로 범위: 첫 제목 위 ~ 마지막 값 아래 (세로 패딩 포함).
        let groupTopY = playTitleLabel.position.y + titleHalf + verticalPadding
        let groupBottomY = totalValueLabel.position.y - valueHalf - verticalPadding
        let groupHeight = max(0, groupTopY - groupBottomY)
        let groupWidth = max(0, contentWidth + padding * 2)

        metricGroupBox.path = CGPath(
            roundedRect: CGRect(
                x: leftX - padding,
                y: groupBottomY,
                width: groupWidth,
                height: groupHeight
            ),
            cornerWidth: GameConfig.summaryMetricGroupCornerRadius,
            cornerHeight: GameConfig.summaryMetricGroupCornerRadius,
            transform: nil
        )

        // 구분선 X 범위: 박스 안쪽 좌우 패딩만큼 들여쓴 가로선.
        let dividerStartX = leftX
        let dividerEndX = leftX + contentWidth
        // 플레이↔최고: 플레이 값과 최고 제목 사이 중간.
        let topDividerY = (playValueLabel.position.y + bestTitleLabel.position.y) / 2
        // 최고↔총점: 최고 값과 총점 제목 사이 중간.
        let bottomDividerY = (bestValueLabel.position.y + totalTitleLabel.position.y) / 2

        metricDividerTop.path = horizontalLinePath(
            startX: dividerStartX,
            endX: dividerEndX,
            y: topDividerY
        )
        metricDividerBottom.path = horizontalLinePath(
            startX: dividerStartX,
            endX: dividerEndX,
            y: bottomDividerY
        )
    }

    private func horizontalLinePath(startX: CGFloat, endX: CGFloat, y: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
        return path
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
