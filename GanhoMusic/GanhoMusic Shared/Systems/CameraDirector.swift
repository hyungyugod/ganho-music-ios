//
//  CameraDirector.swift
//  GanhoMusic Shared
//
//  R2 · 카메라 v2 — 지수 보간 추적 + 맵 클램프 + 감쇠 셰이크 3단 + 줌 펄스 + 방향성 킥
//  (02_GAME_FEEL §3). 기존 update가 cameraNode.position을 절대 대입했으므로 셰이크/킥은
//  SKAction이 아니라 dt 구동 오프셋 — update(dt:)가 position의 *단일 기록 지점*이다.
//  줌 펄스는 scale만 만지므로 SKAction 허용 (클램프 halfW가 xScale을 곱해 자동 정합).
//

import SpriteKit

/// 인게임 카메라 단일 제어기. GameScene 인스턴스 소유 (static 금지 — R1 패턴 동일).
final class CameraDirector {

    // MARK: - Shake Intensity (02 §3 — soft/medium/strong 3단)
    enum ShakeIntensity {
        case soft, medium, strong

        var amplitude: CGFloat {
            switch self {
            case .soft:   return FeelTuning.cameraShakeSoftAmplitude
            case .medium: return FeelTuning.cameraShakeMediumAmplitude
            case .strong: return FeelTuning.cameraShakeStrongAmplitude
            }
        }

        var duration: TimeInterval {
            switch self {
            case .soft:   return FeelTuning.cameraShakeSoftDuration
            case .medium: return FeelTuning.cameraShakeMediumDuration
            case .strong: return FeelTuning.cameraShakeStrongDuration
            }
        }
    }

    // MARK: - State
    private weak var cameraNode: SKCameraNode?
    private var targetProvider: () -> CGPoint = { .zero }
    private var viewportProvider: () -> CGSize = { .zero }

    /// 셰이크/킥 오프셋을 제외한 추적 기준 위치 — 보간·클램프는 이 값에만 적용.
    private var basePosition: CGPoint = .zero

    // 셰이크 — x·y 동시 감쇠형
    private var shakeAmplitude: CGFloat = 0
    private var shakeRemaining: TimeInterval = 0
    private var shakeOffset: CGVector = .zero

    // 방향성 킥 — sin 곡선으로 밀렸다 복귀
    private var kickDirection: CGVector = .zero
    private var kickElapsed: TimeInterval = 0
    private var kickActive: Bool = false

    // MARK: - Configure
    /// didMove에서 1회 배선. basePosition은 현재 카메라 위치에서 시작 (맵 중앙 → 첫 추적 글라이드).
    func configure(cameraNode: SKCameraNode,
                   targetProvider: @escaping () -> CGPoint,
                   viewportProvider: @escaping () -> CGSize) {
        self.cameraNode = cameraNode
        self.targetProvider = targetProvider
        self.viewportProvider = viewportProvider
        self.basePosition = cameraNode.position
    }

    // MARK: - Effects API
    /// 감쇠 셰이크 시작. 재호출 시 진폭/잔여시간 리셋 (강도 합산 없음 — 단순성 우선).
    func shake(_ intensity: ShakeIntensity) {
        shakeAmplitude = intensity.amplitude
        shakeRemaining = intensity.duration
    }

    /// 방향성 킥 — direction(정규화 불필요) 방향으로 4px 밀렸다 복귀 (0.12s).
    /// 0벡터는 noop — 호출부가 폴백 방향(enemy→player)을 책임진다.
    func kick(direction: CGVector) {
        let length = hypot(direction.dx, direction.dy)
        guard length > 0 else { return }
        kickDirection = CGVector(dx: direction.dx / length, dy: direction.dy / length)
        kickElapsed = 0
        kickActive = true
    }

