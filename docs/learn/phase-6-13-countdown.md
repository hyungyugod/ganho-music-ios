# Phase 6-13 — 게임 시작 카운트다운 (3 → 2 → 1 → GO!)

## 한 줄 요약
TitleScene 탭하고 게임 들어가면 *바로* 시작하던 게 이제 **화면 중앙에 큰 숫자 3 → 2 → 1 → GO!**가 1초씩 차례로 떠올랐다 사라져요. GO! 직후에야 음표 스폰·45초 타이머·BGM·플레이어 입력이 *진짜* 시작. 매 숫자에 가벼운 진동, GO!에 묵직한 진동 + "딩!" 소리. 자가 소멸 노드 8호.

---

## 무엇을 했나요?

다섯 식구가 들어왔어요.

1. **CountdownNode** (`Nodes/` 신규) — 자가 소멸 8호. SelfDismissingNode 채택. 4단계 SKAction.sequence가 자체 구동
2. **GameState.countdown** case 1줄 추가 — `.waiting`와 `.playing` 사이
3. **GameConfig 상수 8개** — 폰트(96pt), 페이드인(0.1), 홀드(0.7), 페이드아웃(0.2), GO! 펄스(1.3), GO! 페이드아웃(0.4), GO! 홀드(0.5), zPosition(250)
4. **GameScene** — `didMove` 끝 3줄(spawnSystem.start / gameState = .playing / bgm.play)을 `startGameProperly()` helper로 **byte-identical** 이동 + 그 자리에 `gameState = .countdown` + `showCountdown()` 2줄
5. **pbxproj 4지점** — UUID 0033 (ComboBreakNode 0032 답습)

회귀 0줄: ComboBreakNode / ComboPopupNode / 자가 소멸 노드 7개 전체 / BGMPlayer / SpawnSystem / ScoreSystem / ContactRouter / HapticsManager / AudioManager / HUDNode / 기존 Nodes 14개 / TitleScene / ResultScene / ColorTokens / Repositories / Models / Protocols — **22개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "심호흡"의 시간

```
지금 (Phase 6-12까지)              이번 작업 후 (Phase 6-13)
TitleScene 탭                      TitleScene 탭
    ↓                                 ↓
페이드 전환 (0.4초)                페이드 전환 (0.4초)
    ↓                                 ↓
음표가 *갑자기* 떨어지기 시작!     큰 빨강 "3"
F도 발사됨!                           ↓
45초 타이머도 즉시 카운트!         큰 노랑 "2"
플레이어는 어디 누를지 모름           ↓
                                   큰 분홍 "1"
                                      ↓
                                   민트 "GO!" + 묵직한 진동 + 사운드
                                      ↓
                                   ✅ *이제부터* 음표 스폰
                                   ✅ *이제부터* 45초 타이머
                                   ✅ *이제부터* BGM 페이드인
                                   ✅ *이제부터* 플레이어 이동
```

**3초의 *심호흡***이 없으면 플레이어는 *방어 자세*도 못 잡고 게임이 시작돼버려요.

학생 비유: 100m 달리기에서 출발 신호 없이 *그냥* 뛰어야 한다면? 다들 늦게 출발해 *손해*. 출발 신호(3-2-1-탕!)가 있어야 *공정한 시작*. 게임도 똑같음.

자전적 톤에서, 새벽에 작곡한 BGM이 *서두르지 않고* 자연스럽게 시작되려면 *예고*가 필요해요. 카운트다운이 그 예고를 *시각화* — 플레이어가 음악 전에 *손가락을 D-Pad에 얹고 화면을 살피며 마음을 가다듬는* 시간.

> **Spring 비유**: `@PostConstruct` 직후 트래픽이 *즉시* 들어오면 JIT 컴파일·커넥션 풀 워밍이 안 끝나서 첫 요청들이 *느림*. 카운트다운 = `@ApplicationReadyEvent` 후 워밍업 시간. 트래픽은 *진짜 준비*가 끝나야 받음.

---

