//
//  CountdownNode.swift
//  GanhoMusic Shared
//
//  Phase 6-13 · 게임 시작 카운트다운 3→2→1→GO! 자가 소멸 노드 8호 (개봉감의 시각/촉각/청각)
//

import SpriteKit

/// 게임 시작 직전 화면 중앙에 3 → 2 → 1 → GO! 4단계를 차례로 노출하고 *자가 제거*되는 카운트다운 노드.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 화면 중앙 (0,0) 고정.
/// 자가 소멸 노드 패턴 답습 (AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode /
/// HitFlashNode / ComboPopupNode / ComboBreakNode) — 자가 소멸 노드 *8호*.
///
/// 외부 진입점은 `start(onTick:onGo:onComplete:)` 1개. SKAction.sequence가 4단계를 직렬 진행하며
/// 매 단계 시작 시점에 외부 콜백(햅틱·사운드·완료 알림)을 호출한다.
///
/// Spring 비유: 비동기 워크플로의 단계별 webhook — 각 phase 진입 시 호출자에게 알림을 쏘고,
/// 마지막 phase 종료 후 자기 자신을 disposable로 정리한다.
final class CountdownNode: SKNode, SelfDismissingNode {

    // MARK: - Context (Sprint 10 Phase J / 10.6 폰트 회귀)
    /// 카운트다운 시각 톤 컨텍스트. enum 자체는 인게임/메뉴 두 분기만 — switch default 0(SPEC §4 금지).
    /// Sprint 10.6 — 폰트는 두 컨텍스트 모두 Jua-Regular(fontDisplay)로 통일 (fontPixel + 큰 fontSize
    /// SKLabelNode 렌더링 회귀 회피). 색만 컨텍스트별 — .ingame 픽셀 톤, .menu 카툰 톤.
    enum CountdownContext {
        /// 인게임 8-bit 색 톤 — 3·2·1 픽셀 화이트, GO! 픽셀 옐로. 폰트는 Jua-Regular(렌더 안정성).
        case ingame
        /// 메뉴 v2 카툰 톤 — 3·2·1 navyDeep, GO! coralPrimary. 호환성 보존(현재 호출 0).
        case menu
    }

    // MARK: - Properties
    /// 매 단계마다 text/color/scale이 바뀌는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode
    /// init에서 주입된 컨텍스트. start() 내 색 분기에 사용.
    private let context: CountdownContext

    // MARK: - Init
    /// 라벨 1개 자식으로 부착. text는 빈 문자열로 시작 — start() 안 첫 setup 액션에서 "3"으로 갱신됨.
    /// zPosition = 250 (HitFlash 200 위) — 카운트다운 동안 어떤 UI도 덮는다.
    /// Sprint 10 Phase J — context 분기 init. 기본 init()은 호환성 보존 → init(context:.ingame) 위임.
    /// fontName은 컨텍스트별 — .ingame(fontPixel) / .menu(fontDisplay).
    override convenience init() {
        self.init(context: .ingame)
    }

