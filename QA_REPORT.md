# QA 검수 보고서 — Sprint 5 (ResultScene 3분기 v2 + DiplomaOverlayNode 우드컷)

## SPEC 기능 검증

- [PASS] **ResultScene.init 9개 인자 시그니처**: ResultScene.swift:129-149에 `size/score/bestScore/isNewBest/stats/characterName/difficulty/isNewGraduation/graduatedAt` 순서·이름·타입 byte-identical 보존
- [PASS] **newResultScene 정적 팩토리 시그니처**: ResultScene.swift:99-122에 8개 인자(score/bestScore/isNewBest/stats/characterName/difficulty/isNewGraduation=false/graduatedAt=nil) default 2 포함 보존
- [PASS] **GameScene.swift ResultScene 호출부 0줄 변경**: `git diff HEAD -- "GanhoMusic/GanhoMusic Shared/GameScene.swift"` = 0줄. 호출부(GameScene.swift:755-761) 그대로
- [PASS] **DiplomaOverlayNode private init + present 정적 팩토리 시그니처**: DiplomaOverlayNode.swift:77 (`private init(characterName:graduatedAt:sceneSize:)`) + DiplomaOverlayNode.swift:147-154 (`static func present(characterName:graduatedAt:parent:sceneSize:anchor:onDismiss:)`) 시그니처 그대로
- [PASS] **본문 텍스트 byte-identical**: DiplomaOverlayNode.swift:84 `"다사다난한 실습을 마치고 {NAME}는 드디어 졸업하였다."`, line 88 `"이제 세상이라는 악보 위에 마음껏 노래를 부르며 자유롭게 살 것이다."` — 한 글자도 변경 없음. {NAME} 치환 로직 보존
- [PASS] **dismiss / touchesBegan / SelfDismissingNode 패턴**: DiplomaOverlayNode.swift:170-172 (touchesBegan → dismiss), 177-188 (isUserInteractionEnabled=false → onDismiss nil 토글 → fadeOut → cleanup → notify 시퀀스)
- [PASS] **2단계 탭 정책**: ResultScene.swift:557 (`children.contains(where: { $0.name == "diplomaOverlay" })` 가드), ResultScene.swift:668 (`onDismiss: {}` 빈 클로저)
- [PASS] **transitionToStart 경로**: ResultScene.swift:562-564 (StartScene.newStartScene() + SKTransition.fade(withDuration: sceneTransitionDuration)) 그대로
- [PASS] **revealNewBest 시퀀스 / haptics.heavy / audio.play 발화 조건**: ResultScene.swift:597-618에 `haptics.heavy()` → `audio.play(.comboMilestoneStrong)` → fadeIn/pulse → startBestLabelGoldBlink → emitSparkleBurst() 순서. 호출 조건 = `isNewBest` 분기에서 `scheduleNewBestReveal()` → wait 0.3s → revealNewBest() 보존
- [PASS] **Repositories 5개 호출 위치/순서 0변경**: `git diff HEAD --name-only -- "GanhoMusic/GanhoMusic Shared/Repositories"` 빈 출력. ResultScene은 데이터만 수령

## 빌드 검증

- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **결과**: ✅ **BUILD SUCCEEDED**
- 경고: Resources/Fonts ttf 3개 Copy Bundle Resources 중복 (Sprint 1 잔존 경고, Sprint 5 비관여)
- 에러: 0건
- 비고: 시뮬레이터 iPhone 15 부재 → iPhone 17으로 빌드 검증 (Xcode 26)

## 회귀 가드 결과 (보호 파일 24개 git diff 0줄)

`git diff HEAD --name-only` = 4개 파일만 수정:
- `Config/ColorTokens.swift` (+14)
- `Config/GameConfig.swift` (+121)
- `Nodes/DiplomaOverlayNode.swift` (+179)
- `Scenes/ResultScene.swift` (+407)

보호 파일 24개 모두 `git diff HEAD` = **0줄**:
- GameScene.swift / GameScene+Setup.swift
- Scenes/StartScene.swift / CharacterSelectScene.swift / SkillExplanationScene.swift
- Sprint 1 컴포넌트 5개: GlassPillNode / AccentLineNode / DarkContextChipNode / PrimaryButtonNode / BackButtonNode
- GradientBackgroundNode / PauseButtonNode / SparkleEffectNode
- HUDNode / DPadNode / SkillButtonNode / HUDSkillSlotNode / NoteNode / ProjectileNode / ComboPopupNode / ComboBreakNode
- Repositories 디렉토리 / Systems 디렉토리 / Managers 디렉토리 (0건)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 2건 |

