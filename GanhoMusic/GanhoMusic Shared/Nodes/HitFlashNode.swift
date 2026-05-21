//
//  HitFlashNode.swift
//  GanhoMusic Shared
//
//  Phase 6-9 · F 피격 시 화면 빨간 풀스크린 플래시 + 자가 소멸
//

import SpriteKit

/// F 투사체 피격 시 화면 전체를 빨갛게 덮는 자가 소멸 플래시.
/// PhysicsBody 부착 0 — 순수 시각. BombFlashNode 패턴 답습이나 색·타이밍·zPosition 차이로
/// 별도 클래스. 공통 추출(BaseFlashNode)은 Rule of three(3개 등장) 시점까지 보류.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode 패턴 답습 —
/// 자가 소멸 노드 5회차.
/// Spring 비유: 같은 인터페이스(SelfDismissingNode)를 따르는 두 번째 풀스크린 구현체 —
/// BombFlashNode가 누런 폭탄 잔상이라면 HitFlashNode는 붉은 피격 잔상.
final class HitFlashNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Init
    init() {
        // Sprint 10 Phase J — ganhoBloodAccent(#D8315B) → ganhoPixelHitRed(#C8281A) swap.
        // blendMode .add — 본체 진홍이 배경 픽셀과 가산 합성 → 풀스크린 *번쩍* 임팩트.
        // BombFlashNode와 동형 패턴(Phase G 적용 완료).
        super.init(texture: nil, color: .ganhoPixelHitRed, size: .zero)
        name = "hitFlash"
        zPosition = GameConfig.hitFlashZPosition
        alpha = 0
        blendMode = .add
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flash
    /// 부모(cameraNode)에 addChild 직후 호출. scene.size로 풀스크린 크기 부여 →
    /// fadeIn(빠름) → fadeOut(느림, peakAlpha부터) → 자가 제거.
    /// peakAlpha 미만으로 페이드 — 시야 완전 차단 방지(플레이어가 상황 인지 가능).
    /// self 미사용 — [weak self] 캡처 불필요.
    func flash(sceneSize: CGSize) {
        size = sceneSize
        position = .zero
        let fadeIn = SKAction.fadeAlpha(to: GameConfig.hitFlashPeakAlpha,
                                        duration: GameConfig.hitFlashFadeInDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.hitFlashFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([fadeIn, fadeOut, cleanup]))
    }
}
