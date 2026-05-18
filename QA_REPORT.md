# QA 검수 보고서 — Phase 8-3 (원본 디자인 토큰 + TitleScene 동일화)

## SPEC 기능 검증

- **[PASS] 기능 1 — ColorTokens 14색**: ColorTokens.swift L153-186에 `// MARK: - Game UI Tokens (Phase 8-3)` 섹션 신설, 14개 토큰 모두 원본 CSS L4-23 + L335-338과 byte-equal.
- **[PASS] 기능 2 — GameConfig 17 layout 상수**: GameConfig.swift L640-678에 `// MARK: - Game UI Tokens (Phase 8-3)` 섹션 신설, SPEC 명시 16개 + uiRadiusPill = 999 (캡슐 명시용 동등 토큰) 포함.
- **[PASS] 기능 3 — TitleScene 패널 도입**: didMove(to:)에서 setupLabels() 직전 setupOverlayPanel() 호출(L51), bg SKSpriteNode color=.ganhoUIOverlayBg + size=scene size + zPosition -10, panel SKShapeNode rectOf 480×480 cornerRadius=uiRadius + fillColor .ganhoUIBgCard + strokeColor .ganhoUIBorder + lineWidth uiPanelLineWidth + zPosition -5. SPEC §"기능 3" 라인 그대로 재현.
- **[PASS] 기능 4 — CharacterCardNode 시각 토큰**: border SKShapeNode(cornerRadius uiRadiusSm) 자식 추가, background.color 기본 .ganhoUIBgCard, setSelected에서 .ganhoUIBrand12/.ganhoUIBrand60/.ganhoUIBrandLight ↔ .ganhoUIBgCard/.ganhoUIBorder/.ganhoUITextMuted 분기. init(id:) / setSelected(_:) 시그니처 보존.
- **[PASS] 기능 5 — DifficultyCardNode 캡슐**: background 타입 SKSpriteNode → SKShapeNode, cornerRadius = cardSize.height / 2 (캡슐), fillColor 기본 .clear, setSelected에서 fillColor id.color.withAlphaComponent(0.2) + strokeColor id.color + nameLabel.fontColor .ganhoUIText 동적 교체. init(id:) 시그니처 보존.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **경고**: 0건 (`grep -E "warning:|error:" | grep -v appintents` → 비어 있음)
- **에러**: 0건
- **비고**: 사용자 요청 destination 'iPhone 15'은 본 환경에 없음 → 동등 환경 iPhone 17(iOS 26.5) 시뮬레이터로 검증.

## 정적 검사

- **강제 언래핑(`!`)**: 0건 — 수정 5개 파일 모두 검색, `guard !isTransitioning`(boolean 부정) 외 force unwrap 없음. `init(coder:) fatalError` 1건은 표준 Swift 보일러플레이트(런타임 도달 0).
- **Timer / DispatchQueue**: 0건 — `grep -nE "Timer\.|DispatchQueue"` 결과 비어 있음.
- **매직 넘버**: 1건(panelHeight 480) — TitleScene.swift L82 `panelHeight: CGFloat = 480` 로컬 상수. SPEC §"기능 3" 본문에서 명시 허용("세로는 컨텐츠 기준 동적 — 임시 고정값 480"). P2 권장 — 다음 sprint에서 GameConfig.uiPanelCharacterMaxHeight로 승격 권장.

## CSS 변수 ↔ Swift 토큰 byte-equal 검증

| CSS 변수 (원본) | Swift 토큰 | hex / 알파 | 결과 |
|---|---|---|---|
| --bg | ganhoUIBg | #0f0e15 | PASS |
| --bg-dark | ganhoUIBgDark | #09080f | PASS |
| --bg-card rgba(23,21,30,0.82) | ganhoUIBgCard | #17151e α 0.82 | PASS |
| --brand | ganhoUIBrand | #c4847a | PASS |
| --brand-light | ganhoUIBrandLight | #d4a49c | PASS |
| --brand-12 | ganhoUIBrand12 | #c4847a α 0.12 | PASS |
| --brand-20 | ganhoUIBrand20 | #c4847a α 0.20 | PASS |
| --brand-40 | ganhoUIBrand40 | #c4847a α 0.40 | PASS |
| --brand-60 | ganhoUIBrand60 | #c4847a α 0.60 | PASS |
| --text | ganhoUIText | #eeeeee | PASS |
| --text-muted | ganhoUITextMuted | #aaaaaa | PASS |
| --text-dim | ganhoUITextDim | #555555 | PASS |
| --border rgba(255,255,255,0.07) | ganhoUIBorder | white α 0.07 | PASS |
| .game-overlay 배경 rgba(9,8,15,0.78) | ganhoUIOverlayBg | #09080f α 0.78 | PASS |

