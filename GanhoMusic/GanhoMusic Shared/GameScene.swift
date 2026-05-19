//
//  GameScene.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · 빈 씬 골격 (Hello World 템플릿 제거)
//  Phase 1-2 · 월드 컨테이너 + 카메라 follow + 임시 박스 자동 왕복
//  Phase 1-3 · PlayerNode 정식 + 반투명 D-Pad + dt 입력 이동
//  Phase 2-1 · 맵 외곽 벽 시각화 + corner 마커 폐기
//  Phase 2-2 · SKPhysicsBody 첫 도입 + 중앙 기둥 신설
//  Phase 2-3 · 음표 스폰 루프 + contact 알림 + score 내부 카운트
//  Phase 2-4 · HUD 라벨 부착 + 45초 카운트다운 + 시간 만료 시 endGame()
//  Phase 2-6 · 수간호사 적 NPC 1마리 + 직선 추적 AI + 접촉 시 즉시 게임오버
//  Phase 2-7 · F 투사체 발사 루프 + F 피격 시 게임오버 + 벽 닿으면 소멸
//  Phase 2-10 · spawn / fire 9 메서드를 SpawnSystem으로 분리 (순수 리팩터, 기능 변화 0)
//  Phase 2-11 · didBegin / handleProjectileContact / handleNoteContact를 ContactRouter로 분리 (순수 리팩터)
//  Phase 2-12 · score / combo / lastCollectAt + 콤보 갱신 로직을 ScoreSystem으로 분리 (순수 리팩터)
//  Phase 3-1+2 · GameOverOverlay 부착 + endGame 멱등 가드 + touchesBegan으로 TitleScene 복귀
//  Phase 3-3 · 결과 표시를 ResultScene으로 분리 — 오버레이/터치/가드 폐기, endGame은 presentScene만
//  Phase 3-4 · HighScoreRepository 주입 + endGame에서 record → bestScore/isNewBest를 ResultScene에 전달
//  Phase 3-5 · StatisticsRepository 주입 + endGame에서 recordPlay → stats를 ResultScene에 전달
//  Phase 3 종결 후 리팩터 — setup/add 9개 메서드를 GameScene+Setup.swift로 분리
//  Phase 4-1 · StoneGuardNode 1마리 추가 (시계방향 4 waypoint 패트롤, PhysicsBody 없음 — 시각만)
//  Phase 4-2 · StoneGuardNode PhysicsBody 부착 + ContactRouter onStoneGuardContact stub
//  Phase 4-3 · AIRFORCE 이스터에그 — Player ↔ StoneGuard 첫 접촉 시 비행기 가로지르기 1회
//  Phase 4-4 · AIRFORCE 오버레이 — "나와라 박병장!" 텍스트 자가 페이드아웃
//  Phase 4-5 · AIRFORCE 폭탄 화면 플래시 — 오버레이 닫힘 후 300ms → 420ms 섬광
//  Phase 4-6 · 수간호사 5초 도주 — 트리거 시 enemy.startFleeing 호출
//  Phase 4-7 · 수간호사 복귀 후 F 재스폰 — startFleeing onEnd 콜백으로 fireImmediately
//  Phase 5-2 · 선택 캐릭터 init 주입 + PlayerNode 색 적용 (constructor injection)
//  Phase 6-1 · HapticsManager 신설 + 노트 수집/게임오버 햅틱 트리거 2지점
//  Phase 6-2 · AudioManager 신설 + 노트 수집/게임오버 사운드 트리거 2지점
//  Phase 6-4 · BGMPlayer 신설 + 게임 시작/종료 시 BGM 재생/정지
//  Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 (시각 폴리싱)
//  Phase 6-9 · 피격 카메라 셰이크 + 빨간 플래시 (시각 폴리싱)
//  Phase 6-10 · 콤보 마일스톤(3/5/10/20) 도달 시 화면 중앙 텍스트 팝업 (시각 폴리싱)
//  Phase 6-11 · 콤보 마일스톤 도달 시 햅틱/사운드 동시 발화 (3감각 완성)
//  Phase 6-12 · 콤보 10+ 끊김 시 화면 중앙 BREAK 팝업 + heavy 햅틱 (실망 2감각, 사운드 제외)
//  Phase 6-13 · 게임 시작 카운트다운 3→2→1→GO! (gameState .countdown 신설 + startGameProperly 분리)
//  Phase 6-14 · 게임 끝 5초 긴박감 — BGM rate↑ + HUD timeLabel 빨강 깜빡임 + 매초 light 햅틱
//  Phase 7-1 · 난이도 3단계 시스템 — init에 difficulty 인자 추가 + spawnSystem.apply + endGame에서 ResultScene에 difficulty 전달
//  Phase 9-8 · AIRFORCE 이스터에그 타이밍 정합화 + hard 가드 — 비행기 등장 2.4초 지연 + difficulty==.hard 안전망.
//

import SpriteKit

/// 게임 메인 씬. Phase 1-3 시점에는 PlayerNode(worldNode 자식)와
/// DPadNode(cameraNode 자식)로 사용자 입력 → 캐릭터 이동 → 카메라 추종 골격을 완성한다.
/// 맵 경계/물리/HUD/스폰은 후속 Phase에서 추가.
/// Phase 2-11 — 충돌 분기는 ContactRouter가 담당. GameScene은 콜백 등록만.
class GameScene: SKScene {

    // MARK: - Properties
    // Phase 3 종결 후 리팩터 — GameScene+Setup.swift extension 접근 위해 private 해제 (필수 연동 변경).
    var gameState: GameState = .waiting
    var lastUpdateTime: TimeInterval = 0
    let hud = HUDNode()                                         // Phase 2-4 — cameraNode 자식
    var remainingTime: TimeInterval = GameConfig.gameDuration   // Phase 2-4 — 45초 카운트다운

    // 노드 트리
    let worldNode  = SKNode()
    let cameraNode = SKCameraNode()
    let player     = PlayerNode()    // worldNode 자식 (이동함)
    let enemy      = EnemyNode()     // worldNode 자식 (player 추적, Phase 2-6)
    let stoneGuard = StoneGuardNode()  // worldNode 자식 (4 waypoint 시계방향 패트롤, Phase 4-1)
    /// Phase 9-7 — 이교수 NPC. .hard 난이도에서만 setupProfessor가 set, easy/normal은 nil 유지.
    /// Optional ─ optional chaining(professor?.updatePixelAnimation / professor?.stopThrowing)으로
    /// 호출부 분기 없이 자연 noop. SPEC §회귀 방지: easy/normal 게임 진입 시 professor=nil 보장.
    var professor: ProfessorNode?
    let dpad       = DPadNode()      // cameraNode 자식 (화면 고정)

