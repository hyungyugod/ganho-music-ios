# 자체 점검 — 디바이스 잘림 해소 + 카드 시인성 강화 (Sprint 7)

## 전략

Case A — 1회차. SPEC.md 정밀 구현. QA 피드백 없음(초회).

## 수정 파일 목록

- `GanhoMusic/GanhoMusic iOS/GameViewController.swift` — SKView를 view.safeAreaLayoutGuide.layoutFrame에 mount. view.backgroundColor = .ganhoBgWarmTop fallback. viewSafeAreaInsetsDidChange / viewDidLayoutSubviews에서 relayoutSKView() 호출. relayoutSKView() 내부 `if skView.frame != target` 가드.
- `GanhoMusic/GanhoMusic Shared/Models/Difficulty.swift` — `description: String` computed property 신규(3 case 모두). `: CustomStringConvertible` 채택은 의도적으로 *하지 않음*.
- `GanhoMusic/GanhoMusic Shared/Nodes/DifficultyCardNode.swift` — 카드 크기 V3(112×82), descriptionLabel 신규, fontName Jua/Gowun Dodum 명시, 미선택 알파 0.78, 미선택 fill id.color α 0.08, stroke id.color α 0.4, 라벨 색 .ganhoNavyDeep / .ganhoNavyMuted 토큰 동기화, ringGlow 코너 반경도 카드와 동일(20).
- `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift` — cardBaseX(for:)에서 spacing `characterSelectCardSpacingV3`(22pt) 사용. cardBaseY(for:)에 짝수 인덱스(0/2/4) +8 / 홀수(1/3) -8 지그재그 y 오프셋 적용. 카드/컨테이너/색점/얼굴/태그/링글로우가 모두 같은 헬퍼를 호출하므로 한 곳 변경으로 모두 동기화.
- `GanhoMusic/GanhoMusic Shared/Scenes/DifficultySelectScene.swift` — layoutDifficultyCards에서 width/spacing 모두 V3 상수 사용. layoutSummaryCard에서 offsetX V3(-260) 사용.
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — 신규 V3 상수 19개 추가(`// MARK: - Sprint 7 · 잘림 해소 + 카드 시인성 강화 (Visual-3)` 섹션). 기존 상수 값 변경 0건.

## SPEC 매핑

- **기능 1 (SafeArea SKView Mount)**: `GameViewController.swift` @ `viewDidLoad()` / `viewSafeAreaInsetsDidChange()` / `viewDidLayoutSubviews()` / `relayoutSKView()`. view.backgroundColor = .ganhoBgWarmTop. SKView.translatesAutoresizingMaskIntoConstraints = true / autoresizingMask = []. relayoutSKView 내부 `if skView.frame != target` 가드로 무한 didChangeSize 루프 방지.
- **기능 2 (Difficulty.description)**: `Difficulty.swift` 마지막 `}` 직전. easy/normal/hard 3 case 모두 한 줄 풀이. raw value("easy"/"normal"/"hard") 불변. `: CustomStringConvertible` 채택 안 함.
- **기능 3 (DifficultyCardNode V3 시인성)**: `DifficultyCardNode.swift` init/setSelected/configureLabels. 카드 크기 V3(112×82), cornerRadius V3(20), descriptionLabel 신규(numberOfLines=0 + preferredMaxLayoutWidth=96), 미선택 alpha 0.78, fill id.color α 0.08, stroke id.color α 0.4. ringGlow padding은 기존(10) 유지하되 ringGlow 자체 cornerRadius도 V3(20)으로 카드와 통일.
- **기능 4 (GameConfig V3 상수 묶음)**: `GameConfig.swift` 파일 끝 `// MARK: - Sprint 7 · ...` 섹션. 19개 V3 상수 모두 한국어 주석 + 의미 명시. 기존 difficultyCardWidth/Height/Spacing/FontSize 등은 *값 변경 없음*.
- **기능 5 (CharacterSelectScene 여백 + 지그재그)**: `CharacterSelectScene.swift` cardBaseX/cardBaseY 두 헬퍼. spacing 10→22(V3), 짝수 인덱스 +8 / 홀수 -8 지그재그. z-rotation 미적용(SPEC 명시).
- **기능 6 (DifficultySelectScene summary 균형)**: `DifficultySelectScene.swift` layoutDifficultyCards(width/spacing V3) + layoutSummaryCard(offsetX V3 -260). 시작 버튼 offsetY는 SPEC상 추가 조정 권장이지만 카드 height 82(V3)와 row y(-10) 기준 카드 하단이 midY-51 → 시작버튼 midY-160 → 109pt 여유로 충돌 없음. 별도 V3 분기 불필요.

