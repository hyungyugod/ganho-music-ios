# QA 검수 보고서 — Sprint 1 (디자인 리뉴얼 인프라)

**검수일**: 2026-05-19
**검수자**: Evaluator Agent
**대상**: 디자인 리뉴얼 Sprint 1 — 토큰/폰트/노드 인프라 (시각 변화 0)

---

## SPEC 8개 기능 검증

| # | 기능 | 결과 | 근거 |
|---|---|---|---|
| 1 | ColorTokens v2 토큰 16개 추가 | PASS | `ColorTokens.swift:231-260`, SPEC §3.1 16개 모두 일치, 기존 라인 변경 0 (`git diff` `-` 0줄) |
| 2 | GameConfig 폰트 3개 + 컴포넌트 상수 | PASS | `GameConfig.swift:1108-1167`, `fontDisplay/fontBody/fontNumeric` 3개 + GlassPill/AccentLine/DarkContextChip/PrimaryButton 그림자·화살표 상수 모두 토큰화 |
| 3 | GlassPillNode.swift 신규 | PASS | `init(text: String, size: CGSize)` 시그니처, `name="glassPill"`, blurEffect+shouldRasterize, `import CoreImage` 명시 |
| 4 | AccentLineNode.swift 신규 | PASS | `override init()` 시그니처, `cornerWidth=height/2` 라운드 캡, `fillColor=.ganhoCoralPrimary` |
| 5 | DarkContextChipNode.swift 신규 | PASS | `init(label: String, badge: String? = nil)` 시그니처, 옵셔널 뱃지 안전 처리 (`if let bShape, let bLabel`) |
| 6 | PrimaryButtonNode 코랄 v2 리스타일 | PASS | `init(text:)`/`name="primaryButton"`/`zPosition=100` 보존, 그림자·화살표·Jua 폰트 v2 교체 |
| 7 | BackButtonNode GlassPill 톤 리스타일 | PASS | `init(text:)`/`name="backButton"`/`zPosition=100` 보존, white α=0.55/0.25 + navyDeep + Jua 톤 |
| 8 | GradientBackgroundNode 3-stop 옵션 추가 | PASS | 기존 `init(size:topColor:bottomColor:)` 보존, `static func threeStop(...)` 추가 (texture 교체 방식 A), guard let fallback |

---

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **에러**: 0
- **경고**: 사용자 사전 확인(경고만, 에러 0) → QA 영향 없음

---

## Sprint 1 불변 계약 검증 (SPEC §불변 계약 표)

| 항목 | 상태 | 검증 명령/근거 |
|---|---|---|
| `PrimaryButtonNode.init(text:)` 시그니처 | 보존 | diff: `init(text: String)` 단일 시그니처 유지 |
| `BackButtonNode.init(text:)` 시그니처 | 보존 | diff: `init(text: String)` 단일 |
| `PrimaryButtonNode.name == "primaryButton"` | 보존 | diff: `name = "primaryButton"` 그대로 |
| `BackButtonNode.name == "backButton"` | 보존 | diff: `name = "backButton"` 그대로 |
| `GradientBackgroundNode.init(size:topColor:bottomColor:)` | 보존 | diff: 기존 init 한 줄도 안 만짐, threeStop은 *추가* |
| `GradientBackgroundNode.name == "gradientBackground"` | 보존 | diff에서 name/zPosition 라인 변경 0 |
| 기존 `ColorTokens` hex 값 | 0 변경 | `git diff ColorTokens.swift` `-` 라인 0 (순수 추가) |
| `GameConfig` 게임 로직 상수 | 0 변경 | `git diff GameConfig.swift` `-` 라인 0 (순수 추가). scorePerNote, comboWindow, projectileSpeed, tileSize, gameDuration 모두 그대로 |
| `Info.plist` | 0 변경 | `git status` Info.plist 없음 |
| 기존 5개 씬 파일 | 0 변경 | `git diff "GanhoMusic Shared/Scenes/"` 출력 빈 줄 — 한 줄도 안 만짐 |
| `Systems/` 디렉터리 | 0 변경 | `git diff "GanhoMusic Shared/Systems/"` 빈 출력 |
| 새 노드 3종 호출자 0 | 충족 | `grep -rn "GlassPillNode(\|AccentLineNode(\|DarkContextChipNode(" "GanhoMusic Shared/"` exit 1 (0건) |

