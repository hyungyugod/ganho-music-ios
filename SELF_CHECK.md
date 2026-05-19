# 자체 점검 — Phase 10-2 · StartScene 모던 리스킨 (병동의 새벽 톤)

## SPEC 검증 체크리스트 (13개 항목 — SPEC.md §검증 체크리스트)

- [x] **StartScene 외 다른 씬(.swift) 파일 수정 0건**
  - 수정한 씬 파일: `Scenes/StartScene.swift` 단 1개. CharacterSelectScene / SkillExplanationScene / GameScene / ResultScene 모두 미변경.
- [x] **GameScene·CharacterSelectScene·SkillExplanationScene 변경 0건**
  - grep 확인: 본 sprint에서 해당 파일 수정 이력 없음.
- [x] **GameConfig 기존 상수 *값 변경* 0건 (신규 MARK 섹션만 추가)**
  - `// MARK: - Start Scene Visual (Phase 10-2 · 병동의 새벽 톤)` 섹션 신설. 기존 1044라인 → 신규 추가만으로 1120라인으로 확장. 기존 상수 변경 없음. (단, Phase 10-1d 주석의 오타 "시그니형" → "시그니처" 1자 정정 — *값* 변경 아님)
- [x] **ColorTokens 기존 토큰 변경 0건**
  - `// MARK: - Accent (Phase 10-2 · 병동의 새벽 톤)` 섹션 신설. `ganhoAccentTeal` / `ganhoAccentTealDeep` / `ganhoAccentCoral` 3개 토큰만 추가. `UIColor(hex:)` 헬퍼는 *기존* — 재활용.
- [x] **DifficultyCardNode `init(id:)` / `setSelected(_:)` 시그니처 불변**
  - `init(id: Difficulty)` 그대로. `setSelected(_ selected: Bool)` 그대로. 내부 자식 `ringGlow: SKShapeNode` private 추가만. StartScene 호출부 0줄 변경.
- [x] **StartScene의 `selectDifficulty(_:)` / `transitionToNext()`의 *게임플레이 동작* 불변 (저장 시점·다음 씬·난이도 전달)**
  - `selectDifficulty`: `difficultyRepo.save(id)` 시점/대상 그대로.
  - `transitionToNext`: `CharacterSelectScene.newCharacterSelectScene(difficulty: selectedDifficulty)` 호출 보존. `SKTransition.fade(withDuration: GameConfig.sceneTransitionDuration)` 보존. 슬라이드업 + fadeOut은 *prelude*로 *추가*된 시각 효과일 뿐 전환 대상/난이도 변경 없음.
- [x] **강제 언래핑 `!` 사용 0건**
  - `CIFilter(name: "CIGaussianBlur")` → `if let blurFilter = ...` 옵셔널 처리 (GlowingTitleNode).
  - `CGGradient` → `guard let gradient = ...` 옵셔널 처리 (GradientBackgroundNode).
  - `randomElement()` → `?? "♪"` nil-coalesce 처리 (MusicNoteEmitterNode).
  - `[weak self]` 클로저에서 모두 `self?` 또는 `guard let self`.
  - 작업한 5개 파일에 `!` (force unwrap) 0건 — grep 확인.
- [x] **`Timer.scheduledTimer` 사용 0건 — 모두 SKAction**
  - MusicNoteEmitterNode: `SKAction.repeatForever(sequence([run, wait]))` 패턴.
  - StartScene transitionToNext: `SKAction.sequence([wait, run])` 패턴.
  - 시작 버튼 pulse: `SKAction.repeatForever(sequence([down, up]))` 패턴.
  - Timer 호출 0건.
- [x] **매직 넘버 0건 — 모두 GameConfig 상수**
  - 새로 추가한 모든 수치(zPosition, fontSize, duration, scale, padding, lineWidth, glowWidth, slide distance 등)는 GameConfig.swift 신규 MARK 섹션에 명명 상수로 정의.
  - `0.0` / `1.0` (alpha 한계값)은 의미가 자명한 sentinel 이라 인라인 유지.
  - `.zero` / `1.0` (단위 scale 복귀)도 동일.
- [x] **클로저 `[weak self]` 캡처 적용**
  - MusicNoteEmitterNode: `SKAction.run { [weak self] in self?.spawnOneNote() }`, `SKAction.run { [weak self] in ... activeCount = max(0, self.activeCount - 1) }` 2곳.
  - StartScene.transitionToNext: `SKAction.run { [weak self, weak view] in ... }` — view까지 weak로 캡처.
  - DifficultyCardNode.setSelected: SKAction 클로저 없음 (액션 빌더만 사용) — 캡처 대상 없음.
- [x] **음표 동시 상한 가드 작동 (`activeCount < musicNoteEmitterMaxConcurrent`)**
  - MusicNoteEmitterNode.spawnOneNote 진입부: `guard activeCount < GameConfig.musicNoteEmitterMaxConcurrent else { return }`.
  - 라벨 생성 시 activeCount += 1, decrement 액션에서 -1 — 누수 없음.
  - 상한값: 15 (GameConfig.musicNoteEmitterMaxConcurrent).
- [x] **SKEffectNode `shouldRasterize = true` 적용**
  - GlowingTitleNode: `effect.shouldRasterize = true` — 매 프레임 블러 재계산 0.
  - `shouldEnableEffects = true` (필터 있을 때만), `zPosition = -1` (본 라벨 뒤).
