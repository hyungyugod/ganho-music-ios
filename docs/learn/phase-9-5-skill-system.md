# Phase 9-5 — 캐릭터별 스킬 시스템 4종

## 이번에 한 일을 한 줄로

5명의 간호사 캐릭터 중 4명에게 *각자 다른 능동 스킬 1개씩*을 달아줬어. 김간호만 *스킬 없이* 정공법으로 플레이하고, 정/건/임/이 간호는 좌하단에 새로 생긴 *스킬 버튼*을 한 번 탭하면 자기만의 스킬이 발동돼.

---

## 왜 이걸 했나?

지금까지 5 캐릭터는 *색깔과 이름과 미세한 속도 차이*만 다른 채로 게임에 들어가 있었어. 사실상 *겉모습만 다른 동일 캐릭터 5개*였던 거지. 이번 phase의 목표는 처음으로 *진짜 다른 플레이 경험*을 주는 거야.

특별히 김간호는 *스킬 없음*이 의도된 정체성이야. 이 게임 자체가 사용자(나) 본인의 자전적 이야기로 만들어진 거라, *주인공 김간호는 정공법으로 작곡 시간을 훔치는 사람*이라는 톤을 보존해야 해. 다른 4명의 동료는 각자 다른 방식으로 작곡 시간을 *훔치는* 도구가 다른 거고.

---

## 무엇을 만들었나?

### 1. 4명의 스킬 한 줄 정리

| 캐릭터 | 스킬 이름 | 한 줄 설명 |
|---|---|---|
| 김간호 (.kim) | 없음 | 정공법 — 스킬 버튼 자체가 비활성 |
| 정간호 (.jung) | 암벽등반 돌진 (.dashClimb) | 보고 있는 방향으로 3칸 휙 — 무적 + 벽 1개 부수기 |
| 건간호 (.geon) | 북클럽 소집 (.bookClubRally) | 주변 6칸 안 음표들을 *내 자리로 끌어모음* |
| 임간호 (.im) | 나는야 모범생 (.charmStudent) | 1회 한정 — 1.5초 동안 *날아오는 F가 점수로 바뀜* |
| 이간호 (.lee) | 대만여행 (.taiwanTrip) | 텔레포트 5칸 + 0.5초 무적 + 깜빡임 |

### 2. 새로 만든 파일 4개

```
GanhoMusic Shared/
├── Models/
│   └── PlayerSkill.swift         ← 5 case enum + 메타데이터
├── Systems/
│   └── SkillSystem.swift          ← 컨트롤러 (스킬 실행 + 쿨다운 관리)
└── Nodes/
    ├── SkillButtonNode.swift      ← 좌하단 원형 버튼 (1탭 발동)
    └── HUDSkillSlotNode.swift     ← 버튼 위에 뜨는 쿨다운 진행 링
```

Spring Boot 비유로 치면:
- `PlayerSkill` = enum + 메타데이터 → **DTO + getter** (데이터 모양 정의)
- `SkillSystem` = 발동/쿨다운 관리 → **Service** (실제 비즈니스 로직)
- `SkillButtonNode` = 사용자 입력 받기 → **Controller** (요청 받는 입구)
- `HUDSkillSlotNode` = 진행률 보여주기 → **View** (사용자에게 상태 보여주는 화면)

### 3. PlayerSkill enum — 5개 case + 메타데이터 4개

```swift
enum PlayerSkill {
    case none           // 김간호
    case dashClimb      // 정간호
    case bookClubRally  // 건간호
    case charmStudent   // 임간호
    case taiwanTrip     // 이간호
}

extension PlayerSkill {
    var displayName: String { ... }    // "돌진", "북클럽" 등
    var cooldown: TimeInterval { ... } // 22, 20, .infinity, 22
    var duration: TimeInterval { ... } // 0.26, 0, 1.5, 0.5
    var oncePerGame: Bool { ... }       // 임간호만 true
}
```

각 메타데이터는 *computed property*야. 그냥 변수가 아니라 *호출할 때마다 switch 돌아서 답을 계산해주는 함수* 같은 거. Spring 비유 — `@Getter`가 자동 생성된 단순 getter가 아니라, 호출될 때 분기 로직이 들어간 메서드를 직접 짠 셈.

