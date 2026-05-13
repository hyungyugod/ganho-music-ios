# Phase 6-10 — 콤보 마일스톤 텍스트 팝업

## 한 줄 요약
콤보 X3 / X5 / X10 / X20 도달하는 *그 순간*에 화면 중앙에 **"x5"** 같은 큰 텍스트가 떠오르며 위로 올라가다 사라져요. 마일스톤마다 색이 달라요 — 흰빛 → 분홍 → 황금 → 빨강. **한 판에서 같은 마일스톤은 단 한 번만** 발화 (멱등성). 자가 소멸 노드 6호 패턴 답습.

---

## 무엇을 했나요?

다섯 식구가 들어왔어요.

1. **ComboPopupNode** (`Nodes/`) — SKNode + SKLabelNode 자식, SelfDismissingNode 채택 (6호)
2. **GameConfig 상수 6개** — 마일스톤 배열, 폰트 크기, fly-up 거리, 페이드 시간, 끝 스케일, zPosition
3. **GameScene Properties** — `triggeredComboMilestones: Set<Int>` (멱등성 가드)
4. **GameScene onNoteCollected** — 마일스톤 검사 5줄 추가 (sparkle.emit() 이후, removeFromParent 이전)
5. **pbxproj 4지점** — UUID 0031, HitFlashNode(0030) 답습

회귀 0줄: ScoreSystem / HUDNode / AudioManager / HapticsManager / BGMPlayer / Sparkle / HitFlash / BombFlash / ContactRouter / SpawnSystem / TitleScene / ResultScene / 기존 Nodes / ColorTokens / SelfDismissingNode / Repositories / Models / Protocols — **16개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "잘하고 있어!"의 시각화

지금까지 콤보는 HUD 콤보 라벨에 *조용히 숫자만* 증가했어요. 1, 2, 3, 4, 5...

근데 콤보 = *연속 정답*. 게임에서 가장 *잘 하고 있다*는 신호. 그런데 그 신호가 **숫자 1개** 증가뿐이라니. 너무 조용해요.

자전적 톤에서, 사용자가 새벽에 작곡한 BGM이 깔린 채 음표를 연속으로 줍는다는 건 **곡의 클라이맥스로 가는 과정** 그 자체. 그 클라이맥스를 *시각화*하지 않으면 그냥 숫자 게임.

이번 sprint가 그 *환호*를 추가:
- 콤보 3 → 흰빛 "x3" 떠오름 (첫 환호)
- 콤보 5 → 분홍 "x5" (음악 본체 색)
- 콤보 10 → 황금 "x10" (노트의 황금기)
- 콤보 20 → 빨강 "x20" (클라이맥스)

> **Spring 비유**: 점수 시스템(read-only)은 항상 보여주고, *마일스톤 이벤트*는 별도로 발행. `GET /score/current` (HUD) + `@EventListener MilestoneEvent` (Popup). 정보와 임팩트는 **다른 채널**.

학생 비유: 시계는 항상 시간 보여주죠 (HUD). 알람은 특정 시각에만 울려요 (Popup). 시계가 매분 울리면 시끄럽고, 알람이 항상 울리면 의미 없어요.

---

## 폴링 vs 콜백 — 옵션 B 선택의 의미

콤보가 변경되었다는 걸 어떻게 알 수 있을까요? 두 가지 방법.

### 옵션 A: 콜백 (Push)
```swift
// ScoreSystem에 콜백 추가
scoreSystem.onComboReached = { combo in ... }
```
- 점수 시스템이 "콤보 바뀜!"이라고 *능동적으로 알림*
- Spring `@EventListener(ComboReachedEvent)` 패턴

### 옵션 B: 폴링 (Pull) ← **이번 선택**
```swift
// GameScene이 음표 수집 직후 콤보 값 *조회*
self.scoreSystem.recordNoteHit(...)
let currentCombo = self.scoreSystem.combo   // ← 조회
if 마일스톤 도달 { 팝업 }
```
- GameScene이 *수동적으로 확인*
- Spring 컨트롤러가 `userService.getUser(...)` 호출 결과 보고 분기

