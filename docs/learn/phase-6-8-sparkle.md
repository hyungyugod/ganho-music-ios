# Phase 6-8 — 음표 수집 시 sparkle 파티클

## 한 줄 요약
음표를 먹는 순간 그 자리에 **8개의 흰빛 별빛 파편**이 8방향으로 펼쳐졌다가 0.5초 안에 사라져요. 사운드(6-2) + 햅틱(6-1)에 이어 *시각* 채널까지 더해진 멀티모달 피드백 완성. BGMPlayer 8연속 sprint 후 **첫 시각 폴리싱** sprint — Phase 6의 결.

---

## 무엇을 했나요?

세 식구가 들어왔어요.

1. **SparkleEffectNode** — 새 자가 소멸 노드 (4호)
2. **GameConfig 상수 6개** — 파편 개수/크기/거리/시간/zPosition/끝 스케일
3. **GameScene onNoteCollected 클로저에 5줄** — 음표 위치 캡처 + sparkle 생성 + emit

회귀 0줄: AudioManager / HapticsManager / BGMPlayer / ScoreSystem / ContactRouter / SpawnSystem / TitleScene / ResultScene / 다른 Nodes 모두 변경 없음.

---

## 왜 이게 필요했을까? — "박수만 있고 조명이 없으면 허전해요"

게임 음표를 먹으면 지금까지는:
- **귀**: "팅~" 효과음 (6-2)
- **손**: 가벼운 진동 (6-1)
- **눈**: ... 아무것도 안 일어남 (음표가 그냥 사라짐)

세 채널 중 하나가 비어있었어요. 노래방에서 곡을 부르고 박수받는 순간을 떠올려봐요 — 박수 소리 + 진동 + 조명 깜빡임이 *동시*에 일어나잖아요. 조명 없으면 뭔가 허전해요.

sparkle이 그 *조명* 역할.

