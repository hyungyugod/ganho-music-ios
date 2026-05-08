# Phase 4-1 — 석조무사 NPC: 4 waypoint 시계방향 무한 패트롤

## 개요
맵 4지점을 시계방향으로 순환 순찰하는 새 NPC `StoneGuardNode`를 추가한다. 추적 AI(EnemyNode)와 달리 *정해진 길*만 걷는 두 번째 AI 패턴 — `SKAction.repeatForever(.sequence([.move × 4]))`로 구현. 본 sprint는 *시각 등장 + 패트롤 동작*만이며, PhysicsBody/접촉 효과/이스터에그는 일절 OoS.

## 변경 유형
**혼합** — 신규 NPC 노드(게임플레이 객체 추가) + 시각 등장.

## 게임 경험 의도
플레이어는 게임이 시작되면 *맵 한가운데 사각형 동선을 따라 묵묵히 순찰하는 석조무사*를 발견한다. 수간호사처럼 자신을 쫓지 않고 *정해진 길만 걷는다는 사실*이 시각적으로 명확해야 하며, 게임플레이(점수·콤보·F·게임오버 조건) 자체에는 어떠한 영향도 주지 않는다(본 sprint OoS). 다음 sprint(4-2)의 이스터에그 트리거 토대를 *시각적으로 먼저* 깔아두는 작업이다.

## Sprint 범위 계약

### In Scope
- `Nodes/StoneGuardNode.swift` 신설 (final class, init에서 patrol 자동 시작)
- `Config/GameConfig.swift`에 `// MARK: - Stone Guard (Phase 4-1)` 섹션 + 신규 상수 (속도/크기/waypoint 배열)
- `GameScene+Setup.swift`에 `setupStoneGuard()` extension 메서드 신설
- `GameScene.swift` Properties에 `let stoneGuard = StoneGuardNode()` 1줄, `didMove(to:)`에서 `setupStoneGuard()` 호출 1줄
- pbxproj에 신규 Swift 파일 등록 (PBXBuildFile / PBXFileReference / Nodes 그룹 children / iOS Sources phase 4곳)

### Out of Scope
- StoneGuardNode에 `physicsBody` 부착 — `nil` 유지(기본값)
- PhysicsCategory에 `stoneGuard` 비트마스크 신설 (4-2)
- 접촉 시 효과(이스터에그/오버레이/비행기/폭탄/수간호사 도주)
- 박병장·이교주 등 다른 NPC
- 새로운 ColorTokens 토큰 신설 — 기존 토큰만 사용
- tvOS / macOS Sources phase 수정
- update() 게임 루프 변경 (SKAction이 자동 처리)
- 기존 EnemyNode·PlayerNode·NoteNode·ProjectileNode·HUDNode·DPadNode·SpawnSystem·ContactRouter·ScoreSystem·TitleScene·ResultScene·HighScoreRepository·StatisticsRepository 변경

### 판단 기준
"이 변경이 없으면 SPEC 기능(석조무사가 화면에 등장해 사각형 동선을 시계방향으로 무한 순회)이 동작하는가?" → NO만 허용.

## 변경 범위

### 신설 파일
- `GanhoMusic/GanhoMusic Shared/Nodes/StoneGuardNode.swift`

### 수정 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`

## 기능 상세

### 기능 1: StoneGuardNode (신규 파일)

- **위치**: `GanhoMusic/GanhoMusic Shared/Nodes/StoneGuardNode.swift`
- **파일 헤더**:
  ```
  //
  //  StoneGuardNode.swift
  //  GanhoMusic Shared
  //
  //  Phase 4-1 · 석조무사 NPC — 4 waypoint 시계방향 패트롤 (SKAction)
  //  GDD §7-6: 맵 4지점 사각 순환, 55 px/s, 본 sprint는 시각 등장만 (PhysicsBody 없음).
  //
  ```
- **클래스 시그니처**: `final class StoneGuardNode: SKSpriteNode`, `import SpriteKit`
- **핵심 코드 구조**:
  ```swift
  final class StoneGuardNode: SKSpriteNode {

      // MARK: - Init
      init() {
          let size = CGSize(
              width:  GameConfig.stoneGuardWidth,
              height: GameConfig.stoneGuardHeight
          )
          // 색상: 수간호사(.ganhoBloodAccent 빨강)와의 시각 대비. 새 ColorTokens 신설 금지.
          super.init(texture: nil, color: .ganhoPaper, size: size)
          name = "stoneGuard"
          zPosition = 5
          // physicsBody = nil (기본값). 본 sprint OoS — 4-2에서 도입.
          startPatrol()
      }

      required init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
      }

      // MARK: - Patrol
      /// 4 waypoint 시계방향 무한 순환 SKAction을 self.run으로 실행.
      /// init 시점 호출 — setupStoneGuard()가 (200, 100)에 노드를 둔 직후 worldNode 트리에 들어가면
      /// 첫 .move(to: w[1])부터 자동으로 (760, 100)을 향해 시작된다.
      private func startPatrol() {
          let waypoints = GameConfig.stoneGuardWaypoints
          var moves: [SKAction] = []
          for i in 0..<waypoints.count {
              let from = waypoints[i]
              let to   = waypoints[(i + 1) % waypoints.count]
              let dist = hypot(to.x - from.x, to.y - from.y)
              let dur  = TimeInterval(dist / GameConfig.stoneGuardSpeed)
              moves.append(.move(to: to, duration: dur))
          }
          let loop = SKAction.repeatForever(.sequence(moves))
          run(loop)
      }
  }
  ```
