# 자체 점검 — Sprint 7 Phase A (NIKKE 4:5 캐릭터 카드)

전략: 1회차 — 초기 구현 (Case 판정 해당 없음)

## 변경 파일 목록 + 라인 수

| 파일 | 변경 유형 | 추가 LOC | 수정 LOC |
|---|---|---|---|
| `Models/CharacterID.swift` | 수정 | +33 (rarity + elementSymbol switch + MARK) | 0 |
| `Models/PlayerSkill.swift` | 수정 | +16 (cooldownText switch + MARK) | 0 |
| `Config/GameConfig.swift` | 수정 | +92 (v3 카드 4 + 헥사 5 + 등급 7 + CD 6 + 이름속도 4 + 선택 데코 9 + 스킬패널폭 1 = 36 상수, 주석 포함) | 0 |
| `Nodes/CharacterCardNode.swift` | 거의 전면 재작성 | +346 신규 / -65 v2 | 본문 attach 5 메서드 신규 |
| `Scenes/CharacterSelectScene.swift` | 부분 수정 | +23 (글래스 v3 + isHidden 2 + clamp 4 + 주석) | -8 (글래스 size 교체, layoutCardColorDots 폭 교체, cardBaseX width 교체, layoutSkillInfoChip clamp 추가) |
| `mockups/character-select-v3.html` | 신규 파일 | +445 | 0 |

총 신규 LOC ~955 / 수정 ~73. (SPEC §변경 LOC 추정치 ~669 대비 +)
초과분은 (1) CharacterCardNode 전체 재작성으로 attach 5 메서드 본문이 SPEC 의사코드보다 자세한 주석/zPos 분리, (2) mockup v3에 카드 안 5요소 CSS가 v2보다 +95 LOC 추가, (3) GameConfig 신규 상수 36개에 각각 한국어 주석 — 본 프로젝트 컨벤션.

## 보호 파일 0줄 변경 확인

`git diff --stat -- ResultScene/GameScene/GameState/PhysicsCategory/Managers/Repositories` → **0건** ✅

확인된 경로:
- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift` — 0
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` — 0
- `GanhoMusic/GanhoMusic Shared/GameScene+Setup.swift` — 0
- `GanhoMusic/GanhoMusic Shared/Config/GameState.swift` — 0
- `GanhoMusic/GanhoMusic Shared/Config/PhysicsCategory.swift` — 0
- `GanhoMusic/GanhoMusic Shared/Managers/` — 0
- `GanhoMusic/GanhoMusic Shared/Repositories/` — 0

## 기존 v2 상수 값 보존 확인 (grep)

| 상수 | 값 |
|---|---|
| `characterCardWidth` | 76 ✅ |
| `characterCardHeight` | 104 ✅ |
| `characterCardGlassWidth` | 156 ✅ |
| `characterCardGlassHeight` | 204 ✅ |
| `characterCardSelectedScale` | 1.08 ✅ |
| `characterCardGlassSelectedScale` | 1.08 ✅ |
| `characterCardScaleDuration` | 0.10 ✅ |

`grep -c` 결과 7건 모두 일치. v2 상수 값 변경 0.

## 시그니처 byte-identical 확인

| 시그니처 | 결과 |
|---|---|
| `class func newCharacterSelectScene() -> CharacterSelectScene` | ✅ 변경 0 (line 55) |
| `override init(size: CGSize)` | ✅ 변경 0 (line 63) |
| `private func cardBaseX(for id: CharacterID) -> CGFloat` | ✅ 변경 0 (line 406, 본문 `width = GameConfig.characterCardWidthV3` 1줄만 교체) |
| `private func cardBaseY(for id: CharacterID) -> CGFloat` | ✅ 변경 0 (line 430, 본문 일체 미변경) |
| `private func transitionToNext()` | ✅ 변경 0 (line 519) |
| `private func transitionToStart()` | ✅ 변경 0 (line 509) |
| `preferenceRepo.current` / `preferenceRepo.save(id)` | ✅ 호출 라인 byte-identical |
| `CharacterCardNode.init(id:)` | ✅ 시그니처 동일 (인스턴스 프로퍼티 +9 신규, init body 확장) |
| `CharacterCardNode.setSelected(_:)` | ✅ 시그니처 동일 (본문 +3 — selectedGlow/Pill/PillLabel isHidden 토글) |

