//
//  ColorTokens.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//

import UIKit

/// 게임 컬러 토큰. assets.md §1 16색 팔레트 기반.
/// Asset Catalog Color Set이 추가되면 자동으로 그 값이 우선 적용됨.
extension UIColor {

    // MARK: - Background
    /// 배경 (어두운 야간 병동). HEX #1A1B2E
    static let ganhoBgDeep = UIColor(named: "bgDeep")
        ?? UIColor(red: 0x1A / 255, green: 0x1B / 255, blue: 0x2E / 255, alpha: 1)

    // MARK: - Text / Player
    /// 김간호 가운 / HUD 텍스트. HEX #F4F1DE
    static let ganhoPaper = UIColor(named: "paperWhite")
        ?? UIColor(red: 0xF4 / 255, green: 0xF1 / 255, blue: 0xDE / 255, alpha: 1)

    // MARK: - Brand
    /// 김간호 머리띠 / 음표 보조 (민트). HEX #7DCFB6
    static let ganhoMint = UIColor(named: "mintHair")
        ?? UIColor(red: 0x7D / 255, green: 0xCF / 255, blue: 0xB6 / 255, alpha: 1)

    /// 음표 본체 ♪ (분홍). HEX #F6A6B2
    static let ganhoPinkNote = UIColor(named: "pinkNote")
        ?? UIColor(red: 0xF6 / 255, green: 0xA6 / 255, blue: 0xB2 / 255, alpha: 1)

    // MARK: - Enemy
    /// 수간호사 가운. HEX #A4243B. assets.md §1.
    static let ganhoCrimsonNurse = UIColor(named: "crimsonNurse")
        ?? UIColor(red: 0xA4 / 255, green: 0x24 / 255, blue: 0x3B / 255, alpha: 1)

    /// 수간호사 강조 / 피격 플래시. HEX #D8315B. assets.md §1.
    /// Phase 2-6 hotfix 2 — enemy 본체 색으로 사용 (ganhoCrimsonNurse는 어두워 가시성 ↓).
    static let ganhoBloodAccent = UIColor(named: "bloodAccent")
        ?? UIColor(red: 0xD8 / 255, green: 0x31 / 255, blue: 0x5B / 255, alpha: 1)

    // MARK: - Projectile
    /// F 투사체. HEX #FFD23F. assets.md §1 yellowF.
    static let ganhoYellowF = UIColor(named: "yellowF")
        ?? UIColor(red: 0xFF / 255, green: 0xD2 / 255, blue: 0x3F / 255, alpha: 1)
}