왜 옵션 B를 택했나요?

1. **회귀 위험 0**: ScoreSystem 코드를 한 글자도 안 바꿈. 단위 테스트도 안 깨짐.
2. **한 곳에서만 듣음**: 콤보 마일스톤을 듣는 건 GameScene뿐. 여러 listener를 받을 필요 없으면 폴링이 단순.
3. **결합도 ↓**: 점수 시스템이 "누가 듣는지" 알 필요 없음. 그냥 자기 일만 함.

> **Spring 비유**: HTTP request scope 안에서 `userService.findById(id)` 후 결과 검사 → 분기. 매번 polling이지만 결합도 가장 낮음. 콜백은 발행자가 listener를 *알아야* 해서 결합도 ↑.

학생 비유: "선생님이 점수 나오자마자 와서 알려주세요" (콜백) 대신 "시험 끝나면 내가 점수 확인하기" (폴링). 한 사람만 알면 되면 폴링이 더 빠르고 단순.

**언제 콜백이 더 좋을까?** — 여러 곳에서 같은 이벤트를 들어야 할 때. 예: 콤보 마일스톤 도달 시 (1) 팝업 표시, (2) 도전 과제 갱신, (3) 통계 기록, (4) 광고 표시 등. 그땐 콜백 패턴이 필수.

---

## 멱등성과 Set<Int> — "출석부 패턴"

콤보가 3 도달 → "x3" 팝업 → 콤보 윈도우 만료로 0 → 다시 3 도달.

이 경우 "x3" 팝업이 또 떠야 할까요?

**아니오.** 한 판에서 같은 마일스톤은 한 번만 보여줘야 시각 노이즈가 없어요. 곡의 클라이맥스는 한 곡에 한 번이잖아요.

해결: `triggeredComboMilestones: Set<Int>`로 *이미 본 마일스톤*을 기억.

```swift
if GameConfig.comboMilestones.contains(currentCombo),       // 마일스톤인가?
   !self.triggeredComboMilestones.contains(currentCombo) {  // 처음 도달인가?
    self.triggeredComboMilestones.insert(currentCombo)      // 메모지에 적기
    // ... 팝업 발화
}
```

이게 **멱등성(idempotency)** 패턴. 같은 키에 대해 한 번만 처리.

> **Spring 비유**: 결제 API에서 `idempotency-key` 헤더로 같은 요청 중복 처리 방지. 또는 Redis `SETNX`로 "이 키 처음이야?" 확인. 또는 `@Transactional` 안에서 INSERT 중복 차단.

학생 비유: 출석부에 한 번 체크하면 두 번 체크 안 하잖아요. 출석부 = `Set<학생이름>`. 김간호가 출석했으면 `김간호.insert`. 다시 와도 `contains == true`라 또 안 체크.

### 자동 리셋의 우아함

한 판 끝나고 새 게임 시작하면? GameScene이 *새 인스턴스*로 만들어져요. 새 인스턴스 → `triggeredComboMilestones`는 빈 Set로 자동 초기화. **별도 reset 코드 필요 0**.

```swift
private var triggeredComboMilestones: Set<Int> = []
//                                              ↑
//                            새 GameScene = 새 빈 Set
```

> **Spring 비유**: `@Scope("request")` 빈은 매 HTTP request마다 새 인스턴스. 이전 request의 상태가 자동 청소돼요. 우리도 마찬가지 — GameScene 한 판 = 1 인스턴스 = 1 출석부.

`endGame()`에 `removeAll()` 추가? 안 했어요. **과잉 안전망**이고, SPEC 범위 외. 인스턴스 라이프사이클 신뢰.

---

## SKAction.group의 동시 액션

ComboPopupNode 애니메이션은 3채널이 *동시* 진행:

```swift
let moveUp  = SKAction.moveBy(x: 0, y: 80, duration: 1.0)
let fadeOut = SKAction.fadeOut(withDuration: 1.0)
let scaleUp = SKAction.scale(to: 1.4, duration: 1.0)
let group   = SKAction.group([moveUp, fadeOut, scaleUp])  // ← 동시!
```

