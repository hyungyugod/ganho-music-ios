# Sprint 1 — 디자인 리뉴얼 인프라 (시각 변화 0)

## 개요
DESIGN_RENEWAL_REQUEST.md §9 Sprint 1을 구현한다. 새 디자인 시스템(따뜻한 피치-라벤더 그라데이션 + 코랄 액센트 + 카툰 톤)이 Sprint 2~3에서 끌어다 쓸 **인프라**만 추가한다. 토큰/폰트/재사용 노드 3종 + 버튼 2종 리스타일링 + 그라데이션 3-stop 옵션 추가까지. **기존 5개 씬(StartScene, CharacterSelectScene, SkillExplanationScene, GameScene, ResultScene)의 시각 출력은 한 픽셀도 바뀌지 않는다.**

## 변경 유형
**비주얼 인프라** (시각 변화 0)
— Evaluator는 v2 디자인 시스템 매칭이 아니라 **인프라 완전성 + 기존 화면 0 회귀**를 본다.

## 게임 경험 의도
이 Sprint 결과를 사용자가 직접 보지는 않는다 — 다음 Sprint 2가 메뉴 씬을 리스킨할 때 끌어다 쓸 *부품 창고*를 짓는 단계다. 부품이 잘 깎여 있으면 Sprint 2 작업이 "위치 잡고 색만 바꾸면 끝" 수준으로 떨어진다. Spring 비유로는 도메인 모델/Repository를 먼저 정착시킨 뒤 Controller를 갈아끼우는 절차와 동일하다.

## Sprint 1 범위 계약

### IN (이번 Sprint에 한다)
1. `ColorTokens.swift`에 v2 디자인 토큰 **16개 추가** (DESIGN_RENEWAL_REQUEST.md §3.1 원문 그대로, 기존 토큰 hex 0 변경)
2. `GameConfig.swift`에 폰트 이름 상수 **3개 추가** (`fontDisplay` / `fontBody` / `fontNumeric`) + 컴포넌트 수치 상수 다수 추가
3. 신규 노드 3개 생성:
   - `Nodes/GlassPillNode.swift`
   - `Nodes/AccentLineNode.swift`
   - `Nodes/DarkContextChipNode.swift`
4. `Nodes/PrimaryButtonNode.swift` 내부 시각 리스타일링 (init 시그니처 보존)
5. `Nodes/BackButtonNode.swift` 내부 시각 리스타일링 (init 시그니처 보존)
6. `Nodes/GradientBackgroundNode.swift`에 3-stop 그라데이션 옵션 **추가** (기존 2-stop init 보존)

### OUT (이번 Sprint에는 절대 안 한다)
- 기존 화면(`StartScene`, `CharacterSelectScene`, `SkillExplanationScene`, `GameScene`, `GameScene+Setup`, `ResultScene`) **호출부 어떤 변경도 금지**
- Phase 10-2 StartScene 리스킨 결과물(그라데이션 색 토큰, MusicNoteEmitter, 카드 spring) 어떤 변경도 금지
- 폰트 ttf 파일 실제 추가 (UIAppFonts plist 편집 + Xcode add-to-target은 **사용자 후속 작업**)
- 기존 ColorTokens hex 값 변경 (`ganhoBgDeep`, `ganhoAccentTeal`, `ganhoUIBrand` 등 전부 그대로)
- 게임 수치 / 게임 로직 / 저장소 / 씬 전환
- 새 노드 3종을 어디서 호출하는 코드 추가 (Sprint 2~3에서 호출자가 들어옴)

### 판단 기준 (애매할 때)
- "이 변경이 없으면 SPEC 기능(16 토큰 + 폰트 3개 + 컴포넌트 상수 + 신규 노드 3개 + 버튼 2개 리스타일링 + 3-stop 옵션)이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.
- 특히 **버튼 2개 리스타일링은 호출부 회귀가 발생할 수 있다**. 호출부가 보던 init 시그니처/탭 컨벤션이 그대로 유지되는지가 핵심 가드.

---

## 불변 계약 표 (Evaluator 체크리스트용)

