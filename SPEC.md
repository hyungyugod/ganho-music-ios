# iPhone Landscape 잘림 해소 + 캐릭터 카드 분리감 강화 + 얼굴 SVG 동기화

## 개요
iPhone 17 Pro Landscape 시뮬레이터에서 발견된 3가지 UI 문제(StartScene 시작 버튼 하단 잘림, ResultScene 다시시작/공유 버튼 하단 잘림, CharacterSelectScene 5장 카드가 한 덩어리로 보임)를 한 번에 해소한다. 동시에 첨부된 5장 SVG(`mockups/svg-exports/{kim,jung,geon,im,lee}.svg`)와 CharacterFaceNode 현재 코드를 비교해 **차이가 있는 캐릭터만** path/색상을 재이식한다.

## 변경 유형
**혼합** (UI 비주얼 + 디바이스 대응 인프라)

## 게임 경험 의도
어떤 디바이스(iPhone SE ~ Pro Max)에서도 핵심 버튼이 잘리지 않고, 캐릭터 선택은 "내 친구를 뽑는다"는 느낌이 들도록 5장의 카드가 시각적으로 분리되어 보여야 한다. 카드 안 얼굴은 정해진 5명의 캐릭터 SVG 시안과 일치해야 캐릭터 정체성이 흔들리지 않는다.

## Sprint 범위 계약

### 허용 (이 외 절대 건드리지 말 것)
- **신규**: `GanhoMusic/GanhoMusic Shared/Utilities/SceneSafeArea.swift`
- **수정**: `GanhoMusic/GanhoMusic iOS/GameViewController.swift` — `viewSafeAreaInsetsDidChange()` 명시(정책 기록용 1메서드)
- **수정**: `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — 신규 상수 7개 추가 + 카드 치수 6개 갱신
- **수정**: `GanhoMusic/GanhoMusic Shared/Scenes/StartScene.swift` — `layoutStartButton()`만
- **수정**: `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` — `layoutLabels()` 내 두 버튼 좌표만
- **수정**: `GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift` — `cardBaseX`/`cardBaseY` 동적 spacing + `layoutConfirmButton`/`layoutSkillInfoChip` safeArea 적용
- **수정**: `GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift` — **첨부 SVG와 차이 있는 캐릭터의 빌드 함수만** path/색상 재이식

### 금지 (회귀 위험)
- `GanhoMusic Shared/Models/CharacterID.swift` — 메타데이터 불변
- `GanhoMusic Shared/Nodes/CharacterCardNode.swift` 내부 구조 — 외부 `GameConfig.characterCardWidth/Height` 치수만 흡수
- `GanhoMusic Shared/Scenes/GameScene.swift`
- `GanhoMusic Shared/Scenes/DifficultySelectScene.swift`
- `GanhoMusic Shared/Scenes/SkillExplanationScene.swift`
- `PlayerNode.swift` PNG 로딩 로직
- 기존 상수 `startSceneStartButtonOffsetY`(-180), `resultButtonOffsetYV2`(-180) — **값은 그대로 두고 적용만 중지**(다른 곳 참조 가능성)
- SKView frame을 만지는 모든 시도(2026-05 무한재귀 사고 기록)

### 판단 기준
"이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

---

## 변경 범위

### 수정할 파일
1. `GanhoMusic iOS/GameViewController.swift` — 정책 메서드 1개 추가 (frame 미터치 의도 기록)
2. `GanhoMusic Shared/Config/GameConfig.swift` — 상수 추가/갱신
3. `GanhoMusic Shared/Scenes/StartScene.swift` — `layoutStartButton()`만
4. `GanhoMusic Shared/Scenes/ResultScene.swift` — `layoutLabels()` 내 두 버튼 좌표만
5. `GanhoMusic Shared/Scenes/CharacterSelectScene.swift` — `cardBaseX`/`cardBaseY` 동적 spacing + 확인 버튼/skillInfoChip safeArea 적용
6. `GanhoMusic Shared/Nodes/CharacterFaceNode.swift` — 차이 있는 캐릭터(예: jung, geon, lee, im)만 재이식

### 추가할 파일
- `GanhoMusic Shared/Utilities/SceneSafeArea.swift` — 모든 씬이 공유하는 safeArea 헬퍼 1개

---

## 기능 상세

### 기능 1: SceneSafeArea 헬퍼 신설 (인프라)
- 설명: SKView frame은 절대 만지지 않는 정책 하에, SKScene 내부에서 `view.safeAreaInsets`를 일관되게 읽는 공용 헬퍼. Landscape 전용이므로 left/right 노치 회피가 가장 중요. view 미부착 시 `.zero` 반환으로 강제 언래핑/크래시 0건.
- 구현 위치: `GanhoMusic Shared/Utilities/SceneSafeArea.swift` (신규)
- 핵심 코드 구조:
  ```swift
  import SpriteKit
  import UIKit

  /// SKScene에서 view.safeAreaInsets를 안전하게 읽는 헬퍼.
  /// Landscape 전용 게임 — left/right 노치 회피가 가장 중요.
  /// GameViewController는 SKView frame을 절대 만지지 않는다(2026-05 무한재귀 사고 기록).
  /// 노드 배치 측에서 이 헬퍼를 호출해 좌표를 보정한다.
  enum SceneSafeArea {
      /// 현재 SKView의 safe area insets. view 미부착 시 .zero(안전 폴백).
      static func insets(for scene: SKScene) -> UIEdgeInsets {
          return scene.view?.safeAreaInsets ?? .zero
      }
  }
  ```

### 기능 2: GameViewController 정책 메서드 (정책 기록)
- 설명: `viewSafeAreaInsetsDidChange()`를 *명시적으로* override하되 본문은 super 호출 + 정책 주석만. 다음 사람이 frame을 만지려는 충동을 막는 의도.
- 구현 위치: `GameViewController.swift` — `// MARK: - SafeArea Policy` 섹션 신설
- 핵심 코드 구조:
  ```swift
  // MARK: - SafeArea Policy
  /// SKView frame은 직접 만지지 않는다(2026-05 무한재귀 사고 기록).
  /// safeArea 회피는 각 SKScene이 view.safeAreaInsets를 읽어 노드 좌표에 가산하는 방식만 허용.
  /// 본 메서드는 정책을 코드에 명시하기 위해 존재 — 본문은 super 호출만.
  override func viewSafeAreaInsetsDidChange() {
      super.viewSafeAreaInsetsDidChange()
      // 의도적 no-op. SKScene가 SceneSafeArea.insets(for:)로 직접 읽는다.
  }
  ```

