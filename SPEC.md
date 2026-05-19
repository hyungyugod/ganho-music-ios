# Sprint 7 Phase A — 캐릭터 선택 NIKKE 카드 리뉴얼

## 개요
캐릭터 선택 화면의 5장 카드를 **NIKKE 식 세로 4:5 구조**로 재정비한다. 카드 폭/gap을 130/14 → 160/22로 키워 겹침 0을 보장하고, 좌상단 속성 헥사·좌하단 등급·우상단 CD 미니칩·하단 이름+속도 칩으로 한 카드에 5종 정보를 위계 있게 배치한다. 선택 상태는 기존 scale 1.08 + translateY -12 + 코랄 stroke에 **하단 코랄 radial 글로우 + 상단 "선택됨" 코랄 알약**을 추가해 시선이 즉시 잡히도록 강화한다.

## 변경 유형
**비주얼** (게임 로직 0 회귀, 새로 추가되는 model property는 모두 시각용 computed)

## 게임 경험 의도
플레이어가 캐릭터 선택 화면에 진입한 0.5초 안에 "이 친구는 어떤 속성·등급·스킬을 가졌는지"를 한눈에 인지하게 한다. 작은 카드 안에 정보가 빽빽이 들어차 있지만 위계(속성→얼굴→이름→메타)가 명확해서 다섯 친구를 비교하는 재미가 생긴다. 톤은 여전히 따뜻한 피치·코랄 — NIKKE의 다크 톤은 차용하지 않는다.

## Sprint 7 Phase A 범위 계약

### 허용 (이 SPEC 범위)
- `CharacterID` 신규 computed property 2종(`rarity`, `elementSymbol`) — 순수 시각 lookup, 게임 로직 분기 0
- `PlayerSkill` 신규 computed property 1종(`cooldownText`) — CD 미니칩 표시용 문자열
- `GameConfig` 카드 v3 상수 4종 + 배지/칩 상수 ~12종 추가 (기존 상수 값 변경 0)
- `CharacterCardNode` 내부 구조 변경: 카드 폭·높이를 `characterCardWidthV3`/`HeightV3`로 교체, 카드 외부에 부착되던 정보(이름·태그·색점)를 카드 내부로 흡수, 신규 배지 3종(`attachElementBadge`/`attachRarityBadge`/`attachCDChip`) 부착
- `CharacterSelectScene` 카드 외곽 글래스 컨테이너 폭/높이/cornerRadius를 새 카드 비율(160×200, 4:5)에 맞춰 갱신, 선택 상태에 코랄 glow + 코랄 알약 부착, 하단 스킬 패널 폭 좁히기 + 카드 행과의 충돌 회피 마진 추가
- `cardBaseX(for:)` / `cardBaseY(for:)` 좌표 계산 함수 본문만 v3 폭/spacing 상수 참조로 갱신 (시그니처 0 변경)
- 신규 mockup HTML 1건: `mockups/character-select-v3.html`

### 금지 (절대 건드림 0)
- `CharacterSelectScene.init(size:)` / `newCharacterSelectScene()` 시그니처
- `CharacterPreferenceRepository.current` 복원/저장 로직
- `cardBaseX(for:)` / `cardBaseY(for:)` 함수 **이름·시그니처·호출 순서** (수치만 갱신 OK)
- `.kim → DifficultySelectScene` / `그 외 → SkillExplanationScene` 분기 로직
- `transitionToNext` / `transitionToStart` 콜백 시그니처와 fade transition 시간
- `CharacterID.dotColor` (기존 색 점 토큰 — 카드 흡수 후에도 *값* 유지)
- `CharacterID.displayName` / `tag` / `playerSpeedMultiplier` / `skill` / `color` 값
- `PlayerSkill.cooldown` / `duration` / `oncePerGame` / `displayName` / `fullDescription` / `rangeText` / `castText` 값
- 게임 로직 일체: 점수·콤보·물리·hitbox·input·AI·저장·사운드 — Phase A는 메뉴 씬 비주얼만
- `ResultScene` / `GameScene` / `GameState` / `PhysicsCategory` / Managers / Repositories — 0줄
- 기존 `characterCardWidth`(76)·`characterCardHeight`(104)·`characterCardGlassWidth`(156)·`characterCardGlassHeight`(204) 등 v2 상수 — 값 보존 (다른 참조 가능성)

### 판단 기준
"이 변경이 없으면 NIKKE 식 5요소 카드가 제대로 보이지 않는가?" → YES면 허용, NO면 금지.

---

## 변경 범위

### 수정할 파일 (5개)
- `Models/CharacterID.swift`: `rarity: Int` + `elementSymbol: String` 두 computed property 추가
- `Models/PlayerSkill.swift`: `cooldownText: String` computed property 추가 (CD 미니칩 라벨용)
- `Config/GameConfig.swift`: v3 카드 상수 4종 + 배지/칩 위치·폰트 상수 ~12종 추가 (기존 값 변경 0)
- `Nodes/CharacterCardNode.swift`: 카드 폭/높이를 v3로, 정보 흡수(이름 라벨), 배지 3종 부착 메서드 추가, `setSelected` 코랄 glow + "선택됨" 알약 토글
- `Scenes/CharacterSelectScene.swift`: 글래스 컨테이너 폭/높이를 v3 카드(160×200)에 맞춰 갱신, 카드 외부 태그·색점·이름 부착 코드 *비활성 또는 제거*(카드 내부로 이전), 카드 자식 배지가 화면에 보이도록 zPosition 정리, 하단 스킬 패널 폭 좁히기, `cardBaseX`/`cardBaseY` 내부의 폭/spacing 상수만 v3로 교체

### 추가할 파일 (1개)
- `mockups/character-select-v3.html`: Phase A 신규 시각 레퍼런스 (브라우저 시각 확인용, Swift 코드 컴파일 영향 0)

