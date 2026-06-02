# QA 검수 보고서

## 검수 전제
- 검수 범위: Sprint 5 `Compact Map Rescale` QA 2회차.
- 현재 워크트리는 Sprint 5 외 변경이 섞여 있음. 사용자 지시에 따라 계정/Firebase, 메뉴 화면, Result/CharacterSelect, 난이도 튜닝 등 Sprint 5 범위 밖 기존 unrelated 변경은 감점하지 않음.
- 확인한 주요 Swift 파일: `GameConfig.swift`, `SpawnSystem.swift`, `MapNode.swift`, `WallTileNode.swift`, `GameScene+Setup.swift`, `GameScene+Camera.swift`, `GameScene.swift`, `EnemyNode.swift`, `SkillSystem.swift`, `ContactRouter.swift`, `GameScene+Contact.swift`.

## 이전 QA 개선 지시 검증
- [PASS] 지시 1: `SpawnSystem.randomOpenMapPosition(halfExtent:)`는 `GameConfig.spawnCollectibleHalfExtent`를 받아 `tileSize + halfExtent` margin을 쓰고, `isOpenSpawnPoint`에서 중심+네 모서리 샘플을 모두 검사한다.
- [PASS] 지시 2: `clampedNotePosition`도 같은 `tileSize + spawnCollectibleHalfExtent` margin을 쓰며, 패턴 음표는 최종 위치가 `isOpenSpawnPoint`를 통과하지 못하면 해당 음표만 생략한다.
- [PASS] 지시 3: `MapNode.swift`, `WallTileNode.swift`, `GameScene+Setup.swift`, `GameConfig.swift`의 지적된 stale map-size 주석은 `896×560`, `28×28`, `640개(32×20)` 기준으로 갱신됐다.

## SPEC 기능 검증
- [PASS] 기능 1: `tileSize = 28`, `mapColumns = 32`, `mapRows = 20`, `mapWidth = 896`, `mapHeight = 560` 산식이 유지된다.
- [PASS] 기능 2: `MapNode.tileCoordinate/worldSize`와 `WallTileNode` size/physicsBody는 runtime `tileSize/mapWidth/mapHeight`를 사용한다. 장애물 col/row 패턴은 easy `118개`, normal/hard `156개` 기준과 일치한다.
- [PASS] 기능 3: `GameScene+Camera.updateCameraFollow`는 runtime `GameConfig.mapWidth/mapHeight`로 lower/upper clamp를 계산한다. zoom/fixed camera 변경은 없다.
- [PASS] 기능 4: 석조무사, 이교수, 수간호사 waypoint는 compact map 내부다. 예: 석조무사 `(56,56)...(378,210)`, 이교수 `(84,70)...(364,196)`, 수간호사 `(98,98)...(798,462)`.
- [PASS] 기능 5: 음표/변기 랜덤 스폰은 half extent 기반 margin과 중심+네 모서리 wall 검사로 외곽벽/내부벽 부분 겹침을 방지한다. 패턴 음표도 동일 검사 후 spawn한다.
- [PASS] 기능 6: 플레이어 시작점은 `mapWidth / 4`, `mapHeight / 2`로 compact 기준 `(224,280)`이며, 카메라 초기 위치도 runtime map center 기준이다.
- [PASS] Sprint 5 유지 조건: `tileSize=28`, `mapWidth=896`, runtime 카메라 clamp, compact waypoint, 장애물 col/row 패턴은 유지된다. 속도/스폰 빈도/확률 관련 dirty diff는 이전 QA에서도 확인된 Sprint 5 범위 밖 튜닝으로 보고 감점 제외했다.

## 필수 검색 결과
- 명령: `rg "originalMapWorld|originalMapCellSize" "GanhoMusic/GanhoMusic Shared"`
- 결과:
  ```text
  GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift:    static let originalMapCellSize: CGFloat = 40.0
  GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift:    static let originalMapWorldWidth: CGFloat = originalMapCellSize * CGFloat(originalMapTileWidth)
  GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift:    static let originalMapWorldHeight: CGFloat = originalMapCellSize * CGFloat(originalMapTileHeight)
  GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift:        return tileSize / originalMapCellSize
  ```
- 판정: PASS. 원본 상수 정의와 `mapRuntimeScale` helper에만 남아 있으며, runtime 카메라/맵/스폰/AI 직접 사용은 확인되지 않았다.

