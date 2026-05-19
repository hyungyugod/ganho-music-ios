//
//  BackButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 뒤로 가기 버튼 — 투명 캡슐 + 흰색 7% stroke + muted 텍스트
//  Sprint 1 · v2 Design System 리스타일 — 내부 시각만 GlassPill 톤(반투명 화이트 + navy 라벨 + Jua)으로 교체.
//
//  PrimaryButtonNode와 형태는 동일하지만 *시각 위계*가 한 단계 아래 —
//  white α=0.55 fill + α=0.25 stroke + ganhoNavyDeep 라벨로 *조용한 보조 액션*임을 전달.
//  CharacterSelectScene/SkillExplanationScene의 "← 난이도 다시" / "← 캐릭터 다시" 두 곳에서 사용.
//
//  주의: GlassPillNode 인스턴스를 *직접 사용하지 않는다*. init 시그니처 / name="backButton"이
//  호출부 가드라 컨테이너 교체 시 회귀 위험 — 내부 시각만 GlassPill 톤을 흉내내는 패턴.
//

import SpriteKit

/// 보조 액션 버튼(뒤로 가기 등). PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKShapeNode(GlassPill 톤 캡슐 배경) + SKLabelNode(텍스트) 2개 컨테이너.
/// PrimaryButtonNode와 동형 — fillColor / strokeColor / fontColor만 *낮은 위계*로 교체.
final class BackButtonNode: SKNode {

    // MARK: - Properties
    /// 반투명 흰색 fill + 흰색 25% stroke 캡슐 배경. GlassPill 톤 흉내 — *보조* 액션 위계.
    private let background: SKShapeNode
    /// 버튼 텍스트. fontColor = ganhoNavyDeep, fontName = Jua-Regular — *조용한* 안내 톤.
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
        background.fillColor = UIColor.white
            .withAlphaComponent(GameConfig.glassPillFillAlpha)
        background.strokeColor = UIColor.white
            .withAlphaComponent(GameConfig.glassPillStrokeAlpha)
        background.lineWidth = GameConfig.uiPanelLineWidth
        textLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        super.init()
        name = "backButton"
        zPosition = 100
        background.position = .zero
        addChild(background)
        configureLabel(text: text)
        addChild(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// 텍스트 라벨 스타일 — 캡슐 정중앙. navyDeep 톤으로 *보조 안내*임 강조.
    private func configureLabel(text: String) {
        textLabel.text = text
        textLabel.fontSize = GameConfig.backButtonFontSize
        textLabel.fontColor = .ganhoNavyDeep
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
    }
}
