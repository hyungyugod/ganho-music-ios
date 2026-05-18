# SPEC.md — Phase 7-2 · Hard 맵 도입

## 개요

GDD §6에 명시된 hard 맵을 모바일 48×24 그리드에 도입한다. 원본 웹 게임(`game.js` L289-309) 32×20 hard 맵의 *방 4개 + 중앙 기둥 다수* 디자인을 모바일 좌표계로 충실히 이식하되, *맵 가장자리에서의 절대 거리*는 원본을 유지하고 *중앙 빈 공간만 확장*하는 "옵션 C" 전략을 채택한다. setupMap이 `difficulty` 분기를 통해 easy면 기존 addCentralPillar, normal/hard면 신규 addHardMap을 호출한다.

## 변경 유형
**게임플레이** — 맵 형태가 플레이어/적/F 동선에 직접 영향.

## 게임 경험 의도
easy 맵에서 *넓은 평지* 위 단일 기둥을 익힌 플레이어는 normal/hard 전환 즉시 *코너 방 4개*가 시야에 들어오며 게임의 톤이 달라졌음을 직관한다. 코너 방은 *단기 안식처*(외벽+내벽 협공으로 F가 좁은 입구로만 들어옴)이자 동시에 *함정*(문이 한 칸뿐이라 수간호사가 막아서면 출구 차단)인 양면성을 가진다. 4개 중앙 기둥은 *대칭의 댄스플로어*를 만들어 추격전이 직선이 아닌 곡선 동선이 되도록 유도한다.

## Sprint 범위 계약

- **허용**: hard 맵 좌표 상수 신설(GameConfig), `addHardMap()` 함수 신설(GameScene+Setup), `setupMap()`에 difficulty 분기, normal/hard 같은 hard 맵 공유.
- **금지**:
  - 원본 normal 전용 중간 맵(game.js L272-287) 별도 구현 — GDD §6가 hard 공용으로 결정.
  - 이교수 NPC, 석조무사 hard 미등장 분기, 컷씬, 졸업장.
  - addCentralPillar / addOuterWalls 기존 동작 변경.
  - 플레이어/적/석조무사 기본 스폰 좌표 변경 (§"충돌 검증"에서 무충돌 증명).
  - 새 색 토큰 추가 — 모든 벽 `.ganhoPaper` 재사용.
- **판단 기준**: "이 변경 없으면 hard 맵 정상 동작 안 함?" → YES만 허용.

## 변경 범위
- 수정: `Config/GameConfig.swift`, `GameScene+Setup.swift`
- 신규 파일 0건, pbxproj 변경 0건.

---

## 옵션 비교

| 옵션 | 전략 | 좌상 방 가로벽 c | 우상 방 가로벽 c | 결정 |
|---|---|---|---|---|
| A | 절대 보존 + 정중앙 배치(c+8, r+2) | c12~17 | c30~35 | ❌ |
| B | 비율 ×1.5/×1.2 | c6~14 | c33~41 | ❌ |
| C | **원본 절대 좌표 + 우/하단 거울 대칭** | c4~9 | c38~43 | ✅ |

---

## 옵션 C 최종 좌표 표

좌표계 규약:
- 모바일 그리드: c=0..47, r=0..23. TILE=20pt.
- SpriteKit y는 아래에서 위로 증가. **r이 클수록 시각 상단**.
- 거울 대칭: `mirroredC = 47 - c`, `mirroredR = 23 - r`.
- 원본 game.js의 r=5(원본 캔버스 위쪽) → SpriteKit r=18(시각 상단).

### 코너 방 4개

| 방 | 가로벽 c 범위 | 가로벽 r | 세로벽 r 범위 | 세로벽 c | 문 (c, r) |
|---|---|---|---|---|---|
| 좌상 방(시각 상단·좌) | c4~c9 | r=18 | r=18~21 | c=9 | (9, 20) |
| 우상 방(시각 상단·우) | c38~c43 | r=18 | r=18~21 | c=38 | (38, 20) |
| 좌하 방(시각 하단·좌) | c4~c9 | r=5 | r=2~5 | c=9 | (9, 3) |
| 우하 방(시각 하단·우) | c38~c43 | r=5 | r=2~5 | c=38 | (38, 3) |