    /// 줌 펄스 — scale 1.0 → targetScale → 1.0. easeOut 곡선(Tween). withKey 멱등.
    func zoomPulse(to targetScale: CGFloat, duration: TimeInterval) {
        guard let camera = cameraNode else { return }
        let half = duration / 2
        let zoomIn = Tween.curved(SKAction.scale(to: targetScale, duration: half), .easeOutCubic)
        let zoomOut = Tween.curved(SKAction.scale(to: 1.0, duration: half), .easeOutCubic)
        camera.run(.sequence([zoomIn, zoomOut]), withKey: FeelTuning.cameraZoomPulseActionKey)
    }

    /// 화면 크기/줌 변경(didChangeSize) 시 즉시 스냅 — 구 절대 대입 클램프 시맨틱과 동일.
    /// 보간 없이 타깃을 클램프해 base에 기록 (셰이크/킥 오프셋 미합성 — 레이아웃 순간은 안정 우선).
    func snapToClampedTarget() {
        guard let camera = cameraNode else { return }
        basePosition = clamped(targetProvider(), camera: camera)
        camera.position = basePosition
    }

    // MARK: - Update (카메라 position 단일 기록 지점)
    func update(dt: TimeInterval) {
        guard let camera = cameraNode, dt > 0 else { return }

        // 1) 지수 보간 추적 — lerp(cam, player, 1 - exp(-8.5 × dt)).
        let target = targetProvider()
        let alpha = CGFloat(1 - exp(-FeelTuning.cameraFollowLerpRate * dt))
        basePosition.x += (target.x - basePosition.x) * alpha
        basePosition.y += (target.y - basePosition.y) * alpha

        // 2) 맵 클램프 — 보간 *후* 적용. 기존 GameScene+Camera 시맨틱 보존.
        basePosition = clamped(basePosition, camera: camera)

        // 3) 셰이크 — 매 스텝 0.82배 감쇠 (스텝 = 1/60s 기준, dt 비례 보정).
        if shakeRemaining > 0 {
            shakeRemaining -= dt
            let steps = CGFloat(dt / FeelTuning.cameraShakeDecayReferenceStep)
            shakeAmplitude *= pow(FeelTuning.cameraShakeDecayPerStep, steps)
            if shakeRemaining <= 0 || shakeAmplitude < FeelTuning.cameraShakeMinAmplitude {
                shakeRemaining = 0
                shakeAmplitude = 0
                shakeOffset = .zero
            } else {
                shakeOffset = CGVector(
                    dx: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
                    dy: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
                )
            }
        }

        // 4) 방향성 킥 — sin(π·t)로 0→4px→0 왕복.
        var kickOffset = CGVector.zero
        if kickActive {
            kickElapsed += dt
            let progress = min(1, kickElapsed / FeelTuning.cameraKickDuration)
            if progress >= 1 {
                kickActive = false
            } else {
                let magnitude = sin(.pi * CGFloat(progress)) * FeelTuning.cameraKickDistance
                kickOffset = CGVector(dx: kickDirection.dx * magnitude,
                                      dy: kickDirection.dy * magnitude)
            }
        }

        // 5) 최종 합성 — base + shake + kick.
        camera.position = CGPoint(
            x: basePosition.x + shakeOffset.dx + kickOffset.dx,
            y: basePosition.y + shakeOffset.dy + kickOffset.dy
        )
    }

    // MARK: - Clamp (기존 GameScene+Camera 시맨틱 — halfW/halfH에 xScale 곱, upper<lower면 중앙 폴백)
    private func clamped(_ point: CGPoint, camera: SKCameraNode) -> CGPoint {
        let viewport = viewportProvider()
        let halfW = viewport.width * camera.xScale / 2
        let halfH = viewport.height * camera.yScale / 2
        let worldW = GameplayTuning.mapWidth
        let worldH = GameplayTuning.mapHeight
        let lowerX = halfW
        let upperX = worldW - halfW
        let lowerY = halfH
        let upperY = worldH - halfH
        var result = point
        if upperX < lowerX {
            result.x = worldW / 2
        } else {
            result.x = max(lowerX, min(upperX, point.x))
        }
        if upperY < lowerY {
            result.y = worldH / 2
        } else {
            result.y = max(lowerY, min(upperY, point.y))
        }
        return result
    }
}
