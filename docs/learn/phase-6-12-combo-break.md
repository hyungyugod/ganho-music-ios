# Phase 6-12 — 콤보 끊김 피드백 (실망의 시각/햅틱)

## 한 줄 요약
콤보 10+에 도달했다가 F 피격이나 음표 놓침으로 0으로 떨어지는 *그 순간* 화면 중앙에 **"x12 BREAK"** 같은 빨간 글자가 **아래로 떨어지며 작아져요** + **묵직한 진동(heavy)**. 6-10/6-11의 *환호*(위로 떠오르며 커짐)와 정확히 *대칭*인 **실망**(아래로 떨어지며 작아짐). 자가 소멸 노드 7호.

---

## 무엇을 했나요?

네 식구가 들어왔어요.

1. **ComboBreakNode** (`Nodes/` 신규) — 자가 소멸 7호. SelfDismissingNode 채택. ComboPopupNode의 *방향 반전 쌍*
2. **GameConfig 상수 6개** — 임계값(10), 폰트 크기, 낙하 거리, duration, 끝 스케일, zPosition
3. **GameScene** — `lastComboValue` + `triggeredComboBreaks` Set 2개 프로퍼티 + update 폴링 5줄 + helper 2개 + onProjectileHitPlayer 1줄
4. **pbxproj 4지점** — UUID 0032 (ComboPopupNode 0031 답습)

회귀 0줄: ScoreSystem / ContactRouter / SpawnSystem / HUDNode / BGMPlayer / AudioManager / Repositories / Models / Protocols / 기존 Nodes 13개 / ComboPopupNode / TitleScene / ResultScene / ColorTokens / SelfDismissingNode / `triggeredComboMilestones` Set — **22개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "환호의 반대편"

```
지금                            이번 작업 후
콤보 12 도달 (환호 발화)         콤보 12 도달 (환호 발화)
    ↓                              ↓
콤보 12에서 F 피격                콤보 12에서 F 피격
    ↓                              ↓
조용히 endGame 화면 전환          "x12 BREAK"이 ↓ 떨어지며 페이드아웃
                                 + 묵직한 진동 + 빨간 화면 플래시
                                       ↓
                                 endGame 화면 전환
```

**환호만 있고 실망이 없으면 멀티모달 피드백이 *반쪽***.

6-10/6-11이 "잘하고 있어!"의 3감각을 완성한 직후엔 자연스럽게 "아, 끊겼다"의 시각화가 그리워져요. 운동장에서 1등 달리다 넘어졌는데 *조용*히 일어나기만 한 기분 — 그 *체감 없는 손실*이 답답함을 만들어요.

학생 비유: 100점 받으면 "와! 100점!" (환호), 그런데 시험지에 빨간 펜으로 "X" 그어지면 *눈에 보이게* X가 그어져야 손실이 체감되죠. 채점 결과만 조용히 통보되면 *피드백 채널이 부족*.

이번 sprint가 그 시각·촉각 채널 추가:
- **시각**: ComboBreakNode 화면 중앙에서 *떨어지며* 사라짐 (1초)
- **촉각**: heavy 진동 한 방 (게임오버와 같은 강도, 부정 이벤트 시그널)
- ~~**청각**~~: 의도적 제외 (이유 §3 참조)

> **Spring 비유**: 결제 *성공* 이벤트만 listener 등록하고 *실패* 이벤트는 무시하면 시스템이 반쪽. 환호 = `@TransactionalEventListener PaymentSuccessEvent`, 실망 = `@TransactionalEventListener PaymentFailureEvent`. 두 이벤트가 *대칭*으로 등록돼야 시스템이 완성형.

---

## 왜 사운드는 뺐을까? — *비대칭의 의도*

| 채널 | 환호 (6-10/6-11) | 실망 (6-12) | 의도 |
|---|---|---|---|
| 시각 | ✅ ComboPopupNode (위로 떠오름) | ✅ ComboBreakNode (아래로 떨어짐) | **대칭** |
| 촉각 | ✅ light/medium/heavy 차등 | ✅ heavy 단일 | 부분 대칭 |
| 청각 | ✅ Tink/NewMail 차등 | ❌ 없음 | **비대칭** |

**왜 청각만 비대칭?**