### 중앙 기둥 4개

| 기둥 | c 범위 | r 범위 | 모양 |
|---|---|---|---|
| 중앙-좌 (세로형) | c=17 | r=11~12 | 1×2 |
| 중앙-우 (세로형) | c=30 | r=11~12 | 1×2 |
| 중앙-상 (가로형) | c=23~24 | r=15 | 2×1 |
| 중앙-하 (가로형) | c=23~24 | r=8 | 2×1 |

---

## GameConfig 신규 상수 (~30개)

`Config/GameConfig.swift` 끝에 `// MARK: - Hard Map (Phase 7-2)` 섹션:

```swift
// 좌상 방
static let hardMapTopLeftRoomHWallCStart:  Int = 4
static let hardMapTopLeftRoomHWallCEnd:    Int = 9
static let hardMapTopLeftRoomHWallR:       Int = 18
static let hardMapTopLeftRoomVWallC:       Int = 9
static let hardMapTopLeftRoomVWallRStart:  Int = 18
static let hardMapTopLeftRoomVWallREnd:    Int = 21
static let hardMapTopLeftRoomDoorR:        Int = 20

// 우상 방
static let hardMapTopRightRoomHWallCStart: Int = 38
static let hardMapTopRightRoomHWallCEnd:   Int = 43
static let hardMapTopRightRoomHWallR:      Int = 18
static let hardMapTopRightRoomVWallC:      Int = 38
static let hardMapTopRightRoomVWallRStart: Int = 18
static let hardMapTopRightRoomVWallREnd:   Int = 21
static let hardMapTopRightRoomDoorR:       Int = 20

// 좌하 방
static let hardMapBottomLeftRoomHWallCStart: Int = 4
static let hardMapBottomLeftRoomHWallCEnd:   Int = 9
static let hardMapBottomLeftRoomHWallR:      Int = 5
static let hardMapBottomLeftRoomVWallC:      Int = 9
static let hardMapBottomLeftRoomVWallRStart: Int = 2
static let hardMapBottomLeftRoomVWallREnd:   Int = 5
static let hardMapBottomLeftRoomDoorR:       Int = 3

// 우하 방
static let hardMapBottomRightRoomHWallCStart: Int = 38
static let hardMapBottomRightRoomHWallCEnd:   Int = 43
static let hardMapBottomRightRoomHWallR:      Int = 5
static let hardMapBottomRightRoomVWallC:      Int = 38
static let hardMapBottomRightRoomVWallRStart: Int = 2
static let hardMapBottomRightRoomVWallREnd:   Int = 5
static let hardMapBottomRightRoomDoorR:       Int = 3

// 중앙 기둥
static let hardMapCenterLeftPillarC:        Int = 17
static let hardMapCenterLeftPillarRStart:   Int = 11
static let hardMapCenterLeftPillarREnd:     Int = 12
static let hardMapCenterRightPillarC:       Int = 30
static let hardMapCenterRightPillarRStart:  Int = 11
static let hardMapCenterRightPillarREnd:    Int = 12
static let hardMapCenterTopPillarCStart:    Int = 23
static let hardMapCenterTopPillarCEnd:      Int = 24
static let hardMapCenterTopPillarR:         Int = 15
static let hardMapCenterBottomPillarCStart: Int = 23
static let hardMapCenterBottomPillarCEnd:   Int = 24
static let hardMapCenterBottomPillarR:      Int = 8
```

---

## 기능 상세

### 기능 1: setupMap() 분기 도입

`setupWorld()`의 `addOuterWalls()` + `addCentralPillar()` 직접 호출을 `setupMap()` 단일 진입점으로 추출 + difficulty 분기.

```swift
func setupWorld() {
    worldNode.position = .zero
    addChild(worldNode)
    setupMap()
}

func setupMap() {
    addOuterWalls()
    switch difficulty {
    case .easy:
        addCentralPillar()
    case .normal, .hard:
        addHardMap()
    }
}
```

switch에 **default 미사용** — Difficulty enum 신규 case 추가 시 컴파일러 경고.

### 기능 2: addHardMap()

옵션 C 좌표 그대로 코너 방 4개 + 중앙 기둥 4개 생성.

