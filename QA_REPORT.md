# QA 검수 보고서 — Phase 7-5 시뮬레이터 핫픽스 (4건 버그)

## SPEC 기능 검증

- **[PASS] 버그 1 카드 절단 — 값 변경**: `GameConfig.swift:124` titleLabelOffsetY = 120 / `:471` difficultyCardOffsetY = +80 / `:478` characterCardOffsetY = -160 정확히 적용. 640pt 화면 좌표 산술 검증 PASS (아래 §실제 사용자 시나리오 §1).
- **[PASS] 버그 2 컷씬 최초 1회 — UserDefaults 분기**: `GameConfig.swift:573` 신규 키 `hasSeenIntroCutsceneUserDefaultsKey: String = "hasSeenIntroCutscene"` 추가. `GameScene.swift:158-165` didMove 끝 if/else 분기 (hasSeenIntro 검사). `GameScene.swift:195` onDismiss 안 `UserDefaults.standard.set(true, forKey: ...)` 1줄 추가 (guard let self 뒤 / gameState 전환 전 — 이상적 위치).
- **[PASS] 버그 3 졸업장 좌표 — anchor 변경**: `ResultScene.swift:318` anchor = `CGPoint(x: size.width / 2, y: size.height / 2)`. sceneSize 단일 기준으로 통일.
- **[PASS] 버그 4 졸업장 터치 가드**: `ResultScene.swift:228` `if children.contains(where: { $0.name == "diplomaOverlay" }) { return }` 1줄 추가. 가드 위치 = `guard !isTransitioning else { return }` 바로 다음 (이상적). `DiplomaOverlayNode.swift:80`에서 `name = "diplomaOverlay"` 부착 — 가드 문자열과 정확 일치.

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 경고: 0건 (warning/error grep — AppIntents 제외 → 0줄)
- 비고: 처음 시도한 'iPhone 15' 시뮬레이터가 환경에 부재 → 'iPhone 17'로 재시도 후 성공. 코드 변경 무관(시뮬레이터 환경 차이).

## 회귀 0 영역 검증

`git diff --stat`로 다음 경로에 대해 0줄 변경 확인:

```
TitleScene.swift / Nodes/* / Systems/* / Managers/* / Repositories/* /
Models/* / ColorTokens.swift / PhysicsCategory.swift / GameState.swift /
GameScene+Setup.swift / GanhoMusic iOS-tvOS-macOS/ / GanhoMusic.xcodeproj/
```

→ **(빈 출력, 0줄 변경)** — 자가 소멸 노드 11호(`CutsceneOverlayNode` / `DiplomaOverlayNode` 포함) 미접촉, 시스템·매니저·리포지토리·모델 미접촉, pbxproj 미접촉(신규 파일 0). TitleScene은 이미 `GameConfig.titleLabelOffsetY` / `difficultyCardOffsetY` / `characterCardOffsetY` 를 line 98/187/148에서 참조 중 → *값만 바뀌어 자동 재배치*, 코드 변경 0.

## 정적 검사

| 항목 | 결과 | 비고 |
|------|------|------|
| 강제 언래핑(`!`) | 0건 | 추가된 모든 라인 grep 결과 0. `UserDefaults.standard.bool/set`은 옵셔널 미반환 |
| `Timer.` 사용 | 0건 | UserDefaults 분기는 동기 호출 |
| `DispatchQueue` 사용 | 0건 | 비동기 처리 없음 |
| `[weak self]` 캡처 | 준수 | onDismiss 기존 캡처 유지 + 신규 set 1줄 self 무관(부수효과 안전) |
| guard let | 준수 | 기존 guard let self 유지 |
| MARK 섹션 | 준수 | 신규 코드 모두 기존 MARK 안에 배치 |
| 매직 넘버 | 0건 신규 | `"diplomaOverlay"` 는 노드 name 식별자(자체 정의된 의미체), `size.width / 2`는 SPEC 명시 좌표 |
| GameConfig 상수화 | 준수 | UserDefaults 키, 3개 offset 모두 GameConfig에 정의 후 호출부 참조 |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | **0건** |

