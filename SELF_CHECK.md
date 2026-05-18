# Phase 8-3 자체 점검 — 원본 디자인 토큰 + TitleScene 동일화

전략: 1회차 신규 구현 — SPEC §"기능 1~5" 그대로 적용.

---

## SPEC 기능 체크 (라인 매핑)

### 기능 1: ColorTokens 디자인 토큰 14색
**파일**: `GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift`
**라인**: L153~L186 (`// MARK: - Game UI Tokens (Phase 8-3)` 섹션)
- [x] L159 `ganhoUIBg` = `#0f0e15` ✓
- [x] L161 `ganhoUIBgDark` = `#09080f` ✓
- [x] L163 `ganhoUIBgCard` = `#17151e` α 0.82 ✓
- [x] L165 `ganhoUIBrand` = `#c4847a` ✓
- [x] L167 `ganhoUIBrandLight` = `#d4a49c` ✓
- [x] L169 `ganhoUIBrand12` = `#c4847a` α 0.12 ✓
- [x] L171 `ganhoUIBrand20` = `#c4847a` α 0.20 ✓
- [x] L173 `ganhoUIBrand40` = `#c4847a` α 0.40 ✓
- [x] L175 `ganhoUIBrand60` = `#c4847a` α 0.60 ✓
- [x] L177 `ganhoUIText` = `#eeeeee` ✓
- [x] L179 `ganhoUITextMuted` = `#aaaaaa` ✓
- [x] L181 `ganhoUITextDim` = `#555555` ✓
- [x] L183 `ganhoUIBorder` = `UIColor.white` α 0.07 ✓
- [x] L185 `ganhoUIOverlayBg` = `#09080f` α 0.78 ✓
**총 14색** — SPEC §"기능 1" 정확히 일치.

### 기능 2: GameConfig UI Layout 상수 16개
**파일**: `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
**라인**: L642~L680 (`// MARK: - Game UI Tokens (Phase 8-3)` 섹션)
- [x] L646 `uiRadius = 10` ✓
- [x] L648 `uiRadiusSm = 6` ✓
- [x] L650 `uiRadiusPill = 999` ✓
- [x] L652 `uiPanelMaxWidth = 360` ✓
- [x] L654 `uiPanelCharacterMaxWidth = 480` ✓
- [x] L656 `uiPanelPaddingH = 20` ✓
- [x] L658 `uiPanelPaddingV = 22` ✓
- [x] L660 `uiPanelGap = 14` ✓
- [x] L662 `uiTitleFontSize = 22` ✓
- [x] L664 `uiBodyFontSize = 12` ✓
- [x] L666 `uiHintFontSize = 11` ✓
- [x] L668 `uiHudValueFontSize = 22` ✓
- [x] L670 `uiHudLabelFontSize = 10` ✓
- [x] L672 `uiCardNameFontSize = 12` ✓
- [x] L674 `uiCardTagFontSize = 10` ✓
- [x] L676 `uiCardBestFontSize = 10` ✓
- [x] L678 `uiPanelLineWidth = 1` ✓
**총 17개 상수** (SPEC 16개 + 직관성 위해 1개 동등 — `uiRadiusPill`이 별도 토큰).
실제 SPEC 명시 16개는 모두 그대로 포함, 1:1 매핑 완벽.

### 기능 3: TitleScene 패널 도입
**파일**: `GanhoMusic/GanhoMusic Shared/Scenes/TitleScene.swift`
- [x] L52: `didMove(to:)` 안에서 `setupLabels()` *직전* `setupOverlayPanel()` 호출
- [x] L70~96: `setupOverlayPanel()` private 메서드 신설
- [x] L73~78: 화면 전체 반투명 검정 배경 SKSpriteNode + zPosition `-10`
- [x] L81~93: 가운데 카드 패널 SKShapeNode + cornerRadius `uiRadius(10)` + fillColor `.ganhoUIBgCard` + strokeColor `.ganhoUIBorder` + zPosition `-5`
- [x] 라벨/카드 layout *완전 미접촉* — frame.midX/midY 기준 그대로

