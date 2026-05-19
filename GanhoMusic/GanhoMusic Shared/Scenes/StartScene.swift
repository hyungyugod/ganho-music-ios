//
//  StartScene.swift
//  GanhoMusic Shared
//
//  Phase 10-1a · 시작 시퀀스 1단계 — 제목 + BEST/PLAYS + 스토리 박스 + 난이도 3장 + 시작 버튼
//  Phase 10-2 · 모던 리스킨 (병동의 새벽 톤) — 그라데이션 배경 + 음표 파티클 + 제목 글로우 +
//               카드 spring/링 글로우 + 시작 버튼 pulse + 전환 잔향. *게임플레이 변경 0건*.
//  Sprint 2 · 메뉴 v2 리스킨 — 3-stop warm gradient + GlassPill BEST/PLAYS + Jua 2-라인 타이틀
//               + AccentLine + Gowun Dodum 태그라인. overlay 패널 제거. 음표 emitter는 보존.
//  Sprint 6 · 흐름 재편 — 난이도 카드 3장을 *제거*하고 좌측에 NurseAvatarNode 큰 그림을 부착.
//               난이도 결정은 5단계 흐름의 *마지막*(DifficultySelectScene)으로 이동.
//               transitionToNext는 CharacterSelectScene을 *인자 없이* 호출(difficulty 제거).
//
//  10-1b 완성 시점부터 "시작" → CharacterSelectScene 전환.
//

import SpriteKit

/// 앱 첫 진입 씬. v2 리스킨: 그라데이션 + AccentLine + 2-라인 Jua 타이틀 + 태그라인 +
/// 좌상단 BEST GlassPill / 우상단 PLAYS GlassPill + 좌측 NurseAvatarNode + 시작 버튼.
/// Sprint 6 — 난이도 카드/repo/select 로직 모두 삭제. characterRepo만 유지(다음 씬이 자기 repo로 다시 읽음).
final class StartScene: SKScene {

    // MARK: - Properties
    /// 씬 전환이 시작됐는지 여부. true가 되면 추가 탭은 무시 — 더블 enter 방지.
    private var isTransitioning = false
    /// Sprint 2 — Jua 2-라인 타이틀. line1 "김간호는"(navyDeep 44pt), line2 "음악박사 ♪"(coral 56pt).
    private let titleLine1 = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    private let titleLine2 = SKLabelNode(fontNamed: GameConfig.fontDisplay)
    /// Sprint 2 — 타이틀 위 AccentLine(32×3 코랄).
    private let accentLine = AccentLineNode()
    /// Sprint 2 — Gowun Dodum 태그라인(2줄 자동 줄바꿈).
    private let taglineLabel = SKLabelNode(fontNamed: GameConfig.fontBody)
    /// Sprint 2 — BEST/PLAYS는 GlassPillNode 2개. 옵셔널 — didMove 전엔 nil.
    private var bestPill: GlassPillNode?
    private var playsPill: GlassPillNode?
    /// 시작 버튼 — 명시 탭만 다음 단계로 진행.
    private let startButton = PrimaryButtonNode(text: "시작")
    /// 캐릭터 선택 영속 계층. didMove에서 .current로 복원 — 10-1a는 GameScene 직진 시점에 사용.
    /// 10-1b 이후는 CharacterSelectScene이 자기 repo로 다시 읽는다(불변 흐름).
    private let characterRepo = CharacterPreferenceRepository()
    /// Phase 10-2 — 그라데이션 배경 노드. didChangeSize 시 재생성을 위해 *참조 보관*.
    /// 옵셔널 — didMove 전엔 nil.
    private var gradientBackground: GradientBackgroundNode?
    /// Phase 10-2 — 음표 파티클 컨테이너. 씬 사이즈 의존 — didChangeSize 시 재생성.
    private var musicNoteEmitter: MusicNoteEmitterNode?
    /// Sprint 6 — 좌측 김간호 큰 그림. SKShapeNode 컨테이너. didChangeSize에서 재배치.
    private var nurseAvatar: NurseAvatarNode?

