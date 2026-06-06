# Sprint 5 - Compact Map and Motion Tuning

## 목표

현재보다 맵을 한 번 더 줄이고, 조작감에 비해 빠르게 느껴지는 플레이어 이동 속도를 살짝 낮춘다. 장애물 패턴과 카메라 follow/clamp 구조는 유지하되, 실제 플레이 공간과 속도 체감을 실기기에 맞춘다.

## 현재 상태

- 현재 runtime map:
  - `tileSize = 28`
  - `mapColumns = 32`
  - `mapRows = 20`
  - `mapWidth = 896`
  - `mapHeight = 560`
- 카메라는 `GameConfig.mapWidth/mapHeight` 기준으로 clamp한다.
- `MapNode`는 타일 패턴을 유지하고 `WallTileNode`를 tileSize 기준으로 만든다.
- 플레이어 속도는 난이도별:
  - easy: 280
  - normal: 320
  - hard: 320
- `PlayerNode.update(deltaTime:)`는 현재 `baseSpeedStart * speedMultiplier`를 사용한다.
- `baseSpeedEnd`는 저장만 되고 실제 보간에는 쓰이지 않는다.

## 변경 의도

맵을 더 작게 만들면 같은 속도에서도 이동이 더 빨라 보인다. 따라서 맵 축소와 이동속도 하향은 함께 해야 한다. 다만 너무 크게 바꾸면 난이도/스폰/적 순찰이 한꺼번에 흔들리므로, 1차 값은 보수적으로 둔다.

## 목표 값 제안

### 맵 크기 후보

| tileSize | worldSize | 평가 |
|---:|---:|---|
| 26pt | 832 x 520 | 현재보다 줄지만 안정적. |
| 25pt | 800 x 500 | 화면에 더 가까움. 좋은 1차 후보. |
| 24pt | 768 x 480 | 매우 compact. 난이도 상승 가능성이 큼. |

권장 1차값: `25pt`.

이유:

- 현재 28pt에서 25pt는 약 10.7% 축소다.
- 24pt는 감각상 좋을 수 있지만 스폰/적/투사체 압박이 갑자기 커질 수 있다.
- 사용자가 "더 줄이고"라고 했으므로 26pt보다는 확실한 변화가 필요하다.

### 이동 속도 후보

권장 1차값: 현재 대비 90%.

| 난이도 | 현재 | 1차 목표 |
|---|---:|---:|
| 하 | 280 | 252 |
| 중 | 320 | 288 |
| 상 | 320 | 288 |

실제 구현은 상수를 직접 바꾸기보다 multiplier를 도입하는 것을 권장한다.

```swift
static let playerSpeedTuningMultiplier: CGFloat = 0.9
```

이렇게 하면 원본 정합 주석과 runtime tuning 값을 분리할 수 있다.

## 구현 범위

### Phase A - tileSize 조정

- `GameConfig.compactMapCellSize`를 28 -> 25로 변경.
- `mapWidth/mapHeight` 자동 산식 확인:
  - 32 x 20 x 25 = 800 x 500
- 관련 주석 갱신.

### Phase B - camera/clamp 재확인

- `GameScene+Camera.swift`가 계속 `mapWidth/mapHeight`를 참조하는지 확인한다.
- 화면 크기가 map보다 커지는 케이스에서 clamp가 중앙 고정으로 동작하는지 확인한다.
- 검은 빈 공간이 보이면 camera zoom이 아니라 clamp/position 보정으로 처리한다.

### Phase C - waypoint/스폰 재감사

`tileSize`가 더 줄어들면 wall hitbox, 스폰 margin, NPC waypoint가 더 빡빡해진다.

확인 대상:

- `GameConfig.stoneGuardWaypoints`
- `GameConfig.professorWaypoints`
- 수간호사 waypoints
- `SpawnSystem.randomOpenMapPosition`
- `SkillSystem`의 dash/trip target clamp
- `EnemyNode.startFleeing`

이미 `scaledMapPoint`, `tileCenter`, `mapWidth/mapHeight` 기반으로 정리되어 있지만 `rg`로 다시 검사한다.

명령:

```bash
rg "originalMapWorld|originalMapCellSize|mapWidth|mapHeight|tileSize|scaledMapPoint|cellPoint" "GanhoMusic/GanhoMusic Shared"
```

### Phase D - 이동 속도 하향

권장 구현:

- `GameConfig.playerSpeedRuntimeMultiplier = 0.9` 추가.
- `PlayerNode.apply(_ difficulty:)`에서:
  - `baseSpeedStart = rawStart * multiplier`
  - `baseSpeedEnd = rawEnd * multiplier`
- 또는 dictionary 값을 직접 252/288로 변경.

권장: multiplier.

이유:

- 원본 분석값과 실기기 튜닝값을 분리할 수 있다.
- 후속 조정이 쉽다.

### Phase E - 난이도 체감 확인

속도를 낮추면 음표 수집 점수가 낮아질 수 있다. 동시에 맵이 줄어 점수 접근성은 올라갈 수 있다.

확인할 것:

- 하 난이도에서 45초 동안 너무 답답하지 않은지.
- 중/상에서 F 투사체 회피가 불가능해지지 않는지.
- 목표 점수 달성 난이도가 비정상적으로 바뀌지 않는지.
- 플레이어 시작 지점이 벽/장애물과 겹치지 않는지.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene+Camera.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Nodes/MapNode.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Systems/SpawnSystem.swift` 확인 대상
- `GanhoMusic/GanhoMusic Shared/Systems/SkillSystem.swift` 확인 대상

## 보존할 것

- `mapColumns = 32`, `mapRows = 20`.
- 장애물 타일 패턴.
- camera follow/clamp 구조.
- D-Pad/스킬 UI 위치.
- 점수/졸업/결과 저장 흐름.

## 수용 기준

- 맵 월드 크기가 896 x 560보다 작아진다.
- 플레이어 이동 체감이 살짝 느려진다.
- 카메라 검은 빈 영역이 생기지 않는다.
- easy/normal/hard 모두 시작 위치, 스폰, NPC 이동이 정상이다.
- 벽 내부 노트/변기 스폰이 발생하지 않는다.
- 실기기에서 조작이 덜 급하게 느껴진다.

## 리스크와 대응

- 리스크: 25pt가 너무 작아 난이도가 급상승한다.
  - 대응: 26pt로 되돌릴 수 있게 상수 하나로 둔다.
- 리스크: 속도 90%가 답답할 수 있다.
  - 대응: multiplier를 0.92~0.95로 쉽게 조정 가능하게 둔다.
- 리스크: 기존 주석의 원본 정합 설명과 runtime tuning이 충돌한다.
  - 대응: 원본값과 runtime값을 명확히 분리해 주석을 갱신한다.

