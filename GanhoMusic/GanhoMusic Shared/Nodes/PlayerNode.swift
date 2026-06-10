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
//  Sprint 10 Phase A · 풀바디(CharacterFullBodyNode SKShapeNode) 자식 제거 → 16×20 PixelSprite 자식 SKSpriteNode 1개로 통일.
//                       시각 단일 진실 원천을 자식으로 일원화. physicsBody/velocity/이동/충돌/스킬 0줄 변경.
//                       5명 × 4방향 = 20 SKTexture 정적 캐시(lazy hit). PNG 우선 경로 제거(원본 1:1 픽셀 회귀).
//

import SpriteKit

/// 김간호 캐릭터. 외부(GameScene)가 매 프레임 currentDirection을 갱신해주면,
/// update(deltaTime:)에서 수동 위치 이동과 벽 슬라이드를 적용한다.
/// Phase 2-2 — SKPhysicsBody 부착 (1-1에서 정의된 PhysicsCategory가 드디어 활성화).
/// Phase 8-1 — texture 모드 전환. physicsBody 크기는 *그대로* 16×20 — 게임 hitbox 회귀 0.
///             시각만 32×40pt로 확대(pixelSpriteScale=2) — 카메라 follow / 충돌 / 맵 경계 영향 0.
/// Sprint 10 Phase A — 시각 단일 진실 원천을 *자식 SKSpriteNode 1개*(pixelSpriteChild)로 통일.
///             본체 self는 투명 placeholder. (구 SVG 풀바디 자식 부착은 폐기 후 R0에서 파일 삭제.)
/// R0 — 방향 산출·보행 상태 머신은 PixelCharacterAnimating 기본 구현 사용 (사본 제거).
final class PlayerNode: SKSpriteNode, PixelCharacterAnimating {

    // MARK: - Properties
    /// 현재 이동 방향 (단위 벡터). 외부에서 set, 내부에서 read.
    /// .zero이면 정지.
    var currentDirection: CGVector = .zero

    /// Phase 5-3 — 외부(GameScene)가 setupPlayer에서 주입하는 속도 배율.
    /// 기본 1.0이라 *주입 전*에도 안전(.kim과 동일 속도). update(deltaTime:)에서 곱셈으로 적용.
    var speedMultiplier: CGFloat = 1.0

    /// RunButtonNode를 누르는 동안만 true. 기본은 걷기 속도다.
    var isRunning: Bool = false

    /// GameScene이 주입하는 벽 충돌 조회 클로저. true면 해당 rect는 점유 불가.
    var wallCollisionProvider: ((CGRect) -> Bool)?
    /// GameScene이 주입하는 벽 rect 조회 클로저. wall-slide overlap score 계산에 사용한다.
    var wallRectProvider: ((CGRect) -> [CGRect])?

    /// 이번 프레임에 실제 적용된 이동 속도. 픽셀 방향/걷기 애니메이션이 읽는다.
    private(set) var movementVelocity: CGVector = .zero

    /// Phase 7-1 — 난이도별 시작 속도 (pt/s). default = GameplayTuning.playerBaseSpeed → apply 누락 시 graceful fallback(easy 동작).
    /// update(deltaTime:)에서 speedMultiplier와 곱해져 최종 속도 산출.
    var baseSpeedStart: CGFloat = GameplayTuning.playerBaseSpeed
    /// Phase 7-1 — 난이도별 끝 속도 (pt/s). 본 sprint는 *시작값만* 적용 — 미리 저장만(주의사항 7).
    /// R2에서 속도 곡선으로 활성화 (그랜드 리팩토링 v3 로드맵 — 삭제 금지).
    var baseSpeedEnd: CGFloat = GameplayTuning.playerBaseSpeed

    /// Phase 9-5 — 무적 플래그. true면 ContactRouter 콜백(enemy/projectile) 본문에서 즉시 return.
    /// 정간호 돌진(0.26초)·이간호 텔레포트(0.5초)에서만 set/clear.
    /// 외부(SkillSystem)가 SKAction.run 클로저에서 true ↔ false 토글 — `[weak self]` 캡처 필수(주의사항 5).
    var isInvulnerable: Bool = false

    /// Phase 9-7 — 동결 플래그. 청진기 피격 시 2초간 true → update 최상단 가드로 이동 정지.
    /// 무적(isInvulnerable) 우선 정책: 무적 중 freeze 호출은 noop.
    /// 재호출 noop: 이미 frozen이면 2초 *고정* — 누적 안 함 (연사 무한 정지 방지).
    /// 외부 setter 차단 — set은 freeze(duration:) 메서드만 통과.
    private(set) var isFrozen: Bool = false

