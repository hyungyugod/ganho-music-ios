//
//  AuthProfileSnapshot.swift
//  GanhoMusic Shared
//
//  FirebaseAuth 세션에서 UI 표시와 로컬 복원에 필요한 비민감 요약만 보관한다.
//

import Foundation

struct AuthProfileSnapshot: Codable {
    let uid: String
    let isAnonymous: Bool
    let displayName: String?
    let providerIDs: [String]
    let updatedAt: Date
}