---

## 신규 mockup 시각 사양 — `mockups/character-select-v3.html`

Generator가 이 파일을 신규 작성한다. 아래 사양을 그대로 옮기면 된다.

### 페이지 골격
- v2와 동일한 phone-frame(aspect-ratio 19.5/9, max-width 920px) + island bar(좌측 18px) 재사용
- 외곽 페이지 톤·폰트 로딩(Jua, Gowun Dodum, Noto Sans KR) v2 그대로 복사

### 배경 그라데이션 (v2와 동일 3-stop)
```css
background:
  radial-gradient(ellipse at 80% 20%, #FFD9B8 0%, transparent 50%),
  radial-gradient(ellipse at 20% 80%, #E5C8E8 0%, transparent 60%),
  linear-gradient(165deg, #FFE5D0 0%, #FFC8B5 45%, #DCC9E8 100%);
```

### 상단 영역
- 좌상단 GlassPill "← 메인" (v2 그대로)
- 헤더 중앙: AccentLine(32×3 코랄) + Jua 28pt "함께할 친구를 골라요" + Gowun Dodum 12pt "친구마다 다른 스킬과 이동속도를 가져요"
- 헤더 top 위치 기존 16%

### 카드 5장 배치
- `.cards-row` `top: 36%` (v2 42%에서 -6% 위로 — 카드 키운 만큼 공간 확보)
- gap **22px** (v2 14px → 22)
- 카드 폭 **160px** / 높이 **200px** / cornerRadius **22px** / 4:5 비율
- 배경: `rgba(255,255,255,0.65)` + backdrop-filter blur(10px)
- border: 2px transparent

### 카드 내부 5요소 (zPos 순서: glow → background → 얼굴 → 배지 → 텍스트)

| 요소 | 위치 (카드 좌상단 기준) | 시각 |
|---|---|---|
| **속성 헥사 아이콘** (좌상단) | top 12, left 12 | 28×28 헥사(육각형 path) — 캐릭터별 색 토큰 fill, 흰색 1.5 stroke, 안에 16pt 이모지 (⚡/💧/🌿/🌙/🌸) |
| **등급 로마숫자 배지** (좌하단) | bottom 12, left 12 | 26×18 라운드 사각(cornerRadius 8) — navyDeep 알파 0.85 fill, Jua 11pt 골드 "I"/"II"/"III" |
| **CD 미니칩** (우상단) | top 12, right 12 | 자동 폭 라운드 알약 (Jua 9pt 흰색, padding 4×8, coralLight 알파 0.85 fill) — 텍스트 "1회"/"2회"/"∞" |
| **얼굴 SVG** (중앙) | 카드 중앙 (translate -8 위쪽) | viewBox -50 -55 100 110 v2 SVG 그대로 재사용 — width 88, height 88 |
| **이름 + 속도 칩** (하단) | bottom 22 | Jua 15pt navyDeep "김간호" 위 | Gowun Dodum 10pt scrubMint "⚡ ×1.00" 아래 |

### 5장 캐릭터별 배지 매핑

| 캐릭터 | 속성 헥사 색 (dotColor 재사용) | 속성 이모지 | 등급 (rarity) | CD 미니칩 |
|---|---|---|---|---|
| 김간호 (kim) | #FF8E80 coralLight | 🌸 | **II** (2) | ∞ (스킬 없음) |
| 정간호 (jung) | #9BE0CC scrubMint | 🌿 | **I** (1) | 1회 |
| 건간호 (geon) | #B89DD9 lavenderSoft | 🌙 | **III** (3) | 1회 |
| 임간호 (im) | #FFB347 musicGold | ⚡ | **II** (2) | **1회** (oncePerGame = true → "1회"로 매핑) |
| 이간호 (lee) | #FF8E80 coralLight | 💧 | **I** (1) | 1회 |

> **합의 (Generator는 이 매핑 그대로 따른다)**: `cooldownText`는 `oncePerGame == true`면 "1회", `cooldown == .infinity`면 "∞", 그 외는 "1회"로 단순화 (NIKKE 식 1·2·∞ 시각 위계 차용). 정확한 초 단위는 SkillExplanationScene 메타 칩이 담당 — 카드의 CD 미니칩은 *위계 신호*일 뿐.

### 선택 상태 강화 (3번째 카드 .selected 데모)
- 기존: scale(1.08) + translateY(-12) + 코랄 stroke 2px + 박스 그림자
- 신규 추가:
  - **하단 코랄 radial 글로우**: 카드 하단 80% 위치에 `radial-gradient(ellipse at 50% 50%, rgba(255,107,91,0.45) 0%, transparent 70%)` 절대 위치 div, width 카드폭×1.4, height 80, zIndex -1
  - **상단 "선택됨" 알약**: 카드 top -14에 `position:absolute; left:50%; transform:translateX(-50%);` Jua 10pt 흰색 "선택됨", coral fill, padding 3×12, border-radius 999

### 하단 스킬 패널 (폭 좁히기)
- v2의 `.skill-panel` `bottom: 16%` → **`bottom: 14%`** (카드 키운 만큼 살짝 아래로)
- 최대 폭 **320px** 명시 — 5장 카드 총 폭(160×5 + 22×4 = 888px)과 시각적 분리
- 내부: 기존 라벨 그대로

### Confirm 버튼 (v2와 동일)
- `.confirm-btn` "다음 ▶" coralPrimary alabel — bottom 7%

### 플로팅 음표 (v2 동일)
3개 ♪ ♫ ♬ 배치 그대로.