## 가장 우아한 결정 — *기존 가드 1줄*이 7개 시스템을 자동으로 정지

이번 sprint에서 *제일 아름다운 부분*이에요.

```swift
// GameScene.update() — 본문 *0줄 변경*
override func update(_ currentTime: TimeInterval) {
    super.update(currentTime)
    guard gameState == .playing else { return }   // ⭐ 이 한 줄이 마법
    // ... 7개 시스템 로직 (타이머/이동/카메라/적/콤보 폴링 등)
}
```

**`.countdown` 상태에서는 이 가드가 자동으로 7개 시스템을 멈춰요**:
- 노트 스폰 (SpawnSystem) → `start()` 호출 자체를 늦춤
- F 투사체 → 동일
- 45초 타이머 → update 안 `remainingTime -= dt` 자동 차단
- D-Pad 입력 반영 → update 안 `player.currentDirection = ...` 자동 차단
- 카메라 follow → update 안 `cameraNode.position = ...` 자동 차단
- 적 추적 AI → update 안 `enemy.update(...)` 자동 차단
- 콤보 폴링 (6-10/6-12) → 자동 차단

**추가 가드 코드 0줄**. 새 if문 0줄. 새 분기 0줄. 그냥 `.countdown` 케이스 1개 추가했을 뿐.

> **Spring 비유**: `@Conditional("running")` 어노테이션 하나로 모든 `@Service`가 *조건부 활성화*. 상태 머신 1개를 *모든 시스템이 공유*하니까 새 상태만 추가하면 *모두 자동 정지*.

학생 비유: 학교에서 *수업 종*이 울리지 않으면 *모든 활동*이 멈춰 있죠. 종 1개가 *모든 교실*을 동시 통제. 새 종소리(.countdown)를 추가하면 모든 교실이 *자동으로 멈춤*.

이게 *상태 머신*의 힘 — *흩어진 if문 7개*를 추가하는 게 아니라 *중앙 가드 1줄*만 활용.

---

## Spring 비유 — 흐름 재구성의 단순함

```
                  Before                                  After (6-13)
                  ──────                                  ────────────
didMove(to:)                                  didMove(to:)
  ├─ setupBackground()                          ├─ setupBackground()
  ├─ setupWorld()                               ├─ setupWorld()
  ├─ ...(13줄, 변경 0)                         ├─ ...(13줄, 변경 0)
  ├─ configureContactRouter()                   ├─ configureContactRouter()
  ├─ spawnSystem.start(...)  ⚠ 즉시 시작        ├─ gameState = .countdown  ← 새 2줄
  ├─ gameState = .playing                       └─ showCountdown()
  └─ bgm.play()
                                              showCountdown() {  // 신규 helper
                                                let node = CountdownNode()
                                                cameraNode.addChild(node)
                                                node.start(
                                                  onTick: { haptics.light() },
                                                  onGo:   { heavy + .comboMilestoneStrong },
                                                  onComplete: { startGameProperly() }
                                                )
                                              }

                                              startGameProperly() {  // 신규 helper
                                                spawnSystem.start(...)   ← 기존 3줄
                                                gameState = .playing     ← byte-identical
                                                bgm.play()               ← 이동
                                              }
```

**기존 3줄이 *그대로 이동*만 했어요**. 한 글자도 안 바뀜 (byte-identical).

> **Spring 비유**: `@PostConstruct`에서 *바로* 트래픽 받던 코드를 `ApplicationReadyEvent` 리스너로 *지연*. 트래픽 처리 로직은 한 글자도 안 바뀌고 *호출 타이밍*만 바뀜. 그게 *3감각 카운트다운*이라는 새 lifecycle event 추가의 본질.

학생 비유: "수업 시작" 종이 울리면 선생님이 *바로* 칠판 쓰던 걸, 이제 *교실 정리 종(카운트다운)* 다음에 *수업 시작 종*이 따로 울리도록 분리. 칠판 쓰는 동작 자체는 같음.

---

## Swift / SpriteKit 학습 포인트