- 위로 80pt 이동
- 알파 1 → 0 페이드
- 크기 1.0 → 1.4 확대

세 액션이 *같은 1초 동안 동시* 진행 → "위로 떠오르며 커지며 사라짐" = *별이 폭발하듯 멀어짐*.

> **Spring 비유**:
> - `group` = `CompletableFuture.allOf(moveTask, fadeTask, scaleTask)` — 셋 다 끝나야 다음 단계
> - `sequence` = `chainedFuture.thenCompose(...).thenCompose(...)` — 앞 끝나야 다음 시작

학생 비유: 운동회 계주는 *sequence* (한 명 끝나야 다음). 합창은 *group* (모두 동시에 한 곡). 콤보 팝업은 합창 — 세 효과가 *같은 시간축*에서 노래해야 한 호흡.

### sequence와 group의 조합

```swift
run(.sequence([group, cleanup]))
//   ↑           ↑       ↑
//   순차       동시     자가 제거
```

`group`(동시 1초) → 끝나면 → `cleanup`(removeFromParent) **순차** 진행. 시간 관계가 정확.

---

## 시각 위계 — 마일스톤 등급별 색 차등

마일스톤마다 색이 달라요:

| 마일스톤 | 색 | 의미 |
|---|---|---|
| x3 | `.ganhoPaper` 흰빛 | 첫 도달 — 깔끔한 환호 |
| x5 | `.ganhoPinkNote` 분홍 | 음악 본체 색 |
| x10 | `.ganhoYellowF` 황금 | 노트의 황금기 |
| x20 | `.ganhoBloodAccent` 빨강 | 클라이맥스 |

**왜 색을 다르게?** 텍스트("x3" vs "x20")는 *읽어야* 알아요. 색은 *느낌*으로 즉시 인식.

> **Spring 비유**: HTTP 상태 코드 색상과 정확히 같아요.
> - 2xx (성공) — 흰색·녹색
> - 3xx (리다이렉트) — 분홍·청색
> - 4xx (클라이언트 오류) — 노랑
> - 5xx (서버 오류) — 빨강
>
> 색이 *등급*을 1초 안에 전달. 인간 시각은 색을 글자보다 빠르게 처리해요.

학생 비유: 신호등 빨강·노랑·초록. 글자 "정지/주의/진행" 안 읽어도 색만 보고 알잖아요. **인지 비용**을 색에 위임.

### switch + default fallback

```swift
private static func color(for milestone: Int) -> UIColor {
    switch milestone {
    case 3:  return .ganhoPaper
    case 5:  return .ganhoPinkNote
    case 10: return .ganhoYellowF
    case 20: return .ganhoBloodAccent
    default: return .ganhoPaper        // ← 미래 대비
    }
}
```

`default`가 있는 이유? 만약 미래에 마일스톤 배열에 `25`를 추가했는데 switch는 안 업데이트하면? `default`가 graceful fallback. 크래시 X, 그냥 흰빛으로 표시.

> **Spring 비유**: API 응답 매핑 시 unknown status code → `null` 또는 `Unknown`로 fallback. 시스템이 *예상치 못한 입력*에 우아하게 대응.

학생 비유: 음식점 메뉴에 없는 메뉴 주문하면 "추천 메뉴 드릴게요"라고 대안 제시. 손님이 짜증나지 않게.

---

## HUD 라벨 vs 팝업 — 정보 vs 임팩트 분리

게임 화면에는 두 가지 다른 *콤보 표시*가 있어요:

| | HUD comboLabel | ComboPopupNode |
|---|---|---|
| 부모 | cameraNode | cameraNode |
| 표시 시간 | *항상* (지속) | *1초만* (일회성) |
| 위치 | 고정 (예: 우측 상단) | 화면 중앙 |
| 폰트 크기 | 18 (작음) | 48 (큼, 임팩트) |
| 색 | 한 가지 | 등급별 차등 |
| 역할 | 정보 (현재 콤보 = 5) | 임팩트 (마일스톤 도달!) |

**왜 둘 다 필요?** 정보와 임팩트는 *다른 채널*이에요.

