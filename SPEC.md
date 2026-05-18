# Phase 9-6 — 화캉스 보너스 (변기) 시스템

## 개요
12초마다 15% 확률로 맵에 16×16 픽셀 변기 1개를 스폰. 미수집 시 8초 후 자동 소멸. 수집 시 *음표 2개 동시 수집 효과*(점수+2, 콤보+2) + "화캉스 보너스!" 토스트 0.9초 표시. Phase 2-10 SpawnSystem 패턴 + Phase 6-16 자가 소멸 노드 패턴 답습.

## 변경 유형
**게임플레이 + 비주얼 (혼합)** — 새 수집 노드(게임플레이) + 픽셀 아트/토스트 라벨(비주얼).

## 게임 경험 의도
12초 주기로 *희소한 보너스 기회* — 변기라는 의외성 오브젝트로 "화캉스(화장실 바캉스)"라는 자전적 농담을 시각으로 전달. 8초 소멸 압박이 *지금 가야 하나*라는 미시 결정을 강요해, 평탄한 음표 수집 루프에 *결정의 리듬*을 끼워 넣는다. 수집 시 콤보+2가 마일스톤 직전에 만나면 *황금기 진입* 가속.

## Sprint 범위 계약

### 허용
1. 신규 노드 `ToiletNode` (Nodes/) — 16×16 픽셀 아트, PhysicsBody static.
2. 신규 노드 `ToastLabelNode` (Nodes/) — 자가 소멸 토스트 라벨, SelfDismissingNode 채택.
3. `SpawnSystem` 내부 확장 — `startToiletSpawnLoop()` + `tryRollAndSpawnToilet()` + `currentToiletCount()` + `randomToiletPosition()`. start/stop 시그니처 보존.
4. `ContactRouter` 신규 콜백 `onToiletCollected: (SKNode) -> Void` + bonus 분기 + `handleBonusContact`.
5. `ScoreSystem` 신규 메서드 `recordToiletBonus(at:)` (recordNoteHit 2회 호출).
6. `PhysicsCategory.bonus: UInt32 = 0b1000000 (64)` 신규.
7. `PlayerNode.contactTestBitMask`에 `.bonus` OR 결합.
8. `GameConfig` 변기 관련 상수 일괄 추가 (Toilet Bonus + Toast Label MARK 섹션).
9. `GameScene.configureContactRouter()` 안 `onToiletCollected` 콜백 등록.
10. 변기 픽셀 데이터 `PixelSprite.toiletData()` static + `PixelPalette.toiletPalette`.
11. ColorTokens 3개 (ganhoToiletBowl/ganhoToiletSeat/ganhoToiletAccent).

### 금지
1. 변기 N개 동시 스폰 — 단일성 정책 (1개).
2. 난이도별 차등 (모든 난이도 동일).
3. HUD 변기 카운터/알림.
4. BGM/효과음 신규 (기존 `.noteCollected` 재사용).
5. 변기 종류 확장.
6. Phase 9-1~9-5 영역 코드 0줄 수정.
7. SpawnSystem 기존 시그니처(`start/stop/apply/fireImmediately`) 변경 — *추가만*.

### 판단 기준
"이 변경 없이 변기 보너스가 *제대로 동작하지 않는가*?" → YES면 허용, NO면 금지.

## 스폰 모델 결정 (Planner)

**Bernoulli 단일 시도 (12초마다 1회 15% 판정)** 채택:
- `SKAction.repeatForever([wait(12), run { trySpawn() }])`
- 매 사이클 `CGFloat.random(in: 0..<1) < 0.15` 단일 판정
- 확률 누적 없음 (단순/예측 가능성 우선)
- 평균 스폰 간격: 12s / 0.15 = 80초

**단일성 정책 (동시 1개)**: `tryRollAndSpawnToilet` 진입 시 `currentToiletCount() < 1` 가드를 *확률 시도 전*에 둠 — 화면 어수선함 차단 + 체감 확률 정확.

## "2배 점수 음표 다수 토스트" 의미 해석

사용자 요청 모호 → GDD §7-3 표 명시 1:1:
- 효과: **음표 2개 수집과 동등 (점수+2, 콤보+2)**
- 토스트: **"화캉스 보너스!" 텍스트 0.9초 표시**

해석 결정:
- 점수+2 = `recordToiletBonus`가 *내부적으로 recordNoteHit 2회 호출* → 콤보 윈도우 갱신 + 콤보 2증가 + 점수 2회 가산. 마일스톤 분기 자연 발화.
- "음표 다수 토스트" = ScorePopupNode 2개 fan-out (좌/우 ±8pt offset) + "화캉스 보너스!" ToastLabelNode 1개.

## 노드 트리 부착

