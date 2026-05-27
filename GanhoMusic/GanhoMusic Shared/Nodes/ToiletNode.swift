//
//  ToiletNode.swift
//  GanhoMusic Shared
//
//  Phase 9-6 · "화캉스(화장실 바캉스)" 보너스 수집 노드.
//  12초마다 15% 확률로 단일 스폰. 8초 미수집 시 자동 fadeOut + removeFromParent.
//  SpawnSystem가 부착 + applyLifetime 호출. ContactRouter onToiletCollected 콜백이 수집 시 처리.
//

import SpriteKit

/// 변기 보너스 노드 — 픽셀 아트 16×16(시각) + static PhysicsBody.
/// 노트(NoteNode)와 동일한 *수집 대상*이지만 PhysicsCategory.bonus 비트로 분리 →
/// ContactRouter가 별도 분기(handleBonusContact) → ScoreSystem.recordToiletBonus 호출.
///
/// Spring 비유: NoteNode가 일반 GET API 응답이라면, ToiletNode는 *이벤트 캠페인 한정 보너스 상품* —
/// 같은 도메인 객체(수집물)지만 서버 분기 라우팅(ContactRouter)이 다른 핸들러(recordToiletBonus)로 위임.
final class ToiletNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(width: GameConfig.toiletSize, height: GameConfig.toiletSize)
        // Phase 9-6 — PixelSpriteRenderer 표준 16×20 텍스처. 상단 4행 transparent padding 포함.
        // SKSpriteNode size=16×16이면 vertical squish 0.8배 발생 — 픽셀 retro 톤에 자연 흡수.
        // (toiletData의 의미 영역은 행 4~15, 12행 = 변기 본체. padding은 16×20 정합용.)
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.toiletData(),
            palette: PixelPalette.toiletPalette
        )
        super.init(texture: texture, color: .clear, size: size)
        name = "toilet"
        zPosition = GameConfig.toiletZPosition
        addBonusRing()

        // PhysicsBody: static(isDynamic=false), 충돌 없음(collisionBitMask=0),
        // player와만 contactTestBitMask 매칭 → didBegin 콜백 발화.
        // SPEC.md §기능 1 명세 그대로.
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.bonus
        body.collisionBitMask    = 0
        body.contactTestBitMask  = PhysicsCategory.player
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifetime
    /// 스폰 직후 1회 호출. toiletLifetime(8초) 후 fadeOut + removeFromParent.
    /// GameConfig.toiletLifetimeActionKey로 부착 → 동일 키 재호출 시 SpriteKit이 이전 액션 자동 교체(자연 멱등).
    /// 수집된 노드는 GameScene 콜백이 SKAction.removeFromParent() 호출 → parent==nil 이후 본 액션 도달 시 noop.
    /// SpriteKit의 removeFromParent SKAction은 parent==nil인 노드에 실행 시 안전 noop(공식 문서).
    func applyLifetime() {
        let wait   = SKAction.wait(forDuration: GameConfig.toiletLifetime)
        let fade   = SKAction.fadeOut(withDuration: GameConfig.toiletFadeOutDuration)
        let remove = SKAction.removeFromParent()
        run(.sequence([wait, fade, remove]), withKey: GameConfig.toiletLifetimeActionKey)
    }

    // MARK: - Readability
    private func addBonusRing() {
        let ring = SKShapeNode(circleOfRadius: GameConfig.toiletBonusRingRadius)
        ring.strokeColor = .ganhoIngameRewardMint
        ring.lineWidth = GameConfig.toiletBonusRingLineWidth
        ring.fillColor = UIColor.ganhoPixelHudWhite
            .withAlphaComponent(GameConfig.ingameObjectHaloAlpha)
        ring.zPosition = -1
        addChild(ring)

        let fadeDown = SKAction.fadeAlpha(
            to: GameConfig.toiletBonusPulseAlpha,
            duration: GameConfig.toiletBonusPulseHalfDuration
        )
        let fadeUp = SKAction.fadeAlpha(
            to: 1.0,
            duration: GameConfig.toiletBonusPulseHalfDuration
        )
        ring.run(.repeatForever(.sequence([fadeDown, fadeUp])),
                 withKey: GameConfig.toiletBonusPulseActionKey)
    }
}
