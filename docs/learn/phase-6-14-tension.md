# Phase 6-14 — 타이머 긴박감 (5초 BGM 피치 상승 + HUD 깜빡임 + 매초 햅틱)

## 한 줄 요약
게임 타이머가 **5초 이하**로 떨어지면 BGM이 점점 *빨라지고 살짝 높아져요* (rate 1.0→1.15), HUD 시계 라벨이 **빨강↔원래색**으로 1초 주기 깜빡임, 그리고 **매초**(5→4, 4→3, 3→2, 2→1) 손끝에 가벼운 진동. 6-13 출발 *개봉감*의 정확한 대칭 — **끝의 긴박감**. 신규 파일 0건, 4개 기존 파일 수정만으로 끝낸 가장 작은 sprint.

---

## 무엇을 했나요?

네 식구가 살짝씩 들어왔어요 (새 파일 0건).

1. **BGMPlayer** — `setRate(_:)` + `resetRate()` 2개 메서드 + init에 `enableRate = true` 1줄 + stop()에 rate 복원 1줄
2. **HUDNode** — `startTensionBlink()` + `stopTensionBlink()` 2개 메서드 (timeLabel만 건드림)
3. **GameConfig** — Tension 상수 5개 (`tensionWindow=5.0`, `tensionRateMax=1.15`, ...)
4. **GameScene** — 프로퍼티 2개 + update 폴링 블록 + endGame 정리 1줄

회귀 0줄: 자가 소멸 노드 8개 전체 (CountdownNode 포함) / ContactRouter / ScoreSystem / SpawnSystem / 기존 Nodes 7개 / TitleScene / ResultScene / AudioManager / HapticsManager / Repositories / Models / Protocols / ColorTokens / GameState / GameScene+Setup — **20개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "끝의 시계는 *심장박동*처럼"

```
지금까지 (6-13 카운트다운까지)        이번 작업 후 (6-14)
시작:                                  시작:
3-2-1-GO! 카운트다운 (개봉감)         3-2-1-GO! 카운트다운 (그대로)
    ↓                                      ↓
게임 진행 (45초)                       게임 진행 (45초)
    ↓                                      ↓
타이머 5초 남았는데...                 타이머 5초:
조용히 숫자만 줄어듬                   ⚡ BGM 살짝 빨라지기 시작
"어, 끝나가나?"                        ⚡ HUD "00:05" 빨갛게 깜빡
                                       ⚡ 손끝 톡! (5→4 햅틱)
                                          ↓ 4초
                                       ⚡ BGM 더 빨라짐
                                       ⚡ "00:04" 또 깜빡
                                       ⚡ 손끝 톡! (4→3)
                                          ↓ ...
                                       ⚡ "00:00" → endGame
```

**5초 구간은 게임의 *결정적 클라이맥스***. 점수 한 톨이라도 더 줍거나, F를 피해 마지막 콤보를 잇는 시간이에요. 그런데 지금까진 *조용히 숫자만* 줄어들었죠.

학생 비유: 운동회 50m 달리기에서 결승선 직전 *관중석 함성*이 커지고 *심박*이 뛰는 순간 — 그 *체감*이 없으면 그냥 *숫자*가 줄어들 뿐. 6-14는 그 함성과 심박을 추가.

자전적 톤에서, *마감 직전 박자가 흐트러지는 순간*을 음악적으로 표현 — BGM 피치 상승이 그 *조급함*을 그대로 청각화. 새벽 작곡 톤이 클라이맥스로 휘몰아가는 시점.

> **Spring 비유**: 마감 직전 5분 남은 데드라인 알람 — Slack에 빨간 점멸 + 짧은 진동 + 알림음. 시스템이 *조용히 마감* 가는 게 아니라 *경고 단계 상승*. 6-14가 게임에 같은 알람 시스템 추가.

---

## 가장 우아한 부분 — **`guard .playing`이 카운트다운을 자동 차단**

이번 sprint의 *제일 깨끗한 결정*이에요.

