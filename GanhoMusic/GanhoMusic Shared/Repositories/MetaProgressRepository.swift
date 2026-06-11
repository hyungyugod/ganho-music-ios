//
//  MetaProgressRepository.swift
//  GanhoMusic Shared
//
//  R6 §F2 — 메타 영속 계층 (별 15셀·업적·일일·카운터·마이그레이션 버전).
//  `.scoped` 패턴 (PerDifficultyScoreRepository 동형) — 계정 단위 키 suffix.
//  키별 독립 저장(단일 blob 금지) — 한 키 디코드 실패가 다른 메타를 전손시키지 않는다.
//  별 셀 시맨틱 = ratchet 기록: max(저장값, 신규 획득) 단조 증가만 — 점수 재파생 아님
//  (일일 2배 적립·미래 임계 튜닝에 견고). XP는 기존 `statistics` 키 현행 유지 — 신규 키 0.
//  마이그레이션은 기존 키 *읽기만* — 어떤 기존 키에도 set 0 (T2 byte-보존 게이트).
//

import Foundation

/// 메타 진행 영속 저장소. 단일 스레드(메인) 호출 가정 — 락/큐 없음. 강제 언래핑 0.
final class MetaProgressRepository {

    // MARK: - Counter Keys (저장 sub-key — 단 1회 정의, 호출부 리터럴 금지)
    private static let notesCounterKey = "notes.total"
    private static let skillCounterKeyPrefix = "skill."

    // MARK: - Properties
    private let defaults: UserDefaults
    private let starCellsKey: String
    private let achievementsKey: String
    private let dailyKey: String
    private let countersKey: String
    private let migrationKey: String
    /// 마이그레이션 시드/백필이 읽는 기존 저장소 (같은 defaults 주입 — 자가검증 격리 suite 호환).
    private let perDiffRepo: PerDifficultyScoreRepository
    private let graduationRepo: GraduationRepository
    private let statsRepo: StatisticsRepository

    // MARK: - Init (DI 허용 — 자가검증이 격리 suite 주입)
    init(defaults: UserDefaults = .standard, scope: AccountProgressScope) {
        self.defaults = defaults
        let suffix = scope.storageSuffix
        self.starCellsKey = "\(StorageKeys.metaStarCellsUserDefaultsKey).\(suffix)"
        self.achievementsKey = "\(StorageKeys.metaAchievementsUserDefaultsKey).\(suffix)"
        self.dailyKey = "\(StorageKeys.metaDailyChallengeUserDefaultsKey).\(suffix)"
        self.countersKey = "\(StorageKeys.metaCountersUserDefaultsKey).\(suffix)"
        self.migrationKey = "\(StorageKeys.metaMigrationVersionUserDefaultsKey).\(suffix)"
        self.perDiffRepo = PerDifficultyScoreRepository.scoped(scope: scope, defaults: defaults)
        self.graduationRepo = GraduationRepository.scoped(scope: scope, defaults: defaults)
        // XP는 전역 `statistics` 키 현행 유지 (R5 출하 동작 — SPEC 불일치 #6).
        self.statsRepo = StatisticsRepository(defaults: defaults)
    }

    static func scoped(scope: AccountProgressScope,
                       defaults: UserDefaults = .standard) -> MetaProgressRepository {
        return MetaProgressRepository(defaults: defaults, scope: scope)
    }

    // MARK: - Read
    /// 별 15셀 ratchet 기록. 디코드 실패/키 부재 시 빈 dict graceful 폴백 (기존 repo 패턴).
    var starCells: [CharacterID: [Difficulty: Int]] {
        guard let data = defaults.data(forKey: starCellsKey),
              let raw = try? JSONDecoder().decode([String: [String: Int]].self, from: data) else {
            return [:]
        }
        var result: [CharacterID: [Difficulty: Int]] = [:]
        for (charRaw, inner) in raw {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            var bucket: [Difficulty: Int] = [:]
            for (diffRaw, stars) in inner {
                guard let diff = Difficulty(rawValue: diffRaw) else { continue }
                bucket[diff] = stars
            }
            result[charID] = bucket
        }
        return result
    }

    /// 총 별 (언락 통화) = 15셀 합, 0~45.
    var totalStars: Int {
        return starCells.values.reduce(0) { $0 + $1.values.reduce(0, +) }
    }

