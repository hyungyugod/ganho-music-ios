# Sprint 5 - Compact Map Rescale

## 개요
현재 인게임 맵은 `32 x 20` 타일에 `40pt` 셀을 사용해 `1280 x 800pt` 월드로 동작한다. Sprint 5에서는 장애물 타일 패턴과 카메라 follow/clamp 구조를 유지하면서 runtime 셀 크기만 파격적으로 줄여, iPhone landscape 화면에 가까운 압축 맵으로 만든다.

## 변경 유형
혼합 — 맵 크기와 카메라 clamp 기준은 비주얼 변화이고, 이동 거리/스폰 밀도/충돌 경계 체감은 게임플레이에 직접 영향을 준다.

## 게임 경험 의도
플레이어가 넓은 월드를 오래 이동하기보다 한 화면 가까운 공간에서 음표 수집과 회피 판단을 더 자주 하도록 만든다. 장애물의 배치 기억은 유지하되, 이동 동선이 짧아져 45초 세션의 밀도를 높인다. 카메라 자체는 기존처럼 플레이어를 따라가고 가장자리에서 clamp되어, 조작 UI와 화면 고정 HUD의 감각은 바뀌지 않는다.

## Sprint 범위 계약
- **허용**: compact runtime map size 적용에 필수인 상수 분리, 벽 타일 크기/physicsBody 축소, MapNode 좌표 helper 갱신, 카메라 clamp 기준 교체, NPC waypoint 스케일링, 맵 안 열린 지점 스폰 보정
- **금지**: 장애물 타일 패턴 추가/삭제/재배치, 카메라 zoom/scale 변경, fixed camera 전환, 플레이어/적/투사체 속도 튜닝, 스폰 주기/동시 수 변경, UI safe area 레이아웃 변경, 새 연출/효과 추가
- **판단 기준**: "이 변경이 없으면 축소된 맵 안에서 기존 장애물/스폰/카메라가 정상 동작하지 않는가?" → YES면 허용, NO면 금지

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`: 원본 맵 상수와 runtime compact 맵 상수를 분리하고, waypoint 변환 helper 및 NPC waypoint를 갱신한다.
- `GanhoMusic/GanhoMusic Shared/Nodes/MapNode.swift`: `tileCoordinate`와 `worldSize()`가 runtime `tileSize/mapWidth/mapHeight`를 사용하도록 바꾼다.
- `GanhoMusic/GanhoMusic Shared/Nodes/WallTileNode.swift`: 벽 타일 시각 크기와 physicsBody 크기를 runtime `GameConfig.tileSize`로 바꾼다.
- `GanhoMusic/GanhoMusic Shared/GameScene+Camera.swift`: 카메라 follow/clamp 구조는 유지하고 world size 참조만 `GameConfig.mapWidth/mapHeight`로 바꾼다.
- `GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift`: AIRFORCE 도주 방향 계산의 맵 중심 기준을 `originalMapWorldWidth/Height`에서 runtime `mapWidth/mapHeight`로 바꾼다.
- `GanhoMusic/GanhoMusic Shared/Systems/SpawnSystem.swift`: 스폰 빈도는 유지하고, 음표/변기가 벽 내부나 맵 밖에 생성되지 않도록 제한된 재시도 기반 열린 지점 검사를 추가한다.

### 확인할 파일
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`: `setupPlayer()`와 `setupCamera()`는 이미 `mapWidth/mapHeight`를 사용하므로 동작 확인만 한다. `spawnSergeantPark()`는 화면 연출 좌표이므로 필수 변경하지 않는다.
- `GanhoMusic/GanhoMusic Shared/Systems/SkillSystem.swift`: `taiwanTripTarget`, `clampedToMap`, `isValidTeleportTarget`이 이미 `mapWidth/mapHeight/tileSize`를 쓰므로 회귀 확인만 한다.
- `GanhoMusic/GanhoMusic Shared/Nodes/StoneGuardNode.swift`, `ProfessorNode.swift`: waypoint 배열을 `GameConfig`에서 읽으므로 파일 수정 없이 새 좌표가 적용되는지 확인한다.
- `GanhoMusic/GanhoMusic Shared/GameScene+Contact.swift`, `Config/PhysicsCategory.swift`: 충돌 category 계약 유지 여부만 확인한다.

### 추가할 파일
- 없음

## 기능 상세

