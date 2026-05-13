# Phase 6-6 — AVAudioSession Interruption 처리

## 개요
Phase 6-5에서 BGM 페이드 인/아웃까지 마무리된 BGMPlayer에, 게임 도중 전화/Siri/타이머 알람 같은 **시스템 인터럽션**을 만났을 때 BGM이 자동으로 일시정지되고, 인터럽션이 끝나면 자연스럽게 다시 살아 돌아오도록 한다. AVFoundation 표준 패턴인 `AVAudioSession.interruptionNotification`을 `NotificationCenter`로 구독하고, BGMPlayer **내부에서만** 옵저버를 등록/해제한다. 외부 인터페이스(play/stop)는 6-5 그대로 유지한다 — *좁은 인터페이스(narrow interface)* 원칙.

## 변경 유형
**폴리싱 / 라이프사이클 안정성** — 게임플레이 규칙 변화 0, 시각 변화 0. 시스템과의 매너(graceful interruption handling)를 다듬는 sprint.

## 게임 경험 의도
게임 도중 전화가 울려도, Siri를 불러도, 타이머 알람이 떠도 BGM이 "끊긴 채 영영 돌아오지 못하는" 사고가 없다. 통화를 끊고 게임 화면으로 돌아오면 BGM이 6-5의 페이드 인을 타고 자연스럽게 다시 살아난다. 사용자는 "어 음악이 다시 들어왔네" 정도로만 인지하면 충분 — *시스템과 다투지 않는 앱*이라는 인상.

## Sprint 범위 계약

### 허용
- `BGMPlayer.swift` 내부에서 `NotificationCenter.default.addObserver` 호출
- `BGMPlayer.swift`에 `private func handleInterruption(_:)`, `private func pause()`, `private func resume()` 메서드 추가
- `init()`에 옵저버 등록 한 줄 추가 (player 로딩 성공 *이후*)
- `deinit` 신설 — 옵저버 해제 (`NotificationCenter.default.removeObserver(self)`)
- `[weak self]` 의식 — selector 방식은 weak 자동이지만 의식적 코딩 습관 유지
- 상단 헤더 주석에 "Phase 6-6 · Interruption 처리" 1줄 추가

### 금지
- **GameScene 변경 0줄** — Phase 6-4/6-5와 동일 진입/종료 경로 유지
- **AudioManager / HapticsManager 변경** — Manager 간 결합도 0 유지
- **public 인터페이스 변경** — 외부에 노출되는 메서드는 `play()` / `stop()`만. 새 public 메서드/프로퍼티 추가 금지
- **새 GameConfig 상수 추가** — 인터럽션 처리는 비즈니스 튜닝 값이 아닌 시스템 응답이므로 즉시 처리(페이드 없음). 상수가 필요 없음
- **AVAudioSession 카테고리 변경** — 6-4의 `.playback + .mixWithOthers` 정책 그대로
- **게임 일시정지 UI 신설** — 본 sprint는 BGM 한정. 화면 멈춤은 별도 sprint
- **백그라운드 라이프사이클 옵저버** (`UIApplication.didEnterBackground` 등) — 별도 sprint
- **새 SFX / 음원 추가**

### 판단 기준
"이 변경이 없으면 인터럽션 후 BGM이 자동 복귀하지 못하는가?" → YES면 허용. 아니면 금지.

---

## 변경 범위

### 수정할 파일
- `GanhoMusic/GanhoMusic Shared/Managers/BGMPlayer.swift` — 옵저버 등록/해제, interruption handler, private pause/resume

### 추가할 파일
없음.

### 0줄 변경 파일 (Sprint 범위 계약 검증용)
- `GanhoMusic/GanhoMusic Shared/Scenes/GameScene.swift`
- `GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift`
- `GanhoMusic/GanhoMusic Shared/Managers/HapticsManager.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`

---

## Interruption Notification 페이로드 정리

### Notification 이름
`AVAudioSession.interruptionNotification`

