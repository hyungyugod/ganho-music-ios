# 자체 점검 — Sprint 7 Phase G

전략: 1회차(최초 구현)

## SPEC 기능 체크

- [x] **기능 1**: `Models/Direction.swift` 신규 — enum 4 case(front/back/left/right) + `init?(vector:)` (.zero → nil)
- [x] **기능 2**: PlayerNode 4 child face dict (`faceNodes`) + `facing(_:)` + `lastFacing` 가드 + `buildFacingChildren(for:)`
- [x] **기능 3**: CharacterFaceNode `init(id:facing:)` + `convenience init(id:)` delegation + `buildBackFace`/`buildSideFace` + 10 helper (5 back + 5 side)
- [x] **기능 4**: DPadNode `onDirectionChanged` 클로저 + `updateDirection` 끝에 1 if-let 추가(4줄)
- [x] **기능 5**: GameScene+Setup `setupDPad()` 콜백 등록 1줄(weak self 캡처)
- [x] **기능 6**: GameConfig 상수 2개 (`playerFaceChildScale=0.5`, `playerFaceChildZPosition=1`)
- [x] **기능 7**: mockup 후반부 5×4 그리드 20셀 — front(기존 path 재사용) + back(헤어 silhouette) + left(헤어 한쪽 + 눈 1) + right(scaleX -1 미러링)

## 변경 파일 목록 (총 7개)

| 파일 | 변경 유형 | LOC 변화 |
|---|---|---|
| `Models/Direction.swift` | 신규 | +37 |
| `Nodes/PlayerNode.swift` | 수정 | +43 / -0 |
| `Nodes/CharacterFaceNode.swift` | 수정 | +382 / -9 (init 시그니처 재구성) |
| `Nodes/DPadNode.swift` | 수정 | +12 / -0 |
| `GameScene+Setup.swift` | 수정 | +5 / -0 |
| `Config/GameConfig.swift` | 수정 | +11 / -0 |
| `mockups/villains-and-player-directions-v1.html` | 수정 | +281 / -4 (placeholder 치환) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4 (Direction.swift 등록) |
| **합계** | | **+775 / -13** (신규 ~37, 시각·구조 ~738) |

## 보호 영역 git diff 0줄 검증

- [x] Phase A·B·C·D·E·F 결과물: **0줄** (Scenes/, SergeantParkNode, EnemyNode, ProfessorNode, StoneGuardNode 모두 diff 없음)
- [x] GameScene/GameState/PhysicsCategory: **0줄**
- [x] Managers/Repositories/Systems: **0줄**
- [x] NoteNode/ProjectileNode/StethoscopeNode: **0줄**
- [x] CharacterFaceNode 기존 5 build (`buildKimFace` ~ `buildLeeFace`): **본문 0줄 변경** (오직 init 시그니처만 재구성, 메서드 호출 순서 byte-identical)
- [x] CharacterFaceNode `.mini` factory: **0줄** (`CharacterFaceNode(id:)` → convenience init delegation으로 결과 byte-identical)
- [x] PlayerNode 이동 로직 (`update(deltaTime:)`/`updatePixelDirection`/`tickWalkFrame`/`refreshTexture`/`loadTexture`/`freeze`): **0줄**
- [x] PlayerNode physicsBody 좌표·크기 (`init()` body): **0줄**
- [x] DPad `updateDirection` 본문 알고리즘 (`if abs(x) >= abs(y)` if/else): **byte-identical**, 끝에 4줄(if-let) 추가만
- [x] DPad `touchesEnded`/`touchesCancelled`의 `.zero` set: **0줄 변경** (콜백 미발화 → 정지 시 유지)

## OQ-1/2/3 처리 상태

