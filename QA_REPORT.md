# QA 검수 보고서 — Phase 4-7 (F) 수간호사 복귀 후 F 재스폰

## SPEC 기능 검증

- **PASS** 기능 1 — `SpawnSystem.fireImmediately()` public wrapper 신설
  - `Systems/SpawnSystem.swift:149-151` — `// MARK: - Projectile Fire` 섹션 안.
  - 본문 1줄 `fireProjectile()` 호출. 기존 private `fireProjectile()` 본문/시그니처 변경 0.
  - 헤더 주석 line 6 Phase 4-7 라인 1줄 추가.
- **PASS** 기능 2 — `EnemyNode.startFleeing(duration:onEnd:)` 시그니처 확장
  - `Nodes/EnemyNode.swift:58` — `onEnd: @escaping () -> Void = {}` 정확.
  - `Nodes/EnemyNode.swift:62-65` — sequence end `SKAction.run` 안에서 `self?.isFleeing = false` 다음 줄 `onEnd()` 호출 정확.
  - `[weak self]` 캡처 유지(line 62), `isFleeing`/`update`/`init` 본문 변경 0.
  - 헤더 line 7 / doc line 57 Phase 4-7 주석 추가.
- **PASS** 기능 3 — `GameScene.triggerAirforceEasterEgg` trailing closure 확장
  - `GameScene.swift:216-218` — `enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in self?.spawnSystem.fireImmediately() }` 정확.
  - `[weak self]` + 옵셔널 체이닝 정확.
  - 기존 본문 10줄(비행기 4 + 오버레이 3 + 폭탄 3) + 가드 2줄(line 204-205) 한 글자도 변경 0.
  - 헤더 MARK line 28 / doc line 202 Phase 4-7 주석 추가.

## 빌드 검증

- **결과**: `** BUILD SUCCEEDED **`
- **시뮬레이터**: iPhone 17 / iOS 26.4 / Debug
- **에러**: 0건
- **경고**: 0건 (Swift 컴파일 경고 0건, `Metadata extraction skipped` 환경 메시지는 SPEC 외 무관)
- **빌드 명령**:
  ```
  xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
    -scheme "GanhoMusic iOS" \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build
  ```

## 회귀 검증 (모두 0줄 변경 확인)

| 파일/그룹 | `git diff --stat` 결과 |
|---|---|
| `Nodes/AirplaneNode.swift` | 0 |
| `Nodes/AirforceOverlayNode.swift` | 0 |
| `Nodes/BombFlashNode.swift` | 0 |
| `Systems/ContactRouter.swift` | 0 |
| `Config/PhysicsCategory.swift` | 0 |
| `Nodes/StoneGuardNode.swift` | 0 |
| `GameScene+Setup.swift` | 0 |
| `Config/GameConfig.swift` (전체) | 0 |
| `Nodes/PlayerNode.swift` / `NoteNode.swift` / `ProjectileNode.swift` / `HUDNode.swift` / `DPadNode.swift` | 0 |
| `Scenes/TitleScene.swift` / `ResultScene.swift` | 0 |
| `Config/ColorTokens.swift` | 0 |
| `macOS` / `tvOS Sources` | 0 |
| `project.pbxproj` | 0 |
| 기존 `SpawnSystem.fireProjectile()` 본문/시그니처 | 0 (line 117-136 그대로) |
| 기존 `EnemyNode.isFleeing` / `update` / `init` | 0 |
| 기존 `triggerAirforceEasterEgg` 본문 10줄 (비행기 4 + 오버레이 3 + 폭탄 3) | 0 |
| `airforceTriggered` 가드 2줄 (line 204-205) | 0 |

git diff 통계: **+13줄 / -2줄**, 3개 파일만 수정. SPEC 예상(+13줄)과 정확 일치.

