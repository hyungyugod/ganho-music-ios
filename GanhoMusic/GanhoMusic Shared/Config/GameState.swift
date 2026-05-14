//
//  GameState.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//  Phase 6-13 · `.countdown` case 추가 — 3→2→1→GO! 진행 중 모든 시스템 정지 상태
//

import Foundation

/// 게임 진행 상태. update() 루프 분기 및 씬 전환 가드에 사용.
enum GameState {
    case waiting    // 시작 전 / 인트로
    case countdown  // Phase 6-13 — 3→2→1→GO! 진행 중. update의 모든 시스템(스폰/타이머/이동/카메라/적/콤보 폴링) 정지.
    case playing    // 진행 중
    case paused     // 일시정지 (Phase 3+)
    case gameOver   // 종료
}