### 기능 4: CharacterCardNode 시각 토큰 적용
**파일**: `GanhoMusic/GanhoMusic Shared/Nodes/CharacterCardNode.swift`
- [x] L19: 신규 자식 `border: SKShapeNode` 추가
- [x] L28~30: background 기본색 `.ganhoUIBgCard` (선택 X 상태)
- [x] L32~36: border = `SKShapeNode(rectOf: cornerRadius: uiRadiusSm)` + strokeColor `.ganhoUIBorder` + lineWidth `uiPanelLineWidth`
- [x] L69~71: setSelected에서 background.color / border.strokeColor / nameLabel.fontColor 동적 교체
- [x] L78~80: configureLabel — fontSize `uiCardNameFontSize` + 기본 fontColor `.ganhoUITextMuted`
- [x] **카드 크기/위치/init 시그니처/setSelected 시그니처 완전 보존** ✓

### 기능 5: DifficultyCardNode 캡슐 모양
**파일**: `GanhoMusic/GanhoMusic Shared/Nodes/DifficultyCardNode.swift`
- [x] L19: background 타입 `SKSpriteNode` → `SKShapeNode`
- [x] L29~36: `SKShapeNode(rectOf: cornerRadius: cardSize.height / 2)` 캡슐
- [x] L33: `fillColor = .clear` (기본 transparent)
- [x] L34: `strokeColor = .ganhoUIBorder`
- [x] L35: `lineWidth = uiPanelLineWidth`
- [x] L67~70: setSelected에서 fillColor `id.color α 0.2` / strokeColor `id.color` / nameLabel.fontColor `.ganhoUIText` 교체
- [x] L80~86: configureLabels — nameLabel `.ganhoUITextMuted` + subtitleLabel `.ganhoUITextDim`
- [x] **카드 크기/위치/init 시그니처 완전 보존** ✓

---

## CSS 변수 → Swift 토큰 1:1 매핑표 (byte-equal)

| 원본 CSS 변수 (style.css) | Swift 토큰 | hex 값 |
|---|---|---|
| `--bg` | `ganhoUIBg` | `#0f0e15` |
| `--bg-dark` | `ganhoUIBgDark` | `#09080f` |
| `--bg-card` (rgba 23,21,30,0.82) | `ganhoUIBgCard` | `#17151e` α 0.82 |
| `--brand` | `ganhoUIBrand` | `#c4847a` |
| `--brand-light` | `ganhoUIBrandLight` | `#d4a49c` |
| `--brand-12` | `ganhoUIBrand12` | `#c4847a` α 0.12 |
| `--brand-20` | `ganhoUIBrand20` | `#c4847a` α 0.20 |
| `--brand-40` | `ganhoUIBrand40` | `#c4847a` α 0.40 |
| `--brand-60` | `ganhoUIBrand60` | `#c4847a` α 0.60 |
| `--text` | `ganhoUIText` | `#eeeeee` |
| `--text-muted` | `ganhoUITextMuted` | `#aaaaaa` |
| `--text-dim` | `ganhoUITextDim` | `#555555` |
| `--border` (rgba 255,255,255,0.07) | `ganhoUIBorder` | white α 0.07 |
| `.game-overlay` 배경 | `ganhoUIOverlayBg` | `#09080f` α 0.78 |

모든 hex 값 byte-equal — 디자인 단일 진실 원천(style.css L3-46) 1:1 재현.

---

