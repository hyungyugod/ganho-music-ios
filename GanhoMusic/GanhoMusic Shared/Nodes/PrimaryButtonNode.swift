//
//  PrimaryButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 주요 액션 버튼 — 캡슐 모양 + 라벨, contains(_:) hit-test
//  Sprint 1 · v2 Design System 리스타일 — 내부 시각만 코랄 + 그림자 + 화살표 + Jua로 교체.
//
//  부모 = 좌표·name, 자식 = 시각 패턴.
//  init 시그니처 / 타입 이름 / name="primaryButton" / zPosition=100 / 크기 상수 모두 보존 —
//  잔존 호출부(GameScene 일시정지) 컴파일 그대로 — 메뉴 4씬은 R4에서 PixelButtonNode로 이행.
//

import SpriteKit

/// 주요 액션 버튼(시작·이 친구로 시작 등). PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식: shadow → background → arrowCircle → arrowLabel → textLabel.
/// 캡슐 모양: cornerRadius = height/2 → border-radius:999 동일 효과 (8-3 패턴).
final class PrimaryButtonNode: SKNode {

    // MARK: - Properties
    /// 코랄 fill 캡슐 배경. fillColor = ganhoCoralPrimary, stroke = clear.
    private let background: SKShapeNode
    /// 입체감용 그림자 (배경과 동일 모양, y=-6 오프셋, fillColor = ganhoCoralShadow).
    private let shadowShape: SKShapeNode
    /// 우측 화살표 원 (흰색 α=0.25 동그라미). 시각 위계 — *전진 가능*을 암시.
    private let arrowCircle: SKShapeNode
    /// 우측 화살표 라벨 "▶" — 흰색, 작은 폰트.
    private let arrowLabel: SKLabelNode
    /// 버튼 텍스트. fontColor = .white, fontName = Jua-Regular.
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// 버튼 텍스트만 받아 그림자 + 배경 + 화살표 + 라벨 부착.
    /// 크기는 UILayout 상수(primaryButtonWidth/Height) 고정 — 호출부 변동 없음.
    init(text: String) {
        let buttonSize = CGSize(
            width: UILayout.primaryButtonWidth,
            height: UILayout.primaryButtonHeight
        )
        let cornerRadius = buttonSize.height / 2

        // (1) 그림자 — 배경과 동일 모양, 살짝 아래(y=primaryButtonShadowOffsetY).
        shadowShape = SKShapeNode(
            rectOf: buttonSize,
            cornerRadius: cornerRadius
        )
        shadowShape.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(UILayout.menuControlShadowAlpha)
        shadowShape.strokeColor = .clear
        shadowShape.lineWidth = 0
        shadowShape.isHidden = UILayout.menuControlShadowAlpha <= .zero

        // (2) 본 배경 — 코랄 fill, stroke 없음(v2는 그림자만으로 위계 표현).
        background = SKShapeNode(
            rectOf: buttonSize,
            cornerRadius: cornerRadius
        )
        background.fillColor = .ganhoCoralPrimary
        background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(UILayout.menuControlStrokeAlpha)
        background.lineWidth = UILayout.menuControlLineWidth

        // (3) 우측 화살표 원 — 배경 우측 끝에서 primaryButtonArrowInsetX 안쪽.
        arrowCircle = SKShapeNode(circleOfRadius: UILayout.primaryButtonArrowRadius)
        arrowCircle.fillColor = UIColor.white
            .withAlphaComponent(UILayout.primaryButtonArrowCircleAlpha)
        arrowCircle.strokeColor = .clear
        arrowCircle.lineWidth = 0

        // (4) 화살표 라벨 — 원 중앙.
        arrowLabel = SKLabelNode(fontNamed: Typography.fontDisplay)

        // (5) 본 라벨.
        textLabel = SKLabelNode(fontNamed: Typography.fontDisplay)

        super.init()
        name = "primaryButton"
        zPosition = 100

        // 배치 순서: shadow(z=-1) → background(z=0) → arrowCircle(z=1) → arrowLabel(z=2) → textLabel(z=2)
        shadowShape.position = CGPoint(x: 0, y: UILayout.primaryButtonShadowOffsetY)
        shadowShape.zPosition = -1
        addChild(shadowShape)

        background.position = .zero
        background.zPosition = 0
        addChild(background)

        let arrowX = buttonSize.width / 2 - UILayout.primaryButtonArrowInsetX
        arrowCircle.position = CGPoint(x: arrowX, y: 0)
        arrowCircle.zPosition = 1
        addChild(arrowCircle)

        configureArrowLabel(centerX: arrowX)
        addChild(arrowLabel)

        configureTextLabel(text: text)
        addChild(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// 우측 화살표 라벨 스타일 — 원 중앙, 흰색 작은 폰트.
    private func configureArrowLabel(centerX: CGFloat) {
        arrowLabel.text = "▶"
        arrowLabel.fontSize = UILayout.primaryButtonArrowLabelFontSize
        arrowLabel.fontColor = .white
        arrowLabel.horizontalAlignmentMode = .center
        arrowLabel.verticalAlignmentMode = .center
        arrowLabel.position = CGPoint(x: centerX, y: 0)
        arrowLabel.zPosition = 2
    }

    /// 텍스트 라벨 스타일 — 캡슐 정중앙.
    private func configureTextLabel(text: String) {
        textLabel.text = text
        textLabel.fontSize = UILayout.primaryButtonFontSize
        textLabel.fontColor = .white
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
        textLabel.zPosition = 2
        fitTextLabel()
    }

    private func fitTextLabel() {
        textLabel.setScale(1.0)
        let maxWidth = UILayout.primaryButtonWidth
            - UILayout.primaryButtonTextHorizontalPadding * 2
            - UILayout.primaryButtonArrowReservedWidth
        let width = textLabel.calculateAccumulatedFrame().width
        guard width > maxWidth, width > 0 else { return }
        let scale = max(Typography.labelMinimumScale, maxWidth / width)
        textLabel.setScale(scale)
    }
}