| 노드 | 부모 | zPosition |
|---|---|---|
| `ToiletNode` | `worldNode` | 4 (note 0 위, player 5 아래) |
| `ToastLabelNode` | `worldNode` | 50 (ScorePopupNode와 동일) |

## 변경 범위

### 수정할 파일
- `GameScene.swift` — `configureContactRouter()` 안에 onToiletCollected 콜백 1개 추가
- `Systems/SpawnSystem.swift` — start 끝에 `startToiletSpawnLoop()` 1줄 + stop에 `removeAction(forKey: "spawnToilets")` 1줄 + 신규 메서드 4개
- `Systems/ContactRouter.swift` — 콜백 1개 + didBegin 분기 1개 + `handleBonusContact` 1개
- `Systems/ScoreSystem.swift` — `recordToiletBonus(at:)` 1개 추가
- `Config/PhysicsCategory.swift` — `static let bonus: UInt32 = 0b1000000` 1줄
- `Config/GameConfig.swift` — "Toilet Bonus (Phase 9-6)" + "Toast Label (Phase 9-6)" MARK 섹션
- `Nodes/PlayerNode.swift` — contactTestBitMask OR `.bonus` 1개 추가
- `Models/PixelSprite.swift` — `static func toiletData() -> Frame`
- `Models/PixelPalette.swift` — `static let toiletPalette: [Character: UIColor]`
- `Config/ColorTokens.swift` — 3개 색 추가

### 추가할 파일
- `Nodes/ToiletNode.swift`
- `Nodes/ToastLabelNode.swift`

## 기능 상세

### 기능 1: ToiletNode

```swift
final class ToiletNode: SKSpriteNode {
    init() {
        let size = CGSize(width: GameConfig.toiletSize, height: GameConfig.toiletSize)
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.toiletData(),
            palette: PixelPalette.toiletPalette
        )
        super.init(texture: texture, color: .clear, size: size)
        name = "toilet"
        zPosition = GameConfig.toiletZPosition
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false
        body.categoryBitMask     = PhysicsCategory.bonus
        body.collisionBitMask    = 0
        body.contactTestBitMask  = PhysicsCategory.player
        physicsBody = body
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 스폰 직후 1회 호출. 8초 후 fadeOut + removeFromParent.
    func applyLifetime() {
        let wait   = SKAction.wait(forDuration: GameConfig.toiletLifetime)
        let fade   = SKAction.fadeOut(withDuration: GameConfig.toiletFadeOutDuration)
        let remove = SKAction.removeFromParent()
        run(.sequence([wait, fade, remove]), withKey: "toiletLifetime")
    }
}
```

### 기능 2: PixelSprite.toiletData() (16×16)

```swift
static func toiletData() -> Frame {
    return [
        "................",
        "................",
        "................",
        "................",
        "...ssssssssss...",
        "..s..........s..",
        "..s.CCCCCCCC.s..",
        "..s.CCCCCCCC.s..",
        "...ssssssssss...",
        "...WWWWWWWWWW...",
        "...W........W...",
        "...W........W...",
        "...W........W...",
        "...WWWWWWWWWW...",
        "...W........W...",
        "..WWWWWWWWWWWW..",
    ]
}
```

팔레트: W=본체 흰색, s=시트 회색, C=물 코럴.

### 기능 3: ToastLabelNode

```swift
final class ToastLabelNode: SKNode, SelfDismissingNode {
    private let label: SKLabelNode
    private init(text: String) {
        self.label = SKLabelNode(text: text)
        super.init()
        name = "toast"
        zPosition = GameConfig.toastZPosition
        configureLabel()
        setScale(GameConfig.toastStartScale)
        addChild(label)
    }
    required init?(coder: NSCoder) { fatalError() }

    static func spawn(text: String, at position: CGPoint, parent: SKNode) {
        let node = ToastLabelNode(text: text)
        node.position = CGPoint(x: position.x, y: position.y + GameConfig.toastStartOffsetY)
        parent.addChild(node)
        node.animate()
    }

    private func animate() {
        let moveUp  = SKAction.moveBy(x: 0, y: GameConfig.toastFlyUpDistance, duration: GameConfig.toastDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.toastDuration)
        let scaleUp = SKAction.scale(to: GameConfig.toastEndScale, duration: GameConfig.toastDuration)
        let group   = SKAction.group([moveUp, fadeOut, scaleUp])
        run(.sequence([group, .removeFromParent()]))
    }

    private func configureLabel() {
        label.fontSize = GameConfig.toastFontSize
        label.fontColor = .ganhoYellowF
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
```

### 기능 4: SpawnSystem 확장

