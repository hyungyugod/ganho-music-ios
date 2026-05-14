# SPEC.md — Phase 6-14 타이머 긴박감 (5초 이하 BGM 피치 상승 + HUD 깜빡임 + 매초 햅틱)

## 개요
게임 타이머가 5초 이하로 떨어지면 BGM 재생속도(rate)를 1.0 → 1.15로 *서서히* 끌어올려 피치를 함께 상승시키고, HUD `timeLabel`은 빨강(`ganhoBloodAccent`) ↔ 원래색(`ganhoPaper`) 사이를 1초 주기로 깜빡이며, 매초 정수가 바뀔 때(5→4→3→2→1) `haptics.light()`로 카운트의 *심장박동*을 더한다. 0초 도달 시 기존 `endGame()` 경로가 그대로 발화한다 — 새 종료 로직 0건.

## 변경 유형
**혼합** — 청각(BGM rate ramp) + 시각(HUD 라벨 깜빡임) + 촉각(매초 light) 3채널 동시 발화 + 게임 진행 톤 변화. Evaluator는 게임플레이/비주얼 양쪽 기준을 함께 적용.

## 게임 경험 의도
6-13 *카운트다운*이 출발의 *개봉감*을 줬다면, 6-14는 끝의 *긴박감*을 채워 **시작과 끝의 톤이 대칭**을 이루도록 한다. 5초 구간은 한 판의 결정적 *클라이맥스* — 점수 한 톨이라도 더 줍거나, F를 피해 마지막 콤보를 잇는 시간. BGM이 *빨리 감기*처럼 차오르고, 빨강과 원래색을 오가는 시계가 *심박*처럼 뛰면서, 매초 손끝의 톡 — 새벽 작곡 자전 톤에서 *마감 직전 박자가 흐트러지는 순간*을 멀티모달로 체화한다.

## Sprint 범위 계약
- **허용** (SPEC 기능의 정상 동작에 필수적인 최소 연동 변경):
  - `BGMPlayer`에 신규 API 2개: `setRate(_ rate: Float)`, `resetRate()` (재시작/stop 시 1.0 복원)
  - `BGMPlayer.init`에서 `player.enableRate = true` 1줄
  - `HUDNode`에 신규 API 2개: `startTensionBlink()`, `stopTensionBlink()` (timeLabel 깜빡임 액션 부착/제거)
  - `GameConfig`에 신규 상수 5~6개 (임계값/최대 rate/blink 주기/blink 액션 키 등)
  - `GameScene.update` 안에 5초 *진입* 감지 + 매초 정수 변화 감지 + rate 보간 갱신 (3가지 폴링이 같은 if 블록 안에서 함께 처리)
  - `GameScene.endGame` 안에 `hud.stopTensionBlink()` 1줄 (멱등 가드 안쪽)
- **금지** (SPEC에 없는 독립 기능):
  - 카운트다운(6-13) 시점에서의 rate 변경 — `.playing` 외 상태에서는 절대 발화 금지
  - AVAudioEngine + AVAudioUnitTimePitch 전환 (BGMPlayer 전면 개편) — 본 sprint는 `AVAudioPlayer.rate`만 사용
  - 새 ColorTokens 추가 (빨강은 기존 `ganhoBloodAccent` 재사용)
  - 새 Manager / Node / System 파일 신설
  - 5초 외 다른 구간 시각 효과 (이미 6-13/6-8/6-9/6-10/6-11/6-12로 다른 구간은 채워짐)
  - 카운트다운 스킵 / 일시정지 등 별개 기능
- **판단 기준**: "이 변경이 없으면 5초 긴박감이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지

## BGM rate 변경 메커니즘 결정

