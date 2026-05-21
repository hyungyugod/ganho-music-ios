//
//  TensionVignetteNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase J · 5초 긴박감 픽셀 비네트 (마지막 Phase 신규 노드)
//
//  HUDNode.startTensionBlink가 timeSlot 깜빡임만 담당한다면, 본 노드는 *화면 가장자리*를
//  픽셀 톤 코랄로 액자처럼 둘러 깜빡인다. 두 노드는 같은 박자(0.5s halfPeriod)로 동기 →
//  TIME 라벨 깜빡임 + 비네트 깜빡임이 함께 발화해 절체절명 톤 환기.
//
//  Spring 비유: 같은 이벤트(긴박감 진입)를 listen하는 *두 번째 listener* — 단일 책임 분리.
//

import SpriteKit

/// 5초 긴박감 윈도우 동안 화면 가장자리 4변(상/하/좌/우)을 픽셀 코랄로 둘러싸는 비네트.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 부착해 카메라 follow와 무관하게 화면 고정.
/// 4 자식 모두 `SKAction.repeatForever`로 알파 깜빡임 — 0.3 ↔ 0.7 (`tensionVignetteBlinkHalfPeriod` 0.5s).
/// detach는 외부(GameScene.stopTensionBlink 부근)가 removeFromParent로 명시 — 자가 소멸 0.
///
/// zPosition = 110: HUD 슬롯(99~101) 위 + countdownZPosition(250 ~ 300) 아래 → 인게임 중 살짝 덮되
/// 카운트다운/플래시는 안 가림.
final class TensionVignetteNode: SKNode {

    // MARK: - Init
    /// 화면 크기를 받아 4변 SKSpriteNode를 자식으로 부착. cameraNode 자식 좌표계에서
    /// (0,0) = 화면 중앙 → 상/하/좌/우 가장자리에 inset.
    /// - Parameter sceneSize: GameScene.size 그대로 — 시뮬레이터 회전 시에도 호출자가 재생성하면 자연 대응.
    init(sceneSize: CGSize) {
        super.init()
        name = "tensionVignette"
        zPosition = GameConfig.tensionVignetteZPosition
        buildEdges(sceneSize: sceneSize)
        startBlink()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Edges
    /// 4변 SKSpriteNode 생성 — 색 ganhoPixelTensionEdge, 기본 알파 0.6.
    /// 상/하: 폭=전체 화면, 높이=thickness. 좌/우: 폭=thickness, 높이=전체 화면.
    /// 모서리는 상/하 막대가 덮음(L-shape 겹침 → 더 진한 코너) — 시각 의도된 강조.
    private func buildEdges(sceneSize: CGSize) {
        let thickness = GameConfig.tensionVignetteThickness
        let alpha = GameConfig.tensionVignetteEdgeAlpha
        let halfW = sceneSize.width / 2
        let halfH = sceneSize.height / 2

        // 상단 가로 막대
        let top = SKSpriteNode(
            color: .ganhoPixelTensionEdge,
            size: CGSize(width: sceneSize.width, height: thickness)
        )
        top.alpha = alpha
        top.position = CGPoint(x: 0, y: halfH - thickness / 2)
        addChild(top)

        // 하단 가로 막대
        let bottom = SKSpriteNode(
            color: .ganhoPixelTensionEdge,
            size: CGSize(width: sceneSize.width, height: thickness)
        )
        bottom.alpha = alpha
        bottom.position = CGPoint(x: 0, y: -halfH + thickness / 2)
        addChild(bottom)

        // 좌측 세로 막대 — 상/하 막대가 두께만큼 코너를 가린 후 그 안쪽 길이로.
        let left = SKSpriteNode(
            color: .ganhoPixelTensionEdge,
            size: CGSize(width: thickness, height: sceneSize.height - thickness * 2)
        )
        left.alpha = alpha
        left.position = CGPoint(x: -halfW + thickness / 2, y: 0)
        addChild(left)

        // 우측 세로 막대
        let right = SKSpriteNode(
            color: .ganhoPixelTensionEdge,
            size: CGSize(width: thickness, height: sceneSize.height - thickness * 2)
        )
        right.alpha = alpha
        right.position = CGPoint(x: halfW - thickness / 2, y: 0)
        addChild(right)
    }

    // MARK: - Blink
    /// 4 자식 모두 동일 깜빡임 액션 — fadeAlpha 0.3 ↔ 0.7, 0.5s. HUD TIME 슬롯 깜빡임과 같은 박자.
    /// SKAction.repeatForever — detach 시 SpriteKit이 자식 액션도 함께 정리(removeAllActions 불필요).
    private func startBlink() {
        let half = GameConfig.tensionVignetteBlinkHalfPeriod
        let minA = GameConfig.tensionVignetteBlinkAlphaMin
        let maxA = GameConfig.tensionVignetteBlinkAlphaMax
        let toMin = SKAction.fadeAlpha(to: minA, duration: half)
        let toMax = SKAction.fadeAlpha(to: maxA, duration: half)
        let cycle = SKAction.sequence([toMin, toMax])
        for child in children {
            child.run(.repeatForever(cycle))
        }
    }
}