    // 시스템
    let spawnSystem = SpawnSystem()       // Phase 2-10 — spawn 책임 분리
    let contactRouter = ContactRouter()   // Phase 2-11 — 충돌 분기 책임 분리
    let scoreSystem = ScoreSystem()       // Phase 2-12 — 점수 / 콤보 책임 분리
    let skillSystem = SkillSystem()       // Phase 9-5 — 캐릭터별 스킬 시스템
    let skillButton = SkillButtonNode()   // Phase 9-5 — 좌하단 1탭 발동 버튼
    let hudSkillSlot = HUDSkillSlotNode() // Phase 9-5 — 스킬 쿨다운 진행 시각화
    let pauseButton = PauseButtonNode()   // Sprint 3 — 우상단 일시정지 시각 placeholder
    let highScoreRepo = HighScoreRepository()   // Phase 3-4 — 최고 점수 영구 저장소
    let statsRepo = StatisticsRepository()      // Phase 3-5 — 누적 통계 영구 저장소
    // Phase 7-4 — 캐릭터 × 난이도 매트릭스 / 최초 졸업 일시 저장소. HighScoreRepository와 *병행*.
    // 단일 점수 사용처(ResultScene bestLabel)는 무영향 — 본 두 저장소는 졸업 판정 전용.
    let perDiffRepo = PerDifficultyScoreRepository()
    let graduationRepo = GraduationRepository()
    let haptics = HapticsManager()              // Phase 6-1 — 손맛 강화 (Manager 패턴 첫 등장)
    let audio   = AudioManager()                // Phase 6-2 — 사운드 손맛 (Manager 패턴 두 번째 적용)
    let bgm     = BGMPlayer()                   // Phase 6-4 — 자작 BGM 무한 루프 (음원 부재 시 noop)

    // Phase 4-3 — AIRFORCE 이스터에그 1회 한정 가드. true가 되면 재발동 안 함.
    // 새 GameScene 인스턴스에서 자동 false로 리셋됨.
    private var airforceTriggered: Bool = false

    // Phase 6-10 — 한 판 내 이미 발화된 콤보 마일스톤 추적. 멱등성 보장.
    // GameScene 인스턴스는 한 판 = 1개 → 새 게임 시작 시 빈 Set로 자동 리셋.
    // Spring 비유: idempotency-key — 같은 마일스톤 key는 한 트랜잭션 내 1회만 처리.
    private var triggeredComboMilestones: Set<Int> = []

    // Phase 6-12 — 콤보 끊김 발화 추적. 같은 콤보 값 끊김은 한 판 1회만 발화 (멱등).
    // 6-11 triggeredComboMilestones와 완전 분리 — 환호와 실망은 독립 가드.
    // lastComboValue: 직전 프레임의 콤보값 추적 — 0으로 떨어진 *순간*을 감지하는 폴링 기준점.
    // 첫 프레임에는 0 시작이라 임계값(10) 가드로 노이즈 차단.
    private var lastComboValue: Int = 0
    private var triggeredComboBreaks: Set<Int> = []

    /// Phase 6-14 — 5초 긴박감 1회 가드. 같은 판 1회만 setup 발화 (HUD 깜빡임 시작 등).
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
    /// `airforceTriggered` 1회 가드 패턴 답습 — 단순/안전/회귀 0.
    private var tensionStarted: Bool = false
    /// Phase 6-14 — 직전 프레임의 정수초(ceil). 매초 변화 *순간* 감지용.
    /// -1 초기값 — 첫 프레임 비교가 자연스럽게 첫 변화로 처리됨.
    /// HUD timeLabel이 보여주는 `Int(ceil(remainingTime))`과 정확히 같은 식으로 계산 → *눈에 보이는 숫자가 바뀐 순간* 햅틱 발화.
    private var lastRemainingTimeSecond: Int = -1

    /// Phase 5-2 — TitleScene이 init으로 주입한 선택 캐릭터.
    /// PlayerNode 색 등 캐릭터별 시각/로직 적용에 사용. 한 판 안에서 불변(`let`).
    let characterID: CharacterID
    /// Phase 7-1 — TitleScene이 init으로 주입한 선택 난이도.
    /// 노드/시스템 apply(_:) 호출에 사용. 한 판 안에서 불변(`let`).
    /// macOS/tvOS GameViewController 호출은 default 인자(`.easy`)로 자동 호환 → 회귀 0.
    let difficulty: Difficulty