    // MARK: - Pixel Sprite State (Phase 8-1 / R0 — PixelCharacterAnimating 요구)
    /// 현재 픽셀 텍스처가 표현하는 방향. 정지(.zero) 시 마지막 방향 유지 — 갑작스러운 down 복귀 없음.
    var pixelDirection: PixelDirection = .down
    /// 현재 픽셀 텍스처가 표현하는 프레임. 이동 중 step1↔step2 교차, 정지 시 idle.
    var pixelFrame: PixelFrame = .idle
    /// step1↔step2 교차 누적 시간 (초). walkFrameInterval 도달 시 토글 + 0 리셋.
    var frameAccumulator: TimeInterval = 0
    /// 플레이어 전용 보행 주기 0.11 — 적/빌런(0.18)과 분리 (R0 행동 불변).
    var walkFrameInterval: TimeInterval { GameplayTuning.playerWalkFrameInterval }
    /// 정지→이동 첫 프레임 즉시 step1 토글 — Sprint 11 출발 지연 제거 시맨틱 보존.
    var togglesToStepImmediately: Bool { true }
    /// 현재 픽셀 텍스처가 표현하는 캐릭터. apply(_ characterID:) 호출 시 갱신.
    /// init 직후 .kim — apply 호출 전에도 그래픽이 깨지지 않도록 graceful default.
    private var currentCharacterID: CharacterID = .kim

    // MARK: - Properties — Facing (Sprint 7 Phase G / Sprint 10 Phase A 픽셀 일원화)
    /// 직전 facing 방향. facing(_:)이 같은 값이면 noop — 매 프레임 호출에도 비용 0.
    /// 초기값 .front — 정지 상태에서 정면 보는 자연 톤(D-Pad 미입력 시).
    private var lastFacing: Direction = .front

    // MARK: - Pixel Sprite Child (Sprint 10 Phase A)
    /// 인게임 시각 단일 진실 원천. PlayerNode 본체(self)는 투명 placeholder, 이 자식이 실제 픽셀.
    /// apply(_ characterID:)에서 부착, facing/updatePixelDirection에서 texture 교체만.
    private var pixelSpriteChild: SKSpriteNode?

    /// 5 × 4 = 20 SKTexture 정적 캐시(idle 전용). 첫 호출 시 lazy 채움 → 이후 dict lookup O(1).
    /// static — PlayerNode 인스턴스 전환(캐릭터 재선택 후 재시작)에도 1회 워밍 유지.
    /// SKTexture는 GPU 텍스처라 다중 인스턴스 공유 안전.
    /// facing/init/attach가 계속 사용 — Sprint 10 Phase A 이후에도 보존(idle 방향 텍스처 단일 원천).
    private static var textureCache: [CharacterID: [PixelDirection: SKTexture]] = [:]
    /// 걷기 프레임용 3차원 정적 캐시. [캐릭터][방향][프레임(idle/step1/step2)].
    /// 최대 5 × 4 × 3 = 60 텍스처(lazy 실사용분만). 16×20×4byte 기준 ≈ 77KB — 허용 범위.
    /// idle 전용 textureCache와 분리 — frame 파라미터를 받아 step1/step2를 실제로 렌더해야
    /// 인게임에서 다리 교차가 자식 texture에 반영된다(Sprint 10 Phase A 누락 결함 해소).
    private static var walkTextureCache: [CharacterID: [PixelDirection: [PixelFrame: SKTexture]]] = [:]
    private let nearMissWarning = PlayerNearMissWarningNode()

