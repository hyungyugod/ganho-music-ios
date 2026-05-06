# 08 · Phase 2-3 · 음표 스폰 + 충돌 *알림* + 점수 카운트

> **이번 작업의 한 줄**: 맵 위에 ♪ *음표*가 자동으로 *나타나고*, 박스가 닿으면 *사라지면서 점수가 1 오른다*.
> 비유: 빈 운동장에 색종이 조각이 1.5초마다 한 장씩 떨어지고, 학생이 밟으면 그 조각이 *사라지면서* 카드를 한 장씩 모은다.

---

## 1. 한눈 요약

```
지금 (Phase 2-2)                              이번 작업 (Phase 2-3)
┌────────────────────────┐                   ┌────────────────────────┐
│ ━━━━━━━━━━━━━━━━━━     │                   │ ━━━━━━━━━━━━━━━━━━     │
│ ┃                  ┃    │                   │ ┃    ♪    ♪        ┃    │
│ ┃    ┌──┐          ┃    │      ──→         │ ┃    ┌──┐    ♪      ┃    │
│ ┃    │██│ 기둥     ┃    │                   │ ┃    │██│           ┃    │
│ ┃    └──┘          ┃    │                   │ ┃ ♪  └──┘     ♪    ┃    │
│ ┃ [□] 박스가 부딪힘 ┃    │                   │ ┃   [□] 닿으면 ♪→0  ┃    │
│ ━━━━━━━━━━━━━━━━━━     │                   │ ━━━━━━━━━━━━━━━━━━     │
│ 빈 맵                  │                   │ 음표가 떠다님 + 수집     │
└────────────────────────┘                   └────────────────────────┘
       *공간*만 있음                                *게임이 됨*
```

**핵심 변화 세 가지**:
1. **NoteNode 신설** — 작은 분홍 사각형(♪ placeholder), PhysicsBody 부착, *통과 가능*하게 `collision=0`.
2. **음표 자동 스폰** — `SKAction.repeatForever(sequence([wait, run]))`로 1.5초마다 빈 자리에 1개. 동시에 최대 5개.
3. **충돌 *알림* (contact)** — GameScene이 `SKPhysicsContactDelegate` 채택. 박스가 ♪에 닿는 *순간* 알림 받음 → ♪ 제거 + 내부 점수 카운트 +1.

**부수 변화**: PlayerNode `contactTestBitMask`가 0 → `.note`로 갱신 (2-2 §9-3 이월). 음표 색은 1-1에서 *미리 정의해둔* `.ganhoPinkNote`가 처음으로 활성화.

> **핵심 용어 둘**: *collision*(물리적 막힘) ≠ *contact*(충돌 알림). 2-2는 collision만 켰고 2-3은 contact를 처음 켠다. 같은 SKPhysicsBody지만 다른 비트마스크.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `Nodes/NoteNode.swift` 신설 | `final class NoteNode: SKSpriteNode`. 분홍 16×16 사각형 + PhysicsBody (`isDynamic=false`, `category=.note`, `collision=0`, `contactTest=.player`) |
| `GameConfig` 상수 3개 추가 | `noteSize`, `noteSpawnInterval`, `noteMaxConcurrent` |
| `PlayerNode` `contactTestBitMask` 갱신 | `0` → `PhysicsCategory.note` (2-2 §9-3 이월) |
| `GameScene` `SKPhysicsContactDelegate` 채택 | `physicsWorld.contactDelegate = self`. `didBegin(_:)`에서 player↔note 식별 → note 제거 + score+1 |
| `GameScene.score` 변수 | `private var score: Int = 0`. *값만* 보유 — HUD 표시는 Phase 2-5 |
| `GameScene.spawnNotes()` 신설 | `setupWorld()` 끝에서 호출. SKAction loop으로 매 1.5초 시도 |

