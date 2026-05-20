# Sprint 7 Phase F · QA Report

## 최종 점수 (가중 평균)

| 카테고리 | 점수 | 가중치 | 기여 |
|---|---|---|---|
| 게임 로직 회귀 0 | 10.0/10 | 40% | 4.00 |
| Swift 패턴 | 7.5/10 | 20% | 1.50 |
| 비주얼 일관성 | 9.0/10 | 25% | 2.25 |
| 가독성 & UX | 9.0/10 | 15% | 1.35 |
| **합계** | | | **9.10 / 10** |

## 판정: ✅ 합격

통과선(7.5) 초과. 4개 카테고리 모두 개별 통과선(9.0/7.0/7.0/7.0) 충족. P0 0건, P1 1건(매직 넘버 8개), P2 1건.

---

## 카테고리별 상세

### 게임 로직 회귀 0 — 10.0/10

- 보호 영역 git diff 0줄 ✅:
  - GameScene / GameScene+Setup / PhysicsCategory
  - Models / Systems / Repositories / Scenes / Managers
  - PlayerNode / NoteNode / ProjectileNode / StethoscopeNode
  - Phase A·B·C·D·E 결과물
- 3 빌런 AI/이동/충돌 시그니처 9개 byte-identical:
  - EnemyNode: update/startFleeing/apply
  - ProfessorNode: startPatrol/startThrowingStethoscopes/scheduleNextThrow/throwStethoscope/stopThrowing
  - StoneGuardNode: startPatrol
- physicsBody.size 인자 byte-identical (3종)
- categoryBitMask/collisionBitMask/contactTestBitMask 0줄
- 속도·waypoint 상수 (baseSpeedStart/End, professorSpeed, stoneGuardSpeed, waypoints) 0줄
- SergeantParkNode physicsBody/update/SKAction 실제 코드 0건 (헤더 코멘트만 grep 매치)
- StoneGuard super.init 시그니처 byte-identical, color 값만 .ganhoPaper → .ganhoStoneGuardLight 교체

### Swift 패턴 — 7.5/10

장점:
- MARK 섹션 구분 일관 (`Sprint 7 Phase F`)
- 모든 사이즈/오프셋 GameConfig V3 참조
- 강제 언래핑 0, Timer 0, switch default 0, `as!` 0
- weak self 위반 0 (정적 부착)
- 함수 단일 책임 (attach 메서드 분해)

감점 -2.5: **P1 매직 넘버 8건 잔존** — 시각 디테일(stroke/cornerRadius/비율) 인라인 리터럴
- EnemyNode: cornerRadius 0.6, lineWidth 0.5, * 0.7, height 1.6
- StoneGuardNode: * 0.7, * 0.5, cornerRadius 1.0, lineWidth 0.8, eyeSize (2, 0.8)
- SergeantParkNode: cornerRadius 1.5 (2회), lineWidth 0.6/0.4/0.5/0.4, cornerRadius 0.6
- ProfessorNode: lineWidth 0.4

SPEC §기능4 본문 코드 자체가 인라인 값 예시로 제공한 부분이라 묵시적 허용 여지 있음 — 그래서 P0 아닌 P1. Phase G에서 묶어 정리 권장.

### 비주얼 일관성 — 9.0/10

- mockup `villains-and-player-directions-v1.html` 4 패널 가로 정렬 + SVG 96×120 + 색 chip 3 + 시각 요소 라벨
- 박병장 ✨NEW 표시 + Phase G 후반부 메모
- 색 토큰 6개 hex byte-identical (SPRINT_7_REQUEST §10)
- mockup ↔ Swift 매칭:
  - 수간호사: 차트+클립 → attachChart + attachClip ✅
  - 이교수: 청진기 → attachStethoscopeDisc + Tube ✅
  - 석조무사: 회색 갑옷 + 일자눈 → attachArmor + attachEyes ✅
  - 박병장: 청록 군복 + 캡 + 선글라스 + 골드 chevron → 6 attach ✅
