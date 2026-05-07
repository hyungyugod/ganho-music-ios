# QA 검수 보고서 — Phase 2-9

## SPEC 기능 검증

| # | 기능 | 결과 |
|---|---|---|
| 1 | `GameConfig.projectileFireIntervalEnd: 2.0` 1상수 | PASS |
| 2 | 기존 `projectileFireInterval = 3.5` 값 보존 + 주석만 갱신 | PASS |
| 3 | `startProjectileFireLoop` 본문 → `scheduleNextFire()` | PASS |
| 4 | `scheduleNextFire()` 신설 (재귀 SKAction) | PASS |
| 5 | `currentFireInterval()` 신설 (선형 보간) | PASS |
| 6 | 보간 공식: `interval + (End - interval) * progress` | PASS |
| 7 | progress = `1.0 - remainingTime / gameDuration` | PASS |
| 8 | 재귀 클로저 `[weak self]` 캡처 | PASS |
| 9 | `self?.fireProjectile()` + `self?.scheduleNextFire()` | PASS |
| 10 | withKey "fireProjectiles" 동일 (endGame과 호환) | PASS |

## 빌드

- `** BUILD SUCCEEDED **`
- 경고 0건

## 정적 검사

| 항목 | 결과 |
|---|---|
| 강제 언래핑 / Timer / DispatchQueue / print / as! / fileprivate | 0건 |
| `repeatForever` (fire 영역) | 0건 (spawn은 그대로) |
| 매직 넘버 | 0건 (모두 GameConfig.*) |
| `[weak self]` | PASS |
| withKey 등록(`scheduleNextFire`) ↔ 정지(`endGame`) 매칭 | PASS |

## 회귀 보존

| 영역 | 결과 |
|---|---|
| Config (PhysicsCategory/GameState/ColorTokens) | 0줄 PASS |
| Nodes (HUDNode/DPadNode/NoteNode/PlayerNode/EnemyNode/ProjectileNode) | 0줄 PASS |
| iOS 3 파일 / pbxproj | 0줄 PASS |
| `fireProjectile` / `currentProjectileCount` 본체 | 0줄 PASS |
| `endGame` 본체 (`removeAction("fireProjectiles")` 그대로) | 0줄 PASS |
| `startSpawnLoop` (음표 spawn `repeatForever`) | 0줄 PASS |
| EnemyNode `update` 시그니처 (2-8) | 0줄 PASS |

## 검증 시뮬레이션 (수치)

- progress 0 (시작): `3.5 + (2.0 - 3.5) × 0 = 3.5초`
- progress 0.5 (중반): `3.5 + (-1.5) × 0.5 = 2.75초`
- progress 1.0 (종료 직전): `3.5 + (-1.5) × 1.0 = 2.0초`
- endGame 시 wait 즉시 취소 → 재귀 종료 (비동기, 콜 스택 누적 0)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 / P1 / P2 | 0 / 0 / 0 |

## 채점

| 항목 | 비중 | 점수 |
|---|---|---|
| Swift 패턴 | 35% | 10/10 |
| 게임 로직 | 30% | 10/10 |
| 성능 & 안정성 | 20% | 10/10 |
| 기능 완성도 | 15% | 10/10 |

**가중 점수: 10.0 / 10**

## 최종 판정: **합격**