| 항목 | 결정 | 사유 |
|---|---|---|
| API | `AVAudioPlayer.rate` (`enableRate = true` 필수) | 6-4 `BGMPlayer` 구조 *유지*. AVAudioEngine + AVAudioUnitTimePitch는 전면 개편 → Sprint 범위 초과 |
| 피치 분리 | 분리 안 함 (rate↑ → 피치↑ 동시) | iOS `AVAudioPlayer.rate`의 자연 특성. *영상 빨리감기* 톤 = 마감 직전의 가속감과 의미적으로 일치 |
| rate 범위 | 1.0 → 1.15 (선형, dt 기반 보간) | 0.5~2.0이 안전 구간. 1.15는 *체감되지만 곡 식별성 유지* 균형점 |
| 보간 방식 | 매 프레임 (1.0 + 0.15 × (5 - remainingTime) / 4) | 정수초 점프(0.03씩)보다 매끄러움. dt 기반 이동 정책과 동형 |
| 멱등성 | 같은 rate를 매 프레임 반복 set OK | `AVAudioPlayer.rate` setter는 idempotent (Apple 문서). 별도 dirty-check 불필요 |
| 음원 부재 | guard let player → noop | 6-4 graceful fallback 정책 그대로 |

## 5초 진입 감지 + lastRemainingTime 추적

`GameScene` 프로퍼티 2개 추가:
```swift
/// Phase 6-14 — 5초 긴박감 1회 가드. 같은 판 1회만 setup 발화.
/// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
private var tensionStarted: Bool = false
/// Phase 6-14 — 직전 프레임의 정수초(ceil). 매초 변화 *순간* 감지용.
/// -1 초기값 — 첫 프레임 비교가 자연스럽게 첫 변화로 처리됨.
private var lastRemainingTimeSecond: Int = -1
```

`update(_:)`의 `remainingTime = max(0, remainingTime - dt)` *직후*, `endGame()` early return 전에 *긴박감 폴링 블록* 1개 삽입:
- 5초 진입 (`remainingTime <= tensionWindow && remainingTime > 0`)에서만 동작
- 첫 진입 시 (`!tensionStarted`) 1회만 setup: `hud.startTensionBlink()`. BGM rate는 매 프레임 보간이 자연스럽게 set
- 매 프레임 rate 보간 갱신 (`bgm.setRate(currentRate)`)
- 매초 정수 변화 감지: `let now = max(0, Int(ceil(remainingTime)))` → `if now != lastRemainingTimeSecond && now in 1...4 { haptics.light() }` (5→4부터 4→3, 3→2, 2→1까지 정확히 4회)
- `lastRemainingTimeSecond = now` 갱신

> **5초 진입 멱등성 결정**: 새 Bool 가드 `tensionStarted` 추가 — `airforceTriggered` 같은 *1회 가드* 패턴 답습. 단순/안전/회귀 0.

## HUD timerLabel 깜빡임 위치 결정

**결정: HUDNode 본문에 신규 메서드** `startTensionBlink()` / `stopTensionBlink()`로 캡슐화.

사유:
1. `timeLabel`은 `HUDNode`의 `private` 프로퍼티 → 외부에서 직접 SKAction 부착 불가 (캡슐화 깨면 안 됨)
2. 깜빡임 액션은 *timeLabel 자체*의 colorize SKAction → HUDNode의 도메인 책임
3. `GameScene`은 *언제* 시작/종료할지만 결정 (오케스트레이션) — Manager-같은 책임 경계
4. 6-13 `CountdownNode.start(...)` 콜백 패턴과 동형 — 노드가 시각 동작 자체 책임

구현:
- `startTensionBlink()`: `timeLabel.run(repeatForever([colorize to ganhoBloodAccent (0.5s), colorize to ganhoPaper (0.5s)]), withKey: "tensionBlink")` — `withKey` 사용으로 중복 부착 방지 (SKAction은 같은 key 재부착 시 이전 액션 자동 제거 → 멱등 자연 보장)
- `stopTensionBlink()`: `timeLabel.removeAction(forKey: "tensionBlink")` + `timeLabel.fontColor = .ganhoPaper` (즉시 원색 복원 — 깜빡이는 중간색에서 멈추는 시각 잔상 0)

## BGMPlayer 신규 API

