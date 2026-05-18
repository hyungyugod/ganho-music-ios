//
//  DifficultyCardNode.swift
//  GanhoMusic Shared
//
//  Phase 7-1 · 난이도 선택 카드 — 색 사각형 + 이름 라벨 + 부제 라벨 + 선택 알파/scale 토글
//

import SpriteKit

/// TitleScene 하단 난이도 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKSpriteNode(색 사각형) + SKLabelNode(이름) + SKLabelNode(부제) 3개 컨테이너.
/// CharacterCardNode(5-1)와 동형 패턴 — 부제 라벨 1개만 추가.
/// 본 sprint 정책: 코드 중복 허용. 공통 부모 추출(BaseCardNode)은 별도 sprint.
final class DifficultyCardNode: SKNode {

    // MARK: - Properties
    let id: Difficulty
    private let background: SKSpriteNode
    private let nameLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode

    // MARK: - Init
    init(id: Difficulty) {
        self.id = id
        background = SKSpriteNode(
            color: id.color,
            size: CGSize(
                width: GameConfig.difficultyCardWidth,
                height: GameConfig.difficultyCardHeight
            )
        )
        nameLabel = SKLabelNode(text: id.displayName)
        subtitleLabel = SKLabelNode(text: id.subtitle)
        super.init()
        name = "difficultyCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        addChild(background)
        configureLabels()
        addChild(nameLabel)
        addChild(subtitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Selection
    /// 선택 상태 시각 토글. CharacterCardNode와 동일 패턴 — alpha + scale 2채널.
    /// 같은 GameConfig 상수(deselectedAlpha/selectedScale/scaleDuration)를 재사용하여
    /// 두 카드 종류의 시각 일관성을 유지.
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
    /// 이름 라벨(상단) + 부제 라벨(하단) 스타일.
    /// 이름은 카드 중앙 살짝 위, 부제는 그 아래 -14pt — 한글 2~7자 라인.
    private func configureLabels() {
        nameLabel.fontSize = GameConfig.difficultyCardFontSize
        nameLabel.fontColor = .ganhoBgDeep
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: 8)

        subtitleLabel.fontSize = GameConfig.difficultyCardSubtitleFontSize
        subtitleLabel.fontColor = .ganhoBgDeep
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -14)
    }
}