```swift
func addHardMap() {
    // 코너 방 4개 (가로벽 + 세로벽 doorR 분기)
    addHorizontalWall(cStart: GameConfig.hardMapTopLeftRoomHWallCStart,
                      cEnd:   GameConfig.hardMapTopLeftRoomHWallCEnd,
                      r:      GameConfig.hardMapTopLeftRoomHWallR)
    addVerticalWall(c:       GameConfig.hardMapTopLeftRoomVWallC,
                    rStart:  GameConfig.hardMapTopLeftRoomVWallRStart,
                    rEnd:    GameConfig.hardMapTopLeftRoomVWallREnd,
                    doorR:   GameConfig.hardMapTopLeftRoomDoorR)
    // … 우상/좌하/우하 동형 …

    // 중앙 기둥 4개
    addRectPillar(cStart: GameConfig.hardMapCenterLeftPillarC,
                  cEnd:   GameConfig.hardMapCenterLeftPillarC,
                  rStart: GameConfig.hardMapCenterLeftPillarRStart,
                  rEnd:   GameConfig.hardMapCenterLeftPillarREnd)
    // … 중앙-우/상/하 동형 …
}
```

### 기능 3: 헬퍼 3개

```swift
private func addHorizontalWall(cStart: Int, cEnd: Int, r: Int) {
    addRectPillar(cStart: cStart, cEnd: cEnd, rStart: r, rEnd: r)
}

private func addVerticalWall(c: Int, rStart: Int, rEnd: Int, doorR: Int) {
    for r in rStart...rEnd where r != doorR {
        addRectPillar(cStart: c, cEnd: c, rStart: r, rEnd: r)
    }
}

private func addRectPillar(cStart: Int, cEnd: Int, rStart: Int, rEnd: Int) {
    let t = GameConfig.tileSize
    let widthTiles  = CGFloat(cEnd - cStart + 1)
    let heightTiles = CGFloat(rEnd - rStart + 1)
    let pillarSize = CGSize(width: widthTiles * t, height: heightTiles * t)
    let pillar = SKSpriteNode(color: .ganhoPaper, size: pillarSize)
    pillar.position = CGPoint(
        x: (CGFloat(cStart) + widthTiles  / 2) * t,
        y: (CGFloat(rStart) + heightTiles / 2) * t
    )
    let body = SKPhysicsBody(rectangleOf: pillarSize)
    body.isDynamic          = false
    body.friction           = 0
    body.restitution        = 0
    body.categoryBitMask    = PhysicsCategory.wall
    body.collisionBitMask   = 0
    body.contactTestBitMask = 0
    pillar.physicsBody = body
    worldNode.addChild(pillar)
}
```

**중요**: `addVerticalWall`이 문(doorR) 한 칸을 *건너뛰는* 구현 — SKSpriteNode가 *상단부+하단부 2개*로 쪼개진다. 통짜로 만들면 PhysicsBody가 문을 막아 플레이어 입장 불가.

---

## 플레이어/적/석조무사 스폰 충돌 검증

### Player 스폰 (mapWidth/4, mapHeight/2) = (240, 240) = (c=12, r=12)
모든 hard 맵 벽(c∈[4,9]∪[17]∪[23,24]∪[30]∪[38,43], r∈[2,5]∪[8]∪[11,12]∪[15]∪[18,21])과 무충돌:
- c=12 → 모든 c 범위 밖
- 또는 r=12 → c=17/30의 r=11~12 범위와 r 일치하지만 **c 다름** → 무충돌

**시프트 불필요**.

### Enemy 스폰 (mapWidth*3/4, mapHeight*3/4) = (720, 360) = (c=36, r=18)
- c=36 → 우상/우하 방 c=38 범위 밖
- 모든 중앙 기둥과 c/r 불일치
- **무충돌**

### StoneGuard waypoint
| Waypoint | 타일 | 충돌 |
|---|---|---|
| (200, 100) | (10, 5) | 무충돌 (좌하 방 c4~9 밖) |
| (760, 100) | (38, 5) | ⚠️ **우하 방 가로벽 r=5 c=38~43 안** — 시각 겹침. PhysicsBody 충돌은 stoneGuard의 collisionBitMask에 wall 미포함 시 시각만. |
| (760, 380) | (38, 19) | ⚠️ **우상 방 세로벽 c=38 r=18~21 안** — 시각 겹침 |
| (200, 380) | (10, 19) | 무충돌 |

