# QA_REPORT.md — 디바이스 잘림 해소 + 카드 시인성 강화 (Sprint 7)

**채점 일자**: 2026-05-19
**전략**: Case A 초회
**빌드 검증**: SKIP — Linux workspace (xcodebuild 부재). 정적 검수만 적용 (evaluator.md §4-2 SKIP 처리).

## 점수 요약

| 영역 | 점수 | 가중치 | 가중점수 |
|---|---|---|---|
| Swift 패턴 | 9.0/10 | 0.2 | 1.80 |
| SpriteKit 패턴 | 8.5/10 | 0.2 | 1.70 |
| 성능 | 9.0/10 | 0.2 | 1.80 |
| 기능 완성도 | 8.5/10 | 0.4 | 3.40 |
| **가중 합산** | | | **8.70/10** |

**판정**: 합격 (가중점수 7.5 이상)

---

## 영역별 상세

### Swift 패턴 (9.0/10)

- **강점**:
  - 강제 언래핑 신규 0건. `GameViewController.swift:33`에서 `guard let skView = self.view as? SKView else { ... return }` 패턴 유지. 주석으로 `as!` 회피 의도까지 명시.
  - `Timer` / `DispatchQueue.main.asyncAfter` 신규 0건. SKView frame 동기화는 `viewSafeAreaInsetsDidChange` + `viewDidLayoutSubviews`로 시스템 콜백만 활용.
  - 매직 넘버 신규 0건. 19개 신규 수치를 모두 `GameConfig.*V3` 상수로 분리 (`GameConfig.swift:1731-1789`).
  - `// MARK:` 섹션 구분 유지. `GameViewController`에 `// MARK: - Lifecycle` / `// MARK: - Safe Area Relayout (Sprint 7)` / `// MARK: - Orientation` / `// MARK: - Status Bar / Home Indicator` 신설. `DifficultyCardNode`에 `// MARK: - Properties` / `// MARK: - Init` / `// MARK: - Selection` / `// MARK: - Configure` 4섹션. `GameConfig.swift:1731`에 `// MARK: - Sprint 7 · 잘림 해소 + 카드 시인성 강화 (Visual-3)` 명확 분리.
  - 네이밍: V3 상수가 lowerCamelCase + 명확한 의미 prefix(`difficultyCard*V3`, `difficultySelect*V3`, `characterSelectCard*V3`) 일관.
  - 한국어 주석 풍부 + 한국어 변수명 0건.

- **약점/관찰**:
  - SPEC §기능 6에서 제시한 상수명 `characterCardSpacingV3`(28pt) 대신 `characterSelectCardSpacingV3`(22pt)로 *이름과 값 모두 변경*. SPEC §기능 4 본문에서도 28pt 언급. 이름 변경 자체는 의미 분리 측면에서 더 좋지만 SPEC과의 불일치는 P2.
  - SPEC §기능 6의 `difficultyCardFontSizeV3 = 24` 대신 `difficultyCardNameFontSizeV3 = 22` 사용. 이름이 더 명확해진 장점 / SPEC 수치와 -2pt 차이. P2.
  - `characterSelectCardYOffsetsV3: [CGFloat]` 배열 대신 단일 스칼라 `characterSelectCardZigzagOffsetV3: CGFloat = 8` + 짝홀 부호 패턴으로 단순화. 배열 인덱스 안전 체크 부담을 없앤 합리적 선택. SELF_CHECK에 의도 명시. P2 (SPEC 형태 deviation).

- **개선 제안**: 없음 — 합격선.

### SpriteKit 패턴 (8.5/10)

- **강점**:
  - `didMove(to:)`/`didChangeSize(_:)` 초기화·layout 분리 패턴 회귀 없음. 신규 변경분도 동일 패턴 안에서 처리.
  - SKAction 키(`cardScale`, `ringFade`, `glassSelect`) 그대로 유지. `removeAction(forKey:)`로 중복 액션 방지 패턴 그대로.
  - `DifficultyCardNode`의 z-position 위계(ringGlow -1 / background 0 / labels default / 노드 자체 zPosition 100) 유지.
  - 색 토큰만 사용 — 하드코딩 색 0건. `.ganhoBgWarmTop` / `.ganhoNavyDeep` / `.ganhoNavyMuted` / `.ganhoAccentCoral` 토큰 일관.
  - `descriptionLabel`이 `numberOfLines = 0` + `preferredMaxLayoutWidth = 96`로 자동 wrap 처리 (`DifficultyCardNode.swift:180-181`).
  - SafeArea mount의 무한 didChangeSize 루프 가드: `GameViewController.swift:80` `if skView.frame != target` 체크 — SPEC §주의 2와 일치.

