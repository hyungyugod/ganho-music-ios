# QA 검수 보고서 — Phase 7-1 난이도 3단계 시스템 (하/중/상)

## SPEC 기능 검증

| # | 기능 | 결과 | 비고 |
|---|---|---|---|
| 1 | Difficulty enum + 영구 저장 | PASS | Models/Difficulty.swift(44줄, 4 부속 속성 displayName/subtitle/color), Repositories/DifficultyPreferenceRepository.swift(40줄, CharacterPreferenceRepository 동형) |
| 2 | DifficultyCardNode | PASS | Nodes/DifficultyCardNode.swift(72줄), SKNode 컨테이너 + 색 사각형 + 이름/부제 라벨 + setSelected 토글 |
| 3 | TitleScene 3 카드 + 선택/저장/복원 | PASS | TitleScene.swift:33-38 프로퍼티/:53 didMove 복원/:55,64 setup·layout/:169-203 setup·layout·select/:213-219 touchesBegan 최우선 hit test |
| 4 | GameScene init/factory 확장 (default 인자) | PASS | GameScene.swift:107 difficulty 프로퍼티/:112-116 init/:124-128 factory (`characterID: .kim, difficulty: .easy` 두 인자 모두 default) |
| 5 | PlayerNode/EnemyNode/SpawnSystem apply(_:Difficulty) | PASS | PlayerNode:74-77 / EnemyNode:64-67 / SpawnSystem:43-50 — 모든 dict lookup에 ?? fallback. GameScene+Setup.swift:113-114 character → difficulty 순서 일관 |
| 6 | NoteNode TTL 자가 소멸 | PASS | NoteNode.swift:40-46 applyLifetime, guard `ttl.isFinite, ttl < gameDuration` — easy(.infinity) noop으로 회귀 0 |
| 7 | SpawnSystem 차등 + F burst 루프 | PASS | SpawnSystem.swift:151-173 fireProjectile, `for _ in 0..<projectileBurstCount` + 각 발마다 max 가드(`guard currentProjectileCount() < projectileMaxConcurrent else { return }`) |
| 8 | EnemyNode 보간식 인스턴스 참조 | PASS | EnemyNode.swift:106-107 `self.baseSpeedStart + (baseSpeedEnd - baseSpeedStart) * speedT`, GameConfig.enemyBaseSpeed/MaxSpeed 미참조 |
| 9 | ResultScene 난이도 라벨 | PASS | ResultScene.swift:46,60-77,86-101,127,137,143,185-188 — "난이도: 하/중/상" |

## GDD §5 표 1:1 매핑 검증 (27 셀)

GameConfig.swift §"Difficulty" (라인 416~482) dict 9개 값을 GDD docs/GDD.md:144-158 표와 1:1 대조:

| 항목 | 하(easy) | 중(normal) | 상(hard) | GameConfig 매칭 |
|---|---|---|---|---|
| 플레이어 속도 시작 | 140 | 160 | 160 | playerSpeedStartByDifficulty: [.easy:140,.normal:160,.hard:160] ✓ |
| 플레이어 속도 끝 | 210 | 250 | 250 | playerSpeedEndByDifficulty: [.easy:210,.normal:250,.hard:250] ✓ |
| 동시 음표 수 | 5 | 4 | 4 | noteMaxConcurrentByDifficulty ✓ |
| 음표 TTL | 무한 | 3.5 | 2.8 | noteLifetimeByDifficulty: [.easy:.infinity,.normal:3.5,.hard:2.8] ✓ |
| 수간호사 시작 속도 | 60 | 170 | 200 | enemySpeedStartByDifficulty ✓ |
| 수간호사 끝 속도 | 110 | 290 | 340 | enemySpeedEndByDifficulty ✓ |
| F 최대 동시 수 | 2 | 10 | 14 | projectileMaxConcurrentByDifficulty ✓ |
| 동시 F 투척 수 | 1 | 3 | 4 | projectileBurstCountByDifficulty ✓ |
| F 투척 주기 시작 | 3.5 | 1.0 | 0.8 | projectileFireIntervalStartByDifficulty ✓ |
| F 투척 주기 끝 | 2.0 | 0.35 | 0.25 | projectileFireIntervalEndByDifficulty ✓ |

**결과**: 27 셀 + α(start/end 분리로 10 dict × 3 = 30 매핑) 전부 GDD 정확 일치. **단 한 셀도 불일치 없음**.

