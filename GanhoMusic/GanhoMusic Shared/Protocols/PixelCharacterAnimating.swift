//
//  PixelCharacterAnimating.swift
//  GanhoMusic Shared
//
//  R0 — 픽셀 캐릭터 4노드(Player/Enemy/Professor/StoneGuard)에 복붙돼 있던
//  4방향 산출 + 보행 프레임 상태 머신을 단일 프로토콜 기본 구현으로 추출.
//  동작은 추출 전과 byte-equal — 임계값(0.1/0.01)·간격(0.11/0.18)·텍스처 갱신 시점 보존.
//  static 텍스처 캐시는 노드별 4벌 그대로 유지 — 통합은 R1 TextureAtlasStore 범위.
//

import SpriteKit

/// 픽셀 캐릭터 공통 애니메이션 계약 — 방향 산출과 step1↔step2 보행 토글의 단일 진실 원천.
/// 왜 프로토콜인가: 같은 로직 사본 4벌이 각자 드리프트하는 사고(한 노드만 수정되는 회귀)를 차단한다.
/// ⚠️ 커스터마이즈는 반드시 아래 요구 프로퍼티/훅으로만 — extension 동명 메서드 섀도잉 금지
/// (프로토콜 extension은 정적 디스패치라 호출 지점에 따라 다른 구현이 불리는 사고 방지).
protocol PixelCharacterAnimating: AnyObject {
    /// 현재 픽셀 텍스처가 표현하는 방향. 정지 시 마지막 방향 유지(자연 톤).
    var pixelDirection: PixelDirection { get set }
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    var pixelFrame: PixelFrame { get set }
    /// step1↔step2 교차 누적 시간 (초). walkFrameInterval 도달 시 토글 + 0 리셋.
    var frameAccumulator: TimeInterval { get set }

    /// step1↔step2 교차 주기 (초). Player 0.11 / 적·빌런 0.18 — 값 변경 금지(R0 행동 불변).
    var walkFrameInterval: TimeInterval { get }
    /// 이동 판정 임계값. velocity 기반(A형) 0.1 / position-delta 기반(B형) 0.01.
    var movementThreshold: CGFloat { get }
    /// 정지→이동 첫 프레임에 한 interval 대기 없이 즉시 step1로 토글하는지. Player만 true
    /// (출발 버벅임 제거 — Sprint 11 시맨틱 보존). 적·빌런은 false(1 interval 대기).
    var togglesToStepImmediately: Bool { get }

    /// 현재 (pixelDirection, pixelFrame) 조합을 노드 텍스처에 반영하는 훅.
    /// 보행 토글·idle 복귀·B형 병합 1회 갱신이 모두 이 훅 하나로 모인다.
    func applyPixelTexture()
    /// A형 전용 — 방향이 실제로 바뀐 프레임의 텍스처 반영 훅.
    /// 기본 구현은 applyPixelTexture()와 동일. Player만 "idle 방향 텍스처 + 자식 동기"로 커스텀
    /// (방향 전환 순간 idle 프레임이 잠깐 노출되는 기존 시맨틱 보존).
    func applyDirectionChangeTexture()
}

// MARK: - 공통 기본값 + 방향 산출 단일 사본
extension PixelCharacterAnimating {
    var walkFrameInterval: TimeInterval { GameplayTuning.pixelWalkFrameInterval }
    var movementThreshold: CGFloat { GameplayTuning.pixelDirectionVelocityThreshold }
    var togglesToStepImmediately: Bool { false }

    func applyDirectionChangeTexture() {
        applyPixelTexture()
    }

    /// dx/dy → 4방향 산출 — 리포 전체에서 이 한 벌만 존재해야 한다(§11-3 검증 대상).
    /// SpriteKit 좌표계: +y는 위쪽 → dy >= 0이면 up.
    func resolvedPixelDirection(dx: CGFloat, dy: CGFloat) -> PixelDirection {
        let absDx = abs(dx)
        let absDy = abs(dy)
        if absDx > absDy {
            return dx >= 0 ? .right : .left
        }
        return dy >= 0 ? .up : .down
    }

    // MARK: - 형상 A · velocity 기반 분리형 (Player/Enemy)

    /// velocity 부호로 4방향 산출. 임계값 미만(거의 정지) 시 방향 유지 — 텍스처 재생성 0.
    /// physics 엔진의 미세 잔존 velocity가 *흔들림*으로 보이지 않도록 가드.
    func updatePixelDirection(_ velocity: CGVector) {
        let absDx = abs(velocity.dx)
        let absDy = abs(velocity.dy)
        guard absDx > movementThreshold || absDy > movementThreshold else { return }
        let newDir = resolvedPixelDirection(dx: velocity.dx, dy: velocity.dy)
        if newDir != pixelDirection {
            pixelDirection = newDir
            applyDirectionChangeTexture()
        }
    }

    /// 걷는 중일 때 step1↔step2 교차, 정지 시 idle. 텍스처 반영은 변경 순간에만 — 매 프레임 비용 0.
    /// - Parameter isMoving: 외부에서 판단(velocity != .zero 등). 명시 인자로 받아 책임 분리.
    func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) {
        guard isMoving else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                applyPixelTexture()
            }
            return
        }
        // 정지→이동 첫 프레임: Player만 즉시 step1 토글(출발 지연 제거) — 기존 시맨틱 보존.
        if togglesToStepImmediately && pixelFrame == .idle {
            pixelFrame = .step1
            frameAccumulator = 0
            applyPixelTexture()
            return
        }
        frameAccumulator += deltaTime
        if frameAccumulator >= walkFrameInterval {
            frameAccumulator = 0
            pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
            applyPixelTexture()
        }
    }
}

// MARK: - 형상 B · position-delta 통합형 (Professor/StoneGuard)

/// SKAction.move 기반 노드용 파생 계약 — velocity가 없어 *이전 프레임 위치*와 비교한다.
protocol PixelPositionDeltaAnimating: PixelCharacterAnimating {
    /// updatePixelAnimation에서 이전 프레임 위치와 비교해 진행 방향 산출.
    var lastPosition: CGPoint { get set }
    /// lastPosition 첫 초기화 여부. 첫 update에서 자기 자신과 비교 → 거짓 정지 신호 방지.
    var hasLastPosition: Bool { get set }
}

extension PixelPositionDeltaAnimating where Self: SKNode {
    /// GameScene.update가 매 프레임 호출. 방향+프레임을 한 함수에서 처리하고
    /// needsRefresh 병합 후 텍스처 갱신을 **1회만** 호출한다(기존 시맨틱 보존).
    func updatePixelAnimation(deltaTime: TimeInterval) {
        guard hasLastPosition else {
            lastPosition = position
            hasLastPosition = true
            return
        }
        let dx = position.x - lastPosition.x
        let dy = position.y - lastPosition.y
        lastPosition = position

        let absDx = abs(dx)
        let absDy = abs(dy)
        guard absDx > movementThreshold || absDy > movementThreshold else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                applyPixelTexture()
            }
            return
        }
        let newDir = resolvedPixelDirection(dx: dx, dy: dy)
        var needsRefresh = false
        if newDir != pixelDirection {
            pixelDirection = newDir
            needsRefresh = true
        }
        frameAccumulator += deltaTime
        if frameAccumulator >= walkFrameInterval {
            frameAccumulator = 0
            pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
            needsRefresh = true
        }
        if needsRefresh {
            applyPixelTexture()
        }
    }
}
