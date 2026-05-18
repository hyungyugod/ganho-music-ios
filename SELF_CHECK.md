# 자체 점검 — Phase 8-1 (픽셀 아트 인프라 + 5캐릭터 일괄 이식)

전략: 1회차 — SPEC 충실 구현 (Case 판정 N/A).

---

## 1. git status / git diff --stat

### git status

```
modified:   GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift
modified:   GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj

Untracked files:
  GanhoMusic/GanhoMusic Shared/Models/PixelPalette.swift
  GanhoMusic/GanhoMusic Shared/Models/PixelSprite.swift
  GanhoMusic/GanhoMusic Shared/Nodes/PixelSpriteRenderer.swift
```

### git diff --stat (Phase 8-1 변경분만)

```
 GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift |  93 ++++
 GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift  |   9 +
 GanhoMusic/GanhoMusic Shared/GameScene.swift          |   8 +
 GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift   | 101 +++-
 GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj       |  12 +
 (신규)
 GanhoMusic/GanhoMusic Shared/Models/PixelSprite.swift         (~270줄)
 GanhoMusic/GanhoMusic Shared/Models/PixelPalette.swift        (~90줄)
 GanhoMusic/GanhoMusic Shared/Nodes/PixelSpriteRenderer.swift  (~40줄)
```

---

## 2. SPEC §"기능 상세" 6개 항목 라인 매핑

### 기능 1: PixelSprite 데이터 구조 (game.js L462-627)

| SPEC 항목 | 파일:라인 |
|---|---|
| `enum PixelSprite + Frame typealias` | `Models/PixelSprite.swift:20-23` |
| `static func data(for:direction:frame:)` | `Models/PixelSprite.swift:27-33` |
| `baseFrame(direction:frame:)` — game.js L465-486 정면 base | `Models/PixelSprite.swift:38-60` |
| 방향 분기 (up/left/right) — game.js L488-511 | `Models/PixelSprite.swift:62-87` |
| 프레임 분기 (step1/step2) — game.js L513-520 | `Models/PixelSprite.swift:90-101` |
| `applyOverlay` 디스패치 — game.js L522-525 | `Models/PixelSprite.swift:107-122` |
| `applyJungOverlay` — game.js L526-551 | `Models/PixelSprite.swift:127-154` |
| `applyGeonOverlay` — game.js L552-581 | `Models/PixelSprite.swift:158-189` |
| `applyImOverlay` — game.js L582-601 | `Models/PixelSprite.swift:194-216` |
| `applyLeeOverlay` — game.js L602-627 | `Models/PixelSprite.swift:221-245` |
| `enum PixelDirection / PixelFrame` | `Models/PixelSprite.swift:264-272` |

### 기능 2: PixelPalette 색 매핑 (game.js L637-697)

| SPEC 항목 | 파일:라인 |
|---|---|
| 공통 9키 dict (S/W/C/P/B/E/L/R/M) | `Models/PixelPalette.swift:14-25` |
| `palette(for:)` 병합 진입점 | `Models/PixelPalette.swift:31-37` |
| `charMap(for:)` 5캐릭터 분기 | `Models/PixelPalette.swift:42-83` |

### 기능 3: PixelSpriteRenderer

| SPEC 항목 | 파일:라인 |
|---|---|
| `UIGraphicsImageRenderer` + `ctx.fill` 픽셀 fill | `Nodes/PixelSpriteRenderer.swift:23-34` |
| `SKTexture(image:) + filteringMode = .nearest` | `Nodes/PixelSpriteRenderer.swift:36-38` |

### 기능 4: PlayerNode 픽셀 모드 전환

| SPEC 항목 | 파일:라인 |
|---|---|
| `pixelDirection / pixelFrame / frameAccumulator / currentCharacterID` 프로퍼티 | `Nodes/PlayerNode.swift:38-46` |
| `init()` — texture 모드 (color: .clear) + physicsBody 원래 크기 | `Nodes/PlayerNode.swift:49-79` |
| `apply(_ characterID:)` — currentCharacterID + refreshTexture | `Nodes/PlayerNode.swift:88-92` |
| `updatePixelDirection(_:)` — velocity 부호로 4방향 산출 | `Nodes/PlayerNode.swift:120-136` |
| `tickWalkFrame(deltaTime:isMoving:)` — step1↔step2 교차 | `Nodes/PlayerNode.swift:140-159` |
| `refreshTexture()` private — texture 프로퍼티 교체 | `Nodes/PlayerNode.swift:166-173` |