### 기능 3: GameConfig 상수 토큰 갱신 + 신설
- 설명: 두 분류. (A) 신규 — 화면 가장자리 안전 마진 + 버튼 하단 inset. (B) 갱신 — 카드 치수 키워 분리감 강화. 기존 frame.midY 기반 상수는 **값 보존, 적용 중지**.
- 구현 위치: `GameConfig.swift` 끝부분에 새 MARK 섹션 추가 + 기존 상수 5개 값 갱신
- 핵심 코드 구조:
  ```swift
  // MARK: - Adaptive Layout (디바이스 대응 · iPhone SE ~ Pro Max)
  /// 화면 하단 안전 마진 — safeArea.bottom 위에 추가로 띄울 여백.
  static let adaptiveBottomMargin: CGFloat = 24
  /// 화면 상단 안전 마진.
  static let adaptiveTopMargin: CGFloat = 16
  /// 화면 좌우 안전 마진(노치/dynamic island 영역 회피).
  static let adaptiveHorizontalMargin: CGFloat = 20
  /// StartScene 시작 버튼 — 화면 하단 기준 안쪽 거리.
  static let startButtonBottomInset: CGFloat = 64
  /// ResultScene 두 버튼 — 화면 하단 기준 안쪽 거리.
  static let resultButtonBottomInset: CGFloat = 56
  /// CharacterSelect 카드 spacing 최소값(28pt) — 가장 좁은 디바이스(iPhone SE) 보장.
  static let characterSelectMinCardSpacing: CGFloat = 28
  /// CharacterSelect 카드 spacing 최대값(56pt) — Pro Max에서 과도하게 벌어지지 않도록 clamp.
  static let characterSelectMaxCardSpacing: CGFloat = 56
  ```

  **기존 상수 갱신 (값만 변경, 키 보존):**

  | 키 | 기존 | 신규 | 근거 |
  |---|---|---|---|
  | `characterCardWidth` | 48 | **76** | 게임 카드 톤(1.58×) |
  | `characterCardHeight` | 60 | **104** | 세로 카드 비율(1.73×) |
  | `characterFaceScale` | 0.55 | **0.82** | 카드 확대 비율 동기 |
  | `characterCardGlassWidth` | 124 | **156** | 카드 확대 비율 동기 |
  | `characterCardGlassHeight` | 166 | **204** | 카드 확대 비율 동기 |
  | `characterSelectCardZigzagOffsetV3` | 4 | **6** | 카드 확대에 맞춘 미세 조정 |

  **변경 금지(값 보존):** `startSceneStartButtonOffsetY`(-180), `resultButtonOffsetYV2`(-180), `characterSelectCardSpacingV3`(22 — 새 동적 계산이 이걸 우회), `characterSelectConfirmButtonOffsetY`, `characterSelectSkillInfoOffsetY`.