1. **Sprint 범위 최소화**: AudioManager.SFX 케이스 추가는 OCP로 *언제든* 가능. 본 sprint는 시각+촉각의 대칭 완성에 집중.
2. **환호와의 의도적 차별**: 환호(6-11)는 BGM 위에 효과음이 *얹히는* 톤. 실망은 *침묵의 한숨*이 자연 — 사운드 추가 시 게임오버 사운드(Boop 1073)와 톤 충돌 우려.
3. **다음 sprint 여지**: 6-13에서 *콤보 끊김 사운드*만 단일 책임으로 추가 가능 (enum 케이스 1 + helper 1줄).

> **Spring 비유**: 결제 실패 알림에 *Slack 채널만* 추가하고 SMS는 의도적으로 안 보내는 정책 — *모든 이벤트가 모든 채널로 갈 필요는 없음*. 채널 선택도 디자인.

학생 비유: 친구가 시험 떨어졌을 때 *어깨 두드림(촉각) + 안타까운 표정(시각)*은 자연스럽지만 *큰 소리로 위로*(청각)는 어색해요. 채널마다 *어울리는 이벤트*가 다름.

---

## Spring 비유 — 두 가드의 *완전 분리*

```
GameScene Properties
├── triggeredComboMilestones: Set<Int>  ← 6-10/6-11 환호 가드 (3, 5, 10, 20 도달)
├── triggeredComboBreaks: Set<Int>       ← 6-12 실망 가드 (10+ 끊김)
└── lastComboValue: Int                  ← 6-12 폴링 기준점
```

**두 Set는 한 줄도 안 겹쳐요**. 환호 발화 시 끊김 가드 무변경, 끊김 발화 시 환호 가드 무변경.

> **Spring 비유**:
> ```java
> @Service
> class PaymentService {
>     private Set<Long> idempotentSuccess = new HashSet<>();   // 6-11
>     private Set<Long> idempotentFailure = new HashSet<>();   // 6-12
> }
> ```
> 한 빈에 두 idempotency 키를 두는 건 *서로 독립된 이벤트 종류*라는 뜻. 성공·실패는 각자 자기 처리만 책임.

이 분리가 왜 중요한지:
- 콤보 12 도달 → 환호 발화 → Set 1에 12 insert
- 콤보 12에서 끊김 → 실망 발화 → Set 2에 12 insert
- 다시 콤보 12 도달 → 환호 차단 (Set 1에 이미 있음)
- 다시 콤보 12에서 끊김 → 실망 차단 (Set 2에 이미 있음)
- 콤보 15까지 회복 후 끊김 → "x15 BREAK" 발화 (Set 2에 15 없음 → 새 이벤트)

같은 콤보 *값*은 환호/실망 각각 1회만 발화. 하지만 *값이 다르면* 다른 이벤트 — 진짜 새 사건이라 발화.

---

## Swift / SpriteKit 학습 포인트

### 4-1. SpriteKit 자가 소멸 7호 패턴 — 4·5·6·7호의 누적

```swift
final class ComboBreakNode: SKNode, SelfDismissingNode {
    private let label: SKLabelNode

    init(brokenCombo: Int) {
        self.label = SKLabelNode(text: "x\(brokenCombo) BREAK")
        super.init()
        // ...
    }

    func animate() {
        let moveDown  = SKAction.moveBy(x: 0, y: -GameConfig.comboBreakFallDistance, duration: ...)
        let fadeOut   = SKAction.fadeOut(withDuration: ...)
        let scaleDown = SKAction.scale(to: GameConfig.comboBreakEndScale, duration: ...)
        let group     = SKAction.group([moveDown, fadeOut, scaleDown])
        let cleanup   = SKAction.removeFromParent()
        run(.sequence([group, cleanup]))
    }
}
```

**자가 소멸 노드 7회차 누적**:
1. AirplaneNode (4-3)
2. AirforceOverlayNode (4-4)
3. BombFlashNode (4-5)
4. SparkleEffectNode (6-8)
5. HitFlashNode (6-9)
6. ComboPopupNode (6-10)
7. **ComboBreakNode (6-12)** ← 지금

**7개 모두 3단계 사용법 동일**:
```swift
let node = ComboBreakNode(brokenCombo: 12)
parent.addChild(node)
node.animate()
// → 1초 후 알아서 사라짐. 정리 책임 0.
```

> **Spring 비유**: 7개 빈이 같은 인터페이스(`SelfDismissingNode`) 구현. 호출자는 *구체 빈* 모르고 인터페이스만 알면 됨 (DIP).

