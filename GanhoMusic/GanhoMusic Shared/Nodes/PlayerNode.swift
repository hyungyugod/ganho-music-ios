//
//  PlayerNode.swift
//  GanhoMusic Shared
//
//  Phase 1-3 · 김간호 정식 캐릭터 노드
//  Phase 2-2 · SKPhysicsBody 첫 도입 + velocity 기반 이동 (1-4 자체 클램프 제거)
//

import SpriteKit

/// 김간호 캐릭터. 외부(GameScene)가 매 프레임 currentDirection을 갱신해주면,
/// update(deltaTime:)에서 PhysicsBody의 velocity로 이동 의도를 전달한다.
/// Phase 2-2 — SKPhysicsBody 부착 (1-1에서 정의된 PhysicsCategory가 드디어 활성화).
final class PlayerNode: SKSpriteNode {

    // MARK: - Properties
    /// 현재 이동 방향 (단위 벡터). 외부에서 set, 내부에서 read.
    /// .zero이면 정지.
    var currentDirection: CGVector = .zero

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.playerWidth,
            height: GameConfig.playerHeight
        )
        super.init(texture: nil, color: .ganhoMint, size: size)
        name = "player"

        // Phase 2-2 — PhysicsBody 부착 (dynamic, velocity 통제, 회전/마찰/탄성/감쇠 모두 0)
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.player
        body.collisionBitMask    = PhysicsCategory.wall
        body.contactTestBitMask  = PhysicsCategory.note   // Phase 2-3 활성화
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    /// 외부에서 매 프레임 호출. PhysicsBody의 velocity로 이동 의도 전달.
    /// (Phase 2-2 — 1-3/1-4의 position 직접 변경 + 자체 클램프 패턴은 폐기.
    ///  물리 엔진이 매 프레임 자동으로 위치 갱신 + 충돌 처리.)
    /// - Parameter deltaTime: dt — 본 메서드는 미사용 (velocity 기반이라 엔진이 dt 처리).
    ///   시그니처는 외부 호출부 호환 위해 보존.
    func update(deltaTime: TimeInterval) {
        let speed = GameConfig.playerBaseSpeed
        physicsBody?.velocity = CGVector(
            dx: currentDirection.dx * speed,
            dy: currentDirection.dy * speed
        )
    }
}