핵심은 *switch에 default 없음*이야. 만약 나중에 `.foo` 케이스를 enum에 추가하면 Swift 컴파일러가 *바로* "이 4개 switch 안에 .foo 처리가 없네?"라고 컴파일 에러를 띄워줘. default가 있으면 그냥 조용히 빨려 들어가서 버그를 놓쳐.

### 4. SkillSystem — 컨트롤러의 핵심 5가지 상태

```swift
final class SkillSystem {
    private(set) var activeSkill: PlayerSkill       // 지금 어떤 스킬?
    private(set) var cooldownRemaining: TimeInterval // 쿨다운 남은 시간
    private(set) var durationRemaining: TimeInterval // 효과 지속 남은 시간
    private(set) var usedThisGame: Bool             // 1회 한정 스킬 썼나?
    private weak var scene: GameScene?              // 씬을 만지러 갈 통로
}
```

`private(set)`은 *밖에서는 읽기만 가능, 쓰기는 안에서만*이라는 뜻이야. Spring 비유 — `@Getter`만 있고 `@Setter`는 없는 필드. 외부(HUD)는 `progress`를 폴링해서 읽을 수만 있고, 값을 변경하는 건 SkillSystem 자기 자신뿐.

`scene`은 `weak` 참조야. SkillSystem이 scene을 *강하게 붙들고 있으면* scene이 사라질 때 메모리에서 못 빠져나가는 *순환 참조*가 생겨. weak로 잡으면 "보고는 있지만 붙들지는 않아"라서 메모리 누수 0.

### 5. 매 프레임 update(dt:) — 시간 감소 + 만료 감지

```swift
func update(dt: TimeInterval) {
    if cooldownRemaining > 0 {
        cooldownRemaining = max(0, cooldownRemaining - dt)
    }
    if durationRemaining > 0 {
        let next = max(0, durationRemaining - dt)
        durationRemaining = next
        if next == 0 {
            onDurationExpired()  // 매혹 만료 시 enchanted 해제
        }
    }
}
```

`dt`는 *이전 프레임부터 지금까지 흐른 시간*이야. 보통 1/60초 ≈ 0.0167초. 매 프레임마다 이 값을 빼면 자연스럽게 *실제 시간*에 맞춰 쿨다운이 줄어들어.

`Timer`를 안 쓰고 GameScene.update에서 `skillSystem.update(dt: dt)` 한 줄로 처리해. Spring 비유 — `@Scheduled` 같은 별도 스레드 타이머가 아니라, *메인 루프 안에서 매 사이클 호출되는 일반 메서드*. SpriteKit 게임은 메인 스레드 게임 루프가 시간을 다루는 게 정석.

### 6. tryActivate — 3중 가드로 함부로 발동 못 하게

```swift
func tryActivate() {
    guard activeSkill != .none else { return }              // 김간호 차단
    guard cooldownRemaining <= 0 else { return }            // 쿨다운 중 차단
    guard !(activeSkill.oncePerGame && usedThisGame) else { return }  // 1회 소진 차단

    switch activeSkill {
    case .none:           return
    case .dashClimb:      performDashClimb()
    case .bookClubRally:  performBookClubRally()
    case .charmStudent:   performCharmStudent()
    case .taiwanTrip:     performTaiwanTrip()
    }

    cooldownRemaining = activeSkill.cooldown
    durationRemaining = activeSkill.duration
    if activeSkill.oncePerGame {
        usedThisGame = true
    }
}
```

`guard ... else { return }` 패턴이 *3중 방어선*이야. Spring Boot의 `@PreAuthorize` 또는 Controller 진입부의 권한 검사 줄줄이 같은 거. 하나라도 실패하면 함수 자체가 *조용히 종료*되어 본체에 도달조차 안 해.

### 7. 정간호 — 암벽등반 돌진 (DashClimb)

