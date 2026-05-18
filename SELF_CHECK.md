# 자체 점검 — Phase 10-1 시작 시퀀스 4단계 오버레이 분리

전략: (1회차)

## SPEC 기능 체크

### 10-1a — StartScene
- [x] `Nodes/StoryBoxNode.swift` 신규 — SKShapeNode 카드 패널 + SKLabelNode 본문(numberOfLines=0 + preferredMaxLayoutWidth)
- [x] `Nodes/PrimaryButtonNode.swift` 신규 — 캡슐 SKShapeNode(cornerRadius=height/2) + 코럴 fill + brand stroke + ganhoPaper 텍스트, contains(_:) hit-test 지원
- [x] `Nodes/BackButtonNode.swift` 신규 — 투명 fill + 흰색 7% stroke + ganhoUITextMuted 텍스트
- [x] `Scenes/StartScene.swift` 신규 — 제목 + 부제 + BEST/PLAYS + 스토리 박스 + 난이도 3장 + 시작 버튼. TitleScene 패턴 답습
- [x] `GameViewController.swift` 1줄 변경 — `TitleScene.newTitleScene()` → `StartScene.newStartScene()`
- [x] `GameConfig.swift` 10-1a 상수 19개 추가 (start scene 7개 + storyBox 4개 + primaryButton 3개 + backButton 3개 + spacing 2개)

### 10-1b — CharacterSelectScene
- [x] `Scenes/CharacterSelectScene.swift` 신규 — 헤더 + 5 카드 + 5 태그 라벨(카드 외부) + 뒤로/시작 2 버튼
- [x] `CharacterID.swift`에 `tag: String` computed property 추가 (5 case 분기)
- [x] StartScene "시작" → CharacterSelectScene(difficulty 주입)
- [x] CharacterSelectScene "← 난이도 다시" → StartScene
- [x] "이 친구로 시작" 분기: .kim → GameScene 직진 / 그 외 → SkillExplanationScene
- [x] `GameConfig.swift` 10-1b 상수 9개 추가

### 10-1c — SkillExplanationScene + 김간호 스킵 + TitleScene 삭제
- [x] `Scenes/SkillExplanationScene.swift` 신규 — 헤더 + 큰 아바타(120×150, PixelSpriteRenderer 7.5× 확대) + 스킬명 + StoryBoxNode 재사용 + 조작 안내 + 뒤로/시작
- [x] `PlayerSkill.swift`에 `fullDescription: String` computed property 추가 (5 case 분기)
- [x] CharacterSelectScene .kim 분기 → GameScene 직진 (스킬 화면 스킵)
- [x] SkillExplanationScene "← 캐릭터 다시" → CharacterSelectScene(difficulty 유지)
- [x] "시작" → GameScene(characterID + difficulty 명시 주입)
- [x] `TitleScene.swift` 완전 삭제 + .pbxproj에서 4 위치 모두 제거 (PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase)
- [x] `ResultScene.swift`의 `TitleScene.newTitleScene()` → `StartScene.newStartScene()` 1줄 — 필수 연동 변경(빌드 보존)
- [x] `GameConfig.swift` 10-1c 상수 13개 추가

### 10-1d — 석조무사 경고 컷씬
- [x] `GameConfig.stoneGuardWarningTitle` / `stoneGuardWarningBody` 2개 상수 추가
- [x] `GameScene.showStoneGuardWarningCutscene()` 새 메서드 추가 — showProfessorWarningCutscene 정확 미러
- [x] `showIntroCutscene` onDismiss 분기 수정 — `switch difficulty { case .easy/.normal → showStoneGuard / case .hard → showProfessor }`
- [x] `didMove`의 `hasSeenIntro=true` 분기 수정 — 같은 switch 패턴으로 매 판 경고 환기

### .pbxproj 변경
- [x] PBXBuildFile 6개 추가 + TitleScene 1개 제거
- [x] PBXFileReference 6개 추가 + TitleScene 1개 제거
- [x] Nodes 그룹에 3개 추가
- [x] Scenes 그룹에 3개 추가 + TitleScene 1개 제거
- [x] PBXSourcesBuildPhase 6개 추가 + TitleScene 1개 제거

## Swift 패턴 준수
- 강제 언래핑 미사용: 준수 (모든 view 옵셔널은 `guard let view = self.view` 패턴)
- guard let 옵셔널 처리: 준수 (StartScene/CharacterSelectScene/SkillExplanationScene 모든 transition 메서드)
- MARK 섹션 구분: 준수 (Properties / Factory / Init / Lifecycle / Setup / Touch 표준 분할)
- GameConfig 상수 사용: 준수 (좌표/폰트/spacing 매직 넘버 0건 — overlayPanel 4 라인의 panelHeight=480만 기존 TitleScene/ResultScene 패턴 그대로 답습)
- weak self 캡처: 준수 (GameScene showStoneGuardWarningCutscene의 onDismiss 클로저에 `[weak self]` + guard let self)
- switch default 미사용: 준수 (Difficulty 2 분기 / CharacterID 5 분기 모두 exhaustive)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: 준수 (3 새 씬 모두 setup* 메서드 호출 분리)
- dt 기반 이동: 해당 없음 (UI 씬, update 미사용)
- SKAction 스폰 패턴: 해당 없음 (스폰 없음)
- 충돌 후 노드 즉시 삭제 없음: 해당 없음 (physics 미사용)
- HUD 노드 분리: 해당 없음 (UI 씬, HUD 없음)
- Timer 미사용: 준수 (SKTransition.fade와 SKAction만 사용)
- CutsceneOverlayNode 재사용: 준수 (showStoneGuardWarningCutscene이 신규 노드 0건으로 present 호출)
- isUserInteractionEnabled 패턴: 준수 (CharacterCardNode/DifficultyCardNode contains(_:) hit-test)

## 회귀 차단 검증
- GameScene 게임플레이 로직 (update/contact/skill/setup) 0줄 변경: 준수
- ResultScene 내부 로직 0줄: 준수 (외부 시그널 1줄만 — TitleScene → StartScene)
- CharacterCardNode / DifficultyCardNode 내부 0줄 변경: 준수 (재사용만, 태그 라벨은 *외부* SKLabelNode로 별도 추가)
- CutsceneOverlayNode 0줄: 준수
- PixelSpriteRenderer / PixelSprite / PixelPalette 0줄: 준수 (큰 아바타용 재사용만)
- Repositories 0줄: 준수
- isTransitioning 가드: 준수 (3 새 씬 모두 보유)
- 옵셔널 view 가드: 준수 (모든 presentScene 직전 `guard let view = self.view`)

## 빌드 상태
- 예상 빌드 에러: 없음 (`xcodebuild` BUILD SUCCEEDED 확인)
- 주의 필요 경고: 없음 (warning 0건, error 0건)
- 빌드 대상: `iPhone 17 iOS Simulator, Debug, GanhoMusic iOS`

## 범위 외 미구현 항목
- 없음 (SPEC §"변경 범위" 100% 구현 + .pbxproj 정합 + ResultScene 1줄 필수 연동만 추가)
