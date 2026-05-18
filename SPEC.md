# Phase 9-7 — 이교수 + 청진기 (상 난이도 전용)

## 개요
상 난이도(.hard)에서만 등장하는 두 번째 적 NPC "이교수"를 추가한다. 이교수는 수간호사와 독립적으로 맵을 순찰하며 일정 주기로 "청진기" 투사체를 플레이어에게 투척한다. 청진기에 맞으면 플레이어가 2초간 동결되어 이동 입력이 차단된다. 등장 전에는 인트로 컷씬 dismiss 후 "경고 · 이교수 출현" 컷씬을 1회 표시한다.

## 변경 유형
**게임플레이 + 비주얼 (혼합)**

## 게임 경험 의도
상 난이도에 들어선 플레이어는 수간호사의 F 연발에 더해, 두 번째 위협 "이교수"로부터의 청진기 투척까지 동시에 회피해야 한다. 청진기에 맞으면 죽지는 않지만 2초간 묶여 그대로 수간호사 F 한 발이 날아오는 *공포의 사슬*을 만든다. 등장 전 컷씬으로 "학교에서 나온 깐깐한 이교수"의 톤을 미리 알린다.

## Sprint 범위 계약

### 허용
1. 새 노드 `ProfessorNode` — 이교수 본체 SKSpriteNode + 4 waypoint 순찰 + 청진기 발사 루프
2. 새 노드 `StethoscopeNode` — 청진기 투사체 SKSpriteNode
3. `PlayerNode.isFrozen: Bool` + `freeze(duration:)` 메서드 + update 가드
4. `GameScene.update`에 frozen 가드 1줄 + `professor?.updatePixelAnimation` 1줄
5. `ContactRouter.onStethoscopeHitPlayer` / `onStethoscopeHitWall` 콜백 2개 + `handleStethoscopeContact` 메서드
6. `PhysicsCategory.stethoscope: UInt32 = 0b10000000 (128)` 추가
7. `GameConfig` "Professor (Phase 9-7)" + "Stethoscope (Phase 9-7)" + "Player Freeze (Phase 9-7)" MARK 섹션
8. `GameScene+Setup.setupProfessor()` — hard 분기 가드 함수 내부 + didMove 호출 1줄 추가
9. `GameScene.showProfessorWarningCutscene()` — 인트로 컷씬 onDismiss 안 hard 분기로 호출
10. `GameScene.endGame`에 `professor?.stopThrowing(worldNode:)` 1줄 추가
11. `PixelSprite.professorData(direction:frame:)` extension + `PixelPalette.professorPalette` extension
12. ColorTokens 4개 (회색 머리/머리 음영/콧수염/검은 바지) — 다른 토큰 재사용 최대화
13. "청진기 명중!" 0.9초 토스트 — `ToastLabelNode.spawn` 재사용
14. `CutsceneOverlayNode` 재사용 — 신규 컷씬 노드 신설 금지

### 금지
1. easy/normal 게임플레이 회귀 — 이교수는 hard 외 등장 불가
2. 새 BGM/효과음 추가
3. 수간호사(EnemyNode) 거동/스폰 변경
4. 음표/F/석조무사/변기 거동 변경
5. ProjectileNode에 청진기 분기 추가 (별도 노드 신설)
6. Phase 9-1~9-6 영역 (HUD/스킬/변기/맵/체크보드) 코드 0줄 변경

### 판단 기준
"이 변경 없이 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

## 등장 시점 결정

**Hard 시작과 동시 (worldNode 부착)**. 인트로 컷씬 dismiss → 이교수 경고 컷씬 → 카운트다운 → 게임 시작.

## 컷씬 통합

인트로 컷씬 `onDismiss` 클로저 안에서 `difficulty == .hard` 분기 → `showProfessorWarningCutscene()` 호출, 그 onDismiss에서 `.countdown` 전환. easy/normal은 기존 흐름 그대로.

**메시지 텍스트** (GDD §10 + 사용자 요청 결합):
- 제목: `"경고 · 이교수 출현"`
- 본문: `"학교에서 나온 깐깐한 이교수가 청진기를 들고 순찰을 돕니다! 맞으면 잠시 움직일 수 없게 됩니다. 피하세요."`

## 정지 시스템 결정