> **Spring 비유**:
> - HUD comboLabel = `@RestController GET /combo/current` — 언제든 조회 가능한 read API
> - ComboPopupNode = `@EventListener ComboMilestoneEvent` — 특정 이벤트만 발화하는 알림

두 채널이 *섞이면* 안 돼요:
- HUD에 임팩트 섞기 → 평소 *조용*해야 할 정보가 시끄러워짐
- 팝업에 지속 정보 두기 → 화면이 항상 가려짐

학생 비유: 시계(HUD) = 항상 시간 보여줌. 알람(팝업) = 특정 시각에만 울림. 둘이 *분리*돼야 둘 다 제 역할.

이번 sprint는 HUD를 한 글자도 안 건드리고 *별도 팝업 노드*만 추가. 책임 분리.

---

## 자가 소멸 6호 — 패턴의 누적

자가 소멸 노드 가족:
1. **AirplaneNode** (4-3) — AIRFORCE 비행기
2. **AirforceOverlayNode** (4-4) — "나와라 박병장" 오버레이
3. **BombFlashNode** (4-5) — 폭탄 누런 섬광
4. **SparkleEffectNode** (6-8) — 음표 흰빛 별빛
5. **HitFlashNode** (6-9) — 피격 빨간 플래시
6. **ComboPopupNode** (6-10) — 콤보 마일스톤 텍스트 ← 지금 추가

6개가 같은 패턴 따르니까 이제 **우리 코드베이스의 규범**이 됐어요.

호출자(GameScene) 입장에서 6호 사용법:
```swift
let popup = ComboPopupNode(milestone: 5)    // 1. 생성
cameraNode.addChild(popup)                   // 2. 부착
popup.animate()                              // 3. 발화
// → 1초 후 알아서 사라짐. 정리 책임 0.
```

5호 HitFlashNode 사용법:
```swift
let flash = HitFlashNode()
cameraNode.addChild(flash)
flash.flash(sceneSize: size)
```

4호 SparkleEffectNode 사용법:
```swift
let sparkle = SparkleEffectNode()
worldNode.addChild(sparkle)
sparkle.emit()
```

세 노드의 *3단계 사용 패턴*이 똑같아요. 메서드 이름만 다름(animate/flash/emit). **인지 부담 0**.

> **Spring 비유**: 한 빈에 `@Component @Service @Repository` 어떤 걸 붙일지 *프로젝트마다* 다르면 매번 고민. 팀 규칙 — "domain logic은 `@Service`, DB 접근은 `@Repository`" — 가 있으면 즉시 결정. **규범의 가치**: 의사 결정 부담을 줄여줘요.

다음 7호 노드를 만들 때:
- 4호/5호/6호 어느 하나를 reference로 쓰면 됨
- 인터페이스 자동으로 일치
- pbxproj 4지점 등록 패턴 그대로

---

## 이번 sprint의 한 줄 교훈

**"같은 정보라도 *언제* *어떻게* 보여주느냐에 따라 의미가 다르다."**

콤보 = 5는 같은 숫자지만:
- HUD에서 평범하게 1, 2, 3, 4, **5**로 증가 → "5점이구나"
- 화면 중앙에 분홍 "x5"가 떠오름 → **"우와 콤보 5 달성!"**

같은 데이터, 다른 표현. *임팩트의 차이*가 게임 경험을 바꿔요.

> **Spring 비유**: 시스템 모니터링에서 같은 메트릭이라도:
> - 그라파나 대시보드(HUD) → 평소 조용히 그래프
> - 슬랙 알림(Popup) → 임계치 돌파 시 *환호 또는 경고*
>
> 채널이 분리되어야 각자 제 역할.

Phase 6 시리즈는 이제 **사운드 7개 + 시각 3개 (sparkle 긍정 / hit 부정 / combo popup 긍정 강조)** + 운동감 1개(셰이크) = 11개 폴리싱 디테일. BGMPlayer가 자족적 매니저가 됐듯, *피드백 시스템*도 자족적으로 성장 중.

다음 sprint는 어디로 가도 자연스러운 흐름이에요.