```swift
// MARK: - Tension (Phase 6-14)
/// 재생 속도(피치 포함) 설정. 1.0 = 원본, 1.15 = 5초 긴박감 최대치.
/// enableRate=true가 init에서 켜져 있어야 동작. 음원 부재 시 noop.
/// AVAudioPlayer.rate setter는 idempotent → 매 프레임 호출 안전.
/// 멱등 가드 없음 — 같은 값 반복 set은 Apple이 차단.
/// 0.5 ~ 2.0 범위 권장 (Apple 문서). 본 sprint는 1.0~1.15만 사용.
func setRate(_ rate: Float) {
    guard let player = player else { return }
    player.rate = rate
}

/// rate를 1.0으로 즉시 복원. stop() 안에서도 호출되도록 stop() 본문에 1줄 추가 권장.
/// 재시작 시 새 BGMPlayer 인스턴스라 1.0 자동 시작이지만, 같은 인스턴스 *재진입* 시나리오 안전망.
func resetRate() {
    setRate(1.0)
}
```

`init()` 변경 1줄 (음원 로딩 성공 *후*):
```swift
p.enableRate = true   // Phase 6-14 — rate 변경 활성화 (피치 포함). 6-5 페이드 보간과 독립.
p.numberOfLoops = -1
// ... 기존 라인
```

`stop()` 본문에 1줄 추가 (DispatchWorkItem 안쪽, `player.stop()` 다음):
```swift
self.player?.stop()
self.player?.rate = 1.0   // Phase 6-14 — 다음 라이프사이클 대비 rate 복원 (같은 인스턴스 재진입 안전망)
```

## 변경 범위

### 수정할 파일
- `Config/GameConfig.swift`: MARK Tension (Phase 6-14) 추가, 상수 5개
- `Managers/BGMPlayer.swift`: `init`에 `enableRate = true` 1줄, `stop()`에 rate 복원 1줄, MARK Tension 섹션에 `setRate`/`resetRate` 2개 메서드
- `Nodes/HUDNode.swift`: MARK Tension 섹션에 `startTensionBlink()`/`stopTensionBlink()` 2개 메서드, `timeLabel` 접근만 — `scoreLabel`/`comboLabel`/`nameLabel`은 미접촉
- `GameScene.swift`: 헤더 주석 1줄, 프로퍼티 2개(`lastRemainingTimeSecond`, `tensionStarted`), `update(_:)` 안 긴박감 폴링 블록 ~12줄, `endGame()` 안 `hud.stopTensionBlink()` 1줄 (멱등 가드 안쪽)

### 추가할 파일
없음. 본 sprint는 *기존 파일만* 수정.

## 기능 상세

### 기능 1: BGMPlayer rate API
- 설명: AVAudioPlayer의 `enableRate`를 켜고 `rate`를 외부에서 설정 가능하게 함. 피치도 함께 변함 (Sprint 내 의도된 동작).
- 구현 위치: `Managers/BGMPlayer.swift` — MARK Tension (Phase 6-14) 신규 섹션
- 핵심 코드 구조:
  ```swift
  // init() 안 — 3) 카테고리 설정 다음, 4) numberOfLoops 전
  p.enableRate = true   // Phase 6-14

  // stop()의 DispatchWorkItem 안 — player.stop() 다음
  self.player?.rate = 1.0   // Phase 6-14 — 인스턴스 재진입 안전망

  // MARK: - Tension (Phase 6-14)
  func setRate(_ rate: Float) {
      guard let player = player else { return }
      player.rate = rate
  }
  func resetRate() { setRate(1.0) }
  ```

### 기능 2: HUDNode 깜빡임 API
- 설명: `timeLabel`을 빨강↔원래색 1초 주기로 깜빡이게 하는 시작/종료 API. 액션 키로 멱등 보장.
- 구현 위치: `Nodes/HUDNode.swift` — MARK Tension (Phase 6-14) 신규 섹션
- 핵심 코드 구조:
  ```swift
  // MARK: - Tension (Phase 6-14)
  /// timeLabel을 빨강↔원래색 1초 주기로 깜빡이게 한다. 같은 key로 중복 호출 시 자동 교체(멱등).
  func startTensionBlink() {
      let toRed = SKAction.run { [weak self] in
          self?.timeLabel.fontColor = .ganhoBloodAccent
      }
      let toBase = SKAction.run { [weak self] in
          self?.timeLabel.fontColor = .ganhoPaper
      }
      let wait = SKAction.wait(forDuration: GameConfig.tensionBlinkHalfPeriod)
      let cycle = SKAction.sequence([toRed, wait, toBase, wait])
      timeLabel.run(.repeatForever(cycle), withKey: GameConfig.tensionBlinkActionKey)
  }
  /// 액션 제거 + 색 즉시 원색 복원 (잔상 0).
  func stopTensionBlink() {
      timeLabel.removeAction(forKey: GameConfig.tensionBlinkActionKey)
      timeLabel.fontColor = .ganhoPaper
  }
  ```
