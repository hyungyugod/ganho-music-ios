//
//  ScorePopupNode.swift
//  GanhoMusic Shared
//
//  Phase 6-16 · 음표 수집 자리에 실제 가산점 플로팅 텍스트 (자가 소멸 노드 9호)
//

import SpriteKit

/// 노트 수집 좌표에서 위로 떠오르며 자가 소멸하는 "+1"부터 "+4"까지의 실제 가산점 텍스트.
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
final class ScorePopupNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 가산점 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode
    /// 최고 점수 티어 여부. +4 팝업만 아주 짧은 자체 흔들림을 추가한다.
    private let isHighTier: Bool

    // MARK: - Init (private — spawn factory에서만 호출)
    /// 가산 점수를 받아 텍스트와 색을 결정.
    /// `private init` — 외부 호출자가 *반드시* `spawn` 정적 팩토리를 거치도록 강제 →
    /// position 설정 누락 같은 사용자 실수 컴파일 타임 차단 (패턴 진화).
    private init(gainedPoints: Int) {
        // Sprint 10 Phase J — fontNamed 미지정(시스템 폰트) → fontPixel(Menlo-Bold). 인게임 픽셀 톤 통일.
        self.label = SKLabelNode(fontNamed: GameConfig.fontPixel)
        self.label.text = Self.text(for: gainedPoints)
        self.isHighTier = gainedPoints >= GameConfig.scorePerNoteComboHigh
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
    /// 노트 수집 좌표에서 실제 가산점을 띄우는 자가 소멸 텍스트.
    /// - Parameters:
    ///   - position: 노트가 수집된 worldNode 좌표 (sparkle.position과 동일 권장).
    ///   - gainedPoints: 가산 점수. ScoreSystem.recordNoteHit의 반환값.
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
    /// 부모 addChild 직후 호출. 짧은 pop-in 뒤 move + fade를 동시 진행 → 자가 제거.
    /// self 캡처 없이 액션만 조립한다.
    private func animate() {
        let pop = SKAction.scale(to: GameConfig.scorePopupPopScale,
                                 duration: GameConfig.scorePopupPopDuration)
        let settle = SKAction.scale(to: GameConfig.scorePopupEndScale,
                                    duration: GameConfig.scorePopupSettleDuration)
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: GameConfig.scorePopupFlyUpDistance,
                                       duration: GameConfig.scorePopupDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.scorePopupDuration)
        let floatGroup = SKAction.group([moveUp, fadeOut])
        let cleanup = SKAction.removeFromParent()
        let mainSequence = SKAction.sequence([pop, settle, floatGroup, cleanup])
        if isHighTier {
            run(.group([mainSequence, makeHighTierShake()]))
        } else {
            run(mainSequence)
        }
    }

    private func makeHighTierShake() -> SKAction {
        let right = SKAction.moveBy(x: GameConfig.scorePopupTierHighShakeX,
                                    y: 0,
                                    duration: GameConfig.scorePopupTierHighShakeDuration)
        let left = SKAction.moveBy(x: -GameConfig.scorePopupTierHighShakeX * 2,
                                   y: 0,
                                   duration: GameConfig.scorePopupTierHighShakeDuration)
        let center = SKAction.moveBy(x: GameConfig.scorePopupTierHighShakeX,
                                     y: 0,
                                     duration: GameConfig.scorePopupTierHighShakeDuration)
        return .sequence([right, left, center])
    }

    // MARK: - Configure
    /// 라벨 스타일 — 가산 점수에 따른 색, 중앙 정렬. fontPixel 기반 인게임 픽셀 톤.
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabel(color: UIColor) {
        label.fontSize = GameConfig.scorePopupFontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }

    private static func text(for gainedPoints: Int) -> String {
        switch gainedPoints {
        case GameConfig.scorePerNote:
            return "+\(GameConfig.scorePerNote)"
        case GameConfig.scorePerNoteCombo:
            return "+\(GameConfig.scorePerNoteCombo) \(GameConfig.scorePopupTextComboSuffix)"
        case GameConfig.scorePerNoteComboMid:
            return "+\(GameConfig.scorePerNoteComboMid) \(GameConfig.scorePopupTextComboSuffix)"
        case GameConfig.scorePerNoteComboHigh:
            return "+\(GameConfig.scorePerNoteComboHigh) \(GameConfig.scorePopupTextComboSuffix)"
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
        case GameConfig.scorePerNote:
            return .ganhoPixelHudWhite
        case GameConfig.scorePerNoteCombo:
            return .ganhoPixelHudYellow
        case GameConfig.scorePerNoteComboMid:
            return .ganhoPixelComboGold
        case GameConfig.scorePerNoteComboHigh:
            return .ganhoPixelComboRed
        default:
            return .ganhoPixelHudWhite
        }
    }
}
