# 자체 점검 — Sprint 7 Phase F (Generator 1차)

## 변경 파일 목록 + 라인 수

| 파일 | 유형 | 변경 LOC |
|---|---|---|
| `Config/ColorTokens.swift` | 수정 | +24 (6 토큰 + MARK 헤더 + 주석) |
| `Config/GameConfig.swift` | 수정 | +88 (Phase F V3 상수 ~22개 + MARK 헤더 + 주석) |
| `Nodes/EnemyNode.swift` | 수정 | +58 (setupVisualOverlay 호출 1줄 + 메서드 4개) |
| `Nodes/ProfessorNode.swift` | 수정 | +42 (setupVisualOverlay 호출 2줄 + 메서드 3개) |
| `Nodes/StoneGuardNode.swift` | 수정 | +51 (color 인자값 교체 + 호출 1줄 + 메서드 3개 + 주석) |
| `Nodes/SergeantParkNode.swift` | **신규** | 148 (6 attach + init + chevron factory) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4 (BuildFile + FileRef + Group + Source) |
| `mockups/villains-and-player-directions-v1.html` | **신규** | 321 (4 패널 + SVG + 색 chip + 후반부 메모) |

**합계: 수정 5 Swift + 신규 1 Swift + 1 pbxproj + 1 mockup = 8 파일**
**총 변경 LOC: 신규 ~469 / 수정 ~263 (실 라인은 git diff +517 / -425, SPEC/SELF_CHECK/QA는 무관)**

---

## 보호 영역 0줄 검증 (git diff)

```bash
git diff HEAD --stat -- \
  "GanhoMusic Shared/GameScene.swift" \
  "GanhoMusic Shared/GameScene+Setup.swift" \
  "GanhoMusic Shared/Config/PhysicsCategory.swift" \
  "GanhoMusic Shared/Models/" \
  "GanhoMusic Shared/Systems/" \
  "GanhoMusic Shared/Repositories/" \
  "GanhoMusic Shared/Scenes/" \
  "GanhoMusic Shared/Managers/"
# → 0 출력 (모두 미변경)
```

- **GameScene/GameScene+Setup**: 0줄 — setupEnemy/setupStoneGuard/setupProfessor/addNormalMap/addHardMap 0변경
- **PhysicsCategory**: 0줄 — 비트마스크 0변경
- **Managers/Repositories/Systems/Scenes/Models**: 0줄
- **Phase A·B·C·D·E 결과물**: 모두 미변경
- **PlayerNode/NoteNode/ProjectileNode/StethoscopeNode**: 0줄

---

## 3 빌런 AI/이동/충돌 시그니처+본문 byte-identical

### EnemyNode.swift
```bash
git diff HEAD -- EnemyNode.swift | grep -v "^[+-]{3}" | \
  grep -E "update\(|startPatrol|startFleeing|apply\(|SKPhysicsBody|categoryBitMask|collisionBitMask|contactTestBitMask|physicsSize"
# → 0 출력
```
- `apply(_:)`, `startFleeing(duration:onEnd:)`, `update(deltaTime:targetPosition:speedT:)`: 본문 0변경
- `updatePixelDirection / tickWalkFrame / refreshTexture`: 0변경
- physicsBody size 인자 `physicsSize` (= GameConfig.enemyWidth/Height): 0변경
- categoryBitMask=enemy, collisionBitMask=wall, contactTestBitMask=player: 0변경
- **추가**: `zPosition = 5` 직후 1줄(`setupVisualOverlay()`) + 메서드 4개 (init 본문 외 영역)

### ProfessorNode.swift
```bash
git diff HEAD -- ProfessorNode.swift | grep -v "^[+-]{3}" | \
  grep -E "update\(|startPatrol|startThrowingStetho|scheduleNext|throwStetho|stopThrowing|currentStetho|currentThrowInterval|SKPhysicsBody"
# → 0 출력
```
- `startPatrol`, `startThrowingStethoscopes(targetProvider:worldNode:progressProvider:)`, `scheduleNextThrow`, `throwStethoscope`, `currentThrowInterval`, `stopThrowing(worldNode:)`, `currentStethoscopeCount(in:)`, `updatePixelAnimation(deltaTime:)`, `refreshTexture`: **모두 본문 byte-identical**
- physicsBody 미부착 정책 유지 — 0 줄 변경
- **추가**: `startPatrol()` 직전 1줄(`setupVisualOverlay()`) + 메서드 3개

