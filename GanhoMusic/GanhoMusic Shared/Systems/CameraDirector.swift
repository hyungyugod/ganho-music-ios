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

    /// [#6 프록시] 원시 타깃(player)을 exp 스무딩한 중간 타깃. player.position은 무변경 —
    /// 프록시는 CameraDirector 내부 별도 변수(SPEC 2차 불변). configure/snapToClampedTarget에서 초기화.
    private var smoothedTarget: CGPoint = .zero

    // 셰이크 — x·y 동시 감쇠형
    private var shakeAmplitude: CGFloat = 0
    private var shakeRemaining: TimeInterval = 0
    private var shakeOffset: CGVector = .zero
    /// 변경 4 — 랜덤 오프셋 재추첨 누적기. cameraShakeSampleInterval(1/60s) 경과 시에만 새 오프셋을
    /// 뽑고 그 사이 프레임은 직전 오프셋을 홀드 → 진동 주파수를 프레임레이트와 무관하게 고정.
    private var shakeSampleAccumulator: TimeInterval = 0

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
        // [#6 프록시] 첫 프레임 글라이드 방지 — 원시 타깃으로 초기화 (basePosition 초기화 직후).
        self.smoothedTarget = targetProvider()
    }

    // MARK: - Effects API
    /// 감쇠 셰이크 시작. 재호출 시 진폭/잔여시간 리셋 (강도 합산 없음 — 단순성 우선).
    func shake(_ intensity: ShakeIntensity) {
        shakeAmplitude = intensity.amplitude
        shakeRemaining = intensity.duration
        // 변경 4 — 누적기를 재추첨 임계로 세팅해 첫 update 프레임이 즉시 오프셋을 뽑도록
        // (1프레임 평평한 시작 방지 — 60Hz 기존 동작과 프레임0 동일).
        shakeSampleAccumulator = FeelTuning.cameraShakeSampleInterval
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
        // [#6 프록시] 리사이즈/줌 순간 글라이드 방지 — 클램프 타깃으로 동시 재설정.
        smoothedTarget = clamped(targetProvider(), camera: camera)
        camera.position = basePosition
    }

    // MARK: - Update (카메라 position 단일 기록 지점)
    func update(dt: TimeInterval) {
        guard let camera = cameraNode, dt > 0 else { return }

        // 1) 원시 타깃 — player 위치 읽기 전용(무변경).
        let rawTarget = targetProvider()

        // 2) [#6 프록시 스무딩] — 원시 타깃을 exp 형태로 스무딩(프레임독립). 토글 OFF면 rawTarget 그대로
        //    통과 → 1차 세트와 동일. DPad 4방향 헤딩 양자화의 방향 꺾임·과반응 완화.
        if FeelTuning.cameraProxySmoothingEnabled {
            let s = CGFloat(1 - exp(-FeelTuning.cameraProxyLerpRate * dt))
            smoothedTarget.x += (rawTarget.x - smoothedTarget.x) * s
            smoothedTarget.y += (rawTarget.y - smoothedTarget.y) * s
        } else {
            smoothedTarget = rawTarget
        }

        // 3) [#7 데드존] — 축별로 base 오차가 데드존 half-extent 안이면 그 축 타깃을 직전 base로 치환.
        //    맵클램프·지수보간 *이전*(base는 이번 프레임 미갱신 — 표준 동작). 토글 OFF면 smoothedTarget 그대로.
        var effectiveTarget = smoothedTarget
        if FeelTuning.cameraDeadzoneEnabled {
            let vp = viewportProvider()
            let halfDZW = vp.width  * FeelTuning.cameraDeadzoneViewportFraction
            let halfDZH = vp.height * FeelTuning.cameraDeadzoneViewportFraction
            if abs(smoothedTarget.x - basePosition.x) <= halfDZW { effectiveTarget.x = basePosition.x }
            if abs(smoothedTarget.y - basePosition.y) <= halfDZH { effectiveTarget.y = basePosition.y }
        }

        // 4) 지수 보간 추적 — lerp(cam, effectiveTarget, 1 - exp(-8.5 × dt)). target을 effectiveTarget으로만 교체.
        // [프레임독립 불변 — 변경 금지] alpha = 1 - exp(-rate·dt)는 60/120Hz에서 동일 수렴 속도를
        // 보장하는 핵심 공식. 선형(rate·dt)·고정 per-frame alpha로 바꾸면 120Hz에서 카메라가
        // 2배 빨리 붙어 팔로우 체감이 깨진다. rate 튜닝은 FeelTuning.cameraFollowLerpRate(8.5) 상수 1개로만.
        let alpha = CGFloat(1 - exp(-FeelTuning.cameraFollowLerpRate * dt))
        basePosition.x += (effectiveTarget.x - basePosition.x) * alpha
        basePosition.y += (effectiveTarget.y - basePosition.y) * alpha

        // 5) 맵 클램프 — 보간 *후* 적용. 기존 GameScene+Camera 시맨틱 보존.
        basePosition = clamped(basePosition, camera: camera)

        // 6a) 셰이크 — 매 스텝 0.82배 감쇠 (스텝 = 1/60s 기준, dt 비례 보정). [1차 세트 시간정규화 그대로]
        if shakeRemaining > 0 {
            shakeRemaining -= dt
            // 감쇠(amplitude 곱연산)는 이미 프레임독립이라 매 프레임 그대로 유지 — 무수정.
            let steps = CGFloat(dt / FeelTuning.cameraShakeDecayReferenceStep)
            shakeAmplitude *= pow(FeelTuning.cameraShakeDecayPerStep, steps)
            if shakeRemaining <= 0 || shakeAmplitude < FeelTuning.cameraShakeMinAmplitude {
                shakeRemaining = 0
                shakeAmplitude = 0
                shakeOffset = .zero
                shakeSampleAccumulator = 0
            } else {
                // 변경 4 — 랜덤 오프셋은 시간정규화: 누적 시간이 sampleInterval(1/60s) 경과 시에만
                // 새로 추첨하고 그 사이 프레임은 직전 shakeOffset 홀드. 60Hz면 매 프레임 성립 →
                // 기존과 동일, 120Hz면 한 프레임 걸러 추첨(프레임당 오프셋 1개 — while 불요).
                shakeSampleAccumulator += dt
                if shakeSampleAccumulator >= FeelTuning.cameraShakeSampleInterval {
                    shakeSampleAccumulator -= FeelTuning.cameraShakeSampleInterval   // 캐리오버(드리프트 방지)
                    shakeOffset = CGVector(
                        dx: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
                        dy: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
                    )
                }
                // else: 직전 shakeOffset 홀드
            }
        }

        // 6b) 방향성 킥 — sin(π·t)로 0→4px→0 왕복. [1차 세트 그대로]
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

        // 7) [#5 합성시점 스냅] 저장된 basePosition은 스냅 금지(적분 드리프트 방지) — 합성용 로컬 사본에만.
        //    토글 기본 OFF(실기기 A/B 전용). shake/kick 오프셋은 비스냅(줌펄스 잔여 shimmer는 허용).
        let composedBase = FeelTuning.cameraPixelSnapEnabled
            ? snappedToDevicePixel(basePosition)
            : basePosition
        camera.position = CGPoint(
            x: composedBase.x + shakeOffset.dx + kickOffset.dx,
            y: composedBase.y + shakeOffset.dy + kickOffset.dy
        )
    }

    // MARK: - Pixel Snap (#5 — device-pixel 스냅, 크로스플랫폼 안전)
    /// 축별 round(v·scale)/scale. device-scale은 플랫폼 가드로 취득 — 가드 없으면 macOS 타겟에서
    /// contentScaleFactor(UIView 전용)가 NSView에 없어 컴파일 실패. scale ≤ 0이면 원본 반환(0 나눗셈 방지).
    private func snappedToDevicePixel(_ point: CGPoint) -> CGPoint {
        #if canImport(UIKit)
        let scale = cameraNode?.scene?.view?.contentScaleFactor ?? FeelTuning.cameraPixelSnapFallbackScale
        #else
        let scale = cameraNode?.scene?.view?.window?.backingScaleFactor ?? FeelTuning.cameraPixelSnapFallbackScale
        #endif
        guard scale > 0 else { return point }
        return CGPoint(x: (point.x * scale).rounded() / scale,
                       y: (point.y * scale).rounded() / scale)
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