### 기능 4: StartScene 시작 버튼 safeArea 회피
- 설명: 시작 버튼을 frame.midY 기반 고정 오프셋에서 **화면 하단 + safeArea.bottom + startButtonBottomInset** 식으로 교체.
- 구현 위치: `StartScene.swift` — `layoutStartButton()` 함수 본문만
- 핵심 코드 구조:
  ```swift
  private func layoutStartButton() {
      let safe = SceneSafeArea.insets(for: self)
      // frame.minY는 SpriteKit 좌표계에서 화면 하단. safeArea.bottom + inset만큼 위로.
      startButton.position = CGPoint(
          x: frame.midX,
          y: frame.minY + safe.bottom + GameConfig.startButtonBottomInset
      )
  }
  ```
- 제거/회피: `frame.midY + GameConfig.startSceneStartButtonOffsetY` 식은 더이상 사용하지 않음(상수 자체는 보존).

### 기능 5: ResultScene 두 버튼 safeArea 회피
- 설명: `shareButton`과 `restartButton`의 y좌표를 `frame.midY + offset` → `frame.minY + safe.bottom + inset`으로 교체. x좌표는 기존 `resultShareButtonXOffsetV2` / `resultRestartButtonXOffsetV2` 유지.
- 구현 위치: `ResultScene.swift` — `layoutLabels()` 함수 *끝부분 두 줄만*
- 핵심 코드 구조:
  ```swift
  let safe = SceneSafeArea.insets(for: self)
  let buttonY = frame.minY + safe.bottom + GameConfig.resultButtonBottomInset
  shareButton?.position = CGPoint(
      x: frame.midX + GameConfig.resultShareButtonXOffsetV2,
      y: buttonY
  )
  restartButton.position = CGPoint(
      x: frame.midX + GameConfig.resultRestartButtonXOffsetV2,
      y: buttonY
  )
  ```
- 다른 라벨 위치(titleLabel/scoreLabel/bestLabel/...)는 변경 0건 — frame.midY 기반 그대로 유지(카드 패널 안 배치이므로 잘림 없음).

### 기능 6: CharacterSelect 카드 동적 spacing + 확인 버튼 safeArea
- 설명: `cardBaseX(for:)`의 spacing을 **화면 폭 비례 동적 계산**으로 교체. 좌우 안전 마진 회피 + min/max clamp. 확인 버튼과 skillInfoChip도 safeArea.bottom 회피.
- 구현 위치: `CharacterSelectScene.swift` — `cardBaseX(for:)`, `layoutConfirmButton()`, `layoutSkillInfoChip()`
- 핵심 코드 구조:
  ```swift
  /// Sprint 7+ — 동적 spacing. 화면 폭에 비례해 자동 확장, 최소/최대 clamp.
  private func cardBaseX(for id: CharacterID) -> CGFloat {
      let allCases = CharacterID.allCases
      let count = allCases.count
      let width = GameConfig.characterCardWidth   // 76
      let safe = SceneSafeArea.insets(for: self)
      // 좌우 안전 마진을 뺀 사용 가능한 폭.
      let usable = frame.width
          - safe.left - safe.right
          - 2 * GameConfig.adaptiveHorizontalMargin
      // 카드 N장 자체 폭을 뺀 잔여를 (N-1) 간격에 균등 분배.
      let rawSpacing = (usable - width * CGFloat(count)) / CGFloat(count - 1)
      let spacing = min(
          GameConfig.characterSelectMaxCardSpacing,
          max(GameConfig.characterSelectMinCardSpacing, rawSpacing)
      )
      let totalWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
      let startX = frame.midX - totalWidth / 2 + width / 2
      guard let index = allCases.firstIndex(of: id) else { return startX }
      return startX + CGFloat(index) * (width + spacing)
  }
  ```
  - `cardBaseY(for:)`는 새 `characterSelectCardZigzagOffsetV3`(=6) 값을 그대로 흡수 — 별도 변경 불필요(상수만 값 변경).
  - `layoutConfirmButton()`: `frame.minY + safe.bottom + GameConfig.adaptiveBottomMargin + 추가 inset`(PrimaryButton 높이 고려해 카드 줄 아래 + safeArea 위)로 교체. 카드 줄과 충돌 안 나도록 카드 하단(`cardBaseY + characterCardHeight/2`)보다 더 아래여야 함. 동적 계산으로 안전 확보.
  - `layoutSkillInfoChip()`: confirm 버튼 위쪽 ~36pt 간격으로 배치(상대 좌표). 기존 frame.midY 기반 식은 폐기.

