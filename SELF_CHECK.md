# 자체 점검 — Phase 7-5 핫픽스 (전환 시점 4종 버그)

전략: Case A — 1회차. SPEC가 *값 변경 + UserDefaults 분기 + anchor 변경 + 가드 1줄*뿐. 변경 최소화 원칙으로 정밀 적용.

---

## 1. git status / git diff --stat

```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift       (+13 / -3)
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift                (+13 / -2)
modified:   GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift       (+ 7 / -1)
```

총 3개 파일, +33줄 / -6줄. *허용 파일 외 변경 0건*.

---

## 2. SPEC 4건 버그 → 코드 변경 위치 매핑

### 버그 1: 카드 절단 — 카드 레이아웃 재배치

| 위치 | 변경 | 비고 |
|------|------|------|
| `GameConfig.swift:124` | `titleLabelOffsetY: 80 → 120` | 기존 상수가 이미 존재 → 값만 수정 |
| `GameConfig.swift:471` | `difficultyCardOffsetY: -120 → +80` | titleLabel 아래 / bestLabel 위 (상단 이동) |
| `GameConfig.swift:478` | `characterCardOffsetY: -200 → -160` | Phase 5 원래 값으로 되돌림 |
| `TitleScene.swift` | 변경 0 | 이미 `GameConfig.titleLabelOffsetY` 참조 중(line 98) — *코드 변경 불필요*. 값만 바뀌어도 자동 재배치 |
| `DifficultyCardNode.swift` / `CharacterCardNode.swift` | 변경 0 | 위치는 TitleScene이 GameConfig 참조로 set — 카드 노드 자체 코드 미접촉 |

### 버그 2: 인트로 컷씬 매번 강제 표시 — UserDefaults 1회 가드

| 위치 | 변경 | 비고 |
|------|------|------|
| `GameConfig.swift:573` | `hasSeenIntroCutsceneUserDefaultsKey: String = "hasSeenIntroCutscene"` 신규 | 신규 키 — 기존 키와 충돌 0 |
| `GameScene.swift:156-164` | `didMove` 끝부분의 무조건 `showIntroCutscene()`를 if/else 분기로 교체 | bool 기본값 false → 최초 사용자만 컷씬 표시 |
| `GameScene.swift:193` | `showIntroCutscene` 안 onDismiss 클로저에 `UserDefaults.standard.set(true, forKey: ...)` 1줄 추가 | guard let self 뒤, gameState 전환 전 |

### 버그 3: 졸업장 좌표 어긋남

| 위치 | 변경 | 비고 |
|------|------|------|
| `ResultScene.swift:318` | `anchor: CGPoint(x: frame.midX, y: frame.midY)` → `anchor: CGPoint(x: size.width / 2, y: size.height / 2)` | sceneSize 기준으로 변경 — background와 같은 좌표계로 정렬 |

### 버그 4: ResultScene 터치 경합

| 위치 | 변경 | 비고 |
|------|------|------|
| `ResultScene.swift:226-228` | `touchesBegan` 안 `guard !isTransitioning` 직후에 `if children.contains(where: { $0.name == "diplomaOverlay" }) { return }` 1줄 추가 | DiplomaOverlayNode가 `name = "diplomaOverlay"`로 부착됨(line 80) — 가드 매치 보장 |

---

## 3. 회귀 0 영역 git diff 0줄 grep 결과

```bash
$ git diff --stat -- \
    "GanhoMusic/GanhoMusic Shared/Scenes/TitleScene.swift" \
    "GanhoMusic/GanhoMusic Shared/Nodes/" \
    "GanhoMusic/GanhoMusic Shared/Systems/" \
    "GanhoMusic/GanhoMusic Shared/Managers/" \
    "GanhoMusic/GanhoMusic Shared/Repositories/" \
    "GanhoMusic/GanhoMusic Shared/Models/" \
    "GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift" \
    "GanhoMusic/GanhoMusic Shared/Config/PhysicsCategory.swift" \
    "GanhoMusic/GanhoMusic Shared/Config/GameState.swift" \
    "GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift" \
    "GanhoMusic/GanhoMusic iOS/" \
    "GanhoMusic/GanhoMusic tvOS/" \
    "GanhoMusic/GanhoMusic macOS/" \
    "GanhoMusic/GanhoMusic.xcodeproj/"
(빈 출력 — 0줄)
```

