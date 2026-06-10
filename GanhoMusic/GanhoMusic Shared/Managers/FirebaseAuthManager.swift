//
//  FirebaseAuthManager.swift
//  GanhoMusic Shared
//
//  Firebase 익명 세션, Apple Sign In, Auth 상태 요약 저장을 담당한다.
//

import AuthenticationServices
import CryptoKit
import Foundation
import FirebaseAuth
import OSLog
import Security

extension Notification.Name {
    static let ganhoAuthProfileDidChange = Notification.Name("ganhoAuthProfileDidChange")
}

enum AccountActionResult {
    case success
    case cancelled
    case failure(AuthError?)
}

extension User: FirebaseAuthUserProviding {
    var providerIDs: [String] {
        return providerData.map { $0.providerID }
    }
}

@MainActor
final class FirebaseAuthManager: NSObject {

    // MARK: - Properties
    static let shared = FirebaseAuthManager()

    private let profileRepository = AuthProfileRepository()
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleContinuation: CheckedContinuation<AppleAuthorizationPayload, Error>?
    private var applePresentationProvider: ApplePresentationContextProvider?
    private var appleAuthorizationController: ASAuthorizationController?
    private var appleTimeoutTask: Task<Void, Never>?
    private var appleAuthorizationFlowID: UUID?
    private var hasReceivedInitialAuthState = false
    private var initialAuthContinuations: [CheckedContinuation<AuthProfileSnapshot?, Never>] = []
    private let logger = Logger(subsystem: "GanhoMusic", category: "AuthProfile")