### 하단 annotation 박스 (필수)
mockup HTML 하단에 다음 3개 annotation 박스 추가:
1. **🎴 카드 4:5 NIKKE 구조** — "정사각이 아닌 세로 카드. 5종 정보(속성·얼굴·이름·등급·CD)를 위계 있게 배치."
2. **✨ 선택 = 떠오르기 + 글로우** — "하단 코랄 radial glow + 상단 '선택됨' 알약 추가. 5장 중 시선이 즉시 잡힘."
3. **📋 CD 미니칩** — "스킬 cooldown을 1회/2회/∞ 3단계로 단순화. 정확한 초는 SkillExplanationScene이 담당."

---

## 기능 상세

### 기능 1: `CharacterID` 신규 computed property 2종
- **설명**: 카드 좌상단(속성)·좌하단(등급) 배지에 표시할 시각용 데이터. 게임 로직 분기 0.
- **구현 위치**: `Models/CharacterID.swift` 파일 끝 (기존 `dotColor` 뒤에 이어 추가, MARK 섹션 분리)
- **시그니처**:
  ```swift
  // MARK: - Sprint 7 Phase A — NIKKE 카드 시각용 메타데이터

  /// 카드 좌하단 등급 배지에 표시할 정수(1·2·3 = I·II·III).
  /// switch default 미사용 — 5 case exhaustive. 순수 시각 lookup, 게임 로직 분기 0.
  var rarity: Int {
      switch self {
      case .jung: return 1
      case .kim:  return 2
      case .geon: return 3
      case .im:   return 2
      case .lee:  return 1
      }
  }

  /// 카드 좌상단 헥사 아이콘 안에 표시할 속성 이모지 단문자.
  /// 5종(⚡ 번개/💧 물/🌿 풀/🌙 달/🌸 꽃) — 캐릭터별 색 토큰(dotColor)과 시각 짝.
  var elementSymbol: String {
      switch self {
      case .kim:  return "🌸"
      case .jung: return "🌿"
      case .geon: return "🌙"
      case .im:   return "⚡"
      case .lee:  return "💧"
      }
  }
  ```
- **주의**: `displayName`/`tag`/`color`/`playerSpeedMultiplier`/`skill`/`dotColor` 모두 값 변경 0.

### 기능 2: `PlayerSkill.cooldownText` 신규 computed property
- **설명**: CD 미니칩 라벨 — NIKKE 식 1·2·∞ 3단계 위계.
- **구현 위치**: `Models/PlayerSkill.swift` 파일 끝 (기존 `castText` 뒤에 MARK 섹션 분리)
- **시그니처**:
  ```swift
  // MARK: - Sprint 7 Phase A — CD 미니칩

  /// 카드 우상단 CD 미니칩 라벨. 정확한 초 단위가 아닌 *위계 신호*.
  /// 스킬 없음(.none) → "∞", 그 외 → "1회".
  /// (정확한 초는 SkillExplanationScene 메타 칩이 담당.)
  var cooldownText: String {
      switch self {
      case .none:           return "∞"
      case .charmStudent:   return "1회"
      case .dashClimb:      return "1회"
      case .bookClubRally:  return "1회"
      case .taiwanTrip:     return "1회"
      }
  }
  ```
- **주의**: 기존 `cooldown` TimeInterval, `oncePerGame` Bool은 손대지 않는다. `cooldownText`는 두 값으로부터 *파생 표시*이지만 lookup 단순화 위해 switch. `PlayerSkill` enum의 정확한 case 이름은 Generator가 코드에서 확인 후 동일하게 매핑(상기 case 이름은 추정 — 실제 enum 이름이 다르면 그에 맞춰 5 case exhaustive switch).