**12개 불변 계약 모두 충족.**

---

## Swift 패턴 검증

| 항목 | 결과 | 근거 |
|---|---|---|
| 강제 언래핑 `!` 신규 0건 | PASS | `grep '!'` (`!=`/주석 제외) 신규 파일 3개 + diff 4개에서 0건. CIFilter는 `SKEffectNode.filter` (`CIFilter?`)에 직접 대입해 가드 불필요 |
| `Timer.scheduledTimer` 신규 0건 | PASS | `git diff` `+` 라인에서 `Timer.` 0건 |
| `DispatchQueue` 신규 0건 | PASS | `git diff` `+` 라인에서 `DispatchQueue` 0건 |
| 매직 넘버 0건 | PASS | 모든 수치 GameConfig 상수 참조. PrimaryButton의 `cornerRadius = buttonSize.height / 2`는 *수학적 파생값*이므로 매직 넘버 아님 |
| MARK 섹션 구조 | PASS | 신규 3개 노드 + 수정된 2개 버튼 모두 `// MARK: - Properties` / `// MARK: - Init` / `// MARK: - Configure` 일관 |
| `final class` 사용 | PASS | GlassPillNode, AccentLineNode, DarkContextChipNode 모두 `final class` |
| `import` 필수 | PASS | GlassPillNode `import SpriteKit` + `import CoreImage` 명시. AccentLine/DarkContextChip는 SpriteKit만 |
| `guard let` / `if let` 옵셔널 처리 | PASS | DarkContextChipNode `if let badgeText`, `if let bShape, let bLabel`. GradientBackgroundNode threeStop의 `guard let gradient ... else { fallback; return }` |
| `required init?(coder:) fatalError` | PASS | 3개 신규 노드 + 2개 수정 버튼 모두 일관 |

---

## pbxproj 정합성 검증

4섹션 모두 신규 3개 UUID(`A1C0F1A0...000056/57/58`, `A1C0F1B0...000056/57/58`) 추가:
1. PBXBuildFile: 3건 추가 (`project.pbxproj:72-74`)
2. PBXFileReference: 3건 추가 (`project.pbxproj:140-142`)
3. PBXGroup Nodes: 3건 추가 (`project.pbxproj:304-306`)
4. PBXSourcesBuildPhase (iOS 타겟): 3건 추가 (`project.pbxproj:616-618`)

또한 PBXFileSystemSynchronizedRootGroup이 폴더 자동 동기화 — 이중 안전망. 빌드 통과로 실증.

---

## OPEN_QUESTION 처리 결과

### Q1. 폰트 ttf 파일 추가
- **처리**: SPEC §OPEN_QUESTION Q1에 따라 사용자 후속 작업으로 분리. Evaluator는 GameConfig `fontDisplay/fontBody/fontNumeric` *상수 정의*만 검증 → 모두 추가됨.
- **감점**: 없음.
- **사용자에게 전달할 후속 액션**: SPEC §OPEN_QUESTION Q1 step 1~6 (Google Fonts 다운로드 + Xcode add to target + Info.plist UIAppFonts 편집).

### Q2. PrimaryButton/BackButton "시각 변화 0" 해석
- **처리**: SPEC §9가 우선 — 버튼 내부 시각 v2 교체 OK, init 시그니처/콜백/name 보존이 핵심. 모두 충족.
- **감점**: 없음.

---

## 카테고리별 점수

