//
//  ScorePopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-16 · 음표 수집 자리에 실제 가산점 플로팅 텍스트 (자가 소멸 노드 9호)
//  R1 · Poolable 채택 — private init(gainedPoints:) → init() + configure(gainedPoints:)로
//    내부 개편(풀 재사용 호환). 외부 진입점은 spawn 정적 팩토리 하나 유지(pool 인자 추가).
//

import SpriteKit

/// 노트 수집 좌표에서 위로 떠오르며 풀로 회수되는 "+1"부터 "+4"까지의 실제 가산점 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. worldNode 자식으로 부착 (sparkle과 동일 부모) →
/// 카메라 follow와 자연 동기. 콤보 마일스톤(cameraNode 자식, 화면 중앙 고정)과는
/// 의도적으로 다른 부모 — 마일스톤은 *글로벌* 시그널, 점수 팝업은 *지역* 시그널.
///
/// 외부에서 init을 직접 호출하지 못하게 정적 팩토리 `spawn(at:gainedPoints:parent:pool:)`
/// 하나만 진입점으로 노출 — position 설정 누락 같은 사용자 실수를 사용 규약으로 차단.
/// (R1: init은 풀 factory가 빈 인스턴스를 만들 수 있도록 개방하되 텍스트/색/티어는
///  configure가 set — 인자 없는 init만으로는 의미 있는 팝업이 만들어지지 않는다.)
///
/// 색상 의미:
/// - `.ganhoPixelHudWhite` → 기본 +1 — 노트 1개 수집의 기본 HUD 톤.
/// - `.ganhoPixelHudYellow` → 콤보 +2 — 첫 콤보 보너스 진입 시그널.
/// - `.ganhoPixelComboGold` → 콤보 +3 — 중간 가산점 티어 시그널.
/// - `.ganhoPixelComboRed` → 콤보 +4 — 최고 가산점 티어 시그널.
///
/// 티어별 색상 변화 자체가 콤보가 높을수록 실제 가산점이 커진다는 점수 규칙의 학습 채널 —
/// 텍스트 설명 없이 시각만으로 보너스 상승을 인지하게 만드는 마이크로 폴리싱.
///
/// Spring 비유: Spring AOP의 @AfterReturning advice — 비즈니스 메서드(recordNoteHit) 직후
/// 반환값(가산 점수)을 *시각 채널로 투사*만 한다. 본 메서드(ScoreSystem)는 미접촉.
final class ScorePopupNode: SKNode, SelfDismissingNode, Poolable {

    // MARK: - Properties
    /// 가산점 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode
    /// 최고 점수 티어 여부. +4 팝업만 아주 짧은 자체 흔들림을 추가한다.
    /// R1 — 풀 재사용을 위해 let → var (SPEC 명시 허용). configure가 매 사용 시 set.
    private var isHighTier: Bool = false

    // MARK: - Recycle (R1)
    /// 풀 회수 핸들러. spawn이 obtain 시 [weak pool] 캡처로 주입 —
    /// strong 캡처 시 풀(storage)→노드→핸들러→풀 순환 참조가 생기므로 weak 필수.
    /// nil이면 removeFromParent fallback(풀 미배선 안전망 — 구 자가 소멸과 동일 동작).
    private var recycleHandler: ((ScorePopupNode) -> Void)?

    // MARK: - Init (풀 factory 전용 — 외부 사용 진입점은 spawn)
    /// 빈 팝업 골격 생성. 텍스트/색/티어는 configure(gainedPoints:)가 사용 시점에 set.
    override init() {
        // Sprint 10 Phase J — fontPixel(Menlo-Bold). 인게임 픽셀 톤 통일.
        self.label = SKLabelNode(fontNamed: Typography.fontPixel)
        super.init()
        name = "scorePopup"
        zPosition = ZOrder.scorePopupZPosition
        configureLabelLayout()
        // 시작 시 살짝 작게 — *부풀어 오르는* 톤. ComboPopup(1.0→1.4)보다 약한 *지역* 시그널.
        setScale(FeelTuning.scorePopupStartScale)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Spawn (static factory — 외부 유일 진입점)
    /// 노트 수집 좌표에서 실제 가산점을 띄우는 자가 회수 텍스트.
    /// - Parameters:
    ///   - position: 노트가 수집된 worldNode 좌표 (sparkle.position과 동일 권장).
    ///   - gainedPoints: 가산 점수. ScoreSystem.recordNoteHit의 반환값.
    ///   - parent: 부착 부모. 호출부에서 `worldNode`를 전달 — sparkle과 동일 부모 → 카메라 follow 동기.
    ///   - pool: GameScene 소유 풀 (R1 — obtain/회수 모두 이 풀 경유).
    static func spawn(at position: CGPoint,
                      gainedPoints: Int,
                      parent: SKNode,
                      pool: ObjectPool<ScorePopupNode>) {
        let node = pool.obtain()
        node.configure(gainedPoints: gainedPoints)
        node.recycleHandler = { [weak pool] popup in pool?.recycle(popup) }
        // 시작 위치: 노트 중심 위쪽 +12pt — 노트 본체(16pt)와 텍스트가 같은 픽셀에서 겹치지 않게.
        node.position = CGPoint(x: position.x,
                                y: position.y + FeelTuning.scorePopupStartOffsetY)
        parent.addChild(node)
        node.animate()
    }

    // MARK: - Configure (R1 — obtain 직후 매 사용 시 호출)
    /// 가산 점수에 따라 텍스트/색/티어 set — 구 private init(gainedPoints:)의 가변 절반.
    private func configure(gainedPoints: Int) {
        label.text = Self.text(for: gainedPoints)
        label.fontColor = Self.color(for: gainedPoints)
        isHighTier = gainedPoints >= GameplayTuning.scorePerNoteComboHigh
    }

    // MARK: - Animate (private — spawn에서만 호출)
    /// 부모 addChild 직후 호출. 짧은 pop-in 뒤 move + fade를 동시 진행 → 풀 회수.
    /// R1 — 말미 cleanup이 removeFromParent → requestRecycle(풀 회수)로 교체.
    private func animate() {
        let pop = SKAction.scale(to: FeelTuning.scorePopupPopScale,
                                 duration: FeelTuning.scorePopupPopDuration)
        let settle = SKAction.scale(to: FeelTuning.scorePopupEndScale,
                                    duration: FeelTuning.scorePopupSettleDuration)
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: FeelTuning.scorePopupFlyUpDistance,
                                       duration: FeelTuning.scorePopupDuration)
        let fadeOut = SKAction.fadeOut(withDuration: FeelTuning.scorePopupDuration)
        let floatGroup = SKAction.group([moveUp, fadeOut])
        let cleanup = SKAction.run { [weak self] in self?.requestRecycle() }
        let mainSequence = SKAction.sequence([pop, settle, floatGroup, cleanup])
        if isHighTier {
            run(.group([mainSequence, makeHighTierShake()]))
        } else {
            run(mainSequence)
        }
    }

