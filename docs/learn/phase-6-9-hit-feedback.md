# Phase 6-9 — F 피격 카메라 셰이크 + 빨간 화면 플래시

## 한 줄 요약
수간호사한테 F 학점 맞으면 **화면이 0.28초 좌우로 흔들리고**, 빨간 반투명 막이 **0.30초 동안 화면을 덮었다 사라져요**. 6-8 sparkle(긍정 흰빛 별빛)의 *정반대 톤* — 부정 피드백의 완성. 진동(6-1) + 사운드(6-2) + BGM 정지(6-4) + 셰이크 + 플래시 = **5채널 멀티모달 피격 피드백**.

---

## 무엇을 했나요?

다섯 식구가 들어왔어요.

1. **CameraShakeAction** (`Systems/`) — case 없는 enum 네임스페이스, `static func make()`가 SKAction 1개 반환
2. **HitFlashNode** (`Nodes/`) — SKSpriteNode + SelfDismissingNode, 자가 소멸 5호
3. **GameConfig 상수 7개** — 셰이크 진폭/횟수/스텝 + 플래시 alpha/페이드인/페이드아웃/zPosition
4. **GameScene onProjectileHitPlayer 콜백** — 1줄에서 5줄로 확장 (셰이크 → 플래시 부착 → flash() → endGame)
5. **pbxproj 8지점** — 2 파일 × 4 지점

회귀 0줄: AudioManager / HapticsManager / BGMPlayer / ScoreSystem / ContactRouter / SpawnSystem / TitleScene / ResultScene / 기존 Nodes / Repositories / Models / Protocols — **20개 파일 미접촉**.

---

## 왜 이게 필요했을까? — "맞았다는 걸 5채널로"

게임에서 F 투사체에 맞으면 즉시 gameOver. 0.4초 후 ResultScene으로 전환. 그 0.3초가 게임의 **가장 강렬한 순간**.

지금까지 그 순간에 있던 것:
- **손**: 진동 heavy (6-1) ✓
- **귀**: gameOver 효과음 (6-2) ✓
- **귀**: BGM 페이드 아웃 시작 (6-4) ✓
- **눈**: ... 아무것도 (음표 색만 변할 뿐 화면 자체는 평소와 동일)

눈이 비어있었어요. 학생 비유: 시험에서 F 맞은 *순간* 머리가 *띵*하게 울리잖아요. 화면도 그래야.

이번 sprint가 그 *띵*을 시각화:
- **운동감**: 카메라 좌→우→좌→우 0.28초 셰이크
- **시각**: 빨간 반투명(alpha 0.55) 화면 잠깐 덮음 0.30초

이제 5채널이 endGame 멱등 가드 안쪽에서 *동시* 발화 — 게임에서 가장 풍부한 감각 순간.

> **Spring 비유**: `@TransactionalEventListener`에 등록된 다중 리스너가 한 이벤트(피격)에 *동시* 반응. 알림 + 로그 + 메트릭 + 슬랙 + 이메일 ... 채널마다 별개 listener. 6-9는 5번째와 6번째 listener 등록.

---

## 부정 피드백 vs 긍정 피드백 — 6-8과의 디자인 대칭

이번 sprint의 가장 인상적인 부분.

| | **6-8 sparkle (긍정)** | **6-9 hit (부정)** |
|---|---|---|
| 트리거 | 음표 수집 (반복) | F 피격 (1회) |
| 색 | 흰빛 별빛 | 빨강 혈색 |
| 방향 | 노트에서 *밖으로* 방사 (8방향) | 화면 전체 *덮음* + 카메라 흔들림 |
| 시간 | 0.5초 (여운) | 0.30초 (즉발) |
| 위치 | worldNode (월드 좌표) | cameraNode (화면 좌표) |
| 햅틱 | light (6-1) | heavy (6-1) |
| 의미 | 만족감 | 충격감 |

같은 **자가 소멸 노드 패턴**을 정반대 의미에 적용 — 6-8 SparkleEffectNode(4호)와 6-9 HitFlashNode(5호)가 *같은 SelfDismissingNode protocol*을 채택. 코드 어휘 재사용의 진수.