    /// 업적 달성 dict (달성일 보존).
    var achievements: [AchievementID: Date] {
        guard let data = defaults.data(forKey: achievementsKey),
              let raw = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        var result: [AchievementID: Date] = [:]
        for (idRaw, date) in raw {
            guard let id = AchievementID(rawValue: idRaw) else { continue }
            result[id] = date
        }
        return result
    }

    /// 클리어한 dayKey 집합.
    var clearedDayKeys: Set<String> {
        guard let data = defaults.data(forKey: dailyKey),
              let raw = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(raw)
    }

    func isDailyCleared(dayKey: String) -> Bool {
        return clearedDayKeys.contains(dayKey)
    }

    /// 누적 카운터 raw dict (노출은 cloud 머지·자가검증용).
    var counters: [String: Int] {
        guard let data = defaults.data(forKey: countersKey),
              let raw = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return raw
    }

    var totalNotesCollected: Int { return counters[Self.notesCounterKey] ?? 0 }

    func skillActivationCount(for characterID: CharacterID) -> Int {
        return counters[Self.skillCounterKeyPrefix + characterID.rawValue] ?? 0
    }

    // MARK: - Migration (§F2 — 스코프당 1회, 멱등, 기존 키 읽기 전용)
    func ensureMigrated() {
        guard defaults.integer(forKey: migrationKey) < MetaTuning.metaMigrationVersion else { return }
        // 1) 별 셀 시드 — 기존 perDifficultyScores에서 §F1 신규 임계로 파생.
        //    별은 발매된 적 없는 R5 개발 빌드에서만 표시 — grandfathering 불필요 (SPEC §F1).
        var cells: [CharacterID: [Difficulty: Int]] = [:]
        for (characterID, byDifficulty) in perDiffRepo.current {
            for (difficulty, best) in byDifficulty {
                let stars = MetaProgression.stars(score: best, difficulty: difficulty)
                guard stars > 0 else { continue }
                cells[characterID, default: [:]][difficulty] = stars
            }
        }
        saveStarCells(cells)
        // 2) 백필 업적 — 기존 데이터만으로 판정 가능한 7종 (summary nil → 판 단위 조건 자연 false).
        //    콤보·변기·박병장·누적 음표·스킬·일일은 이력 부재로 0에서 시작 (의도된 한계).
        let backfilled = AchievementEvaluator.newlyAchieved(context: makeContext(summary: nil))
        recordAchievements(backfilled, at: Date())
        // 3) 멱등 가드 기록 — 신규 meta 키만 set (기존 키 set 0, T2).
        defaults.set(MetaTuning.metaMigrationVersion, forKey: migrationKey)
    }

