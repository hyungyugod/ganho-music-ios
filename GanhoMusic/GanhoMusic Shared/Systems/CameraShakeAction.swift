//
//  CameraShakeAction.swift
//  GanhoMusic Shared
//
//  Phase 6-9 · 카메라 셰이크 SKAction 빌더 (피격 시각 임팩트)
//

import SpriteKit

/// 카메라(또는 임의 SKNode)에 적용 가능한 좌우 셰이크 SKAction을 만들어주는
/// 순수 팩토리 네임스페이스. case 없는 enum으로 인스턴스화 차단.
/// Spring 비유: 정적 빌더 — 상태 없음, side-effect 없음, 입력 없이 SKAction 1개 반환.
/// 사용: cameraNode.run(CameraShakeAction.make())
enum CameraShakeAction {

    // MARK: - Make
    /// 좌→우→좌→우 직선 이동을 cameraShakeStepCount회 반복 후 *원위치 복귀*.
    /// 진폭은 GameConfig.cameraShakeAmplitude, 스텝당 길이는 cameraShakeStepDuration.
    /// 마지막 복귀 단계는 누적 변위 0이 되도록 부호 결정 (count 짝/홀).
    /// 학생 비유: 머리를 좌·우·좌·우·좌·우 흔든 뒤 정면으로 *딱* 복귀.
    ///
    /// 누적 변위 검산 (count=6):
    ///   i=0: +amp   (누적 +amp)
    ///   i=1: -2amp  (누적 -amp)
    ///   i=2: +2amp  (누적 +amp)
    ///   i=3: -2amp  (누적 -amp)
    ///   i=4: +2amp  (누적 +amp)
    ///   i=5: -2amp  (누적 -amp)
    ///   복귀:+amp   (누적   0) ✓
    /// 일반화: count 짝수 → 누적 -amp → 복귀 +amp / count 홀수 → 복귀 -amp.
    static func make() -> SKAction {
        let amp = GameConfig.cameraShakeAmplitude
        let dur = GameConfig.cameraShakeStepDuration
        let count = GameConfig.cameraShakeStepCount

        // 첫 이동(+amp), 그 후 (count-1)회 ±2amp 토글, 마지막 ±amp로 원위치.
        var steps: [SKAction] = []
        steps.append(SKAction.moveBy(x: +amp, y: 0, duration: dur))
        for i in 1..<count {
            let dx: CGFloat = (i % 2 == 0) ? +2 * amp : -2 * amp
            steps.append(SKAction.moveBy(x: dx, y: 0, duration: dur))
        }
        // 원위치 복귀: count 짝수면 누적 -amp → 복귀 +amp / 홀수면 누적 +amp → 복귀 -amp.
        let returnDx: CGFloat = (count % 2 == 0) ? +amp : -amp
        steps.append(SKAction.moveBy(x: returnDx, y: 0, duration: dur))
        return SKAction.sequence(steps)
    }
}
