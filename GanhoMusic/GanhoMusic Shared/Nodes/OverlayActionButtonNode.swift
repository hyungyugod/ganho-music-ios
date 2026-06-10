//
//  OverlayActionButtonNode.swift
//  GanhoMusic Shared
//
//  로그인/프로필 오버레이에서 쓰는 배경형 액션 버튼.
//

import SpriteKit

enum OverlayActionButtonStyle {
    case primary
    case secondary
    case destructive
}

final class OverlayActionButtonNode: SKNode {

    // MARK: - Properties
    private let buttonSize: CGSize
    private let style: OverlayActionButtonStyle
    private let shadowNode: SKShapeNode
    private let contentNode = SKNode()
    private let backgroundNode: SKShapeNode
    private let highlightNode: SKShapeNode
    private let iconCircleNode: SKShapeNode
    private let iconLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let titleLabel = SKLabelNode(fontNamed: Typography.fontDisplay)
    private let subtitleLabel = SKLabelNode(fontNamed: Typography.fontBody)
    private var isEnabled = true

    // MARK: - Init
    init(title: String,
         subtitle: String?,
         size: CGSize,
         style: OverlayActionButtonStyle,
         iconText: String? = nil) {
        self.buttonSize = size
        self.style = style
        let cornerRadius = min(UILayout.overlayButtonCornerRadius, size.height / 2)
        shadowNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        highlightNode = SKShapeNode(
            rectOf: CGSize(width: size.width - UILayout.overlayButtonCornerRadius,
                           height: UILayout.overlayButtonHighlightHeight),
            cornerRadius: UILayout.overlayButtonHighlightHeight / 2
        )
        iconCircleNode = SKShapeNode(circleOfRadius: UILayout.overlayButtonIconRadius)
        super.init()
        name = "overlayActionButton"
        configureNodes(iconText: iconText)
        setTitle(title)
        setSubtitle(subtitle)
    }

    @available(*, unavailable, message: "Use init(title:subtitle:size:style:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Configure
    private func configureNodes(iconText: String?) {
        shadowNode.position = CGPoint(x: 0, y: UILayout.overlayButtonShadowOffsetY)
        shadowNode.fillColor = shadowColor.withAlphaComponent(UILayout.menuControlShadowAlpha)
        shadowNode.strokeColor = .clear
        shadowNode.lineWidth = 0
        shadowNode.zPosition = -1
        shadowNode.isHidden = UILayout.menuControlShadowAlpha <= .zero
        addChild(shadowNode)

        backgroundNode.fillColor = fillColor
        backgroundNode.strokeColor = strokeColor
        backgroundNode.lineWidth = UILayout.overlayButtonLineWidth
        backgroundNode.zPosition = 0
        contentNode.addChild(backgroundNode)

        highlightNode.position = CGPoint(
            x: 0,
            y: buttonSize.height / 2 - UILayout.overlayButtonHighlightHeight
        )
        highlightNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.overlayButtonHighlightAlpha)
        highlightNode.strokeColor = .clear
        highlightNode.lineWidth = 0
        highlightNode.zPosition = 1
        highlightNode.isHidden = UILayout.overlayButtonHighlightAlpha <= .zero
        contentNode.addChild(highlightNode)

        iconCircleNode.position = CGPoint(
            x: -buttonSize.width / 2 + UILayout.overlayButtonIconOffsetX,
            y: 0
        )
        iconCircleNode.fillColor = iconFillColor
        iconCircleNode.strokeColor = .clear
        iconCircleNode.lineWidth = 0
        iconCircleNode.zPosition = 2
        contentNode.addChild(iconCircleNode)

        iconLabel.text = resolvedIconText(iconText)
        iconLabel.fontSize = UILayout.overlayButtonSubtitleFontSize
        iconLabel.fontColor = iconTextColor
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = iconCircleNode.position
        iconLabel.zPosition = 3
        contentNode.addChild(iconLabel)

        [titleLabel, subtitleLabel].forEach { label in
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.zPosition = 3
            contentNode.addChild(label)
        }
        titleLabel.fontColor = titleColor
        subtitleLabel.fontColor = subtitleColor
        addChild(contentNode)
    }

    private func resolvedIconText(_ iconText: String?) -> String {
        if let iconText = iconText {
            return iconText
        }
        switch style {
        case .primary:
            return UILayout.overlayButtonDefaultIconText
        case .secondary:
            return UILayout.overlayButtonSecondaryIconText
        case .destructive:
            return UILayout.overlayButtonDestructiveIconText
        }
    }

    // MARK: - Update
    func setTitle(_ text: String) {
        titleLabel.text = text
        layoutLabels()
    }