```swift
override func update(_ currentTime: TimeInterval) {
    super.update(currentTime)
    guard gameState == .playing else { return }   // ⭐ 카운트다운 자동 차단

    remainingTime = max(0, remainingTime - dt)
    if remainingTime <= 0 {
        endGame()
        return
    }

    // Phase 6-14 — 5초 폴링은 여기. .countdown 상태에서 위 guard가 자동 차단.
    if remainingTime <= GameConfig.tensionWindow {
        // ... rate 보간 + HUD 깜빡임 + 매초 햅틱
    }
}
```

**카운트다운(6-13)과 *시간상 비교차* 확인**:
- 카운트다운 중: `.countdown` 상태 → `guard .playing else { return }`이 *모든* update 로직 차단
- 5초 폴링도 이 가드 *안쪽*에 위치 → 카운트다운 중 rate 변경 호출 자체가 발생 불가
- BGM은 GO! 직후 `bgm.play()` → `gameState = .playing`. 카운트다운 동안 BGM 미재생 + rate 변경 0
- 추가 가드 코드 0줄

> **Spring 비유**: `@Conditional("running")` 어노테이션 1개로 모든 `@Scheduled` 잡이 자동 정지. 새 작업(`@Scheduled(rateBoost)`) 추가해도 *같은 조건*이라 자동 따라옴. 흩어진 if문 N개가 아니라 *중앙 가드 1줄*의 힘.

---

## Spring 비유 — *시작과 끝의 대칭*

```
시작 (6-13)                              끝 (6-14)
─────────────                             ────────
3 (빨강)  ← 강한 색                        00:05 빨강 깜빡임 ← 같은 빨강
2 (노랑)                                   00:04 빨강 깜빡임
1 (분홍)                                   00:03 빨강 깜빡임
GO! (민트) ← 출발 신호                     00:02 빨강 깜빡임
                                          00:01 빨강 깜빡임
매 숫자: light 햅틱                        매초: light 햅틱 (4회)
GO!: heavy + 사운드                        0초: endGame heavy + Boop
BGM 페이드인 시작                          BGM 페이드아웃 + 종료

체감: "준비됐다!"                          체감: "끝나간다!"
```

**같은 채널 (시각/청각/촉각)에 *반대 의미*의 메시지를 실음**.

> **Spring 비유**: `ApplicationStartedEvent` listener (출발 알림) ↔ `ApplicationShutdownEvent` listener (종료 알림). 같은 시스템(EventBus), 같은 채널(Slack/SMS), *반대 의미*(시작 vs 끝). 6-13/6-14의 시작/끝 대칭과 동형.

학생 비유: 학교 *시작 종*과 *마치는 종* — 같은 종(채널)이지만 의미가 반대. 시작은 *기대*, 마침은 *아쉬움*. 6-13/6-14가 그 두 종을 게임에 추가.

---

## Swift / SpriteKit 학습 포인트

### 4-1. AVAudioPlayer.rate — 피치까지 같이 움직이는 *자연 가속*

```swift
// init
p.enableRate = true   // ⭐ 안 켜면 rate setter가 무시됨

// 매 프레임
player.rate = 1.15    // 1.0 ~ 2.0 범위. 피치도 같이 올라감
```

**왜 피치가 같이?**
- `AVAudioPlayer.rate`는 *재생 속도* 변경 — 영상/오디오 빨리감기와 동일 원리. 빨리 감으면 *주파수*도 자연 상승 → 피치↑.
- *피치만* 따로 바꾸려면 `AVAudioEngine` + `AVAudioUnitTimePitch` 필요 — 전면 개편 필요. 본 sprint는 *AVAudioPlayer 유지*가 정책.
- "영상 빨리감기" 톤이 *마감 직전 가속감*과 의미적으로 일치 → 피치 분리 *오히려 불필요*.

**함정**: `enableRate = true`를 `prepareToPlay()` *전*에 켜야 함. Apple 문서 명시 — 안 그러면 setter가 silent fail.

> **Spring 비유**: `@EnableScheduling` 어노테이션을 켜야 `@Scheduled` 메서드가 동작. 활성화 flag 누락은 *조용한 미동작*.

### 4-2. `Int(ceil(remainingTime))` — *정수 변화 감지*

```swift
// 매 프레임
let now = max(0, Int(ceil(remainingTime)))   // remainingTime 4.3 → 5, 4.0 → 4, 3.7 → 4
if now != lastRemainingTimeSecond {
    lastRemainingTimeSecond = now
    if now >= 1 && now <= 4 {
        haptics.light()
    }
}
```

