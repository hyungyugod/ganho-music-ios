# Phase 6-7 — 앱 백그라운드/포그라운드 라이프사이클에 따른 BGM 일시정지/재개

## 개요
사용자가 홈 버튼/앱 스위처/제어센터/카톡 알림 클릭 등으로 앱을 백그라운드로 보내면 SpriteKit이 게임을 자동 일시정지하지만 BGM은 `.playback` 카테고리 덕에 혼자 계속 흐른다. 이 부조화를 해소하기 위해 `UIApplication.didEnterBackgroundNotification` / `willEnterForegroundNotification`을 `BGMPlayer`에서 구독하여 BGM도 함께 일시정지/재개한다. 6-6의 private `pause()` / `resume()`을 그대로 재사용하고, "원래 재생 중이었는가"를 기억하는 새 플래그 하나만 추가한다.

## 변경 유형
**폴리싱 / 라이프사이클 안정성** — 게임 핵심 루프 변경 없음. Manager 내부 라이프사이클 옵저버 증설.

## 게임 경험 의도
플레이어가 게임 중 카톡 알림을 보러 잠깐 나갔다가 다시 돌아왔을 때, BGM이 "어색하게 혼자 흐르다 끊기는 일" 없이 자연스럽게 살아난다. 게임 화면이 멈춰 있는 동안 음악도 함께 숨을 죽이고, 다시 화면이 켜지면 음악도 함께 깨어나는 "한 호흡 같은" 일관성을 만든다. 사용자 의도(홈 버튼)에 시스템이 양보하는 6-6의 철학을 라이프사이클 차원으로 확장한 것.

## Sprint 범위 계약

### 허용
- `BGMPlayer.swift` 내부에 라이프사이클 옵저버 **2개**(`didEnterBackground` + `willEnterForeground`) 추가
- `init`에 옵저버 등록 (6-6 interruption 옵저버 다음에 이어 붙임)
- `deinit`에 변화 없음 (`removeObserver(self)` 한 줄이 모든 옵저버 일괄 해제 — 추가 코드 0줄)
- 새 `private var shouldResumeOnForeground: Bool = false` 1개 추가
- 새 `@objc private` 메서드 2개(`handleDidEnterBackground(_:)`, `handleWillEnterForeground(_:)`)
- 파일 헤더 주석에 Phase 6-7 1줄 추가
- `import UIKit` 추가 (`UIApplication.*Notification`은 UIKit 심볼)

### 금지
- `GameScene.swift` / `TitleScene.swift` / `ResultScene.swift` 변경 (BGM 호출 지점 그대로 유지)
- `AudioManager.swift` / `HapticsManager.swift` 변경 (BGM 단독 sprint)
- `GameConfig.swift`에 새 상수 추가 (시간/지연 없음 — pause/resume은 즉시)
- 새 `public` 메서드 / 새 외부 API 노출 (전부 `private`)
- `AVAudioSession` 카테고리 변경 (`.playback` + `.mixWithOthers` 그대로)
- 게임 자체 일시정지 UI / pause overlay 신설
- `SKView.isPaused` / `Scene.isPaused` 직접 조작 (SpriteKit이 자동 처리)
- `Repository`, 새 음원, 새 효과음 추가
- 6-6의 `pause()` / `resume()` / `handleInterruption(_:)` 시그니처/로직 수정