    func setSubtitle(_ text: String?) {
        subtitleLabel.text = text
        subtitleLabel.isHidden = text == nil
        layoutLabels()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : UILayout.overlayButtonDisabledAlpha
    }

    func playPressFeedback() {
        guard isEnabled else { return }
        guard UILayout.overlayButtonPressedOffsetY != .zero else { return }
        contentNode.removeAction(forKey: UILayout.overlayButtonPressActionKey)
        contentNode.position = .zero
        let down = SKAction.moveBy(
            x: 0,
            y: UILayout.overlayButtonPressedOffsetY,
            duration: UILayout.overlayButtonPressDuration
        )
        let up = SKAction.moveBy(
            x: 0,
            y: -UILayout.overlayButtonPressedOffsetY,
            duration: UILayout.overlayButtonPressDuration
        )
        contentNode.run(
            SKAction.sequence([down, up]),
            withKey: UILayout.overlayButtonPressActionKey
        )
    }

    override func contains(_ point: CGPoint) -> Bool {
        guard isEnabled, !isHidden else { return false }
        let rect = CGRect(
            x: position.x - buttonSize.width / 2,
            y: position.y - buttonSize.height / 2,
            width: buttonSize.width,
            height: buttonSize.height
        )
        return rect.contains(point)
    }

    private func layoutLabels() {
        titleLabel.setScale(1.0)
        subtitleLabel.setScale(1.0)
        let leftX = -buttonSize.width / 2 + UILayout.overlayButtonTextLeftInset
        if subtitleLabel.isHidden {
            titleLabel.fontSize = UILayout.overlayButtonSingleTitleFontSize
            titleLabel.position = CGPoint(
                x: leftX,
                y: UILayout.overlayButtonSingleTitleOffsetY
            )
        } else {
            titleLabel.fontSize = UILayout.overlayButtonTitleFontSize
            titleLabel.position = CGPoint(
                x: leftX,
                y: UILayout.overlayButtonTitleOffsetY
            )
            subtitleLabel.fontSize = UILayout.overlayButtonSubtitleFontSize
            subtitleLabel.position = CGPoint(
                x: leftX,
                y: UILayout.overlayButtonSubtitleOffsetY
            )
        }
        fit(label: titleLabel)
        fit(label: subtitleLabel)
    }

    private func fit(label: SKLabelNode) {
        guard !label.isHidden else { return }
        let maxWidth = buttonSize.width
            - UILayout.overlayButtonTextLeftInset
            - UILayout.overlayButtonTextRightInset
        let width = label.calculateAccumulatedFrame().width
        guard width > maxWidth, width > 0 else { return }
        label.setScale(max(Typography.labelMinimumScale, maxWidth / width))
    }

    // MARK: - Style
    // 묶음 A — v2 코랄·네이비 톤. primary=꽉 찬 코랄, secondary=크림+코랄 테두리, destructive=딥코랄.
    private var fillColor: UIColor {
        switch style {
        case .primary:
            return .ganhoCoralPrimary
        case .secondary:
            return .ganhoPaper
        case .destructive:
            return .ganhoCoralShadow
        }
    }

    private var strokeColor: UIColor {
        switch style {
        case .primary:
            return UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.menuControlStrokeAlpha)
        case .secondary:
            return UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.menuControlStrokeAlpha)
        case .destructive:
            return .ganhoCoralShadow
        }
    }

    private var shadowColor: UIColor {
        switch style {
        case .primary:
            return .ganhoCoralShadow
        case .secondary:
            return UIColor.ganhoCoralShadow.withAlphaComponent(UILayout.glassPillShadowAlpha)
        case .destructive:
            return .ganhoCoralShadow
        }
    }

    private var titleColor: UIColor {
        switch style {
        case .primary, .destructive:
            return .ganhoPaper
        case .secondary:
            return .ganhoNavyDeep
        }
    }

    private var subtitleColor: UIColor {
        switch style {
        case .primary, .destructive:
            return UIColor.ganhoPaper.withAlphaComponent(UILayout.ingameHUDReadableAlpha)
        case .secondary:
            return .ganhoNavyMuted
        }
    }

    private var iconFillColor: UIColor {
        switch style {
        case .primary, .destructive:
            return UIColor.ganhoPaper.withAlphaComponent(UILayout.primaryButtonArrowCircleAlpha)
        case .secondary:
            // 코랄 아이콘 원 — SPEC 0.18~0.25 범위. glassPillStrokeAlpha(0.25) 재사용으로 매직 넘버 0.
            return UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.glassPillStrokeAlpha)
        }
    }

    private var iconTextColor: UIColor {
        switch style {
        case .primary, .destructive:
            return .ganhoPaper
        case .secondary:
            return .ganhoNavyDeep
        }
    }
}
