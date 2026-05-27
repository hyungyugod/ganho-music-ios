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
        case .dashClimb:      return "암벽등반 돌진"
        case .bookClubRally:  return "북클럽 소집"
        case .charmStudent:   return "모범생의 매혹"
        case .taiwanTrip:     return "대만여행"
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

    /// Phase 10-1c — 스킬 설명 화면(SkillExplanationScene)에서 표시되는 본문 텍스트.
    /// 효과·조건·쿨다운을 한 문단으로 요약. displayName(짧은 단어)과 분리 — 같은 스킬의 *다른 시점* 표현.
    /// `.none`은 빈 문자열 — 김간호는 스킬 설명 씬 자체를 스킵하므로 호출되지 않음(graceful default).
    var fullDescription: String {
        switch self {
        case .none:           return ""
        case .dashClimb:      return "바라보는 방향으로 3타일 돌진. 벽 1칸 파괴. 쿨다운 22초."
        case .bookClubRally:  return "주변 6타일 안 음표를 한 번에 끌어와 수집. 쿨다운 20초."
        case .charmStudent:   return "수간호사를 4초간 매혹. F 대신 A 투척(수집 시 점수 2배). 게임당 1회."
        case .taiwanTrip:     return "현재 위치의 반대 대각선 방향으로 멀리 순간이동. 착지 후 0.5초 무적. 쿨다운 22초."
        }
    }

    /// Sprint 2 — 스킬 *범위* 라벨. 메타 칩 3개 중 하나. 순수 시각 표현용.
    /// 게임 로직 분기 0 — switch는 단순 문자열 lookup.
    var rangeText: String {
        switch self {
        case .none:           return "—"
        case .dashClimb:      return "3타일"
        case .bookClubRally:  return "6타일"
        case .charmStudent:   return "전역"
        case .taiwanTrip:     return "반대 대각"
        }
    }

    /// Sprint 2 — 스킬 *발동 타입* 라벨. duration=0은 "즉발", 그 외는 "N초".
    /// `.charmStudent`는 게임당 1회 + duration이 있는 매혹 시간 → "지속 \(duration)초" 톤이 어울리지만
    /// SPEC §K4는 duration 0이 아니면 "\(duration)초" 표기를 요청 → 그대로 따른다.
    var castText: String {
        switch self {
        case .none:
            return "—"
        case .dashClimb, .bookClubRally, .charmStudent, .taiwanTrip:
            if duration <= 0 {
                return "즉발"
            }
            let seconds = Int(duration.rounded())
            return "\(seconds)초"
        }
    }

    // MARK: - Sprint 7 Phase A — CD 미니칩

    /// 카드 우상단 CD 미니칩 라벨. 정확한 초 단위가 아닌 *위계 신호*.
    /// 스킬 없음(.none) → "∞", 그 외 → "1회".
    /// (정확한 초는 SkillExplanationScene 메타 칩이 담당.)
    /// switch default 미사용 — 5 case exhaustive.
    var cooldownText: String {
        switch self {
        case .none:           return "∞"
        case .dashClimb:      return "1회"
        case .bookClubRally:  return "1회"
        case .charmStudent:   return "1회"
        case .taiwanTrip:     return "1회"
        }
    }
}
