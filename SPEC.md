# Phase 9-5 — 캐릭터별 스킬 시스템 4종

## 개요
4 캐릭터(정/건/임/이)에게 능동 스킬 1개씩, 김간호는 스킬 없음. 화면 좌하단 신규 스킬 버튼(SkillButtonNode)을 1탭하면 SkillSystem이 활성 스킬을 발동하고 쿨다운 누적을 update(_:currentTime:)에서 진행, 좌하단 SkillButtonNode 위쪽에 HUDSkillSlotNode를 두어 진행률 0.0~1.0을 시각화한다. Phase 9-4의 normal 맵·체크보드 바닥·외곽 벽·HUD 4슬롯 레이아웃은 손대지 않는다.

## 변경 유형
**게임플레이** — 스킬 시스템 신설. (시각 토큰/맵/픽셀 아트는 무변경)

## 게임 경험 의도
"능력치는 전원 동일, 외형·이름·스킬만 차별화"(GDD §4)에 처음으로 *스킬*이 들어오는 단계. 사용자(자전적 김간호 정체성)는 *김간호를 스킬 없이* 정공법으로 플레이하고, 나머지 4 동료는 각자 작곡 시간을 *훔치는 방식*이 다르다. 정간호=*물리적 돌파*(곡괭이로 벽 부수기), 건간호=*주변을 끌어모음*(북클럽 소집), 임간호=*시험기간 매혹*(F→A 매혹, 1회 강력), 이간호=*도망과 회복*(텔레포트+무적).

## Sprint 범위 계약

### 허용
1. 신규 enum `PlayerSkill` (Models/PlayerSkill.swift) — case kim/jung/geon/im/lee + 메타데이터 computed property(cooldown/duration/oncePerGame).
2. 신규 클래스 `SkillSystem` (Systems/SkillSystem.swift) — 활성 스킬 보유, update(dt:) 호출, 진행률 closure로 HUD에 push.
3. 신규 노드 `HUDSkillSlotNode` (Nodes/HUDSkillSlotNode.swift) — 라벨 + 값 + 쿨다운 진행 링 1개. `update(progress:)` API 노출.
4. 신규 노드 `SkillButtonNode` (Nodes/SkillButtonNode.swift) — cameraNode 자식, 좌하단 고정, 1탭 발동 콜백.
5. `CharacterID`에 `skill: PlayerSkill` computed property 1개 추가.
6. `PlayerNode`에 `isInvulnerable: Bool` 프로퍼티 추가. `ContactRouter` 콜백에서 가드.
7. `ProjectileNode`에 `isEnchanted: Bool`, `applyEnchanted()`, `clearEnchanted()` 추가.
8. `GameScene`에 SkillSystem/SkillButton/HUDSkillSlot 프로퍼티 + setup/layout 메서드 추가. `update`에 cooldown/progress 2줄 추가.
9. `GameConfig`에 `MARK: - Skill (Phase 9-5)` 신설.
10. `addRectPillar`/`addVerticalWall`에 `breakable: Bool = false` 파라미터 추가. breakable=true 벽에 `name = "breakableWall"` set. **장식 기둥/외곽 벽/hard 맵의 모든 벽은 breakable: false 유지**.
11. **ContactRouter.onProjectileHitPlayer 시그니처에 SKNode 인자 1개 추가 허용** (enchanted 분기 필수).
12. `SpawnSystem.fireProjectile` 본문 안에 enchanted 가드 1줄 추가 (시그니처 보존).
13. `ScoreSystem`에 `recordCharmedNoteHit` 메서드 1개 추가 (시그니처 보존).

### 금지
1. SPEC에 없는 시각 토큰 신설.
2. Phase 9-4 normal 맵 좌표/구조 변경.
3. 외곽 벽 좌표·크기·물리 정책 변경.
4. 카메라 follow/픽셀 아트/걷기 애니메이션 변경.
5. HUD 4슬롯(TIME/SCORE/COMBO/PLAYER) 위치/폰트 변경.
6. ScoreSystem/SpawnSystem.start/stop 시그니처 변경.
7. DPadNode 변경.
8. Difficulty/CharacterID 케이스 추가.