## 검증 시나리오 (a)~(i) 결과

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| (a) | `fireImmediately` 호출 1곳 (GameScene) | **PASS** | `grep -rn fireImmediately`: 호출 사이트는 `GameScene.swift:217` 1곳만 (정의: `SpawnSystem.swift:149`, 주석 3곳). |
| (b) | trailing closure 형태 정확 | **PASS** | `GameScene.swift:216` — `enemy.startFleeing(duration: GameConfig.enemyFleeDuration) { [weak self] in` (`onEnd:` 라벨 미사용, Swift 관용). |
| (c) | `onEnd` default `= {}` 정확 | **PASS** | `EnemyNode.swift:58` — `onEnd: @escaping () -> Void = {}` 일치. |
| (d) | sequence 마지막 run에 `onEnd()` (isFleeing=false 다음) | **PASS** | `EnemyNode.swift:62-65` — `self?.isFleeing = false` 다음 줄 `onEnd()`. 순서 정확. |
| (e) | `[weak self]` 두 곳 | **PASS** | (1) `GameScene.swift:216` trigger 콜백, (2) `EnemyNode.swift:62` end run. |
| (f) | `projectileMaxConcurrent` 가드 유지 | **PASS** | `SpawnSystem.swift:121` `guard currentProjectileCount() < GameConfig.projectileMaxConcurrent else { return }` 변경 0. wrapper도 `fireProjectile()` 통해 동일 가드 통과. |
| (g) | `airforceTriggered` 가드 그대로 | **PASS** | `GameScene.swift:204-205` 2줄 변경 0. |
| (h) | ARC 안전 | **PASS** | `[weak self]` → `self?.spawnSystem.fireImmediately()` 옵셔널 체이닝. ResultScene 전환 후 GameScene 해제 시에도 nil → 무해. EnemyNode end run의 `self?.isFleeing` 도 동일 패턴 + `onEnd()` 는 closure 변수 캡처라 self와 별개로 정상 호출. |
| (i) | 빌드 SUCCEEDED + 경고 0 | **PASS** | iPhone 17 / iOS 26.4 Debug 빌드 `BUILD SUCCEEDED`, 경고 0, 에러 0. |

## 추가 검증 항목

- **`@escaping` 정확**: `EnemyNode.swift:58` — `@escaping () -> Void` 키워드 정확. `SKAction.run` 클로저가 메서드 종료 후 보관되어 비동기 호출되므로 필수.
- **public wrapper / private fireProjectile 분리**: `SpawnSystem.swift:117` (private `fireProjectile()`) + `SpawnSystem.swift:149` (public `fireImmediately()`) 분리 유지. private 내부 구현 + public 외부 진입점 캡슐화 패턴.

## 정적 검수 — 금지 패턴 검사

| 검사 | 명령 | 결과 |
|---|---|---|
| 강제 언래핑 `!` 신규 도입 | `grep -nE "[A-Za-z_)\]]!"` (3개 파일) | **0건** (`!=` / `//` 제외) |
| `Timer.` 사용 | `grep -nE "Timer\."` (3개 파일) | **0건** |
| `DispatchQueue` 사용 | `grep -nE "DispatchQueue"` (3개 파일) | **0건** (주석 1건 — 금지 문서화) |
| 충돌 콜백 즉시 `removeFromParent()` | `grep -n removeFromParent` | `GameScene.swift:182, 187` 모두 `.run(.removeFromParent())` SKAction 패턴 — 안전(기존 코드, 변경 0) |
| 매직 넘버 신규 도입 | 신규 코드 라인 검사 | **0건** (`GameConfig.enemyFleeDuration` 등 기존 상수만 사용) |
| 신규 `import` | 추가 import 확인 | **0건** (SpriteKit만 기존 사용) |

## SpriteKit 패턴 준수

