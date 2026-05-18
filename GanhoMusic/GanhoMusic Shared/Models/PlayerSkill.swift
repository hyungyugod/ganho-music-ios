//
//  PlayerSkill.swift
//  GanhoMusic Shared
//
//  Phase 9-5 · 캐릭터별 스킬 시스템 4종
//
//  5 case enum — kim(스킬 없음) + jung/geon/im/lee 각 1개씩.
//  메타데이터(displayName/cooldown/duration/oncePerGame)는 computed property로 캡슐화.
//  switch default 미사용 — 5 case exhaustive. 미래 신규 케이스 추가 시 컴파일 에러로 자연 검출.
//

import Foundation

/// 캐릭터가 보유한 능동 스킬. 김간호(.none)는 *결함이 아니라 의도된 정체성*(GDD §4).
/// `CharacterID.skill` computed property로 단일 진입점 분기.
enum PlayerSkill {
    case none           // 김간호 — 스킬 없음 (정공법 정체성)
    case dashClimb      // 정간호 — 암벽등반 돌진
    case bookClubRally  // 건간호 — 북클럽 소집
    case charmStudent   // 임간호 — 나는야 모범생 (게임당 1회)
    case taiwanTrip     // 이간호 — 대만여행 (텔레포트)
}

// MARK: - Metadata
extension PlayerSkill {

    /// 스킬 화면 표시 이름. HUDSkillSlotNode의 라벨 표시 등에 사용.
    /// .none은 "—" 1자(em dash) — 빈 슬롯의 시각적 정체성.
    var displayName: String {
        switch self {
        case .none:           return "—"
        case .dashClimb:      return "돌진"
        case .bookClubRally:  return "북클럽"
        case .charmStudent:   return "매혹"
        case .taiwanTrip:     return "대만"
        }
    }

    /// 스킬 쿨다운(초). 발동 직후부터 카운트 다운.
    /// .charmStudent는 oncePerGame이지만 시그니처 일관성 위해 `.infinity` 반환.
    /// .none은 0 — 발동 자체가 없으므로 의미는 없으나 division-by-zero 회피 위해 1 반환.
    var cooldown: TimeInterval {
        switch self {
        case .none:           return 1  // division-by-zero 회피 sentinel (실제 발동 없음)
        case .dashClimb:      return GameConfig.dashClimbCooldown
        case .bookClubRally:  return GameConfig.bookClubRallyCooldown
        case .charmStudent:   return .infinity  // 게임당 1회 — 진행률 영원 0
        case .taiwanTrip:     return GameConfig.taiwanTripCooldown
        }
    }

    /// 스킬 효과 지속 시간(초). 즉발 스킬은 0.
    var duration: TimeInterval {
        switch self {
        case .none:           return 0
        case .dashClimb:      return GameConfig.dashClimbDuration
        case .bookClubRally:  return 0  // 즉발 — 끌어오기 액션은 노트 자체에 부착
        case .charmStudent:   return GameConfig.charmStudentDuration
        case .taiwanTrip:     return GameConfig.taiwanTripInvulnerableDuration
        }
    }

    /// 게임당 1회만 발동 가능한가? `.charmStudent`만 true.
    /// SkillSystem.tryActivate에서 usedThisGame 가드와 함께 사용.
    var oncePerGame: Bool {
        switch self {
        case .none:           return false
        case .dashClimb:      return false
        case .bookClubRally:  return false
        case .charmStudent:   return true
        case .taiwanTrip:     return false
        }
    }
}