    // MARK: - Init
    /// Phase 7-1 — characterID + difficulty 주입형 init. newGameScene factory가 호출.
    /// Swift 규칙: stored property(`self.characterID`/`self.difficulty`) 초기화 → 그 다음 `super.init`.
    init(size: CGSize, characterID: CharacterID, difficulty: Difficulty) {
        self.characterID = characterID
        self.difficulty = difficulty
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Factory
    /// Phase 7-1 — characterID + difficulty 둘 다 default 인자. TitleScene만 두 인자 모두 명시 → 회귀 0.
    class func newGameScene(characterID: CharacterID = .kim, difficulty: Difficulty = .easy) -> GameScene {
        let scene = GameScene(size: CGSize(width: 1024, height: 768), characterID: characterID, difficulty: difficulty)
        scene.scaleMode = .resizeFill   // Phase 1-3 핫픽스: scene size를 view 크기에 자동 맞춤 — D-Pad가 viewport 안에 들어오게 함
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupBackground()    // 1-2 그대로 (.ganhoBgDeep)
        setupWorld()         // worldNode + 외곽 벽 4개 (2-1) + 중앙 기둥 (2-2)
        setupPlayer()        // PlayerNode를 worldNode 자식으로
        setupCamera()        // cameraNode (1-2 그대로)
        setupDPad()          // 1-3 신설 — DPadNode를 cameraNode 자식으로
        setupHUD()           // Phase 2-4 신설 — HUDNode를 cameraNode 좌상단에
        setupEnemy()         // Phase 2-6 신설 — EnemyNode를 worldNode 자식으로
        setupStoneGuard()    // Phase 4-1 신설 — StoneGuardNode를 worldNode 자식으로 (4 waypoint 시계방향)
        setupProfessor()     // Phase 9-7 신설 — ProfessorNode를 worldNode 자식으로 (hard만, 가드 내부)
        setupSkillButton()   // Phase 9-5 — SkillButtonNode를 cameraNode 좌하단에
        setupHUDSkillSlot()  // Phase 9-5 — HUDSkillSlotNode를 SkillButton 위에
        setupPauseButton()   // Sprint 3 — PauseButtonNode를 cameraNode 우상단에 (시각 placeholder)
        skillSystem.configure(scene: self, skill: characterID.skill)  // Phase 9-5 — 활성 스킬 set
        physicsWorld.gravity = .zero   // Phase 2-2 — 탑다운 게임이라 중력 없음
        configureContactRouter()                       // Phase 2-11 — 콜백 4개 등록
        physicsWorld.contactDelegate = contactRouter   // Phase 2-11 — 분기는 ContactRouter가 담당

        // Phase 6-13 — 게임 시작 전 카운트다운. .countdown 상태는 update의 모든
        // 시스템 로직(스폰/타이머/이동/카메라/적/콤보 폴링)을 자동 차단한다
        // (기존 `guard gameState == .playing` 가드 1개로 7개 시스템 동시 정지).
        // SpawnSystem.start / bgm.play / gameState = .playing 3개는 GO! 콜백
        // 시점(startGameProperly)에 이전 — 카운트다운 동안 *어떤 시스템도 돌지 않는다*.
        // Phase 7-3 — 카운트다운 *전*에 인트로 컷씬 진입. .cutscene 상태도 .countdown과 동일하게
        // update `guard gameState == .playing`에서 자동 차단 → 7개 시스템 동시 정지.
        // 컷씬 탭 종료 시 dismissed 콜백에서 .countdown 전환 + showCountdown() 호출 → 기존 흐름 그대로.
        // Phase 7-5 — UserDefaults 분기. bool 기본값 false → 최초 사용자만 컷씬 표시.
        // 두 번째 이상 진입은 *컷씬 스킵 → 곧장 카운트다운*. onDismiss에서 true set 후 영원 스킵.
        let hasSeenIntro = UserDefaults.standard.bool(forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
        if hasSeenIntro {
            // Phase 10-1d — 2회차 이상도 경고 컷씬은 *매 판* 환기 (SPEC §주의사항 7 / GDD §3).
            // 인트로 컷씬만 영구 스킵 — 적 출현 경고는 매 판 다시 보여 위협 인지 갱신.
            gameState = .cutscene
            switch difficulty {
            case .easy, .normal: showStoneGuardWarningCutscene()
            case .hard:          showProfessorWarningCutscene()
            }
        } else {
            gameState = .cutscene
            showIntroCutscene()
        }
    }

    // MARK: - Cutscene (Phase 7-3)
    /// 게임 시작 직전 화면 전체 컷씬 1회 발화. 난이도별 본문 분기 + `{NAME}` 토큰 치환 후 present.
    /// onDismiss 콜백에서 .countdown 전환 + showCountdown() 호출 — 기존 카운트다운 흐름 *그대로* 진입.
    /// CutsceneOverlayNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    /// 난이도 분기: easy/normal = 수간호사 순찰 톤, hard = 이교수 청진기 톤.
    /// `{NAME}` 토큰 치환은 easy/normal 본문에만 1개 등장 — hard 본문은 캐릭터 비독립이라 토큰 0개(자연 무동작).
    /// onDismiss는 [weak self] 캡처 필수 — 컷씬 표시 중 씬 전환 가능성 대비 (CountdownNode 콜백 패턴 답습).
    private func showIntroCutscene() {
        let title = "어느 한적한 병동의 오후"
        let template: String
        switch difficulty {
        case .easy, .normal:
            template = "수간호사가 순찰을 돈다. 그 틈을 타, {NAME}는 주머니 속 작곡 노트를 슬쩍 꺼낸다… 음표를 모으자."
        case .hard:
            template = "학교에서 나온 깐깐한 이교수가 오늘따라 청진기를 휘두른다. 날아오는 청진기를 피하며 음표를 모으자. 수간호사는 언제나 그렇듯 순찰을 돈다."
        }
        // {NAME} 토큰 치환 — hard 본문에는 토큰이 없어 자연 무동작(원본 동일 반환).
        let body = template.replacingOccurrences(of: "{NAME}", with: characterID.displayName)
        CutsceneOverlayNode.present(
            title: title,
            body: body,
            parent: cameraNode,
            sceneSize: size,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                // Phase 7-5 — 컷씬 종료 시 UserDefaults 플래그 set → 이후 진입은 자동 스킵.
                // UserDefaults.standard 접근은 self 무관 — self 해제 시에도 플래그는 set됨(부수효과 안전).
                UserDefaults.standard.set(true, forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
                // Phase 10-1d — 난이도별 경고 컷씬 2단계 분기.
                // easy/normal: 석조무사 경고 (신규, GDD §10 미구현 → 완성).
                // hard: 이교수 경고 (Phase 9-7).
                // 두 분기 모두 CutsceneOverlayNode 자가 소멸 *직후* 새 컷씬 present → 동시 표시 0.
                switch self.difficulty {
                case .easy, .normal: self.showStoneGuardWarningCutscene()
                case .hard:          self.showProfessorWarningCutscene()
                }
            }
        )
    }

    /// Phase 10-1d — 석조무사 경고 컷씬. easy/normal 난이도 인트로 컷씬 dismiss 직후 발화.
    /// CutsceneOverlayNode 재사용 (SPEC §"금지": 신규 컷씬 노드 신설 금지).
    /// showProfessorWarningCutscene와 시그니처 동형 — title/body만 GameConfig 상수로 교체.
    /// onDismiss에서 .countdown 전환 + showCountdown — 인트로/이교수 경고와 동일 흐름.
    /// [weak self] 캡처 — 컷씬 표시 중 씬 전환 가능성 대비.
    private func showStoneGuardWarningCutscene() {
        CutsceneOverlayNode.present(
            title: GameConfig.stoneGuardWarningTitle,
            body: GameConfig.stoneGuardWarningBody,
            parent: cameraNode,
            sceneSize: size,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.gameState = .countdown
                self.showCountdown()
            }
        )
    }

    /// Phase 9-7 — 이교수 경고 컷씬. hard 난이도에서 인트로 컷씬 dismiss 직후 1회 발화.
    /// CutsceneOverlayNode 재사용 (SPEC §허용 14: 신규 컷씬 노드 신설 금지).
    /// onDismiss에서 .countdown 전환 + showCountdown — 인트로 컷씬과 동일 흐름.
    /// [weak self] 캡처 — 컷씬 표시 중 씬 전환 가능성 대비.
    private func showProfessorWarningCutscene() {
        CutsceneOverlayNode.present(
            title: GameConfig.professorWarningTitle,
            body: GameConfig.professorWarningBody,
            parent: cameraNode,
            sceneSize: size,
            onDismiss: { [weak self] in
                guard let self = self else { return }
                self.gameState = .countdown
                self.showCountdown()
            }
        )
    }

    // MARK: - Countdown (Phase 6-13)
    /// CountdownNode 생성 + cameraNode 부착 + start 진입점 호출.
    /// - onTick: 매 숫자(3/2/1) 표시 직후 light 햅틱 (사운드 없음 — *조용한 카운팅* 톤).
    /// - onGo: GO! 표시 직후 heavy 햅틱 + `comboMilestoneStrong` 사운드 (NewMail 1025 — 긍정 묵직).
    /// - onComplete: GO! 페이드아웃 + 노드 제거 직후 startGameProperly() — 실제 게임 시동.
    /// 콜백 3개 모두 [weak self] 캡처 — 카운트다운 진행 중 씬 전환 가능성 대비 (안전한 해제 의미).
    /// CountdownNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    private func showCountdown() {
        let node = CountdownNode()
        cameraNode.addChild(node)
        node.start(
            onTick: { [weak self] _ in
                self?.haptics.light()
            },
            onGo: { [weak self] in
                guard let self = self else { return }
                self.haptics.heavy()
                self.audio.play(.comboMilestoneStrong)
            },
            onComplete: { [weak self] in
                self?.startGameProperly()
            }
        )
    }