### userInfo 키
| 키 | 타입 | 의미 |
|---|---|---|
| `AVAudioSessionInterruptionTypeKey` | `UInt` → `AVAudioSession.InterruptionType` raw | `.began` (= 1) / `.ended` (= 0) |
| `AVAudioSessionInterruptionOptionKey` | `UInt` → `AVAudioSession.InterruptionOptions` raw | `.shouldResume` 비트가 켜져 있으면 자동 재개 허용 |

### 처리 매트릭스
| Type | shouldResume | 우리 처리 |
|---|---|---|
| `.began` | (irrelevant) | 즉시 `pause()` — 페이드 없음 |
| `.ended` | true | `resume()` — 6-5의 `play()` 호출로 페이드 인 재시작 |
| `.ended` | false | noop — 시스템이 재개 거부했으므로 BGM 그대로 멈춤 |

---

## 기능 상세

### 기능 1: 옵저버 라이프사이클 — init↔deinit 매칭
- **설명**: BGMPlayer 인스턴스가 살아 있는 동안만 인터럽션을 구독한다. 인스턴스 해제 시 옵저버도 같이 정리해 dangling observer / NotificationCenter의 강참조로 인한 누수를 방지.
- **구현 위치**: `BGMPlayer.swift`의 `// MARK: - Init`, 새 `// MARK: - Deinit`
- **핵심 코드 구조**:
  ```swift
  init() {
      // ... 기존 6-5의 Bundle 음원 로딩 / 카테고리 설정 / prepareToPlay 그대로 ...
      player = p

      // 음원 로딩 성공한 *이후에만* 인터럽션 구독.
      // 음원이 없는(player == nil) 경우엔 어차피 play/stop이 noop이므로 구독해도 의미 없음.
      NotificationCenter.default.addObserver(
          self,
          selector: #selector(handleInterruption(_:)),
          name: AVAudioSession.interruptionNotification,
          object: AVAudioSession.sharedInstance()
      )
  }

  // MARK: - Deinit
  /// init에서 addObserver를 한 만큼 정확히 한 번 해제.
  /// Spring `@PreDestroy`와 동일 발상 — 빈 소멸 시점에 등록한 자원 회수.
  deinit {
      NotificationCenter.default.removeObserver(self)
  }
  ```
- **주의**: `addObserver(_:selector:name:object:)` 형식은 옵저버를 약참조하지만, 명시적 `removeObserver(self)` 호출이 표준 안전 패턴. 만약 block 기반 `addObserver(forName:object:queue:using:)`을 쓴다면 반환된 토큰을 보관해야 하므로 본 sprint는 selector 방식 채택.

### 기능 2: Interruption Handler — userInfo 디스패치
- **설명**: NotificationCenter가 호출하는 단일 진입점. `userInfo`에서 type을 꺼내 began/ended로 분기. `@objc` 어노테이션 필수(selector 호출 대상).
- **구현 위치**: `BGMPlayer.swift` 새 `// MARK: - Interruption` 섹션
- **핵심 코드 구조**:
  ```swift
  // MARK: - Interruption
  /// AVAudioSession.interruptionNotification 콜백.
  /// @objc 필수 — Objective-C 런타임 selector 디스패치 대상.
  @objc private func handleInterruption(_ notification: Notification) {
      guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

      switch type {
      case .began:
          // 인터럽션 진입 — 즉시 응답이 미덕. 페이드 없음.
          pause()
      case .ended:
          // 시스템이 재개해도 좋다고 알려준 경우에만 다시 켠다.
          guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
          let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
          if options.contains(.shouldResume) {
              resume()
          }
      @unknown default:
          break
      }
  }
  ```
- **주의**:
  - `@unknown default` — Apple이 향후 새 case 추가 시 컴파일러 경고로 알려주는 forward-compat 패턴
  - `as? UInt` 가드로 강제 언래핑 회피
  - notification은 어떤 스레드에서 올지 보장되지 않지만, `AVAudioPlayer.pause()/play()`는 thread-safe → 추가 디스패치 불필요. 6-5의 `stopWorkItem`이 main queue에서 도는 점은 본 sprint에서 건드리지 않는다