### 기능 3: `GameConfig` v3 카드 상수 + 배지 상수 신규
- **설명**: NIKKE 카드 v3 폭 160 / 높이 200(4:5) / gap 22 / cornerRadius 22 + 4종 배지 폰트·offset 상수.
- **구현 위치**: `Config/GameConfig.swift` 파일 끝 (기존 `characterSelectSkillInfoChipAbove` 뒤에 MARK 섹션 분리)
- **추가 상수 (값 모두 신규, 기존 값 변경 0)**:
  ```swift
  // MARK: - Sprint 7 Phase A · CharacterCard v3 (NIKKE 4:5)

  /// v3 카드 폭(160pt). 기존 characterCardWidth(76) 대비 +84. 4:5 세로 비율 carrier.
  static let characterCardWidthV3: CGFloat = 160
  /// v3 카드 높이(200pt). 폭 160 × 1.25 = 200 → 4:5 비율.
  static let characterCardHeightV3: CGFloat = 200
  /// v3 카드 사이 gap(22pt). 기존 characterCardSpacing(10) 대비 +12. 겹침 0 보장.
  static let characterCardGapV3: CGFloat = 22
  /// v3 카드 cornerRadius(22pt). NIKKE 식 부드러운 둥금.
  static let characterCardCornerRadiusV3: CGFloat = 22

  // --- 속성 헥사 아이콘 (좌상단) ---
  /// 헥사 outer radius(원에 외접) — 14pt → 28pt 헥사 폭.
  static let characterCardElementHexRadius: CGFloat = 14
  /// 헥사 stroke(흰색 1.5pt) — 카드 배경(반투명 화이트)과 분리.
  static let characterCardElementHexStrokeWidth: CGFloat = 1.5
  /// 카드 좌상단 코너 inset (x, y) — 헥사 중심 좌표 계산에 사용.
  static let characterCardElementHexInsetX: CGFloat = 18
  static let characterCardElementHexInsetY: CGFloat = 18
  /// 헥사 안 이모지 폰트 크기(pt). 헥사 폭 28의 약 57% — 시각 균형.
  static let characterCardElementSymbolFontSize: CGFloat = 16

  // --- 등급 로마숫자 배지 (좌하단) ---
  /// 배지 크기(26×18pt) — Jua 11pt 한 자리 로마숫자 수용.
  static let characterCardRarityBadgeWidth: CGFloat = 26
  static let characterCardRarityBadgeHeight: CGFloat = 18
  /// 배지 cornerRadius(8pt) — 부드럽지만 사각.
  static let characterCardRarityBadgeCornerRadius: CGFloat = 8
  /// 배지 fill alpha — navyDeep × 0.85.
  static let characterCardRarityBadgeFillAlpha: CGFloat = 0.85
  /// 카드 좌하단 코너 inset (x, y) — 배지 중심 좌표.
  static let characterCardRarityBadgeInsetX: CGFloat = 22
  static let characterCardRarityBadgeInsetY: CGFloat = 22
  /// 배지 라벨 폰트 크기(pt).
  static let characterCardRarityBadgeFontSize: CGFloat = 11

  // --- CD 미니칩 (우상단) ---
  /// 칩 높이(16pt) — 자동 폭(라벨 너비 + padding).
  static let characterCardCDChipHeight: CGFloat = 16
  /// 칩 좌우 패딩(8pt).
  static let characterCardCDChipHorizontalPadding: CGFloat = 8
  /// 칩 fill — coralLight × 0.85.
  static let characterCardCDChipFillAlpha: CGFloat = 0.85
  /// 칩 라벨 폰트 크기(pt).
  static let characterCardCDChipFontSize: CGFloat = 9
  /// 카드 우상단 코너 inset (x, y).
  static let characterCardCDChipInsetX: CGFloat = 16
  static let characterCardCDChipInsetY: CGFloat = 18

  // --- 이름 + 속도 (하단) ---
  /// 이름 라벨 폰트 크기(pt). Jua, navyDeep.
  static let characterCardNameFontSizeV3: CGFloat = 15
  /// 이름 라벨 y offset (카드 하단 기준 + 28).
  static let characterCardNameOffsetYV3: CGFloat = 28
  /// 속도 칩 라벨 폰트 크기(pt). Gowun Dodum, scrubMint.
  static let characterCardSpeedFontSizeV3: CGFloat = 10
  /// 속도 칩 y offset (카드 하단 기준 + 12 — 이름 아래).
  static let characterCardSpeedOffsetYV3: CGFloat = 12

  // --- 선택 상태 강화 (Phase A) ---
  /// 카드 하단 코랄 radial glow 노드 폭(카드 폭 × 1.4 = 224pt).
  static let characterCardSelectedGlowWidth: CGFloat = 224
  /// 코랄 glow 높이(60pt).
  static let characterCardSelectedGlowHeight: CGFloat = 60
  /// 코랄 glow y offset (카드 하단 기준 -12 — 카드 아래로 살짝 새어 나옴).
  static let characterCardSelectedGlowOffsetY: CGFloat = -12
  /// 코랄 glow 알파(0.45).
  static let characterCardSelectedGlowAlpha: CGFloat = 0.45

  /// "선택됨" 알약 폭(60pt) / 높이(20pt). Jua 10pt 흰색 "선택됨" 수용.
  static let characterCardSelectedPillWidth: CGFloat = 60
  static let characterCardSelectedPillHeight: CGFloat = 20
  /// 알약 라벨 폰트 크기(pt).
  static let characterCardSelectedPillFontSize: CGFloat = 10
  /// 알약 텍스트.
  static let characterCardSelectedPillText: String = "선택됨"
  /// 알약 y offset (카드 상단 기준 +14 — 카드 위로 솟음).
  static let characterCardSelectedPillOffsetY: CGFloat = 14

  // --- 스킬 패널 폭 축소 (Phase A) ---
  /// 하단 스킬 정보 칩 최대 폭(320pt). v2 무한 → v3 320 clamp.
  /// 5장 카드 총 폭(160×5 + 22×4 = 888pt)과 시각적 분리.
  static let characterSelectSkillInfoMaxWidth: CGFloat = 320
  ```
- **주의**: 기존 `characterCardWidth`(76)·`characterCardHeight`(104)·`characterCardGlassWidth`(156)·`characterCardGlassHeight`(204)·`characterCardSelectedScale`(1.08)·`characterCardGlassSelectedScale`(1.08) 등은 **값 그대로 유지**(다른 호출처가 있을 가능성 — 회귀 방지).

