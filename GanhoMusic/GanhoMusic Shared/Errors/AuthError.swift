//
//  AuthError.swift
//  GanhoMusic Shared
//
//  Firebase/Apple 로그인 플로우에서 앱을 중단하지 않고 탈출하기 위한 얇은 오류 타입.
//

import Foundation

enum AuthError: Error {
    case nonceGenerationFailed
    case appleAuthorizationAlreadyInProgress
    case appleCredentialMissing
    case appleIdentityTokenMissing
    case appleIdentityTokenInvalid
    case appleAuthorizationCodeMissing
    case appleAuthorizationTimedOut
    case appleConfigurationFailed
    case appleCredentialRejected
    /// R9 U1 — 서버가 이미 소비한 credential 재사용 거절 (missingOrInvalidNonce 17094).
    /// 재로그인 유저의 link→signIn 폴백 경로에서 발생 — "한 번 더" 전용 카피 분기.
    case appleCredentialAlreadyConsumed
    /// R9 U1 — 네트워크 단절 (networkError 17020). 네트워크 전용 카피 분기.
    case networkUnavailable
    case presentationAnchorMissing
    case accountDeleteFailed
    case accountReauthenticationFailed
}
