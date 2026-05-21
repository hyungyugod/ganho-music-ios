//
//  AirforceOverlayNode.swift
//  GanhoMusic Shared
//
//  Phase 4-4 · AIRFORCE 오버레이 — "나와라 박병장!" 텍스트 + 자가 페이드아웃
//

import SpriteKit

/// AIRFORCE 이스터에그 호출 텍스트 오버레이. PhysicsBody 부착 0 — 순수 시각.
/// 자식 SKLabelNode 1개("나와라 박병장!") 컨테이너.
/// init에서 색·폰트·정렬·zPosition만 부여하고, 외부 호출자가 showAndDismiss()를
/// 부르는 시점에 SKAction.sequence([wait, fadeOut, removeFromParent])로 자가 소멸.
/// AirplaneNode 패턴 답습 — fire-and-forget.
final class AirforceOverlayNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    private let label: SKLabelNode

    // MARK: - Init
    override init() {
        label = SKLabelNode(text: "나와라 박병장!")
        super.init()
        name = "airforceOverlay"
        // HUD(100) 위 — 이스터에그 강조. AirplaneNode(50)보다도 위. 1.8초만 존재.
        zPosition = 200
        configureLabel()
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Show / Dismiss
    /// 부모(cameraNode)에 addChild 직후 호출. 1.5초 대기 → 0.3초 페이드아웃 → 자가 제거.
    /// self 미사용 — [weak self] 캡처 불필요.
    func showAndDismiss() {
        let wait    = SKAction.wait(forDuration: GameConfig.airforceOverlayDisplayDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.airforceOverlayFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, fadeOut, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — Sprint 10 Phase G 픽셀 톤 통일.
    /// fontName: pixelOverlayFontName(Menlo-Bold) — PressStart2P 미설치 → 안티앨리어싱 적은 등폭 픽셀 톤.
    /// fontColor: ganhoPixelWarning(#FFD23F) — 비행기/폭탄과 톤 정합.
    /// cameraNode 자식 (0,0) = 화면 중앙. label position도 (0,0)으로 두면 화면 정중앙.
    private func configureLabel() {
        label.fontName = GameConfig.pixelOverlayFontName
        label.fontSize = GameConfig.airforceOverlayFontSize
        label.fontColor = .ganhoPixelWarning
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
