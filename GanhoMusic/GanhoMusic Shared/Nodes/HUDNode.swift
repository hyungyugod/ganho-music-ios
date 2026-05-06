//
//  HUDNode.swift
//  GanhoMusic Shared
//
//  Phase 2-4 · 점수/시간 라벨 컨테이너 (cameraNode 자식 — 화면 고정)
//

import SpriteKit

/// 점수와 남은 시간 라벨 2개를 묶은 SKNode 컨테이너.
/// 시각 자체는 없고(SKNode), 자식 SKLabelNode 2개로만 구성.
/// GameScene이 cameraNode 좌표계 좌상단에 부착하여 화면 고정.
/// 1-3 DPadNode와 동일 패턴 — 외부엔 update(score:remainingTime:)만 노출.
final class HUDNode: SKNode {

    // MARK: - Properties
    private let scoreLabel: SKLabelNode
    private let timeLabel: SKLabelNode
    private let comboLabel: SKLabelNode

    // MARK: - Init
    override init() {
        scoreLabel = SKLabelNode(text: "🎵 0")
        timeLabel  = SKLabelNode(text: "⏱ 00:45")
        comboLabel = SKLabelNode(text: "🔥 0")
        super.init()
        configure(scoreLabel)
        configure(timeLabel)
        configure(comboLabel)
        // 자기 좌표계 (0,0) = HUD anchor (좌상단). 두 번째 줄은 글자 높이의 1.4배 아래로.
        scoreLabel.position = CGPoint(x: 0, y: 0)
        timeLabel.position  = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4)
        comboLabel.position = CGPoint(x: 0, y: -GameConfig.hudFontSize * 1.4 * 2)
        addChild(scoreLabel)
        addChild(timeLabel)
        addChild(comboLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. 점수 + 남은 시간을 라벨에 반영.
    /// remainingTime은 ceil로 올림 — 사용자가 시작 직후 "45"를 1초간 보도록.
    func update(score: Int, remainingTime: TimeInterval, combo: Int) {
        scoreLabel.text = "🎵 \(score)"
        let seconds = max(0, Int(ceil(remainingTime)))
        timeLabel.text = String(format: "⏱ 00:%02d", seconds)
        comboLabel.text = "🔥 \(combo)"
        comboLabel.alpha = combo >= 2 ? GameConfig.hudAlpha : 0
    }

    // MARK: - Configure
    /// 두 라벨 공통 스타일. 좌상단 anchor 고정 위해 정렬 모드 명시 필수.
    private func configure(_ label: SKLabelNode) {
        label.fontSize = GameConfig.hudFontSize
        label.fontColor = .ganhoPaper
        label.alpha = GameConfig.hudAlpha
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.zPosition = 100
    }
}
