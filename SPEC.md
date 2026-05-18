# Phase 7-5 — 시뮬레이터 핫픽스 (전환 시점 4종 버그)

## 개요
Phase 7-1~7-4 도입 후 시뮬레이터에서 발견된 전환 시점 버그 4개를 한 sprint에 묶어 수정. 사용자 보고: "메뉴 이상 / 컷씬 강제 / 종료 화면 이상". 진단 결과 4개 root cause 식별.

## 변경 유형
**버그 수정** — 신규 기능 0, 오직 기존 버그 4건 수정.

## Sprint 범위 계약

### 수정할 4개 버그

**버그 1: 카드 절단** — 소형 화면(iPhone SE 640×480)에서 캐릭터 카드 5장이 잘림.
- 원인: Phase 7-1이 `characterCardOffsetY` -160 → -200으로 옮겨 작은 화면 하단 초과.
- 수정: 난이도 카드를 *titleLabel 아래/bestLabel 위* (상단)에 배치. characterCardOffsetY를 -160으로 되돌림.

**버그 2: 인트로 컷씬 매번 강제 표시** — 사용자가 "강제로 떠서 이상" 보고.
- 원인: Phase 7-3이 모든 didMove에서 무조건 컷씬 표시.
- 수정: UserDefaults 플래그 `hasSeenIntroCutscene` 도입. 첫 게임 1회만 표시 후 영구 스킵. 사용자 결정: "최초 1회만 표시".

**버그 3: 졸업장 좌표 어긋남** — 작은 화면에서 졸업장 위치 깨짐.
- 원인: Phase 7-4가 anchor를 `frame.midX/midY`로 전달하는데 ResultScene은 `size`가 1024×768로 고정. 실제 frame과 불일치.
- 수정: anchor를 `size.width/2, size.height/2`로 변경.

**버그 4: ResultScene 터치 경합** — 졸업장이 떠 있는데 탭하면 TitleScene 동시 전환.
- 원인: ResultScene.touchesBegan이 `isTransitioning`만 검사. 졸업장 존재 여부 미검사.
- 수정: `children.contains(where: { $0.name == "diplomaOverlay" })` 시 early return.

### 허용
1. `TitleScene.swift` — 난이도 카드 배치 변경 (상단 이동)
2. `GameConfig.swift` — `difficultyCardOffsetY` 값 변경(-120 → +60), `characterCardOffsetY` 되돌림(-200 → -160), 신규 키 `hasSeenIntroCutscene` UserDefaults 키
3. `GameScene.swift` — showIntroCutscene 진입 시 UserDefaults 플래그 검사 + 컷씬 dismiss 시 플래그 set
4. `ResultScene.swift` — touchesBegan에 졸업장 가드 1줄 추가, presentDiploma anchor 계산 변경
5. pbxproj 변경 0건 (신규 파일 0개)

### 금지
- 캐릭터 픽셀 아트 도입 (다음 sprint)
- 컷씬 시스템 자체 제거
- 새 노드/매니저/리포지토리 추가
- 게임 로직 (점수/난이도/적/F) 변경
- 졸업 판정 로직 변경

---

## 기능 상세

### 기능 1: 카드 레이아웃 재배치 (버그 1 수정)

**현재 레이아웃** (640pt 화면 기준):
```
midY +80 : titleLabel
midY +20 : bestLabel
midY -20 : playsLabel
midY -80 : promptLabel
midY -120: 난이도 카드 3장 (Phase 7-1 신규)
midY -200: 캐릭터 카드 5장 (Phase 7-1이 -160 → -200으로 이동)
```
→ 640pt 화면 midY=320, -200 시 y=120pt. 카드 높이 60pt 절반 30pt 내려가면 *하단에서 90pt* — *경계 위태*.

**수정 후 레이아웃**:
```
midY +120: titleLabel (조금 위로)
midY +80 : 난이도 카드 3장 (titleLabel 아래)
midY +20 : bestLabel
midY -20 : playsLabel
midY -80 : promptLabel
midY -160: 캐릭터 카드 5장 (-160 되돌림, 원래 위치)
```
→ 카드가 *위·아래로 나뉘어* 상단 카드는 80pt, 하단 카드는 -160pt. *작은 화면 안전*.

**변경 상수**:
- `titleLabelOffsetY: CGFloat = +120` (기존 +80에서 위로)
- `difficultyCardOffsetY: CGFloat = +80` (기존 -120에서 *상단*으로 이동)
- `characterCardOffsetY: CGFloat = -160` (기존 -200 되돌림)

TitleScene.swift의 `layoutLabels` 또는 `setupLabels`에서 `titleLabel.position.y`를 GameConfig 상수로 참조하도록 변경. 현재 하드코딩이면 GameConfig 상수 신설.

### 기능 2: 컷씬 최초 1회만 (버그 2 수정)

**UserDefaults 키 신설**:
```swift
static let hasSeenIntroCutsceneUserDefaultsKey: String = "hasSeenIntroCutscene"
```

**GameScene.didMove 분기**:
```swift
// 현재 (Phase 7-3):
gameState = .cutscene
showIntroCutscene()

// 수정 후 (Phase 7-5):
let hasSeenIntro = UserDefaults.standard.bool(forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
if hasSeenIntro {
    // 두 번째 이상 — 컷씬 스킵, 곧장 카운트다운
    gameState = .countdown
    showCountdown()
} else {
    // 최초 1회 — 컷씬 표시 + 플래그 set
    gameState = .cutscene
    showIntroCutscene()
}
```