    /// 신규 진입점. GameScene는 명시적으로 `.ingame`, 미래 메뉴 카운트다운(미사용)은 `.menu` 호출.
    ///
    /// Sprint 10.6 — fontName Menlo-Bold(fontPixel) → Jua-Regular(fontDisplay)로 복원.
    /// 원인: Phase J에서 .ingame 분기에 fontPixel 적용 → fontSize 120/140pt 큰 폰트에서 SKLabelNode
    /// 렌더링 회귀(콘솔 로그 onTick/onGo/onComplete 모두 발화하나 시각 미렌더링). 같은 fontPixel을
    /// 쓰는 HUD(18pt) / ComboPopup(32pt) 등 다른 노드는 작은 fontSize라 정상 렌더.
    /// Sprint 7 Phase E(QA 9.76 합격) 시점의 fontDisplay로 폰트만 회귀. 색 분기(.ingame 픽셀 톤)는 보존.
    init(context: CountdownContext) {
        self.context = context
        self.label = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        super.init()
        name = "countdown"
        zPosition = GameConfig.countdownZPosition
        configureLabel()
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Start
    /// 부모(cameraNode)에 addChild 직후 호출. 4단계 시퀀스를 자체 SKAction.sequence로 실행.
    /// - Parameters:
    ///   - onTick: 매 숫자(3/2/1) 표시 직후 호출 — 호출자가 light 햅틱 등 발화.
    ///   - onGo: GO! 표시 직후 호출 — 호출자가 heavy 햅틱 + 사운드.
    ///   - onComplete: GO! 페이드아웃 + removeFromParent 직후 호출 — 호출자가 startGameProperly().
    ///     `removeFromParent` 다음에 위치해 노드가 *이미 트리에서 빠진* 상태에서 게임 시동 보장(시각 잔상 0).
    /// 외부 주입 콜백 3개는 [weak self] 캡처 *외부 책임* — 본 함수 내부 SKAction.run에선 그대로 호출만.
    func start(
        onTick: @escaping (Int) -> Void,
        onGo: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        // Sprint 10 Phase J — context 분기:
        // .ingame: 3·2·1 픽셀 화이트 (ganhoPixelHudWhite), GO! 픽셀 옐로 (ganhoPixelHudYellow)
        // .menu: 3·2·1 navyDeep, GO! coralPrimary (Sprint 7 Phase E 톤 보존, 호환성).
        let tickColor: UIColor = (context == .ingame) ? .ganhoPixelHudWhite : .ganhoNavyDeep
        let step3 = stepAction(text: "3", color: tickColor) { onTick(3) }
        let step2 = stepAction(text: "2", color: tickColor) { onTick(2) }
        let step1 = stepAction(text: "1", color: tickColor) { onTick(1) }
        let stepGo = goAction(onGo: onGo)
        let cleanup = SKAction.removeFromParent()
        let notify = SKAction.run(onComplete)
        run(.sequence([step3, step2, step1, stepGo, cleanup, notify]))
    }

    // MARK: - Step Actions
    /// 일반 단계(3/2/1) 한 묶음 — 텍스트/색 세팅 + 콜백 + 페이드인/홀드/페이드아웃.
    /// scale은 매 단계 시작 시 1.0으로 리셋 — GO! 단계에서 1.3까지 커진 값이 다음 라운드 진입 시 잔류 방지.
    /// (현재는 노드가 자가 소멸하므로 잔류 없음 — 방어 코딩.)
    /// SKAction.run 안에서 self 사용 → [weak self] 캡처 필수.
    private func stepAction(text: String,
                            color: UIColor,
                            onTick: @escaping () -> Void) -> SKAction {
        let setup = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.label.text = text
            self.label.fontColor = color
            // Sprint 7 Phase E — 매 단계 fontSize 갱신 (숫자 120pt). GO! 단계에서 140pt로 바뀐 후 다시 1로 돌아올 때도 안정.
            self.label.fontSize = GameConfig.countdownNumberFontSizeV3
            self.alpha = 0
            self.label.alpha = 1
            self.label.setScale(1.0)
            onTick()
        }
        let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.countdownFadeInDuration)
        let hold    = SKAction.wait(forDuration: GameConfig.countdownHoldDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownFadeOutDuration)
        return .sequence([setup, fadeIn, hold, fadeOut])
    }

    /// GO! 단계 — scale 펄스 추가. hold와 scaleUp을 group으로 동시 진행 (*커지면서 잠시 홀딩*).
    /// 일반 단계(0.7 hold)보다 짧은 0.5 hold에 1.0 → 1.3 scaleUp을 동시에 묶고,
    /// fadeOut은 일반보다 긴 0.4초 — *시작의 잔향* 톤.
    /// SKAction.run 안에서 self 사용 → [weak self] 캡처 필수.
    private func goAction(onGo: @escaping () -> Void) -> SKAction {
        // Sprint 10 Phase J — context 분기: .ingame 픽셀 옐로 / .menu 코랄 프라이머리(호환 톤).
        let goColor: UIColor = (context == .ingame) ? .ganhoPixelHudYellow : .ganhoCoralPrimary
        let setup = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.label.text = "GO!"
            self.label.fontColor = goColor
            // Sprint 7 Phase E — GO! fontSize 140pt (숫자 120pt보다 큼). "더 큰 임팩트" 위계.
            self.label.fontSize = GameConfig.countdownGoFontSizeV3
            self.alpha = 0
            self.label.alpha = 1
            // Sprint 7 Phase E — 시작 scale 1.0 → 1.2. 등장부터 임팩트 확보.
            self.label.setScale(GameConfig.countdownGoStartScaleV3)
            onGo()
        }
        let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.countdownFadeInDuration)
        // Sprint 7 Phase E — 끝 scale 1.3 → 1.8. 더 큰 펄스.
        let scaleUp = SKAction.scale(to: GameConfig.countdownGoEndScaleV3,
                                     duration: GameConfig.countdownGoHoldDuration)
        let hold    = SKAction.wait(forDuration: GameConfig.countdownGoHoldDuration)
        // hold와 scaleUp을 group으로 동시 — *커지면서 잠시 홀딩*. 둘 다 같은 duration이라 동기 종료.
        let holdGroup = SKAction.group([hold, scaleUp])
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.countdownGoFadeOutDuration)
        return .sequence([setup, fadeIn, holdGroup, fadeOut])
    }

    // MARK: - Configure
    /// 라벨 스타일 — 큰 폰트(96), 중앙 정렬. cameraNode 자식 (0,0) = 화면 중앙.
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    /// 색/텍스트는 매 단계 setup 액션에서 갱신되므로 여기선 미설정.
    private func configureLabel() {
        label.fontSize = GameConfig.countdownFontSize
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