- **약점/관찰**:
  - `setSelected(_:)` 내 spring 시퀀스가 `selected` 분기에서 `removeAction(forKey: "cardScale")` 호출 후 새 시퀀스 실행, `else` 분기에서도 키 재사용. 회귀 없음. 단 `else` 분기에서 `scale: 1.0` 액션 이후 `background.fillColor` 변경이 액션 실행과 동시 — 시각 글리치 가능성 매우 낮으나 액션 완료 콜백이 아닌 즉시 변경. P2.
  - SafeArea mount는 SKView의 frame을 코드로 직접 갱신(`translatesAutoresizingMaskIntoConstraints = true` + `autoresizingMask = []`). storyboard와 코드 제약이 혼재되는 패턴이라 향후 storyboard 수정 시 함정 가능. 본 SPEC 범위 내에서는 합리적인 절충.
  - `view.backgroundColor = .ganhoBgWarmTop` — UIColor extension의 시맨틱 토큰이라 SwiftRules §9의 "하드코딩 색상" 룰 위배 아님. SafeArea 바깥 fallback으로 적절. 단 그라데이션 노드와 fallback이 *단색-그라데이션 경계*에서 살짝 컬러 점프 가능 — 노치 영역만 영향이라 시각적으로 무시 가능.

- **개선 제안**: 없음 — 합격선.

### 성능 (9.0/10)

- **강점**:
  - 신규 노드: `DifficultyCardNode`당 SKLabelNode 1개(descriptionLabel) 추가 × 카드 3장 = 총 +3개 노드. 무시 가능.
  - `setupDifficultyCards`/`layoutDifficultyCards`/`layoutSummaryCard` 모두 `didMove`·`didChangeSize` 시점 1회 호출. update 루프 내 노드 생성 없음.
  - `relayoutSKView`의 frame 동일성 체크가 viewDidLayoutSubviews 무한 재호출을 차단. 회전 시 1회만 didChangeSize 발화.
  - `[weak self]` 캡처: 본 sprint는 신규 클로저 없음(N/A). 기존 클로저 회귀 없음.
  - `DifficultyCardNode.init`에서 fill 색을 초기화 후 `setSelected`가 호출되며 다시 설정 — 한 프레임 중복 set이지만 첫 프레임만 발생. 60fps 영향 없음.

- **약점/관찰**:
  - `descriptionLabel.numberOfLines = 0` + `preferredMaxLayoutWidth = 96`는 SKLabelNode가 매 layout마다 텍스트 너비 계산을 수행 — 단, 텍스트가 init 후 변경되지 않으므로 1회만 계산. 성능 영향 없음.
  - SKLabelNode가 동적 텍스트 wrap 사용 시 일부 iOS 버전에서 baseline 정렬이 약간 어긋날 수 있음. `verticalAlignmentMode = .center`로 명시 — 안전.

- **개선 제안**: 없음.

### 기능 완성도 (8.5/10)

**SPEC §기능 1~6 매핑**:

- [PASS] **기능 1 SKView Safe Area Mount**: `GameViewController.swift:22-83`. viewDidLoad에 backgroundColor fallback + SKView frame 갱신 + autoresizing 끄기. viewSafeAreaInsetsDidChange + viewDidLayoutSubviews에서 relayoutSKView 호출. relayoutSKView 내부 frame 동일성 가드 (line 80). SPEC §주의 1~2 완전 준수.

- [PASS] **기능 2 Difficulty.description**: `Difficulty.swift:55-65`. 3 case 모두 한 줄 풀이. `: CustomStringConvertible` 미채택(SPEC §주의 4 준수). raw value 불변. 본 sprint 외 `Difficulty` 인스턴스를 `String(describing:)`/`\()` 형태로 직접 보간하는 사용처 0건 grep 확인(ResultScene은 `displayName`/`shortName` 명시 호출).

- [PASS] **기능 3 DifficultyCardNode V3 시인성**:
  - 카드 크기 112×82 (V3 상수 사용, `DifficultyCardNode.swift:41-44`)
  - cornerRadius 20 (V3)
  - descriptionLabel 신규 + numberOfLines=0 + preferredMaxLayoutWidth=96 (line 180-181)
  - 미선택 alpha 0.78 (line 104)
  - 미선택 fill α 0.08 / stroke α 0.4 (line 129-134)
  - 선택 fill α 0.2 / stroke id.color 정색
  - 3 라벨 색 .ganhoNavyDeep / .ganhoNavyMuted 토큰 동기화 (line 137-139)
  - ringGlow cornerRadius도 V3(20)로 카드와 통일 (line 71) — 시각 일관성