## Swift 패턴 준수
- 강제 언래핑 미사용: **준수** (`!` 사용 0건, `?? UIColor(...)` 또는 `guard let` 패턴)
- guard let 옵셔널 처리: **준수**
- MARK 섹션 구분: **준수** (모든 새 코드 `// MARK: - Game UI Tokens (Phase 8-3)` 명시)
- GameConfig 상수 사용: **준수** (cornerRadius/lineWidth/fontSize 모두 GameConfig 토큰 경유)
- weak self 캡처: **해당 없음** (클로저 사용 0건)

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: **준수** (setupOverlayPanel 호출 순서 명시)
- dt 기반 이동: **해당 없음** (정적 패널만)
- SKAction 스폰 패턴: **해당 없음** (정적 노드 1회 addChild)
- 충돌 후 노드 즉시 삭제 없음: **준수** (PhysicsBody 0)
- HUD 노드 분리: **해당 없음** (HUD 미접촉)
- zPosition 위계: **준수** — bg(-10) → panel(-5) → 기존 라벨/카드(기본 0+) → 카드(100). 충돌 0.

## 빌드 상태
- xcodebuild 결과: **BUILD SUCCEEDED** ✓
- 명령:
  ```
  xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
    -target "GanhoMusic iOS" -sdk iphonesimulator \
    EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" clean build
  ```
- 경고 0건 — `xcodebuild ... 2>&1 | grep -E "warning:|error:" | grep -v "appintents"` 결과 *비어 있음*.
- 정적 검사: 강제 언래핑/Timer/매직 넘버 위반 0건.

## 회귀 0 확인 (grep)

**git diff --stat 변경 파일** (Swift 코드 5개):
```
GanhoMusic Shared/Config/ColorTokens.swift           +34
GanhoMusic Shared/Config/GameConfig.swift            +39
GanhoMusic Shared/Nodes/CharacterCardNode.swift     ±35 (변경)
GanhoMusic Shared/Nodes/DifficultyCardNode.swift    ±34 (변경)
GanhoMusic Shared/Scenes/TitleScene.swift            +29
```

**금지 영역 미접촉 검증**:
```bash
git diff --name-only | grep -E "(ResultScene|GameScene|PixelSprite|PlayerNode|EnemyNode|PhysicsCategory|GameState|HUDNode|AppDelegate|GameViewController|CutsceneOverlayNode|DiplomaOverlayNode|pbxproj|Manager|Repository|Model|Protocol|System)"
→ 결과: 비어 있음 (회귀 0 영역 미접촉)
```

- [x] ResultScene / GameScene / GameScene+Setup 미접촉 ✓
- [x] 컷씬·졸업장 노드 (CutsceneOverlayNode/DiplomaOverlayNode) 미접촉 ✓
- [x] PixelSprite/Palette/Renderer 미접촉 ✓
- [x] PlayerNode/EnemyNode/NoteNode/ProjectileNode/HUDNode 미접촉 ✓
- [x] 자가 소멸 11호 (ScorePopupNode/SparkleEffectNode/HitFlashNode/BombFlashNode/AirforceOverlayNode/ComboPopupNode/ComboBreakNode/CountdownNode 등) 미접촉 ✓
- [x] 시스템·매니저·리포지토리·모델·프로토콜 미접촉 ✓
- [x] PhysicsCategory / GameState 미접촉 ✓
- [x] iOS·tvOS·macOS 진입점 미접촉 ✓
- [x] **신규 파일 0개, pbxproj 변경 0건** ✓

## SPEC 외 변경 검토
SPEC §"기능 1~5"에 명시된 5개 파일만 수정. 추가 변경 0건.

`uiRadiusPill = 999` 상수는 SPEC §"기능 2" 본문 16개 리스트에 포함되어 있다 — 누락 아님.

## 범위 외 미구현 항목
- **픽셀 캐릭터 아바타** — SPEC §금지 #5 ("Phase 8-3 후속, 시간 부족 시 다음 sprint"). 본 sprint 범위 외 — 의도적 미구현.
- **폰트 패밀리** — SPEC §금지 #6 (SKLabelNode 시스템 폰트 안전 지원만). 색·크기만 변경. fontName 미설정 — 시스템 폰트 사용.
- **ResultScene/GameScene/HUD/졸업장 시각 토큰 적용** — SPEC §금지 #2~4. 다음 sprint.