### StoneGuardNode.swift
```bash
git diff HEAD -- StoneGuardNode.swift | grep -v "^[+-]{3}" | \
  grep -E "startPatrol|SKPhysicsBody|categoryBitMask|collisionBitMask|contactTestBitMask"
# → 0 출력
```
- `startPatrol()`: 본문 byte-identical
- physicsBody size 인자 `size` (= GameConfig.stoneGuardWidth/Height): 0변경
- categoryBitMask=stoneGuard, collisionBitMask=0, contactTestBitMask=player: 0변경
- **변경된 단일 line**: `super.init(texture: nil, color: .ganhoPaper, size: size)` → `super.init(texture: nil, color: .ganhoStoneGuardLight, size: size)` — *시그니처 byte-identical, color 인자값만 교체*
- **추가**: physicsBody body 부착 직후 1줄(`setupVisualOverlay()`) + 메서드 3개

---

## physicsBody.size 인자 byte-identical (grep 비교)

| 노드 | physicsBody size 인자 | 변경 |
|---|---|---|
| EnemyNode | `SKPhysicsBody(rectangleOf: physicsSize)` (physicsSize = CGSize(width: GameConfig.enemyWidth, height: GameConfig.enemyHeight)) | **0줄** |
| StoneGuardNode | `SKPhysicsBody(rectangleOf: size)` (size = CGSize(width: GameConfig.stoneGuardWidth, height: GameConfig.stoneGuardHeight)) | **0줄** |
| ProfessorNode | physicsBody 미부착 (통과형) | **0줄** |

StoneGuardNode 자식 armor가 `GameConfig.stoneGuardWidth * 0.7` / `Height * 0.5`를 *시각용*으로만 참조 — physicsBody 호출에는 미사용. 확인 완료.

---

## PhysicsCategory 0줄

```bash
git diff HEAD -- "Config/PhysicsCategory.swift"
# → 0 출력
```

비트마스크 `player/note/enemy/wall/projectile/stoneGuard/bonus/stethoscope` 모두 미변경.

---

## GameScene 0줄

```bash
git diff HEAD -- "GameScene.swift" "GameScene+Setup.swift"
# → 0 출력
```

- `setupEnemy`, `setupStoneGuard`, `setupProfessor`, `addNormalMap`, `addHardMap` 호출 위치/순서/인자 0변경
- ContactRouter 분기 0변경

---

## SergeantParkNode physicsBody/update/SKAction 0건

```bash
grep -E "physicsBody|update\(|SKAction" SergeantParkNode.swift
# → 헤더 코멘트 1줄만 매치 (line 7: "//  physicsBody / SKAction / update / AI **0줄**")
# → 실제 코드 0건
```

- physicsBody 부착 0건
- update(_:) override 0건
- SKAction 실행 0건
- 자식 SKShapeNode 6종만 부착 (Shadow/Body/Head/Cap/Sunglasses/Rank)
- 게임 spawn 0건 (GameScene 등장 없음, Sprint 8 후보)

---

## 강제 언래핑 0 / Timer 0 / switch default 0

```bash
grep -E "Timer\.|! *$|!\)| as!" SergeantParkNode.swift
# → 0 출력
```

- 강제 언래핑 (`!` / `as!`) 0건
- Timer 0건 (모든 시각은 정적 부착, SKAction 미사용)
- switch default 0건 (switch 자체 미사용)
- 클로저 0건 — `[weak self]` 불필요
- magic number 0 — 모든 사이즈/오프셋은 GameConfig V3 상수 참조

EnemyNode/ProfessorNode/StoneGuardNode 신규 추가 영역도 동일 — Timer 0, 강제 언래핑 0.

---

## 빌드 결과

```bash
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" -destination "generic/platform=iOS Simulator" build
# → ** BUILD SUCCEEDED **
```

- 컴파일 에러: **0**
- 신규 워닝: **0** (기존 폰트 duplicate 워닝 3건은 Phase F 무관 — Sprint 5 이전부터 존재)

---

## OPEN_QUESTION 4개 처리 상태

**OQ-1 (SergeantParkNode 부모 클래스)**: ✅ **SKSpriteNode(.clear) + 자식 SKShapeNode 6종** 채택.
기존 빌런 3종(EnemyNode/StoneGuardNode/ProfessorNode) 패턴 일관성. SPRINT_7_REQUEST.md §7.2 "SKShapeNode"
명시는 *추후 변경 가능* — 본 SPEC은 일관성 우선. SergeantParkNode.swift line 12-13 코멘트로 명시.

**OQ-2 (EnemyNode 픽셀 텍스처 톤 흐림)**: ✅ **자식 SKShapeNode 추가만**(차트 + 헬로 + 클립).
픽셀 텍스처(nurseChiefData/chiefPalette) 0변경. 시각 단서는 *부착물*로만 강화 — 회귀 위험 0.

**OQ-3 (StoneGuardNode 단색 → PixelSprite)**: ✅ **현 단색(.ganhoStoneGuardLight) + 자식 SKShape 부착**.
PixelSprite stoneGuardData 정식 변환은 Sprint 8 후보. 본 sprint는 *돌상 무채색 톤*만 부여.

