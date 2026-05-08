//
//  TitleScene.swift
//  GanhoMusic Shared
//
//  Phase 3-1+2 · 첫 진입 타이틀 씬 — 탭 1회로 GameScene 페이드 전환
//  Phase 3-4 · bestLabel 추가 — HighScoreRepository.current를 화면 중앙에 표시
//  Phase 3-5 · playsLabel 추가 — StatisticsRepository.current.playCount 화면 표시 (라벨 4개 재배치)
//

import SpriteKit

/// 앱 첫 진입 씬. "김간호는 음악박사" + "BEST 🏆 N" + "TAP TO START" 라벨을 보여준다.
/// 화면 어디든 탭 → GameScene으로 fade transition. 중복 진입은 isTransitioning 플래그로 방지.
/// 카메라/월드 개념 없음 — 라벨은 frame.midX/midY 기준 직접 배치.
/// Phase 3-4 — didMove에서 매번 HighScoreRepository().current 조회 → ResultScene → TitleScene 복귀 시 자동 갱신.
final class TitleScene: SKScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    private var isTransitioning = false
    private let titleLabel  = SKLabelNode(text: "김간호는 음악박사")
    private let bestLabel   = SKLabelNode(text: "BEST 🏆 0")
    private let playsLabel  = SKLabelNode(text: "PLAYS 0")
    private let promptLabel = SKLabelNode(text: "TAP TO START")

    // MARK: - Factory
    /// GameScene.newGameScene과 동일 패턴. .resizeFill로 view 크기에 자동 맞춤.
    class func newTitleScene() -> TitleScene {
        let scene = TitleScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgDeep
        setupLabels()
        startPromptBlink()
    }

    /// scene.size 변경 시 (회전·resize) 라벨 위치 재계산. 자식 추가는 setupLabels에서만.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutLabels()
    }

    // MARK: - Setup
    private func setupLabels() {
        configureLabel(titleLabel,  fontSize: GameConfig.titleFontSize)
        configureLabel(bestLabel,   fontSize: GameConfig.titleBestFontSize)
        configureLabel(playsLabel,  fontSize: GameConfig.titlePlaysFontSize)
        configureLabel(promptLabel, fontSize: GameConfig.titlePromptFontSize)
        // Phase 3-4 — 매 진입마다 새로 조회. ResultScene → TitleScene 복귀 시 자동 갱신.
        let best = HighScoreRepository().current
        bestLabel.text = "BEST 🏆 \(best)"
        // Phase 3-5 — 매 진입마다 새로 조회. ResultScene → TitleScene 복귀 시 자동 갱신.
        let plays = StatisticsRepository().current.playCount
        playsLabel.text = "PLAYS \(plays)"
        addChild(titleLabel)
        addChild(bestLabel)
        addChild(playsLabel)
        addChild(promptLabel)
        layoutLabels()
    }

    /// 라벨 공통 스타일.
    private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
    }

    /// scene.size 기준 위치 재계산. didMove와 didChangeSize에서 공용.
    private func layoutLabels() {
        titleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.titleLabelOffsetY
        )
        bestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.titleBestOffsetY
        )
        playsLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.titlePlaysOffsetY
        )
        promptLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.titlePromptOffsetY
        )
    }

    /// "TAP TO START" 깜빡임. SKAction.repeatForever — Timer 금지.
    private func startPromptBlink() {
        let fadeOut = SKAction.fadeAlpha(
            to: GameConfig.titlePromptBlinkMinAlpha,
            duration: GameConfig.titlePromptBlinkDuration
        )
        let fadeIn = SKAction.fadeAlpha(
            to: 1.0,
            duration: GameConfig.titlePromptBlinkDuration
        )
        promptLabel.run(.repeatForever(.sequence([fadeOut, fadeIn])))
    }

    // MARK: - Touch
    /// 화면 어디든 탭 1회 → GameScene 전환. 중복 탭은 isTransitioning으로 차단.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let view = self.view else { return }
        isTransitioning = true
        let gameScene = GameScene.newGameScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(gameScene, transition: fade)
    }
}
