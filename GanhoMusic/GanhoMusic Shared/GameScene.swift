//
//  GameScene.swift
//  GanhoMusic Shared
//
//  45초 인게임 루프와 SpriteKit 시스템 연결을 담당한다.
//  GameScene+Setup.swift 등 extension 파일이 세부 책임을 분리해 보유한다.
//

import SpriteKit

/// 45초 인게임 루프를 담당하는 SpriteKit 메인 씬.
/// worldNode는 게임 오브젝트, cameraNode는 HUD와 입력 UI를 화면에 고정 표시한다.
class GameScene: SKScene {

    // MARK: - Properties
    // Phase 3 종결 후 리팩터 — GameScene+Setup.swift extension 접근 위해 private 해제 (필수 연동 변경).
    var gameState: GameState = .waiting
    var lastUpdateTime: TimeInterval = 0
    let hud = HUDNode()                                         // Phase 2-4 — cameraNode 자식
    var remainingTime: TimeInterval = GameplayTuning.gameDuration   // Phase 2-4 — 45초 카운트다운

    // 노드 트리
    let worldNode  = SKNode()
    let mapNode    = MapNode()       // Sprint 10 Phase B — worldNode 자식, 원본 1:1 좌표 그릇(zPos -50)
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

    // R2 — 게임필 director/controller 3종. 전부 씬 인스턴스 소유 (static 금지 — R1 패턴 동일).
    // 배선(worldNode/physicsWorld/cameraNode 주입)은 GameScene+Setup.setupDirectors가 didMove 1회 수행.
    let hitstop = HitstopController()         // 히트스톱 — speed/isPaused + 파이프라인 스킵 (02 §2)
    let cameraDirector = CameraDirector()     // 카메라 v2 — 보간 추적/셰이크/줌/킥 (02 §3)
    let effectDirector = EffectDirector()     // 파티클 6종 — 풀링/캡 8/우선순위 (02 §4)
    let walkDustPool = ObjectPool<WalkDustNode> { WalkDustNode() }   // 걷기 먼지 (02 §5 — 비이미터)

    // R1 — 엔진 코어. registry는 동적 엔티티 3종의 카운트/순회 캐시, 풀 4종은 생성/파괴 반복 평탄화.
    // 전부 씬 인스턴스 소유 — static 금지(씬 해제와 함께 소멸, stale scene 참조 차단).
    // 배선(예열·provider 주입)은 GameScene+Setup.setupEntityPools가 didMove에서 1회 수행.
    let registry = EntityRegistry()
    let notePool = ObjectPool<NoteNode> { NoteNode() }
    let projectilePool = ObjectPool<FProjectileNode> { FProjectileNode() }
    let stethoscopePool = ObjectPool<StethoscopeNode> { StethoscopeNode() }
    let scorePopupPool = ObjectPool<ScorePopupNode> { ScorePopupNode() }