### 판단 기준
"이 변경 없이 SPEC 기능(4 스킬 발동 + 쿨다운 시각화 + 김간호 빈 슬롯)이 정상 동작하는가?" → NO면 허용, YES면 금지.

## 스킬 트리거 방식 (Planner 결정)

**채택: 화면 좌하단 신규 SkillButtonNode (1탭 발동, cameraNode 자식, 알파 0.7 반투명 원형).**

근거:
- D-Pad가 *우하단* 점유 → 사용자가 오른손 엄지로 D-Pad 누른 채 왼손 엄지로 스킬 발동.
- "두 손가락 탭" 제스처는 D-Pad 터치와 충돌.
- GDD docs/GDD.md L139 "D-Pad 왼쪽 스킬 버튼 (웹: Shift 키)" 의도와 정확 일치.
- 김간호 선택 시 버튼은 isUserInteractionEnabled = false + alpha 0.3 + 라벨 "—".

위치/크기: `GameConfig.skillButtonRadius = 32pt`. 좌하단 마진 `skillButtonMarginX/Y = 90, 90` (D-Pad 대칭).

## 스킬 시스템 아키텍처

### 데이터 모델 (Models/PlayerSkill.swift, 신규)

```swift
enum PlayerSkill {
    case none           // 김간호
    case dashClimb      // 정간호 — 암벽등반 돌진
    case bookClubRally  // 건간호 — 북클럽 소집
    case charmStudent   // 임간호 — 나는야 모범생 (게임당 1회)
    case taiwanTrip     // 이간호 — 대만여행

    var displayName: String
    var cooldown: TimeInterval
    var duration: TimeInterval
    var oncePerGame: Bool
}
```

`CharacterID.skill: PlayerSkill` computed property — 5 case 분기.

### 컨트롤러 (Systems/SkillSystem.swift, 신규)

```swift
final class SkillSystem {
    private(set) var activeSkill: PlayerSkill = .none
    private(set) var cooldownRemaining: TimeInterval = 0
    private(set) var durationRemaining: TimeInterval = 0
    private(set) var usedThisGame: Bool = false
    private weak var scene: GameScene?

    func update(dt: TimeInterval) { ... }
    func tryActivate() { ... }
    func configure(scene: GameScene, skill: PlayerSkill) { ... }
    var progress: CGFloat { ... }
    var isDashing: Bool { ... }
    var isCharmActive: Bool { ... }
}
```

**단방향 의존**: SkillSystem → GameScene/Player/Note enumerate 직접 호출. HUD는 GameScene update 흐름 안에서 `hudSkill.update(progress: skillSystem.progress)` 1줄 호출.

### 트리거 노드 (Nodes/SkillButtonNode.swift, 신규)

```swift
final class SkillButtonNode: SKNode {
    var onTap: () -> Void = {}
    func setEnabled(_ enabled: Bool)
}
```

32pt 반지름 원형. ganhoUIBrand20 채움 + ganhoUIBrand 1pt 외곽선. touchesBegan에서 onTap() 호출.

## 각 스킬 4개 상세 설계

### 1. 정간호 — 암벽등반 돌진 (.dashClimb)

| 항목 | 값 |
|---|---|
| 이동 거리 | 3 tile = 60pt (`GameConfig.dashClimbDistance`) |
| 지속 시간 | 0.26초 (`GameConfig.dashClimbDuration`) |
| 쿨다운 | 22초 (`GameConfig.dashClimbCooldown`) |
| 방향 | DPadNode.currentDirection. .zero면 lastDirection, 그것도 zero면 .right(1, 0) |
| 무적 | 돌진 중(0.26초) `player.isInvulnerable = true` |
| 벽 부수기 | 돌진 경로의 *breakableWall name 가진 벽 1칸*만 파괴 |

