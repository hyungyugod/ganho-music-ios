# QA 검수 보고서 — Sprint 2 메뉴 3씬 v2 리스킨

## 빌드 검증
- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- SDK: iOS 26.5 / target iOS 16.6
- 경고: duplicate Font build phase 3건 (Sprint 1 잔존, 본 Sprint 무관). Swift compile warning 0.
- 판정: 빌드 PASS

---

## 회귀 가드 검증

| 파일 | git diff 줄수 | 결과 |
|---|---:|---|
| `GameScene.swift` | 0 | PASS |
| `GameScene+Setup.swift` | 0 | PASS |
| `Scenes/ResultScene.swift` | 0 | PASS |
| `Nodes/GlassPillNode.swift` | 0 | PASS |
| `Nodes/AccentLineNode.swift` | 0 | PASS |
| `Nodes/DarkContextChipNode.swift` | 0 | PASS |
| `Nodes/PrimaryButtonNode.swift` | 0 | PASS |
| `Nodes/BackButtonNode.swift` | 0 | PASS |
| `Nodes/GradientBackgroundNode.swift` | 0 | PASS |
| `Config/ColorTokens.swift` | 0 | PASS |
| `Nodes/CharacterCardNode.swift` | 0 | PASS |
| `Nodes/DifficultyCardNode.swift` | 0 | PASS |
| `Nodes/StoryBoxNode.swift` | 0 | PASS |
| `Nodes/GlowingTitleNode.swift` | 0 | PASS |
| `Nodes/MusicNoteEmitterNode.swift` | 0 | PASS |

OUT 범위 0줄 검증 **완벽**. Sprint 1 컴포넌트 내부·게임 로직·저장소·씬 전환 시그니처·ColorTokens 토큰 모두 무손상.

---

## SPEC 기능 검증

### StartScene (5개)
- **S1 — 3-stop warm gradient**: PASS. `StartScene.swift:89-99` `GradientBackgroundNode.threeStop(... topColor: .ganhoBgWarmTop, midColor: .ganhoBgWarmMid, bottomColor: .ganhoBgWarmBottom)`. `backgroundColor = .ganhoBgWarmTop` 1프레임 fallback (line 64).
- **S2 — Overlay 패널 제거**: PASS. `setupOverlayPanel()` 호출과 함수 본문 모두 제거. `didMove(to:)` 안에서 호출 흔적 0.
- **S3 — Jua 2-라인 타이틀 + AccentLine + 태그라인**: PASS. `setupTitleBlock` (line 161-190): titleLine1 navyDeep 44pt, titleLine2 coral 56pt, accentLine, taglineLabel(Gowun Dodum, numberOfLines=0, preferredMaxLayoutWidth). 우측 정렬(line 166, 173, 180). GlowingTitleNode 인스턴스 제거됨.
- **S4 — BEST/PLAYS GlassPillNode 2개**: PASS. `setupStatPills` (line 129-143): `HighScoreRepository().current` / `StatisticsRepository().current.playCount` 저장소 호출 위치 보존. 좌상단/우상단 배치 (line 145-156).
- **S5 — 시작 버튼 가운데 정렬**: PASS. `layoutStartButton` (line 257-262) 기존 `startSceneStartButtonOffsetY` 그대로.

### CharacterSelectScene (5개)
- **C1 — Warm gradient + AccentLine 헤더 + Gowun Dodum 부제**: PASS. `setupGradientBackground` (line 106-116), `setupHeader` (line 125-142): `headerLabel.fontName = GameConfig.fontDisplay` 명시, `headerSubLabel` Gowun Dodum + `.ganhoNavyMuted`.
- **C2 — Top bar GlassPill back + DarkContextChip difficulty**: PASS. `setupTopBar` (line 159-177): GlassPillNode "← 난이도 다시", DarkContextChipNode label="현재 난이도" badge=`difficulty.shortName`. `backButton` 인스턴스(BackButtonNode) 완전 제거 → `backPill: GlassPillNode?` 옵셔널로 교체. `touchesBegan`에서 `backPill?.contains(location) == true` 패턴 (line 432).
- **C3 — 5장 글래스 외곽 + 색 점 + 선택 stroke/scale/y**: PASS. `setupCardContainers` (line 197-217), `setupCardColorDots` (line 250-262), `applyGlassContainerSelection` (line 388-416). CharacterCardNode 내부 변경 0건. `cardBaseX/cardBaseY` 헬퍼 (line 357-371).
- **C4 — 하단 스킬 정보 패널**: PASS. `rebuildSkillInfoPanel` (line 322-335) — `id.skill == .none` 분기 처리 + 속도 배율 formatted. `select(_:)` (line 382)와 `didMove` (line 89)에서 호출.
- **C5 — Confirm 가운데 정렬**: PASS. `layoutConfirmButton` (line 312-317) `frame.midX`. backButton 인스턴스 제거됨. 기존 `characterSelectButtonRowOffsetY/Spacing` 상수 보존(GameConfig.swift:998/1000).

