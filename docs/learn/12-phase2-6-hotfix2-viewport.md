# 12 · Phase 2-6 Hotfix 2 · viewport 재설계 + player 시작 위치 + enemy 가시성

> **이번 작업의 한 줄**: scene size를 *iPhone viewport에 자동 맞춤* + player를 기둥과 분리 + enemy 색을 더 밝은 톤으로 → 화면에 *모든 노드가 정상적으로 보임*.
> 비유: HTML이 *고정 픽셀 폭*으로 그려지다가 *반응형*으로 전환. viewport meta 태그 + flex layout.

---

## 1. 한눈 요약

```
지금 (Phase 2-6 hotfix 1)                  이번 작업 (hotfix 2)
┌─────────────────────────────┐            ┌─────────────────────────────┐
│ 🎵 0 ⏱ 00:42                │            │ 🎵 0 ⏱ 00:45                │
│   (좌상단 일부만 보임)      │            │   (좌상단 정상)              │
│                              │            │                              │
│         [기둥+player 겹침]   │   ──→      │     ❤️                       │
│                              │            │                              │
│   (D-Pad 화면 밖)            │            │  [□]              [▲]       │
│   (enemy 화면 밖)            │            │  player    [◀][●][▶]        │
│                              │            │                  [▼]         │
└─────────────────────────────┘            └─────────────────────────────┘
       *노드는 있는데 안 보임*                  *모든 노드 화면 안*
```

