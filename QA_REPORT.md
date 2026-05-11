# QA 검수 보고서 — Phase 4-4 "나와라 박병장!" AIRFORCE 오버레이

## SPEC 기능 검증

- **[PASS] 기능 1 (AirforceOverlayNode 신설)** — `final class AirforceOverlayNode: SKNode`, `private let label: SKLabelNode`. init에서 `text="나와라 박병장!"` / `name="airforceOverlay"` / `zPosition=200` / `configureLabel()` / `addChild(label)`. PhysicsBody 0.
- **[PASS] 기능 2 (GameConfig 3상수)** — `airforceOverlayFontSize=28`, `airforceOverlayDisplayDuration=1.5`, `airforceOverlayFadeOutDuration=0.3`. 합산 1.8s. Airforce 섹션 끝 위치(`airplaneTopOffset` 다음), 새 MARK 없음.
- **[PASS] 기능 3 (GameScene.swift)** — 헤더 MARK 1줄(라인 25), `triggerAirforceEasterEgg()` doc 2줄(195-196), 본문 끝 오버레이 3줄(204-206). 비행기 4줄(200-203) 한 줄도 미변경. 가드(198-199) 위치 그대로.
- **[PASS] 기능 4 (pbxproj 0019 4곳)** — PBXBuildFile(30) / PBXFileReference(54) / Nodes children(191) / iOS Sources phase(424). AirplaneNode 0018 패턴 답습. `path = AirforceOverlayNode.swift`. tvOS / macOS Sources 빈 `files = ()` 유지.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령어**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`
- **컴파일 경고/에러**: 0건 / 0건

## 시나리오 (a)~(i) 정적 검증

| # | 시나리오 | 결과 |
|---|---|---|
| (a) | trigger 호출 경로가 onStoneGuardContact 콜백 1곳뿐 | **PASS** — `GameScene.swift:187` `self?.triggerAirforceEasterEgg()` 1곳. didMove/update/endGame 직접 호출 0. |
| (b) | trigger 본문 3줄 (overlay 생성/addChild/showAndDismiss) | **PASS** — `GameScene.swift:204-206`. |
| (c) | showAndDismiss 시퀀스 순서 | **PASS** — `[wait, fadeOut, cleanup]` 정확. wait=displayDuration, fadeOut=fadeOutDuration. |
| (d) | 두 상수 합산 1.8s | **PASS** — 1.5 + 0.3 = 1.8. |
| (e) | airforceTriggered 가드 진입부 그대로 | **PASS** — `if airforceTriggered { return }` / `airforceTriggered = true` 두 줄 진입부. 가드 → 플래그 → 비행기 → 오버레이 순서. |
| (f) | update/endGame/scoreSystem/hud 변경 0 | **PASS** — 모두 미변경. |
| (g) | dpad/player 변경 0 | **PASS** — `player.currentDirection` / `player.update` 그대로. |
| (h) | endGame 변경 0 | **PASS** — ResultScene 전환 시 cameraNode 자식 overlay도 ARC 자동 해제. |
| (i) | pbxproj 4곳 + tvOS/macOS 0건 + 빌드 SUCCEEDED + 경고 0 | **PASS** — 30/54/191/424 4곳 0019 정확. tvOS/macOS 0건. |

## 추가 검증 결과

- **`final class : SKNode`** — 정확
- **zPosition = 200** — HUD(100), Airplane(50) 위
- **SKLabelNode 스타일** — `.ganhoYellowF` / `.center`/`.center` 정렬 / `position = .zero`
- **"나와라 박병장!"** — 띄어쓰기 1, 느낌표 1. 변형 0
- **강제 언래핑 0** — `!` 사용처: required init?(coder:) fatalError(표준), "박병장!" 문자열 리터럴
- **매직 넘버 0** — 28/1.5/0.3 모두 GameConfig 상수 참조
- **[weak self] 캡처** — showAndDismiss self 미사용 → 생략 정당
- **부착지 cameraNode** — `cameraNode.addChild(overlay)` 정확

## 회귀 검증 (OoS, 모두 0줄 변경)

`git diff HEAD --` 대상별:
- `AirplaneNode.swift` — **0 lines**
- `ContactRouter.swift` / `PhysicsCategory.swift` / `StoneGuardNode.swift` / `GameScene+Setup.swift` — **0 lines**
- 기타 노드/씬/`ColorTokens.swift` — **0 lines**
- macOS / tvOS Sources phase — 변경 0

변경 stat:
- `Config/GameConfig.swift` +7 (doc 3 + 상수 3 + 섹션 공백 1)
- `GameScene.swift` +6 (헤더 MARK 1 + doc 2 + 본문 3)
- `project.pbxproj` +4

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- 강제 언래핑 0건(코드)
- Timer/DispatchQueue 0건 — `SKAction.wait/fadeOut/removeFromParent` 시퀀스
- 매직 넘버 0건 — 모두 GameConfig
- MARK 섹션 — Properties / Init / Show / Dismiss / Configure
- `final class` 선언
- 파일 분리 — Nodes/ 1 파일 = 1 클래스
- GameScene 응집 — `triggerAirforceEasterEgg` 단일점, 메서드 분리 X
- 부착지 일관성 — cameraNode 자식
- zPosition 계층 — Airplane(50) < HUD(100) < AirforceOverlay(200)
- 색 토큰 재사용 — `.ganhoYellowF`
- self 캡처 정확
- OoS 위반 0
- tvOS/macOS Sources phase 미변경
- 빌드 SUCCEEDED + 경고 0

## 채점

**항목별**:
- **Swift 패턴 일관성: 10/10**
- **게임 로직 완성도: 10/10**
- **성능 & 안정성: 10/10**
- **기능 완성도: 10/10**

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

**핵심 가치**: 자가 소멸 노드 패턴(AirplaneNode)의 *두 번째 적용*. SKAction.sequence([wait, fadeOut, removeFromParent]) 토스트 패턴 정석. *호출 측 변경 0* 정책이 4-2 → 4-3 → 4-4 *세 sprint 연속* 유지.

**다음 sprint 준비**: Phase 4-5 (폭탄 화면 플래시) / 4-6 (수간호사 5초 도주) / Phase 4-Z (이교주 NPC) 후보.