    // MARK: - Record Run (§F2 — endGame 기존 저장 직후 1회)
    @discardableResult
    func recordRun(_ summary: RunSummary) -> RunMetaOutcome {
        ensureMigrated()   // 방어 호출 — 멱등이라 안전 (SPEC §F2 호출 지점 ②)
        let earned = MetaProgression.stars(score: summary.score, target: summary.effectiveTarget)
        let isSuccess = summary.score >= summary.effectiveTarget
        // 일일 최초 클리어 — armed 판 ∧ 성공 ∧ 해당 dayKey 미클리어 (재클리어는 일반 적립, T8).
        let isDailyFirstClear = summary.dailyModifier != nil
            && isSuccess
            && !isDailyCleared(dayKey: summary.playedDayKey)
        let credited = isDailyFirstClear
            ? min(MetaProgression.maxStarsPerCell, earned * MetaTuning.dailyStarMultiplier)
            : earned
        // 1) 셀 별 ratchet — 단조 증가만.
        ratchetStarCell(characterID: summary.characterID,
                        difficulty: summary.difficulty,
                        stars: credited)
        // 2) 카운터 가산.
        var updatedCounters = counters
        if summary.notesCollected > 0 {
            updatedCounters[Self.notesCounterKey, default: 0] += summary.notesCollected
        }
        if summary.skillActivations > 0 {
            let key = Self.skillCounterKeyPrefix + summary.characterID.rawValue
            updatedCounters[key, default: 0] += summary.skillActivations
        }
        saveCounters(updatedCounters)
        // 3) 일일 클리어 기록.
        if isDailyFirstClear {
            saveClearedDayKeys(clearedDayKeys.union([summary.playedDayKey]))
        }
        // 4) 업적 16종 판정 → 신규 달성분 저장.
        let newAchievements = AchievementEvaluator.newlyAchieved(
            context: makeContext(summary: summary)
        )
        recordAchievements(newAchievements, at: Date())
        // 5) R7 §F6 — 캐릭터 해금 delta: 별 ratchet·업적 기록 반영 *후* endGame 스냅샷과 동일
        //    식으로 재평가 (graduations/scores는 endGame이 이미 갱신한 저장소 현재값).
        //    영속 0 — 라이브 OR 판정 원칙(R6 §F3) 그대로, 해금 상태 저장 금지. allCases 순서 보존.
        let newlyUnlocked = CharacterID.allCases.filter { characterID in
            guard !summary.unlockedCharactersBefore.contains(characterID) else { return false }
            return CharacterUnlockRules.isUnlocked(characterID,
                                                   graduations: graduationRepo.current,
                                                   scores: perDiffRepo.current,
                                                   totalStars: totalStars)
        }
        return RunMetaOutcome(
            effectiveTarget: summary.effectiveTarget,
            earnedStars: earned,
            creditedStars: credited,
            dailyModifier: summary.dailyModifier,
            isDailyFirstClear: isDailyFirstClear,
            newAchievements: newAchievements,
            newlyUnlockedCharacters: newlyUnlocked,
            totalStars: totalStars,
            comboBreaks: summary.comboBreaks,         // R12 #9 — 결과창 통계 칩 운반
            toiletsCollected: summary.toiletsCollected
        )
    }

    // MARK: - Private (저장 헬퍼는 internal — +Cloud extension이 공유, 파일 밖 호출처 없음)
    private func ratchetStarCell(characterID: CharacterID, difficulty: Difficulty, stars: Int) {
        var cells = starCells
        guard stars > (cells[characterID]?[difficulty] ?? 0) else { return }
        cells[characterID, default: [:]][difficulty] = stars
        saveStarCells(cells)
    }

    private func recordAchievements(_ ids: [AchievementID], at date: Date) {
        guard !ids.isEmpty else { return }
        var dict = achievements
        for id in ids where dict[id] == nil {
            dict[id] = date
        }
        saveAchievements(dict)
    }

    private func makeContext(summary: RunSummary?) -> AchievementContext {
        var skillByCharacter: [CharacterID: Int] = [:]
        for characterID in CharacterID.allCases {
            skillByCharacter[characterID] = skillActivationCount(for: characterID)
        }
        return AchievementContext(
            summary: summary,
            starCells: starCells,
            totalStars: totalStars,
            totalNotesCollected: totalNotesCollected,
            skillActivations: skillByCharacter,
            dailyClearCount: clearedDayKeys.count,
            perDifficultyScores: perDiffRepo.current,
            graduations: graduationRepo.current,
            totalXP: statsRepo.current.totalScore,
            achieved: Set(achievements.keys)
        )
    }

    func saveStarCells(_ cells: [CharacterID: [Difficulty: Int]]) {
        var raw: [String: [String: Int]] = [:]
        for (charID, inner) in cells {
            var bucket: [String: Int] = [:]
            for (diff, stars) in inner { bucket[diff.rawValue] = stars }
            raw[charID.rawValue] = bucket
        }
        guard let data = try? JSONEncoder().encode(raw) else { return }
        defaults.set(data, forKey: starCellsKey)
    }

    func saveAchievements(_ dict: [AchievementID: Date]) {
        var raw: [String: Date] = [:]
        for (id, date) in dict { raw[id.rawValue] = date }
        guard let data = try? JSONEncoder().encode(raw) else { return }
        defaults.set(data, forKey: achievementsKey)
    }

    func saveClearedDayKeys(_ keys: Set<String>) {
        guard let data = try? JSONEncoder().encode(Array(keys).sorted()) else { return }
        defaults.set(data, forKey: dailyKey)
    }

    func saveCounters(_ counters: [String: Int]) {
        guard let data = try? JSONEncoder().encode(counters) else { return }
        defaults.set(data, forKey: countersKey)
    }
}
