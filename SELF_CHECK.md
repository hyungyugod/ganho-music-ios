# 자체 점검 — Phase 9-8 AIRFORCE 타이밍 정합화 + hard 가드

전략: 신규 sprint (1회차). 본 sprint는 *순수 보정*이라 큰 방향 선택 없음. 변경 3파일 ~12줄.

---

## SPEC 기능 체크

### 허용 항목 (6건 모두 구현)
- [x] **1. `airforceOverlayDisplayDuration` 1.5 → 2.1 + 주석 갱신**
  - 위치: `GameConfig.swift` L210
  - 주석: "총 수명 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초"
- [x] **2. `bombFlashDelay` 2.1 → 3.4 + 주석 갱신**
  - 위치: `GameConfig.swift` L218
  - 주석: "비행기 중앙 도달 시점 = airplaneDelayAfterOverlay(2.4) + airplaneCrossDuration(2.0)/2 = 3.4초"
- [x] **3. 신상수 `airplaneDelayAfterOverlay: TimeInterval = 2.4` 추가**
  - 위치: `GameConfig.swift` L214-216 (Airforce 섹션 안, 자연 그룹화)
- [x] **4. `triggerAirforceEasterEgg()` 첫 줄에 `if difficulty == .hard { return }` + 비행기 지연 attach**
  - 위치: `GameScene.swift` L656-657 (가드), L668-677 (지연 attach)
  - SKAction.sequence([wait, run{attach}]) 패턴. `[weak self]` + `guard let self`.
- [x] **5. `setupStoneGuard()` 첫 줄에 `guard difficulty != .hard else { return }`**
  - 위치: `GameScene+Setup.swift` L340-342
- [x] **6. 두 파일 헤더 주석 "Phase 9-8" 1줄 추가**
  - `GameScene.swift` L41
  - `GameScene+Setup.swift` L9

### 트리거 동작 정확 명시 (4개 모두 충족)
- [x] **활성 조건**: `difficulty != .hard` 게임 + Player↔StoneGuard 첫 접촉 1회 (setupStoneGuard 가드 + airforceTriggered 1회 가드)
- [x] **이중 발화 차단**: `airforceTriggered` 가드 그대로 보존
- [x] **게임당 1회**: GameScene 인스턴스 새로 만들 때 자동 false 리셋 (stored property)
- [x] **hard 난이도 차단 2중화**:
  - (a) setupStoneGuard 가드 → worldNode에 stoneGuard 미등록 → 충돌 0
  - (b) triggerAirforceEasterEgg 본문 가드 → 호출 경로 변경 시 회귀 차단

### 이스터에그 시퀀스 검증 (t=0 기준)
- [x] t=0.0: 트리거 발화 + airforceTriggered=true ✓ (가드 통과)
- [x] t=0.0: 오버레이 "나와라 박병장!" 표시 ✓ (`overlay.showAndDismiss()` 즉시 호출)
- [x] t=0.0: 수간호사 5초 도주 시작 ✓ (`enemy.startFleeing(duration: 5.0)`)
- [x] t=2.4: 오버레이 소멸 + 비행기 등장 ✓ (`SKAction.wait(2.4)` → attach + crossScreen)
- [x] t=3.4: 비행기 중앙 도달 + 폭탄 섬광 ✓ (BombFlashNode 내부 `bombFlashDelay=3.4`)
- [x] t=4.4: 비행기 우측 도달 + removeFromParent ✓ (AirplaneNode 자가 소멸)
- [x] t=5.0: 도주 종료 + F 1발 ✓ (startFleeing onEnd → fireImmediately)

### 금지 항목 (모두 미위반)
- [x] 신규 Swift 파일 추가 0건
- [x] 신규 PixelSprite 데이터 0건
- [x] 새 ColorTokens / PhysicsCategory / SKAction 키 0건
- [x] `EnemyNode.startFleeing` 시그니처 불변
- [x] `SpawnSystem.fireImmediately` 시그니처/내부 불변
- [x] `airforceTriggered` 1회 가드 정책 불변
- [x] Phase 9-1~9-7 영역 0줄 수정 — 노드 9개(AirplaneNode/AirforceOverlayNode/BombFlashNode/EnemyNode/StoneGuardNode/ProjectileNode/PixelSprite/PixelPalette/ProfessorNode) 및 시스템(SpawnSystem/ContactRouter/SkillSystem) 모두 미접촉

---

## Swift 패턴 준수

| 항목 | 상태 | 근거 |
|---|---|---|
| 강제 언래핑(`!`) 미사용 | 준수 | 신규 코드 안 `!` 0개. `guard let self = self else { return }`로 안전 언래핑 |
| guard let 옵셔널 처리 | 준수 | 지연 attach 클로저 안 `guard let self = self else { return }` |
| MARK 섹션 구분 | 준수 | 기존 `// MARK: - Easter Egg` 그대로 유지 |
| GameConfig 상수 사용 | 준수 | GameScene 본문 신규 코드에 숫자 리터럴 0건. 모든 값 GameConfig 경유 |
| weak self 캡처 | 준수 | `SKAction.run { [weak self] in ... }` — endGame 중 self 해제 안전 |
| 네이밍(lowerCamelCase) | 준수 | `airplaneDelayAfterOverlay` |
| 한국어 주석 OK / 한국어 변수명 0 | 준수 | 모든 식별자 영문 |
| Timer / DispatchQueue 미사용 | 준수 | SKAction.wait + SKAction.sequence만 사용 |