### 기능 1: Runtime Compact Map 상수 분리
- 설명: 원본 웹/40pt 좌표 해석용 상수는 보존하고, 실제 게임 월드 크기를 결정하는 runtime 셀 크기를 `28pt`로 낮춘다. `mapColumns = 32`, `mapRows = 20`은 유지하므로 최종 월드는 `896 x 560pt`가 된다.
- 구현 위치: `GameConfig.swift` `MARK: - Original Map`, `MARK: - World`
- 핵심 코드 구조:
  ```swift
  static let originalMapTileWidth: Int = 32
  static let originalMapTileHeight: Int = 20
  static let originalMapCellSize: CGFloat = 40.0
  static let originalMapWorldWidth: CGFloat = originalMapCellSize * CGFloat(originalMapTileWidth)
  static let originalMapWorldHeight: CGFloat = originalMapCellSize * CGFloat(originalMapTileHeight)

  static let compactMapCellSize: CGFloat = 28.0
  static let tileSize: CGFloat = compactMapCellSize
  static let mapColumns: Int = originalMapTileWidth
  static let mapRows: Int = originalMapTileHeight
  static let mapWidth: CGFloat = tileSize * CGFloat(mapColumns)
  static let mapHeight: CGFloat = tileSize * CGFloat(mapRows)

  static var mapRuntimeScale: CGFloat {
      return tileSize / originalMapCellSize
  }

  static func scaledMapPoint(x: CGFloat, y: CGFloat) -> CGPoint {
      return CGPoint(x: x * mapRuntimeScale, y: y * mapRuntimeScale)
  }

  static func cellPoint(x: CGFloat, y: CGFloat) -> CGPoint {
      return CGPoint(x: x * tileSize, y: y * tileSize)
  }

  static func tileCenter(col: Int, row: Int) -> CGPoint {
      return cellPoint(x: CGFloat(col) + 0.5, y: CGFloat(row) + 0.5)
  }
  ```
- 계약:
  - `originalMapCellSize`, `originalMapWorldWidth`, `originalMapWorldHeight`는 원본 좌표 해석/주석용으로 남긴다.
  - runtime 위치/크기/스폰/카메라에는 `tileSize`, `mapWidth`, `mapHeight`를 사용한다.
  - `compactMapCellSize` 값 외에는 새 매직 넘버를 코드 본문에 흩뿌리지 않는다.

### 기능 2: 장애물 타일 패턴 유지 및 runtime 크기 적용
- 설명: 장애물 개수와 타일 좌표는 그대로 유지하고, 각 타일의 실제 크기만 `28 x 28pt`로 줄인다. 외곽벽, easy 중앙 기둥, normal/hard 방 구조, Sprint 11 추가 장애물의 col/row 데이터는 바꾸지 않는다.
- 구현 위치: `MapNode.swift` `MARK: - Coordinate Helpers`, `WallTileNode.swift` `MARK: - Lifecycle`
- 핵심 코드 구조:
  ```swift
  // MapNode.swift
  func tileCoordinate(col: Int, row: Int) -> CGPoint {
      return GameConfig.tileCenter(col: col, row: row)
  }

  func worldSize() -> CGSize {
      return CGSize(width: GameConfig.mapWidth, height: GameConfig.mapHeight)
  }

  // WallTileNode.swift
  let tileSize = GameConfig.tileSize
  let size = CGSize(width: tileSize, height: tileSize)
  let body = SKPhysicsBody(rectangleOf: size)
  ```
- 유지 계약:
  - `MapNode.buildWalls(difficulty:)`, `buildOuterWall`, `buildEasyInterior`, `buildHardInterior`, `buildExtraObstacles`의 col/row 패턴은 변경하지 않는다.
  - `PhysicsCategory.wall`과 player `collisionBitMask` 계약은 변경하지 않는다.
  - 벽 shadow/highlight/outline은 기존 색과 zPosition을 유지하되, `size`에서 파생된 위치만 자연스럽게 줄어들게 한다.

### 기능 3: 카메라 follow/clamp 구조 유지
- 설명: 카메라를 고정하거나 zoom하지 않는다. 기존 `updateCameraFollow()`의 lower/upper clamp와 "월드가 화면보다 작으면 중앙 고정" 분기는 그대로 두고, world size 참조만 축소된 runtime map으로 교체한다.
- 구현 위치: `GameScene+Camera.swift` `MARK: - Camera Follow`
- 핵심 코드 구조:
  ```swift
  func updateCameraFollow() {
      let halfW = size.width / 2
      let halfH = size.height / 2
      let worldW = GameConfig.mapWidth
      let worldH = GameConfig.mapHeight

      // 이하 lower/upper clamp 구조는 기존 코드 그대로 유지
  }
  ```
- 유지 계약:
  - `cameraNode.setScale`, scene `scaleMode`, `camera = cameraNode`, HUD/DPad cameraNode 자식 구조는 변경하지 않는다.
  - safe area 기반 UI 레이아웃은 `GameScene+Layout.swift`와 `SceneSafeArea`의 기존 방식 그대로 둔다.
  - iPhone landscape 폭이 `896pt`보다 넓은 경우 카메라는 X축 중앙 고정될 수 있다. 이때 배경색이 보이는 것은 허용하지만 검은색/uninitialized 빈 영역은 불합격이다.