### 4-2. ComboPopupNode와의 *방향 반전 쌍*

| 항목 | 환호 (6-10) | 실망 (6-12) |
|---|---|---|
| 이동 | `+y` (위) | `-y` (아래) |
| Scale | 1.0 → 1.4 (확대) | 1.0 → 0.7 (축소) |
| 색 | 등급별 4색 | 빨강 단일 (`.ganhoCrimsonNurse`) |
| Duration | 1.0초 | 1.0초 (동일) |
| zPosition | 150 | 140 (아래) |

**왜 정확한 반전?**
- 인지심리학: *위로 떠오름* = 긍정, *아래로 떨어짐* = 부정 (중력 메타포)
- *확대* = 성취 강조, *축소* = 손실 강조
- 같은 duration → 시간축 대칭이라 *반대 톤*이 명확

> **Spring 비유**: `EventSuccess`와 `EventFailure`가 같은 인터페이스에 *반대 의미*. 채널은 동일(같은 listener 패턴), 의미만 반전.

### 4-3. 폴링 위치의 미묘함 — 1프레임 지연 방지

```swift
override func update(_ currentTime: TimeInterval) {
    super.update(currentTime)
    guard gameState == .playing else { return }
    // ... 기존 로직 (ScoreSystem.tickComboExpiry 포함) ...
    hud.update(...)

    // ⭐ 폴링은 hud.update *직후*에. lastComboValue 갱신은 폴링 *후*에.
    let currentCombo = scoreSystem.combo
    if lastComboValue >= GameConfig.comboBreakThreshold, currentCombo == 0 {
        triggerComboBreak(brokenAt: lastComboValue)
    }
    lastComboValue = currentCombo
}
```

**왜 lastComboValue 갱신이 마지막?**
- `tickComboExpiry()`가 같은 프레임에서 콤보 0으로 떨어뜨림 → 같은 프레임에서 감지해야 1프레임 지연 없음
- `lastComboValue` 갱신을 *비교 전*에 하면 다음 프레임에선 항상 `lastComboValue == 0`이라 끊김 영영 못 잡음

**함정 1**: 만약 `lastComboValue = currentCombo`를 *비교 전*에 두면 영원히 끊김 감지 0. **테스트**: 만약 콘솔에 *colored "x12 BREAK" 안 뜸* 같은 증상이 나오면 이 라인 순서 의심.

**함정 2**: F 피격 분기는 update 흐름 *밖*. SpriteKit physics callback이라 폴링으로 못 잡힘. → **별도 helper 필요** (§4-4).

### 4-4. 두 helper의 분리 — DRY + 진입점 차이

```swift
// 공통 로직 — 둘 다 여기로 수렴
private func triggerComboBreak(brokenAt brokenValue: Int) {
    if triggeredComboBreaks.contains(brokenValue) { return }
    triggeredComboBreaks.insert(brokenValue)
    haptics.heavy()
    let breakNode = ComboBreakNode(brokenCombo: brokenValue)
    cameraNode.addChild(breakNode)
    breakNode.animate()
}

// F 피격 진입점 — 임계값 가드만 추가하고 위로 위임
private func checkAndTriggerComboBreak() {
    let combo = scoreSystem.combo
    if combo >= GameConfig.comboBreakThreshold {
        triggerComboBreak(brokenAt: combo)
    }
}
```

**왜 helper 2개?**
- update 폴링: 콤보 *값* (`lastComboValue`)을 안 채로 호출 → `triggerComboBreak(brokenAt: lastComboValue)` 직접 호출
- F 피격: `scoreSystem.combo` 읽어서 임계값 검사 후 위임 → `checkAndTriggerComboBreak()`
- **공통 동작**(Set 가드 + 햅틱 + 노드 발화)은 `triggerComboBreak`로 통합 → DRY

> **Spring 비유**:
> ```java
> public void doPayment(Payment p) { /* 공통 처리 */ }
> public void doPaymentFromWebhook(WebhookPayload w) {
>     if (w.isValid()) doPayment(w.toPayment());  // 위임
> }
> ```
> 진입점 2개, 공통 로직 1개. *각 진입점의 다른 사전 조건*만 별도 함수가 알면 됨.

### 4-5. ScoreSystem 미수정 — 도메인 시스템 보호 정책

