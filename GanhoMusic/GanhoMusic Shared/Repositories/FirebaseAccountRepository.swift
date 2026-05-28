//
//  FirebaseAccountRepository.swift
//  GanhoMusic Shared
//
//  Firebase Auth + Firestore 프로필 동기화 저장소.
//

import Foundation

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
import FirebaseAuth
import FirebaseFirestore
#endif

enum FirebaseAccountSyncResult: Equatable {
    case unavailable
    case failed(String)
    case synced(UserProfile)
}

enum FirebaseAuthMode: Equatable {
    case unavailable
    case signedOut
    case anonymous
    case personal
}

final class FirebaseAccountRepository {

    private let localProfileRepository: UserProfileRepository

    init(localProfileRepository: UserProfileRepository = UserProfileRepository()) {
        self.localProfileRepository = localProfileRepository
    }

    @discardableResult
    func bootstrapProfile() async -> FirebaseAccountSyncResult {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        FirebaseDiagnostics.info("Profile bootstrap started.")
        guard FirebaseBootstrap.configureIfAvailable() else { return .unavailable }
        do {
            let uid = try await signInAnonymouslyIfNeeded()
            let profile = try await syncProfile(uid: uid)
            localProfileRepository.replace(with: profile)
            FirebaseDiagnostics.info("Profile synced for uid=\(uid).")
            return .synced(profile)
        } catch {
            FirebaseDiagnostics.error("Profile sync failed.", error: error)
            return .failed(Self.userMessage(for: error))
        }
        #else
        FirebaseDiagnostics.error("FirebaseAuth or FirebaseFirestore module is not linked. Profile sync skipped.")
        return .unavailable
        #endif
    }

    func currentAuthMode() -> FirebaseAuthMode {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseBootstrap.configureIfAvailable() else { return .unavailable }
        guard let user = Auth.auth().currentUser else { return .signedOut }
        return user.isAnonymous ? .anonymous : .personal
        #else
        return .unavailable
        #endif
    }

