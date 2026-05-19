# 자체 점검 — Sprint 5 (ResultScene 3분기 v2 + DiplomaOverlayNode 우드컷)

전략: Case A — Sprint 5 최초 회차, SPEC 그대로 구현.

---

## 빌드 상태
- **xcodebuild iPhone 17 결과**: `** BUILD SUCCEEDED **`
- 경고: 폰트 ttf 3개의 *Copy Bundle Resources* 중복(기존 경고, 본 Sprint 비관여)
- 오류 0건

---

## 변경 파일 목록 (git diff --name-only)
- `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift` (+14)
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` (+121)
- `GanhoMusic/GanhoMusic Shared/Nodes/DiplomaOverlayNode.swift` (+179)
- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` (변경분)

기타: `SPEC.md`(이전 Sprint 산출물 갱신), `SELF_CHECK.md`(본 파일), `QA_REPORT.md`(삭제됨, Evaluator가 재생성).

---

## P0 — 즉시 불합격 가드 (모두 통과해야 함)

| 항목 | 확인 결과 | 근거 (파일:라인) |
|---|---|---|
| `ResultScene.init` 9개 인자 시그니처 보존 | OK | ResultScene.swift:99-119 (size/score/bestScore/isNewBest/stats/characterName/difficulty/isNewGraduation/graduatedAt — 순서·이름·타입 그대로) |
| `newResultScene` 정적 팩토리 시그니처 보존 | OK | ResultScene.swift:69-92 (8개 인자 + default 2 + return ResultScene) |
| `GameScene.swift` ResultScene 호출부 0줄 | OK | git diff GanhoMusic/GanhoMusic\ Shared/GameScene.swift = 0건 |
| `DiplomaOverlayNode` private init + present 시그니처 보존 | OK | DiplomaOverlayNode.swift:67-78 (private init), 119-138 (static present) |
| `dismiss()` 시퀀스(isUserInteractionEnabled=false → onDismiss=nil → fadeOut → cleanup → notify) | OK | DiplomaOverlayNode.swift:154-165 |
| `touchesBegan` diplomaOverlay name 가드 보존 | OK | ResultScene.swift:485 (`children.contains(where: { $0.name == "diplomaOverlay" })`) |
| `transitionToStart` 경로(StartScene.newStartScene + SKTransition.fade) 보존 | OK | ResultScene.swift:493-495 |
| `haptics.heavy()` / `audio.play(.comboMilestoneStrong)` 호출 조건 보존 | OK | ResultScene.swift:526-528 (revealNewBest 첫 2줄), 호출 조건 = `if isNewBest` → `scheduleNewBestReveal` → `revealNewBest` 시퀀스 보존 |
| DiplomaOverlayNode 본문 텍스트 0건 변경 | OK | DiplomaOverlayNode.swift:81-87 ("다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다." / "이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다.") — {NAME} 치환 로직 보존 |
| Repositories 5개 호출 위치/순서 변경 0건 | OK | GameScene.swift git diff 0줄 — ResultScene은 데이터만 받음 |
| 2단계 탭 정책 보존 | OK | presentDiploma의 `onDismiss: {}` 빈 클로저 (ResultScene.swift:600), 졸업장 dismiss 후 ResultScene 노출 → 1탭 → StartScene |

---

## P1 — Swift 패턴 (20%)

| 항목 | 결과 | 근거 |
|---|---|---|
| 강제 언래핑 `!` 0건 | OK | grep `!` on ResultScene/DiplomaOverlayNode — 부정 연산자(`!isTransitioning`)만 존재 |
| Timer 사용 0건 | OK | 모든 지연 = `SKAction.wait` + `SKAction.run` |
| 매직 넘버 0건 | OK | 모든 수치 = GameConfig 상수. 예외: `0`(좌표), `1`(alpha), `0.5`(label.text 분기 default 사용 없음), `-12` 도장 회전·`-2` 종이 회전·`0.88` 카드 알파·`0.18` divider 알파 — 의도된 mockup 1:1 정수. `0.88` carPanel alpha는 mockup `rgba(255,255,255,0.88)` 직접 표현(다른 곳 미사용) |
| hex 하드코딩 0건 | OK | ColorTokens.swift에 신규 4 토큰만 추가. ResultScene/DiplomaOverlayNode 본문에서 `UIColor(hex:` 호출 1건은 `GameConfig.diplomaDotHexV2`(상수) 통과 |
| `// MARK:` 섹션 구분 | OK | ResultScene.swift `// MARK: - Properties/Factory/Init/Lifecycle/Setup/Touch/New Best/Diploma`. DiplomaOverlayNode.swift `// MARK: - Properties/Init/Present/Touch Trigger/Dismiss/Configure` |
| private / final / let 일관성 | OK | 모든 새 프로퍼티 `private let` 또는 `private var`. 두 클래스 모두 `final class`. 9개 init 인자 `let` 보존 |
| `[weak self]` 클로저 캡처 | OK | `scheduleNewBestReveal()`의 `SKAction.run { [weak self] in self?.revealNewBest() }` (ResultScene.swift:514-517). `emitSparkleBurst` 내부는 `self.frame.midX`만 사용하지만 `addChild` 호출이 self 의존 — 호출자(revealNewBest)가 이미 weak self 클로저 안 |