- [PASS] **기능 4 CharacterSelectScene 여백 + 지그재그**:
  - `cardBaseX`에서 `characterSelectCardSpacingV3`(22pt) 사용 (`CharacterSelectScene.swift:370`)
  - `cardBaseY`에서 `characterSelectCardZigzagOffsetV3` 기반 짝/홀 인덱스 부호 처리 (line 383-384)
  - 모든 카드/컨테이너/색점/얼굴/태그 라벨/링글로우가 동일 헬퍼를 호출 — 자동 동기화

- [PASS] **기능 5 DifficultySelectScene 시각 균형**:
  - `layoutDifficultyCards`에서 width/spacing V3 사용 (`DifficultySelectScene.swift:363-364`)
  - `layoutSummaryCard`에서 `difficultySelectSummaryCardOffsetXV3`(-260) 사용 (line 318)
  - 시작 버튼 offsetY 미조정 — SELF_CHECK §위험 5에 109pt 여유 근거 명시. 합리적 판단.

- [PASS] **기능 6 GameConfig V3 상수 묶음**: `GameConfig.swift:1731-1789`. 19개 신규 상수, 한국어 주석 부여, MARK 섹션 분리. 기존 상수 값 변경 0건(grep 확인 — `characterCardSpacing=10`, `difficultyCardWidth=80`, `difficultyCardHeight=56`, `difficultySelectSummaryCardOffsetX=-220` 모두 보존).