### 기능 4: NPC waypoint 스케일 및 relative placement
- 설명: 현재 hardcoded `CGPoint` waypoint가 40pt 원본 runtime 기준에 남아 있으면 compact map 밖으로 나가거나 벽과 어긋난다. 수간호사처럼 셀 중심 의미가 명확한 좌표는 cell helper로 재정의하고, 석조무사/이교수처럼 기존 pt 경로를 보존해야 하는 좌표는 `scaledMapPoint`로 축소한다.
- 구현 위치: `GameConfig.swift` `MARK: - Stone Guard`, `MARK: - Professor`, `MARK: - Nurse Chief Patrol`
- 핵심 코드 구조:
  ```swift
  static let stoneGuardWaypoints: [CGPoint] = [
      scaledMapPoint(x: 80, y: 80),
      scaledMapPoint(x: 540, y: 80),
      scaledMapPoint(x: 540, y: 300),
      scaledMapPoint(x: 80, y: 300)
  ]

  static let professorWaypoints: [CGPoint] = [
      scaledMapPoint(x: 120, y: 100),
      scaledMapPoint(x: 520, y: 280),
      scaledMapPoint(x: 520, y: 100),
      scaledMapPoint(x: 120, y: 280)
  ]

  static let nurseChiefWaypointsByDifficulty: [Difficulty: [CGPoint]] = [
      .easy: [
          cellPoint(x: 3.5, y: 3.5),
          cellPoint(x: 28.5, y: 3.5)
      ],
      .normal: [
          cellPoint(x: 3.5, y: 3.5),
          cellPoint(x: 28.5, y: 16.5),
          cellPoint(x: 28.5, y: 3.5),
          cellPoint(x: 3.5, y: 16.5)
      ],
      .hard: [
          cellPoint(x: 3.5, y: 3.5),
          cellPoint(x: 28.5, y: 3.5),
          cellPoint(x: 28.5, y: 16.5),
          cellPoint(x: 3.5, y: 16.5)
      ]
  ]
  ```
- 전략:
  - static waypoint는 clamp로 조용히 보정하지 말고 helper로 의도를 드러낸다.
  - QA에서 waypoint가 벽 내부로 확인될 때만 같은 패턴을 유지하는 가장 가까운 `cellPoint`로 수정한다.
  - `EnemyNode.startFleeing`의 맵 중심 계산은 `GameConfig.mapWidth / 2`, `GameConfig.mapHeight / 2`를 사용한다.

### 기능 5: 스폰, 시작 위치, 경계, 충돌 영향 반영
- 설명: 플레이어 시작과 카메라 초기 위치는 이미 `mapWidth/mapHeight` 기반이므로 compact 상수 변경에 자동 적응한다. 음표/변기 스폰은 `mapWidth/mapHeight/tileSize`를 사용하지만, 현재 중앙 기둥만 회피하므로 작은 맵에서 벽 내부 스폰을 막는 최소 검사를 추가한다.
- 구현 위치: `GameScene+Setup.swift` 확인, `SpawnSystem.swift` `MARK: - Note Spawn`, `MARK: - Toilet Spawn`
- 핵심 코드 구조:
  ```swift
  // GameConfig.swift
  static let spawnPositionMaxAttempts: Int = 12

  // SpawnSystem.swift
  private func randomOpenMapPosition() -> CGPoint? {
      let margin = GameConfig.tileSize
      for _ in 0..<GameConfig.spawnPositionMaxAttempts {
          let point = CGPoint(
              x: CGFloat.random(in: margin ... GameConfig.mapWidth - margin),
              y: CGFloat.random(in: margin ... GameConfig.mapHeight - margin)
          )
          guard isAwayFromCenterPillar(point) else { continue }
          guard isOpenSpawnPoint(point) else { continue }
          return point
      }
      return nil
  }

  private func isOpenSpawnPoint(_ point: CGPoint) -> Bool {
      guard let scene = scene else { return true }
      if let body = scene.physicsWorld.body(at: point),
         body.categoryBitMask == PhysicsCategory.wall {
          return false
      }
      return true
  }
  ```
