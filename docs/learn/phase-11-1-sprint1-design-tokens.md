# Phase 11-1 (Sprint 1) — 디자인 리뉴얼 인프라 (부품 창고 짓기)

## 한 줄 요약
**다음 Sprint들이 쓸 "부품"만 미리 깎아두는 작업이에요.** 따뜻한 코랄·라벤더 색깔표, 폰트 이름표, 그리고 알약 모양 버튼·실 같은 강조 라인·골드 라벨 칩 세 가지 부품을 만들었어요. 화면에는 아직 아무 변화가 없어요 — 다음 Sprint에서 이 부품들을 화면에 갖다 붙일 차례.

---

## 무엇을, 왜?

### 무엇을
| 항목 | 결과 |
|---|---|
| 색깔표 (ColorTokens) | 새 v2 색 **16개** 추가 (피치, 코랄, 라벤더, 골드 등) |
| 폰트 이름표 (GameConfig) | Jua / Gowun Dodum / Noto Sans KR 이름만 등록 (파일은 아직) |
| 새 부품 노드 | GlassPillNode (반투명 알약), AccentLineNode (32×3 코랄 줄), DarkContextChipNode (다크 칩 + 골드 라벨) |
| 기존 버튼 2개 | PrimaryButton (코랄+그림자+화살표), BackButton (반투명 화이트+navy 라벨)로 내부만 새로 칠함 |
| 그라데이션 | 기존 2색 그라데이션 위에 3색 그라데이션 옵션 추가 |

### 왜
- 음악박사 게임을 "어두운 픽셀 톤"에서 "따뜻하고 친근한 카툰 톤"으로 갈아입히는 큰 작업이 시작됐어요.
- 큰 작업을 한 번에 하면 사고 나니까, 다섯 단계(Sprint 1~5)로 쪼개요. **Sprint 1은 인프라 준비**.
- 인프라란 곧 "재료". 색·폰트·재사용 부품 3종이 준비돼야 다음 Sprint가 "위치만 잡고 색 바꾸면 끝" 수준으로 떨어져요.

### 변경 전/후

```
지금 (Sprint 1 후)              다음 Sprint 2 후 (예상)
┌──────────────────────┐       ┌──────────────────────┐
│ 화면 = Phase 10-2 그대로│  ──→  │ 메뉴 3씬 = 카툰 톤으로 │
│ 단, 부품 창고가 가득함 │       │   갈아입음             │
└──────────────────────┘       └──────────────────────┘
        부품 = 색16, 폰트3,             ↑
        Pill/Line/Chip 노드 3종         이번 부품을 끌어다 씀
```

---

## Spring Boot 비유

이번 작업은 Spring으로 치면 **"Service / Repository 만 새로 만들고 Controller는 아직 안 건드린" 단계**예요.

| Spring Boot | SpriteKit (이번 작업) |
|---|---|
| `application.yml`에 색 hex 16개 추가 | `ColorTokens.swift`에 `ganhoCoralPrimary` 등 16개 정적 프로퍼티 |
| `application.yml`에 `app.font.display=Jua-Regular` | `GameConfig.fontDisplay = "Jua-Regular"` |
| 새 `@Service` 클래스 3개 | 새 `SKNode` 서브클래스 3개 (`GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`) |
| 기존 `@Component`의 내부 메서드만 교체 (시그니처 보존) | 기존 `PrimaryButtonNode.init(text:)` 시그니처 보존, 내부 자식 노드만 v2 스타일로 |
| `@Bean public PdfRenderer pdfRenderer3Stop(...)` 추가 | `GradientBackgroundNode.threeStop(...)` static factory 추가 |
| `application.yml` 기존 키 값은 0 변경 | `ColorTokens.swift` 기존 `ganhoBgDeep` 등 hex 0 변경 |

핵심은 **"공개 API는 그대로, 내부와 추가만"**. Spring에서 Controller 메서드 시그니처를 안 바꾸면 프론트가 안 깨지듯, 여기선 `PrimaryButtonNode.init(text:)`와 `name = "primaryButton"` 두 가지가 호출부의 hit-test 가드라 *절대 못 건드림*.

---