- 주의: SKLabelNode의 `colorize` 액션은 `colorBlendFactor` 이슈로 동작이 일관되지 않음 → **fontColor 직접 교체** 패턴 채택 (SKAction.run + wait 4단 반복). 더 안전하고 일관됨.

### 기능 3: GameScene 5초 긴박감 폴링
- 설명: `update(_:)` 안에서 5초 진입을 감지하고, 첫 진입에 1회 setup(HUD blink 시작), 매 프레임 rate 보간 갱신, 매초 정수 변화 시 light 햅틱 발화.
- 구현 위치: `Scenes/GameScene.swift` — `update(_:)` 본문 안, `remainingTime` 감소 *직후* / `endGame()` 호출 *전*. MARK: Game Loop 영역.
- 핵심 코드 구조:
  ```swift
  // Properties 섹션 (기존 lastComboValue 인접)
  /// Phase 6-14 — 5초 긴박감 1회 가드. 같은 판 1회만 setup 발화.
  /// 새 GameScene 인스턴스에서 자동 false 리셋(재시작 안전).
  private var tensionStarted: Bool = false
  /// Phase 6-14 — 직전 프레임의 정수초(ceil). 매초 변화 *순간* 감지용.
  /// -1 초기값 — 첫 프레임 비교가 자연스럽게 첫 변화로 처리됨.
  private var lastRemainingTimeSecond: Int = -1

  // update(_:) — remainingTime 감소 직후, endGame early return 전
  remainingTime = max(0, remainingTime - dt)
  if remainingTime <= 0 {
      endGame()
      return
  }

  // Phase 6-14 — 5초 긴박감 폴링 (.playing 상태에서만, 위 guard 통과 후).
  // 카운트다운(.countdown) 중에는 위 guard에서 이미 차단 → BGM 미재생 상태와 시간 비교차 0.
  if remainingTime <= GameConfig.tensionWindow {
      // 첫 진입 1회 setup
      if !tensionStarted {
          tensionStarted = true
          hud.startTensionBlink()
          // bgm rate는 아래 보간이 매 프레임 set하므로 별도 setup 호출 불필요
      }
      // 매 프레임 rate 보간: 1.0 + 0.15 × (5 - remainingTime) / 5
      let progress = Float((GameConfig.tensionWindow - remainingTime) / GameConfig.tensionWindow)
      let clamped = max(0, min(1, progress))
      let rate = GameConfig.tensionRateBase + (GameConfig.tensionRateMax - GameConfig.tensionRateBase) * clamped
      bgm.setRate(rate)
      // 매초 정수 변화 시 light 햅틱 (5→4, 4→3, 3→2, 2→1 = 4회)
      let now = max(0, Int(ceil(remainingTime)))
      if now != lastRemainingTimeSecond {
          lastRemainingTimeSecond = now
          if now >= 1 && now <= 4 {
              haptics.light()
          }
      }
  }

  // 기존 콤보 윈도우 만료 검사 / D-Pad / player 갱신 / 카메라 follow / enemy 추적 / HUD 갱신 / 콤보 끊김 폴링 (변경 0)
  ```