**14/14 byte-equal**.

## GameConfig UI Layout 상수 검증

| 토큰 | 값 | 원본 CSS 매핑 | 결과 |
|---|---|---|---|
| uiRadius | 10 | --radius 10px | PASS |
| uiRadiusSm | 6 | --radius-sm 6px | PASS |
| uiRadiusPill | 999 | border-radius:999px(.game-difficulty__btn) | PASS |
| uiPanelMaxWidth | 360 | .game-overlay__panel max-width:360px | PASS |
| uiPanelCharacterMaxWidth | 480 | .game-overlay__panel--character max-width:480px | PASS |
| uiPanelPaddingH | 20 | padding:22px 20px | PASS |
| uiPanelPaddingV | 22 | padding:22px 20px | PASS |
| uiPanelGap | 14 | gap:14px | PASS |
| uiTitleFontSize | 22 | .game-overlay__title 22px | PASS |
| uiBodyFontSize | 12 | .game-overlay__desc 12px | PASS |
| uiHintFontSize | 11 | .game-overlay__hint 11px | PASS |
| uiHudValueFontSize | 22 | b 22px 통계 값 | PASS |
| uiHudLabelFontSize | 10 | span 10px 통계 라벨 | PASS |
| uiCardNameFontSize | 12 | .game-character-card__name 12px | PASS |
| uiCardTagFontSize | 10 | .game-character-card__tag 10px | PASS |
| uiCardBestFontSize | 10 | .game-character-card__best 10px | PASS |
| uiPanelLineWidth | 1 | border:1px solid var(--border) | PASS |

**17/17 일치**.

## 회귀 0 영역 검증

`git diff --name-only` 결과 — Swift 변경 5개 파일만:
```
GanhoMusic Shared/Config/ColorTokens.swift           +34
GanhoMusic Shared/Config/GameConfig.swift            +39
GanhoMusic Shared/Nodes/CharacterCardNode.swift     ±35
GanhoMusic Shared/Nodes/DifficultyCardNode.swift    ±34
GanhoMusic Shared/Scenes/TitleScene.swift            +29
```

- [PASS] ResultScene / GameScene / GameScene+Setup 미접촉
- [PASS] PixelSpriteRenderer / PlayerNode / EnemyNode 미접촉
- [PASS] 자가 소멸 11호 (Airplane/Airforce/Bomb/Sparkle/HitFlash/ComboPopup/ComboBreak/Countdown/ScorePopup/CutsceneOverlay/DiplomaOverlay) 미접촉
- [PASS] 모든 Systems/Managers/Repositories/Models/Protocols 미접촉
- [PASS] PhysicsCategory / GameState 미접촉
- [PASS] iOS·tvOS·macOS 진입점 미접촉
- [PASS] 신규 파일 0개 / pbxproj 변경 0건 (`git diff --name-only`에 pbxproj 부재)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 1건 |

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

없음.

## P2 — 권장 사항

### 1. panelHeight 480 매직 넘버 — GameConfig 승격 권장
- **파일**: `GanhoMusic/GanhoMusic Shared/Scenes/TitleScene.swift:82`
- **위반 규칙**: swift-rules.md 매직 넘버 금지(완화) — SPEC §"기능 3" 본문에서 "임시 고정값"으로 명시 허용
- **현재 코드**: `let panelHeight: CGFloat = 480   // 컨텐츠 기준 임시 고정 — TitleScene 라벨/카드 총 높이 커버`
- **수정 제안 (다음 sprint)**: `GameConfig.swift`에 `static let uiPanelCharacterMaxHeight: CGFloat = 480` 추가 후 참조.
- **본 sprint 평가**: SPEC 본문 명시 + 주석 명시 — 점수 감점 없음. 다음 sprint 폴리싱 항목.

