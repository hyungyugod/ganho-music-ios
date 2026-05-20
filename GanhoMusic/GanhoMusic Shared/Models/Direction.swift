//
//  Direction.swift
//  GanhoMusic Shared
//
//  Sprint 7 Phase G · 플레이어 4방향 입력 layer
//
//  PixelDirection(텍스처 갱신용 — down/up/left/right)과 분리된 *입력 의도* 타입.
//  DPadNode 입력 → PlayerNode.facing(_:) 위임에만 쓰인다. 게임 로직 분기 0.
//

import CoreGraphics

/// 4방향 입력 의도. PlayerNode.facing(_:)이 받아 시각 child 토글에 사용.
/// PixelDirection(texture 갱신용)과 분리 — Direction은 *입력 layer* 전용.
///
/// 좌표 약속:
///   - dx > 0 → .right
///   - dx < 0 → .left
///   - dy > 0 → .back  (SpriteKit +y = 위 = 캐릭터 뒷모습)
///   - dy < 0 → .front (SpriteKit -y = 아래 = 카메라 정면)
///   - .zero  → nil    (호출자가 정지 시 유지 처리)
/// 대각선 입력은 |dx| ≥ |dy| 우선 좌우 분기. DPadNode.updateDirection 알고리즘과 일관.
enum Direction: String {
    case front, back, left, right

    /// DPad currentDirection(단위 벡터)을 Direction으로 변환.
    /// .zero(거의 0 — 임계값 0.001) 입력은 nil 반환 → 호출자가 자연 noop 처리(정지 시 유지).
    /// - Parameter vector: dx/dy 단위 벡터(보통 |1|). 임계값 미만이면 nil.
    init?(vector: CGVector) {
        if abs(vector.dx) < 0.001 && abs(vector.dy) < 0.001 { return nil }
        if abs(vector.dx) >= abs(vector.dy) {
            self = vector.dx >= 0 ? .right : .left
        } else {
            self = vector.dy >= 0 ? .back : .front
        }
    }
}
