//
//  ComboBreakNode.swift
//  GanhoMusic Shared
//
//  Phase 6-12 · 콤보 끊김(10+) 시 화면 중앙 텍스트 팝업 + 자가 소멸 (실망의 시각)
//

import SpriteKit

/// 콤보 10+ 상태에서 0으로 떨어진 순간 화면 중앙에서 *아래로 떨어지며* 페이드아웃되는 자가 소멸 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 고정.
/// ComboPopupNode(환호, 6-10)의 *대칭점* — 위→아래, 확대→축소, 등급별 4색→단일 톤(`ganhoCrimsonNurse`).
/// AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode / ComboPopupNode 패턴 답습 —
/// 자가 소멸 노드 7회차.
/// Spring 비유: 4xx 에러 응답 — 시스템이 *손실*을 사용자에게 알리는 일회성 시그널.
final class ComboBreakNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 끊긴 콤보 값을 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode

    // MARK: - Init
    /// 끊기는 순간의 콤보 값을 받아 텍스트로 노출.
    /// 텍스트 포맷 "x{N} BREAK" — 단순 "BREAK"보다 *내가 잃은 것*을 명확히 보여줘 손실감 강화.
    init(brokenCombo: Int) {
        self.label = SKLabelNode(text: "x\(brokenCombo) BREAK")
        super.init()
        name = "comboBreak"
        zPosition = GameConfig.comboBreakZPosition
        configureLabel()
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animate
    /// 부모(cameraNode)에 addChild 직후 호출. group(move + fade + scale) 동시 진행 → 자가 제거.
    /// ComboPopupNode와 정확히 대칭: 이동 방향 -y(아래), scale 축소(0.7), 거리 짧음(60 < 80).
    /// 환호가 *위로 떠오름*이라면 실망은 *아래로 떨어짐* — 시간축은 동일(1.0초).
    /// self 미사용 — [weak self] 캡처 불필요.
    func animate() {
        let moveDown  = SKAction.moveBy(x: 0,
                                         y: -GameConfig.comboBreakFallDistance,
                                         duration: GameConfig.comboBreakDuration)
        let fadeOut   = SKAction.fadeOut(withDuration: GameConfig.comboBreakDuration)
        let scaleDown = SKAction.scale(to: GameConfig.comboBreakEndScale,
                                        duration: GameConfig.comboBreakDuration)
        let group     = SKAction.group([moveDown, fadeOut, scaleDown])
        let cleanup   = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 손실 시그널 색(`ganhoCrimsonNurse`), 중앙 정렬. cameraNode 자식 (0,0) = 화면 중앙.
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    /// 색은 단일 톤 — 환호(ComboPopupNode)는 등급별 4색이지만 끊김은 *값 하나*(임계값 10+).
    /// ColorTokens 추가 0건 — Sprint 최소화 (재사용 정책).
    private func configureLabel() {
        label.fontSize = GameConfig.comboBreakFontSize
        label.fontColor = .ganhoCrimsonNurse
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
