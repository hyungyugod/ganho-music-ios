//
//  UserProfile.swift
//  GanhoMusic Shared
//
//  로컬/서버 계정 프로필 값 객체.
//

import Foundation

/// 사용자를 식별하고 기록 화면을 개인화하기 위한 최소 프로필.
struct UserProfile: Codable, Equatable {
    var id: String
    var nickname: String
    var email: String?
    var photoURL: String?
    var localPhotoPath: String?
    var selectedCharacterID: CharacterID?
    var isAnonymous: Bool
    var createdAt: Date
    var updatedAt: Date

    var recordTitle: String {
        return "\(nickname)님의 기록"
    }

    static func makeGuest(now: Date = Date()) -> UserProfile {
        return UserProfile(
            id: UUID().uuidString,
            nickname: GameConfig.defaultNickname,
            email: nil,
            photoURL: nil,
            localPhotoPath: nil,
            selectedCharacterID: nil,
            isAnonymous: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
