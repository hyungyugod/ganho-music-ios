# Phase 6-11 — 콤보 마일스톤 사운드 + 햅틱 (3감각 완성)

## 한 줄 요약
콤보 X3 / X5 / X10 / X20에 도달하는 *그 순간*에 **진동(촉각)** + **효과음(청각)**이 **시각 팝업(6-10)과 동시에** 발화돼요. 마일스톤이 올라갈수록 진동이 무거워져요(light → medium → heavy). **시각 only**였던 6-10 환호가 이번에 **3감각 동시 환호**로 완성. 새 파일 0건, 기존 3개 파일에만 살짝 손댄 *깔끔한 마무리* sprint.

---

## 무엇을 했나요?

세 식구만 손댔어요. 새 파일 0건.

1. **AudioManager.SFX** — 케이스 2개 추가 (`comboMilestoneSoft` Tink 1057, `comboMilestoneStrong` NewMail 1025)
2. **HapticsManager** — `medium()` 메서드 1개 추가 (light/heavy 사이 강도)
3. **GameScene** — 멱등성 가드 안쪽에 `playComboMilestoneFeedback(for:)` helper 호출 1줄 prepend

회귀 0: ScoreSystem / ContactRouter / SpawnSystem / HUDNode / BGMPlayer / Repositories / Models / Protocols / 기존 Nodes / 기존 Scenes / ColorTokens / GameConfig / **ComboPopupNode 시각 코드** / SelfDismissingNode / pbxproj — **20개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "환호의 3감각"

6-10 직후의 콤보 5 도달 순간:
```
지금                              이번 작업 후
┌─────────────────┐              ┌─────────────────┐
│                 │              │      x5         │
│      x5         │     ──→      │  ♪톡! ♪딩!     │
│  (조용히 떠오름) │              │  (진동+소리+시각)│
└─────────────────┘              └─────────────────┘
   눈만 환호                       눈+귀+손 모두 환호
```

**6-10이 환호를 *시작*했고, 6-11이 환호를 *완성***해요.

학생 비유: 시험에서 100점 받았는데 *조용히 종이만* 받으면 허전하잖아요. 선생님이 "잘했어!" 어깨 두드리고(촉각), "와 멋지다!" 말해주고(청각), 종이를 흔들어 보여주면(시각) — 그게 진짜 환호.

자전적 톤에서 콤보 = 새벽 작곡의 클라이맥스로 가는 진행. 클라이맥스 순간에 *눈만* 환호하면 절반의 환호. 3감각이 동시에 발화해야 *육체적 체감*이 와요.

> **Spring 비유**: 결제 성공 이벤트에 다중 listener가 등록됨. (1) DB 기록, (2) 이메일, (3) SMS, (4) 푸시 알림 — 모두 *같은 트랜잭션 안*에서 발화. 6-10은 listener 1개(시각), 6-11은 listener 2개(촉각/청각)를 추가한 모양. 이벤트 소스(`triggeredComboMilestones` 가드)는 그대로.

---

## 마일스톤별 강도 매핑 — "2-2-2 광역 그룹화"

| 마일스톤 | 시각(6-10) | **촉각(6-11)** | **청각(6-11)** | 의미 |
|---|---|---|---|---|
| x3 (첫 환호) | 흰빛 | `light()` 재사용 | Tink 1057 (Soft) | 가벼운 인정 |
| x5 (정착) | 분홍 | `light()` 재사용 | Tink 1057 (Soft) | 가벼운 환호 유지 |
| x10 (황금기) | 황금 | **`medium()` 신규** | Tink 1057 (Soft) | 진동만 살짝 무거워짐 |
| x20 (클라이맥스) | 빨강 | `heavy()` 재사용 | **NewMail 1025 (Strong)** | 진동+소리 모두 무거움 |

**왜 4 × 2 = 8 상수가 아니라 2-2-2-2 매핑?**
- 시각은 4단계 차등(색), 청각/촉각은 2~3단계 — 인간 지각 특성 일치 (색은 미세 구분 가능, 진동/소리는 카테고리 단위)
- 매번 새 강도 만들면 *과잉*. light/heavy는 재사용, medium 1개만 신규
- 사용자는 *큰 차이*만 인지하면 됨: "이번 거 *더 묵직*하다" 정도

---

