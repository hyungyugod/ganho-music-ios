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
    /// player ↔ projectile 접촉 시.
    var onProjectileHitPlayer: () -> Void = {}
    /// projectile ↔ wall 접촉 시. 인자: 제거할 projectile 노드.
    var onProjectileHitWall: (SKNode) -> Void = { _ in }
    /// player ↔ note 접촉 시. 인자: 제거할 note 노드.
    var onNoteCollected: (SKNode) -> Void = { _ in }

    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories & PhysicsCategory.enemy != 0 {
            onEnemyHit()
            return
        }
        if categories & PhysicsCategory.projectile != 0 {
            handleProjectileContact(contact)
            return
        }
        if categories & PhysicsCategory.note != 0 {
            handleNoteContact(contact)
        }
    }

    // MARK: - Private
    private func handleProjectileContact(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if categories & PhysicsCategory.player != 0 {
            onProjectileHitPlayer()
            return
        }
        if categories & PhysicsCategory.wall != 0 {
            let projectileBody = contact.bodyA.categoryBitMask == PhysicsCategory.projectile
                ? contact.bodyA
                : contact.bodyB
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
}