    /// GO! 카운트다운 종료 직후 호출. 실제 게임 시스템을 가동.
    /// 기존 didMove 끝의 3줄(spawnSystem.start / gameState = .playing / bgm.play)을 이쪽으로 이동 —
    /// 코드 자체는 *완전 동일*, 호출 시점만 늦춤. gameState .countdown → .playing 전환 시
    /// update의 `guard gameState == .playing else { return }` 한 줄이 자동 해제되어
    /// 7개 시스템(타이머/이동/카메라/적/콤보폴링/끊김폴링/score)이 동시 가동된다.
    private func startGameProperly() {
        // Phase 7-1 — SpawnSystem 난이도 차등 적용. start 직전 1회 호출 (인스턴스 프로퍼티 6개 set).
        // start 직전 호출 이유: noteSpawnLoop / scheduleNextFire가 이미 인스턴스 프로퍼티를 참조하므로
        // 첫 사이클부터 차등 동작이 적용된다.
        spawnSystem.apply(difficulty)
        // Phase 2-10 — spawn / fire 두 루프를 SpawnSystem으로 위임. 진행률 closure로 공급.
        spawnSystem.start(
            scene: self,
            world: worldNode,
            player: player,
            enemy: enemy,
            progressProvider: { [weak self] in
                guard let self = self else { return 0 }
                return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
            }
        )
        gameState = .playing // playing 전환 후에야 update가 동작
        bgm.play()           // Phase 6-4 — playing 전환 직후 BGM 시작 (음원 없으면 noop)
    }