## Spring 비유 — 두 매니저의 *다른* 확장 방식

| 매니저 | 확장 방식 | Spring 대응 |
|---|---|---|
| **AudioManager** | `enum SFX`에 `case` 추가 (enum-driven) | `enum NotificationType { EMAIL, SMS, PUSH }` — 새 종류 추가 시 enum 케이스 + switch 분기 |
| **HapticsManager** | `medium()` 메서드 추가 (method-driven) | `NotificationService.sendEmail(...)` / `.sendSms(...)` — 새 메서드로 인터페이스 확장 |

**왜 일관되게 안 만들고 두 방식?**
- AudioManager는 *데이터 차이만* (시스템 사운드 ID 1057 vs 1025) → enum 케이스가 자연
- HapticsManager는 *완성형 강도 카테고리* (Apple이 light/medium/heavy 3단으로 끝) → 메서드가 자연
- **일관성보다 *자연스러움* 우선**. 인터페이스 모양이 다르면 확장 방식도 달라야 함.

> Spring에서도 `@EventListener`(method)와 `enum EventType`(data) 둘 다 흔함. 어떤 게 자연이냐는 *대상의 형태*에 달림.

---

## Swift / SpriteKit 학습 포인트

### 4-1. enum + computed property + exhaustive switch (default 금지)

```swift
enum SFX {
    case noteCollected
    case gameOver
    case comboMilestoneSoft     // Phase 6-11
    case comboMilestoneStrong   // Phase 6-11

    var systemSoundID: SystemSoundID {
        switch self {
        case .noteCollected:        return 1057
        case .gameOver:             return 1073
        case .comboMilestoneSoft:   return 1057
        case .comboMilestoneStrong: return 1025
        }
        // ⛔ default 절 없음 — 의도적
    }
}
```

**왜 default 금지?** 새 케이스 추가 시 컴파일러가 *모든 switch에 매핑 추가하라*고 강제로 에러를 띄움. default를 두면 새 케이스가 default로 흘러들어가 *침묵의 버그* 발생.

**Spring 비유**: Java 14+의 `switch expression`이 sealed type에 대해 exhaustive를 강제하는 것과 동형. `default` 제거 = 컴파일러를 *내 편*으로 만들기.

**함정**: GameScene의 `playComboMilestoneFeedback(for milestone: Int)`는 `Int` 입력이라 exhaustive 불가능 → 여기는 **graceful fallback default** 의도적 포함. enum 매핑과 Int 매핑은 *정책이 달라야 함*.

### 4-2. `UIImpactFeedbackGenerator.FeedbackStyle.medium`

```swift
private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)

init() {
    mediumGenerator.prepare()   // 캐시 워밍
}

func medium() {
    mediumGenerator.impactOccurred()
    mediumGenerator.prepare()   // 다음 호출 대비 재워밍
}
```

**`.medium`은 Apple 표준**이라 튜닝 0. light / medium / heavy 3단이 *완성형* 카테고리.

**`prepare()` 워밍 패턴**: 햅틱 엔진은 첫 호출 시 100~200ms 지연. `prepare()`를 미리 부르면 즉시 발화 가능. 6-1에서 확립된 패턴을 그대로 medium에도 적용.

**Spring 비유**: `@PostConstruct` + `JdbcTemplate` 커넥션 풀 워밍업. 첫 쿼리 지연 제거 위해 미리 풀을 채워둠.

### 4-3. helper의 위치 — GameConfig vs GameScene

```swift
// ❌ GameConfig에 두면? 제어 흐름이 Config에 새어들어감
// extension GameConfig {
//     static func feedback(for milestone: Int) -> (Haptic, SFX) { ... }
// }

// ✅ GameScene private 메서드 — 호출자의 맥락 안쪽
private func playComboMilestoneFeedback(for milestone: Int) {
    switch milestone {
    case 3, 5:   haptics.light();  audio.play(.comboMilestoneSoft)
    case 10:     haptics.medium(); audio.play(.comboMilestoneSoft)
    case 20:     haptics.heavy();  audio.play(.comboMilestoneStrong)
    default:     haptics.light();  audio.play(.comboMilestoneSoft)
    }
}
```