```swift
// ❌ 안 함 — ScoreSystem에 콜백 추가 (옵션 A)
// scoreSystem.onComboBreak = { previousCombo in ... }

// ✅ 함 — GameScene이 폴링 (옵션 B)
let currentCombo = scoreSystem.combo
if lastComboValue >= 10, currentCombo == 0 { ... }
```

**왜 ScoreSystem을 안 건드릴까?**
- 6-10에서 *이미* 마일스톤 폴링으로 결정. 그 결정을 뒤집으면 6-10 sprint를 되돌리는 셈.
- ScoreSystem 책임 = *순수 상태 보관*. 이벤트 발행은 GameScene이 담당.
- listener가 *한 곳*뿐이라 콜백 도입 비용 > 이득.

> **Spring 비유**: `@Entity`는 도메인 상태만, *이벤트 발행*은 `@Service`에서 하는 패턴 (anemic 단순성 vs rich complexity 트레이드오프). 이번 프로젝트는 *anemic 도메인 + smart scene*을 일관되게 유지.

학생 비유: 시계는 *시간만* 보여주면 됨 — 시계가 *알람*까지 책임지면 시계 한 개로는 부족하고, 두 책임을 한 객체에 두면 *시계 고장 = 알람도 고장*. 책임을 *별개 시스템*으로 분리.

---

## 산출물

**신규 (1 파일)**:
- `Nodes/ComboBreakNode.swift` (67줄) — 자가 소멸 7호

**수정 (3 파일)**:
- `Config/GameConfig.swift` (+16줄) — 콤보 끊김 상수 6개 (`comboBreakThreshold=10`, `comboBreakFontSize=48`, `comboBreakFallDistance=60`, `comboBreakDuration=1.0`, `comboBreakEndScale=0.7`, `comboBreakZPosition=140`)
- `GameScene.swift` (+50줄) — Properties 2개 + update 폴링 5줄 + helper 2개 + onProjectileHitPlayer 1줄 + 헤더 주석 1줄
- `GanhoMusic.xcodeproj/project.pbxproj` (+4줄) — UUID 0032 4지점 등록

**pbxproj**:
- 4지점 등록 (PBXBuildFile / PBXFileReference / PBXSourcesBuildPhase / PBXGroup) — ComboPopupNode UUID 0031 패턴 답습

---

## 검증 방법

### 정량
- ✅ `xcodebuild` BUILD SUCCEEDED (iPhone 17 시뮬레이터, iOS 26.4 SDK)
- ✅ 컴파일 경고 0건, 에러 0건
- ✅ `git diff --name-only HEAD`: 4개 파일만 (Swift 3 + pbxproj 1)
- ✅ ScoreSystem / ContactRouter / HUDNode / AudioManager / ColorTokens / ComboPopupNode 변경 0줄
- ✅ `triggeredComboMilestones` 4지점 그대로 (Set 분리 검증)
- ✅ QA 점수: **10.0 / 10.0** (Swift 10, 로직 10, 성능 10, 완성도 10)

### 시각 (사용자가 시뮬레이터에서 확인)
- [ ] 콤보 10 미만(예: 5)에서 음표 놓침 → BREAK *안 뜸* (임계값 가드)
- [ ] 콤보 12 도달 → 환호 ("x10 BREAK 아님, 환호 ComboPopup") → 콤보 윈도우 만료로 0 떨어짐 → 빨간 "x12 BREAK"이 화면 중앙에서 *아래로 떨어지며* 페이드아웃
- [ ] 콤보 15 도달 → F 피격 → 빨간 "x15 BREAK"이 떨어짐 + 묵직한 진동 (실기기) + 빨간 화면 플래시(6-9) + endGame
- [ ] 같은 콤보 값으로 두 번 끊겨도 두 번째는 발화 안 함 (멱등성)
- [ ] 다른 콤보 값으로 끊기면 발화 (예: 12 끊김 → 15 끊김)
- [ ] 새 게임 시작 → Set 리셋 → 모든 끊김 값 다시 발화

### 시뮬레이터 한계
- 햅틱 heavy는 시뮬레이터에서 noop — 실기기로 확인
- BGM/효과음과 시각의 시간차는 시뮬레이터에서도 확인 가능

---

## 회고

### 막혔던 것
없음. SPEC 단계에서 폴링 타이밍 함정(`lastComboValue` 갱신 시점)과 F 피격 별도 경로를 미리 적시했더니 Generator가 빌드 1회로 통과. 매니저 패턴(6-1/6-2)과 자가 소멸 노드(4호~6호) 6번 누적 덕분에 7호는 *완전한 자동주행*. **앞선 sprint의 설계가 좋으면 다음 sprint가 5분 만에 끝난다**는 6-11 회고가 6-12에도 반복.