### SkillExplanationScene (6개)
- **K1 — Gradient + 헤더 AccentLine + 부제**: PASS. `setupHeader` (line 160-177): `headerLabel.fontName = GameConfig.fontDisplay` (line 161), Gowun Dodum 부제, AccentLine.
- **K2 — Top bar GlassPill back + DarkContextChip breadcrumb**: PASS. `setupTopBar` (line 194-212): GlassPillNode "← 캐릭터 다시" + DarkContextChip label=`"\(difficulty.shortName) · \(characterID.displayName)"` badge="스킬". 하단 BackButtonNode `backButton` 보존(line 59) — K6 정책.
- **K3 — 좌측 글래스 아바타 카드 + 이름 뱃지 + role + 속도 칩**: PASS. `setupAvatarCard` (line 231-250): fill white α=0.85, stroke coralPrimary α=0.3 + lineWidth 2. `avatarSprite` (line 93-97) PixelSpriteRenderer 호출 흐름 보존. `setupAvatarNameBadge` + `setupAvatarRoleAndSpeed`.
- **K4 — 우측 코랄 메타 + Jua 36pt 스킬명 + 인용박스 + 메타 칩 3개**: PASS. `setupMetaLabel` (line 339-348), `setupSkillName` (line 357-367) `skillNameLabel.fontName = GameConfig.fontDisplay` (line 359). `setupSkillQuoteBox` (line 379-422): 좌 3px 코랄 보더 (line 399-408) `borderWidth=skillExplanationQuoteBoxBorderWidth=3` 명시. `characterID.skill.fullDescription` 보존 (line 410). `setupStatChips` (line 432-457) CD/범위/발동 DarkContextChip 3개. `PlayerSkill.rangeText/castText` (PlayerSkill.swift:90-114) 신규 computed property.
- **K5 — 컨트롤 힌트 "B" 키 마크**: PASS. `setupControlHint` (line 476-516): 다크 navy α=0.92 컨테이너 + 코랄 원(radius=11) + "B" 라벨 흰색 + Gowun Dodum 라벨. `controlHintLabel.fontName = GameConfig.fontBody` (line 508).
- **K6 — 하단 좌우 버튼 2개**: PASS. `setupButtons` + `layoutButtons` (line 535-546): BackButtonNode + PrimaryButtonNode 좌우. 기존 `characterSelectButtonSpacing` 재사용.

### 모델 변경 (4개 신규 computed property)
- **Difficulty.shortName**: PASS. `Difficulty.swift:47-53` "하/중/상".
- **PlayerSkill.rangeText**: PASS. `PlayerSkill.swift:90-98` "3타일/6타일/전역/최원거리".
- **PlayerSkill.castText**: PASS. `PlayerSkill.swift:103-114` duration ≤ 0 → "즉발", 그 외 → "\(seconds)초".
- **CharacterID.dotColor**: PASS. `CharacterID.swift:81-89` coralLight/scrubMint/lavenderSoft/musicGold/coralLight.

### 15 조합 시작 가능 여부
- StartScene → CharacterSelectScene(difficulty:) 시그니처 보존 (StartScene.swift:339).
- CharacterSelectScene .kim 분기 → GameScene 직진 (CharacterSelectScene.swift:460); 그 외 4 캐릭터 → SkillExplanationScene (line 467).
- SkillExplanationScene → GameScene(characterID:difficulty:) (line 579).
- 5×3=15 조합 모두 컴파일러 검증 통과 (BUILD SUCCEEDED). PASS.

---

## Sprint 2 특수 검수

