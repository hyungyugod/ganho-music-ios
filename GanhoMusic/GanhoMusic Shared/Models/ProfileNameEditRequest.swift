//
//  ProfileNameEditRequest.swift
//  GanhoMusic Shared
//
//  SpriteKit 프로필 오버레이와 UIKit 텍스트 입력 브리지의 Notification payload.
//

import Foundation

extension Notification.Name {
    static let ganhoProfileNameEditRequested = Notification.Name("ganhoProfileNameEditRequested")
    static let ganhoProfileNameEditDidFinish = Notification.Name("ganhoProfileNameEditDidFinish")
}

struct ProfileNameEditRequest {

    // MARK: - Properties
    let displayName: String?
    let nickname: String?
    let isNicknameRequired: Bool

    var userInfo: [String: Any] {
        var info: [String: Any] = [
            GameConfig.profileNameEditRequiredUserInfoKey: isNicknameRequired
        ]
        if let displayName = displayName {
            info[GameConfig.profileNameEditDisplayNameUserInfoKey] = displayName
        }
        if let nickname = nickname {
            info[GameConfig.profileNameEditNicknameUserInfoKey] = nickname
        }
        return info
    }

    // MARK: - Init
    init(displayName: String?,
         nickname: String?,
         isNicknameRequired: Bool) {
        self.displayName = displayName
        self.nickname = nickname
        self.isNicknameRequired = isNicknameRequired
    }

    init?(notification: Notification) {
        guard let required = notification.userInfo?[GameConfig.profileNameEditRequiredUserInfoKey] as? Bool else {
            return nil
        }
        displayName = notification.userInfo?[GameConfig.profileNameEditDisplayNameUserInfoKey] as? String
        nickname = notification.userInfo?[GameConfig.profileNameEditNicknameUserInfoKey] as? String
        isNicknameRequired = required
    }
}

struct ProfileNameEditResult {

    // MARK: - Properties
    let didSave: Bool
    let wasNicknameRequired: Bool

    var userInfo: [String: Any] {
        return [
            GameConfig.profileNameEditSucceededUserInfoKey: didSave,
            GameConfig.profileNameEditRequiredUserInfoKey: wasNicknameRequired
        ]
    }

    // MARK: - Init
    init(didSave: Bool, wasNicknameRequired: Bool) {
        self.didSave = didSave
        self.wasNicknameRequired = wasNicknameRequired
    }

    init?(notification: Notification) {
        guard let didSave = notification.userInfo?[GameConfig.profileNameEditSucceededUserInfoKey] as? Bool,
              let required = notification.userInfo?[GameConfig.profileNameEditRequiredUserInfoKey] as? Bool else {
            return nil
        }
        self.didSave = didSave
        wasNicknameRequired = required
    }
}