**showIntroCutscene 안의 onDismiss 콜백**에서 플래그 set:
```swift
onDismiss: { [weak self] in
    guard let self = self else { return }
    UserDefaults.standard.set(true, forKey: GameConfig.hasSeenIntroCutsceneUserDefaultsKey)
    self.gameState = .countdown
    self.showCountdown()
}
```

### 기능 3: 졸업장 좌표 보정 (버그 3 수정)

**ResultScene.presentDiploma 변경**:
```swift
// 현재 (Phase 7-4):
anchor: CGPoint(x: frame.midX, y: frame.midY),

// 수정 후 (Phase 7-5):
anchor: CGPoint(x: size.width / 2, y: size.height / 2),
```

**근거**: ResultScene이 `.resizeFill` 모드 + size를 1024×768 고정 생성. SKScene의 self size는 항상 (1024, 768)이지만 frame은 view 크기 동적. background SKSpriteNode가 sceneSize 기준이므로 anchor도 같은 기준이어야 정렬.

### 기능 4: 졸업장 터치 가드 (버그 4 수정)

**ResultScene.touchesBegan 변경**:
```swift
// 현재:
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }
    // ...기존 로직...
}

// 수정 후:
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }
    // 졸업장이 표시 중이면 TitleScene 전환을 막는다. 졸업장 자체가 isUserInteractionEnabled=true로
    // 자기 터치를 흡수하므로 *이 경로*는 거의 도달 안 하지만, edge case 안전망.
    if children.contains(where: { $0.name == "diplomaOverlay" }) { return }
    guard let view = self.view else { return }
    // ...기존 TitleScene 전환 로직...
}
```

---

## 변경 파일 목록

1. `Config/GameConfig.swift`:
   - `titleLabelOffsetY: CGFloat = 120` 신설
   - `difficultyCardOffsetY` 값 -120 → +80
   - `characterCardOffsetY` 값 -200 → -160
   - `hasSeenIntroCutsceneUserDefaultsKey: String = "hasSeenIntroCutscene"` 신설

2. `Scenes/TitleScene.swift`:
   - titleLabel.position.y가 하드코딩이면 GameConfig.titleLabelOffsetY 참조로 변경 (또는 layout 메서드 안에서 frame.midY + offset)
   - 다른 라벨 위치 변경 0 — 난이도 카드와 캐릭터 카드의 offsetY *상수만* 바뀌어서 자연 재배치

3. `GameScene.swift`:
   - didMove 끝부분 if/else 분기 (hasSeenIntro 검사)
   - showIntroCutscene 안 onDismiss 클로저에 UserDefaults set 추가

4. `Scenes/ResultScene.swift`:
   - presentDiploma의 anchor 변경
   - touchesBegan에 졸업장 가드 1줄 추가

5. **신규 파일 0개**, **pbxproj 변경 0건**.

---

## 회귀 0 자연 차단

1. **카드 레이아웃 — `characterCardOffsetY` 되돌림** = 작은 화면 안전 + Phase 5 캐릭터 카드 동작 그대로 (-160은 Phase 5 원래 값).
2. **컷씬 스킵 — UserDefaults bool 기본 false** = 첫 실행 사용자(키 없음)에게는 *컷씬 표시*로 동작. 이후 영원히 스킵. 키 자체가 새 키라 기존 키와 충돌 0.
3. **졸업장 좌표 — size.width/2** = sceneSize와 동일 기준. background가 sceneSize 크기이므로 정렬 자동.
4. **터치 가드 — 졸업장 노드 name 검사** = 졸업장 없을 때 children에 해당 노드 0 → early return 발화 0. 기존 동작 그대로.

---

## 주의사항

1. **TitleScene 레이아웃 픽셀 검증** — frame.midY + offset 합산 결과가 *작은 화면(640pt)*에서도 화면 안에 들어가는지. titleLabel +120 → 화면 상단 -80pt 위치 (640pt 화면 위쪽 200pt에서 안전). 캐릭터 카드 -160 → 화면 중앙 -160 = 화면 하단 -160 (640pt 화면 80pt 위치). 안전.

2. **UserDefaults bool 기본값** — Apple 보장: 키 없으면 false 반환. 최초 사용자 자동으로 hasSeenIntro = false → 컷씬 표시 → onDismiss에서 true set → 이후 영원 스킵.

3. **showIntroCutscene 안에서 UserDefaults set** — `[weak self]` 캡처 후에도 UserDefaults.standard 접근은 self 무관. self 해제 시에도 플래그는 set됨(부수 효과 안전).

4. **isUserInteractionEnabled 자동 흡수** — DiplomaOverlayNode가 *자식 노드 자기* 터치 흡수. children 가드는 *edge case 안전망*이지 핵심 차단은 노드 자체 isUserInteractionEnabled.

5. **시뮬레이터 끊김** — 본 sprint *범위 외*. SpriteKit + PhysicsBody 다수 = 시뮬레이터 한계. 실기에서는 보통 60fps. 별도 sprint에서 프로파일링 필요 시 진행.

6. **GameConfig 상수 변경 — 정수 값만** = 함수/타입 시그니처 변경 0. 컴파일 영향 0.

7. **TitleScene titleLabel offsetY가 하드코딩이면** GameConfig 신규 상수 도입. 그 외 라벨(bestLabel/playsLabel/promptLabel) 위치는 변경 0 — 난이도 카드를 +80에 두면 *bestLabel(+20)과 60pt 간격* 안전.