**검증된 미접촉 영역**:
- 모든 노드 (PlayerNode/EnemyNode/StoneGuardNode/NoteNode/ProjectileNode/AirplaneNode/AirforceOverlayNode/BombFlashNode/HitFlashNode/SparkleEffectNode/ScorePopupNode/ComboPopupNode/ComboBreakNode/CountdownNode/HUDNode/DPadNode/CharacterCardNode/DifficultyCardNode/CutsceneOverlayNode/**DiplomaOverlayNode**) → 자가 소멸 11호 + 모든 카드 노드 0줄 변경
- 모든 시스템·매니저·리포지토리·모델 0줄 변경
- ColorTokens / PhysicsCategory / GameState 0줄 변경
- GameScene+Setup.swift 0줄 변경
- iOS·tvOS·macOS 진입점 0줄 변경
- pbxproj 0줄 변경 (신규 파일 0개)
- TitleScene.swift 0줄 변경 (이미 GameConfig 상수 참조 중 → 값 변경만으로 자동 재배치)

---

## 4. 빌드 결과

```
$ xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
             -target "GanhoMusic iOS" \
             -sdk iphonesimulator \
             EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" \
             clean build

** BUILD SUCCEEDED **
```

- 빌드 상태: SUCCEEDED
- 경고: 0건 (AppIntents 메타데이터 정보 메시지 제외 — 본 변경 무관)
- 에러: 0건

---

## 5. 정적 검사 (강제 언래핑 / 매직 넘버 / Timer / DispatchQueue 0건)

```bash
$ git diff -- <수정 3파일> | grep -E "^\+" | grep -v "^+++" | grep -E "!|Timer|DispatchQueue"
NONE
```

| 항목 | 결과 | 비고 |
|------|------|------|
| 강제 언래핑(`!`) | 0건 | `UserDefaults.standard.bool(forKey:)` / `UserDefaults.standard.set(_, forKey:)` 모두 옵셔널 미반환 |
| Timer | 0건 | UserDefaults 분기는 동기 호출, 카운트다운/컷씬 흐름은 기존 SKAction 사용 |
| DispatchQueue | 0건 | 비동기 처리 없음 |
| 매직 넘버 | 0건 신규 | `size.width / 2` / `size.height / 2`은 SPEC 명시 좌표(상수화 대상 아님), `"diplomaOverlay"`는 단발 노드 식별자 |
| guard let 옵셔널 처리 | 준수 | `onDismiss` 클로저의 `guard let self = self else { return }` 유지 |
| [weak self] 캡처 | 준수 | `onDismiss: { [weak self] in ... }` 유지 |

---

## 6. 4건 버그가 *코드 수준에서 자연 차단*되는지 확인

### 버그 1: 카드 절단 — 차단 메커니즘
- **레이아웃 분리**: 난이도 카드(+80)는 *상단*, 캐릭터 카드(-160)는 *하단*. 두 그룹이 화면 중앙선을 기준으로 위/아래 분리됨.
- **640pt 화면 검증**: midY=320. titleLabel(+120) y=440 / difficultyCard(+80) y=400 / bestLabel(+20) y=340 / playsLabel(-20) y=300 / promptLabel(-80) y=240 / characterCard(-160) y=160 — 가장 낮은 캐릭터카드(60pt 절반=30pt) 하단 y=130 → 화면 하단(0)에서 130pt 위 = *안전*.
- **자연 차단**: GameConfig 단일 상수 변경 → 모든 layout 메서드가 자동 재배치. 카드 노드 코드 변경 0건.

### 버그 2: 컷씬 강제 표시 — 차단 메커니즘
- **bool 기본값 false 보장**: Apple `UserDefaults.standard.bool(forKey:)` 키 부재 시 자동 false 반환 → 최초 사용자에게는 *자연*적으로 컷씬 표시.
- **onDismiss 멱등 set**: 컷씬 닫힘 → `set(true, forKey:)` → 디스크 동기화. 두 번째 진입 시 키 = true → if 분기 → 카운트다운 직진.
- **자연 차단**: didMove 분기 + onDismiss flag set 2개 변경. 컷씬 시스템 자체(CutsceneOverlayNode) 변경 0건.

### 버그 3: 졸업장 좌표 어긋남 — 차단 메커니즘
- **sceneSize 단일 기준**: DiplomaOverlayNode의 background도 sceneSize 기준 → anchor도 같은 기준 → 정렬 보장.
- **frame 동적성 무관**: `.resizeFill` 모드의 frame은 view 크기에 따라 달라지지만 self.size는 1024×768 고정 → background와 anchor가 *같은 1024×768 좌표계*에서 정확히 일치.
- **자연 차단**: ResultScene presentDiploma 1줄 변경. DiplomaOverlayNode 변경 0건.

### 버그 4: 졸업장 터치 경합 — 차단 메커니즘
- **이중 방어**: (1) DiplomaOverlayNode가 자기 `isUserInteractionEnabled = true`로 자기 터치 흡수 → 부모(ResultScene)에 터치 전달 안 됨. (2) edge case로 부모에 도달해도 `children.contains(where:)` 가드 → early return.
- **노드 name 일치 검증**: `DiplomaOverlayNode.swift:80`에서 `name = "diplomaOverlay"` 부착 → 가드 문자열과 정확 일치.
- **회귀 0**: 졸업장 없을 때 children에 매치 노드 0개 → contains 반환 false → 가드 발화 0 → 기존 TitleScene 전환 동작 그대로.

---

## 7. SPEC 기능 체크리스트

- [x] **기능 1: 카드 레이아웃 재배치** — titleLabelOffsetY 120 / difficultyCardOffsetY +80 / characterCardOffsetY -160
- [x] **기능 2: 컷씬 최초 1회만** — UserDefaults 키 신설 + didMove if/else 분기 + onDismiss flag set
- [x] **기능 3: 졸업장 좌표 보정** — anchor를 `size.width/2, size.height/2`로 변경
- [x] **기능 4: 졸업장 터치 가드** — touchesBegan에 `children.contains(where: { $0.name == "diplomaOverlay" })` 가드 1줄 추가

---

## 8. Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (UserDefaults API 옵셔널 미반환)
- guard let 옵셔널 처리: 준수 (기존 `guard let self = self` 유지)
- MARK 섹션 구분: 준수 (변경 위치 모두 기존 MARK 안)
- GameConfig 상수 사용: 준수 (UserDefaults 키도 GameConfig 정의)
- weak self 캡처: 준수 (기존 `[weak self]` 유지)

## 9. SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 (분기는 didMove 끝부분에 유지)
- dt 기반 이동: N/A (본 sprint는 입력/이동 미접촉)
- SKAction 스폰 패턴: N/A
- 충돌 후 노드 즉시 삭제 없음: 준수 (변경 없음)
- HUD 노드 분리: 준수 (변경 없음)

---

## 10. 범위 외 미구현 항목

**없음** — SPEC의 4건 모두 정밀 적용. 허용 외 파일 변경 0건.

## 11. 필수 연동 변경

**없음** — SPEC가 명시한 4개 파일(GameConfig / TitleScene / GameScene / ResultScene)만 변경. TitleScene은 이미 GameConfig 상수 참조 중이라 *코드 변경 0건* (값만 바뀌어도 layoutLabels/layoutDifficultyCards/layoutCharacterCards에서 자동 재배치).