## 들어간 핵심 결정 5가지

### 1. 색깔표는 *추가만* (16개)
DESIGN_RENEWAL_REQUEST.md §3.1을 hex/이름까지 1:1로 복사해서 `ColorTokens.swift` 끝에 새 MARK 섹션으로 추가했어요. **기존 토큰**(Phase 10-2에서 추가한 `ganhoAccentTeal` 포함)은 단 한 줄도 안 바꿨어요.

왜? Sprint 2~3가 점진적으로 *기존 토큰을 v2 토큰으로 교체*할 거예요. 지금 동시에 두 톤이 공존해야 함 — 그래서 추가만.

### 2. 폰트는 이름표만, 파일은 아직 없음 (OPEN_QUESTION Q1)
```swift
static let fontDisplay: String = "Jua-Regular"
static let fontBody:    String = "GowunDodum-Regular"
static let fontNumeric: String = "NotoSansKR-Bold"
```
근데 ttf 파일은 아직 프로젝트에 안 들어왔어요. 왜?
- 폰트 ttf 다운로드 + Xcode `Add to target` + `Info.plist UIAppFonts` 배열 추가는 **IDE 작업**이라 Generator가 안전하게 못 함.
- 다행히 `SKLabelNode(fontNamed: "Jua-Regular")`는 ttf가 없으면 **시스템 폰트로 자동 fallback**해요. 컴파일/런타임 둘 다 깨지지 않음.
- **사용자가 후속으로** Google Fonts에서 3개 ttf 받아서 Xcode에 추가 → Info.plist UIAppFonts 배열 추가 → 그 다음에 진짜 Jua 폰트가 적용됨.

Spring으로 치면 **`application.yml`에 `app.font.display=Jua-Regular`라고 적어두고, 실제 ttf 리소스는 운영자가 `static/fonts/` 에 업로드하는 패턴**.

### 3. 새 부품 노드 3종은 *호출자 0*
- `GlassPillNode(text:size:)` — 반투명 화이트 + 가우시안 블러 + Jua 라벨
- `AccentLineNode()` — 32×3 라운드 캡 코랄 라인 (헤더 위 강조)
- `DarkContextChipNode(label:badge:?)` — navy 0.92 칩 + 골드 라벨 + 옵션 코랄 뱃지

**이번 Sprint에서는 어디서도 인스턴스화 안 함**. Sprint 2 메뉴 씬 리스킨에서 처음 등장. 만약 지금 미리 끼워봤다면 *시각 회귀가 발생*해서 Sprint 1 합격 기준("기존 화면 변화 0")을 깬다는 게 SPEC의 가드.

Spring으로 치면 **새 `@Service`를 빈으로 등록해두기만 하고, 컨트롤러는 다음 PR에서 주입받기**.

### 4. 기존 버튼 2개는 *내부만* 갈아치움
`PrimaryButtonNode.init(text:)`와 `name = "primaryButton"`은 호출부(StartScene 등)에서 `node.contains(location)`로 hit-test하는 가드예요. 시그니처/이름이 바뀌면 호출부 컴파일 깨짐.

그래서:
- ✅ `init(text:)` 시그니처 그대로
- ✅ `name = "primaryButton"` 그대로
- ✅ 자식 노드 추가/색 변경만 (코랄 fill + navy 그림자 자식 + 흰 화살표 원 자식)

이건 Spring의 **"public API는 잠그고 내부 구현만 갈아치우는 리팩토링"** 패턴이에요. 호출자 영향 0.

### 5. GradientBackgroundNode 3-stop은 *static factory*로
기존 `init(size:topColor:bottomColor:)`는 SKSpriteNode의 designated init이라 새 3-stop init을 체이닝하는 게 복잡해요. 그래서:

```swift
static func threeStop(size:topColor:midColor:bottomColor:) -> GradientBackgroundNode {
    let node = GradientBackgroundNode(size:..., topColor:..., bottomColor:...)
    node.texture = makeGradientTexture3Stop(...)  // 텍스처만 교체
    return node
}
```

기존 2-stop init을 *한 번 호출*해서 노드 골격을 만든 다음, `SKSpriteNode.texture` 가 `var`인 점을 이용해 3-stop 텍스처로 갈아끼우는 방식.

