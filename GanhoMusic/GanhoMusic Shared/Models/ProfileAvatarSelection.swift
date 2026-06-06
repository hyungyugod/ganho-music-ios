//
//  ProfileAvatarSelection.swift
//  GanhoMusic Shared
//
//  계정별 대표 프로필 이미지 선택 값 객체.
//

import Foundation

enum ProfileAvatarID: String, Codable, CaseIterable {
    case kim
    case jung
    case geon
    case im
    case lee
    case customPhoto

    var characterID: CharacterID? {
        switch self {
        case .kim:
            return .kim
        case .jung:
            return .jung
        case .geon:
            return .geon
        case .im:
            return .im
        case .lee:
            return .lee
        case .customPhoto:
            return nil
        }
    }

    init(characterID: CharacterID) {
        switch characterID {
        case .kim:
            self = .kim
        case .jung:
            self = .jung
        case .geon:
            self = .geon
        case .im:
            self = .im
        case .lee:
            self = .lee
        }
    }
}

struct ProfileAvatarSnapshot: Codable {
    let selectedID: ProfileAvatarID
    let customPhotoFileName: String?
    let updatedAt: Date

    static var defaultKim: ProfileAvatarSnapshot {
        return ProfileAvatarSnapshot(
            selectedID: .kim,
            customPhotoFileName: nil,
            updatedAt: Date()
        )
    }
}
