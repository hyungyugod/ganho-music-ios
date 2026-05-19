//
//  GlowingTitleNode.swift
//  GanhoMusic Shared
//
//  Phase 10-2 · StartScene 모던 리스킨
//
//  제목 라벨 + 글로우 컨테이너. SKEffectNode(CIGaussianBlur 적용한 라벨 사본)을
//  본 라벨 *뒤*에 두어 외곽이 부드럽게 빛나는 효과.
//  shouldRasterize = true로 성능 가드 — 매 프레임 블러 재계산 0.
//  StartScene 외 ResultScene/CharacterSelectScene 등에서도 재사용 가능.
//

import SpriteKit
import UIKit

/// 제목 라벨 + 외곽 글로우 컨테이너. SKNode 서브클래스.
/// 자식 트리:
///   - SKEffectNode (글로우 레이어, zPosition -1, CIGaussianBlur 적용한 글로우 라벨)
///   - SKLabelNode (본 제목 라벨, 원본 톤)
/// `mainLabel`만 외부 접근 허용 — 호출부에서 text/position을 추가 조작할 때 사용.
final class GlowingTitleNode: SKNode {

    // MARK: - Properties
    /// 본 제목 라벨. 외부에서 색상/텍스트 변경이 필요할 경우 접근 — 본 sprint에서는 init 시점만 사용.
    let mainLabel: SKLabelNode
    /// 글로우 레이어. CIFilter 부재 시에도 자식으로 유지(빈 effect node) — 트리 형태 일관성.
    private let glowEffect: SKEffectNode

    // MARK: - Init
    /// - Parameters:
    ///   - text: 제목 텍스트.
    ///   - fontSize: 본 라벨 폰트 크기 (글로우 라벨도 같은 크기).
    ///   - glowColor: 글로우 외곽 색. SPEC상 `.ganhoAccentTeal` 권장.
    init(text: String, fontSize: CGFloat, glowColor: UIColor) {
        // 본 라벨 — 원본 톤(.ganhoPaper) 유지. StartScene의 기존 titleLabel 색 일치.
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        self.mainLabel = label

        // 글로우 라벨 — 본 라벨과 같은 텍스트지만 glowColor + blur 적용.
        let glowLabel = SKLabelNode(text: text)
        glowLabel.fontSize = fontSize
        glowLabel.fontColor = glowColor
        glowLabel.horizontalAlignmentMode = .center
        glowLabel.verticalAlignmentMode = .center

        // SKEffectNode — CIGaussianBlur 적용. CIFilter는 옵셔널 — 실패 시 일반 라벨로 graceful.
        let effect = SKEffectNode()
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(
                GameConfig.titleGlowBlurRadius,
                forKey: "inputRadius"
            )
            effect.filter = blurFilter
            effect.shouldEnableEffects = true
        } else {
            // CIGaussianBlur 부재 시 글로우 비활성화 — 본 라벨만 보임. 시각적 강제 fallback.
            effect.shouldEnableEffects = false
        }
        // 매 프레임 블러 재계산 방지. 텍스트 변경 시 cache 무효화 필요 (본 sprint에선 정적 텍스트).
        effect.shouldRasterize = true
        effect.zPosition = -1
        effect.addChild(glowLabel)
        self.glowEffect = effect

        super.init()
        name = "glowingTitle"
        addChild(effect)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
