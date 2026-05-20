# SPRINT_9_REQUEST.md — 실기 검증 2차 결함 4종 + 캐릭터 선택 UX 재정비

> **작성**: 2026-05-20 (Sprint 8 전체 합격 8.78~9.68 평균 9.22 직후 사용자 시뮬레이터 실기 4종 결함 보고)
> **단일 진실 원천**: 이 문서의 §1 Phase 구조 / §6 변경 금지 / §11 합격 기준 / §14 사용자 의사결정만 따른다.

---

## 0. 한 줄 요약

스크린샷 4장에서 드러난 **잔존 시각 결함 4종**을 해소한다. Sprint 8이 *발화/노출/등장* 자체는 살렸지만, **레이아웃·크기·정체성·겹침**이 아직 다듬어지지 않음.

## 1. Phase 구조 (4 Phase 순차 실행)

| Phase | 작업 | 매핑 이슈 | 무게 |
|---|---|---|---|
| **A** | 캐릭터 선택창 — 카드 내부 정렬 + 좌우 화살표 + 여백 확보 | #1 "선택됨"·이름·스킬·다음 버튼 모두 겹침 + 둥둥 뜬 얼굴 | 중 (LOC ~250) |
| **B** | 인게임 풀바디 — 2칸 크기 축소 + 캐릭터별 정체성 요소 + PixelSprite 본체 시각 차단 | #2/#3 캐릭터 사이즈 과대 + 정간호가 김간호처럼 보임 | 중 (LOC ~200) |
| **C** | 빌런 시각 강화 + 카운트다운 표시 보장 (zPos 진단·고정) | #3 빌런 안 보임 + 카운트다운 미가시 | 소 (LOC ~80) |
| **D** | 결과창 위 요소들 더 위로 + 위·아래 묶음 분리 | #4 결과창 요소 다 겹쳐 보임 | 소 (LOC ~60) |

**Phase 의존성**: A → B → C → D 순차. Phase B의 풀바디 크기/zPos 확정이 Phase C 카운트다운 가림 진단의 전제가 되기 때문(B 먼저). Phase D는 독립.

---

## 2. 시각 레퍼런스

| 신규 파일 | 역할 |
|---|---|
| `mockups/sprint9-character-select-v4.html` | Phase A 캐릭터 선택창 신규 레이아웃 — 카드 안 "선택됨" 알약 + 좌우 화살표 + 안전 margin |
| `mockups/sprint9-ingame-character-sizing.html` | Phase B 풀바디 2칸 비교 + 캐릭터별 정체성 요소 시안 |
| `mockups/sprint9-result-spacing-v4.html` | Phase D 결과창 V4 spacing 시안 |

(목업 HTML 3개는 본 Sprint 작업지시서와 함께 작성 — Planner는 브라우저에서 시각 확인 후 SPEC.md에 좌표/색 토큰 그대로 복사.)

---

## 3. 문제 진단 (스크린샷 4장 → 코드 원인)

### 3-1. 스크린샷 1 — 캐릭터 선택창

**증상**:
- "선택됨" 알약과 헤더 부제("친구마다 다른 속도를 가져요")가 거의 닿아 있음
- 카드 하단의 코랄 glow가 카드 외부로 새어 나와 PrimaryButton("다음")과 시각 충돌
- 카드 옆 ±1 슬롯의 얼굴이 "둥둥" 뜬 상태 — 가운/카드 시각 분리 없음
- 다음 버튼이 좌측 카드 glow와 겹침

**원인**:
| 결함 | 파일 | 원인 |
|---|---|---|
| 알약↔헤더 sub 겹침 | `CharacterCardNode.swift` L297~322 | `selectedPill.position.y = halfH + characterCardSelectedPillOffsetY` — 카드 **외부 상단**으로 부착. halfH=100인데 카드 y=midY+0이라 alphabet y ≈ midY+100+offset, 헤더 sub y ≈ midY+85(estimate). 충돌 |
| glow↔다음 버튼 겹침 | `CharacterCardNode.swift` L267~294 | `selectedGlow.position.y = -halfH + selectedGlowOffsetY` — 카드 **외부 하단**. 다음 버튼이 그 아래에 위치 |
| 카드↔헤더 margin 부족 | `CharacterSelectScene.swift` L428 | `characterCardCenterYV4 = 0.50` — 카드 중심이 화면 정중앙. 헤더는 +headerOffsetY (~+85). 거리 부족 |
| 둥둥 얼굴 | `CharacterSelectScene.swift` L266 `layoutCharacterFaces()` | 얼굴이 카드 **위에** 별도 SKNode로 부착 (zPos 105). 측면 카드일 때 카드 alpha=0.55인데 얼굴 alpha는 동일 — 시각상 얼굴만 떠 보임 |
| 좌우 화살표 부재 | 없음 | 스와이프 인터랙션은 존재(touchesMoved/탭)하나 시각 가이드 0건 — 사용자 발견 어려움 |

