//
//  ContactRouter.swift
//  GanhoMusic Shared
//
//  Phase 2-11 · 충돌 처리 분기를 GameScene에서 분리
//

import SpriteKit

/// SpriteKit 물리 충돌 알림(SKPhysicsContactDelegate)을 받아 카테고리별로 분기.
/// 효과는 콜백으로 위임 — GameScene 직접 모름. 결합도 ↓.
/// NSObject 상속 필수 (SKPhysicsContactDelegate가 Obj-C 프로토콜).
final class ContactRouter: NSObject, SKPhysicsContactDelegate {

    // MARK: - Callbacks
    /// player ↔ enemy 접촉 시.
    var onEnemyHit: () -> Void = {}
    /// player ↔ stoneGuard 접촉 시. Phase 4-2 — stub. 본체는 4-3에서.
    var onStoneGuardContact: () -> Void = {}
    /// player ↔ projectile 접촉 시. Phase 9-5 — projectile 노드 인자 추가
    /// (enchanted 상태 분기 필수). 콜백 본문에서 `node as? ProjectileNode` 캐스팅 후
    /// `isEnchanted` 가드 → 점수 가산 + 노드 제거 / 일반 F는 endGame 흐름.
    var onProjectileHitPlayer: (SKNode) -> Void = { _ in }
    /// projectile ↔ wall 접촉 시. 인자: 제거할 projectile 노드.
    var onProjectileHitWall: (SKNode) -> Void = { _ in }
    /// player ↔ note 접촉 시. 인자: 제거할 note 노드.
    var onNoteCollected: (SKNode) -> Void = { _ in }
    /// Phase 9-6 — player ↔ toilet(bonus) 접촉 시. 인자: 제거할 toilet 노드.
    /// 호출부는 콜백 본문 마지막에 `toilet.run(.removeFromParent())` SKAction 사용 — didBegin 진행 중
    /// 즉시 removeFromParent 호출은 물리 엔진과 충돌 시 크래시 가능(SpriteKit 공식 권고).
    var onToiletCollected: (SKNode) -> Void = { _ in }

    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories & PhysicsCategory.enemy != 0 {
            onEnemyHit()
            return
        }
        if categories & PhysicsCategory.stoneGuard != 0 {
            onStoneGuardContact()
            return
        }
        if categories & PhysicsCategory.projectile != 0 {
            handleProjectileContact(contact)
            return
        }
        // Phase 9-6 — bonus(변기) 분기. note 분기보다 *앞에* 둠 — bonus 비트는 단독으로 떠
        // note와 동시에 매치되지 않으나, 분기 순서 결정성 유지(주의사항).
        if categories & PhysicsCategory.bonus != 0 {
            handleBonusContact(contact)
            return
        }
        if categories & PhysicsCategory.note != 0 {
            handleNoteContact(contact)
        }
    }

    // MARK: - Private
    private func handleProjectileContact(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        // Phase 9-5 — projectile 본체 식별을 두 분기(player/wall) *모두* 공통화.
        // bodyA/bodyB 중 projectile 카테고리인 쪽을 골라 node 전달.
        let projectileBody = contact.bodyA.categoryBitMask == PhysicsCategory.projectile
            ? contact.bodyA
            : contact.bodyB
        if categories & PhysicsCategory.player != 0 {
            guard let node = projectileBody.node else { return }
            onProjectileHitPlayer(node)
            return
        }
        if categories & PhysicsCategory.wall != 0 {
            guard let node = projectileBody.node else { return }
            onProjectileHitWall(node)
        }
    }

    private func handleNoteContact(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let noteBody: SKPhysicsBody?
        if bodyA.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyA
        } else if bodyB.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyB
        } else {
            noteBody = nil
        }
        guard let node = noteBody?.node else { return }
        onNoteCollected(node)
    }

    /// Phase 9-6 — bonus 카테고리(변기) 충돌 분기.
    /// bodyA/bodyB 중 bonus 카테고리인 쪽을 골라 노드 전달.
    /// handleProjectileContact의 projectileBody 식별 패턴과 동형.
    private func handleBonusContact(_ contact: SKPhysicsContact) {
        let bonusBody = contact.bodyA.categoryBitMask == PhysicsCategory.bonus
            ? contact.bodyA
            : contact.bodyB
        guard let node = bonusBody.node else { return }
        onToiletCollected(node)
    }
}
