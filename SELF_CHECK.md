# 자체 점검 — Phase 4-4 "나와라 박병장!" AIRFORCE 오버레이

전략: 1회차 — Planner 산출 SPEC.md를 그대로 정확 구현.

## 파일별 변경 줄 수

| 파일 | 변경 유형 | 줄 수 | 위치 |
|---|---|---|---|
| `GanhoMusic Shared/Nodes/AirforceOverlayNode.swift` | 신규 | 56줄 (전체) | 신설 |
| `GanhoMusic Shared/Config/GameConfig.swift` | 6줄 추가 | +6 (doc 3 + 상수 3) | 202~208 (Airforce 섹션 끝) |
| `GanhoMusic Shared/GameScene.swift` | 6줄 추가 | +6 (헤더 MARK 1 + doc 2 + 본문 3) | 25, 195-196, 204-206 |
| `GanhoMusic.xcodeproj/project.pbxproj` | 4줄 추가 | +4 | line 30, 54, 191, 424 |

총 변경: 1 신규 + 16줄 추가. SPEC "헤더 MARK 1 + 본문 3 + 코멘트 2" = 6줄 전부 정확.

## SPEC 기능 체크
- [x] **기능 1 (AirforceOverlayNode 신설)**: `final class AirforceOverlayNode: SKNode`. `private let label: SKLabelNode`. init에서 text="나와라 박병장!", zPosition=200, name="airforceOverlay". `configureLabel()` 호출 후 `addChild(label)`. `showAndDismiss()`가 `SKAction.sequence([wait(displayDuration), fadeOut(fadeOutDuration), removeFromParent()])` 실행. PhysicsBody 없음.
- [x] **기능 2 (GameConfig 3상수)**: `airforceOverlayFontSize: CGFloat = 28`, `airforceOverlayDisplayDuration: TimeInterval = 1.5`, `airforceOverlayFadeOutDuration: TimeInterval = 0.3`. Airforce 섹션(`// MARK: - Airforce Easter Egg (Phase 4-3)`) *내부 끝*, `airplaneTopOffset` 바로 다음에 추가. 새 MARK 없음.
- [x] **기능 3 (GameScene.swift)**: (a) 헤더 4-3 MARK 다음 줄에 4-4 MARK 1줄. (b) `triggerAirforceEasterEgg()` doc 코멘트에 Phase 4-4 동작 설명 2줄 추가. (c) 본문 마지막에 `let overlay = AirforceOverlayNode()` / `cameraNode.addChild(overlay)` / `overlay.showAndDismiss()` 3줄 추가. 비행기 부분 한 줄도 변경 X. 가드 안쪽 보장.
- [x] **기능 4 (pbxproj 4곳 0019)**: PBXBuildFile (line 30), PBXFileReference (line 54), Nodes 그룹 children (line 191), iOS Sources phase (line 424). AirplaneNode 0018 패턴 정확 답습. path = `AirforceOverlayNode.swift` (디렉터리 미포함). tvOS/macOS 0건.

## OoS 미위반 체크리스트 (전부 미변경 확인)
- [x] `AirplaneNode.swift` — 한 줄도 미변경 (Read로 확인 완료, 단 git diff 0)
- [x] `ContactRouter.swift` — 미변경
- [x] `PhysicsCategory` — 미변경
- [x] `StoneGuardNode.swift` — 미변경
- [x] `GameScene+Setup.swift` — 미변경
- [x] 기존 `GameConfig` 상수 값/이름 — airplane 4상수(`airplaneWidth=32`, `airplaneHeight=16`, `airplaneCrossDuration=2.0`, `airplaneTopOffset=60`) 및 그 외 일체 미변경
- [x] 다른 노드 (Enemy/Player/Note/Projectile/HUD/DPad) — 미변경
- [x] `TitleScene` / `ResultScene` — 미변경
- [x] `ColorTokens` 새 토큰 — 신설 0건. 기존 `.ganhoYellowF` 재사용만
- [x] `update()` — 미변경
- [x] `endGame()` — 미변경
- [x] `airforceTriggered` 가드 위치 — `if airforceTriggered { return }` / `airforceTriggered = true` 그대로 (line 198~199)
- [x] 비행기 4줄 (`AirplaneNode()` / `cameraNode.addChild(plane)` / `let y = ...` / `plane.crossScreen(...)`) — 한 줄도 변경 없음 (line 200~203)
- [x] 부착지 cameraNode 외 사용 — 없음
- [x] 오버레이 위치 설정 코드 — 없음 (Planner 지시: cameraNode 자식 (0,0) = 화면 중앙, 라벨 position .zero만)
- [x] 메서드 분리 — 안 함. `triggerAirforceEasterEgg()` 한 곳에 응집
- [x] tvOS / macOS Sources phase — 미변경 (둘 다 빈 `files = ()`)
- [x] 사용자 입력 처리 추가 — 없음
- [x] `gameState` / 일시정지 — 미변경

## 코드 패턴 준수
- 강제 언래핑 미사용: 준수 (AirforceOverlayNode.swift의 `!`는 모두 "박병장!" 텍스트 안 느낌표만 — 코드 0건)
- `guard let` / `if let` 옵셔널 처리: 해당 없음 (옵셔널 0건)
- MARK 섹션 구분: 준수 (`// MARK: - Properties / Init / Show / Dismiss / Configure`)
- GameConfig 상수 사용: 준수 (28/1.5/0.3 매직 넘버 0, 모두 GameConfig 참조)
- `[weak self]` 캡처: 해당 없음 (showAndDismiss self 미참조 — SPEC 명시)

