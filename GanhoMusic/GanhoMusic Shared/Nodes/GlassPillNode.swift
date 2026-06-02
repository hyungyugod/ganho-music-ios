//
//  GlassPillNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  반투명 화이트 알약 + 가우시안 블러 + 라벨. CharacterSelectScene 뒤로 버튼,
//  통계 칩, D-Pad 키, 난이도 칩에서 재사용.
//  SKEffectNode + CIGaussianBlur는 iOS 13+ — 시뮬레이터에서도 정상 작동.
//

import SpriteKit
import CoreImage

/// 반투명 화이트 알약(α=0.55) + 가우시안 블러 + Jua 라벨.
/// 부모(SKNode) = 좌표·name, 자식 = 시각. hit-test는 호출부의 `contains(location)` 패턴.
final class GlassPillNode: SKNode {

    // MARK: - Properties
    /// 블러 효과 컨테이너 — background를 자식으로 감싸 가우시안 블러를 적용한다.
    private let blurEffect: SKEffectNode
    /// 반투명 알약 배경. fillColor = white α=0.55, strokeColor = white α=0.25.
    private let background: SKShapeNode
    /// 라벨. fontName = Jua-Regular(없으면 시스템 fallback), fontColor = navyDeep.
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// - Parameters:
    ///   - text: 라벨 텍스트.
    ///   - size: 알약 크기. cornerRadius = size.height/2 자동 (border-radius:999 동일).
    init(text: String, size: CGSize) {
        background = SKShapeNode(
            rectOf: size,
            cornerRadius: size.height / 2
        )
        background.fillColor = UIColor.white.withAlphaComponent(GameConfig.glassPillFillAlpha)
        background.strokeColor = UIColor.white.withAlphaComponent(GameConfig.glassPillStrokeAlpha)
        background.lineWidth = GameConfig.uiPanelLineWidth

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

        // 계층: self → blurEffect → background (블러 적용 대상)
        //        self → textLabel (블러 비적용, 또렷한 라벨)
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
}
