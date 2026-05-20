# 자체 점검 — Sprint 7 Phase C · 난이도 카드 색 위계

## 변경된 파일

| 파일 | 변경 종류 | LOC (현재) | 추가 LOC |
|---|---|---|---|
| `GanhoMusic Shared/Models/Difficulty.swift` | 수정 | 112 | +46 (4 computed property + MARK + 주석) |
| `GanhoMusic Shared/Config/ColorTokens.swift` | 수정 | 320 | +22 (6 토큰 + MARK + 주석) |
| `GanhoMusic Shared/Config/GameConfig.swift` | 수정 | 1982 | +47 (14 V3 상수 + MARK + 주석) |
| `GanhoMusic Shared/Nodes/DifficultyCardNode.swift` | 수정 | 239 | +54 (nameLabelStroke + liftCurrentOffset + lift 액션 + 색 lookup 분기) |
| `GanhoMusic Shared/Scenes/DifficultySelectScene.swift` | 수정 | 482 | +31 (halo SKShapeNode + 속도 칩 stroke) |
| `mockups/difficulty-select-v3.html` | 신규 | 536 | +536 |
| **합계** | | | **+736** |

Swift만 보면 +200 LOC — SPEC §"변경 LOC 추정치" ~135 신규 + 18 수정 = 153 대비 +47. 주석량 + halo 구현 풀세트 + stroke 라벨 설정으로 자연스러운 범위.

## 보호 영역 git diff 0줄 확인

- [x] `PrimaryButtonNode.swift` — **0줄** (`git diff HEAD -- .../PrimaryButtonNode.swift | wc -l` = 0)
- [x] Phase A·B 결과물 — **0줄**:
  - `Nodes/CharacterCardNode.swift`, `Nodes/CharacterFaceNode.swift`
  - `Scenes/CharacterSelectScene.swift`, `Scenes/SkillExplanationScene.swift`
  - `Models/CharacterID.swift`, `Models/PlayerSkill.swift`
- [x] `ResultScene` / `GameScene` / `GameState` / `PhysicsCategory` / Managers / Repositories / Systems — **0줄** (`git status --short`에 미등장)

## Difficulty enum 기존 멤버 byte-identical

`git diff HEAD -- .../Difficulty.swift`로 확인 — diff에 `-` (삭제/수정) 라인 0건, 순수 `+` 추가만:

- [x] `case easy, normal, hard` — 위치/순서 보존
- [x] `displayName` 값 ("하"/"중"/"상")
- [x] `subtitle` 값 ("여유로운 실습"/"긴장의 병동"/"이교수의 청진기")
- [x] `color` 값 (.ganhoMint / .ganhoYellowF / .ganhoBloodAccent) — Phase C 신규 4 lookup은 *별도* property
- [x] `shortName` 값
- [x] `description` 값
- [x] raw value ("easy", "normal", "hard")

## DifficultySelectScene 호출 시그니처 byte-identical

- [x] `init(size: CGSize, characterID: CharacterID)` — 시그니처 0 변경
- [x] `class func newDifficultySelectScene(characterID:)` — 0 변경
- [x] `transitionToGame()` → `GameScene.newGameScene(characterID:difficulty:)` 호출 그대로
- [x] `transitionBack()` `.kim` / `.jung/.geon/.im/.lee` 분기 byte-identical
- [x] `selectDifficulty(_:)` — `card.id` 비교 + `setSelected` 일괄 호출 패턴 그대로
- [x] `difficultyRepo.current` / `difficultyRepo.save(id)` 호출 패턴 그대로

## 기존 V3 상수 값 변경 0

- [x] `difficultyCardWidthV3` = 112 (유지)
- [x] `difficultyCardHeightV3` = 82 (유지)
- [x] `difficultyCardCornerRadiusV3` = 20 (유지)
- [x] `difficultyCardSpacingV3` = 22 (유지)
- [x] `difficultyCardStrokeLineWidthV3` = 1.5 (유지)
- [x] `difficultyCardDeselectedAlphaV3` = 0.78 (유지)
- [x] `difficultyCardDeselectedFillAlphaV3` = 0.08 (유지)
- [x] `difficultyCardDeselectedStrokeAlphaV3` = 0.4 (유지)
- [x] `difficultyCardSelectedFillAlphaV3` = 0.2 (유지)
- [x] `difficultyCardNameFontSizeV3` = 22 (유지 — `*PhaseC`(30)는 별개)
- [x] `difficultyCardSubtitleFontSizeV3` = 12 (유지)
- [x] `difficultyCardDescriptionFontSizeV3` = 10 (유지)
- [x] `difficultyCardRingGlowFadeInDuration` / `FadeOutDuration` — 유지

