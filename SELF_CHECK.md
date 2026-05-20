# 자체 점검 — Sprint 7 Phase D

전략: Case A — 최초 구현. SPEC 요구사항을 정밀하게 그대로 적용.

## 변경 파일 목록

| 파일 | 변경 LOC | 비고 |
|---|---|---|
| `Scenes/ResultScene.swift` | +167 / -15 | 레이아웃 V3 시프트 + 신규 자식 3개 + touchesBegan 분기 + inferredCharacterID |
| `Nodes/CharacterFaceNode.swift` | +11 | static func mini(id:) — setScale 0.47x |
| `Config/GameConfig.swift` | +149 | Phase D V3 상수 ~40개 신규 (V2 상수 모두 보존) |
| `GanhoMusic.xcodeproj/project.pbxproj` | +4 | ScoreboardScene.swift 등록 (BuildFile + FileReference + Scenes group + Sources phase) |
| `Scenes/ScoreboardScene.swift` (신규) | +498 | 신규 씬 + ResultReturnContext struct |
| `mockups/result-screen-v3.html` (신규) | +430 | v2 카피 + §5.2 표 매칭 |
| `mockups/highscore-board-v1.html` (신규) | +323 | 5×3 매트릭스 + ★ 데모 + 빈 셀 + stat |

**Swift 합계: 수정 ~313 LOC + 신규 498 LOC = 811 LOC.**  
**Mockup 합계: 753 LOC.**

## 보호 영역 git diff 검증 (0줄)

`git diff HEAD --` 검증 결과:

| 영역 | git diff 라인 수 |
|---|---|
| Phase A·B·C 결과물 (CharacterCardNode/CharacterSelectScene/CharacterID/PlayerSkill/SkillExplanationScene/DifficultyCardNode/DifficultySelectScene/Difficulty/ColorTokens/GlassPillNode/DarkContextChipNode/PrimaryButtonNode/BackButtonNode/StoryBoxNode) | **0** |
| GameScene / GameState / PhysicsCategory / Managers / Systems | **0** |
| Repositories (HighScoreRepository / StatisticsRepository / PerDifficultyScoreRepository / GraduationRepository) | **0** (읽기 전용) |

## SPEC 기능 체크

- [x] **기능 1**: ResultScene 레이아웃 V3 재배치 — headerChip(+115) / titleLabel(+85) / subtitleLabel(+58) / accentLine(+148) / scoreSub(-44) / divider(-78) / playsValue·totalValue(-98) / playsTitle·totalTitle(-112). `bestLabel.alpha = 0` 시각 차단(노드 트리 보존). scoreLabel.text = "\(finalScore)" (♪ 제거).
- [x] **기능 1**: ResultScene 신규 자식 3개 — `scoreNoteIconLabel` (Jua 24pt, scoreLabel.x -60) / `bestPill` (GlassPillNode 120×28, scoreLabel.x +120) / `scoreboardButton` (GlassPillNode 110×36, shareButton.x -110). touchesBegan 분기 추가.
- [x] **기능 1**: `inferredCharacterID` computed property — `CharacterID.allCases.first { $0.displayName == characterName }` 역변환.
- [x] **기능 2**: `CharacterFaceNode.mini(id:)` static factory — 기존 `init(id:)` + `setScale(scoreboardMiniFaceScale = 0.47)`. 신규 시각 자식 0건.
- [x] **기능 3**: `ScoreboardScene.swift` 신규 (~498 LOC) — `lastUpdatedKey: (CharacterID, Difficulty)?` + `returnContext: ResultReturnContext?`. 5×3 매트릭스 + ★ 마커 + 백 버튼 + 브레드크럼 + 하단 stat. `ResultReturnContext` struct 같은 파일에 정의.
- [x] **기능 4**: `GameConfig` Phase D V3 상수 ~40개 — ResultScene V3 (note icon / best pill / scoreboard button / 오프셋 시프트) + ScoreboardScene (매트릭스 셀/헤더 좌표·폰트·★ 마커·백 버튼·브레드크럼·stat).
- [x] **기능 5**: `mockups/result-screen-v3.html` — v2 카피 + ♪ 24pt 좌측 absolute + BEST GlassPill 우측 +120 + headerChip 위로 +15 + scoreboardButton 좌측 + annotation 박스.
- [x] **기능 5**: `mockups/highscore-board-v1.html` — 5×3 매트릭스 (Phase C 색) + ★ 데모(건간호 하 200★) + 빈 셀 "—" + 하단 stat + annotation 박스.

