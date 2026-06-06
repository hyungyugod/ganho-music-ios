//
//  GameScene+MovementInput.swift
//  GanhoMusic Shared
//
//  D-Pad 입력 전달, 이동 입력 리셋, 벽 충돌 조회를 분리한다.
//

import SpriteKit

// MARK: - Movement Input
extension GameScene {
    func resetMovementInput() {
        smoothedMoveDirection = .zero
        player.currentDirection = .zero
    }

    func updateMovementInput() {
        let target = dpad.currentDirection
        guard isZeroVector(target) == false else {
            resetMovementInput()
            return
        }
        smoothedMoveDirection = target
        player.currentDirection = smoothedMoveDirection
    }

    private func isZeroVector(_ vector: CGVector) -> Bool {
        return hypot(vector.dx, vector.dy) < GameConfig.dpadInputSnapEpsilon
    }
}

// MARK: - Wall Collision Query
extension GameScene {
    func containsWall(in rect: CGRect) -> Bool {
        return wallRects(intersecting: rect).isEmpty == false
    }

    func wallRects(intersecting rect: CGRect) -> [CGRect] {
        var rects: [CGRect] = []
        var hit = false
        physicsWorld.enumerateBodies(in: rect) { body, stop in
            guard body.categoryBitMask & PhysicsCategory.wall != 0 else { return }
            guard let node = body.node,
                  let wallRect = self.wallRect(for: node),
                  wallRect.intersects(rect) else {
                return
            }
            rects.append(wallRect)
            hit = true
            stop.pointee = false
        }
        if hit == false {
            return []
        }
        return rects
    }

    private func wallRect(for node: SKNode) -> CGRect? {
        if let tile = node as? WallTileNode {
            let center = tile.parent?.convert(tile.position, to: self) ?? tile.position
            return CGRect(
                x: center.x - tile.size.width / 2,
                y: center.y - tile.size.height / 2,
                width: tile.size.width,
                height: tile.size.height
            )
        }

        guard let parent = node.parent else { return nil }
        let frame = node.calculateAccumulatedFrame()
        let minPoint = parent.convert(frame.origin, to: self)
        let maxPoint = parent.convert(
            CGPoint(x: frame.maxX, y: frame.maxY),
            to: self
        )
        return CGRect(
            x: min(minPoint.x, maxPoint.x),
            y: min(minPoint.y, maxPoint.y),
            width: abs(maxPoint.x - minPoint.x),
            height: abs(maxPoint.y - minPoint.y)
        )
    }
}
