//
//  CharacterID.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 UI 골격 — 5명 enum (id/displayName/color)
//

import UIKit

/// 5 캐릭터 식별자. raw String — case 이름이 그대로 raw value("kim", "jung"...).
/// CaseIterable 채택으로 `.allCases` 자동 생성 — TitleScene이 5 카드 일괄 생성에 사용.
/// 본 sprint(5-1)는 *UI 골격*만 — 스킬·외형 적용은 5-2 이후.
enum CharacterID: String, CaseIterable {
    case kim, jung, geon, im, lee

    /// 카드 라벨에 표시되는 한국어 이름. GDD §4 기준.
    var displayName: String {
        switch self {
        case .kim:  return "김간호"
        case .jung: return "정간호"
        case .geon: return "건간호"
        case .im:   return "임간호"
        case .lee:  return "이간호"
        }
    }

    /// 카드 배경색. ColorTokens 기존 5색 재사용 — 새 토큰 신설 X.
    var color: UIColor {
        switch self {
        case .kim:  return .ganhoPaper
        case .jung: return .ganhoMint
        case .geon: return .ganhoPinkNote
        case .im:   return .ganhoYellowF
        case .lee:  return .ganhoBloodAccent
        }
    }
}
