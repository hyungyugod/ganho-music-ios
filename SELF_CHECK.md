# 자체 점검 — Phase 7-3 인트로 컷씬 (자가 소멸 노드 10호)

## git status / git diff --stat

```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift     (+33 lines)
modified:   GanhoMusic/GanhoMusic Shared/Config/GameState.swift      (+2 lines)
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift             (+38 / -2 lines)
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj          (+4 lines)
new file:   GanhoMusic/GanhoMusic Shared/Nodes/CutsceneOverlayNode.swift  (185 lines)

총합 (소스): 4 files changed, 77 insertions(+), 2 deletions(-) (CutsceneOverlayNode.swift는 untracked 신규)
```

---

## SPEC §"기능 상세" 4개 항목별 라인 매핑

### 기능 1 — GameState `.cutscene` case 신설
- **파일**: `GanhoMusic Shared/Config/GameState.swift`
- **라인**: 15 (case 추가 위치: `.waiting` 다음, `.countdown` 이전 — SPEC 명시 위치 정확 일치)
- **헤더 주석**: 7번째 줄에 `Phase 7-3 · .cutscene case 추가` 1줄 첨가
- 회귀: 기존 case 5개(`.waiting/.countdown/.playing/.paused/.gameOver`) 미접촉.

### 기능 2 — CutsceneOverlayNode 신설 (자가 소멸 노드 10호)
- **파일**: `GanhoMusic Shared/Nodes/CutsceneOverlayNode.swift` (신규, 185줄)
- **타입 선언**: 35줄 `final class CutsceneOverlayNode: SKNode, SelfDismissingNode` (SPEC 명시 그대로)
- **private init**: 47~73줄 — 4 자식 노드(background/titleLabel/bodyLabel/tapLabel) 생성 + alpha 0 + isUserInteractionEnabled = true + zPosition 부여
- **required init?(coder:)**: 75~77줄 — fatalError 폴백 (다른 자가 소멸 노드 답습)
- **정적 팩토리 `present`**: 87~99줄 — 시그니처 `(title:body:parent:sceneSize:onDismiss:)` SPEC 일치, fadeIn 발화
- **touchesBegan override**: 105~107줄 — `dismiss()` 호출
- **dismiss()**: 116~127줄 — 첫 줄 `isUserInteractionEnabled = false`(다중 탭 차단) → onDismiss 캡처 + nil 토글 → fadeOut + cleanup + notify 시퀀스
- **configure private 메서드 4개**: 132~177줄 (background/title/body/tap)
- **bodyLabel**: 158~167줄 — `numberOfLines = 0` + `preferredMaxLayoutWidth = sceneSize.width * GameConfig.cutsceneBodyWidthRatio`
- **tapLabel alpha**: 173줄 — `alpha = GameConfig.cutsceneTapLabelAlpha`
- **색**: `.ganhoPaper` 재사용 (configureTitleLabel/configureBodyLabel/configureTapLabel) — 새 토큰 0건
- **패턴 답습**: ScorePopupNode 9호의 private init + 정적 팩토리 패턴, CountdownNode 8호의 `SKAction.sequence([fadeOut, cleanup, notify])` 패턴 일관 유지

### 기능 3 — GameScene didMove + showIntroCutscene()
- **파일**: `GanhoMusic Shared/GameScene.swift`
- **didMove 변경**: 149~152줄 — `gameState = .countdown` + `showCountdown()` → `gameState = .cutscene` + `showIntroCutscene()`로 2줄 교체 (SPEC §"기능 3" 정확 일치)
- **didMove 주변 주석**: Phase 7-3 의도 설명 3줄 추가 (회귀 0 자연 차단 메커니즘 명시)
- **showIntroCutscene() 신설 위치**: 155~187줄 (`showCountdown()` *위*에 신설 — SPEC 명시 위치)
- **MARK 섹션**: 155줄 `// MARK: - Cutscene (Phase 7-3)` — `// MARK: - Countdown (Phase 6-13)` 위
- **switch difficulty 분기**:
  - `case .easy, .normal`: "수간호사가 순찰을 돈다. 그 틈을 타, {NAME}는 주머니 속 작곡 노트를 슬쩍 꺼낸다… 음표를 모으자."
  - `case .hard`: "학교에서 나온 깐깐한 이교수가 오늘따라 청진기를 휘두른다. 날아오는 청진기를 피하며 음표를 모으자. 수간호사는 언제나 그렇듯 순찰을 돈다."
