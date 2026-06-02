//
//  CloudProgressRepository.swift
//  GanhoMusic Shared
//
//  Firestore users/{uid} 아래 점수와 진행도 summary를 저장한다.
//

import Foundation
import FirebaseFirestore

final class CloudProgressRepository {

    // MARK: - Properties
    private let firestore: Firestore

    // MARK: - Init
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    // MARK: - Write
    func save(profile: AuthProfileSnapshot,
              record: CloudScoreRecord,
              progress: CloudProgressSnapshot) async throws {
        try await save(profile: profile, records: [record], progress: progress)
    }

    func save(profile: AuthProfileSnapshot,
              records: [CloudScoreRecord],
              progress: CloudProgressSnapshot) async throws {
        let batch = firestore.batch()
        let userDocument = userDocument(uid: profile.uid)
        batch.setData(userData(profile: profile), forDocument: userDocument, merge: true)

        for record in records {
            let scoreDocument = userDocument
                .collection(GameConfig.cloudScoresCollectionName)
                .document(record.localID)
            batch.setData(scoreData(record: record), forDocument: scoreDocument, merge: true)
        }

        let progressDocument = userDocument
            .collection(GameConfig.cloudProgressCollectionName)
            .document(GameConfig.cloudProgressSummaryDocumentName)
        batch.setData(progressData(progress: progress), forDocument: progressDocument, merge: true)

        try await commit(batch: batch)
    }

    // MARK: - Delete
    func deleteUserData(uid: String) async throws {
        let userDocument = userDocument(uid: uid)
        try await deleteCollection(
            userDocument.collection(GameConfig.cloudScoresCollectionName),
            batchLimit: GameConfig.cloudDeleteBatchLimit
        )
        try await deleteCollection(
            userDocument.collection(GameConfig.cloudProgressCollectionName),
            batchLimit: GameConfig.cloudDeleteBatchLimit
        )
        try await deleteDocument(userDocument)
    }

    // MARK: - Data Mapping
    private func userDocument(uid: String) -> DocumentReference {
        return firestore
            .collection(GameConfig.cloudUsersCollectionName)
            .document(uid)
    }

    private func userData(profile: AuthProfileSnapshot) -> [String: Any] {
        var data: [String: Any] = [
            "uid": profile.uid,
            "isAnonymous": profile.isAnonymous,
            "providerIDs": profile.providerIDs,
            "lastSeenAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let displayName = profile.displayName {
            data["displayName"] = displayName
        }
        return data
    }

    private func scoreData(record: CloudScoreRecord) -> [String: Any] {
        return [
            "localID": record.localID,
            "characterID": record.characterID,
            "difficulty": record.difficulty,
            "score": record.score,
            "maxCombo": record.maxCombo,
            "airforceTriggered": record.airforceTriggered,
            "playedAt": record.playedAt,
            "createdAt": FieldValue.serverTimestamp()
        ]
    }

    private func progressData(progress: CloudProgressSnapshot) -> [String: Any] {
        return [
            "highScore": progress.highScore,
            "stats": [
                "playCount": progress.stats.playCount,
                "totalScore": progress.stats.totalScore
            ],
            "perDifficultyScores": progress.perDifficultyScores,
            "graduations": progress.graduations,
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    private func commit(batch: WriteBatch) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            batch.commit { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    private func deleteCollection(_ collection: CollectionReference,
                                  batchLimit: Int) async throws {
        let boundedLimit = max(1, min(batchLimit, GameConfig.cloudDeleteBatchLimit))

        while true {
            let snapshot = try await getDocuments(collection.limit(to: boundedLimit))
            guard !snapshot.documents.isEmpty else { return }

            let batch = firestore.batch()
            snapshot.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            try await commit(batch: batch)

            if snapshot.documents.count < boundedLimit {
                return
            }
        }
    }

    private func deleteDocument(_ document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    private func getDocuments(_ query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let snapshot = snapshot else {
                    continuation.resume(throwing: AuthError.accountDeleteFailed)
                    return
                }
                continuation.resume(returning: snapshot)
            }
        }
    }
}