### 판단 기준
"이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지.

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Managers/BGMPlayer.swift`:
  - 헤더 주석에 Phase 6-7 1줄 추가
  - `import UIKit` 추가
  - 새 프로퍼티 `shouldResumeOnForeground` 1개
  - `init`에 라이프사이클 옵저버 2개 등록 추가
  - 새 `@objc private` 메서드 2개

### 추가할 파일
- 없음.

## 기능 상세

### 기능 1: UIKit import 및 헤더 주석 갱신
- 설명: `UIApplication.didEnterBackgroundNotification`, `willEnterForegroundNotification`은 UIKit 심볼이라 import 필요
- 구현 위치: `BGMPlayer.swift` 파일 최상단
- 핵심 코드 구조:
  ```swift
  //
  //  BGMPlayer.swift
  //  GanhoMusic Shared
  //
  //  Phase 6-4 · 자작 BGM 무한 루프 재생 인프라 (graceful fallback)
  //  Phase 6-5 · play/stop에 페이드 인(1.5s) / 아웃(1.0s) 적용
  //  Phase 6-6 · Interruption 처리 — 전화/Siri/타이머 등 시스템 인터럽션 시 BGM 자동 일시정지/복귀
  //  Phase 6-7 · 백그라운드/포그라운드 라이프사이클 — 홈 버튼/앱 스위처 시 BGM 일시정지/재개
  //

  import AVFoundation
  import UIKit  // Phase 6-7 — UIApplication.*Notification 사용
  ```

### 기능 2: 상태 보관 플래그 `shouldResumeOnForeground`
- 설명: 백그라운드 진입 시점에 "원래 재생 중이었는가"를 기록. 포그라운드 복귀 시 이 플래그가 true일 때만 `resume()` 호출. 게임 진입 안 함 / `gameOver` 후 / 음원 부재 환경에서는 false 유지하여 의도 없는 재생 차단.
- 구현 위치: `BGMPlayer.swift` `// MARK: - Properties` 섹션 (기존 `isFadingOut`, `stopWorkItem` 옆)
- 핵심 코드 구조:
  ```swift
  /// Phase 6-7 — 백그라운드 진입 시점에 player.isPlaying이 true였는지 기록.
  /// 포그라운드 복귀 시 이 비트가 켜져 있을 때만 resume() 호출.
  /// 게임 미진입/gameOver 후/음원 부재 등 *원래 안 울리던* 상황은 false 유지.
  /// Spring `@Stateful`(혹은 scope=session 빈)의 짧은 변형 — 라이프사이클 페어를 잇는 일회용 메모.
  private var shouldResumeOnForeground: Bool = false
  ```

### 기능 3: `init`에 라이프사이클 옵저버 2개 등록
- 설명: 6-6의 interruption 옵저버 등록 *바로 다음 줄*에 이어 붙임. 6-6과 동일한 selector 방식으로 일관성 확보. 음원 로딩 성공한 이후 시점이므로 시뮬레이터/리소스 누락 환경에서는 옵저버 자체가 등록되지 않아 NotificationCenter에 군더더기 0.
- 구현 위치: `BGMPlayer.swift` `init()` 끝, 6-6 옵저버 등록 직후
- 핵심 코드 구조:
  ```swift
  // (기존 6-6 interruption 옵저버 등록 코드 그대로)
  NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
  )

  // Phase 6-7 — 앱 라이프사이클 옵저버 페어.
  // 페어 관계: didEnterBackground(앱이 background phase로 진입한 직후 발행)
  //         ↔ willEnterForeground(suspended→inactive로 깨어나기 직전 발행).
  // selector 일관성: 6-6과 동일하게 selector 방식. block 방식과 섞으면 deinit 정리가 복잡.
  // object: nil — 시스템이 단 하나의 UIApplication.shared만 발행하므로 필터 불필요.
  NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDidEnterBackground(_:)),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
  )
  NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillEnterForeground(_:)),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
  )
  ```

### 기능 4: `handleDidEnterBackground(_:)` — 백그라운드 진입 콜백
- 설명: 백그라운드 진입 시점에 `player.isPlaying`이 true면 `shouldResumeOnForeground = true`로 기록 후 `pause()` 호출. 이미 멈춰 있었거나(`isPlaying == false`) 음원 부재(`player == nil`)면 noop. 6-6의 `pause()` 그대로 재사용 — `isFadingOut` 가드 덕에 페이드 아웃 중 호출돼도 멱등.
- 구현 위치: `BGMPlayer.swift` 신설 `// MARK: - Lifecycle` 섹션 (`// MARK: - Interruption` 다음)
- 핵심 코드 구조:
  ```swift
  // MARK: - Lifecycle
  /// Phase 6-7 — 앱이 백그라운드로 진입한 직후 시스템이 발행.
  /// 발생 예: 홈 버튼, 앱 스위처, 제어센터에서 다른 앱 진입, 전화/카톡 알림 클릭.
  /// 의도성: 사용자 의도(자발적) — interruption(시스템 강제)과 결이 다름.
  /// Spring `@EventListener` 비유 — 앱 컨테이너의 phase 변경 이벤트를 받아 디스패치.
  @objc private func handleDidEnterBackground(_ notification: Notification) {
      guard let player = player else { return }       // 음원 부재 시 자동 noop
      if player.isPlaying {
          shouldResumeOnForeground = true             // 복귀 시 깨우라는 메모
          pause()                                     // 6-6의 private pause() 재사용
      }
      // else: 원래 안 울리던 상태 — 플래그 false 유지 (변경 안 함)
  }
  ```