- 적용 지시:
  - `randomNotePosition()`과 `randomToiletPosition()`은 공통 helper를 호출해 중복을 줄인다.
  - note pattern의 개별 위치는 기존 `clampedNotePosition`을 유지하되, 최종 위치가 wall이면 해당 note만 spawn하지 않는 방식으로 처리한다.
  - 스폰 주기, 최대 동시 수, note lifetime, toilet 확률은 변경하지 않는다.
  - 플레이어 시작 위치 `mapWidth / 4`, `mapHeight / 2`는 유지한다. `28pt` 기준 시작점은 `224, 280`이며 easy 중앙 기둥과 겹치지 않아야 한다.
  - 경계는 외곽 `WallTileNode` 물리 충돌로 유지한다. 별도 player 좌표 clamp를 새로 추가하지 않는다.
  - F/A 투사체는 기존처럼 벽을 통과한다. `FProjectileNode.collisionBitMask = 0` 정책은 변경하지 않는다.

### 기능 6: Safe Area 및 Landscape 기준
- 설명: 맵 크기 산정은 safe area가 아니라 SpriteKit world 기준 고정값으로 한다. safe area는 cameraNode 자식 UI 배치에만 사용한다.
- 구현 위치: `GameScene+Layout.swift`, `SceneSafeArea.swift` 확인
- 기준:
  - `GameScene.newGameScene`의 `.resizeFill` 때문에 scene `size`는 landscape SKView 크기로 갱신된다.
  - compact map 목표값은 `GameConfig.mapWidth = 896`, `GameConfig.mapHeight = 560`이다.
  - iPhone SE landscape처럼 scene이 맵보다 작은 경우 카메라는 player follow 후 가장자리에서 clamp한다.
  - 넓은 iPhone landscape에서 scene width가 맵 width보다 큰 경우 `updateCameraFollow`의 기존 branch가 world center를 사용한다.
  - `SceneSafeArea.insets(for:)`는 HUD, D-Pad, SkillButton, PauseButton 위치에만 적용한다. 맵 크기나 카메라 world clamp에 safe inset을 더하지 않는다.

## 빌드/QA 기준
- `xcodebuild`로 iOS scheme 빌드 에러가 없어야 한다. 사용 가능한 iPhone Simulator destination을 사용한다.
- `rg "originalMapWorld|originalMapCellSize" "GanhoMusic/GanhoMusic Shared"` 실행 후 runtime 이동/충돌/카메라 코드가 원본 world/cell size를 직접 쓰지 않아야 한다. 허용 위치는 `GameConfig` 원본 상수, `scaledMapPoint`, 원본 설명 주석 정도다.
- `GameConfig.mapWidth == 896`, `GameConfig.mapHeight == 560`, `GameConfig.mapColumns == 32`, `GameConfig.mapRows == 20`이어야 한다.
- wall tile 개수는 기존 패턴과 같아야 한다. easy는 외곽 100 + 중앙 8 + 추가 10 = 118개, normal/hard는 외곽 100 + hard interior 44 + 추가 12 = 156개가 기준이다.
- easy/normal/hard 각각 게임 진입 후 플레이어, 수간호사, 석조무사 또는 이교수가 맵 안에서 시작해야 한다.
- 카메라가 축소된 맵 기준으로 clamp되어야 하며, 화면 밖 검은 빈 영역이 보이면 불합격이다.
- 음표/변기는 맵 밖 또는 wall tile 내부에 생성되지 않아야 한다. 스폰 실패 시 해당 tick은 noop으로 넘어가도 된다.
- 대만여행과 돌진 target clamp는 새 `mapWidth/mapHeight/tileSize` 기준을 따라야 한다.
- 플레이어가 외곽벽을 통과하지 못하고, 벽 충돌 후 튕김/밀림이 과하게 발생하지 않아야 한다.
- D-Pad, SkillButton, HUD, PauseButton의 safe area 위치는 Sprint 5 전후로 바뀌지 않아야 한다.

## 주의사항
- Swift 강제 언래핑(`!`)을 추가하지 않는다. optional 접근은 `guard let` 또는 `if let`을 사용한다.
- `Timer`나 `DispatchQueue.main.asyncAfter`를 사용하지 않는다. 기존처럼 `SKAction.wait`와 `SKAction.sequence`를 사용한다.
- `update()` 안에서 새 노드를 반복 생성하는 방식으로 QA 보정하지 않는다.
- `GameConfig` 외부에 `28`, `896`, `560`, waypoint 원시 좌표 같은 매직 넘버를 추가하지 않는다.
- `MapNode.buildWalls`의 장애물 타일 col/row 패턴을 바꾸면 사용자 요청의 "장애물들은 다 그대로" 계약 위반이다.
- 카메라 변경은 world size 참조 교체까지만 허용한다. zoom, scale, fixed camera, HUD 좌표계 변경은 금지한다.
- compact map은 같은 이동/투사체 속도에서 난이도를 올릴 수 있다. 이번 Sprint에서는 속도 튜닝을 하지 말고 QA_REPORT에 후속 튜닝 필요 여부만 기록한다.