### 4-1. enum case 추가의 *공짜 영향력*

```swift
enum GameState {
    case waiting
    case countdown   // ⭐ Phase 6-13 — 추가만 했는데 7개 시스템이 자동 정지
    case playing
    case paused
    case gameOver
}
```

**왜 이게 *공짜*인가?**
- `guard gameState == .playing else { return }`은 *equality 비교*. `.countdown`은 자동으로 *false* → guard 통과 못함 → update 본문 미실행.
- exhaustive `switch`였다면 *모든 switch에 `.countdown` 케이스 추가*가 강제됨 — 회귀 위험. 다행히 우리 코드는 `==` / `!=`만 쓰고 exhaustive switch 0건. 무료 확장.

**함정 (Generator가 잘 점검한 부분)**: GameState를 *exhaustive switch*로 다루는 곳이 있으면 컴파일 에러. 6-13 Generator는 `grep "switch.*gameState"`로 전수 검사 → 0건 → 안전.

> **Spring 비유**: `enum Role { ADMIN, USER }`에 `GUEST`를 추가했을 때, 모든 `if (role == ADMIN)`은 자동으로 false → 안전. 하지만 모든 `switch (role)`은 *수동* 처리 강제 — Swift도 동일.

### 4-2. SKAction.sequence를 *콜백*으로 외부와 연결

```swift
func start(
    onTick: @escaping (Int) -> Void,    // 3/2/1 각각에서 호출
    onGo: @escaping () -> Void,         // GO! 직후 호출
    onComplete: @escaping () -> Void    // 4단계 + cleanup 끝난 후 호출
) {
    let step3 = stepAction(text: "3", color: .ganhoBloodAccent,
                            beforeAnimate: { [weak self] in
                                self?.label.setScale(1.0)
                                onTick(3)   // ⭐ 외부 콜백
                            })
    // ... step2, step1, stepGo ...
    let cleanup = SKAction.removeFromParent()
    let notify = SKAction.run(onComplete)   // ⭐ 외부 콜백
    run(.sequence([step3, step2, step1, stepGo, cleanup, notify]))
}
```

**왜 *콜백*으로 외부와 연결?**
- 햅틱·사운드는 *Manager에 의존* (HapticsManager / AudioManager). CountdownNode가 직접 알면 *결합도 ↑*.
- 콜백으로 분리하면 CountdownNode는 *순수 시각 + 시퀀스*만 책임. 호출자(GameScene)가 *부가 효과*(햅틱/사운드)를 주입.
- 미래에 다른 Scene에서 CountdownNode를 쓸 때 *다른 부가 효과* 주입 가능 (재사용성 ↑).

> **Spring 비유**: `@Component`가 직접 `slack.send(...)` 호출하면 결합도 ↑. `EventPublisher`를 주입받아 *콜백*으로 이벤트 발행 → listener가 각자 처리. CountdownNode = EventPublisher 패턴.

### 4-3. SKAction.run 안에서 `self` 접근 시 `[weak self]` 필수

```swift
let setup = SKAction.run { [weak self] in
    guard let self = self else { return }
    self.label.text = text          // ⭐ self 사용
    self.label.fontColor = color    // ⭐ self 사용
    self.label.alpha = 0
    beforeAnimate()
}
```

**왜 `[weak self]`?**
- SKAction은 *비동기 실행* — 미래의 어느 시점에 클로저 호출. 그 사이에 노드가 트리에서 제거되거나 Scene이 deinit되면 *강한 참조*는 메모리 누수.
- `[weak self]`로 약한 참조 → `guard let self = self`로 안전 unwrap → self 사용.
- 콜백(`onTick`, `onGo`, `onComplete`)은 *외부 클로저*라 그대로 호출만 — CountdownNode 내부는 self 미사용 → 캡처 불필요.

**Swift 5.7+ `guard let self = self`**: 옛날에는 `guard let strongSelf = self else { return }; strongSelf.label.text = ...`처럼 *임시 이름*이 강제됐는데, 이제 shadowing 가능 → 가독성 ↑.

