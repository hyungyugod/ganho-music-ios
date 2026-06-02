//
//  CloudScoreRecord.swift
//  GanhoMusic Shared
//
//  Firestore와 pending queue에 저장할 한 판 점수 값 객체.
//

import Foundation

struct CloudScoreRecord: Codable {
    let localID: String
    let characterID: String
    let difficulty: String
    let score: Int
    let maxCombo: Int
    let airforceTriggered: Bool
    let playedAt: Date
}
