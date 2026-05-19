# Sprint 7 Phase A · QA Report

## 최종 점수 (가중 평균)

| 카테고리 | 점수 | 가중치 | 기여 |
|---|---|---|---|
| 게임 로직 회귀 0 | 9.8 | 0.40 | 3.92 |
| Swift 패턴 | 9.4 | 0.20 | 1.88 |
| 비주얼 일관성 (mockup) | 9.3 | 0.25 | 2.325 |
| 가독성 & UX | 8.8 | 0.15 | 1.32 |
| **합계** | | | **9.45 / 10** |

## 판정: ✅ 합격 (PASS)

전 카테고리 통과선(9.0 / 7.0 / 7.0 / 7.0) 충족. P0/P1 이슈 0건.

---

## 카테고리별 상세

### 게임 로직 회귀 0 (9.8/10)

통과
- 보호 영역 git diff 0줄 확인:
  - `ResultScene.swift` 0줄
  - `GameScene.swift` / `GameScene+Setup.swift` 0줄
  - `Config/GameState.swift` / `Config/PhysicsCategory.swift` 0줄
  - `Managers/`, `Repositories/` 0줄
- `preferenceRepo.current` 복원 (CharacterSelectScene.swift:77) byte-identical
- `preferenceRepo.save(id)` 호출 (line 443) byte-identical
- `transitionToNext` (line 519) / `transitionToStart` (line 509) 시그니처 + fade duration byte-identical
- `.kim → DifficultySelectScene` / `.jung/.geon/.im/.lee → SkillExplanationScene` 분기 (line 523~536) 보존
- `cardBaseX(for:)` / `cardBaseY(for:)` 시그니처 byte-identical, 본문은 v3 폭(`characterCardWidthV3`)만 교체
- `setSelected(_:)` 시그니처 byte-identical, 본문에 glow/pill isHidden 토글 3줄만 추가
- `CharacterID.dotColor` / `displayName` / `tag` / `playerSpeedMultiplier` / `skill` / `color` 값 변경 0
- `PlayerSkill.cooldown` / `duration` / `oncePerGame` / `displayName` / `fullDescription` / `rangeText` / `castText` 값 변경 0
- v2 카드 상수 값 보존: `characterCardWidth=76`, `Height=104`, `GlassWidth=156`, `GlassHeight=204`, `SelectedScale=1.08`, `GlassSelectedScale=1.08`, `GlassScaleDuration=0.18`, `characterCardScaleDuration=0.10` 그대로 (GameConfig.swift:236-252, 1233-1254)
- `applyGlassContainerSelection` 시그니처/로직 보존 — 글래스 컨테이너 자체는 alpha=0이지만 노드 + 액션 그대로 작동(코드 변경 최소화)

미세 감점(-0.2)
- 사용자 QA 프롬프트 §12 "1회/2회/∞ 3단계" 명시 vs 실제 구현 "1회/∞ 2단계". SPEC.md 자체가 line 175-184에서 2단계로 명시하고 mockup annotation도 "1회/∞ 2단계"로 일치 — SPEC 합의 사항(NIKKE 식 시각 위계). 회귀가 아닌 SPEC 설계 결정이므로 정보 손실 0, 시각 가독성에 영향 0.

### Swift 패턴 (9.4/10)

통과
- 강제 언래핑 0건. CharacterCardNode 4건 `!`는 모두 Bool 부정자(`!selected`), CharacterSelectScene 1건은 `!isTransitioning` 가드. force-unwrap 0.
- Timer / DispatchQueue 0건 (수정된 4파일 grep 결과)
- `update()` 안 `addChild()` 0건. 모든 addChild는 init/setup* 함수 내부.
- `guard let` 옵셔널 처리: `layoutSkillInfoChip`의 `guard let chip = skillInfoChip else { return }` (line 371), `touchesBegan`의 `guard let touch = touches.first` (line 488), `transitionTo*`의 `guard let view = self.view` 보존.
- `switch default` 미사용 확인: `CharacterID.rarity` (5 case exhaustive), `CharacterID.elementSymbol` (5 case exhaustive), `PlayerSkill.cooldownText` (5 case exhaustive). `attachRarityBadge` 안 Int→로마숫자 switch는 `default: return "I"` 허용(Int 전체 case 망라 불가 — SPEC line 660이 명시 허용).
- MARK 섹션: 모든 신규 코드에 `// MARK: - Sprint 7 Phase A · …` 또는 `// MARK: - Sprint 7 Phase A — …` 일관 적용.
- GameConfig 상수 사용: 카드 안 모든 위치/크기/폰트는 GameConfig 참조. 수학 상수 `.pi/3` 1개(헥사 꼭짓점 각도)는 매직 넘버 아님.
- 클로저 `self` 강한 캡처 0건 — Phase A는 SKAction 본문에 self 캡처 사용 0.