| 항목 | 상태 | 검증 방법 |
|---|---|---|
| `PrimaryButtonNode.init(text:)` 시그니처 | 보존 | grep로 `init(text:` 단일 시그니처 확인 |
| `BackButtonNode.init(text:)` 시그니처 | 보존 | grep로 `init(text:` 단일 시그니처 확인 |
| `PrimaryButtonNode.name == "primaryButton"` | 보존 | hit-test의 `contains(_:)` 호출부 패턴 유지 |
| `BackButtonNode.name == "backButton"` | 보존 | hit-test 패턴 유지 |
| `GradientBackgroundNode.init(size:topColor:bottomColor:)` | 보존 | StartScene 호출부 컴파일 그대로 |
| `GradientBackgroundNode.name == "gradientBackground"` | 보존 | 자식 추적 패턴 유지 |
| 기존 `ColorTokens` hex 값 | 0 변경 | git diff에서 기존 라인 변경 0 |
| `GameConfig` 게임 로직 상수 | 0 변경 | scorePerNote, comboWindow 등 단 1줄도 안 만짐 |
| `Info.plist` | 0 변경 | UIAppFonts 편집은 사용자 후속 작업 — SPEC OPEN_QUESTION 처리 |
| 기존 5개 씬 파일 | 0 변경 | grep로 Scenes/ 디렉토리 git diff 비어 있어야 함 |
| 새 노드 3종은 **호출자 0** | 충족 | grep로 `GlassPillNode(` / `AccentLineNode(` / `DarkContextChipNode(` 호출부 0건 |

---

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Config/ColorTokens.swift` — extension 끝에 v2 토큰 16개 **추가만** (기존 라인 변경 금지)
- `GanhoMusic Shared/Config/GameConfig.swift` — enum 끝쪽에 폰트 상수 3개 + 컴포넌트 상수 + 폰트 헬퍼 1개 **추가만**
- `GanhoMusic Shared/Nodes/PrimaryButtonNode.swift` — init 시그니처/타입 이름/`name`/탭 컨벤션 보존, 내부 시각만 v2 코랄 스타일로 교체
- `GanhoMusic Shared/Nodes/BackButtonNode.swift` — init 시그니처/타입 이름/`name`/탭 컨벤션 보존, 내부 시각만 GlassPill 패턴으로 교체
- `GanhoMusic Shared/Nodes/GradientBackgroundNode.swift` — 기존 init 보존, 새 3-stop static factory **추가**

### 추가할 파일
- `GanhoMusic Shared/Nodes/GlassPillNode.swift` — 반투명 화이트 알약 + 가우시안 블러 + 라벨
- `GanhoMusic Shared/Nodes/AccentLineNode.swift` — 32×3 코랄 라운드 라인 (헤더 위 액센트)
- `GanhoMusic Shared/Nodes/DarkContextChipNode.swift` — 다크 navy 칩 + 골드 라벨 + 옵션 코랄 뱃지

---

## 기능 상세

### 기능 1: ColorTokens v2 토큰 16개 추가
- 설명: DESIGN_RENEWAL_REQUEST.md §3.1 그대로 hex/이름 1:1 복사
- 구현 위치: `Config/ColorTokens.swift` — 기존 `extension UIColor` **마지막 MARK 섹션 다음**에 새 MARK 섹션 `// MARK: - v2 Design System (Warm Pastel · Sprint 1)` 추가
- 추가할 토큰 16개 (이름 / hex / 의도):

```swift
// MARK: - v2 Design System (Warm Pastel · Sprint 1)
// DESIGN_RENEWAL_REQUEST.md §3.1 — 따뜻한 피치-라벤더 그라데이션 + 코랄 액센트 + 카툰 톤.
// Sprint 1은 *추가만* — 기존 토큰(ganhoBgDeep, ganhoAccentTeal, ganhoUIBrand 등) hex 0 변경.

// 배경 그라데이션 (3-stop)
static let ganhoBgWarmTop    = UIColor(hex: "#FFE5D0")  // 피치 (상단)
static let ganhoBgWarmMid    = UIColor(hex: "#FFC8B5")  // 코랄 (중간)
static let ganhoBgWarmBottom = UIColor(hex: "#DCC9E8")  // 라벤더 (하단)
static let ganhoBgAccent1    = UIColor(hex: "#FFD9B8")  // BG 액센트 (radial)
static let ganhoBgAccent2    = UIColor(hex: "#E5C8E8")  // BG 액센트 (radial)

// Primary 액션 (코랄 패밀리)
static let ganhoCoralPrimary = UIColor(hex: "#FF6B5B")  // 메인 CTA 색
static let ganhoCoralLight   = UIColor(hex: "#FF8E80")  // 호버/포커스
static let ganhoCoralShadow  = UIColor(hex: "#C44A3D")  // 입체 그림자 베이스

// 텍스트 & 위계
static let ganhoNavyDeep     = UIColor(hex: "#2D2A4A")  // 메인 텍스트
static let ganhoNavyMuted    = UIColor(hex: "#5A5670")  // 보조 텍스트
static let ganhoMusicGold    = UIColor(hex: "#FFB347")  // 음표·HUD 라벨

// 그래픽 디테일
static let ganhoLavenderSoft = UIColor(hex: "#B89DD9")  // 라벤더 액센트
static let ganhoScrubMint    = UIColor(hex: "#9BE0CC")  // 정간호 / 일부 카드
static let ganhoSkinTone     = UIColor(hex: "#FFE2C6")  // 캐릭터 피부 톤

// 체크보드 (Game floor) — Sprint 3에서 GameScene이 끌어다 씀
static let ganhoFloorPeachA  = UIColor(hex: "#FFEFE0")  // 체크보드 밝은 칸
static let ganhoFloorPeachB  = UIColor(hex: "#FFDFC8")  // 체크보드 어두운 칸
```

