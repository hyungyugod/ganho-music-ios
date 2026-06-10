//
//  HitstopController.swift
//  GanhoMusic Shared
//
//  R2 · 히트스톱 — physicsWorld.speed + worldNode.isPaused 제어 (02_GAME_FEEL §2).
//  본 게임은 플레이어 이동이 GameScene.update 수동 적분이라 worldNode 일시정지만으로는
//  안 멈춘다 — 동결 중에는 tick(dt:)가 true를 반환해 게임플레이 파이프라인 전체를 스킵시킨다
//  (remainingTime 포함 동결). tick 위치는 gameState 가드 *이전* — 게임오버 램프도 진행.
//

import SpriteKit

/// 히트스톱 단일 제어기. GameScene 인스턴스 소유 (static 금지 — R1 패턴 동일).
/// 중첩 정책: 더 긴 쪽만 적용 (잔여 총량 비교). 일시정지 진입 시 cancel — 원복 책임 단일화.
final class HitstopController {

    #if DEBUG
    /// DEBUG 토글 — false면 모든 request가 noop (on/off 체감 비교용, 02 §2).
    static var isEnabled: Bool = true
    #endif

    // MARK: - State
    private enum Phase {
        case idle
        case frozen     // speed 0 + worldNode 일시정지 + 파이프라인 스킵
        case ramping    // worldNode 재개 + speed 0→1 보간 (파이프라인은 진행 — 게임오버 전용)
    }

    private var phase: Phase = .idle
    private var freezeRemaining: TimeInterval = 0
    private var rampDuration: TimeInterval = 0
    private var rampElapsed: TimeInterval = 0

    private weak var worldNode: SKNode?
    private weak var physicsWorld: SKPhysicsWorld?

    // MARK: - Configure
    /// didMove에서 1회 배선. physicsWorld는 씬 소유 객체 — weak 보관(씬 해제 시 자연 nil).
    func configure(worldNode: SKNode, physicsWorld: SKPhysicsWorld) {
        self.worldNode = worldNode
        self.physicsWorld = physicsWorld
    }

    // MARK: - Request / Cancel
    /// 히트스톱 요청. 중첩 시 더 긴 쪽만 적용 — 잔여 총량(freeze+ramp)이 더 길 때만 교체.
    func request(freeze: TimeInterval, ramp: TimeInterval = 0) {
        #if DEBUG
        guard Self.isEnabled else { return }
        #endif
        guard worldNode != nil else { return }
        guard freeze + ramp > remainingTotal else { return }
        freezeRemaining = freeze
        rampDuration = ramp
        rampElapsed = 0
        phase = .frozen
        physicsWorld?.speed = 0
        worldNode?.isPaused = true
    }

    /// 즉시 원복 — 일시정지 진입/메인 이탈 시 호출. speed/isPaused 소유권을 호출자에게 넘긴다.
    func cancel() {
        guard phase != .idle else { return }
        restore()
    }

    // MARK: - Tick
    /// GameScene.update 프레임 준비 구역에서 매 프레임 호출 (gameState 가드 *이전*).
    /// - Returns: true면 이번 프레임의 게임플레이 파이프라인을 스킵해야 함 (동결 중).
    func tick(dt: TimeInterval) -> Bool {
        switch phase {
        case .idle:
            return false
        case .frozen:
            freezeRemaining -= dt
            if freezeRemaining <= 0 {
                if rampDuration > 0 {
                    phase = .ramping
                    rampElapsed = 0
                    worldNode?.isPaused = false
                    physicsWorld?.speed = 0
                } else {
                    restore()
                }
            }
            return true
        case .ramping:
            rampElapsed += dt
            let progress = min(1, rampElapsed / rampDuration)
            physicsWorld?.speed = CGFloat(progress)
            if progress >= 1 {
                restore()
            }
            // 램프 중에는 파이프라인 진행 — 현 매핑상 램프는 게임오버 전용이라
            // gameState 가드가 자연 차단, 시각(worldNode SKAction)만 서서히 재생된다.
            return false
        }
    }

    // MARK: - Private
    private var remainingTotal: TimeInterval {
        switch phase {
        case .idle:    return 0
        case .frozen:  return max(0, freezeRemaining) + rampDuration
        case .ramping: return max(0, rampDuration - rampElapsed)
        }
    }

    private func restore() {
        phase = .idle
        freezeRemaining = 0
        rampDuration = 0
        rampElapsed = 0
        physicsWorld?.speed = 1
        worldNode?.isPaused = false
    }
}
