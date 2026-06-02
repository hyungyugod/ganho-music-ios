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
import Security

extension Notification.Name {
    static let ganhoAuthProfileDidChange = Notification.Name("ganhoAuthProfileDidChange")
}

enum AccountActionResult {
    case success
    case cancelled
    case failure
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
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
        }
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

    // MARK: - Apple Sign In
    @discardableResult
    func signInWithApple(presentationAnchor: ASPresentationAnchor) async -> AccountActionResult {
        do {
            let rawNonce = try NonceGenerator.randomNonceString()
            currentNonce = rawNonce
            defer { clearAppleFlowState() }

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
            clearAppleFlowState()
            NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
            if isUserCancellation(error) {
                return .cancelled
            }
            return .failure
        }
    }

    // MARK: - Account Actions
    func signOutToGuestSession() async -> AccountActionResult {
        do {
            try Auth.auth().signOut()
            clearLocalAccountState()
            return await finishAccountActionWithGuestSession()
        } catch {
            return .failure
        }
    }

    func deleteCurrentAccount(presentationAnchor: ASPresentationAnchor) async -> AccountActionResult {
        guard let user = Auth.auth().currentUser else {
            return await finishAccountActionWithGuestSession()
        }

        let uid = user.uid
        let isAppleLinked = user.providerData.contains { provider in
            provider.providerID == GameConfig.authAppleProviderID
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
            return .failure
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
            controller.delegate = self
            controller.presentationContextProvider = presentationProvider
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
        let rawNonce = try NonceGenerator.randomNonceString()
        currentNonce = rawNonce
        defer { clearAppleFlowState() }

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
            return .failure
        }

        NotificationCenter.default.post(name: .ganhoAuthProfileDidChange, object: nil)
        return .success
    }

    private func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == ASAuthorizationError.errorDomain else { return false }
        return ASAuthorizationError.Code(rawValue: nsError.code) == .canceled
    }

    private func clearAppleFlowState() {
        currentNonce = nil
        appleContinuation = nil
        applePresentationProvider = nil
    }

    private func finishAppleAuthorization(with result: Result<AppleAuthorizationPayload, Error>) {
        guard let continuation = appleContinuation else { return }
        appleContinuation = nil
        continuation.resume(with: result)
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

// MARK: - Nonce
private enum NonceGenerator {
    static func randomNonceString() throws -> String {
        let characters = Array(GameConfig.authNonceCharacterSet)
        var randomBytes = [UInt8](repeating: 0, count: GameConfig.authNonceLength)
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