    // MARK: - Init
    init() {
        // Phase 8-1 — physicsBody 크기는 원래대로 16×20 (게임 로직 회귀 0).
        // 시각 크기는 pixelSpriteScale(2)배 — 32×40pt 화면 픽셀.
        let physicsSize = CGSize(
            width:  GameplayTuning.playerWidth,
            height: GameplayTuning.playerHeight
        )
        let visualSize = CGSize(
            width:  GameplayTuning.playerWidth  * GameplayTuning.pixelSpriteScale,
            height: GameplayTuning.playerHeight * GameplayTuning.pixelSpriteScale
        )
        // 초기 텍스처는 .kim의 down/idle. apply(_ characterID:)로 캐릭터 확정 시 갱신.
        // Sprint 10 Phase A — 본체 self.texture는 투명 placeholder 정책상 시각 영향 0이지만
        //                    size 0 방지 위해 .kim down idle 텍스처를 placeholder로 보유.
        let initialTexture = Self.cachedTexture(for: .kim, direction: .down)
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "player"

        // Phase 2-2 — PhysicsBody 부착 (dynamic, velocity 통제, 회전/마찰/탄성/감쇠 모두 0)
        // Phase 8-1 — body 크기는 *시각 크기와 무관하게* physicsSize 사용 → 기존 hitbox 보존.
        // Sprint 10 Phase A — physicsBody 코드 0줄 변경(SPEC §8.12).
        let body = SKPhysicsBody(rectangleOf: physicsSize)
        body.isDynamic           = true
        body.allowsRotation      = false
        body.friction            = 0
        body.restitution         = 0
        body.linearDamping       = 0
        body.categoryBitMask     = PhysicsCategory.player
        body.collisionBitMask    = PhysicsCategory.none
        body.contactTestBitMask  = PhysicsCategory.note
                                 | PhysicsCategory.enemy
                                 | PhysicsCategory.projectile
                                 | PhysicsCategory.bonus   // Phase 2-3 + 2-6 + 2-7 + 9-6 변기 보너스
                                 | PhysicsCategory.aItem   // Sprint 10 Phase D — 수간호사 매혹 분기 시 F→A 수집
        physicsBody = body
        addChild(nearMissWarning)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Apply
    /// Phase 5-R — 캐릭터 정체성 단일 진입점.
    /// 외부(GameScene+Setup)는 setter를 직접 알지 않고 CharacterID 하나만 넘긴다.
    /// Phase 8-1 — color 단색 setter 폐기. 대신 currentCharacterID 갱신 + refreshTexture 호출.
    /// 기존 speedMultiplier 적용은 유지 — 캐릭터별 차등 속도(5-3) 그대로.
    /// Sprint 10 Phase A — attachFullBody(CharacterFullBodyNode) 제거 → attachPixelSpriteChild로 교체.
    ///                     refreshTexture() 호출 자체는 보존(currentCharacterID/pixelDirection state 정합).
    func apply(_ characterID: CharacterID) {
        currentCharacterID = characterID
        speedMultiplier = characterID.playerSpeedMultiplier
        // refreshTexture()는 self.texture를 변경하지만 본체는 투명 placeholder가 됐으므로
        // 호출 자체는 보존 (currentCharacterID/pixelDirection state 갱신 + 본체 texture는 fallback용).
        refreshTexture()
        // Sprint 10 Phase A — attachFullBody → attachPixelSpriteChild로 교체.
        // 자식 SKSpriteNode 1개가 시각 단일 진실 원천(20-텍스처 lazy 캐시).
        attachPixelSpriteChild(for: characterID)
        // 초기 방향: lastFacing이 .front라면 자식 텍스처도 down으로 초기 노출 (이미 attach에서 처리).
    }

    /// Phase 7-1 — 난이도 정체성 단일 진입점.
    /// dict lookup에 fallback 필수 — 강제 언래핑 금지(주의사항 5).
    /// `apply(_ characterID:)`와 *서로 다른 프로퍼티*를 set하므로 호출 순서 무관 (주의사항 1).
    /// 일관성을 위해 GameScene+Setup에서 character 먼저 → difficulty 나중 순서로 호출.
    /// Sprint 10 Phase A — 본 메서드 0줄 변경(SPEC §8.12).
    func apply(_ difficulty: Difficulty) {
        let start = GameplayTuning.playerSpeedStartByDifficulty[difficulty] ?? GameplayTuning.playerBaseSpeed
        let end = GameplayTuning.playerSpeedEndByDifficulty[difficulty] ?? GameplayTuning.playerBaseSpeed
        baseSpeedStart = start * GameplayTuning.playerSpeedRuntimeMultiplier
        baseSpeedEnd = end * GameplayTuning.playerSpeedRuntimeMultiplier
    }

    func updateNearMissWarning(closestProjectileDistance distance: CGFloat?,
                               profile: DangerWarningProfile) {
        nearMissWarning.update(closestProjectileDistance: distance, profile: profile)
    }

    // MARK: - Pixel Sprite Child Attachment (Sprint 10 Phase A)
    /// 인게임 시각 자식 부착. 캐릭터 전환 시 기존 자식 정리 + 신규 자식 부착 + 본체 투명화.
    /// 자식 SKSpriteNode 1개의 texture 프로퍼티만 교체해서 4방향 전환(facing/updatePixelDirection).
    /// 메모리: 자식 노드 1개 + 20-텍스처 static 캐시(첫 사용 시 lazy) = 25.6KB(SPEC OQ-C).
    private func attachPixelSpriteChild(for characterID: CharacterID) {
        // 1. 기존 자식 정리 (캐릭터 전환 시 누적 방지).
        pixelSpriteChild?.removeFromParent()

        // 2. SKSpriteNode 생성. 초기 texture는 .down(.front 대응) idle.
        let initialTexture = Self.cachedTexture(for: characterID, direction: .down)
        let child = SKSpriteNode(texture: initialTexture)
        child.name = "pixelSpriteChild"
        child.zPosition = ZOrder.playerFaceChildZPosition  // 1 — 기존 상수 재사용
        // 시각 크기 = 16×20(텍스처) × pixelSpriteScale(2) = 32×40pt → playerWidth×Height와 정합
        child.size = CGSize(
            width:  GameplayTuning.playerWidth  * GameplayTuning.pixelSpriteScale,
            height: GameplayTuning.playerHeight * GameplayTuning.pixelSpriteScale
        )
        // filteringMode는 PixelSpriteRenderer가 이미 .nearest 세팅 → 별도 코드 불요.
        addChild(child)
        self.pixelSpriteChild = child

        // 3. PlayerNode 본체(self) 투명 placeholder.
        //    color clear + colorBlendFactor 1.0 합성 — 본체 픽셀 색 완전 차단(Sprint 9 Phase B 검증 패턴).
        //    alpha는 1.0 유지 — alpha 0이면 자식까지 같이 사라짐(SpriteKit 표준 전파).
        //    freeze(duration:)의 alpha 깜빡임은 자식까지 자연 전파 → 본체/자식 동시 깜빡임(자연 톤).
        self.alpha = 1.0
        self.colorBlendFactor = 1.0
        self.color = .clear

        // 4. pixelDirection state도 초기 .down으로 정합 — 이후 facing/updatePixelDirection이 동일한 키 lookup.
        pixelDirection = .down
        // pixelFrame은 .idle 그대로(init default). Phase A는 walk 미적용 정책.
    }

    /// 5 × 4 = 20 SKTexture 정적 캐시 헬퍼. 첫 호출 시 lazy 생성 → 이후 dict lookup O(1).
    /// PixelSpriteRenderer는 이미 filteringMode = .nearest 보장 — 픽셀 perfect.
    /// SKTexture는 GPU 텍스처 공유 안전 — 다중 PlayerNode 인스턴스가 같은 텍스처 참조해도 OK.
    private static func cachedTexture(for characterID: CharacterID,
                                       direction: PixelDirection) -> SKTexture {
        if let cached = textureCache[characterID]?[direction] {
            return cached
        }
        let sprite = PixelSprite.data(for: characterID,
                                      direction: direction,
                                      frame: .idle)
        let palette = PixelPalette.palette(for: characterID)
        let texture = PixelSpriteRenderer.texture(from: sprite, palette: palette)
        if textureCache[characterID] == nil {
            textureCache[characterID] = [:]
        }
        textureCache[characterID]?[direction] = texture
        return texture
    }

    /// 걷기 프레임 텍스처 정적 캐시 헬퍼(frame 파라미터 포함). 첫 호출 시 lazy 생성 → 이후 O(1) lookup.
    /// cachedTexture(for:direction:)가 항상 .idle만 렌더하는 것과 달리, step1/step2도 실제로 렌더한다.
    /// PixelSprite.data(for:direction:frame:) → PixelSpriteRenderer 경로는 cachedTexture와 동형(강제 언래핑 0).
    /// SKTexture는 GPU 텍스처 공유 안전 — 다중 PlayerNode 인스턴스가 같은 텍스처 참조해도 OK.
    private static func walkTexture(for characterID: CharacterID,
                                    direction: PixelDirection,
                                    frame: PixelFrame) -> SKTexture {
        if let cached = walkTextureCache[characterID]?[direction]?[frame] {
            return cached
        }
        let sprite = PixelSprite.data(for: characterID,
                                      direction: direction,
                                      frame: frame)
        let palette = PixelPalette.palette(for: characterID)
        let texture = PixelSpriteRenderer.texture(from: sprite, palette: palette)
        if walkTextureCache[characterID] == nil {
            walkTextureCache[characterID] = [:]
        }
        if walkTextureCache[characterID]?[direction] == nil {
            walkTextureCache[characterID]?[direction] = [:]
        }
        walkTextureCache[characterID]?[direction]?[frame] = texture
        return texture
    }

    // MARK: - Facing (Sprint 7 Phase G / Sprint 10 Phase A 픽셀 일원화)
    /// D-Pad 입력 방향 → 자식 SKSpriteNode texture 교체. 다음 SK 프레임(~16ms) 안 전환.
    /// lastFacing 가드 — 같은 방향 재호출 시 noop(매 프레임 호출에도 비용 0).
    /// 게임 로직(velocity·position·hitbox·skill) 0건 변경 — 순수 시각 layer.
    /// Sprint 10 Phase A — fullBody?.facing(_:) 위임 폐기. 자식 texture 교체로 일원화.
    /// pixelDirection state 동기화 — updatePixelDirection(velocity 기반 fallback)가 noop 되도록.
    func facing(_ direction: Direction) {
        if direction == lastFacing { return }
        lastFacing = direction
        let pixelDir = Self.pixelDirection(from: direction)
        pixelSpriteChild?.texture = Self.cachedTexture(
            for: currentCharacterID,
            direction: pixelDir
        )
        pixelDirection = pixelDir
    }

    /// Direction(D-Pad 입력 layer) → PixelDirection(텍스처 키) 변환.
    /// 좌표 약속:
    ///   .front(카메라 정면, dy < 0) → .down (스프라이트 정면)
    ///   .back (캐릭터 뒷모습, dy > 0) → .up
    ///   .left → .left
    ///   .right → .right
    /// switch exhaustive — default 없음(Direction 4 case enum).
    private static func pixelDirection(from direction: Direction) -> PixelDirection {
        switch direction {
        case .front: return .down
        case .back:  return .up
        case .left:  return .left
        case .right: return .right
        }
    }

    // MARK: - Update (Movement)
    /// 외부에서 매 프레임 호출. dt 기반 수동 이동 후 벽과 겹치면 축을 분리해 wall-slide를 적용한다.
    func update(deltaTime: TimeInterval) {
        // Phase 9-7 — 동결 가드. 청진기 피격 시 2초간 isFrozen=true → velocity 0으로 강제 정지 후 early return.
        // 함수 *최상단* 가드 — 기존 로직 전혀 도달하지 않도록 보장(주의사항 10).
        // 무적(isInvulnerable)과 독립 — 무적은 ContactRouter 콜백에서 freeze 호출 자체를 차단.
        if isFrozen {
            physicsBody?.velocity = .zero
            movementVelocity = .zero
            return
        }
        guard deltaTime > 0 else {
            physicsBody?.velocity = .zero
            movementVelocity = .zero
            return
        }
        let movementModeScale = isRunning
            ? GameplayTuning.playerRunSpeedScale
            : GameplayTuning.playerWalkSpeedScale
        let speed = baseSpeedStart * speedMultiplier * movementModeScale
        let velocity = CGVector(
            dx: currentDirection.dx * speed,
            dy: currentDirection.dy * speed
        )
        moveWithWallSlide(velocity: velocity, deltaTime: deltaTime)
        physicsBody?.velocity = .zero
    }

    private func moveWithWallSlide(velocity: CGVector, deltaTime: TimeInterval) {
        let delta = CGVector(
            dx: velocity.dx * CGFloat(deltaTime),
            dy: velocity.dy * CGFloat(deltaTime)
        )
        let start = resolvedPositionAfterWallRecovery(from: position, preferredDelta: delta)
        guard abs(delta.dx) >= GameplayTuning.dpadInputSnapEpsilon
            || abs(delta.dy) >= GameplayTuning.dpadInputSnapEpsilon else {
            position = start
            movementVelocity = .zero
            return
        }

        let fullTarget = CGPoint(x: start.x + delta.dx, y: start.y + delta.dy)
        if canOccupy(fullTarget) || canMoveWithoutWorseningOverlap(from: start, to: fullTarget) {
            let resolved = resolvedPositionAfterWallRecovery(from: fullTarget, preferredDelta: delta)
            position = resolved
            movementVelocity = resolvedVelocity(from: start, to: resolved, deltaTime: deltaTime)
            return
        }

        var nextPosition = start
        var appliedDelta = CGVector.zero

        let xTarget = CGPoint(x: start.x + delta.dx, y: start.y)
        if canOccupy(xTarget) || canMoveWithoutWorseningOverlap(from: start, to: xTarget) {
            nextPosition.x = xTarget.x
            appliedDelta.dx = delta.dx
        }

        let yTarget = CGPoint(x: nextPosition.x, y: start.y + delta.dy)
        if canOccupy(yTarget) || canMoveWithoutWorseningOverlap(from: nextPosition, to: yTarget) {
            nextPosition.y = yTarget.y
            appliedDelta.dy = delta.dy
        }

        let preferredRecoveryDelta = abs(appliedDelta.dx) >= GameplayTuning.dpadInputSnapEpsilon
            || abs(appliedDelta.dy) >= GameplayTuning.dpadInputSnapEpsilon
            ? appliedDelta
            : delta
        let resolved = resolvedPositionAfterWallRecovery(
            from: nextPosition,
            preferredDelta: preferredRecoveryDelta
        )
        position = resolved
        if abs(appliedDelta.dx) < GameplayTuning.dpadInputSnapEpsilon
            && abs(appliedDelta.dy) < GameplayTuning.dpadInputSnapEpsilon {
            movementVelocity = resolvedVelocity(from: start, to: resolved, deltaTime: deltaTime)
        } else {
            movementVelocity = CGVector(
                dx: appliedDelta.dx / CGFloat(deltaTime),
                dy: appliedDelta.dy / CGFloat(deltaTime)
            )
        }
    }

    private func canOccupy(_ point: CGPoint) -> Bool {
        let rect = wallQueryRect(centeredAt: point)
        if wallRects(intersecting: rect).isEmpty == false {
            return false
        }
        guard wallRectProvider == nil,
              let wallCollisionProvider = wallCollisionProvider else {
            return true
        }
        if wallCollisionProvider(rect) { return false }
        return true
    }

    private func canMoveWithoutWorseningOverlap(from start: CGPoint,
                                                to target: CGPoint) -> Bool {
        let startScore = overlapScore(at: start)
        guard startScore > GameplayTuning.playerWallRecoveryScoreEpsilon else { return false }
        let targetScore = overlapScore(at: target)
        guard targetScore <= startScore + GameplayTuning.playerWallSlideOverlapTolerance else {
            return false
        }
        return doesMoveDeeperIntoWall(from: start, to: target) == false
    }

    private func resolvedPositionAfterWallRecovery(from point: CGPoint,
                                                   preferredDelta: CGVector) -> CGPoint {
        guard wallRectProvider != nil else { return point }
        var resolved = point

        for _ in 0..<GameplayTuning.playerWallRecoveryMaxIterations {
            let currentScore = overlapScore(at: resolved)
            guard currentScore > GameplayTuning.playerWallRecoveryScoreEpsilon else {
                return resolved
            }

            guard let candidate = bestRecoveryCandidate(from: resolved,
                                                        currentScore: currentScore,
                                                        preferredDelta: preferredDelta) else {
                return resolved
            }
            resolved = candidate
        }

        return resolved
    }

    private func bestRecoveryCandidate(from point: CGPoint,
                                       currentScore: CGFloat,
                                       preferredDelta: CGVector) -> CGPoint? {
        let queryRect = wallQueryRect(centeredAt: point)
        let wallRects = wallRects(intersecting: queryRect)
        var bestPoint: CGPoint?
        var bestScore = CGFloat.greatestFiniteMagnitude
        var bestTangentPenalty = CGFloat.greatestFiniteMagnitude
        var bestCorrectionDistance = CGFloat.greatestFiniteMagnitude

        for wallRect in wallRects {
            let intersection = queryRect.intersection(wallRect)
            guard intersection.isNull == false,
                  intersection.width > 0,
                  intersection.height > 0 else {
                continue
            }

            for offset in recoveryOffsets(
                queryRect: queryRect,
                wallRect: wallRect,
                preferredDelta: preferredDelta
            ) {
                let candidate = CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
                let score = overlapScore(at: candidate)
                guard score < currentScore - GameplayTuning.playerWallRecoveryScoreEpsilon else {
                    continue
                }
                let tangentPenalty = recoveryTangentPenalty(
                    offset: offset,
                    preferredDelta: preferredDelta
                )
                let correctionDistance = recoveryDistance(offset)
                if shouldPreferRecoveryCandidate(
                    score: score,
                    tangentPenalty: tangentPenalty,
                    correctionDistance: correctionDistance,
                    bestScore: bestScore,
                    bestTangentPenalty: bestTangentPenalty,
                    bestCorrectionDistance: bestCorrectionDistance
                ) {
                    bestScore = score
                    bestTangentPenalty = tangentPenalty
                    bestCorrectionDistance = correctionDistance
                    bestPoint = candidate
                }
            }
        }

        return bestPoint
    }

    private func recoveryOffsets(queryRect: CGRect,
                                 wallRect: CGRect,
                                 preferredDelta: CGVector) -> [CGVector] {
        let padding = GameplayTuning.playerWallRecoveryPadding
        let moveLeft = wallRect.minX - queryRect.maxX - padding
        let moveRight = wallRect.maxX - queryRect.minX + padding
        let moveDown = wallRect.minY - queryRect.maxY - padding
        let moveUp = wallRect.maxY - queryRect.minY + padding

        let horizontal = abs(moveLeft) <= abs(moveRight)
            ? CGVector(dx: moveLeft, dy: 0)
            : CGVector(dx: moveRight, dy: 0)
        let vertical = abs(moveDown) <= abs(moveUp)
            ? CGVector(dx: 0, dy: moveDown)
            : CGVector(dx: 0, dy: moveUp)

        return [
            clampedRecoveryOffset(horizontal),
            clampedRecoveryOffset(vertical)
        ].sorted { lhs, rhs in
            let lhsDistance = recoveryDistance(lhs)
            let rhsDistance = recoveryDistance(rhs)
            if abs(lhsDistance - rhsDistance) > GameplayTuning.playerWallRecoveryScoreEpsilon {
                return lhsDistance < rhsDistance
            }
            let lhsPenalty = recoveryTangentPenalty(offset: lhs, preferredDelta: preferredDelta)
            let rhsPenalty = recoveryTangentPenalty(offset: rhs, preferredDelta: preferredDelta)
            if abs(lhsPenalty - rhsPenalty) > GameplayTuning.playerWallRecoveryScoreEpsilon {
                return lhsPenalty < rhsPenalty
            }
            return abs(lhs.dx) > abs(lhs.dy)
        }
    }

    private func overlapScore(at point: CGPoint) -> CGFloat {
        let rect = wallQueryRect(centeredAt: point)
        return wallRects(intersecting: rect).reduce(CGFloat.zero) { score, wallRect in
            return score + intersectionArea(rect, wallRect)
        }
    }

    private func doesMoveDeeperIntoWall(from start: CGPoint,
                                        to target: CGPoint) -> Bool {
        let startRect = wallQueryRect(centeredAt: start)
        let targetRect = wallQueryRect(centeredAt: target)
        let queryRect = startRect.union(targetRect)
        return wallRects(intersecting: queryRect).contains { wallRect in
            let startArea = intersectionArea(startRect, wallRect)
            let targetArea = intersectionArea(targetRect, wallRect)
            return targetArea > startArea + GameplayTuning.playerWallRecoveryScoreEpsilon
        }
    }

    private func shouldPreferRecoveryCandidate(score: CGFloat,
                                               tangentPenalty: CGFloat,
                                               correctionDistance: CGFloat,
                                               bestScore: CGFloat,
                                               bestTangentPenalty: CGFloat,
                                               bestCorrectionDistance: CGFloat) -> Bool {
        if score < bestScore - GameplayTuning.playerWallRecoveryScoreEpsilon {
            return true
        }
        guard abs(score - bestScore) <= GameplayTuning.playerWallRecoveryScoreEpsilon else {
            return false
        }
        if tangentPenalty < bestTangentPenalty - GameplayTuning.playerWallRecoveryScoreEpsilon {
            return true
        }
        guard abs(tangentPenalty - bestTangentPenalty) <= GameplayTuning.playerWallRecoveryScoreEpsilon else {
            return false
        }
        return correctionDistance < bestCorrectionDistance
    }

    private func recoveryTangentPenalty(offset: CGVector,
                                        preferredDelta: CGVector) -> CGFloat {
        let preferredLength = recoveryDistance(preferredDelta)
        let offsetLength = recoveryDistance(offset)
        guard preferredLength > GameplayTuning.dpadInputSnapEpsilon,
              offsetLength > GameplayTuning.playerWallRecoveryScoreEpsilon else {
            return 0
        }
        let dot = offset.dx * preferredDelta.dx + offset.dy * preferredDelta.dy
        return abs(dot / (offsetLength * preferredLength))
    }

    private func clampedRecoveryOffset(_ offset: CGVector) -> CGVector {
        let maxCorrection = GameplayTuning.playerWallRecoveryMaxCorrection
        if abs(offset.dx) > maxCorrection {
            return CGVector(dx: offset.dx < 0 ? -maxCorrection : maxCorrection, dy: 0)
        }
        if abs(offset.dy) > maxCorrection {
            return CGVector(dx: 0, dy: offset.dy < 0 ? -maxCorrection : maxCorrection)
        }
        return offset
    }

    private func recoveryDistance(_ vector: CGVector) -> CGFloat {
        return sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
    }

    private func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard intersection.isNull == false else { return 0 }
        return max(0, intersection.width) * max(0, intersection.height)
    }