### 기능 3: private pause() — 즉시 일시정지
- **설명**: `player.pause()`만 호출. 페이드 아웃 사용 안 함 (인터럽션은 즉시 응답해야 자연스러움 — 페이드 0.3초가 통화 벨소리와 겹치면 오히려 부자연스러움).
- **구현 위치**: `BGMPlayer.swift` `// MARK: - Interruption` 내부, `handleInterruption` 아래
- **핵심 코드 구조**:
  ```swift
  /// 인터럽션 진입 시 즉시 멈춤 (페이드 없음).
  /// 6-5의 stop()과 다른 점:
  ///   - stop()은 의도적 게임 종료 → 페이드 아웃으로 끝
  ///   - pause()는 시스템 강요 → 즉시 멈추고 player 내부 재생 위치 보존
  /// player.pause()는 currentTime을 유지하므로 ended에서 play()를 다시 부르면
  /// numberOfLoops=-1 설정과 함께 자연스럽게 이어진다.
  private func pause() {
      guard let player = player else { return }
      // 페이드 아웃이 *진행 중*이었다면 (stop 호출 직후 인터럽션 도착 같은 희귀 시나리오):
      //   페이드는 이미 시스템이 처리 중이고 stopWorkItem이 곧 player.stop()을 호출할 예정.
      //   여기서 추가로 pause()를 부르면 player.stop()과 충돌 가능 — 그래서 isFadingOut 가드.
      if isFadingOut { return }
      player.pause()
  }
  ```
- **왜 isFadingOut 가드인가**: 게임이 막 끝나 `stop()`이 호출된 직후(=페이드 아웃 진행 중) 인터럽션이 들어오는 경우, 어차피 곧 `player.stop()`이 실행될 예정. 여기서 `pause()`를 추가로 부르면 의미상 충돌 — "이미 끝나는 중인 음악은 그냥 끝나게 둔다"는 정책.

### 기능 4: private resume() — 페이드 인 재시작
- **설명**: 6-5의 `play()`를 그대로 재호출. play()의 기존 가드(`player.isPlaying` 체크 + `stopWorkItem.cancel()` + `isFadingOut = false` 초기화)가 인터럽션 후 재진입 시나리오를 그대로 흡수.
- **구현 위치**: `BGMPlayer.swift` `// MARK: - Interruption` 내부, `pause` 아래
- **핵심 코드 구조**:
  ```swift
  /// 인터럽션 종료(.ended + shouldResume) 시 6-5의 play() 그대로 재호출.
  /// play() 내부의 isPlaying 가드가 핵심:
  ///   - pause() 후엔 isPlaying=false → play() 진입 → 페이드 인 처음부터 다시 시작
  ///   - 이미 isPlaying=true (희귀: 다른 경로로 살아남) → noop, 회귀 없음
  /// 별도 페이드 인 코드 작성 안 함 — 6-5의 fadeIn을 *재사용*하는 게 6-6의 우아함.
  private func resume() {
      play()
  }
  ```
- **검증 포인트**: 6-5의 `play()` 첫 줄 `if player.isPlaying { return }` — `pause()` 직후엔 `isPlaying`이 `false`이므로 이 가드를 통과하고 페이드 인이 시작된다. ✅

### 기능 5: 교차 시나리오 정합성

| 시나리오 | 진입 상태 | 인터럽션 began 처리 | 인터럽션 ended 처리 |
|---|---|---|---|
| 페이드 인 중 began | `isPlaying=true, isFadingOut=false, volume이 0→1 보간 중` | `player.pause()` 실행. volume은 보간 중간값에 멈춤. | `play()` 진입 → `isPlaying=false` → `volume=0`으로 리셋 → 페이드 인 처음부터 다시 시작. UX: "통화 끝나고 처음부터 살아 돌아옴" |
| 정상 재생 중 began | `isPlaying=true, isFadingOut=false, volume=1` | `player.pause()` 실행. volume=1로 멈춤. | `play()` 진입 → `volume=0` 리셋 → 페이드 인 1.5초 후 1.0. 약간의 "다시 페이드 인" 비용을 받아들이고 일관성 우선. |
| 페이드 아웃 중 began | `isPlaying=true, isFadingOut=true, volume이 1→0 보간 중, stopWorkItem 예약됨` | **noop** (isFadingOut 가드). 이미 게임이 끝나는 중이므로 그냥 페이드 아웃 진행. | `play()` 진입 → `stopWorkItem.cancel() + isFadingOut=false` → `isPlaying`이 아직 true면 가드에 막혀 noop / false면 새로 페이드 인. 어느 쪽이든 일관성 깨지지 않음. |
| 음원 없음 (player=nil) | — | `pause()`의 guard let player에 막혀 noop | `play()`의 guard let player에 막혀 noop |

