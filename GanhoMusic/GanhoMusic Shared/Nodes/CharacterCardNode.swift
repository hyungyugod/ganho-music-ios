//
//  CharacterCardNode.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 카드 — 색 사각형 + 이름 라벨 + 선택 알파 토글
//  Phase 5-5 · 카드 선택 시 scale 강조 (SKAction.scale 0.10s 보간)
//

import SpriteKit

/// TitleScene 하단 캐릭터 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKSpriteNode(색 사각형) + SKLabelNode(이름) 2개 컨테이너.
/// HUDNode / AirforceOverlayNode 패턴 답습 — 부모 = 좌표·zPosition·name, 자식 = 시각 속성.
final class CharacterCardNode: SKNode {

    // MARK: - Properties
    let id: CharacterID
    private let background: SKSpriteNode
    private let nameLabel: SKLabelNode

    // MARK: - Init
    init(id: CharacterID) {
        self.id = id
        background = SKSpriteNode(
            color: id.color,
            size: CGSize(
                width: GameConfig.characterCardWidth,
                height: GameConfig.characterCardHeight
            )
        )
        nameLabel = SKLabelNode(text: id.displayName)
        super.init()
        name = "characterCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        addChild(background)
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
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
        let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
        removeAction(forKey: "cardScale")
        run(
            SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
            withKey: "cardScale"
        )
    }

    // MARK: - Configure
    /// 이름 라벨 스타일 — 배경 사각형 위 정중앙.
    private func configureLabel() {
        nameLabel.fontSize = GameConfig.characterCardFontSize
        nameLabel.fontColor = .ganhoBgDeep
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = .zero
    }
}
