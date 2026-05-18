//
//  CharacterCardNode.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 카드 — 색 사각형 + 이름 라벨 + 선택 알파 토글
//  Phase 5-5 · 카드 선택 시 scale 강조 (SKAction.scale 0.10s 보간)
//  Phase 8-3 · 시각 토큰 원본화 — ganhoUIBgCard 배경 + border SKShapeNode + brand 강조
//

import SpriteKit

/// TitleScene 하단 캐릭터 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKSpriteNode(색 사각형) + SKShapeNode(보더) + SKLabelNode(이름) 3개 컨테이너.
/// HUDNode / AirforceOverlayNode 패턴 답습 — 부모 = 좌표·zPosition·name, 자식 = 시각 속성.
/// Phase 8-3 — background 기본색을 ganhoUIBgCard로, border SKShapeNode 자식 추가(SKSpriteNode는 stroke 미지원).
final class CharacterCardNode: SKNode {

    // MARK: - Properties
    let id: CharacterID
    private let background: SKSpriteNode
    private let border: SKShapeNode       // Phase 8-3 — 카드 외곽 보더(원본 1px stroke)
    private let nameLabel: SKLabelNode

    // MARK: - Init
    init(id: CharacterID) {
        self.id = id
        let cardSize = CGSize(
            width: GameConfig.characterCardWidth,
            height: GameConfig.characterCardHeight
        )
        // Phase 8-3 — 원본 .character-card 톤: 반투명 카드 배경(ganhoUIBgCard).
        background = SKSpriteNode(color: .ganhoUIBgCard, size: cardSize)
        // Phase 8-3 — SKSpriteNode는 stroke 미지원 → 자식 SKShapeNode로 보더만 표현(fill clear).
        border = SKShapeNode(rectOf: cardSize, cornerRadius: GameConfig.uiRadiusSm)
        border.fillColor = .clear
        border.strokeColor = .ganhoUIBorder
        border.lineWidth = GameConfig.uiPanelLineWidth
        nameLabel = SKLabelNode(text: id.displayName)
        super.init()
        name = "characterCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        border.position = .zero
        addChild(background)
        addChild(border)
        configureLabel()
        addChild(nameLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Selection
    /// 선택 상태 시각 토글. true → alpha 1.0(또렷) + scale 1.08(살짝 큼),
    /// false → alpha 0.5(흐림) + scale 1.0(기본).
    /// alpha + scale 2개로 표현 — Phase 5-5 — scale 토글 추가(SKAction 0.10s 보간).
    /// Phase 8-3 — 추가로 background.color / border.strokeColor / nameLabel.fontColor를 토큰으로 교체.
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
        let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
        removeAction(forKey: "cardScale")
        run(
            SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
            withKey: "cardScale"
        )
        // Phase 8-3 — 시각 토큰 교체:
        // 선택: 코럴 12% 배경 + 코럴 60% 보더 + brand-light 텍스트
        // 해제: 카드 기본 배경 + 흰색 7% 보더 + muted 텍스트
        background.color = selected ? .ganhoUIBrand12 : .ganhoUIBgCard
        border.strokeColor = selected ? .ganhoUIBrand60 : .ganhoUIBorder
        nameLabel.fontColor = selected ? .ganhoUIBrandLight : .ganhoUITextMuted
    }

    // MARK: - Configure
    /// 이름 라벨 스타일 — 배경 사각형 위 정중앙.
    /// Phase 8-3 — 기본 색은 muted(해제 상태). setSelected에서 동적 교체.
    private func configureLabel() {
        nameLabel.fontSize = GameConfig.uiCardNameFontSize
        nameLabel.fontColor = .ganhoUITextMuted
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = .zero
    }
}
