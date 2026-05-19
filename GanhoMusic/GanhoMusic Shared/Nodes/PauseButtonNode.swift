//
//  PauseButtonNode.swift
//  GanhoMusic Shared
//
//  Sprint 3 · v2 Game Visual
//
//  우상단 일시정지 버튼 — navy 라운드 32×32 + 흰 || 두 줄.
//  Sprint 3는 *시각 placeholder*만 — `isUserInteractionEnabled = false`.
//  실제 일시정지 로직은 후속 Sprint(또는 별도 SPEC)에서 부여.
//

import SpriteKit

/// 인게임 우상단 일시정지 버튼.
/// cameraNode 자식으로 부착 → 화면 고정. 시각만, 터치 X.
final class PauseButtonNode: SKNode {

    // MARK: - Properties
    /// navy 라운드 배경. fillColor = navyDeep.withAlpha(pauseButtonBgAlpha).
    private let background: SKShapeNode
    /// 좌측 흰 세로 막대.
    private let bar1: SKSpriteNode
    /// 우측 흰 세로 막대.
    private let bar2: SKSpriteNode

    // MARK: - Init
    override init() {
        let size = CGSize(
            width: GameConfig.pauseButtonSize,
            height: GameConfig.pauseButtonSize
        )
        background = SKShapeNode(
            rectOf: size,
            cornerRadius: GameConfig.pauseButtonCornerRadius
        )
        let barSize = CGSize(
            width: GameConfig.pauseButtonBarWidth,
            height: GameConfig.pauseButtonBarHeight
        )
        bar1 = SKSpriteNode(color: .white, size: barSize)
        bar2 = SKSpriteNode(color: .white, size: barSize)
        super.init()
        name = "pauseButton"
        zPosition = 200

        // 배경 — navy 알약. strokeColor = clear.
        background.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.pauseButtonBgAlpha)
        background.strokeColor = .clear
        addChild(background)

        // 두 막대 — 중심 0 기준 좌/우 분리.
        let barOffset = (GameConfig.pauseButtonBarWidth + GameConfig.pauseButtonBarGap) / 2
        bar1.position = CGPoint(x: -barOffset, y: 0)
        bar2.position = CGPoint(x: +barOffset, y: 0)
        addChild(bar1)
        addChild(bar2)

        // Sprint 3: 시각 placeholder만. 터치 흡수 0 — 부모(cameraNode)로 자연 패스스루.
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
