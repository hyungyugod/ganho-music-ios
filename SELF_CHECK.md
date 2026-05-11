# 자체 점검 — Phase 4-7 (F) 수간호사 복귀 후 F 재스폰

## SPEC 기능 체크

- [x] **기능 1: SpawnSystem.fireImmediately() public wrapper 신설**
  - `// MARK: - Projectile Fire` 섹션 안, `currentProjectileCount()` 다음에 추가
  - private `fireProjectile()` wrapper, 본문은 `fireProjectile()` 호출 1줄
  - 기존 `fireProjectile()` 본문/시그니처 변경 0
- [x] **기능 2: EnemyNode.startFleeing 시그니처에 onEnd 콜백 추가**
  - `startFleeing(duration: TimeInterval, onEnd: @escaping () -> Void = {})`
  - default `= {}` 적용 (Phase 4-6 호출 사이트 호환)
  - sequence end `SKAction.run` 본문에서 `self?.isFleeing = false` 다음 줄에 `onEnd()` 호출
  - 기존 `isFleeing` / `update` / `init` 본문 변경 0
- [x] **기능 3: GameScene.triggerAirforceEasterEgg 마지막 줄 trailing closure 확장**
  - 기존 1줄 `enemy.startFleeing(duration: GameConfig.enemyFleeDuration)`
  - 신규 3줄 `enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in / self?.spawnSystem.fireImmediately() / }`
  - 그 외 trigger 본문 10줄 + 가드 2줄 변경 0

## 파일별 변경 줄 수

| 파일 | 추가 줄 | 변경 줄 | 비고 |
|---|---|---|---|
| `Systems/SpawnSystem.swift` | +7 | 0 | 헤더 1줄 + wrapper 6줄(doc 3 + 본문 3) |
| `Nodes/EnemyNode.swift` | +4 | 1 | 헤더 1줄 + doc 1줄 + onEnd() 호출 1줄 / startFleeing 시그니처 1줄 수정 |
| `GameScene.swift` | +4 | 1 | 헤더 MARK 1줄 + doc 1줄 + trailing closure 2줄 / 마지막 줄 1줄 수정 |

총 변경: ~16줄 (SPEC 예상 +13줄과 근사). 신규 파일 0건, pbxproj 변경 0건.

## Swift 패턴 준수

- **강제 언래핑 미사용**: 준수 (신규 코드 `!` 0건)
- **guard let 옵셔널 처리**: 해당 없음 (옵셔널 신규 도입 0)
- **MARK 섹션 구분**: 준수 (SpawnSystem `// MARK: - Projectile Fire` 섹션 안 유지)
- **GameConfig 상수 사용**: 준수 (신규 상수 추가 0, 기존 `GameConfig.enemyFleeDuration` 그대로 호출)
- **weak self 캡처**: 준수
  - GameScene 콜백: `{ [weak self] in self?.spawnSystem.fireImmediately() }`
  - EnemyNode end run: `[weak self] in self?.isFleeing = false; onEnd()` (기존 4-6 그대로 유지)

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 해당 없음 (트리거 시점 콜백)
- **dt 기반 이동**: 해당 없음
- **SKAction 스폰 패턴**: 준수 (Timer/DispatchQueue 미사용. `SKAction.sequence([start, wait, end])` 그대로)
- **충돌 후 노드 즉시 삭제 없음**: 준수 (변경 영역에 충돌 콜백 없음)
- **HUD 노드 분리**: 해당 없음

## 빌드 상태

- **xcodebuild build**: `** BUILD SUCCEEDED **` (iPhone 17 simulator, iOS 26.4)
- **경고**: 0건 (코드 관련) — `Metadata extraction skipped. No AppIntents.framework dependency found` 는 SPEC 외 환경 메시지로 무관
- **에러**: 0건
- **강제 언래핑 신규 도입**: 0건
- **매직 넘버 신규 도입**: 0건