- **금지 사항**:
  - `physicsBody` 부착 금지
  - Timer / DispatchQueue 사용 금지
  - 매직 넘버 직접 사용 금지
  - 강제 언래핑(`!`) 금지
  - update(_:)에서 매 프레임 위치 갱신 코드 작성 금지

### 기능 2: GameConfig 신규 상수 (Stone Guard 섹션)

- **위치**: `Config/GameConfig.swift` 파일 *맨 끝*, Statistics 섹션 다음
- **신규 섹션**:
  ```swift
  // MARK: - Stone Guard (Phase 4-1)
  /// 석조무사 박스 가로 (pt). GDD §7-6 — 수간호사와 동일 16×20.
  static let stoneGuardWidth: CGFloat = 16
  /// 석조무사 박스 세로 (pt). GDD §7-6 16×20.
  static let stoneGuardHeight: CGFloat = 20
  /// 석조무사 패트롤 속도 (pt/s). GDD §7-6 — 시간 보간 없음(단일 상수).
  static let stoneGuardSpeed: CGFloat = 55
  /// 석조무사 4 waypoint(시계방향: 좌하 → 우하 → 우상 → 좌상).
  /// 맵 960×480, 중앙 기둥 (480, 240±40) 회피.
  /// 한 바퀴 둘레 = 1680pt → 1680/55 ≈ 30.5초.
  static let stoneGuardWaypoints: [CGPoint] = [
      CGPoint(x: 200, y: 100),   // 좌하 — 시작 위치
      CGPoint(x: 760, y: 100),   // 우하
      CGPoint(x: 760, y: 380),   // 우상
      CGPoint(x: 200, y: 380)    // 좌상
  ]
  ```

### 기능 3: setupStoneGuard() (GameScene+Setup.swift extension)

- **위치**: `GameScene+Setup.swift` 내 `extension GameScene { ... }` 블록 *맨 끝* (`setupEnemy()` 다음)
- **핵심 코드**:
  ```swift
  func setupStoneGuard() {
      // Phase 4-1 — 첫 waypoint(좌하단)에 위치 부여. StoneGuardNode.init에서 patrol이 이미 시작됐으므로
      // 첫 .move 액션은 (200, 100) → (760, 100) 우향으로 자동 진행된다.
      let first = GameConfig.stoneGuardWaypoints[0]
      stoneGuard.position = CGPoint(x: first.x, y: first.y)
      worldNode.addChild(stoneGuard)
  }
  ```
- **금지**: waypoints 배열 인덱스 가드 추가 금지, setupStoneGuard에서 SKAction 직접 시작 금지

### 기능 4: GameScene.swift 본체 변경

- **수정 1 — 헤더 코멘트**: 파일 상단 마지막 줄(Phase 3 종결 후 리팩터) 다음에:
  ```
  //  Phase 4-1 · StoneGuardNode 1마리 추가 (시계방향 4 waypoint 패트롤, PhysicsBody 없음 — 시각만)
  ```
- **수정 2 — Properties**: `let enemy = EnemyNode()` 다음 줄에:
  ```swift
  let stoneGuard = StoneGuardNode()  // worldNode 자식 (4 waypoint 시계방향 패트롤, Phase 4-1)
  ```
  접근 제어자: 기존 player/enemy/dpad/hud와 동일 internal(기본).
- **수정 3 — `didMove(to:)`**: `setupEnemy()` 호출 다음 줄에:
  ```swift
  setupStoneGuard()    // Phase 4-1 신설 — StoneGuardNode를 worldNode 자식으로 (4 waypoint 시계방향)
  ```
- **금지**:
  - update(_:)에 stoneGuard 관련 코드 추가 금지
  - configureContactRouter에 stoneGuard 분기 추가 금지
  - endGame에서 `stoneGuard.removeAllActions()` 호출 금지 (ARC 자동 정리)

### 기능 5: pbxproj 등록 (식별자 0017)

신규 파일 1개 → 4곳에 식별자 추가. 식별자 `0017`은 grep 검증 결과 충돌 없음.