```swift
private func performDashClimb() {
    let direction = currentDashDirection()  // 1) 방향 결정
    let end = ... // 2) 도착 좌표 계산
    breakFirstBreakableWall(from: start, to: end)  // 3) 경로 위 벽 1칸 깨기
    player.isInvulnerable = true                    // 4) 무적 on
    let move = SKAction.move(to: end, duration: 0.26)
    let endAction = SKAction.run { [weak player] in
        player?.isInvulnerable = false              // 5) 끝나면 무적 off
    }
    player.run(.sequence([move, endAction]))
}
```

이 한 함수에 *5가지 동시 처리*가 들어가. 핵심은 `SKAction.sequence`인데, *이동 → 콜백* 두 단계를 묶어서 *0.26초 후 자동으로 무적을 해제*해주는 타이머 역할을 해.

`[weak player]`는 *클로저가 player를 강하게 붙들지 못하게* 막는 메모리 누수 방어. Swift 코딩 규칙(rules)에서 클로저 안에서 self/외부 객체를 잡을 땐 무조건 weak 필수.

### 8. 벽 부수기 — name으로 식별

분리벽만 `name = "breakableWall"`을 붙여놨어. 외곽 벽이나 장식 기둥은 name 없음. 정간호가 돌진하면 `enumerateChildNodes(withName:)`로 *이름이 breakableWall인 노드만* 검사해.

```swift
world.enumerateChildNodes(withName: GameConfig.breakableWallName) { node, _ in
    // 진행 방향 + 거리 검사 → 가장 가까운 벽 1개 찾기
}
```

Spring 비유 — DB에서 `WHERE category = 'breakable'`로 필터링하는 거랑 같음. 전체를 다 뒤지지 않고 *마킹된 것만* 골라봐서 효율적.

### 9. 건간호 — 북클럽 소집 (BookClubRally)

```swift
world.enumerateChildNodes(withName: "note") { node, _ in
    let dx = node.position.x - center.x
    let dy = node.position.y - center.y
    guard dx * dx + dy * dy < radiusSquared else { return }  // 거리^2 비교
    let move = SKAction.move(to: center, duration: 0.4)
    move.timingMode = .easeIn
    node.run(move)
}
```

`dx * dx + dy * dy < radiusSquared` — *거리의 제곱을 비교*해. 실제 거리는 `sqrt(dx*dx + dy*dy)`인데 sqrt가 비싸. 양쪽 다 제곱해서 비교해도 결과는 같으니까 *루트 안 씌우기*가 성능 핵심.

음표가 *플레이어 자리로 자기 발로 걸어옴* → 도착하면 자연스럽게 player와 부딪쳐 → 기존 ContactRouter가 "음표 수집!" 하고 처리. *기존 로직을 안 건드리고 음표만 끌어당겨주면 끝.*

### 10. 임간호 — 나는야 모범생 (CharmStudent)

```swift
private func performCharmStudent() {
    world.enumerateChildNodes(withName: "projectile") { node, _ in
        if let projectile = node as? ProjectileNode {
            projectile.applyEnchanted()  // F → A로 변신
        }
    }
}
```

발동하는 순간 화면에 떠 있던 F들이 *분홍색 A로 변신*해. ProjectileNode에 `isEnchanted` 플래그가 켜지고 색이 노란색 → 분홍색으로 바뀌어.

또 1.5초 동안은 *새로 발사되는 F도 출생 즉시 enchanted*가 돼:

```swift
// SpawnSystem.fireProjectile 안
let isCharmed = (scene as? GameScene)?.skillSystem.isCharmActive ?? false
// ...
if isCharmed {
    projectile.applyEnchanted()
}
```

ContactRouter에서 *플레이어 ↔ F* 충돌이 일어날 때:

```swift
if let projectile = node as? ProjectileNode, projectile.isEnchanted {
    self.scoreSystem.recordCharmedNoteHit()  // 점수 가산
    projectile.run(.removeFromParent())      // F 제거
    return  // endGame 안 함
}
```

*공격을 점수로 바꿔주는* 마법. 게임 전체에서 *딱 한 번* 쓸 수 있어서(oncePerGame=true) 타이밍이 핵심.

### 11. 이간호 — 대만여행 (TaiwanTrip)