    @discardableResult
    func signUpOrLinkEmail(email: String, password: String, nickname: String) async -> FirebaseAccountSyncResult {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseBootstrap.configureIfAvailable() else { return .unavailable }
        do {
            let normalizedNickname = UserProfileRepository.normalizedNickname(nickname)
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let user: User
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                do {
                    let result = try await currentUser.link(with: credential)
                    user = result.user
                } catch {
                    FirebaseDiagnostics.error("Anonymous email link failed. Falling back to email sign-in.", error: error)
                    let result = try await Auth.auth().signIn(with: credential)
                    user = result.user
                }
            } else {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                user = result.user
            }
            let profile = try await upsertProfile(
                uid: user.uid,
                nickname: normalizedNickname.isEmpty ? GameConfig.defaultNickname : normalizedNickname,
                email: user.email ?? email,
                isAnonymous: false
            )
            localProfileRepository.replace(with: profile)
            FirebaseDiagnostics.info("Email account ready uid=\(user.uid).")
            return .synced(profile)
        } catch {
            FirebaseDiagnostics.error("Email sign-up failed.", error: error)
            return .failed(Self.userMessage(for: error))
        }
        #else
        return .unavailable
        #endif
    }

    @discardableResult
    func signInEmail(email: String, password: String) async -> FirebaseAccountSyncResult {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseBootstrap.configureIfAvailable() else { return .unavailable }
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let profile = try await syncProfile(uid: result.user.uid)
            localProfileRepository.replace(with: profile)
            FirebaseDiagnostics.info("Email sign-in completed uid=\(result.user.uid).")
            return .synced(profile)
        } catch {
            FirebaseDiagnostics.error("Email sign-in failed.", error: error)
            return .failed(Self.userMessage(for: error))
        }
        #else
        return .unavailable
        #endif
    }

    @discardableResult
    func syncSignedInPersonalProfile(nickname: String?, email: String?) async -> FirebaseAccountSyncResult {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseBootstrap.configureIfAvailable(),
              let user = Auth.auth().currentUser else { return .unavailable }
        do {
            let profile = try await upsertProfile(
                uid: user.uid,
                nickname: nickname ?? localProfileRepository.current.nickname,
                email: email ?? user.email,
                isAnonymous: user.isAnonymous
            )
            localProfileRepository.replace(with: profile)
            return .synced(profile)
        } catch {
            FirebaseDiagnostics.error("Signed-in profile sync failed.", error: error)
            return .failed(Self.userMessage(for: error))
        }
        #else
        return .unavailable
        #endif
    }

    func signOutToGuest() async {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        do {
            try Auth.auth().signOut()
            _ = await bootstrapProfile()
        } catch {
            FirebaseDiagnostics.error("Sign-out failed.", error: error)
        }
        #endif
    }

    #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
    private func signInAnonymouslyIfNeeded() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid {
            FirebaseDiagnostics.info("Using existing anonymous user uid=\(uid).")
            return uid
        }
        FirebaseDiagnostics.info("Anonymous sign-in started.")
        let result = try await Auth.auth().signInAnonymously()
        FirebaseDiagnostics.info("Anonymous sign-in completed uid=\(result.user.uid).")
        return result.user.uid
    }

    private func syncProfile(uid: String) async throws -> UserProfile {
        let document = Firestore.firestore()
            .collection("profiles")
            .document(uid)
        FirebaseDiagnostics.info("Profile document read started uid=\(uid).")
        let snapshot = try await document.getDocument()

        if let data = snapshot.data(),
           let profile = makeProfile(uid: uid, data: data) {
            FirebaseDiagnostics.info("Existing profile loaded uid=\(uid).")
            return profile
        }

        let local = localProfileRepository.current
        let now = Date()
        let profile = UserProfile(
            id: uid,
            nickname: local.nickname,
            email: Auth.auth().currentUser?.email,
            photoURL: local.photoURL,
            localPhotoPath: local.localPhotoPath,
            selectedCharacterID: local.selectedCharacterID,
            isAnonymous: Auth.auth().currentUser?.isAnonymous ?? true,
            createdAt: now,
            updatedAt: now
        )
        var data: [String: Any] = [
            "nickname": profile.nickname,
            "isAnonymous": profile.isAnonymous,
            "createdAt": Timestamp(date: profile.createdAt),
            "updatedAt": Timestamp(date: profile.updatedAt)
        ]
        if let email = profile.email { data["email"] = email }
        if let photoURL = profile.photoURL { data["photoURL"] = photoURL }
        if let selectedCharacterID = profile.selectedCharacterID {
            data["selectedCharacterID"] = selectedCharacterID.rawValue
        }
        try await document.setData(data, merge: true)
        FirebaseDiagnostics.info("New profile created uid=\(uid).")
        return profile
    }

    private func makeProfile(uid: String, data: [String: Any]) -> UserProfile? {
        guard let nickname = data["nickname"] as? String else { return nil }
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
        return UserProfile(
            id: uid,
            nickname: nickname,
            email: data["email"] as? String,
            photoURL: data["photoURL"] as? String,
            localPhotoPath: localProfileRepository.current.localPhotoPath,
            selectedCharacterID: (data["selectedCharacterID"] as? String).flatMap(CharacterID.init(rawValue:)),
            isAnonymous: data["isAnonymous"] as? Bool ?? (Auth.auth().currentUser?.isAnonymous ?? true),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func upsertProfile(uid: String,
                               nickname: String,
                               email: String?,
                               isAnonymous: Bool) async throws -> UserProfile {
        let document = Firestore.firestore()
            .collection("profiles")
            .document(uid)
        let snapshot = try await document.getDocument()
        let now = Date()
        let existing = snapshot.data().flatMap { makeProfile(uid: uid, data: $0) }
        let local = localProfileRepository.current
        let createdAt = existing?.createdAt ?? now
        let profile = UserProfile(
            id: uid,
            nickname: nickname.isEmpty ? (existing?.nickname ?? GameConfig.defaultNickname) : nickname,
            email: email ?? existing?.email,
            photoURL: existing?.photoURL ?? local.photoURL,
            localPhotoPath: local.localPhotoPath,
            selectedCharacterID: existing?.selectedCharacterID ?? local.selectedCharacterID,
            isAnonymous: isAnonymous,
            createdAt: createdAt,
            updatedAt: now
        )
        var data: [String: Any] = [
            "nickname": profile.nickname,
            "isAnonymous": profile.isAnonymous,
            "createdAt": Timestamp(date: profile.createdAt),
            "updatedAt": Timestamp(date: profile.updatedAt)
        ]
        if let email = profile.email { data["email"] = email }
        if let photoURL = profile.photoURL { data["photoURL"] = photoURL }
        if let selectedCharacterID = profile.selectedCharacterID {
            data["selectedCharacterID"] = selectedCharacterID.rawValue
        }
        try await document.setData(data, merge: true)
        return profile
    }

    private static func userMessage(for error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case 17006:
            return "Firebase 콘솔에서 이메일/비밀번호 로그인을 켜야 해요."
        case 17007:
            return "이미 가입된 이메일이에요. 로그인으로 들어가 주세요."
        case 17008, 17034:
            return "이메일 주소를 정확히 입력해 주세요."
        case 17009:
            return "비밀번호가 맞지 않아요."
        case 17011:
            return "가입된 계정을 찾지 못했어요."
        case 17020:
            return "네트워크 연결을 확인해 주세요."
        case 17026:
            return "비밀번호는 6자 이상이어야 해요."
        default:
            return "계정 처리에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }
    #endif
}