### 3-2. 스크린샷 2·3 — 인게임 캐릭터

**증상**:
- 사용자가 정간호를 선택했는데 인게임 캐릭터가 김간호처럼 보임(빨강 십자 캡 인상)
- 캐릭터가 화면 1/3 가량을 차지 — 의도된 "2칸(64pt)" 대비 약 2배 크기
- 빌런이 화면에서 식별되지 않음
- 카운트다운 화면에 미가시 (로그는 `[Phase E] onTick 3/2/1/onGo/onComplete` 모두 발화)

**원인**:
| 결함 | 파일 | 원인 |
|---|---|---|
| 캐릭터 크기 과대 | `CharacterFullBodyNode.swift` L101~158 | body 56×44 + head r18 + hair 32×10 + cap 14×6 + legs 24h → 본체 노드 y범위 ≈ -60~+41 = **101pt** + scale `playerFullBodyScaleV4=0.35` → 화면상 약 35pt. *이론상* 1칸 수준이나 PixelSprite 본체(32×40)와 *위에 겹쳐* 시각 중첩으로 더 커 보임 |
| PixelSprite 본체 노출 | `PlayerNode.swift` L153~154 SPEC + 잔존 P2 #4 | "PixelSprite 본체 시각은 *그대로 노출*" 명시 — 풀바디 위 PixelSprite가 32×40 그대로 보임 |
| 정체성 결손 | `CharacterFullBodyNode.swift` L80~99 colorPalette | 1차 구현: 색 3개(body/hair/cap)만 차등 — *안경(정간호) / 빨강 캡(김간호) / 사이드테일(임간호 가발) / 묶음(이수민)* 등 정체성 요소 0건 |
| 빌런 시각 약함 | `EnemyNode.swift` / `ProfessorNode.swift` / `StoneGuardNode.swift` Phase G | `self.color = .clear; self.colorBlendFactor = 1.0` 2줄로 PixelSprite alpha 0 차단 → 시각 자식(halo/chart/clip/stethoDisc/tube/armor/eye)만 남음. 자식 크기가 작아 화면에서 식별 약함 |
| 카운트다운 미가시 | `GameScene.swift` L282~333 | onTick~onComplete 모두 발화(로그 확인). 가능 원인 후보 4종: (1) PauseButtonNode/HUD 등 zPos 240~250 침범 가능성 / (2) cameraNode가 worldOffset에 위치해 자식 position=.zero가 화면 밖 / (3) Jua-Regular 폰트 로드 실패 (시뮬레이터 fallback 시 폰트 size 0으로 추락 가능) / (4) dim alpha 0.32가 너무 짙어 fontColor coralPrimary가 묻힘 |

### 3-3. 스크린샷 4 — 결과창

**증상**:
- "중 난이도 · 정간호" → "실습 종료" → 부제 → "♪ 0" → "BEST 11" → SCORE → BEST 11 → 9 PLAYS → 공유 → 다시 시작 — *세로 11단*이 화면 가운데 580pt 안에 압축
- 위쪽 5단(headerChip~scoreLabel)이 너무 가까워 호흡 0pt

**원인**:
- `GameConfig.swift` V3 offsets: headerChip +115 / title +85 / subtitle +58 / scoreLabel -2 / divider -78
- **headerChip↔title gap = 30pt** (Jua 22pt + Jua 38pt 폰트 높이 합산 시 시각 gap ≈ 0pt)
- **subtitle↔scoreLabel gap = 60pt** (subtitle 16pt + score 56pt → 시각 gap ≈ 6pt)
- 모두 V4로 +20~30pt 위로 끌어올리고, 위쪽 묶음(header/title/subtitle)과 아래쪽 묶음(score/stat)을 더 분리 필요

---

## 4. Phase 상세

### Phase A — 캐릭터 선택창 카드 내부 정렬 + 좌우 화살표 + 여백

