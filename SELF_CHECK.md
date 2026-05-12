# 자체 점검 — Phase 5-R · PlayerNode.apply(_:) 단일 진입점 리팩터

전략: Case A (초기 구현 — SPEC 정밀 적용)

## 1. 변경 파일 목록 (정확히 2개)

| # | 파일 | 변경 요약 |
|---|---|---|
| 1 | `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift` | (a) 헤더 1줄 추가 `Phase 5-R · CharacterID 단일 진입점 메서드 apply(_:) 추출 (순수 리팩터)`. (b) `// MARK: - Apply` 섹션 신설(MARK: - Update 바로 위). (c) `func apply(_ characterID: CharacterID)` 메서드 추가, 본문 정확히 2줄 (`color = characterID.color` / `speedMultiplier = characterID.playerSpeedMultiplier`). |
| 2 | `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift` | `setupPlayer()` 내부의 `player.color = characterID.color`와 `player.speedMultiplier = characterID.playerSpeedMultiplier` 두 줄을 `player.apply(characterID)` 한 줄로 *교체*. 위치 동일(`player.position` 다음, `worldNode.addChild(player)` 이전). |

### diff 요약 (5-R 변경분만)

**PlayerNode.swift**:
- 헤더 라인 추가: `//  Phase 5-R · CharacterID 단일 진입점 메서드 apply(_:) 추출 (순수 리팩터)`
- 새 섹션:
  ```swift
  // MARK: - Apply
  /// Phase 5-R — 캐릭터 정체성 단일 진입점.
  /// 외부(GameScene+Setup)는 setter를 직접 알지 않고 CharacterID 하나만 넘긴다.
  /// 기능 변화 0 — 5-2(color) + 5-3(speedMultiplier) 두 setter를 *내부에서 그대로* 호출.
  func apply(_ characterID: CharacterID) {
      color = characterID.color
      speedMultiplier = characterID.playerSpeedMultiplier
  }
  ```
- Properties / Init / required init? / Update 메서드 / physicsBody 설정 — **0줄 변경**.

**GameScene+Setup.swift** (`setupPlayer()` 함수만):
- 삭제 2줄:
  ```swift
  player.color = characterID.color   // Phase 5-2 …
  player.speedMultiplier = characterID.playerSpeedMultiplier   // Phase 5-3 …
  ```
- 추가 1줄:
  ```swift
  player.apply(characterID)   // Phase 5-R — 5-2(color) + 5-3(speedMultiplier) 단일 진입점으로 통합
  ```
- `player.position` 계산식 / `worldNode.addChild(player)` 위치 — **0줄 변경**.
- `setupPlayer()` 외 다른 메서드(setupBackground/setupWorld/addOuterWalls/addCentralPillar/setupCamera/setupDPad/setupHUD/setupEnemy/setupStoneGuard) — **0줄 변경**.

## 2. SPEC In Scope 3항목 충족 여부

| # | SPEC 요구사항 | 충족 |
|---|---|---|
| 1 | `apply(_ characterID: CharacterID)` 메서드 신설 (시그니처 정확, 본문 정확히 2줄, 순서 `color` → `speedMultiplier`, guard/if/print/SKAction/추가 setter 0건) | ✅ |
| 2 | `PlayerNode.swift` 헤더에 `Phase 5-R …` 한 줄 추가 (기존 1-3 / 2-2 / 5-3 라인 그대로 유지) | ✅ |
| 3 | `setupPlayer()` 두 줄을 `player.apply(characterID)` 한 줄로 교체 (위치: `player.position` 다음, `worldNode.addChild(player)` 이전) | ✅ |

## 3. SPEC Out of Scope 위반 0건 확인

| Out of Scope 항목 | 변경 여부 |
|---|---|
| `CharacterID.swift` | **0줄 변경** (color/playerSpeedMultiplier/displayName 그대로) |
| `GameScene.swift` 본문 (init / factory / didMove / update / configureContactRouter / triggerAirforceEasterEgg / endGame) | **0줄 변경** |
| `TitleScene.swift` | **0줄 변경** |
| `HUDNode.swift` | **0줄 변경** |
| `GameConfig.swift` | **0줄 변경** |
| `ColorTokens.swift` | **0줄 변경** |
| `EnemyNode` / `StoneGuardNode` / 다른 Nodes | **0줄 변경** |
| `SpawnSystem` / `ContactRouter` / `ScoreSystem` / Repositories | **0줄 변경** |
| `PlayerNode` 내 다른 부분 (Properties / Init / required init? / Update / physicsBody) | **0줄 변경** |
| pbxproj | **0줄 변경** (파일 추가/삭제 없음) |
| 테스트 코드, macOS/tvOS 타겟 | **0줄 변경** |
| `setupPlayer()` 외 다른 setup 메서드 | **0줄 변경** |

→ Out of Scope 위반: **0건**

## 4. 기능 변화 0 검증 — 5 캐릭터 정적 추적

`setupPlayer()` 호출 흐름이 5-3과 동일한 결과를 산출함을 정적으로 증명.

### 호출 흐름 비교

**Before (5-3)**:
```
setupPlayer() 진입
  → player.position = (mapW/4, mapH/2)
  → player.color = characterID.color                    // Direct setter A
  → player.speedMultiplier = characterID.playerSpeedMultiplier   // Direct setter B
  → worldNode.addChild(player)
```

