# 자체 점검 — Sprint 2 (메뉴 3씬 v2 리스킨)

전략: Case A (최초 실행) — SPEC 정밀 적용. 게임플레이/저장소/씬 전환 시그니처 0건 변경.

## SPEC 기능 체크

### StartScene
- [x] S1 — 3-stop warm gradient (StartScene.swift:88-99 setupGradientBackground)
- [x] S1 부수: backgroundColor 1프레임 fallback → `.ganhoBgWarmTop` (StartScene.swift:67)
- [x] S2 — overlay 패널 제거: setupOverlayPanel 호출 + 함수 제거 (StartScene.swift 64-72 didMove)
- [x] S3 — Jua 2-라인 타이틀 + AccentLine + Gowun Dodum 태그라인 (StartScene.swift:153-195 setupTitleBlock/layoutTitleBlock)
- [x] S3 — GlowingTitleNode 인스턴스 제거 (StartScene.swift:24-32 Properties)
- [x] S3 — 우측 정렬: horizontalAlignmentMode = .right (StartScene.swift:159, 166)
- [x] S3 — 태그라인 자동 줄바꿈: numberOfLines = 0 + preferredMaxLayoutWidth (StartScene.swift:178-179)
- [x] S4 — BEST/PLAYS → GlassPillNode 2개 (StartScene.swift:130-149 setupStatPills/layoutStatPills)
- [x] S4 — `HighScoreRepository().current`/`StatisticsRepository().current.playCount` 호출 위치 보존 (StartScene.swift:132-133)
- [x] S5 — 시작 버튼 가운데 정렬 유지 (StartScene.swift:227 layoutStartButton — 기존 OffsetY 그대로)
- [x] StartScene transitionToNext 전환 시그니처 보존 (StartScene.swift:287-308)
- [x] `_ = characterRepo` 정적 의존 회피 보존 (StartScene.swift:307)
- [x] 음표 emitter 보존 (StartScene.swift:106-118 setupMusicNoteEmitter)
- [x] 난이도 카드 3장 spring/링 글로우 보존 (StartScene.swift:201-230 setupDifficultyCards/layoutDifficultyCards/selectDifficulty — DifficultyCardNode 내부 변경 0)

### CharacterSelectScene
- [x] C1 — 3-stop warm gradient (CharacterSelectScene.swift:100-114)
- [x] C1 — AccentLine + Jua 헤더 + Gowun Dodum 부제 (CharacterSelectScene.swift:117-151 setupHeader/layoutHeader)
- [x] C2 — 좌상단 GlassPill 뒤로 (CharacterSelectScene.swift:154-188 setupTopBar/layoutTopBar)
- [x] C2 — 우상단 DarkContextChip 난이도 (badge: difficulty.shortName) (CharacterSelectScene.swift:162-167)
- [x] C2 — backButton 인스턴스 제거. backPill 옵셔널로 교체 (CharacterSelectScene.swift:37 backPill?)
- [x] C2 — `backPill?.contains(location) == true` 패턴 (CharacterSelectScene.swift:412)
- [x] C2 — Difficulty.shortName computed property 추가 (Difficulty.swift:47-53)
- [x] C3 — 5장 외곽 글래스 컨테이너 (CharacterSelectScene.swift:191-219 setupCardContainers/layoutCardContainers)
- [x] C3 — 우상단 색 점 5개 (CharacterSelectScene.swift:240-267 setupCardColorDots/layoutCardColorDots)
- [x] C3 — CharacterID.dotColor computed property 추가 (CharacterID.swift:79-89)
- [x] C3 — applyGlassContainerSelection: coral stroke + scale 1.08 + y +12 (CharacterSelectScene.swift:381-409)
- [x] C3 — CharacterCardNode 내부 변경 0 (Nodes/CharacterCardNode.swift git diff 0줄 확인)
- [x] C3 — cardBaseX/cardBaseY 헬퍼 (CharacterSelectScene.swift:347-360)
- [x] C4 — 하단 DarkContextChip 스킬 정보 패널 (CharacterSelectScene.swift:323-342 rebuildSkillInfoPanel/layoutSkillInfoChip)
- [x] C4 — select(_:) 와 didMove에서 rebuildSkillInfoPanel 호출 (CharacterSelectScene.swift:80, 374)
- [x] C5 — confirm 버튼 가운데 정렬, backButton 인스턴스 제거됨 (CharacterSelectScene.swift:311-319 layoutConfirmButton)
- [x] 전환 (뒤로) StartScene + (시작) .kim/스킬 분기 보존 (CharacterSelectScene.swift:438-462 transitionToStart/transitionToNext)