## P0 — 치명 이슈
**없음**.

## P1 — 중요 이슈
**없음**.

## P2 — 권장 사항

### 1. 카드 패널 알파 0.88 매직 리터럴
- **파일**: `Scenes/ResultScene.swift:208`
- **현재 코드**: `panel.fillColor = UIColor.white.withAlphaComponent(0.88)`
- **이슈**: 알파 값 0.88이 직접 리터럴. GameConfig 상수로 추출 가능
- **수정 제안**: `GameConfig.resultPanelFillAlphaV2 = 0.88` 상수 추가 + 참조
- **심각도**: 매우 낮음 — mockup `rgba(255,255,255,0.88)` 1:1 매핑, 단일 사용처

### 2. divider 알파 0.18 매직 리터럴
- **파일**: `Scenes/ResultScene.swift:398`
- **현재 코드**: `divider.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(0.18)`
- **이슈**: 알파 값 0.18이 직접 리터럴. GameConfig 상수화 가능
- **수정 제안**: `GameConfig.resultDividerAlphaV2 = 0.18` 상수 추가
- **심각도**: 매우 낮음 — mockup 1:1 매핑, 단일 사용처

## 통과 항목

### Swift 패턴 일관성 (P1 전체 통과)
- 강제 언래핑 `!` 0건 (문자열 리터럴 "NEW BEST!" 4건만 매치, 실제 옵셔널 force unwrap 0)
- Timer / DispatchQueue 0건 (모든 지연 = SKAction.wait + SKAction.run)
- 매직 넘버 0건 (모든 수치 GameConfig 상수, P2 알파 2건 외)
- hex 하드코딩 0건 (ColorTokens 신규 4 토큰만 추가, ResultScene/DiplomaOverlayNode UIColor(hex:) 1건은 `GameConfig.diplomaDotHexV2` 상수 경유)
- `// MARK:` 섹션 구분 (ResultScene 9개 섹션 / DiplomaOverlayNode 5개 섹션)
- `final class` + private/let 일관성 (모든 신규 자식 노드 private let, 9개 init 인자 private let)
- `[weak self]` 캡처 — scheduleNewBestReveal의 SKAction.run 클로저(ResultScene.swift:589)

### SpriteKit 패턴
- `didMove(to:)`에서 초기화 (setupBackgroundGradient → setupOverlayPanel → setupLabels)
- 충돌 후 노드 즉시 삭제 0건 (해당 없음 — ResultScene/Diploma는 물리 없음)
- 도트 패턴 단일 SKShapeNode + CGMutablePath addEllipse 누적 (1100개 도트가 노드 1개 통합, 렌더 부담 최소)
- SparkleEffectNode 자가 소멸 패턴 재활용 (내부 0건 변경, addChild 좌표/zPosition만 다름)

### 분기별 시각 명세 (P2 mockup 매칭)
- **분기 A (일반)**: 타이틀 "실습 종료" navyDeep + 점수 코랄 + 부제 "수고했어요! 한 번 더 해볼까요?" + sparkle 0개 + shareButton "📤 공유" + 3-stop warm 그라데이션
- **분기 B (신기록)**: 타이틀 "✨ NEW BEST! ✨" 골드 + 점수 골드 + 부제 "최고 기록을 갱신했어요!" + scoreSub "NEW SCORE" + sparkle 5개(emitSparkleBurst) + shareButton "📤 자랑하기" + heavy 햅틱 + NewMail 사운드 + bestLabel 골드 깜빡임 + newBestLabel 황금 라벨
- **분기 C (졸업장)**: A 카드 위에 DiplomaOverlayNode 오버레이 + 우드컷 종이(520×320 -2°) + 도트 패턴(단일 path) + ㄱ자 코너 데코 + 도장(r=28 -12°) + 명조 폰트(fontSerif) + 본문 텍스트 byte-identical

### 빌드 & 호환
- xcodebuild SUCCEEDED (iPhone 17 시뮬레이터)
- fontSerif("GowunBatang-Regular") ttf 부재 — SKLabelNode 시스템 fallback 안전 (크래시 0)
- 5×3=15 캐릭터·난이도 조합 + 신기록 + 졸업장 진입 가능 (init 9개 인자 / 호출부 0변경)

---

## 채점

