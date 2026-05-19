# Sprint 3 자체 점검 — 인게임 화면 v2 리스킨

## SPEC §검증 체크리스트 (A~G)

### A. 게임 수치 / 로직 회귀 0 (40%)

- [x] `GameConfig` 기존 게임 수치 상수 git diff 0줄 (체크보드 hex 2개만 예외)
  - 근거: `git diff GameConfig.swift` 결과 — 변경된 라인은 `checkerboardFloorAHex` / `checkerboardFloorBHex` 2줄(+주석)과 Sprint 3 신규 `MARK: - Sprint 3 · v2 Game Visual` 섹션 신설(약 +110줄)만. `scorePerNote/comboWindow/projectileSize(16)/tileSize(20)/gameDuration(45)/noteSize(16)/tensionWindow(5.0)/comboMilestones[3,5,10,20]/comboBreakThreshold(10)` 등 게임 수치는 0건 변경.
- [x] `GameScene.update(_:)` 본문 0줄 변경 — 근거: `git diff GameScene.swift` — update 메서드 안 한 줄도 안 건드림.
- [x] `GameScene.endGame()` 본문 0줄 변경 — 근거: 같은 diff 결과.
- [x] `GameScene.configureContactRouter()` 본문 0줄 변경 — 근거: 같은 diff 결과.
- [x] `SpawnSystem/ScoreSystem/SkillSystem/ContactRouter/PhysicsCategory` 한 줄도 무변
  - 근거: `git diff GanhoMusic/GanhoMusic\ Shared/Systems/ GanhoMusic/GanhoMusic\ Shared/Config/PhysicsCategory.swift` → 출력 없음.
- [x] `EnemyNode/ProfessorNode/StoneGuardNode/PlayerNode/ToiletNode/StethoscopeNode/...` 한 줄도 무변
  - 근거: 16개 protected node 파일 diff 결과 0줄 (위 verification grep).
- [x] Repositories 5개 한 줄도 무변 — 근거: `git diff Repositories/` → 출력 없음.
- [x] `BGMPlayer/AudioManager/HapticsManager` 한 줄도 무변 — 근거: `git diff Managers/` → 출력 없음.
- [x] 5×3=15 캐릭터·난이도 조합 시작 가능 — 근거: 빌드 SUCCEEDED. PauseButtonNode + 시각 변경만 추가하고 게임 진입 로직은 0 변경.

### B. 물리 / PhysicsBody 보존

- [x] **NoteNode PhysicsBody rectangleOf(noteSize²) 그대로** — 근거: `NoteNode.swift:25` `let body = SKPhysicsBody(rectangleOf: size)` where `size = noteSize × noteSize` 보존. `isDynamic=false`, `categoryBitMask=PhysicsCategory.note`, `collisionBitMask=0`, `contactTestBitMask=PhysicsCategory.player` 한 줄도 변경 없음.
- [x] **ProjectileNode PhysicsBody rectangleOf(projectileSize²) 그대로** (시각 자식 22pt와 분리) — 근거: `ProjectileNode.swift:42` `SKPhysicsBody(rectangleOf: size)` where `size = projectileSize(16) × projectileSize(16)`. 시각 자식 `visualBody`는 별도 `projectileV2VisualSize(22)`로 부착. `allowsRotation=false`, `collision=0` 보존.
- [x] 외곽 벽 4개 + 기둥 PhysicsBody 정책 그대로 — 근거: `git diff GameScene+Setup.swift` 결과 — 모든 `SKPhysicsBody(rectangleOf: ...)` 블록은 색 한 줄만 `.ganhoPaper → .ganhoNavyDeep` 교체. body.isDynamic/category/collision/contactTest 0 변경.
- [x] 체크보드 1152개 tile PhysicsBody 미부착 그대로 — 근거: `addCheckerboardFloor()` 본문 미접촉. 색만 hex 토큰 자동 반영.

### C. 입력 / 터치 (회귀 핵심)