> **Spring 비유**: `@Async` 메서드 안에서 *부모 빈*에 강한 참조를 유지하면 빈 cleanup 시 회로 문제. WeakReference 비슷한 처리. Swift는 *언어 차원*에서 `[weak self]`를 강제.

### 4-4. SKAction.sequence vs SKAction.group

```swift
// ❌ 4단계가 동시 진행 (group) — 잘못된 패턴
let group = SKAction.group([step3, step2, step1, stepGo])
// → 3, 2, 1, GO! 모두 *동시*에 페이드인/아웃. 카운트다운 의미 0.

// ✅ 4단계가 차례로 진행 (sequence) — 카운트다운 패턴
let sequence = SKAction.sequence([step3, step2, step1, stepGo])
// → 3 끝나면 2, 2 끝나면 1, 1 끝나면 GO! 차례로.

// ✅ GO!의 *내부*는 group — 페이드와 scale이 동시
let holdGroup = SKAction.group([hold, scaleUp])
// → "GO!"가 *커지면서 잠시 머무름* (스케일과 시간이 같이 흐름)
```

**언제 sequence vs group?**
- *차례*로 일어나야 하면 sequence (카운트다운, 노트 스폰 간격, 인트로 컷씬)
- *동시*에 일어나야 하면 group (페이드 + 이동 + scale = 자가 소멸 노드 6/7호의 핵심 패턴)

> **Spring 비유**: `Mono.then()` (sequence) vs `Mono.zip()` (group). Swift SpriteKit은 같은 추상을 SKAction으로 제공.

### 4-5. 함수 추출 (Extract Method)의 우아함

```swift
// Before — didMove가 길어짐
override func didMove(to view: SKView) {
    // ... 13줄 setup ...
    spawnSystem.start(scene: self, world: worldNode, player: player, enemy: enemy,
                      progressProvider: { [weak self] in
                          guard let self = self else { return 0 }
                          return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
                      })
    gameState = .playing
    bgm.play()
}

// After — 3줄을 helper로 추출
override func didMove(to view: SKView) {
    // ... 13줄 setup ...
    gameState = .countdown
    showCountdown()
}

private func startGameProperly() {
    spawnSystem.start(scene: self, world: worldNode, player: player, enemy: enemy,
                      progressProvider: { [weak self] in
                          guard let self = self else { return 0 }
                          return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
                      })
    gameState = .playing
    bgm.play()
}
```

**왜 추출?**
- 3줄을 *byte-identical*로 이동 → 회귀 0 보장.
- 호출 타이밍 변경(`didMove` 즉시 → GO! 콜백)이 *함수 이름*으로 명시 (`startGameProperly`).
- 미래에 *다른 진입점*(예: 일시정지 후 재개)에서도 같은 helper 호출 가능 (확장성).

> **Spring 비유**: `@Bean` 초기화 로직을 `init()`에서 빼서 별도 메서드로 → 다른 lifecycle event(`@RestartHook`)에서도 호출 가능. 응집도 ↑, 재사용성 ↑.

---

## 산출물

**신규 (1 파일)**:
- `Nodes/CountdownNode.swift` (~75줄) — 자가 소멸 8호

**수정 (4 파일)**:
- `Config/GameState.swift` (+1줄) — `.countdown` case
- `Config/GameConfig.swift` (+10줄) — MARK Countdown + 상수 8개
- `GameScene.swift` (+25줄/-3줄) — 헤더 주석 + didMove 끝부분 + showCountdown + startGameProperly + MARK Countdown
- `GanhoMusic.xcodeproj/project.pbxproj` (+4줄) — UUID 0033 4지점

**미접촉 (회귀 0)**:
- ComboBreakNode / ComboPopupNode / 자가 소멸 노드 7개 전체
- BGMPlayer / SpawnSystem / ScoreSystem / ContactRouter / HapticsManager / AudioManager
- HUDNode / PlayerNode / EnemyNode / DPadNode / NoteNode / ProjectileNode / StoneGuardNode 등 14개 Node
- TitleScene / ResultScene
- ColorTokens / PhysicsCategory
- Repositories / Models / Protocols / Errors