- **{NAME} 치환**: `template.replacingOccurrences(of: "{NAME}", with: characterID.displayName)` (SPEC 명시 그대로)
- **present 호출**: `CutsceneOverlayNode.present(title:, body:, parent: cameraNode, sceneSize: size, onDismiss: { ... })`
- **onDismiss 클로저**: `[weak self]` 캡처 → `guard let self = self else { return }` → `self.gameState = .countdown` + `self.showCountdown()` (CountdownNode 패턴 답습)

### 기능 4 — GameConfig 컷씬 상수 신설
- **파일**: `GanhoMusic Shared/Config/GameConfig.swift`
- **MARK**: 534줄 `// MARK: - Cutscene (Phase 7-3)` — 파일 *맨 아래* 신설 (기존 § 미접촉)
- **상수 11개** (SPEC §"기능 4" 명시 값 정확 일치):
  | 라인 | 상수명 | 값 |
  |---|---|---|
  | 537 | cutsceneBackgroundAlpha | 0.85 |
  | 540 | cutsceneTitleFontSize | 26 |
  | 543 | cutsceneBodyFontSize | 20 |
  | 545 | cutsceneTapFontSize | 16 |
  | 548 | cutsceneTitleOffsetY | 100 |
  | 550 | cutsceneTapOffsetY | -120 |
  | 553 | cutsceneBodyWidthRatio | 0.7 |
  | 556 | cutsceneZPosition | 300 |
  | 559 | cutsceneFadeInDuration | 0.25 |
  | 562 | cutsceneFadeOutDuration | 0.3 |
  | 565 | cutsceneTapLabelAlpha | 0.7 |

### pbxproj 등록 (CutsceneOverlayNode.swift) — ScorePopupNode 답습 4지점
- **PBXBuildFile** (49줄): `A1C0F1B00000000000000038 /* CutsceneOverlayNode.swift in Sources */`
- **PBXFileReference** (92줄): `A1C0F1A00000000000000038 /* CutsceneOverlayNode.swift */ = {... path = CutsceneOverlayNode.swift; ...}`
- **PBXGroup Nodes** (239줄): Nodes group `children`에 추가 (ScorePopupNode/DifficultyCardNode 뒤)
- **PBXSourcesBuildPhase iOS** (518줄): `C75D46252FA627C20016BB86` 빌드 페이즈 `files` 배열에 추가
- tvOS/macOS 빌드 페이즈는 SPEC §"회귀 0 영역" 미접촉 (기존 Sources도 모두 빈 배열로 유지) — 정확 일치

---

## 회귀 0 영역 git diff 0줄 확인 (전체 목록)

`git diff --stat HEAD -- [규칙 목록]` 명령 결과 **출력 0줄** = 전 영역 0줄 변경 확인:

- [x] `GanhoMusic Shared/Scenes/TitleScene.swift` — 0줄
- [x] `GanhoMusic Shared/Scenes/ResultScene.swift` — 0줄
- [x] `GanhoMusic Shared/GameScene+Setup.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/PlayerNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/EnemyNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/StoneGuardNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/NoteNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/ProjectileNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/DPadNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/HUDNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/CountdownNode.swift` — **0줄 (SPEC §"주의사항 2" 완전 보존 확인)**
- [x] `GanhoMusic Shared/Nodes/ScorePopupNode.swift` — 0줄 (자가 소멸 9호)
- [x] `GanhoMusic Shared/Nodes/ComboPopupNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/ComboBreakNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/CharacterCardNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/DifficultyCardNode.swift` — 0줄
- [x] `GanhoMusic Shared/Nodes/AirplaneNode.swift` / `AirforceOverlayNode.swift` / `BombFlashNode.swift` / `SparkleEffectNode.swift` / `HitFlashNode.swift` — 0줄
- [x] `GanhoMusic Shared/Systems/ContactRouter.swift` — 0줄
- [x] `GanhoMusic Shared/Systems/SpawnSystem.swift` — 0줄
- [x] `GanhoMusic Shared/Systems/ScoreSystem.swift` — 0줄
- [x] `GanhoMusic Shared/Systems/CameraShakeAction.swift` — 0줄
- [x] `GanhoMusic Shared/Managers/BGMPlayer.swift` — 0줄
- [x] `GanhoMusic Shared/Managers/AudioManager.swift` — 0줄
- [x] `GanhoMusic Shared/Managers/HapticsManager.swift` — 0줄
- [x] `GanhoMusic Shared/Config/ColorTokens.swift` — 0줄
- [x] `GanhoMusic Shared/Config/PhysicsCategory.swift` — 0줄
- [x] `GanhoMusic Shared/Models/CharacterID.swift` / `Difficulty.swift` / `GameStats.swift` — 0줄
- [x] `GanhoMusic Shared/Repositories/HighScoreRepository.swift` / `StatisticsRepository.swift` / `CharacterPreferenceRepository.swift` / `DifficultyPreferenceRepository.swift` — 0줄
- [x] `GanhoMusic iOS/GameViewController.swift` / `AppDelegate.swift` / `SceneDelegate.swift` — 0줄
- [x] `GanhoMusic tvOS/GameViewController.swift` — 0줄
- [x] `GanhoMusic macOS/GameViewController.swift` — 0줄