**왜 `ceil`?**
- `floor` 또는 단순 `Int` 캐스팅 → 4.3 → 4, 4.0 → 4 같이 *연속된 정수 값* 발생
- `ceil` → 4.3 → 5, 4.0 → 4 — *5초 표시되는 동안 5*, *4초 표시되는 동안 4*로 자연스러움
- HUD가 "00:05" 표시할 때 `now = 5`, "00:04" 표시할 때 `now = 4` — *시각 동기화*

**매초 발화 보장**:
- 1프레임당 1회 비교 → 60fps에서 매 1/60초 검사
- `now`가 *바뀐 순간*만 발화 → 같은 4초 동안 햅틱 1회만
- 5→4, 4→3, 3→2, 2→1 = 정확히 4회

> **Spring 비유**: `@Scheduled(fixedRate=1000)` 매초 잡 vs *정수 변화 감지*. 후자가 더 정밀 — 시간이 *비균등하게* 흘러도 정확한 분기점 캡처.

### 4-3. SKAction.run + wait — *fontColor 직접 교체* 패턴

```swift
// ❌ colorize 액션 — SKLabelNode에서 일관성 이슈
let toRed = SKAction.colorize(with: .ganhoBloodAccent, colorBlendFactor: 1.0, duration: 0.5)

// ✅ fontColor 직접 교체 — 항상 동작
let toRed = SKAction.run { [weak self] in
    self?.timeLabel.fontColor = .ganhoBloodAccent
}
let wait = SKAction.wait(forDuration: 0.5)
let cycle = SKAction.sequence([toRed, wait, toBase, wait])
timeLabel.run(.repeatForever(cycle), withKey: "tensionBlink")
```

**왜 `colorize`를 피했나?**
- `SKLabelNode`는 `colorBlendFactor` 기본값 0 → `colorize` 액션이 무시되는 케이스 존재 (SpriteKit 버전별 동작 불일치)
- `fontColor`를 *즉시 교체*하는 게 더 안전하고 일관됨
- `wait` + `repeatForever`로 깜빡임 효과 동일하게 구현

**`withKey`의 마법**:
- 같은 키로 재호출 시 SpriteKit이 *이전 액션 자동 제거 + 새 액션 부착*
- `tensionStarted` Bool 가드와 *이중 멱등*
- `removeAction(forKey:)`로 즉시 종료 가능

> **Spring 비유**: 같은 ID로 `Scheduler.schedule(job)` 재호출 시 이전 잡 자동 취소. ID 기반 멱등.

### 4-4. `Float` vs `CGFloat` 혼용 주의

```swift
// AVAudioPlayer.rate는 Float
static let tensionRateBase: Float = 1.0
static let tensionRateMax: Float = 1.15

// remainingTime은 TimeInterval (Double)
let progress = Float((GameConfig.tensionWindow - remainingTime) / GameConfig.tensionWindow)
let rate = GameConfig.tensionRateBase + (GameConfig.tensionRateMax - GameConfig.tensionRateBase) * progress
bgm.setRate(rate)
```

**왜 `Float` 강제 캐스팅?**
- Swift는 *암시적 변환* 안 함 (Java/Kotlin과 다름). `Double * Float` 컴파일 에러.
- `tensionRateBase: Float = 1.0`에서 `Float` 명시로 *원치 않는 Double 캐스팅* 차단.
- `progress` 계산은 `Double` 영역에서 → 마지막에 `Float` 캐스팅.

**함정**: `let rate = 1.0 + 0.15 * progress` 같이 *literal*만 쓰면 `Double` 추론 → AVAudioPlayer.rate 타입 미스매치.

> **Spring 비유**: `BigDecimal` vs `double` 혼용. Java는 자동 변환 일부 허용, Swift는 *명시 강제*. 안전.

### 4-5. 1회 가드 `tensionStarted: Bool`

```swift
private var tensionStarted: Bool = false

// update 안
if remainingTime <= GameConfig.tensionWindow {
    if !tensionStarted {
        tensionStarted = true
        hud.startTensionBlink()   // 첫 진입에만 1회 발화
    }
    // 매 프레임 rate 보간은 여기 (반복 OK)
    bgm.setRate(...)
}
```