---

## 검증 방법

### 정량
- ✅ `xcodebuild` BUILD SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 컴파일 경고 0건, 에러 0건
- ✅ `git diff --name-only HEAD`: 5개 파일만 (Swift 4 + pbxproj 1)
- ✅ AudioManager / BGMPlayer / HapticsManager / ColorTokens 변경 0줄
- ✅ `update()` 본문 변경 0줄 (`guard .playing` 자동 차단 검증)
- ✅ spawnSystem.start 인자 byte-identical 이동
- ✅ QA 점수: **9.9 / 10.0** (Swift 9.7, 로직 10, 성능 10, 완성도 10)

### 시각 (사용자가 시뮬레이터에서 확인)
- [ ] TitleScene 탭 → GameScene 진입 → 빨간 "3" 등장 (1초)
- [ ] "2" 노란색으로 (1초)
- [ ] "1" 분홍색으로 (1초)
- [ ] "GO!" 민트색으로 *살짝 커지며* 등장 + (실기기) heavy 진동 + NewMail 사운드
- [ ] GO! 페이드아웃 직후 음표 스폰 시작 + 45초 타이머 시작 + BGM 페이드인
- [ ] **카운트다운 중 D-Pad 누르면 캐릭터 *이동 안 함*** (gameState != .playing)
- [ ] 카운트다운 중 적이 *추적 안 함*, F 발사 안 됨, 음표 스폰 안 됨, 타이머 감소 안 함, BGM 재생 안 됨
- [ ] GO! 이후 정상 진행 → 콤보 10+ 끊김 시 6-12 ComboBreak 정상 동작 (회귀 0)
- [ ] 게임오버 후 ResultScene → TitleScene 복귀 → 다시 진입 시 카운트다운 *처음부터* 재발화

### 시뮬레이터 한계
- 햅틱은 시뮬레이터에서 noop — 실기기 확인 필요
- 사운드는 시뮬레이터에서도 재생 (NewMail 1025 → macOS 사운드 채널)

---

## 회고

### 막혔던 것
없음. SPEC 단계에서 GameState exhaustive switch 함정·ColorTokens 4색 존재 확인·spawnSystem.start 시그니처 보존을 *미리 적시*했더니 Generator가 빌드 1회로 통과. **상태 머신 가드(`guard .playing`) 한 줄이 7개 시스템을 자동 정지**시키는 발견이 이번 sprint의 *가장 큰 우아함*. 추가 가드 코드 0줄로 회귀 위험을 0으로 보장.

### Spring과 다르네 싶었던 것
1. **enum case 추가의 *공짜 영향력***: Java enum 추가도 비슷하지만, Swift는 *exhaustive switch*가 더 흔해서 더 *조심*해야 함. 본 sprint는 `==` 비교만 써서 무료 확장 가능.
2. **SKAction.sequence를 콜백으로 외부와 연결**: Spring `EventPublisher` 패턴과 동형. 노드가 *부가 효과*를 모르도록 분리 → 결합도 ↓.
3. **`[weak self]`의 언어 차원 강제**: Spring `@Async`에서 부모 빈 참조는 *프로그래머 주의 사항*이지만, Swift는 *문법 차원*에서 명시. Swift가 더 안전.
4. **byte-identical 함수 추출**: Java/Spring에서도 흔하지만 Swift `[weak self]` 캡처 + closure가 *그대로* 옮겨지는 게 인상적. 캡처 의미가 *함수 위치 무관*.

### 평가 점수
- Swift 패턴: 9.7/10 (P2 1건 — GameScene 파일 누적 길이 444줄, 본 sprint 외 부담)
- 게임 로직: 10/10
- 성능: 10/10
- 완성도: 10/10
- **가중: 9.9 / 10.0**