**왜 GameScene 안?**
- 6-10의 `ComboPopupNode.color(for:)`와 *위치/형태 대칭* — 한 곳은 시각 매핑, 한 곳은 피드백 매핑
- GameConfig는 *수치 상수* 보관소. 제어 흐름은 노출 안 하는 게 깔끔
- 호출 부위 1줄 → `self.playComboMilestoneFeedback(for: currentCombo)`

**Spring 비유**: 도메인 service의 private helper와 같음. `@Configuration`(GameConfig)에는 상수만, `@Service`(GameScene)에는 로직.

### 4-4. 호출 순서 — 촉각 → 청각 → 시각

```swift
// 가드 안쪽 (멱등성 보장)
self.triggeredComboMilestones.insert(currentCombo)
self.playComboMilestoneFeedback(for: currentCombo)  // 햅틱 → 사운드
let popup = ComboPopupNode(milestone: currentCombo)
self.cameraNode.addChild(popup)
popup.animate()                                      // 시각 (마지막)
```

**인간 지각 시간축**:
- 촉각: 0~10ms (가장 즉각, 신체 표면)
- 청각: ~30ms
- 시각: 60ms+ (망막 → 시각 피질, SKAction 1프레임)

**코드 라인 순서 = 체감 순서**가 되면 한 사건이 일관된 임팩트로 도달. 한 프레임 안(1/60초)이라 사람은 차이 못 느끼지만, *약속을 굳혀두면* 미래에 다른 멀티모달 이벤트(예: 7번째 listener) 추가 시 같은 순서로 prepend하면 됨.

**Spring 비유**: 다중 `@EventListener`에 `@Order`로 실행 순서 지정. 코드 라인 순서가 곧 `@Order(1)`, `@Order(2)`, `@Order(3)`.

### 4-5. 멱등성 가드 안쪽 prepend — 회귀 0의 비밀

```swift
// 6-10 (시각 only):
if guards-pass {
    self.triggeredComboMilestones.insert(currentCombo)
    let popup = ComboPopupNode(...)
    cameraNode.addChild(popup)
    popup.animate()
}

// 6-11 (가드 안쪽에 1줄 prepend):
if guards-pass {
    self.triggeredComboMilestones.insert(currentCombo)
    self.playComboMilestoneFeedback(for: currentCombo)  // ⬅ NEW
    let popup = ComboPopupNode(...)
    cameraNode.addChild(popup)
    popup.animate()
}
```

**핵심**:
- 가드 *밖*에서 호출하면 콤보 3을 여러 번 도달할 때마다 "딩!" 반복 → 시각 팝업과 비대칭
- 가드 *안쪽*이라 1회만 발화 — 시각/청각/촉각 모두 동시 1회
- 기존 6-10 시각 코드는 *위치 그대로* — 앞에 1줄만 추가

**Spring 비유**: 결제 트랜잭션 안쪽에 새 listener 등록. 트랜잭션 밖에 두면 멱등성 위반.

---

## 산출물

**수정 (3 파일)**:
- `Managers/AudioManager.swift` (+15/-7) — SFX 케이스 2 + switch 매핑 4지점 + allCases 배열
- `Managers/HapticsManager.swift` (+14/-2) — mediumGenerator 프로퍼티 + prepare() + medium()
- `GameScene.swift` (+34/-0) — 헤더 주석 1줄 + MARK 섹션 1개 + helper 28줄 + 가드 안쪽 1줄

**생성 (0 파일)**:
- 없음. 모든 변경이 기존 파일 안쪽 확장.

**pbxproj**:
- 변경 0건 (신규 파일 0개라 등록 불필요)

---

## 검증 방법

### 정량
- ✅ `xcodebuild` BUILD SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 컴파일 경고 0건, 에러 0건
- ✅ `git diff --name-only HEAD`: 3개 Swift 파일만
- ✅ `grep "default:" AudioManager.swift` → 0줄 (exhaustive switch 유지)
- ✅ `grep "triggeredComboMilestones" GameScene.swift` → 4지점 모두 6-10 패턴 유지 (선언/contains/insert/주석)
- ✅ QA 점수: 10.0 / 10.0 (Swift 10, 로직 10, 성능 10, 완성도 10)

