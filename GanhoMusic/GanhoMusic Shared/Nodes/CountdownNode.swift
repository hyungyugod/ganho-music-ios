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

    // MARK: - Properties
    /// 매 단계마다 text/color/scale이 바뀌는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    private let label: SKLabelNode

    // MARK: - Init
    /// 라벨 1개 자식으로 부착. text는 빈 문자열로 시작 — start() 안 첫 setup 액션에서 "3"으로 갱신됨.
    /// zPosition = 250 (HitFlash 200 위) — 카운트다운 동안 어떤 UI도 덮는다.
    /// Sprint 7 Phase E — fontDisplay(Jua-Regular) 부여. 시스템 폰트 fallback 제거 → v3 톤(타이틀과 동일 패밀리).
    override init() {
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
        // Sprint 7 Phase E — 3/2/1 모두 navyDeep 통일. "차분한 긴장 누적" 톤.
        // GO!의 코랄과 색 대비를 통해 "준비 → 출발" 감정 전환 강조.
        let step3 = stepAction(text: "3", color: .ganhoNavyDeep) { onTick(3) }
        let step2 = stepAction(text: "2", color: .ganhoNavyDeep) { onTick(2) }
        let step1 = stepAction(text: "1", color: .ganhoNavyDeep) { onTick(1) }
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
            self.label.alpha = 0
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
        let setup = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.label.text = "GO!"
            // Sprint 7 Phase E — mint → coralPrimary. "출발의 폭발" 따뜻한 톤.
            self.label.fontColor = .ganhoCoralPrimary
            // Sprint 7 Phase E — GO! fontSize 140pt (숫자 120pt보다 큼). "더 큰 임팩트" 위계.
            self.label.fontSize = GameConfig.countdownGoFontSizeV3
            self.label.alpha = 0
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
