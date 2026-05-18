# 자체 점검 — Phase 7-2 · Hard 맵 도입

## git 상태

```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
modified:   GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift
```

```
 .../GanhoMusic Shared/Config/GameConfig.swift      |  51 ++++++++++
 GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift | 113 ++++++++++++++++++++-
 2 files changed, 163 insertions(+), 1 deletion(-)
```

신규 파일 0건. pbxproj 변경 0건.

---

## 변경 위치 파일:라인 매핑

### Config/GameConfig.swift
- L483~535 — `// MARK: - Hard Map (Phase 7-2)` 섹션 신설.
  - 좌상 방 7 상수 (L487~493)
  - 우상 방 7 상수 (L496~502)
  - 좌하 방 7 상수 (L505~511)
  - 우하 방 7 상수 (L514~520)
  - 중앙 기둥 12 상수 (L523~534)
- 총 **40 상수** — SPEC §"GameConfig 신규 상수" ~30개 명세 충족(SPEC가 7×4=28 방 + 12 중앙 = 40을 "~30"으로 추산했음. SPEC 표 + 코드 블록과 라인 단위 1:1 일치).
- 기존 상수 미접촉.

### GameScene+Setup.swift
- L19~23 — `setupWorld()` 본체 교체. `addOuterWalls() + addCentralPillar()` 직접 호출 → `setupMap()` 단일 호출.
- L27~34 — `setupMap()` 신설. `addOuterWalls()` 후 `switch difficulty` 분기. case `.easy` → addCentralPillar / case `.normal, .hard` → addHardMap. **default 미사용**.
- L38~100 — `addHardMap()` 신설. 코너 방 4개(가로벽+세로벽 = 8호출) + 중앙 기둥 4 호출.
- L102~104 — `private func addHorizontalWall(cStart:cEnd:r:)` 신설.
- L107~111 — `private func addVerticalWall(c:rStart:rEnd:doorR:)` 신설. `for r in rStart...rEnd where r != doorR { addRectPillar(...) }` — 문 한 칸 건너뛰며 SKSpriteNode 분리.
- L116~136 — `private func addRectPillar(cStart:cEnd:rStart:rEnd:)` 신설. PhysicsBody 7줄은 addCentralPillar와 byte-equal.

---

## 회귀 0 영역 검증 (git diff 0줄)

`git diff --name-only` 결과 — 변경 파일만:
```
GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift
SPEC.md / SELF_CHECK.md / QA_REPORT.md  (산출물, 코드 외)
```

지정된 회귀 0 영역 모두 0줄 변경 확인:
- `GameScene.swift` — diff 0줄
- `TitleScene.swift` — diff 0줄
- `ResultScene.swift` — diff 0줄
- `Nodes/` 디렉터리 전체 — 0줄 (PlayerNode, EnemyNode, StoneGuardNode, ProjectileNode, NoteNode, DPadNode, HUDNode, 자가소멸 9 노드 포함)
- `Systems/` 디렉터리 전체 — 0줄 (ContactRouter, ScoreSystem, SpawnSystem, CameraShakeAction)
- `Managers/` 디렉터리 전체 — 0줄 (Audio/BGM/Haptics)
- `Models/` 디렉터리 전체 — 0줄 (Difficulty 포함)
- `Repositories/` 디렉터리 전체 — 0줄
- `Protocols/` 디렉터리 전체 — 0줄
- `Config/ColorTokens.swift` / `Config/PhysicsCategory.swift` / `Config/GameState.swift` — 0줄
- `GanhoMusic iOS/` / `GanhoMusic tvOS/` / `GanhoMusic macOS/` — 0줄 (각 플랫폼 GameViewController 포함)
- `GanhoMusic.xcodeproj/` — 0줄 (pbxproj 미접촉, 신규 파일 0개)

---

## 빌드 결과

```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
           -target "GanhoMusic iOS" \
           -sdk iphonesimulator \
           EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" \
           clean build
```

**`** BUILD SUCCEEDED **`** — 컴파일 에러 0건.

경고 grep (`warning:` 패턴, AppIntents.framework 알림 제외):
- **0건** — Swift 컴파일러 경고 없음.

---