`PlayerNode.isFrozen: Bool` 신설 + 외부 진입점 `freeze(duration:)`:
- `update(deltaTime:)` 최상단에서 `if isFrozen { physicsBody?.velocity = .zero; return }`
- GameScene.update D-Pad 입력 라우팅에서 `if !skillSystem.isDashing && !player.isFrozen` 가드
- 시각: alpha 1.0 ↔ 0.4 깜빡임 (taiwanTripFlash 패턴)
- 2초 후 SKAction.run 콜백으로 `isFrozen = false` + alpha 복원
- `isInvulnerable == true`면 freeze 호출 noop (무적 우선)
- `isFrozen == true`면 재호출 noop (2초 *고정*, 누적 안 함)

## 변경 범위

### 수정할 파일
- `GameScene.swift` — `var professor: ProfessorNode?` 프로퍼티 + update 가드 + Professor update 호출 + 컷씬 분기 + endGame stop + ContactRouter 콜백 2개
- `GameScene+Setup.swift` — `setupProfessor()` 메서드 + didMove에서 호출 1줄
- `Systems/ContactRouter.swift` — 콜백 2개 + 분기 1개 + handleStethoscopeContact
- `Config/PhysicsCategory.swift` — `stethoscope: UInt32 = 0b10000000`
- `Config/GameConfig.swift` — 3개 MARK 섹션
- `Config/ColorTokens.swift` — 4개 토큰
- `Nodes/PlayerNode.swift` — isFrozen + freeze(duration:) + update 가드
- `Models/PixelSprite.swift` — professorData extension
- `Models/PixelPalette.swift` — professorPalette extension

### 추가할 파일
- `Nodes/ProfessorNode.swift`
- `Nodes/StethoscopeNode.swift`

## 기능 상세

### 기능 1: ProfessorNode

```swift
final class ProfessorNode: SKSpriteNode {
    private var pixelDirection: PixelDirection = .down
    private var pixelFrame: PixelFrame = .idle
    private var frameAccumulator: TimeInterval = 0
    private var currentWaypointIndex: Int = 0
    private weak var worldRef: SKNode?
    private var targetProvider: () -> CGPoint? = { nil }
    private var progressProvider: () -> Double = { 0 }

    init() {
        let physicsSize = CGSize(width: GameConfig.professorWidth, height: GameConfig.professorHeight)
        let visualSize = CGSize(
            width: GameConfig.professorWidth * GameConfig.pixelSpriteScale,
            height: GameConfig.professorHeight * GameConfig.pixelSpriteScale
        )
        let initialTexture = PixelSpriteRenderer.texture(
            from: PixelSprite.professorData(direction: .down, frame: .idle),
            palette: PixelPalette.professorPalette
        )
        super.init(texture: initialTexture, color: .clear, size: visualSize)
        name = "professor"
        zPosition = 5
        // physicsBody 미부착 — *통과형* NPC. 위협은 청진기 담당.
        startPatrol()
    }

    private func startPatrol() {
        let waypoints = GameConfig.professorWaypoints
        var moves: [SKAction] = []
        for i in 0..<waypoints.count {
            let from = waypoints[i]
            let to = waypoints[(i + 1) % waypoints.count]
            let dist = hypot(to.x - from.x, to.y - from.y)
            let dur = TimeInterval(dist / GameConfig.professorSpeed)
            moves.append(SKAction.move(to: to, duration: dur))
        }
        run(.repeatForever(.sequence(moves)))
    }

    func startThrowingStethoscopes(targetProvider: @escaping () -> CGPoint?,
                                    worldNode: SKNode,
                                    progressProvider: @escaping () -> Double) {
        self.targetProvider = targetProvider
        self.worldRef = worldNode
        self.progressProvider = progressProvider
        scheduleNextThrow()
    }

    private func scheduleNextThrow() {
        let interval = currentThrowInterval()
        let wait = SKAction.wait(forDuration: interval)
        let throwAction = SKAction.run { [weak self] in
            self?.throwStethoscope()
            self?.scheduleNextThrow()
        }
        run(.sequence([wait, throwAction]), withKey: GameConfig.professorThrowActionKey)
    }

    private func currentThrowInterval() -> TimeInterval {
        let progress = progressProvider()
        let start = GameConfig.stethoscopeThrowIntervalStart
        let end = GameConfig.stethoscopeThrowIntervalEnd
        return start + (end - start) * progress
    }

    private func throwStethoscope() {
        guard let world = worldRef else { return }
        guard let target = targetProvider() else { return }
        guard currentStethoscopeCount(in: world) < GameConfig.stethoscopeMaxConcurrent else { return }
        let dx = target.x - position.x
        let dy = target.y - position.y
        let magnitude = hypot(dx, dy)
        guard magnitude > 0 else { return }
        let unitX = dx / magnitude
        let unitY = dy / magnitude
        let stethoscope = StethoscopeNode()
        stethoscope.position = position
        stethoscope.physicsBody?.velocity = CGVector(
            dx: unitX * GameConfig.stethoscopeSpeed,
            dy: unitY * GameConfig.stethoscopeSpeed
        )
        world.addChild(stethoscope)
    }

    private func currentStethoscopeCount(in world: SKNode) -> Int {
        var count = 0
        world.enumerateChildNodes(withName: "stethoscope") { _, _ in count += 1 }
        return count
    }

    func stopThrowing(worldNode: SKNode) {
        removeAction(forKey: GameConfig.professorThrowActionKey)
        worldNode.enumerateChildNodes(withName: "stethoscope") { node, _ in
            node.physicsBody?.velocity = .zero
        }
    }

    // EnemyNode 패턴 답습 — dt 매 프레임 호출, 방향/걷기 프레임 갱신
    func updatePixelAnimation(deltaTime: TimeInterval) { /* ... */ }
    required init?(coder: NSCoder) { fatalError() }
}
```

