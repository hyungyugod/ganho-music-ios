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
    private let iconLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let titleLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let subtitleLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    private var isEnabled = true

    // MARK: - Init
    init(title: String,
         subtitle: String?,
         size: CGSize,
         style: OverlayActionButtonStyle,
         iconText: String? = nil) {
        self.buttonSize = size
        self.style = style
        let cornerRadius = min(GameConfig.overlayButtonCornerRadius, size.height / 2)
        shadowNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        highlightNode = SKShapeNode(
            rectOf: CGSize(width: size.width - GameConfig.overlayButtonCornerRadius,
                           height: GameConfig.overlayButtonHighlightHeight),
            cornerRadius: GameConfig.overlayButtonHighlightHeight / 2
        )
        iconCircleNode = SKShapeNode(circleOfRadius: GameConfig.overlayButtonIconRadius)
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
        shadowNode.position = CGPoint(x: 0, y: GameConfig.overlayButtonShadowOffsetY)
        shadowNode.fillColor = shadowColor
        shadowNode.strokeColor = .clear
        shadowNode.lineWidth = 0
        shadowNode.zPosition = -1
        addChild(shadowNode)

        backgroundNode.fillColor = fillColor
        backgroundNode.strokeColor = strokeColor
        backgroundNode.lineWidth = GameConfig.overlayButtonLineWidth
        backgroundNode.zPosition = 0
        contentNode.addChild(backgroundNode)

        highlightNode.position = CGPoint(
            x: 0,
            y: buttonSize.height / 2 - GameConfig.overlayButtonHighlightHeight
        )
        highlightNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.overlayButtonHighlightAlpha)
        highlightNode.strokeColor = .clear
        highlightNode.lineWidth = 0
        highlightNode.zPosition = 1
        contentNode.addChild(highlightNode)

        iconCircleNode.position = CGPoint(
            x: -buttonSize.width / 2 + GameConfig.overlayButtonIconOffsetX,
            y: 0
        )
        iconCircleNode.fillColor = iconFillColor
        iconCircleNode.strokeColor = .clear
        iconCircleNode.lineWidth = 0
        iconCircleNode.zPosition = 2
        contentNode.addChild(iconCircleNode)

        iconLabel.text = resolvedIconText(iconText)
        iconLabel.fontSize = GameConfig.overlayButtonSubtitleFontSize
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
            return GameConfig.overlayButtonDefaultIconText
        case .secondary:
            return GameConfig.overlayButtonSecondaryIconText
        case .destructive:
            return GameConfig.overlayButtonDestructiveIconText
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
        alpha = enabled ? 1.0 : GameConfig.overlayButtonDisabledAlpha
    }

    func playPressFeedback() {
        guard isEnabled else { return }
        contentNode.removeAction(forKey: GameConfig.overlayButtonPressActionKey)
        contentNode.position = .zero
        let down = SKAction.moveBy(
            x: 0,
            y: GameConfig.overlayButtonPressedOffsetY,
            duration: GameConfig.overlayButtonPressDuration
        )
        let up = SKAction.moveBy(
            x: 0,
            y: -GameConfig.overlayButtonPressedOffsetY,
            duration: GameConfig.overlayButtonPressDuration
        )
        contentNode.run(
            SKAction.sequence([down, up]),
            withKey: GameConfig.overlayButtonPressActionKey
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
        let leftX = -buttonSize.width / 2 + GameConfig.overlayButtonTextLeftInset
        if subtitleLabel.isHidden {
            titleLabel.fontSize = GameConfig.overlayButtonSingleTitleFontSize
            titleLabel.position = CGPoint(
                x: leftX,
                y: GameConfig.overlayButtonSingleTitleOffsetY
            )
        } else {
            titleLabel.fontSize = GameConfig.overlayButtonTitleFontSize
            titleLabel.position = CGPoint(
                x: leftX,
                y: GameConfig.overlayButtonTitleOffsetY
            )
            subtitleLabel.fontSize = GameConfig.overlayButtonSubtitleFontSize
            subtitleLabel.position = CGPoint(
                x: leftX,
                y: GameConfig.overlayButtonSubtitleOffsetY
            )
        }
        fit(label: titleLabel)
        fit(label: subtitleLabel)
    }

    private func fit(label: SKLabelNode) {
        guard !label.isHidden else { return }
        let maxWidth = buttonSize.width
            - GameConfig.overlayButtonTextLeftInset
            - GameConfig.overlayButtonTextRightInset
        let width = label.calculateAccumulatedFrame().width
        guard width > maxWidth, width > 0 else { return }
        label.setScale(max(GameConfig.labelMinimumScale, maxWidth / width))
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
            return .clear
        case .secondary:
            return .ganhoCoralPrimary
        case .destructive:
            return .ganhoCoralShadow
        }
    }

    private var shadowColor: UIColor {
        switch style {
        case .primary:
            return .ganhoCoralShadow
        case .secondary:
            return UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.glassPillShadowAlpha)
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
            return UIColor.ganhoPaper.withAlphaComponent(GameConfig.ingameHUDReadableAlpha)
        case .secondary:
            return .ganhoNavyMuted
        }
    }

    private var iconFillColor: UIColor {
        switch style {
        case .primary, .destructive:
            return UIColor.ganhoPaper.withAlphaComponent(GameConfig.primaryButtonArrowCircleAlpha)
        case .secondary:
            // 코랄 아이콘 원 — SPEC 0.18~0.25 범위. glassPillStrokeAlpha(0.25) 재사용으로 매직 넘버 0.
            return UIColor.ganhoCoralPrimary.withAlphaComponent(GameConfig.glassPillStrokeAlpha)
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