## 핵심 검증

- [x] `ResultScene.newResultScene(...)` 8개 인자(+ size 합 9개) 시그니처 **byte-identical** — score, bestScore, isNewBest, stats, characterName, difficulty, isNewGraduation, graduatedAt. 호출부 (GameScene.swift:755) 그대로 컴파일 OK.
- [x] `ResultScene.init(...)` 9개 인자 시그니처 byte-identical.
- [x] `bestLabel.alpha = 0` 시각만 차단 — 노드 트리 보존, addChild 후속 유지. `startBestLabelGoldBlink` 액션은 그대로 발화하지만 위치(-60)는 V3에서 비어있고 bestPill(점수 우측)이 BEST 시각 담당.
- [x] **새 ResultScene 인스턴스 생성 시 (ScoreboardScene → ResultScene 복귀) `isNewGraduation: false` / `graduatedAt: nil` 명시** — 졸업장 재표시 차단 (SPEC §주의사항 3).
- [x] `PerDifficultyScoreRepository.best(characterID:difficulty:)` 호출은 0건 — 대신 `current` dict로 매트릭스 일괄 조회 (성능 + 단순화).
- [x] `StatisticsRepository.current.playCount` — 읽기만.
- [x] `GraduationRepository.current.count` — 읽기만 (졸업장 보유 수).
- [x] **저장·갱신 함수 호출 0건** — `recordPlay` / `record(characterID:date:)` / `record(characterID:difficulty:score:)` 호출 0.

## 신기록·졸업장 분기 보존

- [x] `DiplomaOverlayNode.present(...)` 발화 조건 byte-identical — `isNewGraduation && graduatedAt != nil` 가드 그대로.
- [x] sparkle 5발 (`emitSparkleBurst`) 발화 조건 byte-identical — `isNewBest`일 때 `revealNewBest`에서 발화.
- [x] heavy 햅틱 (`haptics.heavy()`) 발화 조건 byte-identical.
- [x] NewMail 사운드 (`audio.play(.comboMilestoneStrong)`) 발화 조건 byte-identical.
- [x] `startBestLabelGoldBlink` withKey 패턴 변경 0.
- [x] `resultSparklePositionsV2` 좌표 변경 0.

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (`guard let view = self.view, let touch = touches.first` / `if let pill = scoreboardButton, pill.contains(...)` / `?? .zero` / `?? 0`).
- guard let 옵셔널 처리: 준수.
- MARK 섹션 구분: 준수 (`// MARK: - Setup (Sprint 7 Phase D · V3 신규 자식 3개)` / `// MARK: - Helpers (Sprint 7 Phase D)` 등).
- GameConfig 상수 사용: 준수 — 매직 넘버 0. `resultScoreNoteIconFontSizeV3 = 24`, `resultBestPillWidthV3 = 120` 등 모든 좌표/크기/텍스트가 상수.
- weak self 캡처: 신규 코드에서 클로저 sync (touchesBegan 안 즉시 실행) 사용 — `[weak self]` 불필요. 기존 `scheduleNewBestReveal` 클로저는 `[weak self]` 그대로 보존.
- Timer 미사용: 준수 — `SKAction.wait(forDuration:)` 만 사용 (기존 코드).
- switch default 미사용: 준수 — `Difficulty.allCases` / `CharacterID.allCases` iteration으로 처리.

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 — `setupBackgroundGradient()` / `setupHeader()` / `setupBackButton()` / `setupBreadcrumbChip()` / `setupMatrix()` / `setupStatLabel()` 순서.
- didChangeSize(_:)에서 layout 재계산: 준수 — `layoutAll()` 호출.
- dt 기반 이동: 해당 사항 없음 (UI 씬).
- SKAction 스폰 패턴: 해당 사항 없음 (정적 매트릭스).
- 충돌 후 노드 즉시 삭제 없음: 해당 사항 없음 (물리 0).
- HUD 노드 분리: 해당 사항 없음 (씬 자체가 정보 화면).
- 액션 dispatch 0 — `update()` 안 `addChild()` 0건.
- repo 인스턴스는 매 씬 new (UserDefaults 기반 stateless) — 기존 다른 씬 패턴 답습.