- **(1) PBXBuildFile**: StatisticsRepository.swift 다음:
  ```
  A1C0F1B00000000000000017 /* StoneGuardNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000017 /* StoneGuardNode.swift */; };
  ```
- **(2) PBXFileReference**:
  ```
  A1C0F1A00000000000000017 /* StoneGuardNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StoneGuardNode.swift; sourceTree = "<group>"; };
  ```
- **(3) Nodes 그룹 children** (그룹 식별자 `A1C0F1570000000000000007`): ProjectileNode.swift 다음에:
  ```
  A1C0F1A00000000000000017 /* StoneGuardNode.swift */,
  ```
- **(4) iOS PBXSourcesBuildPhase**: StatisticsRepository.swift 다음에:
  ```
  A1C0F1B00000000000000017 /* StoneGuardNode.swift in Sources */,
  ```
- tvOS/macOS Sources phase 미수정.

## waypoint 좌표 검증

| 검증 대상 | 좌표 범위 | 패트롤 변 | 충돌 여부 |
|---|---|---|---|
| 중앙 기둥 | x ∈ [460, 500], y ∈ [200, 280] | — | — |
| 가로 변 (하) | y = 100 | x: 200 → 760 | 기둥 y 미접근 → **OK** |
| 가로 변 (상) | y = 380 | x: 200 → 760 | 기둥 y 미접근 → **OK** |
| 세로 변 (우) | x = 760 | y: 100 → 380 | 기둥 x 미접근 → **OK** |
| 세로 변 (좌) | x = 200 | y: 100 → 380 | 기둥 x 미접근 → **OK** |
| 외곽 벽 | (0,0)–(960,480) | — | waypoint 모두 내부 → **OK** |

**결론**: 4 waypoint 직선 경로 모두 중앙 기둥/외곽 벽 통과 없음. PhysicsBody 없으므로 player·enemy·F·노트와 통과 가능 (의도된 OoS).

## 동시성 / 엣지 케이스

1. **첫 waypoint 일관성**: setupStoneGuard에서 (200,100)에 두고 startPatrol의 첫 액션이 (760,100)으로 자동 시작. waypoints 배열이 폐곡선(`(i+1) % count`)이라 마지막 (200,380)→(200,100)으로 한 바퀴 완성.
2. **SKAction ARC 정리**: 노드 제거 또는 ARC 해제 시 SKAction 자동 중단. endGame에서 별도 정리 불필요.
3. **GameScene→ResultScene 전환**: presentScene 시 GameScene 통째 ARC 해제 → 자식 트리 함께 해제 → SKAction 자동 정리.
4. **재인스턴스화**: 새 GameScene이 새 StoneGuardNode 생성 → 깨끗한 패트롤 시작.
5. **한 바퀴 시간**: 1680/55 ≈ 30.5초. 게임 45초 동안 1바퀴 + 약 14초.
6. **physicsBody nil 안전**: 다른 노드의 contactTestBitMask에 stoneGuard 비트가 없음 → didBegin 분기 0.

## 검증 시나리오

| # | 시나리오 | 기대 결과 |
|---|---|---|
| (a) | 게임 시작 직후 | 석조무사(.ganhoPaper) 박스 16×20이 (200,100)에서 오른쪽으로 이동 시작 |
| (b) | 약 10초 | (760,100) 근처 도착 → 위쪽으로 |
| (c) | 약 15초 | (760,380) 근처 도착 → 왼쪽으로 |
| (d) | 약 25초 | (200,380) 근처 도착 → 아래쪽으로 |
| (e) | 약 30~31초 | (200,100) 복귀 → 두 번째 바퀴 시작 |
| (f) | 플레이어가 같은 위치 | 그대로 통과 (PhysicsBody nil) |
| (g) | 카메라 follow | worldNode 자식이라 카메라와 시각적으로 흘러감 |
| (h) | 게임오버 | ResultScene 전환 시 GameScene ARC 해제 → 석조무사도 함께 사라짐 |

## 주의사항

- **기존 시스템 보존 절대 원칙**: EnemyNode·PlayerNode·NoteNode·ProjectileNode·HUDNode·DPadNode·SpawnSystem·ContactRouter·ScoreSystem·TitleScene·ResultScene·HighScoreRepository·StatisticsRepository·GameStats·PhysicsCategory 한 줄도 수정 금지.
- **update() 게임 루프 보존**: stoneGuard 관련 코드 추가 금지.
- **PhysicsCategory 미수정**: `stoneGuard` 비트 신설 금지(4-2 OoS).
- **ColorTokens 미수정**: `.ganhoPaper` 사용.
- **swift-rules.md 준수**: guard let, MARK, GameConfig 상수, final class, required init?(coder:) fatalError, 강제 언래핑 0, Timer 0.
- **spritekit-rules.md 준수**: 초기화는 didMove에서, dt 기반 이동(SKAction이 자동), 노드 계층 일관성, zPosition 5.