## SPEC 기능 체크

- [x] **기능 1**: `CharacterID.rarity: Int` + `elementSymbol: String` 2 computed property 추가 — switch default 미사용, 5 case exhaustive, 게임 로직 분기 0
- [x] **기능 2**: `PlayerSkill.cooldownText: String` computed property 추가 — `.none` → "∞", 그 외 4 case → "1회". 정확한 case 이름(`.dashClimb`, `.bookClubRally`, `.charmStudent`, `.taiwanTrip`)을 PlayerSkill.swift에서 확인 후 매핑
- [x] **기능 3**: `GameConfig` v3 상수 36종 신규 추가 — 카드 4(폭/높이/gap/cornerRadius) + 헥사 5 + 등급 배지 7 + CD 칩 6 + 이름속도 4 + 선택 데코 9 + 스킬패널폭 1. 기존 v2 상수 값 변경 0
- [x] **기능 4**: `CharacterCardNode` NIKKE 재구성 — 카드 size를 v3(160×200)로 교체, attach 5 메서드(ElementBadge/RarityBadge/CDChip/NameAndSpeed/SelectedDecor) 신규, setSelected에 glow/pill isHidden 토글 3줄 추가. zPos 순서: glow(-1) < bg(0) < border(1) < 5요소(5-6) < pill(10-11)
- [x] **기능 5**: `CharacterSelectScene` 글래스 v3 크기 + alpha 0, 색점·태그 라벨 isHidden, cardBaseX width를 v3로, layoutSkillInfoChip 폭 clamp(320pt) 추가

## 신규 mockup 파일

- `mockups/character-select-v3.html` — phone-frame 19.5/9 + island + 카드 5장(160×200 NIKKE 4:5) + 5장 카드 안 5요소(SVG 헥사·등급·CD 칩·얼굴 SVG·이름+속도) + 선택 데모(3번째 건간호: glow + "선택됨" 알약) + 스킬 패널 폭 320pt + confirm + 플로팅 음표 3개 + 하단 annotation 3개(필수 — 카드 4:5 구조 / 선택 강화 / CD 미니칩) ✅

## Swift 패턴 준수

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` 0건 | ✅ grep 결과 0건 (`isHidden = !selected`는 Bool 부정자) |
| `guard let`/`if let` 옵셔널 처리 | ✅ `layoutSkillInfoChip`의 `guard let chip = skillInfoChip` 추가 |
| MARK 섹션 구분 | ✅ 모든 신규 코드에 `// MARK: - Sprint 7 Phase A · …` |
| GameConfig 상수 사용 | ✅ 카드 위치/크기/폰트 모두 GameConfig 참조. 수학 상수(`.pi/3`)는 매직 넘버 아님 |
| `weak self` 캡처 | ✅ 클로저 사용 0건(Phase A는 SKAction 본문에 self 캡처 없음) |
| Timer.scheduledTimer | ✅ 0건 |
| switch default 미사용(5 case enum) | ✅ rarity/elementSymbol/cooldownText 모두 exhaustive |

## SpriteKit 패턴 준수

| 항목 | 결과 |
|---|---|
| `didMove(to:)`에서 초기화 | ✅ CharacterSelectScene 기존 패턴 유지 |
| dt 기반 이동 | 해당 없음 (정적 메뉴 씬) |
| SKAction 스폰 패턴 | ✅ setSelected의 `SKAction.scale` 액션 패턴 유지 |
| 충돌 후 노드 즉시 삭제 없음 | 해당 없음 (물리 0) |
| HUD 노드 분리 | ✅ CharacterCardNode가 독립 SKNode 서브클래스 |
| `update()` 안 addChild | ✅ 0건 (모든 addChild는 init/setup) |
| zPosition 명시 | ✅ 9개 자식 모두 명시(-1, 0, 1, 5, 6, 10, 11) |