| 카테고리 | 가중치 | 점수 | 근거 |
|---|---|---|---|
| 게임 로직 회귀 0 | 40% | **10.0/10** | 보호 파일 24개 git diff 0줄. GameScene.swift:755 호출부 byte-identical. Repositories/Systems/Managers 0줄. Diploma 본문 텍스트 byte-identical. 2단계 탭 정책·dismiss 시퀀스·haptics/audio 발화 조건 그대로. 회귀 신호 0건 |
| Swift 패턴 | 20% | **9.5/10** | 강제 언래핑/Timer/hex 하드코딩 0. MARK 구분 충실. final class + private let 일관. [weak self] 캡처. 알파 매직 리터럴 2건(P2)으로 0.5점 감점 |
| 비주얼 일관성 | 25% | **9.5/10** | mockup result-screen-v2.html 3분기 시각 명세 충실 구현. 신규 4 토큰만 추가. 우드컷 도트 단일 path 1100개 통합. 명조 폰트 fallback 안전. 카드 배경 0.88 alpha 등 mockup 1:1 매핑. fontSerif ttf 부재로 분기 C 명조 시각이 시스템 폰트로 fallback(시각 100% 매칭이 아닌 graceful 대체)이라 0.5점 감점 |
| 가독성 & UX | 15% | **9.5/10** | headerChip + AccentLine + divider + stat 그룹 + 버튼 2개 명확한 시각 위계. 분기별 부제 텍스트 따뜻한 톤("수고했어요!" / "최고 기록을 갱신했어요!"). "GAME OVER"→"실습 종료" 톤 교체. sparkle 5발 위치 카드 주변 5개 좌표 균형. 도장 -12° 회전이 의례적 무게감. 다중 탭 가드(isTransitioning + diplomaOverlay name 가드) 견고. 의도된 alpha=0 비활성 라벨이 노드 트리 보존 + 시각 차단 동거하는 *학습 친화* 디자인. minor: 노드 트리에 alpha=0 라벨 6개 잔존이 코드 가독성에는 약간 부담(SPEC.md 명시된 보호 가드 의도라 감점 미반영, 0.5만 감점) |

**가중 평균**: (10.0 × 0.40) + (9.5 × 0.20) + (9.5 × 0.25) + (9.5 × 0.15) = 4.0 + 1.9 + 2.375 + 1.425 = **9.7/10**

## 최종 판정: **합격**

가중 평균 **9.7/10** ≫ 합격선 7.5/10. P0/P1 0건, P2 2건(매우 낮은 알파 매직 리터럴)만 발견.

Sprint 5 P0 회귀 가드 10개 항목 모두 PASS. ResultScene 9개 init 인자 + DiplomaOverlayNode private init / present 시그니처 byte-identical. GameScene.swift / Repositories / Systems / Managers / Sprint 1-3 보호 자산 24개 모두 git diff 0줄. 빌드 SUCCEEDED.

3분기 시각 명세(A 일반 / B 신기록 / C 졸업장)가 mockup result-screen-v2.html과 시각 매칭. 우드컷 도트 패턴이 단일 SKShapeNode + CGMutablePath 누적으로 노드 1개 통합 — 성능 안전. fontSerif는 ttf 부재 시 시스템 fallback으로 크래시 0.

## 디자인 리뉴얼 전체 완료 여부

- [x] **Sprint 1** — 디자인 토큰 + 노드 컴포넌트 (QA 9.83, 877b162)
- [x] **Sprint 2** — 메뉴 3씬 v2 (QA 9.50, 924efe2)
- [x] **Sprint 3** — 인게임 v2 리스킨 (QA 9.22, cdbf3e9)
- [ ] **Sprint 4** — PNG 캐릭터 마이그레이션 (사용자 외주 PNG 80장 대기)
- [x] **Sprint 5** — ResultScene 3분기 + DiplomaOverlayNode 우드컷 (**QA 9.7, 본 회차**)

**Sprint 1/2/3/5 모두 합격**. **Sprint 4 PNG 자산 도착 후** 캐릭터 마이그레이션 진행 가능 — CharacterSpritePrompt.md 기준 5명 × 16장 외주.

## 합격 후 후속 작업 (선택)

1. **P2 알파 상수화** (선택 — 시각 영향 0): GameConfig에 `resultPanelFillAlphaV2 = 0.88` / `resultDividerAlphaV2 = 0.18` 두 상수 추가
2. **GowunBatang-Regular.ttf 임포트** (분기 C 시각 100% 매칭): https://fonts.google.com/specimen/Gowun+Batang 다운로드 → Resources/Fonts → Xcode add to target → Info.plist UIAppFonts 추가
3. **Sprint 4 PNG 외주** (디자인 리뉴얼 마무리): CHARACTER_SPRITE_PROMPT.md 기준