| 항목 | 결과 | 비고 |
|---|---|---|
| 모든 SKLabelNode `fontName`이 GameConfig.font* 사용 | PASS | `SKLabelNode(text:)` 4건 모두 setup 함수에서 `.fontName = GameConfig.fontDisplay/Body` 명시 (CharacterSelectScene.swift:126; SkillExplanationScene.swift:161, 359, 508) |
| 하드코딩 hex 0건 | PASS | grep `UIColor(red:|hex:|#[0-9A-Fa-f]{6}` 결과 0 |
| Sprint 1 컴포넌트 재사용 가시화 | PASS | GlassPillNode 4건 / AccentLineNode 3건 / DarkContextChipNode 7건 / PrimaryButtonNode 3건 / BackButtonNode 1건 / GradientBackgroundNode.threeStop 3건 |
| 매직 넘버 0건 (Scenes/ 신규 코드) | PASS | grep `:CGFloat= \d+`, `withAlphaComponent(\d.\d+)`, `scale(to: \d.\d+)`, `fontSize = \d+` 결과 0 (모두 GameConfig 참조) |
| 컨트롤 힌트 "B" 키 마크 가시 | PASS | SkillExplanationScene.swift:494-506: 코랄 원 radius=11 + "B" 흰색 라벨 |
| 카드 색 점 8px 가시 (반지름 4) | PASS | CharacterSelectScene.swift:252 `circleOfRadius: GameConfig.characterCardColorDotRadius=4` → 직경 8 |
| 인용 박스 좌 3px 코랄 보더 가시 | PASS | SkillExplanationScene.swift:399-408 borderWidth=3, fillColor=ganhoCoralPrimary |
| 강제 언래핑 0건 | PASS | grep `!` 결과 모두 `!=`/`guard !` 부정 패턴 |
| Timer/DispatchQueue 0건 | PASS | grep 결과 0 |
| weak self 캡처 | PASS | StartScene.swift:337 `[weak self, weak view]` |
| MARK 섹션 구분 | PASS | StartScene 9 / CharacterSelect 14 / SkillExplanation 16 섹션 |
| 기존 미사용 상수 보존 (SPEC 정책) | PASS | startSceneBestPlaysSpacing/TopMargin, characterSelectButtonRowOffsetY/Spacing 모두 유지 |

---

## P0 — 치명적 이슈
**없음.**

## P1 — 중요 이슈
**없음.**

## P2 — 권장 사항

### 1. `dotColor`의 `.kim`/`.lee` 동일 색 (가독성)
- **파일**: `Models/CharacterID.swift:83, 87`
- **현상**: `.kim`과 `.lee` 모두 `.ganhoCoralLight`. SPEC §C3 OPEN_QUESTION에 "신규 토큰 `ganhoBlushPink` 추가 — 1건 허용"으로 정책 명시되었으나 Generator는 신규 토큰 도입 0건을 선택.
- **위반 규칙**: 가독성·UX (15%) — 카드 우상단 점의 *시각 변별력* 약화.
- **현재 코드**:
  ```swift
  case .kim:  return .ganhoCoralLight
  case .lee:  return .ganhoCoralLight
  ```
- **수정 제안**: Sprint 후속 작업에서 ColorTokens에 `ganhoBlushPink` 신규 토큰 1건 추가 후 `.lee`만 교체. 본 Sprint 합격에는 영향 없음(SPEC §C3에서 옵셔널 정책으로 명시).

### 2. SkillExplanationScene 메타라벨 좌우 정렬 (UX)
- **파일**: `Scenes/SkillExplanationScene.swift:343, 350-355`
- **현상**: `metaLabel.horizontalAlignmentMode = .center`이며 position `frame.midX + skillExplanationMetaLabelOffsetX(=80)` 중심. mockup의 좌측 정렬 라벨과 미세한 차이.
- **위반 규칙**: 비주얼 일관성 (25%) — mockup §"코랄 메타 라벨"이 좌측 정렬임.
- **수정 제안**: 차후 `horizontalAlignmentMode = .left` 변경 검토. 본 Sprint에서는 시각 일관성 우선이라 미세 갭 허용.

### 3. avatarRoleLabel은 SPEC에서 "role tag"로 명시되었으나 `.tag` 사용
- **파일**: `Scenes/SkillExplanationScene.swift:310`
- **현상**: `avatarRoleLabel.text = characterID.tag` ("번머리 실습생" 등). SPEC §K3은 "role tag(Gowun Dodum)"라고만 명시 → tag 재사용은 합리적 매핑.
- **위반 규칙**: 명세 해석 모호성. P2 권장 — 의도 표기 명확화 위해 주석 1줄 추가.
- **수정 제안**: `// SPEC §K3 — role tag로 CharacterID.tag 재사용 (kim="번머리 실습생" 등)` 주석 1줄로 의도 명시.

---

## 통과 항목