- **OQ-1** (4방향 path 위치): `CharacterFaceNode` 확장 채택 — `init(id:facing:)` + 10 helper(`buildKimHairBack` ~ `buildLeeSide`). 기존 5 `build{Char}Face` 본문 byte-identical, mini factory 회귀 0.
- **OQ-2** (PlayerNode texture vs face child 시각 충돌): **대안 (자연 겹침)** 채택 — PixelSprite texture는 그대로 유지(zPos 0), face child를 zPos=1로 위에 얹음. CharacterFaceNode의 head ellipse(opaque fill)가 player visual(32×40)을 거의 덮어 시각 중심이 face child가 됨. refreshTexture를 건드리면 PixelSprite 시스템 byte-identical 제약 위반이므로 본 방식이 가장 안전. 발 부분(하단 6pt)은 pixel sprite가 비치며 자연 톤.
- **OQ-3** (DPad 함수): `updateDirection(forTouchLocation:)` 끝에 1 if-let 추가. `touchesEnded`/`Cancelled`의 `.zero` set은 콜백 미발화 → 정지 시 마지막 방향 유지. `Direction.init?(vector:)`가 `.zero`에서 nil 반환 → 본 함수에 `.zero`가 흘러들어와도 자연 noop.

## Swift 패턴 준수

- [x] 강제 언래핑 미사용: `Direction.init?(vector:)`로 Optional, `if let dir = Direction(vector:)` 패턴
- [x] guard let 옵셔널 처리: DPadNode `updateDirection`의 if-let, PlayerNode `physicsBody?.velocity`(기존 패턴 유지)
- [x] MARK 섹션 구분: `// MARK: - Facing (Sprint 7 Phase G)`, `// MARK: - Callbacks (Sprint 7 Phase G)`, `// MARK: - Sprint 7 Phase G · Back Face` 등
- [x] GameConfig 상수 사용: `playerFaceChildScale`, `playerFaceChildZPosition` 외부화
- [x] weak self 캡처: `setupDPad()`의 `dpad.onDirectionChanged = { [weak self] direction in ... }`
- [x] switch default 미사용: `Direction` 4 case exhaustive, `init(id:facing:)` switch facing 4 case + 내부 switch id 5 case 모두 exhaustive

## SpriteKit 패턴 준수

- [x] didMove(to:)에서 초기화: 기존 패턴 유지(setupDPad가 GameScene 진입점에서 호출)
- [x] dt 기반 이동: PlayerNode `update(deltaTime:)` byte-identical
- [x] SKAction 스폰 패턴: face child는 `apply(_:)`에서 1회만 추가(`addChild` 반복 없음), `facing(_:)`은 isHidden 토글만
- [x] 충돌 후 노드 즉시 삭제 없음: face child는 충돌 노드와 무관
- [x] HUD 노드 분리: face child는 PlayerNode child(worldNode 자식 chain)

## PixelSprite texture 시스템 byte-identical

- [x] `loadTexture(for:direction:frame:)`: 0줄 변경
- [x] `refreshTexture()`: 0줄 변경
- [x] `updatePixelDirection(_:)`: 0줄 변경
- [x] `tickWalkFrame(deltaTime:isMoving:)`: 0줄 변경
- [x] PixelDirection·PixelFrame 상호작용: 0줄 변경
- [x] face child는 PixelSprite과 무관 — `addChild`로 독립 layer

## 빌드 상태

- **빌드 결과**: ✅ **BUILD SUCCEEDED**
- 명령: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination "generic/platform=iOS Simulator" build`
- 예상 빌드 에러: 없음
- 신규 워닝: 없음 (사전 존재 font duplicate 워닝 3개만 남음 — 본 sprint 무관)

## 범위 외 미구현 항목

- 없음. SPEC 기능 1~7 모두 구현 완료.
- 후속 sprint 후보(SPEC 명시):
  - 5캐릭터 back/side 헤어 silhouette 차별화 보강 (현재는 hairBrown 공통 + path 형태로 구분)
  - PixelSprite texture를 face child에 흡수해 hybrid 시스템 정리 (현재는 자연 겹침)