## 변경 금지 항목 회귀 검증

- `GanhoMusic Shared/Scenes/GameScene.swift`: 미접촉 ✅
- `Repositories/*` (DifficultyPreferenceRepository / CharacterPreferenceRepository / HighScoreRepository / StatisticsRepository / GraduationRepository): 미접촉 ✅
- `Managers/AudioManager.swift`, `Managers/HapticsManager.swift`: 미접촉 ✅
- `Difficulty` enum의 case 추가/삭제: 없음 ✅ (description property 만 추가). raw value 불변 ✅.
- `StartScene` / `ResultScene` transitionToNext / presentScene 시그니처: 미접촉 ✅
- `CharacterID` enum, `CharacterCardNode` 내부 구조: 미접촉 ✅
- `GameScene.newGameScene(characterID:difficulty:)` 시그니처: 미접촉 ✅
- `ResultScene.newResultScene(...)` 시그니처: 미접촉 ✅
- `GlassPillNode`, `PrimaryButtonNode`, `DarkContextChipNode` 내부 구조: 미접촉 ✅
- 음표 emitter, 그라데이션 배경 노드, NurseAvatarNode: 미접촉 ✅
- StartScene 타이틀/태그라인 문구: 미접촉 ✅
- 사운드 발화 시퀀스(newBest reveal, sparkle 5발, diploma): 미접촉 ✅
- `Difficulty.subtitle`/`displayName`/`color`/`shortName` 기존 4 프로퍼티 본문: 미접촉 ✅
- `DifficultyCardNode.setSelected(_:)` 호출 시그니처: 불변 ✅ (호출부 변경 0)
- 기존 GameConfig 상수 값(`difficultyCardWidth=80`, `difficultyCardHeight=56`, `difficultyCardSpacing=16`, `difficultyCardFontSize=20`, `difficultyCardSubtitleFontSize=10`, `characterCardSpacing=10`, `difficultySelectSummaryCardOffsetX=-220`, ringGlow 관련 상수 등): 미변경 ✅

## Swift 규칙 자체 점검

- 강제 언래핑 `!` 신규 사용: 없음 ✅ (GameViewController도 기존 `guard let skView = self.view as? SKView else { return }` 패턴 유지)
- guard let / if let / ?? 사용 ✅
- Timer.scheduledTimer / DispatchQueue.main.asyncAfter: 신규 0건 ✅. SKView frame 재조정은 `viewSafeAreaInsetsDidChange` + `viewDidLayoutSubviews` 활용
- 매직 넘버: 신규 0건 ✅. 모든 새 수치는 `GameConfig.*V3` 상수로 분리(총 19개)
- `[weak self]` 클로저 캡처: 본 SPEC은 신규 클로저 없음(N/A). 기존 클로저 회귀 없음 ✅
- MARK 섹션 구분 유지 ✅:
  - GameViewController: `// MARK: - Lifecycle` / `// MARK: - Safe Area Relayout (Sprint 7)` / `// MARK: - Orientation` / `// MARK: - Status Bar / Home Indicator`
  - DifficultyCardNode: `// MARK: - Properties` / `// MARK: - Init` / `// MARK: - Selection` / `// MARK: - Configure`
  - GameConfig: `// MARK: - Sprint 7 · 잘림 해소 + 카드 시인성 강화 (Visual-3)` 신규 섹션
- 네이밍 컨벤션: V3 상수는 lowerCamelCase + 명확한 의미 prefix(`difficultyCard*V3`, `characterSelectCard*V3`, `difficultySelectSummary*V3`) ✅
- 한국어 변수명 없음 ✅. 주석은 한국어 ✅

## SpriteKit 규칙 자체 점검