    #if DEBUG
    /// R1 — DEBUG 전용 프레임/노드 진단 라벨. FrameStats.isEnabled=false면 nil 유지. 릴리즈 미포함.
    var frameStats: FrameStats?
    #endif
    let skillButton = SkillButtonNode()   // Phase 9-5 — 우하단 1탭 발동 버튼
    let runButton = RunButtonNode()       // Sprint 11 — 쿨타임 없는 hold-to-run 버튼
    let hudSkillSlot = HUDSkillSlotNode() // Phase 9-5 — 스킬 쿨다운 진행 시각화
    let pauseButton = PauseButtonNode()   // Sprint 3 — 우상단 일시정지 시각 placeholder
    /// R8 — 일시정지 v3 다이얼로그 (구 pauseOverlay/PrimaryButtonNode 2개 대체). nil = 비표시.
    var pauseDialog: PixelDialogNode?
    var pauseStoredDPadInteractionEnabled: Bool = true
    var pauseStoredSkillInteractionEnabled: Bool = true
    var pauseStoredRunInteractionEnabled: Bool = true
    var smoothedMoveDirection: CGVector = .zero
    let highScoreRepo = HighScoreRepository()   // Phase 3-4 — 최고 점수 영구 저장소
    let statsRepo = StatisticsRepository()      // Phase 3-5 — 누적 통계 영구 저장소
    // Phase 7-4 — 캐릭터 × 난이도 매트릭스 / 최초 졸업 일시 저장소. HighScoreRepository와 *병행*.
    // 단일 점수 사용처(ResultScene bestLabel)는 무영향 — 본 두 저장소는 졸업 판정 전용.
    let accountScope: AccountProgressScope
    let perDiffRepo: PerDifficultyScoreRepository
    let graduationRepo: GraduationRepository
    // R6 §F2/F9 — 메타 영속 계층 (perDiffRepo와 동일 스코프). endGame 1회만 기록 — update 경로 I/O 0.
    let metaRepo: MetaProgressRepository
    let haptics = HapticsManager()              // Phase 6-1 / R2 — CoreHaptics v2 + UIImpact 폴백
    let synth   = ChiptuneSynth.shared          // R2 — 칩튠 SFX 신스 (구 AudioManager 시스템 사운드 전폐)
    let bgm     = BGMPlayer()                   // Phase 6-4 — 자작 BGM 무한 루프 (음원 부재 시 noop)
    // Phase 4-3 — AIRFORCE 이스터에그 1회 한정 가드. true가 되면 재발동 안 함.
    // 새 GameScene 인스턴스에서 자동 false로 리셋됨.
    var airforceTriggered: Bool = false

    // Phase 6-10 — 한 판 내 이미 발화된 콤보 마일스톤 추적. 멱등성 보장.
    // GameScene 인스턴스는 한 판 = 1개 → 새 게임 시작 시 빈 Set로 자동 리셋.
    // Spring 비유: idempotency-key — 같은 마일스톤 key는 한 트랜잭션 내 1회만 처리.
    var triggeredComboMilestones: Set<Int> = []

    // Phase 6-12 — 콤보 끊김 발화 추적. 같은 콤보 값 끊김은 한 판 1회만 발화 (멱등).
    // 6-11 triggeredComboMilestones와 완전 분리 — 환호와 실망은 독립 가드.
    // lastComboValue: 직전 프레임의 콤보값 추적 — 0으로 떨어진 *순간*을 감지하는 폴링 기준점.
    // 첫 프레임에는 0 시작이라 임계값(10) 가드로 노이즈 차단.
    var lastComboValue: Int = 0   // R8 분할 — +UpdatePipeline 소비 (private→internal)
    var maxComboThisRun: Int = 0
    var triggeredComboBreaks: Set<Int> = []

    /// Phase 6-14 — 긴박감 1회 가드. 같은 판 1회만 setup 발화 (HUD 깜빡임 시작 등).
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
    /// `airforceTriggered` 1회 가드 패턴 답습 — 단순/안전/회귀 0.
    var tensionStarted: Bool = false

    /// R7 §F2 — near-miss "아슬!" 팝업·햅틱 쿨다운(0.25s) 기준 시각. 콤보 연장은 쿨다운 비대상.
    /// 새 GameScene 인스턴스에서 자동 0 리셋 — sentinel 0 < 첫 lastUpdateTime이라 첫 이벤트 통과.
    var lastNearMissFeedbackAt: TimeInterval = 0

    /// Sprint 10 Phase J — 5초 긴박감 화면 가장자리 비네트. tensionStarted true 진입 시 attach,
    /// endGame/stopTensionBlink 경로에서 detach. nil 상태로 시작 → 재시작 안전.
    /// cameraNode 자식 부착해 카메라 follow와 무관하게 화면 고정.
    var tensionVignette: TensionVignetteNode?

    /// Sprint 8 Phase G — 박병장 hard 난이도 데뷔 1회 발화 플래그.
    /// false → 트리거 조건(30s OR 50점) 만족 시 spawnSergeantPark + 컷씬 발화 + true 토글.
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
    var sergeantParkDebuted: Bool = false