### 기능 2: StethoscopeNode

```swift
final class StethoscopeNode: SKSpriteNode {
    init() {
        let size = CGSize(width: GameConfig.stethoscopeSize, height: GameConfig.stethoscopeSize)
        super.init(texture: nil, color: .ganhoPixelChiefShoes, size: size)  // 검은 톤 재사용
        name = "stethoscope"
        zPosition = 5

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.allowsRotation = false
        body.friction = 0
        body.restitution = 0
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.stethoscope
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
        physicsBody = body

        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: GameConfig.stethoscopeRotationDuration)))
    }
    required init?(coder: NSCoder) { fatalError() }
}
```

### 기능 3: PlayerNode.isFrozen + freeze(duration:)

```swift
private(set) var isFrozen: Bool = false

func freeze(duration: TimeInterval) {
    if isFrozen { return }
    if isInvulnerable { return }
    isFrozen = true

    let half = GameConfig.frozenBlinkHalfPeriod
    let fadeOut = SKAction.fadeAlpha(to: GameConfig.frozenBlinkMinAlpha, duration: half)
    let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: half)
    let cycle = SKAction.sequence([fadeOut, fadeIn])
    let cycleCount = max(1, Int(duration / (half * 2)))
    let blink = SKAction.repeat(cycle, count: cycleCount)
    let restore = SKAction.run { [weak self] in
        self?.isFrozen = false
        self?.alpha = 1.0
        self?.physicsBody?.velocity = .zero
    }
    run(.sequence([blink, restore]), withKey: GameConfig.playerFreezeActionKey)
}

func update(deltaTime: TimeInterval) {
    if isFrozen {
        physicsBody?.velocity = .zero
        return
    }
    // 기존 로직 그대로
    let speed = baseSpeedStart * speedMultiplier
    physicsBody?.velocity = CGVector(dx: currentDirection.dx * speed, dy: currentDirection.dy * speed)
}
```

### 기능 4: GameScene 통합

```swift
var professor: ProfessorNode?

// update 안 D-Pad 라우팅 가드 수정
if !skillSystem.isDashing && !player.isFrozen {
    player.currentDirection = dpad.currentDirection
} else if player.isFrozen {
    player.currentDirection = .zero
}

// Professor 픽셀 갱신 (hard만, optional)
professor?.updatePixelAnimation(deltaTime: dt)

// 인트로 컷씬 onDismiss 안 분기
onDismiss: { [weak self] in
    guard let self = self else { return }
    UserDefaults.standard.set(true, forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
    if self.difficulty == .hard {
        self.showProfessorWarningCutscene()
    } else {
        self.gameState = .countdown
        self.showCountdown()
    }
}

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

// configureContactRouter 안
contactRouter.onStethoscopeHitPlayer = { [weak self] node in
    guard let self = self else { return }
    if self.player.isInvulnerable {
        node.run(.removeFromParent())
        return
    }
    self.haptics.medium()
    self.cameraNode.run(CameraShakeAction.make())
    ToastLabelNode.spawn(text: GameConfig.stethoscopeToastText,
                         at: self.player.position,
                         parent: self.worldNode)
    self.player.freeze(duration: GameConfig.playerFreezeDuration)
    node.run(.removeFromParent())
}
contactRouter.onStethoscopeHitWall = { node in
    node.run(.removeFromParent())
}

// endGame 안 spawnSystem.stop() 다음
professor?.stopThrowing(worldNode: worldNode)
```