이 게임의 자전적 톤: 사용자가 새벽 병동에서 작곡한 곡. 어두운 BG(#1A1B2E) 위에 분홍 음표가 별처럼 떠 있어요. 음표 = 별. 그래서 음표를 먹는 순간이 *별이 잠시 터지는* 순간이 되면 미학적으로 완성. 흰빛 8방향 방사가 그걸 시각화.

> **Spring 비유**: 한 이벤트(노트 수집)에 등록된 다중 `@TransactionalEventListener`들이 *동시* 반응. 알림 발송 + 로그 기록 + 메트릭 수집처럼 채널 분리. 6-8은 *시각* 채널 등록.

---

## SKAction.group vs SKAction.sequence — 핵심 차이

이번 sprint의 가장 큰 학습 포인트.

```swift
// group — 동시에
let combined = SKAction.group([move, fade, scale])
child.run(combined)
// → 이동, 페이드, 스케일이 동시에 0.5초 동안 진행

// sequence — 차례로
let combined = SKAction.sequence([wait, cleanup])
run(combined)
// → wait 0.5초 끝나야 cleanup 시작
```

| | group | sequence |
|---|---|---|
| 진행 방식 | 동시 (parallel) | 차례로 (serial) |
| 총 길이 | max(액션 길이들) | sum(액션 길이들) |
| 용도 | 한 노드에 여러 효과 동시 | 일이 순서대로 일어나야 할 때 |

sparkle은:
- 각 파편: 이동 + 페이드 + 스케일이 *동시* → `group`
- 컨테이너: wait(0.5초) → removeFromParent *차례로* → `sequence`

> **Spring 비유**:
> - **group = `CompletableFuture.allOf(a, b, c)`** — 비동기 작업 a, b, c를 동시에 시작, 셋 다 끝나면 다음. 한 메서드 안에 3개의 외부 API 호출을 *병렬*로 던지는 패턴.
> - **sequence = `future.thenCompose(...).thenCompose(...)`** — 앞 작업 결과를 다음 작업이 받아 *직렬*로 진행. 트랜잭션 안에서 INSERT → SELECT → UPDATE를 순서대로.

게임은 *시간의 예술*이라 group/sequence를 자유자재로 쓰는 게 중요해요. 6-5의 페이드 인/아웃에서도 setVolume이 비동기로 보간되는 게 같은 발상이었고, 6-8은 그걸 SKAction으로 *명시적*으로 한 거예요.

---

## SKShapeNode의 가벼움 — "텍스처 없는 도형"

sparkle 파편 1개는 단 한 줄이에요.

```swift
let particle = SKShapeNode(circleOfRadius: 2.0)
```

여기서 끝. **이미지 파일 0개**, **텍스처 캐시 0**, **포토샵 0**.

SpriteKit에는 두 가지 노드 패밀리가 있어요:
- **SKSpriteNode**: 이미지 텍스처 표시. PNG/JPG/.spriteatlas 필요. 게임 캐릭터/배경에 적합
- **SKShapeNode**: 도형(원/사각형/path) 표시. 코드만으로 즉시 만듦

sparkle처럼 *짧게 살아 있는 추상 입자*에는 SKShapeNode가 완벽. 새벽 1시에 "별빛 8개 만들어볼까?"하고 6초 안에 만들 수 있어요.

> **Spring 비유**: `@RestController`가 String 1줄 응답하는 것 vs 큰 JSON 객체 응답. 가벼운 응답은 캐시도 안 필요하고 만들기도 쉬워요. 무거운 응답이 *항상* 정답은 아니에요 — 짧고 단순한 게 충분할 때가 많아요.

학생 비유: "축제 폭죽 = SKSpriteNode (텍스처 풍부, 화려). 라이터 불꽃 = SKShapeNode (간단, 즉석). sparkle은 라이터 불꽃 톤."

---

## SelfDismissingNode 4호 — 패턴의 누적

Phase 4-R에서 추출한 SelfDismissingNode protocol을 채택하는 노드가 이제 4개:
1. **AirplaneNode** (Phase 4-3) — AIRFORCE 비행기
2. **AirforceOverlayNode** (Phase 4-4) — "나와라 박병장" 오버레이
3. **BombFlashNode** (Phase 4-5) — 폭탄 화면 플래시
4. **SparkleEffectNode** (Phase 6-8) — 음표 sparkle ← 지금 추가

공통 책임: **"한 번 등장 → 액션 수행 → 자가 제거"**. 호출자는 add만 하면 됨, 정리는 노드 본인.

```swift
// 호출자 입장 (3줄)
let sparkle = SparkleEffectNode()
sparkle.position = noteOrigin
worldNode.addChild(sparkle)
sparkle.emit()
// 노드는 0.5초 후 알아서 사라짐 — 호출자가 cleanup 책임 0
```

이게 *fire-and-forget* 패턴이에요. 호출자가 결과 안 기다리고 그냥 던지면 자체 종료.

> **Spring 비유**:
> - `@Async` 메서드 호출 — Future 안 받으면 fire-and-forget
> - 일회용 빈 — `@Scope("request")`처럼 요청 끝나면 자동 정리
> - 또는 메시지 큐에 보낸 후 응답 안 기다리는 패턴

**패턴이 누적될수록 가치 ↑**. 1개일 때는 "이거 굳이 protocol?" 싶지만 4개가 같은 패턴 따르면 *우리 코드베이스의 규범*이 됨. 5호, 6호 추가될 때마다 같은 모양으로 안전하게 짤 수 있어요.

---

## "좌표 캡처 타이밍"의 미묘함

GameScene 변경 5줄에서 가장 미묘한 부분.

```swift
let sparkleOrigin = note.position    // ← 먼저 캡처
let sparkle = SparkleEffectNode()
sparkle.position = sparkleOrigin     // ← 캡처한 값 사용
worldNode.addChild(sparkle)
sparkle.emit()
note.run(.removeFromParent())        // ← 그 후 제거
```

순서가 바뀌면 어떻게 될까?

```swift
note.run(.removeFromParent())        // 먼저 제거하면
let sparkleOrigin = note.position    // note의 parent가 nil이라 좌표 의미 불명확
```

note가 worldNode 자식이었을 때 `note.position`은 worldNode 좌표계 기준값. parent에서 빠지면 그 좌표가 *어디 기준인지* 모호해져요. 게다가 ARC가 청소하기 전에 잠깐은 메모리에 남아 있어 *우연히* 동작할 수도 — 그게 더 무서워요. 가끔 동작하는 버그가 가장 추적하기 어려워요.

> **Spring 비유**:
> - DB 트랜잭션 안에서 SELECT한 값을 *커밋 전에* 사용 vs 커밋 후 사용. 커밋 후엔 entity가 detached 되어 lazy field가 LazyInitializationException 던질 수 있어요. **자원의 생명 주기 안에서 값을 다 써야 함**.
> - 또는 `Optional.map { $0.someValue }` 안에서 값 추출 vs `Optional`이 nil이 된 *후* 추출. 명확한 수명 안에서.

**규칙: 자료의 *수명*과 사용 시점을 일치시킨다**. 사라질 자료는 사라지기 *전*에 필요한 정보 다 캡처.

---

## GameConfig 상수 6개 — 모든 수치는 한 곳

SparkleEffectNode 안에는 매직 넘버가 0개예요. 모든 수치는 GameConfig에서.

```swift
// GameConfig.swift — 한 곳에 모음
static let sparkleParticleCount: Int = 8
static let sparkleParticleRadius: CGFloat = 2.0
static let sparkleSpawnDistance: CGFloat = 24
static let sparkleFadeDuration: TimeInterval = 0.5
static let sparkleZPosition: CGFloat = 30
static let sparkleEndScale: CGFloat = 0.2
```

왜?
1. **튜닝 한 곳**: "파편 6개로 줄여볼까?" → GameConfig 한 줄만 수정
2. **6개월 뒤 가독성**: `2.0`이 코드 어딘가에 박혀 있으면 "이게 뭐였더라?" → 이름이 의도를 설명
3. **swift-rules.md §7 매직 넘버 금지** 정책 일관

각 상수에 짧은 의도 주석을 달았어요. "왜 8개인가? 4면 빈약, 16면 노이즈"같은 *디자인 결정의 근거*를 코드 옆에 둠.

> **Spring 비유**: `application.yml`에 `sparkle.particle-count: 8`로 빼고 `@Value("${sparkle.particle-count}")` 주입받는 패턴. 운영 중 튜닝이 쉬워져요.

수학 상수 `2 * CGFloat.pi`의 `2`만 매직 넘버 *예외* — `2π = 한 바퀴`는 수학 정의라 별도 상수로 빼면 오히려 의미 흐려져요. 이런 *수학적 상수*는 코드에 직접 두는 게 명료.

---

## 회귀 0 — 새 sprint가 옛 코드를 안 건드림

이번 sprint에서:
- AudioManager / HapticsManager / BGMPlayer — **0줄 변경**
- ScoreSystem / ContactRouter / SpawnSystem — **0줄 변경**
- TitleScene / ResultScene — **0줄 변경**
- 기존 Nodes (Player/Enemy/Note/Projectile/HUD/Card/Airplane/Bomb/AirforceOverlay) — **0줄 변경**
- Repositories / Models / Protocols — **0줄 변경**

변경된 곳은 *반드시 변경되어야만 하는* 4곳:
- 새 SparkleEffectNode.swift (신규)
- GameConfig.swift (상수 추가)
- GameScene.swift (sparkle 트리거 5줄)
- pbxproj (파일 등록 4지점)

이게 **외과수술적 변경**이에요. 칼이 닿은 곳만 다친다.

> **Spring 비유**: 새 `@RestController` 추가가 기존 컨트롤러를 안 건드리고, 기존 Service를 *호출만* 함. 새 기능이 옛 기능의 어떤 라인도 안 만지면 회귀 위험 0.

8 sprint 누적이지만 BGMPlayer가 1번 깨진 적 없고, ScoreSystem이 1번 깨진 적 없어요. **좁은 변경 표면 + 좁은 인터페이스의 누적 효과**.

---

## 60fps 유지 — "8개 × 0.5초"의 부담

성능 분석:
- 음표 수집 빈도: ~1~2개/초 (콤보 시 더 빠를 수 있음)
- sparkle 컨테이너 수명: 0.5초
- 동시 sparkle 컨테이너 최대: ~3~4개
- 동시 SKShapeNode 최대: 24~32개

SKShapeNode 30개 정도는 60fps 영향 무시 가능. SKSpriteNode와 달리 텍스처 캐시 안 쓰고, 도형 자체가 GPU에 매우 친화적.

만약 콤보 X10에 음표가 5개/초로 들어오면 sparkle ~20개 컨테이너 = ~160개 SKShapeNode. 그래도 60fps 유지 가능 — SKShapeNode 100개 단위는 iOS 디바이스에 큰 부담 아님.

> **Spring 비유**: REST API에 1초당 100 요청 들어와도 응답이 1줄 String이면 부담 미미. 처리량은 *작업의 무게*에 비례. 가벼운 노드 100개 << 무거운 노드 10개.

만약 미래에 60fps 깨지면 *그때 가서* 최적화 (object pool, SKEmitterNode 전환 등). **premature optimization 금지** — swift-rules.md 정책.

---

## 이번 sprint의 한 줄 교훈

**"가벼운 도구로 큰 임팩트를 만들 수 있다."**

- 코드 ~70줄 (SparkleEffectNode 68줄 + GameScene 9줄)
- 새 텍스처 0, 새 사운드 0, 새 햅틱 0
- 회귀 0줄

그런데 게임 경험상으로는:
- 음표 수집 만족감이 *압도적으로* 증가
- 자전적 톤(음악=별)의 시각적 완성
- 3채널(햅틱+사운드+시각) 멀티모달 피드백 완성

가벼움이 좋은 게 아니라, **"불필요한 무거움을 안 더하는 것"**이 좋은 거예요. SKShapeNode 8개로 충분한 임팩트가 나오는데 SKEmitterNode + .sks 파일 + 텍스처를 더할 이유 없어요.

> **Spring 비유**: 새 API를 만들 때 SpringBoot Web 풀스택이 *항상* 답은 아니에요. Spring Web MVC 슬림 버전 / WebFlux / 또는 그냥 Functional Bean — 작업의 무게에 맞는 도구. 무거운 도구를 안 꺼내는 것도 실력.

Phase 6 시리즈는 이제 **사운드 인프라(6-1~6-7) + 시각 폴리싱(6-8)** 으로 폭이 넓어졌어요. 다음 sprint는 어디로 가도 (또 다른 시각 폴리싱 / Phase 6-R 종결 / Phase 7 백엔드) 자연스러운 흐름.
