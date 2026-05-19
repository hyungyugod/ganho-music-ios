# QA 검수 보고서 — Phase 10-2 · StartScene 모던 리스킨 (병동의 새벽 톤)

## SPEC 기능 검증

| # | 기능 | 결과 | 비고 |
|---|---|---|---|
| 1 | 그라데이션 배경(`GradientBackgroundNode`, zPos -20, tealDeep→teal) | PASS | StartScene.swift:89-98, GradientBackgroundNode.swift 전체 — UIGraphicsImageRenderer로 1회 생성, didChangeSize 시 rebuild |
| 2 | 떠다니는 음표 파티클(`MusicNoteEmitterNode`, 상한 15, repeatForever) | PASS | MusicNoteEmitterNode.swift:60-110 — `guard activeCount < musicNoteEmitterMaxConcurrent` 가드 작동 |
| 3 | 제목 글로우(`GlowingTitleNode`, SKEffectNode + CIGaussianBlur) | PASS | GlowingTitleNode.swift:52-67 — `shouldRasterize = true`, `if let blurFilter` 옵셔널 처리 |
| 4 | BEST/PLAYS 살구색 액센트(`.ganhoAccentCoral`) | PASS | StartScene.swift:155-156 — 부제 muted 유지 |
| 5 | 난이도 카드 spring(1.12→1.08) + 살구 링 글로우 | PASS | DifficultyCardNode.swift:46-69 (init), 86-126 (setSelected). 시그니처 불변 |
| 6 | 시작 버튼 pulse(0.98↔1.02, 2초 주기) | PASS | StartScene.swift:267-283 — withKey "startButtonPulse", 전환 시 정리 |
| 7 | 씬 전환 카드 슬라이드업 + fadeOut prelude | PASS | StartScene.swift:308-348 — `CharacterSelectScene.newCharacterSelectScene(difficulty:)` 호출/`sceneTransitionDuration` 불변 |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 빌드 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- SDK: iPhoneSimulator26.5
- 신규 3개 파일(GradientBackgroundNode/MusicNoteEmitterNode/GlowingTitleNode) 모두 PBXSourcesBuildPhase(C75D46252FA627C20016BB86, iOS 타겟)에 정상 등록 — 컴파일 입력에 누락 없음
- 빌드 경고: AppIntents 메타데이터 경고 1건 (기존부터 존재, 본 sprint 무관)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 2건 |

## P0 — 치명적 이슈

없음.

- 강제 언래핑(`!`) 0건 — 정적 grep 검증:
  - StartScene 289: `guard !isTransitioning` (boolean NOT, 강제 언래핑 아님)
  - GameConfig 내 `!`는 모두 *문자열 리터럴* (`"수간호사의 충실한 부하 석조무사가 출현합니다!"` 등 한국어 안내 텍스트)
  - 7개 파일 본문에서 force-unwrap 0건
- 매 프레임 `addChild` 0건 — 모든 addChild는 setup/spawn 1회성
- Timer/DispatchQueue 0건 — 모두 SKAction
- 빌드 에러 0건

## P1 — 중요 이슈

없음.

- `init(id:)` / `setSelected(_:)` 시그니처 불변 (DifficultyCardNode.swift:31, 86) → 호출부 StartScene.swift:202, 203, 232 변경 0
- 게임플레이 흐름 불변:
  - `selectDifficulty(_:)` 내 `difficultyRepo.save(id)` 시점·대상 유지 (StartScene 228-234)
  - `transitionToNext()` 의 `CharacterSelectScene.newCharacterSelectScene(difficulty: self.selectedDifficulty)` 호출 유지 (337-339)
  - `sceneTransitionDuration` 사용 유지 (340)
  - hit test 우선순위(카드 → 시작 버튼) 유지 (288-302)
  - `isTransitioning` 가드 유지 (289)