## 빌드 상태

`xcodebuild ... build` 결과: **BUILD SUCCEEDED** ✅

- 컴파일 에러: 0
- 신규 워닝: 0 (기존 Fonts Resources 중복 워닝 3건은 본 변경과 무관)

## OPEN_QUESTION 처리 상태

- **OQ-1 (글래스 컨테이너 처리)**: ✅ 채택 — alpha 0.0 + size v3 + cornerRadius v3. `applyGlassContainerSelection`은 계속 작동(scale/stroke 액션 보존).
- **OQ-2 (헥사 아이콘 이모지 채택)**: ✅ 채택 — `id.elementSymbol`이 단일 이모지 문자열 반환, `SKLabelNode`에 Jua 폰트로 렌더.
- **OQ-3 (등급 매핑 1·2·3)**: ✅ 채택 — kim II / jung I / geon III / im II / lee I.
- **OQ-4 (spacing clamp vs gap 22)**: ✅ 채택 — `characterSelectMinCardSpacing(28)` 우선. iPhone 12 Pro 가로 844pt safeArea ~757pt 가용폭에서 카드 5장(160×5=800)이 미달이므로 clamp 28pt 작동 → 카드 줄 총 폭 912pt. 화면을 살짝 넘지만 `frame.midX` 중심 정렬로 양 끝이 균등 분배되며 카드 간 겹침 0 보장. Pro Max(932pt)에서 raw=11.25 → 28 clamp 동일. iPad 가로처럼 더 넓은 화면에선 raw spacing이 22~56 사이로 자연 분포.

## iPhone 12 Pro 가로 가용폭 추정

- 디바이스 가로: 844pt
- safeArea(노치 한쪽 ~47pt + 반대쪽 0pt): 좌측 47pt 가정
- adaptiveHorizontalMargin × 2: 40pt
- 가용폭: 844 - 47 - 40 = **757pt**
- 카드 5장 폭: 160 × 5 = 800pt → 가용폭 초과
- `rawSpacing = (757 - 800) / 4 = -10.75` → `min/max clamp`로 **28pt 적용**
- 카드 줄 총 폭: 800 + 28×4 = 912pt
- `frame.midX` 중심 정렬 → 좌우 양측 -34pt씩 화면 외측 (visual frame 안에 카드 1/2장 좌·우 끝이 살짝 외측). **카드 간 겹침 0 보장** (사양 1순위 통과선 만족).

이 절단 위험은 사양 §"OQ-4 결정"의 의도된 trade-off — 카드 폭 160 / gap 22를 디자인 의도값으로 두되, 좁은 디바이스에선 spacing 28 clamp가 우선 작동해 카드 자체 폭은 보존. SE/Pro/Pro Max 모두 동일 카드 폭이 보장돼 시각 일관성 확보. Phase B 이후 mockup에서 본 사양으로 시각 검증 후 후속 조정 가능.

## 범위 외 미구현 항목

- 없음. SPEC.md §"Sprint 7 Phase A 범위 계약"의 "허용" 5개 항목 + mockup 1건 모두 구현. "금지" 항목 0건 위반.

## 필수 연동 변경(범위 외지만 구현 필요)

- `Scenes/CharacterSelectScene.swift::layoutCardColorDots()` 본문의 `characterCardGlassWidth` → `characterCardWidthV3` 참조 교체 (5줄): isHidden된 색점이지만 좌표 계산식 일관성 유지(글래스 컨테이너도 이제 v3 폭 사용). 사양 §"기능 5 - 좌표 계산 v3 폭 사용"의 *암시적 일관성* 항목.