    /// 점수 절반(A) 마일스톤 1회 발화 가드. triggeredComboMilestones(콤보 전용)와 완전 분리 —
    /// 기준(점수 vs 콤보)·의미가 달라 신규 Bool을 둔다(혼용 금지).
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전) — sergeantParkDebuted 패턴 답습.
    var halfScoreMilestoneShown: Bool = false
    /// 목표-10점(B) 마일스톤 1회 발화 가드. 새 GameScene 인스턴스에서 자동 false 리셋.
    var nearTargetMilestoneShown: Bool = false

    /// Sprint 10 Phase H — 한 판 내 발화된 컷씬 ID Set (원본 game.js `state.cutscenesShown`와 byte-equal).
    /// 5종 컷씬 모두 *매 판 1회* 발화 정책 — UserDefaults 영구 스킵 X. 새 GameScene 인스턴스에서 자동 비어 시작.
    /// 사용처: mid1/mid2 update 폴링 1회 가드. Set.contains O(1) — 매 프레임 호출 안전.
    /// 키: "intro" / "mid1" / "mid2" / "introStoneGuard" / "introProfessor".
    var cutscenesShown: Set<String> = []
    /// Phase 6-14 — 직전 프레임의 정수초(ceil). 매초 변화 *순간* 감지용.
    /// -1 초기값 — 첫 프레임 비교가 자연스럽게 첫 변화로 처리됨.
    /// HUD timeLabel이 보여주는 `Int(ceil(remainingTime))`과 정확히 같은 식으로 계산 → *눈에 보이는 숫자가 바뀐 순간* 햅틱 발화.
    var lastRemainingTimeSecond: Int = -1   // R8 분할 — +UpdatePipeline 소비 (private→internal)

    /// R1 — tension BGM rate 직전 전송값(양자화 가드). nil = 미전송 → 윈도우 첫 진입 시 무조건 전송.
    /// 보간값이 매 프레임 연속이라 FeelTuning.tensionRateQuantizeStep 단위로 반올림 양자화 후
    /// 직전 전송값과 다를 때만 setRate — 1.0→1.15 단조 증가·최종 1.15 도달 시맨틱 보존.
    var lastSentTensionRate: Float?   // R8 분할 — +UpdatePipeline 소비 (private→internal)

    /// Phase 5-2 — TitleScene이 init으로 주입한 선택 캐릭터.
    /// PlayerNode 색 등 캐릭터별 시각/로직 적용에 사용. 한 판 안에서 불변(`let`).
    let characterID: CharacterID
    /// Phase 7-1 — TitleScene이 init으로 주입한 선택 난이도.
    /// 노드/시스템 apply(_:) 호출에 사용. 한 판 안에서 불변(`let`).
    /// macOS/tvOS GameViewController 호출은 default 인자(`.easy`)로 자동 호환 → 회귀 0.
    let difficulty: Difficulty
    /// R6 §F7 — 이번 판 일일 모디파이어. nil = 일반 판 (기존 동작 byte-동일). 한 판 안에서 불변(`let`).
    /// factory 기본 인자가 DailyChallengeSession에서 해석 — 명시 주입 가능 형태 유지 (테스트·부팅 분기).
    let dailyModifier: DailyModifier?

    /// R6 §F1/F7 — 이번 판 실효 목표의 *단일 공급점*. 음표 러시면 ×1.3 ceil, 아니면 라이브 목표.
    /// 마일스톤 배너·졸업 판정·RunSummary·ResultScene verdict가 전부 이 값 경유 (모순 0 계약).
    var effectiveTargetScore: Int {
        let base = GameplayTuning.targetScoreByDifficulty[difficulty]
            ?? GameplayTuning.targetScoreByDifficultyFallback
        guard dailyModifier == .noteRush else { return base }
        return Int((Double(base) * MetaTuning.noteRushTargetMultiplier).rounded(.up))
    }

    // MARK: - Init
    /// Phase 7-1 — characterID + difficulty 주입형 init. newGameScene factory가 호출.
    /// Swift 규칙: stored property(`self.characterID`/`self.difficulty`) 초기화 → 그 다음 `super.init`.
    init(size: CGSize, characterID: CharacterID, difficulty: Difficulty,
         dailyModifier: DailyModifier? = nil) {
        self.characterID = characterID
        self.difficulty = difficulty
        self.dailyModifier = dailyModifier
        let scope = AccountProgressScopeProvider.current(
            authProfile: AuthProfileRepository().current
        )
        self.accountScope = scope
        self.perDiffRepo = PerDifficultyScoreRepository.scoped(scope: scope)
        self.graduationRepo = GraduationRepository.scoped(scope: scope)
        self.metaRepo = MetaProgressRepository.scoped(scope: scope)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Factory
    /// Phase 7-1 — characterID + difficulty 둘 다 default 인자. TitleScene만 두 인자 모두 명시 → 회귀 0.
    /// R6 — dailyModifier 기본 인자 = DailyChallengeSession 경유 (armed 상태·dayKey 검증 자동).
    /// macOS/tvOS의 무인자 newGameScene() 호출도 기본 인자로 그대로 호환 (SPEC §주의사항 6).
    /// 재도전(retry)도 같은 factory 경유라 armed 상태가 자연 유지 — 자정 경과 시 자동 해제.
    class func newGameScene(characterID: CharacterID = .kim,
                            difficulty: Difficulty = .easy,
                            dailyModifier: DailyModifier? = DailyChallengeSession.shared.activeModifier()) -> GameScene {
        let scene = GameScene(size: CGSize(width: 1024, height: 768), characterID: characterID,
                              difficulty: difficulty, dailyModifier: dailyModifier)
        scene.scaleMode = .resizeFill   // Phase 1-3 핫픽스: scene size를 view 크기에 자동 맞춤 — D-Pad가 viewport 안에 들어오게 함
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        setupBackground()    // 1-2 그대로 (.ganhoBgDeep)
        setupWorld()         // worldNode + 외곽 벽 4개 (2-1) + 중앙 기둥 (2-2)
        setupEntityPools()   // R1 — 풀 예열(12/16/6/8) + SpawnSystem 풀·레지스트리 배선 (didMove 1회)
        setupPlayer()        // PlayerNode를 worldNode 자식으로
        setupCamera()        // cameraNode (1-2 그대로)
        setupDirectors()     // R2 — hitstop/cameraDirector/effectDirector 배선 + 먼지 풀 예열
        setupDPad()          // 1-3 신설 — DPadNode를 cameraNode 자식으로
        setupHUD()           // Phase 2-4 신설 — HUDNode를 cameraNode 좌상단에
        setupEnemy()         // Phase 2-6 신설 — EnemyNode를 worldNode 자식으로
        setupStoneGuard()    // Phase 4-1 신설 — StoneGuardNode를 worldNode 자식으로 (4 waypoint 시계방향)
        setupProfessor()     // Phase 9-7 신설 — ProfessorNode를 worldNode 자식으로 (hard만, 가드 내부)
        setupSkillButton()   // Phase 9-5 — SkillButtonNode를 cameraNode 우하단에
        setupRunButton()     // Sprint 11 — SkillButton 왼쪽 hold-to-run 버튼
        setupHUDSkillSlot()  // Phase 9-5 — HUDSkillSlotNode를 SkillButton 위에
        setupPauseButton()   // Sprint 3 — PauseButtonNode를 cameraNode 우상단에 (시각 placeholder)
        setupDailyModifier() // R6 §F7 — 모디파이어 배선 (속도/쿨다운/배율/비네트/HUD 표식). nil이면 noop
        #if DEBUG
        setupFrameStats()    // R1 — DEBUG 전용 진단 라벨 (릴리즈 빌드 코드·노드 0)
        #endif
        skillSystem.configure(scene: self, skill: characterID.skill)  // Phase 9-5 — 활성 스킬 set
        physicsWorld.gravity = .zero   // Phase 2-2 — 탑다운 게임이라 중력 없음
        configureContactRouter()                       // Phase 2-11 — 콜백 4개 등록
        physicsWorld.contactDelegate = contactRouter   // Phase 2-11 — 분기는 ContactRouter가 담당

        resetCutsceneStateAndShowIntro()
    }

    // MARK: - Game Loop (R1 — 명시 파이프라인 / R2 — 히트스톱·카메라 v2·자석)
    /// 02_GAME_FEEL §1 파이프라인 고정:
    /// **input → player(+자석) → AI → projectiles → collisions(콜백) → effects → camera → HUD → registry.compact()**
    /// 기존 폴링(콤보 만료/스킬/배너/tension/끊김)은 의미가 보존되는 단계에 배속 —
    /// 동일 프레임 내 상대 순서 불변 조건(tickComboExpiry → 끊김 폴링, 카메라는 player 이후,
    /// HUD는 점수/시간 확정 이후, compact 항상 마지막)을 지킨다.
    /// R2 — 히트스톱 tick은 상태 가드 *이전*(프레임 준비 구역): 게임오버 히트스톱(상태가 이미
    /// .gameOver)도 램프가 진행돼야 한다. 동결 중에는 파이프라인 전체 스킵(remainingTime 포함 동결).
    override func update(_ currentTime: TimeInterval) {
        // ── 프레임 준비 (파이프라인 진입 전 공통 가드 — 시맨틱 변경 금지 구역) ──
        // 첫 프레임 처리
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // R2 — 히트스톱 tick (상태 가드 이전). true = 동결 중 → 이번 프레임 전체 스킵.
        if hitstop.tick(dt: dt) { return }

        // R2 — 게임오버 연출 구간(지연 전환 0.9s): 셰이크/킥/deathBurst가 보이도록
        // 카메라만 계속 갱신. 게임플레이 파이프라인은 진행하지 않는다.
        if gameState == .gameOver {
            cameraDirector.update(dt: dt)
            return
        }

        // 상태 가드 — playing이 아니면 입력/이동/카메라 모두 정지
        guard gameState == .playing else { return }

        // Phase 2-4 — 45초 카운트다운. 0 도달 시 즉시 종료(early return)으로
        // 이번 프레임의 player/카메라/HUD 갱신은 건너뛴다.
        remainingTime = max(0, remainingTime - dt)
        if remainingTime <= 0 {
            endGame()
            return
        }

        if triggerMidCutsceneIfNeeded() {
            return
        }

        // ── input: 콤보 윈도우/스킬 상태 확정 → D-Pad 입력 위임 ──
        updateInputPhase(dt: dt, currentTime: currentTime)

        // ── player: dt 보간 이동 + wall-slide + 걷기 프레임 + 수집 자석(말미) ──
        updatePlayerPhase(dt: dt)

        // ── AI: 수간호사 상태 머신 / 석조무사·이교수 패트롤 시각 / 박병장 데뷔 폴링 ──
        updateAIPhase(dt: dt)

        // ── projectiles: F/청진기는 physicsBody.velocity 구동 — SpriteKit physics가
        //    시뮬레이션 단계에서 자동 적분. R7 §F2 — near-miss 보너스 폴링만 본 슬롯 배속
        //    (콤보 타이머 = 게임 수치 변경이라 effects 단계 "무변경" 계약상 금지 — SPEC 주의 2). ──
        updateNearMissBonusPhase()

        // ── collisions: SpriteKit physics 콜백(ContactRouter.didBegin)이 본 update 밖에서
        //    담당 — 점수/회수는 GameScene+Contact 콜백으로 발화 (명시적 빈 슬롯). ──

        // ── effects: 배너/긴박감/위험 경고/콤보 오라 — 게임 수치를 바꾸지 않는 시각·청각 레이어 ──
        updateEffectsPhase()

        // ── camera: player 갱신 이후 — CameraDirector 단일 기록(보간→클램프→셰이크/킥 합성) ──
        updateCameraFollow(dt: dt)

        // ── HUD: 점수/시간 확정 이후 표시 + 콤보 끊김 폴링 ──
        updateHUDPhase()

        // ── registry.compact(): 항상 마지막 — 부모 잃은 참조 안전망 청소 (프레임당 1회) ──
        registry.compact()

        #if DEBUG
        frameStats?.tick(currentTime: currentTime)
        #endif
    }
    // R8 §B③ — 파이프라인 단계·Tension 폴링·마일스톤 배너는 +UpdatePipeline.swift로 분리.
}