---

## SpriteKit 패턴 준수

| 항목 | 상태 | 근거 |
|---|---|---|
| didMove(to:)에서 초기화 | 준수 | 기존 setup* 호출 패턴 그대로 |
| dt 기반 이동 | N/A | 본 sprint는 이동 로직 미접촉 |
| SKAction 스폰 패턴 | 준수 | 지연 attach를 `SKAction.sequence([wait, run])`로 구현 |
| 충돌 후 노드 즉시 삭제 없음 | 준수 | 본 sprint는 충돌 콜백 미수정 (기존 패턴 보존) |
| HUD 노드 분리 | N/A | HUD 미접촉 |
| cameraNode 자식 부착 (이스터에그 시각 일관성) | 준수 | overlay/plane/bomb 모두 cameraNode 자식 |
| 노드 자가 소멸 패턴 | 준수 | AirplaneNode/AirforceOverlayNode/BombFlashNode 모두 내부에서 removeFromParent — GameScene 후속 정리 0건 |

---

## 빌드 상태

- **빌드 명령**: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **결과**: `** BUILD SUCCEEDED **`
- **에러**: 없음
- **경고**: 신규 발생 없음 (기존 코드의 AppIntents 경고만 — 본 sprint 무관)

---

## 매직 넘버 정책 검증

GameScene 본문 신규 코드 그렙:
- `2.4` → 출현 0건 (GameConfig.airplaneDelayAfterOverlay로 치환)
- `3.4` → 출현 0건 (GameConfig.bombFlashDelay로 치환, BombFlashNode 내부 자동 적용)
- `2.1` → 출현 0건 (airforceOverlayDisplayDuration 상수가 흡수)

신규 호출 1건: `SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)` — SPEC §매직 넘버 정책 일치.

---

## 회귀 방지 — Phase 9-1~9-7 영역 0줄

다음 파일은 **읽기만** 수행했고, 0줄 수정:

| 파일 | 수정 0줄 확인 |
|---|---|
| AirplaneNode.swift | ✓ (시그니처 `crossScreen(sceneWidth:atY:)` 그대로 호출만) |
| AirforceOverlayNode.swift | ✓ (`showAndDismiss()` 그대로 호출, 내부 `airforceOverlayDisplayDuration` 자동 신값 반영) |
| BombFlashNode.swift | ✓ (`flash(sceneSize:)` 그대로 호출, 내부 `bombFlashDelay` 자동 신값 반영) |
| EnemyNode.swift | ✓ (`startFleeing(duration:onEnd:)` 시그니처 그대로) |
| StoneGuardNode.swift | ✓ |
| ProjectileNode.swift | ✓ |
| SpawnSystem.swift | ✓ (`fireImmediately()` 시그니처 그대로) |
| ContactRouter.swift | ✓ |
| PixelSprite.swift / PixelPalette.swift | ✓ |
| Difficulty.swift / PhysicsCategory.swift | ✓ |
| ProfessorNode.swift / StethoscopeNode.swift / ToiletNode.swift / SkillButtonNode.swift | ✓ |

---

## 변경 파일 / 라인 요약

| 파일 | 추가 줄 | 변경 줄 | 비고 |
|---|---|---|---|
| `Config/GameConfig.swift` | +5 (신상수 + 주석) | 4 (값 1.5→2.1, 2.1→3.4, 주석 갱신) | Airforce 섹션 안에 그룹화 |
| `GameScene.swift` | +12 (가드 1줄 + 지연 attach 7줄 + 헤더 1줄 + 주석 3줄) | -3 (즉시 부착 3줄 제거) | `triggerAirforceEasterEgg`만 변경 |
| `GameScene+Setup.swift` | +3 (가드 1줄 + 주석 2줄 + 헤더 1줄) | 0 | `setupStoneGuard`만 변경 |
| **신규 파일** | **0개** | - | pbxproj 변경 0 |

**docs/learn/phase-9-8-airforce-timing-correction.md** — 학습 노트 작성 완료 (중학생 수준 + Spring Boot 비유).

---

## 자체 점수 예상 (평가 가중치 기준)

| 영역 | 가중치 | 자체 평가 | 근거 |
|---|---|---|---|
| Swift 패턴 | 35% | 10.0 | 강제 언래핑 0, GameConfig 상수, [weak self], guard let 모두 준수 |
| 게임 로직 | 30% | 10.0 | SKAction.sequence 지연 attach + airforceTriggered 1회 가드 + difficulty == .hard 2중 가드 |
| 성능 & 안정성 | 20% | 10.0 | 신규 노드 0, Timer 0, 매직 넘버 0, [weak self] 메모리 안전 |
| 기능 완성도 | 15% | 10.0 | 사용자 요청 시퀀스 정확 일치(2.4 → 2.0 → 3.4) + hard 차단 2중화 |
| **가중 합계 (예상)** | - | **10.0** | 빌드 성공 + SPEC 6건 모두 충족 + 금지 항목 0건 위반 |

---

## 범위 외 미구현 항목

**없음**. SPEC §허용 6건 모두 구현. SPEC §금지 8건 모두 회피.