**OQ-4 (hitbox 보존 검증)**: ✅ Evaluator가 grep 가능하도록 본문 위 grep 결과 모두 첨부.
`SKPhysicsBody(rectangleOf: size)` 인자 (GameConfig.enemyWidth/Height, stoneGuardWidth/Height) 모두 0변경.

---

## SPEC 기능 체크

- [x] **기능 1**: EnemyNode setupVisualOverlay — 헬로(navyMuted alpha 0.18 zPos -0.1) + 차트(paper fill + navyDeep stroke zPos 0.1) + 클립(coralPrimary zPos 0.2)
- [x] **기능 2**: ProfessorNode setupVisualOverlay — 청진기 mini disc(coralPrimary + coralShadow stroke zPos 0.1) + 튜브(coralLight zPos 0.15). StethoscopeNode와 무관.
- [x] **기능 3**: StoneGuardNode setupVisualOverlay — color `.ganhoPaper` → `.ganhoStoneGuardLight` + 사각 갑옷(stoneGuardDark fill + stoneGuardOutline stroke 0.8) + 일자눈 2개(navyDeep rectOf 2×0.8 좌우 대칭)
- [x] **기능 4**: SergeantParkNode 신규 — SKSpriteNode(.clear) + 6 attach 메서드(shadow/body/head/cap/sunglasses/rank). physicsBody/update/SKAction 0건.
- [x] **기능 5**: ColorTokens 6 토큰 — ganhoAirforceTeal/AirforceTealLight/SunglassesBlack/StoneGuardLight/StoneGuardDark/StoneGuardOutline. ganhoSkinTone은 line 256에 기존 존재 → 재사용.
- [x] **기능 6**: GameConfig Phase F V3 상수 ~22개 — enemyVisual{Halo,Chart} 5 + professorStetho{Icon,Tube} 4 + stoneGuardEye{X,Y} 2 + sergeant{Park,Shadow,Body,Head,Cap,Sunglasses,Rank,Chevron} 18 = **29 상수** (SPEC 추정 ~22 충족)
- [x] **기능 7**: mockups/villains-and-player-directions-v1.html — 4 패널 가로 정렬, 각 220×320pt, SVG 96×120, 핵심 시각 요소 4개 + 색 키 chip 3개, 박병장 ✨NEW 표시, 하단 후반부 메모

---

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (0건)
- guard let 옵셔널 처리: **준수** (해당 메서드 없음 — 정적 부착만)
- MARK 섹션 구분: **준수** (`MARK: - Init / Attach / Visual Overlay` 등)
- GameConfig 상수 사용: **준수** (29 신규 상수 모두 참조, 매직 넘버 0)
- weak self 캡처: **N/A** (정적 부착만, 클로저 미사용)

---

## SpriteKit 패턴 준수

- `didMove(to:)`에서 초기화: **N/A** (Node 클래스 — init에서 직접 부착)
- dt 기반 이동: **N/A** (시각만, 이동 0)
- SKAction 스폰 패턴: **N/A** (SergeantParkNode SKAction 0건 — 시각만)
- 충돌 후 노드 즉시 삭제 없음: **준수** (충돌 처리 0건)
- HUD 노드 분리: **N/A**

---

## 변경 LOC 추정 vs 실제

| 파일 | SPEC 추정 LOC | 실제 LOC |
|---|---|---|
| EnemyNode.swift | ~26 | +58 (주석 포함) |
| ProfessorNode.swift | ~21 | +42 (주석 포함) |
| StoneGuardNode.swift | ~32 | +51 |
| SergeantParkNode.swift (신규) | ~150 | 148 |
| ColorTokens.swift | ~20 | +24 |
| GameConfig.swift | ~90 | +88 |
| mockups/villains-and-player-directions-v1.html (신규) | ~200 | 321 (4 패널 + 후반부 메모 포함) |
| **합계** | **~540** | **신규 ~469 / 수정 ~263 = ~732** |

SPEC 추정 대비 +36% — 주석/코멘트가 늘어남(모든 자식 SKShape에 zPos 설명, OQ 결정 근거, hitbox 보존 계약 명시). 게임 코드 LOC는 SPEC 범위 내.

---

## 범위 외 미구현 항목

**없음** — SPEC §"허용" 모두 구현, §"금지" 모두 회피.

---

## 최종 보고 요약

- 변경 파일: **8개** (수정 5 Swift + 신규 1 Swift + 1 pbxproj + 1 mockup)
- 변경 LOC: 신규 ~469 / 수정 ~263
- **빌드: SUCCEEDED**
- **보호 영역 git diff 0줄: ✅**
- 4명 빌런 시각 정체성: ✅ (mockup 4 패널 가로 정렬, 각 SVG + 색 chip)
- SergeantParkNode 컴파일 OK + GameScene 등장 0건
- 기존 3종 hitbox·AI byte-identical (grep 비교 통과)
