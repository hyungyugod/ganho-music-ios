//
//  AchievementID.swift
//  GanhoMusic Shared
//
//  R6 업적 16종 (SPEC §F5 / 02 §7-5). raw String = 저장 포맷 — 변경 금지 (SPEC 표 고정).
//  표시명·조건 문구는 Scoreboard 업적 탭이 소비. 판정 로직은 AchievementEvaluator 소관.
//

import Foundation

/// 업적 16종 식별자. raw 문자열이 UserDefaults·클라우드 저장 키 — byte 불변.
enum AchievementID: String, CaseIterable {
    case firstGraduation = "first_graduation"
    case combo10 = "combo_10"
    case combo20 = "combo_20"
    case fullComboGraduation = "full_combo_graduation"
    case toiletManiac = "toilet_maniac"
    case sergeantWitness = "sergeant_witness"
    case kimHardClear = "kim_hard_clear"
    case skillMaster = "skill_master"
    case hardAllCharacters = "hard_all_characters"
    case notes500 = "notes_500"
    case notes2000 = "notes_2000"
    case daily7 = "daily_7"
    case threeStar5 = "three_star_5"
    case threeStar15 = "three_star_15"
    case allCharactersUnlocked = "all_characters_unlocked"
    case level10 = "level_10"

    /// 표시명 (SPEC 표 "이름(안)" — 게임 톤 내 카피). switch exhaustive — default 금지.
    var displayName: String {
        switch self {
        case .firstGraduation:       return "첫 졸업"
        case .combo10:               return "콤보 10"
        case .combo20:               return "콤보 20"
        case .fullComboGraduation:   return "풀콤보 졸업"
        case .toiletManiac:          return "변기 마니아"
        case .sergeantWitness:       return "박병장 목격"
        case .kimHardClear:          return "정공법"
        case .skillMaster:           return "스킬 마스터"
        case .hardAllCharacters:     return "상 난이도 정복"
        case .notes500:              return "누적 음표 500"
        case .notes2000:             return "누적 음표 2,000"
        case .daily7:                return "일일 도전 7회"
        case .threeStar5:            return "3별 셀 5개"
        case .threeStar15:           return "올클리어"
        case .allCharactersUnlocked: return "전 캐릭터 해금"
        case .level10:               return "음악박사"
        }
    }

    /// 미달성 셀에 표시할 조건 문구 (SPEC §F5 — "미달성 = 어둡게+조건 문구").
    var conditionText: String {
        switch self {
        case .firstGraduation:       return "처음으로 졸업하기"
        case .combo10:               return "한 판 콤보 10 달성"
        case .combo20:               return "한 판 콤보 20 달성"
        case .fullComboGraduation:   return "콤보 안 끊고 졸업"
        case .toiletManiac:          return "한 판 변기 4개 수집"
        case .sergeantWitness:       return "박병장과 마주치기"
        case .kimHardClear:          return "김간호로 상 난이도 졸업"
        case .skillMaster:           return "4캐릭터 스킬 각 10회 발동"
        case .hardAllCharacters:     return "5캐릭터 전원 상 난이도 졸업"
        case .notes500:              return "음표 누적 500개 수집"
        case .notes2000:             return "음표 누적 2,000개 수집"
        case .daily7:                return "일일 도전 7회 클리어"
        case .threeStar5:            return "★★★ 셀 5개 모으기"
        case .threeStar15:           return "15셀 전부 ★★★"
        case .allCharactersUnlocked: return "5캐릭터 전원 해금"
        case .level10:               return "Lv.10 음악박사 도달"
        }
    }
}
