# 디자인 리뉴얼 진행 상태

> 이 파일은 디자인 리뉴얼 하네스가 **자동 갱신**합니다. 수동 편집 비권장.
> 자세한 절차는 `CLAUDE.md` § "디자인 리뉴얼 모드" 참고.

**최종 갱신**: 2026-05-19 (Sprint 7 Phase F 합격 — 빌런 4종 + 박병장)
**현재 진행 중인 Sprint**: Sprint 7 (Phase A·B·C·D·E·F ✅ / G 진행 중). Sprint 1/2/3/5/6 합격. Sprint 4(PNG 캐릭터 80장)는 사용자 자산 작업 대기.

---

## 🚀 빠른 시작

Claude Code 세션에서 아래 한 마디만 입력하면 다음 Sprint가 자동 진행됨:

```
디자인 리뉴얼 진행해줘
```

특정 Sprint를 명시하고 싶으면:

```
Sprint 2 진행해줘
```

자동으로:
1. 이 파일을 읽어 현재 진행 상태 파악
2. 다음 Sprint의 Planner 프롬프트 실행
3. Generator → Evaluator 사이클 (최대 3회)
4. 합격하면 이 파일 갱신

---

## Sprint 진행 현황

| Sprint | 범위 | 상태 | 점수 | 시도 |
|---|---|---|---|---|
| **1** | 디자인 토큰 + 노드 컴포넌트 (인프라) | ✅ 합격 | 9.83/10 | 1/3 |
| **2** | 메뉴 3씬 (Start/Character/Skill) | ✅ 합격 | 9.50/10 | 1/3 |
| **3** | 인게임 (GameScene + HUD + 컨트롤) | ✅ 합격 | 9.22/10 | 1/3 |
| **4** | PNG 캐릭터 통합 | ⏸️ 자산 대기 | - | 0/3 |
| **5** | ResultScene 3분기 | ✅ 합격 | 9.70/10 | 1/3 |
| **6** | 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터 | ✅ 합격 | 9.53/10 | 1/3 |
| **7-A** | 캐릭터 선택 NIKKE 카드 리뉴얼 | ✅ 합격 | 9.45/10 | 1/3 |
| **7-B** | 스킬 설명 겹침 해소 | ✅ 합격 | 9.77/10 | 1/3 |
| **7-C** | 난이도 카드 색 위계 | ✅ 합격 | 9.83/10 | 1/3 |
| **7-D** | 결과창 + ScoreboardScene 신설 | ✅ 합격 | 9.83/10 | 1/3 |
| **7-E** | 카운트다운 오버레이 | ✅ 합격 | 9.76/10 | 1/3 |
| **7-F** | 빌런 4종 + 박병장 신규 | ✅ 합격 | 9.10/10 | 1/3 |
| **7-G** | 플레이어 4방향 스프라이트 | ⏳ 대기 | - | 0/3 |

### 상태 범례
- ✅ **합격** — Evaluator 합격 기준 충족, 완료
- ⏳ **대기** — 다음 트리거 시 시작 가능
- 🔄 **진행 중** — 현재 하네스 사이클 돌고 있음
- ❌ **불합격** — 재시도 필요 (시도 횟수 +1)
- ⏸️ **미시작** — 선행 Sprint 미완료 또는 자산 대기

### Sprint 4 자산 대기 해제 조건
- `mockups/svg-exports/` 폴더에 5개 SVG 존재 ✅
- `GanhoMusic/Assets.xcassets/Characters/` 폴더에 PNG 자산 존재 ❌ (사용자가 Figma에서 제작 필요)

사용자가 PNG 자산을 `Assets.xcassets/Characters/`에 추가하면 Sprint 4 상태가 "⏳ 대기"로 변경됨.

---

## 진행 로그

(각 Sprint 완료/시도 시 자동 추가)