> **Spring 비유**: 같은 인터페이스(`UserService`)에 정반대 구현체 — `RegisterUserService` vs `DeleteUserService`. 둘 다 *사용자에 영향*을 주지만 의미가 정반대. 패턴은 같고 방향만 다름.

학생 비유: "노래방에서 박수받으면 조명이 화려하게 *반짝* (sparkle), 실수하면 화면이 빨갛게 깜빡 (hit). 같은 조명 시스템, 반대 메시지."

---

## SKCameraNode 활용 — "카메라가 흔들리면 세상이 흔들린다"

이번 sprint의 가장 중요한 기술 결정.

게임에는 이미 `cameraNode`가 있고 player를 follow 중이에요. 카메라를 흔들면:
- worldNode 자식(player, enemy, note, sparkle) → 카메라 기준 *상대적*으로 이동 → 흔들림 보임
- cameraNode 자식(HUD, D-Pad, HitFlash) → 카메라와 *함께* 이동 → 같이 흔들림 → 흔들림 효과 더 강함

```swift
cameraNode.run(CameraShakeAction.make())  // 단 한 줄
```

이 한 줄이 화면 전체를 흔들어요. 마법.

> **Spring 비유**: `ApplicationContext.refresh()` 같은 *상위 레벨에서 한 번 흔들면* 모든 자식 빈들이 재초기화되는 발상. 카메라 = 컨텍스트, 자식 노드 = 빈.

UIKit 비유: `UIView.animate { view.transform = .translate(by: 8, 0) }`. SpriteKit에서는 cameraNode에 `moveBy` SKAction.

---

## "단순 직선 셰이크" — sin파 random 떨림 안 쓰는 이유

셰이크 알고리즘은 그냥 좌→우→좌→우 반복.

```swift
+amp → -2amp → +2amp → -2amp → +2amp → -2amp → +amp(복귀)
```

sin파 random 떨림이 *생물학적*으로 자연스럽지만 *학습 단계*에선 단순 sequence가 훨씬 좋아요.

- **예측 가능**: 6 step + 복귀 1 = 7 step. 정확히 0.28초.
- **디버깅 쉬움**: 누적 변위 0이 되는지 *수동 검산* 가능 (count=6 검산표 봤죠?)
- **코드 짧음**: for 루프 + 부호 토글 = 12줄

```
i=0: +8   (누적 +8)
i=1: -16  (누적 -8)
i=2: +16  (누적 +8)
i=3: -16  (누적 -8)
i=4: +16  (누적 +8)
i=5: -16  (누적 -8)
복귀:+8   (누적   0) ✓
```

**누적 변위 0**이 핵심. 셰이크 끝나면 카메라가 *정확히* 시작 위치로 돌아옴. follow 좌표와 어긋남 0.

> **Spring 비유**: 단순 `@Scheduled(fixedRate=1000)` vs 복잡한 `@Scheduled(cron="0/5 * * * * MON-FRI")`. 학습 단계에선 fixed-rate가 압도적. 복잡한 cron은 검증할 일이 많아 디버그 지옥.

random 셰이크는 Phase 7+에서 검토. **premature optimization 금지** — swift-rules.md 정책.

---

## "원위치 복귀" 부호 결정 — 짝수/홀수 일반화

count=6은 짝수라 누적이 -amp → 복귀는 +amp.
count=5라면? 홀수라 누적이 +amp → 복귀는 -amp.

```swift
let returnDx: CGFloat = (count % 2 == 0) ? +amp : -amp
```

이 한 줄이 *일반화*. count를 6에서 7로 바꿔도 자동으로 부호 맞춰져요. 만약 단순히 `+amp`만 박았다면 count 변경 시마다 부호 수정 필요 → 버그 자리.

> **Spring 비유**: 빈 의존성 자동 주입 — `@Autowired`가 타입 보고 알아서 매핑. 만약 매 곳에서 빈 이름을 명시했으면 빈 이름 바뀔 때마다 수정 지옥. 자동화 가능한 건 자동화.

이런 *수학적 일반화*가 future-proof의 시작.

---

## enum 네임스페이스 — "case 없는 enum"의 활용

`CameraShakeAction`은 case가 없는 enum.

```swift
enum CameraShakeAction {
    static func make() -> SKAction { ... }
}

// 사용
cameraNode.run(CameraShakeAction.make())
```