- 토큰 카운트: 5(배경) + 3(코랄) + 3(텍스트) + 3(디테일) + 2(체크보드) = **16개**.

---

### 기능 2: GameConfig 폰트 상수 3개 + 컴포넌트 수치 상수 추가
- 설명: SKLabelNode에서 v2 폰트(Jua, Gowun Dodum, Noto Sans KR)를 호출할 때 쓸 *이름 상수*만 추가. ttf 파일 실제 추가는 사용자 후속 작업 — 그래서 SKLabelNode fontNamed에 직접 넘기면 ttf 미존재 시 시스템 폰트로 fallback되어 *컴파일/런타임 모두 깨지지 않는다*.
- 구현 위치: `Config/GameConfig.swift` — 파일 끝의 `}` 직전(맨 마지막 MARK 섹션 다음)에 새 MARK 섹션들 추가.
- 핵심 코드:

```swift
// MARK: - Typography (Sprint 1 · v2 Design System)
// DESIGN_RENEWAL_REQUEST.md §3.2 폰트 시스템.
// ttf 파일 실제 임포트는 사용자 후속 작업(Xcode add to target + Info.plist UIAppFonts).
// 본 상수는 *이름만* 정의 — SKLabelNode(fontNamed:)는 ttf 미존재 시 시스템 폰트로 자동 fallback,
// 컴파일 및 런타임 모두 깨지지 않음.

/// Display 폰트 — 타이틀·UI 강조 (Jua-Regular). 모든 타이틀, 버튼 텍스트, HUD 값.
static let fontDisplay: String = "Jua-Regular"
/// Body 폰트 — 본문·설명 (GowunDodum-Regular). 태그라인, 스킬 설명, 카드 부제.
static let fontBody: String = "GowunDodum-Regular"
/// Numeric 폰트 — 수치 표시 (NotoSansKR-Bold). 점수·시간 등 정렬 필요한 숫자.
static let fontNumeric: String = "NotoSansKR-Bold"

// MARK: - v2 Components (Sprint 1)

/// GlassPillNode 배경 화이트 α. DESIGN_RENEWAL_REQUEST.md §3.3.B = 0.55.
static let glassPillFillAlpha: CGFloat = 0.55
/// GlassPillNode stroke α — 살짝의 외곽선.
static let glassPillStrokeAlpha: CGFloat = 0.25
/// GlassPillNode 가우시안 블러 반경. §3.3.B = radius 12.
static let glassPillBlurRadius: CGFloat = 12
/// GlassPillNode 라벨 폰트 크기.
static let glassPillFontSize: CGFloat = 14

/// AccentLineNode 가로 길이(pt). §3.3.C = 32.
static let accentLineWidth: CGFloat = 32
/// AccentLineNode 두께(pt). §3.3.C = 3.
static let accentLineHeight: CGFloat = 3

/// DarkContextChipNode 배경 navy α. §3.3.D = 0.92.
static let darkContextChipBgAlpha: CGFloat = 0.92
/// DarkContextChipNode 라벨 폰트 크기.
static let darkContextChipLabelFontSize: CGFloat = 13
/// DarkContextChipNode 뱃지 폰트 크기. 더 작음.
static let darkContextChipBadgeFontSize: CGFloat = 11
/// DarkContextChipNode 가로 패딩(pt) — 라벨 양옆 여백.
static let darkContextChipHorizontalPadding: CGFloat = 14
/// DarkContextChipNode 세로 높이(pt).
static let darkContextChipHeight: CGFloat = 28
/// DarkContextChipNode 라벨-뱃지 간 가로 간격(pt).
static let darkContextChipBadgeSpacing: CGFloat = 8

/// PrimaryButtonNode v2 그림자 y 오프셋(pt) — 음수면 아래쪽. §3.3.A = 6 → -6.
static let primaryButtonShadowOffsetY: CGFloat = -6
/// PrimaryButtonNode v2 그림자 blur(pt).
static let primaryButtonShadowBlurRadius: CGFloat = 12
/// PrimaryButtonNode v2 우측 화살표 원 반경(pt).
static let primaryButtonArrowRadius: CGFloat = 12
/// PrimaryButtonNode v2 우측 화살표 우측 마진(pt) — 배경 우측 끝에서 안쪽 거리.
static let primaryButtonArrowInsetX: CGFloat = 22
```