## 빌드 검증
- 결과: BUILD SUCCEEDED
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -configuration Debug build`
- 비고: 컴파일 에러 없음. `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` note가 출력됐으나 빌드 실패 요인은 아니다.

## 정적 검사 결과
- 강제 언래핑: `as!`, `try!`, 명확한 optional 강제 언래핑 패턴 없음. `!` 검색 결과는 논리 부정/문자열/주석 위주.
- `Timer.`: 없음.
- `DispatchQueue`: `Managers/BGMPlayer.swift:143` 기존 범위 외 사용만 확인, Sprint 5 감점 제외.
- 물리 충돌 콜백 내 즉시 삭제: 주요 contact 경로는 `wait(0) + removeFromParent()` 또는 `SKAction.removeFromParent()`로 지연 제거한다.
- 파일 분리: `GameScene.swift`는 289줄로 300줄 미만이며 `Nodes/`, `Systems/`, `Config/` 분리는 유지된다.

## 검수 결과 요약

| 등급 | 건수 |
|---|---:|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 2건 |

## P0 — 치명적 이슈
- 없음.

## P1 — 중요 이슈
- 없음.

## P2 — 권장 사항

### 1. `GameScene.swift`에 compact map 이전 크기 주석이 남아 있음
- **파일**: `GanhoMusic/GanhoMusic Shared/GameScene.swift:248`
- **위반 규칙**: Swift 주석 규칙. 주석은 현재 runtime 기준을 설명해야 한다.
- **현재 코드**: `원본 32×20 맵(1280×800pt)으로 좁아져 무클램프 시 화면 밖 검은 빈 공간 노출 위험.`
- **수정 제안**: `runtime compact 맵(896×560pt) 기준으로 clamp하지 않으면 화면 밖 빈 영역 노출 위험.`처럼 현재 기준으로 갱신할 것.

### 2. `SpawnSystem.swift` 변기 스폰 주석이 half extent margin을 설명하지 않음
- **파일**: `GanhoMusic/GanhoMusic Shared/Systems/SpawnSystem.swift:317`
- **위반 규칙**: Swift 주석 규칙. 구현은 `tileSize + halfExtent` margin인데 주석은 `외곽 1타일 마진`만 설명한다.
- **현재 코드**: `변기 스폰 위치 — randomNotePosition 정책 재사용 (외곽 1타일 마진 + 중앙 기둥/벽 회피).`
- **수정 제안**: `외곽벽 1타일 + 수집 hitbox half extent margin`과 `중심+네 모서리 wall 검사`를 명시할 것.

## 통과 항목
- `SpawnSystem.randomOpenMapPosition`은 노드 half extent 기반이며 중심+네 모서리 모두 wall body 검사를 통과한 위치만 반환한다.
- `clampedNotePosition`은 같은 half extent margin을 사용하고 패턴 음표가 벽과 부분 겹치면 해당 음표를 생략한다.
- `MapNode.swift`, `WallTileNode.swift`, `GameScene+Setup.swift`, `GameConfig.swift`의 기존 stale map-size 주석은 갱신됐다.
- `GameConfig.mapWidth == 896`, `GameConfig.mapHeight == 560`.
- `EnemyNode.startFleeing`은 runtime map center `mapWidth / 2`, `mapHeight / 2`를 사용한다.
- `SkillSystem`의 teleport clamp는 runtime `mapWidth/mapHeight/tileSize` 기준을 유지한다.
- 스폰 루프는 `SKAction.repeatForever`를 사용한다.
- 게임 종료 시 `spawnSystem.stop()`과 `professor?.stopThrowing(...)` 정리가 유지된다.

## 범위 외 관찰
- `git diff` 기준 `GameConfig.swift`에는 `noteMaxConcurrentByDifficulty`, `projectileMaxConcurrentByDifficulty`, `projectileBurstCountByDifficulty`, `projectileFireIntervalStart/EndByDifficulty`, `noteSpawnIntervalByDifficulty` 변경이 존재한다. 사용자 지시상 Sprint 5 범위 밖 기존 unrelated 변경으로 보아 감점하지 않았다.
- `MapNode.buildExtraObstacles`와 note pattern 관련 변경도 dirty diff에 포함되어 있으나, Sprint 5 QA 2회차의 핵심 수정 대상은 half extent spawn 보정과 stale 주석 갱신이므로 별도 감점하지 않았다.

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: 9/10
- 게임 로직 완성도: 9/10
- 성능 & 안정성: 9/10
- 기능 완성도: 9/10
- **가중 점수**: 9.0/10

## 최종 판정: 합격

**구체적 개선 지시**:
1. `GameScene.swift:248`의 `1280×800pt` stale comment를 runtime compact `896×560pt` 기준 설명으로 갱신할 것.
2. `SpawnSystem.swift:317`의 변기 스폰 주석에 `tileSize + spawnCollectibleHalfExtent` margin과 중심+네 모서리 wall 검사 정책을 명시할 것.
