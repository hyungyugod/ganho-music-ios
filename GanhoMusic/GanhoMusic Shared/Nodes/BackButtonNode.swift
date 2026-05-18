//
//  BackButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 뒤로 가기 버튼 — 투명 캡슐 + 흰색 7% stroke + muted 텍스트
//
//  PrimaryButtonNode와 형태는 동일하지만 *시각 위계*가 한 단계 아래 —
//  fill transparent + ganhoUITextMuted 라벨로 *보조 액션*임을 전달.
//  CharacterSelectScene/SkillExplanationScene의 "← 난이도 다시" / "← 캐릭터 다시" 두 곳에서 사용.
//

import SpriteKit

/// 보조 액션 버튼(뒤로 가기 등). PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKShapeNode(투명 캡슐 배경) + SKLabelNode(텍스트) 2개 컨테이너.
/// PrimaryButtonNode와 동형 — fillColor / strokeColor / fontColor만 *낮은 위계*로 교체.
final class BackButtonNode: SKNode {

    // MARK: - Properties
    /// 투명 fill + 흰색 7% stroke 캡슐 배경. 시각 위계상 *보조* 액션임을 알린다.
    private let background: SKShapeNode
    /// 버튼 텍스트. fontColor = ganhoUITextMuted(회색) — *조용한* 안내 톤.
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// 버튼 텍스트만 받아 배경 + 라벨 부착.
    /// 크기는 PrimaryButtonNode보다 살짝 작음(backButton 상수) — 시각 위계 차별화.
    init(text: String) {
        let buttonSize = CGSize(
            width: GameConfig.backButtonWidth,
            height: GameConfig.backButtonHeight
        )
        background = SKShapeNode(
            rectOf: buttonSize,
            cornerRadius: buttonSize.height / 2
        )
        background.fillColor = .clear
        background.strokeColor = .ganhoUIBorder
        background.lineWidth = GameConfig.uiPanelLineWidth
        textLabel = SKLabelNode(text: text)
        super.init()
        name = "backButton"
        zPosition = 100
        background.position = .zero
        addChild(background)
        configureLabel()
        addChild(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// 텍스트 라벨 스타일 — 캡슐 정중앙. muted 톤으로 *보조 안내*임 강조.
    private func configureLabel() {
        textLabel.fontSize = GameConfig.backButtonFontSize
        textLabel.fontColor = .ganhoUITextMuted
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
    }
}