### 왜 지금?
1. **2-2에서 *물리 인프라*만 깔아둠**. PhysicsCategory 4개(player/note/enemy/wall) 중 wall만 활성. note가 *드디어* 활성화 = 1-1 자산 두 번째 활용.
2. **MVP의 절반**. Phase 1+2가 "플레이 가능 게임"인데 *수집*이 빠지면 게임이 아님. 음표 수집은 게임 정체성("음악박사")의 핵심 동사.
3. **Phase 2-5(HUD)·2-6(적) 진입 전 기반**. score 변수·contact 콜백 패턴이 깔려야 HUD 갱신·F 투사체 충돌 처리도 같은 방식으로 올라감.
4. **`.ganhoPinkNote` 토큰 활성화**. 1-1에서 정의만 해두고 5단계 sleep. 음표 도입 = 자연스러운 활성 시점.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| 점수 라벨 / 타이머 라벨 / 콤보 라벨 (HUDNode) | Phase 2-5 |
| 콤보 시스템 (3 이상 ×2) | Phase 2-5 |
| 음표 TTL (normal/hard 3.5/2.8초 만료) | 난이도 시스템과 함께 (Phase 4 대 Phase 2-5 상의) — easy는 무한이라 자연 OUT |
| 음표↔플레이어 4타일 거리 검사 (GDD §7-2) | 적이 없으므로 *현 단계 의미 없음* — Phase 2-6(수간호사 도입) 시 함께 |
| 사운드 (C장조 스케일) | Phase 6 |
| 적 NPC / F 투사체 | Phase 2-6 |
| `Systems/SpawnSystem.swift` 분리 | 후속 — 적/투사체 스폰 추가될 때 함께 (지금 분리하면 단일 호출처라 과설계) |
| 화캉스 보너스 (변기) | Phase 4 |

---

## 3. Spring 비유 🌱

### 3-1. *contact* = "이벤트 *발행*", *collision* = "비즈니스 *제약*"
| 개념 | Spring 비유 | 2-2까지 | 2-3 추가 |
|---|---|---|---|
| `collisionBitMask` | DB `FOREIGN KEY` / `CHECK` 제약 — *위반을 막음* | wall ↔ player 막힘 | (변경 없음) |
| `contactTestBitMask` | `ApplicationEvent` 발행 — 일어났음을 *알림* | 모두 0 (이벤트 미발행) | player ↔ note 알림 활성 |
| `didBegin(_:)` | `@EventListener` | 미사용 | GameScene이 청취 |

> 같은 `SKPhysicsBody`인데 **막힘**과 **알림**을 *비트마스크 두 개*로 분리한 게 핵심. Spring DDD에서 도메인 *제약*과 도메인 *이벤트*를 같은 객체가 갖되 분리해 다루는 것과 같음.

### 3-2. NoteNode = `@Entity NoteEntity`
1-3의 PlayerNode와 같은 패턴. `final class NoteNode: SKSpriteNode` + `init`에서 PhysicsBody 부착. Spring `@Entity` 한 개 추가하는 감각.

```
Player ↔ Order            (도메인의 주체)
Note   ↔ Coupon / Item    (사용자가 주워 모으는 객체)
```

NoteNode는 *상태 거의 없음*. 위치 + 시각만. Java로 치면 *anemic value object*에 가까움. 향후 TTL 도입 시 `spawnedAt: TimeInterval` 같은 자체 상태가 붙으면 *rich domain*화.

### 3-3. `SKAction.repeatForever(sequence([wait, run]))` = `@Scheduled(fixedRate=1500)`
Spring `@Scheduled(fixedRate = 1500)` 메서드 = 1.5초마다 실행. SpriteKit 정석은 `Timer` 금지 + SKAction:

```swift
let wait  = SKAction.wait(forDuration: 1.5)
let spawn = SKAction.run { [weak self] in self?.trySpawnNote() }
run(SKAction.repeatForever(.sequence([wait, spawn])))
```

차이: `@Scheduled`는 컨테이너가 호출, SKAction은 *씬*이 호출. 둘 다 *시간 기반 트리거*인데 호스트만 다름.