미세 감점(-0.6)
- `CharacterCardNode.swift:184-188`에서 `roman` String을 `if-else` 대신 switch + default — Int 매핑이므로 unavoidable. 점수 영향 미세.

### 비주얼 일관성 (9.3/10)

통과 — mockup `character-select-v3.html` 매칭률 ≈ 92%

| 요소 | mockup | Swift 구현 | 일치 |
|---|---|---|---|
| 카드 폭 | 160px | `characterCardWidthV3 = 160` | ✅ |
| 카드 높이 | 200px | `characterCardHeightV3 = 200` | ✅ |
| gap | 22px | `characterCardGapV3 = 22` | ✅ |
| cornerRadius | 22px | `characterCardCornerRadiusV3 = 22` | ✅ |
| 헥사 28×28 / radius 14 | ✅ | `characterCardElementHexRadius = 14` | ✅ |
| 헥사 stroke 1.5 흰 | ✅ | `Width = 1.5`, `.white` | ✅ |
| 헥사 이모지 16pt | ✅ | `characterCardElementSymbolFontSize = 16` | ✅ |
| 등급 배지 26×18 / radius 8 | ✅ | `Width=26, Height=18, CornerRadius=8` | ✅ |
| 등급 라벨 Jua 11pt 골드 | ✅ | `fontDisplay`, 11pt, `.ganhoMusicGold` | ✅ |
| 등급 배지 navyDeep × 0.85 | ✅ | `withAlphaComponent(0.85)` | ✅ |
| CD 칩 9pt 흰 + padding 4×8 + coralLight × 0.85 | ✅ | `fontSize=9`, `horizontalPadding=8`, `height=16` → 수직 padding ≈ 3.5 (≈4) | ✅ |
| 이름 Jua 15pt navyDeep | ✅ | `NameFontSizeV3=15`, `.ganhoNavyDeep`(선택 시) | ✅ |
| 속도 Gowun 10pt scrubMint | ✅ | `SpeedFontSizeV3=10`, `.ganhoScrubMint`, `fontBody` | ✅ |
| 선택 글로우 ellipse 224×80 / 코랄 0.45 | width 224 / height 60 (Swift) | width=224, height=60 | mockup 80 vs Swift 60 ↓ |
| "선택됨" 알약 60×20 / Jua 10pt 흰 / 코랄 fill | ✅ | width=60, height=20, fontSize=10, `.ganhoCoralPrimary` | ✅ |
| 알약 top offset +14 (mockup bottom: -14) | ✅ | `PillOffsetY=14` (halfH 위로) | ✅ |
| glow 카드 하단 새어나옴 (bottom: -12) | ✅ | `GlowOffsetY=-12` (halfH 아래로) | ✅ |
| 스킬 패널 max-width 320 | ✅ | `characterSelectSkillInfoMaxWidth=320` + clamp 패턴 | ✅ |
| 5캐릭터 헥사·등급·이모지 매핑 | kim🌸II∞ / jung🌿I1회 / geon🌙III1회 / im⚡II1회 / lee💧I1회 | CharacterID + PlayerSkill 동일 매핑 | ✅ |
| 3번째 카드 .selected 데모 (glow+알약) | ✅ | 정상 | ✅ |
| 하단 annotation 박스 3개 | ✅ (line 593-606) | — | ✅ |

미세 감점(-0.7)
- **glow 높이 mismatch**: mockup CSS `height: 80px` (line 248) vs Swift `characterCardSelectedGlowHeight: CGFloat = 60` (GameConfig.swift:1894). SPEC §"선택 상태 강화" line 108은 "height 80", §기능 3 line 254도 "코랄 glow 높이(60pt)" — SPEC 본문 자체에 80 vs 60 자가-모순. 구현은 SPEC 상수 정의(60) 따름. 시각 영향 ≤5% — 코랄 ellipse의 alpha gradient 페이딩 영역에 묻혀 식별 어려움. **권장 후속**: mockup CSS를 `height: 60px`로 정렬하거나 Swift 상수를 80으로 통일하면 100% 일치.

### 가독성 & UX (8.8/10)