**구현 방향**:
1. 방향 벡터 추출 (DPad.currentDirection → SkillSystem.lastDirection → 기본 우측).
2. 시작/끝 좌표 계산.
3. 벽 1칸 식별: `scene.worldNode.enumerateChildNodes(withName: GameConfig.breakableWallName)` → 선분 거리 검사, 첫 발견 노드 fadeOut+removeFromParent.
4. `player.run(.move(to: target, duration: dashClimbDuration), completion: { isInvulnerable=false })`. 시작 직전 isInvulnerable = true.
5. 돌진 중 D-Pad 입력 무시: `skillSystem.isDashing` 게이트로 update의 currentDirection 갱신 1줄 가드.

**벽 부수기 판정**: normal 맵의 분리벽 호출(`addVerticalWall`)에서만 `breakable: true`. 외곽 벽/장식 기둥/hard 맵 모든 벽은 breakable:false → name 없음(또는 nil) → enumerate 결과에 안 잡힘.

### 2. 건간호 — 북클럽 소집 (.bookClubRally)

| 항목 | 값 |
|---|---|
| 반경 | 120pt (`GameConfig.bookClubRallyRadius`) |
| 지속 시간 | 즉발 (duration = 0) |
| 쿨다운 | 20초 (`GameConfig.bookClubRallyCooldown`) |
| 끌어오기 액션 | SKAction.move(to: player.position, duration: 0.4, .easeIn) |
| F 음표 처리 | **F는 끌어오지 않음** — 음표만 |

**구현 방향**:
1. `scene.worldNode.enumerateChildNodes(withName: "note")` → 거리 < 120 인 음표에 SKAction.move.
2. 도착 시점 player와 자연 contact → ContactRouter.onNoteCollected 정상 발화 → 점수/콤보 자동.

### 3. 임간호 — 나는야 모범생 / 매혹 (.charmStudent)

| 항목 | 값 |
|---|---|
| 지속 시간 | 1.5초 (`GameConfig.charmStudentDuration`) |
| 쿨다운 | 게임당 1회 (`.infinity`) |
| 효과 대상 | 모든 활성 ProjectileNode(F) → 1.5초 enchanted (수집 가능 A) |
| 시각 표현 | color = .ganhoPinkNote + isEnchanted = true |
| 새로 발사되는 F | 윈도우 안 출생 즉시 enchanted (SpawnSystem.fireProjectile 가드) |
| 점수 보너스 | enchanted 수집 시 `recordCharmedNoteHit` (scorePerNoteCombo × 2) |

**구현 방향**:
1. usedThisGame = true 즉시 set.
2. enumerate "projectile" → applyEnchanted() 호출.
3. durationRemaining = 1.5. 만료 시 endCharmStudent() → enumerate로 clearEnchanted.
4. **ContactRouter.onProjectileHitPlayer 시그니처에 SKNode 인자 추가** + GameScene 콜백 본문에서 `if let p = node as? ProjectileNode, p.isEnchanted { scoreSystem.recordCharmedNoteHit(...); p.removeFromParent(); return }` 가드.

### 4. 이간호 — 대만여행 / 텔레포트 (.taiwanTrip)

| 항목 | 값 |
|---|---|
| 지속 시간(무적) | 0.5초 (`GameConfig.taiwanTripInvulnerableDuration`) |
| 쿨다운 | 22초 (`GameConfig.taiwanTripCooldown`) |
| 텔레포트 거리 | 5 tile = 100pt (`GameConfig.taiwanTripJumpDistance`) |
| 방향 후보 | 4방향 랜덤 셔플, 맵 경계 + 벽 미겹침인 첫 후보 채택 |
| 무적 표현 | alpha 0.4 ↔ 1.0 깜빡임 (SKAction.repeat) |

**구현 방향**:
1. 4 후보 배열 shuffled.
2. 각 후보에 대해 맵 경계 + physicsWorld.body(at:) 검사.
3. 첫 성공 후보로 player.position 즉시 set.
4. isInvulnerable = true + 깜빡임 액션. 0.5초 후 완료 콜백에서 false + alpha 1.0 복원.

