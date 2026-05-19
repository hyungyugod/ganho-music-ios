# 자체 점검 — Sprint 1 (디자인 리뉴얼 인프라)

전략: 1회차 (Case A 해당 없음)

---

## SPEC 8개 기능 체크

### 기능 1 — ColorTokens v2 토큰 16개 추가
- [x] 구현 완료. `ColorTokens.swift:233-261` (라인 번호: 신규 MARK 섹션 `v2 Design System (Warm Pastel · Sprint 1)`)
- [x] 토큰 16개 모두 SPEC 원문 hex 그대로:
  - 배경 5: `ganhoBgWarmTop(#FFE5D0)`, `ganhoBgWarmMid(#FFC8B5)`, `ganhoBgWarmBottom(#DCC9E8)`, `ganhoBgAccent1(#FFD9B8)`, `ganhoBgAccent2(#E5C8E8)`
  - 코랄 3: `ganhoCoralPrimary(#FF6B5B)`, `ganhoCoralLight(#FF8E80)`, `ganhoCoralShadow(#C44A3D)`
  - 텍스트 3: `ganhoNavyDeep(#2D2A4A)`, `ganhoNavyMuted(#5A5670)`, `ganhoMusicGold(#FFB347)`
  - 디테일 3: `ganhoLavenderSoft(#B89DD9)`, `ganhoScrubMint(#9BE0CC)`, `ganhoSkinTone(#FFE2C6)`
  - 체크보드 2: `ganhoFloorPeachA(#FFEFE0)`, `ganhoFloorPeachB(#FFDFC8)`

### 기능 2 — GameConfig 폰트 상수 3개 + 컴포넌트 수치 상수
- [x] 폰트 3개: `fontDisplay`, `fontBody`, `fontNumeric` 추가 (`GameConfig.swift:1117-1124`)
- [x] 컴포넌트 상수 추가 (`GameConfig.swift:1126-1170`):
  - GlassPill 4종: `glassPillFillAlpha`, `glassPillStrokeAlpha`, `glassPillBlurRadius`, `glassPillFontSize`
  - AccentLine 2종: `accentLineWidth`, `accentLineHeight`
  - DarkContextChip 7종: `darkContextChipBgAlpha`, `darkContextChipLabelFontSize`, `darkContextChipBadgeFontSize`, `darkContextChipHorizontalPadding`, `darkContextChipHeight`, `darkContextChipBadgeSpacing`, `darkContextChipBadgeHorizontalPadding`, `darkContextChipBadgeVerticalInset`
  - PrimaryButton 6종: `primaryButtonShadowOffsetY`, `primaryButtonShadowBlurRadius`, `primaryButtonArrowRadius`, `primaryButtonArrowInsetX`, `primaryButtonArrowCircleAlpha`, `primaryButtonArrowLabelFontSize`

### 기능 3 — GlassPillNode.swift 신규
- [x] `Nodes/GlassPillNode.swift` 신규 파일 작성
- [x] `init(text: String, size: CGSize)` 시그니처 정확
- [x] `SKEffectNode + CIGaussianBlur` 패턴, `shouldRasterize = true`
- [x] `import SpriteKit` + `import CoreImage` 모두 명시
- [x] `name = "glassPill"`, `zPosition = 100`

### 기능 4 — AccentLineNode.swift 신규
- [x] `Nodes/AccentLineNode.swift` 신규 파일 작성
- [x] `override init()` 시그니처 (SKShapeNode 상속)
- [x] 32×3 라운드 캡 (cornerWidth/Height = height/2)
- [x] `fillColor = .ganhoCoralPrimary`, `strokeColor = .clear`
- [x] `name = "accentLine"`, `zPosition = 10`

### 기능 5 — DarkContextChipNode.swift 신규
- [x] `Nodes/DarkContextChipNode.swift` 신규 파일 작성
- [x] `init(label: String, badge: String? = nil)` 시그니처 (badge는 옵셔널 default nil)
- [x] navy 0.92 배경 + Jua 골드 라벨 + 옵션 코랄 뱃지
- [x] 라벨 width 기반 자동 폭 계산 — 뱃지 유무에 따라 분기
- [x] `name = "darkContextChip"`, `zPosition = 100`

### 기능 6 — PrimaryButtonNode 코랄 v2 리스타일링
- [x] `init(text: String)` 시그니처 보존 — 호출부 회귀 0
- [x] `name = "primaryButton"`, `zPosition = 100` 보존
- [x] 배경 `fillColor = .ganhoCoralPrimary`, `strokeColor = .clear`
- [x] 그림자 자식 추가 (`fillColor = .ganhoCoralShadow`, `position.y = -6`, `zPosition = -1`)
- [x] 우측 화살표 원(`circleOfRadius: 12`) + "▶" 라벨 추가
- [x] 라벨 `fontColor = .white`, `fontName = Jua-Regular`
- [x] 호출자 검증: `CharacterSelectScene:32`, `SkillExplanationScene:32`, `StartScene:37` 모두 `PrimaryButtonNode(text:)` 그대로 → 컴파일 OK

