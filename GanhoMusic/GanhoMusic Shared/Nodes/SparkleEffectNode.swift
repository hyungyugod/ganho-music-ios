//
//  SparkleEffectNode.swift
//  GanhoMusic Shared
//
//  Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 + 자가 소멸 (시각 폴리싱)
//

import SpriteKit

/// 음표 수집 시 노트 위치에서 8방향으로 방사되는 sparkle 파편 컨테이너.
/// PhysicsBody 부착 0 — 순수 시각. SKAction.group(이동 + 페이드 + 스케일)을
/// 8개 자식 SKShapeNode에 *동시* 실행 → 0.5초 후 컨테이너 자가 제거.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode 패턴 답습 — 자가 소멸 노드 4회차.
/// Spring 비유: @TransactionalEventListener 다중 listener — 한 이벤트(노트 수집)에
/// 햅틱(6-1) + 사운드(6-2) + sparkle(6-8) 3채널 멀티모달 반응.
final class SparkleEffectNode: SKNode, SelfDismissingNode {

    // MARK: - Init
    override init() {
        super.init()
        name = "sparkle"
        zPosition = GameConfig.sparkleZPosition
        buildParticles()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Particles
    /// 8개의 SKShapeNode 원형 파편을 자식으로 부착. 모두 (0,0)에서 출발.
    /// 색은 SKColor.white — 어두운 BG(#1A1B2E) 위 별빛 톤. 새 ColorTokens 추가 0.
    /// init 시점에만 호출 — update 안 addChild 패턴 위반 0.
    private func buildParticles() {
        for _ in 0..<GameConfig.sparkleParticleCount {
            let particle = SKShapeNode(circleOfRadius: GameConfig.sparkleParticleRadius)
            particle.fillColor = .white            // 흰빛 별빛 — 어두운 BG에 또렷
            particle.strokeColor = .clear          // 외곽선 없음 — 순수 별빛
            particle.position = .zero
            addChild(particle)
        }
    }

    // MARK: - Emit
    /// 부모(worldNode)에 addChild 직후 호출. 각 파편에 8방향 SKAction.group를 *동시*에 run.
    /// group 액션은 [move, fadeOut, scale]을 *동시* 진행 — Spring의 CompletableFuture.allOf와 유사.
    /// 마지막 .removeFromParent()는 컨테이너(self)가 자가 제거(fire-and-forget).
    /// self 미사용 — [weak self] 캡처 불필요.
    func emit() {
        let angleStep = (2 * CGFloat.pi) / CGFloat(GameConfig.sparkleParticleCount)
        for (index, child) in children.enumerated() {
            let angle = angleStep * CGFloat(index)
            let dx = cos(angle) * GameConfig.sparkleSpawnDistance
            let dy = sin(angle) * GameConfig.sparkleSpawnDistance
            let move  = SKAction.moveBy(x: dx, y: dy, duration: GameConfig.sparkleFadeDuration)
            let fade  = SKAction.fadeOut(withDuration: GameConfig.sparkleFadeDuration)
            let scale = SKAction.scale(to: GameConfig.sparkleEndScale,
                                       duration: GameConfig.sparkleFadeDuration)
            child.run(.group([move, fade, scale]))
        }
        // 컨테이너 자가 제거: group 길이만큼 대기 후 removeFromParent.
        // child 액션과 동일한 sparkleFadeDuration으로 묶어 정확한 타이밍 보장.
        let wait    = SKAction.wait(forDuration: GameConfig.sparkleFadeDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, cleanup]))
    }
}