## 회귀 0 검증 (git diff HEAD --name-only)

수정·신규 파일 13건:
- 신규 3건: Difficulty.swift / DifficultyPreferenceRepository.swift / DifficultyCardNode.swift
- 수정 10건: GameConfig.swift / GameScene.swift / GameScene+Setup.swift / EnemyNode.swift / NoteNode.swift / PlayerNode.swift / ResultScene.swift / TitleScene.swift / SpawnSystem.swift / project.pbxproj
- 산출물: SPEC.md / SELF_CHECK.md / QA_REPORT.md (재생성)

다음 27 항목 **diff 0줄** 확인:
- HUDNode / BGMPlayer / AudioManager / HapticsManager / ColorTokens / PhysicsCategory / GameState / ContactRouter / ScoreSystem / CameraShakeAction / SelfDismissingNode: 미접촉
- 자가 소멸 노드 9개 (Airplane / AirforceOverlay / BombFlash / Sparkle / HitFlash / ComboPopup / ComboBreak / Countdown / ScorePopup): 미접촉
- StoneGuardNode / CharacterID / CharacterPreferenceRepository / HighScoreRepository / StatisticsRepository / GameStats / DPadNode / ProjectileNode: 미접촉
- GanhoMusic iOS/GameViewController.swift / AppDelegate.swift / SceneDelegate.swift: 미접촉
- GanhoMusic tvOS / GanhoMusic macOS 폴더: 미접촉

(`git diff HEAD --name-only | grep -E "<27패턴>"` → 0 매치)

## 회귀 0 *동작* 자연 차단 검증

`GameConfig.swift` 라인 416~459 dict 값을 *대응 기존 단일 상수*와 직접 대조:

| 항목 | dict[.easy] | 기존 단일 상수 | 일치 |
|---|---|---|---|
| playerSpeedStartByDifficulty | 140 | GameConfig.playerBaseSpeed(L37) = 140 | ✓ |
| enemySpeedStartByDifficulty | 60 | GameConfig.enemyBaseSpeed(L90) = 60 | ✓ |
| enemySpeedEndByDifficulty | 110 | GameConfig.enemyMaxSpeed(L93) = 110 | ✓ |
| noteMaxConcurrentByDifficulty | 5 | GameConfig.noteMaxConcurrent(L62) = 5 | ✓ |
| noteLifetimeByDifficulty | .infinity | applyLifetime 가드 `ttl.isFinite` 미통과 → noop | ✓ |
| projectileMaxConcurrentByDifficulty | 2 | GameConfig.projectileMaxConcurrent(L110) = 2 | ✓ |
| projectileBurstCountByDifficulty | 1 | (기존 1발 코드 = 루프 1회 등가) | ✓ |
| projectileFireIntervalStartByDifficulty | 3.5 | GameConfig.projectileFireInterval(L105) = 3.5 | ✓ |
| projectileFireIntervalEndByDifficulty | 2.0 | GameConfig.projectileFireIntervalEnd(L108) = 2.0 | ✓ |

**결과**: easy 난이도가 *수치적으로 기존과 완전 동일*. 회귀 0 동작 자연 차단 성립.

## 카드 hit test 우선순위 검증

TitleScene.swift:210-238 `touchesBegan(_:with:)` 순서:
1. `for card in difficultyCards { if card.contains(location) { selectDifficulty(card.id); return } }` ← 최우선
2. `for card in characterCards { if card.contains(location) { select(card.id); return } }` ← 두 번째
3. GameScene 전환(isTransitioning 가드 + presentScene) ← 마지막

각 카드 매치 시 *즉시 return*으로 다른 처리 차단됨. 검증 통과.

## GameScene init default 인자 검증

GameScene.swift:124 `class func newGameScene(characterID: CharacterID = .kim, difficulty: Difficulty = .easy) -> GameScene`
— 두 인자 모두 default. macOS GameViewController/tvOS GameViewController 기존 `GameScene.newGameScene()` 호출이 default 인자로 자동 호환 → 미수정에도 컴파일 통과. **빌드 SUCCEEDED로 실제 검증됨**.

## PlayerNode/EnemyNode apply 호출 순서 검증

GameScene+Setup.swift:113-114:
```swift
player.apply(characterID)   // character 먼저
player.apply(difficulty)    // difficulty 나중 (주의사항 1)
```

