//
//  FirebaseRecordRepository.swift
//  GanhoMusic Shared
//
//  Firestore 사용자별 플레이 기록 저장소.
//

import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum FirebaseRecordSaveResult: Equatable {
    case unavailable
    case saved
}

final class FirebaseRecordRepository {

    private let accountRepository: FirebaseAccountRepository

    init(accountRepository: FirebaseAccountRepository = FirebaseAccountRepository()) {
        self.accountRepository = accountRepository
    }

    @discardableResult
    func save(_ record: GameRecord) async -> FirebaseRecordSaveResult {
        #if canImport(FirebaseFirestore)
        FirebaseDiagnostics.info("Record save requested score=\(record.score).")
        let syncResult = await accountRepository.bootstrapProfile()
        guard case let .synced(profile) = syncResult else { return .unavailable }

        do {
            let data: [String: Any] = [
                "characterId": record.characterID,
                "difficulty": record.difficulty,
                "score": record.score,
                "bestScore": record.bestScore,
                "isNewBest": record.isNewBest,
                "playCount": record.playCount,
                "totalScore": record.totalScore,
                "graduated": record.graduated,
                "playedAt": Timestamp(date: record.playedAt)
            ]
            try await Firestore.firestore()
                .collection("profiles")
                .document(profile.id)
                .collection("records")
                .addDocument(data: data)
            try await Firestore.firestore()
                .collection("profiles")
                .document(profile.id)
                .setData(profileSummaryData(record: record), merge: true)
            FirebaseDiagnostics.info("Record saved for uid=\(profile.id), score=\(record.score).")
            return .saved
        } catch {
            FirebaseDiagnostics.error("Record save failed.", error: error)
            return .unavailable
        }
        #else
        FirebaseDiagnostics.error("FirebaseFirestore module is not linked. Record save skipped.")
        return .unavailable
        #endif
    }

    #if canImport(FirebaseFirestore)
    private func profileSummaryData(record: GameRecord) -> [String: Any] {
        return [
            "bestScore": record.bestScore,
            "playCount": record.playCount,
            "totalScore": record.totalScore,
            "unlockedCharacterIDs": CharacterUnlockRepository()
                .unlockedCharacterIDs(forPlayCount: record.playCount),
            "updatedAt": Timestamp(date: Date())
        ]
    }
    #endif
}