### Spring과 다르네 싶었던 것
1. **두 Set의 *공존***: Java에서도 가능하지만, Swift `Set<Int>` 인스턴스 변수 2개로 두 가드를 *동일 클래스* 안에 두는 게 깔끔. Spring이라면 `@Service` 안에 idempotency key Map 2개를 두거나 별도 빈으로 분리할 수도 있는데, Swift는 *값 타입* + GameScene 인스턴스 라이프사이클로 자동 리셋이라 더 단순.
2. **방향 반전이 *디자인***: ComboPopup 위→ComboBreak 아래는 코드 한 줄(`-y` vs `+y`)이지만 *플레이어 체감*은 정반대. 이런 *작은 반전*이 큰 의미를 만드는 게 게임 디자인의 특징.
3. **사운드 제외도 *디자인***: 모든 채널을 다 안 채우는 게 *대칭 비대칭의 의도*. Spring에서도 모든 이벤트에 모든 알림 채널을 거는 건 *나쁜 디자인*이라는 교훈과 동형.

### 평가 점수
- Swift 패턴: 10/10
- 게임 로직: 10/10
- 성능: 10/10
- 완성도: 10/10
- **가중: 10.0 / 10.0**

### 사용자 직접 확인할 것
- 실기기에서 콤보 끊김 heavy 진동이 게임오버 heavy 진동과 *구분*되는지 (둘 다 heavy지만 *맥락*이 다름 — 끊김 후엔 게임 진행, 게임오버 후엔 화면 전환)
- "x12 BREAK" 텍스트 색(`.ganhoCrimsonNurse` 재사용)이 빨간 화면 플래시(6-9)와 톤 충돌 안 하는지
- 콤보 윈도우 만료가 너무 빈번해서 BREAK이 *과하게 자주* 뜨는지 (다음 sprint에서 임계값 조정 여지)

---

## 멀티모달 가족 — 환호와 실망의 *대칭 완성*

| 이벤트 | 촉각 | 청각 | 시각 | 운동감 |
|---|---|---|---|---|
| 노트 수집 (6-1/6-2/6-8) | light | Tink 1057 | Sparkle 8방향 | — |
| 콤보 마일스톤 (6-10/6-11) | light/medium/heavy | Tink/NewMail | ComboPopup *위로* ↑ | — |
| **콤보 끊김 (6-12)** | **heavy** | **(의도적 제외)** | **ComboBreak *아래로* ↓** | — |
| 피격 (6-1/6-2/6-9) | heavy | Boop 1073 | HitFlash 빨강 | CameraShake |
| 게임오버 (6-2/6-5) | heavy | Boop 1073 | (Scene 전환) | — |

**Phase 6 시리즈가 12번째 sprint를 거치며 *피드백 시스템*이 완성**됐어요. 매 sprint는 작은 추가지만 *어떤 게임 이벤트도 1감각으로 끝나지 않는다*는 정책이 정착. 환호와 실망이 *대칭*으로 존재하니 게임 진행의 *기복*이 신체로 전달돼요.

---

## 한 줄 교훈

> **"환호의 반대편은 침묵이 아니라 *대칭의 시각화*다."**

콤보 끊김 = 데이터로는 `combo = 0`. 그 데이터를 *어떻게 보여주느냐*에 따라:
- (6-11까지) 조용히 HUD 숫자만 → "5점이구나"
- (6-12 이후) 떨어지는 BREAK 텍스트 + 진동 → **"아, 내 콤보 12 잃었다"**

같은 0이지만 *시각화 채널이 있느냐 없느냐*가 게임 경험의 깊이를 만들어요.

> **Spring 비유**: 모니터링 시스템에서 *성공률 99.5%*는 같은 데이터지만, *대시보드에 빨간 점멸*로 표시하느냐 *조용히 로그만*에 쓰느냐가 운영팀의 반응을 완전히 바꿔요. 같은 정보, 다른 *채널 디자인*.

Phase 6은 이제 **12번째 sprint**까지 누적. 환호/실망/노트/피격/게임오버 5개 이벤트가 *모두 멀티모달*. 다음 sprint(6-13 or Phase 7)로 가는 길은 어디든 자연.