```swift
let candidates: [CGVector] = [
    CGVector(dx:  1, dy:  0),
    CGVector(dx: -1, dy:  0),
    CGVector(dx:  0, dy:  1),
    CGVector(dx:  0, dy: -1)
].shuffled()

for direction in candidates {
    let candidate = ... // 후보 좌표
    if isValidTeleportTarget(candidate) {
        targetPosition = candidate
        break  // 첫 성공 후보 채택
    }
}
```

4방향(상/하/좌/우)을 *셔플*해서 무작위 순서로 시도. 맵 밖이거나 벽이랑 겹치는 후보는 건너뛰고 *첫 성공*에서 끝. 4개 다 실패하면 제자리 무적만(fallback).

벽 검사는 `physicsWorld.body(at:)`로 *그 위치에 물리 바디가 있나*를 물어봐. 있으면 벽이고, 없으면 빈 공간.

### 12. 무적 단일 정책

스킬 4개 중 *돌진(0.26초)*과 *대만여행(0.5초)*은 player를 무적으로 만들어. 무적 가드는 `PlayerNode.isInvulnerable: Bool` 한 줄 + ContactRouter 콜백 2지점:

```swift
contactRouter.onEnemyHit = { [weak self] in
    if self?.player.isInvulnerable == true { return }
    self?.endGame()
}
contactRouter.onProjectileHitPlayer = { [weak self] node in
    // ... enchanted 처리 후 ...
    if self?.player.isInvulnerable == true { return }
    // endGame
}
```

Spring 비유 — `@PreAuthorize("isAuthenticated()")` 어노테이션을 두 컨트롤러 메서드에 일관되게 다는 것과 같음. *진입 조건 검사 단일 지점*이라 빠뜨릴 일 0.

### 13. HUD 진행률 시각화 — 4가지 상태

HUDSkillSlotNode가 매 프레임 `skillSystem.progress`(0.0~1.0)를 받아서 시각 분기:

| 상태 | progress | 시각 |
|---|---|---|
| 사용 가능 | 1.0 | 링 가득 + "READY" 밝게 |
| 쿨다운 중 | 0~1 | 링 알파 = progress + "..." |
| 1회 소진 | 0 (영구) | 링 사라짐 + "USED" 흐릿 |
| 김간호 | (무시) | 링 알파 0 + "—" 흐릿 |

```swift
func update(progress: CGFloat) {
    if currentSkill == .none { return }  // 김간호는 항상 빈 슬롯
    if currentSkill.oncePerGame, progress <= 0 {
        ringFillNode.alpha = 0
        valueNode.text = "USED"; return
    }
    if progress >= 1.0 {
        ringFillNode.alpha = 1.0
        valueNode.text = "READY"; return
    }
    ringFillNode.alpha = progress
    valueNode.text = "..."
}
```

### 14. SkillButton — 1탭 발동 + 김간호 비활성

```swift
final class SkillButtonNode: SKNode {
    var onTap: () -> Void = {}

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 0.85 : 0.3
        isUserInteractionEnabled = enabled
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onTap()
    }
}
```

`isUserInteractionEnabled = false`로 두면 *터치 자체가 노드에 도달하지 않아*. 김간호 모드에선 시각도 흐릿하고 터치도 안 먹혀.

GameScene에서 콜백 등록:
```swift
skillButton.onTap = { [weak self] in
    self?.skillSystem.tryActivate()
}
```

Spring 비유 — Controller가 `@PostMapping("/skill")`을 받으면 service.tryActivate()를 부르는 거랑 같음. 입구는 단순하고 진짜 일은 Service가 다 함.

---

## Swift/SpriteKit 패턴 메모

### `private(set)`로 읽기 전용 외부 노출

`SkillSystem`의 5개 상태(activeSkill/cooldownRemaining/...)는 다 `private(set)`. 외부(HUD/SpawnSystem)는 *읽기만* 가능하고, 변경은 SkillSystem 자기만 함. Spring Boot의 `@Getter` 없는 `@Setter`는 거의 안 쓰는 거랑 동치 — *외부가 함부로 바꾸지 못하게* 캡슐화.

### 시그니처 변경 최소화 — 본문만 손대기

