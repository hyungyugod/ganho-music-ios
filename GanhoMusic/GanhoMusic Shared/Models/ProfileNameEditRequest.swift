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
            UILayout.profileNameEditRequiredUserInfoKey: isNicknameRequired
        ]
        if let displayName = displayName {
            info[UILayout.profileNameEditDisplayNameUserInfoKey] = displayName
        }
        if let nickname = nickname {
            info[UILayout.profileNameEditNicknameUserInfoKey] = nickname
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
        guard let required = notification.userInfo?[UILayout.profileNameEditRequiredUserInfoKey] as? Bool else {
            return nil
        }
        displayName = notification.userInfo?[UILayout.profileNameEditDisplayNameUserInfoKey] as? String
        nickname = notification.userInfo?[UILayout.profileNameEditNicknameUserInfoKey] as? String
        isNicknameRequired = required
    }
}

struct ProfileNameEditResult {

    // MARK: - Properties
    let didSave: Bool
    let wasNicknameRequired: Bool

    var userInfo: [String: Any] {
        return [
            UILayout.profileNameEditSucceededUserInfoKey: didSave,
            UILayout.profileNameEditRequiredUserInfoKey: wasNicknameRequired
        ]
    }

    // MARK: - Init
    init(didSave: Bool, wasNicknameRequired: Bool) {
        self.didSave = didSave
        self.wasNicknameRequired = wasNicknameRequired
    }

    init?(notification: Notification) {
        guard let didSave = notification.userInfo?[UILayout.profileNameEditSucceededUserInfoKey] as? Bool,
              let required = notification.userInfo?[UILayout.profileNameEditRequiredUserInfoKey] as? Bool else {
            return nil
        }
        self.didSave = didSave
        wasNicknameRequired = required
    }
}
