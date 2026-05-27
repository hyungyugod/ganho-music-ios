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
        let profile = GameConfig.warningProfileByDifficulty[difficulty] ?? GameConfig.warningProfileFallback
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

        var closestProjectileDistance: CGFloat?
        worldNode.enumerateChildNodes(withName: "projectile") { [weak self] node, _ in
            guard let self = self, let projectile = node as? FProjectileNode else { return }
            let distance = self.distance(from: projectile.position, to: self.player.position)
            if !projectile.isEnchanted {
                closestProjectileDistance = self.closestDistance(current: closestProjectileDistance, candidate: distance)
            }
            projectile.updateNearMissWarning(distanceToPlayer: distance, profile: profile)
        }
        worldNode.enumerateChildNodes(withName: "stethoscope") { [weak self] node, _ in
            guard let self = self, let stethoscope = node as? StethoscopeNode else { return }
            let distance = self.distance(from: stethoscope.position, to: self.player.position)
            closestProjectileDistance = self.closestDistance(current: closestProjectileDistance, candidate: distance)
            stethoscope.updateNearMissWarning(distanceToPlayer: distance, profile: profile)
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
