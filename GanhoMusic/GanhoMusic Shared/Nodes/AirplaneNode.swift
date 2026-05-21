//
//  AirplaneNode.swift
//  GanhoMusic Shared
//
//  Phase 4-3 · AIRFORCE 이스터에그 비행기 — 좌→우 가로지르기 + 자가 소멸
//  Sprint 8 Phase G · 비행기 형상 6 자식(fuselage/wings/tail/cockpit/propeller/contrail) — 노란 사각형 → 비행기.
//  Sprint 10 Phase G · 6 자식 SKShape → 16×5 도트 픽셀 SKTexture (원본 game.js L3328~L3336 byte-equal).
//

import SpriteKit

/// AIRFORCE 이스터에그 비행기. PhysicsBody 부착 0 — 순수 시각.
/// Sprint 10 Phase G — 6 자식 attach* 메서드 폐기 → 원본 16×5 도트 매트릭스 + SCALE=3 픽셀 텍스처.
/// init에서 texture/zPosition만 부여하고, scene.size 의존인 SKAction은 외부 호출자가
/// crossScreen(sceneWidth:atY:)을 부르는 시점에 시작한다.
/// SKAction.sequence([move, removeFromParent])로 자가 소멸(fire-and-forget).
final class AirplaneNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Pixel Matrix (Sprint 10 Phase G)
    /// 원본 game.js L3328~L3336 byte-equal 16×5 도트 매트릭스. SCALE=3 → 48×15 px.
    /// 'A' = 동체 본색(#aab3c7), 'W' = 조종석 창문(#e2e7ef), '.' = 투명.
    /// 첫 행이 위쪽 — UIGraphicsImageRenderer는 y가 아래로 증가하므로 자연 정합.
    private static let airplaneRows: [String] = [
        ".......A........",
        ".AAA.AAAAWAAA.A.",
        "AAAAAAAAAAAAAAA.",
        ".AAA.AAAAWAAA.A.",
        ".......A........"
    ]

    /// 도트 매트릭스 팔레트. 'A'/'W' 두 색만 — '.'은 팔레트 미등록 = 자연 투명.
    /// inline UIColor literal 아닌 GameConfig extension(.ganhoPixelPlaneBody/Window) 재사용 — DRY.
    private static let airplanePalette: [Character: UIColor] = [
        "A": .ganhoPixelPlaneBody,
        "W": .ganhoPixelPlaneWindow
    ]

    // MARK: - Init
    init() {
        // Sprint 10 Phase G — texture 1회 생성 + size는 texture.size() 사용.
        // 16×5×SCALE3 = 48×15 px → 시각이 화면(640~852pt 가로)에서 작아 보이지 않도록 SKAction.move 그대로.
        let tex = PixelSpriteRenderer.texture(
            rows: Self.airplaneRows,
            palette: Self.airplanePalette,
            scale: GameConfig.airplanePixelScale
        )
        super.init(texture: tex, color: .clear, size: tex.size())
        name = "airplane"
        // HUD(100) 아래, 일반 노드(5) 위. 점수 라벨을 가리지 않으며 공중에 떠 있는 느낌.
        zPosition = 50
        // Sprint 10 Phase G — 6 자식 attach* 메서드 호출 폐기. 원본은 16×5 픽셀 본체만 노출.
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cross (시그니처 byte-identical 보존)
    /// 부모(cameraNode)에 addChild 직후 호출. 화면 좌측 바깥에서 시작 → 우측 바깥까지 이동 → 자가 제거.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 시작/끝 모두 화면 바깥(노드 폭만큼 여유).
    /// - Parameters:
    ///   - sceneWidth: 씬 가로 크기(scene.size.width). 좌우 바깥 좌표 계산용.
    ///   - y: cameraNode 좌표계 y (화면 중앙 기준). 화면 상단 가까이 = 양수.
    func crossScreen(sceneWidth: CGFloat, atY y: CGFloat) {
        let startX = -(sceneWidth / 2 + size.width)
        let endX   = +(sceneWidth / 2 + size.width)
        position = CGPoint(x: startX, y: y)
        let move    = SKAction.move(to: CGPoint(x: endX, y: y),
                                    duration: GameConfig.airplaneCrossDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([move, cleanup]))
    }
}
