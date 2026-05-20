//
//  StoneGuardNode.swift
//  GanhoMusic Shared
//
//  Phase 4-1 · 석조무사 NPC — 4 waypoint 시계방향 패트롤 (SKAction)
//  GDD §7-6: 맵 4지점 사각 순환, 55 px/s, 본 sprint는 시각 등장만 (PhysicsBody 없음).
//  Phase 4-2 · PhysicsBody 부착 (collision=0 통과형, contactTest=.player)
//

import SpriteKit

/// 석조무사 NPC. 추적 AI(EnemyNode)와 달리 *정해진 길*만 걷는 두 번째 AI 패턴.
/// init 시점에 startPatrol()을 호출 — SKAction.repeatForever(.sequence([.move × 4]))으로
/// 4 waypoint를 시계방향으로 무한 순회한다. 본 sprint는 PhysicsBody 미부착(시각 등장만).
final class StoneGuardNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.stoneGuardWidth,
            height: GameConfig.stoneGuardHeight
        )
        // Sprint 7 Phase F — 색상: 따뜻한 종이톤(.ganhoPaper)에서 *돌상 무채색*(.ganhoStoneGuardLight)으로 교체.
        // super.init 시그니처 byte-identical(texture: nil, color: _, size: size) — 값만 변경.
        // 새 ColorTokens(ganhoStoneGuardLight #A0A0A8)는 Phase F에서 추가.
        super.init(texture: nil, color: .ganhoStoneGuardLight, size: size)
        name = "stoneGuard"
        // EnemyNode와 동일한 zPosition 5 — 다른 노드(벽/음표/기둥) 위에 그려짐.
        zPosition = 5

        // Phase 4-2 — PhysicsBody 부착. EnemyNode 패턴 답습하되 collision=0(통과형).
        // patrol은 SKAction.move 기반 → isDynamic=false (velocity 미사용).
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.stoneGuard
        body.collisionBitMask    = 0                            // 통과형 — 아무도 막지 않음
        body.contactTestBitMask  = PhysicsCategory.player       // player와 닿으면 알림
        physicsBody = body

        // Sprint 7 Phase F — 시각 보강 자식 노드 부착(갑옷 + 일자눈).
        // physicsBody.size 인자(GameConfig.stoneGuardWidth/Height) 변경 0 — hitbox byte-identical.
        setupVisualOverlay()

        // Sprint 8 Phase G — 본체 단색 시각 차단(physicsBody/패트롤은 보존, color로 투명).
        // texture는 nil이지만 color=.ganhoStoneGuardLight로 *돌상 무채색*이 보였음.
        // color=.clear로 본체를 투명하게 → 시각 자식(Phase 7-F 갑옷+일자눈)만 노출.
        // colorBlendFactor=1.0은 texture 합성 정책 명시 — texture nil이라 시각 영향은 color에만.
        self.color = .clear
        self.colorBlendFactor = 1.0

        startPatrol()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Patrol
    /// 4 waypoint 시계방향 무한 순환 SKAction을 self.run으로 실행.
    /// init 시점 호출 — setupStoneGuard()가 (200, 100)에 노드를 둔 직후 worldNode 트리에 들어가면
    /// 첫 .move(to: w[1])부터 자동으로 (760, 100)을 향해 시작된다.
    private func startPatrol() {
        let waypoints = GameConfig.stoneGuardWaypoints
        var moves: [SKAction] = []
        for i in 0..<waypoints.count {
            let from = waypoints[i]
            let to   = waypoints[(i + 1) % waypoints.count]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur  = TimeInterval(dist / GameConfig.stoneGuardSpeed)
            moves.append(.move(to: to, duration: dur))
        }
        let loop = SKAction.repeatForever(.sequence(moves))
        run(loop)
    }

    // MARK: - Visual Overlay (Sprint 7 Phase F)
    /// 석조무사 시각 단서 보강 — 사각 갑옷(dark fill) + 일자눈 2개.
    /// init에서 1회 호출. physicsBody/이동 0줄 영향 — 자식 SKShapeNode만 추가.
    /// 모든 좌표/크기는 부모 SKSpriteNode 중심(0,0) 기준.
    /// Sprint 9 Phase C — 시각 자식 부착 *직후* applyVisualScaleV9()로 일괄 1.4배 확대.
    ///                     physicsBody는 본체 size 기준이라 hitbox 회귀 0.
    private func setupVisualOverlay() {
        attachArmor()
        attachEyes()
        applyVisualScaleV9()
    }

    /// Sprint 9 Phase C — 시각 자식(armor + 일자눈 2개) 일괄 setScale.
    /// 자식 transform scale만 변경 — 본체 SKSpriteNode size·physicsBody·patrol 무영향.
    private func applyVisualScaleV9() {
        for child in children {
            child.setScale(GameConfig.stoneGuardVisualScaleV9)
        }
    }

    /// 사각 갑옷 — stoneGuardDark fill + stoneGuardOutline stroke 0.8. 본체 위에 겹친 *돌상 갑옷판*.
    /// 본체 크기보다 약간 작게(0.7배) → 외곽선이 본체를 살짝 보여줌. zPos 0.1.
    private func attachArmor() {
        let armorSize = CGSize(
            width:  GameConfig.stoneGuardWidth  * 0.7,
            height: GameConfig.stoneGuardHeight * 0.5
        )
        let armor = SKShapeNode(rectOf: armorSize, cornerRadius: 1.0)
        armor.fillColor = .ganhoStoneGuardDark
        armor.strokeColor = .ganhoStoneGuardOutline
        armor.lineWidth = 0.8
        armor.zPosition = 0.1
        addChild(armor)
    }

    /// 일자눈 2개 — navyDeep 색의 가로 직사각형 좌우 대칭. *무뚝뚝한 돌상* 표정.
    /// rectOf 2×0.8 → 가로로 긴 얇은 눈. zPos 0.2 → 갑옷(0.1) 위.
    private func attachEyes() {
        let eyeSize = CGSize(width: 2, height: 0.8)
        for sign in [-1, 1] {
            let eye = SKShapeNode(rectOf: eyeSize)
            eye.fillColor = .ganhoNavyDeep
            eye.strokeColor = .clear
            eye.position = CGPoint(
                x: CGFloat(sign) * GameConfig.stoneGuardEyeOffsetX,
                y: GameConfig.stoneGuardEyeOffsetY
            )
            eye.zPosition = 0.2
            addChild(eye)
        }
    }
}