왜 enum? 왜 class도 struct도 아닌?

- **인스턴스화 차단**: case가 없으면 `let x = CameraShakeAction()` 불가능 (enum 컴파일러가 막음). 의도치 않은 인스턴스 생성 방지.
- **namespace 역할**: `CameraShakeAction.make()` 형태로 호출 — 정적 함수 그룹.
- **상태 없음 명시**: 인스턴스 변수 둘 수 없어 *순수 함수만* 가짐을 강제.

> **Spring 비유**:
> - `@Component`가 아닌 `static factory method`만 있는 utility class
> - Lombok의 `@UtilityClass` (final + private constructor + 모두 static)
> - 또는 Kotlin의 `object` 키워드 — 싱글톤 namespace

학생 비유: "수학에서 `Math.sqrt(...)`는 인스턴스화 안 해요. `let m = Math()` 안 만들고 그냥 `Math.sqrt(4)`. Math는 *함수 모음*이지 객체가 아니에요."

---

## Rule of Three — "두 번까지는 별개"

HitFlashNode와 BombFlashNode가 비슷해요:
- 둘 다 화면 전체 덮는 SKSpriteNode
- 둘 다 SelfDismissingNode 채택
- 둘 다 fadeIn → fadeOut → 자가 제거

근데 다른 점도 많아요:
- 색: 누런 흰빛 vs 빨강
- 트리거: AIRFORCE 이스터에그 vs F 피격
- 타이밍: 0.42초 (wait 2.1 + fade) vs 0.30초 (즉발)
- alpha 피크: 1.0 (완전 차단) vs 0.55 (반투명)
- zPosition: 250 vs 200

공통 추출(BaseFlashNode protocol/superclass)을 *지금* 안 했어요. **Rule of Three** 원칙:

> "같은 패턴이 **3번 등장하면** 그때 추출."

왜? 2개 비교는 *우연*일 수 있어요. 3개째 등장해야 *진짜 공통점*이 드러납니다.

만약 BaseFlashNode를 *지금* 추출하면? 3번째 플래시(예: 보너스 점수 노란 플래시)가 새 요구사항을 들고 와서 abstract가 깨질 수 있어요. **premature abstraction** — 추상화의 무덤.

> **Spring 비유**: 두 컨트롤러가 비슷하다고 `AbstractBaseController` 만들지 말 것. 세 번째 컨트롤러가 abstract를 *깨면서* "사실 1번이랑 2번도 다른 방향이었네" 깨달음. 추상화는 *세 번 보고* 한다.

학생 비유: "친구 두 명이 비슷한 옷 입고 와도 *우연*. 세 명이 똑같이 입고 오면 *유행*. 그제야 '이건 트렌드구나' 인정해요."

---

## 트리거 순서 고정 — "셰이크 → 플래시 → endGame"

```swift
self.cameraNode.run(CameraShakeAction.make())    // 1
let flash = HitFlashNode()                          // 2
self.cameraNode.addChild(flash)                     // 3
flash.flash(sceneSize: self.size)                   // 4
self.endGame()                                      // 5
```

순서가 *반드시* 이래야 해요. 왜?

**만약 endGame 먼저 호출하면?**
- `gameState = .gameOver` 전환
- 다음 프레임에 update가 `cameraNode.position = player.position`로 카메라 *덮어쓰기*
- 셰이크 액션이 *별개 큐*에서 진행되지만, 셰이크 첫 스텝(+amp 이동)이 적용되는 *그 한 프레임*에 follow가 player 좌표로 cameraNode.position 덮어씀 → 셰이크 잠식

**시각 효과를 endGame 전에 발화하면?**
- gameState는 *아직* .playing
- 다음 프레임에 update가 early return — gameState 가드 통과 못 함 (이미 endGame 호출 후엔 .gameOver)
- 셰이크 액션이 단독으로 cameraNode.position 변경

결국 endGame 호출 *후*에야 update의 카메라 follow가 정지 → 셰이크가 시각적으로 보임. 이게 *의도된* 동작.

> **Spring 비유**: 트랜잭션 안에서 이벤트 발행 후 commit. Commit 전에 이벤트 listener들이 작업 시작하면 *읽지 못한 데이터*에 의존할 수 있음. 본 sprint도 비슷 — endGame이 state 전환의 commit, 그 *전*에 시각 효과 listener들이 일을 시작해 두는 패턴.