### 기능 4: endGame 정리
- 설명: `endGame()` 멱등 가드 안쪽에 `hud.stopTensionBlink()` 1줄 추가. 0초 만료 / F 피격 / enemy 접촉 어느 경로든 깜빡임 즉시 종료.
- 구현 위치: `Scenes/GameScene.swift` — `endGame()` 본문, `bgm.stop()` 다음 줄
- 핵심 코드 구조:
  ```swift
  audio.play(.gameOver)
  bgm.stop()                   // 6-4 — rate는 stop 내부 DispatchWorkItem에서 1.0 복원
  hud.stopTensionBlink()       // Phase 6-14 — 깜빡임 즉시 종료 (잔상 0)
  spawnSystem.stop()
  // ... 이하 기존 그대로
  ```
- `bgm.stop()`의 페이드아웃 1초가 끝난 *후* DispatchWorkItem이 rate=1.0 복원 — 페이드아웃 중에는 rate가 1.15 유지된 채 볼륨이 줄어 자연스럽게 사그라듦.

### 기능 5: GameConfig 상수 5개
- 설명: 매직 넘버 0건 정책 유지. 모든 신규 값은 GameConfig.
- 구현 위치: `Config/GameConfig.swift` — 파일 끝부분에 새 MARK 섹션
- 핵심 코드 구조:
  ```swift
  // MARK: - Tension (Phase 6-14)
  /// 5초 긴박감 발화 시작 임계값 (초). remainingTime이 이 값 이하로 떨어지면 폴링 진입.
  static let tensionWindow: TimeInterval = 5.0
  /// BGM rate 시작값 (1.0 = 원본).
  static let tensionRateBase: Float = 1.0
  /// BGM rate 최대값 (1.15 = 영상 빨리감기 톤, 피치 포함). 0.5~2.0 권장 범위 중 안전.
  static let tensionRateMax: Float = 1.15
  /// 깜빡임 한 색 머무는 길이 (초). 총 1초 주기 = 빨강 0.5 + 원색 0.5.
  static let tensionBlinkHalfPeriod: TimeInterval = 0.5
  /// HUDNode timeLabel 깜빡임 SKAction 키. 중복 호출 시 자동 교체(멱등) 보장.
  static let tensionBlinkActionKey: String = "tensionBlink"
  ```

## 6-13까지의 회귀 0 영역

본 sprint가 *미접촉*해야 하는 영역 (Evaluator가 grep 검증):

- **자가 소멸 노드 8개 전체** (AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode / ComboPopupNode / ComboBreakNode / CountdownNode) — Sprint 본문에서 import / 호출 0건
- **ContactRouter** — 충돌 분기 변경 0
- **ScoreSystem / SpawnSystem** — 시그니처/본문 변경 0
- **PlayerNode / EnemyNode / DPadNode / NoteNode / ProjectileNode / StoneGuardNode** — 변경 0
- **TitleScene / ResultScene** — 변경 0
- **AudioManager / HapticsManager** — 시그니처/본문 변경 0 (기존 `haptics.light()` 호출만 추가)
- **Repositories / Models / Protocols / Errors** — 변경 0
- **ColorTokens** — 신규 색 추가 0 (`ganhoBloodAccent`/`ganhoPaper` 재사용만)
- **GameScene+Setup** — 변경 0 (setup 함수는 모두 미접촉)
- **HUDNode 기존 4 라벨** — `scoreLabel`/`comboLabel`/`nameLabel`/`init`/`update`/`setCharacterName`/`configure` 변경 0. *추가 메서드만* 신설.
- **BGMPlayer 6-5/6-6/6-7 로직** — 페이드 / Interruption / 라이프사이클 변경 0. `init`에 `enableRate=true` 1줄 + `stop()`에 rate 복원 1줄 + 신규 메서드 2개만.
- **카운트다운(6-13) 시간 비교차 0**: 카운트다운 중에는 `.countdown` 상태 → `update`의 `guard gameState == .playing` 가드가 모든 폴링을 *자동 차단*. 5초 폴링도 동일 가드 *안쪽*에 위치하므로 카운트다운 중 rate 변경 무의미·발화 불가 보장. BGM 미재생 상태와 시간상 *완전 비교차*.

## 주의사항

### 기존 코드와 충돌 가능성