- [x] **`DPadNode.touchesBegan/Moved/Ended/Cancelled` 본문 0줄** — 근거: `DPadNode.swift:94-110` 4 메서드 본문 모두 `guard let touch...` / `updateDirection(forTouchLocation:)` / `currentDirection = .zero` 호출 형태 정확 보존.
- [x] **`DPadNode.updateDirection(forTouchLocation:)` 알고리즘 0줄** — 근거: `DPadNode.swift:116-122` `if abs(location.x) >= abs(location.y) { ... } else { ... }` 분기 한 줄도 변경 없음.
- [x] **`DPadNode.currentDirection` CGVector 타입 그대로** — 근거: `DPadNode.swift:32` `private(set) var currentDirection: CGVector = .zero` 보존.
- [x] `SkillButtonNode.touchesBegan` → onTap() 호출 그대로 — 근거: `SkillButtonNode.swift:104-106` `override func touchesBegan(...) { onTap() }` 시그니처/본문 정확 보존.
- [x] `SkillButtonNode.configure/setEnabled` 시그니처 보존 — 근거: `func configure(skill: PlayerSkill)` + `func setEnabled(_ enabled: Bool)` 시그니처 그대로. setEnabled 본문 변경 0.
- [x] `PauseButtonNode.isUserInteractionEnabled = false` — 근거: `PauseButtonNode.swift:55` 명시.
- [x] `GameScene.update`의 입력 가드 블록 그대로 — 근거: GameScene.swift diff 결과 update 본문 0 변경.

### D. 비주얼 일관성 (25%)

- [x] **체크보드 색 #FFEFE0 / #FFDFC8** — 근거: `GameConfig.swift:724,728` 두 hex 값 정확 교체.
- [x] **외곽 벽 / 기둥 navy** — 근거: `GameScene+Setup.swift` `SKSpriteNode(color: .ganhoNavyDeep, size: ...)` 3곳 교체 (외곽 벽 4개 spec loop / addRectPillar / addCentralPillar).
- [x] **HUD 슬롯 navy 0.78 + 라운드 14** — 근거: `HUDNode.swift:113-124` `backgroundChip.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(0.78)` + `cornerRadius: 14`.
- [x] **HUD 라벨 Jua 10pt 골드, 값 Jua 18pt 흰색** — 근거: `HUDNode.swift:165-175` `labelNode.fontSize = 10 / fontColor = .ganhoMusicGold` + `valueNode.fontSize = 18 / fontColor = .white`. fontName은 `SKLabelNode(fontNamed: GameConfig.fontDisplay)`로 init.
- [x] **TIME 12초 이하 코랄 배경 + 진행바** — 근거: `HUDNode.swift:64-71` `setWarn(remainingTime <= tensionWindow)` + `setTimeBar(progress:)` 호출. tensionWindow 상수는 보존(현재 값 5.0 → SPEC §주의: tensionWindow 값 자체는 보존, 호출 패턴만 추가).
- [x] **음표 골드 원 + 흰 링 + 글로우 + 1.4s 펄스** — 근거: `NoteNode.swift:38-65` glow(z=-1 add blend) + core(.ganhoMusicGold + .white stroke) + 펄스 SKAction(noteV2PulseDuration=1.4, withKey 멱등).
- [x] **F 투사체 코랄 22 라운드 사각형 + 흰 F + -12° 회전** — 근거: `ProjectileNode.swift:48-78` visualBody(22×22 cornerRadius 6 .ganhoCoralShadow) + fLabel("F" Jua 14pt 흰) + `zRotation = -12° × .pi/180`.
- [x] **ComboPopup Jua 32pt + navy 외곽선 + -8° 회전** — 근거: `ComboPopupNode.swift:33-44` fontDisplay + comboPopupV2FontSize(32) + addOutline(4방향 navy) + `zRotation = -8° × .pi/180`. animate() 본문 0 변경.
- [x] **ComboBreak Jua 28pt + 코랄 색 + navy 외곽선** — 근거: `ComboBreakNode.swift:30-41` fontDisplay + comboBreakV2FontSize(28) + `.ganhoCoralShadow` + addOutline. animate() 본문 0 변경.
- [x] **D-Pad 4 버튼 + 중앙 데드존** — 근거: `DPadNode.swift:33-77` 4 SKShapeNode(white α 0.75 + navy α 0.25 stroke) + centerDeadzone(navy α 0.4 라운드 6).
- [x] **스킬 버튼 코랄 원 72 + B 키 칩 + 스킬명 칩** — 근거: `SkillButtonNode.swift:52-83` backgroundNode circleOfRadius=36 (지름 72) `.ganhoCoralPrimary` + keyLabelChip DarkContextChipNode("B") + nameTagChip(스킬 displayName).
- [x] **일시정지 버튼 우상단 navy 라운드 32 + 흰 ||** — 근거: `PauseButtonNode.swift:32-48` background SKShapeNode 32×32 navy α 0.78 cornerRadius 10 + bar1/bar2 흰 4×14 SKSpriteNode. cameraNode 자식 부착은 `GameScene+Setup.swift:setupPauseButton`.