- zPosition 누적 순서 일관 (-0.1 → 0 → 0.1 → 0.2 → 0.3 → 0.4)
- 4명 정체성 색 충돌 0 (navyMuted/coral/회색/청록)

감점 -1.0: SKShapeNode.glowWidth 한계 + 픽셀 텍스처와 자식 SKShape 겹침 미세 불완전.

### 가독성 & UX — 9.0/10

- 모든 attach 메서드 docstring + Spring 비유 톤
- OQ-1/2/3 해결 근거 코멘트 명시
- "physicsBody·AI·이동·texture 0줄 영향" 회귀 0 계약 코멘트 명시
- mockup ✨NEW 박병장 + 색 키 chip
- 메서드명 자가 설명적 (attachShadow/Body/Head/Cap/Sunglasses/Rank)

감점 -1.0: 일부 attach docstring 길어 간결성 떨어짐.

---

## 회귀 검증 grep

| 검증 | 기대 | 실제 |
|---|---|---|
| 9개 AI/이동/충돌 시그니처 | byte-identical | ✅ |
| `SKPhysicsBody(rectangleOf:` 인자 | byte-identical | ✅ |
| SergeantParkNode physicsBody/update/SKAction | 0건 (코멘트 제외) | **0건** ✅ |
| ColorTokens 6 hex | byte-identical | ✅ |
| GameConfig V3 ~22 (실제 29) 상수 | detection | ✅ |
| 강제 언래핑 | 0건 | **0건** ✅ |
| Timer | 0건 | **0건** ✅ |
| switch default | 0건 | **0건** ✅ |
| update() override (3 빌런) | byte-identical | ✅ |

---

## 보호 영역 git diff

| 보호 그룹 | 결과 |
|---|---|
| GameScene / GameScene+Setup / PhysicsCategory | 0줄 ✅ |
| Models / Systems / Repositories / Managers | 0줄 ✅ |
| PlayerNode / NoteNode / ProjectileNode / StethoscopeNode | 0줄 ✅ |
| Phase A·B·C·D·E 결과물 | 0줄 ✅ |

전체 git diff --stat: ColorTokens +20 / GameConfig +95 / EnemyNode +25 / ProfessorNode +21 / StoneGuardNode +32 + SergeantParkNode 신규 148 + pbxproj 4줄 + mockup 신규 321.

---

## 빌드 결과

**BUILD SUCCEEDED** ✅

- 컴파일 에러: 0
- 신규 워닝: 0
- 무관 워닝 3건(폰트 duplicate)

---

## P1 — 시각 디테일 매직 넘버 잔존 (8건)

GameConfig V3에 다음 시각 디테일 상수 추가 권장 (Phase G에서 묶어 처리):
- `enemyVisualChartCornerRadius`, `enemyVisualChartStrokeWidth`, `enemyVisualClipWidthRatio`, `enemyVisualClipHeight`
- `stoneGuardArmorWidthRatio`, `stoneGuardArmorHeightRatio`, `stoneGuardArmorCornerRadius`, `stoneGuardArmorStrokeWidth`, `stoneGuardEyeSize`
- `sergeantBodyCornerRadius`, `sergeantBodyStrokeWidth`, `sergeantHeadStrokeWidth`, `sergeantCapCrownStrokeWidth`, `sergeantSunglassesCornerRadius`, `sergeantSunglassesStrokeWidth`
- `professorStethoTubeStrokeWidth`

## P2 — StoneGuard eyeSize 토큰화

`Nodes/StoneGuardNode.swift:100` `let eyeSize = CGSize(width: 2, height: 0.8)` → GameConfig `stoneGuardEyeSize`.

---

## 최종 판정: ✅ 합격 (9.10/10)

Sprint 7 Phase F 합격선(7.5) 여유 있게 통과. Phase G (플레이어 4방향) 진행 가능.

**잔존 P1/P2 (합격 영향 0)**:
1. 시각 디테일 매직 넘버 8건 (stroke/cornerRadius) — Phase G 시작 시 묶어 정리 권장.
2. StoneGuard eyeSize 토큰화 1건.