### 기능 5: ColorTokens 픽셀 팔레트 ~28개

| SPEC 항목 | 파일:라인 |
|---|---|
| 공통 9개 (S/W/C/P/B/E/L/R/M) | `Config/ColorTokens.swift:53-71` |
| kim 2개 (H/b) | `Config/ColorTokens.swift:74-77` |
| jung 4개 (J/j/K/k) | `Config/ColorTokens.swift:80-87` |
| geon 6개 (G/g/F/f/O/p) | `Config/ColorTokens.swift:90-101` |
| im 3개 (I/i/T) | `Config/ColorTokens.swift:104-109` |
| lee 3개 (Q/q/D) | `Config/ColorTokens.swift:112-117` |
| `UIColor(hex:)` convenience init | `Config/ColorTokens.swift:121-138` |

신설 색 토큰 총 **27개** (9 + 2 + 4 + 6 + 3 + 3) + `UIColor(hex:)` 헬퍼 1개.

### 기능 6: GameConfig 픽셀 상수

| SPEC 항목 | 파일:라인 |
|---|---|
| `pixelSpriteScale: CGFloat = 2` | `Config/GameConfig.swift:636` |
| `pixelWalkFrameInterval: TimeInterval = 0.18` | `Config/GameConfig.swift:640` |
| MARK 섹션 `// MARK: - Pixel Sprite (Phase 8-1)` | `Config/GameConfig.swift:632` |

### GameScene update 1줄 추가

| SPEC 항목 | 파일:라인 |
|---|---|
| `guard gameState == .playing` 가드 안쪽 호출 | `GameScene.swift:341-345` |
| `velocity = player.physicsBody?.velocity ?? .zero` — 옵셔널 처리 | 동일 |
| `player.updatePixelDirection(velocity)` | 동일 |
| `player.tickWalkFrame(deltaTime: dt, isMoving:)` | 동일 |

### pbxproj 등록

| 항목 | 파일:라인 |
|---|---|
| PBXBuildFile 3개 (042/043/044) | `project.pbxproj:53-55` |
| PBXFileReference 3개 | `project.pbxproj:102-104` |
| PBXGroup Nodes에 PixelSpriteRenderer 추가 | `project.pbxproj:247` |
| PBXGroup Models에 PixelSprite/PixelPalette 추가 | `project.pbxproj:294-295` |
| PBXSourcesBuildPhase 3개 등록 | `project.pbxproj:534-536` |

---

## 3. 회귀 0 영역 grep 결과 (git diff 0줄 확인)

다음 파일 모두 `git diff HEAD -- <path> | wc -l` 결과 **0**:

```
0  GanhoMusic Shared/Nodes/EnemyNode.swift
0  GanhoMusic Shared/Nodes/StoneGuardNode.swift
0  GanhoMusic Shared/Nodes/ProjectileNode.swift
0  GanhoMusic Shared/Nodes/NoteNode.swift
0  GanhoMusic Shared/Nodes/DPadNode.swift
0  GanhoMusic Shared/Nodes/HUDNode.swift
0  GanhoMusic Shared/Nodes/CharacterCardNode.swift
0  GanhoMusic Shared/Nodes/DifficultyCardNode.swift
0  GanhoMusic Shared/Nodes/AirforceOverlayNode.swift
0  GanhoMusic Shared/Nodes/AirplaneNode.swift
0  GanhoMusic Shared/Nodes/BombFlashNode.swift
0  GanhoMusic Shared/Nodes/HitFlashNode.swift
0  GanhoMusic Shared/Nodes/SparkleEffectNode.swift
0  GanhoMusic Shared/Nodes/CountdownNode.swift
0  GanhoMusic Shared/Nodes/ComboBreakNode.swift
0  GanhoMusic Shared/Nodes/ComboPopupNode.swift
0  GanhoMusic Shared/Nodes/CutsceneOverlayNode.swift
0  GanhoMusic Shared/Nodes/DiplomaOverlayNode.swift
0  GanhoMusic Shared/Nodes/ScorePopupNode.swift
0  GanhoMusic Shared/Systems/ContactRouter.swift
0  GanhoMusic Shared/Systems/SpawnSystem.swift
0  GanhoMusic Shared/Systems/ScoreSystem.swift
0  GanhoMusic Shared/Scenes/TitleScene.swift
0  GanhoMusic Shared/Scenes/ResultScene.swift
0  GanhoMusic Shared/GameScene+Setup.swift
0  GanhoMusic Shared/Models/CharacterID.swift
0  GanhoMusic Shared/Models/Difficulty.swift
0  GanhoMusic Shared/Models/GameStats.swift
0  GanhoMusic Shared/Config/PhysicsCategory.swift
0  GanhoMusic Shared/Config/GameState.swift
0  GanhoMusic iOS/GameViewController.swift
0  GanhoMusic iOS/AppDelegate.swift
0  GanhoMusic tvOS/GameViewController.swift
0  GanhoMusic macOS/GameViewController.swift
```

자가 소멸 노드 11호(Airplane / Airforce / Bomb / HitFlash / Sparkle / Countdown / ComboBreak / ComboPopup / Cutscene / Diploma / ScorePopup) 전체, EnemyNode / StoneGuard / Projectile / Note / DPad / HUD / 카드 노드들, 모든 시스템·매니저·리포지토리·모델 (CharacterID/Difficulty/GameStats) 모두 미접촉.

PhysicsCategory / GameState / TitleScene / ResultScene / GameScene+Setup / iOS·tvOS·macOS 진입점도 모두 0줄.

---

## 4. 빌드 결과

명령:
```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -target "GanhoMusic iOS" -sdk iphonesimulator \
  EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" clean build
```

마지막 출력:
```
CodeSign /…/Release-iphonesimulator/GanhoMusic.app
RegisterExecutionPolicyException /…/GanhoMusic.app
Validate /…/GanhoMusic.app
Touch /…/GanhoMusic.app

** BUILD SUCCEEDED **
```

- **빌드 결과**: `BUILD SUCCEEDED`
- **컴파일 경고**: `grep -E "warning:|error:"` 결과 0건
- **링크 에러**: 0건
- **CodeSign / Validate**: 성공

---

## 5. 정적 검사 — 신규/수정 5 파일

### 강제 언래핑 (`!`)

```
$ grep -nE '!\s*$|!\s*[,)]|!\s*\.' <신규/수정 5 파일> | grep -v "fatalError\|//"
강제 언래핑 0건
```

신규 코드의 모든 옵셔널 접근은 `guard let`, `if let`, `??` 사용:
- `player.physicsBody?.velocity ?? .zero` (GameScene:344)
- `GameConfig.playerSpeedStartByDifficulty[difficulty] ?? GameConfig.playerBaseSpeed` (PlayerNode:97)
- `palette[char]`는 `guard let color = palette[char] else { continue }` (PixelSpriteRenderer:30)

### Timer / DispatchQueue

```
$ grep -nE "Timer\.|DispatchQueue\." <신규/수정 5 파일>
Timer/DispatchQueue 0건
```

### 매직 넘버

매직 넘버는 모두 `GameConfig` 상수 (`pixelSpriteScale`, `pixelWalkFrameInterval`, `playerWidth`, `playerHeight`, `playerBaseSpeed`) 또는 픽셀 도메인의 본질 상수 (16×20 그리드의 16/20) 사용. 그리드 크기 16/20은 game.js와 *byte-equal* 보존을 위해 `PixelSpriteRenderer.spriteWidth/spriteHeight` private 상수로 분리.

### `MARK:` 섹션 구분