### 기능 5: `handleWillEnterForeground(_:)` — 포그라운드 복귀 콜백
- 설명: 플래그가 true일 때만 `resume()`(= `play()`) 호출, 호출 직후 플래그 false로 리셋. `play()` 내부의 `isPlaying` 가드 + `stopWorkItem.cancel()` + `isFadingOut = false`가 어떤 진입 상태든 흡수.
- 구현 위치: `BGMPlayer.swift` `// MARK: - Lifecycle` 섹션 내, `handleDidEnterBackground` 다음
- 핵심 코드 구조:
  ```swift
  /// Phase 6-7 — 앱이 곧 포그라운드로 돌아갈 시점에 시스템이 발행
  /// (UIApplicationWillEnterForeground — active 진입 *직전*, 화면이 사용자에게 보이기 직전).
  /// shouldResumeOnForeground 비트가 켜져 있을 때만 resume — 의도 없던 재생 금지.
  /// 호출 직후 플래그 false로 리셋하여 다음 라이프사이클 페어를 깨끗이 시작.
  @objc private func handleWillEnterForeground(_ notification: Notification) {
      guard shouldResumeOnForeground else { return }
      shouldResumeOnForeground = false                // 페어 종료 — 다음 사이클 위한 리셋
      resume()                                        // 6-6의 private resume() → play() 재사용
  }
  ```

### 기능 6: `deinit` 변경 없음
- 설명: 6-6의 `NotificationCenter.default.removeObserver(self)` 한 줄이 self가 등록한 *모든* 옵저버를 일괄 해제하므로 추가 코드 불필요. 옵저버를 더 등록하더라도 deinit 본문은 그대로.
- 구현 위치: `BGMPlayer.swift` `// MARK: - Deinit`
- 핵심 코드 구조:
  ```swift
  // 변경 없음 — removeObserver(self)가 6-6 + 6-7 옵저버 3개 모두 일괄 해제.
  deinit {
      NotificationCenter.default.removeObserver(self)
  }
  ```

## 사용할 Notification 정확히 명시

| 이름 | 발행 시점 | 페어 |
|---|---|---|
| `UIApplication.didEnterBackgroundNotification` | 앱이 background phase로 진입 *직후*. `applicationDidEnterBackground(_:)`와 같은 시점. SpriteKit이 이미 `isPaused = true`를 자동 적용한 직후. | ↓ |
| `UIApplication.willEnterForegroundNotification` | suspended → inactive로 깨어나기 *직전*. 화면이 사용자에게 다시 보이기 직전. `applicationWillEnterForeground(_:)`와 동시점. | ↑ |

페어 관계: 매 백그라운드/복귀 사이클마다 정확히 1쌍 발행됨. 한 사이클의 시작과 끝.

## 백그라운드 진입 시 처리 흐름

```
1. 사용자 홈 버튼 누름
2. iOS가 SpriteKit 자동 일시정지 (SKView.isPaused = true)
3. UIApplication.didEnterBackgroundNotification 발행
4. BGMPlayer.handleDidEnterBackground(_:) 호출됨
5. player.isPlaying 확인:
   - true → shouldResumeOnForeground = true, pause() 호출
   - false → noop (게임 안 시작했거나, 이미 gameOver 후)
6. pause() 내부:
   - player == nil → guard로 즉시 return (음원 부재)
   - isFadingOut → guard로 즉시 return (페이드 아웃 중 — "끝나는 중인 음악은 그냥 끝나게")
   - 그 외 → player.pause() (currentTime 보존)
```

## 포그라운드 복귀 시 처리 흐름

```
1. 사용자 앱 스위처에서 다시 앱 선택
2. UIApplication.willEnterForegroundNotification 발행
3. BGMPlayer.handleWillEnterForeground(_:) 호출됨
4. shouldResumeOnForeground 확인:
   - false → 즉시 return (원래 안 울리던 상태)
   - true → 플래그 false로 리셋 → resume() 호출
5. resume() = play() 재호출. play() 내부:
   - player == nil → guard로 noop
   - player.isPlaying == true → return (이미 어떤 이유로 살아 있음 — 중복 차단)
   - 그 외 → stopWorkItem 정리, isFadingOut 리셋, volume=0 → play() → 1.5s 페이드 인
6. SpriteKit도 view가 다시 active되면 자동 isPaused = false 복원
```

## interruption(6-6)과 background(6-7) 교차 시나리오