---

## P2 — 분기별 시각 (25%)

### 분기 A (일반 결과: isNewBest=false && isNewGraduation=false)
- [x] 타이틀 "실습 종료" navyDeep — ResultScene.swift:configureTitleLabelV2 (line ≈301-318)
- [x] 점수 코랄(ganhoCoralPrimary) — ResultScene.swift:configureScoreLabelV2 (line ≈321-330)
- [x] 부제 "수고했어요! 한 번 더 해볼까요?" — ResultScene.swift:configureSubtitleLabelV2 (line ≈354-365)
- [x] sparkle 0개 — `if isNewBest` 분기 안에서만 `emitSparkleBurst` 호출 (ResultScene.swift:revealNewBest)
- [x] shareButton "📤 공유" — ResultScene.swift:setupButtons (line ≈407)
- [x] 헤더 칩 "X 난이도 · 캐릭터명" — DarkContextChipNode label 합성 (line ≈243-247)
- [x] AccentLine, divider, PLAYS/TOTAL stats 부착
- [x] 3-stop warm 그라데이션 배경 (`setupBackgroundGradient` → `GradientBackgroundNode.threeStop`)

### 분기 B (신기록: isNewBest=true)
- [x] 타이틀 "✨ NEW BEST! ✨" 골드(ganhoMusicGold) — configureTitleLabelV2 분기
- [x] 점수 골드(ganhoMusicGold) — configureScoreLabelV2 분기
- [x] 부제 "최고 기록을 갱신했어요!" — configureSubtitleLabelV2 분기
- [x] 점수 부제 "NEW SCORE" — configureScoreSubLabelV2 분기
- [x] sparkle 5개 동시 — `emitSparkleBurst()` 호출(revealNewBest 마지막 라인) + GameConfig.resultSparklePositionsV2 5개 좌표
- [x] shareButton "📤 자랑하기" — setupButtons 분기
- [x] heavy 햅틱 + NewMail 사운드 — revealNewBest 첫 2줄 보존
- [x] bestLabel 골드 깜빡임 — startBestLabelGoldBlink 호출 보존
- [x] newBestLabel 황금 라벨 fade-in + pulse — configureNewBestLabel + scheduleNewBestReveal 보존