Spring으로 치면 **기존 빈을 한 번 부른 뒤 setter로 핵심 필드만 갈아끼우는 builder 패턴**.

---

## Swift / SpriteKit 학습 포인트

### 4-1. `SKSpriteNode.texture` 는 `var` — 인스턴스 생성 후 갈아끼우기 가능
Swift는 보통 `final class` + immutable이 권장되지만, `SKSpriteNode.texture: SKTexture?`는 *var*. 그래서 GradientBackgroundNode가 살아있는 채로 그라데이션 색을 바꿔치기할 수 있어요.

**왜?** SpriteKit은 게임 엔진 — 매 프레임 텍스처 교체(애니메이션)가 일상이라 immutable로 가둘 수 없어요. Spring의 `@Service` 빈이 immutable인 것과 정반대 철학.

### 4-2. `SKEffectNode + CIGaussianBlur` 에는 `shouldRasterize = true`
```swift
blurEffect = SKEffectNode()
blurEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 12])
blurEffect.shouldRasterize = true  // ← 필수
```
블러를 매 프레임 재계산하면 GPU가 죽어요. `shouldRasterize`는 "한 번 계산한 결과를 이미지로 캐싱"하라는 뜻. Spring의 `@Cacheable`과 똑같은 발상.

**함정**: shouldRasterize를 안 켜면 시뮬레이터에서도 FPS가 60 → 20으로 떨어질 수 있어요.

### 4-3. CIFilter는 옵셔널 반환 — 옵셔널인 채로 대입
```swift
// ❌ 강제 언래핑 — nil이면 즉사
blurEffect.filter = CIFilter(name: "CIGaussianBlur")!

// ✅ SKEffectNode.filter 자체가 CIFilter? 라서 옵셔널 그대로 대입
blurEffect.filter = CIFilter(name: "CIGaussianBlur", parameters: [...])
```
SPEC의 "강제 언래핑 0건" 규칙은 이런 자잘한 곳에서 깨지기 쉬워요.

### 4-4. `SKLabelNode(fontNamed:)` 의 자동 fallback
- ttf 미존재 시 자동으로 시스템 폰트 fallback. 별도 가드 0줄.
- 단, `UIFont`가 필요한 경우(드물지만): `UIFont(name:size:) ?? UIFont.systemFont(ofSize:)` 패턴.

### 4-5. SKShapeNode 알약(pill) 만들기
```swift
SKShapeNode(rectOf: size, cornerRadius: size.height / 2)
```
`cornerRadius = height/2` 면 자동 알약. `width == height` 면 자동 원. CSS의 `border-radius: 50%` 와 동치.

### 4-6. `CGPath(roundedRect:cornerWidth:cornerHeight:)` 의 라운드 캡
AccentLineNode는 SKShapeNode의 `path` 를 직접 만들었어요:
```swift
path = CGPath(roundedRect: rect, cornerWidth: height/2, cornerHeight: height/2, transform: nil)
```
양 끝이 반원으로 떨어지는 "라운드 캡 라인" 효과. SKShapeNode(rectOf:cornerRadius:)와 같은 결과지만 CGPath를 직접 만져본다는 학습 포인트.

### 4-7. `SKLabelNode.frame.width` 는 *부착 전에도* 계산 가능
DarkContextChipNode에서 라벨 너비 기반으로 칩 폭 자동 계산:
```swift
labelNode.text = label  // 이 시점에 frame.width 계산됨
let totalWidth = padding * 2 + labelNode.frame.width + ...
```
SwiftUI의 GeometryReader 없이도 폰트 메트릭으로 즉시 계산. 단, 시스템 폰트로 fallback될 때 폭이 살짝 달라질 수 있어요 (Sprint 1 합격 기준엔 영향 0).

---

## 산출물