### 시나리오 A: 전화 옴 → 통화 받으러 화면 전환
```
t=0  전화 옴
t=0  interruption began 발행 → handleInterruption(.began) → pause() 호출
     · player.pause() 실행됨
t=0+ 사용자가 통화 받기 탭 → 앱이 백그라운드로
t=0+ didEnterBackground 발행 → handleDidEnterBackground 호출
     · player.isPlaying == false (방금 pause됨) → noop, 플래그 false 유지
t=N  통화 끝, 사용자가 앱으로 복귀
t=N  willEnterForeground 발행 → handleWillEnterForeground 호출
     · shouldResumeOnForeground == false → noop (resume 안 함)
t=N  interruption ended (.shouldResume) 발행 → handleInterruption(.ended)
     · resume() → play() → 페이드 인 재개  ← 이게 *유일한* 진입점
```
→ 결론: 6-6이 책임지고 깨움. 6-7은 끼어들지 않음 (플래그 false 유지). **이중 재생 0**.

### 시나리오 B: 게임 중 홈 버튼 → 다시 복귀
```
t=0   게임 정상 진행, player.isPlaying == true
t=0+  홈 버튼
t=0+  didEnterBackground → handleDidEnterBackground
      · isPlaying true → shouldResumeOnForeground = true, pause()
t=N   앱 재진입
t=N   willEnterForeground → handleWillEnterForeground
      · 플래그 true → false로 리셋 → resume() → play() → 페이드 인
```
→ 결론: 깔끔한 단일 페어. **6-7만 작동**.

### 시나리오 C: 페이드 아웃 진행 중 백그라운드
```
t=0    gameOver → bgm.stop() → isFadingOut = true, stopWorkItem 예약 (1.0초 후 player.stop())
t=0.5  사용자 홈 버튼 (페이드 아웃 중)
t=0.5  didEnterBackground → handleDidEnterBackground
       · player.isPlaying == true (페이드 아웃 중에도 isPlaying=true)
       · shouldResumeOnForeground = true
       · pause() 호출 → isFadingOut 가드로 noop ("끝나는 중인 음악은 그냥 끝나게")
t=1.0  stopWorkItem 실행 → player.stop(), isFadingOut = false
       ※ 백그라운드에서도 DispatchQueue.main은 일정 시간 살아 있음. 다만 long-suspend 시 보류될 수 있는데, 이 경우 player.stop()이 늦게 실행되어도 isPlaying이 자연스럽게 false로 가는 시점이라 문제 없음.
t=N    포그라운드 복귀 → handleWillEnterForeground
       · 플래그 true → false로 리셋 → resume() = play()
       · play() 내부: isPlaying == false → 정상 재진입 → 페이드 인
```
→ 결론: gameOver 직후 백그라운드 가도 *복귀 시 BGM이 살아남*. 의도는? **버그가 아니라 정상**. resume의 의미는 "백그라운드 진입 시점에 살아 있었다면 다시"이므로 페이드 아웃 중도 "살아 있었다"로 친다. 후속 sprint에서 정책 조정 가능 (본 sprint 범위 밖).

### 시나리오 D: 통화 중 백그라운드 → 통화 끝 후 복귀
```
t=0  전화 → interruption began → pause() (isPlaying false)
t=0+ 백그라운드 → handleDidEnterBackground
     · isPlaying false → noop, 플래그 false 유지
t=N  통화 끝, 앱 재진입
t=N  willEnterForeground → handleWillEnterForeground
     · 플래그 false → noop
t=N  interruption ended → handleInterruption(.ended) → resume()
```
→ 결론: 6-6 책임. 6-7은 가만히 있음. **OK**.

## shouldResumeOnForeground 상태 관리 매트릭스

| 상황 | 시점 | 플래그 |
|---|---|---|
| 초기화 직후 | `init` 끝 | false |
| 게임 미진입 (TitleScene) | - | false 유지 |
| 게임 시작, BGM 재생 중 + 백그라운드 진입 | `handleDidEnterBackground` | **true 세팅** |
| 게임 시작 안 함 + 백그라운드 진입 | `handleDidEnterBackground` | false 유지 (isPlaying false) |
| gameOver 후 + 백그라운드 진입 | `handleDidEnterBackground` | false 유지 (isPlaying false) |
| 음원 부재 + 백그라운드 진입 | `handleDidEnterBackground` | false 유지 (guard로 즉시 return) |
| 포그라운드 복귀, 플래그 true | `handleWillEnterForeground` | **false 리셋** + resume() |
| 포그라운드 복귀, 플래그 false | `handleWillEnterForeground` | false 유지, noop |
| 통화로 인한 pause 상태 + 백그라운드 | `handleDidEnterBackground` | false 유지 (isPlaying false) |