1. **`update(_:)` 폴링 순서**: 5초 폴링은 `remainingTime -= dt` *직후*, `endGame()` early return *전*, 콤보 만료 검사 *전*에 배치. 0초 도달 시 폴링 *없이* 즉시 endGame — 4→1 햅틱 발화 후 0 도달이라 정확히 light × 4회 (5→4, 4→3, 3→2, 2→1).
2. **`hud.update(...)` 매 프레임 호출**: 기존 코드가 `comboLabel.alpha`를 조건부로 갱신하지만 `timeLabel`은 매 프레임 `text`만 갱신. `fontColor` 변경은 SKAction이 백그라운드에서 처리하며 `text` 갱신과 독립. 단, `update(score:remainingTime:combo:)` 본문은 변경 0.
3. **6-13 카운트다운 동시 발생 0**: 카운트다운 중 `remainingTime` 감소 차단됨 → 5초 폴링 미발화 보장. 카운트다운(2~3초) + 5초 윈도우(5초) = 시간상 *겹칠 일 0*.
4. **6-12 콤보 끊김 폴링과 동시 발생 OK**: 한 프레임에 콤보 끊김 + 5초 진입이 동시 발생 가능 — 두 폴링은 다른 if 블록, 다른 채널(콤보 = heavy + ComboBreakNode / 긴박감 = light + BGM rate + HUD 깜빡임). 충돌 없음.

### SpriteKit 특성상 주의할 점

5. **SKLabelNode colorize 회피**: 일부 SpriteKit 버전에서 `SKLabelNode`의 `colorize` 액션이 폰트 색 보간이 일관되지 않음. **fontColor 직접 교체** 패턴 채택 (SKAction.run + wait 4단 반복). 더 안전하고 일관됨.
6. **`SKAction.repeatForever` + `withKey` 멱등**: 같은 키로 재호출 시 SpriteKit이 이전 액션을 자동 제거하고 새 액션 부착. 별도 `tensionStarted` 가드와 *이중* 멱등 — 안전.
7. **`AVAudioPlayer.rate`와 `setVolume(fadeDuration:)` 독립**: 페이드 보간(볼륨)과 rate(속도)는 별개 채널. 동시 적용 가능. `stop()`의 페이드아웃 1초 동안 rate=1.15 유지 → 페이드아웃 끝에 rate=1.0 복원이 자연스러움.

### 빌드 에러 가능성

8. **`AVAudioPlayer.enableRate` 위치**: `numberOfLoops = -1` 라인 *전*에 두면 안전. `prepareToPlay()` *전*에 설정. Apple 문서 권장 순서.
9. **`Float` vs `CGFloat` 혼용 주의**: `AVAudioPlayer.rate`는 `Float` 타입. `tensionRateBase`/`tensionRateMax`는 `Float`로 선언. `progress` 계산 시 `TimeInterval`(Double) → `Float` 캐스팅 필요 (`Float(progress)`).
10. **`Int(ceil(remainingTime))` 캐스팅**: `remainingTime`이 `TimeInterval` (Double). `ceil` 후 `Int` 변환 — overflow 위험 0 (45 이하 양수).
11. **신규 파일 0개**: pbxproj 변경 0건 — 4지점 등록 불필요. Generator 작업 부담 감소.

### 시각 검증 (사용자 시뮬레이터에서)

- [ ] 5초 진입 *순간* HUD timeLabel 빨강으로 즉시 전환 시작
- [ ] 5초~1초 동안 BGM이 점점 빨라지고 살짝 높아짐 (음원 부재 시 noop OK)
- [ ] 매초(5→4, 4→3, 3→2, 2→1) 실기기에서 light 진동 4회
- [ ] 0초 도달 → endGame → 빨강 깜빡임 즉시 멈춤, BGM 페이드아웃 1초
- [ ] ResultScene 진입 후 BGM 완전 정지, 다음 게임 진입 시 rate=1.0으로 정상 시작
- [ ] F 피격으로 5초 이전 게임오버 → 깜빡임 발화 0, rate 변경 0 (회귀 0)
- [ ] 5초 진입 후 F 피격 → 깜빡임 즉시 멈춤 + 페이드아웃 중 rate 자연 정지