### 기능 4: `CharacterCardNode` 카드 본체 NIKKE 식 재구성
- **설명**: 카드 폭/높이를 v3 상수로 교체, 카드 내부에 5요소(헥사·등급·CD·얼굴 자리·이름+속도)를 흡수. 기존 외부 부착(태그 라벨·색점)은 `CharacterSelectScene` 쪽에서 제거 또는 hidden.
- **구현 위치**: `Nodes/CharacterCardNode.swift` 전체 (init 본문 + 신규 메서드)
- **핵심 구조 (의사코드)**:
  ```swift
  // MARK: - Sprint 7 Phase A — NIKKE 4:5 카드

  final class CharacterCardNode: SKNode {

      // MARK: - Properties
      let id: CharacterID
      private let background: SKSpriteNode
      private let border: SKShapeNode
      private let nameLabel: SKLabelNode             // Jua 15pt — 카드 하단 내부로 흡수
      private let speedLabel: SKLabelNode            // Gowun Dodum 10pt 속도 ×N.NN

      // Phase A 신규
      private let elementHex: SKShapeNode            // 좌상단 헥사
      private let elementSymbol: SKLabelNode         // 헥사 안 이모지
      private let rarityBadge: SKShapeNode           // 좌하단 배지
      private let rarityLabel: SKLabelNode           // 배지 안 로마숫자
      private let cdChip: SKShapeNode                // 우상단 CD
      private let cdLabel: SKLabelNode               // CD 안 텍스트
      private let selectedGlow: SKShapeNode          // 하단 코랄 radial (선택 시만 보임)
      private let selectedPill: SKShapeNode          // 상단 "선택됨" 알약 (선택 시만 보임)
      private let selectedPillLabel: SKLabelNode

      // MARK: - Init
      init(id: CharacterID) {
          self.id = id
          let cardSize = CGSize(
              width: GameConfig.characterCardWidthV3,
              height: GameConfig.characterCardHeightV3
          )
          background = SKSpriteNode(color: .ganhoUIBgCard, size: cardSize)
          border = SKShapeNode(rectOf: cardSize, cornerRadius: GameConfig.characterCardCornerRadiusV3)
          // 노드 인스턴스 빈 초기화
          nameLabel = SKLabelNode()
          speedLabel = SKLabelNode()
          elementHex = SKShapeNode()
          elementSymbol = SKLabelNode()
          rarityBadge = SKShapeNode()
          rarityLabel = SKLabelNode()
          cdChip = SKShapeNode()
          cdLabel = SKLabelNode()
          selectedGlow = SKShapeNode()
          selectedPill = SKShapeNode()
          selectedPillLabel = SKLabelNode()
          super.init()
          name = "characterCard_\(id.rawValue)"
          zPosition = 100
          addChild(background)
          addChild(border)
          attachElementBadge()
          attachRarityBadge()
          attachCDChip()
          attachNameAndSpeed()
          attachSelectedDecor()
      }

      // MARK: - Phase A · 좌상단 속성 헥사 아이콘
      private func attachElementBadge() {
          // 6각형 path — outer radius 14, 꼭짓점이 위 (시작 각도 90도)
          let r = GameConfig.characterCardElementHexRadius
          let path = CGMutablePath()
          for i in 0..<6 {
              let angle = CGFloat(i) * .pi / 3 + .pi / 2
              let x = r * cos(angle)
              let y = r * sin(angle)
              if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
              else { path.addLine(to: CGPoint(x: x, y: y)) }
          }
          path.closeSubpath()
          elementHex.path = path
          elementHex.fillColor = id.dotColor
          elementHex.strokeColor = .white
          elementHex.lineWidth = GameConfig.characterCardElementHexStrokeWidth

          let halfW = GameConfig.characterCardWidthV3 / 2
          let halfH = GameConfig.characterCardHeightV3 / 2
          elementHex.position = CGPoint(
              x: -halfW + GameConfig.characterCardElementHexInsetX,
              y:  halfH - GameConfig.characterCardElementHexInsetY
          )
          elementHex.zPosition = 5
          addChild(elementHex)

          elementSymbol.text = id.elementSymbol
          elementSymbol.fontName = GameConfig.fontDisplay
          elementSymbol.fontSize = GameConfig.characterCardElementSymbolFontSize
          elementSymbol.horizontalAlignmentMode = .center
          elementSymbol.verticalAlignmentMode = .center
          elementSymbol.position = elementHex.position
          elementSymbol.zPosition = 6
          addChild(elementSymbol)
      }

      // MARK: - Phase A · 좌하단 등급 로마숫자 배지
      private func attachRarityBadge() {
          let size = CGSize(
              width: GameConfig.characterCardRarityBadgeWidth,
              height: GameConfig.characterCardRarityBadgeHeight
          )
          rarityBadge.path = CGPath(
              roundedRect: CGRect(x: -size.width/2, y: -size.height/2,
                                  width: size.width, height: size.height),
              cornerWidth: GameConfig.characterCardRarityBadgeCornerRadius,
              cornerHeight: GameConfig.characterCardRarityBadgeCornerRadius,
              transform: nil
          )
          rarityBadge.fillColor = UIColor.ganhoNavyDeep
              .withAlphaComponent(GameConfig.characterCardRarityBadgeFillAlpha)
          rarityBadge.strokeColor = .clear
          let halfW = GameConfig.characterCardWidthV3 / 2
          let halfH = GameConfig.characterCardHeightV3 / 2
          rarityBadge.position = CGPoint(
              x: -halfW + GameConfig.characterCardRarityBadgeInsetX,
              y: -halfH + GameConfig.characterCardRarityBadgeInsetY
          )
          rarityBadge.zPosition = 5
          addChild(rarityBadge)

          let roman: String
          switch id.rarity {
          case 1: roman = "I"
          case 2: roman = "II"
          case 3: roman = "III"
          default: roman = "I"  // 안전 fallback (현재 값은 1·2·3만)
          }
          rarityLabel.text = roman
          rarityLabel.fontName = GameConfig.fontDisplay
          rarityLabel.fontSize = GameConfig.characterCardRarityBadgeFontSize
          rarityLabel.fontColor = .ganhoMusicGold
          rarityLabel.horizontalAlignmentMode = .center
          rarityLabel.verticalAlignmentMode = .center
          rarityLabel.position = rarityBadge.position
          rarityLabel.zPosition = 6
          addChild(rarityLabel)
      }

      // MARK: - Phase A · 우상단 CD 미니칩
      private func attachCDChip() {
          cdLabel.text = id.skill.cooldownText
          cdLabel.fontName = GameConfig.fontDisplay
          cdLabel.fontSize = GameConfig.characterCardCDChipFontSize
          cdLabel.fontColor = .white
          cdLabel.horizontalAlignmentMode = .center
          cdLabel.verticalAlignmentMode = .center
          let labelW = cdLabel.frame.width
          let chipSize = CGSize(
              width: labelW + GameConfig.characterCardCDChipHorizontalPadding * 2,
              height: GameConfig.characterCardCDChipHeight
          )
          cdChip.path = CGPath(
              roundedRect: CGRect(x: -chipSize.width/2, y: -chipSize.height/2,
                                  width: chipSize.width, height: chipSize.height),
              cornerWidth: chipSize.height / 2,
              cornerHeight: chipSize.height / 2,
              transform: nil
          )
          cdChip.fillColor = UIColor.ganhoCoralLight
              .withAlphaComponent(GameConfig.characterCardCDChipFillAlpha)
          cdChip.strokeColor = .clear
          let halfW = GameConfig.characterCardWidthV3 / 2
          let halfH = GameConfig.characterCardHeightV3 / 2
          cdChip.position = CGPoint(
              x:  halfW - GameConfig.characterCardCDChipInsetX - chipSize.width/2,
              y:  halfH - GameConfig.characterCardCDChipInsetY
          )
          cdChip.zPosition = 5
          addChild(cdChip)
          cdLabel.position = cdChip.position
          cdLabel.zPosition = 6
          addChild(cdLabel)
      }

      // MARK: - Phase A · 카드 하단 이름 + 속도
      private func attachNameAndSpeed() {
          nameLabel.text = id.displayName
          nameLabel.fontName = GameConfig.fontDisplay
          nameLabel.fontSize = GameConfig.characterCardNameFontSizeV3
          nameLabel.fontColor = .ganhoNavyDeep
          nameLabel.horizontalAlignmentMode = .center
          nameLabel.verticalAlignmentMode = .center
          let halfH = GameConfig.characterCardHeightV3 / 2
          nameLabel.position = CGPoint(
              x: 0, y: -halfH + GameConfig.characterCardNameOffsetYV3
          )
          nameLabel.zPosition = 5
          addChild(nameLabel)

          speedLabel.text = "⚡ ×\(formattedSpeed(id.playerSpeedMultiplier))"
          speedLabel.fontName = GameConfig.fontBody
          speedLabel.fontSize = GameConfig.characterCardSpeedFontSizeV3
          speedLabel.fontColor = .ganhoScrubMint
          speedLabel.horizontalAlignmentMode = .center
          speedLabel.verticalAlignmentMode = .center
          speedLabel.position = CGPoint(
              x: 0, y: -halfH + GameConfig.characterCardSpeedOffsetYV3
          )
          speedLabel.zPosition = 5
          addChild(speedLabel)
      }

      private func formattedSpeed(_ value: CGFloat) -> String {
          let rounded1 = (value * 10).rounded() / 10
          if abs(value - rounded1) < 0.001 {
              return String(format: "%.1f", Double(value))
          }
          return String(format: "%.2f", Double(value))
      }

      // MARK: - Phase A · 선택 데코(글로우 + 알약, 기본 isHidden)
      private func attachSelectedDecor() {
          let glowSize = CGSize(
              width: GameConfig.characterCardSelectedGlowWidth,
              height: GameConfig.characterCardSelectedGlowHeight
          )
          selectedGlow.path = CGPath(ellipseIn: CGRect(
              x: -glowSize.width/2, y: -glowSize.height/2,
              width: glowSize.width, height: glowSize.height
          ), transform: nil)
          selectedGlow.fillColor = UIColor.ganhoCoralPrimary
              .withAlphaComponent(GameConfig.characterCardSelectedGlowAlpha)
          selectedGlow.strokeColor = .clear
          let halfH = GameConfig.characterCardHeightV3 / 2
          selectedGlow.position = CGPoint(
              x: 0, y: -halfH + GameConfig.characterCardSelectedGlowOffsetY
          )
          selectedGlow.zPosition = -1
          selectedGlow.isHidden = true
          addChild(selectedGlow)

          let pillSize = CGSize(
              width: GameConfig.characterCardSelectedPillWidth,
              height: GameConfig.characterCardSelectedPillHeight
          )
          selectedPill.path = CGPath(
              roundedRect: CGRect(x: -pillSize.width/2, y: -pillSize.height/2,
                                  width: pillSize.width, height: pillSize.height),
              cornerWidth: pillSize.height / 2,
              cornerHeight: pillSize.height / 2,
              transform: nil
          )
          selectedPill.fillColor = .ganhoCoralPrimary
          selectedPill.strokeColor = .clear
          selectedPill.position = CGPoint(
              x: 0, y: halfH + GameConfig.characterCardSelectedPillOffsetY
          )
          selectedPill.zPosition = 10
          selectedPill.isHidden = true
          addChild(selectedPill)

          selectedPillLabel.text = GameConfig.characterCardSelectedPillText
          selectedPillLabel.fontName = GameConfig.fontDisplay
          selectedPillLabel.fontSize = GameConfig.characterCardSelectedPillFontSize
          selectedPillLabel.fontColor = .white
          selectedPillLabel.horizontalAlignmentMode = .center
          selectedPillLabel.verticalAlignmentMode = .center
          selectedPillLabel.position = selectedPill.position
          selectedPillLabel.zPosition = 11
          selectedPillLabel.isHidden = true
          addChild(selectedPillLabel)
      }

      // MARK: - Selection
      func setSelected(_ selected: Bool) {
          alpha = selected ? 1.0 : GameConfig.characterCardDeselectedAlpha
          let targetScale: CGFloat = selected ? GameConfig.characterCardSelectedScale : 1.0
          removeAction(forKey: "cardScale")
          run(
              SKAction.scale(to: targetScale, duration: GameConfig.characterCardScaleDuration),
              withKey: "cardScale"
          )
          background.color = selected ? .ganhoUIBrand12 : .ganhoUIBgCard
          border.strokeColor = selected ? .ganhoCoralPrimary : .ganhoUIBorder
          nameLabel.fontColor = selected ? .ganhoNavyDeep : .ganhoNavyMuted
          selectedGlow.isHidden = !selected
          selectedPill.isHidden = !selected
          selectedPillLabel.isHidden = !selected
      }
  }
  ```