- `didMove(to:)`에서 초기화 패턴: 회귀 없음 ✅
- `didChangeSize(_:)`에서 layout 재호출 패턴: 회귀 없음 ✅
- SKAction 키(`cardScale`, `ringFade`, `glassSelect`): 그대로 ✅
- `removeAction(forKey:)`로 중복 액션 방지: 유지 ✅
- 노드 z-position 위계(ringGlow -1 / background 0 / labels default / card.zPosition 100): 유지 ✅
- 색상 토큰 사용: `.ganhoBgWarmTop` / `.ganhoNavyDeep` / `.ganhoNavyMuted` / `.ganhoAccentCoral` 등 ColorTokens 정의된 토큰만 사용. 하드코딩 UIColor(red:green:blue:) 신규 0건 ✅
- SKLabelNode `numberOfLines = 0` + `preferredMaxLayoutWidth` 패턴(descriptionLabel): 적용 ✅
- ringGlow cornerRadius도 카드 cornerRadiusV3(20)로 통일 — 외곽 형태 mismatch 회귀 없음 ✅
- `update()` 내 addChild() 패턴: 본 sprint 범위에 update 변경 없음 ✅

## 위험 / 보완 메모

1. **iPhone 17 Pro 외 기기**: Safe area 기반이므로 iPhone SE(노치 없음) / iPhone 15(노치 있음) 모두 자동 작동. 노치 없는 기기에서는 inset이 (0,0,0,0)이라 SKView frame이 view.bounds와 동일 — 기존 동작 그대로.
2. **그라데이션 fallback**: `view.backgroundColor = .ganhoBgWarmTop`만 깔았으므로 노치 영역은 단일 톤(피치 #FFE5D0). 더 정교한 노치 영역 그라데이션은 SPEC 범위 밖.
3. **DifficultyCardNode 초기 fill 색**: init에서 deselected 톤(α 0.08)으로 채움. DifficultySelectScene이 setupDifficultyCards에서 즉시 `setSelected(id == selectedDifficulty)`를 호출하므로 첫 프레임도 정확한 상태.
4. **NurseAvatarNode 좌표**: StartScene의 `nurseAvatarOffsetX = 180`은 frame.minX + 180 기준. SafeArea 적용 후 NurseAvatar가 살짝 우측으로 이동 — 의도된 변경(SPEC §주의 8), 추가 조정 불필요.
5. **DifficultySelectScene 시작 버튼 충돌**: 카드 height 82, 카드 row y = midY - 10, 카드 하단 y = midY - 51. 시작 버튼 y = midY - 160 → 사이 간격 109pt. PrimaryButtonNode 높이 ~50pt를 빼도 60pt 여유. 충돌 없음. SPEC §주의 6의 "Generator가 실제 빌드에서 확인 후 필요 시 시작버튼 offsetY 추가 하향"은 본 빌드에서 *불필요*.
6. **`difficultyCardCornerRadiusV3 = 20`**: 카드 height 82, height/2 = 41 > 20 → 캡슐이 아닌 둥근 사각형 톤. SPEC §기능3과 §기능6 일치.
7. **빌드 경고**: 신규 경고 0건 예상. V3 상수는 모두 사용처 있음(unused 경고 없음). 미사용 인자나 옵셔널 강제 언래핑 미발생.
8. **CharacterSelectScene 지그재그**: CharacterID.allCases가 5개(.kim/.jung/.geon/.im/.lee)일 때 짝/홀 인덱스 패턴은 +8/-8/+8/-8/+8. SPEC §기능5의 "0번/2번/4번은 +zigzag, 1번/3번은 -zigzag" 동일. CharacterID 순서 변경 시에도 패턴 자체는 인덱스 mod 2 기준이라 유지.
9. **summary 카드 좌측 경계**: width 200, 중심 midX-260 → 좌측 경계 midX-360. iPhone 17 Pro landscape safe area 가로 ~800pt 기준 midX≈400, 좌측 경계 약 40pt — 안전.
10. **description 문구 길이**: 각각 14/14/13자 한글. 폰트 사이즈 10pt × 96pt 폭에서 1줄에 거의 들어가지만 폰트에 따라 2줄 wrap 가능. `numberOfLines = 0`으로 자동 처리 — 카드 height 82pt 안에 충분히 수용.

---

SELF_CHECK.md 작성 완료. 수정 파일 6개.
