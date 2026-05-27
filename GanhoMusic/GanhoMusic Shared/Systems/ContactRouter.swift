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
    /// (enchanted 상태 분기 필수). 콜백 본문에서 `node as? FProjectileNode` 캐스팅 후
    /// `isEnchanted` 가드 → 점수 가산 + 노드 제거 / 일반 F는 endGame 흐름.
    var onProjectileHitPlayer: (SKNode) -> Void = { _ in }
    /// projectile ↔ wall 접촉 시. 인자: 제거할 projectile 노드.
    var onProjectileHitWall: (SKNode) -> Void = { _ in }
    /// player ↔ note 접촉 시. 인자: 제거할 note 노드.
    var onNoteCollected: (SKNode) -> Void = { _ in }
    /// Phase 9-6 — player ↔ toilet(bonus) 접촉 시. 인자: 제거할 toilet 노드.
    /// 호출부는 `deferRemoveAfterContact(_:)`로 다음 액션 틱 제거 — didBegin 진행 중
    /// 즉시 removeFromParent 호출은 물리 엔진과 충돌 시 크래시 가능.
    var onToiletCollected: (SKNode) -> Void = { _ in }
    /// Phase 9-7 — stethoscope ↔ player 접촉 시. 인자: 제거할 stethoscope 노드.
    /// 호출부는 player.freeze 발화 후 `deferRemoveAfterContact(_:)` 사용 — didBegin 즉시 제거 금지.
    /// 무적(isInvulnerable) 가드는 호출부 책임 — ContactRouter는 분기만 담당.
    var onStethoscopeHitPlayer: (SKNode) -> Void = { _ in }
    /// Phase 9-7 — stethoscope ↔ wall 접촉 시. 인자: 제거할 stethoscope 노드.
    /// onProjectileHitWall 패턴 답습 — 단순 노드 제거만.
    var onStethoscopeHitWall: (SKNode) -> Void = { _ in }
    /// Sprint 10 Phase D — aItem(매혹 변환 A) ↔ player 접촉 시. 인자: 제거할 aItem 노드.
    /// 호출부는 ScoreSystem.recordCharmedNoteHit으로 ×2 가산 후 `deferRemoveAfterContact(_:)` 사용.
    /// didBegin 즉시 removeFromParent 금지(주의사항 1).
    var onAItemCollected: (SKNode) -> Void = { _ in }
    /// Sprint 10 Phase D — aItem ↔ wall 접촉 시. 인자: 제거할 aItem 노드.
    /// onProjectileHitWall 패턴 답습 — 단순 노드 제거만.
    var onAItemHitWall: (SKNode) -> Void = { _ in }

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
        // Phase 9-7 — stethoscope 분기. projectile 분기와 분리 — 별도 비트(128)라 동시 매치 없음.
        // projectile 다음에 둠 — 비트 값 오름차순(16 → 128) 자연 정렬.
        if categories & PhysicsCategory.stethoscope != 0 {
            handleStethoscopeContact(contact)
            return
        }
        // Sprint 10 Phase D — aItem 분기. 별도 비트(256) — projectile/stethoscope/bonus와 단독 매치.
        // 비트 오름차순(16 → 128 → 256) 자연 정렬 위치.
        if categories & PhysicsCategory.aItem != 0 {
            handleAItemContact(contact)
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

    /// Phase 9-7 — stethoscope 카테고리(청진기) 충돌 분기.
    /// handleProjectileContact 패턴 정확 답습 — stethoscope 본체 식별 후 player/wall 분기.
    /// player 우선 — 청진기가 player와 wall 동시 매치되는 경우는 stethoscope 비트가 *단독*이라
    /// 실제로 없지만 분기 순서 결정성 유지.
    private func handleStethoscopeContact(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let stethoscopeBody = contact.bodyA.categoryBitMask == PhysicsCategory.stethoscope
            ? contact.bodyA
            : contact.bodyB
        if categories & PhysicsCategory.player != 0 {
            guard let node = stethoscopeBody.node else { return }
            onStethoscopeHitPlayer(node)
            return
        }
        if categories & PhysicsCategory.wall != 0 {
            guard let node = stethoscopeBody.node else { return }
            onStethoscopeHitWall(node)
        }
    }

    /// Sprint 10 Phase D — aItem(매혹 변환 A) 카테고리 충돌 분기.
    /// handleProjectileContact / handleStethoscopeContact 패턴 정확 답습.
    /// player 우선 — wall과 동시 매치되는 경우는 비트가 단독(256)이라 실제로 없으나 분기 순서 결정성 유지.
    private func handleAItemContact(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let aBody = contact.bodyA.categoryBitMask == PhysicsCategory.aItem
            ? contact.bodyA
            : contact.bodyB
        if categories & PhysicsCategory.player != 0 {
            guard let node = aBody.node else { return }
            onAItemCollected(node)
            return
        }
        if categories & PhysicsCategory.wall != 0 {
            guard let node = aBody.node else { return }
            onAItemHitWall(node)
        }
    }
}
