//
//  PixelCardNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 카드 베이스.
//  ink700 면 + 2px line500 보더 + 하드섀도 + contentNode 슬롯 (R4 캐릭터/난이도 카드 조립).
//  선택: 액센트 보더 + 글로우(액센트 alpha 0.30, 1.4배 사각 1장 — SKEffectNode 금지)
//  + scale 1.04 easeOutBack 0.18s. 해제: 글로우 removeFromParent (좀비 금지).
//

import SpriteKit
import UIKit

/// v3 카드. 선택 상태 시각 전환 내장 — 터치 판정은 호출측(씬) 책임.
final class PixelCardNode: SKNode {

    /// 자식 콘텐츠 부착 슬롯 (얼굴 픽셀·이름·칩 등 — R4 조립).
    let contentNode = SKNode()
    /// 카드 면 크기.
    let cardSize: CGSize

    private let accent: UIColor
    private let borderNode: SKShapeNode
    private var glowNode: SKSpriteNode?
    private(set) var isSelected = false

    /// 내부 적층 — 글로우(-1, 카드 뒤) < 섀도(0) < 면(1) < 보더(2) < 콘텐츠(3).
    private enum InnerZ {
        static let glow: CGFloat = -1
        static let shadow: CGFloat = 0
        static let face: CGFloat = 1
        static let border: CGFloat = 2
        static let content: CGFloat = 3
    }

    /// 선택 스케일 액션 키 — withKey 멱등 (연타 토글 시 자동 교체).
    private static let selectActionKey = "pixelCardSelect"

    // MARK: - Init
    /// - Parameters:
    ///   - size: 카드 면 크기.
    ///   - accent: 선택 시 보더·글로우 액센트색.
    init(size: CGSize, accent: UIColor) {
        cardSize = size
        self.accent = accent

        let rect = CGRect(x: (-size.width / 2).rounded(),
                          y: (-size.height / 2).rounded(),
                          width: size.width.rounded(),
                          height: size.height.rounded())
        borderNode = SKShapeNode(rect: rect)   // 직각 — 패널만 라운드 허용 (03_UI §4)
        borderNode.fillColor = .clear
        borderNode.strokeColor = Palette.line500
        borderNode.lineWidth = UILayout.v3BorderWidth
        super.init()

        let shadow = SKSpriteNode(color: Palette.ink900, size: size)
        shadow.position = CGPoint(x: UILayout.v3HardShadowOffset.dx,
                                  y: UILayout.v3HardShadowOffset.dy)
        shadow.zPosition = InnerZ.shadow
        addChild(shadow)

        let face = SKSpriteNode(color: Palette.ink700, size: size)
        face.zPosition = InnerZ.face
        addChild(face)

        borderNode.zPosition = InnerZ.border
        addChild(borderNode)

        contentNode.zPosition = InnerZ.content
        addChild(contentNode)
    }

    @available(*, unavailable, message: "Use init(size:accent:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Selection (03_UI §5 — easeOutBack 0.18s)
    func setSelected(_ selected: Bool, animated: Bool) {
        guard isSelected != selected else { return }
        isSelected = selected

        borderNode.strokeColor = selected ? accent : Palette.line500
        if selected {
            attachGlow()
        } else {
            // 좀비 금지 — alpha 숨김이 아니라 제거 (R3 합격 게이트).
            glowNode?.removeFromParent()
            glowNode = nil
        }

        let targetScale = selected ? UILayout.v3CardSelectedScale : 1.0
        removeAction(forKey: Self.selectActionKey)
        guard animated else {
            setScale(targetScale)
            return
        }
        let scale = SKAction.scale(to: targetScale, duration: FeelTuning.Motion.cardSelect)
        run(Tween.curved(scale, .easeOutBack), withKey: Self.selectActionKey)
    }

    /// 글로우 — 액센트색 alpha 0.30, 카드 1.4배 사각 1장, 카드 뒤 z (블러 0 — §11).
    private func attachGlow() {
        guard glowNode == nil else { return }
        let glow = SKSpriteNode(
            color: accent,
            size: CGSize(width: cardSize.width * Palette.glowScale,
                         height: cardSize.height * Palette.glowScale)
        )
        glow.alpha = Palette.glowAlpha
        glow.zPosition = InnerZ.glow
        addChild(glow)
        glowNode = glow
    }
}
