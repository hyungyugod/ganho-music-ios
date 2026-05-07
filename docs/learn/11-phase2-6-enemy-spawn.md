# 11 · Phase 2-6 · 수간호사 적 NPC + 추적 AI + 접촉 시 게임오버

> **이번 작업의 한 줄**: 빨간 박스(수간호사)가 한 마리 등장해서 *플레이어를 직선 추적*한다. 닿으면 *즉시 게임오버*.
> 비유: 술래잡기. 술래가 정확히 *나를 향해* 직선으로 다가옴. 잡히면 끝. 음표 모으는 *동기*가 *시간*에서 *위협*으로 진화.

---

## 1. 한눈 요약

```
지금 (Phase 2-5)                          이번 작업 (Phase 2-6)
┌────────────────────────┐                ┌────────────────────────┐
│ 🎵 5  ⏱ 00:30  🔥 4   │                │ 🎵 5  ⏱ 00:30  🔥 4   │
│ ━━━━━━━━━━━━━━━━━━     │                │ ━━━━━━━━━━━━━━━━━━     │
│ ┃ 👵?     ♪      ┃    │                │ ┃ 👵→         ♪   ┃   │ ← 적이 player 방향
│ ┃   │██│   ♪    ┃    │      ──→       │ ┃    │██│   ♪    ┃    │
│ ┃ [□] 모으기    ┃    │                │ ┃ [□]닿으면 GAME ┃    │ ← 접촉=게임오버
│ ━━━━━━━━━━━━━━━━━━     │                │ ━━━━━━━━━━━━━━━━━━     │
│ 종료 사유: 시간만        │                │ 종료 사유: 시간 OR 피격 │
└────────────────────────┘                └────────────────────────┘
       *속편한 수집*                           *위협 압박*
```

**핵심 변화 세 가지**:
1. **EnemyNode 신설** — 16×20 빨간 박스(crimsonNurse). PhysicsBody dynamic, 벽에 막힘(collisionBitMask=.wall), player와 contact 알림 발생.
2. **추적 AI** — `update(_:)`에서 매 프레임 `player.position - enemy.position`을 정규화 + `enemyBaseSpeed` 곱하기 → velocity로 전달. GDD §7-4 "직선 추적" 정확 일치.
3. **didBegin 분기 확장** — 현재 player↔note만 처리. enemy 접촉 추가 → `endGame()` 호출. 분기 패턴은 if/else if 사슬 그대로 확장 (switch는 OUT).

**부수 변화**: PlayerNode `contactTestBitMask`가 `.note` → `.note | .enemy`로 1자리 확장. `endGame()` 안 enemy.velocity = .zero 1줄 추가. ColorTokens에 `.ganhoCrimsonNurse` 신규 토큰 1개.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `Nodes/EnemyNode.swift` 신설 | PlayerNode 패턴 그대로. SKSpriteNode 16×20, dynamic body, collide=.wall, contactTest=.player. `update(deltaTime:targetPosition:)` 메서드로 추적 |
| `Config/GameConfig.swift` 상수 3개 추가 | `enemyBaseSpeed=60`, `enemyWidth=16`, `enemyHeight=20`. 새 MARK `// MARK: - Enemy (Phase 2-6)` |
| `Config/ColorTokens.swift` 토큰 1개 추가 | `.ganhoCrimsonNurse` — assets.md §1 `crimsonNurse #A4243B` 토큰을 코드에 진입 |
| `Nodes/PlayerNode.swift` 1줄 수정 | `contactTestBitMask = .note` → `.note \| .enemy` |
| `GanhoMusic Shared/GameScene.swift` | (1) `private let enemy = EnemyNode()` 추가, (2) `setupEnemy()` 신설 — 맵 좌상단 1tile 안쪽 배치, (3) `update(_:)`에 enemy.update(dt, targetPosition: player.position) 추가, (4) `didBegin`에 enemy 접촉 분기 추가 → `endGame()`, (5) `endGame()`에 enemy.velocity = .zero 추가 |

### 왜 지금?
1. **2-5에서 *콤보 보상*이 정착**. 이제 *위험*이 들어와야 *연속 압박이 진짜 압박*이 됨. 콤보가 ×2 보너스를 주는 만큼 "지금 빨리 모아야 한다"는 동기가 *적의 추적*과 만나야 의미가 살아남.
2. **회피 게임의 본질이 *첫 추적자 진입*으로 즉시 살아남**. F 투사체(2-7)가 들어오기 전에도 "수간호사가 다가온다 → 동선 짜야 한다"는 *공간 사고*가 발생.
3. **단일 EnemyNode 1마리만**. 스폰 루프 0개, 발사 로직 0개. *추적 AI 한 가지*에 집중 → SPEC 작게 유지. F 투사체는 2-7로 분리.
4. **endGame 진입 사유 *2개*로 자연스럽게 확장**. 시간 만료(현행) + 적 피격(신규). 사유별 메시지 분기는 Phase 3 게임오버 화면에서. 본 sprint는 *진입 트리거*만 추가.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| F 투사체 (ProjectileNode) | Phase 2-7 |
| 적 속도 시간 보간 (60 → 110) | Phase 2-8 |
| 적 사운드 / 시각 펄스 | Phase 6 |
| 적 다수 (2 마리 이상) | Phase 4 (석조무사·이교수 등장 시) |
| 게임오버 화면 / 사유 라벨 | Phase 3 |
| 무적 시간 / 피격 후 부활 | Phase 5 (스킬 시스템과 함께) |
| 추적 경로 회피(A* 등) | OUT — GDD §7-4가 "직선 추적" 명시 |
| 적 ↔ 음표 충돌 (적이 음표 막음) | OUT — note의 collisionBitMask=0 그대로 |

