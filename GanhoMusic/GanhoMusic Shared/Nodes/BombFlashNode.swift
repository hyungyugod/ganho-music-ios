//
//  BombFlashNode.swift
//  GanhoMusic Shared
//
//  Phase 4-5 · AIRFORCE 폭탄 화면 플래시 — 누런 섬광 + 자가 소멸
//

import SpriteKit

/// AIRFORCE 이스터에그 폭탄 화면 플래시. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·zPosition·name·alpha=0만 부여하고, scene.size 의존인
/// size·position·SKAction은 외부 호출자가 flash(sceneSize:) 부르는 시점에 시작한다.
/// SKAction.sequence([wait, fadeIn, fadeOut, removeFromParent])로 자가 소멸(fire-and-forget).
/// AirplaneNode / AirforceOverlayNode 패턴 답습 — 자가 소멸 노드 3회차.
final class BombFlashNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Init
    init() {
        super.init(texture: nil, color: .ganhoPaper, size: .zero)
        name = "bombFlash"
        zPosition = 250
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flash
    /// 부모(cameraNode)에 addChild 직후 호출. scene.size로 풀스크린 크기 부여 →
    /// wait(2.1) → fadeIn(0.07) → fadeOut(0.35) → 자가 제거.
    /// self 미사용 — [weak self] 캡처 불필요.
    func flash(sceneSize: CGSize) {
        size = sceneSize
        position = .zero
        let wait    = SKAction.wait(forDuration: GameConfig.bombFlashDelay)
        let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.bombFlashFadeInDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.bombFlashFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, fadeIn, fadeOut, cleanup]))
    }
}