- **주의**:
  - 강제 언래핑 0건. SKShapeNode/SKLabelNode init은 옵셔널 아님.
  - `selectedGlow.zPosition = -1`은 카드 background보다 뒤. 외부 글래스 컨테이너(`CharacterSelectScene` cardContainers)가 zPos 90 또는 alpha 0(isHidden 옵션 채택 시)이면 글로우는 시각상 카드 아래로 새어 나옴.
  - 기존 CharacterCardNode가 어떤 프로퍼티/메서드를 외부에 노출하는지 Generator가 확인 후, 외부 호출자(예: `CharacterSelectScene.setupCardContainers`)가 깨지지 않도록 *기존 public/internal 시그니처 보존*. 특히 `setSelected(_:)`는 시그니처 byte-identical.

### 기능 5: `CharacterSelectScene` 글래스/외부 정보 조정 + 좌표 갱신
- **설명**: v3 카드(160×200)에 맞춰 글래스 컨테이너 폭/높이/cornerRadius 갱신, 외부 부착 정보(태그 라벨·색점)는 카드 내부 흡수로 인해 비활성(isHidden), 좌표 계산은 v3 폭 사용, 하단 스킬 패널 최대 폭 clamp.
- **구현 위치**: `Scenes/CharacterSelectScene.swift`
- **변경 포인트**:

  **5-1. 글래스 컨테이너 크기 갱신** (`setupCardContainers`)
  - 컨테이너 폭/높이를 `characterCardWidthV3`(160) / `characterCardHeightV3`(200)로 교체, cornerRadius `characterCardCornerRadiusV3`(22) 사용.
  - 컨테이너 alpha를 0.0으로 설정(시각상 안 보임 — NIKKE 카드 자체가 충분히 강조)  ← **OQ-1 결정**.
  - 회귀 안전성: 컨테이너 노드 자체는 남아있고 위치 계산 함수도 호출되지만 시각 0.

  **5-2. 좌표 계산 v3 폭 사용** (`cardBaseX(for:)`)
  - 함수 본문 안 `let width = GameConfig.characterCardWidth`(76)을 `characterCardWidthV3`(160)로 교체.
  - spacing clamp(28~56)는 그대로. `characterCardGapV3`(22)는 *디자인 의도값* — SE 좁은 화면에서는 28pt 최소값이 우선 작용. OK.
  - `cardBaseY(for:)`의 zigzag offset(±6)은 유지.

  **5-3. 외부 부착 정보 isHidden** (`setupTagLabels`, `setupCardColorDots`)
  - 태그 라벨 5개: 카드 내부 nameLabel + speedLabel로 흡수 → `label.isHidden = true` 한 줄.
  - 색점 5개: 카드 내부 elementHex로 흡수 → `dot.isHidden = true` 한 줄.
  - 얼굴 5개(`characterFaces`): 카드 중앙에 표시 → **유지**. zPos 105 유지.

  **5-4. 하단 스킬 패널 폭 좁히기** (`layoutSkillInfoChip`)
  - `DarkContextChipNode`는 라벨 너비 기반 자동 폭이므로, frame.width 측정 → `setScale(maxW / currentW)` clamp 패턴:
    ```swift
    private func layoutSkillInfoChip() {
        guard let chip = skillInfoChip else { return }
        chip.position = CGPoint(
            x: frame.midX,
            y: confirmButton.position.y + GameConfig.characterSelectSkillInfoChipAbove
        )
        let maxW = GameConfig.characterSelectSkillInfoMaxWidth
        let currentW = chip.calculateAccumulatedFrame().width
        if currentW > maxW {
            chip.setScale(maxW / currentW)
        } else {
            chip.setScale(1.0)
        }
    }
    ```
    실제 함수 이름은 Generator가 코드에서 확인. (`layoutSkillInfoChip` 또는 `rebuildSkillInfoPanel` 또는 다른 이름)