**왜 Bool 1개?**
- 5초 진입은 *한 판에 1회만* 발생 (4초→5초 회복 시나리오 없음 — 시간은 단방향)
- `lastComboValue` 같은 Int 추적 불필요 — *진입 여부*만 알면 됨
- `airforceTriggered` 패턴(Phase 4-3) 답습

**자동 리셋**:
- 새 GameScene 인스턴스에서 자동 `false` 초기화
- `endGame` 후 `stopTensionBlink()` 호출이 액션을 제거하지만 `tensionStarted`는 그대로 — *재발화 가드*로 작동 (한 판 끝나면 의미 없음)

> **Spring 비유**: 결제 시도 1회 가드 — 같은 요청 ID 재시도 차단. 인스턴스 라이프사이클로 자동 리셋.

---

## 산출물

**수정 (4 파일, +104줄)**:
- `Managers/BGMPlayer.swift` (+22줄) — enableRate + setRate/resetRate + stop()에 rate 복원
- `Nodes/HUDNode.swift` (+26줄) — startTensionBlink/stopTensionBlink
- `Config/GameConfig.swift` (+16줄) — Tension 상수 5개
- `GameScene.swift` (+40줄) — 프로퍼티 2개 + update 폴링 블록 + endGame 정리

**신규 파일**: 0건 (Sprint 범위 최소화)
**pbxproj 변경**: 0건 (신규 파일 없음)

---

## 검증 방법

### 정량
- ✅ `xcodebuild` BUILD SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 컴파일 경고 0건, 에러 0건
- ✅ `git diff --name-only HEAD`: 4개 Swift 파일만
- ✅ ColorTokens / GameState / 자가 소멸 노드 8개 / Systems / Repositories / Models 변경 0줄
- ✅ Sprint 회귀 0 영역 20개 미접촉 (git diff 전수 검사)
- ✅ QA 점수: **10.0 / 10.0** (Swift 10, 로직 10, 성능 10, 완성도 10)

### 시각 (사용자가 시뮬레이터에서 확인)
- [ ] 게임 시작 후 40초 흐른 시점에 BGM 정상 재생 (rate=1.0)
- [ ] "00:05" 표시되는 순간 timeLabel 빨강 즉시 전환 시작
- [ ] 5초~1초 동안 BGM이 점점 빨라지고 살짝 높아짐 (음원 부재 시 시뮬레이터에서 noop)
- [ ] timeLabel이 빨강↔원래색을 1초 주기로 깜빡임
- [ ] 매초(5→4, 4→3, 3→2, 2→1) 실기기에서 light 진동 4회
- [ ] "00:00" 도달 → endGame → 빨강 깜빡임 즉시 멈춤, BGM 페이드아웃 1초
- [ ] ResultScene 진입 후 BGM 완전 정지, TitleScene 복귀 후 다시 게임 시작 시 rate=1.0으로 정상 시작
- [ ] **5초 이전** F 피격 → 깜빡임 발화 0, rate 변경 0 (회귀 0 검증)
- [ ] **5초 이후** F 피격 → 깜빡임 즉시 멈춤 + 페이드아웃 중 rate 자연 정지
- [ ] 카운트다운(3-2-1-GO!) 중 BGM 미재생 + rate 변경 0 (6-13 회귀 0)

### 시뮬레이터 한계
- 햅틱 light는 시뮬레이터에서 noop — 실기기에서 매초 진동 확인 필요
- BGM rate 변경은 시뮬레이터에서도 들림 (macOS 사운드 채널)

---

## 회고

### 막혔던 것
없음. SPEC 단계에서:
- AVAudioPlayer rate vs AVAudioEngine 트레이드오프 사전 결정
- SKLabelNode colorize 함정 사전 회피 (fontColor 직접 교체로 우회)
- Float vs Double 타입 혼용 사전 경고
- 카운트다운(6-13) 시간 비교차 사전 검증

→ Generator가 빌드 1회로 통과. *13번째 sprint의 누적된 설계 노하우*가 작동한 결과.

