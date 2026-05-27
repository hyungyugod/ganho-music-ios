//
//  StethoscopeNode.swift
//  GanhoMusic Shared
//
//  Phase 9-7 · 청진기 투사체 — 이교수(ProfessorNode)가 발사.
//  FProjectileNode(F)와 분리된 별도 PhysicsCategory.stethoscope 사용.
//  명중 시 즉시 게임오버가 아닌 *2초 정지* — F와 정체성 분리.
//

import SpriteKit

/// 청진기 투사체. ProfessorNode가 throwStethoscope()에서 생성·발사.
/// 발사 시점 player 위치 향한 단위 벡터 × stethoscopeSpeed velocity.
/// 벽/player와 contact 알림. collision=0(통과). PhysicsCategory.stethoscope 비트 단독 사용 —
/// ContactRouter가 별도 분기(handleStethoscopeContact)로 콜백 발화.
///
/// 시각: SKAction.rotate로 회전(allowsRotation=false라 충돌 박스는 그대로) — *도구가 빙글빙글 날아오는* 톤.
/// 색은 .ganhoPixelChiefShoes(검정)로 *어두운 위협* 시그널.
///
/// Spring 비유: FProjectileNode가 일반 비즈니스 이벤트라면, StethoscopeNode는 *특수 캠페인 이벤트* —
/// 같은 도메인(투사체)이지만 핸들러 경로(ContactRouter 분기)가 다르고 후속 비즈니스 로직(freeze)도 별개.
final class StethoscopeNode: SKSpriteNode {

    private let haloNode: SKShapeNode
    private let highlightNode: SKShapeNode
    private var isNearMissPulsing = false

    // MARK: - Init
    init() {
        // Sprint 10 Phase E — 원본 game.js drawStethoscope (L2922~L2960) 14×8 픽셀 텍스처.
        // size 18×18 → 28×16 (원본 14×8 × SCALE 2). 가로 넓고 세로 좁은 청진기 원본 비율.
        let size = CGSize(width: GameConfig.stethoscopeWidth, height: GameConfig.stethoscopeHeight)
        let texture = PixelSpriteRenderer.stethoscopeTexture()
        haloNode = SKShapeNode(circleOfRadius: GameConfig.stethoscopeReadableHaloRadius)
        highlightNode = SKShapeNode(rectOf: size)
        super.init(texture: texture, color: .clear, size: size)
        name = "stethoscope"
        // Player/Enemy/StoneGuard/Professor(5)와 동급 zPosition — UI(100) 아래.
        zPosition = 5
        addReadableWarning()

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = true
        body.allowsRotation      = false   // SKAction.rotate는 *시각만* — 충돌 박스는 회전 무관.
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.stethoscope
        body.collisionBitMask    = 0       // 통과(벽에 막혀 멈추는 버그 회피, FProjectileNode 패턴 답습)
        body.contactTestBitMask  = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body

        // 시각 회전 — 위협 시그널 강조. allowsRotation=false라 충돌 박스는 정지 상태 유지.
        // repeatForever — endGame 시 removeFromParent로 자연 종료.
        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: GameConfig.stethoscopeRotationDuration)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Readability
    private func addReadableWarning() {
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(GameConfig.stethoscopeReadableHaloAlpha)
        haloNode.lineWidth = GameConfig.ingameObjectHaloLineWidth
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(GameConfig.ingameObjectHaloAlpha * GameConfig.ingameHalfAlphaMultiplier)
        haloNode.zPosition = -1
        addChild(haloNode)

        highlightNode.strokeColor = .ganhoPixelHudYellow
        highlightNode.lineWidth = GameConfig.ingameObjectHaloLineWidth
        highlightNode.fillColor = .clear
        highlightNode.zPosition = 1
        addChild(highlightNode)
    }

    func updateNearMissWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        guard distance <= profile.projectileNearMissRadius else {
            stopNearMissPulse()
            return
        }
        startNearMissPulseIfNeeded()
    }

    private func startNearMissPulseIfNeeded() {
        guard !isNearMissPulsing else { return }
        isNearMissPulsing = true
        let haloGrow = SKAction.scale(to: GameConfig.stethoscopeNearMissPulseScale,
                                      duration: GameConfig.stethoscopeNearMissPulseHalfDuration)
        let haloShrink = SKAction.scale(to: 1.0,
                                        duration: GameConfig.stethoscopeNearMissPulseHalfDuration)
        let highlightGrow = SKAction.scale(to: GameConfig.stethoscopeNearMissPulseScale,
                                           duration: GameConfig.stethoscopeNearMissPulseHalfDuration)
        let highlightShrink = SKAction.scale(to: 1.0,
                                             duration: GameConfig.stethoscopeNearMissPulseHalfDuration)
        haloNode.run(.repeatForever(.sequence([haloGrow, haloShrink])),
                     withKey: GameConfig.stethoscopeNearMissPulseActionKey)
        highlightNode.run(.repeatForever(.sequence([highlightGrow, highlightShrink])),
                          withKey: GameConfig.stethoscopeNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        haloNode.removeAction(forKey: GameConfig.stethoscopeNearMissPulseActionKey)
        highlightNode.removeAction(forKey: GameConfig.stethoscopeNearMissPulseActionKey)
        haloNode.setScale(1.0)
        highlightNode.setScale(1.0)
    }
}