---

## 3. Spring 비유 🌱

### 3-1. 추적 AI = "@Scheduled로 매 tick마다 target을 polling"
| 개념 | Spring/Reactive | 본 작업 |
|---|---|---|
| 주기 | `@Scheduled(fixedRate=16)` | `update(_:)` 60Hz |
| 관찰 대상 | `targetService.getPosition()` | `player.position` |
| 자기 상태 갱신 | `this.velocity = ...` | `enemy.physicsBody.velocity = ...` |
| 종료 트리거 | `if (collision) eventBus.emit(end)` | `didBegin → endGame()` |

Spring으로 치면: 매 16ms마다 `@Scheduled` 작업이 *target 서비스의 현재 위치*를 polling → 단위 벡터 계산 → 자기 velocity 갱신. **관측·계산·반영의 3단계가 단일 thread 위에서 순서 보장**되는 패턴 (Spring `@Scheduled`도 동일 — 한 작업 끝나야 다음 작업).

### 3-2. didBegin 분기 = "GlobalExceptionHandler의 type별 분기"
```swift
// 현재 (2-5)
if bodyA.categoryBitMask == .note { /* 점수/콤보 */ }
else if bodyB.categoryBitMask == .note { /* 점수/콤보 */ }

// 확장 (2-6)
if bodyA.categoryBitMask == .note || bodyB.categoryBitMask == .note { /* 점수/콤보 */ }
else if bodyA.categoryBitMask == .enemy || bodyB.categoryBitMask == .enemy { /* endGame */ }
```
Spring으로 치면 `@RestControllerAdvice`의 `@ExceptionHandler` 사슬:
```java
@ExceptionHandler(NoteException.class)   // → 점수 갱신
@ExceptionHandler(EnemyException.class)  // → 게임 종료
```
**한 종류씩 별도 메서드로 등록 vs if/else 사슬**: Spring은 컴파일 타임에 dispatch 테이블 구축, SpriteKit didBegin은 단일 함수 안에서 분기. 분기 수가 *2~3개*면 if/else가 *충분*. *5개 이상*이면 함수 분리 검토 — 본 sprint는 2분기라 if/else 그대로 확장이 가장 깔끔.

### 3-3. EnemyNode = "Service 클래스, 의존성을 메서드 인자로 주입"
```swift
// EnemyNode.swift
func update(deltaTime: TimeInterval, targetPosition: CGPoint) { ... }
```
Spring으로 치면:
```java
@Service
class EnemyService {
    void update(double dt, Position target) { ... }
}
```
**왜 인자 주입?** EnemyNode가 *player 인스턴스 자체를 멤버로 보유*하면 PlayerNode 의존성이 강하게 묶임. *position 값만* 넘기면 "추적 대상이 무엇이든 OK" — 추후 다중 적이 같은 EnemyNode 클래스를 공유할 때 유연성. **의존성 역전 원칙(DIP)의 가장 가벼운 형태** — 인터페이스 추출까지는 안 가도, *값으로 전달*하기만 해도 결합도 ↓.

> **함정 피하기**: GameScene이 *enemy.update(dt, targetPosition: player.position)* 호출 — *player 직접 참조는 GameScene만*. 추후 EnemyNode가 늘어나도 GameScene이 한 자리에서 통제 (Spring 비유: `@Service`들 사이 직접 호출 금지, `@Controller`가 orchestrate).

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `CGVector` 정규화 — magnitude 0 가드
```swift
let dx = targetPosition.x - position.x
let dy = targetPosition.y - position.y
let magnitude = hypot(dx, dy)   // sqrt(dx*dx + dy*dy)
guard magnitude > 0 else {
    physicsBody?.velocity = .zero   // 같은 위치면 정지
    return
}
let unitX = dx / magnitude
let unitY = dy / magnitude
physicsBody?.velocity = CGVector(
    dx: unitX * GameConfig.enemyBaseSpeed,
    dy: unitY * GameConfig.enemyBaseSpeed
)
```

**왜 `hypot`?** `sqrt(dx*dx + dy*dy)`도 OK지만 **overflow 방지** 보장 — 거리가 매우 클 때 `dx*dx`가 Float 한계를 넘어도 `hypot`은 안전. 게임 거리는 안 큰 값이라 실용적 차이는 없지만 *수학 의도가 명시적*.

**왜 magnitude 가드?** 첫 프레임에 enemy = player 위치라면 magnitude = 0 → 0으로 나눔(NaN). 게임에선 안 일어나지만(시작 좌표가 다름) 방어적 가드는 *비용 0*. **NaN이 한 번 들어가면 SpriteKit 노드가 화면에서 사라짐 — 디버깅 매우 어려움**.

**Spring 비유**: `BigDecimal.divide`에서 `divisor.signum() == 0` 가드와 동일. 0 division은 *데이터*가 아닌 *상태* 문제.

### 4-2. velocity 기반 추적 vs position 직접 갱신
```swift
// ✅ 권장 (PlayerNode 패턴 일관)
physicsBody?.velocity = CGVector(dx: vx, dy: vy)

// ❌ 비권장
position = CGPoint(x: position.x + vx * dt, y: position.y + vy * dt)
```