- 폰트 fallback 패턴 가이드 (이번 Sprint에는 호출자 없음 — Sprint 2~3에서 적용):
  - `SKLabelNode(fontNamed: GameConfig.fontDisplay)` 형태로 직접 호출하면 SpriteKit이 자동으로 시스템 폰트로 fallback. 추가 가드 불필요.
  - `UIFont`가 필요한 경우(없을 예정이지만 만약): `UIFont(name: GameConfig.fontDisplay, size: 16) ?? UIFont.systemFont(ofSize: 16)` 패턴.

---

### 기능 3: GlassPillNode (신규)
- 설명: 반투명 화이트(α=0.55) 알약 + 가우시안 블러 + 라벨. CharacterSelectScene "← 난이도 다시" 버튼, 통계 칩, D-Pad 키, 난이도 칩에서 재사용 예정.
- 구현 위치: `GanhoMusic Shared/Nodes/GlassPillNode.swift` (신규 파일)
- 시그니처: `init(text: String, size: CGSize)`
- 핵심 코드 구조:

```swift
//
//  GlassPillNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  반투명 화이트 알약 + 가우시안 블러 + 라벨. CharacterSelectScene 뒤로 버튼,
//  통계 칩, D-Pad 키, 난이도 칩에서 재사용.
//  SKEffectNode + CIGaussianBlur는 iOS 13+ — 시뮬레이터에서도 정상 작동.
//

import SpriteKit
import CoreImage

/// 반투명 화이트 알약(α=0.55) + 가우시안 블러 + Jua 라벨.
/// 부모(SKNode) = 좌표·name, 자식 = 시각. hit-test는 호출부의 `contains(location)` 패턴.
final class GlassPillNode: SKNode {

    // MARK: - Properties
    private let blurEffect: SKEffectNode
    private let background: SKShapeNode
    private let textLabel: SKLabelNode

    // MARK: - Init
    /// - Parameters:
    ///   - text: 라벨 텍스트.
    ///   - size: 알약 크기. cornerRadius = size.height/2 자동.
    init(text: String, size: CGSize) {
        background = SKShapeNode(
            rectOf: size,
            cornerRadius: size.height / 2
        )
        background.fillColor = UIColor.white.withAlphaComponent(GameConfig.glassPillFillAlpha)
        background.strokeColor = UIColor.white.withAlphaComponent(GameConfig.glassPillStrokeAlpha)
        background.lineWidth = GameConfig.uiPanelLineWidth
        blurEffect = SKEffectNode()
        blurEffect.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": GameConfig.glassPillBlurRadius]
        )
        blurEffect.shouldRasterize = true
        textLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        super.init()
        name = "glassPill"
        zPosition = 100
        blurEffect.addChild(background)
        addChild(blurEffect)
        configureLabel(text: text)
        addChild(textLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    private func configureLabel(text: String) {
        textLabel.text = text
        textLabel.fontSize = GameConfig.glassPillFontSize
        textLabel.fontColor = .ganhoNavyDeep
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center
        textLabel.position = .zero
        textLabel.zPosition = 1  // blurEffect 위로
    }
}
```

- 참고: `GameConfig.uiPanelLineWidth`가 이미 존재한다고 가정. 만약 없다면 Generator는 1.0pt로 대체.

---

### 기능 4: AccentLineNode (신규)
- 설명: 32×3 라운드 캡 코랄 라인. 모든 헤더 위 시각적 강조.
- 구현 위치: `GanhoMusic Shared/Nodes/AccentLineNode.swift` (신규 파일)
- 시그니처: `init()` (크기 고정 — GameConfig 상수)
- 핵심 코드 구조:

```swift
//
//  AccentLineNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  32×3 라운드 캡 코랄 라인. 모든 헤더 위 시각적 강조에 재사용.
//  DESIGN_RENEWAL_REQUEST.md §3.3.C.
//

import SpriteKit

/// 32×3 코랄 라운드 캡 라인. PhysicsBody 0 — 순수 시각.
final class AccentLineNode: SKShapeNode {

    // MARK: - Init
    override init() {
        super.init()
        let size = CGSize(
            width: GameConfig.accentLineWidth,
            height: GameConfig.accentLineHeight
        )
        path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: size.height / 2,
            cornerHeight: size.height / 2,
            transform: nil
        )
        fillColor = .ganhoCoralPrimary
        strokeColor = .clear
        lineWidth = 0
        name = "accentLine"
        zPosition = 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

---

### 기능 5: DarkContextChipNode (신규)
- 설명: navy 0.92 배경 + 골드 라벨 + 옵션 코랄 뱃지.
- 구현 위치: `GanhoMusic Shared/Nodes/DarkContextChipNode.swift` (신규 파일)
- 시그니처: `init(label: String, badge: String? = nil)`
- 핵심 코드 구조:

```swift
//
//  DarkContextChipNode.swift
//  GanhoMusic Shared
//
//  Sprint 1 · v2 Design System
//
//  navy 0.92 배경 + 골드 라벨 + 옵션 코랄 뱃지.
//  난이도 표시, 브레드크럼, HUD 슬롯, 스킬명 칩에 재사용.
//  DESIGN_RENEWAL_REQUEST.md §3.3.D.
//

import SpriteKit

/// 다크 navy 칩(α=0.92) + Jua 골드 라벨 + 옵션 코랄 뱃지.
/// 폭은 라벨 너비 기반 자동.
final class DarkContextChipNode: SKNode {

    // MARK: - Properties
    private let background: SKShapeNode
    private let labelNode: SKLabelNode
    private let badgeNode: SKShapeNode?
    private let badgeLabel: SKLabelNode?