### 기능 7: CharacterFaceNode SVG 동기화 (차이 있는 캐릭터만)
- 설명: Generator는 5명의 `build{Kim,Jung,Geon,Im,Lee}Face()`를 첨부 SVG와 1:1 비교. 차이가 있는 캐릭터만 path 좌표/색상을 재이식. SVG y-down → SpriteKit y-up이므로 모든 SVG y 값에 `-1` 곱하기(기존 파일 헤더 라인 11의 변환 패턴 동일).
- 구현 위치: `CharacterFaceNode.swift` — 각 `build*Face()` 함수

#### 비교 결과 (현재 코드 vs 첨부 SVG)

| 캐릭터 | 현재 코드 | 첨부 SVG | 차이 판단 |
|---|---|---|---|
| **kim** | viewBox -50..55 좌표계 사용, 헤드폰 cy=2 rx=7 ry=10, 닫힌 눈 path(-14,-6)~ | viewBox -120..130 (큰 좌표) 헤드폰 cy=4 rx=14 ry=20, 컬 디테일 4개, 클로즈드아이 path(-28,-4)~(-12,-4) | 좌표계 다르지만 형태 일치. 카드 위 76×104 안에서 시각 동일 결과 가능성. **유지(변경 0)** 권장 — 차이 발견 시 재이식. |
| **jung** | 스파이크 머리 + 헤드밴드(코랄) + 작은 cap + 곡괭이 미니 | 핑크 러닝캡(#FF8E80) + 챙(#C44A3D) + G+ 로고 + 안경(rx=18) + 땀방울 | **완전 다른 디자인** — 곡괭이/스파이크/헤드밴드 없음. **재이식 강력 후보**: 핑크 러닝캡 + 안경 + 땀방울. |
| **geon** | 단정한 머리 + 작은 안경(r=9) + 책 미니 + 갈색 눈 path | **라벤더 톤** 큰 둥근 검은 눈(rx=9 ry=12) + 위 머리 한 점 tuft + 단순 어두운 머리 + 작은 미소. 안경/책 없음 | **완전 다른 디자인 (v6)** — **재이식 강력 후보**. |
| **im** | 긴머리 좌우 + 앞머리 + 고양이귀 + 고양이눈 + 수염 + 분홍코 | 긴머리 좌우 + 가운데 가르마 앞머리 + 작은 고양이귀(삼각형) + 큰 둥근 눈(쿠키런 톤) + 분홍 고양이코. **수염 없음** | **부분 차이 (v6)** — 큰 둥근 눈 + 수염 제거. **재이식 강력 후보**. |
| **lee** | Bob cut + **강아지귀** ❌ + 동그란 눈 + 혀 | 곱슬 단발(side curls) + 앞머리 + 닫힌 눈 미소(SVG 시그너처) + 따뜻한 미소. **강아지귀 명시적으로 제거(SVG 주석 v3)** | **부분 차이 (v3)** — 강아지귀 제거 + 닫힌 눈 + side curls dots. **재이식 강력 후보**. |

#### Generator 작업 절차
1. 각 빌드 함수를 첨부 SVG와 시각 비교(코드 path 좌표 → 머릿속 렌더 → SVG 형태 매칭)
2. **kim**: 변경 권장 0 (좌표 스케일은 다르지만 형태 일치). Generator가 명확한 차이를 발견하면 재이식 가능.
3. **jung**: 첨부 SVG 기반으로 buildJungFace 전체 재이식 — 핑크 러닝캡(`#FF8E80`) + 챙(`#C44A3D`) + 안경 원형 + 동공 + 결연한 눈썹 + 땀방울(`#9BCDF0`)
4. **geon**: 전체 재이식 — `#1F1410`(어두운 머리) + 위 한 점 tuft path + 큰 검은 눈 ellipse + 흰 highlight + 작은 미소. 책/안경/단정한머리 제거.
5. **im**: 부분 재이식 — 수염 제거 + 고양이눈을 큰 둥근 눈(`#2D2A4A` 채움) + 흰 highlight로 교체 + 앞머리 가운데 가르마 path 갱신. 긴머리/고양이귀/분홍코는 유지.
6. **lee**: 부분 재이식 — 강아지귀 ellipse 제거 + side curls + curl detail dots 추가 + 동그란 눈을 닫힌 눈 path로 교체 + 혀 제거.
7. 새 raw 색상이 필요하면 `UIColor(hex: "#...")` 기존 패턴 따름. `ColorTokens`에 동일 hex 토큰이 있으면 그쪽 우선.
8. SVG y-down → SpriteKit y-up: 모든 y 값에 `-1` 곱하기(기존 변환 패턴 보존).
9. SVG의 큰 좌표계(±120)를 코드의 작은 좌표계(±32~±70)로 *축소*하지 말 것 — Generator는 기존 함수의 좌표 스케일을 답습하고 *형태* 일치를 우선시.
10. 빌드 함수 시작에 `// 기준 SVG: mockups/svg-exports/<id>.svg (vN)` 주석 1줄 추가.

---

## 상수 토큰 표

### 신규 추가 (GameConfig.swift 끝)
| 상수 | 값 | 용도 |
|---|---|---|
| `adaptiveBottomMargin` | 24 | 화면 하단 안전 마진 |
| `adaptiveTopMargin` | 16 | 화면 상단 안전 마진 |
| `adaptiveHorizontalMargin` | 20 | 좌우 노치 회피 |
| `startButtonBottomInset` | 64 | StartScene 시작 버튼 하단 inset |
| `resultButtonBottomInset` | 56 | ResultScene 두 버튼 하단 inset |
| `characterSelectMinCardSpacing` | 28 | 카드 spacing 최소(SE 보장) |
| `characterSelectMaxCardSpacing` | 56 | 카드 spacing 최대(Pro Max clamp) |

### 갱신 (키 보존, 값만 변경)
| 상수 | 기존 | 신규 |
|---|---|---|
| `characterCardWidth` | 48 | **76** |
| `characterCardHeight` | 60 | **104** |
| `characterFaceScale` | 0.55 | **0.82** |
| `characterCardGlassWidth` | 124 | **156** |
| `characterCardGlassHeight` | 166 | **204** |
| `characterSelectCardZigzagOffsetV3` | 4 | **6** |

### 보존 (값 변경 0, 적용 중지)
- `startSceneStartButtonOffsetY` (-180) — 새 식이 이걸 우회
- `resultButtonOffsetYV2` (-180) — 새 식이 이걸 우회
- `characterSelectCardSpacingV3` (22) — 새 동적 계산이 이걸 우회
- `characterSelectConfirmButtonOffsetY`, `characterSelectSkillInfoOffsetY` — 새 식이 이걸 우회

---

## 합격 기준 (Evaluator 채점)

### 빌드 / 패턴
- xcodebuild 성공 (iPhone SE / 17 Pro / 17 Pro Max 시뮬레이터)
- 강제 언래핑 0건 (SceneSafeArea가 `?? .zero` 폴백 제공)
- Timer 사용 0건
- 매직 넘버 0건 — 모든 새 좌표가 GameConfig 상수 참조
- MARK 섹션 구분 적절 (`// MARK: - Adaptive Layout`, `// MARK: - SafeArea Policy`)

### SpriteKit 패턴
- `didChangeSize(_:)` → `layoutXxx()` 재호출 보존 (StartScene/ResultScene/CharacterSelectScene 모두)
- scaleMode `.resizeFill` 보존
- 초기화는 `didMove(to:)`에 보존
- SKView frame **건드림 0건** (GameViewController)

### 기능 완성도
- StartScene 시작 버튼이 화면 하단 safeArea 위 64pt에 위치 — Pro Max에서도 잘림 없음
- ResultScene 두 버튼이 화면 하단 safeArea 위 56pt에 위치 — SE에서도 잘림 없음
- CharacterSelect 5장 카드가 76×104pt + 화면 폭 비례 동적 spacing(28~56pt clamp)
- 카드 외곽 글래스 컨테이너(156×204) 동기 확대
- 얼굴 노드(scale 0.82)도 동기 확대
- 첨부 SVG와 차이 있는 캐릭터(최소 jung, geon)의 얼굴이 시각 동기화됨

### 회귀 방지 (각 항목 0건)
- GameScene 코드 변경 0
- DifficultySelectScene 코드 변경 0
- SkillExplanationScene 코드 변경 0
- CharacterCardNode 내부 구조 변경 0 (외부 GameConfig 치수만 흡수)
- CharacterID 변경 0
- PlayerNode 변경 0

---

## 검증 절차

### 1. 빌드 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```
SUCCEED.

### 2. 시각 비교 (수동)
| 디바이스 | StartScene | CharacterSelect | ResultScene |
|---|---|---|---|
| iPhone SE | 시작 버튼 잘림 X | 카드 5장 화면 폭 안에 + spacing ≥ 28pt | 다시시작/공유 잘림 X |
| iPhone 17 Pro | 시작 버튼 잘림 X | 카드 spacing 자연스럽게 늘어남 | 잘림 X |
| iPhone 17 Pro Max | 시작 버튼 잘림 X | spacing ≤ 56pt clamp 작동 | 잘림 X |

### 3. 캐릭터 얼굴 비교
`mockups/svg-exports/*.svg`를 브라우저로 띄우고 시뮬레이터 CharacterSelect 옆에 두고 1:1 시각 비교:
- kim: 곱슬 번머리 + 코랄 헤드폰
- jung: 핑크 러닝캡 + 안경 + 땀방울 (스파이크/곡괭이 없음)
- geon: 라벤더 톤 큰 검은 눈 + 위 머리 한 점 (안경/책 없음)
- im: 긴머리 + 작은 고양이귀 + 큰 둥근 눈 + 분홍 고양이코 (수염 없음)
- lee: 곱슬 단발 + 앞머리 + 닫힌 눈 미소 (강아지귀 없음)

### 4. 회귀 검증
StartScene → CharacterSelect(5명 모두 탭) → DifficultySelect → GameScene(45초 플레이) → ResultScene → 다시시작 → StartScene 1사이클 정상 작동.

---

## 주의사항

- **SKView frame 미터치 절대 원칙**: GameViewController에 `view.frame =` 또는 `skView.frame =` 같은 대입은 절대 추가 금지. `viewSafeAreaInsetsDidChange()` 본문은 super 호출만.
- **SceneSafeArea 호출 시점**: `didMove(to:)`보다는 `layoutXxx()` 안에서 매번 호출. `didChangeSize`에서 layout이 다시 불릴 때 회전/safeArea 변화를 자동 흡수.
- **CharacterCardNode 내부 미터치**: 카드 크기는 init 시점에 `GameConfig.characterCardWidth/Height`로 흡수 — 자동 확대. CharacterCardNode 자체 코드 수정 0건이어야 함.
- **CharacterFaceNode 좌표계 보존**: 기존 작은 좌표계(±32~±70)와 모든 캐릭터가 일관성을 가짐. 신규 캐릭터(jung/geon) 재이식 시도 *기존 작은 좌표계로 환산*하는 게 안전(SVG의 ±120 좌표계를 그대로 옮기면 카드 밖으로 비어져 나옴).
- **빌드 에러 가능성**: `SceneSafeArea`는 `import UIKit` 필요. 다른 씬 파일은 이미 SpriteKit만 import 중이므로 헬퍼 호출 시 추가 import 불필요(SKScene이 UIKit 전이 import).
- **didChangeSize 회귀**: 모든 씬의 `didChangeSize`는 기존 layout 함수들을 재호출하므로 자동 적응. 새 코드를 추가할 때 이 패턴을 깨지 말 것.
- **alpha=0 라벨 보존**: ResultScene의 `characterLabel`, `difficultyLabel`, `statsLabel`, `promptLabel`은 alpha=0이지만 부착되어 있다. 위치 코드는 frame.midY 기반 그대로 두기(보호 가드).
- **Sprint 카운터**: 이 변경은 단일 디자인 리뉴얼 Sprint가 아니므로 `DESIGN_RENEWAL_STATE.md` 갱신은 진행 로그 한 줄만.