## 검증 시나리오

### (a) 빌드
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0
- `import UIKit` 추가됨

### (b) 음원 부재 폴백 (회귀 0)
- `bgm.m4a` 없음 → init 첫 guard에서 player = nil → 옵저버 등록 자체 안 됨
- handleDidEnterBackground/handleWillEnterForeground 호출 자체 안 일어남

### (c) 6-6 코드 무변경 검증
- `handleInterruption(_:)` 시그니처/본문 0줄 변경
- `pause()` 시그니처/본문 0줄 변경
- `resume()` 시그니처/본문 0줄 변경

### (d) 백그라운드 진입 — 재생 중일 때
- player.isPlaying == true 상태에서 didEnterBackgroundNotification 발행
- shouldResumeOnForeground = true 세팅
- pause() 호출 → player.pause() 실행

### (e) 포그라운드 복귀 — 플래그 true
- shouldResumeOnForeground == true 상태에서 willEnterForegroundNotification 발행
- 플래그 false로 리셋
- resume() → play() → 페이드 인

### (f) 시나리오 A 통화 → 백그라운드 — 6-7 noop
- 6-6 pause() 후 player.isPlaying = false
- 백그라운드 진입 시 isPlaying false라 6-7 노op, 플래그 false 유지
- 포그라운드 복귀 시 플래그 false라 6-7 noop
- 6-6 ended가 단독으로 resume 책임

### (g) deinit 무변경
- removeObserver(self) 한 줄로 3개 옵저버 일괄 해제

### (h) 회귀 0줄
- GameScene/AudioManager/HapticsManager/GameConfig/TitleScene/ResultScene/Nodes/Systems/Repositories/Models/Protocols 모두 0줄

### (i) Phase 1~6 회귀
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터 선택/AIRFORCE/페이드/Interruption 모두 정상

## 학습 가치

### 1. UIApplication 라이프사이클 vs AVAudioSession interruption
| 축 | interruption (6-6) | lifecycle (6-7) |
|---|---|---|
| 발행자 | AVAudioSession | UIApplication |
| 트리거 | 전화/Siri/알람 등 *시스템이 오디오 자원을 빼앗을 때* | 홈 버튼/앱 스위처 등 *사용자가 앱을 떠날 때* |
| 의도성 | 강제 (사용자가 원치 않아도 발생) | 자발적 (사용자가 능동적으로 선택) |
| 페어 | began ↔ ended (+ shouldResume 비트) | didEnterBackground ↔ willEnterForeground |
| 복귀 조건 | `.shouldResume` 플래그가 시스템 결정 | `shouldResumeOnForeground`가 *우리* 결정 |
| Spring 비유 | `@TransactionalEventListener` (시스템 트랜잭션 인터럽트) | `@ServletRequestListener` (request lifecycle) |

→ "오디오를 뺏긴다"와 "앱이 멀어진다"는 **다른 사건**이지만 BGMPlayer 입장에선 결국 "지금 안 들려야 하는 상황"이라는 점에서 같은 처치(pause)가 정답. 6-5/6-6의 pause/resume 메서드를 DRY로 재사용 가능한 이유.

### 2. "상태를 기억하는" 패턴 — `shouldResumeOnForeground`
- **문제**: 백그라운드 진입 시점과 복귀 시점은 *다른 콜백*. 두 콜백을 잇는 데이터가 없으면 복귀 시 "원래 재생 중이었나?" 알 수 없음.
- **해결**: 인스턴스 변수로 짧은 메모 남김. 일종의 **상태 머신**.
- Spring 비유:
  - `@Stateful` 빈처럼 빈 내부에 상태 보관. (Spring 자체 어노테이션은 아니지만 EJB 발상)
  - 혹은 `scope=session` 빈 — HTTP request 하나가 끝나도 다음 request에서 상태 이어짐
  - 또는 일종의 *correlation id* — 이벤트 페어를 잇는 식별자
- 중학생 비유: "엄마가 잠깐 나갔다 들어올 때, 나갈 때 켜져 있던 TV를 다시 켤지 말지 결정하려면 '나갈 때 켜져 있었는지' 메모지에 적어둬야 한다. 메모 없으면 들어와서 알 길이 없다." 그 메모지가 `shouldResumeOnForeground`.