**왜 velocity?** SpriteKit이 *벽 충돌 처리*를 자동으로 함 — `collisionBitMask = .wall`이면 enemy가 벽에 막힘. position 직접 갱신은 *물리 엔진 우회* — 충돌 검사 안 됨, 매 프레임 *벽 통과*. PlayerNode가 2-2에서 똑같은 이유로 velocity로 전환 — 그 패턴 그대로 적용.

**Spring 비유**: `@Transactional` 안에서 entity의 setter 사용 vs `@Modifying @Query`로 직접 UPDATE 쿼리. setter는 변경 감지(dirty checking)가 ORM의 일부 기능을 자동 수행, 직접 UPDATE는 우회 — 트랜잭션·캐시 일관성 깨짐 위험.

### 4-3. `update(deltaTime:targetPosition:)` 시그니처 — dt는 미사용
```swift
func update(deltaTime: TimeInterval, targetPosition: CGPoint) {
    // dt는 *velocity 기반*이라 직접 사용 안 함
    // 시그니처는 PlayerNode와 일관성 + 추후 dt 기반 보간 도입 여지
    let dx = targetPosition.x - position.x
    // ...
}
```

**왜 dt 안 쓰는데 시그니처에 둠?** PlayerNode.update(deltaTime:)와 *형식 일치*. 추후 "1초간 점진적 가속" 같은 보간이 들어오면 dt 곱이 필요 — *시그니처 추가 변경 없이 구현 교체*. **API 안정성 = 호출처 보호**. Spring `@Service` 메서드 시그니처도 같은 이유로 *최대한 변하지 않게* 유지.

> **함정**: `_ deltaTime: TimeInterval` 같은 underscore 라벨링은 *외부 호출 시 라벨 생략* — 가독성 ↓. **명시적 라벨 유지**가 호출처에서 의미 자명.

### 4-4. PlayerNode `contactTestBitMask` OR 확장 — *기존 비트 보존*
```swift
// 기존 (2-3)
body.contactTestBitMask = PhysicsCategory.note

// 확장 (2-6)
body.contactTestBitMask = PhysicsCategory.note | PhysicsCategory.enemy
```

**왜 OR?** `contactTestBitMask`는 *비트마스크* — 여러 카테고리를 동시에 알림 받으려면 OR. 2-3에서 0b0010(note)이었는데 enemy(0b0100) 추가하면 0b0110. **2-3 회귀 보존** + 2-6 신규 동시 만족.

**함정**: `=`로 *덮어쓰기*하면 note 알림 사라짐(2-3 회귀). 반드시 OR. **비트마스크 확장은 *언제나 OR*** — Spring `@Profile("dev | prod")`에서 OR 의미와 동일.

### 4-5. didBegin 분기 — *category 식별을 짧은 헬퍼로*
```swift
func didBegin(_ contact: SKPhysicsContact) {
    let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    if categories & PhysicsCategory.enemy != 0 {
        endGame()
        return
    }
    if categories & PhysicsCategory.note != 0 {
        handleNoteContact(contact)
    }
}
```

**왜 OR로 묶고 AND로 검사?** bodyA/bodyB *어느 쪽*에 enemy/note가 있는지 *순서 무관*. categoryBitMask들을 OR로 합쳐 비트 하나로 만들고, AND로 비트 검사. **분기 코드 *절반*** — 2-5 if/else if(bodyA/bodyB) 사슬 4줄이 1줄로.

**함정**: 적 접촉 분기를 *먼저* — 만약 enemy↔note 접촉이 발생하면(현재는 안 일어남, collide=0) note 처리가 *우선*되면 안 됨. 게임 종료가 *우선순위 최상위*.

> **현재는 player↔enemy / player↔note만 발생** — 다른 조합은 PhysicsBody 설정상 contact 알림 자체가 안 옴. 그래도 분기 *우선순위*는 *피해 우선* 명시가 안전.

### 4-6. EnemyNode 위치 — `worldNode` 자식 (player와 동일 좌표계)
```swift
// GameScene.setupEnemy
enemy.position = CGPoint(
    x: GameConfig.tileSize * 2,                       // 좌측 1tile + 박스 폭 여유
    y: GameConfig.mapHeight - GameConfig.tileSize * 2 // 상단 1tile 안쪽
)
worldNode.addChild(enemy)
```

**왜 worldNode?** player가 worldNode 자식이라 *같은 좌표계*. cameraNode가 player를 따라가면 enemy도 *상대적으로* 화면 안에서 움직임. cameraNode 자식으로 두면 *화면 고정 적*이 되어버려 추적 의미 0.

**왜 좌상단?** 기둥(맵 정중앙) + 플레이어(맵 정중앙 시작) 위치를 피해 *대각선 반대편* 시작. 첫 추적까지 *몇 초 여유* → 사용자가 적의 등장을 인지할 시간. **가장자리 시작은 모바일 게임 컨벤션** (캔디크러시·터치드래곤 등 보스 등장 패턴).

### 4-7. `endGame()` 안 enemy.velocity = .zero — *상태 정지의 다단 보호*
```swift
private func endGame() {
    gameState = .gameOver
    removeAction(forKey: "spawnNotes")
    player.currentDirection = .zero
    player.physicsBody?.velocity = .zero
    enemy.physicsBody?.velocity = .zero  // ← Phase 2-6 추가
    hud.update(score: score, remainingTime: 0, combo: 0)
}
```