### 1. 게임 로직 회귀 0 (가중 40%) — **10/10**
- Scenes/ Systems/ git diff 0줄 (실측)
- GameConfig 게임 로직 상수(scorePerNote, comboWindow, projectileSpeed, tileSize, gameDuration) 변경 0줄
- PhysicsCategory / ContactRouter / PlayerSkill / Difficulty / EnemyNode 비대상
- 기존 ColorTokens hex 값 0 변경
- DESIGN_RENEWAL_REQUEST.md §6 (절대 건드림 금지) 12 항목 전부 충족
- **근거**: `git diff --stat`에서 변경된 9개 파일 모두 (1) 인프라 추가 (2) 버튼 2개 내부 시각만 — 호출부 인터페이스 보존

### 2. Swift 패턴 (가중 20%) — **9.5/10**
- 강제 언래핑 0, Timer 0, DispatchQueue 0, 매직 넘버 0
- MARK 구조 일관, final class, guard let / if let 안전, required init? fatalError
- import 필수 항목 명시 (CoreImage)
- **소소한 -0.5 사유**: AccentLineNode가 SKShapeNode를 *상속*해 외부에서 fillColor 등 public 프로퍼티에 쓰기 가능 — 캡슐화 관점에서는 SKNode 컨테이너 패턴(GlassPill/DarkContextChip와 동일)이 더 일관이지만, SPEC §기능 4가 `final class AccentLineNode: SKShapeNode`를 명시 → SPEC 충실 우선이라 감점 아닌 *관찰 사항*. **점수 9.5로 -0.5는 BackButton의 `background.lineWidth = uiPanelLineWidth` 잔존** — SPEC §기능 7은 "GlassPill 톤 흉내"라 lineWidth는 명시되지 않았으나 0이 더 v2 톤에 맞다(PrimaryButton은 lineWidth 0으로 갔음). 다만 `uiPanelLineWidth`도 GameConfig 토큰이라 매직 넘버는 아님 → 정합 trade-off, 감점 미세

### 3. 비주얼 인프라 완전성 (가중 25%) — **10/10**
- v2 토큰 16개 정확 (SPEC §3.1 hex/이름 1:1 일치)
- 폰트 상수 3개 + 컴포넌트 상수 19종(GlassPill 4 + AccentLine 2 + DarkContextChip 7 + PrimaryButton 6) 모두 추가. 심지어 SPEC에 없던 `darkContextChipBadgeHorizontalPadding`, `darkContextChipBadgeVerticalInset`, `primaryButtonArrowCircleAlpha`, `primaryButtonArrowLabelFontSize`까지 토큰화 — *매직 넘버 0 원칙을 더 강화*
- 신규 3종 모두 시그니처/name/zPosition 정확
- PrimaryButton v2 5요소(그림자 + 본 배경 + 화살표 원 + 화살표 라벨 + 본 라벨) 완비, zPosition 계층 명확(-1/0/1/2/2)
- BackButton GlassPill 톤 충실, GlassPillNode 인스턴스 *직접 사용 안 함* (SPEC §주의사항 준수)
- GradientBackgroundNode 3-stop은 designated init 체이닝 우회 패턴 A 정확. guard let fallback (강제 언래핑 0)
- 새 노드 3종 호출자 0 (grep 0건) — Sprint 2 대기 자세 충족

### 4. 가독성 & UX (가중 15%) — **9.5/10**
- 컴파일 에러 0 (xcodebuild BUILD SUCCEEDED)
- 신규 코드 doc-comment 풍부 (`/// - Parameters:` 형식, 한국어 의도 주석)
- pbxproj 4섹션 정합 + PBXFileSystemSynchronizedRootGroup 이중 안전망
- ttf 미존재 시 SKLabelNode 시스템 폰트 fallback — 런타임 크래시 0
- **-0.5 사유**: SPEC §검증 체크리스트 가독성 항목 중 "실행 시 StartScene 시각 결과가 Phase 10-2 결과물과 픽셀 동일"은 정적 검수로 100% 확증 불가 — 호출부 코드 변경 0 + 호출 시그니처 보존으로 추정 PASS, 실기기 시각 확인은 사용자 한 번 더 권장

---

## 가중 평균 계산