## PhysicsBody 7줄 비교 (addCentralPillar vs addRectPillar)

```bash
diff <(sed -n '127,133p' GameScene+Setup.swift) \
     <(sed -n '205,211p' GameScene+Setup.swift)
```

**결과: diff 0줄 (byte-equal 달성)**

addCentralPillar (L127~133) / addRectPillar (L205~211) 양쪽 모두 정렬·공백·식별자 완전 동일:
```swift
        let body = SKPhysicsBody(rectangleOf: pillarSize)
        body.isDynamic           = false
        body.friction            = 0
        body.restitution         = 0
        body.categoryBitMask     = PhysicsCategory.wall
        body.collisionBitMask    = 0
        body.contactTestBitMask  = 0
```

→ SPEC §"주의사항 1" 충족.

---

## SPEC §"옵션 C 최종 좌표 표" 코드 매핑 검증

### 코너 방 4개

| 방 | SPEC c/r | GameConfig 상수 | addHardMap 호출 라인 |
|---|---|---|---|
| 좌상 방 H-Wall c4~9, r=18 | hardMapTopLeftRoomHWallCStart=4, CEnd=9, R=18 | L43~45 |
| 좌상 방 V-Wall c=9, r=18~21, door=20 | hardMapTopLeftRoomVWallC=9, RStart=18, REnd=21, DoorR=20 | L46~49 |
| 우상 방 H-Wall c38~43, r=18 | hardMapTopRightRoomHWallCStart=38, CEnd=43, R=18 | L52~54 |
| 우상 방 V-Wall c=38, r=18~21, door=20 | hardMapTopRightRoomVWallC=38, RStart=18, REnd=21, DoorR=20 | L55~58 |
| 좌하 방 H-Wall c4~9, r=5 | hardMapBottomLeftRoomHWallCStart=4, CEnd=9, R=5 | L61~63 |
| 좌하 방 V-Wall c=9, r=2~5, door=3 | hardMapBottomLeftRoomVWallC=9, RStart=2, REnd=5, DoorR=3 | L64~67 |
| 우하 방 H-Wall c38~43, r=5 | hardMapBottomRightRoomHWallCStart=38, CEnd=43, R=5 | L70~72 |
| 우하 방 V-Wall c=38, r=2~5, door=3 | hardMapBottomRightRoomVWallC=38, RStart=2, REnd=5, DoorR=3 | L73~76 |

8 호출 = 4 방 × (가로벽 1 + 세로벽 1). ✅ 한 셀 오차 없음.

### 중앙 기둥 4개

| 기둥 | SPEC c/r | GameConfig 상수 | addHardMap 호출 라인 |
|---|---|---|---|
| 중앙-좌 (1×2) | c=17, r=11~12 | hardMapCenterLeftPillarC=17, RStart=11, REnd=12 | L80~83 |
| 중앙-우 (1×2) | c=30, r=11~12 | hardMapCenterRightPillarC=30, RStart=11, REnd=12 | L85~88 |
| 중앙-상 (2×1) | c=23~24, r=15 | hardMapCenterTopPillarCStart=23, CEnd=24, R=15 | L90~93 |
| 중앙-하 (2×1) | c=23~24, r=8 | hardMapCenterBottomPillarCStart=23, CEnd=24, R=8 | L95~98 |

4 호출. ✅ 한 셀 오차 없음.

**총 12 호출 = 가로벽 4 + 세로벽 4 + 중앙 기둥 4** → SPEC §"기능 2" 명세 완전 충족.

---

## SPEC §"주의사항" 13개 항목 준수 여부