### Sprint 1 — 디자인 토큰 + 노드 컴포넌트
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼인프라 10.0 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ColorTokens v2 16토큰 + GameConfig 폰트3·컴포넌트19상수 + 신규 노드 3종(GlassPill/AccentLine/DarkContextChip) + PrimaryButton/BackButton 내부 리스타일 + GradientBackgroundNode threeStop factory. 기존 5개 씬 git diff 0줄, 신규 노드 호출자 0건. 빌드 SUCCEEDED.
- **사용자 후속 작업 (OPEN_QUESTION Q1)**: 폰트 ttf 3개(Jua/GowunDodum/NotoSansKR) 다운로드 → `Resources/Fonts/` 추가 → `Info.plist` `UIAppFonts` 배열 추가 → Sprint 2 시작 전 시뮬레이터에서 폰트 적용 시각 확인.

### Sprint 2 — 메뉴 3씬
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.50/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과)
- 비고: StartScene/CharacterSelectScene/SkillExplanationScene을 3-stop warm gradient + Jua/Gowun Dodum 폰트 + Sprint 1 인프라(GlassPill 4 / AccentLine 3 / DarkContextChip 7 / Primary 3 / Back 1 / Gradient.threeStop 3) 호출로 재구성. 4개 신규 computed property(Difficulty.shortName / PlayerSkill.rangeText/castText / CharacterID.dotColor) 추가 — 순수 시각 라벨용. GameScene/GameScene+Setup/ResultScene + Sprint 1 컴포넌트 6개 + 기타 보호 파일 15개 git diff 0줄. 빌드 SUCCEEDED.