### GameScene.swift 변경 범위 검증
`git diff GameScene.swift` 결과 정확 2 hunk:
1. **didMove 끝 2줄 교체** (149~150 → 149~152): `gameState = .countdown` + `showCountdown()` → `gameState = .cutscene` + `showIntroCutscene()` (+ 주석 3줄)
2. **showIntroCutscene 메서드 신설** (153~187, 35줄, `// MARK: - Cutscene (Phase 7-3)` 섹션)

**GameScene.swift 변경 외 메서드는 0건 접촉** — update / endGame / configureContactRouter / showCountdown / startGameProperly / triggerAirforceEasterEgg / playComboMilestoneFeedback / triggerComboBreak / checkAndTriggerComboBreak / layoutDPad / layoutHUD / didChangeSize / setup* 일체 0줄 변경.

---

## 빌드 결과

```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
           -target "GanhoMusic iOS" \
           -sdk iphonesimulator \
           EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" \
           clean build
```

- **결과**: `** BUILD SUCCEEDED **`
- **컴파일 성공 파일 목록**: CutsceneOverlayNode.swift 포함 (Compiling 목록 마지막에 명시 확인)
- **Swift 컴파일 경고**: 0건 (Metadata extraction skipped 경고는 AppIntents 미사용 표준 메시지, 코드 경고 아님)
- **링킹**: arm64 + x86_64 lipo 성공, CodeSign / Validate / Touch 정상 종료

---

## 정적 검사

### 강제 언래핑 (`!`)
- `CutsceneOverlayNode.swift`: 0건 (`grep "!"` 출력 0줄)
- `GameScene.swift` 변경 부분: 0건 (`replacingOccurrences` 등 안전 API만 사용)
- `GameConfig.swift` / `GameState.swift` 변경 부분: 0건

### 매직 넘버
- `CutsceneOverlayNode.swift`: 0건. 모든 폰트/오프셋/알파/duration이 `GameConfig.cutscene*` 상수 참조.
- 유일 비-GameConfig 리터럴: `.zero` (CGPoint 기본값), `0` (zPosition 본 노드 내부 자식 z, 배경=0/라벨=1 시각 위계), `1` (자식 z, 본 노드 좌표계 *내부* 위계 — GameConfig 노출 가치 ↓).
- `GameScene.swift` 변경 부분: 텍스트 리터럴(타이틀/난이도별 본문)만 — 의도된 도메인 상수.

### Timer / DispatchQueue
- 4개 파일(CutsceneOverlayNode/GameScene/GameConfig/GameState) 전체 0건 (`grep "Timer\|DispatchQueue"` 출력 0줄)
- 모든 지연/시퀀스가 SKAction (fadeIn/fadeOut/wait/sequence/run) 기반

### 메모리 안전
- onDismiss 클로저: `[weak self]` + `guard let self` 패턴 (GameScene 178~185줄)
- SKAction.run notify: self 미사용 → [weak self] 불필요 (CountdownNode 동일 정책)
- onDismiss 캡처 후 nil 토글: 다중 발화 차단 (2중 안전망)

---

## SPEC §"주의사항" 12개 준수 여부