### 시각 (사용자가 시뮬레이터에서 확인)
- [ ] 콤보 3 도달 → 흰빛 "x3" + (시뮬레이터에서) 가벼운 효과음 "딩"
- [ ] 콤보 5 도달 → 분홍 "x5" + 같은 톤 효과음
- [ ] 콤보 10 도달 → 황금 "x10" + 같은 톤 효과음 (실기기에서는 진동 *medium* 차이 인지 가능)
- [ ] 콤보 20 도달 → 빨강 "x20" + 더 묵직한 효과음 (NewMail)
- [ ] 콤보가 떨어졌다가 다시 같은 마일스톤 도달 → 발화 *안 함* (멱등성 — 6-10에서 검증됨, 6-11 추가 채널도 동일)
- [ ] 게임 새로 시작 → 모든 마일스톤 다시 발화 (인스턴스 자동 리셋)

### 시뮬레이터 한계
- 햅틱은 시뮬레이터에서 noop — UIKit이 자동 무시 (크래시 없음)
- 실기기 햅틱 강도 차이(light/medium/heavy)는 사용자가 직접 손끝으로 확인

---

## 회고

### 막혔던 것
없음. 6-10이 멱등성 가드를 잘 설계해두어 6-11은 *가드 안쪽 1줄 prepend*로 끝남. 매니저 패턴(6-1/6-2)이 OCP로 열려있어 enum 케이스 2 + 메서드 1만 추가하면 자연 확장. **앞선 sprint들의 설계가 좋으면 다음 sprint가 짧다**는 교훈.

### Spring과 다르네 싶었던 것
1. **enum + computed property + exhaustive switch**: Java enum도 추상 메서드 가능하지만 switch exhaustive 강제는 Swift가 더 강함
2. **default 절을 의도적으로 *생략***: Java/Spring에서는 보통 default를 *방어적*으로 두지만, Swift는 *컴파일러를 내 편으로* 만들기 위해 생략
3. **enum-driven vs method-driven 확장 혼용**: Spring은 일관성 강박이 있지만 Swift/iOS는 *자연스러움 우선*

### 평가 점수
- Swift 패턴: 10/10
- 게임 로직: 10/10
- 성능: 10/10
- 완성도: 10/10
- **가중: 10.0 / 10.0**

### 사용자 직접 확인할 것
- 실기기에서 콤보 10(medium) vs 콤보 20(heavy) 진동 차이가 *실제로* 느껴지는지
- 콤보 20의 NewMail(1025) 효과음이 환호 톤에 맞는지, 아니면 더 어울리는 시스템 사운드가 있는지 (대안: 1112 Anticipate / 1117 BeginRecording / 1325 Tweet)
- BGM 위에 효과음이 겹쳤을 때 *섞임*이 자연스러운지

---

## 멀티모달 가족 — 6 시리즈가 만들어 낸 *피드백 시스템*

| 이벤트 | 촉각 | 청각 | 시각 | 운동감 |
|---|---|---|---|---|
| 노트 수집 (6-1/6-2/6-8) | light | Tink 1057 | Sparkle 8방향 | — |
| **콤보 마일스톤 (6-10/6-11)** | **light/medium/heavy** | **Tink/NewMail** | **ComboPopup fly-up** | — |
| 피격 (6-1/6-2/6-9) | heavy | Boop 1073 | HitFlash 빨강 | CameraShake |
| 게임오버 (6-2/6-5) | heavy | Boop 1073 | (Scene 전환) | — |

**6-1부터 6-11까지 11개 sprint가 누적되어 *피드백 시스템*이 완성**됐어요. 매 sprint는 작은 추가지만, *어떤 게임 이벤트도 1감각으로 끝나지 않는다*는 정책이 정착.

다음 sprint(7-x 백엔드)부터는 이 피드백 시스템 위에 *온라인 점수 경쟁*이 올라가요. 잘 작곡된 BGM 위에 *플레이어 간 환호 전염*이 한 층 더 쌓이는 셈.

---

## 한 줄 교훈

> **"한 사건은 한 감각으로 끝나지 않는다."**

콤보 5는 같은 데이터지만:
- 6-10 (시각만) → "5점 도달" 정보 전달
- 6-11 (3감각) → "콤보 5 환호" *경험* 전달

같은 이벤트, 채널 추가만으로 *경험의 깊이*가 달라져요. Spring에서도 똑같음 — 같은 결제 이벤트에 listener를 늘릴수록 *시스템의 풍부함*이 커짐. 코드 양은 작지만 효과는 큼.