### 3. 옵저버 패턴의 일반화 — 단일 → 다중
- 6-6: 옵저버 1개 (interruption)
- 6-7: 옵저버 +2 → 총 3개 (interruption + didBackground + willForeground)
- **옵저버 매트릭스**가 됨. 각 옵저버는 *독립적인 콜백*이지만 *공유 자원*(`player`, `isFadingOut`, `shouldResumeOnForeground`)을 읽고 쓴다.
- 핵심 통찰: `removeObserver(self)` 한 줄이 N개 옵저버를 일괄 해제 → **선언적 정리**. 옵저버 추가할 때마다 deinit을 안 건드려도 됨.
- Spring 비유: `@EventListener` 메서드를 빈에 여러 개 두면 ApplicationContext가 빈 소멸 시 자동 해제 → 같은 발상.

### 4. 멱등성 + 가드의 누적 가치
세 phase에 걸쳐 쌓인 가드가 함께 작동:

| Phase | 가드 | 효과 |
|---|---|---|
| 6-5 | `isFadingOut` (stop 중복 차단) | 페이드 아웃 중 stop 다시 들어와도 안전 |
| 6-5 | `stopWorkItem.cancel()` (play 시) | 페이드 아웃 중 play 들어오면 예약 stop 취소 |
| 6-6 | `pause()` 내 `isFadingOut` 가드 | "끝나는 중인 음악은 그냥 끝나게" |
| 6-6 | `play()` 내 `isPlaying` 가드 | 이미 재생 중일 때 중복 play 차단 |
| **6-7** | **`shouldResumeOnForeground` 플래그** | **의도 없던 백그라운드 → 복귀 시 깨우지 않음** |

→ 어떤 순서로 어떤 이벤트가 와도 (전화 → 백그라운드 → 통화 끝 → 복귀, 또는 페이드 아웃 → 백그라운드 → 복귀 등) **이중 재생 0, 의도 없는 재생 0, 크래시 0**.

### 5. 시스템과의 협력 — "양보"의 누적
- **6-6**: 시스템 인터럽션에 양보 ("전화가 더 중요하다, 음악은 비키자")
- **6-7**: 사용자 의도에 양보 ("홈 버튼 누른 사용자가 더 중요하다, 음악은 비키자")
- 두 phase 모두 BGMPlayer가 *주도하지 않고 응답*하는 패턴. 시스템과 사용자 모두에게 "good citizen"이 되는 길.

### 6. `@PostConstruct` / `@PreDestroy` 페어와 init/deinit 페어
- 6-7 추가 후 BGMPlayer의 init/deinit 페어는 **3 옵저버 등록 ↔ 1줄 일괄 해제**라는 비대칭 모습.
- 이게 가능한 이유: `removeObserver(self)`가 self가 등록한 모든 옵저버를 selector/name/object 상관없이 일괄 해제하는 *벌크 API*.
- 학습 포인트: **API가 벌크 해제를 지원하면 자원 관리가 선언적**이 됨. 추가할 때마다 해제 코드 안 늘어남.

## 주의사항

- **`UIApplication.didEnterBackgroundNotification` 발행 시점에 `DispatchQueue.main`은 살아 있음** — `handleDidEnterBackground` 안에서 sync/async 디스패치 가능. 다만 본 sprint는 디스패치 안 함(즉시 처리).
- **앱이 suspend된 후에는 코드 실행 안 됨** — `didEnterBackground` 콜백은 suspend *전*에 호출된다는 점이 보장됨. 그 안에서 pause 처리 시 충분.
- **시뮬레이터 검증**: Cmd+Shift+H (홈) → 다시 앱 → BGM 일시정지/재개 확인.
- **실기기 검증 시나리오**:
  1. 게임 진입(BGM 재생 중) → 홈 → 다시 앱: BGM이 페이드 인하며 살아남
  2. 타이틀 화면(BGM 없음) → 홈 → 다시 앱: BGM 안 켜짐 (플래그 false)
  3. gameOver(BGM 페이드 아웃) → 홈 → 복귀: 시나리오 C 결과대로
  4. 게임 중 전화 → 통화 끝나고 화면 복귀: 6-6/6-7 협력 (resume은 6-6이 책임)
- **음원 부재 환경**: 옵저버 등록 자체가 안 일어남 → 회귀 0.
- **빌드 에러 가능성**: `import UIKit` 누락 시 unresolved symbol. → 반드시 추가.
- **6-6의 동작 보존 검증**: `handleInterruption(_:)`, `pause()`, `resume()` 시그니처/본문은 *손대지 않음*. 6-7은 이들을 *소비*만 함.