### SkillExplanationScene
- [x] K1 — 3-stop warm gradient + AccentLine 헤더 + Jua + Gowun Dodum 부제 (SkillExplanationScene.swift:141-174)
- [x] K2 — 좌상단 GlassPill "← 캐릭터 다시" (SkillExplanationScene.swift:177-201 setupTopBar)
- [x] K2 — 우상단 DarkContextChip 브레드크럼 (badge "스킬") (SkillExplanationScene.swift:188-194)
- [x] K2 — 하단 BackButtonNode 보존(기능 K6용) (SkillExplanationScene.swift:60-61 backButton 프로퍼티)
- [x] K3 — 좌측 글래스 아바타 카드 (SkillExplanationScene.swift:214-247 setupAvatarCard/setupAvatar)
- [x] K3 — avatarSprite + PixelSpriteRenderer 호출 흐름 보존 (SkillExplanationScene.swift:79-90 init)
- [x] K3 — 코랄 이름 뱃지 (SkillExplanationScene.swift:250-279 setupAvatarNameBadge)
- [x] K3 — role 라벨 + 속도 칩 (SkillExplanationScene.swift:282-307 setupAvatarRoleAndSpeed)
- [x] K4 — 우측 코랄 메타 라벨 (SkillExplanationScene.swift:310-323 setupMetaLabel)
- [x] K4 — Jua 스킬명 (fontDisplay, navyDeep) (SkillExplanationScene.swift:325-339 setupSkillName)
- [x] K4 — 인용 박스 좌 3px 코랄 보더 + 글래스 fill 0.55 (SkillExplanationScene.swift:344-393 setupSkillQuoteBox)
- [x] K4 — `characterID.skill.fullDescription` 호출 보존 (SkillExplanationScene.swift:378)
- [x] K4 — 메타 칩 3개 (CD/범위/즉발) (SkillExplanationScene.swift:396-431 setupStatChips/layoutStatChips)
- [x] K4 — PlayerSkill.rangeText, castText computed property 추가 (PlayerSkill.swift:91-117)
- [x] K4 — StoryBoxNode 인스턴스 제거. 클래스 파일 자체는 유지 (StoryBoxNode.swift 별도 파일 git diff 0)
- [x] K5 — 컨트롤 힌트 다크 컨테이너 + 코랄 "B" 원 + 라벨 (SkillExplanationScene.swift:434-477 setupControlHint/layoutControlHint)
- [x] K5 — controlHintLabel 프로퍼티 유지 (SkillExplanationScene.swift:57)
- [x] K6 — 하단 BackButton + PrimaryButton 좌우 배치 (SkillExplanationScene.swift:480-489 setupButtons/layoutButtons — characterSelectButtonSpacing 재사용)

## 모델 변경 (Sprint 2 신규 computed property)
- [x] Difficulty.shortName (Difficulty.swift:47-53) — "하"/"중"/"상"
- [x] PlayerSkill.rangeText (PlayerSkill.swift:91-100) — "3타일"/"6타일"/"전역"/"최원거리"
- [x] PlayerSkill.castText (PlayerSkill.swift:104-117) — duration 0 → "즉발", 그 외 → "N초"
- [x] CharacterID.dotColor (CharacterID.swift:79-89) — coralLight/scrubMint/lavenderSoft/musicGold/coralLight

## GameConfig 신규 상수 (Sprint 2)
- [x] StartScene v2: startSceneTitleLine1FontSize(44), Line2FontSize(56), TaglineFontSize(13), TaglineMaxWidth(240), TitleBlockRightMargin(64), TitleBlockOffsetY(60), TitleLineSpacing(58), AccentLineAboveTitleOffset(36), TaglineBelowTitleOffset(-48), StatPillWidth(96), StatPillHeight(28), StatPillSideMargin(60), StatPillTopMargin(30) — GameConfig.swift:1170-1196
- [x] CharacterSelect v2: HeaderSubFontSize(12), HeaderSubText, HeaderSubOffsetY(-22), AccentLineOffsetY(24), BackPillText/Width(120)/Height(28), DifficultyChipLabel, TopBarMarginX(40)/MarginY(30), CardGlassWidth(110)/Height(140)/CornerRadius(18)/FillAlpha(0.65), ColorDotRadius(4)/InsetX(14)/InsetY(14), GlassSelectedScale(1.08)/YOffset(12)/StrokeWidth(2)/ScaleDuration(0.18), SkillInfoOffsetY(-100), ConfirmButtonOffsetY(-180) — GameConfig.swift:1198-1247
- [x] SkillExplanation v2: HeaderSubText/FontSize(12), AccentLineOffsetY(24), HeaderSubOffsetY(-22), BackPillText/Width(130)/Height(28), BreadcrumbBadge("스킬"), TopBarMarginX(40)/MarginY(30), AvatarCardWidth(180)/Height(200)/CornerRadius(24)/FillAlpha(0.85)/StrokeAlpha(0.3)/StrokeWidth(2), CardOffsetX(-180)/Y(0), NameBadgeOffsetY(90)/FontSize(12)/Width(80)/Height(24), RoleOffsetY(-110)/FontSize(11), SpeedChipOffsetY(-130), MetaLabelFontSize(11)/OffsetX(80)/OffsetY(120), QuoteBoxWidth(300)/Height(80)/CornerRadius(14)/FillAlpha(0.55)/BorderWidth(3)/FontSize(14)/HorizontalPadding(28)/OffsetY(0), StatChipSpacing(8)/RowOffsetY(-60), ControlHintContainerWidth(280)/Height(32)/FillAlpha(0.92), KeyCircleRadius(11)/KeyFontSize(12), LabelFontSize(12), HorizontalPadding(14), KeySpacing(10), ContainerOffsetY(-120) — GameConfig.swift:1249-1314