### 기능 5: GameScene+Setup.setupProfessor

```swift
func setupProfessor() {
    guard difficulty == .hard else { return }
    let node = ProfessorNode()
    let first = GameConfig.professorWaypoints[0]
    node.position = first
    worldNode.addChild(node)
    professor = node
    node.startThrowingStethoscopes(
        targetProvider: { [weak self] in self?.player.position },
        worldNode: worldNode,
        progressProvider: { [weak self] in
            guard let self = self else { return 0 }
            return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
        }
    )
}

// didMove 호출 추가 (setupStoneGuard 다음)
setupProfessor()
```

### 기능 6: ContactRouter 분기

```swift
var onStethoscopeHitPlayer: (SKNode) -> Void = { _ in }
var onStethoscopeHitWall: (SKNode) -> Void = { _ in }

// didBegin 안 projectile 분기 다음
if categories & PhysicsCategory.stethoscope != 0 {
    handleStethoscopeContact(contact)
    return
}

private func handleStethoscopeContact(_ contact: SKPhysicsContact) {
    let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    let stethoscopeBody = contact.bodyA.categoryBitMask == PhysicsCategory.stethoscope
        ? contact.bodyA : contact.bodyB
    if categories & PhysicsCategory.player != 0 {
        guard let node = stethoscopeBody.node else { return }
        onStethoscopeHitPlayer(node)
        return
    }
    if categories & PhysicsCategory.wall != 0 {
        guard let node = stethoscopeBody.node else { return }
        onStethoscopeHitWall(node)
    }
}
```

## GameConfig 상수

```swift
// MARK: - Professor (Phase 9-7)
static let professorWidth: CGFloat = 16
static let professorHeight: CGFloat = 20
static let professorSpeed: CGFloat = 70
static let professorWaypoints: [CGPoint] = [
    CGPoint(x: 320, y: 200),
    CGPoint(x: 640, y: 200),
    CGPoint(x: 640, y: 280),
    CGPoint(x: 320, y: 280)
]
static let professorThrowActionKey: String = "professorThrow"
static let professorWarningTitle: String = "경고 · 이교수 출현"
static let professorWarningBody: String = "학교에서 나온 깐깐한 이교수가 청진기를 들고 순찰을 돕니다! 맞으면 잠시 움직일 수 없게 됩니다. 피하세요."

// MARK: - Stethoscope (Phase 9-7)
static let stethoscopeSize: CGFloat = 18
static let stethoscopeSpeed: CGFloat = 220
static let stethoscopeThrowIntervalStart: TimeInterval = 2.5
static let stethoscopeThrowIntervalEnd: TimeInterval = 1.4
static let stethoscopeMaxConcurrent: Int = 4
static let stethoscopeRotationDuration: TimeInterval = 0.5
static let stethoscopeToastText: String = "청진기 명중!"

// MARK: - Player Freeze (Phase 9-7)
static let playerFreezeDuration: TimeInterval = 2.0
static let frozenBlinkHalfPeriod: TimeInterval = 0.2
static let frozenBlinkMinAlpha: CGFloat = 0.4
static let playerFreezeActionKey: String = "playerFreeze"
```

## ColorTokens

```swift
static let ganhoPixelProfessorHair = UIColor(hex: "#7a7570")
static let ganhoPixelProfessorHairShadow = UIColor(hex: "#5a5550")
static let ganhoPixelProfessorMustache = UIColor(hex: "#2a2025")
static let ganhoPixelProfessorPants = UIColor(hex: "#1f1a1f")
```

## PhysicsCategory

```swift
static let stethoscope: UInt32 = 0b10000000  // 128
```