- **주의**:
  - `preferenceRepo.save(_:)` 호출 라인 byte-identical.
  - `transitionToNext` / `transitionToStart` 콜백 시그니처와 transition 시간(0.3s 등) byte-identical.
  - 5장 카드 선택 → 해제 → 다른 선택 시 액션 시간 0.18s(`characterCardScaleDuration`) 유지.
  - 만약 기존 CharacterCardNode가 외부에서 `nameLabel`을 읽거나 수정하는 호출자가 있다면 Generator는 호환 인터페이스를 보존(예: nameLabel은 내부 hidden + getter 그대로).

---

## 합격 기준 (SPRINT_7_REQUEST.md §2.5 + Phase A 한정)

### 절대 통과선
1. **시뮬레이터에서 5장 카드 시각적으로 0px 겹침** — 카드 폭 160 + gap 22 × 4 + spacing clamp 작동.
2. **헥사 아이콘 5종이 캐릭터 색과 일치** — `id.dotColor` 5종이 각 카드 헥사 fill로 표시.
3. **선택 → 해제 → 다른 선택 시 시각 전환 매끄러움** — 액션 시간 0.18s 유지. glow/알약 isHidden 토글은 즉시.
4. **`preferenceRepo` 저장값이 v2와 byte-identical** — `select(_:)` → `preferenceRepo.save(id)` 호출 라인 1 변경 0.

### Phase A 채점 룰 (4-카테고리, SPRINT_7_REQUEST.md §11)
| 카테고리 | 가중치 | Phase A 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 — preferenceRepo / transition / 게임 상수 0 변경 |
| Swift 패턴 | 20% | 7.0 이상 — guard let, MARK, GameConfig 상수, 강제 언래핑 0 |
| 비주얼 일관성 (mockup) | 25% | 7.0 이상 — `character-select-v3.html` 매칭률 ≥ 85% |
| 가독성 & UX | 15% | 7.0 이상 — 5요소 0px 겹침 + 헥사·등급·CD 식별 가능 |

