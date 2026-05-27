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
    var remainingTime: TimeInterval = GameConfig.gameDuration   // Phase 2-4 — 45초 카운트다운

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
    let skillButton = SkillButtonNode()   // Phase 9-5 — 좌하단 1탭 발동 버튼
    let hudSkillSlot = HUDSkillSlotNode() // Phase 9-5 — 스킬 쿨다운 진행 시각화
    let pauseButton = PauseButtonNode()   // Sprint 3 — 우상단 일시정지 시각 placeholder
    var pauseOverlay: SKNode?
    var pauseResumeButton: PrimaryButtonNode?
    var pauseMenuButton: PrimaryButtonNode?
    var pauseStoredDPadInteractionEnabled: Bool = true
    var pauseStoredSkillInteractionEnabled: Bool = true
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
    var airforceTriggered: Bool = false

    // Phase 6-10 — 한 판 내 이미 발화된 콤보 마일스톤 추적. 멱등성 보장.
    // GameScene 인스턴스는 한 판 = 1개 → 새 게임 시작 시 빈 Set로 자동 리셋.
    // Spring 비유: idempotency-key — 같은 마일스톤 key는 한 트랜잭션 내 1회만 처리.
    var triggeredComboMilestones: Set<Int> = []

    // Phase 6-12 — 콤보 끊김 발화 추적. 같은 콤보 값 끊김은 한 판 1회만 발화 (멱등).
    // 6-11 triggeredComboMilestones와 완전 분리 — 환호와 실망은 독립 가드.
    // lastComboValue: 직전 프레임의 콤보값 추적 — 0으로 떨어진 *순간*을 감지하는 폴링 기준점.
    // 첫 프레임에는 0 시작이라 임계값(10) 가드로 노이즈 차단.
    private var lastComboValue: Int = 0
    var triggeredComboBreaks: Set<Int> = []

    /// Phase 6-14 — 5초 긴박감 1회 가드. 같은 판 1회만 setup 발화 (HUD 깜빡임 시작 등).
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
    /// `airforceTriggered` 1회 가드 패턴 답습 — 단순/안전/회귀 0.
    var tensionStarted: Bool = false

    /// Sprint 10 Phase J — 5초 긴박감 화면 가장자리 비네트. tensionStarted true 진입 시 attach,
    /// endGame/stopTensionBlink 경로에서 detach. nil 상태로 시작 → 재시작 안전.
    /// cameraNode 자식 부착해 카메라 follow와 무관하게 화면 고정.
    var tensionVignette: TensionVignetteNode?

    /// Sprint 8 Phase G — 박병장 hard 난이도 데뷔 1회 발화 플래그.
    /// false → 트리거 조건(30s OR 50점) 만족 시 spawnSergeantPark + 컷씬 발화 + true 토글.
    /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
    var sergeantParkDebuted: Bool = false

    /// Sprint 10 Phase H — 한 판 내 발화된 컷씬 ID Set (원본 game.js `state.cutscenesShown`와 byte-equal).
    /// 5종 컷씬 모두 *매 판 1회* 발화 정책 — UserDefaults 영구 스킵 X. 새 GameScene 인스턴스에서 자동 비어 시작.
    /// 사용처: mid1/mid2 update 폴링 1회 가드. Set.contains O(1) — 매 프레임 호출 안전.
    /// 키: "intro" / "mid1" / "mid2" / "introStoneGuard" / "introProfessor".
    var cutscenesShown: Set<String> = []
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

        resetCutsceneStateAndShowIntro()
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

        if triggerMidCutsceneIfNeeded() {
            return
        }

        // Sprint 8 Phase G — 박병장 hard 난이도 데뷔. 30s 또는 50점 중 더 빠른 쪽 1회.
        // 가드: hard 난이도 + 미발화. 트리거 만족 시 즉시 sergeantParkDebuted=true → 재진입 차단.
        // spawnSergeantPark는 컷씬+노드 부착을 GameScene+Setup으로 위임 — update는 조건 분기만.
        if difficulty == .hard && !sergeantParkDebuted {
            let elapsed = GameConfig.gameDuration - remainingTime
            if elapsed >= GameConfig.sergeantParkDebutTimeV4
                || scoreSystem.score >= GameConfig.sergeantParkDebutScoreV4 {
                sergeantParkDebuted = true
                spawnSergeantPark()
            }
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
                // Sprint 10 Phase J — 픽셀 비네트 attach (cameraNode 자식). HUD 깜빡임과 같은 박자 동기.
                let vignette = TensionVignetteNode(sceneSize: size)
                cameraNode.addChild(vignette)
                tensionVignette = vignette
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
        } else if skillSystem.isDashing {
            player.currentDirection = .zero
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

        // 3) 카메라 follow — Sprint 10 Phase B: 맵 가장자리 클램프 적용.
        //    원본 32×20 맵(1280×800pt)으로 좁아져 무클램프 시 화면 밖 검은 빈 공간 노출 위험.
        //    updateCameraFollow가 worldW/H 단일 진실 원천(GameConfig)을 참조 → 맵 크기 변경 시 자동 적응.
        updateCameraFollow()

        // 4) Sprint 10 Phase D — 수간호사 패트롤 + 텔레그래프 상태 머신.
        //    player 추적 폐기 → 4지점 사각 순환. update(dt:) 단일 인자.
        //    player.position / 진행률 / charmActive는 provider 캡처(GameScene+Setup에서 1회 주입).
        //    SpawnSystem.startProjectileFireLoop는 폐기됨 — F 발사는 EnemyNode 내부 상태 머신이 전담.
        enemy.update(deltaTime: dt)

        // Phase 4-1 — 석조무사 SKAction 패트롤의 시각 프레임 갱신.
        if stoneGuard.parent != nil {
            stoneGuard.updatePixelAnimation(deltaTime: dt)
        }

        // Phase 9-7 — 이교수 픽셀 애니메이션 갱신 (hard만). easy/normal에선 professor=nil → optional chain 자연 noop.
        // SKAction.move 기반이라 position 변화량으로 방향/걷기 프레임 산출 (ProfessorNode 내부 자기 처리).
        professor?.updatePixelAnimation(deltaTime: dt)

        // 위험 경고는 밸런스 수치를 바꾸지 않는 시각 레이어다. 생성은 setup/발사 시점,
        // 여기서는 거리 기반 alpha/펄스만 갱신해 노드 churn을 막는다.
        updateDangerWarnings()

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

}
