//
//  GlassPillNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  크림 알약 + 코랄 테두리 + 입체 그림자 + 가우시안 블러 + 라벨. CharacterSelectScene 뒤로 버튼,
//  통계 칩, D-Pad 키, 난이도 칩에서 재사용.
//  SKEffectNode + CIGaussianBlur는 iOS 13+ — 시뮬레이터에서도 정상 작동.
//

import SpriteKit
import CoreImage

/// 크림(ganhoPaper) 알약 + 코랄 2px 테두리 + 입체 그림자 + 가우시안 블러 + Jua 라벨.
/// 묶음 A "Secondary 버튼 3계층"의 본보기 — 흰·크림이라도 그림자+테두리로 "버튼임"을 전달.
/// 부모(SKNode) = 좌표·name, 자식 = 시각. hit-test는 호출부의 `contains(location)` 패턴.
final class GlassPillNode: SKNode {

    // MARK: - Properties
    /// 입체 그림자(블러 비대상). background와 동일 모양 — blurEffect *밖*에 직접 부착해
    /// 그림자가 블러로 흐려지지 않도록 한다. zPosition=-1로 배경보다 아래.
    private let shadowShape: SKShapeNode
    /// 블러 효과 컨테이너 — background를 자식으로 감싸 가우시안 블러를 적용한다.
    private let blurEffect: SKEffectNode
    /// 크림 알약 배경. fillColor = ganhoPaper α=0.82(불투명 상향), strokeColor = 코랄 2px.
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

        background = SKShapeNode(
            rectOf: size,
            cornerRadius: size.height / 2
        )
        background.fillColor = UIColor.ganhoPaper.withAlphaComponent(GameConfig.glassPillFillAlpha)
        background.strokeColor = .ganhoCoralPrimary
        background.lineWidth = GameConfig.glassPillBorderWidth

        blurEffect = SKEffectNode()
        // SKEffectNode.filter는 CIFilter? 옵셔널 — CIFilter(name:) 옵셔널 결과를 직접 대입.
        // 강제 언래핑 0건 — filter 자체가 nil 허용이라 별도 가드 불필요.
        blurEffect.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": GameConfig.glassPillBlurRadius]
        )
        blurEffect.shouldRasterize = true

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
}