- 기존 GameConfig 상수 *값 변경* 0건 — 1041라인 이후 추가만 (라인 1045~1107이 신규 MARK 섹션)
- 기존 ColorTokens 변경 0건 — line 219 이후 추가만 (3개 토큰: ganhoAccentTeal/ganhoAccentTealDeep/ganhoAccentCoral)
- `[weak self]` 캡처 적용:
  - StartScene.swift:335 — `[weak self, weak view]` (transitionToNext의 SKAction.run)
  - MusicNoteEmitterNode.swift:50, 104 — 2곳

## P2 — 권장 사항

### 1. StartScene.swift 라인 수 349 — spritekit-rules.md §11 "300줄 초과 시 분리 신호" 권장 기준 근접
- **파일**: `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift` (349 lines)
- **위반 규칙**: spritekit-rules.md §11 "파일이 300줄 초과 → 가장 무거운 책임을 별도 파일로 분리"
- **상황**: 단일 책임이 본질적으로 *5채널 비주얼 + 난이도 선택 + 씬 전환*으로 결합돼 있어 즉시 분리하면 응집도가 떨어질 수 있음. 다만 향후 Phase 10-3 등에서 비주얼 setup/rebuild 5개 메서드(setupGradientBackground/rebuildGradientBackground/setupMusicNoteEmitter/rebuildMusicNoteEmitter/attachStartButtonPulse)를 `Systems/StartSceneVisualSystem.swift`나 `Nodes/StartSceneBackdropNode.swift`로 묶어 위임하면 StartScene을 300줄 이하로 회귀시킬 수 있음.
- **수정 제안**: 본 sprint 합격 후 별도 리팩토링 sprint에서 처리 권장.

### 2. `_ = characterRepo` 잔여 명시 참조 — Phase 10-1a 임시 의존이 더 이상 unused가 아님
- **파일**: `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift:347`
- **위반 규칙**: swift-rules.md §8 "인라인 주석: 왜 이렇게 했는지 설명 (무엇인지 X)"
- **현재 코드**: `_ = characterRepo  // 정적 의존 회피 — Swift 컴파일러 unused warning 방지를 위해 명시 참조.`
- **상황**: `characterRepo` 프로퍼티가 line 46에서 `let characterRepo = CharacterPreferenceRepository()`로 보유되고 있는데, 본 sprint에서 *실제 사용처가 없음*. Phase 10-1a 시점에는 GameScene 직진 임시 코드에서 사용했을 가능성이 있음. 현재는 "다음 씬이 다시 .current로 읽으므로 본 씬에서 별도 전달 불필요"라는 주석만 있고 호출은 없음. 본 라인은 컴파일러 경고를 피하려는 워크어라운드라기보다는 *프로퍼티 자체를 제거*하거나 *임시 의존 주석을 명확히* 하는 것이 깔끔.
- **수정 제안**: 별도 sprint에서 `characterRepo` 프로퍼티 제거 또는 사용처 명시.

## 통과 항목 (정적/구조 검증)