    // MARK: - Init
    /// - Parameters:
    ///   - label: 본 라벨 텍스트(Jua + 골드).
    ///   - badge: 옵션 뱃지 텍스트(코랄 알약 안 흰색). nil이면 미생성.
    init(label: String, badge: String? = nil) {
        labelNode = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        labelNode.text = label
        labelNode.fontSize = GameConfig.darkContextChipLabelFontSize
        labelNode.fontColor = .ganhoMusicGold
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .center

        if let badgeText = badge {
            let bLabel = SKLabelNode(fontNamed: GameConfig.fontDisplay)
            bLabel.text = badgeText
            bLabel.fontSize = GameConfig.darkContextChipBadgeFontSize
            bLabel.fontColor = .white
            bLabel.horizontalAlignmentMode = .center
            bLabel.verticalAlignmentMode = .center
            badgeLabel = bLabel
            let bgSize = CGSize(
                width: bLabel.frame.width + 12,
                height: GameConfig.darkContextChipHeight - 8
            )
            let bShape = SKShapeNode(
                rectOf: bgSize,
                cornerRadius: bgSize.height / 2
            )
            bShape.fillColor = .ganhoCoralPrimary
            bShape.strokeColor = .clear
            badgeNode = bShape
        } else {
            badgeLabel = nil
            badgeNode = nil
        }

        let labelWidth = labelNode.frame.width
        let badgeWidth = badgeNode?.frame.width ?? 0
        let totalWidth = GameConfig.darkContextChipHorizontalPadding * 2
            + labelWidth
            + (badgeNode != nil ? GameConfig.darkContextChipBadgeSpacing + badgeWidth : 0)
        let bgSize = CGSize(
            width: totalWidth,
            height: GameConfig.darkContextChipHeight
        )
        background = SKShapeNode(
            rectOf: bgSize,
            cornerRadius: bgSize.height / 2
        )
        background.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.darkContextChipBgAlpha)
        background.strokeColor = .clear
        super.init()
        name = "darkContextChip"
        zPosition = 100
        addChild(background)
        labelNode.position = CGPoint(
            x: -bgSize.width / 2 + GameConfig.darkContextChipHorizontalPadding,
            y: 0
        )
        addChild(labelNode)
        if let bShape = badgeNode, let bLabel = badgeLabel {
            let badgeCenterX = bgSize.width / 2 - GameConfig.darkContextChipHorizontalPadding - badgeWidth / 2
            bShape.position = CGPoint(x: badgeCenterX, y: 0)
            bLabel.position = CGPoint(x: badgeCenterX, y: 0)
            addChild(bShape)
            addChild(bLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

---

### 기능 6: PrimaryButtonNode 내부 리스타일링
- 설명: init 시그니처/타입 이름/`name`/탭 컨벤션은 그대로. 내부 시각만 v2 코랄 스타일(코랄 배경 + 라운드 알약 + navy 그림자 + 우측 화살표 + Jua 라벨)로 교체.
- 구현 위치: `GanhoMusic Shared/Nodes/PrimaryButtonNode.swift`
- **보존**:
  - `final class PrimaryButtonNode: SKNode` 타입
  - `init(text: String)` 시그니처
  - `name = "primaryButton"`
  - `zPosition = 100`
  - 호출부에서 `contains(location)`으로 hit-test하는 패턴
- **변경**:
  - 배경 fillColor → `.ganhoCoralPrimary`
  - 배경 strokeColor → `.clear` (v2는 stroke 없이 그림자만)
  - 라벨 fontColor → `.white`
  - 라벨 fontName → `GameConfig.fontDisplay`
  - 그림자 SKShapeNode 자식 추가: 배경과 동일 모양, `fillColor = .ganhoCoralShadow`, `position = (0, primaryButtonShadowOffsetY)`, `zPosition = -1`
  - 우측 화살표 원 자식 추가: `SKShapeNode(circleOfRadius: primaryButtonArrowRadius)`, `fillColor = UIColor.white.withAlphaComponent(0.25)`, position은 배경 우측 끝에서 `primaryButtonArrowInsetX`만큼 안쪽
  - 우측 화살표 라벨: SKLabelNode "▶" 흰색, 화살표 원 중앙
- 호출부 회귀 검증:
  - StartScene, CharacterSelectScene, SkillExplanationScene 등에서 `PrimaryButtonNode(text: ...)` 호출만 — 컴파일 그대로.
  - hit-test는 `node.contains(location)` 또는 `nodes(at:).contains(where: { $0.name == "primaryButton" })` 패턴 둘 다 작동.

---

### 기능 7: BackButtonNode 내부 리스타일링 (GlassPill 패턴)
- 설명: init 시그니처/타입 이름/`name`/탭 컨벤션 그대로. 내부 시각만 GlassPill 톤(반투명 화이트 + Jua + navy 라벨)으로 교체.
- 구현 위치: `GanhoMusic Shared/Nodes/BackButtonNode.swift`
- **보존**:
  - `final class BackButtonNode: SKNode`
  - `init(text: String)` 시그니처
  - `name = "backButton"`
  - `zPosition = 100`
  - 크기 상수(`backButtonWidth/Height/FontSize`) 사용
- **변경**:
  - 배경 fillColor → `UIColor.white.withAlphaComponent(GameConfig.glassPillFillAlpha)`
  - 배경 strokeColor → `UIColor.white.withAlphaComponent(GameConfig.glassPillStrokeAlpha)`
  - 라벨 fontColor → `.ganhoNavyDeep`
  - 라벨 fontName → `GameConfig.fontDisplay`
- **주의**: GlassPillNode 자체를 인스턴스화하지 말 것 — BackButtonNode는 *내부 시각만 GlassPill 톤을 흉내*. 이유: BackButtonNode의 `init(text:)` 시그니처와 hit-test name이 호출부 가드라 컨테이너 교체 시 회귀 위험.

---

### 기능 8: GradientBackgroundNode 3-stop 옵션 추가
- 설명: 기존 2-stop `init(size:topColor:bottomColor:)`는 그대로. 새 3-stop static factory를 **추가**. Sprint 2 메뉴 씬들이 이 3-stop을 호출하게 됨. **Sprint 1에서는 호출자 0**.
- 구현 위치: `GanhoMusic Shared/Nodes/GradientBackgroundNode.swift`
- **보존**:
  - 기존 `init(size:topColor:bottomColor:)` 시그니처/동작
  - `name = "gradientBackground"`
  - `zPosition = GameConfig.startSceneGradientZPosition`
  - StartScene 호출부 컴파일 그대로
- **추가**:
  - 새 `static func threeStop(size:topColor:midColor:bottomColor:) -> GradientBackgroundNode`
  - 새 private static `makeGradientTexture3Stop(size:top:mid:bottom:)`
- 핵심 코드 구조 (방식 A — designated init 체이닝 우회):

```swift
// MARK: - Init (3-stop, Sprint 1)

/// 3색 세로 그라데이션 인스턴스 생성. top(0.0) → mid(0.5) → bottom(1.0).
/// Sprint 2 메뉴 씬(StartScene 외)에서 ganhoBgWarmTop/Mid/Bottom 호출 예정.
/// Sprint 1에서는 호출자 0 — 인프라만 준비.
///
/// 구현 노트: SKSpriteNode designated init 체이닝 제약을 피하기 위해
/// 기존 2-stop init을 한 번 호출한 뒤 texture를 교체하는 패턴.
static func threeStop(
    size: CGSize,
    topColor: UIColor,
    midColor: UIColor,
    bottomColor: UIColor
) -> GradientBackgroundNode {
    let node = GradientBackgroundNode(size: size, topColor: topColor, bottomColor: bottomColor)
    node.texture = makeGradientTexture3Stop(
        size: size,
        top: topColor,
        mid: midColor,
        bottom: bottomColor
    )
    return node
}

private static func makeGradientTexture3Stop(
    size: CGSize,
    top: UIColor,
    mid: UIColor,
    bottom: UIColor
) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        let cgCtx = ctx.cgContext
        let colors = [top.cgColor, mid.cgColor, bottom.cgColor] as CFArray
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.5, 1.0]
        ) {
            cgCtx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        } else {
            cgCtx.setFillColor(top.cgColor)
            cgCtx.fill(CGRect(origin: .zero, size: size))
        }
    }
    return SKTexture(image: image)
}
```

---

## 주의사항

### Swift / SpriteKit 패턴
- **강제 언래핑 0건**: CIFilter init이 옵셔널 반환이지만 SKEffectNode.filter 자체가 `CIFilter?` 타입이라 `filter = CIFilter(name:...)` 직접 대입 가능 (옵셔널 그대로 넘김).
- **매직 넘버 0건**: 모든 수치는 GameConfig 상수로. 위 §기능 2의 GameConfig 추가 블록 그대로 사용.
- **MARK 구조 일관성**: 새 노드 3개는 기존 `PrimaryButtonNode.swift` MARK 구조(`// MARK: - Properties` / `// MARK: - Init` / `// MARK: - Configure`)를 그대로 답습.
- **weak self 캡처**: 새 노드 3개는 SKAction 클로저가 없음 — weak 캡처 필요 0.
- **SKLabelNode fontName 안전성**: ttf 미존재 시 SpriteKit이 자동으로 시스템 폰트 fallback. 별도 가드 불필요.

### SpriteKit 특성
- `SKEffectNode + CIGaussianBlur`: iOS 13+ 지원, 시뮬레이터 정상 작동. `shouldRasterize = true` 필수.
- `SKShapeNode(rectOf:cornerRadius:)`: cornerRadius가 height/2면 자동 알약.
- `SKSpriteNode.texture` 는 `var` — 인스턴스 생성 후 교체 가능. GradientBackgroundNode 방식 A에서 활용.

### 호출자 0 가드
- 새 노드 3개(GlassPill/AccentLine/DarkContextChip)는 **이번 Sprint에서 어디서도 인스턴스화되지 않는다**. Sprint 2 메뉴 씬 작업에서 호출자가 들어옴.
- 만약 Generator가 "기존 화면에 미리 끼워보자"라고 충동하면 **즉시 SPEC 위반**.

### 빌드 에러 가능성
- `import CoreImage` 누락 시 CIFilter 미해상 — GlassPillNode.swift 상단에 `import CoreImage` 명시.
- `GameConfig.uiPanelLineWidth`가 이미 정의돼 있다고 가정. 미정의면 Generator는 1.0pt 리터럴로 대체 (단, SPEC상 매직 넘버 0건 규칙은 일관 토큰이 없을 때의 *최소 fallback*으로만 허용).

---

## 검증 체크리스트 (Evaluator용)

### 게임 로직 회귀 (40%)
- [ ] `git diff GanhoMusic/GanhoMusic\ Shared/Scenes/` → 변경 0줄
- [ ] `git diff GanhoMusic/GanhoMusic\ Shared/Systems/` → 변경 0줄
- [ ] GameConfig 게임 수치(scorePerNote, comboWindow, projectileSpeed, tileSize, gameDuration) 변경 0줄
- [ ] PhysicsCategory 변경 0줄
- [ ] ContactRouter / PlayerSkill / Difficulty / EnemyNode 변경 0줄

### Swift 패턴 (20%)
- [ ] 강제 언래핑 `!` 신규 0건
- [ ] `Timer.scheduledTimer` 신규 0건
- [ ] 매직 넘버 0건 — 모든 수치 GameConfig 상수
- [ ] MARK 섹션 구조 일관 (Properties / Init / Configure)
- [ ] 신규 파일 3개 모두 `import SpriteKit` + 필요 시 `import CoreImage`
- [ ] `final class` 사용

### 비주얼 인프라 완전성 (25% — Sprint 1 특수)
- [ ] ColorTokens에 v2 토큰 16개 추가 (ganhoBgWarmTop/Mid/Bottom, ganhoBgAccent1/2, ganhoCoralPrimary/Light/Shadow, ganhoNavyDeep/Muted, ganhoMusicGold, ganhoLavenderSoft, ganhoScrubMint, ganhoSkinTone, ganhoFloorPeachA/B)
- [ ] 기존 ColorTokens hex 값 0줄 변경 (ganhoBgDeep, ganhoAccentTeal, ganhoUIBrand 등 보존)
- [ ] GameConfig에 fontDisplay/fontBody/fontNumeric 3개 + 컴포넌트 상수(glassPill*, accentLine*, darkContextChip*, primaryButton 그림자/화살표 상수) 추가
- [ ] GlassPillNode.swift 신규 생성 + `init(text:size:)` 시그니처
- [ ] AccentLineNode.swift 신규 생성 + `init()` 시그니처
- [ ] DarkContextChipNode.swift 신규 생성 + `init(label:badge:)` 시그니처 (badge는 String?, default nil)
- [ ] PrimaryButtonNode 내부 코랄 + 그림자 + 화살표 + Jua 라벨로 교체. `init(text:)` 보존, `name="primaryButton"` 보존
- [ ] BackButtonNode 내부 GlassPill 톤(반투명 화이트 + Jua + navy 라벨)으로 교체. `init(text:)` 보존, `name="backButton"` 보존
- [ ] GradientBackgroundNode에 `static func threeStop(size:topColor:midColor:bottomColor:)` 추가, 기존 `init(size:topColor:bottomColor:)` 보존
- [ ] 신규 노드 3개를 어디에서도 인스턴스화 0건 (Sprint 2 대기)

### 가독성 & UX (15%)
- [ ] 컴파일 에러 0건 (Xcode 빌드 클린)
- [ ] 실행 시 StartScene 시각 결과가 Phase 10-2 결과물과 픽셀 동일 (기존 호출자가 그대로 작동 — GradientBackgroundNode 2-stop init, MusicNoteEmitter, GlowingTitle 등)
- [ ] 신규 노드 3개를 임시 디버그 호출 시 크래시 0

---

## OPEN_QUESTION (사용자 후속 작업 항목)

### Q1. 폰트 ttf 파일 추가 — 누가 언제?
- **현재 SPEC 범위**: GameConfig에 폰트 이름 상수 3개만 추가. ttf 파일 추가/Info.plist 편집은 **사용자 후속 작업으로 분리**.
- **이유**:
  1. Generator는 Xcode 프로젝트 파일(.xcodeproj/project.pbxproj)을 안전하게 편집할 수 없음 (target membership, build phase 자동 등록 등 IDE 작업).
  2. ttf 미존재 시 `SKLabelNode(fontNamed:)`는 자동으로 시스템 폰트 fallback — 컴파일/런타임 모두 정상.
- **사용자 후속 액션** (Sprint 1 완료 후):
  1. https://fonts.google.com/specimen/Jua 에서 `Jua-Regular.ttf` 다운로드
  2. https://fonts.google.com/specimen/Gowun+Dodum 에서 `GowunDodum-Regular.ttf` 다운로드
  3. https://fonts.google.com/specimen/Noto+Sans+KR 에서 `NotoSansKR-Bold.ttf` 다운로드
  4. Xcode에서 `GanhoMusic Shared/Resources/Fonts/` 폴더 생성 후 3개 ttf 드래그 → "Copy items if needed" + "Add to target: GanhoMusic iOS" 체크
  5. `GanhoMusic iOS/Info.plist`에 다음 추가:
     ```xml
     <key>UIAppFonts</key>
     <array>
       <string>Jua-Regular.ttf</string>
       <string>GowunDodum-Regular.ttf</string>
       <string>NotoSansKR-Bold.ttf</string>
     </array>
     ```
  6. Sprint 2 시작 전 시뮬레이터에서 한 번 빌드/실행하여 "Jua-Regular" 폰트가 실제 적용되는지 시각 확인.
- **검수 영향**: Evaluator는 이 항목을 "사용자 후속 작업"으로 인지하고 Sprint 1 합격 판정에서 제외. GameConfig 폰트 *상수 정의*만 검증.

### Q2. PrimaryButton/BackButton "시각 변화 0"의 정확한 해석
- DESIGN_RENEWAL_STATE.md 합격 기준 "기존 화면 시각 변화 0"과 DESIGN_RENEWAL_REQUEST.md §9 Sprint 1 "PrimaryButtonNode/BackButtonNode 리스타일링"이 **표면적으로 모순**.
- 본 SPEC의 해석: §9가 우선. **버튼 내부 시각은 v2로 교체되고, 이를 사용하는 모든 씬에서 버튼 자체의 모습은 바뀐다**. 단 init 시그니처/탭 콜백/`name`은 보존 → 기능 회귀 0.
- 시각 변화 0의 진짜 의미: "씬 *레이아웃*과 *그라데이션 색*은 기존" — 다음 Sprint 2가 끌어다 쓸 *부품*만 새로 깎임.
- Evaluator는 이 트레이드오프를 인지하고 채점.

---

**SPEC 작성**: Planner Agent (Sprint 1)
**문서 의존**: DESIGN_RENEWAL_REQUEST.md §3 / §6 / §9 / §11, DESIGN_RENEWAL_STATE.md Sprint 1
**다음 단계**: Generator가 본 SPEC을 그대로 구현 → Evaluator가 위 §검증 체크리스트로 채점