## Swift 패턴 준수
- 강제 언래핑 미사용: ✅ (grep `! ` 결과 0건, 모든 옵셔널은 `if let`/`guard let`/`?.contains == true` 패턴)
- guard let 옵셔널 처리: ✅ (transitionToStart/transitionToNext/transitionToGame guard let view)
- Timer 미사용: ✅ (grep `Timer.` 결과 0건)
- 매직 넘버 미사용: ✅ (모든 좌표/크기/duration이 GameConfig 상수)
- MARK 섹션 구분: ✅ (Properties / Factory / Init / Lifecycle / Setup (Sprint 2 · X) / Touch 등)
- weak self 캡처: ✅ (StartScene.transitionToNext SKAction.run [weak self, weak view])
- 하드코딩 hex 0건: ✅ (모든 색은 ColorTokens — `.ganhoNavyDeep`, `.ganhoCoralPrimary`, `.ganhoNavyMuted`, `.ganhoBgWarmTop` 등)
- SKLabelNode fontName 시스템 폰트 0건: ✅ (모든 라벨이 `SKLabelNode(fontNamed: GameConfig.font*)` 또는 setupX에서 `.fontName = GameConfig.font*` 명시 설정)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: ✅
- didChangeSize(_:)에서 layout + rebuild: ✅
- addChild 누적 회피: ✅ (rebuildGradientBackground, rebuildSkillInfoPanel — 기존 노드 removeFromParent 후 재생성)
- zPosition 위계: ✅
  - 그라데이션: -20 (GradientBackgroundNode 내부 상수)
  - musicNoteEmitter: -15 (MusicNoteEmitterNode 내부)
  - 헤더/AccentLine/태그라인: 4~10 (기본)
  - 글래스 컨테이너: 90
  - 카드/PrimaryButton: 100
  - 색 점/태그 라벨/이름 뱃지/속도 칩: 110+
- 충돌 후 노드 즉시 삭제 없음: ✅ (게임 로직 미변경)
- HUD 노드 분리: ✅ (메뉴 씬은 카메라 없음, 모든 노드 frame.midX/midY 기준 직접 배치)

## 불변 계약 보존 (SPEC §불변 계약 표)

### StartScene
- [x] Factory `class func newStartScene() -> StartScene`, `scaleMode = .resizeFill` (StartScene.swift:62-65)
- [x] 초기화 `didMove(to:)` 진입점, `selectedDifficulty = difficultyRepo.current` 복원 (StartScene.swift:71)
- [x] touchesBegan 우선순위: 난이도 카드 → 시작 버튼 (StartScene.swift:270-284)
- [x] selectDifficulty 내 `difficultyRepo.save(id)` (StartScene.swift:224)
- [x] transitionToNext → `CharacterSelectScene.newCharacterSelectScene(difficulty:)` + `SKTransition.fade(...sceneTransitionDuration)` (StartScene.swift:300-304)
- [x] isTransitioning guard 그대로 (StartScene.swift:271)
- [x] BEST/PLAYS 저장소 호출 위치·시점 (StartScene.swift:132-133 setupStatPills)
- [x] DifficultyCardNode×3 + setSelected + spring/링 글로우 (DifficultyCardNode.swift 미변경)
- [x] `_ = characterRepo` 보존 (StartScene.swift:307)