`apply(_ characterID:)` (PlayerNode.swift:65-68) set: color, speedMultiplier
`apply(_ difficulty:)` (PlayerNode.swift:74-77) set: baseSpeedStart, baseSpeedEnd

**서로 다른 4개 프로퍼티**를 set — 충돌 0건. 호출 순서 무관하나 일관성 위해 character→difficulty 통일. 검증 통과.

EnemyNode는 setupEnemy에서 `enemy.apply(difficulty)` 1줄만 — character 적용 없음, 순서 검증 불필요.

## SpawnSystem burst 루프 안전성 검증

SpawnSystem.swift:151-173 `fireProjectile()`:
```swift
for _ in 0..<projectileBurstCount {
    guard currentProjectileCount() < projectileMaxConcurrent else { return }
    let projectile = ProjectileNode()
    projectile.position = enemy.position
    projectile.physicsBody?.velocity = CGVector(...)
    world.addChild(projectile)
}
```

- **각 발마다 max 가드** (L164) ✓
- 매 발 1발씩 발사 (1발 코드 그대로 루프 안에 둠) ✓
- easy=1 → 루프 1회 → 정확히 기존 1발과 동등 ✓
- max 초과 시 즉시 `return`으로 나머지 루프 차단 (break 아님 — fireProjectile 종료, 동일 효과) ✓

검증 통과.

## NoteNode TTL 가드 검증

NoteNode.swift:40-46:
```swift
func applyLifetime(_ ttl: TimeInterval) {
    guard ttl.isFinite, ttl < GameConfig.gameDuration else { return }
    let wait   = SKAction.wait(forDuration: ttl)
    let fade   = SKAction.fadeOut(withDuration: 0.2)
    let remove = SKAction.removeFromParent()
    run(.sequence([wait, fade, remove]), withKey: "noteLifetime")
}
```

- easy(.infinity)는 `isFinite` 가드 통과 안 함 → noop ✓
- ttl ≥ gameDuration(45초)도 noop (sentinel 안전망) ✓
- withKey 사용으로 중복 호출 시 자동 멱등 ✓

검증 통과.

## dict subscript fallback 검증

모든 신규 dict lookup에 `??` fallback 검색 결과:

| 파일:라인 | 코드 | fallback |
|---|---|---|
| PlayerNode.swift:75 | `playerSpeedStartByDifficulty[difficulty]` | `?? GameConfig.playerBaseSpeed` |
| PlayerNode.swift:76 | `playerSpeedEndByDifficulty[difficulty]` | `?? GameConfig.playerBaseSpeed` |
| EnemyNode.swift:65 | `enemySpeedStartByDifficulty[difficulty]` | `?? GameConfig.enemyBaseSpeed` |
| EnemyNode.swift:66 | `enemySpeedEndByDifficulty[difficulty]` | `?? GameConfig.enemyMaxSpeed` |
| SpawnSystem.swift:44 | `noteMaxConcurrentByDifficulty[difficulty]` | `?? GameConfig.noteMaxConcurrent` |
| SpawnSystem.swift:45 | `noteLifetimeByDifficulty[difficulty]` | `?? .infinity` |
| SpawnSystem.swift:46 | `projectileMaxConcurrentByDifficulty[difficulty]` | `?? GameConfig.projectileMaxConcurrent` |
| SpawnSystem.swift:47 | `projectileBurstCountByDifficulty[difficulty]` | `?? 1` |
| SpawnSystem.swift:48 | `projectileFireIntervalStartByDifficulty[difficulty]` | `?? GameConfig.projectileFireInterval` |
| SpawnSystem.swift:49 | `projectileFireIntervalEndByDifficulty[difficulty]` | `?? GameConfig.projectileFireIntervalEnd` |

신규/변경 파일 전체에 **강제 언래핑(`!`) 0건**. 검증 통과.

## pbxproj 등록 검증