### 수정 파일 (6개)
- `GanhoMusic Shared/Config/ColorTokens.swift` — v2 토큰 16개 *추가만*
- `GanhoMusic Shared/Config/GameConfig.swift` — 폰트 상수 3 + 컴포넌트 수치 상수 19 *추가만*
- `GanhoMusic Shared/Nodes/PrimaryButtonNode.swift` — 내부 시각 v2 코랄 스타일
- `GanhoMusic Shared/Nodes/BackButtonNode.swift` — 내부 시각 GlassPill 톤
- `GanhoMusic Shared/Nodes/GradientBackgroundNode.swift` — `static func threeStop(...)` 추가
- `GanhoMusic.xcodeproj/project.pbxproj` — 신규 .swift 3개 등록

### 신규 파일 (3개)
- `GanhoMusic Shared/Nodes/GlassPillNode.swift`
- `GanhoMusic Shared/Nodes/AccentLineNode.swift`
- `GanhoMusic Shared/Nodes/DarkContextChipNode.swift`

### 산출 문서
- `SPEC.md` — Planner가 작성한 명세
- `SELF_CHECK.md` — Generator 자체 점검
- `QA_REPORT.md` — Evaluator 채점 (9.83/10)

---

## 검증 방법

### 시각 검증 (사용자가 해야 함)
- [ ] Xcode 빌드 → 시뮬레이터 실행 → **Phase 10-2 결과물과 픽셀 동일**해야 함
- [ ] StartScene, CharacterSelectScene, SkillExplanationScene, GameScene, ResultScene 모두 평소처럼 동작
- [ ] 시작 버튼(PrimaryButton), 뒤로 버튼(BackButton)이 *살짝* 다르게 보일 수 있음 — 코랄+그림자+화살표(Primary), 반투명 화이트(Back). 이건 SPEC OPEN_QUESTION Q2에서 의도된 변화로 합의됨.

### 정량 검증 (자동)
- ✅ 빌드 성공 (xcodebuild iPhone 17 simulator, Debug, 에러 0)
- ✅ 기존 5개 씬 git diff 0줄
- ✅ ColorTokens 기존 hex 0줄 변경
- ✅ GameConfig 게임 로직 상수 0줄 변경
- ✅ 신규 노드 3종 호출자 0건 (`grep -r "GlassPillNode(|AccentLineNode(|DarkContextChipNode("`)
- ✅ PrimaryButton/BackButton/GradientBackground `init` 시그니처 + `name` 보존
- ✅ 강제 언래핑 신규 0, Timer 신규 0, 매직 넘버 0

---

## 사용자 결정 필요 사항 (Sprint 2 시작 전)

### ① 폰트 ttf 추가 (OPEN_QUESTION Q1)
**옵션**:
- **A. 지금 추가** ⭐ — Sprint 2 결과물이 실제 Jua/GowunDodum/NotoSansKR로 보임
- B. 나중 추가 — Sprint 2 결과물은 시스템 폰트로 fallback (시각 평가에 영향)

**A 선택 시 해야 할 일**:
1. https://fonts.google.com/specimen/Jua → `Jua-Regular.ttf` 다운로드
2. https://fonts.google.com/specimen/Gowun+Dodum → `GowunDodum-Regular.ttf` 다운로드
3. https://fonts.google.com/specimen/Noto+Sans+KR → `NotoSansKR-Bold.ttf` 다운로드
4. Xcode → `GanhoMusic Shared/Resources/Fonts/` 폴더 생성 → 3개 ttf 드래그 → "Copy items if needed" ✅ + "Add to target: GanhoMusic iOS" ✅
5. `GanhoMusic iOS/Info.plist` 에 추가:
   ```xml
   <key>UIAppFonts</key>
   <array>
     <string>Jua-Regular.ttf</string>
     <string>GowunDodum-Regular.ttf</string>
     <string>NotoSansKR-Bold.ttf</string>
   </array>
   ```
6. 빌드 → 시뮬레이터 실행 → Sprint 2가 끝나기 전에 폰트 적용 확인.

---

## SPEC에 들어갔던 핵심 제약

- **변경 유형**: 비주얼 인프라 (시각 변화 0)
- **게임 경험 의도**: 다음 Sprint 2가 끌어다 쓸 부품 창고 짓기. 사용자가 직접 보는 결과 없음.
- **Sprint 1 범위 계약**:
  - IN: 토큰 16, 폰트 상수 3, 컴포넌트 상수 19, 신규 노드 3, 버튼 2 리스타일, 그라데이션 3-stop factory
  - OUT: 기존 씬 호출부, 폰트 ttf 파일 추가, Info.plist 편집, 게임 로직, 신규 노드 인스턴스화
