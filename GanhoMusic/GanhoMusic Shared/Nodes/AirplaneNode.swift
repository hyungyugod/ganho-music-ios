//
//  AirplaneNode.swift
//  GanhoMusic Shared
//
//  Phase 4-3 · AIRFORCE 이스터에그 비행기 — 좌→우 가로지르기 + 자가 소멸
//

import SpriteKit

/// AIRFORCE 이스터에그 비행기. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·크기·zPosition만 부여하고, scene.size 의존인 SKAction은
/// 외부 호출자가 crossScreen(sceneWidth:atY:)을 부르는 시점에 시작한다.
/// SKAction.sequence([move, removeFromParent])로 자가 소멸(fire-and-forget).
final class AirplaneNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.airplaneWidth,
            height: GameConfig.airplaneHeight
        )
        // 색: F 투사체와 동일 .ganhoYellowF — 주의 환기. 새 ColorTokens 신설 금지.
        super.init(texture: nil, color: .ganhoYellowF, size: size)
        name = "airplane"
        // HUD(100) 아래, 일반 노드(5) 위. 점수 라벨을 가리지 않으며 공중에 떠 있는 느낌.
        zPosition = 50
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cross
    /// 부모(cameraNode)에 addChild 직후 호출. 화면 좌측 바깥에서 시작 → 우측 바깥까지 이동 → 자가 제거.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 시작/끝 모두 화면 바깥(노드 폭만큼 여유).
    /// - Parameters:
    ///   - sceneWidth: 씬 가로 크기(scene.size.width). 좌우 바깥 좌표 계산용.
    ///   - y: cameraNode 좌표계 y (화면 중앙 기준). 화면 상단 가까이 = 양수.
    func crossScreen(sceneWidth: CGFloat, atY y: CGFloat) {
        let startX = -(sceneWidth / 2 + size.width)
        let endX   = +(sceneWidth / 2 + size.width)
        position = CGPoint(x: startX, y: y)
        let move    = SKAction.move(to: CGPoint(x: endX, y: y),
                                    duration: GameConfig.airplaneCrossDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([move, cleanup]))
    }
}