신규 파일 모두 `// MARK: - Public Entry`, `// MARK: - Base Frame`, `// MARK: - Overlay Dispatch`, `// MARK: - jung/geon/im/lee Overlay`, `// MARK: - Properties`, `// MARK: - Init`, `// MARK: - Apply`, `// MARK: - Update (Movement)`, `// MARK: - Update (Pixel Animation, Phase 8-1)`, `// MARK: - Texture Refresh` 등 명확한 섹션 구분.

### `[weak self]` 캡처

본 sprint 신규 코드는 closure를 사용하지 않음(모든 호출이 직접 메서드 호출). UIGraphicsImageRenderer의 closure 내부에서는 self 미사용이므로 [weak self] 불필요.

---

## 6. 5캐릭터 오버레이 → game.js 원본 byte-equal 확인

### kim
- 원본 game.js L523: `'kim'은 기본 번머리(이미 base에 반영)이므로 추가 변형 없음.`
- Swift `Models/PixelSprite.swift:109-111`: `case .kim: break  // 'kim'은 기본 번머리(이미 base에 반영)이므로 추가 변형 없음. (game.js L523 주석 그대로)`
- 라인 수: **0줄 오버레이** (base만 사용).

### jung — game.js L526-551 (26줄)
Swift `applyJungOverlay`: **26줄 일치** (`PixelSprite.swift:127-154`).
핵심 행:
- 원본: `base[2] = '....JJJJJJJJ....';` → Swift `base[2] = "....JJJJJJJJ...."` ✓
- 원본: `base[10] = base[10].substring(0, 14) + 'KK';` → Swift `base[10] = String(base[10].prefix(14)) + "KK"` ✓
- 원본: `base[11] = base[11].substring(0, 14) + 'kK';` → Swift `base[11] = String(base[11].prefix(14)) + "kK"` ✓

### geon — game.js L552-581 (30줄)
Swift `applyGeonOverlay`: **byte-equal** (`PixelSprite.swift:158-189`).
핵심 행:
- 원본: `base[2] = '.....GGGGGGGG...';` → Swift `base[2] = ".....GGGGGGGG..."` ✓
- 원본: `base[6] = '..SSFFSSSSFFSS..';` → Swift `base[6] = "..SSFFSSSSFFSS.."` ✓
- 원본: `base[12] = base[12].substring(0, 14) + 'OO';` → Swift `String(base[12].prefix(14)) + "OO"` ✓

### im — game.js L582-601 (20줄)
Swift `applyImOverlay`: **byte-equal** (`PixelSprite.swift:194-216`).
핵심 행:
- 원본: `base[1] = '....T......T....';` → Swift `base[1] = "....T......T...."` ✓
- 원본: `base[11] = 'II..WWWWWWWW..II'.replace('II..', 'iI..').replace('..II', '..Ii');`
  → Swift `base[11] = "II..WWWWWWWW..II".replacingOccurrences(of: "II..", with: "iI..").replacingOccurrences(of: "..II", with: "..Ii")` ✓

### lee — game.js L602-627 (26줄)
Swift `applyLeeOverlay`: **byte-equal** (`PixelSprite.swift:221-245`).
핵심 행:
- 원본: `base[2] = '.....QQQQQQQQ...';` → Swift `base[2] = ".....QQQQQQQQ..."` ✓
- 원본: `const overlayEdge = (row) => 'qq' + row.substring(2, 14) + 'qq';`
  → Swift `overlayEdge(_ row:)` 헬퍼: `"qq" + String(chars[2..<14]) + "qq"` ✓
  - JS `substring(2, 14)` = index 2..13(end 미포함) = 12자 → Swift `chars[2..<14]` = 12자 ✓
- 원본: `base[2] = '...DD' + base[2].substring(5, 11) + 'DD...';`
  → Swift `base[2] = "...DD" + leeSubstring5to11(base[2]) + "DD..."` (헬퍼는 `chars[5..<11]`) ✓
  - JS `substring(5, 11)` = index 5..10(end 미포함) = 6자 → Swift `chars[5..<11]` = 6자 ✓

