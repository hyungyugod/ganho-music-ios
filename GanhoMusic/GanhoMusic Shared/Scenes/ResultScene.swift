//
//  ResultScene.swift
//  GanhoMusic Shared
//
//  Phase 3-3 · 결과 화면 — GameScene의 GameOverOverlayNode 모달을 폐기하고 별도 씬으로 분리
//  Phase 3-4 · bestScore / isNewBest 주입 + bestLabel 신설 (라벨 4개 재배치)
//  Phase 3-5 · GameStats 주입 + statsLabel 신설 (라벨 5개 재배치, "PLAYS N / TOTAL N")
//  Phase 5-7 · 캐릭터 이름 라벨 추가 (init 6번째 인자 characterName)
//

import SpriteKit

/// 게임 종료 후 결과를 보여주는 독립 씬.
/// `finalScore`/`bestScore`/`isNewBest`는 init 주입으로 박혀(`let`) 변조 불가.
/// 신기록이면 "★ NEW BEST! ★", 아니면 "BEST 🏆 N"으로 분기 표시.
/// 표시 후 탭 1회 → TitleScene fade.
/// TitleScene과 동일한 라벨/팩토리/터치 패턴을 답습.
final class ResultScene: SKScene {

    // MARK: - Properties
    /// init 주입된 최종 점수. 불변.
    private let finalScore: Int
    /// init 주입된 최고 점수(record 후 기준). 불변.
    private let bestScore: Int
    /// 이번 점수가 신기록을 갱신했는지. 불변.
    private let isNewBest: Bool
    /// Phase 3-5 — init 주입된 누적 통계(이번 판 반영 후 값). 불변.
    private let stats: GameStats
    /// Phase 5-7 — init 주입된 캐릭터 한국어 이름. 불변. characterLabel.text 합성에만 사용.
    /// String만 받음 — CharacterID enum 결합도 차단(HUDNode 5-4와 동형).
    private let characterName: String
    /// TitleScene 복귀 중복 진입 가드.
    private var isTransitioning = false
    private let titleLabel  = SKLabelNode(text: "GAME OVER")
    private let scoreLabel  = SKLabelNode(text: "🎵 0")
    private let bestLabel   = SKLabelNode(text: "BEST 🏆 0")
    private let statsLabel  = SKLabelNode(text: "PLAYS 0  /  TOTAL 0")
    /// Phase 5-7 — title(+80) 위쪽에 표시되는 캐릭터 라벨. 텍스트는 setupLabels에서 합성.
    private let characterLabel = SKLabelNode(text: "")
    private let promptLabel = SKLabelNode(text: "TAP TO RETURN")

    // MARK: - Factory
    /// 점수/최고 점수/신기록 여부/누적 통계를 주입받아 ResultScene 인스턴스 생성. .resizeFill로 view 크기에 자동 맞춤.
    /// 외부에서는 반드시 이 팩토리만 사용 — `private init` 으로 직접 호출 차단.
    /// Phase 3-5 — `stats: GameStats` 인자 추가.
    /// Phase 5-7 — `characterName: String` 인자 추가 (마지막 인자).
    class func newResultScene(
        score: Int,
        bestScore: Int,
        isNewBest: Bool,
        stats: GameStats,
        characterName: String
    ) -> ResultScene {
        let scene = ResultScene(
            size: CGSize(width: 1024, height: 768),
            score: score,
            bestScore: bestScore,
            isNewBest: isNewBest,
            stats: stats,
            characterName: characterName
        )
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Init
    /// 6개 인자 모두 `let` 이므로 `super.init` 전에 저장.
    /// Phase 5-7 — `characterName` 6번째 인자 추가.
    private init(
        size: CGSize,
        score: Int,
        bestScore: Int,
        isNewBest: Bool,
        stats: GameStats,
        characterName: String
    ) {
        self.finalScore = score
        self.bestScore = bestScore
        self.isNewBest = isNewBest
        self.stats = stats
        self.characterName = characterName
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .ganhoBgDeep
        setupLabels()
    }

    /// scene.size 변경 시(회전·resize) 라벨 위치 재계산. 자식 추가는 setupLabels에서만.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutLabels()
    }

    // MARK: - Setup
    private func setupLabels() {
        configureLabel(titleLabel,     fontSize: GameConfig.resultTitleFontSize)
        configureLabel(scoreLabel,     fontSize: GameConfig.resultScoreFontSize)
        configureLabel(bestLabel,      fontSize: GameConfig.resultBestFontSize)
        configureLabel(statsLabel,     fontSize: GameConfig.resultStatsFontSize)
        configureLabel(characterLabel, fontSize: GameConfig.resultCharacterFontSize)
        configureLabel(promptLabel,    fontSize: GameConfig.resultPromptFontSize)
        scoreLabel.text = "🎵 \(finalScore)"
        // Phase 3-4 — 신기록이면 강조 문구, 아니면 기존 최고치 표시.
        bestLabel.text = isNewBest ? "★ NEW BEST! ★" : "BEST 🏆 \(bestScore)"
        // Phase 3-5 — 누적 통계 표시. record 후 주입되므로 이번 판이 이미 반영된 값.
        statsLabel.text = "PLAYS \(stats.playCount)  /  TOTAL \(stats.totalScore)"
        // Phase 5-7 — 사용한 캐릭터 이름. 빈 문자열이어도 "🎮 "만 — 크래시 없음(graceful).
        characterLabel.text = "🎮 \(characterName)"
        addChild(titleLabel)
        addChild(scoreLabel)
        addChild(bestLabel)
        addChild(statsLabel)
        addChild(characterLabel)
        addChild(promptLabel)
        layoutLabels()
    }

    /// 6개 라벨 공통 스타일. TitleScene과 동일 패턴.
    private func configureLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontSize = fontSize
        label.fontColor = .ganhoPaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.alpha = GameConfig.hudAlpha
    }

    /// scene.size 기준 위치 재계산. didMove와 didChangeSize에서 공용.
    private func layoutLabels() {
        titleLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultTitleOffsetY
        )
        scoreLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultScoreOffsetY
        )
        bestLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultBestOffsetY
        )
        statsLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultStatsOffsetY
        )
        characterLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultCharacterOffsetY
        )
        promptLabel.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.resultPromptOffsetY
        )
    }

    // MARK: - Touch
    /// 화면 어디든 탭 1회 → TitleScene 전환. 중복 탭은 isTransitioning으로 차단.
    /// view 옵셔널은 강제 언래핑 금지 — guard let으로 안전 추출.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let view = self.view else { return }
        isTransitioning = true
        let titleScene = TitleScene.newTitleScene()
        let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
        view.presentScene(titleScene, transition: fade)
    }
}
