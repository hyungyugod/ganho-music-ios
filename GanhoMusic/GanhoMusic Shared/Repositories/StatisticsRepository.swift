//
//  StatisticsRepository.swift
//  GanhoMusic Shared
//
//  Phase 3-5 · 누적 통계 영구 저장 (UserDefaults + Codable JSON)
//

import Foundation

/// 누적 통계(playCount, totalScore)를 UserDefaults에 JSON Data로 영구 저장.
/// 키 문자열은 GameConfig.statisticsUserDefaultsKey로 단일화.
/// init에 defaults/key를 기본값 인자로 받아 DI를 허용.
/// 단일 스레드(메인) 호출 가정 → 락/큐 없음.
final class StatisticsRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.statisticsUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 저장된 누적 통계. 키가 없거나 디코딩 실패 시 GameStats() 기본값(0,0)으로 폴백.
    var current: GameStats {
        guard let data = defaults.data(forKey: key) else { return GameStats() }
        return (try? JSONDecoder().decode(GameStats.self, from: data)) ?? GameStats()
    }

    // MARK: - Write
    /// 한 판 종료 시 호출. playCount += 1, totalScore += score 후 인코딩하여 디스크에 저장.
    /// 인코딩 실패 시 무시(다음 호출에서 재시도) — 앱이 죽지 않는다.
    func recordPlay(score: Int) {
        var stats = current
        stats.playCount += 1
        stats.totalScore += score
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: key)
    }
}