| # | 항목 | 준수 |
|---|---|---|
| 1 | GameState exhaustive switch 0건 검증 | OK — `grep "switch.*gameState"` 결과 **0건**. 다른 파일 영향 0 |
| 2 | CountdownNode 완전 보존 (dismiss 후 showCountdown() 그대로) | OK — CountdownNode.swift / showCountdown() 0줄 변경, dismiss onDismiss에서 호출만 |
| 3 | 자가 소멸 패턴 변형 — SelfDismissingNode marker protocol 채택 + 터치 트리거 | OK — `final class CutsceneOverlayNode: SKNode, SelfDismissingNode` + touchesBegan override |
| 4 | isUserInteractionEnabled = true (init) 필수 | OK — init 64줄에서 명시 설정 |
| 5 | 다중 탭 방지 (dismiss 첫 줄 false 토글 + onDismiss nil 캡처) | OK — dismiss 118~121줄 |
| 6 | 본문 자동 줄바꿈 (numberOfLines = 0 + preferredMaxLayoutWidth) | OK — configureBodyLabel 165~166줄 |
| 7 | 폰트 가시성 (제목 26 / 본문 20 / TAP 16, .ganhoPaper, 배경 .black α=0.85) | OK — GameConfig 상수값 + configure 메서드 4개 |
| 8 | showCountdown private 접근 제한자 변경 0 | OK — `private func showCountdown()` 그대로, 동일 클래스 내부 호출 |
| 9 | resize 대응 불필요 (짧은 수명) | OK — 본 노드는 didChangeSize 미구독, 호출부에서도 layout* 호출 0건 |
| 10 | pbxproj 등록 (ScorePopupNode 답습 4지점: PBXBuildFile/FileReference/Group/SourcesBuildPhase iOS) | OK — 4지점 정확 등록, tvOS/macOS Sources는 기존 빈 배열 유지 |
| 11 | 메모리 관리 ([weak self] 캡처 — CountdownNode 답습) | OK — onDismiss `[weak self]` + `guard let self` (GameScene 178줄) |
| 12 | {NAME} 치환 (easy/normal 본문에 1개 등장) | OK — `replacingOccurrences(of: "{NAME}", with: characterID.displayName)` (GameScene 173줄). hard 본문은 토큰 없어 자연 무동작 |

---

## GameState case 추가가 다른 파일 컴파일에 미치는 영향 검증

### grep 검증
```bash
grep -rn "switch.*gameState\|switch gameState" GanhoMusic/
```
- 결과: **0건**
- 결론: exhaustive switch 0개 → case 추가가 다른 파일 컴파일 에러 유발 0건
- 모든 gameState 비교는 equality 기반(`== .playing` / `== .gameOver`) → 새 case 무관

### 영향 분석 (SPEC 영향 분석 표 기준)
| 파일:라인 | 코드 | 영향 |
|---|---|---|
| GameScene.swift:149 | `gameState = .countdown` → `.cutscene` | **의도된 변경 — 본 sprint 핵심** |
| GameScene.swift:181 | `gameState = .playing` (startGameProperly) | 무영향 |
| GameScene.swift:242 | `guard gameState == .playing` (update) | **핵심 차단점 — `.cutscene`에서 모든 시스템 정지** (SPEC 회귀 0 자연 차단 메커니즘 1번) |
| GameScene.swift:473 | `if gameState == .gameOver` (endGame) | 무영향 |
- 외부 파일에서 `gameState` 직접 비교 0건 (GameScene 내부 전용 프로퍼티)

### 회귀 0 자연 차단 8개 (SPEC 명시)
1. update 폴링 — `guard gameState == .playing`이 `.cutscene` 자동 차단 (7개 시스템 동시 정지) — OK
2. SpawnSystem.start 미호출 — startGameProperly 안 → countdown 후 도달 — OK
3. bgm.play 미호출 — 동일 — OK
4. player velocity 0 — didMove 직후 누적 0 — OK (조작 미반영)
5. 컷씬 노드 cameraNode 자식 — worldNode/HUD 시각 분리 — OK (`parent: cameraNode` 명시)
6. EnemyNode/ProjectileSpawn 미실행 — update 차단으로 자동 — OK
7. ContactRouter 콜백 미발화 — 노드 간 접촉 경로 0 (player 미이동) — OK
8. 다중 탭 차단 — isUserInteractionEnabled 토글 + onDismiss nil 캡처 — OK (dismiss 118~121줄)

---

## 범위 외 미구현 항목

**없음** — SPEC §"기능 상세" 4개 + pbxproj 등록 + 빌드 검증 + 회귀 0 확인 모두 완수.

다음 sprint로 의도적 보류:
- mid1 / mid2 / introStoneGuard / introProfessor 컷씬 (SPEC §"금지")
- 컷씬 중복 표시 방지 Set (SPEC §"영구 저장 동작" — *intro는 매 게임 시작 시 표시*)
- 새 ColorTokens / 새 사운드 / 새 햅틱 (SPEC §"금지")
