//
//  DailyChallenge.swift
//  GanhoMusic Shared
//
//  R6 일일 도전 (SPEC §F7 / 02 §7-4). dayKey(yyyyMMdd, 로컬 Calendar) → SeededRandom →
//  모디파이어 6종 중 1 결정 — 하루 동일 (T7). DailyChallengeSession은 armed 상태 보관자 —
//  dayKey 불일치 시 자동 해제 (자정 경과 안전, Timer 금지 — 표시 시점 1회 계산).
//  SPEC이 본 파일에 enum + 결정 함수 + 세션을 함께 두도록 명시 (신규 10파일 고정).
//

import Foundation

/// 일일 모디파이어 6종 — raw 문자열 = 저장·동기화 포맷 (변경 금지, SPEC §F7 표).
enum DailyModifier: String, CaseIterable {
    case speedNight = "speed_night"
    case noteRush = "note_rush"
    case lightsOut = "lights_out"
    case mirrorWard = "mirror_ward"
    case goldenToilet = "golden_toilet"
    case fullSpirit = "full_spirit"

    /// 표시명 — Start 칩·인게임 HUD 표식 공용. switch exhaustive — default 금지.
    var displayName: String {
        switch self {
        case .speedNight:   return "스피드 나이트"
        case .noteRush:     return "음표 러시"
        case .lightsOut:    return "소등"
        case .mirrorWard:   return "거울 병동"
        case .goldenToilet: return "황금 변기"
        case .fullSpirit:   return "기합 충만"
        }
    }
}

/// 일일 도전 결정 함수 네임스페이스. case 없는 enum — 인스턴스화 차단.
enum DailyChallenge {

    /// dayKey 포맷 — yyyyMMdd (로컬 Calendar.current, 02 §7-4 "시드 = YYYYMMDD").
    private static let dayKeyFormat = "yyyyMMdd"

    /// 오늘의 dayKey. 호출 시점 1회 계산 — Timer/매초 갱신 금지 (SPEC §주의사항 7).
    static func todayKey(now: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = dayKeyFormat
        return formatter.string(from: now)
    }

    /// dayKey → 모디파이어 결정 (결정적 — 같은 키는 항상 같은 결과, T7).
    /// yyyyMMdd는 항상 숫자라 UInt64 직변환 — 비정상 키는 FNV-1a 해시 폴백 (강제 언래핑 0).
    static func modifier(forDayKey dayKey: String) -> DailyModifier {
        let seed = UInt64(dayKey) ?? fnv1aHash(dayKey)
        var generator = SeededRandom(seed: seed)
        // allCases 비어 있을 수 없으나 randomElement는 Optional — 첫 케이스 폴백 (강제 언래핑 0).
        return DailyModifier.allCases.randomElement(using: &generator) ?? .speedNight
    }

    /// 자정(다음 날 시작)까지 남은 초. 표시 시점 1회 계산 — 시(時) 단위 환산은 호출부.
    static func secondsUntilTomorrow(now: Date = Date(), calendar: Calendar = .current) -> TimeInterval {
        let startOfToday = calendar.startOfDay(for: now)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return 0
        }
        return max(0, startOfTomorrow.timeIntervalSince(now))
    }

    /// 남은 시간 시(時) 단위 (올림 — "~{h}시간" 표기용).
    static func hoursUntilTomorrow(now: Date = Date(), calendar: Calendar = .current) -> Int {
        let seconds = secondsUntilTomorrow(now: now, calendar: calendar)
        return Int((seconds / MetaTuning.dailySecondsPerHour).rounded(.up))
    }

    /// FNV-1a 64bit — 비숫자 dayKey 폴백 해시. 상수는 알고리즘 정의 자체 (도메인 수치 아님).
    private static func fnv1aHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}

/// 일일 도전 armed 상태 보관자 (SPEC §F7 — 세션 단위, 영속 0).
/// Start 칩 탭이 toggle, GameScene factory 기본 인자가 `activeModifier()`로 해석.
/// dayKey 검증으로 날짜 경과 시 자동 비활성 — 재도전(retry)은 같은 날이면 자연 유지.
final class DailyChallengeSession {

    // MARK: - Shared
    static let shared = DailyChallengeSession()

    // MARK: - State
    /// armed 시점의 dayKey. nil = 비활성.
    private(set) var armedDayKey: String?

    // MARK: - Queries
    /// 현재(호출 시점 기준) armed 상태인지 — dayKey 일치까지 검증.
    func isArmed(now: Date = Date()) -> Bool {
        guard let armedDayKey = armedDayKey else { return false }
        guard armedDayKey == DailyChallenge.todayKey(now: now) else {
            // 자정 경과 — 자동 해제 (stale armed 상태 즉시 청소).
            self.armedDayKey = nil
            return false
        }
        return true
    }

    /// armed 상태면 오늘의 모디파이어, 아니면 nil — GameScene factory 기본 인자의 단일 공급점.
    func activeModifier(now: Date = Date()) -> DailyModifier? {
        guard isArmed(now: now) else { return nil }
        return DailyChallenge.modifier(forDayKey: DailyChallenge.todayKey(now: now))
    }

    // MARK: - Mutations
    /// Start 칩 탭 — armed 토글. 반환값 = 토글 후 armed 여부 (칩 스타일 갱신용).
    @discardableResult
    func toggle(now: Date = Date()) -> Bool {
        if isArmed(now: now) {
            armedDayKey = nil
            return false
        }
        armedDayKey = DailyChallenge.todayKey(now: now)
        return true
    }
}
