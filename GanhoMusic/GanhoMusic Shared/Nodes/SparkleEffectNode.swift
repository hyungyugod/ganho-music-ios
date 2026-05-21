//
//  SparkleEffectNode.swift
//  GanhoMusic Shared
//
//  Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 + 자가 소멸 (시각 폴리싱)
//  Sprint 10 Phase J · context 분기 (.ingame 픽셀 사각 / .menu 카툰 원형)
//

import SpriteKit

/// 음표 수집 시 노트 위치에서 8방향으로 방사되는 sparkle 파편 컨테이너.
/// PhysicsBody 부착 0 — 순수 시각. SKAction.group(이동 + 페이드 + 스케일)을
/// 8개 자식 노드에 *동시* 실행 → 0.5초 후 컨테이너 자가 제거.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode 패턴 답습 — 자가 소멸 노드 4회차.
/// Sprint 10 Phase J — `context` 분기 도입.
/// - `.ingame`: 인게임 픽셀 톤 — SKSpriteNode 3×3pt 정사각 + ganhoPixelHudWhite. 음표 수집 (GameScene).
/// - `.menu`: 메뉴 카툰 톤 — SKShapeNode 원형 + .white. 신기록 burst (ResultScene).
/// Spring 비유: 동일 클래스가 두 환경(production/dev)에서 다른 빈 구성 — 호출부 `init(context:)`에서 선택.
final class SparkleEffectNode: SKNode, SelfDismissingNode {

    // MARK: - Context (Sprint 10 Phase J)
    /// sparkle 시각 톤 컨텍스트. enum 자체는 인게임/메뉴 두 분기만 — switch default 0(SPEC §4 금지).
    enum SparkleContext {
        /// 인게임 8-bit 톤 — 3×3pt 정사각 픽셀 + 페이퍼 화이트.
        case ingame
        /// 메뉴 v2 카툰 톤 — 반지름 2pt 원 + 순백. ResultScene 신기록 burst.
        case menu
    }

    /// 호출자가 init에서 주입. buildParticles에서 입자 모양/색 분기에 사용 + 호출 후 변경 없음.
    private let context: SparkleContext

    // MARK: - Init
    /// 기본값 `.ingame` — 기존 호출부(GameScene)가 인자 생략해도 자연 인게임 톤 유지.
    /// ResultScene만 `.menu` 명시 — 호출부 grep 명확화.
    init(context: SparkleContext = .ingame) {
        self.context = context
        super.init()
        name = "sparkle"
        zPosition = GameConfig.sparkleZPosition
        buildParticles()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Particles
    /// 8개의 파편을 자식으로 부착. 모두 (0,0)에서 출발.
    /// Sprint 10 Phase J — context 분기:
    /// - `.ingame`: SKSpriteNode `sparklePixelSize × sparklePixelSize` 정사각 + ganhoPixelHudWhite.
    /// - `.menu`: SKShapeNode `sparkleParticleRadius` 원형 + .white.
    /// init 시점에만 호출 — update 안 addChild 패턴 위반 0.
    private func buildParticles() {
        for _ in 0..<GameConfig.sparkleParticleCount {
            let particle: SKNode
            switch context {
            case .ingame:
                // 인게임 픽셀 톤 — 정사각 픽셀 페이퍼 화이트. 어두운 BG(#1A1B2E) 위 8-bit 별빛.
                let pixelSize = GameConfig.sparklePixelSize
                let sprite = SKSpriteNode(
                    color: .ganhoPixelHudWhite,
                    size: CGSize(width: pixelSize, height: pixelSize)
                )
                particle = sprite
            case .menu:
                // 메뉴 카툰 톤 — 둥근 원 순백. v2 따뜻한 BG 위 신기록 burst.
                let shape = SKShapeNode(circleOfRadius: GameConfig.sparkleParticleRadius)
                shape.fillColor = .white
                shape.strokeColor = .clear
                particle = shape
            }
            particle.position = .zero
            addChild(particle)
        }
    }

    // MARK: - Emit
    /// 부모(worldNode / cameraNode / scene)에 addChild 직후 호출. 각 파편에 8방향 SKAction.group을
    /// *동시* run. group 액션 [move, fadeOut, scale]을 동시 진행. self 미사용 — [weak self] 캡처 불필요.
    /// **Sprint 10 Phase J: SKAction 본문 0건 변경.**
    func emit() {
        let angleStep = (2 * CGFloat.pi) / CGFloat(GameConfig.sparkleParticleCount)
        for (index, child) in children.enumerated() {
            let angle = angleStep * CGFloat(index)
            let dx = cos(angle) * GameConfig.sparkleSpawnDistance
            let dy = sin(angle) * GameConfig.sparkleSpawnDistance
            let move  = SKAction.moveBy(x: dx, y: dy, duration: GameConfig.sparkleFadeDuration)
            let fade  = SKAction.fadeOut(withDuration: GameConfig.sparkleFadeDuration)
            let scale = SKAction.scale(to: GameConfig.sparkleEndScale,
                                       duration: GameConfig.sparkleFadeDuration)
            child.run(.group([move, fade, scale]))
        }
        // 컨테이너 자가 제거: group 길이만큼 대기 후 removeFromParent.
        // child 액션과 동일한 sparkleFadeDuration으로 묶어 정확한 타이밍 보장.
        let wait    = SKAction.wait(forDuration: GameConfig.sparkleFadeDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, cleanup]))
    }
}