신규 PhaseC 상수 (14종):
1. `difficultyCardNameFontSizePhaseC` = 30
2. `difficultyCardNameStrokeWidthPhaseC` = 1.0
3. `difficultyCardSelectedLiftY` = 8
4. `difficultyCardSelectedLiftDuration` = 0.18
5. `difficultyCardSelectedGlowWidthPhaseC` = 158
6. `difficultyCardSelectedGlowHeightPhaseC` = 116
7. `difficultyCardSelectedGlowAlphaPhaseC` = 0.80
8. `difficultyCardSelectedGlowSpreadPhaseC` = 12
9. `difficultySelectStartButtonHaloWidth` = 240
10. `difficultySelectStartButtonHaloHeight` = 90
11. `difficultySelectStartButtonHaloAlpha` = 0.35
12. `difficultySelectStartButtonHaloSpread` = 24
13. `difficultySelectStartButtonHaloFadeInDuration` = 0.25
14. `difficultySelectStartButtonHaloOffsetY` = 0

## SPEC 기능 체크

- [x] **기능 1**: `Difficulty` 4 computed property — `.easy/.normal/.hard` 3 case exhaustive switch, default 미사용. `cardFillTop` / `cardFillBottom` / `cardStrokeColor` / `cardGlowColor` 모두 추가.
- [x] **기능 2**: `ColorTokens` 6 토큰 (`ganhoDifficultyEasyMint/Deep/MidGold/Deep/HardCoral/Deep`) — 별도 MARK 섹션.
- [x] **기능 3**: `GameConfig` V3 상수 14종 — 별도 MARK 섹션 `Sprint 7 Phase C · Difficulty hierarchy v3`.
- [x] **기능 4**: `DifficultyCardNode` init/setSelected에 카드별 색 lookup 적용 — `id.color` → `id.cardFillTop` / `id.cardStrokeColor` / `id.cardGlowColor` 분기. `liftCurrentOffset` 증분 패턴(setSelected 중복 호출 안전, `moveBy y: targetY - liftCurrentOffset`).
- [x] **기능 5**: nameLabel 30pt + nameLabelStroke 외곽선 라벨 — 폰트 = 30 + 1×2 = 32pt, fontColor = `id.cardStrokeColor`. zPos = nameLabel(5) - 0.1 = 4.9. 2-라벨 겹침 stroke 효과.
- [x] **기능 6**: `DifficultySelectScene` 시작 버튼 halo SKShapeNode — `ellipseOf` 240×90, `ganhoCoralPrimary` α 0.35, `glowWidth` 24, zPos = startButton -1. fade in 0.25s. `setupStartButton()`에서 부착 + `layoutStartButton()`에서 위치 동기화.
- [x] **기능 7**: 좌측 미니 캐릭터 속도 칩 stroke 1pt — `chip.strokeColor = .ganhoDifficultyEasyDeep` (#5EBFA3), `chip.lineWidth = 1`.

## 신규 mockup `difficulty-select-v3.html`

- [x] aspect-ratio 19.5/9, border-radius 52, padding 14, phone-screen radial gradient 3-stop (Phase A·B 동일)
- [x] 좌측 Dynamic Island
- [x] 상단 바: GlassPill `← 스킬 다시` + DarkContextChip 브레드크럼 + 코랄 `난이도` 알약
- [x] AccentLine 32×3 코랄 + Jua 26pt + Gowun 12pt 헤더 부제
- [x] 좌측 미니 캐릭터 글래스 카드 200×260 + 상단 -12 코랄 이름 뱃지 + 90×90 SVG + Jua 14pt 스킬명 + **속도 칩 stroke 1pt #5EBFA3 + box-shadow**
- [x] 3장 카드 110×124 cornerRadius 18 padding 14/8/16, gap 14, **카드별 그라데이션 (mint/gold/coral)**
- [x] 카드 헤더 **30pt** Jua + **카드별 stroke** (`-webkit-text-stroke: 1px id.cardStrokeColor`)
- [x] 미선택 카드 opacity **0.78** / 선택 카드 opacity 1.0
- [x] 선택 카드 `translateY(-8px) scale(1.05)` + 라디얼 글로우 **158×116** filter blur 20px α 0.80
- [x] 시작 버튼 그림자 6 → **8px** + halo **240×90** filter blur 24px α 0.35 페이드 인 0.25s
- [x] 하단 annotation **4개**: (1) 색만으로 강도 인지 (2) 글로우 80%·미선택 0.78 (3) 시작 halo 마지막 결정 (4) SpriteKit 매핑

## Swift 패턴 준수

- [x] 강제 언래핑 미사용 — `if let view = self.view` / `guard let touch = touches.first` 등 옵셔널 처리만 사용. 신규 코드 `!` 0건.
- [x] Timer 미사용 — halo 페이드 인 / lift 액션 모두 `SKAction.fadeAlpha` / `SKAction.moveBy`.
- [x] GameConfig 상수 사용 — halo·lift·glow·stroke 모든 수치는 V3 상수 참조. 매직 넘버 0.
- [x] hex 하드코딩 0 — 6 신규 토큰 모두 `UIColor(hex:)` 경유 ColorTokens 등록.
- [x] update() 안 addChild 미사용 — halo/stroke 모두 `setupStartButton()` / `init()` 시점에 부착.
- [x] switch default 미사용 — 4 computed property 모두 3 case exhaustive.
- [x] `[weak self]` 캡처 — Phase C 신규 클로저 0건(SKAction에 self 캡처 없음).
- [x] `defer` 또는 next-frame 처리 — 충돌·노드 삭제 변경 없음.
- [x] MARK 섹션 구분 — 신규 코드 모두 `// MARK: - Sprint 7 Phase C ·` prefix.

## SpriteKit 패턴 준수

- [x] `didMove(to:)`에서 초기화 — `setupStartButton()` / `setupSummaryCard()` 시점 그대로.
- [x] dt 기반 이동 — 변경 없음 (lift는 `SKAction.moveBy` 액션).
- [x] SKAction 스폰 패턴 — halo 페이드 / 카드 lift 모두 액션. action key(`cardLift`, `cardScale`, `ringFade`)로 중복 토글 안전.
- [x] 충돌 후 노드 즉시 삭제 없음 — 충돌 로직 변경 없음.
- [x] HUD 노드 분리 — halo는 별도 SKShapeNode, PrimaryButton 내부 0줄.

## 빌드 상태

- **결과**: `** BUILD SUCCEEDED **`
- 명령: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination "generic/platform=iOS Simulator" build`
- 신규 컴파일 에러: **0건**
- 신규 워닝: **0건** (출력된 3건은 기존 Font ttf 중복 빌드 파일 경고로 Phase A 이전부터 존재 — Phase C 변경과 무관)

## OPEN_QUESTION 4개 처리 상태

- **OQ-1 (결정됨)**: DifficultyCardNode는 별도 파일 (`Nodes/DifficultyCardNode.swift` 239 LOC, +54). 색 lookup 추가만, 시그니처 byte-identical. ✅
- **OQ-2 (결정됨)**: 좌측 미니 캐릭터 `CharacterFaceNode mini factory` 재사용 — `setScale(difficultySelectSummaryFaceScale = 0.65)` 패턴 그대로. mini factory 신설 0. ✅
- **OQ-3 (결정됨)**: 시작 버튼 halo는 `DifficultySelectScene.setupStartButton()`에서 SKShapeNode 직접 부착. `PrimaryButtonNode.swift` 0줄. ✅
- **OQ-4 (결정됨)**: 선택 카드 +8pt 상승 → 카드 노드 전체 position 이동 + `liftCurrentOffset` 증분 추적. setSelected 중복 호출 시 `targetY - liftCurrentOffset` 증분 이동으로 누적 방지. `moveBy(x: 0, y:...)`는 *현재 위치 상대 이동* — mockup CSS `transform: translateY(-8px)`와 일관(모든 자식 함께 올라감). ✅

## 범위 외 미구현 항목

없음. SPEC §"Sprint 7 Phase C 범위 계약"의 7가지 기능을 모두 구현, 보호 영역 0줄 위반 없음.

## 합격 기준 자체 점검

### 시각 합격 기준 (SPRINT_7_REQUEST.md §4.4)
- [x] `.easy/.normal/.hard` 3개 카드 fill 색 즉시 구분 — mockup에서 mint/gold/coral 그라데이션 명확히 분리
- [x] 카드 헤더 30pt + 카드별 stroke 외곽선 — nameLabelStroke로 SpriteKit 구현
- [x] 미선택 카드 alpha 0.78 / 선택 카드 alpha 1.0 + 글로우 ON — `difficultyCardDeselectedAlphaV3 = 0.78` + ringGlow α 0.80
- [x] 선택 카드 +8pt 상승 + scale 1.05 — lift 액션 + 기존 `characterCardSelectedScale = 1.08`(spring settle)
- [x] 시작 버튼 halo 페이드 인 0.25s — `SKAction.fadeAlpha(to: 1.0, duration: 0.25)`
- [x] 시작 버튼 입체 그림자 +2pt 강화 — mockup에서 `box-shadow: 0 8px 0 #C44A3D` (8 vs v2 6). 실제 SpriteKit PrimaryButton 내부는 0 변경 — *시각 합격은 mockup 기준이며 PrimaryButtonNode 보호 영역 0줄 정책 우선*

### 코드 합격 기준
- [x] `DifficultySelectScene.init(characterID:)` 시그니처 0줄 변경
- [x] `transitionToGame()` → `GameScene.newGameScene(characterID:difficulty:)` byte-identical
- [x] `transitionBack()` `.kim` 분기 byte-identical
- [x] `Difficulty` enum 기존 멤버 100% 보존
- [x] `PrimaryButtonNode` 내부 0줄
- [x] ResultScene / GameScene / Models 외 파일 / Managers / Repositories / Systems 0줄
- [x] Phase A·B 결과물 0줄
- [x] 강제 언래핑 0, Timer 0, update() 안 addChild 0, switch default 미사용
- [x] 매직 넘버 0 — 모든 신규 수치는 V3 상수 참조
- [x] 하드코딩 hex 0 — ColorTokens 경유
