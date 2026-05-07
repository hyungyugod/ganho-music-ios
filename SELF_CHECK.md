# 자체 점검 — Phase 2-9 (F 발사 주기 시간 보간)

전략: Case A — 1회차, SPEC.md를 정밀 적용. 직전 sprint 2-8 합격 패턴을 그대로 차용 (보간 공식·`[weak self]`·withKey 정책).

## SPEC 기능 체크

- [x] **기능 1: GameConfig.projectileFireIntervalEnd 추가** — `Config/GameConfig.swift:104` `static let projectileFireIntervalEnd: TimeInterval = 2.0` 1줄 추가. 기존 `projectileFireInterval` 주석을 *시작값* / Phase 2-9 보간 명시로 갱신 (값 3.5 그대로).
- [x] **기능 2: startProjectileFireLoop 본문 교체** — 기존 `repeatForever` 시퀀스 등록 본문을 제거하고 `scheduleNextFire()` 단일 호출로 단순화. 시그니처·호출 위치(`didMove`) 변경 0.
- [x] **기능 3: scheduleNextFire 신설** — `GameScene.swift:322`. wait + run 시퀀스를 withKey "fireProjectiles"로 등록. run 클로저는 `[weak self]` 캡처 후 `self?.fireProjectile()` + `self?.scheduleNextFire()` 2 줄 (재귀).
- [x] **기능 4: currentFireInterval 신설** — `GameScene.swift:336`. 보간 공식 그대로 — `progress = 1.0 - remainingTime / GameConfig.gameDuration`, 반환은 `projectileFireInterval + (projectileFireIntervalEnd - projectileFireInterval) * progress`. EnemyNode.update의 speed 보간과 동일 패턴.

## 준수 룰 12개 (SPEC §"준수 룰")

| # | 룰 | 결과 | 증거 |
|---|---|---|---|
| 1 | `projectileFireIntervalEnd` 1상수 정의 | **PASS** | `GameConfig.swift:104` |
| 2 | `scheduleNextFire` 함수 정의 1건 + 호출 ≥ 2건 | **PASS** | 정의 `GameScene.swift:322`, 호출 `:315` (startProjectileFireLoop) + `:327` (재귀 자기 호출) = 2건 |
| 3 | `currentFireInterval` 함수 정의 1건 + 호출 1건 | **PASS** | 정의 `:336`, 호출 `:323` (scheduleNextFire 안) |
| 4 | 재귀 클로저 `[weak self]` 캡처 | **PASS** | `:325` `let fire = SKAction.run { [weak self] in` |
| 5 | 재귀 클로저 안 `self?.fireProjectile()` + `self?.scheduleNextFire()` 2 줄 | **PASS** | `:326` + `:327` |
| 6 | withKey "fireProjectiles" 1건 (scheduleNextFire 안) | **PASS** | `:329` `self.run(.sequence([wait, fire]), withKey: "fireProjectiles")`. endGame `:436`의 removeAction과 매칭 |
| 7 | 매직 넘버 0건 (3.5/2.0/45 모두 GameConfig.*) | **PASS** | grep 결과 모든 매치는 *주석/문자열*에만 (line 11/29/237/333/334/335/363). 실행 코드는 GameConfig.* 통해서만 사용 |
| 8 | `SKAction.repeatForever`가 fireProjectile 영역에서 0건 (spawn은 그대로) | **PASS** | repeatForever 코드 라인은 `:276` (note spawn) 1건만. fire 영역 0건 |
| 9 | 강제 언래핑 / Timer / print / as! / fileprivate 0건 | **PASS** | grep 0 매치 (Timer\.\|print(\|as!\|fileprivate). `?.` chaining만 사용 |
| 10 | endGame `removeAction(forKey: "fireProjectiles")` 보존 | **PASS** | `:436` 그대로 유지 (변경 0) |
| 11 | `fireProjectile` / `currentProjectileCount` 본체 변경 0 | **PASS** | git diff 확인 — 두 함수 본문 변경 0 |
| 12 | BUILD SUCCEEDED | **PASS** | `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build` → `** BUILD SUCCEEDED **` |

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (옵셔널 chaining `self?.` 사용)
- guard let 옵셔널 처리: **준수** (해당 영역 미사용 — 단순 산술 보간)
- MARK 섹션 구분: **준수** (기존 `// MARK: - Spawn` 섹션 안에 추가, 새 섹션 신설 안 함)
- GameConfig 상수 사용: **준수** (3.5/2.0/45/projectileFireInterval/projectileFireIntervalEnd/gameDuration 모두 GameConfig.* 경유)
- weak self 캡처: **준수** (재귀 클로저에 `[weak self]` + `self?.` 2회)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: **준수** (startProjectileFireLoop 호출 위치 변경 0)
- dt 기반 이동: **해당 없음** (이번 sprint는 보간 *시간 주기* 변경, 이동 로직 무관)
- SKAction 스폰 패턴: **준수** (재귀 SKAction 패턴, Timer 미사용)
- 충돌 후 노드 즉시 삭제 없음: **준수** (handleProjectileContact 변경 0, `.run(.removeFromParent())` 패턴 유지)
- HUD 노드 분리: **준수** (HUD 영역 변경 0)

## 빌드 상태

- 예상 빌드 에러: **없음** (`** BUILD SUCCEEDED **` 확인)
- 주의 필요 경고: **없음**

## 변경 줄 수 (git diff HEAD)

| 파일 | +추가 | -삭제 | 순증 |
|---|---|---|---|
| `Config/GameConfig.swift` | +4 | -1 | +3 (1상수 + 주석 1줄 갱신·확장) |
| `GanhoMusic Shared/GameScene.swift` | +26 | -6 | +20 (scheduleNextFire 9줄 + currentFireInterval 9줄 + start 본문 단순화 차이 + 주석) |
| **합계** | **+30** | **-7** | **+23** |

회귀 보존: PhysicsCategory / GameState / ColorTokens / 6개 Nodes / iOS 3 파일 / pbxproj — 변경 0건 (수정 파일 2개로 한정).

## 범위 외 미구현 항목

- **없음** — SPEC §금지 항목(F 동시 수, 청진기, 무적 시간, 사운드, Systems 분리, player 속도, enemy 속도) 모두 변경 0. SPRint 범위 계약 준수.

## 검증 시뮬레이션 (SPEC §검증 시뮬레이션 일치 확인)

- (a) 시작 직후 `progress = 0` → interval = 3.5 + (2.0 - 3.5) * 0 = **3.5초** ✓
- (b) 남은 22.5초 → `progress = 0.5` → interval = 3.5 + (-1.5) * 0.5 = **2.75초** ✓
- (c) 남은 5초 → `progress ≈ 0.889` → interval ≈ 3.5 + (-1.5) * 0.889 ≈ **2.17초** ✓
- (d) 남은 0초 → `progress = 1.0` → interval = **2.0초** ✓ (단, endGame이 removeAction 호출하여 다음 발사 안 됨)
- (e) enemy 속도 보간 (2-8) 그대로 동시 동작 — `:262` curveT 라인 변경 0 ✓
- (f) F 동시 최대 2개 — `fireProjectile` `:345` guard 그대로 ✓
- (g) endGame 시 fire 시퀀스 즉시 정지 — `:436` removeAction 그대로 ✓
