# Sprint 5 - Compact Map Rescale

## 목표

맵을 현재보다 크게 줄인다. 장애물의 타일 패턴은 유지하고, 카메라 follow/clamp 구조도 유지하되, 실제 월드 크기를 화면에 더 가깝게 만든다.

## 현재 상태 요약

- 현재 맵은 `32 x 20` 타일이다.
- 현재 셀 크기는 `40pt`라서 월드는 `1280 x 800pt`다.
- 카메라는 `GameScene+Camera.swift`에서 `originalMapWorldWidth/Height`를 참조해 clamp한다.
- `MapNode`도 `originalMapWorldWidth/Height`를 world size로 반환한다.
- 장애물은 타일 좌표 기반으로 생성된다. 따라서 셀 크기를 줄이면 패턴은 유지하면서 실제 크기만 줄일 수 있다.
- 적/특수 NPC waypoint 중 일부는 pt 좌표가 직접 박혀 있다.

## 디자인 의도

플레이어가 "넓은 맵을 돌아다니는 느낌"보다 "한 화면 안에서 압축된 회피/수집을 하는 느낌"을 받게 한다. 장애물 배치는 그대로 보이되, 이동 거리와 화면 밖 빈 공간을 줄인다. 사용자가 요청한 대로 카메라의 기본 동작은 유지해서 기존 조작 감각을 크게 바꾸지 않는다.

## 목표 크기

1차 후보:

| Cell Size | World Size | 느낌 |
|---|---|---|
| 32pt | 1024 x 640 | 현재보다 줄지만 아직 큰 편. |
| 28pt | 896 x 560 | iPhone landscape 화면에 가까운 강한 축소. |
| 26pt | 832 x 520 | 거의 한 화면 느낌. 난이도 상승 가능성이 큼. |

권장 1차 값은 `28pt`다. 너무 작으면 적/투사체/노트 밀도가 갑자기 올라가므로, 실기기에서 답답하면 `30~32pt`로 되돌릴 여지를 둔다.

## 핵심 원칙

- `mapColumns = 32`, `mapRows = 20`은 유지한다.
- 장애물 타일 좌표는 유지한다.
- 셀 크기만 줄여 월드 크기를 줄인다.
- 카메라 follow/clamp 로직은 유지하되 참조 world size를 새 `mapWidth/mapHeight`로 바꾼다.
- 플레이어/적/투사체 속도는 이 Sprint에서 우선 변경하지 않는다.
- 축소 후 난이도가 너무 올라가면 후속 Sprint에서 수치 튜닝한다.

## 구현 전략

### Phase A - 런타임 맵 크기와 원본 참조 분리

현재 `originalMapCellSize = 40`이 runtime `tileSize`로도 쓰인다. Sprint 5에서는 의미를 분리한다.

권장 구조:

```swift
static let originalMapCellSize: CGFloat = 40.0
static let compactMapCellSize: CGFloat = 28.0
static let tileSize: CGFloat = compactMapCellSize
static let mapWidth: CGFloat = tileSize * CGFloat(mapColumns)
static let mapHeight: CGFloat = tileSize * CGFloat(mapRows)
```

`originalMapCellSize`는 원본 좌표 해석용으로 남기고, 실제 runtime은 `tileSize/mapWidth/mapHeight`를 사용한다.

### Phase B - Camera/MapNode 참조 정리

수정 대상:

- `GameScene+Camera.swift`
  - `originalMapWorldWidth/Height` 대신 `GameConfig.mapWidth/mapHeight`.
- `MapNode.worldSize()`
  - `GameConfig.mapWidth/mapHeight` 반환.
- `MapNode.tileCoordinate(col:row:)`
  - `GameConfig.tileSize` 사용.

이렇게 해야 맵 축소 후 카메라가 옛 `1280 x 800` 기준으로 clamp하지 않는다.

### Phase C - Waypoint 스케일링

점검 대상:

- `GameConfig.nurseChiefWaypointsByDifficulty`
- `GameConfig.stoneGuardWaypoints`
- `GameConfig.professorWaypoints`
- `GameScene+Setup.spawnSergeantPark()` 위치 산식
- `SkillSystem.taiwanTripTarget`, `isPointInsideMap`, note/toilet spawn 등

권장 방식:

```swift
static var mapRuntimeScale: CGFloat {
    return tileSize / originalMapCellSize
}

static func scaledMapPoint(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: x * mapRuntimeScale, y: y * mapRuntimeScale)
}
```

기존 pt 좌표가 원본 40pt 셀 기준이면 `scaledMapPoint`로 변환한다. 타일 중심 좌표는 더 좋은 방식으로 `tileCenter(col:row:)` helper를 둔다.

예:

- nurse easy start `140,140`은 `3.5,3.5` 셀 중심이다.
- `1140,660`은 `28.5,16.5` 셀 중심이다.
- 따라서 `tileCenter(col: 3, row: 3)` 또는 `cellPoint(x: 3.5, y: 3.5)` 형태가 더 안전하다.

좌표 감사표:

