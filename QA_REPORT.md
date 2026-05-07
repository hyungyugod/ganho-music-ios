# QA 검수 보고서 — Phase 2-8 수간호사 속도 시간 보간

## SPEC 기능 검증

- **[PASS]** 기능 1 — `GameConfig.enemyMaxSpeed = 110` 상수 추가
  - `Config/GameConfig.swift:89` 정의 1건. `enemyBaseSpeed`(L86) 다음 줄 위치 정확.
  - 주석 2줄 (GDD 출처 + Phase 2-8 보간 의도) 모두 SPEC 명시 형식과 일치.
- **[PASS]** 기능 2 — `EnemyNode.update` 시그니처 확장 + 보간 계산
  - `Nodes/EnemyNode.swift:54` 시그니처 `func update(deltaTime: TimeInterval, targetPosition: CGPoint, speedT: CGFloat)` — `speedT: CGFloat` 인자 추가.
  - `:65-66` 보간 공식 `let speed = GameConfig.enemyBaseSpeed + (GameConfig.enemyMaxSpeed - GameConfig.enemyBaseSpeed) * speedT` SPEC 그대로.
  - `:67-70` velocity dx/dy 곱셈 항이 `* speed`로 일관 — base 직접 사용 0.
- **[PASS]** 기능 3 — `GameScene.update(_:)` 안 curveT 계산 + 호출 인자 추가
  - `GameScene.swift:262` `let curveT = CGFloat(1.0 - remainingTime / GameConfig.gameDuration)` — TimeInterval → CGFloat 캐스트로 시그니처 일치 보장.
  - `:263` `enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)` — speedT 인자 추가. SPEC §"기능 3" 형식 정확 일치.
  - 위치는 `cameraNode.position = player.position` (L257) 직후 — SPEC 가이드 준수.

## 검증 시뮬레이션 (산술 확인)

| 시점 | remainingTime | curveT | speed |
|---|---|---|---|
| 시작 | 45.0 | 0.0 | 60 + 50·0 = **60** |
| 22.5초 | 22.5 | 0.5 | 60 + 50·0.5 = **85** |
| 종료 | 0 | 1.0 | 60 + 50·1 = **110** |

SPEC §"검증 시뮬레이션" (a)/(b)/(c) 모두 산술 일치.

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 컴파일 경고: 0건
- 컴파일 에러: 0건

## 회귀 보존 (git diff --stat)

```
GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift |  3 +++
GanhoMusic/GanhoMusic Shared/GameScene.swift         |  5 ++++-
GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift   | 14 +++++++++-----
3 files changed, 16 insertions(+), 6 deletions(-)
```

- 수정 파일 정확히 3개 (SPEC 명시와 일치).
- `Config/PhysicsCategory.swift` / `GameState.swift` / `ColorTokens.swift` — **0 변경**
- `Nodes/HUDNode.swift` / `DPadNode.swift` / `NoteNode.swift` / `PlayerNode.swift` / `ProjectileNode.swift` — **0 변경**
- iOS 3 파일 / `pbxproj` — **0 변경**
- GameScene 의 다른 함수(setup* / didBegin / endGame / startSpawnLoop / startProjectileFireLoop / fireProjectile / handleNoteContact / handleProjectileContact 등) — **0 변경**
- HUDNode `update(score:remainingTime:combo:)` 시그니처 — **0 변경** (`GameScene:266` 호출 그대로)
- GameConfig 기존 상수 — **0 변경** (enemyMaxSpeed 1상수 *추가*만)
- EnemyNode init / required init — **0 변경** (update 시그니처만 확장)

## 정적 검수 결과

| 검사 항목 | 결과 |
|---|---|
| `enemyMaxSpeed` 정의 1건 (GameConfig) | PASS — `Config/GameConfig.swift:89` |
| `enemyMaxSpeed` 사용 1건 (EnemyNode 보간) | PASS — `Nodes/EnemyNode.swift:66` |
| `speedT: CGFloat` 시그니처 추가 | PASS — `Nodes/EnemyNode.swift:54` |
| 보간 공식 `base + (max - base) * t` | PASS — `Nodes/EnemyNode.swift:65-66` |
| `curveT` 계산 1건 (GameScene) | PASS — `GameScene.swift:262` |
| `enemy.update` 호출 1건 (speedT 인자 포함) | PASS — `GameScene.swift:263` |
| 매직 넘버 60 / 110 / 45 raw 사용 | PASS — 모두 `GameConfig.*` namespace 경유. (HUDNode L24 `"⏱ 00:45"`는 placeholder 표시 문자열로 본 sprint 무관·기존 코드) |
| `hypot` + `magnitude > 0` 가드 보존 | PASS — `Nodes/EnemyNode.swift:57-61` 무손상 |
| `Timer.` 사용 | 0건 |
| `DispatchQueue` 사용 | 0건 |
| `print(` 사용 | 0건 |
| ` as!` 사용 | 0건 |
| 강제 언래핑 `!` 신규 도입 | 0건 (수정 코드 한정) |
| `dx/dy` / 단위벡터 정규화 (`unitX`, `unitY`) 보존 | PASS — `Nodes/EnemyNode.swift:55-56, 62-63` 무손상 |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 1건 (정보 수준) |