`GanhoMusic.xcodeproj/project.pbxproj` grep 결과:
- **PBXBuildFile** (라인 46-48): Difficulty.swift / DifficultyPreferenceRepository.swift / DifficultyCardNode.swift 3건 등록 ✓
- **PBXFileReference** (라인 88-90): 동일 3건 ✓
- **PBXGroup** (라인 236 Nodes / 270 Repositories / 281 Models): 3 그룹에 1건씩 ✓
- **PBXSourcesBuildPhase iOS target** (`C75D46252FA627C20016BB86 /* Sources */`, 라인 472): 라인 512-514에 3건 등록 ✓
- **PBXSourcesBuildPhase tvOS target** (`C75D46362FA627C20016BB86`, 라인 518): `files = ()` 빈 채로 유지 ✓
- **PBXSourcesBuildPhase macOS target** (`C75D46462FA627C20016BB86`, 라인 525): `files = ()` 빈 채로 유지 ✓

검증 통과.

## 빌드 검증

명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -target "GanhoMusic iOS" -sdk iphonesimulator EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" clean build`

**결과**: `** BUILD SUCCEEDED **`

- BUILD SUCCEEDED: ✓
- 컴파일 에러: 0건
- 컴파일 경고: 0건 (Metadata extraction 무관 외 0)
- 아키텍처: arm64 + x86_64 universal binary 생성 완료
- CodeSign / Validate / Touch 모두 성공

검증 통과.

## 정적 검사 결과

| 항목 | 결과 | 확인 방법 |
|---|---|---|
| 강제 언래핑(`!`) | 0건 (신규/변경 파일) | grep `[a-zA-Z_)\]]!\.` / `try!` / `as!` 0 매치 (주석/문자열/!= 제외) |
| 매직 넘버 (신규 파일) | 3건 (P2) | DifficultyCardNode `y: 8`, `y: -14` (라벨 내부 좌표, SPEC 의사 코드 그대로), NoteNode `withDuration: 0.2` (fade duration) |
| 매직 넘버 (변경 파일) | 0건 | GameConfig 상수 참조만 |
| Timer | 0건 | grep `Timer\.` 0 매치 |
| DispatchQueue | 0건 (신규/변경) | BGMPlayer.swift:143은 회귀 0 영역(미접촉) |
| 함수 단일 책임 | 통과 | apply / setupDifficultyCards / layoutDifficultyCards / selectDifficulty 각각 한 역할 |
| MARK 섹션 구분 | 통과 | 신규 3 파일 모두 MARK 사용 |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 3건 |

---

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

없음.

## P2 — 권장 사항

### 1. DifficultyCardNode 라벨 좌표 — 인라인 매직 넘버

- **파일**: `GanhoMusic Shared/Nodes/DifficultyCardNode.swift:70, 76`
- **현재 코드**:
  ```swift
  nameLabel.position = CGPoint(x: 0, y: 8)
  subtitleLabel.position = CGPoint(x: 0, y: -14)
  ```
- **참고**: SELF_CHECK가 인지하고 있는 의도적 선택 (SPEC §"DifficultyCardNode 구조" 의사 코드 그대로). 카드 내부 라벨 좌표라 외부 영향은 없음.
- **권장**: 향후 BaseCardNode 추출 시 `GameConfig.difficultyCardNameLabelY` / `...SubtitleLabelY` 상수로 흡수. 본 sprint 범위 외.

### 2. NoteNode fade-out duration 매직 넘버

- **파일**: `GanhoMusic Shared/Nodes/NoteNode.swift:43`
- **현재 코드**: `let fade = SKAction.fadeOut(withDuration: 0.2)`
- **이유**: SPEC §"기능 6"은 wait+fade+remove 시퀀스만 명시, fade duration 상수는 SPEC 명시 없음. 인라인 리터럴.
- **수정 제안**: `GameConfig` 신규 상수
  ```swift
  /// NoteNode TTL 만료 시 fade-out 길이 (초). normal/hard 음표가 사라지는 잔향.
  static let noteFadeOutDuration: TimeInterval = 0.2
  ```
  로 흡수 후 NoteNode에서 참조. 1줄 변경, 회귀 0.

### 3. DifficultyCardNode "cardScale" 액션 키 인라인 문자열

- **파일**: `GanhoMusic Shared/Nodes/DifficultyCardNode.swift:55, 58`
- **현재 코드**:
  ```swift
  removeAction(forKey: "cardScale")
  run(..., withKey: "cardScale")
  ```
- **참고**: CharacterCardNode와 완전 동형 — 두 카드 모두 동일 문자열 키 사용으로 시각적 일관성 유지. CharacterCardNode가 이미 같은 패턴이므로 본 sprint에서 추출하지 않음은 의도적.
- **권장**: 향후 BaseCardNode 추출 sprint에서 `static let cardScaleActionKey = "cardScale"` 공통 상수로 통합. 본 sprint 범위 외.

