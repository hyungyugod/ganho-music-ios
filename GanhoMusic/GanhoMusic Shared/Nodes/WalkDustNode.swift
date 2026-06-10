//
//  WalkDustNode.swift
//  GanhoMusic Shared
//
//  R2 · 걷기 먼지 — 4걸음마다 발밑 2px 사각 2개 0.25s 페이드 (02_GAME_FEEL §5).
//  파티클 이미터 아님 — ObjectPool 풀링 노드 (update 내 신규 할당 0).
//  사각 2개는 TextureAtlasStore 베이크 텍스처 1장 — 퍼프당 1노드 (평시 노드 게이트 기여).
//

import SpriteKit

/// 걷기 먼지 1퍼프 — 2px 사각 2개가 베이크된 단일 스프라이트.
/// GameScene이 풀에서 obtain → 발밑 배치 → play() → 페이드 후 자가 회수.
final class WalkDustNode: SKSpriteNode, Poolable {

    /// 풀 소유자(GameScene)가 obtain 시 주입하는 회수 핸들러. nil이면 removeFromParent 폴백.
    var recycleHandler: ((WalkDustNode) -> Void)?

    // MARK: - Init
    init() {
        let texture = TextureAtlasStore.walkDustTexture()
        super.init(texture: texture, color: .clear,
                   size: CGSize(width: TextureAtlasStore.walkDustTextureSize.width,
                                height: TextureAtlasStore.walkDustTextureSize.height))
        zPosition = ZOrder.walkDustZPosition
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Play
    /// 부모 attach 직후 호출 — 0.25s 페이드 후 풀 회수 (좀비 금지: alpha 0 잔존 없이 detach).
    func play() {
        alpha = FeelTuning.walkDustStartAlpha
        let fade = SKAction.fadeOut(withDuration: FeelTuning.walkDustFadeDuration)
        let recycle = SKAction.run { [weak self] in
            guard let self = self else { return }
            if let handler = self.recycleHandler {
                handler(self)
            } else {
                self.removeFromParent()
            }
        }
        run(.sequence([fade, recycle]))
    }

    // MARK: - Poolable
    func resetForReuse() {
        removeAllActions()
        alpha = FeelTuning.walkDustStartAlpha
        position = .zero
    }
}