**왜 명시 정지?** `update(_:)`는 `gameState != .playing` 가드로 enemy.update 호출 안 됨 → velocity 갱신 멈춤. 그러나 *마지막 갱신값*이 그대로 남음 → enemy가 관성으로 계속 이동. Damping 0 + dynamic body 조합이라 가속 없이도 *직선 등속 운동* 지속. **상태(state)와 표시(display)의 분리**(2-5 §9-2 #7과 동일 원리) — gameOver 진입 ≠ 노드 정지.

**Spring 비유**: 트랜잭션 commit 후 영속성 컨텍스트 close — *논리 완료*와 *리소스 정리*는 분리된 단계. 한쪽만 하면 누수.

### 4-8. ColorTokens *추가 패턴* — 기존 4토큰 보존
```swift
// 기존 4 토큰 (Phase 1-1) 그대로
static let ganhoBgDeep = ...
static let ganhoPaper = ...
static let ganhoMint = ...
static let ganhoPinkNote = ...

// 신규 (Phase 2-6) — assets.md §1 `crimsonNurse #A4243B` 진입
static let ganhoCrimsonNurse = UIColor(named: "crimsonNurse")
    ?? UIColor(red: 0xA4 / 255, green: 0x24 / 255, blue: 0x3B / 255, alpha: 1)
```

**왜 fallback 패턴 유지?** Asset Catalog Color Set이 *추후* 추가되면 자동 우선 적용. 본 sprint에선 fallback HEX(#A4243B)가 활용됨. **ColorTokens 진입 패턴 = "assets.md 토큰 → ColorTokens 항목 1개"** — 일대일 매핑.

> **assets.md §1과 정확히 같은 HEX**. 시각 일관성 = *디자인 토큰 단일 소스*.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
| 파일 | 한 줄 설명 |
|---|---|
| `Nodes/EnemyNode.swift` | 16×20 빨간 박스(crimsonNurse). dynamic body. `update(deltaTime:targetPosition:)` |

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | 상수 3개 추가 — `enemyBaseSpeed=60`, `enemyWidth=16`, `enemyHeight=20`. 새 MARK `// MARK: - Enemy (Phase 2-6)` |
| `Config/ColorTokens.swift` | 토큰 1개 추가 — `.ganhoCrimsonNurse` (#A4243B). MARK `// MARK: - Enemy` 추가 |
| `Nodes/PlayerNode.swift` | 1줄 — `contactTestBitMask = .note` → `.note \| .enemy` |
| `GanhoMusic Shared/GameScene.swift` | (1) `private let enemy = EnemyNode()` 멤버 추가, (2) `setupEnemy()` 신설 + `didMove(to:)`에서 호출, (3) `update(_:)`에 enemy 추적 호출 1줄 추가, (4) `didBegin` 분기 확장 (enemy 우선), (5) `endGame()`에 enemy.velocity = .zero 추가 |

### 절대 손대지 않는 파일
- `Nodes/HUDNode.swift`, `Nodes/DPadNode.swift`, `Nodes/NoteNode.swift` (2-5 / 2-3 그대로)
- `Config/PhysicsCategory.swift` (1-1에서 `.enemy`/`.wall` 이미 정의됨 — 변경 0)
- `Config/GameState.swift` (1-1 그대로)
- iOS 3 파일 (`AppDelegate`, `GameViewController`, `SceneDelegate`)

### Xcode 멤버십
**필요함.** `Nodes/EnemyNode.swift` 신설 → `project.pbxproj`의 `GanhoMusic iOS` 타겟에 등록. **Generator의 fallback 정책 trigger**: 등록 누락 시 빌드 실패 → SELF_CHECK에 명시 + 사용자 수동 등록 안내. 2-3에서 NoteNode 등록 시와 동일 패턴.

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
- `EnemyNode` 등장 ≥ 3건 (멤버 선언 1, setupEnemy 1, didBegin 또는 endGame 1)
- `enemyBaseSpeed` 등장 1건 (EnemyNode.update)
- `PhysicsCategory.enemy` 등장 ≥ 2건 (EnemyNode 카테고리, PlayerNode contactTest, didBegin 분기)
- `targetPosition` 등장 ≥ 2건 (EnemyNode 시그니처, GameScene 호출)
- `hypot` 등장 1건 (정규화)
- `Timer` / `print()` / `as!` / `fileprivate` / 강제 언래핑 `!` 0건 (`fatalError` 면제)
- 매직 넘버 0건 (60/16/20 모두 GameConfig)
- `update(_:)` 안 `addChild()` 0건 (enemy는 setupEnemy에서만)
- `position = ...`로 enemy 직접 위치 갱신 0건 (velocity만)

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 시작 직후 좌상단에 빨간 박스 등장
- (b) 빨간 박스가 *정확히 player 방향*으로 이동 (직선)
- (c) D-Pad로 player를 좌상단 반대(우하단) 방향 이동 → 적과 거리 벌어짐
- (d) 가만히 있으면 적이 다가와 *닿음* → 즉시 게임 종료 (HUD가 시간 0초 표시 + 음표 스폰 중지 + player·적 둘 다 정지)
- (e) 시간 만료(00:00) 도달 시에도 동일하게 게임 종료 (적도 정지)
- (f) 적이 *벽에 막힘* (외곽 벽이나 중앙 기둥에 부딪히면 통과 안 됨, 정지하지도 않음 — 옆으로 미끄러짐 정도는 OK)
- (g) 음표 수집·콤보·HUD·D-Pad·카메라 follow 모두 2-5 그대로

### 6-3. 회귀 (1-3 + 1-5 + 2-1 + 2-2 + 2-3 + 2-4 + 2-5 + 핫픽스)
- DPadNode/HUDNode/NoteNode 그대로
- Config 4 파일(GameConfig 추가 / ColorTokens 추가 / PhysicsCategory 그대로 / GameState 그대로)
- iOS 3 파일 그대로
- 1-3 (PlayerNode 이동 / contactTest는 .note|.enemy로 확장됐지만 .note 알림 보존)
- 1-5 (카메라 드론 follow)
- 2-1 (외곽 벽)
- 2-2 (중앙 기둥 + gravity 0)
- 2-3 (음표 spawn + didBegin note 처리 — enemy 분기가 *먼저* 검사되지만 player↔note 충돌 시엔 enemy 비트 0이므로 note 분기 진입)
- 2-4 (HUD 점수/시간 라벨 + 시간 만료 endGame)
- 2-5 (콤보 윈도우 + 점수 분기 + 콤보 라벨 + endGame combo: 0)

---

## 7. 사용자 결정 필요 사항

### 결정 ① · 2-6 sprint 범위
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 수간호사 NPC만 (F 투사체는 2-7)** ⭐ | 신설 1 파일, 수정 4 파일. 1 SPEC = 1 sub-feature 원칙 충실 | ⭐ — 작은 변경 = 정확한 QA |
| B. 수간호사 + F 투사체 한꺼번에 | 신설 2 파일(EnemyNode + ProjectileNode), 수정 5 파일. PhysicsCategory에 projectile 비트 추가 | 큰 변경 = QA 피드백 흩어짐 |

**왜 A?** 2-3(음표 spawn) → 2-4(HUD) → 2-5(콤보) 패턴을 그대로 — *각 sprint가 게임플레이 한 단계 진화*. F 투사체는 *발사 주기·발사 지점·소멸 조건* 등 추가 결정사항이 많음 → 별도 sprint(2-7)가 더 깔끔.

### 결정 ② · 추적 AI 방식
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. velocity 기반 (PhysicsBody)** ⭐ | PlayerNode 패턴 일관. 벽 충돌 자동. dt 미사용 | ⭐ — 2-2 패턴 재활용 |
| B. position 직접 갱신 | dt 곱 명시적. 단순 산수 | 벽 통과 — 기둥/외곽 벽 무시 |
| C. SKAction.move(to:player.position) | 선언형 | 매 프레임 액션 갱신 — 비용 ↑ |

**왜 A?** PlayerNode가 2-2에서 *velocity 기반*으로 전환된 이유와 동일 — 물리 엔진이 *벽 충돌 자동 처리*. **수간호사도 벽에 막혀야** GDD §6 easy맵의 중앙 기둥이 *전략 요소*가 됨 (플레이어가 기둥 뒤로 숨기 가능).

### 결정 ③ · 적 시작 위치
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 맵 좌상단 1tile 안쪽** ⭐ | (40, mapH-40). 플레이어 시작(맵 중앙)과 *대각선 반대* | ⭐ — 인지 여유 |
| B. 매 게임 4모서리 중 랜덤 | 랜덤성 | 첫 sprint에서 결정론 우선 |
| C. 플레이어 정반대편 (대칭 미러) | 대칭 강조 | 시각 균형은 좋지만 산수 추가 |

**왜 A?** 사용자가 시뮬레이터 첫 실행 시 *적의 등장*을 *시각적으로 인지*할 시간이 필요. 좌상단은 대부분의 모바일 게임이 *부정적 신호(적/타이머)*를 두는 위치 → 컨벤션 일치. 랜덤은 2-8 난이도 보간 sprint에서 추가 검토.

### 결정 ④ · 적 색상
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 새 토큰 `.ganhoCrimsonNurse` (#A4243B)** ⭐ | assets.md §1 `crimsonNurse` 그대로 진입. ColorTokens.swift 1줄 추가 | ⭐ — 디자인 토큰 일관 |
| B. 기존 토큰 재활용 (`.ganhoPinkNote` 등) | 신설 파일 변경 0 | 음표·적 색 충돌 — 시각 혼란 |
| C. 검정/회색 등 임시 | placeholder | assets.md 정의 무시 — 미감 가이드 위반 |

**왜 A?** assets.md §1이 *수간호사 가운 = #A4243B*로 정의됨. **디자인 토큰의 단일 소스 원칙** — 코드에 진입하는 순간이 토큰의 *첫 사용*. 다음 토큰(`.ganhoYellowF` for F 투사체)도 같은 패턴으로 2-7에서 진입 예정.

### 결정 ⑤ · didBegin 분기 패턴
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. categoryBitMask OR + AND 검사 (`if categories & .enemy != 0`)** ⭐ | 4줄 → 2줄. bodyA/bodyB 순서 무관 | ⭐ — 분기 단순화 |
| B. if/else if(bodyA), else if(bodyB) 그대로 확장 | 2-5 패턴 일관 | 분기 4줄 → 8줄. 가독성 ↓ |
| C. 분리 함수 (`handleNoteContact`/`handleEnemyContact`) | 의도 명시적 | 분리 자체가 sub-feature — Phase 2-7 또는 2-8에서 |

**왜 A?** `categories = bodyA.cat \| bodyB.cat` → `if categories & .enemy != 0`은 *비트 검사 한 번*. 분기 수가 늘어도 패턴 그대로 확장 가능 (5개 분기까지는 OK). C는 분기 구조 자체의 변화라 *별도 sprint*로 분리.

### 결정 ⑥ · `endGame()` 안 enemy 정지
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `enemy.physicsBody?.velocity = .zero` 1줄 추가** ⭐ | 명시적, player와 대칭 | ⭐ — 표현 일관 |
| B. EnemyNode가 자체 gameState 가드 | 캡슐화 | EnemyNode가 GameState를 알아야 함 — 결합도 ↑ |
| C. 정지 안 함 (관성 무시) | 코드 0줄 | enemy가 endGame 후에도 계속 이동 — 어색 |

**왜 A?** player.physicsBody?.velocity = .zero(2-4)와 *대칭 패턴*. EnemyNode가 GameState enum을 import할 필요 없음 (B의 부작용 회피). 1줄 추가로 *표현 일관*.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 (적 추적 AI + 접촉 시 게임오버)
- **게임 경험 의도**:
  > "수간호사 한 마리가 좌상단에서 등장해 *플레이어를 직선 추적*한다. 닿으면 *즉시 게임 종료*. 게임이 *시간 만료까지 음표 모으기*에서 *수간호사를 피하며 음표 모으기*로 진화한다. 회피 게임의 본질이 들어선다."
- **Sprint 범위 계약**:
  - **IN**: 신설 1 파일 (EnemyNode), 수정 4 파일 (GameConfig 상수 3개, ColorTokens 토큰 1개, PlayerNode contactTest 1줄, GameScene setupEnemy + update 추적 + didBegin 분기 + endGame 정지). pbxproj 1건 (EnemyNode 등록).
  - **OUT**: F 투사체(2-7) / 적 속도 보간(2-8) / 적 다수 / 게임오버 화면 / 무적 시간 / 회피 경로 AI / 사운드 / 시각 펄스 / Systems 폴더 분리.
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / `DispatchQueue.main.asyncAfter` 0건
  - `update(_:)` 안 `addChild()` 0건 (enemy 추가는 setupEnemy에서만)
  - 매직 넘버 0건 — 60/16/20 모두 `GameConfig.enemy*`. 좌상단 좌표(`tileSize * 2`)는 자명한 산수
  - velocity 기반 추적 (position 직접 갱신 0건)
  - `hypot` 사용 + magnitude > 0 가드 (NaN 방지)
  - `EnemyNode.update(deltaTime:targetPosition:)` 시그니처 — 외부 의존 명시
  - PlayerNode `contactTestBitMask` OR 확장 (`.note | .enemy` — 기존 비트 보존)
  - didBegin 분기 우선순위: enemy *먼저* 검사 → endGame, 그 다음 note → 점수
  - ColorTokens 신규 토큰 1개 (`.ganhoCrimsonNurse` #A4243B) — assets.md §1 정확 일치
  - endGame() 안 `enemy.physicsBody?.velocity = .zero` 1줄 추가
- **회귀 보존 (1-3 + 1-5 + 2-1 + 2-2 + 2-3 + 2-4 + 2-5 + 핫픽스)**:
  - HUDNode / DPadNode / NoteNode / GameState / PhysicsCategory / iOS 3 파일 변경 0
  - 1-3 / 1-5 / 2-1 / 2-2 / 2-3 / 2-4 / 2-5 동작 보존
  - HUDNode `update(score:remainingTime:combo:)` 시그니처 그대로 (호출 시 인자 형식 변경 0)
  - PlayerNode 카테고리/충돌 비트는 *contactTest만* 변경 (categoryBitMask, collisionBitMask 그대로)

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없음.** 1차 빌드 SUCCEEDED + P0/P1/P2 0건 + 회귀 8/8 + 정적 룰 11/11 PASS + 가중 10.0/10.0. 2-5에 이은 *두 sprint 연속 1차 통과* — 학습 노트 §7 결정사항 6건 사전 확정 + SPEC §"기능 상세"에 코드 스켈레톤까지 명시한 게 결정타. Generator가 *해석할 여지*를 거의 안 남김.

> **인사이트**: 신설 1 파일이라 pbxproj 자동 등록이 핵심 게이트였는데 NoteNode(2-3) 등록 패턴이 Generator 안에 *학습된 패턴*으로 남아 있어서 한 번에 성공. **이전 sprint의 *디테일이 다음 sprint의 인프라*가 된다** — 2-3 sprint에서 고생한 pbxproj 등록이 2-6에서는 자동 동작.

### 9-2. Spring과 다르네 싶었던 것
1. **`hypot(dx, dy)` vs `Math.sqrt(dx*dx + dy*dy)`**: Java/Kotlin에선 보통 `Math.sqrt`. C/Swift는 `hypot` — *overflow 방지 보장*. 게임 거리에선 차이 없지만 *수학 의도 명시*가 더 중요. **언어가 제공하는 함수의 *의미적 폭*을 알면 코드가 짧아짐**. Java에도 `Math.hypot` 있는데 잘 안 씀 — 라이브러리는 알고 쓰는 게 차이.
2. **비트마스크 OR 확장 — `.note | .enemy`**: Java도 가능하지만 *Spring 일상 코드*에선 거의 안 씀(JPA·Spring Security가 enum/list로 대체). 게임은 *60Hz 매 프레임 비교*라 비트 OR 한 번의 비용이 압도적. **게임 도메인은 Spring보다 *저수준 자료구조*에 익숙해질 필요**. `@Profile("dev | prod")`의 OR 의미와 본질은 같음 — 표현 방식만 다름.
3. **`update(deltaTime:targetPosition:)` 시그니처에 *미사용 dt 보존***: Spring에선 미사용 파라미터는 *린트 경고* → 즉시 제거. Swift 게임 도메인은 *시그니처 안정성*이 호출처 보호 가치 ↑. dt가 본 sprint에선 미사용이지만 Phase 2-8 보간에서 *시그니처 추가 변경 없이* 활성. **API 안정성 = 호출처 보호** — Spring `@Deprecated` 후 N개월 유지하는 패턴과 정신은 같음.
4. **didBegin의 비트 OR 식별 패턴**: bodyA/bodyB 순서 무관 → `categories = bodyA.cat | bodyB.cat`로 OR 후 AND 비트 검사. *분기 코드 절반*. Spring `@RestController`의 `@RequestParam` 순서 무관과 비슷한 *위치 추상화*. **데이터 구조의 *대칭성*을 활용한 분기 단순화** — 함수형 사고에 가까움.
5. **PhysicsCategory 비트가 *1-1에서 미리 정의*되었다는 가치**: 1-1 sprint에서 `.enemy=0b0100`, `.wall=0b1000`을 *5단계 미래까지 예측*해서 정의해둠. 2-6 sprint에서 PhysicsCategory.swift 변경 0줄. **인프라는 *처음 설계할 때 예측*하면 *5단계 후 sprint*가 한 줄짜리 변경이 됨**. Spring `application.yml` 키를 처음부터 잘 짜면 *수년간 bean 추가만으로 끝남*과 같은 원리.
6. **회귀 보존 8파일 변경 0줄 = `git diff --stat`로 자동 검증**: Java 프로젝트에서 *엉뚱한 파일을 건드렸나*는 *PR 리뷰어*가 잡지만, 본 하네스에선 *Evaluator가 stat으로 자동 잡음*. **회귀 검증의 자동화 = 사람 손 안 거치는 안전망**. Spring CI에 `git diff --stat | grep ...` 같은 헬프 스크립트 추가하면 같은 효과.
7. **`fatalError("init(coder:) has not been implemented")` = Java `throw new UnsupportedOperationException()`**: SwiftLint도 면제 처리. **언어 컨벤션의 "약속된 예외"**. Java로 치면 `Cloneable`을 구현 안 하는 클래스에 `clone()`이 `CloneNotSupportedException` 던지는 것과 동일.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-7 진입 시)
1. **F 투사체 (Phase 2-7)**: ProjectileNode 신설. PhysicsCategory에 `projectile: UInt32 = 0b10000` 추가 — *드디어 1-1에서 정의 안 한 비트가 처음 추가됨*. 적이 일정 주기(GDD §5 easy: 3.5→2.0초)로 player 방향 발사. 발사 시점 player.position 캡처(직선 진행). 벽 충돌 시 소멸. F↔player 접촉 시 endGame.
2. **적 속도 시간 보간 (Phase 2-8)**: GDD §5 — `obsBaseSpeed=60` → `obsMaxSpeed=110` 보간. `curveT = 1 - remainingTime / gameDuration`. enemyMaxSpeed 상수 신규 + EnemyNode가 보간 계수 인자로 받기. **`update(deltaTime:targetPosition:)` 시그니처에 *speed: CGFloat* 추가 검토** — 또는 GameScene이 보간 후 EnemyNode.currentSpeed 프로퍼티에 set.
3. **didBegin 함수 분리 (Phase 2-7 또는 2-8)**: 분기 3개(enemy/note/projectile)가 되면 `handleEnemyContact`/`handleNoteContact`/`handleProjectileContact` 분리 검토. 현재 didBegin이 35줄 — projectile 추가 시 50줄 넘어가면 *함수 분리 트리거*.
4. **endGame 진입 사유 (Phase 3)**: 현재 시간 만료 / 적 접촉 모두 *동일 endGame*. 2-7에서 F 피격 추가되면 사유 3개. 게임오버 화면 도입 시 reason enum 도입 (`.timeOver`/`.caught`/`.shot`).
5. **무적 시간 (Phase 5)**: 이간호 스킬 "대만여행"으로 0.5초 무적. PlayerNode에 `isInvincible: Bool` + didBegin에서 `guard !player.isInvincible else { return }` 우선 검사 (enemy/projectile 분기보다 *더 위*).
6. **적 시작 위치 — 매 게임 랜덤화 (Phase 4 또는 보스급 적 진입 시)**: 현재 좌상단 고정. 다중 적 등장 시 랜덤 또는 4모서리 순환 배치 검토. GameConfig에 spawn position 정책 상수 신규.
7. **`tileSize * 2` 산수의 상수화 (Phase 4)**: setupEnemy의 좌상단 좌표는 *자명 산수* 면제됐지만 적 다수 등장 시 spawn position이 여러 곳 필요하면 GameConfig.enemySpawnInsetTiles 같은 상수 추출.
8. **EnemyNode 리스트 관리 (Phase 4)**: 현재 단일 멤버 `private let enemy = EnemyNode()`. 다수 등장 시 `private var enemies: [EnemyNode] = []` + `worldNode.enumerateChildNodes(withName: "enemy")` 패턴 (음표 spawn에서 이미 사용 중).

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **10 / 10** — 강제 언래핑 0 / 매직 넘버 0 / MARK 일관성 / fallback 패턴 일관 / GameConfig 상수 3개 정확 진입 / fatalError는 init(coder:) 표준 패턴 면제
- 게임 로직 (30%): **10 / 10** — velocity 기반 추적 / hypot + magnitude>0 가드 (NaN 방어) / didBegin enemy 우선 분기 / endGame velocity 정지 / PlayerNode contactTest OR 확장 / 회귀 8/8 보존
- 성능 (20%): **10 / 10** — BUILD SUCCEEDED 경고 0 / [weak self] 정상 / update 안 addChild 0건 / dt 기반 이동 / pbxproj 자동 등록 성공
- 기능 완성도 (15%): **10 / 10** — SPEC IN 8 기능 모두 구현 / OUT 0건 침범 / pbxproj 자동 등록 → 사용자 수동 작업 0
- **가중평균: 10.0 / 10 — 합격** (1회차 통과, 학습노트 시리즈 *최고점* 달성)

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 7가지 (§6-2):
- (a) ~~시작 직후 좌상단에 빨간 박스(crimsonNurse) 등장~~ → **hotfix 1 후**: 시작 직후 *player 좌상단 대각선*에 빨간 박스 명확히 보임 (화면 표시 -160, +100)
- (b) 빨간 박스가 *정확히 player 방향*으로 직선 이동
- (c) D-Pad로 player를 우하단 방향 이동 → 적과 거리 벌어짐
- (d) 가만히 있으면 적이 다가와 *닿음* → 즉시 게임 종료 (HUD 시간 0초 + 음표 spawn 정지 + player·적 둘 다 정지)
- (e) 시간 만료(00:00) 도달 시에도 동일 게임 종료 (적도 정지)
- (f) 적이 외곽 벽이나 중앙 기둥에 *막힘* (옆으로 미끄러짐 정도는 OK)
- (g) 음표 수집·콤보·HUD·D-Pad·카메라 follow 모두 2-5 그대로

---

## 11. Hotfix 1 (2026-05-07) — enemy 시각 가시성 보장

### 11-1. 발견된 문제
사용자가 본 sprint 합격 직후 시뮬레이터(iPhone 17 가로) 실행 시 **enemy가 화면에 보이지 않음**. 14초 흐른 스크린샷에도 빨간 박스 위치 불명.

### 11-2. 원인 진단
- enemy 좌표 (40, 440) → 화면 표시 (-440, +200) (cameraNode 기준)
- iPhone 17 가로 모드 노치/Dynamic Island가 좌측 약 50~60pt를 가림
- enemy가 정확히 *노치 영역에 들어가서* 시각적으로 가려짐
- HUD 좌상단 영역(-442, +191)과도 겹침

### 11-3. 핫픽스 변경
| 파일 | 변경 |
|---|---|
| `GameScene.swift` setupEnemy() | 좌표를 `(tileSize*2, mapHeight - tileSize*2)` = (40, 440)에서 `(mapWidth/2 - tileSize*8, mapHeight/2 + tileSize*5)` = **(320, 340)**으로 변경 |
| `EnemyNode.swift` init() | `physicsBody = body` 다음 줄에 `zPosition = 5` 1줄 추가 (외곽 벽/기둥/음표 위에 항상 그려지게) |

**새 좌표의 의미**:
- 화면 표시 (-160, +100) — 어떤 viewport·노치에서도 화면 안 안전 영역
- player(맵 정중앙)에서 거리 ≈ 188.68pt → 60pt/s 속도로 **약 3.14초** 후 도달
- 중앙 기둥(맵 정중앙) 위쪽으로 비껴 있어 처음엔 막힘 없이 추적
- 시작 즉시 위협 인지 + 적당한 인지 시간

### 11-4. 학습 포인트
1. **시뮬레이터/실기기의 *시각적 viewport*는 좌표 계산만으론 알 수 없다**: iPhone 17 가로 모드 노치는 SDK 좌표상 화면 안이지만 *시각적으로 가려짐*. SafeAreaInsets를 고려하지 않은 절대 좌표 배치는 위험.
2. **player 시작 위치 기준 *상대좌표*가 안전**: 카메라 follow 게임에서 *시각적으로 보이는지*는 player 기준 상대 거리로 판단해야. 맵 절대좌표는 player 위치에 따라 화면에서 사라질 수 있음.
3. **zPosition 명시는 *디버깅 보험***: 다른 노드와 위치 겹침이 없어도 *기본 0*으로 두면 추가 순서에 따라 가려질 위험. 작은 정수(5)로 명시 = 시각 우선순위 *데이터로 표현*.
4. **하네스 1 사이클로 *작은 핫픽스*도 처리 가능**: 좌표 2줄 + zPosition 1줄 변경에도 SPEC → Generator → Evaluator 한 사이클이 *과해 보일 수* 있지만 회귀 위험 검증(다른 파일 0 변경)을 *자동화*하는 가치가 큼. Spring으로 치면 *2줄 핫픽스 PR*에도 CI/CD 통과시키는 정신.

### 11-5. 평가 점수 (Hotfix 1)
- 가중평균: **9.35 / 10 — 합격**
- 1차 BUILD SUCCEEDED + P0/P1 0건 + 회귀 12/12 보존 + 좌표 검증 100% 일치

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 6건 사용자 OK (모두 추천대로 가는지)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → EnemyNode 신설 + GameConfig/ColorTokens/PlayerNode/GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-7 (F 투사체 + 발사 주기 + F 피격 시 endGame) 으로
```

> **2-6 본질**: 게임이 *수집*에서 *수집 + 회피*로 진화. 콤보(2-5)가 *왜 빨리 모아야 하는지*를 만들었다면, 적(2-6)은 *왜 동선을 짜야 하는지*를 만든다. **위험 설계**의 첫 진입 — F 투사체(2-7)·난이도 보간(2-8)이 그 위에 쌓일 토대.