### Spring과 다르네 싶었던 것
1. **`enableRate = true` 명시 활성화**: Spring `@EnableScheduling`처럼 별도 활성화 flag — 안 켜면 silent fail.
2. **`Float` vs `CGFloat` 명시**: Java는 *자동 변환* 일부 허용, Swift는 강제. 안전성 ↑.
3. **`SKAction.repeatForever + withKey` 멱등**: Spring `@Scheduled` ID 기반 잡 관리와 동형. ID 재호출 = 자동 교체.
4. **`Int(ceil(remainingTime))` 정수 변화 감지**: Spring `@Scheduled(fixedRate)`보다 더 정밀 — 시간 흐름 *비균등*도 정확 캡처.

### 평가 점수
- Swift 패턴: 10/10
- 게임 로직: 10/10
- 성능: 10/10
- 완성도: 10/10
- **가중: 10.0 / 10.0**

### 사용자 직접 확인할 것
- 실기기에서 5→4 light 진동이 *심박*처럼 자연스러운지
- BGM rate 1.15가 *체감되지만 곡 식별성 유지* 균형점인지 (필요시 1.10 또는 1.20 조정)
- 빨강 깜빡임 1초 주기가 너무 빠르거나 느린지 (필요시 `tensionBlinkHalfPeriod` 조정)
- BGM 페이드아웃 중 rate=1.15 유지가 자연스러운 마감음인지

### 다음 sprint 후보
- **6-15 베스트 스코어 갱신 폴리싱**: ResultScene 신기록 시 황금 빛 + heavy + NewMail
- **6-15 카운트다운 스킵**: 탭으로 GO! 점프
- **Phase 6 마무리**: 픽셀 아트 + 앱 아이콘
- **Phase 7**: Supabase 백엔드 (Apple Sign In + 리더보드)

---

## 멀티모달 가족 — 14번째 sprint의 누적

| 이벤트 | 촉각 | 청각 | 시각 | 운동감/기타 |
|---|---|---|---|---|
| 시작 카운트다운 (6-13) | light × 3 + heavy | NewMail × 1 (GO!) | CountdownNode | — |
| 노트 수집 (6-1/6-2/6-8) | light | Tink 1057 | Sparkle 8방향 | — |
| 콤보 마일스톤 (6-10/6-11) | light/medium/heavy | Tink/NewMail | ComboPopup ↑ | — |
| 콤보 끊김 (6-12) | heavy | (제외) | ComboBreak ↓ | — |
| **타이머 긴박감 (6-14)** | **light × 4 (매초)** | **BGM rate 1.0→1.15** | **HUD 빨강 깜빡임** | — |
| 피격 (6-1/6-2/6-9) | heavy | Boop 1073 | HitFlash 빨강 | CameraShake |
| 게임오버 (6-2/6-5) | heavy | Boop 1073 | (Scene 전환) | — |

**Phase 6 시리즈가 14번째 sprint를 거치며 *피드백 시스템*이 완성에 가까워졌어요**. 이번 추가로 *게임의 시작과 끝*이 모두 멀티모달로 마감됨 — 출발(6-13)과 마무리(6-14)의 톤이 *대칭* + *서로 다른 색깔*로 채워짐.

---

## 한 줄 교훈

> **"가장 작은 sprint는 *기존 가드 한 줄이 새 기능을 자동으로 받쳐주는* 변경이다."**

이번 sprint는:
- 신규 파일 0건
- pbxproj 변경 0건
- 회귀 영역 미접촉 20개
- 빌드 1회 통과
- 가중 점수 10.0

*기존 `guard gameState == .playing`* 한 줄이 카운트다운 비교차를 *자동* 보장. *기존 `endGame` 멱등 가드*가 F/enemy/0초 3경로의 정리를 *자동* 수렴. 신규 코드는 *진짜 새 동작*(rate 보간 + 깜빡임 + 매초 햅틱)에만 집중.

> **Spring 비유**: `@Conditional + @EventListener` 조합이 자리 잡힌 시스템에서는, 새 기능 추가가 *기존 조건 + 새 listener 1개*로 끝남. 흩어진 if문 N개 추가가 아니라 *중앙 가드의 힘*을 빌리기.

Phase 6은 이제 **14번째 sprint**까지 누적. 시작과 끝이 *대칭*으로 채워졌으니, 다음은 *중간*(베스트 스코어 갱신) 또는 *외부*(백엔드)로 가도 자연.