### 기능 6: AVAudioSession 카테고리 변경 0
6-4의 `.playback + .mixWithOthers` 정책 그대로. 인터럽션은 카테고리와 무관하게 `AVAudioSession.sharedInstance()`가 발행하므로 카테고리 손대지 않는다. AudioManager의 `.ambient` 정책 또한 영향 0.

---

## 검증 시나리오

### (a) 빌드
- `xcodebuild ... build` → BUILD SUCCEEDED, 경고 0

### (b) 음원 부재 폴백 (회귀 0)
- `bgm.m4a` 없음 → init 첫 guard에서 player = nil
- 옵저버 등록 자체 안 됨 (player == nil 이후 코드 도달 X) — 또는 옵저버 등록은 되더라도 pause/resume 모두 guard에 막힘
- 6-3/6-4/6-5와 동일 noop 동작

### (c) 6-5 회귀
- play()/stop() 본문 0줄 변경
- isFadingOut / stopWorkItem 사용 패턴 그대로
- GameConfig.bgmFade*Duration 호출 그대로

### (d) 인터럽션 began 동작
- handleInterruption(.began) → pause() → player.pause()
- isFadingOut=false 상태에서만 발화

### (e) 인터럽션 ended + shouldResume 동작
- handleInterruption(.ended, shouldResume=true) → resume() → play()
- play()의 isPlaying 가드를 거쳐 페이드 인 재시작

### (f) 인터럽션 ended without shouldResume
- options.contains(.shouldResume) == false → 분기 무시
- BGM 멈춘 상태 유지

### (g) 페이드 아웃 도중 began
- isFadingOut=true → pause() noop
- 게임 종료 페이드 아웃 그대로 진행

### (h) deinit 옵저버 해제
- BGMPlayer ARC 해제 시 deinit 호출
- removeObserver(self) → NotificationCenter에서 등록 제거

### (i) Phase 1~5 회귀
- 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터 선택/AIRFORCE 모두 정상

---

## 학습 가치 (docs/learn/에 별도 노트로 작성될 내용 시드)

### 1. NotificationCenter 옵저버 패턴 — Spring `@EventListener` 비유
Spring에서 다른 빈이 발행하는 이벤트를 받을 때 `@EventListener` 메서드를 만들고 ApplicationEvent를 받는 것처럼, iOS에서는 시스템이 발행하는 이벤트(인터럽션, 화면 회전, 백그라운드 진입 등)를 `NotificationCenter`로 구독한다. **NotificationCenter == iOS의 ApplicationEventPublisher**.

차이점: Spring `@EventListener`는 컨테이너가 메서드 시그니처로 자동 매핑하지만, iOS는 **selector + addObserver 명시 호출**이 필요하다. 컨테이너의 의존성 주입 마법이 없는 만큼 직접 등록/해제를 챙겨야 한다.

### 2. 라이프사이클 매칭 — init↔deinit (Spring `@PostConstruct`↔`@PreDestroy`)
스프링 빈이 `@PostConstruct`에서 연결한 자원을 `@PreDestroy`에서 닫는 것처럼, BGMPlayer는 `init`에서 등록한 옵저버를 `deinit`에서 해제해야 한다. **등록한 횟수만큼 정확히 해제** — 이게 안 지켜지면 dangling observer로 크래시 / 누수.