    private func makeHighTierShake() -> SKAction {
        let right = SKAction.moveBy(x: FeelTuning.scorePopupTierHighShakeX,
                                    y: 0,
                                    duration: FeelTuning.scorePopupTierHighShakeDuration)
        let left = SKAction.moveBy(x: -FeelTuning.scorePopupTierHighShakeX * 2,
                                   y: 0,
                                   duration: FeelTuning.scorePopupTierHighShakeDuration)
        let center = SKAction.moveBy(x: FeelTuning.scorePopupTierHighShakeX,
                                     y: 0,
                                     duration: FeelTuning.scorePopupTierHighShakeDuration)
        return .sequence([right, left, center])
    }

    // MARK: - Poolable (R1)
    /// 회수 단일 진입점 — animate 말미가 호출.
    func requestRecycle() {
        if let handler = recycleHandler {
            handler(self)
        } else {
            removeFromParent()
        }
    }

    /// 재사용 직전 신품 복원 — 잔존 애니메이션 제거 + alpha/scale을 init 직후 상태로.
    /// position은 spawn이 매번 절대 좌표로 set하지만 불변식(보관 = 신품 상태) 유지 차원에서 0 복원.
    func resetForReuse() {
        removeAllActions()
        alpha = 1
        setScale(FeelTuning.scorePopupStartScale)
        position = .zero
    }

    // MARK: - Label Layout
    /// 라벨 고정 스타일 — 크기/정렬은 1회만 (색·텍스트는 configure가 매 사용 시 set).
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabelLayout() {
        label.fontSize = FeelTuning.scorePopupFontSize
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }

    private static func text(for gainedPoints: Int) -> String {
        switch gainedPoints {
        case GameplayTuning.scorePerNote:
            return "+\(GameplayTuning.scorePerNote)"
        case GameplayTuning.scorePerNoteCombo:
            return "+\(GameplayTuning.scorePerNoteCombo) \(FeelTuning.scorePopupTextComboSuffix)"
        case GameplayTuning.scorePerNoteComboMid:
            return "+\(GameplayTuning.scorePerNoteComboMid) \(FeelTuning.scorePopupTextComboSuffix)"
        case GameplayTuning.scorePerNoteComboHigh:
            return "+\(GameplayTuning.scorePerNoteComboHigh) \(FeelTuning.scorePopupTextComboSuffix)"
        default:
            return "+\(gainedPoints)"
        }
    }

    // MARK: - Color Mapping (pure function, fallback 흰빛)
    /// 가산 점수 → ColorTokens 매핑. ScoreSystem.recordNoteHit의 점수 분기와 동일 조건 사용.
    /// 정적 메서드: 외부 상태 의존 0 — 입력 같으면 출력 같음(pure function).
    /// ComboPopupNode.color(for:) static 메서드와 위치/형태 대칭.
    /// +1/+2/+3/+4 실제 가산점 티어를 기존 픽셀 팔레트로 구분.
    /// 인게임 점수 팝업, HUD, 콤보 색상이 같은 픽셀 팔레트를 공유 → 시각 일관성.
    private static func color(for gainedPoints: Int) -> UIColor {
        switch gainedPoints {
        case GameplayTuning.scorePerNote:
            return .ganhoPixelHudWhite
        case GameplayTuning.scorePerNoteCombo:
            return .ganhoPixelHudYellow
        case GameplayTuning.scorePerNoteComboMid:
            return .ganhoPixelComboGold
        case GameplayTuning.scorePerNoteComboHigh:
            return .ganhoPixelComboRed
        default:
            return .ganhoPixelHudWhite
        }
    }
}
