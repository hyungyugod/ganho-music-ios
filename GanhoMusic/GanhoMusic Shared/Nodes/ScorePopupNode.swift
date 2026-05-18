//
//  ScorePopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-16 · 음표 수집 자리에 +1 / +2 플로팅 텍스트 (자가 소멸 노드 9호)
//

import SpriteKit

/// 노트 수집 좌표에서 위로 떠오르며 자가 소멸하는 "+1" 또는 "+2" 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. worldNode 자식으로 부착 (sparkle과 동일 부모) →
/// 카메라 follow와 자연 동기. 콤보 마일스톤(cameraNode 자식, 화면 중앙 고정)과는
/// 의도적으로 다른 부모 — 마일스톤은 *글로벌* 시그널, 점수 팝업은 *지역* 시그널.
///
/// 자가 소멸 노드 패턴 답습 (AirplaneNode / AirforceOverlayNode / BombFlashNode /
/// SparkleEffectNode / HitFlashNode / ComboPopupNode / ComboBreakNode / CountdownNode) —
/// 자가 소멸 노드 *9호*. 단, 본 노드는 외부에서 `init`을 직접 호출하지 못하게
/// init을 private으로 두고 정적 팩토리 `spawn(at:gainedPoints:parent:)` 하나만 노출 —
/// 사용자 실수(position 설정 누락 등)를 *컴파일 타임에* 차단하는 패턴 진화 형태.
///
/// 색상 의미:
/// - `.ganhoPaper` (흰빛) → 기본 +1 — 노트 1개 수집의 흰빛 (HUD/시작 마일스톤과 동형).
/// - `.ganhoYellowF` (황금) → 콤보 ×2 +2 — 콤보 보너스의 *황금기* 톤 (F 투사체와 동일 색이나
///   콤보 마일스톤 x10 황금과 의미 공유: *2배 점수 획득*의 시각 시그널).
///
/// 두 색상의 *대비* 자체가 "콤보 3부터 2배"라는 점수 규칙의 학습 채널 — 텍스트 설명 없이
/// 시각만으로 보너스 발동을 인지하게 만드는 마이크로 폴리싱.
///
/// Spring 비유: Spring AOP의 @AfterReturning advice — 비즈니스 메서드(recordNoteHit) 직후
/// 반환값(가산 점수)을 *시각 채널로 투사*만 한다. 본 메서드(ScoreSystem)는 미접촉.
final class ScorePopupNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// "+1" 또는 "+2" 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode

    // MARK: - Init (private — spawn factory에서만 호출)
    /// 가산 점수(1 또는 2)를 받아 텍스트와 색을 결정.
    /// `private init` — 외부 호출자가 *반드시* `spawn` 정적 팩토리를 거치도록 강제 →
    /// position 설정 누락 같은 사용자 실수 컴파일 타임 차단 (패턴 진화).
    private init(gainedPoints: Int) {
        self.label = SKLabelNode(text: "+\(gainedPoints)")
        super.init()
        name = "scorePopup"
        zPosition = GameConfig.scorePopupZPosition
        configureLabel(color: Self.color(for: gainedPoints))
        // 시작 시 살짝 작게 — *부풀어 오르는* 톤. ComboPopup(1.0→1.4)보다 약한 *지역* 시그널.
        setScale(GameConfig.scorePopupStartScale)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Spawn (static factory — 외부 유일 진입점)
    /// 노트 수집 좌표에서 +1 또는 +2를 띄우는 자가 소멸 텍스트.
    /// - Parameters:
    ///   - position: 노트가 수집된 worldNode 좌표 (sparkle.position과 동일 권장).
    ///   - gainedPoints: 가산 점수. `GameConfig.scorePerNote` 또는 `GameConfig.scorePerNoteCombo`.
    ///     그 외 값은 graceful fallback (+1 흰빛) — 미래 점수 시스템 확장 안전망.
    ///   - parent: 부착 부모. 호출부에서 `worldNode`를 전달 — sparkle과 동일 부모 → 카메라 follow 동기.
    static func spawn(at position: CGPoint, gainedPoints: Int, parent: SKNode) {
        let node = ScorePopupNode(gainedPoints: gainedPoints)
        // 시작 위치: 노트 중심 위쪽 +12pt — 노트 본체(16pt)와 텍스트가 같은 픽셀에서 겹치지 않게.
        node.position = CGPoint(x: position.x,
                                y: position.y + GameConfig.scorePopupStartOffsetY)
        parent.addChild(node)
        node.animate()
    }

    // MARK: - Animate (private — spawn에서만 호출)
    /// 부모 addChild 직후 호출. group(move + fade + scale) 동시 진행 → 자가 제거.
    /// SKAction.group은 [move, fade, scale] 3개를 *동시* 실행 — CompletableFuture.allOf 패턴.
    /// self 미사용 → [weak self] 캡처 불필요.
    /// ComboPopupNode.animate() 완전 답습 — 차이는 distance/scale/duration 상수값만.
    private func animate() {
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: GameConfig.scorePopupFlyUpDistance,
                                       duration: GameConfig.scorePopupDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.scorePopupDuration)
        let scaleUp = SKAction.scale(to: GameConfig.scorePopupEndScale,
                                      duration: GameConfig.scorePopupDuration)
        let group   = SKAction.group([moveUp, fadeOut, scaleUp])
        let cleanup = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 가산 점수에 따른 색, 중앙 정렬. fontName 미지정 (다른 자가 소멸 노드 일관).
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabel(color: UIColor) {
        label.fontSize = GameConfig.scorePopupFontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }

    // MARK: - Color Mapping (pure function, fallback +1 흰빛)
    /// 가산 점수 → ColorTokens 매핑. ScoreSystem.recordNoteHit의 점수 분기와 동일 조건 사용.
    /// 정적 메서드: 외부 상태 의존 0 — 입력 같으면 출력 같음(pure function).
    /// ComboPopupNode.color(for:) static 메서드와 위치/형태 대칭.
    private static func color(for gainedPoints: Int) -> UIColor {
        switch gainedPoints {
        case GameConfig.scorePerNote:      return .ganhoPaper        // +1 흰빛 — 기본 수집
        case GameConfig.scorePerNoteCombo: return .ganhoYellowF      // +2 황금 — 콤보 보너스
        default:                            return .ganhoPaper       // 미래 점수 확장 대비 graceful fallback
        }
    }
}
