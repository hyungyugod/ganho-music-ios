//
//  PlayerNode.swift
//  GanhoMusic Shared
//
//  Phase 1-3 · 김간호 정식 캐릭터 노드
//  Phase 2-2 · SKPhysicsBody 첫 도입 + velocity 기반 이동 (1-4 자체 클램프 제거)
//  Phase 5-3 · 캐릭터별 이동속도 차등 (speedMultiplier 주입)
//  Phase 5-R · CharacterID 단일 진입점 메서드 apply(_:) 추출 (순수 리팩터)
//  Phase 7-1 · 난이도별 기준 속도 차등 (baseSpeedStart/End 인스턴스 프로퍼티 + apply(_:Difficulty))
//  Phase 8-1 · 단색 SKSpriteNode → 픽셀 텍스처 모드. PixelSprite + PixelPalette + PixelSpriteRenderer 사용.
//             4방향 + 걷기 애니메이션을 PlayerNode가 *자기 update*에서 수동 처리.
//

import SpriteKit

/// 김간호 캐릭터. 외부(GameScene)가 매 프레임 currentDirection을 갱신해주면,
/// update(deltaTime:)에서 PhysicsBody의 velocity로 이동 의도를 전달한다.
/// Phase 2-2 — SKPhysicsBody 부착 (1-1에서 정의된 PhysicsCategory가 드디어 활성화).
/// Phase 8-1 — texture 모드 전환. physicsBody 크기는 *그대로* 16×20 — 게임 hitbox 회귀 0.
///             시각만 32×40pt로 확대(pixelSpriteScale=2) — 카메라 follow / 충돌 / 맵 경계 영향 0.
final class PlayerNode: SKSpriteNode {

    // MARK: - Properties
    /// 현재 이동 방향 (단위 벡터). 외부에서 set, 내부에서 read.
    /// .zero이면 정지.
    var currentDirection: CGVector = .zero

    /// Phase 5-3 — 외부(GameScene)가 setupPlayer에서 주입하는 속도 배율.
    /// 기본 1.0이라 *주입 전*에도 안전(.kim과 동일 속도). update(deltaTime:)에서 곱셈으로 적용.
    var speedMultiplier: CGFloat = 1.0

    /// Phase 7-1 — 난이도별 시작 속도 (pt/s). default = GameConfig.playerBaseSpeed → apply 누락 시 graceful fallback(easy 동작).
    /// update(deltaTime:)에서 speedMultiplier와 곱해져 최종 속도 산출.
    var baseSpeedStart: CGFloat = GameConfig.playerBaseSpeed
    /// Phase 7-1 — 난이도별 끝 속도 (pt/s). 본 sprint는 *시작값만* 적용 — 미리 저장만(주의사항 7).
    /// 다음 보강 sprint에서 진행률 보간식 도입 시 사용.
    var baseSpeedEnd: CGFloat = GameConfig.playerBaseSpeed

    /// Phase 9-5 — 무적 플래그. true면 ContactRouter 콜백(enemy/projectile) 본문에서 즉시 return.
    /// 정간호 돌진(0.26초)·이간호 텔레포트(0.5초)에서만 set/clear.
    /// 외부(SkillSystem)가 SKAction.run 클로저에서 true ↔ false 토글 — `[weak self]` 캡처 필수(주의사항 5).
    var isInvulnerable: Bool = false

    /// Phase 9-7 — 동결 플래그. 청진기 피격 시 2초간 true → update 최상단 가드로 이동 정지.
    /// 무적(isInvulnerable) 우선 정책: 무적 중 freeze 호출은 noop.
    /// 재호출 noop: 이미 frozen이면 2초 *고정* — 누적 안 함 (연사 무한 정지 방지).
    /// 외부 setter 차단 — set은 freeze(duration:) 메서드만 통과.
    private(set) var isFrozen: Bool = false