## OoS(Out of Scope) 미위반 체크

- [x] AirplaneNode / AirforceOverlayNode / BombFlashNode 변경 0
- [x] ContactRouter / PhysicsCategory / StoneGuardNode / GameScene+Setup 변경 0
- [x] GameConfig 변경 0 (기존 상수 + 신규 상수 모두 0)
- [x] Player / Note / Projectile / HUD / DPad 노드 변경 0
- [x] TitleScene / ResultScene 변경 0
- [x] ColorTokens 신규 토큰 0
- [x] update() / endGame() / airforceTriggered 가드 위치 변경 0
- [x] F 발사 주기 / projectileMaxConcurrent 변경 0
- [x] 기존 fireProjectile 본문/시그니처 변경 0
- [x] 기존 EnemyNode `isFleeing` / `update` / `init` 본문 변경 0
- [x] trigger 본문 10줄(비행기 4 + 오버레이 3 + 폭탄 3) + 가드 2줄 변경 0
- [x] pbxproj 변경 0
- [x] macOS / tvOS 변경 0
- [x] Test 코드 추가 0
- [x] `SelfDismissingNode` 프로토콜 추출 0

## 검증 시나리오 (a)~(i)

| # | 시나리오 | 정적 검증 결과 |
|---|---|---|
| (a) | 미접촉 시 fireImmediately 호출 0 | `grep fireImmediately` GameScene 호출 사이트 1곳뿐(line 217, `triggerAirforceEasterEgg` 안 onEnd 콜백). trigger는 `airforceTriggered` 가드(line 203-204)로 첫 접촉 전 0회. **합격** |
| (b) | trigger 본문에 trailing closure 정확 | line 216 `enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in` 일치. **합격** |
| (c) | onEnd default `= {}` 정확 | `EnemyNode.swift` line 57 `onEnd: @escaping () -> Void = {}` 일치. **합격** |
| (d) | sequence 마지막 run 본문 onEnd() 호출 | `EnemyNode.swift` line 61-64 `self?.isFleeing = false` 다음 줄 `onEnd()`. **합격** |
| (e) | [weak self] 두 곳 | (1) `GameScene.swift` line 216 trigger 콜백 (2) `EnemyNode.swift` line 61 end run. 정확. **합격** |
| (f) | projectileMaxConcurrent 가드 그대로 | `SpawnSystem.fireProjectile()` line 120 `guard currentProjectileCount() < GameConfig.projectileMaxConcurrent else { return }` 변경 0. **합격** |
| (g) | airforceTriggered 가드 그대로 | `triggerAirforceEasterEgg()` 첫 2줄 line 203-204 `if airforceTriggered { return }` + `airforceTriggered = true` 변경 0. **합격** |
| (h) | ARC 안전 | GameScene 콜백 `[weak self]` → `self?.spawnSystem` 옵셔널 체이닝. ResultScene 전환 후 GameScene 해제 시 onEnd 발화해도 self == nil → 옵셔널 체이닝으로 무해. **합격** |
| (i) | 빌드 SUCCEEDED + 경고 0 | `** BUILD SUCCEEDED **` + 경고 0 + 강제 언래핑 0 + 매직 넘버 0 + `@escaping` + default `= {}` 정확. **합격** |

## 4-6 호환성 검증 (default `= {}` 효과)

기존 4-6 호출 사이트(GameScene 외 가능성)에서 `enemy.startFleeing(duration:)` 한 인자 호출 시
default `= {}` 가 적용되어 컴파일 에러 없음. 현재 호출 사이트는 GameScene 1곳뿐이며 trailing closure로 확장됨 — 호환성은 보장되지만 실호출 0건.

## 범위 외 미구현 항목

없음. SPEC In Scope 3건(SpawnSystem / EnemyNode / GameScene) 모두 정확히 구현.

## 전략 (2회차 이상 시 기록)

해당 없음 (1회차).
