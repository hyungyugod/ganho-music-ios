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
/// R1 — Poolable 채택. ProfessorNode가 풀 경유 provider로 실체화, 피격/벽 정리는 지연 회수로 풀 복귀.
final class StethoscopeNode: SKSpriteNode, Poolable {

    private let haloNode: SKShapeNode
    private let highlightNode: SKShapeNode
    private var isNearMissPulsing = false

    // MARK: - Recycle (R1)
    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러 — unregister + pool.recycle 수행.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자기 파괴와 동일 동작).
    var recycleHandler: ((StethoscopeNode) -> Void)?

    // MARK: - Init
    init() {
        // Sprint 10 Phase E — 원본 game.js drawStethoscope (L2922~L2960) 14×8 픽셀 텍스처.
        // size 18×18 → 28×16 (원본 14×8 × SCALE 2). 가로 넓고 세로 좁은 청진기 원본 비율.
        // R1 — 텍스처는 TextureAtlasStore 캐시 경유 (렌더 결과 byte-equal).
        let size = CGSize(width: GameplayTuning.stethoscopeWidth, height: GameplayTuning.stethoscopeHeight)
        let texture = TextureAtlasStore.stethoscopeTexture()
        haloNode = SKShapeNode(circleOfRadius: UILayout.stethoscopeReadableHaloRadius)
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

        startSpinning()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Spin (R1 — init·resetForReuse 공용 추출)
    /// 시각 회전 — 위협 시그널 강조. allowsRotation=false라 충돌 박스는 정지 상태 유지.
    /// repeatForever — 회수 시 resetForReuse의 removeAllActions로 종료 후 재부착.
    private func startSpinning() {
        run(.repeatForever(.rotate(byAngle: .pi * 2,
                                   duration: GameplayTuning.stethoscopeRotationDuration)))
    }

    // MARK: - Poolable (R1)
    /// 회수 단일 진입점 — 피격/벽 정리 등 모든 회수 요청이 이 메서드로 수렴.
    func requestRecycle() {
        if let handler = recycleHandler {
            handler(self)
        } else {
            removeFromParent()
        }
    }

    /// 재사용 직전 신품 복원: 잔존 액션 제거 → near-miss 펄스 정리(자식 halo/highlight) →
    /// 시각/물리 원복 → 회전 repeatForever 재부착(removeAllActions가 지우므로 필수).
    /// zRotation도 0 복원 — 회전 도중 회수된 각도가 다음 사용자에게 남지 않게.
    func resetForReuse() {
        removeAllActions()
        stopNearMissPulse()
        alpha = 1
        setScale(1)
        zRotation = 0
        position = .zero
        physicsBody?.velocity = .zero
        startSpinning()
    }

    // MARK: - Readability
    private func addReadableWarning() {
        haloNode.strokeColor = UIColor.ganhoIngameDanger
            .withAlphaComponent(UILayout.stethoscopeReadableHaloAlpha)
        haloNode.lineWidth = UILayout.ingameObjectHaloLineWidth
        haloNode.fillColor = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(UILayout.ingameObjectHaloAlpha * UILayout.ingameHalfAlphaMultiplier)
        haloNode.zPosition = -1
        addChild(haloNode)

        highlightNode.strokeColor = .ganhoPixelHudYellow
        highlightNode.lineWidth = UILayout.ingameObjectHaloLineWidth
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
        let haloGrow = SKAction.scale(to: GameplayTuning.stethoscopeNearMissPulseScale,
                                      duration: GameplayTuning.stethoscopeNearMissPulseHalfDuration)
        let haloShrink = SKAction.scale(to: 1.0,
                                        duration: GameplayTuning.stethoscopeNearMissPulseHalfDuration)
        let highlightGrow = SKAction.scale(to: GameplayTuning.stethoscopeNearMissPulseScale,
                                           duration: GameplayTuning.stethoscopeNearMissPulseHalfDuration)
        let highlightShrink = SKAction.scale(to: 1.0,
                                             duration: GameplayTuning.stethoscopeNearMissPulseHalfDuration)
        haloNode.run(.repeatForever(.sequence([haloGrow, haloShrink])),
                     withKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
        highlightNode.run(.repeatForever(.sequence([highlightGrow, highlightShrink])),
                          withKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        haloNode.removeAction(forKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
        highlightNode.removeAction(forKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
        haloNode.setScale(1.0)
        highlightNode.setScale(1.0)
    }
}
