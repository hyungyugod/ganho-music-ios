//
//  GameScene+DangerWarnings.swift
//  GanhoMusic Shared
//
//  Distance-based danger warning updates for the main game loop.
//

import CoreGraphics
import SpriteKit

extension GameScene {
    func updateDangerWarnings() {
        let profile = GameplayTuning.warningProfileByDifficulty[difficulty] ?? GameplayTuning.warningProfileFallback
        enemy.updateProximityWarning(
            distanceToPlayer: distance(from: enemy.position, to: player.position),
            profile: profile
        )
        if stoneGuard.parent != nil {
            stoneGuard.updateProximityWarning(
                distanceToPlayer: distance(from: stoneGuard.position, to: player.position),
                profile: profile
            )
        }
        if let professor = professor {
            professor.updateProximityWarning(
                distanceToPlayer: distance(from: professor.position, to: player.position),
                profile: profile
            )
        }

        // R1 — 구 enumerateChildNodes("projectile"/"stethoscope") 프레임당 2건(update 경로 게이트 대상)
        // → registry 배열 직접 순회. 대상·판정·갱신 시맨틱 동일, 트리 전체 순회 비용만 제거.
        var closestProjectileDistance: CGFloat?
        for projectile in registry.projectiles {
            let distanceToPlayer = distance(from: projectile.position, to: player.position)
            if !projectile.isEnchanted {
                closestProjectileDistance = closestDistance(current: closestProjectileDistance,
                                                            candidate: distanceToPlayer)
            }
            projectile.updateNearMissWarning(distanceToPlayer: distanceToPlayer, profile: profile)
        }
        for stethoscope in registry.stethoscopes {
            let distanceToPlayer = distance(from: stethoscope.position, to: player.position)
            closestProjectileDistance = closestDistance(current: closestProjectileDistance,
                                                        candidate: distanceToPlayer)
            stethoscope.updateNearMissWarning(distanceToPlayer: distanceToPlayer, profile: profile)
        }
        player.updateNearMissWarning(closestProjectileDistance: closestProjectileDistance, profile: profile)
    }

    private func closestDistance(current: CGFloat?, candidate: CGFloat) -> CGFloat {
        guard let current = current else { return candidate }
        return min(current, candidate)
    }

    private func distance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