| # | 항목 | 준수 |
|---|---|---|
| 1 | PhysicsBody 정책 완전 일치 (byte-equal) | ✅ diff 0줄 |
| 2 | 벽 색 `.ganhoPaper` 1종만 (새 토큰 0건) | ✅ ColorTokens 미접촉 |
| 3 | 타일 좌표 → 픽셀 변환 (anchorPoint 기본 .center) | ✅ `((cStart + widthTiles/2) × t, (rStart + heightTiles/2) × t)` |
| 4 | SpriteKit y 위로 증가 (SPEC 표가 이미 변환됨) | ✅ 표 값 그대로 사용, 추가 변환 없음 |
| 5 | 외곽 벽 중복 방지 (hard r∈[2,21], c∈[4,43] 내부) | ✅ 외벽 r=0/23, c=0/47과 겹침 0 |
| 6 | 문은 세로벽에서만 분기 (가로벽 doorC 없음) | ✅ addHorizontalWall에 doorC 매개변수 없음 |
| 7 | 세로벽 SKSpriteNode 분리 (통짜 금지) | ✅ `for r ... where r != doorR { addRectPillar(...) }` |
| 8 | setupWorld 호출 순서 보존 | ✅ position=.zero → addChild → setupMap |
| 9 | normal/hard 공용 정책 (`case .normal, .hard`) | ✅ switch에서 동일 분기 |
| 10 | easy 무변경 (기존 addCentralPillar와 완전 동일) | ✅ case .easy → addCentralPillar 호출 |
| 11 | switch default 미사용 (Difficulty 확장 시 경고) | ✅ default 없음 |
| 12 | stoneGuard 시각 겹침 — 본 sprint 미접촉 | ✅ stoneGuardWaypoints 미접촉, normal 분기 미접촉 |
| 13 | NoteSpawn / ProjectileSpawn 무관 | ✅ SpawnSystem 미접촉 |

---

## 정적 검사 결과

| 패턴 | 결과 |
|---|---|
| 강제 언래핑 `!` | **0건** — guard let/if let만 사용 |
| 매직 넘버 | **0건** — 모든 좌표는 GameConfig 상수 |
| Timer | **0건** — 시간 기반 로직 없음 (정적 맵 setup) |
| DispatchQueue | **0건** — 비동기 작업 없음 |
| print() 디버그 | **0건** |
| weak self | 해당 없음 — 클로저 미사용 (정적 setup 함수) |

---

## SPEC 기능 체크

- [x] **기능 1**: setupMap() 분기 도입 — setupWorld가 setupMap() 단일 호출. switch difficulty에서 .easy → addCentralPillar / .normal, .hard → addHardMap.
- [x] **기능 2**: addHardMap() — 코너 방 4개(8 호출) + 중앙 기둥 4 호출, SPEC 좌표 표 100% 일치.
- [x] **기능 3**: 헬퍼 3개 — addRectPillar / addHorizontalWall / addVerticalWall 모두 private.
- [x] **GameConfig 상수**: hard 맵 상수 40개 `// MARK: - Hard Map (Phase 7-2)` 섹션 신설.

---

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수
- guard let / if let / switch 사용: 해당 없음(정적 맵, 분기는 switch case 사용)
- MARK 섹션 구분: 준수 (`// MARK: - Hard Map (Phase 7-2)`)
- GameConfig 상수 사용: 준수 (모든 타일 좌표 상수화)
- weak self 캡처: 해당 없음 (클로저 0건)

---

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 해당 없음(GameScene 본체 미접촉. setupMap은 setupWorld가 호출)
- dt 기반 이동: 해당 없음 (정적 맵)
- SKAction 스폰 패턴: 해당 없음 (반복 스폰 없음)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (정적 벽)
- HUD 노드 분리: 해당 없음 (HUD 미접촉)
- PhysicsBody 정책 일관성 (addRectPillar = addCentralPillar): 준수 (byte-equal)
- worldNode 자식으로 추가: 준수 (`worldNode.addChild(pillar)`)

---

## 빌드 상태

- 컴파일 에러: **0건**
- 컴파일 경고: **0건** (AppIntents 정보성 알림 제외)
- BUILD SUCCEEDED ✅

---

## 범위 외 미구현 항목

- 없음. SPEC §"Sprint 범위 계약"의 "허용" 항목만 구현. "금지" 항목 모두 미접촉:
  - 원본 normal 전용 중간 맵 별도 구현 ❌ 미구현
  - 이교수 NPC, 석조무사 hard 분기, 컷씬, 졸업장 ❌ 미구현
  - addCentralPillar / addOuterWalls 기존 동작 변경 ❌ 미접촉 (byte-equal)
  - 플레이어/적/석조무사 스폰 좌표 변경 ❌ 미접촉
  - 새 색 토큰 ❌ `.ganhoPaper` 1종만 사용