- **준수 룰**: 강제 언래핑 0, Timer 0, 매직 넘버 0, MARK 일관, `final class`
- **회귀 보존**: Phase 10-2 StartScene 결과물 픽셀 동일

---

## 회고

### 9-1. 막혔던 것
- SKSpriteNode designated init 체이닝 제약 때문에 GradientBackgroundNode의 3-stop을 새 init으로 만드는 게 까다로움. 결국 **static factory + texture 교체 패턴**으로 우회.
- pbxproj에 신규 .swift 3개 등록 — UUID 16자리 hex 4개 새로 만들고 PBXFileReference / PBXBuildFile / PBXGroup 3섹션에 일관되게 등록. 자동화하기 어려운 부분이라 Generator가 직접 정합 검증.

### 9-2. Spring과 다르네 싶었던 것
1. `SKSpriteNode.texture` 가 var — Spring 빈 immutable과 정반대
2. `CIFilter(name:)` 옵셔널 반환을 강제 언래핑 없이 받아 SKEffectNode.filter? 에 그대로 대입
3. SKLabelNode 자동 fallback — 폰트 미존재 시 자동 시스템 폰트
4. SKShapeNode cornerRadius = height/2 = 알약 (CSS border-radius: 50%와 동치)
5. CGPath roundedRect로 라운드 캡 라인 — UIKit이 아닌 Core Graphics 영역

### 9-3. 다음 작업 이월 결정
- 폰트 ttf 3개 추가 (사용자 OPEN_QUESTION Q1)
- Sprint 2 시작 전 시뮬레이터에서 폰트 적용 시각 확인
- Sprint 2에서 신규 노드 3종(GlassPill/AccentLine/DarkContextChip)을 메뉴 씬 3개에 첫 호출 — 이때 첫 시각 회귀가 의도된 형태로 발생

### 9-4. 평가 점수
| 카테고리 | 점수 | 가중치 |
|---|---|---|
| 게임 로직 회귀 0 | 10.0 | 40% → 4.00 |
| Swift 패턴 | 9.5 | 20% → 1.90 |
| 비주얼 인프라 완전성 | 10.0 | 25% → 2.50 |
| 가독성 & UX | 9.5 | 15% → 1.43 |
| **가중 평균** | **9.83 / 10** | |

QA 반복: **1회** (한 번에 통과)

### 9-5. 사용자 직접 확인할 것
- [ ] Xcode 빌드 SUCCEEDED (이미 자동 확인됨)
- [ ] 시뮬레이터 실행 시 StartScene Phase 10-2와 픽셀 동일
- [ ] 메뉴 씬 진입 시 시작 버튼(PrimaryButton)이 *코랄+그림자+화살표* 톤으로 살짝 바뀐 게 의도와 일치하는지
- [ ] (선택) 폰트 ttf 3개 Xcode 추가 + Info.plist UIAppFonts 배열 작성

---

## 다음 단계 안내

**Sprint 2 — 메뉴 3씬 (Start/Character/Skill)**
- `mockups/main-screen-v2.html` 매칭 → StartScene
- `mockups/character-select-v2.html` 매칭 → CharacterSelectScene
- `mockups/skill-explanation-v2.html` 매칭 → SkillExplanationScene
- 캐릭터 자리는 placeholder (Sprint 4 PNG 통합 대기)

트리거: 세션에서 `디자인 리뉴얼 진행해줘` 또는 `Sprint 2 진행해줘` 한 마디.

---

## 핵심 교훈

> **"비주얼 큰 작업은 부품부터 깎는다. 부품이 잘 깎이면 본 작업이 단순해진다."**

Sprint 1만 한 줄도 안 보이는 결과지만, Sprint 2가 "위치 잡고 색 바꾸면 끝" 수준으로 떨어진 게 진짜 성과. Spring으로 치면 도메인 모델/Repository를 먼저 정착시킨 뒤 Controller만 갈아끼우는 절차와 동일.