### 공통 base — game.js L465-520 (총 56줄: base 22 + 방향 분기 18 + 프레임 분기 8 + 주석/빈줄)
Swift `baseFrame`: **byte-equal** (`PixelSprite.swift:38-103`).
- 원본 base[0..19] 20행 → Swift 20행 일치
- 방향 분기 up (10행) / left (3행) / right (3행) — 각 행 16자 그대로
- 프레임 step1/step2 (각 2행) — 일치

---

## 7. Swift 패턴 준수

| 항목 | 결과 |
|---|---|
| 강제 언래핑 미사용 | 준수 |
| guard let / if let / ?? 옵셔널 처리 | 준수 (`player.physicsBody?.velocity ?? .zero`, `guard let color = palette[char]`) |
| MARK 섹션 구분 | 준수 (모든 신규 파일 `// MARK: -` 다수 사용) |
| GameConfig 상수 사용 | 준수 (`pixelSpriteScale`, `pixelWalkFrameInterval` 신규 정의 + 호출부 참조) |
| weak self 캡처 | N/A (신규 코드에 closure 캡처 없음) |
| 한글 변수명 금지 / 주석 한글 허용 | 준수 |
| 매직 넘버 → 상수화 | 준수 (16/20 그리드는 PixelSpriteRenderer private 상수) |

## 8. SpriteKit 패턴 준수

| 항목 | 결과 |
|---|---|
| didMove(to:)에서 초기화 | 준수 (GameScene 초기화 흐름 미접촉) |
| dt 기반 이동 | 준수 (PlayerNode.tickWalkFrame에 deltaTime 인자) |
| SKAction 스폰 패턴 | N/A (본 sprint는 텍스처 갱신만, 스폰 미관련) |
| 충돌 후 노드 즉시 삭제 없음 | N/A (ContactRouter 미접촉) |
| HUD 노드 분리 | 준수 (HUD 미접촉) |
| 텍스처 매 프레임 생성 금지 | 준수 (refreshTexture는 dir/frame 변경 *순간*에만 호출 — 정지 시 비용 0) |
| filteringMode = .nearest | 준수 (PixelSpriteRenderer:38) |

---

## 9. 빌드 상태

- 예상 빌드 에러: **없음** (실제 BUILD SUCCEEDED 확인됨)
- 주의 필요 경고: **없음** (`grep "warning:|error:"` 결과 0건)

---

## 10. 범위 외 미구현 항목

- **EnemyNode / StoneGuard 픽셀화**: SPEC 금지 §1 — 다음 sprint
- **음표/F/StoneGuard 픽셀 디테일**: SPEC 금지 §2 — 다음 sprint
- **CharacterCardNode 픽셀 아바타**: SPEC 금지 §4 — 다음 sprint (타이틀 카드는 단색 유지)
- **SKAction.animate(withTextures:) 자동 애니메이션**: SPEC 금지 §5 — PlayerNode가 *수동으로* dir/frame 결정 후 텍스처 교체 (의도된 설계)
- **다크/라이트 테마 토글**: SPEC 금지 §3 — 별도 sprint

---

## 11. 시연 시 동작 (예상)

- **kim 선택 후 게임 시작**: 김간호가 *번머리 + 흰 가운 + 가슴 십자 + 파란 하의 + 갈색 신발* 픽셀 모자이크로 등장 (16×20 → 32×40pt 화면 픽셀).
- **D-Pad 우 입력**: pixelDirection = .right → 왼쪽 눈만 보이는 옆모습 텍스처로 즉시 교체.
- **D-Pad 좌/상/하 입력**: 각각 left/up(뒷모습)/down 텍스처 교체.
- **이동 중**: 0.18초마다 발이 step1↔step2 교차 (총총 보행).
- **정지**: 발이 idle 위치로 복귀, 마지막 방향 유지.
- **다른 캐릭터 선택**: TitleScene에서 jung/geon/im/lee 선택 시 PlayerNode.apply(_ characterID:)가 refreshTexture 호출 → 짧은머리+곡괭이 / 단정머리+안경+책 / 긴머리+고양이귀 / 단발+강아지귀 자동 적용.
- **physicsBody hitbox**: 시각 크기는 32×40이지만 hitbox는 원래 16×20 유지 — 음표/적/F 충돌 판정 회귀 0.