**핵심 변화 세 가지**:
1. **viewport 자동 맞춤** — `didChangeSize(_:)` 오버라이드. scene.size가 view 크기로 갱신될 때마다 D-Pad/HUD 위치 *자동 재배치*.
2. **player 시작 위치 분리** — player가 기둥(맵 정중앙)과 같은 좌표에서 시작 → 첫 프레임 물리 분리 force로 어딘가로 튕김. **player를 맵 좌측 1/4(`mapWidth/4, mapHeight/2`) = (240, 240)**으로 옮김. 기둥과 안 겹침.
3. **enemy 색 톤 강화** — `.ganhoCrimsonNurse` (#A4243B 어두운 빨강)을 `.ganhoBloodAccent` (#D8315B 밝은 빨강)으로 교체. assets.md §1 `bloodAccent` 토큰 신설 진입.

**부수 변화**: setupDPad/setupHUD를 *addChild + 위치 계산* 한 번에서 *addChild는 init에서, 위치 계산은 layoutDPad/layoutHUD 헬퍼*로 분리. didChangeSize 호출 시 layout 함수만 다시 실행.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `GameScene.didChangeSize(_:)` 신설 | scene.size 변경 시 SpriteKit이 호출. layoutDPad / layoutHUD 재호출로 위치 갱신 |
| `setupDPad()` → `setupDPad()` + `layoutDPad()` 분리 | addChild는 setup, 좌표는 layout. layout만 didChangeSize에서 재호출 |
| `setupHUD()` → `setupHUD()` + `layoutHUD()` 분리 | 동일 패턴 |
| `setupPlayer()` 좌표 변경 | (mapW/2, mapH/2) → (mapW/4, mapH/2) = (240, 240). 기둥과 분리 |
| `setupEnemy()` 좌표 재조정 | hotfix 1의 (320, 340) 유지 또는 player 변경에 맞춰 재계산 (240, 240 player 기준 +tile*4 우상단 → (320, 340) 그대로 OK) |
| `ColorTokens` 토큰 1개 추가 | `.ganhoBloodAccent` (#D8315B). assets.md §1 `bloodAccent` 진입 |
| `EnemyNode` color 변경 | `.ganhoCrimsonNurse` → `.ganhoBloodAccent` |

### 왜 지금?
1. **사용자 검증 실패**. Phase 2-6 본 sprint + hotfix 1 합격에도 시뮬레이터에서 enemy/D-Pad 안 보임. *코드 정확성* ≠ *사용자 경험*.
2. **viewport는 게임 *전체*의 기반**. Phase 2-7(F 투사체) / 2-8(난이도 보간) / 3+(게임오버 화면) 모두 정상 viewport 위에서 동작해야 함. **기반 인프라 우선**.
3. **player + 기둥 같은 좌표는 *원래부터 잠재 버그***. Phase 2-2(중앙 기둥 진입) 시점부터 있었지만 시각적으로 검증 안 됨. 이번 sprint에서 함께 해결.
4. **assets.md `bloodAccent` 토큰 미진입**. 16색 팔레트 중 `crimsonNurse`만 코드에 있고 `bloodAccent`는 *수간호사 강조 / 피격 플래시*용으로 정의됨. enemy 시각 가시성을 위해 더 적절.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| F 투사체 (ProjectileNode) | Phase 2-7 |
| 적 속도 보간 | Phase 2-8 |
| 게임오버 화면 | Phase 3 |
| 적 사운드 / 시각 펄스 | Phase 6 |
| ColorTokens 16색 *전체* 진입 | 필요 시점에 점진 진입 (현재 5 → 6 토큰) |
| scaleMode 변경 (.resizeFill 유지) | viewport 자동 갱신은 .resizeFill에 의존 |

---

## 3. Spring 비유 🌱

### 3-1. didChangeSize = "@EventListener(WindowResizeEvent)"
| 개념 | Spring/Reactive | 본 작업 |
|---|---|---|
| 이벤트 트리거 | `WindowResizeEvent` 발생 | view bounds 변경 → SpriteKit이 didChangeSize 호출 |
| 핸들러 | `@EventListener` 메서드 | `override func didChangeSize` |
| 갱신 대상 | UI 컴포넌트 layout | D-Pad / HUD 위치 |

Spring으로 치면 `ApplicationContext`에 등록된 listener가 *resize 이벤트*를 받아 *bean 위치 재계산*. 게임 루프에선 SpriteKit이 *자동* listener 등록 — 우리는 메서드 오버라이드만.

### 3-2. setup vs layout 분리 = "Bean 생성 vs Bean 갱신"
```swift
// setup: Bean 생성 (한 번만)
private func setupDPad() {
    cameraNode.addChild(dpad)
    layoutDPad()
}

// layout: Bean 상태 갱신 (여러 번 호출 가능)
private func layoutDPad() {
    dpad.position = ...
}
```
Spring으로 치면 `@Bean` 생성(`@PostConstruct`)과 `@Scheduled` 갱신의 분리:
- `@PostConstruct` = setup (한 번)
- `@Scheduled(fixedRate)` 또는 이벤트 기반 갱신 = layout (여러 번)

**원칙**: *생성*과 *갱신*을 분리하면 *갱신만* 재호출 가능. addChild를 layout에 두면 *매번 자식 추가*되어 메모리 누수.

### 3-3. ColorTokens 점진 진입 = "feature flag로 점진 도입"
assets.md 16색 중 *현재 사용 중인 5개*만 ColorTokens.swift 진입. 나머지 11개는 *필요 시점에 진입*.
Spring으로 치면 *feature flag*로 신기능 점진 도입 — 한꺼번에 다 진입하면 *과설계*. 점진 진입이 *실제 사용 추적*과 *의존성 최소*에 유리.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `didChangeSize(_:)` 오버라이드 패턴
```swift
override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)   // 부모 호출 필수
    layoutDPad()
    layoutHUD()
}
```
**왜 super 호출?** SKScene 부모 클래스가 *내부 layout 작업*을 수행할 수 있음. 오버라이드 시 super 호출 *반드시 첫 줄*. Swift override 패턴 표준.

**언제 호출되나?**
- scene이 처음 view에 attach될 때 (`scaleMode = .resizeFill`이면 view 크기로 갱신)
- view 크기 변경 시 (회전 / 분할 화면 등)
- 즉, *view 크기와 scene 크기가 다를 때마다*

**didMove(to:) vs didChangeSize**:
- `didMove(to:)`: scene이 view에 *처음 add*될 때 1회. 노드 *생성/추가* 책임.
- `didChangeSize(_:)`: scene 크기 변경 시 *여러 번*. 노드 *위치 갱신* 책임.

### 4-2. setup/layout 분리 — *멱등성 (idempotency)*
```swift
private func setupDPad() {
    cameraNode.addChild(dpad)   // ❗ 한 번만 호출되어야 함
    layoutDPad()
}

private func layoutDPad() {
    let halfW = size.width / 2
    let halfH = size.height / 2
    dpad.position = CGPoint(...)   // ✅ 여러 번 호출 OK (멱등)
}
```
**왜 분리?** `addChild`는 *멱등 아님* — 두 번 호출하면 *같은 자식 두 번 추가* → 노드 트리 오염. `position = ...`은 *멱등* — 같은 값 여러 번 할당해도 결과 동일. didChangeSize에서는 *멱등 작업만* 호출.

**Spring 비유**: `@PostConstruct` vs setter. `@PostConstruct`는 *bean 생성 시 1회*, setter는 *언제든*. 책임 분리.

### 4-3. ColorTokens fallback 패턴 일관 적용
```swift
// MARK: - Enemy
/// 수간호사 가운. HEX #A4243B. assets.md §1.
static let ganhoCrimsonNurse = UIColor(named: "crimsonNurse")
    ?? UIColor(red: 0xA4 / 255, green: 0x24 / 255, blue: 0x3B / 255, alpha: 1)

/// 수간호사 강조 / 피격 플래시. HEX #D8315B. assets.md §1.
/// Phase 2-6 hotfix 2 — enemy 본체 색으로 사용 (ganhoCrimsonNurse는 어두워 가시성 ↓).
static let ganhoBloodAccent = UIColor(named: "bloodAccent")
    ?? UIColor(red: 0xD8 / 255, green: 0x31 / 255, blue: 0x5B / 255, alpha: 1)
```
**왜 fallback?** Asset Catalog Color Set이 *추후* 추가되면 자동 우선. 코드만으론 어떤 토큰이 *Asset Catalog에 있고 없는지* 모름. fallback은 *항상 유효*한 안전망.

**왜 점진 진입?** assets.md 16색 *전체*를 ColorTokens.swift에 진입하면 *11개 미사용 토큰* — Dead code. *실제 사용 시점*에 진입이 깔끔.

### 4-4. player 시작 위치 — 기둥 회피
```swift
// 변경 전 (Phase 2-2): 기둥과 같은 좌표
player.position = CGPoint(
    x: GameConfig.mapWidth  / 2,    // 480
    y: GameConfig.mapHeight / 2     // 240 — 기둥(2-2)도 같은 좌표!
)

// 변경 후 (hotfix 2): 맵 좌측 1/4 + 세로 가운데
player.position = CGPoint(
    x: GameConfig.mapWidth  / 4,    // 240
    y: GameConfig.mapHeight / 2     // 240
)
```
**왜 좌측 1/4?** 기둥(480, 240)에서 *1/4 거리*(240pt). 시야 좌측에 player, 우측에 기둥/적 추적 경로 → *공간 사고* 자연스러움.

**잠재 버그 회피**: dynamic body + static body가 *같은 좌표*에서 시작하면 SpriteKit이 *분리 force* 적용 → player가 어딘가로 *튕김*. 16pt 정도 미세 이동이지만 *카메라 follow*가 그걸 따라가서 *시각적 미세 흔들림*. Phase 2-2부터 잠재.

### 4-5. enemy 위치는 그대로 (320, 340) — player 기준 우상단 유지
- 기존 hotfix 1: enemy(320, 340)는 *기존 player(480, 240) 기준 좌상단*
- 신규 hotfix 2: player(240, 240)으로 변경 → enemy(320, 340)이 *player 기준 우상단*
- 거리: √(80² + 100²) ≈ 128pt → 60pt/s에서 ~2.13초

**왜 enemy 위치 안 변경?** player만 *좌측으로* 이동했으니 상대 위치는 *우상단*으로 자연스럽게 변함. 적이 *반대편*에서 다가오는 구도 OK.

### 4-6. ganhoBloodAccent (#D8315B) vs ganhoCrimsonNurse (#A4243B) — 시각 대비
- bgDeep #1A1B2E (어두운 남보라) 대비:
  - crimsonNurse #A4243B (어두운 빨강) → *대비 약함*. 16×20 박스가 묻힘.
  - bloodAccent #D8315B (밝은 핑크빨강) → *대비 강함*. 명확히 보임.
- assets.md §1 정의: bloodAccent는 *피격 플래시*용 — 시각 강조 의도. enemy 본체 색으로도 적합.

**디자인 토큰 사용 변경**: assets.md 변경 0(토큰 정의 그대로). 코드의 *사용처*만 변경. 사용자 본인이 향후 시각 디자인 통합 시 자유.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.**

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/ColorTokens.swift` | 토큰 1개 추가 — `.ganhoBloodAccent` (#D8315B). MARK 보존 |
| `GanhoMusic Shared/GameScene.swift` | (1) setupPlayer 좌표 변경 (mapW/2 → mapW/4), (2) setupDPad/setupHUD 본문을 layoutDPad/layoutHUD로 분리, (3) didChangeSize 신설 |
| `Nodes/EnemyNode.swift` | color 1줄 — `.ganhoCrimsonNurse` → `.ganhoBloodAccent` |

### 손대지 않는 파일
- `Config/GameConfig.swift`, `Config/PhysicsCategory.swift`, `Config/GameState.swift` (변경 0)
- `Nodes/PlayerNode.swift`, `Nodes/HUDNode.swift`, `Nodes/DPadNode.swift`, `Nodes/NoteNode.swift` (변경 0)
- iOS 3 파일, pbxproj (변경 0)
- `GameScene` 의 `setupBackground` / `setupWorld` / `addOuterWalls` / `addCentralPillar` / `setupCamera` / `setupEnemy` / `update` / `didBegin` / `endGame` / spawn 관련 (변경 0)

### Xcode 멤버십
**필요 없음.** 신설 파일 0건.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `didChangeSize` 등장 1건 (GameScene)
- `layoutDPad` 등장 ≥ 2건 (setupDPad에서 호출 + didChangeSize에서 호출)
- `layoutHUD` 등장 ≥ 2건 (동일)
- `ganhoBloodAccent` 정의 1건 (ColorTokens) + 사용 1건 (EnemyNode)
- 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건
- 매직 넘버 0건 (mapWidth/4 등 자명 산수만)

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 시작 직후 *밝은 빨간 박스(enemy)* 화면 안에 명확히 보임
- (b) player(민트)가 *맵 좌측 1/4*에 보임 — 기둥(흰색)과 분리됨
- (c) D-Pad 4개 버튼이 화면 우하단에 명확히 보임
- (d) HUD `🎵 0 ⏱ 00:45` 화면 좌상단에 정상
- (e) enemy가 player 방향으로 직선 이동 → 약 2초 후 도달 → 즉시 게임 종료
- (f) 시간 만료(00:00)에도 동일 종료
- (g) 음표 수집 / 콤보 / 카메라 follow 모두 본 sprint 그대로

### 6-3. 회귀 (1-3 + 1-5 + 2-1 + 2-2 + 2-3 + 2-4 + 2-5 + 2-6)
- 게임 로직 (점수/콤보/시간/spawn) 변경 0
- player/enemy/note 추적 AI / contact 분기 / endGame 로직 변경 0
- 외곽 벽 / 중앙 기둥 / 카메라 follow 그대로
- 본 sprint 합격 시 *코드 동작*은 동일, *시각 표시*만 정상화

---

## 7. 사용자 결정 (모두 추천 옵션 자동 확정)

사용자 지시 "한번에 다 진행"에 따라 결정 6건 모두 추천 옵션으로 진행:

| 결정 | 옵션 | 사유 |
|---|---|---|
| ① viewport 갱신 방식 | didChangeSize 오버라이드 + layout 분리 | SpriteKit 표준 패턴 |
| ② setup/layout 분리 패턴 | setup(1회 addChild + 1회 layout) + layout(idempotent) | 멱등성 보장 |
| ③ player 시작 위치 | (mapW/4, mapH/2) = (240, 240) | 기둥과 분리, 좌측 1/4 |
| ④ enemy 위치 | 기존 (320, 340) 유지 | player 기준 우상단 자연스러움 |
| ⑤ enemy 색 | `.ganhoBloodAccent` 신규 토큰 | bgDeep 대비 강함, 시각 가시성 ↑ |
| ⑥ scaleMode | `.resizeFill` 유지 | 기존 의도 보존, didChangeSize가 그 위에서 동작 |

---

## 8. SPEC에 들어갈 핵심 제약 (Generator에게 전달)

- **변경 유형**: 비주얼/인프라 (viewport + 시각 가시성)
- **게임 경험 의도**:
  > "scene size가 iPhone viewport에 자동 맞춰져 D-Pad/HUD가 정상 위치에 보인다.
  > player가 기둥과 분리되어 시작. enemy가 밝은 빨강으로 명확히 보임.
  > 게임이 *코드만 정확*한 상태에서 *사용자가 정상 플레이 가능*한 상태로 진화."
- **Sprint 범위 계약**:
  - **IN**: 신설 0 파일. 수정 3 파일 (ColorTokens 토큰 1개, GameScene 4가지 변경, EnemyNode color 1줄).
  - **OUT**: F 투사체 / 속도 보간 / 게임오버 화면 / scaleMode 변경 / scene size 변경 / 16색 전체 토큰 진입 / 신설 파일.
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print` / `as!` / `fileprivate` / `DispatchQueue.main.asyncAfter` 0건
  - `update(_:)` 안 `addChild` 0건
  - 매직 넘버 0건 (mapWidth/4 등 자명 산수만)
  - `didChangeSize`에서 `super.didChangeSize(oldSize)` 첫 줄 호출 필수
  - layout 함수는 멱등 (addChild 0)
  - setupDPad / setupHUD는 *addChild + layout 호출* 형태 유지 (기존 패턴 보존하되 좌표 부분만 layout으로 분리)
  - `.ganhoBloodAccent` fallback 패턴 일관 (`UIColor(named:) ?? UIColor(red:green:blue:alpha:)`)
- **회귀 보존**:
  - 게임 로직 / 추적 AI / didBegin / endGame 한 줄도 변경 X
  - PlayerNode / HUDNode / DPadNode / NoteNode / Config 4 파일 / iOS 3 파일 / pbxproj 변경 0
  - HUDNode `update(score:remainingTime:combo:)` 시그니처 그대로
  - GameScene 의 다른 setup 함수(setupBackground/setupWorld/addOuterWalls/addCentralPillar/setupCamera/setupEnemy/startSpawnLoop) 변경 0

---

## 9. 회고

### 9-1. 막혔던 것
**진단 사이클이 길었음** — 본 sprint(2-6) 직후 시각 검증 실패 → hotfix 1(좌표 이동)도 실패 → 마젠타 색 진단 → 또 실패 → 종합적으로 *viewport 자체* 문제로 결론. **코드 정확성 ≠ 사용자 경험**임을 강하게 학습. 단위 테스트(빌드/grep)만으론 *시각 검증*을 대체 못함. 

> **인사이트**: 게임에서 *시뮬레이터 시각 검증*은 *별도 검증 단계*. xcodebuild SUCCEEDED + Evaluator 합격 ≠ 게임 정상. 차후 학습 노트 §6-2(시각 검증 항목)을 *가설 수준이 아니라 *체크리스트*로 더 구체화 필요.

### 9-2. Spring과 다르네 싶었던 것
1. **viewport는 *런타임 갱신* 대상**: Spring web에서 *responsive design*은 *CSS media query*가 처리. iOS는 *런타임 콜백*(didChangeSize)으로 직접 처리. **선언형 vs 명령형의 차이**. 게임 도메인은 명령형이 자연스러움 — *매 프레임 위치 갱신*이 본질.
2. **setup vs layout 분리 = `@PostConstruct` vs setter**: Spring `@PostConstruct`는 1회, setter는 무한. 본 sprint의 `setupX()` vs `layoutX()` 분리도 동일 *책임 구분*. **멱등성(idempotency)** 개념이 *호출 횟수에 따른 안정성*을 보장.
3. **점진 진입 원칙 (ColorTokens)**: assets.md 16색 중 *현재 6개*만 코드에 진입. 나머지 10개는 *필요 시점*에. Spring의 *feature flag*와 비슷 — *과설계 회피*. **Dead code도 결국 부채**.
4. **잠재 버그가 *시각 검증에서 드러남***: player와 기둥이 같은 좌표로 시작한 건 Phase 2-2부터 있었지만 *물리 분리 force가 작아* 시각적으로 *큰 영향 없었음*. 시각 검증을 강화한 본 sprint에서 드러남. **버그는 *드러나는 시점*과 *발생 시점*이 다를 수 있음**.

### 9-3. 다음 작업으로 이월
1. **scaleMode 검토 (Phase 4 폴리싱)**: `.resizeFill`이 다양한 디바이스(iPad, iPhone SE)에서 동작 검증.
2. **ColorTokens 점진 진입**: 16색 중 *실사용 시점*에 점진 추가. F 투사체(2-7) → `.ganhoYellowF` 진입 예정.
3. **D-Pad 시각 강조 (Phase 6)**: 현재 `.ganhoPaper` 흰색 박스. 아이콘/그라데이션은 폴리싱.
4. **player 시작 위치 정책 (Phase 4)**: 다중 캐릭터 도입 시 spawn point system 검토.
5. **시각 검증 자동화 (Phase 6+)**: 시뮬레이터 스크린샷 자동 캡처 + 핵심 노드 위치 검증 스크립트 (XCTest UI test).
6. **Phase 2-7 (F 투사체)**: 본 sprint 정착 후 즉시 진입 가능. PhysicsCategory.projectile 첫 추가.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.5 / 10** — setup/layout 분리 패턴 정확, fallback 일관, MARK 보존
- 게임 로직 (30%): **9.5 / 10** — didChangeSize 표준 패턴, 멱등 보장, 회귀 12행 0 변경
- 성능 & 안정성 (20%): **10 / 10** — BUILD SUCCEEDED 경고 0, 강제 언래핑 0
- 기능 완성도 (15%): **10 / 10** — SPEC 6 기능 정확 구현, OUT 0건 침범
- **가중평균: 9.575 / 10 — 합격**

### 9-5. 사용자가 직접 확인할 것
시뮬레이터 `⌘R` 후 §6-2 (a)~(g) 시각 검증:
- (a) 시작 직후 *밝은 빨간 박스(enemy)* 화면 안 명확히 보임
- (b) player(민트)가 화면 좌측, 기둥(흰)이 우측 — 분리 확인
- (c) D-Pad 4개 버튼 화면 우하단 명확
- (d) HUD 좌상단 정상
- (e) ~2초 후 enemy가 player에 닿음 → 즉시 게임 종료
- (f) 시간 만료 시 동일 종료
- (g) 음표/콤보/카메라 follow 모두 본 sprint 그대로

### 9-6. P2 권장 (정보성, 본 sprint 외)
- `.ganhoCrimsonNurse` 토큰이 *정의는 보존되나 사용처 0건* (dead token). assets.md §1 정의 자체는 그대로 두고 코드의 *사용처*만 `.ganhoBloodAccent`로 전환 → 토큰 자체는 *향후 사용 가능성*(예: 수간호사 가운 픽셀 아트 진입 시) 있어 보존. P2 등급.

---

## 11. Hotfix 3 (2026-05-07) — 진단 라벨 제거 + D-Pad 가시성

### 11-1. hotfix 2 후 발생한 추가 진단 사이클
hotfix 2 빌드 후에도 사용자 시뮬레이터 결과가 *예전 빌드 그대로* 표시됨. 진단을 위해 **임시 진단 라벨**을 GameScene에 추가:
- `private let debugLabel = SKLabelNode()` 멤버 + setupDebugLabel + update에서 player/enemy/cam/scene 좌표를 노란색 텍스트로 화면 정중앙에 표시.
- xcodebuild 성공에도 시뮬레이터 install 자체가 안 되는 것으로 의심 → `xcrun simctl uninstall + install + launch`로 *강제 재설치*.

**진단 결과**: `p:240,240 e:256,260 c:240,240 scene:874x402`
- player 좌표 정상 (hotfix 2 정확 반영)
- enemy 추적 정상
- cameraNode follow 정상
- scene size = iPhone 17 viewport (874×402)로 *.resizeFill 정상 갱신*
- → **모든 코드는 정상이었고, 단지 *시뮬레이터 install 캐시*가 빌드를 반영 안 했던 것**.

### 11-2. hotfix 3 변경
1. **진단 라벨 제거**: `debugLabel` 멤버 / `setupDebugLabel()` / update의 텍스트 갱신 모두 삭제. GameScene 코드 4부분 제거 (선언 1줄, 호출 1줄, 함수 11줄, update 8줄).
2. **D-Pad 가시성 개선**: `GameConfig.dpadAlpha` 0.3 → 0.5. 진단 결과 D-Pad가 화면 우하단에 정상 그려지지만 *반투명 0.3 + 어두운 배경*으로 시각 인식 어려움. 0.5로 올려 *반투명 의도 유지 + 가시성 충분*.

### 11-3. 인사이트
1. **xcodebuild SUCCEEDED ≠ 시뮬레이터 반영**. iOS 시뮬레이터는 *별도 install 단계*. Xcode ⌘R이 install을 *건너뛰는* 경우가 있음 (캐시 충돌, 디바이스 mismatch 등). 디버깅 시 `xcrun simctl uninstall + install + launch`로 *강제 재설치*가 가장 확실.
2. **진단 라벨은 SKLabelNode 1개**로 충분. cameraNode 자식 + zPosition 200 + 화면 정중앙. 한 줄에 *모든 핵심 좌표*를 출력. 다음에도 *시각 검증 실패 시 첫 진단 도구*로 활용 가능.
3. **사용자 경험 ≠ 코드 정확성**의 두 번째 사례. hotfix 1·2가 *코드는 정확했는데* 사용자에겐 *효과 없음*. 사용자 시뮬레이터 환경 자체의 *외부 변수*(install 캐시)가 모든 변경을 차단. **진단 도구가 없으면 *영원히* 원인 못 찾음**.

### 11-4. simctl 명령 재사용 가능 패턴
```bash
xcrun simctl terminate booted com.hg.GanhoMusic
xcrun simctl uninstall booted com.hg.GanhoMusic
xcrun simctl install booted "<DerivedData>/Build/Products/Debug-iphonesimulator/GanhoMusic.app"
xcrun simctl launch booted com.hg.GanhoMusic
```
- bundle id `com.hg.GanhoMusic` (Info.plist `CFBundleIdentifier`).
- DerivedData 경로는 `~/Library/Developer/Xcode/DerivedData/GanhoMusic-<hash>` (xcodebuild 출력에서 확인).
- 시뮬레이터 캐시 의심 시 첫 번째 디버깅 단계로 활용.

---

## 10. 다 읽었다면 다음은?

```
[1] 진단 코드 원복 (showsPhysics 제거, EnemyNode color 원복) — 완료
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] SPEC.md 작성 (직접) → Generator → Evaluator
[4] 합격 시 §9 회고 + 로드맵 갱신
[5] Phase 2-7 (F 투사체) 진입 가능
```

> **본질**: 게임의 *코드 정확성*과 *사용자 경험*은 별개. SpriteKit + UIKit 통합에서 *viewport*는 별도 인프라로 다뤄야. 본 sprint가 *플레이 가능한 게임*의 진짜 시작.
