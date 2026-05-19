//
//  ComboPopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-10 · 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 + 자가 소멸 (시각 폴리싱)
//  Sprint 3 · v2 디자인 시스템 — Jua 32pt + v2 토큰 색 매핑 + navy 외곽선 4방향 + -8° 회전
//

import SpriteKit

/// 콤보 마일스톤(3/5/10/20) 도달 시 화면 중앙에 떠오르는 자가 소멸 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 고정.
/// AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode 패턴 답습 —
/// 자가 소멸 노드 6회차.
/// Sprint 3 — fontName fontDisplay + 새 fontSize 32 + v2 색 매핑 + navy 외곽선 + -8° 회전.
/// **animate() SKAction 본문은 0건 변경.**
final class ComboPopupNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 마일스톤 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode

    // MARK: - Init
    /// 마일스톤 값(3/5/10/20 등)을 받아 텍스트와 색을 결정.
    /// 텍스트 포맷 "x\(milestone)" — 라벨 1개로 깔끔한 단일 메시지.
    init(milestone: Int) {
        self.label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        self.label.text = "x\(milestone)"
        super.init()
        name = "comboPopup"
        zPosition = GameConfig.comboPopupZPosition
        let color = Self.color(for: milestone)
        configureLabel(color: color)
        // Sprint 3 — navy 외곽선 시뮬레이션: 4방향(±1pt) 자식 4개를 라벨 *뒤*(z=-1)에 배치.
        addOutline(text: "x\(milestone)")
        addChild(label)
        // Sprint 3 — 살짝 비스듬한 회전 (-8°).
        zRotation = GameConfig.comboPopupV2RotationDegrees * .pi / 180
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animate
    /// 부모(cameraNode)에 addChild 직후 호출. group(move + fade + scale) 동시 진행 → 자가 제거.
    /// SKAction.group은 [move, fade, scale] 3개를 *동시* 실행 — CompletableFuture.allOf 패턴.
    /// self 미사용 — [weak self] 캡처 불필요.
    /// **Sprint 3: SKAction 본문 0건 변경.**
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
        label.fontSize = GameConfig.comboPopupV2FontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 0
    }

    /// Sprint 3 — navy 외곽선 4방향 시뮬레이션. 본 라벨 뒤(z=-1)에 navy 라벨 4개 ±1pt 오프셋.
    /// 4 라벨은 본 폰트/사이즈/정렬 동일, fontColor만 navy + position만 4방향.
    private func addOutline(text: String) {
        let offset = GameConfig.comboPopupV2OutlineWidth
        let offsets: [CGPoint] = [
            CGPoint(x: -offset, y:  0),
            CGPoint(x: +offset, y:  0),
            CGPoint(x:  0,      y: -offset),
            CGPoint(x:  0,      y: +offset)
        ]
        for off in offsets {
            let outline = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            outline.text = text
            outline.fontSize = GameConfig.comboPopupV2FontSize
            outline.fontColor = .ganhoNavyDeep
            outline.verticalAlignmentMode = .center
            outline.horizontalAlignmentMode = .center
            outline.position = off
            outline.zPosition = -1
            addChild(outline)
        }
    }

    // MARK: - Color Mapping (Sprint 3 v2)
    /// 마일스톤 값 → ColorTokens v2 매핑. 미일치 시 기본 ganhoMusicGold로 graceful fallback.
    /// case 3 골드, 5 코랄, 10 골드(황금기 강조), 20 코랄 쉐도우(클라이맥스).
    /// 정적 메서드: 외부 상태 의존 0 — 입력 같으면 출력 같음(pure function).
    private static func color(for milestone: Int) -> UIColor {
        switch milestone {
        case 3:  return .ganhoMusicGold     // 골드 — 첫 도달
        case 5:  return .ganhoCoralPrimary  // 코랄 — 음악의 따뜻함
        case 10: return .ganhoMusicGold     // 황금 — 노트의 황금기
        case 20: return .ganhoCoralShadow   // 진한 코랄 — 클라이맥스
        default: return .ganhoMusicGold     // 미래 마일스톤 대비
        }
    }
}
