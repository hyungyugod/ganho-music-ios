//
//  GameScene+MovementInput.swift
//  GanhoMusic Shared
//
//  D-Pad 아날로그 입력 보간과 이동 입력 리셋을 분리한다.
//

import SpriteKit

// MARK: - Movement Input
extension GameScene {
    func resetMovementInput() {
        smoothedMoveDirection = .zero
        player.currentDirection = .zero
    }

    func updateSmoothedMovementInput(deltaTime dt: TimeInterval) {
        let target = dpad.currentDirection
        let isStartingInput = isZeroVector(smoothedMoveDirection) && isZeroVector(target) == false
        let response: CGFloat
        let adjustedTarget: CGVector

        if isZeroVector(target) {
            response = GameConfig.dpadInputReleaseResponse
            adjustedTarget = .zero
        } else if isStartingInput {
            response = GameConfig.dpadInputInitialResponse
            adjustedTarget = initialBoostedVector(from: target)
        } else {
            response = GameConfig.dpadInputTurnResponse
            adjustedTarget = target
        }

        smoothedMoveDirection = interpolatedVector(
            from: smoothedMoveDirection,
            to: adjustedTarget,
            response: response,
            dt: dt
        )
        player.currentDirection = smoothedMoveDirection
    }

    private func initialBoostedVector(from target: CGVector) -> CGVector {
        let length = hypot(target.dx, target.dy)
        guard length >= GameConfig.dpadInputSnapEpsilon else { return .zero }

        let magnitude = max(length, GameConfig.dpadInputInitialMagnitude)
        return CGVector(
            dx: target.dx / length * magnitude,
            dy: target.dy / length * magnitude
        )
    }

    private func interpolatedVector(from current: CGVector,
                                    to target: CGVector,
                                    response: CGFloat,
                                    dt: TimeInterval) -> CGVector {
        let t = min(1, response * CGFloat(dt))
        let next = CGVector(
            dx: current.dx + (target.dx - current.dx) * t,
            dy: current.dy + (target.dy - current.dy) * t
        )
        guard hypot(next.dx, next.dy) >= GameConfig.dpadInputSnapEpsilon else {
            return .zero
        }
        return next
    }

    private func isZeroVector(_ vector: CGVector) -> Bool {
        return hypot(vector.dx, vector.dy) < GameConfig.dpadInputSnapEpsilon
    }
}