## P0 — 치명적 이슈
**없음.**

## P1 — 중요 이슈
**없음.**

## P2 — 권장 사항

### 1. (정보) `speedT` 입력값 clamp(0, 1) 가드 미적용
- **파일**: `Nodes/EnemyNode.swift:54-66`
- **현황**: `speedT`가 0~1 범위 가정. 호출처(`GameScene.swift:262`)는 `remainingTime = max(0, ...)`로 음수 방지되어 상한 1.0이 보장됨. 하한은 `remainingTime` ≤ `gameDuration` 가정 위에서 0으로 보장. 즉 *현재 호출 그래프에서 안전*.
- **판정**: SPEC §주의사항이 명시적으로 clamp 미적용을 의도. 감점 사유 **아님**. 다만 향후 호출처가 늘어나거나 `gameDuration` 동적 변경 sprint가 들어오면 방어적 `min(1, max(0, speedT))` 검토 권장 — 별도 sprint 사항.
- **수정 제안**: 본 sprint에서는 **변경 불필요**. Phase 2-9 또는 difficulty 시스템 도입 sprint에 함께 검토.

## 통과 항목 (요약)

- 강제 언래핑 0건, 옵셔널 체이닝(`physicsBody?.velocity`) 보존 → 크래시 안전
- Swift 패턴: `MARK: - Update` 섹션 구분 보존, `guard magnitude > 0` 가드, `GameConfig.*` namespace 100% 사용
- SpriteKit 패턴: `didMove(to:)` 초기화·SKAction 스폰 루프·dt 기반 update·`PhysicsCategory` 비트마스크·`GameState` enum — 모두 무손상
- 보간 공식의 *NaN 방지 가드 위치*: `magnitude > 0` 검사가 `speed` 계산 *이전* 동작 → 0 division 안전
- Sprint 범위: SPEC OUT(F 발사 주기 보간 / 청진기 / 사운드 / Systems 분리 / player 속도 보간) 모두 미터치 — 범위 위반 0
- 빌드 클린: SUCCEEDED + 경고 0

---

## 채점

**항목별 점수** (4개 기준, 각 /10):

- **Swift 패턴 일관성 (35%)**: **10/10**
  - 매직 넘버 0건, GameConfig namespace 100%, MARK 섹션 보존, 옵셔널 체이닝 / guard 사용, 함수 단일 책임 유지. 완벽.
- **게임 로직 완성도 (30%)**: **10/10**
  - SpriteKit 패턴 무손상. dt 기반 velocity 갱신 유지. 보간 공식이 게임 의도(난이도 곡선) 정확 구현. 검증 시뮬레이션 (a)/(b)/(c) 산술 일치.
- **성능 & 안정성 (20%)**: **10/10**
  - 강제 언래핑 0, weak self 클로저 보존(루프 코드 무변경), NaN 가드(magnitude > 0)가 보간 *전*에 동작 → division-by-zero 불가. 빌드 SUCCEEDED + 경고 0.
- **기능 완성도 (15%)**: **10/10**
  - SPEC §"기능 1/2/3" 모두 정확 구현. 회귀 보존 8 영역 모두 0 변경. SPEC §"준수 룰" 9 항목 모두 PASS.

**가중 점수**: 10·0.35 + 10·0.30 + 10·0.20 + 10·0.15 = **10.0 / 10.0**

## 최종 판정: **합격**

> 최종 점수 8.0 이상이라 한 번 더 엄격히 재검토했습니다. 본 sprint는 *3 파일, 16 줄 추가*의 핫픽스급 변경이며, SPEC가 단일 보간 공식 도입에 한정되어 있고 변경 라인이 모두 SPEC 명시 형식과 1:1 일치합니다. 매직 넘버 / 강제 언래핑 / Timer / 회귀 손상 어느 쪽도 발견되지 않았고, 빌드도 클린합니다. 관대함이 아니라 *변경 표면이 좁고 정확한 결과*로 판단합니다.

**구체적 개선 지시**:
1. **없음.** SPEC 범위 안에서 추가 작업 불필요. 다음 단계(Phase 2-9 — F 발사 주기 보간) 진행 가능.