**무적 가드 단일 정책**: PlayerNode.isInvulnerable: Bool = false. ContactRouter 콜백에서 onEnemyHit / onProjectileHitPlayer 양쪽에 가드 1줄.

## HUD 연동

### HUDSkillSlotNode 시그니처 (신규)

```swift
final class HUDSkillSlotNode: SKNode {
    init()
    func configure(skill: PlayerSkill)
    func update(progress: CGFloat)
}
```

### update(progress:) 호출 패턴
- 0.0 ~ 1.0 (CGFloat).
- 매 프레임 GameScene.update 끝에서 1줄 호출.
- `SkillSystem.progress`:
  - 김간호: 항상 1.0.
  - 임간호 oncePerGame & usedThisGame=true: 0.0 영구.
  - 일반: cooldownRemaining=0이면 1.0, 아니면 `1.0 - cooldownRemaining / activeSkill.cooldown`.

### 상태 시각
- 사용 가능(progress=1.0): ring 완전 채움 `.ganhoUIBrandLight`.
- 쿨다운 중(0<p<1): ring 채움 비율 = progress, `.ganhoUIBrand40`.
- 1회 소진: ring 채움 0, value dim.
- 김간호: ring alpha 0, value "—" dim.

### HUD 5번째 슬롯 배치
- 기존 HUDNode(상단 4슬롯)는 **0줄 변경**.
- HUDSkillSlotNode는 좌하단 SkillButtonNode 바로 위 (cameraNode 자식). GameScene.layoutHUD는 변경 안 함, 신규 layoutHUDSkillSlot 추가.

### 김간호 표시
- SkillButtonNode alpha 0.3 + "—" + isUserInteractionEnabled=false.
- HUDSkillSlotNode value "—" dim + ring alpha 0.

## 회귀 방지

| 영역 | 상태 |
|---|---|
| 외곽 벽 (addOuterWalls) | 0줄 변경 |
| Phase 9-4 normal 맵 좌표 (GameConfig.normalMap*) | 0줄 변경 |
| Phase 9-4 체크보드 바닥 (addCheckerboardFloor) | 0줄 변경 |
| 카메라 follow (cameraNode.position = player.position) | 0줄 변경 |
| Player/Enemy 픽셀 아트 | 0줄 변경 |
| HUD 4슬롯 레이아웃 (TIME/SCORE/COMBO/PLAYER) | 0줄 변경 |
| DPadNode | 0줄 변경 |
| ScoreSystem 시그니처 | 0줄 변경 (recordCharmedNoteHit 메서드 추가 가능) |
| SpawnSystem.start/stop 시그니처 | 0줄 변경 (fireProjectile 본문 1줄 가드 허용) |
| ContactRouter 시그니처 | onProjectileHitPlayer만 SKNode 인자 1개 추가 |

## 매직 넘버 정책

### GameConfig.swift 신규 MARK 섹션

```swift
// MARK: - Skill System (Phase 9-5)

// 공통
static let skillButtonRadius: CGFloat = 32
static let skillButtonMarginX: CGFloat = 90
static let skillButtonMarginY: CGFloat = 90
static let skillButtonInactiveAlpha: CGFloat = 0.3
static let skillButtonActiveAlpha: CGFloat = 0.85
static let hudSkillSlotOffsetY: CGFloat = 50

// 정간호
static let dashClimbDistance: CGFloat = 60
static let dashClimbDuration: TimeInterval = 0.26
static let dashClimbCooldown: TimeInterval = 22

// 건간호
static let bookClubRallyRadius: CGFloat = 120
static let bookClubRallyMoveDuration: TimeInterval = 0.4
static let bookClubRallyCooldown: TimeInterval = 20

// 임간호
static let charmStudentDuration: TimeInterval = 1.5
static let charmStudentBonusScore: Int = 4

// 이간호
static let taiwanTripJumpDistance: CGFloat = 100
static let taiwanTripInvulnerableDuration: TimeInterval = 0.5
static let taiwanTripCooldown: TimeInterval = 22
static let taiwanTripFlashAlpha: CGFloat = 0.4
static let taiwanTripFlashHalfPeriod: TimeInterval = 0.1

// HUDSkillSlot
static let hudSkillSlotRingRadius: CGFloat = 12
static let hudSkillSlotRingLineWidth: CGFloat = 2

// name 식별자
static let breakableWallName: String = "breakableWall"
```