    // MARK: - Pixel Sprite State (Phase 8-1)
    /// 현재 픽셀 텍스처가 표현하는 방향. velocity 부호 변화 시 갱신 후 refreshTexture 호출.
    /// 정지(.zero) 시 마지막 방향 유지 — 갑작스러운 down 복귀 없음(자연 톤).
    private var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    private var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). GameConfig.pixelWalkFrameInterval 도달 시 토글 + 0 리셋.
    private var frameAccumulator: TimeInterval = 0
    /// 현재 픽셀 텍스처가 표현하는 캐릭터. apply(_ characterID:) 호출 시 갱신.
    /// init 직후 .kim — apply 호출 전에도 그래픽이 깨지지 않도록 graceful default.
    private var currentCharacterID: CharacterID = .kim

    // MARK: - Properties — Facing (Sprint 7 Phase G / Sprint 8 Phase G 풀바디 교체)
    /// 4방향 CharacterFaceNode child 캐시. apply(_:) 호출 시 일괄 재생성.
    /// Sprint 8 Phase G — 신규 캐릭터 적용 시 정리만 하고, *재부착 안 함*(fullBody로 교체).
    /// dict lookup으로 facing(_:) noop 가드(.zero 시 미발화)와 즉시 토글 비용 0.
    private var faceNodes: [Direction: CharacterFaceNode] = [:]
    /// 직전 facing 방향. facing(_:)이 같은 값이면 noop — 매 프레임 호출에도 비용 0.
    /// 초기값 .front — 정지 상태에서 정면 보는 자연 톤(D-Pad 미입력 시).
    private var lastFacing: Direction = .front
    /// Sprint 8 Phase G — 인게임 풀바디 child. apply(_:)에서 부착, facing(_:)에서 위임.
    /// CharacterFaceNode 4-child 패턴 대체 — *팔다리 보이는 캐릭터* 정체성.
    private var fullBody: CharacterFullBodyNode?

    // MARK: - Init
    init() {
        // Phase 8-1 — physicsBody 크기는 원래대로 16×20 (게임 로직 회귀 0).
        // 시각 크기는 pixelSpriteScale(2)배 — 32×40pt 화면 픽셀.
        let physicsSize = CGSize(
            width:  GameConfig.playerWidth,
            height: GameConfig.playerHeight
        )
        let visualSize = CGSize(
            width:  GameConfig.playerWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.playerHeight * GameConfig.pixelSpriteScale
        )
        // 초기 텍스처는 .kim의 down/idle. apply(_ characterID:)로 캐릭터 확정 시 갱신.
        // Sprint 4 (PNG migration partial) — Self.loadTexture가 PNG 우선·픽셀 fallback 처리.
        let initialTexture = Self.loadTexture(
            for: .kim, direction: .down, frame: .idle
        )
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "player"

        // Phase 2-2 — PhysicsBody 부착 (dynamic, velocity 통제, 회전/마찰/탄성/감쇠 모두 0)
        // Phase 8-1 — body 크기는 *시각 크기와 무관하게* physicsSize 사용 → 기존 hitbox 보존.
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.player
        body.collisionBitMask    = PhysicsCategory.wall
        body.contactTestBitMask  = PhysicsCategory.note
                                 | PhysicsCategory.enemy
                                 | PhysicsCategory.projectile
                                 | PhysicsCategory.bonus   // Phase 2-3 + 2-6 + 2-7 + 9-6 변기 보너스
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Apply
    /// Phase 5-R — 캐릭터 정체성 단일 진입점.
    /// 외부(GameScene+Setup)는 setter를 직접 알지 않고 CharacterID 하나만 넘긴다.
    /// Phase 8-1 — color 단색 setter 폐기. 대신 currentCharacterID 갱신 + refreshTexture 호출.
    /// 기존 speedMultiplier 적용은 유지 — 캐릭터별 차등 속도(5-3) 그대로.
    func apply(_ characterID: CharacterID) {
        currentCharacterID = characterID
        speedMultiplier = characterID.playerSpeedMultiplier
        refreshTexture()
        // Sprint 8 Phase G — buildFacingChildren(face 4-child)을 CharacterFullBodyNode 부착으로 교체.
        // PixelSprite texture/physicsBody/이동 로직 0건 변경 — 시각만.
        attachFullBody(for: characterID)
    }

    /// Phase 7-1 — 난이도 정체성 단일 진입점.
    /// dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    /// `apply(_ characterID:)`와 *서로 다른 프로퍼티*를 set하므로 호출 순서 무관 (주의사항 1).
    /// 일관성을 위해 GameScene+Setup에서 character 먼저 → difficulty 나중 순서로 호출.
    func apply(_ difficulty: Difficulty) {
        baseSpeedStart = GameConfig.playerSpeedStartByDifficulty[difficulty] ?? GameConfig.playerBaseSpeed
        baseSpeedEnd   = GameConfig.playerSpeedEndByDifficulty[difficulty]   ?? GameConfig.playerBaseSpeed
    }

    // MARK: - Facing (Sprint 7 Phase G / Sprint 8 Phase G 풀바디 교체)
    /// D-Pad 입력 방향 → 시각 child 토글. isHidden만 다루므로 다음 SK 프레임(~16ms) 안 전환.
    /// lastFacing 가드 — 같은 방향 재호출 시 noop(매 프레임 호출에도 비용 0).
    /// 게임 로직(velocity·position·hitbox·skill) 0건 변경 — 순수 시각 layer.
    /// Sprint 8 Phase G — fullBody?.facing(_:)으로 위임 (CharacterFaceNode 4-child 폐기).
    func facing(_ direction: Direction) {
        if direction == lastFacing { return }
        lastFacing = direction
        fullBody?.facing(direction)
    }

    /// Sprint 8 Phase G — apply(_ characterID:)에서 1회 호출.
    /// 기존 face child 4개 정리(누수 0) + 새 CharacterFullBodyNode 부착.
    /// fullBody는 *PlayerNode visual(32×40)에 맞춰* playerFullBodyScaleV4(0.35) 축소.
    /// zPosition은 playerFaceChildZPosition(1) — PixelSprite texture(zPos 0) 위 자연 오버레이.
    /// PixelSprite 본체 시각은 *그대로 노출* — 풀바디 위에 겹쳐 보이지만 풀바디가 더 크고 명확.
    /// 추후 보강 sprint에서 PixelSprite 본체도 차단(빌런 3종 패턴) 후보.
    private func attachFullBody(for characterID: CharacterID) {
        // Sprint 7 Phase G face child 4개 정리 — 누수 0 + 시각 중첩 0.
        for (_, node) in faceNodes { node.removeFromParent() }
        faceNodes.removeAll()

        // 기존 fullBody 정리 — 캐릭터 전환 시 누적 방지.
        fullBody?.removeFromParent()

        let body = CharacterFullBodyNode(id: characterID)
        body.name = "fullBody"
        body.setScale(GameConfig.playerFullBodyScaleV9)
        body.zPosition = GameConfig.playerFaceChildZPosition
        // 초기 facing 노출 일치 — apply 직후 lastFacing이 .front라면 .front 노출 이미 set됨.
        body.facing(lastFacing)
        addChild(body)
        self.fullBody = body

        // Sprint 9 Phase B — PixelSprite 본체 시각 차단 (Enemy 패턴 답습).
        // refreshTexture()/physicsBody/이동 0줄 영향 — color 합성만으로 투명화.
        self.color = .clear
        self.colorBlendFactor = 1.0
    }

    // MARK: - Update (Movement)
    /// 외부에서 매 프레임 호출. PhysicsBody의 velocity로 이동 의도 전달.
    /// (Phase 2-2 — 1-3/1-4의 position 직접 변경 + 자체 클램프 패턴은 폐기.
    ///  물리 엔진이 매 프레임 자동으로 위치 갱신 + 충돌 처리.)
    /// - Parameter deltaTime: dt — 본 메서드는 미사용 (velocity 기반이라 엔진이 dt 처리).
    ///   시그니처는 외부 호출부 호환 위해 보존.
    func update(deltaTime: TimeInterval) {
        // Phase 9-7 — 동결 가드. 청진기 피격 시 2초간 isFrozen=true → velocity 0으로 강제 정지 후 early return.
        // 함수 *최상단* 가드 — 기존 로직 전혀 도달하지 않도록 보장(주의사항 10).
        // 무적(isInvulnerable)과 독립 — 무적은 ContactRouter 콜백에서 freeze 호출 자체를 차단.
        if isFrozen {
            physicsBody?.velocity = .zero
            return
        }
        // Phase 7-1 — baseSpeedStart × speedMultiplier. easy default가 playerBaseSpeed(140)와 같아 회귀 0.
        // 본 sprint는 *시작값만* — baseSpeedEnd는 다음 보강 sprint(주의사항 7).
        let speed = baseSpeedStart * speedMultiplier
        physicsBody?.velocity = CGVector(
            dx: currentDirection.dx * speed,
            dy: currentDirection.dy * speed
        )
    }

    // MARK: - Freeze (Phase 9-7)
    /// 청진기 피격 시 외부(ContactRouter 콜백)에서 호출. duration초간 이동 입력 차단.
    /// 정책:
    /// 1) 이미 frozen이면 noop — 2초 *고정*, 누적 안 함 (연사 무한 정지 방지).
    /// 2) 무적(isInvulnerable) 우선 — 무적 중 호출 noop. 이간호 텔레포트와 일관.
    /// 3) 시각: alpha 1.0 ↔ frozenBlinkMinAlpha(0.4) 반복 깜빡임.
    /// 4) duration 종료 시 SKAction.run 콜백으로 isFrozen=false + alpha 1.0 복원 + velocity 0.
    /// 5) withKey: playerFreezeActionKey → 같은 키 재호출 시 SpriteKit 자동 액션 교체 (이중 안전망).
    /// [weak self] 캡처 — 동결 진행 중 씬 전환 가능성 대비.
    func freeze(duration: TimeInterval) {
        if isFrozen { return }
        if isInvulnerable { return }
        isFrozen = true

        let half = GameConfig.frozenBlinkHalfPeriod
        let fadeOut = SKAction.fadeAlpha(to: GameConfig.frozenBlinkMinAlpha, duration: half)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: half)
        let cycle = SKAction.sequence([fadeOut, fadeIn])
        // duration / (half * 2) 사이클 수 계산. max(1, ...) — duration < halfPeriod*2 극단 케이스에도 1회 깜빡임 보장.
        let cycleCount = max(1, Int(duration / (half * 2)))
        let blink = SKAction.repeat(cycle, count: cycleCount)
        let restore = SKAction.run { [weak self] in
            self?.isFrozen = false
            self?.alpha = 1.0
            self?.physicsBody?.velocity = .zero
        }
        run(.sequence([blink, restore]), withKey: GameConfig.playerFreezeActionKey)
    }

    // MARK: - Update (Pixel Animation, Phase 8-1)
    /// GameScene.update가 매 프레임 호출. PlayerNode가 자기 텍스처를 갱신.
    /// velocity dx/dy 부호 + 절대값 비교로 4방향 산출. 정지 시 마지막 방향 유지.
    /// 텍스처 재생성은 *방향이 실제로 바뀐 프레임에만* — 매 프레임 호출이라도 정지 시 비용 0.
    func updatePixelDirection(_ velocity: CGVector) {
        let absDx = abs(velocity.dx)
        let absDy = abs(velocity.dy)
        // 거의 정지(임계값 0.1 미만) — 방향 유지(텍스처 재생성 없음).
        // physics 엔진의 미세 잔존 velocity가 *흔들림*으로 보이지 않도록 임계값 가드.
        guard absDx > 0.1 || absDy > 0.1 else { return }
        let newDir: PixelDirection
        if absDx > absDy {
            newDir = velocity.dx >= 0 ? .right : .left
        } else {
            // SpriteKit 좌표계: +y는 위쪽 → dy > 0이면 up.
            newDir = velocity.dy >= 0 ? .up : .down
        }
        if newDir != pixelDirection {
            pixelDirection = newDir
            refreshTexture()
        }
    }

    /// GameScene.update가 매 프레임 호출. 걷는 중일 때 step1↔step2 교차, 정지 시 idle.
    /// 텍스처 재생성은 *변경 순간에만* — 매 프레임 호출이라도 변화 없으면 비용 0.
    /// - Parameter isMoving: 외부에서 판단(velocity != .zero 등). 명시 인자로 받아 책임 분리.
    func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) {
        guard isMoving else {
            // 정지 — idle로 전환 (이미 idle이면 noop, 텍스처 재생성 없음).
            if pixelFrame != .idle {
                pixelFrame = .idle
                frameAccumulator = 0
                refreshTexture()
            }
            return
        }
        // 이동 중 — 누적 시간이 임계 도달 시 step1↔step2 토글.
        frameAccumulator += deltaTime
        if frameAccumulator >= GameConfig.pixelWalkFrameInterval {
            frameAccumulator = 0
            // 처음 idle → step1, 이후 step1 ↔ step2 교차.
            pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
            refreshTexture()
        }
    }

    // MARK: - Texture Refresh
    /// 현재 캐릭터/방향/프레임 조합으로 텍스처를 재생성하고 SKSpriteNode.texture에 set.
    /// SKTexture 이전 값은 ARC로 자동 해제 — 메모리 누수 0.
    /// 호출 빈도: 캐릭터 적용 1회 + 방향 변경 시 + 프레임 변경 시 (0.18초 주기 ↔ idle 진입).
    /// Sprint 4 (PNG migration partial) — Self.loadTexture가 PNG 우선·픽셀 fallback 처리.
    private func refreshTexture() {
        texture = Self.loadTexture(
            for: currentCharacterID,
            direction: pixelDirection,
            frame: pixelFrame
        )
    }

    // MARK: - Texture Loading (Sprint 4 — walk 미적용 버전)
    /// 5명 캐릭터(kim/jung/geon/im/lee) PNG 자산이 있으면 PNG 텍스처 반환,
    /// 없으면 PixelSpriteRenderer로 fallback (EnemyNode·ProfessorNode 등 비대상).
    ///
    /// **walk 미적용 정책**: direction·frame 파라미터를 모두 무시하고 항상 `{char}_down_idle_1.png`
    /// 사용. 캐릭터는 이동 방향과 무관하게 카메라를 바라봄 (브롤스타즈·쿠키런 패턴).
    /// 풀세트 PNG 도착 시 frame/direction 분기 활성화 예정.
    ///
    /// 현재 자산 상태 (2026-05-19):
    /// - kim/jung/geon/im/lee × down × idle → PNG 보유 ✓
    /// - 풀세트 (4방향 × idle+walk = 16프레임 × 5명) 미보유
    private static func loadTexture(
        for char: CharacterID,
        direction: PixelDirection,
        frame: PixelFrame
    ) -> SKTexture {
        // PNG 우선 — 5명 캐릭터 down_idle만 보유, 모든 방향·프레임 요청을 이 PNG로 매핑.
        let pngName = "\(char.rawValue)_down_idle_1"
        if UIImage(named: pngName) != nil {
            let tex = SKTexture(imageNamed: pngName)
            tex.filteringMode = .linear  // 부드러운 스케일링 (픽셀의 .nearest와 대비)
            return tex
        }
        // Fallback — PNG 자산 미보유 캐릭터(현재 시점 없음). 향후 신규 캐릭터 추가 시 graceful 대응.
        return PixelSpriteRenderer.texture(
            from: PixelSprite.data(for: char, direction: direction, frame: frame),
            palette: PixelPalette.palette(for: char)
        )
    }
}