    private func wallRects(intersecting rect: CGRect) -> [CGRect] {
        guard let wallRectProvider = wallRectProvider else { return [] }
        return wallRectProvider(rect)
    }

    private func resolvedVelocity(from start: CGPoint,
                                  to end: CGPoint,
                                  deltaTime: TimeInterval) -> CGVector {
        guard deltaTime > 0 else { return .zero }
        return CGVector(
            dx: (end.x - start.x) / CGFloat(deltaTime),
            dy: (end.y - start.y) / CGFloat(deltaTime)
        )
    }

    private func wallQueryRect(centeredAt point: CGPoint) -> CGRect {
        let rect = CGRect(
            x: point.x - GameplayTuning.playerWidth / 2,
            y: point.y - GameplayTuning.playerHeight / 2,
            width: GameplayTuning.playerWidth,
            height: GameplayTuning.playerHeight
        )
        return rect.insetBy(
            dx: GameplayTuning.playerWallQueryInset,
            dy: GameplayTuning.playerWallQueryInset
        )
    }

    // MARK: - Freeze (Phase 9-7)
    /// 청진기 피격 시 외부(ContactRouter 콜백)에서 호출. duration초간 이동 입력 차단.
    /// 정책:
    /// 1) 이미 frozen이면 noop — 2초 *고정*, 누적 안 함 (연사 무한 정지 방지).
    /// 2) 무적(isInvulnerable) 우선 — 무적 중 호출 noop. 이간호 텔레포트와 일관.
    /// 3) 시각: alpha 1.0 ↔ frozenBlinkMinAlpha(0.4) 반복 깜빡임. (SpriteKit 표준 alpha 전파로 자식까지 깜빡임)
    /// 4) duration 종료 시 SKAction.run 콜백으로 isFrozen=false + alpha 1.0 복원 + velocity 0.
    /// 5) withKey: playerFreezeActionKey → 같은 키 재호출 시 SpriteKit 자동 액션 교체 (이중 안전망).
    /// [weak self] 캡처 — 동결 진행 중 씬 전환 가능성 대비.
    /// Sprint 10 Phase A — 본 메서드 0줄 변경(SPEC §8.12).
    func freeze(duration: TimeInterval) {
        if isFrozen { return }
        if isInvulnerable { return }
        isFrozen = true

        let half = GameplayTuning.frozenBlinkHalfPeriod
        let fadeOut = SKAction.fadeAlpha(to: GameplayTuning.frozenBlinkMinAlpha, duration: half)
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
        run(.sequence([blink, restore]), withKey: GameplayTuning.playerFreezeActionKey)
    }