---

## 실제 사용자 시나리오 — 4건 버그 차단 검증

### 시나리오 1: 작은 화면(iPhone SE 640×480 또는 640pt 높이 가로화면) — 버그 1 차단

**좌표 산술** (midY = 320, 화면 [0, 640]):

| 요소 | offsetY | 절대 y | 노드 높이/절반 | 상단/하단 |
|------|---------|--------|---------------|---------|
| titleLabel | +120 | 440 | (라벨) | top 여백 200pt ✓ |
| difficultyCard 행 | +80 | 400 | 56/28 | top=428, bot=372 ✓ |
| bestLabel | +20 | 340 | (라벨) | ✓ |
| playsLabel | -20 | 300 | (라벨) | ✓ |
| promptLabel | -80 | 240 | (라벨) | ✓ |
| characterCard 행 | -160 | 160 | 60/30 | top=190, bot=130 (하단 130pt 여유) ✓ |

- difficultyCard ↔ titleLabel 간격: 440 - 428 = **12pt** (안전 ≥ 8pt)
- difficultyCard ↔ bestLabel 간격: 372 - 340 = **32pt** (안전)
- promptLabel ↔ characterCard 간격: 240 - 190 = **50pt** (안전)
- characterCard ↔ 화면 하단: 130 - 0 = **130pt** (안전, 절단 회피)

→ **버그 1 자연 차단**. Phase 7-1의 -200(하단 90pt 위태)을 -160으로 되돌리고 난이도 카드를 상단으로 분리해 위/아래 분리 레이아웃 완성.

### 시나리오 2: 인트로 컷씬 최초 1회 — 버그 2 차단

| 시점 | UserDefaults `hasSeenIntroCutscene` | didMove 분기 | 결과 |
|------|-----------------------------------|-------------|------|
| 신규 사용자 1회차 진입 | (키 부재) → Apple 보장 default false | `else` → showIntroCutscene() | 컷씬 표시 → onDismiss에서 `set(true)` |
| 2회차 진입 | true | `if` → showCountdown() | 컷씬 스킵, 곧장 카운트다운 |
| N회차(N≥2) | true | `if` 분기 동일 | 영원 스킵 |

- bool 기본값 false: Apple Foundation `UserDefaults.bool(forKey:)` 키 부재 시 false 반환 (공식 문서). 자연 최초 표시.
- set 위치: onDismiss 안 guard let self 직후 / gameState 전환 전 → self 해제 가능성 0(이미 guard 통과), 컷씬 끝나기 전 시점이 아니므로 사용자가 컷씬을 *읽고 탭한 시점*에 정확히 set.
- *부수효과 안전*: `UserDefaults.standard` 정적 접근이므로 self 무관, self 해제되어도 플래그 set 보장.

→ **버그 2 자연 차단**.

### 시나리오 3: 작은 화면에서 졸업장 위치 — 버그 3 차단

- ResultScene `.resizeFill` 모드 + `size = 1024×768` 고정.
- `self.size` = (1024, 768) 항상.
- `self.frame` = view 크기에 따라 동적(작은 화면에서 ≠ 1024×768).
- background SKSpriteNode가 sceneSize 기준으로 배치됨.
- 변경 전 `frame.midX/midY` = view 크기 기준 → 작은 화면에서 background와 anchor 좌표계 *불일치* → 졸업장 위치 어긋남.
- 변경 후 `size.width/2, size.height/2` = (512, 384) → background와 *같은 sceneSize 좌표계* → 정렬 보장.

→ **버그 3 자연 차단**.

### 시나리오 4: 졸업장 표시 중 탭 — 버그 4 차단