### PlayerSkill computed property 캡슐화
```swift
extension PlayerSkill {
    var cooldown: TimeInterval { switch self { ... } }
    var duration: TimeInterval { switch self { ... } }
    var oncePerGame: Bool { switch self { ... } }
    var displayName: String { switch self { ... } }
}
```

## 파일 변경 요약

### 수정할 파일
- `GameScene.swift`: skillSystem/skillButton/hudSkill 프로퍼티 + update 2줄 + configureContactRouter 가드 + startGameProperly 1줄
- `GameScene+Setup.swift`: setupSkillButton/setupHUDSkillSlot/layout 4 메서드 + addRectPillar/addVerticalWall `breakable` 파라미터 + normal 맵 호출에 `breakable: true`
- `Models/CharacterID.swift`: `var skill: PlayerSkill` computed property
- `Nodes/PlayerNode.swift`: `var isInvulnerable: Bool = false`
- `Nodes/ProjectileNode.swift`: `var isEnchanted: Bool`, applyEnchanted/clearEnchanted
- `Systems/ContactRouter.swift`: onProjectileHitPlayer (SKNode) 인자 추가
- `Systems/SpawnSystem.swift`: fireProjectile 본문 enchanted 가드 1줄
- `Systems/ScoreSystem.swift`: recordCharmedNoteHit 메서드 추가
- `Config/GameConfig.swift`: MARK: - Skill 섹션

### 추가할 파일
- `Models/PlayerSkill.swift`
- `Systems/SkillSystem.swift`
- `Nodes/SkillButtonNode.swift`
- `Nodes/HUDSkillSlotNode.swift`

## 주의사항

1. **PhysicsCategory.wall은 외곽 벽/내부 벽 공용** — `name == "breakableWall"` 필터 필수.
2. **임간호 매혹 중 새 F**: SpawnSystem.fireProjectile에서 `scene as? GameScene`로 캐스팅하여 skillSystem.isCharmActive 조회. start 시그니처 보존.
3. **player.isInvulnerable 시각화**: alpha 깜빡임 SKAction.repeat 사용. 완료 콜백에서 alpha 1.0 강제 복원.
4. **SKAction.move(to:) 도중 player 입력 무시**: skillSystem.isDashing 게이트 가드 1줄.
5. **weak self 캡처**: SKAction.run 클로저 안 `[weak self]` + guard let 필수.

## 평가 가중치

### Swift 패턴 (35%)
- PlayerSkill enum 메타데이터 computed property 캡슐화 — 5 case exhaustive.
- GameConfig 매직 넘버 집중.
- switch default 미사용.

### 게임 로직 (30%)
- cooldown 정확성 (22/20/∞/22).
- 동시 발동 방지 (3중 가드).
- 무적 정확성 (ContactRouter 2지점).

### 성능 (20%)
- enumerate는 발동 시 1회만.
- weak self 누락 시 감점.

### 기능 완성도 (15%)
- 5 캐릭터 분기 (김간호 noop).
- HUDSkillSlotNode 4 상태 시각 구분.
- SkillButtonNode 김간호 비활성화.

---

**판단 기준**: Generator는 위 SPEC을 글자 그대로 채택. Evaluator는 Sprint 범위 계약 허용/금지 목록을 동일 기준으로 채점. 김간호 "스킬 없음"은 *결함이 아니라 의도된 정체성*.