---

## 통과 항목

- GDD §5 표 27 셀 + α 1:1 정확 매핑 (단 한 셀도 불일치 없음)
- 회귀 0 영역 27 항목 완전 불변 (`git diff` 0줄 확인)
- 회귀 0 동작 자연 차단 (easy 난이도 수치 = 기존 단일 상수와 정확 일치)
- 카드 hit test 우선순위 (난이도 → 캐릭터 → 전환) + 즉시 return
- GameScene init 두 인자 모두 default → macOS/tvOS 호환
- PlayerNode/EnemyNode apply 호출 순서 (서로 다른 프로퍼티 set, 충돌 0)
- SpawnSystem burst 루프 각 발 max 가드
- NoteNode TTL `ttl.isFinite, ttl < gameDuration` 가드 → easy noop 보장
- dict subscript 10건 모두 `??` fallback (강제 언래핑 0건)
- pbxproj iOS target Sources 3건 등록, tvOS/macOS Sources 빈 채 유지
- 빌드 SUCCEEDED, 경고 0건
- Timer / DispatchQueue 신규 코드 0건
- MARK 섹션 구분 일관

---

## 채점

**항목별 점수**:

- **Swift 패턴 일관성: 9.5/10**
  - 강제 언래핑 0건, MARK/guard let/?? fallback 모두 일관.
  - 단 P2 매직 넘버 3건 (라벨 좌표 2건 + fade duration 1건). 정책상 인지된 인라인이라 -0.5만 차감.

- **게임 로직 완성도: 10/10**
  - SpriteKit 패턴 100% 준수 (SKAction.sequence + withKey, dt 기반 이동, didMove 초기화, PhysicsCategory 비트마스크).
  - 회귀 0 자연 차단 (easy 수치 = 기존 상수)로 기존 9 sprint 동작 완전 보존.
  - GDD §5 27 셀 정확 매핑.
  - GameScene init default 인자 + apply(_:) 분리로 책임 경계 명확.

- **성능 & 안정성: 10/10**
  - 강제 언래핑 0건, weak self 캡처(closures), 빌드 클린 (경고 0).
  - dict fallback 10건 모두 graceful — nil로 인한 크래시 경로 0.
  - NoteNode TTL `isFinite` 가드로 `.infinity` 안전 처리(SpriteKit wait(forDuration: .infinity) 위험 회피).
  - SpawnSystem burst 매 발 max 가드로 동시 max 초과 방지.

- **기능 완성도: 10/10**
  - SPEC 9개 기능 모두 구현, SELF_CHECK 라인 매핑과 실제 코드 1:1 일치.
  - SPEC §"금지" 범위 외 미구현 항목(이교수/hard맵/석조무사 분기/목표점수/컷씬/졸업장) 모두 미접촉 (범위 위반 0).
  - ResultScene 난이도 라벨 추가, TitleScene 카드 3장 + 영구 저장/복원 완비.

**가중 점수** = 9.5×0.35 + 10×0.30 + 10×0.20 + 10×0.15 = **3.325 + 3.000 + 2.000 + 1.500 = 9.825 / 10.0**

(반올림: **9.8 / 10.0**)

## 최종 판정: **합격**

P0 0건 / P1 0건 / P2 3건 (모두 매직 넘버 — 회귀 0 영역). 가중 점수 9.8 ≥ 7.0 합격선. 빌드 SUCCEEDED, GDD §5 27 셀 정확 매핑, 회귀 0 영역 27 항목 완전 불변, easy 동작 수치 정확 보존.

**구체적 개선 지시** (선택, 차기 sprint 권장):
1. `NoteNode.swift:43`의 `withDuration: 0.2`를 `GameConfig.noteFadeOutDuration: TimeInterval = 0.2`로 흡수 (1줄, 회귀 0).
2. 차기 sprint에서 BaseCardNode 추출 시 DifficultyCardNode/CharacterCardNode 공통 라벨 좌표 상수(`cardNameLabelOffsetY` 등)와 `cardScaleActionKey` 상수를 GameConfig로 통합.
3. PlayerNode `baseSpeedEnd` 보간 미적용 (주의사항 7) — 다음 보강 sprint에서 진행률 보간식 도입 시 사용.