| 카테고리 | 점수 | 가중치 | 가중점 |
|---|---|---|---|
| 게임 로직 회귀 0 | 10.0 | 40% | 4.00 |
| Swift 패턴 | 9.5 | 20% | 1.90 |
| 비주얼 인프라 완전성 | 10.0 | 25% | 2.50 |
| 가독성 & UX | 9.5 | 15% | 1.43 |
| **가중 평균** | | | **9.83 / 10** |

---

## 최종 판정: **합격**

- 가중 평균 9.83 ≥ 7.5 (Sprint 1 통과선) → **합격**
- 각 카테고리별 통과선 충족:
  - 게임 로직 회귀 0: 10.0 ≥ 9.0 ✓
  - Swift 패턴: 9.5 ≥ 7.0 ✓
  - 비주얼 인프라 완전성: 10.0 ≥ 7.0 ✓
  - 가독성 & UX: 9.5 ≥ 7.0 ✓

### Sprint 2 진행 가능 여부: **가능**

근거:
1. Sprint 2가 끌어 쓸 인프라(토큰 16개, 폰트 상수 3개, 컴포넌트 상수 19종, 신규 노드 3종, 리스타일 버튼 2종, 3-stop 그라데이션 옵션) 모두 완비
2. 기존 5개 씬 0 회귀 — Sprint 2 메뉴 씬 리팩토링이 깨끗한 베이스에서 시작 가능
3. 빌드 통과 — Sprint 2 첫 시도부터 컴파일 실패 위험 0
4. 호출자 0 가드 충족 — Sprint 2가 신규 노드를 *처음* 인스턴스화할 때 의도된 회귀 0

### 사용자 후속 액션 (Sprint 2 시작 전 선택사항)
1. (선택) ttf 파일 3개를 Google Fonts에서 다운로드 후 Xcode 프로젝트에 add to target
2. (선택) `GanhoMusic iOS/Info.plist`에 `UIAppFonts` 배열 추가
3. (필수 아님 — Sprint 2 이후 한 번에 처리해도 무방)

---

## 통과 항목 요약

- 기존 5개 씬 파일 git diff 0줄 (StartScene/CharacterSelectScene/SkillExplanationScene/GameScene/ResultScene 전부)
- 기존 ColorTokens hex 값 0 변경 (`ganhoBgDeep #1A1B2E` 등 모든 기존 토큰 보존)
- GameConfig 게임 로직 상수 0 변경 (scorePerNote, comboWindow, projectileSpeed, tileSize, gameDuration 등)
- 강제 언래핑 신규 0건, Timer 신규 0건, DispatchQueue 신규 0건, 매직 넘버 신규 0건
- 빌드 BUILD SUCCEEDED
- 신규 3개 노드 호출자 0건 (Sprint 2 대기 자세)
- pbxproj 4섹션 정합 + 자동 동기화 이중 안전망

---

## 개선 지시 (선택 — 합격 결정에는 영향 없음)

Sprint 2 작업 시 참고할 *권장 사항* (점수 영향 0):

1. **AccentLineNode 캡슐화** — SKShapeNode 상속 대신 SKNode 컨테이너 패턴으로 통일하면 GlassPill/DarkContextChip와 일관성↑. 단 SPEC §기능 4가 SKShapeNode 상속을 명시한 상태라 Sprint 1 범위에서는 변경 금지. Sprint 2 호출 단계에서 외부 색 변경 요구가 생기지 않으면 그대로 OK.
2. **BackButton lineWidth** — 현재 `background.lineWidth = uiPanelLineWidth`로 stroke가 살짝 보임. PrimaryButton은 lineWidth=0으로 그림자만 사용. v2 톤 일관성 위해 Sprint 2에서 BackButton stroke를 더 옅게 하거나 lineWidth 0으로 갈지는 시각 비교 후 결정.
3. **신규 노드 미사용 경고 없음 확인 완료** — Swift는 클래스 정의 자체에 unused 경고 없음. 호출자 0이 빌드 경고를 만들지 않는다는 점이 빌드 결과로 실증됨.

---

**검수 완료**: Evaluator Agent, 2026-05-19
**다음 단계**: Sprint 2 (StartScene + CharacterSelectScene + SkillExplanationScene 리스킨) 진행 가능