| 경로 | 차단 메커니즘 | 단계 |
|------|--------------|------|
| 졸업장 자체 탭 | `DiplomaOverlayNode.isUserInteractionEnabled = true` (line 83) → 자기가 흡수 | 1차 |
| edge case로 ResultScene에 도달 | `children.contains(where: { $0.name == "diplomaOverlay" })` → true → early return | 2차 안전망 |
| 졸업장 없을 때 일반 탭 | children에 매치 노드 0 → contains false → 가드 발화 0 → 기존 TitleScene 전환 동작 그대로 | 회귀 0 |

- 가드 위치 = `guard !isTransitioning else { return }` 직후 = **이상적 위치** (다른 가드보다 *앞*에서 졸업장 조기 차단, view 추출 전).
- 노드 name 일치 검증: `DiplomaOverlayNode.swift:80` 에서 `name = "diplomaOverlay"` 부착 — 가드의 문자열 리터럴과 정확히 일치.

→ **버그 4 자연 차단**.

---

## 통과 항목 (4건 모두 정밀 적용)

- SPEC §5 변경 파일 목록의 4개 파일 중 *실제 코드 변경*은 3개 파일(GameConfig / GameScene / ResultScene) — TitleScene은 이미 상수 참조 중이라 변경 불필요. 허용 외 파일 변경 0건.
- 신규 파일 0개, pbxproj 변경 0건.
- 자가 소멸 노드 11호(CutsceneOverlayNode / DiplomaOverlayNode 포함) 미접촉 — 회귀 0.
- 시스템·매니저·리포지토리·모델 / ColorTokens / PhysicsCategory / GameState / GameScene+Setup / iOS·tvOS·macOS 진입점 미접촉.
- 강제 언래핑 / Timer / DispatchQueue / 매직 넘버 신규 0건.
- 빌드 SUCCEEDED + 경고 0건.

---

## 채점

### 항목별 점수

| 영역 | 점수 | 근거 |
|------|------|------|
| Swift 패턴 일관성 | 10/10 | 강제 언래핑 0, Timer 0, DispatchQueue 0, GameConfig 상수화 100%, MARK 섹션 준수, weak self 캡처 유지. UserDefaults 키도 GameConfig에 흡수. |
| 게임 로직 완성도 | 10/10 | 4건 버그 모두 root cause 정확 진단 + 정밀 차단. didMove if/else 분기 / onDismiss set 위치 / anchor 좌표계 통일 / 가드 위치(isTransitioning 직후) 모두 *이상적*. |
| 성능 & 안정성 | 10/10 | `children.contains(where:)` O(n) but n ≤ 10 + early return으로 사용자 체감 0. UserDefaults bool 호출 1회/씬 진입(딕셔너리 lookup 마이크로초). 부수효과 self 해제 안전. |
| 기능 완성도 | 10/10 | SPEC 4건 1:1 매핑, 회귀 0 자연 차단, 빌드 SUCCEEDED, 작은 화면(640pt) 좌표 산술 검증 PASS. |

### 가중 점수

```
0.35 × 10 + 0.30 × 10 + 0.20 × 10 + 0.15 × 10
= 3.50 + 3.00 + 2.00 + 1.50
= 10.0/10
```

**가중 점수: 10.0 / 10**

> **자기 검토 (관대함 점검)**: "10점이면 내가 관대한가?" — 점검 결과:
> - SPEC 4건 모두 정확한 위치에 정확한 변경. 위치 1개라도 어긋났으면 감점.
> - 가드 위치(`isTransitioning` 직후), onDismiss set 위치(guard let self 직후), anchor 기준(sceneSize 일관)이 *이상적 위치*에서 정확.
> - 회귀 0 영역 grep 0줄, 빌드 경고 0건, 정적 검사 0건.
> - 핫픽스는 *원래 작은 변경*. 변경 범위·정확도·검증성 모두 만점 수준. 관대함이 아닌 *정밀한 작은 sprint*에 대한 정당한 평가.

---

## 최종 판정: **합격**

**구체적 개선 지시**: 없음. 4건 버그 모두 코드 수준에서 차단됨. 사용자 시나리오(작은 화면, 최초/재진입, 졸업장 표시 중 탭) 4가지 모두 자연 차단 메커니즘 검증 완료.