    // MARK: - Auth State
    func startObserving() {
        guard authListenerHandle == nil else { return }
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.profileRepository.save(user: user)
            } else {
                self.profileRepository.clear()
            }
            self.resolveInitialAuthStateIfNeeded()
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
        }
    }

    func waitForInitialAuthState() async -> AuthProfileSnapshot? {
        startObserving()
        if hasReceivedInitialAuthState {
            return profileRepository.current
        }

        return await withCheckedContinuation { continuation in
            if hasReceivedInitialAuthState {
                continuation.resume(returning: profileRepository.current)
            } else {
                initialAuthContinuations.append(continuation)
            }
        }
    }

    func ensureLaunchSession() async -> User? {
        _ = await waitForInitialAuthState()
        return await ensureAnonymousSession()
    }

    func ensureAnonymousSession() async -> User? {
        if let user = Auth.auth().currentUser {
            profileRepository.save(user: user)
            return user
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            profileRepository.save(user: result.user)
            return result.user
        } catch {
            return nil
        }
    }

    private func resolveInitialAuthStateIfNeeded() {
        guard !hasReceivedInitialAuthState else { return }
        hasReceivedInitialAuthState = true
        let snapshot = profileRepository.current
        let continuations = initialAuthContinuations
        initialAuthContinuations.removeAll()
        continuations.forEach { continuation in
            continuation.resume(returning: snapshot)
        }
    }

    // MARK: - Apple Sign In
    @discardableResult
    func signInWithApple(presentationAnchor: ASPresentationAnchor) async -> AccountActionResult {
        guard appleAuthorizationFlowID == nil else {
            return .failure(.appleAuthorizationAlreadyInProgress)
        }
        let flowID = UUID()
        appleAuthorizationFlowID = flowID
        defer { clearAppleFlowStateIfOwned(by: flowID) }

        do {
            let rawNonce = try NonceGenerator.randomNonceString()
            currentNonce = rawNonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = SHA256Hasher.sha256(rawNonce)

            let payload = try await performAppleAuthorization(request: request, anchor: presentationAnchor)
            let credential = OAuthProvider.appleCredential(
                withIDToken: payload.idTokenString,
                rawNonce: payload.rawNonce,
                fullName: payload.fullName
            )

            let user = try await signInOrLinkAppleCredential(credential)
            profileRepository.save(user: user)
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            return .success
        } catch {
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            if isUserCancellation(error) {
                return .cancelled
            }
            return .failure(authError(from: error))
        }
    }

    // MARK: - Account Actions
    func updateProfileName(displayName: String?,
                           nickname: String?,
                           isNicknameRequired: Bool = false) async -> AccountActionResult {
        guard let user = await currentUserForProfileEdit() else {
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            return .failure(nil)
        }

        let sanitizedNickname = sanitizedOptionalText(nickname)
        guard isValidNickname(sanitizedNickname, isRequired: isNicknameRequired) else {
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            return .failure(nil)
        }

        let sanitizedDisplayName = sanitizedOptionalText(displayName)
        await commitFirebaseDisplayNameIfNeeded(user: user, displayName: sanitizedDisplayName)

        let snapshot = profileRepository.saveProfile(
            uid: user.uid,
            isAnonymous: user.isAnonymous,
            displayName: sanitizedDisplayName,
            nickname: sanitizedNickname,
            providerIDs: user.providerData.map { $0.providerID }
        )
        NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)

        do {
            try await CloudProgressRepository().saveProfile(profile: snapshot)
        } catch {
            logger.warning("Profile cloud sync deferred after local save: \(error.localizedDescription, privacy: .public)")
        }
        return .success
    }

    private func currentUserForProfileEdit() async -> User? {
        if let user = Auth.auth().currentUser {
            return user
        }
        return await ensureAnonymousSession()
    }

    private func commitFirebaseDisplayNameIfNeeded(user: User, displayName: String?) async {
        let currentDisplayName = sanitizedOptionalText(user.displayName)
        guard displayName != currentDisplayName else { return }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        do {
            try await changeRequest.commitChanges()
        } catch {
            logger.warning("Firebase displayName update deferred: \(error.localizedDescription, privacy: .public)")
        }
    }

    func signOutToGuestSession() async -> AccountActionResult {
        do {
            try Auth.auth().signOut()
            clearLocalAccountState()
            return await finishAccountActionWithGuestSession()
        } catch {
            return .failure(nil)
        }
    }

    func deleteCurrentAccount(presentationAnchor: ASPresentationAnchor) async -> AccountActionResult {
        guard let user = Auth.auth().currentUser else {
            return await finishAccountActionWithGuestSession()
        }

        let uid = user.uid
        let isAppleLinked = user.providerData.contains { provider in
            provider.providerID == StorageKeys.authAppleProviderID
        }

        do {
            var authorizationCode: String?
            if isAppleLinked {
                let payload = try await requestAppleAuthorizationForSensitiveAction(anchor: presentationAnchor)
                let credential = OAuthProvider.appleCredential(
                    withIDToken: payload.idTokenString,
                    rawNonce: payload.rawNonce,
                    fullName: nil
                )
                try await user.reauthenticate(with: credential)
                guard let authorizationCodeString = payload.authorizationCodeString else {
                    throw AuthError.appleAuthorizationCodeMissing
                }
                authorizationCode = authorizationCodeString
            }

            try await CloudProgressRepository().deleteUserData(uid: uid)

            if let authorizationCode = authorizationCode {
                try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
            }

            try await user.delete()
            clearLocalAccountState()
            return await finishAccountActionWithGuestSession()
        } catch {
            if isUserCancellation(error) {
                return .cancelled
            }
            return .failure(authError(from: error))
        }
    }

    private func performAppleAuthorization(request: ASAuthorizationAppleIDRequest,
                                           anchor: ASPresentationAnchor) async throws -> AppleAuthorizationPayload {
        try await withCheckedThrowingContinuation { continuation in
            guard appleContinuation == nil else {
                continuation.resume(throwing: AuthError.appleAuthorizationAlreadyInProgress)
                return
            }
            appleContinuation = continuation
            let presentationProvider = ApplePresentationContextProvider(anchor: anchor)
            applePresentationProvider = presentationProvider
            let controller = ASAuthorizationController(authorizationRequests: [request])
            appleAuthorizationController = controller
            controller.delegate = self
            controller.presentationContextProvider = presentationProvider
            startAppleAuthorizationTimeout()
            controller.performRequests()
        }
    }

    private func signInOrLinkAppleCredential(_ credential: AuthCredential) async throws -> User {
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            do {
                let result = try await currentUser.link(with: credential)
                return result.user
            } catch {
                guard shouldFallbackToSignIn(afterLinkError: error) else { throw error }
                let result = try await Auth.auth().signIn(with: credential)
                return result.user
            }
        }

        let result = try await Auth.auth().signIn(with: credential)
        return result.user
    }

    private func shouldFallbackToSignIn(afterLinkError error: Error) -> Bool {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        return code == .credentialAlreadyInUse
            || code == .accountExistsWithDifferentCredential
            || code == .providerAlreadyLinked
    }

    private func requestAppleAuthorizationForSensitiveAction(anchor: ASPresentationAnchor) async throws -> AppleAuthorizationPayload {
        guard appleAuthorizationFlowID == nil else {
            throw AuthError.appleAuthorizationAlreadyInProgress
        }
        let flowID = UUID()
        appleAuthorizationFlowID = flowID
        defer { clearAppleFlowStateIfOwned(by: flowID) }

        let rawNonce = try NonceGenerator.randomNonceString()
        currentNonce = rawNonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.nonce = SHA256Hasher.sha256(rawNonce)
        return try await performAppleAuthorization(request: request, anchor: anchor)
    }

    private func clearLocalAccountState() {
        profileRepository.clear()
        PendingCloudScoreRepository().clear()
    }

    private func finishAccountActionWithGuestSession() async -> AccountActionResult {
        guard await ensureAnonymousSession() != nil else {
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            return .failure(nil)
        }

        NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
        return .success
    }

    private func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == ASAuthorizationError.errorDomain else { return false }
        return ASAuthorizationError.Code(rawValue: nsError.code) == .canceled
    }

    private func authError(from error: Error) -> AuthError? {
        if let authError = error as? AuthError {
            return authError
        }
        let nsError = error as NSError
        guard let firebaseCode = AuthErrorCode(rawValue: nsError.code) else { return nil }
        return AuthErrorMapper.appleAuthError(from: firebaseCode)
    }

    private func clearAppleFlowStateIfOwned(by flowID: UUID) {
        guard appleAuthorizationFlowID == flowID else { return }
        clearAppleFlowState()
    }

    private func clearAppleFlowState() {
        appleTimeoutTask?.cancel()
        appleTimeoutTask = nil
        currentNonce = nil
        appleContinuation = nil
        applePresentationProvider = nil
        appleAuthorizationController = nil
        appleAuthorizationFlowID = nil
    }

    private func startAppleAuthorizationTimeout() {
        appleTimeoutTask?.cancel()
        let timeoutNanoseconds = UInt64(
            StorageKeys.authAppleRequestTimeout * Double(StorageKeys.nanosecondsPerSecond)
        )
        appleTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: timeoutNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.finishAppleAuthorization(
                    with: .failure(AuthError.appleAuthorizationTimedOut)
                )
            }
        }
    }

    private func finishAppleAuthorization(with result: Result<AppleAuthorizationPayload, Error>) {
        guard let continuation = appleContinuation else { return }
        appleContinuation = nil
        appleTimeoutTask?.cancel()
        appleTimeoutTask = nil
        appleAuthorizationController = nil
        applePresentationProvider = nil
        currentNonce = nil
        continuation.resume(with: result)
    }

    private func sanitizedOptionalText(_ text: String?) -> String? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed = trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func isValidNickname(_ text: String?,
                                 isRequired: Bool) -> Bool {
        guard let text = text else { return !isRequired }
        return text.count >= StorageKeys.profileNicknameMinLength
            && text.count <= StorageKeys.profileNicknameMaxLength
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension FirebaseAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let rawNonce = currentNonce else {
            finishAppleAuthorization(with: .failure(AuthError.nonceGenerationFailed))
            return
        }
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finishAppleAuthorization(with: .failure(AuthError.appleCredentialMissing))
            return
        }
        guard let identityToken = appleCredential.identityToken else {
            finishAppleAuthorization(with: .failure(AuthError.appleIdentityTokenMissing))
            return
        }
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            finishAppleAuthorization(with: .failure(AuthError.appleIdentityTokenInvalid))
            return
        }
        let authorizationCodeString: String?
        if let authorizationCode = appleCredential.authorizationCode {
            authorizationCodeString = String(data: authorizationCode, encoding: .utf8)
        } else {
            authorizationCodeString = nil
        }

        let payload = AppleAuthorizationPayload(
            idTokenString: tokenString,
            authorizationCodeString: authorizationCodeString,
            rawNonce: rawNonce,
            fullName: appleCredential.fullName
        )
        finishAppleAuthorization(with: .success(payload))
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        finishAppleAuthorization(with: .failure(error))
    }
}

// MARK: - Apple Presentation
private final class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return anchor
    }
}

// MARK: - Apple Payload
private struct AppleAuthorizationPayload {
    let idTokenString: String
    let authorizationCodeString: String?
    let rawNonce: String
    let fullName: PersonNameComponents?
}

// MARK: - Firebase Auth Error Mapping
private enum AuthErrorMapper {
    static func appleAuthError(from code: AuthErrorCode) -> AuthError? {
        switch code {
        case .operationNotAllowed:
            return .appleConfigurationFailed
        case .invalidCredential,
             .credentialAlreadyInUse,
             .accountExistsWithDifferentCredential,
             .providerAlreadyLinked:
            return .appleCredentialRejected
        default:
            return nil
        }
    }
}

// MARK: - Nonce
private enum NonceGenerator {
    static func randomNonceString() throws -> String {
        let characters = Array(StorageKeys.authNonceCharacterSet)
        var randomBytes = [UInt8](repeating: 0, count: StorageKeys.authNonceLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else { throw AuthError.nonceGenerationFailed }

        let nonce = randomBytes.map { byte -> Character in
            let index = Int(byte) % characters.count
            return characters[index]
        }
        return String(nonce)
    }
}

private enum SHA256Hasher {
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}
