//
//  PrimaryButtonNode.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 주요 액션 버튼 — 캡슐 모양 + 라벨, contains(_:) hit-test
//
//  CharacterCardNode / DifficultyCardNode 패턴 답습 — 부모 = 좌표·name, 자식 = 시각.
//  코럴 fill + brand stroke + ganhoPaper 텍스트로 *주요 액션*임을 시각 위계로 전달.
//  hit-test는 호출부의 touchesBegan에서 `contains(location)`으로 수행 — 카드 패턴 동일.
//

import SpriteKit

/// 주요 액션 버튼(시작·이 친구로 시작 등). PhysicsBody 0 — 순수 시각 + hit test 대상.
/// 자식 SKShapeNode(캡슐 배경) + SKLabelNode(텍스트) 2개 컨테이너.
/// 캡슐 모양: cornerRadius = height/2 → border-radius:999 동일 효과 (DifficultyCardNode 8-3 패턴).
final class PrimaryButtonNode: SKNode {

    // MARK: - Properties
    /// 코럴 fill 캡슐 배경. fillColor = ganhoUIBrand, stroke = ganhoUIBrandLight.
    private let background: SKShapeNode
    /// 버튼 텍스트. fontColor = ganhoPaper(밝은 흰빛) — 코럴 배경 위 가독성.
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// 버튼 텍스트만 받아 배경 + 라벨 부착.
    /// 크기는 GameConfig 상수(primaryButtonWidth/Height) 고정 — 호출부 변동 없음.
    init(text: String) {
        let buttonSize = CGSize(
            width: GameConfig.primaryButtonWidth,
            height: GameConfig.primaryButtonHeight
        )
        // 캡슐 cornerRadius = height/2 → border-radius:999 동일 효과.
        background = SKShapeNode(
            rectOf: buttonSize,
            cornerRadius: buttonSize.height / 2
        )
        background.fillColor = .ganhoUIBrand
        background.strokeColor = .ganhoUIBrandLight
        background.lineWidth = GameConfig.uiPanelLineWidth
        textLabel = SKLabelNode(text: text)
        super.init()
        name = "primaryButton"
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
    /// 텍스트 라벨 스타일 — 캡슐 정중앙. CharacterCardNode.configureLabel과 동형 패턴.
    private func configureLabel() {
        textLabel.fontSize = GameConfig.primaryButtonFontSize
        textLabel.fontColor = .ganhoPaper
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
    }
}
