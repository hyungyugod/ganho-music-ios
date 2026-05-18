# QA 검수 보고서 — Phase 9-8 AIRFORCE 타이밍 정합화 + hard 가드

## SPEC 기능 검증 (6건)

| # | 기능 | 상태 | 위치 |
|---|---|---|---|
| 1 | `airforceOverlayDisplayDuration` 1.5 → 2.1 + 주석 갱신 | PASS | `Config/GameConfig.swift:210-212` |
| 2 | `bombFlashDelay` 2.1 → 3.4 + 주석 갱신 | PASS | `Config/GameConfig.swift:220-223` |
| 3 | 신상수 `airplaneDelayAfterOverlay: TimeInterval = 2.4` 추가 | PASS | `Config/GameConfig.swift:216-219` |
| 4 | `triggerAirforceEasterEgg()` 첫 줄 hard 가드 | PASS | `GameScene.swift:656-658` |
| 4b | 비행기 부착 블록 SKAction.sequence 지연 패턴 + [weak self] + guard let | PASS | `GameScene.swift:670-678` |
| 5 | `setupStoneGuard()` 첫 줄 hard 가드 | PASS | `GameScene+Setup.swift:341-343` |
| 6 | 두 파일 헤더 "Phase 9-8" 주석 | PASS | `GameScene.swift:41`, `GameScene+Setup.swift:9` |

## 회귀 방지 (git diff)

`git diff --name-only` 결과 정확히 3개 파일.

| 회귀 방지 대상 | 결과 |
|---|---|
| AirplaneNode/AirforceOverlayNode/BombFlashNode | 0줄 PASS |
| EnemyNode/StoneGuardNode/ProjectileNode | 0줄 PASS |
| SpawnSystem/ContactRouter | 0줄 PASS |
| PixelSprite/PixelPalette/Difficulty/PhysicsCategory | 0줄 PASS |
| PlayerSkill/SkillSystem/SkillButton/HUDSkillSlot | 0줄 PASS |
| ToiletNode/ToastLabelNode/ProfessorNode/StethoscopeNode | 0줄 PASS |
| pbxproj | 0줄 PASS |
| 신규 Swift 파일 | 0개 PASS |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 에러: 0, 신규 경고: 0

## 이슈 카운트

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

### Swift 패턴
- 강제 언래핑 신규 0건
- Timer/DispatchQueue 신규 0건
- 매직 넘버 신규 0건 (`size.height / 2`는 HEAD 기존, 본 sprint 도입 아님)
- `[weak self]` + `guard let self = self else { return }` 적용
- GameConfig 상수 경유 — airplaneDelayAfterOverlay/airplaneTopOffset

### SpriteKit 패턴
- SKAction.sequence([wait, run]) 패턴 Timer 대체 — spritekit-rules §4 일치
- cameraNode 자식 부착 패턴 보존
- 자가 소멸 패턴 보존 (AirplaneNode 내부 처리)

### 게임 로직 검증식
- 오버레이 총 수명 = 2.1 + 0.3 = **2.4초** ✓
- 비행기 등장 시점 = airplaneDelayAfterOverlay(**2.4**) ✓
- 비행기 중앙 도달 = 2.4 + 2.0/2 = **3.4** = bombFlashDelay ✓
- 폭탄 섬광 = 0.07 + 0.35 = **0.42초** ✓
- 도주 종료 = 5.0 → fireImmediately() ✓

### Sprint 범위 계약
- 허용 6건 모두 구현, 금지 8건 모두 회피
- AirplaneNode.crossScreen 시그니처 불변
- EnemyNode.startFleeing 시그니처 불변
- SpawnSystem.fireImmediately 시그니처 불변

## 채점

| 항목 | 가중치 | 점수 |
|---|---|---|
| Swift 패턴 일관성 | 35% | 10/10 |
| 게임 로직 완성도 | 30% | 10/10 |
| 성능 & 안정성 | 20% | 10/10 |
| 기능 완성도 | 15% | 10/10 |

**가중 점수**: 10.0 × 0.35 + 10.0 × 0.30 + 10.0 × 0.20 + 10.0 × 0.15 = **10.0 / 10**

## 최종 판정: **합격**

본 sprint는 *순수 보정 sprint*의 모범 사례. SPEC §허용 6건 정밀 적용, §금지 8건 0건 위반. git diff 회귀 검증 13+개 대상 + pbxproj + 신규 파일 0개. BUILD SUCCEEDED. Spring `@PreAuthorize` 답습한 hard 2중 가드는 *방어 설계*의 좋은 예시.

## 시뮬레이터 검증 시나리오

| 단계 | 액션 | 기대 결과 |
|---|---|---|
| (a) | easy 게임 진입 | stoneGuard 좌하단 패트롤 |
| (b) | player → stoneGuard 충돌 | "나와라 박병장!" 오버레이 2.4초 |
| (c) | t=0~2.4 | 수간호사 도주 시작 (5초) |
| (d) | t=2.4 | 오버레이 소멸 + 비행기 좌측 등장 |
| (e) | t=3.4 | 비행기 중앙 도달 시 화면 누런 섬광(420ms) |
| (f) | t=4.4 | 비행기 우측 바깥 도달 |
| (g) | t=5.0 | 수간호사 정상 추적 복귀 + F 1발 재발사 |
| (h) | stoneGuard 재접촉 | airforceTriggered=true → noop |
| (i) | normal 게임 | (a)~(h) 동일 |
| (j) | hard 게임 | stoneGuard 미등장, 이교수만 활동 |
| (k) | 게임 재시작 → easy | airforceTriggered 리셋 → 다시 1회 발화 |
