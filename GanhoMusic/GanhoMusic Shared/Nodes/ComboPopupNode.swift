//
//  ComboPopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-10 · 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 + 자가 소멸 (시각 폴리싱)
//

import SpriteKit

/// 콤보 마일스톤(3/5/10/20) 도달 시 화면 중앙에 떠오르는 자가 소멸 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 고정.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode 패턴 답습 —
/// 자가 소멸 노드 6회차.
/// Spring 비유: HTTP 상태 코드 색상 매핑 — 마일스톤 등급별 시각적 위계
/// (2xx 흰 / 3xx 분홍 / 4xx 노랑 / 5xx 빨강과 동형).
final class ComboPopupNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 마일스톤 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode

    // MARK: - Init
    /// 마일스톤 값(3/5/10/20 등)을 받아 텍스트와 색을 결정.
    /// 텍스트 포맷 "x\(milestone)" — 라벨 1개로 깔끔한 단일 메시지.
    init(milestone: Int) {
        self.label = SKLabelNode(text: "x\(milestone)")
        super.init()
        name = "comboPopup"
        zPosition = GameConfig.comboPopupZPosition
        configureLabel(color: Self.color(for: milestone))
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animate
    /// 부모(cameraNode)에 addChild 직후 호출. group(move + fade + scale) 동시 진행 → 자가 제거.
    /// SKAction.group은 [move, fade, scale] 3개를 *동시* 실행 — CompletableFuture.allOf 패턴.
    /// self 미사용 — [weak self] 캡처 불필요.
    func animate() {
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: GameConfig.comboPopupFlyUpDistance,
                                       duration: GameConfig.comboPopupDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.comboPopupDuration)
        let scaleUp = SKAction.scale(to: GameConfig.comboPopupEndScale,
                                      duration: GameConfig.comboPopupDuration)
        let group   = SKAction.group([moveUp, fadeOut, scaleUp])
        let cleanup = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 마일스톤 색상, 중앙 정렬. cameraNode 자식 (0,0) = 화면 중앙.
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabel(color: UIColor) {
        label.fontSize = GameConfig.comboPopupFontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }

    // MARK: - Color Mapping
    /// 마일스톤 값 → ColorTokens 매핑. 미일치 시 기본 .ganhoPaper로 graceful fallback.
    /// 색은 등급이 올라갈수록 강렬해진다 (HTTP 상태 코드 색상 위계와 동형).
    /// 정적 메서드: 외부 상태 의존 0 — 입력 같으면 출력 같음(pure function).
    private static func color(for milestone: Int) -> UIColor {
        switch milestone {
        case 3:  return .ganhoPaper        // 흰빛 — 첫 도달
        case 5:  return .ganhoPinkNote     // 분홍 — 음악 본체 색
        case 10: return .ganhoYellowF      // 황금 — 노트의 황금기
        case 20: return .ganhoBloodAccent  // 빨강 — 클라이맥스
        default: return .ganhoPaper        // 미래 마일스톤 대비
        }
    }
}