```swift
// start(...) 끝에 1줄 추가
startToiletSpawnLoop()

// stop() 안에 1줄 추가
scene?.removeAction(forKey: "spawnToilets")

// MARK: - Toilet Spawn (Phase 9-6)
private func startToiletSpawnLoop() {
    let wait = SKAction.wait(forDuration: GameConfig.toiletSpawnInterval)
    let roll = SKAction.run { [weak self] in self?.tryRollAndSpawnToilet() }
    let loop = SKAction.repeatForever(.sequence([wait, roll]))
    scene?.run(loop, withKey: "spawnToilets")
}

private func tryRollAndSpawnToilet() {
    guard let world = worldNode else { return }
    guard currentToiletCount() < GameConfig.toiletMaxConcurrent else { return }
    guard CGFloat.random(in: 0..<1) < GameConfig.toiletSpawnProbability else { return }
    guard let position = randomToiletPosition() else { return }
    let toilet = ToiletNode()
    toilet.position = position
    world.addChild(toilet)
    toilet.applyLifetime()
}

private func currentToiletCount() -> Int {
    guard let world = worldNode else { return 0 }
    var count = 0
    world.enumerateChildNodes(withName: "toilet") { _, _ in count += 1 }
    return count
}

private func randomToiletPosition() -> CGPoint? {
    let margin = GameConfig.tileSize
    let x = CGFloat.random(in: margin ... GameConfig.mapWidth  - margin)
    let y = CGFloat.random(in: margin ... GameConfig.mapHeight - margin)
    let cx = GameConfig.mapWidth  / 2
    let cy = GameConfig.mapHeight / 2
    if abs(x - cx) + abs(y - cy) < GameConfig.tileSize * 3 {
        return nil
    }
    return CGPoint(x: x, y: y)
}
```

### 기능 5: ContactRouter 분기

```swift
var onToiletCollected: (SKNode) -> Void = { _ in }

func didBegin(_ contact: SKPhysicsContact) {
    let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    // 기존 분기 그대로
    if categories & PhysicsCategory.bonus != 0 {
        handleBonusContact(contact)
        return
    }
    // 기존 note 분기 그대로
}

private func handleBonusContact(_ contact: SKPhysicsContact) {
    let bonusBody = contact.bodyA.categoryBitMask == PhysicsCategory.bonus ? contact.bodyA : contact.bodyB
    guard let node = bonusBody.node else { return }
    onToiletCollected(node)
}
```

### 기능 6: ScoreSystem

```swift
/// Phase 9-6 — 변기 수집 시 호출. 음표 2개 효과(GDD §7-3).
/// recordNoteHit 2회 호출 — 콤보 윈도우 검사/콤보 누적 자연 동작.
func recordToiletBonus(at now: TimeInterval) {
    recordNoteHit(at: now)
    recordNoteHit(at: now)
}
```

### 기능 7: GameScene 콜백

```swift
contactRouter.onToiletCollected = { [weak self] toilet in
    guard let self = self else { return }
    let toiletOrigin = toilet.position
    self.scoreSystem.recordToiletBonus(at: self.lastUpdateTime)
    self.haptics.medium()
    self.audio.play(.noteCollected)
    let sparkle = SparkleEffectNode()
    sparkle.position = toiletOrigin
    self.worldNode.addChild(sparkle)
    sparkle.emit()
    ToastLabelNode.spawn(text: GameConfig.toiletToastText,
                         at: toiletOrigin,
                         parent: self.worldNode)
    let gained = self.scoreSystem.combo >= GameConfig.comboBonusThreshold
        ? GameConfig.scorePerNoteCombo : GameConfig.scorePerNote
    ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x - GameConfig.toiletScorePopupFanOutX, y: toiletOrigin.y),
                         gainedPoints: gained, parent: self.worldNode)
    ScorePopupNode.spawn(at: CGPoint(x: toiletOrigin.x + GameConfig.toiletScorePopupFanOutX, y: toiletOrigin.y),
                         gainedPoints: gained, parent: self.worldNode)
    let currentCombo = self.scoreSystem.combo
    if GameConfig.comboMilestones.contains(currentCombo),
       !self.triggeredComboMilestones.contains(currentCombo) {
        self.triggeredComboMilestones.insert(currentCombo)
        self.playComboMilestoneFeedback(for: currentCombo)
        let popup = ComboPopupNode(milestone: currentCombo)
        self.cameraNode.addChild(popup)
        popup.animate()
    }
    toilet.run(.removeFromParent())
}
```

*주의*: ScorePopupNode/SparkleEffectNode/ComboPopupNode/triggeredComboMilestones/playComboMilestoneFeedback 호출 형태는 GameScene 기존 onNoteCollected 콜백 패턴을 그대로 미러. 실제 시그니처는 코드 읽고 조정.

### 기능 8: PhysicsCategory + PlayerNode