## 통과 항목

- ColorTokens 14색 — CSS L4-23 + L335-338과 byte-equal
- GameConfig 17 UI layout 상수 — game.css L335-740와 1:1 매핑
- TitleScene 패널 — bg(zPos -10) + panel(zPos -5) + 라벨/카드(기본 0+) 위계 충돌 0
- CharacterCardNode — init(id:) / setSelected(_:) 시그니처 보존, border 자식 SKShapeNode 추가 패턴 명확
- DifficultyCardNode — SKShapeNode 캡슐 전환, fill clear + brand stroke 톤 원본 일치
- 빌드 PASS, 경고 0건, 정적 검사(force unwrap / Timer / DispatchQueue) 0건
- 회귀 0 영역 100% 미접촉 (다른 28개 노드 + 6개 씬 + 시스템/매니저/리포지토리 전부)
- MARK 섹션 구분 + 한글 주석 — 모든 변경에 Phase 8-3 라벨 명시
- weak self / dt / SKAction 패턴 — 정적 노드만 추가하여 해당 없음(부적용 PASS)

---

## 채점

### 항목별 점수

- **Swift 패턴 일관성**: 10/10
  - 강제 언래핑 0, Timer/DispatchQueue 0, MARK 섹션 100%, GameConfig 상수 경유 100%, 카드 init 시그니처 보존
- **게임 로직 완성도**: 10/10
  - 상태 전이 미변경 — 시각 토큰만 교체. GameState/PhysicsCategory 미접촉. 라벨/카드 layout 7-5 결과 보존.
- **성능 & 안정성**: 10/10
  - SKShapeNode 2개(bg는 SKSpriteNode) 추가 — 정적 노드, 매 프레임 비용 0. 메모리 누수 위험 없음. PhysicsBody 0.
- **기능 완성도**: 10/10
  - SPEC §"기능 1~5" 모두 1:1 구현. 14색 + 17상수 + 패널 + 카드 시각 + 캡슐 — 100% 라인 매핑.

### 가중 점수

| 항목 | 가중 | 점수 | 기여 |
|---|---|---|---|
| Swift 패턴 | 0.25 | 10 | 2.50 |
| 게임 로직 | 0.25 | 10 | 2.50 |
| 성능 & 안정성 | 0.25 | 10 | 2.50 |
| 기능 완성도 | 0.25 | 10 | 2.50 |

**가중 점수**: **10.0/10**

## 최종 판정: **합격**

**판단 근거**:
1. SPEC §"기능 1~5" 5개 항목 모두 PASS (라인-by-라인 매핑 100%).
2. CSS 변수 14개 byte-equal — 디자인 단일 진실 원천 100% 재현.
3. GameConfig 17 layout 상수 byte-equal — game.css L335-740 1:1.
4. 빌드 PASS + 경고 0건 + 정적 검사 0건.
5. 회귀 0 영역 — Swift 5개 파일만 변경, 다른 모든 시스템 미접촉.
6. P0/P1 0건, P2 1건(SPEC 본문 명시 허용 — 점수 비반영).

**관대 검토**: 토큰 14개 + 상수 17개 + 5개 파일 변경 라인 모두 SPEC과 byte-equal 확인. SPEC을 *그대로 옮긴* 작업이라 점수가 높지만, 그 자체가 SPEC 요구. 추가 감점 사유 발견 못함. P2 1건은 SPEC §"기능 3"이 "임시 고정값 480" 명시 — 위반 아님.

**다음 sprint 개선 지시** (8-4 또는 후속):
1. `GameConfig.uiPanelCharacterMaxHeight = 480` 토큰 신설 → TitleScene panelHeight 참조로 전환.
2. CharacterCardNode 픽셀 아바타 도입 (SPEC §금지 #5 → 다음 sprint).
3. ResultScene / GameScene HUD / 졸업장 시각 토큰 적용 (SPEC §금지 #2~4).
4. 폰트 패밀리 — Inter / Noto Sans KR 도입 검토(필요 시 fontName 설정).
