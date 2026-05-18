//
//  PhysicsCategory.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//

import Foundation

/// SpriteKit 물리 충돌 카테고리 비트마스크.
/// 2의 거듭제곱으로만 정의 — OR로 조합 가능하게.
struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0b0001   // 1
    static let note:       UInt32 = 0b0010   // 2
    static let enemy:      UInt32 = 0b0100   // 4
    static let wall:       UInt32 = 0b1000   // 8
    static let projectile: UInt32 = 0b10000  // 16  ← Phase 2-7 신설
    static let stoneGuard: UInt32 = 0b100000 // 32  ← Phase 4-2 신설
    static let bonus:      UInt32 = 0b1000000 // 64 ← Phase 9-6 신설 (변기 보너스)
}