| 대상 | 현재 기준 | 변경 방식 |
|---|---|---|
| 수간호사 waypoint | 40pt 셀 기준 pt 좌표 | `cellPoint(x:y:)` 또는 `scaledMapPoint`로 변환 |
| 석조무사 waypoint | pt 좌표 배열 | 원본 기준이면 `scaledMapPoint`, 타일 기준이면 `cellPoint`로 재정의 |
| 이교수 waypoint | pt 좌표 배열 | `scaledMapPoint`로 변환 |
| 플레이어 시작 위치 | `mapWidth / 4`, `mapHeight / 2` | 자동 적응, 벽 충돌만 확인 |
| 카메라 초기 위치 | `mapWidth / 2`, `mapHeight / 2` | 자동 적응 |
| 노트/변기 스폰 | `mapWidth/mapHeight` 랜덤 | 자동 적응, margin 확인 |
| 대만여행 target | `mapWidth/mapHeight` 기준 | 자동 적응, margin 확인 |
| 박병장 등장 위치 | `cameraNode` 또는 world 좌표 혼합 가능 | 구현 전 실제 코드 확인 후 map/camera 좌표계 분리 |

### Phase D - 장애물/바닥 렌더링 확인

- `MapNode.buildWalls(difficulty:)`는 타일 좌표 기반이므로 대부분 자동 적응한다.
- `WallTileNode` size가 `GameConfig.tileSize`를 참조하는지 확인한다.
- 체크보드 floor도 `tileSize/mapColumns/mapRows`를 참조하는지 확인한다.
- 노트 스폰 margin이 새 tile size와 맞는지 확인한다.

### Phase E - 플레이 감각 확인

축소 후에는 같은 속도라도 체감 이동 범위가 커진다. 그러나 사용자가 "장애물들은 다 그대로 두고 카메라 같은 설정은 그대로"라고 했으므로 첫 구현은 속도를 유지한다.

확인할 것:

- 플레이어 시작 위치가 벽/기둥과 겹치지 않는다.
- easy/normal/hard 모두 적 waypoint가 벽 안에 박히지 않는다.
- 투사체가 너무 즉시 닿지 않는다.
- 노트가 벽 안에 스폰되지 않는다.
- 대만여행/돌진 같은 스킬 target clamp가 새 map size를 따른다.

## 구현 체크리스트

1. `rg "originalMapWorld|originalMapCellSize|mapWidth|mapHeight"`로 참조 지점 목록화.
2. `originalMapCellSize`를 원본 참조값으로 남기고 runtime cell size를 새 상수로 분리.
3. `MapNode.tileCoordinate`와 `worldSize`를 runtime size 기준으로 변경.
4. `updateCameraFollow`를 runtime `mapWidth/mapHeight` 기준으로 변경.
5. waypoint 배열을 helper 기반으로 바꾸고 하드코딩 pt 좌표를 줄인다.
6. easy/normal/hard 각각 `setupWorld`, `setupEnemy`, `setupStoneGuard`, `setupProfessor` 시작 위치를 점검한다.
7. 빌드 후 최소 한 판에서 카메라 검은 빈 공간, 벽 내부 스폰, 적 맵 밖 이동을 확인한다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene+Camera.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/MapNode.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift`
- `GanhoMusic/GanhoMusic Shared/Systems/SpawnSystem.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Systems/SkillSystem.swift` 확인 대상
- 적 노드 파일은 waypoint 적용 방식에 따라 수정 가능:
  - `EnemyNode.swift`
  - `ProfessorNode.swift`
  - `StoneGuardNode.swift`

## 보존해야 할 것

- `GameScene.newGameScene(characterID:difficulty:)` 시그니처.
- `mapColumns = 32`, `mapRows = 20`.
- `MapNode.buildWalls`의 장애물 타일 패턴.
- 카메라 follow/clamp의 구조.
- D-Pad/스킬 입력 UI 위치.
- 기존 점수/스폰/충돌 저장 흐름.

## 수용 기준

- 맵 월드 크기가 기존 `1280 x 800`보다 확실히 작아진다.
- 장애물 패턴은 같은 타일 배치로 유지된다.
- 카메라가 축소된 맵 크기에 맞게 clamp된다.
- 화면 밖 검은 빈 영역이 생기지 않는다.
- 플레이어와 모든 NPC가 맵 안에서 시작하고 이동한다.
- easy/normal/hard 모두 최소 1판 진입 가능하다.
- 노트/변기/투사체가 맵 밖 또는 벽 내부에 비정상적으로 생성되지 않는다.

## 리스크와 대응

- 리스크: pt 좌표 waypoint가 축소되지 않으면 적이 맵 밖으로 나간다.
  - 대응: 모든 pt waypoint를 helper로 통일한다.
- 리스크: 맵이 너무 작아져 난이도가 급상승한다.
  - 대응: Sprint 5에서는 `28pt`로 시작하고, 실기기 피드백 후 `30~32pt`로 조정한다.
- 리스크: `originalMapWorldWidth/Height`를 참조하는 곳을 놓치면 카메라/AI가 옛 맵 기준으로 움직인다.
  - 대응: 구현 전후 `rg "originalMapWorld|originalMapCellSize|mapWidth|mapHeight"`를 반드시 돌린다.
- 리스크: 원본 1:1 주석과 runtime compact map의 의미가 충돌한다.
  - 대응: 주석을 `원본 참조값`과 `runtime compact value`로 명확히 나눈다.

## 검토 포인트

- 1차 셀 크기를 `28pt`로 시작해도 되는지 확인이 필요하다.
- "카메라 같은 설정은 그대로"를 camera follow 유지로 해석했다. 만약 화면 전체 고정 카메라를 원하면 별도 큰 변경이다.
- 장애물 "그대로"는 타일 패턴 유지로 해석했다. 장애물의 화면상 크기까지 그대로 유지하면 맵 축소와 충돌한다.
