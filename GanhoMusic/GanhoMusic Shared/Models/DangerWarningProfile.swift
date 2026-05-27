//
//  DangerWarningProfile.swift
//  GanhoMusic Shared
//
//  Difficulty-specific visual warning profile for projectile and enemy danger cues.
//

import CoreGraphics

struct DangerWarningProfile {
    let telegraphLineLength: CGFloat
    let telegraphLineAlpha: CGFloat
    let showAllBurstLines: Bool
    let enemyWarningStartDistance: CGFloat
    let enemyWarningCriticalDistance: CGFloat
    let projectileNearMissRadius: CGFloat
    let professorRingAlphaMultiplier: CGFloat
}