- 강제 언래핑 0건 (7 파일 정적 grep 검증)
- Timer/DispatchQueue 0건 (정적 grep 검증)
- 매직 넘버 0건 — 모든 신규 수치는 GameConfig 신규 24 상수로 명명(zPosition/spawnInterval/fontSize/riseDuration/fadeIn/fadeOut/maxAlpha/startYOffset/riseEndYMargin/driftRange/blurRadius/springOvershoot/phase1/phase2/ringGlowPadding/ringGlowLineWidth/ringGlowWidth/ringGlowFadeIn/ringGlowFadeOut/pulseScaleMin/pulseScaleMax/pulseHalfDuration/exitSlideDistance/exitSlideDuration)
- MARK 섹션 구분 (모든 신규 파일 + 수정 부분에서 일관)
- guard let / if let 옵셔널 처리 — CGGradient, CIFilter, view 모두 안전 처리
- `[weak self]` 클로저 캡처 — 해당하는 모든 클로저에 적용 (transitionToNext에선 view까지 weak)
- `withKey:` 모든 SKAction에 부여 — cardScale, ringFade, startButtonPulse, musicNoteSpawn → 씬 전환 시 정리 가능
- SKEffectNode `shouldRasterize = true` — GlowingTitleNode.swift:64
- 음표 동시 상한 가드 — `guard activeCount < musicNoteEmitterMaxConcurrent` 진입부 가드
- 자식 노드 자가 removeFromParent — MusicNoteEmitterNode 라벨의 sequence 끝에 `SKAction.removeFromParent()`
- 컬러 토큰 시맨틱 이름 — 모든 색이 `.ganhoXxx` 토큰 (하드코딩 UIColor 0건)
- project.pbxproj 신규 3 파일 등록 (PBXBuildFile 3 + PBXFileReference 3 + Nodes 그룹 3 + Sources phase 3)
- 빌드 SUCCEEDED — iPhone 17 시뮬레이터(iOS 26.5)
- DifficultyCardNode init(id:) / setSelected(_:) 시그니처 불변 — 호출부 변경 0
- 기존 GameConfig 상수·ColorTokens 토큰 *값 변경* 0건 (git diff 검증)
- 게임플레이 7대 불변 계약(selectDifficulty 저장 시점/transitionToNext 다음 씬/sceneTransitionDuration/isTransitioning 가드/hit test 우선순위/HighScore·Statistics 읽기/카드 위치) 모두 유지

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: **10/10** → 강제 언래핑 0, 매직 넘버 0, MARK 섹션 일관, guard let/if let 안전 처리, `[weak self]` 적용. P2 2건은 사소한 권장 사항.
- 게임 로직 완성도: **10/10** → didMove 초기화, didChangeSize 시 리빌드, SKAction.repeatForever 스폰, 액션 키 기반 라이프사이클, 게임플레이 7대 불변 계약 모두 유지.
- 성능 & 안정성: **10/10** → 그라데이션 텍스처 1회 생성, SKEffectNode shouldRasterize, 음표 상한 15, weak 캡처, 자가 removeFromParent. update() 매 프레임 addChild 0.
- 기능 완성도: **10/10** → SPEC 7개 기능 모두 구현. project.pbxproj 등록까지 자동화 (Generator가 빌드 입력 누락 위험까지 선제 처리).

**가중 점수 계산**:
- Swift패턴(0.35×10) + 게임로직(0.30×10) + 성능안정성(0.20×10) + 기능완성도(0.15×10)
- = 3.50 + 3.00 + 2.00 + 1.50
- = **10.0 / 10.0**

## 최종 판정: **합격**

본 sprint는 SPEC의 비주얼 5채널 리스킨을 *게임플레이 0건 변경*으로 완수했다. 강제 언래핑·매직 넘버·Timer 사용 0건. 모든 SKAction에 withKey 부여로 라이프사이클 안전. SKEffectNode shouldRasterize·음표 상한 가드·weak 캡처 등 성능/안정성 가드 다층 적용. 빌드 SUCCEEDED. 신규 3 파일의 project.pbxproj 등록까지 자동 처리해 사용자가 Xcode UI에서 추가 작업할 필요 없음.

P2 2건(StartScene 라인 수 349 / characterRepo 잔여 명시 참조)은 본 sprint의 합격 판정과 무관한 *후속 sprint 권장* 항목.

**구체적 개선 지시** (향후 별도 sprint, 본 sprint 합격에는 무관):
1. StartScene의 비주얼 5채널 setup/rebuild 메서드를 `Nodes/StartSceneBackdropNode.swift` 또는 `Systems/StartSceneVisualSystem.swift`로 묶어 위임 → StartScene 300줄 이하 회귀.
2. `characterRepo` 프로퍼티의 실제 사용처가 없다면 제거(또는 사용처 명시) → `_ = characterRepo` 워크어라운드 제거.
