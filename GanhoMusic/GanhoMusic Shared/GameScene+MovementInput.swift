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
        return hypot(vector.dx, vector.dy) < GameplayTuning.dpadInputSnapEpsilon
    }
}

#if DEBUG
// MARK: - R7 Demo Autopilot (시각 증빙 전용 — 릴리즈 미포함)
/// env 플래그 1회 평가 캐시 + 데모 전용 수치 — update 경로 매 프레임 environment dict 생성 방지.
private enum DemoAutopilot {
    static let isEnabled =
        ProcessInfo.processInfo.environment["GANHO_DEMO_AUTOPILOT"] == "1"
    /// 회피 행동 진입 거리 (pt). 이 거리 안의 접근 투사체에 '스침 회피' 기동 — 대역 확보 여유.
    static let dodgeTriggerDistance: CGFloat = 80
    /// 투사체 속도 유효 하한 (pt/s). 정지 투사체(이론상 없음)는 회피 대상 제외.
    static let minThreatSpeed: CGFloat = 1
    /// 스침 대역 내측 한계 (pt). 경로 중심선과의 측면 거리 < 이 값이면 수직으로 밀어낸다.
    /// 비접촉 통과가 가능한 측면 오프셋(세로 코리도 |dy| ≥ 18) 바깥 + near-miss 셸(R8:
    /// 히트박스 가장자리 10px — 세로 18~28px 대역) 안. 구 22px 중심거리보다 대역이 넓어져
    /// 기존 19~21.5 기동 수치는 무변경으로 더 안정 발화.
    static let grazeBandInner: CGFloat = 19
    /// 스침 대역 외측 한계 (pt). 측면 거리 ≤ 이 값이면 역평행 주행 — 대역 유지.
    static let grazeBandOuter: CGFloat = 21.5
    /// 수직 밀어내기 입력 크기 (0~1). 풀스피드(≈4px/frame)는 2.5px 대역을 건너뜀 —
    /// 아날로그 입력 크기가 속도에 비례(PlayerNode velocity = direction × speed)함을 이용해
    /// ≈1px/frame로 감속, 대역에 정밀 안착.
    static let dodgePushScale: CGFloat = 0.25
}

extension GameScene {
    /// GANHO_DEMO_AUTOPILOT=1 — 위협 투사체 수직 회피 + 평시 최근접 음표 주행.
    /// simctl 터치 주입 불가 제약에서 인게임 콤보 게이지(F3)·near-miss(F2) 캡처 전용
    /// (GANHO_SKIP_CUTSCENE 전례 동형). 수직 회피는 숙련 플레이어의 '스침 회피'를 재현 —
    /// near-miss 판정(히트박스 가장자리 10px 셸 진입→이탈 — R8 retune)이 자연 발생하는 기하를 만든다.
    /// 돌진/동결 중엔 기존 입력 가드와 동일하게 미개입. 게임 수치·판정 로직 0 변경 — 입력 대체만.
    func applyDemoAutopilotIfEnabled() {
        guard DemoAutopilot.isEnabled, !skillSystem.isDashing, !player.isFrozen else { return }
        if let dodge = demoDodgeDirection() {
            player.currentDirection = dodge
            player.isRunning = true
            return
        }
        var nearestDistSq = CGFloat.greatestFiniteMagnitude
        var nearestPosition: CGPoint?
        for note in registry.notes {
            let dx = note.position.x - player.position.x
            let dy = note.position.y - player.position.y
            let distSq = dx * dx + dy * dy
            if distSq < nearestDistSq {
                nearestDistSq = distSq
                nearestPosition = note.position
            }
        }
        guard let target = nearestPosition, nearestDistSq > 0 else { return }
        let dist = sqrt(nearestDistSq)
        player.currentDirection = CGVector(dx: (target.x - player.position.x) / dist,
                                           dy: (target.y - player.position.y) / dist)
        player.isRunning = true
    }

    /// 최근접 접근 위협(비매혹 F·청진기)에 대한 '스침 회피' 기동 벡터.
    /// 1) 경로 중심선 측면 거리 < 19px → 수직으로 밀어내 비접촉 대역 확보.
    /// 2) 측면 19~21px(스침 대역) → 경로와 평행 주행 — 투사체가 지나가는 동안 대역 유지.
    /// 3) 이미 지나갔거나(along<0) 대역 밖 → nil (음표 추적 복귀 — 자연 이탈이 near-miss 이탈 프레임).
    private func demoDodgeDirection() -> CGVector? {
        var nearestDistSq = DemoAutopilot.dodgeTriggerDistance * DemoAutopilot.dodgeTriggerDistance
        var threatPosition: CGPoint?
        var threatVelocity: CGVector = .zero
        for projectile in registry.projectiles where !projectile.isEnchanted {
            let dx = projectile.position.x - player.position.x
            let dy = projectile.position.y - player.position.y
            let distSq = dx * dx + dy * dy
            if distSq < nearestDistSq {
                nearestDistSq = distSq
                threatPosition = projectile.position
                threatVelocity = projectile.physicsBody?.velocity ?? .zero
            }
        }
        for stethoscope in registry.stethoscopes {
            let dx = stethoscope.position.x - player.position.x
            let dy = stethoscope.position.y - player.position.y
            let distSq = dx * dx + dy * dy
            if distSq < nearestDistSq {
                nearestDistSq = distSq
                threatPosition = stethoscope.position
                threatVelocity = stethoscope.physicsBody?.velocity ?? .zero
            }
        }
        guard let threat = threatPosition else { return nil }
        let speed = hypot(threatVelocity.dx, threatVelocity.dy)
        guard speed > DemoAutopilot.minThreatSpeed else { return nil }
        let unitV = CGVector(dx: threatVelocity.dx / speed, dy: threatVelocity.dy / speed)
        let perp = CGVector(dx: -unitV.dy, dy: unitV.dx)
        let relX = player.position.x - threat.x
        let relY = player.position.y - threat.y
        // 경로 좌표계 분해 — along(진행 방향 성분, + = 플레이어가 투사체 앞) / lateral(측면 성분).
        let along = relX * unitV.dx + relY * unitV.dy
        guard along >= 0 else { return nil }   // 이미 지나감 — 추적 복귀로 자연 이탈
        let lateral = relX * perp.dx + relY * perp.dy
        let absLateral = abs(lateral)
        if absLateral < DemoAutopilot.grazeBandInner {
            // 중심선에 너무 가까움 — 감속 수직 밀어내기 (대역 건너뛰기 방지).
            let scale = DemoAutopilot.dodgePushScale
            return lateral >= 0
                ? CGVector(dx: perp.dx * scale, dy: perp.dy * scale)
                : CGVector(dx: -perp.dx * scale, dy: -perp.dy * scale)
        }
        if absLateral <= DemoAutopilot.grazeBandOuter {
            // 스침 대역 — *역평행* 주행 (투사체를 마주 보고 달림). easy F(120~200pt/s)는
            // 플레이어(~252pt/s)보다 느려 평행 주행이면 통과가 영원히 안 일어남 —
            // 역평행이 통과(=near-miss 진입→이탈)를 강제한다. 측면 성분 0이라 대역 유지.
            return CGVector(dx: -unitV.dx, dy: -unitV.dy)
        }
        return nil
    }
}
#endif

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
