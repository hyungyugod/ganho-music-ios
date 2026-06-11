//
//  StethoscopeNode.swift
//  GanhoMusic Shared
//
//  Phase 9-7 · 청진기 투사체 — 이교수(ProfessorNode)가 발사.
//  FProjectileNode(F)와 분리된 별도 PhysicsCategory.stethoscope 사용.
//  명중 시 즉시 게임오버가 아닌 *2초 정지* — F와 정체성 분리.
//  R2 · 가독성 자식 2종(halo/highlight) 삭제 → 베이크 텍스처 1노드화 (자식 0 — 노드 게이트).
//    near-miss 펄스는 normal↔pulse 베이크 변형 텍스처 교차 (기존 펄스 주기 상수 재사용).
//

import SpriteKit

/// 청진기 투사체. ProfessorNode가 throwStethoscope()에서 생성·발사.
/// 발사 시점 player 위치 향한 단위 벡터 × stethoscopeSpeed velocity.
/// 벽/player와 contact 알림. collision=0(통과). PhysicsCategory.stethoscope 비트 단독 사용 —
/// ContactRouter가 별도 분기(handleStethoscopeContact)로 콜백 발화.
///
/// 시각: SKAction.rotate로 회전(allowsRotation=false라 충돌 박스는 그대로) — *도구가 빙글빙글 날아오는* 톤.
/// 베이크(halo+본체+highlight)가 통째로 회전 — 구 자식 회전 동반과 동일, halo는 원이라 회전 불변.
///
/// Spring 비유: FProjectileNode가 일반 비즈니스 이벤트라면, StethoscopeNode는 *특수 캠페인 이벤트* —
/// 같은 도메인(투사체)이지만 핸들러 경로(ContactRouter 분기)가 다르고 후속 비즈니스 로직(freeze)도 별개.
/// R1 — Poolable 채택. ProfessorNode가 풀 경유 provider로 실체화, 피격/벽 정리는 지연 회수로 풀 복귀.
final class StethoscopeNode: SKSpriteNode, Poolable {

    private var isNearMissPulsing = false

    // MARK: - Near-miss Bonus Tracking (R7 §F2)
    /// R7/R8 — 히트박스 가장자리 10px 셸 진입 여부. GameScene+NearMiss 폴링이 단독 기록자 (F와 동형).
    var nearMissEntered: Bool = false
    /// R7 — 보상 부여 완료 (투사체 1개당 1회 상한).
    var nearMissAwarded: Bool = false

    // MARK: - Recycle (R1)
    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러 — unregister + pool.recycle 수행.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자기 파괴와 동일 동작).
    var recycleHandler: ((StethoscopeNode) -> Void)?

    // MARK: - Init
    init() {
        // R2 — physicsBody는 원본 28×16(stethoscopeWidth/Height) byte-equal 유지.
        //      시각만 베이크 정사각(halo 바깥끝 포함) — 회전 시각과 정합.
        let physicsSize = CGSize(width: GameplayTuning.stethoscopeWidth,
                                 height: GameplayTuning.stethoscopeHeight)
        let bakedSide = TextureAtlasStore.stethoscopeBakedSideLength
        let visualSize = CGSize(width: bakedSide, height: bakedSide)
        let texture = TextureAtlasStore.stethoscopeBakedTexture(pulsing: false)
        super.init(texture: texture, color: .clear, size: visualSize)
        name = "stethoscope"
        // Player/Enemy/StoneGuard/Professor(5)와 동급 zPosition — UI(100) 아래.
        zPosition = 5

        let body = SKPhysicsBody(rectangleOf: physicsSize)
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

    /// 재사용 직전 신품 복원: 잔존 액션 제거 → near-miss 펄스 정리(normal 베이크 복원) →
    /// 시각/물리 원복 → 회전 repeatForever 재부착(removeAllActions가 지우므로 필수).
    /// zRotation도 0 복원 — 회전 도중 회수된 각도가 다음 사용자에게 남지 않게.
    /// R7 §F2 — near-miss 추적 플래그 2종도 반드시 리셋 (FProjectileNode와 동일 게이트).
    func resetForReuse() {
        removeAllActions()
        stopNearMissPulse()
        nearMissEntered = false
        nearMissAwarded = false
        alpha = 1
        setScale(1)
        zRotation = 0
        position = .zero
        physicsBody?.velocity = .zero
        startSpinning()
    }

    // MARK: - Near-miss Pulse (R2 — 자식 0, 베이크 변형 텍스처 교차)
    func updateNearMissWarning(distanceToPlayer distance: CGFloat, profile: DangerWarningProfile) {
        guard distance <= profile.projectileNearMissRadius else {
            stopNearMissPulse()
            return
        }
        startNearMissPulseIfNeeded()
    }

    /// normal↔pulse 베이크 교차 — 구 자식 scale 펄스(halo/highlight ×1.18, 0.09s 반주기)의 텍스처판.
    private func startNearMissPulseIfNeeded() {
        guard !isNearMissPulsing else { return }
        isNearMissPulsing = true
        let half = GameplayTuning.stethoscopeNearMissPulseHalfDuration
        let toPulse = SKAction.setTexture(
            TextureAtlasStore.stethoscopeBakedTexture(pulsing: true), resize: false)
        let toNormal = SKAction.setTexture(
            TextureAtlasStore.stethoscopeBakedTexture(pulsing: false), resize: false)
        let cycle = SKAction.sequence([
            toPulse, .wait(forDuration: half),
            toNormal, .wait(forDuration: half)
        ])
        run(.repeatForever(cycle), withKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
    }

    private func stopNearMissPulse() {
        guard isNearMissPulsing else { return }
        isNearMissPulsing = false
        removeAction(forKey: GameplayTuning.stethoscopeNearMissPulseActionKey)
        texture = TextureAtlasStore.stethoscopeBakedTexture(pulsing: false)
    }
}