학생 비유: "선생님이 종 치기 *전*에 답안지 다 작성해놔야 해요. 종 치고 나면 답안지 못 받아요. 시각 효과(답안지)를 endGame(종) 전에 보낸다."

---

## ColorTokens 재사용 — "이미 있는 걸 다시 만들지 않기"

assets.md에 정의된 색 토큰 중 `ganhoBloodAccent` (HEX #D8315B)가 *이미* "피격 플래시" 용도로 명시되어 있었어요. 새로 만든 게 아니라:

```swift
super.init(texture: nil, color: .ganhoBloodAccent, size: .zero)
```

ColorTokens.swift는 **0줄 변경**.

왜 중요할까?
- **색 일관성**: 게임 전체에서 *같은 빨강*을 쓰면 시각 어휘가 명료
- **튜닝 한 곳**: 빨강을 좀 더 진하게 바꾸려면 ColorTokens.swift 한 줄만 수정
- **assets.md ↔ 코드 정합**: 디자인 문서가 코드의 진실과 일치

> **Spring 비유**: `application.yml`에 정의된 색상값 vs 컨트롤러마다 하드코딩. 디자인 시스템은 *한 곳에 모이고 모든 곳에서 참조*가 정답.

---

## SelfDismissingNode 5호 — 패턴의 누적

자가 소멸 노드 가족:
1. **AirplaneNode** (4-3) — AIRFORCE 비행기
2. **AirforceOverlayNode** (4-4) — "나와라 박병장" 오버레이
3. **BombFlashNode** (4-5) — 폭탄 누런 섬광
4. **SparkleEffectNode** (6-8) — 음표 흰빛 별빛
5. **HitFlashNode** (6-9) — 피격 빨간 플래시 ← 지금 추가

5개가 같은 패턴 따르니까 이제 **우리 코드베이스의 규범**이 됐어요. 6호, 7호 추가할 때마다 *같은 모양*으로 안전하게 짤 수 있어요.

다음 사람이 이 코드를 읽을 때:
- "어, 자가 소멸 노드네. SelfDismissingNode 채택했으니 알아서 사라지겠지"
- "BombFlash/HitFlash 패턴 그대로 답습하면 되겠다"

**규범의 가치**: 의사 결정 부담을 줄여줘요.

> **Spring 비유**: 한 빈에 `@Component @Service @Repository` 어떤 걸 붙일지 *프로젝트마다* 다르면 매번 고민. 팀이 합의된 규칙 — "domain logic은 `@Service`, DB 접근은 `@Repository`" — 가 있으면 즉시 결정.

---

## 이번 sprint의 한 줄 교훈

**"강렬한 순간을 만드는 건 채널 수가 아니라 채널의 *동기*다."**

게임오버 0.3초에 진동 + 사운드 + BGM 정지 + 셰이크 + 플래시가 *동시* 발화. 채널 하나하나는 단순해요. 근데 *같은 0.3초 안에 5개가 함께* 일어나면 사용자 인지에 폭발적 임팩트.

- 진동만 있으면 → "어, 뭐가 있었나?"
- 진동 + 소리만 → "아, 졌네"
- 진동 + 소리 + 셰이크 + 빨강 → **"맞았다!"** (몸으로 느낌)

각 채널이 *조금씩 더해지는* 게 아니라 *곱연산*. 1+1+1+1+1 = 5가 아니라 1×2×2×2×2 = 16의 임팩트.

> **Spring 비유**: 모니터링이 *로그 1채널*보다 *로그 + 메트릭 + 트레이스 + 알람*이 합쳐졌을 때 디버깅 능력이 폭발적으로 향상. 채널 수가 아니라 *동시 관측*이 핵심.

Phase 6 시리즈는 이제 **사운드(6-1~6-7) + 시각(6-8 긍정, 6-9 부정) + 운동감(6-9 셰이크)**으로 4채널 폴리싱이 완성됐어요. 다음 sprint는 어디로 가도 — 6-R 종결 / 새 시각 폴리싱 / Phase 7 백엔드 — 자연스러운 흐름.