학생 비유: "도서관에서 책 빌렸으면 반납해야 한다. 안 하면 다음에 빌리려는 사람도 곤란하고, 책 자체가 사라져도 도서관 시스템엔 '아직 빌려준 상태'로 남는다."

### 3. 시스템과 협상하는 매너 — "전화 끝나면 자연스럽게 돌아오는" UX 디테일
좋은 앱은 시스템과 싸우지 않는다. 전화 오면 멈추고, 끝나면 돌아오고, 무음 모드면 조용히 한다. 이번 sprint의 한 줄 정리:

> "BGM은 게임의 주인공이지만, 전화는 인생의 주인공이다. 우리는 잠시 빠져 준다."

### 4. 좁은 인터페이스(Narrow Interface) 원칙
외부에 노출되는 메서드는 6-5 그대로 `play()` / `stop()` 두 개. `pause()` / `resume()` 같은 인터럽션 응답은 **private** — 호출자가 알 필요 없다. Spring에서 컨트롤러가 서비스의 public API만 알고 내부 트랜잭션 처리는 모르는 것과 동일.

학생 비유: "식당에서 손님은 '주문/계산'만 알면 된다. 주방에서 불을 잠깐 줄였다가 다시 켜는 건 셰프 몫."

### 5. 재사용의 우아함 — resume()이 play()를 그냥 부른다
6-5에서 잘 만들어 둔 `play()`(페이드 인 + isPlaying 가드 + stopWorkItem cancel)를 그대로 호출하는 것이 6-6의 가장 우아한 부분. 같은 페이드 인 곡선을 두 번 작성하지 않는다 — **DRY(Don't Repeat Yourself)**.

---

## 주의사항

### 빌드 에러 가능성
- `@objc` 누락 시 selector 디스패치 런타임 크래시 → handleInterruption 메서드에 반드시 `@objc` 어노테이션
- `#selector(handleInterruption(_:))` 시그니처가 메서드 정의와 일치해야 함 (파라미터 1개, 라벨 underscore)
- `AVAudioSession.InterruptionType(rawValue: UInt)` — `UInt`로 캐스팅 (Int 아님)

### SpriteKit 특성상 주의할 점
- BGMPlayer는 SKNode가 아니므로 SKAction 사용 불가 — 6-5의 DispatchWorkItem 패턴 그대로 유지
- Notification 콜백 스레드 보장 없음 — 다만 본 sprint에서 추가하는 `pause()/play()`는 AVAudioPlayer가 thread-safe, 추가 main dispatch 불필요

### 회귀 위험
- **GameScene 진입 시점 BGM 시작은 그대로** — 6-4/6-5의 진입 경로(GameScene `didMove(to:)`에서 `bgm.play()`) 0줄 변경
- **음원 없는 환경(시뮬레이터에 bgm.m4a 미포함)**: `player == nil` → pause/resume 모두 guard에 막힘 → 회귀 0
- **6-5의 isFadingOut 가드**: pause()에서 isFadingOut 확인 안 하면 페이드 아웃 도중 인터럽션 시 stopWorkItem의 player.stop()과 충돌 가능 — 반드시 가드 포함

### 검증 체크리스트 (SELF_CHECK.md에서 다룰 항목 미리보기)
- [ ] `init()` 안의 옵저버 등록이 `player = p` *이후*에 있는가 (player == nil이면 등록 안 함)
- [ ] `deinit`에서 `removeObserver(self)` 호출되는가
- [ ] `handleInterruption`에 `@objc` 붙어 있는가
- [ ] `pause()`/`resume()`가 `private`인가 (외부 노출 0)
- [ ] `pause()`가 `isFadingOut` 가드를 가지는가
- [ ] `resume()`이 `play()`를 호출만 하는가 (페이드 인 직접 구현 X — 재사용)
- [ ] `userInfo` 파싱에 강제 언래핑 없는가
- [ ] `@unknown default` 처리 있는가
- [ ] GameScene / GameConfig / AudioManager / HapticsManager 0줄 변경 확인
- [ ] 빌드 BUILD SUCCEEDED + 경고 0
