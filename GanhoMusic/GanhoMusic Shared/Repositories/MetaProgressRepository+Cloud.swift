//
//  MetaProgressRepository+Cloud.swift
//  GanhoMusic Shared
//
//  R6 §F4 — 클라우드 합류 절반 (스냅샷 변환·머지·재파생). 본체가 300줄 규칙에 닿아
//  extension 분리 (R4/R5 extension 분할 전례 — SPEC 신규 10파일 외 필수 연동 분리, SELF_CHECK 기재).
//  머지 정책: 별 셀 = max / 업적 = 합집합(달성일 이른 쪽) / 일일 dayKey = 합집합 /
//  카운터 = max (sum은 이중 계상 위험 — 보수적 하한 채택, SPEC §F4).
//

import Foundation

extension MetaProgressRepository {

    // MARK: - Cloud Snapshot
    /// 클라우드 meta 스냅샷용 raw 변환 (CloudProgressSnapshot.make의 meta 인자).
    func cloudMeta() -> CloudMetaProgress {
        var rawCells: [String: [String: Int]] = [:]
        for (charID, inner) in starCells {
            var bucket: [String: Int] = [:]
            for (diff, stars) in inner { bucket[diff.rawValue] = stars }
            rawCells[charID.rawValue] = bucket
        }
        var rawAchievements: [String: Date] = [:]
        for (id, date) in achievements { rawAchievements[id.rawValue] = date }
        return CloudMetaProgress(
            starCells: rawCells,
            achievements: rawAchievements,
            dailyClearedDayKeys: Array(clearedDayKeys).sorted(),
            counters: counters
        )
    }

    // MARK: - Merge (syncProgressForCurrentUser — 실패해도 로컬 우선)
    @discardableResult
    func merge(cloudMeta incoming: CloudMetaProgress) -> Bool {
        // 별 셀 max-merge — rawValue 역변환 실패 셀만 무시 (graceful, 기존 repo 패턴).
        var cells = starCells
        var cellsChanged = false
        for (charRaw, inner) in incoming.starCells {
            guard let charID = CharacterID(rawValue: charRaw) else { continue }
            for (diffRaw, stars) in inner {
                guard let diff = Difficulty(rawValue: diffRaw) else { continue }
                if stars > (cells[charID]?[diff] ?? 0) {
                    cells[charID, default: [:]][diff] = stars
                    cellsChanged = true
                }
            }
        }
        if cellsChanged { saveStarCells(cells) }
        // 업적 합집합 — 달성일은 이른 쪽 (GraduationRepository.mergeEarliest 동형 정책).
        var mergedAchievements = achievements
        var achievementsChanged = false
        for (idRaw, incomingDate) in incoming.achievements {
            guard let id = AchievementID(rawValue: idRaw) else { continue }
            if let existing = mergedAchievements[id], existing <= incomingDate { continue }
            mergedAchievements[id] = incomingDate
            achievementsChanged = true
        }
        if achievementsChanged { saveAchievements(mergedAchievements) }
        // 일일 dayKey 합집합.
        let mergedDays = clearedDayKeys.union(incoming.dailyClearedDayKeys)
        let daysChanged = mergedDays != clearedDayKeys
        if daysChanged { saveClearedDayKeys(mergedDays) }
        // 카운터 max.
        var mergedCounters = counters
        var countersChanged = false
        for (key, value) in incoming.counters where value > (mergedCounters[key] ?? 0) {
            mergedCounters[key] = value
            countersChanged = true
        }
        if countersChanged { saveCounters(mergedCounters) }
        return cellsChanged || achievementsChanged || daysChanged || countersChanged
    }

    /// 점수 기반 별 재파생 max — 클라우드 점수 머지 직후 1회 (§F2 갱신 지점 ②).
    @discardableResult
    func reapplyStarRatchet(scores: [CharacterID: [Difficulty: Int]]) -> Bool {
        var cells = starCells
        var didChange = false
        for (characterID, byDifficulty) in scores {
            for (difficulty, best) in byDifficulty {
                let derived = MetaProgression.stars(score: best, difficulty: difficulty)
                if derived > (cells[characterID]?[difficulty] ?? 0) {
                    cells[characterID, default: [:]][difficulty] = derived
                    didChange = true
                }
            }
        }
        if didChange { saveStarCells(cells) }
        return didChange
    }
}