    // MARK: - Factory
    /// TitleScene.newTitleScene과 동일 패턴. .resizeFill로 view 크기에 자동 맞춤.
    class func newStartScene() -> StartScene {
        let scene = StartScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        // Sprint 2 — 1프레임 fallback도 warm top으로 (다크 플래시 회피).
        backgroundColor = .ganhoBgWarmTop
        setupGradientBackground()             // Sprint 2 — 3-stop warm gradient. zPos -20.
        setupMusicNoteEmitter()               // Phase 10-2 — 보존. zPos -15.
        setupStatPills()                      // Sprint 2 — BEST/PLAYS GlassPill 2개.
        setupTitleBlock()                     // Sprint 2 — AccentLine + Jua 2-라인 + Gowun Dodum 태그.
        setupNurseAvatar()                    // Sprint 6 — 좌측 김간호 큰 그림.
        setupStartButton()
        attachStartButtonPulse()              // Phase 10-2 — 시작 버튼 호흡 pulse
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Phase 10-2 — 그라데이션/음표 emitter는 sceneSize 의존 → 사이즈 변경 시 재생성.
        rebuildGradientBackground()
        rebuildMusicNoteEmitter()
        layoutStatPills()
        layoutTitleBlock()
        layoutNurseAvatar()                   // Sprint 6.
        layoutStartButton()
    }

    // MARK: - Setup (Sprint 2 · Background)
    /// Sprint 2 — 3-stop warm gradient(피치 → 코랄 → 라벤더). zPos -20.
    /// didChangeSize에서 재생성하기 위해 인스턴스 참조 보관.
    private func setupGradientBackground() {
        let node = GradientBackgroundNode.threeStop(
            size: size,
            topColor: .ganhoBgWarmTop,
            midColor: .ganhoBgWarmMid,
            bottomColor: .ganhoBgWarmBottom
        )
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientBackground = node
        addChild(node)
    }

    /// 사이즈 변경 시 그라데이션 재생성. 기존 노드는 removeFromParent.
    private func rebuildGradientBackground() {
        gradientBackground?.removeFromParent()
        gradientBackground = nil
        setupGradientBackground()
    }

    /// Phase 10-2 — 음표 파티클 컨테이너 부착. SKAction.repeatForever로 자동 스폰 시작.
    private func setupMusicNoteEmitter() {
        let emitter = MusicNoteEmitterNode(sceneSize: size)
        // 원점은 씬 좌측 하단 (0,0) — emitter 내부 좌표계가 sceneSize 범위에 그대로 매핑.
        emitter.position = .zero
        musicNoteEmitter = emitter
        addChild(emitter)
    }

    /// Phase 10-2 — 사이즈 변경 시 emitter 재생성. 떠 있는 음표는 자가 정리됨.
    private func rebuildMusicNoteEmitter() {
        musicNoteEmitter?.stopEmitting()
        musicNoteEmitter?.removeAllChildren()
        musicNoteEmitter?.removeFromParent()
        musicNoteEmitter = nil
        setupMusicNoteEmitter()
    }

    // MARK: - Setup (Sprint 2 · Stats)
    /// Sprint 2 — 좌상단 BEST GlassPill / 우상단 PLAYS GlassPill.
    /// 저장소 호출 위치 *그대로* — setup 시점 1회.
    private func setupStatPills() {
        let best = HighScoreRepository().current
        let plays = StatisticsRepository().current.playCount
        let pillSize = CGSize(
            width: GameConfig.startSceneStatPillWidth,
            height: GameConfig.startSceneStatPillHeight
        )
        let bestNode = GlassPillNode(text: "BEST 🏆 \(best)", size: pillSize)
        let playsNode = GlassPillNode(text: "PLAYS \(plays)", size: pillSize)
        bestPill = bestNode
        playsPill = playsNode
        addChild(bestNode)
        addChild(playsNode)
        layoutStatPills()
    }