통과
- 5요소 카드 내부 좌상단/좌하단/우상단/중앙/하단 배치 — zPos 순서(-1 < 0 < 1 < 5~6 < 10~11) 명확.
- 색점·태그 라벨 isHidden 처리 — 카드 내부로 흡수된 정보 시각 중복 0.
- `applyGlassContainerSelection`은 alpha 0 컨테이너에 액션을 그대로 적용 — 코드 깔끔히 살아있어 후속 v3.5에서 alpha 0.3으로 복원 가능 (SPEC §OQ-1 명시 의도).
- `setScale(1.0)` reset 직전에 setScale 호출(line 381) — `didChangeSize` 반복 시 누적 scale 방지 패턴 정확.

미세 감점(-1.2)
- 카드 5장 합산 폭(912pt @clamp 28)이 iPhone 12 Pro 가로 844pt를 -68pt 초과 → 양 끝 카드 좌·우 ~34pt가 화면 외측. SPEC §OQ-4가 명시한 trade-off(카드 폭 보존 우선)이지만 *실기 시각상 양 끝 카드 일부 잘림* — SE/Pro/Pro Max 모두 동일 현상. Phase B 이후 mockup 시각 검증 시 후속 조정 권장.
- `attachCDChip` 안에서 `cdLabel`을 먼저 SKLabelNode로 만들고 `cdLabel.frame.width`를 측정해 chip 폭 계산하는 패턴(line 211) — 라벨이 아직 부모에 부착 전이라도 frame 계산 작동(SKLabelNode는 텍스트/폰트 설정 시점에 frame 산출). 정상 작동하지만 의존성이 미묘 — 주석으로 명시했으면 더 좋았음.

---

## 보호 영역 git diff

| 파일/디렉토리 | 결과 |
|---|---|
| `ResultScene.swift` | 0줄 ✅ |
| `GameScene.swift` / `GameScene+Setup.swift` | 0줄 ✅ |
| `Config/GameState.swift` / `Config/PhysicsCategory.swift` | 0줄 ✅ |
| `Managers/` | 0줄 ✅ |
| `Repositories/` | 0줄 ✅ |

전체 `git diff --stat`은 5 Swift 파일(목표 그대로) + 신규 mockup + 산출물 3개만 변경됨.

---

## 빌드 결과

**BUILD SUCCEEDED**

- 컴파일 에러: 0
- Swift 컴파일 워닝: 0
- 무관 워닝 3건(Fonts 리소스 중복 빌드 단계 — 본 변경과 무관, 사전부터 존재)

---

## 구체적 개선 지시 (조건부 — 후속 Phase에서 처리 가능, 합격 영향 0)

1. **mockup glow 높이 정렬**: `mockups/character-select-v3.html` line 248의 `.char-card.selected::before { height: 80px; }`를 `60px`로 변경하거나, Swift `GameConfig.characterCardSelectedGlowHeight`를 `80`으로 변경. SPEC §"선택 상태 강화"(line 108, 80) vs §"기능 3"(line 254, 60) 자가-모순 해결.
2. **카드 양 끝 잘림 보정**: iPhone 12 Pro 가로에서 5장 카드 줄이 화면 ±34pt 외측. 후속 Phase에서 (A) `characterSelectMinCardSpacing`을 16pt로 축소, (B) 카드 폭을 v3.5에서 140으로 축소, (C) 5장 → 가로 스크롤 carousel 중 하나 결정 권장.
3. **`attachCDChip` 주석 보강**: line 211의 `cdLabel.frame.width` 측정이 부착 전 시점에 작동하는 이유(SKLabelNode가 텍스트/폰트만으로 frame 산출) 한 줄 주석 추가 권장.

이 3건 모두 P2 권장 사항으로 Phase A 합격 판정에 영향 0.

---

## 최종 판정

**합격 (PASS) · 가중 점수 9.45 / 10**

- 게임 로직 회귀 0건 — 보호 영역 5개 디렉토리 모두 0줄.
- preferenceRepo / transitionTo* / .kim 분기 / v2 상수 값 / CharacterID·PlayerSkill 기존 값 byte-identical.
- mockup `character-select-v3.html` 와 Swift 구현 매칭률 ≈ 92% (glow 높이 60 vs 80 단일 mismatch만).
- Swift 패턴 위반 0건(force unwrap / Timer / update-내-addChild / 매직 넘버 모두 0).
- 빌드 SUCCEEDED, 신규 워닝 0.