## 빌드 결과

- **xcodebuild ... build → BUILD SUCCEEDED** (iOS Simulator 타겟, generic platform).
- 컴파일 에러: **0**.
- 신규 워닝: **0** (기존 폰트 중복 워닝만 — 폰트 리소스 중복 등록, 기존 상태).
- Xcode 프로젝트에 `ScoreboardScene.swift` 등록 확인:
  - `PBXBuildFile`: `A1C0F1B00000000000000074 /* ScoreboardScene.swift in Sources */`
  - `PBXFileReference`: `A1C0F1A00000000000000074 /* ScoreboardScene.swift */`
  - Scenes group children: 추가됨
  - PBXSourcesBuildPhase (iOS target): 추가됨

## OPEN_QUESTION 처리 상태 (모두 SPEC에서 결정됨)

- **OQ-1**: ScoreboardScene → ResultScene 복귀는 **옵션 A** — 새 인스턴스 생성, `ResultReturnContext` struct로 9-인자 전달, `isNewGraduation: false` 강제. ✓ 적용됨.
- **OQ-2**: GraduationRepository API는 `graduationRepo.current.count`, StatisticsRepository는 `statsRepo.current.playCount`. ✓ 적용됨.
- **OQ-3**: ★ 마커는 `isNewBest && inferredCharacterID != nil`일 때만 (charID, difficulty) 튜플. 그 외 nil → 매트릭스에 ★ 미표시. ✓ 적용됨.
- **OQ-4**: `CharacterFaceNode.mini` 팩토리는 기존 `init(id:)` + `setScale(0.47)`. 신규 시각 자식 0. ✓ 적용됨.

## 범위 외 미구현 항목

- 없음.

## 주의사항 (Generator 자체 발견)

1. **bestLabel `startBestLabelGoldBlink` 깜빡임 활동 중**: `bestLabel.alpha = 0`을 setupLabels에서 설정해도, 신기록 분기에서 `scheduleNewBestReveal` → `revealNewBest()` → `startBestLabelGoldBlink` 액션이 fadeAlpha 0.5↔1.0 cycle을 발화한다. 위치는 V3에서 비어있는 자리(midY -60)라 bestPill의 시각에 영향 없지만, *기술적으로는* alpha=0 이후 일정 시간 후(0.3s reveal delay) 위치에 흐릿한 텍스트가 가끔 나타날 수 있다. SPEC §주의사항 1이 "괜찮음"으로 명시 → 그대로 진행.
2. **`breadcrumbChip` 폭 계산**: `calculateAccumulatedFrame().width / 2`로 우측 정렬 보정. DarkContextChipNode는 라벨 폭 기반 자동 크기이므로 chip마다 폭이 다를 수 있어 동적 계산 필요. layoutAll()에서 매번 재계산.
3. **매트릭스 자식 좌표는 씬 좌표로 직접 계산**: `matrixContainer.position = .zero`로 두고 자식 노드들의 position을 frame.midX/midY 기준 절대 좌표로 부여. didChangeSize 시 `relayoutMatrixChildren()`로 일괄 갱신.
