//
//  CloudSaveCoordinator.swift
//  GanhoMusic Shared
//
//  게임 종료 cloud save와 pending queue flush를 조율한다.
//

import Foundation

enum CloudSaveResult {
    case saved
    case queued
    case skipped
}

enum CloudProgressSyncResult {
    case merged
    case skipped
    case failed
}

final class CloudSaveCoordinator {

    // MARK: - Properties
    static let shared = CloudSaveCoordinator()

    private let cloudRepository: CloudProgressRepository
    private let pendingRepository: PendingCloudScoreRepository
    private let authProfileRepository: AuthProfileRepository

    // MARK: - Init
    init(cloudRepository: CloudProgressRepository = CloudProgressRepository(),
         pendingRepository: PendingCloudScoreRepository = PendingCloudScoreRepository(),
         authProfileRepository: AuthProfileRepository = AuthProfileRepository()) {
        self.cloudRepository = cloudRepository
        self.pendingRepository = pendingRepository
        self.authProfileRepository = authProfileRepository
    }

    // MARK: - Save
    @discardableResult
    func saveGameResult(record: CloudScoreRecord,
                        progress: CloudProgressSnapshot) async -> CloudSaveResult {
        guard let user = await FirebaseAuthManager.shared.ensureAnonymousSession() else {
            pendingRepository.enqueue(record)
            return .queued
        }

        let profile = profileSnapshot(user: user)
        authProfileRepository.save(snapshot: profile)

        do {
            try await cloudRepository.save(profile: profile, record: record, progress: progress)
            await flushPendingIfPossible()
            return .saved
        } catch {
            pendingRepository.enqueue(record)
            return .queued
        }
    }

    @discardableResult
    func flushPendingIfPossible() async -> CloudSaveResult {
        let pendingRecords = pendingRepository.current
        guard !pendingRecords.isEmpty else { return .skipped }
        guard let user = await FirebaseAuthManager.shared.ensureAnonymousSession() else {
            return .queued
        }

        let profile = profileSnapshot(user: user)
        let progress = currentProgressSnapshot()

        do {
            try await cloudRepository.save(profile: profile, records: pendingRecords, progress: progress)
            pendingRepository.remove(localIDs: Set(pendingRecords.map { $0.localID }))
            authProfileRepository.save(snapshot: profile)
            return .saved
        } catch {
            return .queued
        }
    }

    @discardableResult
    func syncProgressForCurrentUser(scope: AccountProgressScope) async -> CloudProgressSyncResult {
        guard let profile = authProfileRepository.current,
              !profile.uid.isEmpty else {
            return .skipped
        }

        do {
            guard let progress = try await cloudRepository.fetchProgress(uid: profile.uid) else {
                return .skipped
            }
            let scoreRepository = PerDifficultyScoreRepository.scoped(scope: scope)
            let graduationRepository = GraduationRepository.scoped(scope: scope)
            let didMergeScores = scoreRepository.mergeMax(progress.typedPerDifficultyScores)
            let didMergeGraduations = graduationRepository.mergeEarliest(progress.typedGraduations)
            return didMergeScores || didMergeGraduations ? .merged : .skipped
        } catch {
            return .failed
        }
    }

    // MARK: - Snapshot
    private func profileSnapshot(user: FirebaseAuthUserProviding) -> AuthProfileSnapshot {
        return AuthProfileSnapshot(
            uid: user.uid,
            isAnonymous: user.isAnonymous,
            displayName: user.displayName,
            providerIDs: user.providerIDs,
            updatedAt: Date()
        )
    }

    private func currentProgressSnapshot() -> CloudProgressSnapshot {
        let scope = AccountProgressScopeProvider.current(authProfile: authProfileRepository.current)
        return CloudProgressSnapshot.make(
            highScore: HighScoreRepository().current,
            stats: StatisticsRepository().current,
            perDifficultyScores: PerDifficultyScoreRepository.scoped(scope: scope).current,
            graduations: GraduationRepository.scoped(scope: scope).current
        )
    }
}

protocol FirebaseAuthUserProviding {
    var uid: String { get }
    var isAnonymous: Bool { get }
    var displayName: String? { get }
    var providerIDs: [String] { get }
}