    private func layoutStatPills() {
        guard let best = bestPill, let plays = playsPill else { return }
        let y = frame.maxY - GameConfig.startSceneStatPillTopMargin
        best.position = CGPoint(
            x: frame.minX + GameConfig.startSceneStatPillSideMargin,
            y: y
        )
        plays.position = CGPoint(
            x: frame.maxX - GameConfig.startSceneStatPillSideMargin,
            y: y
        )
    }

    // MARK: - Setup (Sprint 2 · Title Block)
    /// Sprint 2 — AccentLine + Jua 2-라인 타이틀 + Gowun Dodum 태그라인.
    /// 우측 정렬 — 타이틀 블록이 우측, 좌측은 NurseAvatarNode 영역.
    private func setupTitleBlock() {
        // 라인 1 — "김간호는" navyDeep.
        titleLine1.text = "김간호는"
        titleLine1.fontSize = GameConfig.startSceneTitleLine1FontSize
        titleLine1.fontColor = .ganhoNavyDeep
        titleLine1.horizontalAlignmentMode = .right
        titleLine1.verticalAlignmentMode = .center

        // 라인 2 — "음악박사 ♪" coral.
        titleLine2.text = "음악박사 ♪"
        titleLine2.fontSize = GameConfig.startSceneTitleLine2FontSize
        titleLine2.fontColor = .ganhoCoralPrimary
        titleLine2.horizontalAlignmentMode = .right
        titleLine2.verticalAlignmentMode = .center

        // 태그라인 — Gowun Dodum body.
        taglineLabel.text = "수간호사 몰래, 떠오른 멜로디를\n45초 안에 모아 보세요"
        taglineLabel.fontSize = GameConfig.startSceneTaglineFontSize
        taglineLabel.fontColor = .ganhoNavyMuted
        taglineLabel.horizontalAlignmentMode = .right
        taglineLabel.verticalAlignmentMode = .center
        taglineLabel.numberOfLines = 0
        taglineLabel.preferredMaxLayoutWidth = GameConfig.startSceneTaglineMaxWidth

        addChild(accentLine)
        addChild(titleLine1)
        addChild(titleLine2)
        addChild(taglineLabel)
        layoutTitleBlock()
    }

    private func layoutTitleBlock() {
        let anchorX = frame.maxX - GameConfig.startSceneTitleBlockRightMargin
        let centerY = frame.midY + GameConfig.startSceneTitleBlockOffsetY
        // 타이틀 1행은 위, 타이틀 2행은 아래 — 줄간 lineSpacing.
        let line1Y = centerY + GameConfig.startSceneTitleLineSpacing / 2
        let line2Y = centerY - GameConfig.startSceneTitleLineSpacing / 2
        titleLine1.position = CGPoint(x: anchorX, y: line1Y)
        titleLine2.position = CGPoint(x: anchorX, y: line2Y)
        // AccentLine은 타이틀1 위로 +offset, 우측 정렬에 맞춰 우측 끝을 anchorX에 맞춤.
        accentLine.position = CGPoint(
            x: anchorX - GameConfig.accentLineWidth / 2,
            y: line1Y + GameConfig.startSceneAccentLineAboveTitleOffset
        )
        // 태그라인은 타이틀2 아래.
        taglineLabel.position = CGPoint(
            x: anchorX,
            y: line2Y + GameConfig.startSceneTaglineBelowTitleOffset
        )
    }

    // MARK: - Setup (Sprint 6 · Nurse Avatar)
    /// Sprint 6 — 좌측 김간호 큰 그림. mockup main-screen-v2.html 좌측 6% 정렬.
    /// PNG swap 호환 — SKNode 서브클래스라 향후 SKSpriteNode(texture:)로 교체 가능.
    private func setupNurseAvatar() {
        let avatar = NurseAvatarNode()
        avatar.setScale(GameConfig.nurseAvatarScale)
        avatar.zPosition = GameConfig.nurseAvatarZPosition
        nurseAvatar = avatar
        addChild(avatar)
        layoutNurseAvatar()
    }

    private func layoutNurseAvatar() {
        nurseAvatar?.position = CGPoint(
            x: frame.minX + GameConfig.nurseAvatarOffsetX,
            y: frame.midY + GameConfig.nurseAvatarOffsetY
        )
    }

