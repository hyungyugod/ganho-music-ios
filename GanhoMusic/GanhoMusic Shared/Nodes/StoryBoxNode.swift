//
//  StoryBoxNode.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 스토리 박스 — SKShapeNode 패널 + SKLabelNode 본문(자동 줄바꿈)
//
//  CutsceneOverlayNode의 본문 라벨 패턴(numberOfLines=0 + preferredMaxLayoutWidth)을
//  카드 형태로 추출한 *재사용 가능한 박스*. StartScene의 게임 소개 / SkillExplanationScene의
//  스킬 설명 본문 두 곳에서 동일 톤으로 사용.
//
//  PhysicsBody 0 — 순수 시각. parent의 좌표계 (0,0) 기준 중앙 배치.
//

import SpriteKit

/// 반투명 카드 패널 + 자동 줄바꿈 본문 라벨 컨테이너.
/// 외부에서는 init(body:) 1개로만 생성. 폭/높이는 GameConfig 상수 고정.
/// 본문 라벨이 박스 안에 자연 줄바꿈되도록 preferredMaxLayoutWidth = 박스폭 - 좌우 패딩.
final class StoryBoxNode: SKNode {

    // MARK: - Properties
    /// 카드 패널 — 반투명 ganhoUIBgCard + 흰색 7% 보더. CharacterCardNode와 동형 톤.
    private let panel: SKShapeNode
    /// 본문 라벨 — 자동 줄바꿈. fontColor는 ganhoUIText(밝은 본문 톤).
    private let bodyLabel: SKLabelNode

    // MARK: - Init
    /// 본문 텍스트를 받아 박스 + 라벨 부착.
    /// numberOfLines = 0 + preferredMaxLayoutWidth = 패널폭 - 패딩 × 2 → iOS 11+ 자동 줄바꿈.
    init(body: String) {
        let boxSize = CGSize(
            width: GameConfig.storyBoxWidth,
            height: GameConfig.storyBoxHeight
        )
        panel = SKShapeNode(rectOf: boxSize, cornerRadius: GameConfig.uiRadiusSm)
        panel.fillColor = .ganhoUIBgCard
        panel.strokeColor = .ganhoUIBorder
        panel.lineWidth = GameConfig.uiPanelLineWidth
        bodyLabel = SKLabelNode(text: body)
        super.init()
        name = "storyBox"
        // panel을 부모 좌표계 (0,0)에 정렬 — addChild 부모 측에서 position만 설정하면 됨.
        panel.position = .zero
        addChild(panel)
        configureBodyLabel()
        addChild(bodyLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    /// 본문 라벨 스타일 — 박스 정중앙 (0,0), 자동 줄바꿈.
    /// CutsceneOverlayNode.configureBodyLabel과 동형 패턴 — numberOfLines=0 + preferredMaxLayoutWidth 둘 다 설정.
    /// 폭 = storyBoxWidth - horizontalPadding × 2 → 양 가장자리 패딩 확보.
    private func configureBodyLabel() {
        bodyLabel.fontSize = GameConfig.storyBoxFontSize
        bodyLabel.fontColor = .ganhoUIText
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.position = .zero
        // iOS 11+ 자동 줄바꿈. numberOfLines = 0 → 줄 수 제한 없음.
        // preferredMaxLayoutWidth 없으면 줄바꿈 미발화(SpriteKit 사양).
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth =
            GameConfig.storyBoxWidth - GameConfig.storyBoxHorizontalPadding * 2
    }
}
