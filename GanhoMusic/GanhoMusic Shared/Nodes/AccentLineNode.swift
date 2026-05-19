//
//  AccentLineNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  32×3 라운드 캡 코랄 라인. 모든 헤더 위 시각적 강조에 재사용.
//  DESIGN_RENEWAL_REQUEST.md §3.3.C.
//

import SpriteKit

/// 32×3 코랄 라운드 캡 라인. PhysicsBody 0 — 순수 시각.
final class AccentLineNode: SKShapeNode {

    // MARK: - Init
    /// 크기 고정(GameConfig.accentLineWidth × accentLineHeight) 코랄 라인.
    /// 호출자는 좌표만 잡으면 됨 — 색·두께·라운드 캡은 토큰에서 자동.
    override init() {
        super.init()
        let size = CGSize(
            width: GameConfig.accentLineWidth,
            height: GameConfig.accentLineHeight
        )
        // rect 중심을 (0,0)으로 — SKShapeNode 관례에 맞춤(부모가 좌표 결정).
        path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: size.height / 2,
            cornerHeight: size.height / 2,
            transform: nil
        )
        fillColor = .ganhoCoralPrimary
        strokeColor = .clear
        lineWidth = 0
        name = "accentLine"
        zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