- **빌드**: iPhone 17 시뮬레이터 BUILD SUCCEEDED, Swift compile error/warning 0
- **회귀 가드**: 15개 보호 파일 git diff 0줄 — Sprint 1 인프라, 게임 로직, 저장소, 씬 전환 시그니처, ColorTokens, GameScene/GameScene+Setup/ResultScene 모두 무손상
- **15 조합**: 5 캐릭터 × 3 난이도 컴파일 검증 + 분기 시그니처 모두 일치 (`.kim` 스킵 분기 포함)
- **Swift 패턴**: 강제 언래핑 0 / Timer 0 / 매직 넘버 0 / 하드코딩 hex 0 / weak self 적용 / MARK 구조 + private/internal 가시성 일관
- **SpriteKit 패턴**: didMove + didChangeSize rebuild 패턴 / zPosition 위계(-20/-15/80/90/100/110) / addChild 누적 회피 / 충돌 내 즉시 삭제 0
- **폰트 시스템**: 모든 SKLabelNode `fontName` 명시 — `SKLabelNode(text:)` 4건도 setup에서 `.fontName = GameConfig.font*` 설정
- **Sprint 1 컴포넌트 재사용**: 6 컴포넌트 21건 호출 (GlassPill 4 / Accent 3 / DarkChip 7 / Primary 3 / Back 1 / Gradient.threeStop 3)
- **불변 계약**: SPEC §불변 계약 표(StartScene/CharacterSelectScene/SkillExplanationScene 각 7-9개 항목) 모두 보존
- **mockup 시각 매칭**: 텍스트(타이틀 "김간호는" + "음악박사 ♪", 부제, 헤더, 부제, 컨트롤 힌트, 메타 라벨, 인용 박스 등) 모두 일치

---

## 채점

### 항목별 점수 + 근거

| 카테고리 | 가중치 | 점수 | 근거 |
|---|---:|---:|---|
| **게임 로직 회귀 0** | 40% | **10.0** | OUT 범위 15개 파일 git diff 0줄, 게임 수치/저장소/씬 전환 시그니처 0건 변경. .kim 스킵 분기 보존(CharacterSelectScene.swift:458). 15 조합 컴파일 PASS. SPEC §불변 계약 표 23개 항목 100% 보존. |
| **Swift 패턴** | 20% | **9.5** | 강제 언래핑 0, Timer 0, 매직 넘버 0, 하드코딩 hex 0, weak self 적용 (StartScene.swift:337), MARK 구조(9/14/16). 0.5 감점 — SkillExplanationScene.swift:318의 `String(format: "×%.2f", ...)` 인라인 포맷 문자열은 GameConfig 상수로 빼는 게 더 일관적. |
| **비주얼 일관성** | 25% | **9.0** | Sprint 1 컴포넌트 6종 21건 재사용. 모든 SKLabelNode가 GameConfig.fontDisplay/Body/Numeric. ColorTokens v2 토큰만 사용. mockup 텍스트 100% 일치. 1.0 감점 — `.kim`/`.lee` 동점색(P2#1), metaLabel 정렬 미세 갭(P2#2). |
| **가독성 & UX** | 15% | **9.0** | 컨트롤 힌트 "B" 키 가시(radius 11px 코랄 원), 카드 색 점 8px 가시(radius 4), 인용박스 좌 3px 코랄 보더 가시. AccentLine 헤더 위 +24pt 명시 배치. didChangeSize rebuild 패턴 완비. 1.0 감점 — `.kim`/`.lee` 동점색으로 카드 정체성 변별 약함. |

### 가중 평균 계산
```
0.40 × 10.0 + 0.20 × 9.5 + 0.25 × 9.0 + 0.15 × 9.0
= 4.00 + 1.90 + 2.25 + 1.35
= 9.50 / 10
```

**가중 평균: 9.50 / 10**

---

## 최종 판정: **합격**

- 통과선: 가중 평균 7.5 ↑ → 9.50으로 여유 통과
- 각 카테고리 통과선:
  - 게임 로직 회귀 0 (9.0+) → 10.0 PASS
  - Swift 패턴 (7.0+) → 9.5 PASS
  - 비주얼 일관성 (7.0+) → 9.0 PASS
  - 가독성 & UX (7.0+) → 9.0 PASS

### Sprint 3 진행 가능 여부

**가능.** 본 Sprint 2의 메뉴 3씬 v2 리스킨이 모든 통과선을 넘었고, 게임 로직 회귀 0(완벽), Sprint 1 인프라 무손상, 빌드 PASS, 15 조합 컴파일 검증 통과로 인게임(Sprint 3)으로 진행해도 후행 작업의 기반이 안정적이다.

### Sprint 3 진입 전 권장 정리 (선택)
- P2#1: ColorTokens에 `ganhoBlushPink` 토큰 1건 추가 후 `.lee` dotColor 교체 (시각 변별력 강화). 본 Sprint 2 합격 점수에는 영향 없음.
- P2#2: SkillExplanationScene `metaLabel.horizontalAlignmentMode = .left`로 mockup 정확 매칭 (Sprint 3 별도 작업).
- P2#3: avatarRoleLabel 의도 주석 1줄 추가 (코드 가독성).

세 P2 항목 모두 *합격 점수에 영향 없는 권장 사항*이며 Sprint 3 진행을 막지 않음.

---

**검수 일시**: 2026-05-19
**검수 환경**: macOS Darwin 25.3.0, Xcode 26.x, iPhone 17 Simulator (iOS 26.5 SDK)
**Evaluator**: Sprint 2 QA Agent
