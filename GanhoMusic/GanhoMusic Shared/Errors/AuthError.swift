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
    case presentationAnchorMissing
    case accountDeleteFailed
    case accountReauthenticationFailed
}