### 3-4. score 변수 = "*값만* 가진 in-memory state"
```swift
private var score: Int = 0
```
HUD 라벨은 별개 → `score` 갱신과 *표시*가 분리. Spring으로 치면 `@Service` 안의 `private long counter` — `@RestController`(HUD)가 노출하는 건 *별 책임*. 본 sub-feature에선 controller 없이 service만.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKPhysicsContactDelegate` 채택 + `didBegin(_:)`
```swift
class GameScene: SKScene, SKPhysicsContactDelegate {
    override func didMove(to view: SKView) {
        // ...
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self   // ⭐ 한 줄로 알림 수신
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // 두 body 중 어느 쪽이 note인지 비트마스크로 식별
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let noteBody: SKPhysicsBody?
        if bodyA.categoryBitMask == PhysicsCategory.note { noteBody = bodyA }
        else if bodyB.categoryBitMask == PhysicsCategory.note { noteBody = bodyB }
        else { noteBody = nil }
        guard let noteNode = noteBody?.node else { return }

        score += 1
        noteNode.run(.removeFromParent())   // ⭐ 즉시가 아닌 *다음 프레임* 안전 제거
    }
}
```

**왜 `run(.removeFromParent())`?** `didBegin` 안에서 즉시 `removeFromParent()`도 동작은 하지만, *물리 시뮬레이션 루프 도중*이라 같은 프레임 다른 콜백에서 *해체된 노드*를 참조할 수 있음. SKAction에 위임하면 프레임 종료 후 정리 → 안전. components.md SpriteKit 체크리스트의 "충돌 처리 후 노드 즉시 삭제 금지"와 일치.

### 4-2. `category` / `collision` / `contactTest` *재정리*
2-2에서 봤지만 이번에 *모두* 의미 있게 사용:

| 비트마스크 | player | note(이번) | wall(2-2) |
|---|---|---|---|
| `categoryBitMask` | `.player` | `.note` | `.wall` |
| `collisionBitMask` | `.wall` (벽 막힘) | `0` (player 통과) | `0` (static, 안 움직임) |
| `contactTestBitMask` | `.note` ⭐ (2-3 갱신) | `.player` ⭐ (신설) | `0` |

**핵심**: note는 `collision=0`이라 박스를 *막지 않음*. 그러나 `contactTest=.player`라 *접촉 알림*은 발생. 박스가 음표를 *통과하면서* 콜백이 한 번 발생 → 그때 노드 제거.

> **함정**: `contactTest`는 *대칭*이라 한쪽만 설정해도 콜백 1회. 양쪽 다 설정해도 콜백은 여전히 1회 (OR 조건). 본 작업은 *의미 명확화*를 위해 양쪽 다.

### 4-3. `enumerateChildNodes(withName:using:)`로 현재 음표 수 세기
```swift
private func currentNoteCount() -> Int {
    var count = 0
    worldNode.enumerateChildNodes(withName: "note") { _, _ in count += 1 }
    return count
}
```

**왜 이렇게?** `worldNode.children.compactMap { $0 as? NoteNode }.count`도 가능하지만 *이름 검색*이 SpriteKit 정석. 노드 이름은 `NoteNode.init`에서 `name = "note"`로 부여.

**Spring 비유**: `@Repository`의 `findAllByType("note").size()` 호출 — 메모리 인덱스 조회.

### 4-4. `CGFloat.random(in:)`으로 균등 분포 위치
```swift
let x = CGFloat.random(in: GameConfig.tileSize ... GameConfig.mapWidth  - GameConfig.tileSize)
let y = CGFloat.random(in: GameConfig.tileSize ... GameConfig.mapHeight - GameConfig.tileSize)
```

**왜 마진 1tile?** 외곽 벽은 맵 *바깥쪽* 1tile에 있지만, 음표가 벽에 *너무 가까이* 박히면 시각적으로 어색. 안전 마진 1tile.

**중앙 기둥 회피**: 기둥 영역(40×80) 안에 음표가 생기면 박스가 절대 못 닿음 → 시각 검사 한 번 + 재추첨 또는 영역 밖으로 강제. 본 작업은 *간단한 거리 검사 후 skip*: 기둥 중심에서 manhattan 거리 < 60pt면 이번 시도 포기 (다음 1.5초에 다시).

> **함정**: `Int.random(in:)`은 정수, `CGFloat.random(in:)`은 부동소수. 음표는 픽셀 단위로 떨릴 필요 없으므로 `CGFloat.random`로 OK. 추후 타일 격자 정렬 원하면 `Int.random` + `tileSize` 곱.

### 4-5. `SKAction.repeatForever(sequence([wait, run]))` 패턴
```swift
private func startSpawnLoop() {
    let wait  = SKAction.wait(forDuration: GameConfig.noteSpawnInterval)
    let spawn = SKAction.run { [weak self] in self?.trySpawnNote() }
    let loop  = SKAction.repeatForever(.sequence([wait, spawn]))
    run(loop, withKey: "spawnNotes")
}
```

**왜 `[weak self]`?** SKAction 클로저가 GameScene을 *강하게 참조*하면 씬 종료 시 메모리 누수. weak 캡처가 정석. swift-rules.md 준수.

**왜 `withKey:`?** 후속 Phase에서 게임 종료 시 `removeAction(forKey: "spawnNotes")`로 정확히 멈출 수 있게. 키 없으면 모든 액션 일괄 정지밖에 못 함.

**왜 `Timer` 금지?** `Timer`는 *Foundation 시간*, SKAction은 *씬 시간*. 일시정지/시간배율 시 SKAction은 자동 동기, Timer는 별개 흐름 → 게임 일시정지 시 음표가 *계속 스폰*되는 버그. components.md "Timer 금지" 룰의 이유.

### 4-6. `init` 안 PhysicsBody 부착 (NoteNode)
```swift
final class NoteNode: SKSpriteNode {
    init() {
        let size = CGSize(width: GameConfig.noteSize, height: GameConfig.noteSize)
        super.init(texture: nil, color: .ganhoPinkNote, size: size)
        name = "note"

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic           = false   // 안 움직임 (player가 통과)
        body.categoryBitMask     = PhysicsCategory.note
        body.collisionBitMask    = 0       // *막지 않음* — player 통과
        body.contactTestBitMask  = PhysicsCategory.player   // 알림은 받음
        physicsBody = body
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
```

PlayerNode(2-2)와 같은 골격 + 비트마스크만 다름. Swift `final class` + `super.init(texture:color:size:)` designated init 패턴.

**왜 `isDynamic=false`?** 음표가 *밀려나면 안 됨* (수집 위치가 *예측 가능*해야 게임성). dynamic이면 박스에 부딪혀 살짝 움직임. static이 맞음.

### 4-7. 점수 *값* 와 점수 *표시* 분리
```swift
// GameScene
private var score: Int = 0   // 본 sub-feature

// (HUD는 Phase 2-5에서 별도 노드로)
```

**왜 분리?** 한 sub-feature가 *너무 큰 책임*을 지면 회귀 테스트 어려움. Phase 2-5에서 ScoreLabel을 추가할 때 GameScene의 `score`만 바인딩하면 됨. SRP.

**Spring 비유**: `@Service ScoreService.increment()` (지금) → Phase 2-5에서 `@RestController ScoreController.get()` 추가 (나중). Service 먼저 검증되면 Controller는 단순 노출.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
| 파일 | 내용 |
|---|---|
| `Nodes/NoteNode.swift` | `final class NoteNode: SKSpriteNode` + PhysicsBody (~25 LOC) |

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | 상수 3개 추가: `noteSize`(16), `noteSpawnInterval`(1.5), `noteMaxConcurrent`(5) |
| `Nodes/PlayerNode.swift` | `contactTestBitMask = 0` → `PhysicsCategory.note` (1줄) |
| `GanhoMusic Shared/GameScene.swift` | (1) `SKPhysicsContactDelegate` 채택, (2) `physicsWorld.contactDelegate = self` (`didMove` 추가), (3) `didBegin(_:)` 신설, (4) `private var score`, (5) `spawnNotes()` + `trySpawnNote()` + `currentNoteCount()` + `randomNotePosition()` 4 헬퍼, (6) `setupWorld()` 끝에서 `startSpawnLoop()` 호출 |

### 절대 손대지 않는 파일
- `Nodes/DPadNode.swift` (0바이트)
- `Config/PhysicsCategory.swift`, `GameState.swift`, `ColorTokens.swift` (0바이트 — `.ganhoPinkNote`가 *드디어 활성화*되지만 정의 자체는 1-1 그대로)
- `iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` (0바이트)
- `project.pbxproj` (0바이트 — `PBXFileSystemSynchronizedRootGroup` auto-sync로 새 파일 자동 등록, 1-1/1-3 패턴 그대로)

### Xcode 멤버십
**필요 없음.** 프로젝트가 `PBXFileSystemSynchronizedRootGroup` 모드라 `Nodes/NoteNode.swift`는 *디스크에 저장만 하면* 빌드에 자동 포함.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `class NoteNode` 정의 1건
- `SKPhysicsContactDelegate` 채택 1건
- `physicsWorld.contactDelegate = self` 1건
- `didBegin(_:)` 정의 1건
- `PhysicsCategory.note` 등장 ≥ 3건 (NoteNode init / PlayerNode contactTest / didBegin 식별)
- `SKAction.repeatForever` 1건
- `Timer` / `print()` / `as!` / `fileprivate` / 강제 언래핑 `!` 0건 (`fatalError`/네임드 옵셔널 캐스트 면제)
- `update(deltaTime:)` 안 `addChild()` 0건 (셋업/스폰 콜백만)
- 매직 넘버 0건 — 16/1.5/5는 모두 GameConfig

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 시작 직후 1.5초 안에 **분홍 사각형 1개** 맵 어딘가에 등장
- (b) 시간이 지나면 점점 **최대 5개**까지 동시에 떠 있음 (그 이상은 안 늘어남)
- (c) 박스가 음표에 닿으면 **음표가 사라짐** (박스는 멈추지 않고 그대로 통과)
- (d) 음표는 **중앙 기둥 안**에 생기지 않음 (코너 한쪽이 슬쩍 걸치는 정도는 OK — manhattan 거리 검사라 직사각형 정확도는 아님)
- (e) 음표는 **외곽 벽 안쪽 1tile 마진** 안에서만 생김
- (f) 박스/벽/기둥/카메라 follow 모두 2-2 그대로
- (g) D-Pad 우하단 작동 그대로

> **점수는 시각으론 검증 안 됨** — Phase 2-5에서 라벨 도입 시 *간접 검증*. 본 작업은 `print` 금지라 콘솔 확인도 OUT. `score` 정합성은 코드 리뷰로만.

### 6-3. 회귀 (1-5 + 2-1 + 2-2 + 핫픽스)
- 외곽 벽 4개 + 중앙 기둥 1개 시각/충돌 그대로 (2-1/2-2)
- 박스가 외곽 벽/기둥에 *부딪힘*은 그대로 (collision)
- D-Pad 우하단, alpha 0.3 그대로 (1-3)
- 카메라 드론 follow 그대로 (1-5)
- `physicsWorld.gravity = .zero` 그대로 (2-2)
- 0바이트 회귀 파일들 그대로

---

## 7. 사용자 결정 필요 사항

### 결정 ① · 음표 색
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `.ganhoPinkNote`** ⭐ | 1-1에 *이미 정의된* 토큰. assets.md §1 팔레트의 "음표 본체 ♪" 색. | ⭐ — 1-1 자산 *드디어* 활성화 |
| B. 다른 색 | ColorTokens 변경/신설 필요 | 회귀 (1-1 자산 변경) |

**왜 A?** 1-1에서 *바로 이 순간을 위해* 정의해둔 토큰. 사용처 0 → 1로 가는 자연스러운 전환. 색 결정 비용 0.

### 결정 ② · 음표 시각 형태
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 색깔 사각형 (16×16)** ⭐ | GDD §18 MVP "스프라이트 색깔 사각형으로 대체" 정책 그대로. PlayerNode/벽과 일관 | ⭐ — MVP 정책 + 일관성 |
| B. `SKLabelNode` 텍스트 ♪ | 시각이 *게임답긴* 함. 글꼴/크기 조정 필요. *경계 박스*가 글자 영역과 어긋나 충돌 어색 가능 | 시각 폴리싱은 Phase 6 |
| C. 아이콘 이미지 | Assets.xcassets에 PNG 추가 필요. MVP 단계 과설계 | OUT |

**왜 A?** 모든 게임 오브젝트(player/벽/기둥/음표)가 *같은 추상화 단계*(색깔 사각형)에 있어야 회귀가 단순. ♪ 시각 폴리싱은 Phase 6에서 한꺼번에.

### 결정 ③ · 스폰 시스템 위치 (파일 분리 vs 인라인)
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. GameScene 안 4 헬퍼** ⭐ | `spawnNotes`/`trySpawnNote`/`currentNoteCount`/`randomNotePosition`. 외부 의존 0 | ⭐ — 1 SPEC = 1 sub-feature |
| B. `Systems/SpawnSystem.swift` 분리 | 1-1 스타일 새 폴더 진입 + pbxproj sync. 호출처 1개라 과설계 | 적/투사체 추가될 때 함께 |

**왜 A?** Systems/ 폴더 분리는 *2개 이상 호출처*가 생길 때 가치. 지금은 음표 한 종류만. Phase 2-6(적·투사체) 도입 시점에 묶어 분리.

### 결정 ④ · 동시 음표 최대 수 + 스폰 주기
| 옵션 | 값 | 추천 |
|---|---|---|
| **A. GDD easy 명세** ⭐ | `noteMaxConcurrent=5`, `noteSpawnInterval=1.5` | ⭐ — GDD 명세 따름 |
| B. 다른 값 | 사용자 디자인 | GDD 갱신 부담 |

**왜 A?** GDD §5 easy 동시 음표=5. 스폰 주기는 GDD에 명시 없으나 *45초/5음표*면 *균형*있는 1.5초. 추후 난이도별 조정.

### 결정 ⑤ · 음표 위치 정책
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 균등 랜덤 + 기둥 manhattan 회피 + 외곽 1tile 마진** ⭐ | 단순. 적이 없는 단계라 충분 | ⭐ — 사실상 GDD §7-2의 *현 단계 가능 부분만* |
| B. GDD §7-2 그대로 (player/적 4타일 회피) | 적이 없으므로 player 거리만 — 시작 직후 박스가 정중앙이라 음표가 항상 외곽에만 → 어색 | OUT |
| C. 타일 격자 강제 정렬 | 시각 OK. 산수 한 단계 추가 | Phase 6 |

**왜 A?** 적이 없는 *현 단계*에 GDD §7-2를 부분 적용하면 의미 흐림. 거리 검사는 Phase 2-6(적 도입)과 함께. 본 작업은 *기둥 안에만 안 생기게*가 충분.

### 결정 ⑥ · 점수 변수 vs 시스템 분리
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. GameScene `private var score: Int = 0`** ⭐ | 한 변수 + `score += 1` 한 줄. 콤보 없는 단계라 단순 | ⭐ — 콤보·HUD와 함께 분리 |
| B. `Systems/ScoreSystem.swift` 분리 | 콤보 없는 단계라 호출 1줄 vs 새 파일 = 과설계 | Phase 2-5 |

**왜 A?** 점수는 *콤보·라벨*과 한 묶음. 콤보 도입(Phase 2-5) 시 같이 분리하면 자연스러움.

### 결정 ⑦ · 충돌 시 노드 제거 방식
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `note.run(.removeFromParent())`** ⭐ | 다음 프레임 정리. SpriteKit 안전 패턴 | ⭐ — components.md 체크리스트 일치 |
| B. `note.removeFromParent()` 즉시 | 같은 프레임 내 다른 콜백 위험 | 함정 가능성 |

**왜 A?** components.md "충돌 처리 후 노드 즉시 삭제 금지" 일치. SKAction이 *자동으로* 다음 프레임에 정리.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 + 비주얼 (음표 스폰 + 충돌 *알림* + 점수 카운트)
- **게임 경험 의도**:
  > "맵 위에 분홍 음표가 1.5초마다 한 개씩, 최대 5개까지 떠다닌다. 박스가 닿으면 음표가 사라진다(점수는 아직 *내부에서만* 카운트, HUD 표시는 다음 phase). 1-1에서 정의해둔 PhysicsCategory.note와 .ganhoPinkNote가 처음으로 활성화된다. 박스는 음표를 통과하지만 알림은 받는다 — collision과 contact가 분리되는 첫 사례."
- **Sprint 범위 계약**:
  - **IN**: NoteNode 신설(`Nodes/NoteNode.swift`). PlayerNode `contactTestBitMask` 갱신. GameScene `SKPhysicsContactDelegate` 채택 + `didBegin` + `score` + `spawnNotes` 4 헬퍼. GameConfig 상수 3개 추가. 총 **신설 1 파일 + 수정 3 파일**.
  - **OUT**: HUD/라벨/콤보/사운드/적/투사체/TTL/4타일 거리/`Systems/SpawnSystem.swift` 분리/화캉스 보너스/`Score` 값객체.
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / `Foundation Timer` / `DispatchQueue.main.asyncAfter` 0건
  - `update()` 안 `addChild()` 0건 (스폰은 SKAction 콜백 내부)
  - 매직 넘버 0건 — 16/1.5/5 모두 GameConfig 상수
  - 음표 동시 최대 5 *준수* — `currentNoteCount() >= noteMaxConcurrent`이면 skip
  - 음표는 기둥 manhattan 60pt 안에 생기면 skip
  - 음표는 외곽 1tile 마진 안에서만 생성
  - SKAction 클로저 `[weak self]` 캡처
  - 노드 제거는 `run(.removeFromParent())` (즉시 호출 금지)
  - SKAction에 `withKey: "spawnNotes"` 명시
- **회귀 보존 (1-5 + 2-1 + 2-2 + 핫픽스)**:
  - DPadNode / Config 3 파일 (PhysicsCategory/GameState/ColorTokens) / iOS 3 파일 / pbxproj 모두 0바이트
  - 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
  - 1-5 카메라 drone follow 그대로
  - 2-1 외곽 벽 4개 그대로
  - 2-2 중앙 기둥 + `physicsWorld.gravity = .zero` 그대로
  - PlayerNode `init` 본문은 *contactTestBitMask 한 줄* 외 변경 0

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**`PBXFileSystemSynchronizedRootGroup` 가정 부분 오해.** SPEC §주의사항에서 "디스크 저장만으로 빌드 자동 포함"으로 단정했는데, 실제 프로젝트는 *하이브리드* — `Nodes/` 그룹은 자동 동기화되어 있어도 iOS 타겟의 `PBXSourcesBuildPhase.files` 배열에 명시 등록이 함께 필요한 구조. Generator가 NoteNode를 디스크에 저장만 하면 빌드가 *cannot find 'NoteNode' in scope* 에러를 뱉었고, 결국 `project.pbxproj`에 PBXBuildFile/PBXFileReference/Sources files 3쌍을 추가해 빌드를 통과시켰음.

> **Evaluator 평가 결과**: 23줄 추가 중 NoteNode 3줄이 *진짜 필수*, 나머지 20줄(PlayerNode·DPadNode 중복 등록 + 새 `Nodes` PBXGroup 11줄)은 *과변경*으로 P1 감점. 빌드 영향은 없으나 *최소 변경 원칙* 위반. 다음 sprint 진입 시 SPEC §"Xcode 멤버십" 항목을 *시도 후 fallback* 형태로 명시할 것 — "디스크 저장 후 빌드 시도 → 실패 시 PBXBuildFile + PBXFileReference + Sources files 3줄만 추가".

> **인사이트**: 1-1과 1-3에서 PlayerNode/DPadNode가 *디스크 저장만으로* 빌드된 줄 알았는데, 실제로는 그때도 pbxproj에 명시 등록이 들어가 있었던 것. 이 사실을 SPEC에 *처음부터* 반영했어야 함. 학습 노트 §4 "Xcode 멤버십" 서술 갱신 필요 (다음 학습 노트의 회귀 보존 목록 작성 시 참고).

### 9-2. Spring과 다르네 싶었던 것
1. **collision = "DB CHECK 제약", contact = "ApplicationEvent"**: 같은 SKPhysicsBody에 *두 종류 비트마스크*가 공존. Spring DDD에서 도메인 *불변식*과 도메인 *이벤트*를 같은 엔티티가 갖되 분리 처리하는 것과 정확히 같은 구조. PlayerNode는 "wall에 막힘"(collision)과 "note 닿음 알림"(contact)을 *동시에* 가짐.
2. **`SKPhysicsContactDelegate`는 채택만 하면 되는 *옵셔널 프로토콜***: `didBegin(_:)`을 구현 안 해도 컴파일 에러 없음. Java `interface` 강제 구현과 다름. `func didBegin` 시그니처가 정확해야 함 (`_` 라벨 누락 시 호출 안 됨).
3. **`note.run(.removeFromParent())` = "다음 프레임 정리 큐"**: 즉시 호출(`note.removeFromParent()`)도 동작하나 *같은 프레임 다른 콜백*이 해체된 노드 참조 가능성. SKAction이 *프레임 종료 후* 정리 → 안전. Spring `@Async`로 후처리 큐에 넘기는 패턴과 비슷.
4. **`run` 메서드명 vs 지역 변수 모호성**: `let run = SKAction.run { ... }` 후 `self.run(loop)`이 *모호 충돌* 가능. Java에선 `Runnable.run()`과 변수명 `run` 충돌 시 `this.run()` 명시로 해결되는데, Swift도 같은 패턴 + *지역 변수명을 다르게* (`spawn`)이 더 깨끗함. **이름이 메서드와 충돌하면 변수 쪽을 양보**.
5. **`enumerateChildNodes(withName:using:)` = "메모리 인덱스 조회"**: 자식 노드를 이름 키로 검색. Java로 치면 `@Repository.findAllByName("note")`. SpriteKit이 내부적으로 이름 인덱스를 보유하는지 여부와 무관하게 *순회*는 보장. 5개 음표 정도는 비용 무시.
6. **`CGFloat.random(in: a...b)` 균등 분포**: `Random` 인스턴스 생성 없이 *정적 메서드*로 즉시 호출. Java `ThreadLocalRandom.current().nextDouble(a, b)`보다 짧음. 인스턴스 시드 필요 시 별도 API.
7. **`final class NoteNode: SKSpriteNode` + `super.init(texture:color:size:)`**: `final`로 상속 차단(런타임 dispatch 비용 감소). Spring `final class @Component`도 같은 정책. designated init 호출 후 `name`, PhysicsBody 부착이 자연스러운 순서.
8. **PhysicsBody `isDynamic = false`의 의미**: 음표가 *밀리지 않음*. 박스가 빠르게 통과해도 음표 위치 고정. Spring `@Immutable @Entity` 어노테이션 비슷 — *값은 고정, 반응만*. 게임에선 시각적으로 매우 중요(수집 위치 예측 가능성).

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-4/2-5/2-6 진입 시)
1. **HUD 라벨 (Phase 2-5)**: `score` 변수가 *내부 카운트만* 됨. SKLabelNode를 cameraNode 자식으로 추가하면 *항상 화면 고정* + 카메라 좌표계. 점수 변경 시 라벨 갱신 — 옵저버 패턴(KVO) 또는 단순 `didSet` 또는 매 프레임 read 중 선택 결정 필요.
2. **콤보 시스템 (Phase 2-5)**: GDD §8 "마지막 수집 후 2.5초 이내 재수집 안 하면 초기화". `lastCollectAt: TimeInterval?` 변수 + `update(_:)`에서 시간 체크. 콤보 3+ 시 점수 ×2.
3. **음표 사운드 (Phase 6)**: GDD §15 콤보 단계별 음계(C4→D4→…→A5). `AVAudioEngine` 또는 `SKAction.playSoundFileNamed`. 즉발 사운드라 후자가 단순.
4. **45초 타이머 (Phase 2-5)**: `gameDuration: 45` (이미 GameConfig에 있음). `SKAction.sequence([wait(45), run { gameOver() }])`. gameState `.playing` → `.over` 전환.
5. **적 NPC + F 투사체 (Phase 2-6)**: 수간호사. PhysicsCategory.enemy + EnemyNode. F 투사체는 ProjectileNode + contactTestBitMask=.player. 동일한 `didBegin` 패턴이지만 카테고리 식별 if/else가 *3가지*로 분기 → switch 또는 분리 함수 검토.
6. **`Systems/SpawnSystem.swift` 분리 시점**: 적/투사체 스폰까지 추가되면 GameScene이 비대해짐. Phase 2-6 진입 시 동시 분리 권장. 현재 `startSpawnLoop`/`trySpawnNote`/`currentNoteCount`/`randomNotePosition` 4 헬퍼는 SpawnSystem으로 이주 가능한 그대로.
7. **음표↔플레이어 4타일 거리 검사 (GDD §7-2)**: 적이 도입되는 Phase 2-6에서 함께 적용. 적의 위치도 manhattan 4tile 이상 떨어진 빈 자리에만 음표 스폰. 현재 기둥 회피 로직(`< tileSize * 3`) 위치에 추가.
8. **음표 TTL (Phase 4 난이도 시스템)**: easy=무한이라 현재 OUT. normal/hard에서 3.5/2.8초 만료 도입 시 `NoteNode.spawnedAt: TimeInterval` + `update`에서 만료 처리. 또는 SKAction.wait → removeFromParent 패턴.
9. **`PhysicsCategory.enemy` 활성화**: 1-1에서 정의만 해두고 5단계 sleep. Phase 2-6에서 깨어남.
10. **SPEC §Xcode 멤버십 표현 갱신**: "디스크 저장만으로 빌드 자동 포함" → "디스크 저장 후 빌드 시도. 실패 시 pbxproj에 PBXBuildFile/PBXFileReference/Sources files 3줄(파일당) 추가" — 다음 sprint부터.
11. **pbxproj 변경 회귀 보존 정책**: "0바이트 변경"이 아니라 "*추가만, 그것도 새 파일 등록 3줄만*" 으로 룰 조정. 삭제 0건 / 기존 등록 변경 0건 / 추가는 새 파일별 3쌍만.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.0 / 10** — `final` / `private` / MARK / `[weak self]` / `guard` / 옵셔널 캐스트 0건 모두 정석. -1.0은 SELF_CHECK pbxproj 보고 정확도(4줄 vs 23줄) — 보고서가 실제와 일치하지 않은 P1 감점
- 게임 로직 (30%): **9.5 / 10** — SPEC §기능 1~6 1바이트 일치. collision↔contact 분리, score 가산, 노드 SKAction 위임 제거 모두 정확
- 성능 (20%): **9.5 / 10** — `update()` 안 노드 생성 0건, `[weak self]` 캡처, `enumerateChildNodes` 호출 1.5초 1회. 빌드 클린 / 경고 0
- 기능 완성도 (15%): **8.5 / 10** — `BUILD SUCCEEDED`, P0 위반 0. -1.5는 pbxproj 23줄 추가 중 NoteNode 3줄 외 *과변경* (PlayerNode/DPadNode 중복 등록 + Nodes PBXGroup) — 빌드 영향은 없으나 최소 변경 원칙 위반
- **가중평균: 9.18 / 10 — 합격** (1회차에 통과, 임계 8.0)

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 7가지:
- (a) 시작 직후 1.5초 안에 분홍 사각형 1개 등장
- (b) 시간 지나면 동시에 최대 5개. 그 이상 안 늘어남
- (c) 박스가 음표에 닿으면 음표 사라짐 (박스는 통과)
- (d) 음표가 중앙 기둥 *안쪽*에 생기지 않음
- (e) 음표가 외곽 벽 안쪽 1tile 마진 안에서만 생김
- (f) 박스/벽/기둥/카메라 follow는 2-2 그대로
- (g) D-Pad 우하단, 작동, 반투명 그대로

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 7건 사용자 OK (모두 추천대로 가는지)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → NoteNode 신설 + PlayerNode/GameScene/GameConfig 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-4(?) 또는 2-5(HUD) 또는 2-6(적)으로
```

> **2-3 본질**: 게임이 *공간*에서 *게임*이 되는 순간. collision(2-2)과 contact(2-3)가 분리되는 첫 사례 = 향후 모든 충돌 패턴의 토대.
