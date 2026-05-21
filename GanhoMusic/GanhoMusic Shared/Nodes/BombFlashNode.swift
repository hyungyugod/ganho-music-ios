//
//  BombFlashNode.swift
//  GanhoMusic Shared
//
//  Phase 4-5 · AIRFORCE 폭탄 화면 플래시 — 누런 섬광 + 자가 소멸
//  Sprint 10 Phase G · 픽셀 톤 통일 — color .ganhoPaper → .ganhoPixelFlashWhite,
//                                       blendMode .add, peakAlpha 0.92, fadeAlpha(to:) 보간.
//

import SpriteKit

/// AIRFORCE 이스터에그 폭탄 화면 플래시. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·zPosition·name·alpha=0·blendMode만 부여하고, scene.size 의존인
/// size·position·SKAction은 외부 호출자가 flash(sceneSize:) 부르는 시점에 시작한다.
/// SKAction.sequence([wait, fadeIn, fadeOut, removeFromParent])로 자가 소멸(fire-and-forget).
/// Sprint 10 Phase G — fadeIn은 fadeAlpha(to:duration:) — peakAlpha 0.92 명시.
///   (SKAction.fadeIn(withDuration:)는 alpha 1.0까지 가는 strict ↑ — peakAlpha 제어 불가).
/// blendMode .add — 본체 색 #fffce0가 배경 픽셀과 가산 합성 → 풀스크린 *번쩍* 임팩트.
final class BombFlashNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Init
    init() {
        super.init(texture: nil, color: .ganhoPixelFlashWhite, size: .zero)
        name = "bombFlash"
        zPosition = 250
        alpha = 0
        // Sprint 10 Phase G — additive 합성. 0.42s 풀스크린 1회만 발화이므로 60fps 안전(OQ-6).
        blendMode = .add
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flash
    /// 부모(cameraNode)에 addChild 직후 호출. scene.size로 풀스크린 크기 부여 →
    /// wait(3.4) → fadeIn(0.07, to: 0.92) → fadeOut(0.35) → 자가 제거.
    /// self 미사용 — [weak self] 캡처 불필요.
    func flash(sceneSize: CGSize) {
        size = sceneSize
        position = .zero
        let wait    = SKAction.wait(forDuration: GameConfig.bombFlashDelay)
        let fadeIn  = SKAction.fadeAlpha(to: GameConfig.bombFlashPeakAlpha,
                                         duration: GameConfig.bombFlashFadeInDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.bombFlashFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, fadeIn, fadeOut, cleanup]))
    }
}