### 분기 C (졸업장: isNewGraduation=true && graduatedAt != nil)
- [x] A 카드 위에 DiplomaOverlayNode 오버레이 — presentDiploma 호출 보존(setupLabels 끝)
- [x] 우드컷 종이 카드(520×320 cornerRadius=8, fill=DiplomaPaper #FFF9EA, stroke=DiplomaBorder #C76F00, lineWidth=4, -2° 회전) — buildPaperCard
- [x] 도트 패턴(단일 SKShapeNode + CGMutablePath addEllipse 12pt 격자) — buildDotsPattern
- [x] 코너 데코 ㄱ자 2개(좌상·우하, strokeColor=DiplomaBorder lineWidth=3, -2° 회전) — buildCornerDeco
- [x] 도장 원 r=28(stroke=coralShadow, fill=coralLight α=0.4, -12° 회전) + 라벨 "김간호\n음악대학" Jua 9pt coralShadow — buildStamp
- [x] 명조 폰트(fontSerif) 7 라벨 — init 후 fontName 일괄 교체
- [x] 라벨 색 명조 톤 분기 — titleEn/issuer/date/tap=DiplomaTextMuted(#8B5A0E), titleKo/body1/body2=DiplomaTextDeep(#5A3A0E)
- [x] 본문 텍스트 0건 변경 — body1Template/body2Label.text 그대로
- [x] {NAME} 치환 로직 보존 — `replacingOccurrences(of: "{NAME}", with: characterName)`

### 2단계 탭 정책 (분기 C)
- [x] 졸업장 1탭 → dismiss → onDismiss={} → ResultScene 노출 → 1탭 → StartScene fade
- [x] touchesBegan 가드 `children.contains(where: { $0.name == "diplomaOverlay" })` 보존

---

## P3 — 빌드 & 호환 (15%)

| 항목 | 결과 |
|---|---|
| xcodebuild SUCCEEDED | OK (BUILD SUCCEEDED) |
| `fontSerif` ttf 부재 시 크래시 0 | OK — SKLabelNode가 unknown fontName 시 시스템 fallback. fontSerif="GowunBatang-Regular"는 GameConfig 상수만 추가 |
| 5×3=15 캐릭터·난이도 조합 + 신기록 + 졸업장 진입 가능 | OK — 9개 인자 시그니처 보존, GameScene 호출부 0건 변경, 분기 로직(isNewBest / isNewGraduation+graduatedAt) 보존 |

---

## P4 — Sprint 1~3 보호 (40%, 회귀 0)

`git diff --name-only` 출력에 따른 회귀 가드 — **Sprint 5에서 수정된 파일은 4개뿐**:
- ColorTokens.swift (Sprint 5 신규 토큰 4개 *추가만* — 기존 토큰 hex 0 변경)
- GameConfig.swift (Sprint 5 신규 상수 약 30개 *추가만* — 기존 상수 변경 0)
- DiplomaOverlayNode.swift (자식 노드 + configureBackground 확장 + 라벨 fontName/Color 명조 톤)
- ResultScene.swift (시각 레이아웃 v2)

다음 파일들 git diff = **0줄**:
- GameScene.swift
- GameScene+Setup.swift
- Scenes/StartScene.swift
- Scenes/CharacterSelectScene.swift
- Scenes/SkillExplanationScene.swift
- Systems/* (ContactRouter, SkillSystem, SpawnSystem, ScoreSystem, CameraShakeAction)
- Repositories/* (HighScore, Statistics, PerDifficultyScore, Graduation, CharacterPreference, DifficultyPreference)
- Managers/* (BGMPlayer, AudioManager, HapticsManager)
- Nodes/GlassPillNode.swift (Sprint 1)
- Nodes/AccentLineNode.swift (Sprint 1)
- Nodes/DarkContextChipNode.swift (Sprint 1)
- Nodes/PrimaryButtonNode.swift (Sprint 1)
- Nodes/BackButtonNode.swift
- Nodes/GradientBackgroundNode.swift
- Nodes/PauseButtonNode.swift (Sprint 3)
- Nodes/SparkleEffectNode.swift
- Nodes/HUDNode.swift, DPadNode.swift, SkillButtonNode.swift, HUDSkillSlotNode.swift
- Nodes/NoteNode.swift, ProjectileNode.swift
- Nodes/ComboPopupNode.swift, ComboBreakNode.swift
- 인게임 노드(EnemyNode, ProfessorNode, StoneGuardNode, PlayerNode, ToiletNode, AirplaneNode 등) 전체

`git status` 결과:
```
modified:   GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
modified:   GanhoMusic/GanhoMusic Shared/Nodes/DiplomaOverlayNode.swift
modified:   GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift
```

---

## SpriteKit 패턴 준수

| 항목 | 결과 | 근거 |
|---|---|---|
| `didMove(to:)`에서 초기화 | OK | ResultScene.swift:didMove(to:) → setupBackgroundGradient → setupOverlayPanel → setupLabels |
| update()에 addChild() 없음 | OK | update() 미 오버라이드. sparkle 5발은 *revealNewBest 호출 시 1회만* addChild |
| SKAction 스폰 패턴 | OK | scheduleNewBestReveal = wait + run([weak self]) 시퀀스 |
| 충돌 후 노드 즉시 삭제 없음 | N/A | ResultScene/DiplomaOverlayNode는 충돌 0 |
| HUD 노드 분리 | OK | ResultScene은 카메라 없는 정적 씬, 기존 layout 유지 |

---

## 핵심 구현 디테일

1. **2-stop SparkleEffectNode 재활용**: ResultScene이 `import SpriteKit`만으로 자식 부착 → emit() 호출. 기존 자가 소멸 4호 패턴 그대로 — addChild 좌표/zPosition만 다름.

2. **단일 SKShapeNode 도트 패턴**: `buildDotsPattern`에서 `CGMutablePath`에 12pt 격자 약 1100개 도트를 *누적 addEllipse* — 노드 1개로 통합. SpriteKit 드로우콜 1회 처리.

3. **graceful fontSerif fallback**: `GameConfig.fontSerif = "GowunBatang-Regular"` — ttf 부재 시 SKLabelNode가 시스템 폰트로 자동 fallback. 크래시 없이 시각만 시스템 폰트로 대체.

4. **분기 B titleLabel vs newBestLabel 분리**: titleLabel(카드 헤더 +70 골드 "✨ NEW BEST! ✨") + newBestLabel(화면 정중앙 +0 큰 황금 "NEW BEST!") — y 분리로 두 라벨 다 살림.

5. **기존 라벨 6개 alpha=0 비활성**: characterLabel / difficultyLabel / statsLabel / promptLabel은 노드 트리 보존을 위해 *addChild는 유지*하되 alpha=0으로 시각 차단. headerChip + stat 그룹이 대체.

6. **revealNewBest sparkle 5발 마지막 라인 추가**: 기존 시퀀스(haptic → audio → fadeIn/pulse → goldBlink) 보존 + `emitSparkleBurst()` 한 줄만 끝에 추가.

7. **DiplomaOverlayNode 우드컷 z 계층**:
   - background(0) → paperCard(0.5) → dotsPattern(0.7) → cornerDeco(0.8) → labels(1) → stamp(1.2 + child label(1) 자식 z=1)

---

## 범위 외 미구현 항목
- **없음**. SPEC §파일별 변경 명세의 모든 항목 구현.
- **OPEN_QUESTION** Q2: GowunBatang-Regular.ttf 임포트는 *사용자 후속 작업*으로 명시(SPEC §OPEN_QUESTION). 본 Sprint는 fontSerif 상수만 정의 → SKLabelNode fallback 안전.