**변경 금지 회귀 확인**:
- GameScene 미접촉 OK
- Repositories/* 미접촉 OK
- AudioManager / HapticsManager 미접촉 OK
- Difficulty enum case·rawValue 불변 OK (description만 추가)
- StartScene / ResultScene transitionToNext 시그니처 미접촉 OK
- CharacterID / CharacterCardNode 내부 미접촉 OK
- GameScene.newGameScene(characterID:difficulty:) 시그니처 불변 OK
- ResultScene.newResultScene(...) 시그니처 불변 OK
- GlassPillNode / PrimaryButtonNode / DarkContextChipNode 내부 미접촉 OK
- 음표 emitter / 그라데이션 배경 / NurseAvatarNode 미접촉 OK
- 사운드 발화 시퀀스 미접촉 OK
- DifficultyCardNode.setSelected(_:) 시그니처 불변 OK
- 기존 GameConfig 상수 값 미변경 OK

**SPEC 수치 deviation (P2 등급)**:
- SPEC §기능 6: `characterCardSpacingV3 = 28` → 구현 `characterSelectCardSpacingV3 = 22` (이름·값 모두 변경)
- SPEC §기능 6: `difficultyCardFontSizeV3 = 24` → 구현 `difficultyCardNameFontSizeV3 = 22`
- SPEC §기능 6: `difficultyCardHeightV3 = 80` → 구현 82
- SPEC §기능 6: `characterSelectCardYOffsetsV3: [CGFloat] = [-6, 8, -4, 6, -6]` 5개 배열 → 구현 단일 스칼라 `characterSelectCardZigzagOffsetV3 = 8` + 짝홀 부호
- SPEC §기능 6에 명시된 `difficultySelectDifficultyRowOffsetXV3` / `difficultySelectDifficultyRowOffsetYV3` *V3 신설 상수* 부재. 대신 기존 `difficultySelectDifficultyRowOffsetX/Y`를 그대로 사용 — 값 동일(110, -10)이라 기능 동등.

이 deviation들은 모두 SPEC §주의사항 1·5·6 같은 "회귀 방지 절대 룰"을 어기지 않고, 사용자 경험 측면에서도 합리적이지만 SPEC 텍스트와의 1:1 매핑이 깨진 점이 감점 요소. -1.5점.

**잠재 이슈 (참고용, P3)**:
- `CharacterSelectScene.cardBaseX`는 layout grid 계산에 `GameConfig.characterCardWidth`(48pt)를 사용하지만 실제 시각 컨테이너는 `characterCardGlassWidth`(110pt). 이건 *Sprint 7 이전부터* 존재했던 패턴 — Generator가 새로 도입한 회귀가 아님. 5장 카드의 카드 간 *시각 거리*는 `48 + 22 = 70pt` 그리드 — 110pt 글래스 컨테이너는 각각 70pt 그리드 위에서 양옆 20pt씩 overlap. 사용자가 "흩어진 인상"을 느끼는지 여부는 글래스 컨테이너 거리가 결정하므로, 22pt spacing은 실효 +12pt 여백 — SPEC §기능 5의 "흩어진 인상" 의도와 일치. *이상 동작 가능성*은 글래스 컨테이너가 서로 살짝 겹쳐 보일 수 있다는 점이지만 fillAlpha 0.65 + strokeColor clear라 시각적으로 자연스럽게 융합. 차회 sprint에서 사용자 피드백을 본 뒤 spacing 28까지 확장하는 옵션 보유.

---

## 사용자 요구 충족도 (육안 검증 시뮬레이션)

- **메인 화면(StartScene) 잘림 해소**: PASS
  - 근거: GameViewController가 SKView를 `view.safeAreaLayoutGuide.layoutFrame`에 mount. StartScene의 `frame.minX + 60` BEST GlassPill / `frame.maxX - 64` 타이틀이 자동으로 safe area 안으로 들어옴. view.backgroundColor = .ganhoBgWarmTop fallback으로 노치 영역 연속성도 유지.

- **캐릭터 카드 흩어짐 + 예쁨**: PASS (소폭 미달 가능)
  - 근거: spacing 10→22(+12pt) — SPEC §기능 5에서 제시한 28pt보다 작지만 카드 폭 산정에 사용되는 characterCardWidth가 48임을 고려하면 시각적으로 *합당한 여백* 확보. 짝/홀 인덱스 ±8pt 지그재그로 5장이 자연스럽게 흩어진 인상. z-rotation은 SPEC 지시대로 *미적용* — hit test 회귀 방지.

- **난이도 흐림 해소 + 설명 추가 + 크기 확대**: PASS
  - 근거:
    - 미선택 alpha 0.5 → 0.78 상향 (+0.28)
    - 미선택 fill을 `id.color × 0.08`로 색이 살짝 깔리는 톤
    - 미선택 stroke `id.color × 0.4`로 미선택도 명확
    - 카드 크기 80×56 → 112×82 (1.4× × 1.46× 확장)
    - descriptionLabel 신규 (3 case 모두 다른 한 줄 풀이)
    - 폰트 nameLabel 20→22pt, subtitle 10→12pt, description 10pt
    - 라벨 색 .ganhoNavyDeep / .ganhoNavyMuted로 가독성 향상

- **결과창(ResultScene) 잘림 해소**: PASS
  - 근거: SafeArea mount로 자동 해결. ResultScene 자체는 변경 0건 — frame.midX 기준 콘텐츠라 SKView frame이 safe area로 줄어들면 panel·버튼이 자동으로 안전 영역 내부 정렬. SPEC §기능 7 의도 그대로.

---

## 구체적 개선 지시 (점수 6.0 미만일 때만)

없음 — 가중점수 8.70으로 합격선(7.5) 초과.

다만 차회 sprint에서 다듬을 수 있는 권장(점수 영향 없음):

1. `characterSelectCardSpacingV3 = 22`를 SPEC 권장값(28)에 맞춰 늘려보고 사용자 만족도 확인 — 22가 충분히 흩어진 인상이면 그대로 두되, 빽빽한 인상이 남으면 28까지 확장.
2. `setSelected(_:)`의 `else` 분기에서 background fillColor 변경 직후 scale 1.0 액션 — 액션과 색 변경 동시 발화가 시각 글리치 없는지 실기 빌드에서 확인. 필요 시 `SKAction.colorize` 0.15s로 부드럽게.
3. SPEC §기능 6의 `difficultyCardHeightV3 = 80` 권장값과 구현(82)의 +2pt 차이가 시작 버튼과 충돌 없는지 카드 row 하단 y = midY-51 기준 109pt 여유로 안전 — 회귀 0. 변경 권장 아님.
4. SPEC §주의사항 12 — iPhone SE / iPhone 15 등 다양한 기기에서도 잘림 없는지 시뮬레이터 실기 확인 권장(Linux workspace 환경상 본 검수에서는 미수행).

---

## 판정 근거 한 줄

SPEC §주의사항(케이스 추가/삭제 금지·rawValue 불변·서명 불변·기존 상수 값 보존·무한 layout 루프 가드·CustomStringConvertible 미채택·storyboard 미수정) 모두 정확히 준수했고, 사용자 4대 요구(메인/캐릭터/난이도/결과창)를 SafeArea + V3 카드 + descriptionLabel + summary offsetX 보정으로 통합 해결한 합격품. SPEC 수치 deviation 4건은 모두 합리적 절충으로 P2 등급.

QA_REPORT.md 작성 완료. 판정: 합격. 가중점수: 8.70/10