```swift
// PhysicsCategory.swift
static let bonus: UInt32 = 0b1000000  // 64

// PlayerNode.swift
body.contactTestBitMask = PhysicsCategory.note
                        | PhysicsCategory.enemy
                        | PhysicsCategory.projectile
                        | PhysicsCategory.stoneGuard
                        | PhysicsCategory.bonus    // ← 추가
```

## 매직 넘버 정책

```swift
// MARK: - Toilet Bonus (Phase 9-6)
static let toiletSize: CGFloat = 16
static let toiletSpawnInterval: TimeInterval = 12.0
static let toiletSpawnProbability: CGFloat = 0.15
static let toiletLifetime: TimeInterval = 8.0
static let toiletFadeOutDuration: TimeInterval = 0.3
static let toiletMaxConcurrent: Int = 1
static let toiletZPosition: CGFloat = 4

// MARK: - Toast Label (Phase 9-6)
static let toiletToastText: String = "화캉스 보너스!"
static let toastDuration: TimeInterval = 0.9
static let toastFontSize: CGFloat = 24
static let toastStartOffsetY: CGFloat = 16
static let toastFlyUpDistance: CGFloat = 40
static let toastStartScale: CGFloat = 0.8
static let toastEndScale: CGFloat = 1.1
static let toastZPosition: CGFloat = 50
static let toiletScorePopupFanOutX: CGFloat = 8

// ColorTokens.swift
static let ganhoToiletBowl    = UIColor(hex: "#f4f0ee")
static let ganhoToiletSeat    = UIColor(hex: "#b8b3ad")
static let ganhoToiletAccent  = UIColor(hex: "#ff8a7a")
```

## HUD/UI 연동

**HUD 신설 없음.** GDD §7-3 표에 HUD 명시 안 됨. 맵 픽셀 + 0.9초 토스트만으로 전달.

## 스폰 가능 조건

- 게임 상태 가드: SpawnSystem이 SKAction.repeatForever를 scene에 부착 → scene이 일시정지 시 SKAction 자체 멈춤 → 자연 차단.
- 단일성: `currentToiletCount() < 1` 가드.
- 스폰 위치 충돌: 음표 위치 정책 재사용 (외곽 1타일 마진 + 중앙 manhattan 3타일 회피).

## 회귀 방지

- Phase 9-1~9-5 영역 0줄: SkillSystem / normalMap / 체크보드 / HUD 4슬롯 / 캐릭터 픽셀 / breakable wall — 1줄도 안 건드림.
- SpawnSystem 시그니처(`start/stop/apply/fireImmediately`) 보존.
- ScoreSystem 시그니처(`recordNoteHit/recordCharmedNoteHit/tickComboExpiry/reset`) 보존, *추가만*.
- ContactRouter 기존 콜백 4개 시그니처 보존, *추가만*.
- PlayerNode contactTestBitMask는 OR 1개 *추가만*.
- PhysicsCategory.bonus=64는 기존 6개 카테고리와 비트 충돌 없음.

## 주의사항

- **즉시 removeFromParent 금지**: ContactRouter didBegin 진행 중 노드 제거 시 크래시 가능 → `toilet.run(.removeFromParent())` SKAction 패턴 사용.
- **weak self 캡처**: SKAction.run / onToiletCollected 클로저 모두 `[weak self]`.
- **TTL fadeOut 도중 수집**: applyLifetime의 withKey "toiletLifetime"이 자동 교체 가능. removeFromParent 두 번 실행 → node.parent == nil이면 noop 자연 멱등.
- **첫 12초 변기 0개**: SKAction.sequence([wait(12), run]) — 의도된 톤.

## 평가 가중치
- Swift 패턴 35% — guard let / weak self / GameConfig 상수화 / MARK 섹션
- 게임 로직 30% — SKAction 12초 루프 + 8초 TTL + Bernoulli + ContactRouter 분기 + ScoreSystem 응축
- 성능 & 안정성 20% — 강제 언래핑 0 / addChild 매 프레임 0 / 노드 제거 SKAction 패턴 / 빌드 클린
- 기능 완성도 15% — GDD §7-3 1:1: 12s/15%/8s/점수+2/콤보+2/"화캉스 보너스!" 0.9초

**필수 검증**:
1. ToiletNode가 PixelSpriteRenderer + PixelSprite.toiletData() + PixelPalette.toiletPalette 거쳐 생성
2. SpawnSystem.start에 1줄, stop에 1줄 추가
3. ContactRouter에 onToiletCollected + bonus 분기
4. ScoreSystem.recordToiletBonus가 recordNoteHit 2회 호출
5. ToastLabelNode가 SelfDismissingNode 채택 + 정적 spawn 팩토리
6. GameConfig 매직 넘버 0건
7. Phase 9-1~9-5 파일 0줄 수정