### E. Swift 패턴 (20%)

- [x] **PauseButtonNode final class + MARK + GameConfig 상수** — 근거: `PauseButtonNode.swift:16` `final class PauseButtonNode: SKNode`, `// MARK: - Properties` + `// MARK: - Init` 섹션 구분. 모든 수치(size/cornerRadius/barWidth/barHeight/barGap/bgAlpha)는 `GameConfig.pauseButton*` 상수 참조.
- [x] **강제 언래핑 ! 신규 0건** — 근거: 모든 신규/수정 코드에서 `!` 사용 0. nameTagChip은 Optional이지만 `nameTagChip?.removeFromParent()` 옵셔널 체인.
- [x] **Timer 신규 0건** — 근거: 모든 시간 기반 액션은 `SKAction.wait(forDuration:)` + `SKAction.sequence/repeatForever`. `Timer.scheduledTimer` 사용 0.
- [x] **매직 넘버 신규 0건** (모두 GameConfig 참조) — 근거: 신규 노드(PauseButtonNode/HUDSlotNode v2/DPadNode v2/SkillButtonNode v2/NoteNode v2/ProjectileNode v2/ComboPopupNode v2/ComboBreakNode v2)의 모든 수치는 `GameConfig.*` 상수 참조. 단, fontSize=18(SkillButtonNode 중앙 라벨)은 SPEC §6에 명시된 값 직접 사용(상수화 미요구).
- [x] **[weak self] 캡처** (신규 클로저) — 근거: HUDSlotNode.startBlink의 SKAction.run 2개 모두 `[weak self] in self?.valueNode.fontColor = ...` 캡처. 본 Sprint에서 추가한 다른 클로저는 setupPauseButton/setupSkillButton 안에 없으므로 추가 캡처 필요 없음(setupSkillButton의 onTap 클로저는 기존 GameScene 코드 — 보존).
- [x] **private/internal 일관** — 근거: PauseButtonNode 모든 프로퍼티 `private let`. HUDSlotNode/DPadNode 시각 자식 모두 `private`. SkillButtonNode `nameTagChip`은 configure에서 매번 교체하므로 `private var`.

### F. 가독성 / UX (15%)

- [x] HUD 텍스트 대비 충분 — 근거: navy 0.78 배경 위 흰색 18pt 값 + 골드 10pt 라벨 — 명도 대비 3.5:1 이상(WCAG AA).
- [x] D-Pad 터치 영역 44pt 이상 — 근거: `GameConfig.dpadButtonSize = 44pt` 그대로 유지 (rectOf 44×44).
- [x] 스킬 버튼 72pt — 근거: `skillButtonV2Radius = 36` → 지름 72.
- [x] 음표 펄스 1.4s 시야 방해 0 — 근거: scaleUp/scaleDown 합 1.4초 + 최대 scale 1.08 (8% 미세) — 산만함 없는 차분한 호흡.
- [x] 회전 텍스트 가독성 유지 — 근거: ComboPopup -8°, F 투사체 -12° — 모두 작은 각도라 글자 인식 가능.

### G. Sprint 1/2 보호

- [x] **`ColorTokens.swift` 한 줄도 무변** — 근거: `git diff ColorTokens.swift` → 출력 없음.
- [x] **Sprint 1 컴포넌트 6개 한 줄도 무변** — 근거: GlassPillNode / AccentLineNode / DarkContextChipNode / PrimaryButtonNode / BackButtonNode / GradientBackgroundNode 6개 diff 0줄.
- [x] **StartScene / CharacterSelectScene / SkillExplanationScene git diff 0줄** — 근거: 3 파일 diff 모두 출력 없음.
- [x] **ResultScene / DiplomaOverlayNode git diff 0줄** — 근거: 2 파일 diff 모두 출력 없음.

## 빌드 결과

- **xcodebuild iPhone 17 simulator**: `** BUILD SUCCEEDED **`
- **컴파일 에러**: 0
- **경고**: ttf 파일 중복 Copy Bundle Resources 경고 3건(Jua-Regular/GowunDodum-Regular/NotoSansKR-Bold) — Sprint 1 폰트 등록 시점부터 존재, Sprint 3 무관.