### CharacterSelectScene
- [x] Factory + private init + required init? coder (CharacterSelectScene.swift:55-76)
- [x] selectedCharacterID = preferenceRepo.current 복원 (CharacterSelectScene.swift:79)
- [x] touchesBegan 우선순위: 카드 → 뒤로 → confirm (CharacterSelectScene.swift:401-426)
- [x] select(_:) 내 preferenceRepo.save (CharacterSelectScene.swift:367)
- [x] CharacterCardNode×5 + setSelected — 내부 변경 0 (CharacterCardNode.swift git diff 0)
- [x] 카드 5장 가로 정렬 좌표식 그대로 (cardBaseX는 동일 식: startX + index*(width+spacing))
- [x] 전환 (뒤로) StartScene + (시작 .kim → GameScene / 외 → SkillExplanation) (CharacterSelectScene.swift:438-462)
- [x] difficulty: let 불변 (CharacterSelectScene.swift:23)

### SkillExplanationScene
- [x] Factory + private init + required init? coder (SkillExplanationScene.swift:65-100)
- [x] 큰 아바타 PixelSprite.data + PixelPalette.palette + PixelSpriteRenderer.texture 흐름 (SkillExplanationScene.swift:82-90)
- [x] 스킬 본문 텍스트 출처 `characterID.skill.fullDescription` 보존 (SkillExplanationScene.swift:378)
- [x] touchesBegan: 뒤로(GlassPill+BackButton 둘 다) → 시작 (SkillExplanationScene.swift:495-510)
- [x] 전환 (뒤로) → CharacterSelectScene + (시작) → GameScene (SkillExplanationScene.swift:513-531)

## Sprint 1 인프라 보존 (내부 변경 0)
- [x] GlassPillNode.swift — git diff 0줄
- [x] AccentLineNode.swift — git diff 0줄
- [x] DarkContextChipNode.swift — git diff 0줄
- [x] PrimaryButtonNode.swift — git diff 0줄
- [x] BackButtonNode.swift — git diff 0줄
- [x] GradientBackgroundNode.swift — git diff 0줄

## OUT-of-scope 파일 (git diff 0줄 검증)
- [x] GanhoMusic Shared/GameScene.swift — 0줄
- [x] GanhoMusic Shared/GameScene+Setup.swift — 0줄
- [x] GanhoMusic Shared/Scenes/ResultScene.swift — 0줄
- [x] ColorTokens.swift — 0줄 (Sprint 1의 ganhoAccentTeal/Coral/v2 토큰 모두 유지)
- [x] CharacterCardNode.swift / DifficultyCardNode.swift — 0줄 (내부 변경 0 정책)
- [x] StoryBoxNode.swift / GlowingTitleNode.swift — 0줄 (인스턴스만 제거, 클래스 파일 유지)
- [x] MusicNoteEmitterNode.swift — 0줄

## 빌드 상태
- xcodebuild iPhone 17 시뮬레이터 (iOS 26.5 SDK / iOS 16.6 target) — **BUILD SUCCEEDED**
- 예상 빌드 에러: 없음
- 새 경고: 없음 (기존 duplicate Font 빌드 페이즈 경고만 — 본 Sprint 무관)

## 15 조합 시작 가능 여부
- StartScene → CharacterSelectScene 시그니처 보존: `newCharacterSelectScene(difficulty:)` (StartScene.swift:301)
- CharacterSelectScene → GameScene .kim 직진 (5 캐릭터 × 3 난이도 중 3 조합) — `GameScene.newGameScene(characterID:difficulty:)` (CharacterSelectScene.swift:451)
- CharacterSelectScene → SkillExplanationScene .jung/.geon/.im/.lee × 3 난이도 (12 조합) — `SkillExplanationScene.newSkillExplanationScene(characterID:difficulty:)` (CharacterSelectScene.swift:457)
- SkillExplanationScene → GameScene (시작) — `GameScene.newGameScene(characterID:difficulty:)` (SkillExplanationScene.swift:526)
- SkillExplanationScene → CharacterSelectScene (뒤로) — `CharacterSelectScene.newCharacterSelectScene(difficulty:)` (SkillExplanationScene.swift:518)
- 총 5×3=15 조합 모두 시그니처/타입 일치 — 컴파일 SUCCESS로 검증됨

## 범위 외 미구현 항목
- 없음 — SPEC §IN 항목 모두 구현, §OUT 항목 0건 변경.

## 필수 연동 변경
- 없음 — Sprint 2는 메뉴 3씬 + GameConfig + 3 모델 computed property만 변경. 게임 로직/저장소/씬 전환 시그니처 0건 변경. Sprint 1 인프라 내부 변경 0건.
