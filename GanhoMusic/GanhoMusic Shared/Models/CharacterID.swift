//
//  CharacterID.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 UI 골격 — 5명 enum (id/displayName/color)
//  Phase 5-3 · 캐릭터별 이동속도 차등 (speedMultiplier 주입)
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

    /// Phase 5-3 — 캐릭터별 이동속도 배율. `.kim` = 1.0을 기준으로 +/- 10% 이내 미세 차등.
    /// PlayerNode.update(deltaTime:)에서 GameConfig.playerBaseSpeed × multiplier로 velocity 산출.
    var playerSpeedMultiplier: CGFloat {
        switch self {
        case .kim:  return 1.00   // 기준
        case .jung: return 1.10   // 민첩
        case .lee:  return 1.05   // 살짝 빠름
        case .im:   return 0.95   // 살짝 느림
        case .geon: return 0.90   // 묵직
        }
    }

    /// Phase 9-5 — 캐릭터별 능동 스킬. `.kim`은 .none (스킬 없음 = 정공법 정체성).
    /// SkillSystem.configure(scene:skill:)에 전달되어 활성 스킬 확정.
    /// switch default 미사용 — 5 case exhaustive(미래 신규 케이스 추가 시 자연 컴파일 에러).
    var skill: PlayerSkill {
        switch self {
        case .kim:  return .none
        case .jung: return .dashClimb
        case .geon: return .bookClubRally
        case .im:   return .charmStudent
        case .lee:  return .taiwanTrip
        }
    }

    /// Phase 10-1b — 캐릭터 선택 화면 카드 아래 표시되는 짧은 태그(특징 1줄).
    /// displayName(이름)과 분리 — 같은 카드 위치에 *이름 위에 태그* 톤으로 풍부한 정보 전달.
    /// 카드 *외부* SKLabelNode로 표시되어 CharacterCardNode 내부 변경 0건.
    var tag: String {
        switch self {
        case .kim:  return "번머리 실습생"
        case .jung: return "곡괭이 근육"
        case .geon: return "안경과 책"
        case .im:   return "긴머리 냥"
        case .lee:  return "단발 댕댕"
        }
    }
}