    // MARK: - Pixel Animation Hooks (R0 — PixelCharacterAnimating)
    // updatePixelDirection / tickWalkFrame 본문은 프로토콜 기본 구현이 단일 진실 원천.
    // PlayerNode는 텍스처 반영 훅 2개만 구현 — 기존 시맨틱 byte-equal 보존:
    //   · 방향 변경 프레임: 본체 refreshTexture(idle 캐시) + 자식에 idle 방향 텍스처 (순간적 idle 노출 보존)
    //   · 보행 토글 프레임: walkTexture 캐시로 본체+자식 동기 (다리 교차가 화면에 보임 — Sprint 11)

    /// 방향이 바뀐 프레임 전용 훅 — 자식에 *idle 방향 텍스처*를 적용(기존 updatePixelDirection 시맨틱).
    func applyDirectionChangeTexture() {
        refreshTexture()
        // Sprint 10 Phase A — 본체뿐 아니라 자식도 같이 갱신(시각 단일 진실 원천).
        pixelSpriteChild?.texture = Self.cachedTexture(
            for: currentCharacterID,
            direction: pixelDirection
        )
    }

    /// 현재 pixelDirection + pixelFrame 조합 텍스처를 본체(self)와 자식 pixelSpriteChild 양쪽에 set.
    /// 텍스처는 walkTexture 정적 캐시에서 가져오므로 매 호출 재생성 없음 — 변화 없는 프레임은 노드가 noop 처리.
    func applyPixelTexture() {
        let tex = Self.walkTexture(
            for: currentCharacterID,
            direction: pixelDirection,
            frame: pixelFrame
        )
        texture = tex                  // 본체(placeholder) 값 정합 유지
        pixelSpriteChild?.texture = tex
    }

    // MARK: - Texture Refresh
    /// 현재 캐릭터/방향 조합으로 텍스처를 재생성하고 SKSpriteNode.texture에 set.
    /// SKTexture 이전 값은 ARC로 자동 해제 — 메모리 누수 0.
    /// 호출 빈도: 캐릭터 적용 1회 + 방향 변경 시 (D-Pad/velocity fallback).
    /// Sprint 10 Phase A — PNG 우선 경로 제거. cachedTexture(20-텍스처 static 캐시) 직행.
    ///                     본체 self.texture는 투명 placeholder 정책상 시각 영향 0 — 자식이 단일 진실 원천.
    ///                     단, currentCharacterID/pixelDirection 상태 정합 위해 *값으로*는 정확히 유지.
    private func refreshTexture() {
        texture = Self.cachedTexture(
            for: currentCharacterID,
            direction: pixelDirection
        )
    }
}
