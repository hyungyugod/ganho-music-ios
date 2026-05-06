//
//  GameState.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//

import Foundation

/// 게임 진행 상태. update() 루프 분기 및 씬 전환 가드에 사용.
enum GameState {
    case waiting    // 시작 전 / 인트로
    case playing    // 진행 중
    case paused     // 일시정지 (Phase 3+)
    case gameOver   // 종료
}