**After (5-R)**:
```
setupPlayer() 진입
  → player.position = (mapW/4, mapH/2)
  → player.apply(characterID)                           // facade 호출
       └─ (내부) self.color = characterID.color         // setter A (5-3과 동일 라인)
       └─ (내부) self.speedMultiplier = characterID.playerSpeedMultiplier   // setter B (5-3과 동일 라인)
  → worldNode.addChild(player)
```

**관찰**:
- 두 setter의 호출 순서 동일 (color → speedMultiplier).
- 두 setter의 우변 식 동일 (`characterID.color`, `characterID.playerSpeedMultiplier`).
- 두 setter 모두 `worldNode.addChild(player)` *이전*에 실행 — 5-3과 동일.
- `CharacterID.swift`는 0줄 변경 → `.color` / `.playerSpeedMultiplier` 반환값도 5-3과 동일.

### 5 캐릭터 시나리오 정적 결과

| # | 캐릭터 | `characterID.color` 반환 | `characterID.playerSpeedMultiplier` 반환 | 적용 후 `player.color` | 적용 후 `player.speedMultiplier` |
|---|---|---|---|---|---|
| (a) | `.kim` | `.ganhoPaper` | `1.00` | `.ganhoPaper` | `1.00` |
| (b) | `.jung` | `.ganhoMint` | `1.10` | `.ganhoMint` | `1.10` |
| (c) | `.geon` | `.ganhoPinkNote` | `0.90` | `.ganhoPinkNote` | `0.90` |
| (d) | `.im` | `.ganhoYellowF` | `0.95` | `.ganhoYellowF` | `0.95` |
| (e) | `.lee` | `.ganhoBloodAccent` | `1.05` | `.ganhoBloodAccent` | `1.05` |

→ 모든 5 캐릭터에서 5-3 종결 시점과 **비트 단위 동일 결과**.

### 추가 검증 — 호출 타이밍

- `apply(_:)` 본문은 함수 호출 시 동기 실행 (SKAction/dispatch_async 없음) → 5-3의 직접 setter와 실행 시점 동일.
- `apply(_:)` 본문에 side effect 0 (guard/if/로그/디버그/추가 setter 없음).
- `update(deltaTime:)`의 `playerBaseSpeed * speedMultiplier` 곱셈 식은 5-3 그대로 → 첫 입력부터 정상 속도.

→ 기능 변화: **0**

## 5. 빌드 결과

```bash
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

- ✅ **BUILD SUCCEEDED**
- ✅ 경고/에러 (AppIntents 메타 추출 제외) — **0줄**
- ✅ 컴파일 결과물: `GanhoMusic.app` 정상 생성, codesign 통과

```bash
xcodebuild ... 2>&1 | grep -E "warning:|error:" | grep -v "AppIntents"
# (출력 없음)
```

## 6. 학습 노트

생성 완료: `docs/learn/phase-5-R-player-apply.md`

수록 4 포인트:
1. **Tell-Don't-Ask** — 식당 김치찌개 비유, 직접 지시 vs 위임
2. **Facade 메서드** — Spring `userService.applyProfile(profile)` 비유
3. **OCP (Open/Closed)** — 5-5에서 setter 추가 시 호출 측 불변 보장
4. **정보 은닉** — Controller가 Entity 내부 컬럼을 모르고 `entity.update(dto)` 호출하는 패턴

추가 수록:
- Phase 4-R(SelfDismissingNode 프로토콜)과의 DNA 비교 — 둘 다 "동작 0 변화, 구조 정돈".
- Swift 외부 레이블 `_` 문법 해설 (`func apply(_ characterID:)` → `player.apply(characterID)`).
- 중학생 수준 일상 비유 + Spring 사례 곁들임 (사용자 멘탈 모델 준수).

## Swift 패턴 준수

- 강제 언래핑 미사용: ✅ (옵셔널 없음)
- guard let 옵셔널 처리: ✅ (해당 없음 — 비옵셔널 인자)
- MARK 섹션 구분: ✅ (`// MARK: - Apply` 신설, Init → Apply → Update 의미 흐름)
- GameConfig 상수 사용: ✅ (해당 없음 — 매직 넘버 0건, 신규 상수 추가 없음)
- weak self 캡처: ✅ (해당 없음 — 클로저 없음)
- 함수 단일 책임: ✅ (`apply(_:)`는 캐릭터 정체성 적용만 담당)
- 외부 레이블 `_`: ✅ (Swift 관용 표기, `player.apply(characterID)`)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화 흐름 보존: ✅ (`setupPlayer()` 호출 시점 5-3 그대로)
- dt 기반 이동: ✅ (`update(deltaTime:)` 본문 0줄 변경)
- SKAction 스폰 패턴: ✅ (해당 없음 — 본 sprint는 setup 시점, 스폰 미접촉)
- 충돌 후 노드 즉시 삭제 없음: ✅ (해당 없음 — 충돌 로직 미접촉)
- HUD 노드 분리: ✅ (HUDNode 0줄 변경)
- 물리 바디 설정: ✅ (Init 안의 physicsBody 설정 0줄 변경 → category/collision/contact mask 동일)

## 범위 외 미구현 항목

**없음**. SPEC In Scope 3항목 전부 구현, Out of Scope 위반 0건.
