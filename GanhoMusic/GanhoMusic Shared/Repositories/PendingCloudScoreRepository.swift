//
//  PendingCloudScoreRepository.swift
//  GanhoMusic Shared
//
//  Firestore 저장 실패 시 한 판 점수를 로컬 큐에 보관한다.
//

import Foundation

final class PendingCloudScoreRepository {

    // MARK: - Properties
    private let defaults: UserDefaults
    private let key: String
    private let limit: Int

    // MARK: - Init
    init(defaults: UserDefaults = .standard,
         key: String = GameConfig.cloudPendingScoreUserDefaultsKey,
         limit: Int = GameConfig.cloudPendingScoreLimit) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
    }

    // MARK: - Read
    var current: [CloudScoreRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        guard let records = try? JSONDecoder().decode([CloudScoreRecord].self, from: data) else {
            defaults.removeObject(forKey: key)
            return []
        }

        let clampedRecords = clamp(records)
        if clampedRecords.count != records.count {
            save(clampedRecords)
        }
        return clampedRecords
    }

    // MARK: - Write
    func enqueue(_ record: CloudScoreRecord) {
        var records = current.filter { $0.localID != record.localID }
        records.append(record)
        save(clamp(records))
    }

    func remove(localIDs: Set<String>) {
        guard !localIDs.isEmpty else { return }
        let records = current.filter { !localIDs.contains($0.localID) }
        save(records)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ records: [CloudScoreRecord]) {
        guard !records.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(clamp(records)) else { return }
        defaults.set(data, forKey: key)
    }

    private func clamp(_ records: [CloudScoreRecord]) -> [CloudScoreRecord] {
        let boundedLimit = max(0, limit)
        guard records.count > boundedLimit else { return records }
        guard boundedLimit > 0 else { return [] }
        return Array(records.suffix(boundedLimit))
    }
}