**해결**: GDD §5상 StoneGuard는 *normal까지만 등장*, hard 미등장. 현재 코드는 무조건 호출이라 normal에서 시각 겹침 발생 가능. 게임 로직(추적/이스터에그)에는 영향 0 — *별도 sprint*에서 등장 분기 처리. 본 sprint는 waypoint 좌표 미접촉.

### 외곽 벽 중복
- 외벽 r=0/23, c=0/47. hard 맵 좌표 모두 r∈[2,21], c∈[4,43] → **중복 0**.

---

## 회귀 0 자연 차단

| 항목 | 차단 메커니즘 |
|---|---|
| easy 플레이 | switch `.easy` → addCentralPillar 그대로. 한 줄도 안 건드림. |
| 외곽 벽 | setupMap이 addOuterWalls를 *변경 없이* 호출. |
| 플레이어/적 스폰 | §"충돌 검증"에서 무충돌 증명. |
| 음표/F 스폰 시스템 | SpawnSystem 미접촉. 벽 검사는 SpriteKit physics에 위임. |
| HUD/카메라/이스터에그 | 모든 시스템 미접촉. |
| pbxproj | 신규 파일 0개. |

---

## 주의사항 (필독)

1. **PhysicsBody 정책 완전 일치** — addRectPillar의 body 7줄은 addCentralPillar와 byte-equal. category=wall, isDynamic=false, friction=0, restitution=0, collisionBitMask=0, contactTestBitMask=0.

2. **벽 색 `.ganhoPaper` 1종만** — 새 토큰 0건.

3. **타일 좌표 → 픽셀 변환** — anchorPoint 기본값 .center 가정. 직사각형 중심 = `((cStart + widthTiles/2) × tileSize, (rStart + heightTiles/2) × tileSize)`.

4. **SpriteKit y 위로 증가** — 원본 game.js와 *상하 반전*. SPEC 좌표 표는 이미 *SpriteKit r 기준*으로 변환 완료. 원본 r을 그대로 베끼지 말 것.

5. **외곽 벽 중복 방지** — hard 맵 좌표 모두 r∈[2,21], c∈[4,43] 내부. 자연 차단.

6. **문은 세로벽에서만 분기** — 원본 디자인 충실. 가로벽 doorC 매개변수 없음.

7. **세로벽 SKSpriteNode 분리** — doorR 한 칸을 *건너뛰어* 상단부+하단부 2개로 쪼갠다. 통짜 + 빈 픽셀은 PhysicsBody가 문을 막아 플레이어 입장 불가.

8. **setupWorld 호출 순서 보존** — `worldNode.position = .zero` → `addChild(worldNode)` → `setupMap()`.

9. **normal/hard 공용 정책** — GDD §6 "hard맵(normal·hard 공용)" 명시. switch case `.normal, .hard`.

10. **easy 무변경 보장** — easy 분기는 기존 addCentralPillar와 완전 동일.

11. **switch default 미사용** — Difficulty 신규 case 추가 시 컴파일러 경고.

12. **stoneGuard 시각 겹침** — normal에서 우측 코너 방 벽과 stoneGuard가 시각 겹칠 수 있음. 게임 로직 영향 0. *별도 sprint*.

13. **NoteSpawn / ProjectileSpawn 무관** — SpawnSystem 코드 미접촉.

---

## 작업 체크리스트

- [ ] GameConfig.swift 끝에 hard 맵 상수 ~30개.
- [ ] setupWorld()를 setupMap() 단일 호출로 교체.
- [ ] setupMap() 신설 — switch 분기.
- [ ] addHardMap() 신설.
- [ ] 헬퍼 3개 (addRectPillar / addHorizontalWall / addVerticalWall).
- [ ] PhysicsBody 7줄 byte-equal.
- [ ] 강제 언래핑/매직 넘버 0건.
- [ ] 빌드 SUCCEEDED + 시뮬 시 easy/normal/hard 시각 확인.