`SpawnSystem.start`/`SpawnSystem.fireProjectile` 같은 외부 호출되는 시그니처는 *건드리지 않았어*. 본문 안에서 `scene as? GameScene`으로 캐스팅해서 `skillSystem.isCharmActive`를 조회:

```swift
let isCharmed = (scene as? GameScene)?.skillSystem.isCharmActive ?? false
```

`as?`는 *실패 시 nil*. weak `scene`이 nil이거나 GameScene 아닌 경우(테스트 씬 등)에도 자연 fallback. Spring 비유 — `Optional<User>` 반환받고 `.orElse(anonymous)`로 처리하는 패턴.

### ContactRouter 시그니처는 *최소* 확장

`onProjectileHitPlayer`만 인자가 `() -> Void` → `(SKNode) -> Void`로 1개 늘어났어. 나머지 3개 콜백은 그대로. 왜냐면 enchanted 분기에서 *어느 projectile이 부딪쳤는지* 알아야 그것만 제거할 수 있거든.

### 매직 넘버 0건

모든 숫자가 `GameConfig.swift`의 `// MARK: - Skill (Phase 9-5)` 섹션에 모여 있어. 코드에는:

```swift
GameConfig.dashClimbDistance       // 60
GameConfig.dashClimbDuration       // 0.26
GameConfig.bookClubRallyRadius     // 120
GameConfig.charmStudentDuration    // 1.5
GameConfig.taiwanTripJumpDistance  // 100
GameConfig.breakableWallName       // "breakableWall"
```

같은 식으로 *이름이 붙은 상수*만 등장. 22, 20, 0.26, 60 같은 *날 숫자*는 절대 코드에 직접 안 적었어.

### Timer 0건 — SKAction.sequence 사용

스킬 효과 지속 시간 관리는 두 방식이 섞여 있어:
1. SkillSystem.update에서 dt 감산 (cooldown/duration)
2. SKAction.sequence로 콜백 등록 (돌진 끝/텔레포트 끝)

둘 다 *SpriteKit 게임 루프 안*에서 도는 거라 자연스러워. `Timer.scheduledTimer`는 단 한 줄도 없어 — Foundation Timer는 별도 RunLoop에서 도는 거라 SpriteKit과 어울리지 않거든.

### `[weak self]` + `guard let self` 패턴

```swift
skillButton.onTap = { [weak self] in
    self?.skillSystem.tryActivate()
}
```

`self?.`로 *self가 살아 있을 때만* 호출. SkillSystem 내부에서도:

```swift
let endAction = SKAction.run { [weak player] in
    player?.isInvulnerable = false
}
```

player까지 weak로 잡았어. SKAction.run 클로저가 player를 강하게 잡으면 *씬 전환 시 player가 해제 안 되는* 누수 잠재 위험.

### enumerate는 *발동 시 1회만*

`enumerateChildNodes`는 worldNode의 자식을 *전부 순회*하는 무거운 연산이야. SkillSystem의 enumerate 4 지점은 다 *발동 직후 1회*만 호출돼 — 매 프레임이 아니야:

- `performBookClubRally`: 발동 시 1회 (음표 끌어모음)
- `performCharmStudent`: 발동 시 1회 (F → A 변신)
- `breakFirstBreakableWall`: 발동 시 1회 (벽 1개 깨기)
- `onDurationExpired`: 1.5초 만료 시 1회 (enchanted 해제)

매 프레임 60Hz로 1100+ 노드를 도는 건 성능 자살. *이벤트 순간에만* 도는 게 핵심.

---

## 회귀 방지 (안 건드린 부분)

이번에도 *건드리지 않은 영역*이 진짜 핵심:

| 영역 | 상태 |
|---|---|
| 외곽 벽 `addOuterWalls()` | 0줄 변경 |
| Phase 9-4 normal 맵 좌표 | 0줄 변경 (`addNormalMap` 함수 본체는 그대로, `breakable: true` 인자만 추가) |
| 체크보드 바닥 `addCheckerboardFloor` | 0줄 변경 |
| 카메라 follow `cameraNode.position = player.position` | 0줄 변경 |
| Player/Enemy 픽셀 아트 | 0줄 변경 |
| HUD 4슬롯(TIME/SCORE/COMBO/PLAYER) | 0줄 변경 |
| DPadNode | 0줄 변경 |
| ScoreSystem.start/recordNoteHit | 0줄 변경 (메서드 하나만 *추가*) |
| SpawnSystem.start/stop | 0줄 변경 (fireProjectile 본문 1줄만 추가) |

