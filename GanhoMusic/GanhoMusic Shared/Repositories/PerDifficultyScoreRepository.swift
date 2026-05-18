//
//  PerDifficultyScoreRepository.swift
//  GanhoMusic Shared
//
//  Phase 7-4 · 캐릭터 × 난이도 매트릭스 최고 점수 저장소 (졸업장 시스템용)
//

import Foundation

/// 캐릭터(5종) × 난이도(3종) = 15 셀 매트릭스로 최고 점수를 영구 저장하는 영속 계층.
/// UserDefaults JSON `[String: [String: Int]]` 직렬화 — 외부 raw 키는 enum.rawValue.
/// 외층 키 = `CharacterID.rawValue`, 내층 키 = `Difficulty.rawValue`, 값 = Int 최고 점수.
///
/// HighScoreRepository(단일 최고점)와 *병행 유지* — 본 저장소는 *졸업 판정* 전용이고,
/// 기존 단일 최고점은 ResultScene 표시에 그대로 쓰임. 두 저장소 모두 endGame에서 동시 갱신.
///
/// init에 `defaults`/`key`를 기본값으로 받아 DI를 허용 — prod는 기본 생성자, 테스트는 별도 suite 주입.
/// 단일 스레드(메인) 호출 가정 → 락/큐 없음.
/// 강제 언래핑 0건 — guard let / try? 로 graceful 실패. 디코딩/인코딩 실패 시 빈 dict 또는 false 반환.
///
/// Spring 비유: JPA Repository — `findBy(id)` = best(:), `save(entity)` = record(:). 둘 다 갱신 시 true.
final class PerDifficultyScoreRepository {

    // MARK: - Properties
    private let key: String
    private let defaults: UserDefaults

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.perDifficultyScoreUserDefaultsKey) {
        self.defaults = defaults
        self.key = key
    }

    // MARK: - Read
    /// 디스크에 저장된 매트릭스 전체. 키가 없거나 디코딩 실패 시 빈 dict로 graceful 폴백.
    /// rawValue → enum 역변환 실패는 *해당 셀만* 무시(graceful) — 전체 dict 폐기 0.
    /// StatisticsRepository.current 패턴 답습 + 2층 dict 변환.
    var current: [CharacterID: [Difficulty: Int]] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        guard let raw = try? JSONDecoder().decode([String: [String: Int]].self, from: data) else { return [:] }
        var result: [CharacterID: [Difficulty: Int]] = [:]
        for (charRaw, inner) in raw {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            var bucket: [Difficulty: Int] = [:]
            for (diffRaw, score) in inner {
                guard let diff = Difficulty(rawValue: diffRaw) else { continue }
                bucket[diff] = score
            }
            result[charID] = bucket
        }
        return result
    }

    /// 단일 셀(캐릭터 × 난이도)의 최고 점수. 미기록 시 0 반환 (UserDefaults integer(forKey:) 규약 답습).
    /// 졸업 판정 헬퍼(GameScene.isGraduated)가 모든 난이도에 대해 이 메서드를 호출.
    func best(characterID: CharacterID, difficulty: Difficulty) -> Int {
        return current[characterID]?[difficulty] ?? 0
    }

    // MARK: - Write
    /// 점수가 기존 셀 최고를 갱신하면 디스크에 저장하고 true 반환. 아니면 false.
    /// HighScoreRepository.record와 동형 시그니처 — 갱신만 true, 같은 점수도 false(엄격 비교 `>`).
    /// 인코딩 실패 시 false 반환 — 앱이 죽지 않는다(graceful).
    @discardableResult
    func record(characterID: CharacterID, difficulty: Difficulty, score: Int) -> Bool {
        var matrix = current
        let prior = matrix[characterID]?[difficulty] ?? 0
        guard score > prior else { return false }
        var bucket = matrix[characterID] ?? [:]
        bucket[difficulty] = score
        matrix[characterID] = bucket
        // enum → rawValue 직렬화 — 2층 dict 모두 변환.
        var raw: [String: [String: Int]] = [:]
        for (charID, inner) in matrix {
            var innerRaw: [String: Int] = [:]
            for (diff, s) in inner {
                innerRaw[diff.rawValue] = s
            }
            raw[charID.rawValue] = innerRaw
        }
        guard let data = try? JSONEncoder().encode(raw) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