- [x] **빌드 에러 0건, 콘솔 경고 최소화**
  - `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build` → **`** BUILD SUCCEEDED **`**.
  - 경고 1건(`appintentsmetadataprocessor: Metadata extraction skipped. No AppIntents.framework dependency found.`) — 본 sprint 변경과 무관, 기존 프로젝트 톤.
- [ ] **시뮬레이터에서 60fps 유지 확인 (디버그 통계)**
  - **미실행** — Generator 단계는 빌드까지만. 실제 60fps 측정은 사용자가 시뮬레이터에서 `view.showsFPS = true`로 확인할 것. SPEC §성능 가드 항목에 따른 정적 분석 통과:
    - 음표 상한 15개 + repeatForever 단일 스폰 액션 = 음표 부담 ≤ 60fps 한도.
    - 그라데이션 텍스처 didMove 1회 생성 → 매 프레임 갱신 0.
    - SKEffectNode shouldRasterize = true → 블러 1회 cache.
    - 모든 액션 withKey 부여 → 씬 전환 시 정리 가능.
    - addChild는 setup/spawn 시점만 — `update()` 매 프레임 addChild 0.

---

## 추가 작업: project.pbxproj 신규 파일 등록

본 프로젝트는 PBXFileSystemSynchronizedRootGroup + 명시적 PBXBuildFile/PBXFileReference *하이브리드* 구성이다.
- 동기화 그룹만으로는 새 .swift 파일이 빌드 입력에 누락된다 (실측 확인: 첫 빌드 시 신규 3파일 컴파일 시도 0).
- 따라서 신규 3개 파일을 `GanhoMusic.xcodeproj/project.pbxproj`에 *명시적으로* 추가:
  - PBXBuildFile section: 3개 항목 추가 (ID: A1C0F1B00000000000000053~55)
  - PBXFileReference section: 3개 항목 추가 (ID: A1C0F1A00000000000000053~55)
  - Nodes 그룹 children에 3개 항목 추가
  - PBXSourcesBuildPhase(iOS 타겟) files에 3개 항목 추가
- 사용자 주의: 본 변경은 사용자가 Xcode UI에서 다시 파일을 *추가*할 필요 없도록 *자동* 등록한다. Xcode를 재열고 작업하면 정상 인식.

---

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수
- guard let / if let 옵셔널 처리: 준수
- MARK 섹션 구분: 준수 (모든 신규 파일 + 수정 부분)
- GameConfig 상수 사용: 준수 (매직 넘버 0건)
- weak self 캡처: 준수 (해당하는 모든 클로저)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수 (StartScene.didMove에서 5채널 setup 호출)
- dt 기반 이동: 해당 없음 (본 sprint는 SKAction 기반 — update 미사용)
- SKAction 스폰 패턴: 준수 (MusicNoteEmitter.repeatForever 패턴)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (본 sprint physicsBody 0)
- HUD 노드 분리: 해당 없음 (StartScene은 HUD 미사용)
- SKEffectNode shouldRasterize=true: 준수 (GlowingTitleNode)
- 모든 SKAction에 withKey 부여: 준수 (cardScale, ringFade, startButtonPulse, musicNoteSpawn)

## 빌드 상태
- 빌드 결과: `** BUILD SUCCEEDED **` (iPhone 17 시뮬레이터, iOS 26.4.1)
- 신규 파일 컴파일 확인: GradientBackgroundNode / MusicNoteEmitterNode / GlowingTitleNode 모두 정상 컴파일.
- 수정 파일 컴파일 확인: StartScene / GameConfig / ColorTokens / DifficultyCardNode 정상.
- 예상 에러: 없음.
- 주의 필요 경고: AppIntents 메타데이터 경고 1건 — 본 sprint 무관(기존부터 존재).

## 범위 외 미구현 항목
- 60fps 실측: 시뮬레이터 실행 단계는 사용자 영역. 정적 분석상 성능 가드 모든 항목 통과.
- 본 sprint 범위 외 변경 0건.

---

## 변경 파일 요약 (절대경로)
1. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift` — 비주얼 5채널 추가 (그라데이션 / 음표 / 글로우 제목 / pulse / exit slide), 게임플레이 불변
2. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — Phase 10-2 MARK 섹션 신설 (~24 신규 상수)
3. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift` — Accent MARK 섹션 신설 (3 신규 토큰)
4. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Nodes/DifficultyCardNode.swift` — ringGlow 자식 + spring overshoot (시그니처 불변)
5. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Nodes/GradientBackgroundNode.swift` — 신규 (SKSpriteNode 서브클래스, CGGradient → SKTexture 1회 생성)
6. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Nodes/MusicNoteEmitterNode.swift` — 신규 (SKNode 서브클래스, repeatForever 스폰 + 상한 가드)
7. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic Shared/Nodes/GlowingTitleNode.swift` — 신규 (SKNode 서브클래스, SKEffectNode + CIGaussianBlur 글로우 컨테이너)
8. `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/practical-joliot-42cfcd/GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 신규 3개 .swift 파일 빌드 등록 (PBXBuildFile / PBXFileReference / Nodes 그룹 / Sources phase)