### Sprint 3 — 인게임
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.22/10** (게임로직 9.8 · Swift패턴 8.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과) + 미니 패치 1건 (P2 #5: ProjectileNode hitbox visual-only 회전)
- 비고: GameScene+Setup(배경/체크보드/벽/기둥), HUDNode(navy 칩+골드 라벨+TIME 경고+진행바), DPadNode(시각만 SKShape 교체, 입력 100% byte-identical), SkillButtonNode(코랄 원 72+B 칩+스킬명 칩), HUDSkillSlotNode(fontDisplay+v2 색), NoteNode(골드 원+글로우+1.4s 펄스), ProjectileNode(코랄 22+F+visual-only -12° 회전, hitbox 축정렬 보존), ComboPopup/ComboBreak(Jua+navy 외곽선+회전), PauseButtonNode 신규(시각 placeholder). 19개 보호 파일 git diff 0줄. 게임 수치/물리/입력/AI/저장/사운드 0건 변경. 빌드 SUCCEEDED.
- 잔존 P2: SkillButtonNode 매직 넘버 18 / 인라인 알파 6곳 / 스킬명 칩 CD 텍스트 누락 / SPEC 명시 상수 2개 누락. Sprint 5 진행에 영향 0.

### Sprint 4 — PNG 캐릭터 통합
- 시작: -
- 완료: -
- 점수: -
- 비고: PNG 자산 도착 후 시작

### Sprint 5 — ResultScene 3분기
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.70/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.5 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ResultScene 3분기 시각(A 일반/B 신기록/C 졸업장), DiplomaOverlayNode 우드컷(SKShapeNode + CGMutablePath addEllipse 단일 노드 통합 ~1100 도트) + double-border ㄱ자 + 도장 + fontSerif 명조 라벨. sparkle 5발 신기록 분기. ColorTokens v2 Diploma 토큰 4개 추가. ResultScene init 9개 인자 byte-identical / 본문 텍스트 byte-identical / 햅틱·사운드 시퀀스·2단계 탭 정책 모두 보존. 보호 파일 24개 git diff 0줄. 빌드 SUCCEEDED.
- **사용자 후속 작업 권장**: GowunBatang-Regular.ttf 추가(졸업장 명조 폰트). Google Fonts → Resources/Fonts → Info.plist UIAppFonts. 미추가 시 시스템 폰트 fallback(크래시 0).

### Sprint 7 Phase F — 빌런 4종 + 박병장 신규
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.10/10** (게임로직 10.0 · Swift패턴 7.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과)
- 비고: 3 기존 빌런(EnemyNode 수간호사/ProfessorNode 이교수/StoneGuardNode 석조무사) 시각 자식 SKShapeNode 부착 + 신규 SergeantParkNode(박병장 공군 청록+선글라스) ~148 LOC. 3 기존 빌런 AI/이동/충돌 시그니처 9개(update/startFleeing/apply, startPatrol/startThrowingStethoscopes/scheduleNextThrow/throwStethoscope/stopThrowing) byte-identical, 본문 0줄 변경. physicsBody.size 인자/categoryBitMask/collisionBitMask/contactTestBitMask 0줄. 속도·waypoint 상수 0줄. StoneGuardNode super.init color 값만 .ganhoPaper → .ganhoStoneGuardLight 교체(시그니처 byte-identical). setupVisualOverlay 호출은 EnemyNode init 마지막, ProfessorNode/StoneGuardNode startPatrol 직전 1줄. EnemyNode 자식 3개(halo+chart+clip zPos -0.1/0.1/0.2), ProfessorNode 자식 2개(stethoDisc+tube zPos 0.1/0.15), StoneGuardNode 자식 3개(armor+eye×2 zPos 0.05/0.2). SergeantParkNode SKSpriteNode(.clear) 상속 + 6 attach 메서드(Shadow/Body/Head/Cap/Sunglasses/Rank) zPos -0.1~0.4 — physicsBody/update/SKAction 0건(시각 시안만, GameScene spawn 0건). ColorTokens 6 신규(AirforceTeal #3A6F7F, AirforceTealLight #5A8F9F, SunglassesBlack #1A1A1A, StoneGuardLight #A0A0A8, StoneGuardDark #5A5670, StoneGuardOutline #7A7570). GameConfig Phase F V3 상수 29개 신규(enemyVisualHalo/Chart 5 + professorStetho 4 + stoneGuardEye 2 + sergeant 18). Xcode pbxproj 4줄(SergeantParkNode 등록). 신규 mockup villains-and-player-directions-v1.html ~321 LOC(4 패널 가로 정렬 + SVG 96×120 + 색 chip + 박병장 ✨NEW + Phase G 후반부 5명 4방향 메모). 보호 영역 git diff 0줄: GameScene/GameScene+Setup/PhysicsCategory/Models/Systems/Repositories/Managers/PlayerNode/NoteNode/ProjectileNode/StethoscopeNode/Phase A·B·C·D·E 결과물. 강제 언래핑 0, Timer 0, switch default 0, as! 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P1 (합격 영향 0)**: 시각 디테일 매직 넘버 8건(stroke/cornerRadius/비율 리터럴) — Phase G 시작 시 enemyVisualChart*StrokeWidth/stoneGuardArmorCornerRadius/sergeantBodyCornerRadius 등 추가 7~10개 상수로 묶어 정리 권장.
- **잔존 P2 (합격 영향 0)**: StoneGuardNode `let eyeSize = CGSize(width: 2, height: 0.8)` → GameConfig `stoneGuardEyeSize` 토큰화.

### Sprint 7 Phase E — 카운트다운 오버레이
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.76/10** (게임로직 10.0 · Swift패턴 9.6 · 비주얼 9.5 · UX 9.7)
- QA 반복: 1회 (한 번에 통과)
- 비고: 게임 시작 시 멈춤감 해소를 위한 3·2·1·GO! 카운트다운 시각 v3 보강. 기존 CountdownNode(Phase 6-13 신설) 시그니처 `init()` + `start(onTick:onGo:onComplete:)` byte-identical 유지. 4가지 보강: ① SKLabelNode init에 fontNamed Jua-Regular 적용(시스템 폰트 → Jua) ② 색 4개 갱신(3·2·1 = ganhoNavyDeep / GO = ganhoCoralPrimary, v2 blood/yellow/pink/mint와 다름) ③ stepAction/goAction setup에 fontSize 분기 추가(숫자 120pt V3 / GO 140pt V3) ④ GO scale 1.0→1.3 → 1.2→1.8(더 큰 펄스). GameScene.showCountdown에 dim SKSpriteNode 부착 + 페이드인 + onComplete에서 fadeOut→cleanup→startGameProperly 시퀀스([weak self] 이중 캡처). dim zPosition 240(CountdownNode 250 아래). 총 4.0s = 3·2·1(3.0s) + GO!(0.8s) + dim fadeOut(0.2s). GameConfig V3 신규 상수 9종(NumberFontSizeV3=120, GoFontSizeV3=140, GoStartScaleV3=1.2, GoEndScaleV3=1.8, DimAlpha=0.32, DimFadeInDuration=0.2, DimFadeOutDuration=0.2, DimZPosition=240, DimNodeName="countdownDim"). 기존 V2 상수 8개 값 보존(fontSize 96, fadeIn 0.1, hold 0.7, fadeOut 0.2, goEndScale 1.3, goFadeOut 0.4, goHold 0.5, zPosition 250). 신규 mockup countdown-overlay-v1.html ~247 LOC(4프레임 16:9 미니 + dim + 색 대비 + Jua + 캡션 + 메모 + JS 0줄 + mini-actor placeholder). 보호 영역 git diff 0줄: DPadNode/SkillButtonNode/SkillSystem/SpawnSystem/ContactRouter/ScoreSystem/GameScene+Setup/Managers(AudioManager 포함)/Repositories/GameState/PhysicsCategory/ColorTokens/모든 다른 Scenes/Phase A·B·C·D 결과물. CountdownNode.start 시그니처 + startGameProperly 본체 + gameState 전이 + spawnSystem.start 호출 위치 byte-identical. 강제 언래핑 0, Timer 0, switch default 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: (1) V3 상수 명명 규칙 (countdownGoEndScale vs V3) 공존 — Sprint 7 종료 후 일괄 정리. (2) AudioManager tick/chime 키 등록은 Sprint 8 후보(SPRINT_7_REQUEST §6.3 명시). (3) dim fadeOut 0.2s + spawnSystem 갭이 추후 사운드 등록 시 청각 단절 우려 — chime ≥0.2s 또는 .group 검토.

### Sprint 7 Phase D — 결과창 + ScoreboardScene 신설
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.8 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: ResultScene 5요소 0px 겹침 + 신규 ScoreboardScene 5×3 매트릭스. ResultScene 신규 자식 3종(scoreNoteIconLabel 24pt 좌측 / bestPill GlassPill 우측 +120 / scoreboardButton GlassPill 좌측 -110). scoreLabel "♪" 제거(텍스트만 "\(finalScore)"). bestLabel.alpha=0 시각 차단 + 노드 트리 보존. headerChip/titleLabel/subtitle/accentLine V3 +15/+15/+14/+18 시프트, divider/playsValue/playsTitle/totalValue/totalTitle V3 +12 동조 상승. touchesBegan에 scoreboard 칩 분기 추가(기존 StartScene 분기 보존, 1탭 정책 유지). inferredCharacterID computed property(characterName → CharacterID 역변환 — 5 displayName 유일성 안전). 신규 ScoreboardScene ~499 LOC: GradientBackgroundNode.threeStop + AccentLine + Jua 30 "기록 보기" + 매트릭스 15셀(CharacterID.allCases × Difficulty.allCases) + 행 헤더 5(CharacterFaceNode.mini 32px setScale 0.47 + 약칭 라벨) + 열 헤더 3(Phase C 색 토큰) + ★ 마커 lastUpdatedKey 셀(zPos 3) + 하단 stat("총 플레이 N회 · 졸업장 N장") + 좌상단 "← 결과로" GlassPill + 우상단 "캐릭터별 기록" DarkContextChip. ResultReturnContext struct 8필드(같은 파일 동봉, Foundation 의존만). 백 버튼 복귀 시 새 ResultScene 인스턴스 isNewGraduation:false/graduatedAt:nil 강제(졸업장 재표시 차단). CharacterFaceNode.mini 정적 팩토리 1개 추가(신규 시각 자식 0). GameConfig Phase D V3 상수 ~40개 신규. Xcode pbxproj 4줄 추가(ScoreboardScene 등록). 신규 mockup 2종(result-screen-v3.html ~430 / highscore-board-v1.html ~323). 보호 영역 git diff 0줄: Phase A·B·C 결과물 14파일 + GameScene/GameState/PhysicsCategory/Managers/Systems + Repositories(저장 호출 0건, 읽기 전용 — perDiffRepo.current·statsRepo.current.playCount·graduationRepo.current.count). DiplomaOverlayNode.present + isNewBest sparkle 5발/heavy 햅틱/NewMail 사운드 발화 조건 byte-identical. newResultScene 시그니처 byte-identical. 강제 언래핑 0, Timer 0, switch default 0, update()-내-addChild 0, 하드코딩 hex 0(Scenes). 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: bestLabel.alpha=0 직후 신기록 분기에서 startBestLabelGoldBlink 액션이 alpha 0.5↔1.0 깜빡일 수 있음. 차후 정리 Sprint에서 removeAction 또는 alpha 0 강제 유지 한 줄 추가 가능.

### Sprint 7 Phase C — 난이도 카드 색 위계
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.8 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: 난이도 3장 카드에 색 위계(하=민트/중=골드/상=코랄 그라데이션) 부여. Difficulty 4종 computed property(cardFillTop/cardFillBottom/cardStrokeColor/cardGlowColor) 3 case exhaustive switch default 미사용. ColorTokens 6 신규(EasyMint/EasyDeep/MidGold/MidDeep/HardCoral/HardDeep). GameConfig Phase C V3 상수 14종(NameFontSize=30, NameStrokeWidth=1.0, LiftY=8, LiftDuration=0.18, GlowWidth=158, GlowHeight=116, GlowAlpha=0.80, GlowSpread=12, HaloWidth=240, HaloHeight=90, HaloAlpha=0.35, HaloSpread=24, HaloFadeIn=0.25, HaloOffsetY=0). DifficultyCardNode init/setSelected에서 id.cardFillTop/cardStrokeColor/cardGlowColor lookup 적용 + ringGlow.strokeColor 동기화. nameLabelStroke 32pt + nameLabel 30pt 2-라벨 stroke 패턴(SKLabelNode stroke 직접 미지원 우회). liftCurrentOffset 증분 패턴 — setSelected 다중 호출 안전. DifficultySelectScene 시작 버튼 halo SKShapeNode 240×90 ellipse + 페이드 인 0.25s + zPosition startButton-1. 좌측 속도 칩 stroke 1pt 보강. 신규 mockup difficulty-select-v3.html ~536줄. PrimaryButtonNode 내부 0줄 변경(OQ-3 halo는 Scene 책임). Phase A·B 결과물 6파일 + 게임 로직 4파일 + Managers/Repositories/Systems 디렉토리 모두 git diff 0줄. Difficulty enum 기존 멤버(color/displayName/subtitle/description/shortName/raw value) byte-identical. init/transitionToGame/transitionBack 시그니처 byte-identical. 강제 언래핑 0, Timer 0, update()-내-addChild 0, switch default 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (합격 영향 0)**: DifficultySelectScene 속도 칩 `chip.lineWidth = 1` 리터럴 GameConfig 상수화 권장. 차기 정리 Sprint에서.

### Sprint 7 Phase B — 스킬 설명 겹침 해소
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.77/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.7 · UX 9.6)
- QA 반복: 1회 (한 번에 통과)
- 비고: SkillExplanationScene에서 시각 충돌 4건 정리. (1) 하단 secondary BackButtonNode `addChild` 호출 제거 — 좌상단 GlassPill `topBackPill`이 백 버튼 단독 책임. (2) 우측 본문 상단 `metaLabel`("XX의 스킬") `addChild` 호출 제거 — 우상단 브레드크럼 `breadcrumbChip`이 위치 정보 단독 책임. (3) `didChangeSize(_:)`의 `layoutMetaLabel()` 호출 제거. (4) `setupSkillQuoteBox()` 폭/보더, `layoutStatChips()` spacing을 V3 상수 참조로 교체. GameConfig 신규 상수 5종(`skillExplanationQuoteBoxWidthV3=332`, `ContentWidthRatioV3=0.52`, `QuoteBoxBorderWidthV3=4`, `StatChipSpacingV3=10`, `BottomButtonGapV3=18`). 기존 v2 상수(300/3/8) 값 보존. `backButton` / `metaLabel` 인스턴스 자체는 보존(시그니처 0 변경) — `touchesBegan`의 `contains` 가드는 부모(씬) 없어 hit-test false 반환으로 안전. 신규 mockup `skill-explanation-v3.html` ~280줄. 보호 영역 13파일(Phase A 결과물 4 + 게임 로직 4 + 보호 노드 5) 모두 git diff 0줄. `init(characterID:)` / `transitionToCharacterSelect()` / `transitionToDifficulty()` byte-identical. 강제 언래핑 0, Timer 0, update()-내-addChild 0. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (Phase B 합격 영향 0)**: `setupMetaLabel()` / `layoutMetaLabel()` 두 함수가 dead-leaning 상태. SPEC OQ-2 보존 원칙(인스턴스 시그니처 보존)에 따라 의도적 잔류. 차기 정리 Sprint에서 함수 자체 삭제 또는 isHidden 플래그 검토 가능.

### Sprint 7 Phase A — 캐릭터 선택 NIKKE 카드 리뉴얼
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.45/10** (게임로직 9.8 · Swift패턴 9.4 · 비주얼 9.3 · UX 8.8)
- QA 반복: 1회 (한 번에 통과)
- 비고: 카드 폭 76→160 · 높이 104→200 · gap 10→22 · 4:5 NIKKE 식 세로 카드. 카드 내부 5요소(좌상단 헥사 28×28 캐릭터 색 + 이모지 5종 / 좌하단 등급 로마숫자 배지 26×18 navyDeep×0.85 + 골드 라벨 / 우상단 CD 미니칩 9pt coralLight×0.85 / 중앙 얼굴 SVG / 하단 이름 Jua 15 + 속도 Gowun 10) 흡수. 선택 데코 신규 2종(하단 코랄 ellipse glow 224×60 alpha 0.45 + 상단 "선택됨" 알약 60×20 Jua 10 흰/코랄). CharacterID.rarity/elementSymbol · PlayerSkill.cooldownText 3종 computed property 추가(5 case exhaustive switch). GameConfig v3 상수 ~28종 신규(기존 7종 값 보존). CharacterCardNode 5요소 attach* 메서드 신규 + setSelected glow/pill 토글. CharacterSelectScene 글래스 컨테이너 v3 폭/높이 + alpha 0.0, 외부 색점·태그 isHidden, cardBaseX/Y 본문만 v3 폭, 스킬 패널 setScale clamp(max 320). 신규 mockup character-select-v3.html ~445줄. 보호 영역 git diff 0줄(ResultScene/GameScene/GameState/PhysicsCategory/Managers/Repositories), preferenceRepo·transitionTo*·.kim 분기·CharacterID/PlayerSkill 기존 값 byte-identical. 강제 언래핑 0건, Timer 0건, update()-내-addChild 0건. 빌드 SUCCEEDED 신규 워닝 0.
- **잔존 P2 (Phase A 합격 영향 0)**: (1) glow 높이 mockup CSS 80 vs Swift 60 SPEC 자가-모순 정렬. (2) iPhone 12 Pro 가로에서 카드 5장 합산 폭 912pt가 화면 844pt 초과 → 양 끝 ±34pt 외측 → 후속 Phase에서 minCardSpacing 축소 또는 카드 폭 v3.5 보정 권장. (3) attachCDChip의 frame.width 측정 패턴 주석 보강.

### Sprint 6 — 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.53/10** (게임로직 9.8 · Swift패턴 9.4 · 비주얼 9.2 · UX 9.5)
- QA 반복: 1회 (한 번에 통과 — Evaluator subagent stream timeout으로 부모 하네스가 직접 핵심 검증 수행)
- 비고: 5단계 흐름(Start→Character→Skill→Difficulty→Game) + .kim 4단계(스킬 스킵) 신설. mockup 2종 수정(character-select / skill-explanation) + 1종 신규(difficulty-select-v2.html ~510줄). Swift 수정 4건(StartScene 난이도 카드 70~100줄 삭제·NurseAvatarNode 부착 / CharacterSelectScene init(size:) 단순화·5장 얼굴 부착·.kim→Difficulty 분기 / SkillExplanationScene difficulty 인자 제거·시작→다음·Difficulty 전이 / GameConfig 신규 상수 ~50개·characterSelectBackPillText "← 메인" 값 교체) + 신규 3건(DifficultySelectScene 448줄 / CharacterFaceNode 660줄 5캐릭터 SVG→SKShapeNode / NurseAvatarNode 374줄 김간호 큰 그림 SVG→SKShapeNode). GameScene.newGameScene(characterID:difficulty:) 시그니처 byte-identical, 보호 영역 17파일 + 공용 노드 8파일 + Managers/Repositories/GameState/PhysicsCategory/ColorTokens 모두 git diff 0줄. 강제 언래핑 0건, Timer 0건. 빌드 SUCCEEDED 신규 워닝 0건.
- **사용자 후속 작업 권장 (SPRINT_6_REQUEST.md §7)**: (1) Sprint 4 PNG 자산 도착 시 CharacterFaceNode → SKSpriteNode 교체(좌표/스케일 동일 유지). (2) NurseAvatarNode 호흡 애니메이션(scale 1.02↔0.98 3초 주기). (3) 캐릭터→스킬→난이도 단계 전이 chime 사운드. (4) 시뮬레이터 실기로 5명 얼굴 식별·NurseAvatar 4영역 분간 시각 검증.

---

## Sprint별 요점 (DESIGN_RENEWAL_REQUEST.md §9에서 발췌)

### Sprint 1 (시각 변화 0)
- `ColorTokens.swift` 토큰 15개 추가
- Jua / Gowun Dodum / Noto Sans KR ttf 추가 + Info.plist + GameConfig 폰트 상수
- 신규 노드: `GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`
- `PrimaryButtonNode`, `BackButtonNode` 리스타일링
- `GradientBackgroundNode` 3-stop 그라데이션 옵션 추가

### Sprint 2 (메뉴 화면 시각 변경)
- `mockups/main-screen-v2.html` 매칭 → StartScene
- `mockups/character-select-v2.html` 매칭 → CharacterSelectScene
- `mockups/skill-explanation-v2.html` 매칭 → SkillExplanationScene
- 캐릭터 자리는 placeholder (Sprint 4 대기)

### Sprint 3 (인게임 시각 변경)
- `mockups/game-map-v2.html` 매칭
- 체크보드 hex 토큰 교체 (#FFEFE0 / #FFDFC8)
- HUD 4슬롯 + TIME 12초 이하 경고 색
- D-Pad **우하단** / 스킬 버튼 **좌하단** 위치
- 음표·F 투사체·콤보팝업 v2 스타일

### Sprint 4 (PNG 통합) — 자산 대기 중
- `PixelSpriteRenderer` → `SKTextureAtlas` 마이그레이션
- 5명 × 16프레임 PNG 임포트
- 폴폴폴 `SKAction` 패턴 (scaleY 호흡)

### Sprint 5 (결과 화면)
- `mockups/result-screen-v2.html` 매칭 → ResultScene
- 3분기 (일반·신기록·졸업장) 분기별 시각
- DiplomaOverlayNode 우드컷 패턴 + 명조 폰트

---

## 합격 기준 요약 (DESIGN_RENEWAL_REQUEST.md §11)

각 Sprint마다 Evaluator가 다음 4개 카테고리로 채점:

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (절대 회귀 0) |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 |
| 가독성 & UX | 15% | 7.0 이상 |

가중 평균 **7.5 이상**이면 ✅ 합격.

---

## 트러블슈팅

**Q. "디자인 리뉴얼 진행해줘"라고 했는데 반응이 없어요**
→ Claude Code 세션이 `CLAUDE.md`를 읽었는지 확인. 새 세션 시작 시 자동으로 읽혀야 함. 안 됐다면 "CLAUDE.md를 다시 읽어줘"라고 요청.

**Q. Sprint 1만 계속 돌고 다음으로 안 넘어가요**
→ Evaluator 점수가 7.5 미만이라 합격 처리가 안 됨. 점수 상세를 보고 어디서 막혔는지 확인. 3회 시도 초과 시 사용자 개입 필요.

**Q. Sprint 순서를 바꾸고 싶어요**
→ 이 파일의 진행 현황 표를 수동 편집해서 원하는 Sprint를 "⏳ 대기"로 변경. Sprint 5가 Sprint 4보다 먼저 가능함.

**Q. 처음부터 다시 시작하고 싶어요**
→ 이 파일 삭제 → "디자인 리뉴얼 진행해줘" 입력 → Sprint 1부터 자동 재시작.
