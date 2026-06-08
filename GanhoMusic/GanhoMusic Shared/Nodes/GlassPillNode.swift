//
//  GlassPillNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  크림 알약 + 낮은 네이비 테두리 + 라벨. CharacterSelectScene 뒤로 버튼,
//  통계 칩, D-Pad 키, 난이도 칩에서 재사용.
//

import SpriteKit

/// 크림(ganhoPaper) 알약 + 낮은 네이비 테두리 + Jua 라벨.
/// 부모(SKNode) = 좌표·name, 자식 = 시각. hit-test는 호출부의 `contains(location)` 패턴.
final class GlassPillNode: SKNode {

    // MARK: - Properties
    /// 톤다운 sprint 기본값에서는 숨겨지는 그림자 노드. destructive 등 미래 스타일 호환용으로 유지.
    private let shadowShape: SKShapeNode
    /// 기존 계층 호환용 effect container. 기본 스타일에서는 filter를 쓰지 않는다.
    private let blurEffect: SKEffectNode
    /// 크림 알약 배경.
    private let background: SKShapeNode
    /// 라벨. fontName = Jua-Regular(없으면 시스템 fallback), fontColor = navyDeep.
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// - Parameters:
    ///   - text: 라벨 텍스트.
    ///   - size: 알약 크기. cornerRadius = size.height/2 자동 (border-radius:999 동일).
    init(text: String, size: CGSize) {
        shadowShape = SKShapeNode(
            rectOf: size,
            cornerRadius: size.height / 2
        )
        shadowShape.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.glassPillShadowAlpha)
        shadowShape.strokeColor = .clear
        shadowShape.lineWidth = 0
        shadowShape.position = CGPoint(x: 0, y: GameConfig.glassPillShadowOffsetY)
        shadowShape.zPosition = -1
        shadowShape.isHidden = GameConfig.glassPillShadowAlpha <= .zero

        background = SKShapeNode(
            rectOf: size,
            cornerRadius: size.height / 2
        )
        background.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.menuControlFillAlpha)
        background.strokeColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.menuControlStrokeAlpha)
        background.lineWidth = GameConfig.glassPillBorderWidth

        blurEffect = SKEffectNode()
        blurEffect.filter = nil
        blurEffect.shouldRasterize = false

        textLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)

        super.init()
        name = "glassPill"
        zPosition = 100

        // 계층: self → shadowShape(z=-1, 블러 밖) → blurEffect → background (블러 적용 대상)
        //        self → textLabel (블러 비적용, 또렷한 라벨)
        // 그림자는 반드시 blurEffect *밖*에 부착 — 안에 넣으면 그림자도 블러된다.
        addChild(shadowShape)
        blurEffect.addChild(background)
        addChild(blurEffect)
        configureLabel(text: text)
        addChild(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// 라벨 스타일 — 알약 정중앙. blurEffect 위(zPosition=1)에 또렷하게 표시.
    private func configureLabel(text: String) {
        textLabel.text = text
        textLabel.fontSize = GameConfig.glassPillFontSize
        textLabel.fontColor = .ganhoNavyDeep
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
        textLabel.zPosition = 1
    }

    func setText(_ text: String) {
        textLabel.text = text
    }

    // MARK: - Style
    /// 계정 삭제 등 파괴적 액션용 톤(딥코랄 fill + 흰 글자). init 이후 호출 — 시그니처 불변.
    /// setText(_:)가 fontColor를 건드리지 않으므로 confirmDelete 모드 전환 후에도 글자색 유지.
    func applyDestructiveStyle() {
        background.fillColor = UIColor.ganhoCoralShadow.withAlphaComponent(GameConfig.glassPillDestructiveFillAlpha)
        background.strokeColor = .ganhoCoralShadow
        textLabel.fontColor = .ganhoPaper
        shadowShape.fillColor = UIColor.ganhoInkBlack.withAlphaComponent(GameConfig.glassPillShadowAlpha)
    }

    /// 캐릭터 홈 메뉴 버튼과 같은 크림 배경 + 네이비 테두리 톤.
    /// 기본 GlassPill 스타일은 유지하고, 지정 호출부에서만 선택적으로 적용한다.
    func applyCharacterHomeMenuStyle(active: Bool = false) {
        shadowShape.isHidden = true
        blurEffect.filter = nil
        blurEffect.shouldRasterize = false

        background.fillColor = active
            ? .ganhoCoralPrimary
            : UIColor.ganhoPaper.withAlphaComponent(GameConfig.characterHomePanelFillAlpha)
        background.strokeColor = active
            ? UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelFocusedStrokeAlpha)
            : UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.characterHomePanelStrokeAlpha)
        background.lineWidth = GameConfig.characterHomePanelLineWidth

        textLabel.fontSize = GameConfig.characterHomeMenuFontSize
        textLabel.fontColor = active ? .ganhoPaper : .ganhoNavyDeep
    }
}