## SpriteKit 패턴 준수
- `didMove(to:)` 초기화: 해당 없음 (GameScene `didMove` 미변경)
- dt 기반 이동: 해당 없음
- `SKAction` 스폰 패턴: 준수 (Timer 0, SKAction.wait + fadeOut + removeFromParent)
- 충돌 후 노드 즉시 삭제 없음: 준수 (PhysicsBody 부착 0)
- HUD 노드 분리: 해당 없음 (HUD 미변경)
- 자가 소멸 fire-and-forget: 준수 (AirplaneNode 패턴 답습)
- zPosition 계층: 준수 (HUD=100 < AirforceOverlayNode=200, Airplane=50)
- 부착지: 준수 (cameraNode.addChild — worldNode/self/hud 0건)

## 빌드 결과
- **xcodebuild build (iOS Simulator) — BUILD SUCCEEDED** (line 마지막)
- 명령어: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`
- 컴파일 경고: 0건 (grep "warning:|error:" — `AppIntents.framework` 무관 경고 제외 후 0)
- 컴파일 에러: 0건
- 링크 성공 (arm64 + x86_64 universal binary, CodeSign 완료)

## 검증 시나리오 (a)~(i) 정적 검증 결과

| # | 시나리오 | 검증 방법 | 결과 |
|---|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 → 오버레이 0건 | `triggerAirforceEasterEgg()` 호출 경로가 `contactRouter.onStoneGuardContact` 콜백뿐인지 (`grep triggerAirforceEasterEgg`) | **통과** — 호출은 line 187 `self?.triggerAirforceEasterEgg()` 1곳뿐. didMove/update/endGame에서 호출 0건 |
| (b) | Player가 석조무사 첫 통과 → 노란 "나와라 박병장!" + 비행기 동시 등장 | `triggerAirforceEasterEgg()` 본문에 `AirforceOverlayNode()` / `cameraNode.addChild(overlay)` / `overlay.showAndDismiss()` 3줄 존재 | **통과** — GameScene.swift line 204-206에 정확 3줄 존재 |
| (c) | ~1.5초 후 → 오버레이 페이드아웃 시작 | `showAndDismiss()` 시퀀스 정확: `wait(1.5) → fadeOut(0.3) → removeFromParent()` | **통과** — AirforceOverlayNode.swift line 39-42, `[wait, fadeOut, cleanup]` 순서 정확. wait는 `airforceOverlayDisplayDuration=1.5`, fadeOut은 `airforceOverlayFadeOutDuration=0.3` 사용 |
| (d) | ~1.8초 후 → 오버레이 완전 사라짐 | `airforceOverlayDisplayDuration + airforceOverlayFadeOutDuration == 1.5 + 0.3 = 1.8` 및 `removeFromParent()` 부착 | **통과** — GameConfig line 205+208에서 산술적으로 1.8초. cleanup 액션이 시퀀스 마지막 |
| (e) | 재통과 시 → 오버레이·비행기 모두 0 | `airforceTriggered` 가드 진입부 그대로 (line 198~199) | **통과** — `if airforceTriggered { return }` 가드가 비행기·오버레이 *둘 다* 위에 위치. 한 번 true 되면 두 노드 모두 차단 |
| (f) | 점수·HUD 영향 0 | `update()` / `endGame()` / `scoreSystem` / `hud` 한 줄도 변경 없음 | **통과** — GameScene.swift `update()` (line 127-164) 한 줄도 미변경. `endGame()` (line 208-233) 미변경. `scoreSystem` 호출부 미변경 |
| (g) | D-Pad 정상 입력 | `dpad` / `player.currentDirection` / `player.update` 변경 없음 | **통과** — update() line 148 `player.currentDirection = dpad.currentDirection` 그대로. `player.update(deltaTime: dt)` 그대로 |
| (h) | 게임오버 잔존 → ResultScene 전환 시 ARC 자동 해제 | `endGame()` 변경 없음 — `cameraNode` 자식 overlay도 함께 해제 | **통과** — `endGame()` 미변경. `view.presentScene(resultScene, ...)` 시 GameScene → cameraNode → overlay 체인이 모두 ARC로 dealloc. SKAction.sequence도 SKNode dealloc 시 자동 정리 |
| (i) | pbxproj 정합성 → 빌드 SUCCEEDED + 경고 0 | 4곳 식별자가 모두 정확히 1회 등장. tvOS/macOS 0019 0건 | **통과** — `grep 0019` 결과: line 30 (PBXBuildFile), 54 (PBXFileReference), 191 (Nodes children), 424 (iOS Sources phase). tvOS Sources phase는 line 427-429 `files = ()` 빈 상태 그대로, macOS도 동일 |

## 텍스트 정확성
- "나와라 박병장!" — 띄어쓰기 1회, 느낌표 1개 (AirforceOverlayNode.swift line 22). 변형 없음.

## 가드 정합성
- `airforceTriggered` 가드 → 플래그 → 비행기 → 오버레이 순서 보장 (GameScene line 198-206):
  ```
  198: if airforceTriggered { return }
  199: airforceTriggered = true
  200: let plane = AirplaneNode()
  201: cameraNode.addChild(plane)
  202: let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
  203: plane.crossScreen(sceneWidth: size.width, atY: y)
  204: let overlay = AirforceOverlayNode()
  205: cameraNode.addChild(overlay)
  206: overlay.showAndDismiss()
  ```
- 가드 단일점: 두 노드 모두 동일 가드 안쪽 → 1회 한정. 재발동 시 진입 차단.

## 범위 외 미구현 항목
- 없음. SPEC 명시 In Scope 4건 모두 완료. Out of Scope 항목 위반 0건.