    /// scene.size 변경 시 SpriteKit이 호출 (.resizeFill 모드에서 view bounds 변경 시 자동 트리거).
    /// cameraNode 자식의 화면 고정 위치(D-Pad / HUD)를 재계산해서 viewport에 맞춤.
    /// 첫 attach 시점에도 scene이 1024×768 → view 크기로 갱신되며 호출됨.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutDPad()
        layoutHUD()
        layoutSkillButton()    // Phase 9-5 — 화면 회전/resize 시 좌하단 SkillButton 재배치
        layoutHUDSkillSlot()   // Phase 9-5 — 화면 회전/resize 시 SkillButton 위 HUDSkillSlot 재배치
        layoutPauseButton()    // Sprint 3 — 화면 회전/resize 시 우상단 PauseButton 재배치
    }

    /// scene.size 변경 시(viewport 회전·resize)에 위치만 재계산. addChild 0건 — 멱등 보장.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙, +x 우, +y 상. 우하단 = (+x, -y).
    func layoutDPad() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        dpad.position = CGPoint(
            x: +(halfW - GameConfig.dpadMarginX),
            y: -(halfH - GameConfig.dpadMarginY)
        )
    }

    /// scene.size 변경 시 위치만 재계산. addChild 0건 — 멱등.
    /// Phase 8-5 — 좌상단 anchor에서 *상단 중앙* anchor로 변경. HUDNode 내부가 가로 4슬롯 중앙 정렬 구조.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 상단 중앙 = (0, +halfH - margin).
    func layoutHUD() {
        let halfH = size.height / 2
        hud.position = CGPoint(
            x: 0,                                   // 가로 중앙
            y: +(halfH - GameConfig.hudTopMargin)   // 상단에서 28pt 아래
        )
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        // 첫 프레임 처리
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // 상태 가드 — playing이 아니면 입력/이동/카메라 모두 정지
        guard gameState == .playing else { return }

        // Phase 2-4 — 45초 카운트다운. 0 도달 시 즉시 종료(early return)으로
        // 이번 프레임의 player/카메라/HUD 갱신은 건너뛴다.
        remainingTime = max(0, remainingTime - dt)
        if remainingTime <= 0 {
            endGame()
            return
        }

        // Phase 6-14 — 5초 긴박감 폴링 (.playing 상태에서만, 위 guard 통과 후).
        // 카운트다운(.countdown) 중에는 위 `guard gameState == .playing`에서 이미 차단 →
        // BGM 미재생 상태와 시간 비교차 0. 카운트다운(2~3초) + 5초 윈도우는 시간상 *겹칠 일 0*.
        // 0 도달 분기는 위 early return에서 처리되므로 여기 진입 시 remainingTime > 0 보장.
        if remainingTime <= GameConfig.tensionWindow {
            // 첫 진입 1회 setup — HUD 깜빡임 시작. BGM rate는 아래 보간이 매 프레임 set.
            if !tensionStarted {
                tensionStarted = true
                hud.startTensionBlink()
            }
            // 매 프레임 rate 보간: 1.0 + 0.15 × (5 - remainingTime) / 5.
            // TimeInterval(Double) → Float 캐스팅 — AVAudioPlayer.rate는 Float 타입.
            // AVAudioPlayer.rate setter는 idempotent → 매 프레임 호출 안전 (Apple 문서).
            let progress = Float((GameConfig.tensionWindow - remainingTime) / GameConfig.tensionWindow)
            let clamped = max(Float(0), min(Float(1), progress))
            let rate = GameConfig.tensionRateBase + (GameConfig.tensionRateMax - GameConfig.tensionRateBase) * clamped
            bgm.setRate(rate)
            // 매초 정수 변화 시 light 햅틱 (5→4, 4→3, 3→2, 2→1 = 4회).
            // HUD timeLabel이 보여주는 ceil 식과 동일 — *눈에 보이는 숫자가 바뀐 순간* 발화.
            // 0초 도달은 위 early return에서 처리되어 여기로 안 옴 (4회 발화 정확 보장).
            let now = max(0, Int(ceil(remainingTime)))
            if now != lastRemainingTimeSecond {
                lastRemainingTimeSecond = now
                if now >= 1 && now <= 4 {
                    haptics.light()
                }
            }
        }

        // Phase 2-5 — 콤보 윈도우 만료 검사 (Phase 2-12: ScoreSystem에 위임)
        scoreSystem.tickComboExpiry(currentTime: currentTime)

        // Phase 9-5 — SkillSystem 매 프레임 진행 (쿨다운/지속시간 감산).
        skillSystem.update(dt: dt)

        // 1) D-Pad 입력을 PlayerNode로 위임 (DPadNode → PlayerNode 직접 참조 금지 → GameScene 경유)
        // Phase 9-5 — 정간호 돌진 중에는 D-Pad 입력 무시(SKAction.move가 위치 제어). 가드 1줄.
        // Phase 9-7 — 청진기 동결 중에도 D-Pad 입력 무시. AND 가드로 두 조건 결합 — 스킬 가드 회귀 0.
        // 동결 시 currentDirection = .zero로 즉시 set → PlayerNode.update 가드 도달 전에도
        // *마지막 방향 잔존*으로 인한 미세 이동 방지.
        if !skillSystem.isDashing && !player.isFrozen {
            player.currentDirection = dpad.currentDirection
        } else if player.isFrozen {
            player.currentDirection = .zero
        }

        // 2) PlayerNode 자체 dt 보간 이동 (도메인이 자기 갱신)
        // 돌진 중에는 currentDirection이 zero로 유지되어 velocity 0 — SKAction.move만 위치 변경.
        player.update(deltaTime: dt)

        // Phase 8-1 — PlayerNode 픽셀 방향/걷기 프레임 갱신 (시각만 — 게임 로직 무관).
        // velocity가 set된 *직후* 읽어야 이번 프레임의 의도가 즉시 반영됨.
        // physicsBody?.velocity는 옵셔널 — guard let 패턴(주의사항 5).
        let velocity = player.physicsBody?.velocity ?? .zero
        let isMoving = abs(velocity.dx) > 0.1 || abs(velocity.dy) > 0.1
        player.updatePixelDirection(velocity)
        player.tickWalkFrame(deltaTime: dt, isMoving: isMoving)

        // 3) 카메라 follow — Phase 1-5: 드론 follow. player가 늘 화면 정중앙. 클램프 없음 (회피 게임 본질)
        cameraNode.position = player.position

        // 4) Phase 2-6 — 적 직선 추적 (player 위치를 향해 velocity 갱신)
        // Phase 2-8 — 게임 진행률 0 ~ 1 (시작 0, 끝 1). remainingTime은 max(0, ...)으로 음수 방지.
        // speedT는 CGFloat (EnemyNode.update 시그니처 일치) — TimeInterval(Double) → CGFloat 변환.
        let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)
        enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)

        // Phase 9-7 — 이교수 픽셀 애니메이션 갱신 (hard만). easy/normal에선 professor=nil → optional chain 자연 noop.
        // SKAction.move 기반이라 position 변화량으로 방향/걷기 프레임 산출 (ProfessorNode 내부 자기 처리).
        professor?.updatePixelAnimation(deltaTime: dt)

        // 5) HUD 라벨 갱신 (Phase 2-4) — Phase 2-12: ScoreSystem에서 값 조회
        hud.update(score: scoreSystem.score, remainingTime: remainingTime, combo: scoreSystem.combo)

        // 6) Phase 6-12 — 콤보 끊김 폴링. tickComboExpiry(콤보 윈도우 만료)가 같은 프레임에
        // 콤보를 0으로 떨어뜨린 직후를 캡처. F 피격 경로는 별도 분기(configureContactRouter).
        // playing 상태에서만 실행 — gameOver 전환 후엔 위 guard에서 이미 차단됨.
        // ScoreSystem 시그니처 미변경(옵션 B 폴링) — 6-10 환호 폴링과 같은 패턴.
        let currentCombo = scoreSystem.combo
        if lastComboValue >= GameConfig.comboBreakThreshold, currentCombo == 0 {
            triggerComboBreak(brokenAt: lastComboValue)
        }
        lastComboValue = currentCombo

        // Phase 9-5 — HUDSkillSlot 진행률 시각화. SkillSystem.progress는 4 상태 분기 후 반환.
        hudSkillSlot.update(progress: skillSystem.progress)
    }

    // MARK: - Contact Router
    /// ContactRouter의 4개 콜백을 등록. didMove 안에서 1회 호출.
    /// Phase 2-12 — onNoteCollected의 콤보/점수 로직은 ScoreSystem.recordNoteHit으로 위임.
    /// onProjectileHitWall은 self 미사용 — [weak self] 불필요.
    private func configureContactRouter() {
        contactRouter.onEnemyHit = { [weak self] in
            guard let self = self else { return }
            // Phase 9-5 — 이간호 텔레포트/정간호 돌진 중 무적 가드.
            // SkillSystem이 player.isInvulnerable을 자체 시퀀스로 토글.
            if self.player.isInvulnerable { return }
            self.endGame()
        }
        contactRouter.onProjectileHitPlayer = { [weak self] node in
            guard let self = self else { return }
            // Phase 9-5 — enchanted F 가드. ProjectileNode.isEnchanted = true면
            // 일반 endGame이 아니라 *수집*으로 처리 — 점수 가산 + 노드 제거 후 early return.
            if let projectile = node as? ProjectileNode, projectile.isEnchanted {
                self.scoreSystem.recordCharmedNoteHit()
                self.haptics.light()
                self.audio.play(.noteCollected)
                projectile.run(.removeFromParent())
                return
            }
            // Phase 9-5 — 일반 F도 무적 시(이간호 텔레포트) 차단.
            if self.player.isInvulnerable { return }
            // Phase 6-9 — 시각 임팩트 2채널: 카메라 셰이크 + 빨간 플래시.
            // haptics.heavy() (6-1) + audio.play(.gameOver) (6-2) + BGM stop (6-4)은
            // endGame() 내부에서 이미 발화 — 5채널 멀티모달 피격 피드백 완성.
            // 시각 효과 → 상태 전환 순서: 피격 콜백에서 시각만 일으키고,
            // gameOver 상태 전환은 endGame이 전담(책임 분리).
            self.cameraNode.run(CameraShakeAction.make())
            let flash = HitFlashNode()
            self.cameraNode.addChild(flash)
            flash.flash(sceneSize: self.size)
            // Phase 6-12 — F 피격 시점에 콤보 10+이면 BREAK 발화 (endGame 직전).
            // endGame이 gameState를 .gameOver로 전환하면 update 폴링이 차단되므로 여기서 강제 검사.
            self.checkAndTriggerComboBreak()
            self.endGame()
        }
        contactRouter.onProjectileHitWall = { node in
            node.run(.removeFromParent())
        }
        contactRouter.onNoteCollected = { [weak self] note in
            guard let self = self else { return }
            self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
            self.haptics.light()   // Phase 6-1 — 수집 손맛
            self.audio.play(.noteCollected)   // Phase 6-2 — 수집 사운드 (햅틱 → 사운드 순서)
            // Phase 6-8 — note 위치에서 sparkle 8방향 방사. note는 worldNode 자식이므로
            // worldNode 좌표계 위치를 캡처해 같은 worldNode에 sparkle을 부착 → 카메라 follow 자연 동기.
            // note.position을 *먼저* 캡처 — note.removeFromParent() 후엔 노드가 트리에서 빠짐.
            let sparkleOrigin = note.position
            let sparkle = SparkleEffectNode()
            sparkle.position = sparkleOrigin
            self.worldNode.addChild(sparkle)
            sparkle.emit()
            // Phase 6-16 — 노트 수집 자리에 "+1"/"+2" 텍스트 1회 발화 (시각 채널만).
            // recordNoteHit 직후의 combo로 점수 분기 — ScoreSystem 시그니처 미접촉(옵션 B 폴링).
            // worldNode 부모: sparkle과 동일 좌표계 → 카메라 follow와 자연 동기.
            let gainedPoints = self.scoreSystem.combo >= GameConfig.comboBonusThreshold
                ? GameConfig.scorePerNoteCombo
                : GameConfig.scorePerNote
            ScorePopupNode.spawn(at: sparkleOrigin, gainedPoints: gainedPoints, parent: self.worldNode)
            // Phase 6-10 — 콤보 마일스톤 도달 시 화면 중앙 텍스트 팝업 1회 발화 (멱등성).
            // recordNoteHit 직후의 combo 값을 폴링 — ScoreSystem 시그니처 미변경(옵션 B).
            let currentCombo = self.scoreSystem.combo
            if GameConfig.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                // Phase 6-11 — 가드 안쪽에서 3감각 동시 발화. 촉각→청각→시각 순서로 prepend.
                // 회귀 0: 6-10의 시각 코드(ComboPopupNode)는 마지막 위치 그대로 유지.
                // 멱등성 신뢰: triggeredComboMilestones Set이 한 판 1회만 통과시키므로
                // 사운드/햅틱도 시각과 동일하게 1회만 발화 — 비대칭 0.
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                self.cameraNode.addChild(popup)
                popup.animate()
            }
            note.run(.removeFromParent())
        }
        contactRouter.onStoneGuardContact = { [weak self] in
            self?.triggerAirforceEasterEgg()
        }
        // Phase 9-7 — 청진기 명중 콜백. F 피격(onProjectileHitPlayer) 패턴 미러 + freeze 발화.
        // 무적(isInvulnerable) 우선 가드 — 이간호 텔레포트와 일관성(주의사항 4).
        // didBegin 즉시 removeFromParent 금지 → node.run(.removeFromParent()) SKAction 사용(주의사항 6).
        contactRouter.onStethoscopeHitPlayer = { [weak self] node in
            guard let self = self else { return }
            if self.player.isInvulnerable {
                node.run(.removeFromParent())
                return
            }
            // 멀티모달 피드백: 햅틱 medium + 카메라 셰이크 + "청진기 명중!" 토스트.
            // BGM/효과음 신규 추가 금지(SPEC §금지 2) — 기존 audio.play 호출 0건.
            self.haptics.medium()
            self.cameraNode.run(CameraShakeAction.make())
            ToastLabelNode.spawn(text: GameConfig.stethoscopeToastText,
                                 at: self.player.position,
                                 parent: self.worldNode)
            // 2초 동결 발화. PlayerNode.freeze 내부에서 isFrozen 가드 + 깜빡임 시퀀스 진행.
            self.player.freeze(duration: GameConfig.playerFreezeDuration)
            node.run(.removeFromParent())
        }
        // 청진기 ↔ wall 접촉 시 — onProjectileHitWall 패턴 답습. self 미사용 → [weak self] 불필요.
        contactRouter.onStethoscopeHitWall = { node in
            node.run(.removeFromParent())
        }
        // Phase 9-6 — 변기 보너스 수집. onNoteCollected 패턴 미러 (콤보/마일스톤 분기 자연 발화).
        // 음표 2개 효과 = recordToiletBonus(=recordNoteHit 2회) + ScorePopup fan-out 2개 + 토스트 1개.
        contactRouter.onToiletCollected = { [weak self] toilet in
            guard let self = self else { return }
            let toiletOrigin = toilet.position
            // 1. 도메인: 점수+2 / 콤보+2 단일 진입점 호출 (마일스톤 분기는 아래 폴링).
            self.scoreSystem.recordToiletBonus(at: self.lastUpdateTime)
            // 2. 멀티모달 피드백: 음표 수집보다 *살짝 강한* 손맛 — medium(음표 수집은 light).
            //    audio는 noteCollected 재사용(SPEC 금지 4: BGM/효과음 신규 0).
            self.haptics.medium()
            self.audio.play(.noteCollected)
            // 3. sparkle 시각 — 음표 수집과 동형. toilet은 worldNode 자식이므로 worldNode 좌표 그대로.
            let sparkle = SparkleEffectNode()
            sparkle.position = toiletOrigin
            self.worldNode.addChild(sparkle)
            sparkle.emit()
            // 4. "화캉스 보너스!" 0.9초 토스트.
            ToastLabelNode.spawn(text: GameConfig.toiletToastText,
                                 at: toiletOrigin,
                                 parent: self.worldNode)
            // 5. ScorePopup fan-out — 좌·우 ±toiletScorePopupFanOutX(8) offset으로 2개 동시 발화 →
            //    *음표 2개 동시 수집* 시각 시그널. 색은 현재 콤보 상태에 따라 분기(음표 수집과 동일 규칙).
            let gained = self.scoreSystem.combo >= GameConfig.comboBonusThreshold
                ? GameConfig.scorePerNoteCombo
                : GameConfig.scorePerNote
            ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x - GameConfig.toiletScorePopupFanOutX,
                                             y: toiletOrigin.y),
                                 gainedPoints: gained,
                                 parent: self.worldNode)
            ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x + GameConfig.toiletScorePopupFanOutX,
                                             y: toiletOrigin.y),
                                 gainedPoints: gained,
                                 parent: self.worldNode)
            // 6. 마일스톤 분기 — 음표 수집 콜백 패턴 정확 답습. recordToiletBonus가 콤보 2회 증가시켰으므로
            //    하나의 사이클에서 *두 마일스톤 통과* 가능(예: combo 2→3→4가 3 통과). 단일 멱등 Set 가드는
            //    그대로 — 두 번째 마일스톤 통과는 다음 변기/노트 수집에서 검사. 즉 *건너뛴 마일스톤*은
            //    한 판에서 1회만 발화 가능 — Set 멱등성 신뢰.
            let currentCombo = self.scoreSystem.combo
            if GameConfig.comboMilestones.contains(currentCombo),
               !self.triggeredComboMilestones.contains(currentCombo) {
                self.triggeredComboMilestones.insert(currentCombo)
                self.playComboMilestoneFeedback(for: currentCombo)
                let popup = ComboPopupNode(milestone: currentCombo)
                self.cameraNode.addChild(popup)
                popup.animate()
            }
            // 7. 노드 제거 — didBegin 진행 중 즉시 removeFromParent는 크래시 위험.
            //    SKAction.removeFromParent()를 1프레임 지연으로 사용 → 안전.
            //    applyLifetime의 fadeOut/remove 액션이 진행 중이어도 부모에서 빠진 후엔 noop.
            toilet.run(.removeFromParent())
        }
    }

    // MARK: - Combo Milestone Feedback (Phase 6-11)
    /// 콤보 마일스톤(3/5/10/20) 도달 시 햅틱/사운드를 등급별로 발화.
    /// 시각(ComboPopupNode.color(for:)) 4단계와 다르게 청각/촉각은 2~3단계로 광역 그룹화:
    /// x3/x5 → light + soft (노트 수집 연장선), x10 → medium + soft (황금기 진입 신호),
    /// x20 → heavy + strong (gameOver와 같은 무게지만 톤은 긍정).
    /// 인간 지각상 색은 미세 구분 가능, 진동/소리는 거친 카테고리라 시각이 *세밀*하고
    /// 청각/촉각이 *광역*인 비대칭이 자연스럽다.
    /// default는 graceful fallback — 미래 `comboMilestones` 배열 확장 시 크래시 방지 안전망.
    /// (이번 sprint는 배열 변경 금지라 default는 실행 경로 아님.)
    /// ComboPopupNode.color(for:) static 메서드와 위치/형태 대칭 — 한 곳은 시각 매핑, 한 곳은 피드백 매핑.
    private func playComboMilestoneFeedback(for milestone: Int) {
        switch milestone {
        case 3, 5:
            haptics.light()
            audio.play(.comboMilestoneSoft)
        case 10:
            haptics.medium()
            audio.play(.comboMilestoneSoft)
        case 20:
            haptics.heavy()
            audio.play(.comboMilestoneStrong)
        default:
            // 미래 마일스톤 추가 대비 안전망. 6-10 color(for:)와 동일한 graceful fallback 정책.
            haptics.light()
            audio.play(.comboMilestoneSoft)
        }
    }

    // MARK: - Combo Break Feedback (Phase 6-12)
    /// 콤보 10+ 상태에서 0으로 떨어진 순간 호출. 시각(ComboBreakNode) + 햅틱(heavy) 2채널 발화.
    /// 사운드는 본 sprint 범위 외 — 환호(6-11)와의 의도적 비대칭(실망은 *침묵의 한숨* 톤).
    /// 멱등 가드: 같은 끊김 값은 한 판 1회만 발화. 6-11 환호 가드와 동일 패턴, 완전 분리된 Set 사용.
    /// 호출 경로 2개: update 폴링 / onProjectileHitPlayer 클로저 (endGame 직전).
    /// 두 경로가 같은 helper를 호출 → DRY + 같은 값 2회 발화 방지(Set.contains 가드).
    private func triggerComboBreak(brokenAt brokenValue: Int) {
        if triggeredComboBreaks.contains(brokenValue) { return }
        triggeredComboBreaks.insert(brokenValue)
        // 부정 이벤트 → 게임오버와 동일 강도(heavy). 6-11 환호(light/medium/heavy)와 의도적 대칭.
        // light/medium은 노트 수집·콤보 환호에 점유됨 → 실망은 heavy가 자연.
        haptics.heavy()
        let breakNode = ComboBreakNode(brokenCombo: brokenValue)
        cameraNode.addChild(breakNode)
        breakNode.animate()
    }

    /// F 피격 분기에서 호출. 콤보 임계값 미달이면 noop.
    /// endGame() 전 *마지막* 발화 기회 — endGame이 gameState를 .gameOver로 바꾸면
    /// update 폴링이 `guard gameState == .playing` 이후 차단되므로 여기서 강제 검사.
    /// 폴링 경로(update)와 분리된 이유: F 피격은 SpriteKit physics callback에서 발생 →
    /// update 흐름 밖이라 폴링으로 못 잡힘. 두 경로 모두 triggerComboBreak로 수렴.
    private func checkAndTriggerComboBreak() {
        let combo = scoreSystem.combo
        if combo >= GameConfig.comboBreakThreshold {
            triggerComboBreak(brokenAt: combo)
        }
    }

    // MARK: - Easter Egg
    /// Player ↔ StoneGuard 첫 접촉 시 호출. 1회 한정 가드 후 비행기 1마리를 cameraNode에 부착,
    /// 좌→우 가로지르기 SKAction 실행. AirplaneNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    /// 점수/HUD/적/게임오버 로직 일체 미접촉 — 순수 시각 이스터에그.
    /// Phase 4-4 — 동일 가드 안쪽에 AirforceOverlayNode("나와라 박병장!") 동시 부착.
    /// 두 노드는 서로 모르며 각자 자기 SKAction으로 자가 소멸(fire-and-forget).
    /// Phase 4-5 — 동일 가드 안쪽에 BombFlashNode 폭탄 플래시도 동시 발화, 자가 소멸.
    /// Phase 4-6 — 동일 가드 안쪽에 enemy.startFleeing(...) 호출로 수간호사 5초 도주 모드 진입.
    /// Phase 4-7 — startFleeing onEnd 콜백 등록 — 도주 종료 시 spawnSystem.fireImmediately() 발화.
    private func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        // Phase 9-8 — hard 난이도 다층 방어 가드. setupStoneGuard에서 이미 stoneGuard 미등록이라
        // 이 메서드 자체로 진입할 경로가 없으나, 호출 경로 변경 시 회귀 차단용 안전망(Spring @PreAuthorize 답습).
        if difficulty == .hard { return }
        airforceTriggered = true
        // t=0 — 오버레이 즉시 표시(자가 2.4초 후 소멸).
        let overlay = AirforceOverlayNode()
        cameraNode.addChild(overlay)
        overlay.showAndDismiss()
        // t=0 — 수간호사 도주 모드 진입(5초 후 onEnd 콜백으로 F 1발 재발사).
        enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in
            self?.spawnSystem.fireImmediately()
        }
        // Phase 9-8 — 비행기는 오버레이 완전 소멸(t=2.4) 후 등장. SKAction.sequence 지연 attach 패턴.
        // AirplaneNode 시그니처 불변. [weak self] 캡처로 endGame 중 self 해제 안전.
        let plane = AirplaneNode()
        let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
        let wait = SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)
        let attach = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.cameraNode.addChild(plane)
            plane.crossScreen(sceneWidth: self.size.width, atY: y)
        }
        cameraNode.run(.sequence([wait, attach]))
        // t=3.4 — 비행기 중앙 도달 시점에 폭탄 섬광. bombFlashDelay 상수(3.4)가 BombFlashNode 내부에서 자동 적용.
        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)
    }

    // MARK: - Game State
    /// 시간 만료 / enemy 접촉 / F 피격 시 호출. gameState 전환 + 모든 액션·velocity 정지.
    /// Phase 2-10 — spawn / fire 정지 + projectile velocity 정지를 SpawnSystem.stop()으로 위임.
    /// Phase 3-1+2 — 멱등 가드 추가 (적/F/시간 동시 발생 시 1회만 실행).
    /// Phase 3-3 — 오버레이/가드 패턴 폐기. 정지 작업 후 ResultScene으로 fade transition.
    private func endGame() {
        // 멱등 가드 — 이미 종료됐으면 아무 것도 안 함.
        if gameState == .gameOver { return }
        gameState = .gameOver
        haptics.heavy()   // Phase 6-1 — 종료 무게감 (가드 통과 1회만)
        audio.play(.gameOver)   // Phase 6-2 — heavy 직후, spawnSystem.stop() 전
        bgm.stop()           // Phase 6-4 — gameOver 사운드와 동시에 BGM 정지 (멱등 가드 안쪽 = 1회 보장)
        hud.stopTensionBlink()   // Phase 6-14 — 깜빡임 즉시 종료 (잔상 0). 0초 만료 / F 피격 / enemy 접촉 모든 경로에서 발화.
        spawnSystem.stop()
        // Phase 9-7 — 이교수 청진기 발사 루프 정지 + 활성 청진기 velocity 0.
        // easy/normal에선 professor=nil → optional chain 자연 noop.
        professor?.stopThrowing(worldNode: worldNode)
        player.currentDirection = .zero
        player.physicsBody?.velocity = .zero
        enemy.physicsBody?.velocity = .zero   // Phase 2-6 — 관성 정지
        hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)

        // Phase 3-3 — 결과 표시는 ResultScene이 담당. presentScene 직후 GameScene 자식은 ARC로 해제됨.
        // Phase 3-4 — record → current 순서가 핵심. record가 디스크를 갱신한 *직후* current를 읽으면
        // 신기록일 때 bestScore가 *이번 점수*가 된다(자기 일관성).
        // Phase 3-5 — recordPlay → current도 같은 record/current 패턴.
        // 순서: record(highScore) → current(best) → recordPlay(stats) → current(stats).
        guard let view = self.view else { return }
        let score = scoreSystem.score
        let isNewBest = highScoreRepo.record(score)
        let bestScore = highScoreRepo.current
        statsRepo.recordPlay(score: score)
        let stats = statsRepo.current
        // Phase 7-4 — 매트릭스 갱신 + 졸업 판정 + 최초 일시 기록.
        // 순서: matrix.record → isGraduated(matrix) → graduation.record(Date()) → graduation.graduatedAt.
        // perDiffRepo.record는 새 점수가 셀 최고를 갱신했는지 무관하게 호출 — 매트릭스 자기 일관성 우선.
        // isGraduated가 매트릭스 *최신 상태*를 읽으므로 record→isGraduated 순서가 중요.
        // record(Date())는 *최초 졸업*에만 true 반환 → 이후 갱신 호출은 false → 일시 영원 동일.
        // graduatedAt(:)는 최초 기록 이후라면 항상 유효한 Date 반환 — Optional은 한 번도 졸업 안 했을 때만 nil.
        perDiffRepo.record(characterID: characterID, difficulty: difficulty, score: score)
        var isNewGraduation = false
        if GameScene.isGraduated(characterID: characterID, scores: perDiffRepo) {
            isNewGraduation = graduationRepo.record(characterID: characterID, date: Date())
        }
        let graduatedAt = graduationRepo.graduatedAt(characterID: characterID)
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterName: characterID.displayName,
            difficulty: difficulty,
            isNewGraduation: isNewGraduation,
            graduatedAt: graduatedAt
        )
        view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }

    // MARK: - Graduation (Phase 7-4)
    /// 캐릭터의 모든 난이도(easy/normal/hard)가 목표 점수 이상 달성됐는지 검사.
    /// 한 난이도라도 목표 미달이면 false. 모든 난이도 통과 시 true.
    /// `Difficulty.allCases` 순회 — 미래 난이도 추가 시 자동 반영(GameConfig.targetScoreByDifficulty dict 한 줄만 추가).
    /// static 헬퍼 — GameScene 인스턴스 상태 미접근 (순수 함수). 미래 TitleScene 뱃지 등에서도 재사용 가능.
    /// 목표 점수 dict 조회 실패 시 `Int.max` 폴백 — 어떤 점수로도 달성 불가 = 졸업 차단 (graceful 안전망).
    private static func isGraduated(characterID: CharacterID,
                                    scores repo: PerDifficultyScoreRepository) -> Bool {
        let targets = GameConfig.targetScoreByDifficulty
        for difficulty in Difficulty.allCases {
            let target = targets[difficulty] ?? Int.max
            if repo.best(characterID: characterID, difficulty: difficulty) < target {
                return false
            }
        }
        return true
    }
}