### 사용자 직접 확인할 것
- 실기기에서 GO! heavy 진동 + NewMail 1025 사운드가 *출발 신호*로 자연스러운지
- 카운트다운 3초가 너무 길거나 짧은지 (필요시 GameConfig.countdownHoldDuration 0.7 → 0.5로 조정)
- 민트색 "GO!"가 김간호 머리띠 색과 *통일감* 느껴지는지
- 카운트다운 중 화면 탭이 *무반응*인 게 답답한지 (탭 스킵 기능은 6-14에서 추가 가능)
- TitleScene → GameScene 전환 페이드(0.4초)와 카운트다운 시작이 *자연스럽게* 이어지는지

### 다음 sprint 후보
- **6-14 카운트다운 스킵**: 카운트다운 중 화면 탭하면 즉시 GO!로 점프. `touchesBegan` 1줄 추가.
- **타이머 5초 긴박감**: BGM 피치 상승 + HUD 라벨 깜빡임 + 매초 light 햅틱
- **베스트 스코어 갱신 폴리싱**: ResultScene에서 신기록 시 *황금 빛* + 진동
- **Phase 6 마무리** — 픽셀 아트 + 앱 아이콘
- **Phase 7** — Supabase 백엔드 (Apple Sign In + 리더보드)

---

## 멀티모달 가족 — 13번째 sprint의 누적

| 이벤트 | 촉각 | 청각 | 시각 | 운동감 |
|---|---|---|---|---|
| **시작 카운트다운 (6-13)** | **light × 3 + heavy** | **NewMail × 1 (GO!)** | **CountdownNode 3-2-1-GO!** | — |
| 노트 수집 (6-1/6-2/6-8) | light | Tink 1057 | Sparkle 8방향 | — |
| 콤보 마일스톤 (6-10/6-11) | light/medium/heavy | Tink/NewMail | ComboPopup *위로* ↑ | — |
| 콤보 끊김 (6-12) | heavy | (의도적 제외) | ComboBreak *아래로* ↓ | — |
| 피격 (6-1/6-2/6-9) | heavy | Boop 1073 | HitFlash 빨강 | CameraShake |
| 게임오버 (6-2/6-5) | heavy | Boop 1073 | (Scene 전환) | — |

**Phase 6 시리즈가 13번째 sprint를 거치며 *피드백 시스템*이 완성**됐어요. 이번에 *게임 시작*까지 멀티모달 이벤트 가족에 추가됐죠. 매 sprint는 작은 추가지만 *어떤 게임 순간도 1감각으로 끝나지 않는다*는 정책이 굳건히 정착.

다음 sprint(6-14 or Phase 7)로 가는 길은 어디든 자연 — 멀티모달 가족이 6명(시작/수집/환호/끊김/피격/게임오버)으로 늘었고, 게임의 *모든 주요 순간*이 시각·청각·촉각 중 2개 이상의 채널로 전달됨.

---

## 한 줄 교훈

> **"가장 우아한 변경은 *기존 가드 한 줄이 자동으로 일을 해주는 것*이다."**

이번 sprint에서 *추가 가드 코드*를 한 줄도 안 썼어요. 기존 `guard gameState == .playing`이 *모든 시스템 차단*을 자동으로 해줬으니까. enum case 1개만 추가했을 뿐.

> **Spring 비유**: `@Conditional` 어노테이션이 *조건부 빈 활성화*를 자동 처리. 새 조건만 추가하면 모든 `@Service`가 *자동으로 따라옴*. *상태 머신 1개 + 중앙 가드*가 흩어진 7개 if문보다 강력.

같은 데이터(`gameState`), 같은 가드(`guard .playing`), 같은 시스템 7개. *새 case 하나*가 모든 걸 *공짜로* 멈춰줘요. 이게 *enum + 중앙 가드*의 설계 우아함.

Phase 6은 이제 **13번째 sprint**까지 누적. 게임의 시작·진행·종료 *모든 순간*이 멀티모달. 다음은 어디로 가도 자연.