**목표**: 카드 외부의 부유 요소(알약/글로우/얼굴)를 모두 카드 *안*으로 들이고, 좌우 화살표를 명시. 카드↔헤더↔버튼 사이 최소 32pt 시각 호흡 확보.

#### 4-A-1. CharacterCardNode 내부 재정렬

`Nodes/CharacterCardNode.swift`:

1. `attachSelectedDecor()` 안 `selectedPill.position.y` 산식 교체:
   - **AS-IS**: `halfH + GameConfig.characterCardSelectedPillOffsetY` (외부 상단)
   - **TO-BE**: `halfH - GameConfig.characterCardSelectedPillInsetTopV9` (**내부 상단 inset**)
   - 신규 상수: `characterCardSelectedPillInsetTopV9: CGFloat = 16` (카드 상단에서 16pt 안쪽)

2. `selectedGlow.position.y` 산식 교체:
   - **AS-IS**: `-halfH + selectedGlowOffsetY` (외부 하단)
   - **TO-BE**: `-halfH + selectedGlowInsetBottomV9` (내부 하단 inset)
   - **AND** `selectedGlow.path` 크기를 카드 폭에 맞춤(`width = cardWidthV3 - 8`, `height = 36`) — 카드 외부 침범 0
   - 신규 상수: `characterCardSelectedGlowInsetBottomV9: CGFloat = 22`

