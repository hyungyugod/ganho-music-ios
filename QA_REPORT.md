# QA 검수 보고서 — Phase 4-1 석조무사 NPC

## SPEC 기능 검증

| # | SPEC In Scope | 결과 |
|---|---|---|
| 1 | `Nodes/StoneGuardNode.swift` 신설 (final class, init, startPatrol) | PASS — `final class`, MARK 2개, `required init?(coder:) fatalError`, hypot+dist/speed로 SKAction.repeatForever(.sequence) 정확 구현 |
| 2 | `GameConfig.swift` Stone Guard 섹션 5상수 | PASS — `// MARK: - Stone Guard (Phase 4-1)`, 4상수 모두 `///` 퀵헬프, waypoints 4점 SPEC 좌표 일치 |
| 3 | `GameScene+Setup.swift`에 setupStoneGuard() 추가 | PASS — extension 맨 끝, setupEnemy 다음, 첫 waypoint 부여 + worldNode.addChild |
| 4 | `GameScene.swift` 헤더 1줄 + Properties 1줄 + didMove 1줄 | PASS — 정확히 ±3줄 |
| 5 | pbxproj 4곳 등록 (식별자 0017) | PASS — PBXBuildFile / PBXFileReference / Nodes 그룹 / iOS Sources phase. tvOS·macOS Sources phase 빈 채 유지 |

## 빌드 검증

- **결과**: BUILD SUCCEEDED (iPhone 17 Simulator)
- **에러 0건 / 경고 0건**

## Out of Scope 위반 점검 — 모두 OK

- StoneGuardNode physicsBody 부착 X
- PhysicsCategory에 stoneGuard 비트 X
- ContactRouter에 stoneGuard 분기 X
- SpawnSystem 관여 X
- 새 ColorTokens 토큰 X
- 박병장·이교주 등 다른 NPC X
- 이스터에그/오버레이/비행기/폭탄 X
- macOS/tvOS Sources phase 변경 X
- update() 게임 루프 변경 X
- configureContactRouter / endGame 변경 X

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 검증 시나리오 (a)~(h) 정적 검증

| # | 시나리오 | 결과 |
|---|---|---|
| (a) | 시작 직후 (200,100) 우향 | PASS — first=(200,100), 첫 .move(to: w[1]=(760,100)) |
| (b) | ~10초 (760,100) 도착 → 위 | PASS — 560/55 ≈ 10.18s |
| (c) | ~15초 (760,380) → 좌 | PASS — +280/55 ≈ 5.09s = 15.27s |
| (d) | ~25초 (200,380) → 아래 | PASS — +560/55 ≈ 10.18s = 25.45s |
| (e) | ~30~31초 (200,100) 복귀 | PASS — +280/55 = 30.55s, repeatForever |
| (f) | player 통과 가능 | PASS — physicsBody nil → 충돌 미발생 |
| (g) | 카메라 follow | PASS — worldNode 자식 |
| (h) | 게임오버 ARC 정리 | PASS — presentScene 시 GameScene ARC 해제로 자동 |

## 통과 항목

- Swift 패턴 — 강제 언래핑 0, Timer 0, 매직 넘버 0, MARK 2개, final class, required init?(coder:) fatalError, 영어 변수명, 클로저 미사용 (weak self 부담 0)
- SpriteKit 패턴 — SKAction.move + sequence + repeatForever 표준, zPosition 5, worldNode 자식, update 미사용, physicsBody nil로 OoS 정확 준수
- 성능 — 노드 1개 추가, update 부담 0, 매 프레임 IO 0
- 기능 완성도 — SPEC 5/5, OoS 8/8 무위반, 검증 (a)~(h) 통과
- waypoint 검증 — 외곽 벽 내부, 중앙 기둥 미접근, 한 바퀴 30.55초
- pbxproj — 0017 식별자 충돌 0

## 채점

**항목별**:
- Swift 패턴: **10/10**
- 게임 로직: **10/10**
- 성능 & 안정성: **10/10**
- 기능 완성도: **10/10**

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

**핵심 가치**: SKAction 패턴이 처음 도입된 두 번째 AI. *기존 시스템을 한 줄도 깨지 않고* 새 NPC를 추가. update/contactRouter/endGame 한 줄도 건드리지 않음 — 이 sprint의 본질을 정확히 달성.

**다음 sprint 준비**: Phase 4-2 (석조무사 PhysicsBody + AIRFORCE 이스터에그)로 진행 가능.
