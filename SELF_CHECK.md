# 자체 점검

전략: Case A — 이유: QA 가중 점수 6.9로 compact map 방향은 유지하고, 지적된 스폰 판정/주석 문제만 정밀 보정했다.

## 구현 요약
- `GameConfig.spawnCollectibleHalfExtent`를 추가해 NoteNode/ToiletNode의 16×16 physics hitbox 기준 half extent를 스폰 판정에 사용했다.
- `SpawnSystem.randomOpenMapPosition(halfExtent:)`가 수집물 중심점과 네 모서리 모두 외곽 마진 및 wall body 검사를 통과한 위치만 반환하도록 수정했다.
- `clampedNotePosition`도 같은 half extent margin을 사용하고, 패턴 음표 최종 위치가 중심+네 모서리 wall 검사를 통과하지 못하면 해당 note만 생략하도록 유지했다.
- `MapNode.swift`, `WallTileNode.swift`, `GameScene+Setup.swift`, `GameConfig.swift`의 stale map-size 주석을 runtime compact 기준(`896×560`, `28×28`, `640개(32×20)`)으로 갱신했다.

## QA 개선 지시 체크
- [x] 지시 1: `randomOpenMapPosition`을 half extent 기반으로 변경하고 중심+네 모서리 wall/body 샘플 검사를 적용.
- [x] 지시 2: `clampedNotePosition`도 half extent margin을 사용하도록 변경하고 패턴 음표 개별 생략 흐름 유지.
- [x] 지시 3: stale map-size 주석을 runtime compact 기준으로 갱신.

## SPEC 기능 체크
- [x] Runtime compact map 상수 유지: `tileSize = 28pt`, `mapWidth = 896pt`, `mapHeight = 560pt`, `mapColumns = 32`, `mapRows = 20`.
- [x] 장애물 col/row 패턴 유지: 스폰 판정과 주석만 수정, 벽 배치 데이터 변경 없음.
- [x] 카메라 구조 유지: zoom/scale/fixed camera 변경 없음.
- [x] 스폰 튜닝 유지: 스폰 빈도/최대 수/확률/속도 변경 없음.

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수
- guard let 옵셔널 처리: 준수
- MARK 섹션 구분: 준수
- GameConfig 상수 사용: 준수
- weak self 캡처: 준수 (신규 escaping 클로저 없음)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 준수
- 충돌 후 노드 즉시 삭제 없음: 준수
- HUD 노드 분리: 준수

## rg 점검 결과
- 명령: `rg "originalMapWorld|originalMapCellSize" "GanhoMusic/GanhoMusic Shared"`
- 결과: `GameConfig.swift`의 원본 상수 정의와 `mapRuntimeScale` helper에만 남음.
- runtime 코드 직접 사용: 없음

## 빌드 상태
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -configuration Debug build`
- 결과: `BUILD SUCCEEDED`
- 예상 빌드 에러: 없음
- 주의 필요 경고: AppIntents metadata dependency 없음 경고와 scheme platform note가 출력됐지만 빌드 실패 요인은 아님

## 범위 외 미구현 항목
- 없음