3. **신규 attach**: `attachCenterIndicatorBadge()` (선택됨 알약 대체 옵션 — 의사결정 #1 참고)
   - 카드 내부 상단에 `coralPrimary` fill + Jua 11pt "선택됨" 라벨
   - 이미 `selectedPill`이 그 역할이라 *없어도 됨* — 1번 항목만으로 카드 내부 진입 충족

#### 4-A-2. CharacterSelectScene 여백·화살표·카드 위치

`Scenes/CharacterSelectScene.swift`:

1. **카드 y 위치 하향 이동**:
   - **AS-IS**: `characterCardCenterYV4 = 0.50` → 카드 중심 = scene.height × 0.50
   - **TO-BE**: `characterCardCenterYV9 = 0.44` → 카드 중심 = 44% (약 9pt 아래)
   - 효과: 카드 top(midY + 100 - 50 = +50pt)이 헤더 sub bottom (+85pt - 8pt = +77pt)과 27pt 이격

2. **확인 버튼 더 아래로**:
   - **AS-IS**: `frame.minY + safe.bottom + adaptiveBottomMargin + characterSelectConfirmButtonBottomInset`
   - **TO-BE**: 동일 식 + 카드 bottom 기준 *최소 36pt 호흡* 보장:
     ```swift
     let cardBottom = cardBaseY(for: .kim) - GameConfig.characterCardHeightV3 / 2
     let minButtonY = frame.minY + safe.bottom + adaptiveBottomMargin + characterSelectConfirmButtonBottomInset
     let buttonY = min(minButtonY, cardBottom - 36 - PrimaryButton.height/2)
     confirmButton.position = CGPoint(x: frame.midX, y: buttonY)
     ```
   - 신규 상수: `characterSelectConfirmButtonGapV9: CGFloat = 36`

3. **좌우 화살표 신규 노드 2개**:
   - `leftArrowChip = GlassPillNode(text: "‹", size: CGSize(width: 36, height: 36))`
   - `rightArrowChip = GlassPillNode(text: "›", size: CGSize(width: 36, height: 36))`
   - 위치: 카드 좌우 ±260pt 지점, y = cardBaseY
   - `touchesBegan`에 분기 추가 — 누르면 `swipeTo(index: currentIndex ± 1)`
   - 시각: 카드 끝에 안 닿게 카드 폭/2 + 100pt 외측, alpha 0.85
   - zPos 115 (카드 110보다 위)
   - **isHidden 가드**: 끝(index 0 / max)에서는 해당 방향 화살표 isHidden=true

4. **스킬 칩 위치 재정렬**:
   - **AS-IS**: `chip.position.y = confirmButton.position.y + characterSelectSkillInfoChipAbove`
   - 변경 없이 *characterSelectSkillInfoChipAboveV9* 신규 상수로 거리 확대: 기존 18~24 → **44**
   - 카드 bottom과 스킬 칩 사이 호흡 확보

#### 4-A-3. 둥둥 얼굴 해소

`CharacterSelectScene.swift` setupCharacterFaces / layoutCharacterFaces:

- 얼굴 위치를 카드 *내부 중앙*으로 조정 (`face.position.y = cardBaseY + characterFaceOffsetYWithinCardV9`)
  - 신규 상수: `characterFaceOffsetYWithinCardV9: CGFloat = 12` (카드 중심 약간 위)
- 얼굴 zPos를 카드보다 *낮게* — 카드 alpha 차이를 따라가도록 (`face.zPosition = 4`, 카드 본체 자식 5보다 아래)
  - 또는 *얼굴을 카드의 child로 부착* — alpha 자동 상속

#### 4-A-4. Phase A 합격 기준

- 카드 안 "선택됨" 알약 / glow 가 모두 카드 사각형 안에 위치(외부 픽셀 0)
- 좌우 카드 ±1 슬롯 캐릭터 face가 카드 alpha와 일치(0.55)
- "‹" "›" 화살표 시뮬레이터 식별 가능 + 끝 방향에서 isHidden=true
- 헤더 sub bottom ↔ 카드 top ≥ 24pt
- 카드 bottom ↔ 스킬칩 top ≥ 16pt
- 스킬칩 bottom ↔ 다음 버튼 top ≥ 20pt

---

### Phase B — 인게임 풀바디 2칸 크기 + 캐릭터별 정체성 + PixelSprite 차단

**목표**: 풀바디 노드를 "2칸(64pt)" 크기로 명확히 줄이되, 캐릭터별 정체성(안경/캡색/머리스타일)을 *5종 모두* 시각 식별 가능하게.

#### 4-B-1. 풀바디 크기 — 2칸 명확화

`Nodes/CharacterFullBodyNode.swift` body/head/legs path 모두 *축소*:

| 부위 | AS-IS | TO-BE (V9) | 신규 상수 |
|---|---|---|---|
| body | 56×44 | **40×32** | `playerFullBodyBodyWidthV9 = 40` / `HeightV9 = 32` |
| head | r=18 | **r=12** | `playerFullBodyHeadRadiusV9 = 12` |
| hair | 32×10 | **22×7** | `playerFullBodyHairWidthV9 = 22` / `HeightV9 = 7` |
| cap | 14×6 | **10×4** | `playerFullBodyCapWidthV9 = 10` / `HeightV9 = 4` |
| arm | 4×28 | **3×20** | `playerFullBodyArmHeightV9 = 20` (폭은 기존 `playerArmWidthV4`) |
| leg | 5×24 | **4×18** | `playerFullBodyLegHeightV9 = 18` |

**모든 좌표 y 비례 재계산** — body.y=-16 → -12, head.y=20 → 14, hair.y=30 → 21, cap.y=36 → 25, leg offsetY=-48 → -34. 위·아래 총 범위 약 70pt(35pt scale 0.5 적용 시 약 35pt = 1.1 tile).

**그리고** scale 변경:
- `playerFullBodyScaleV9: CGFloat = 0.92` (path 자체가 작아져서 scale은 거의 1:1)
- 효과: 화면상 약 64pt = 2 tile

#### 4-B-2. 캐릭터별 정체성 요소

`CharacterFullBodyNode.swift` 각 buildXxxBody에 캐릭터별 *추가 자식 1~2개*:

| 캐릭터 | 정체성 요소 | path |
|---|---|---|
| 김간호 (.kim) | 빨강 십자 캡(현재 cap.color에 더해 cap 위 작은 **십자** 2px SKShapeNode 2개) | width 2, height 4 + width 4, height 2, fill `coralPrimary`, z=13 |
| 정간호 (.jung) | **안경**(둥근 사각 2개 옆에 path 1개) | 4×3 ellipse 2 + bridge 2×0.5 line, fill `clear` + stroke `navyDeep` w=0.5, z=13 |
| 박건오 (.geon) | 야구 캡(앞으로 살짝 챙) | 14×5 cornerRadius 7, fill `coralPrimary`, z=12 — 위치 cap 자리 |
| 임수민 (.im) | **사이드테일** (오른쪽으로 흘러내린 머리) | 6×16 cornerRadius 3, hair color, position (8, 22), z=13 |
| 이수민 (.lee) | **묶음 머리** (양 옆 작은 묶음) | 4×6 cornerRadius 2 ×2, position (±10, 28), z=13 |

각각 build{Front/Back/Left/Right}Body 4메서드에 동일 캐릭터 분기 적용 — 측면일 때 안경/사이드테일 좌표 부호만 반전. 5캐릭터 × 4방향 × 1~2 요소 = 약 30 자식 추가.

#### 4-B-3. PixelSprite 본체 시각 차단

`Nodes/PlayerNode.swift` attachFullBody 끝에 1줄 추가:
```swift
// Sprint 9 Phase B — PixelSprite 본체 시각 차단 (빌런 3종 패턴 답습). hitbox/이동 보존.
self.alpha = 0  // 부모 자체 alpha를 0으로 — physicsBody는 영향 0
```
→ **위험**: PlayerNode 자체 alpha=0이면 자식인 fullBody도 alpha 0됨.

**대안 (권장)**: PixelSprite는 SKSpriteNode → texture만 차단:
```swift
self.texture = nil
self.color = .clear
self.colorBlendFactor = 1.0
self.size = CGSize.zero  // hitbox는 physicsBody 인자에서 결정되므로 size=0 무해
```

#### 4-B-4. Phase B 합격 기준

- 인게임 캐릭터 가로/세로 ≤ 70pt (2.2 tile 이하)
- 정간호 안경, 김간호 빨강 십자, 임수민 사이드테일이 시뮬레이터에서 식별 가능
- PixelSprite 본체 그림자/픽셀 잔존 0px
- physicsBody·velocity·이동·skill 0줄 변경 (`git diff PlayerNode.swift | grep "physicsBody\|velocity\|setupPhysics"` 빈 출력)

---

### Phase C — 빌런 시각 강화 + 카운트다운 표시 보장

**목표**: 빌런 3종(EnemyNode/ProfessorNode/StoneGuardNode) 시각 자식 *확대*로 식별성 회복, 카운트다운 가림 원인 진단·고정.

#### 4-C-1. 빌런 시각 자식 크기 1.4배

각 *시각 자식*만 신규 V9 상수로 1.4배 확대 (physicsBody 0줄 변경):

`Config/GameConfig.swift`:
```swift
// MARK: - Sprint 9 Phase C · Enemy Visual Scale-up
static let enemyVisualScaleV9: CGFloat = 1.4
static let professorVisualScaleV9: CGFloat = 1.4
static let stoneGuardVisualScaleV9: CGFloat = 1.4
```

`Nodes/EnemyNode.swift` setupVisualOverlay 끝에:
```swift
// 빌런 시각 자식 일괄 1.4배 확대 — physicsBody/hitbox 영향 0
self.children.filter { $0.name?.hasPrefix("enemyVisual_") == true }
    .forEach { $0.setScale(GameConfig.enemyVisualScaleV9) }
```

같은 패턴 ProfessorNode/StoneGuardNode.

**대안**: 각 자식 init 시점에 GameConfig 상수 직접 곱해 좌표/크기 산출 — 코드 깔끔. 둘 중 선호.

#### 4-C-2. 카운트다운 가림 진단 + 고정

`GameScene.swift` showCountdown:

1. **진단 print 정리**: `[Phase E]` 6줄 → `#if DEBUG` wrap.

2. **카운트다운 zPos 안전 마진 +50**:
   ```swift
   // Sprint 9 Phase C — HUD/Pause/SkillSlot 110 + 잠재적 zPos noise 회피.
   node.zPosition = GameConfig.countdownNodeZPositionV9  // = 300 (기존 250 + 50)
   dim.zPosition = GameConfig.countdownDimZPositionV9    // = 290
   ```

3. **카메라 좌표 명시 set**:
   ```swift
   node.position = .zero  // cameraNode 좌표계 중심
   // cameraNode 자체가 worldOffset에 위치할 가능성 → 명시 position=.zero로 화면 정중앙 보장
   ```

4. **fontName fallback**:
   ```swift
   // CountdownNode 안 SKLabelNode fontName이 nil/실패 시 시뮬레이터에서 폰트 size 0 가능성
   // 명시 fallback: Jua-Regular 미로드 시 systemFont(ofSize: 120)으로 추락
   ```
   - 이는 CountdownNode 본체 변경이 필요한데, *본체 보호* 정책 검토 필요. SPEC.md에서 의사결정 #2 확정.

5. **dim alpha 완화**:
   - **AS-IS**: `countdownDimAlpha = 0.32`
   - **TO-BE**: `countdownDimAlphaV9 = 0.22` (어둠 완화, coralPrimary 숫자가 묻히지 않게)

#### 4-C-3. Phase C 합격 기준

- 빌런 3종(수간호/이교수/석조무사) 시뮬레이터 화면에서 시각 식별 가능 (~24pt 이상)
- 카운트다운 3·2·1·GO 4가지 모두 시뮬레이터 화면에 표시되어 사용자 확인 가능
- `[Phase E]` print 0건 (release 빌드)
- PixelSprite alpha 0 / setupVisualOverlay 2줄 보존 (회귀 0)

---

### Phase D — 결과창 위 묶음 분리 + 전체 위로

**목표**: 위쪽 4단(headerChip/title/subtitle/scoreLabel) 사이 호흡 확대, 위쪽 묶음과 아래쪽 묶음(divider/plays/total) 분리.

#### 4-D-1. V4 offsets 정의

`Config/GameConfig.swift`:

```swift
// MARK: - Sprint 9 Phase D · Result V4 Spacing
static let resultHeaderChipOffsetYV4: CGFloat = 145   // V3 115 → +30
static let resultAccentLineOffsetYV4: CGFloat = 178   // V3 148 → +30
static let resultTitleOffsetYV4: CGFloat = 100        // V3 85  → +15
static let resultSubtitleOffsetYV4: CGFloat = 64      // V3 58  → +6
static let resultScoreOffsetYV4: CGFloat = 6          // V3 -2  → +8 (score를 약간 위로)
static let resultDividerOffsetYV4: CGFloat = -68      // V3 -78 → +10
// playsValue / TotalValue 등은 divider 기준 *상대* 식으로 갱신 필요
static let resultStatGapFromDividerV9: CGFloat = 28   // divider→stat 행 거리
```

#### 4-D-2. ResultScene 호출 교체

`Scenes/ResultScene.swift` layout 메서드 안 모든 V3 참조를 V4로 1:1 교체. V3 상수는 *값 보존* (다른 곳 참조 가능성).

#### 4-D-3. 위·아래 묶음 분리 검증

- 위 묶음 = headerChip(midY+145) / accentLine(+178) / title(+100) / subtitle(+64) / score(+6)
- 아래 묶음 = divider(-68) / plays(divider-28) / total(divider-28-20)
- score(+6) ↔ divider(-68) gap = 74pt — 충분히 분리

#### 4-D-4. Phase D 합격 기준

- 위 묶음 5단 각 행간 ≥ 24pt 시각 호흡 (Jua 폰트 베이스라인 기준)
- 위 묶음 마지막(score) ↔ 아래 묶음 첫(divider) gap ≥ 60pt
- ResultScene init 시그니처 byte-identical (`finalScore/personalBest/difficulty/characterName/...`)
- DiplomaOverlayNode / sparkle 5발 / heavy 햅틱 / NewMail 사운드 발화 시점 byte-identical
- 2단계 탭 정책 byte-identical
- "기록 보기" / "공유" / "다시 시작" 3 버튼 hit-test 회귀 0건

---

## 5. 신규 GameConfig 상수 (V9 sub-MARK 일괄)

```swift
// MARK: - Sprint 9 Phase A · Character Select V9
static let characterCardSelectedPillInsetTopV9: CGFloat = 16
static let characterCardSelectedGlowInsetBottomV9: CGFloat = 22
static let characterCardCenterYV9: CGFloat = 0.44
static let characterSelectConfirmButtonGapV9: CGFloat = 36
static let characterSelectSkillInfoChipAboveV9: CGFloat = 44
static let characterFaceOffsetYWithinCardV9: CGFloat = 12
static let characterSelectArrowChipWidthV9: CGFloat = 36
static let characterSelectArrowChipHeightV9: CGFloat = 36
static let characterSelectArrowChipOffsetXV9: CGFloat = 260
static let characterSelectArrowChipZPositionV9: CGFloat = 115

// MARK: - Sprint 9 Phase B · Player FullBody V9
static let playerFullBodyBodyWidthV9: CGFloat = 40
static let playerFullBodyBodyHeightV9: CGFloat = 32
static let playerFullBodyHeadRadiusV9: CGFloat = 12
static let playerFullBodyHairWidthV9: CGFloat = 22
static let playerFullBodyHairHeightV9: CGFloat = 7
static let playerFullBodyCapWidthV9: CGFloat = 10
static let playerFullBodyCapHeightV9: CGFloat = 4
static let playerFullBodyArmHeightV9: CGFloat = 20
static let playerFullBodyLegHeightV9: CGFloat = 18
static let playerFullBodyScaleV9: CGFloat = 0.92

// MARK: - Sprint 9 Phase C · Enemy Visual & Countdown V9
static let enemyVisualScaleV9: CGFloat = 1.4
static let professorVisualScaleV9: CGFloat = 1.4
static let stoneGuardVisualScaleV9: CGFloat = 1.4
static let countdownNodeZPositionV9: CGFloat = 300
static let countdownDimZPositionV9: CGFloat = 290
static let countdownDimAlphaV9: CGFloat = 0.22

// MARK: - Sprint 9 Phase D · Result V4 Spacing
static let resultHeaderChipOffsetYV4: CGFloat = 145
static let resultAccentLineOffsetYV4: CGFloat = 178
static let resultTitleOffsetYV4: CGFloat = 100
static let resultSubtitleOffsetYV4: CGFloat = 64
static let resultScoreOffsetYV4: CGFloat = 6
static let resultDividerOffsetYV4: CGFloat = -68
static let resultStatGapFromDividerV9: CGFloat = 28
```

V3/V4 기존 상수는 모두 *값 보존* — 다른 곳 참조 가능성 + 회귀 안전망.

---

## 6. 변경 금지 (절대 건드리지 말 것)

| 영역 | 이유 |
|---|---|
| `PlayerNode.swift` `setupPhysics()` / `update(deltaTime:)` 본문 | 게임 로직 회귀 0 |
| 모든 `physicsBody.size` / `categoryBitMask` / `collisionBitMask` / `contactTestBitMask` | hitbox 동일 |
| `SpawnSystem.swift` / `ScoreSystem.swift` / `SkillSystem.swift` / `ContactRouter.swift` | 게임 로직 |
| `Models/` 모든 enum 값 (CharacterID/Difficulty/PlayerSkill 케이스, raw, displayName, color) | 의미 보존 |
| `Repositories/` 저장 호출 — read-only 변경만 허용 | 저장 회귀 0 |
| `CharacterFaceNode.swift` 전체 | Sprint 6/7 결과물, 선택 화면 정체성 단일 진실 원천 |
| `NurseAvatarNode.swift` 전체 | StartScene 메인 캐릭터 |
| Sprint 8 Phase F V4 상수 11종 + zPos 적층 80<100<110 | Phase F 합격 결과 |
| Sprint 8 Phase G 빌런 3종 `self.color = .clear; self.colorBlendFactor = 1.0` 2줄 | 의사결정 #6 보호 |
| Sprint 7 Phase D `ResultScene init` 9개 인자 + scoreLabel 텍스트 "\(finalScore)" 정책 + bestLabel.alpha=0 | 분기별 발화 조건 보존 |
| `DiplomaOverlayNode` 본체 | Sprint 5 결과물 |

---

## 7. 빌드·검증 절차

1. `cd /Users/hg/Desktop/ganho-music-ios && xcodebuild -scheme GanhoMusic ...` 빌드 SUCCEEDED
2. `git diff` 보호 영역 0줄 확인 (§6)
3. 시뮬레이터 iPhone 17 Pro Landscape에서 4 화면 모두 확인:
   - 캐릭터 선택창: 알약/glow 카드 안쪽, 화살표 시각 식별, 다음 버튼 호흡 ≥ 36pt
   - 인게임: 캐릭터 ≤ 70pt, 정간호 안경 식별, 빌런 식별, 카운트다운 3·2·1·GO 4단 표시
   - 결과창: 위·아래 묶음 분리, 모든 라벨 ≥ 24pt 호흡

---

## 8. 시그니처 byte-identical 검증 (필수 grep)

```bash
cd /Users/hg/Desktop/ganho-music-ios

# 1) func 시그니처 변경 0
git diff --diff-filter=M | grep -E "^[+-].*func "
# 빈 출력이어야 함 (private helper 신규 추가 시 [+func] 가능)

# 2) physicsBody/velocity 0줄 변경
git diff "GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift" | grep -E "physicsBody|velocity"
# 빈 출력

# 3) 보호 노드 git diff 0줄
git diff "GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift"  # 빈
git diff "GanhoMusic/GanhoMusic Shared/Nodes/NurseAvatarNode.swift"    # 빈

# 4) ResultScene init 인자 byte-identical
git diff "GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift" | grep "init(finalScore"
# 빈 출력
```

---

## 9. 합격 기준 (각 Phase 가중 평균 7.5 이상)

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (절대 회귀 0) |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 |
| 가독성 & UX | 15% | 7.0 이상 |

---

## 10. 시뮬레이터 실측 우선순위

목업 매칭보다 **시뮬레이터 화면 실측이 단일 진실 원천**. Evaluator는 mockup HTML 좌표와 시뮬레이터 실측이 충돌 시 *실측을 우선*해야 한다 (사용자가 실제 본 결과가 무엇인지가 가장 중요).

---

## 11. 진행 순서

```
SPRINT_9_REQUEST.md 읽기
  → Phase A (캐릭터 선택창)
      → Planner SPEC.md → Generator → Evaluator → 합격 시 다음
  → Phase B (인게임 풀바디)
  → Phase C (빌런 + 카운트다운)
  → Phase D (결과창 위로)
  → Sprint 9 전체 합격 → DESIGN_RENEWAL_STATE.md 갱신
```

각 Phase는 기본 하네스(SPEC → Generator → Evaluator → 판정) 그대로. CLAUDE.md "디자인 리뉴얼 모드 — Sprint 8 Phase 모드" 절차 답습 + Sprint 8 → 9 치환.

---

## 12. 트리거

사용자가 한 마디 입력:

```
Sprint 9 진행해줘
```

또는 특정 Phase:

```
Sprint 9 Phase A 진행해줘
```

자동으로:
1. `DESIGN_RENEWAL_STATE.md` 읽고 Sprint 9 Phase 진행 상태 확인
2. 다음 Phase의 Planner 프롬프트 실행 (`SPRINT_9_REQUEST.md`를 SPEC 단일 진실로 사용)
3. Generator → Evaluator (최대 3회)
4. 합격 시 DESIGN_RENEWAL_STATE.md 갱신 + 다음 Phase로

---

## 13. 잔존 위험 / Phase 4개 통과 후에도 남는 결함 후보

- 풀바디 5캐릭터 정체성 요소 (Phase B 단순화 — 안경/십자/사이드테일/묶음/캡색) — *2차 식별성*은 자산 도착(Sprint 4 PNG) 시 SKSpriteNode(texture:)로 전환되며 자동 해소
- 빌런 시각 자식 1.4배가 hitbox 외관과 시각 정렬에서 어색할 가능성 — 시뮬레이터 실측 후 미세 조정 (Sprint 10 후보)
- 카운트다운 표시 결함이 fontName Jua-Regular 로드 실패라면 Info.plist UIAppFonts 추가가 *근본 해법* (사용자 후속 작업)
- 결과창 V4 spacing이 작은 폰트 환경(Dynamic Type 큰 글씨)에서 시각 호흡 부족 가능 — Dynamic Type 1.2배 이상 실측 후 결정

---

## 14. 사용자 의사결정 (사전 확정 — 2026-05-20)

Sprint 9 Planner는 다음 7건 결정을 SPEC.md에 그대로 복사·반영해야 한다:

1. **선택됨 표지 위치**: 카드 내부 상단 (외부 부착 ❌). `selectedPill` 인스턴스는 *재사용*, position만 V9 inset.
2. **카드 외부 부유 시각 0**: glow/이름/스킬칩 모두 카드 사각형 안쪽 또는 카드와 명확히 분리된 영역(스킬칩=카드 bottom 아래 44pt 이격).
3. **좌우 화살표**: 신규 `GlassPillNode` 2개. 끝 방향에서 isHidden=true (현재 위치 시각 가이드).
4. **스와이프 인터랙션**: 기존 touchesMoved 40pt threshold 유지 + 화살표 탭 추가. 양옆 카드 탭 분기도 유지.
5. **풀바디 크기**: 2칸(64pt) 목표 — path 자체 축소 + scale 0.92. PixelSprite 본체 시각 차단 (texture=nil 패턴).
6. **캐릭터 정체성 요소**: 5종 × 1~2자식. 1차는 *단순 path*(안경/십자/사이드테일/묶음/캡색). 자산 도착 시 SKSpriteNode 교체.
7. **카운트다운 표시 보장**: zPos 250 → 300, dim alpha 0.32 → 0.22, position .zero 명시. 진단 print는 `#if DEBUG` wrap. CountdownNode 본체는 *시그니처 보호* — font fallback 추가는 본체 1줄 수정만 허용 (decision case-by-case).

---

## 15. 끝

본 작업지시서는 **Sprint 9 단일 진실 원천**. Planner/Generator/Evaluator 모두 본 문서의 §1~§14만 따른다. 시뮬레이터 실측이 mockup과 충돌 시 §10에 따라 실측 우선.

작성: 2026-05-20
사용자 의사결정 7건 확정.