### 기능 7 — BackButtonNode GlassPill 톤 리스타일링
- [x] `init(text: String)` 시그니처 보존
- [x] `name = "backButton"`, `zPosition = 100` 보존
- [x] 배경 `fillColor = white α=0.55`, `strokeColor = white α=0.25` (GlassPill 톤 흉내)
- [x] 라벨 `fontColor = .ganhoNavyDeep`, `fontName = Jua-Regular`
- [x] GlassPillNode 인스턴스 직접 사용 0건 — 내부 시각만 흉내(SPEC 주의사항 준수)
- [x] 호출자 검증: `CharacterSelectScene:31`, `SkillExplanationScene:31` 모두 `BackButtonNode(text:)` 그대로 → 컴파일 OK

### 기능 8 — GradientBackgroundNode 3-stop 옵션 추가
- [x] 기존 `init(size:topColor:bottomColor:)` 시그니처/동작/zPosition/name 모두 보존
- [x] 신규 `static func threeStop(size:topColor:midColor:bottomColor:) -> GradientBackgroundNode` 추가
- [x] 신규 `private static func makeGradientTexture3Stop(...)` 헬퍼 추가
- [x] 구현 방식: 2-stop init으로 생성 후 `node.texture = ...` 교체 (designated init 체이닝 우회)
- [x] 호출자 검증: `StartScene:90` 호출은 기존 2-stop 그대로 → 컴파일 OK

---

## SPEC 불변 계약 표 검증

| 항목 | 상태 | 근거 |
|---|---|---|
| `PrimaryButtonNode.init(text:)` 시그니처 | 보존 | `PrimaryButtonNode.swift:38` `init(text: String)` 단일 |
| `BackButtonNode.init(text:)` 시그니처 | 보존 | `BackButtonNode.swift:34` `init(text: String)` 단일 |
| `PrimaryButtonNode.name == "primaryButton"` | 보존 | `PrimaryButtonNode.swift:73` `name = "primaryButton"` |
| `BackButtonNode.name == "backButton"` | 보존 | `BackButtonNode.swift:46` `name = "backButton"` |
| `GradientBackgroundNode.init(size:topColor:bottomColor:)` | 보존 | `GradientBackgroundNode.swift:25` 시그니처 그대로 |
| `GradientBackgroundNode.name == "gradientBackground"` | 보존 | `GradientBackgroundNode.swift:33` 그대로 |
| 기존 `ColorTokens` hex 값 | 0 변경 | `git diff ColorTokens.swift` 결과: `-` 라인 0 (추가만) |
| `GameConfig` 게임 로직 상수 | 0 변경 | `git diff GameConfig.swift` 결과: `-` 라인 0 (추가만) — `gameDuration`, `tileSize`, `scorePerNote`, `comboWindow` 모두 보존 |
| `Info.plist` | 0 변경 | `git diff Info.plist` 비어 있음 |
| 기존 5개 씬 파일 | 0 변경 | `git diff Scenes/` 비어 있음 (확인 명령: `git diff --stat Scenes/`) |
| 새 노드 3종 호출자 0 | 충족 | `grep -rn "GlassPillNode(\|AccentLineNode(\|DarkContextChipNode(" GanhoMusic/` 결과 0건 |

---

## 검수 체크리스트 채점 (SPEC §검증 체크리스트)

### 게임 로직 회귀 (40%)
- [x] `git diff Scenes/` → 변경 0줄
- [x] `git diff Systems/` → 변경 0줄
- [x] GameConfig 게임 수치(scorePerNote, comboWindow, projectileSpeed, tileSize, gameDuration) 변경 0줄 — 모두 보존, `git diff GameConfig.swift`에서 `-` 라인 0
- [x] PhysicsCategory 변경 0줄 (수정 대상 아님)
- [x] ContactRouter / PlayerSkill / Difficulty / EnemyNode 변경 0줄 (수정 대상 아님)

### Swift 패턴 (20%)
- [x] 강제 언래핑 `!` 신규 0건 — `grep '![ ).,;]'` 결과 0건 (주석 제외)
- [x] `Timer.scheduledTimer` 신규 0건
- [x] 매직 넘버 0건 — 모든 수치 `GameConfig.*` 상수 참조
- [x] MARK 섹션 구조 일관: `// MARK: - Properties` / `// MARK: - Init` / `// MARK: - Configure`
- [x] 신규 파일 3개 모두 `import SpriteKit` + GlassPillNode는 `import CoreImage` 추가
- [x] `final class` 사용 — GlassPillNode, AccentLineNode, DarkContextChipNode 모두