PlayerNode contactTestBitMask에 `| PhysicsCategory.stethoscope` 추가.

## 회귀 방지

| Phase | 보호 영역 | 본 SPEC 회귀 가능 지점 | 대응 |
|---|---|---|---|
| 9-1 (8-3/4/5) | HUD/디자인 토큰 | 0줄 | HUD 코드 미접촉 |
| 9-4 | 체크보드/normal 맵 | 0줄 | setupMap의 normal 분기 미접촉 |
| 9-5 | SkillSystem/스킬 노드 | 1줄 (`!player.isFrozen` 가드만 추가) | skill 가드와 *AND* 결합 |
| 9-6 | 변기/토스트/콤보 | 0줄 (ToastLabelNode 재사용만) | 텍스트만 다름, 코드 동일 |

`EnemyNode`, `StoneGuardNode`, `SpawnSystem`, `ScoreSystem`, `SkillSystem`, `ToiletNode` 모두 *읽기 전용*.

## 매직 넘버 정책

모든 값은 GameConfig.swift 상수 경유. 호출부 리터럴 0건.

## 주의사항

1. **CutsceneOverlayNode 동시 표시 금지**: 인트로 dismiss 후 *완전 제거*된 다음 이교수 경고 호출.
2. **GameState `.cutscene` 유지**: 이교수 경고 진입 시 `.countdown`은 *컷씬 dismiss 후*에만 전환.
3. **hard 외 professor 미설정**: `professor: ProfessorNode?` Optional. `setupProfessor` 내부 가드 + endGame `professor?.stopThrowing()`은 nil이면 자연 noop.
4. **무적과 정지 우선순위**: `isInvulnerable` 우선 (무적 → 정지 → 게임오버 순서).
5. **freeze 재호출 noop**: 2초 *고정*, 연사 시 무한 정지 방지.
6. **didBegin 안 즉시 제거 금지**: `node.run(.removeFromParent())` SKAction 사용.
7. **청진기 발사 SKAction key**: `"professorThrow"`로 부착, endGame에서 removeAction(forKey:) 일괄 정지.
8. **PixelPalette 두 dict 분리**: `chiefPalette`와 `professorPalette`는 별도 dict, 키 충돌 무관.
9. **회전 액션 vs 충돌 박스**: `allowsRotation = false` 명시, SKAction.rotate는 시각만.
10. **PlayerNode.update 시그니처 보존**: isFrozen 가드는 함수 *최상단* early return.

## 평가 가중치

- Swift 패턴 35% — guard let / weak self / GameConfig 상수화 / MARK
- 게임 로직 30% — SKAction 패턴 / PhysicsCategory 분리 / didBegin 즉시 제거 금지
- 성능 & 안정성 20% — optional chain / removeAction / endGame 정리
- 기능 완성도 15% — GDD §7-8 요구 전부, hard만 등장, easy/normal 회귀 0

## Generator 작업 순서 권장

1. GameConfig 신규 상수
2. PhysicsCategory.stethoscope
3. ColorTokens 4개
4. PixelSprite.professorData
5. PixelPalette.professorPalette
6. PlayerNode (isFrozen + freeze + update 가드)
7. StethoscopeNode (신규)
8. ProfessorNode (신규, StethoscopeNode 사용)
9. ContactRouter (콜백 + 분기)
10. GameScene+Setup.setupProfessor
11. GameScene (프로퍼티 + update + 컷씬 + endGame + 콜백)
12. .pbxproj 신규 파일 2개 추가
13. 빌드 검증

## 필수 검증 항목

1. easy/normal 게임 진입 시 professor=nil, 이교수 경고 컷씬 표시 안 됨
2. hard 게임 진입 시 인트로 컷씬 → 이교수 경고 컷씬 → 카운트다운 흐름
3. 청진기 발사 주기 2.5→1.4 보간, 동시 4개 한정
4. 청진기 명중 시 2초 freeze + alpha 깜빡임 + 토스트 + 햅틱 medium + 카메라 셰이크
5. 무적 중 청진기 명중 시 freeze 무시 (이간호 텔레포트 일관성)
6. freeze 중 재명중 시 시간 누적 안 함 (고정 2초)
7. endGame 후 청진기 추가 발사 0
8. Phase 9-1~9-6 코드 0줄 변경
