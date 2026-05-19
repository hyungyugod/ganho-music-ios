//
//  DifficultyCardNode.swift
//  GanhoMusic Shared
//
//  Phase 7-1 · 난이도 선택 카드 — 색 사각형 + 이름 라벨 + 부제 라벨 + 선택 알파/scale 토글
//  Phase 8-3 · 캡슐 형태 SKShapeNode로 전환 — 원본 .game-difficulty__btn border-radius:999 재현
//  Phase 10-2 · 선택 시 spring overshoot + 살구 링 글로우 추가 (시그니처 불변)
//

import SpriteKit

/// TitleScene 하단 난이도 선택 카드. PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKShapeNode(캡슐 배경) + SKLabelNode(이름) + SKLabelNode(부제) 3개 컨테이너.
/// Phase 10-2 — ringGlow SKShapeNode 자식 1개 추가(zPosition -1, fade 토글).
/// CharacterCardNode(5-1)와 동형 패턴 — 부제 라벨 1개만 추가.
/// 본 sprint 정책: 코드 중복 허용. 공통 부모 추출(BaseCardNode)은 별도 sprint.
/// Phase 8-3 — background를 SKSpriteNode → SKShapeNode 캡슐(cornerRadius = height/2)로 전환.
/// 원본 `.game-difficulty__btn`은 `border-radius: 999px` 캡슐 — fill clear + brand stroke 톤.
final class DifficultyCardNode: SKNode {

    // MARK: - Properties
    let id: Difficulty
    private let background: SKShapeNode   // Phase 8-3 — SKSpriteNode → SKShapeNode 캡슐
    private let nameLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    /// Phase 10-2 — 선택 시 띄우는 살구색 링 글로우. 평소 alpha 0, 선택 시 fade-in.
    /// 카드 배경보다 *살짝 큰* 캡슐로 외곽에서 빛나는 톤.
    private let ringGlow: SKShapeNode

    // MARK: - Init
    init(id: Difficulty) {
        self.id = id
        let cardSize = CGSize(
            width: GameConfig.difficultyCardWidth,
            height: GameConfig.difficultyCardHeight
        )
        // Phase 8-3 — 캡슐 cornerRadius = height/2 → border-radius:999 캡슐 동일 효과.
        background = SKShapeNode(
            rectOf: cardSize,
            cornerRadius: cardSize.height / 2
        )
        background.fillColor = .clear            // 기본 transparent
        background.strokeColor = .ganhoUIBorder  // 흰색 7% 보더
        background.lineWidth = GameConfig.uiPanelLineWidth
        nameLabel = SKLabelNode(text: id.displayName)
        subtitleLabel = SKLabelNode(text: id.subtitle)
        // Phase 10-2 — 링 글로우. 카드보다 padding만큼 큰 캡슐.
        let ringSize = CGSize(
            width: cardSize.width + GameConfig.difficultyCardRingGlowPadding,
            height: cardSize.height + GameConfig.difficultyCardRingGlowPadding
        )
        ringGlow = SKShapeNode(
            rectOf: ringSize,
            cornerRadius: ringSize.height / 2
        )
        ringGlow.fillColor = .clear
        ringGlow.strokeColor = .ganhoAccentCoral
        ringGlow.lineWidth = GameConfig.difficultyCardRingGlowLineWidth
        ringGlow.glowWidth = GameConfig.difficultyCardRingGlowWidth
        ringGlow.alpha = 0
        super.init()
        name = "difficultyCard_\(id.rawValue)"
        zPosition = 100
        background.position = .zero
        // 링 글로우는 *배경보다 뒤*에 배치 — 외곽에서 빛나는 톤.
        ringGlow.position = .zero
        ringGlow.zPosition = -1
        addChild(ringGlow)
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
    /// Phase 8-3 — 추가로 fillColor / strokeColor / nameLabel.fontColor를 동적 교체.
    /// Phase 10-2 — 선택 시 spring overshoot(1.12 → 1.08) + 링 글로우 fade-in 추가.
    /// 호출 시그니처 불변 — 호출부 변경 0.
    func setSelected(_ selected: Bool) {
        alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
        removeAction(forKey: "cardScale")
        if selected {
            // Phase 10-2 — spring: overshoot 1.12 → settle 1.08.
            let overshoot = SKAction.scale(
                to: GameConfig.difficultyCardSpringOvershootScale,
                duration: GameConfig.difficultyCardSpringPhase1Duration
            )
            overshoot.timingMode = .easeOut
            let settle = SKAction.scale(
                to: GameConfig.characterCardSelectedScale,
                duration: GameConfig.difficultyCardSpringPhase2Duration
            )
            settle.timingMode = .easeInEaseOut
            run(
                SKAction.sequence([overshoot, settle]),
                withKey: "cardScale"
            )
        } else {
            run(
                SKAction.scale(to: 1.0, duration: GameConfig.characterCardScaleDuration),
                withKey: "cardScale"
            )
        }
        // Phase 8-3 — 선택 시 난이도 색을 *옅은 fill*(α 0.2) + 진한 stroke로 — 원본 brand 톤.
        background.fillColor = selected ? id.color.withAlphaComponent(0.2) : .clear
        background.strokeColor = selected ? id.color : .ganhoUIBorder
        nameLabel.fontColor = selected ? .ganhoUIText : .ganhoUITextMuted

        // Phase 10-2 — 링 글로우 fade in/out. 액션 키로 중복 토글 안전.
        ringGlow.removeAction(forKey: "ringFade")
        let targetAlpha: CGFloat = selected ? 1.0 : 0.0
        let duration: TimeInterval = selected
            ? GameConfig.difficultyCardRingGlowFadeInDuration
            : GameConfig.difficultyCardRingGlowFadeOutDuration
        ringGlow.run(
            SKAction.fadeAlpha(to: targetAlpha, duration: duration),
            withKey: "ringFade"
        )
    }

    // MARK: - Configure
    /// 이름 라벨(상단) + 부제 라벨(하단) 스타일.
    /// 이름은 카드 중앙 살짝 위, 부제는 그 아래 -14pt — 한글 2~7자 라인.
    /// Phase 8-3 — 기본 색은 muted/dim(해제 상태). setSelected에서 nameLabel만 동적 교체.
    private func configureLabels() {
        nameLabel.fontSize = GameConfig.difficultyCardFontSize
        nameLabel.fontColor = .ganhoUITextMuted
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: 8)

        subtitleLabel.fontSize = GameConfig.difficultyCardSubtitleFontSize
        subtitleLabel.fontColor = .ganhoUITextDim
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -14)
    }
}