### 비주얼 인프라 완전성 (25% — Sprint 1 특수)
- [x] ColorTokens에 v2 토큰 16개 추가 (위 §기능1 명세 일치)
- [x] 기존 ColorTokens hex 값 0줄 변경 (`ganhoBgDeep #1A1B2E`, `ganhoAccentTeal #5BD7CF`, `ganhoUIBrand #c4847a` 등 보존)
- [x] GameConfig에 `fontDisplay` / `fontBody` / `fontNumeric` 3개 + GlassPill / AccentLine / DarkContextChip / PrimaryButton 그림자·화살표 컴포넌트 상수 추가
- [x] `GlassPillNode.swift` 신규 + `init(text:size:)` 시그니처 일치
- [x] `AccentLineNode.swift` 신규 + `init()` 시그니처 일치
- [x] `DarkContextChipNode.swift` 신규 + `init(label:badge:)` 시그니처 (badge: String? = nil) 일치
- [x] PrimaryButtonNode 내부 시각 코랄 + 그림자 + 화살표 + Jua로 교체. `init(text:)` / `name="primaryButton"` 보존
- [x] BackButtonNode 내부 시각 GlassPill 톤(반투명 화이트 + Jua + navy 라벨)으로 교체. `init(text:)` / `name="backButton"` 보존
- [x] GradientBackgroundNode `static func threeStop(size:topColor:midColor:bottomColor:)` 추가, 기존 `init(size:topColor:bottomColor:)` 보존
- [x] 신규 노드 3종 인스턴스화 0건 (`grep` 결과 0건 — Sprint 2 대기)

### 가독성 & UX (15%)
- [x] 컴파일 에러 가능성: 모든 토큰·상수·시그니처가 명확히 정의됨. ttf 미존재 시 SKLabelNode가 시스템 폰트로 자동 fallback (SPEC §주의사항).
- [x] StartScene 시각 결과 보존 — `GradientBackgroundNode(size:topColor:bottomColor:)` 호출이 그대로(2-stop), `MusicNoteEmitter` / `GlowingTitle` 등 미변경.
- [x] 신규 노드 3종은 호출자 0이라 디버그 호출 시에도 init 코드만 실행되며 크래시 가능 지점 없음 (강제 언래핑 0, optional 처리 안전).

---

## Swift / SpriteKit 패턴 준수

- 강제 언래핑 미사용: 준수 (확인: `CIFilter(name:)` 옵셔널 결과를 `SKEffectNode.filter` (`CIFilter?` 타입)에 직접 대입)
- guard let 옵셔런 처리: 준수 (DarkContextChipNode `if let badgeText`, `if let bShape, let bLabel`)
- MARK 섹션 구분: 준수
- GameConfig 상수 사용: 준수 — 모든 수치 토큰화
- weak self 캡처: 해당 없음 (SKAction 클로저 0건)
- didMove(to:)에서 초기화: 해당 없음 (씬 변경 0)
- dt 기반 이동: 해당 없음
- SKAction 스폰 패턴: 해당 없음
- 충돌 후 노드 즉시 삭제 없음: 해당 없음
- HUD 노드 분리: 해당 없음

---

## 빌드 상태

- 예상 빌드 에러: 없음
  - 모든 토큰 정의 ColorTokens.swift에 존재
  - 모든 GameConfig 상수 정의 GameConfig.swift에 존재
  - GlassPillNode는 `import CoreImage` 명시 — `CIFilter` 해상 OK
  - PBXFileReference + PBXBuildFile + PBXGroup(Nodes) + PBXSourcesBuildPhase(iOS) 4섹션 모두 신규 3개 UUID 추가
  - 또한 PBXFileSystemSynchronizedRootGroup이 GanhoMusic Shared 폴더를 자동 동기화하므로 이중 안전망
- 주의 필요 경고: 없음
  - 신규 노드 3종 호출자 0 → "unused" 경고 가능성이 있으나 Swift는 클래스 정의 자체에 unused 경고 없음

---

## 범위 외 미구현 항목

- ttf 파일 추가(Jua-Regular / GowunDodum-Regular / NotoSansKR-Bold): **사용자 후속 작업으로 분리** (SPEC §OPEN_QUESTION Q1)
- Info.plist UIAppFonts 편집: 위와 동일 — 사용자 후속 작업
- 신규 노드 3종 호출자 추가: **의도적으로 0** — Sprint 2 메뉴 씬 리스킨 작업에서 호출자 도입
- 기존 5개 씬 시각 변경: **의도적으로 0** — Sprint 1 범위 OUT (SPEC §Sprint 1 범위 계약 OUT)

---

## pbxproj 등록 검증

수정한 4섹션:
1. PBXBuildFile section: `A1C0F1B0...00000056/57/58` 추가
2. PBXFileReference section: `A1C0F1A0...00000056/57/58` 추가
3. PBXGroup section (Nodes): 3개 fileRef 추가
4. PBXSourcesBuildPhase section (iOS): 3개 buildFile 추가

추가 안전망: `PBXFileSystemSynchronizedRootGroup` (`C75D46202FA627C10016BB86 /* GanhoMusic Shared */`)가 폴더 전체를 자동 동기화하며, `PBXFileSystemSynchronizedBuildFileExceptionSet`의 `membershipExceptions`에 신규 파일이 포함되지 않으므로 자동으로 타겟에 멤버십 부여됨. 즉 명시적 등록 + 자동 동기화의 이중 보장.

---

**작성**: Generator Agent (Sprint 1, 1회차)
**다음 단계**: Evaluator가 SPEC §검증 체크리스트로 채점
