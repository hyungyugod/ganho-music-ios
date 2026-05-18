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
    let dpad       = DPadNode()      // cameraNode 자식 (화면 고정)

    // 시스템
    let spawnSystem = SpawnSystem()       // Phase 2-10 — spawn 책임 분리
    let contactRouter = ContactRouter()   // Phase 2-11 — 충돌 분기 책임 분리
    let scoreSystem = ScoreSystem()       // Phase 2-12 — 점수 / 콤보 책임 분리
    let highScoreRepo = HighScoreRepository()   // Phase 3-4 — 최고 점수 영구 저장소
    let statsRepo = StatisticsRepository()      // Phase 3-5 — 누적 통계 영구 저장소
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
        gameState = .cutscene
        showIntroCutscene()
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
                // .cutscene → .countdown 전환 + 기존 카운트다운 흐름 그대로 진입.
                // CountdownNode 코드/타이밍 변경 0 — 컷씬은 *앞에 끼어든* 레이어 1단계.
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
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 좌상단 = (-x, +y). D-Pad와 부호만 반전.
    func layoutHUD() {
        let halfW = size.width  / 2
        let halfH = size.height / 2
        hud.position = CGPoint(
            x: -(halfW - GameConfig.hudMarginX),
            y: +(halfH - GameConfig.hudMarginY)
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

        // 1) D-Pad 입력을 PlayerNode로 위임 (DPadNode → PlayerNode 직접 참조 금지 → GameScene 경유)
        player.currentDirection = dpad.currentDirection

        // 2) PlayerNode 자체 dt 보간 이동 (도메인이 자기 갱신)
        player.update(deltaTime: dt)

        // 3) 카메라 follow — Phase 1-5: 드론 follow. player가 늘 화면 정중앙. 클램프 없음 (회피 게임 본질)
        cameraNode.position = player.position

        // 4) Phase 2-6 — 적 직선 추적 (player 위치를 향해 velocity 갱신)
        // Phase 2-8 — 게임 진행률 0 ~ 1 (시작 0, 끝 1). remainingTime은 max(0, ...)으로 음수 방지.
        // speedT는 CGFloat (EnemyNode.update 시그니처 일치) — TimeInterval(Double) → CGFloat 변환.
        let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)
        enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)

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
    }

    // MARK: - Contact Router
    /// ContactRouter의 4개 콜백을 등록. didMove 안에서 1회 호출.
    /// Phase 2-12 — onNoteCollected의 콤보/점수 로직은 ScoreSystem.recordNoteHit으로 위임.
    /// onProjectileHitWall은 self 미사용 — [weak self] 불필요.
    private func configureContactRouter() {
        contactRouter.onEnemyHit = { [weak self] in
            self?.endGame()
        }
        contactRouter.onProjectileHitPlayer = { [weak self] in
            guard let self = self else { return }
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
        airforceTriggered = true
        let plane = AirplaneNode()
        cameraNode.addChild(plane)
        let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
        plane.crossScreen(sceneWidth: size.width, atY: y)
        let overlay = AirforceOverlayNode()
        cameraNode.addChild(overlay)
        overlay.showAndDismiss()
        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)
        enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in
            self?.spawnSystem.fireImmediately()
        }
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
        let resultScene = ResultScene.newResultScene(
            score: score, bestScore: bestScore, isNewBest: isNewBest, stats: stats,
            characterName: characterID.displayName,
            difficulty: difficulty
        )
        view.presentScene(resultScene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }
}