    // MARK: - Start Button
    /// 시작 버튼 — 명시 탭만 진행. addChild + layout 분리.
    private func setupStartButton() {
        addChild(startButton)
        layoutStartButton()
    }

    private func layoutStartButton() {
        startButton.position = CGPoint(
            x: frame.midX,
            y: frame.midY + GameConfig.startSceneStartButtonOffsetY
        )
    }

    /// Phase 10-2 — 시작 버튼에 호흡 pulse. 0.98 ↔ 1.02, 한 주기 2초.
    /// 외부에서 부착 — PrimaryButtonNode 내부 구조 변경 0.
    /// 씬 전환 시 transitionToNext에서 액션 키로 정리.
    private func attachStartButtonPulse() {
        let down = SKAction.scale(
            to: GameConfig.startButtonPulseScaleMin,
            duration: GameConfig.startButtonPulseHalfDuration
        )
        down.timingMode = .easeInEaseOut
        let up = SKAction.scale(
            to: GameConfig.startButtonPulseScaleMax,
            duration: GameConfig.startButtonPulseHalfDuration
        )
        up.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([down, up])
        startButton.run(
            SKAction.repeatForever(pulse),
            withKey: "startButtonPulse"
        )
    }

    // MARK: - Touch
    /// Sprint 6 — 카드 hit test 분기 삭제. 시작 버튼 hit test만.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isTransitioning else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if startButton.contains(location) {
            transitionToNext()
        }
    }

    /// 시작 버튼 탭 시 다음 단계(CharacterSelect)로 전환.
    /// Sprint 6 — 난이도 인자 전달 제거. CharacterSelectScene.newCharacterSelectScene()을 *인자 없이* 호출.
    /// Phase 10-2 — *게임플레이 동작 불변* — presentScene 대상, sceneTransitionDuration 모두 그대로.
    /// 타이틀/시작버튼/NurseAvatar 슬라이드업 + fade-out *prelude*만 추가.
    private func transitionToNext() {
        guard let view = self.view else { return }
        isTransitioning = true

        // Phase 10-2 — 시작 버튼 pulse 정리.
        startButton.removeAction(forKey: "startButtonPulse")
        // Phase 10-2 — 음표 emitter 정지(추가 스폰 중단). 떠 있는 음표는 자가 정리.
        musicNoteEmitter?.stopEmitting()

        // Phase 10-2 — 타이틀/시작 버튼/NurseAvatar *살짝 위로* 슬라이드 + fadeOut.
        let slideUp = SKAction.moveBy(
            x: 0,
            y: GameConfig.startSceneExitSlideDistance,
            duration: GameConfig.startSceneExitSlideDuration
        )
        slideUp.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(
            withDuration: GameConfig.startSceneExitSlideDuration
        )
        // 같은 액션 인스턴스를 여러 노드에 run하면 SpriteKit이 내부적으로 복사 — 안전.
        let exit = SKAction.group([slideUp, fadeOut])
        startButton.run(exit)
        titleLine1.run(exit)
        titleLine2.run(exit)
        taglineLabel.run(exit)
        nurseAvatar?.run(exit)

        // Phase 10-2 — 슬라이드 완료 후 presentScene.
        // Sprint 6 — newCharacterSelectScene을 *인자 없이* 호출(difficulty 제거).
        let wait = SKAction.wait(forDuration: GameConfig.startSceneExitSlideDuration)
        let present = SKAction.run { [weak view] in
            guard let view = view else { return }
            let nextScene = CharacterSelectScene.newCharacterSelectScene()
            let fade = SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)
            view.presentScene(nextScene, transition: fade)
        }
        run(SKAction.sequence([wait, present]))

        // characterRepo는 다음 씬이 다시 .current로 읽으므로 본 씬에서 별도 전달 불필요.
        // 정적 의존 회피 — Swift 컴파일러 unused warning 방지를 위해 명시 참조.
        _ = characterRepo
    }
}
