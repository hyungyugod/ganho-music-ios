# 자체 점검 — Phase 4-6 (E) 수간호사 5초 도주 모드

전략: 최초 구현 (1회차).

## 파일별 변경 줄 수

| 파일 | 추가 줄 | 삭제 줄 | 변경 요약 |
|---|---|---|---|
| `GanhoMusic Shared/Nodes/EnemyNode.swift` | +16 | 0 | 헤더 1 + `// MARK: - State` 4 + `// MARK: - Flee` 9 + update 분기 3 줄 (direction 주석 1 + `let direction` 1 + `* direction` 2회) |
| `GanhoMusic Shared/Config/GameConfig.swift` | +3 | 0 | Airforce 섹션 끝 doc 2줄 + `enemyFleeDuration: TimeInterval = 5.0` 1줄 |
| `GanhoMusic Shared/GameScene.swift` | +3 | 0 | 헤더 MARK 1 + trigger doc 1 + `enemy.startFleeing(...)` 1줄 |

신설 파일 0, 삭제 파일 0, pbxproj 변경 0.

## SPEC 기능 체크
- [x] 기능 1 — `var isFleeing: Bool = false`: EnemyNode 19행, `// MARK: - State` 섹션 신설
- [x] 기능 2 — `startFleeing(duration:)`: EnemyNode 56~62행, 첫 줄 `if isFleeing { return }` 가드, 두 `SKAction.run` 모두 `[weak self]`
- [x] 기능 3 — update 방향 분기: EnemyNode 86행 `let direction: CGFloat = isFleeing ? -1 : 1`, 87~89행 velocity 두 성분 모두 `* direction`
- [x] 기능 4 — EnemyNode 헤더: 6행 "Phase 4-6 · 5초 도주 모드 추가" 1줄 추가
- [x] 기능 5 — GameConfig `enemyFleeDuration`: 219행, Airforce 섹션 *끝* (`bombFlashFadeOutDuration` 다음), doc 2줄 포함
- [x] 기능 6 — GameScene trigger 1줄: 214행 본문 *마지막*, `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)`
- [x] 기능 7 — GameScene 헤더/doc: 27행 헤더 MARK + 200행 trigger doc

## OoS(Out of Scope) 미위반 체크리스트
- [x] AirplaneNode.swift 변경 0
- [x] AirforceOverlayNode.swift 변경 0
- [x] BombFlashNode.swift 변경 0
- [x] ContactRouter.swift 변경 0
- [x] PhysicsCategory.swift 변경 0
- [x] StoneGuardNode.swift 변경 0
- [x] GameScene+Setup.swift 변경 0
- [x] 기존 GameConfig 상수 값 변경 0 (airplane 4 + airforceOverlay 3 + bombFlash 3 + 그 외 모두 그대로)
- [x] Player/Note/Projectile/HUD/DPad Node 변경 0
- [x] TitleScene/ResultScene 변경 0
- [x] ColorTokens 변경 0 (새 토큰 추가 없음)
- [x] update() 게임 루프 변경 0
- [x] endGame() 변경 0
- [x] airforceTriggered 가드 위치 변경 0 (trigger 본문 1~2행 그대로)
- [x] contactBitMask/collisionBitMask 변경 0 (EnemyNode physicsBody 설정 그대로)
- [x] 기존 trigger 본문 10줄 한 줄도 변경 없음 (마지막에 1줄 *추가*만)
- [x] F 재스폰 효과 없음 (다음 sprint)
- [x] DispatchQueue.main.asyncAfter / Timer 사용 0
- [x] 사운드/햅틱 0
- [x] 도주 시각 효과 (색 변화 등) 0
- [x] pbxproj 변경 0
- [x] macOS/tvOS 변경 0
- [x] Test 코드 추가 0
- [x] 도주 속도 별도 상수 추가 0 (enemyBaseSpeed/enemyMaxSpeed 그대로)

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (EnemyNode/GameConfig/GameScene 신규 코드에 `!` 0; grep 검증)
- guard/if let 옵셔널 처리: 준수 (신규 코드에는 옵셔널이 없음 — `isFleeing`은 비옵셔널 Bool)
- MARK 섹션 구분: 준수 (`// MARK: - State`, `// MARK: - Flee` 신설, 기존 `// MARK: - Init`/`// MARK: - Update` 보존)
- GameConfig 상수 사용: 준수 (`enemyFleeDuration` 신설, trigger에서 `GameConfig.enemyFleeDuration` 참조 — 매직 넘버 0)
- weak self 캡처: 준수 (`startFleeing` 내부 두 `SKAction.run` 클로저 모두 `[weak self]`)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 해당 없음 (변경 없음, 기존 그대로)
- dt 기반 이동: 해당 없음 (velocity 기반, 엔진이 dt 처리 — 기존 정책 보존)
- SKAction 스폰 패턴: 준수 (`SKAction.sequence([run, wait, run])`로 시간 흐름 표현, Timer/DispatchQueue 미사용)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (충돌 코드 변경 0)
- HUD 노드 분리: 해당 없음 (HUD 변경 0)

## 빌드 상태
- 빌드: **BUILD SUCCEEDED** (`xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`)
- 경고: 0건 (SDK 자체 노트만 출력, 본 변경 관련 경고 없음)
- 에러: 0건

## 검증 시나리오 정적 검증 결과

| # | 시나리오 | 검증 방법 | 결과 |
|---|---|---|---|
| (a) | 미접촉 시 도주 0 | `grep -rn "startFleeing"` → 호출 1곳 (GameScene.swift:214) 외에 trigger 외부 호출처 없음 | 통과 |
| (b) | trigger 시 호출 정확 | GameScene.swift:214 = `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)` (trigger 본문 마지막) | 통과 |
| (c) | x축 velocity 반전 | EnemyNode.swift:86 `let direction: CGFloat = isFleeing ? -1 : 1` + 88행 `dx: unitX * speed * direction` | 통과 |
| (d) | y축 velocity 반전 | EnemyNode.swift:89 `dy: unitY * speed * direction` | 통과 |
| (e) | 5초 후 false | EnemyNode.swift:60 `let end = SKAction.run { [weak self] in self?.isFleeing = false }` — sequence 마지막 액션 | 통과 |
| (f) | 도주 중 충돌 게임오버 | EnemyNode.swift init 본문 contactTestBitMask=`.player` / collisionBitMask=`.wall` 그대로 (변경 0) | 통과 |
| (g) | 재통과 시 도주 0 | airforceTriggered 가드(GameScene.swift:201) + `if isFleeing { return }` (EnemyNode.swift:57) 이중 가드 | 통과 |
| (h) | ARC 해제 | EnemyNode.swift:58, 60 두 `SKAction.run` 클로저 모두 `[weak self]` 캡처 | 통과 |
| (i) | 빌드 SUCCEEDED + 경고 0 | xcodebuild BUILD SUCCEEDED + 강제 언래핑 0 + 매직 넘버 0 + Timer/DispatchQueue 호출 0 (주석 안 안내만 존재) | 통과 |

## 범위 외 미구현 항목
- 없음. SPEC In Scope 7개 기능 모두 구현, Out of Scope 24개 항목 모두 미접촉.
