//
//  ToastLabelNode.swift
//  GanhoMusic Shared
//
//  Phase 9-6 · 변기 수집 시 "화캉스 보너스!" 0.9초 토스트 텍스트 (자가 소멸 노드 10호).
//  SparkleEffectNode / ScorePopupNode / ComboPopupNode 자가 소멸 노드 패턴 답습.
//

import SpriteKit

/// 변기 수집 좌표 위쪽에 0.9초간 떠오르며 자가 소멸하는 "화캉스 보너스!" 텍스트.
/// PhysicsBody 부착 0 — 순수 시각. worldNode 자식으로 부착 → 카메라 follow 자연 동기.
///
/// ScorePopupNode 패턴 정확 답습 — 차이는 텍스트(고정 "화캉스 보너스!") + 색(.ganhoYellowF) +
/// 시작 scale(0.8 → 1.1) + duration(0.9). 외부 진입점은 정적 팩토리 `spawn(text:at:parent:)` 단일.
///
/// SelfDismissingNode 채택 — 자가 소멸 노드 마커 프로토콜 일관성 유지.
///
/// Spring 비유: Spring AOP의 @AfterReturning advice — 비즈니스 메서드(recordToiletBonus) 직후
/// *시각 채널 부수효과*만 발화. 핵심 도메인(ScoreSystem) 미접촉 — 사이드카 패턴.
final class ToastLabelNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 토스트 텍스트를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    /// ScorePopupNode와 동형 구조.
    private let label: SKLabelNode

    // MARK: - Init (private — spawn factory에서만 호출)
    /// 외부 호출자가 *반드시* `spawn` 정적 팩토리를 거치도록 강제 → position 설정 누락 같은
    /// 사용자 실수 컴파일 타임 차단. ScorePopupNode와 동일 패턴.
    private init(text: String) {
        self.label = SKLabelNode(text: text)
        super.init()
        name = "toast"
        zPosition = GameConfig.toastZPosition
        configureLabel()
        // 시작 시 살짝 작게 — *부풀어 오르는* 톤. ScorePopupNode(0.8 → 1.0)과 동형.
        setScale(GameConfig.toastStartScale)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Spawn (static factory — 외부 유일 진입점)
    /// 변기 수집 좌표 위쪽에 토스트 텍스트를 띄우는 자가 소멸 라벨.
    /// - Parameters:
    ///   - text: 표시 텍스트. 호출부에서 `GameConfig.toiletToastText` 전달.
    ///   - position: 변기가 수집된 worldNode 좌표 (sparkle.position과 동일 권장).
    ///   - parent: 부착 부모. 호출부에서 `worldNode` 전달 — sparkle과 동일 부모 → 카메라 follow 동기.
    static func spawn(text: String, at position: CGPoint, parent: SKNode) {
        let node = ToastLabelNode(text: text)
        // 변기 중심 위쪽 +toastStartOffsetY pt에서 시작 — 변기 본체와 텍스트 픽셀 겹침 방지.
        node.position = CGPoint(x: position.x,
                                y: position.y + GameConfig.toastStartOffsetY)
        parent.addChild(node)
        node.animate()
    }

    // MARK: - Animate (private — spawn에서만 호출)
    /// 부모 addChild 직후 호출. group(move + fade + scale) 동시 진행 → 자가 제거.
    /// SKAction.group은 [move, fade, scale] 3개를 *동시* 실행 — CompletableFuture.allOf 패턴.
    /// self 미사용 → [weak self] 캡처 불필요.
    /// ScorePopupNode.animate() 완전 답습 — 상수만 toastDuration / toastFlyUpDistance / toastEndScale.
    private func animate() {
        let moveUp  = SKAction.moveBy(x: 0,
                                       y: GameConfig.toastFlyUpDistance,
                                       duration: GameConfig.toastDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.toastDuration)
        let scaleUp = SKAction.scale(to: GameConfig.toastEndScale,
                                      duration: GameConfig.toastDuration)
        let group   = SKAction.group([moveUp, fadeOut, scaleUp])
        let cleanup = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 황금색(.ganhoYellowF), 중앙 정렬. fontName 미지정 (다른 자가 소멸 노드 일관).
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabel() {
        label.fontSize = GameConfig.toastFontSize
        // .ganhoYellowF — 콤보 ×10 마일스톤(황금기 톤)과 동일 색 → *보너스 = 황금기 가속*이라는 의미 공유.
        label.fontColor = .ganhoYellowF
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