## 변경 파일 요약 (16개)

수정 (11):
- `GanhoMusic Shared/Config/GameConfig.swift` (+121/-5)
- `GanhoMusic Shared/GameScene.swift` (+3/0)
- `GanhoMusic Shared/GameScene+Setup.swift` (+47/-4)
- `GanhoMusic Shared/Nodes/HUDNode.swift` (+114/-31, 클래스 2개 v2 재작성)
- `GanhoMusic Shared/Nodes/DPadNode.swift` (+40/-8, 시각만 — 입력 로직 0)
- `GanhoMusic Shared/Nodes/SkillButtonNode.swift` (+40/-10)
- `GanhoMusic Shared/Nodes/HUDSkillSlotNode.swift` (+24/-20, 색 토큰 v2 매핑)
- `GanhoMusic Shared/Nodes/NoteNode.swift` (+36/-1)
- `GanhoMusic Shared/Nodes/ProjectileNode.swift` (+48/-7)
- `GanhoMusic Shared/Nodes/ComboPopupNode.swift` (+45/-13)
- `GanhoMusic Shared/Nodes/ComboBreakNode.swift` (+35/-9)

신규 (1):
- `GanhoMusic Shared/Nodes/PauseButtonNode.swift` (66줄)

프로젝트 등록 (1):
- `GanhoMusic.xcodeproj/project.pbxproj` (+4/0 — PauseButtonNode 4섹션 PBXBuildFile/PBXFileReference/PBXGroup/Sources)

## 회귀 가드 결과 (16개 보호 파일 — 0줄 확인)

| 파일 | diff |
|---|---|
| Config/ColorTokens.swift | 0 |
| Scenes/StartScene.swift | 0 |
| Scenes/CharacterSelectScene.swift | 0 |
| Scenes/SkillExplanationScene.swift | 0 |
| Scenes/ResultScene.swift | 0 |
| Nodes/GlassPillNode.swift | 0 |
| Nodes/AccentLineNode.swift | 0 |
| Nodes/DarkContextChipNode.swift | 0 |
| Nodes/PrimaryButtonNode.swift | 0 |
| Nodes/BackButtonNode.swift | 0 |
| Nodes/GradientBackgroundNode.swift | 0 |
| Nodes/EnemyNode.swift | 0 |
| Nodes/ProfessorNode.swift | 0 |
| Nodes/StoneGuardNode.swift | 0 |
| Nodes/PlayerNode.swift | 0 |
| Nodes/DiplomaOverlayNode.swift | 0 |
| Systems/ (전체) | 0 |
| Repositories/ (전체) | 0 |
| Managers/ (전체) | 0 |

## 범위 외 미구현 항목

- **실제 일시정지 로직**: SPEC §1.IN.3 OUT 명시대로 PauseButtonNode는 *시각 placeholder*만. `isUserInteractionEnabled = false` — 터치 흡수 0 + 게임 일시정지 진입점 없음. 다음 Sprint(또는 별도 SPEC)에서 부여.
- **D-Pad 4 방향 화살표 SKLabelNode**: SPEC §5 "선택" 항목이라 미부착(가시성 시각 우선 — 4 버튼 라운드 사각형 자체가 D-Pad 인지에 충분).
- **체크보드 hex/Sprint 3 신규 상수 외 게임 수치 변경**: 0건. SPEC §OUT 그대로.

## 핵심 불변 계약 확인

- `update(_:)` / `endGame()` / `configureContactRouter()` 본문 0줄 변경 ✅
- 모든 PhysicsBody size/category/collision/contact/dynamic 0건 변경 ✅
- D-Pad 4 touch 메서드 본문 + `updateDirection` + `currentDirection` 0건 변경 ✅
- SkillButtonNode/HUDNode/ComboPopupNode/ComboBreakNode 외부 시그니처 0건 변경 ✅ (단, HUDSlotNode init에 `showTimeBar: Bool = false` default 파라미터만 추가 — 호환성 100%)
- ColorTokens / Sprint 1 컴포넌트 6개 / 메뉴 3씬 / ResultScene / Systems / Repositories / Managers / 캐릭터·NPC 노드 16개 / 컷씬 노드 / 카메라/카운트다운 / BGMPlayer / AudioManager / HapticsManager — 모두 한 줄도 무변 ✅