### AI 슬롭 자동 감점 항목
- 강제 언래핑 `!` → Swift 패턴 -1
- 매직 넘버 하드코딩 → Swift 패턴 -1 per 3건 이상
- `update()` 안 `addChild()` → 성능 -1
- `Timer.scheduledTimer` → Swift 패턴 -1
- 클로저 `self` 강한 캡처 → 성능 -1

---

## 변경 LOC 추정치

| 파일 | 신규 LOC | 수정 LOC | 합계 |
|---|---|---|---|
| `Models/CharacterID.swift` | ~22 (rarity + elementSymbol switch) | 0 | ~22 |
| `Models/PlayerSkill.swift` | ~12 (cooldownText switch) | 0 | ~12 |
| `Config/GameConfig.swift` | ~70 (v3 상수 4종 + 배지/칩 12종 + 선택 데코 7종 + 패널 폭 1) | 0 | ~70 |
| `Nodes/CharacterCardNode.swift` | ~180 (attach* 메서드 + 인스턴스 + setSelected 갱신) | ~10 (init 본문 폭 교체) | ~190 |
| `Scenes/CharacterSelectScene.swift` | ~10 (스킬 패널 폭 clamp) | ~15 (글래스 컨테이너 크기, 외부 부착 isHidden, cardBaseX 폭) | ~25 |
| `mockups/character-select-v3.html` | ~350 (HTML + CSS + annotation) | 0 | ~350 |
| **합계** | **~644** | **~25** | **~669** |

Swift 코드만 ~319 LOC → SPRINT_7_REQUEST.md §1 Phase A 예상치(~300) 부합.

---

## 주의사항

### Swift / SpriteKit 패턴
- **강제 언래핑 0건**: SKShapeNode/SKLabelNode init은 옵셔널이 아님. `guard let`/`if let` 패턴은 `skillInfoChip` 같은 옵셔널 프로퍼티에만 적용.
- **GameConfig 상수만 사용**: 카드 안 모든 위치/크기는 `GameConfig.characterCardXxxV3` 참조. 헥사 path의 `.pi / 3`은 수학 상수(매직 넘버 아님).
- **switch default 미사용**: `CharacterID.rarity`/`elementSymbol`, `PlayerSkill.cooldownText` 모두 enum 5 case exhaustive. `rarityBadge` 안 Int → 로마숫자 변환은 `default: return "I"` 허용(Int 전체 case 망라 불가).
- **MARK 섹션 구분**: 새 코드는 모두 `// MARK: - Sprint 7 Phase A · …` 시작.
- **클로저 `self` 캡처**: Phase A는 SKAction.run 클로저 사용 0건. 추가 시 `[weak self]` 필수.

### SpriteKit 좌표 / zPosition
- 카드 좌표계 (0,0)이 카드 중심. 좌상단 배지 = `(-halfW + insetX, halfH - insetY)`. y-up.
- 카드 자식 zPos: background(0) < 헥사/배지/칩/이름/속도(5) < 알약 라벨(11). 글로우(-1) — 카드 background 뒤이지만 외부 컨테이너(alpha 0)보다 앞이므로 시각상 새어 나옴.
- `CharacterFaceNode`는 *씬 자식*으로 별도 부착 zPos 105 — 카드 자식이 아님. 회귀 방지 위해 그대로 유지.

### 빌드 / 회귀 위험
- 기존 `characterCardWidth`(76) 참조처: `CharacterCardNode` + `CharacterSelectScene.cardBaseX` 두 곳을 모두 v3로 갱신.
- `characterCardGlassWidth/Height`(156/204) 참조처: `setupCardContainers` + `layoutCardColorDots`(우상단 색점 inset 계산). 색점이 isHidden이라도 계산은 작동 — 글래스 폭/높이도 v3로 갱신해 일관성 확보.

### OPEN_QUESTION

**OQ-1 (결정됨)**: 카드 외곽 글래스 컨테이너(`cardContainers`, zPos 90)와 외부 색점·태그 라벨은 시각상 불필요 →
- **(A) 채택**: `cardContainers` 폭/높이/cornerRadius를 v3로 갱신하되 `alpha = 0.0`(시각 0). 색점·태그 라벨은 `isHidden = true`. 코드/구조 변경 최소.
- 글래스 컨테이너 alpha 0이 어색하면 후속에서 `alpha = 0.3` 정도로 *카드 외곽 fade* 가능 — Phase A는 0.0으로 시작.

**OQ-2 (결정됨)**: 헥사 아이콘 — *이모지* 채택. Jua/Gowun 폰트로 렌더링 가능, 5종 시각 차별성 즉시 확보.

**OQ-3 (결정됨)**: 등급 매핑 `CharacterID.rarity`:
- 김간호 II (주인공, 정공법 → 중간)
- 정간호 I (이동속도 +10% 기본 등급)
- 건간호 III (북클럽 6타일 광역, 가장 *희귀*)
- 임간호 II (전역 매혹 게임당 1회 — 위력 III급이지만 제약으로 II)
- 이간호 I (대시 클라임 기본 등급)
→ 사용자 후속 조정은 별도 Sprint에서.

**OQ-4 (결정됨)**: spacing clamp 28~56 vs `characterCardGapV3`(22). 22pt는 *디자인 의도값* — clamp가 우선 작동. 0px 겹침 통과선이 22pt 사양보다 우선.

---

## 관련 파일 (절대 경로)

- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Scenes/CharacterSelectScene.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Nodes/CharacterCardNode.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Nodes/CharacterFaceNode.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Models/CharacterID.swift`
- `GanhoMusic/GanhoMusic/GanhoMusic Shared/Models/PlayerSkill.swift`
- `mockups/character-select-v2.html` (참고용)
- 신규: `mockups/character-select-v3.html`