- `didMove(to:)` 초기화 — 변경 영역 외 (기존 유지).
- `dt` 기반 이동 — 변경 영역 외.
- `SKAction.sequence` 스폰 — `EnemyNode.startFleeing` 그대로 유지 (start → wait → end).
- 충돌 델리게이트 내 즉시 삭제 없음 — `.run(.removeFromParent())` SKAction 패턴 유지.
- HUD 노드 분리 — 변경 영역 외.
- `PhysicsCategory` 비트마스크 — 변경 영역 외.

## 파일 분리 / 사이즈

- `GameScene.swift` — **252줄** (300줄 미만 유지).
- 신규 파일 0건, pbxproj 변경 0건.

## Sprint 범위

- OoS 위반 0건. SPEC In Scope 3건 모두 정확 구현.
- 4-6 호환성 — default `= {}` 덕분에 기존 호출 사이트가 1인자만으로도 컴파일 가능 (현재 호출 사이트는 GameScene 1곳뿐이며 trailing closure로 확장됨).

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- SPEC 기능 3건 100% 구현
- 회귀 검증 18개 그룹 모두 0줄 변경
- 검증 시나리오 (a)~(i) 9개 모두 PASS
- 빌드 SUCCEEDED + 경고 0 + 에러 0
- 강제 언래핑 / Timer / DispatchQueue / 매직 넘버 / 신규 import 0건
- `@escaping` 키워드 + default `= {}` + `[weak self]` 두 곳 모두 정확
- public wrapper / private 분리 패턴 유지
- ARC 안전 (옵셔널 체이닝)
- AIRFORCE 이스터에그 5/5 단계 완성

## P0 / P1 / P2 — 이슈

없음.

---

## 채점

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (35%) | 10/10 | `@escaping`/default/`[weak self]`/옵셔널 체이닝/MARK 섹션 모두 규칙 일치. 신규 코드 매직 넘버·강제 언래핑 0건. |
| 게임 로직 완성도 (30%) | 10/10 | SKAction.sequence로 시간 흐름 표현(Timer 금지 준수). 콜백 등록 패턴이 별도 SKAction 동기화보다 안전. 도주→복귀 직후 F 1발 발사 의도 정확 구현. |
| 성능 & 안정성 (20%) | 10/10 | `[weak self]` 두 곳 + 옵셔널 체이닝. ResultScene 전환 후 self nil 가능성 안전. `projectileMaxConcurrent` 가드로 동시 발사 한계 보호. |
| 기능 완성도 (15%) | 10/10 | SPEC In Scope 3건 모두 정확 구현. OoS 위반 0건. AIRFORCE 이스터에그 5단계 모두 완성. |

**가중 점수** = (10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

### 합격 근거 (엄격 재검토)

내가 관대하게 보지 않았는가? 다시 점검:

1. **변경이 너무 작아 점수가 부풀려진 것 아닌가?** — 변경량은 작지만 SPEC가 명시한 "+~13줄"과 정확 일치, OoS 위반 가능성이 큰 sprint(`isFleeing` 본문, 가드 2줄, fireProjectile 본문)를 모두 0줄로 지켜냄. 변경량 자체가 작아도 정확도는 별개 채점 영역. 감점 사유 없음.
2. **trailing closure 안 `[weak self]` 부재 가능성?** — line 216 정확 존재.
3. **EnemyNode self == nil일 때 `onEnd()` 미호출 가능성?** — `onEnd`는 closure 변수로 캡처되어 `self?.isFleeing = false` 다음 줄 `onEnd()` 가 self와 무관하게 호출됨. 호출 누락 없음.
4. **GameScene self == nil일 때 fireImmediately 미실행 가능성?** — 의도된 동작. ResultScene으로 전환 후 GameScene 해제됐다면 발사할 필요가 없으며 옵셔널 체이닝으로 무해.
5. **빌드 경고 0이 정말인가?** — `grep -iE "warning:|error:"` 환경 메시지 제외 0건 확인.

감점 사유 없음. **10.0/10.0 합격** 확정.

### 구체적 개선 지시

없음 — SPEC 명세를 한 글자 단위로 정확히 구현. 추가 작업 불필요.