새로 *추가*만 했고 *수정*은 최소화. 추가는 안전, 수정은 위험. 이게 회귀 방지의 황금 원칙.

Spring 비유 — 기존 Service에 새 메서드 *추가*는 안전하지만, 기존 메서드 *시그니처 변경*은 모든 호출자가 영향을 받아 위험.

---

## 자주 헷갈리는 부분

### "왜 김간호 cooldown이 1초야? .infinity가 더 자연 아닌가?"

`progress` 계산식 안에 `cooldownRemaining / activeSkill.cooldown`이 들어가. 만약 cooldown이 0이면 *0으로 나누기* 에러가 나. .none은 어차피 tryActivate에서 차단되니까 실제 사용 안 되지만, *division-by-zero 회피용 sentinel*로 1을 줬어.

Spring 비유 — DTO에 nullable 필드를 `Optional.of(0)`이 아니라 `Optional.empty()`로 두면 NPE가 안 나는 것과 같은 *안전망*.

### "왜 임간호 cooldown은 .infinity야?"

임간호는 게임당 1회 한정(oncePerGame). 1회 쓰면 *남은 게임 시간 동안 영원히 못 씀*이라는 의미를 cooldown=.infinity로 표현. progress 계산에선 *cooldown 무관* 분기로 빠지지만(usedThisGame 가드), enum의 의미적 일관성을 위해 .infinity로 통일.

### "왜 breakableWall 이름을 GameConfig 상수로 빼뒀어? 그냥 'breakableWall' 직접 적으면 되지 않아?"

문자열 리터럴이 *두 군데*(설정 시점 + 검색 시점)에 등장하면 오타 위험. 한쪽이 "breakableWall"이고 다른 쪽이 "breakable_wall"이면 *조용히* enumerate가 빈 결과를 반환해서 디버그가 어려워. 상수로 빼두면 *단일 진실 원천*이라 오타 0.

Spring 비유 — 설정 키 `"app.batch.size"`를 코드 양쪽에 두 번 적는 대신 `Constants.BATCH_SIZE_KEY` 한 곳에 정의하는 패턴.

### "SKAction.move(to:)는 부드러운가? 텔레포트는 즉시 점프인데?"

- 돌진(.dashClimb): `SKAction.move(to:duration: 0.26)` → *0.26초 동안 부드럽게 이동*
- 텔레포트(.taiwanTrip): `player.position = targetPosition` → *즉시 점프*

같은 위치 변경이지만 *지속 시간을 줘서 보간*하면 부드럽고, *직접 대입*하면 즉시야. 게임 톤에 맞춰 골랐어.

### "physicsWorld.body(at:)는 뭐야?"

`physicsWorld.body(at: CGPoint)` — *그 좌표에 물리 바디가 있나*를 묻는 SpriteKit API. 벽이 있으면 `SKPhysicsBody?`가 nil이 아닌 값으로 돌아옴. 텔레포트 후보를 *벽이랑 겹치지 않는지* 확인하는 데 썼어.

Spring 비유 — `userRepository.findById(id).isPresent()` 같은 *존재 검사*. 있으면 true, 없으면 false.

---

## 다음 Phase 미리보기

- 스킬 사운드/햅틱이 아직 없어. 발동 시 *짧은 효과음 + 진동*을 추가하면 손맛 폭발할 듯.
- 정간호 돌진할 때 *잔상 효과*(SKEmitterNode 파티클)를 깔면 시각이 더 강해질 거야.
- 임간호 매혹 발동할 때 *화면 전체에 짧은 분홍 플래시*를 깔면 "마법이 일어난다"는 톤이 살아.
- 이간호 텔레포트 시 *원본 자리에 잔상 1프레임*을 남기면 *순간이동* 톤이 더 살 거야.

이번 sprint는 *시스템 골격*만 세웠고, *시각/청각 폴리싱*은 다음 phase로 미뤘어.
