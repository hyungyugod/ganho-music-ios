# 24 · Phase 4-1 · 석조무사 — 사각 순환 패트롤 NPC 🚶

> **이번 작업 한 줄**: 정해진 4 지점을 *시계 방향으로* 무한 순환하는 새 NPC를 추가한다. 기존 수간호사가 *플레이어를 추적*한다면, 석조무사는 *정해진 길*만 걷는다 — 두 번째 AI 패턴 도입.

---

## 1. 왜?

지금까지 게임 NPC는 *수간호사 1종*뿐이었다. 매 프레임 *플레이어 위치를 향해* velocity를 갱신하는 **직선 추적 AI**. 단순하고 강력하지만 *한 가지 행동 패턴*만 가능. 게임이 풍부해지려면 *다른 행동 패턴*이 필요하다.

이번에 들어오는 **석조무사**(GDD §7-6)는:
- 맵 4지점을 사각형으로 *순환 순찰*
- 플레이어 위치 무관 — *정해진 길*만 걷는다
- 본 sprint에서는 *시각적 등장*만 (접촉 효과·이스터에그는 4-2로 분리)

> Spring으로 치면: 수간호사 = `@Service`(요청이 올 때마다 즉시 반응), 석조무사 = `@Scheduled`(정해진 주기로 정해진 일을 함). 같은 "Bean"이지만 *언제 무엇을 할지 결정하는 방식*이 다르다.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `EnemyNode.update(deltaTime:targetPosition:)` | `@Service`의 메서드 | "들어오는 인풋(player 위치)에 즉시 반응" |
| `StoneGuardNode`의 `SKAction.sequence(...).repeatForever()` | `@Scheduled(cron = ...)` | "정해진 시간표대로 자동 실행" |
| `SKAction.move(to: waypoint, duration: ...)` | (Java) ScheduledExecutorService.schedule | "이 시각에 이 일을 하라" |
| `repeatForever` | `@Scheduled(fixedRate = ...)` | "끝나면 다시" |

**핵심**: SpriteKit은 **두 가지 *시간 흐름* 모델**을 모두 제공한다.
1. **`update(_:)` 게임 루프** — 매 프레임 코드를 직접 실행 (수간호사 추적)
2. **`SKAction`** — *정해진 시각·기간*에 *정해진 일*을 자동 실행 (석조무사 패트롤)

> 두 번째는 Spring `@Scheduled`처럼 *프레임워크에 시간을 위임*하는 방식. 코드가 깔끔하고 *상태 관리 부담 ↓*.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **`SKAction` — 시간 기반 자동 실행 객체**

```swift
let move = SKAction.move(to: CGPoint(x: 760, y: 100), duration: 10.2)
node.run(move)
```

이 한 줄이 의미하는 바:
- 노드를 *현재 위치 → (760, 100)*까지 *10.2초에 걸쳐 자동 이동*
- 매 프레임 `update`에 코드를 적을 필요 없음
- 보간(linear interpolation)은 SpriteKit이 자동 처리

> Spring으로 치면 "한 줄로 cron job 등록". 직접 시간 계산할 필요 없음.

### 3-2. **`SKAction.sequence` — 여러 액션 연속 실행**

```swift
let patrol = SKAction.sequence([
    SKAction.move(to: w1, duration: t1),
    SKAction.move(to: w2, duration: t2),
    SKAction.move(to: w3, duration: t3),
    SKAction.move(to: w4, duration: t4)
])
```

배열 안의 액션을 *위에서 아래 순서대로* 실행. 첫 액션이 끝나면 두 번째 시작.

> Spring으로 치면 *cron job들의 직렬 체인*. "A 끝나면 B, B 끝나면 C..."

### 3-3. **`SKAction.repeatForever` — 무한 반복**

```swift
let loop = SKAction.repeatForever(patrol)
node.run(loop)
```

sequence를 무한히 반복. 노드가 사라지면 자동 정리.

> Spring으로 치면 `@Scheduled(fixedRate = ...)`의 영원 버전. 게임 종료까지 멈추지 않음.

### 3-4. **수동 update vs SKAction 비교**

| 측면 | EnemyNode (수동 update) | StoneGuardNode (SKAction) |
|---|---|---|
| 행동 결정 | 매 프레임 *플레이어 위치 보고 결정* | 시작 시 *전체 경로 결정*, 이후 자동 |
| 코드 위치 | GameScene.update에서 호출 | init에서 한 번 run 후 끝 |
| 동적 변화 | OK (목표가 매 프레임 바뀜) | 어려움 (정해진 경로만) |
| 적합한 NPC | 추적 / 회피 / 반응형 AI | 패트롤 / 컷씬 이동 / 정해진 동선 |
| Spring 비유 | `@Service` (요청 즉시 응답) | `@Scheduled` (시간표대로) |

**핵심**: 두 패턴 모두 옳다. *NPC의 의도*에 따라 선택.

### 3-5. **속도(px/s) → duration(s) 변환**

```swift
let distance = hypot(w2.x - w1.x, w2.y - w1.y)  // 두 점 사이 거리
let duration = distance / GameConfig.stoneGuardSpeed  // 시간 = 거리 / 속도
let move = SKAction.move(to: w2, duration: duration)
```

기억할 수식: **`duration = distance / speed`**. 중학교 물리.

> SKAction.move는 *duration 기준*이지 *speed 기준*이 아니므로 수동 변환 필요.

### 3-6. **PhysicsBody는 *없음* — 본 sprint OoS**

석조무사는 본 sprint에서 *시각만* 추가. `physicsBody = nil`(기본값 — PhysicsBody 미부착). player와 *통과* 가능. 이상해 보이지만:
- 접촉 효과(이스터에그)는 4-2로 분리
- 충돌 감지를 미리 켜두면 "효과 없는 접촉"이 *보이는데 작동 안 함* → 더 어색
- 4-2에서 PhysicsBody + contactTest 한꺼번에 도입

> Spring으로 치면 "MVP는 일단 시각만, 인터랙션은 다음 스프린트". *얼마나 작게 만들지 명확히 가르는 결정*.

---

## 4. 무엇을 만드나?

### 새 파일 (1개)
| 파일 | 역할 |
|---|---|
| `Nodes/StoneGuardNode.swift` | SKSpriteNode 상속. init에서 4 waypoint 패트롤 SKAction을 즉시 시작 |

### 고치는 파일 (3개)
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | `stoneGuardSpeed: 55`, `stoneGuardWidth/Height: 16/20`, 4 waypoint 좌표 상수 |
| `GameScene.swift` | `private let stoneGuard = StoneGuardNode()` 프로퍼티 + setup 호출 |
| `GameScene+Setup.swift` | `setupStoneGuard()` 메서드 신설 — worldNode에 addChild |

### Xcode pbxproj
- `StoneGuardNode.swift`를 Nodes 그룹·iOS Sources phase 등록 (기존 패턴 답습)

### 4 waypoint 좌표 (시계방향 순회)
```
맵 크기 960×480 (mapColumns 48 × tileSize 20, mapRows 24 × tileSize 20)

  (200, 380) ────→ (760, 380)
       ↑               │
       │               │
       │      🧱       │   ← 중앙 기둥 (480, 240)
       │               ↓
  (200, 100) ←──── (760, 100)
```
- **시작**: (200, 100) (좌하단)
- **시계방향**: 좌하 → 우하 → 우상 → 좌상 → 좌하 ...
- 가로 변: 560pt, 세로 변: 280pt
- 한 바퀴: 1680pt / 55 px/s ≈ **30.5초** (게임 45초 동안 1바퀴 + 약간 더)

### 한 그림으로

```
[GameScene didMove]
  setupBackground / setupWorld / setupPlayer / setupCamera /
  setupDPad / setupHUD / setupEnemy /
  setupStoneGuard()  ← 추가
       ↓
  StoneGuardNode 생성 (init에서 SKAction.repeatForever 자동 시작)
       ↓
  worldNode 자식으로 부착
       ↓
  매 프레임 SpriteKit이 자동 이동 — GameScene.update는 *손대지 않음*
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 시작 직후 | 석조무사 박스(회색? — ColorTokens 검토)가 (200, 100)에서 *오른쪽으로* 이동 시작 |
| (b) | 약 10초 경과 | 석조무사가 (760, 100) 근처 도착 → *위로* 방향 전환 |
| (c) | 약 15초 경과 | (760, 380) 근처 도착 → *왼쪽*으로 |
| (d) | 약 25초 경과 | (200, 380) 근처 도착 → *아래로* |
| (e) | 약 30초 경과 | (200, 100)으로 복귀 → 다시 시계방향 시작 (한 바퀴 완료) |
| (f) | 플레이어가 석조무사와 같은 위치 | **그대로 통과** (PhysicsBody 없음, OoS) |
| (g) | 카메라 이동 (플레이어 따라감) | 석조무사가 worldNode 자식이라 카메라와 함께 시각적으로 흘러감 (정상) |
| (h) | 게임오버 | 석조무사 SKAction이 멈출 필요 X — ResultScene 전환 시 GameScene 통째 ARC 해제 → 석조무사도 함께 사라짐 |

> **핵심**: 사용자는 *움직이는 박스*를 추가로 볼 뿐. 게임플레이 자체는 *변화 0* (접촉 효과는 4-2).

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 첫 sprint 범위 | 석조무사 시각 등장 + 패트롤만 | 작게 분리, 다음 sprint(이스터에그) 토대 |
| AI 방식 | **`SKAction.repeatForever(sequence([move × 4]))`** | 두 번째 AI 패턴 학습 |
| 충돌체 | **PhysicsBody 없음** (OoS) | 본 sprint 시각만 |
| 패트롤 영역 | 사각형 (200,100)–(760,380) | 중앙 기둥·플레이어·수간호사 위치 회피 |
| 방향 | 시계방향 | 임의 |
| 속도 | 55 px/s | GDD §7-6 명세 |
| 색상 | (Generator 결정 — ColorTokens 기존 토큰만) | 새 색 토큰 신설 금지 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클(QA 1회)에 **만점 합격(10.0/10)**. P0/P1/P2 0건.

이번 sprint의 본질 = *기존 시스템을 한 줄도 깨지 않고 새 NPC 추가*. `update()` / `configureContactRouter` / `endGame` 한 글자도 건드리지 않음. SKAction이 자체적으로 시간 흐름을 관리하므로 GameScene이 *모르는 채로* 패트롤이 진행됨.

### 7-2. 새로 배운 것

1. **`SKAction.move(to:duration:)`** — 시작점에서 끝점까지 *자동 보간*. duration은 `distance / speed`로 수동 계산.
2. **`SKAction.sequence([...])`** — 여러 액션을 *직렬 체인*. 첫 액션 끝나면 두 번째.
3. **`SKAction.repeatForever(...)`** — 영원히 반복. 노드 ARC 해제 시 자동 정리.
4. **수동 update vs SKAction 비교** — *추적 AI*는 매 프레임 갱신(EnemyNode), *패트롤 AI*는 시작 시 전체 경로 결정(StoneGuardNode). 같은 NPC지만 *행동 결정 방식*이 다름.
5. **`hypot(dx, dy)`** — 두 점 사이 거리 (피타고라스). `sqrt(dx² + dy²)`보다 *오버플로 안전*하고 가독성 ↑.
6. **`(i + 1) % count`** — 폐곡선 인덱스. 마지막 waypoint에서 첫 waypoint로 자연 복귀.
7. **physicsBody nil 정책** — 본 sprint OoS 명시. *충돌 효과 없을 때 PhysicsBody 부착 금지* — 미래 노이즈 방지.
8. **`zPosition` 일관성** — 5(EnemyNode와 동일). HUD(100) 아래, 일반 노드 위.
9. **SpriteKit의 두 시간 모델** — `update(_:)` 게임 루프(직접 갱신) vs `SKAction`(시간 위임). 둘 다 옳고, *NPC 의도*에 따라 선택.

> Spring으로 치면: `update`는 `@Service`(요청 즉시 처리), `SKAction`은 `@Scheduled(cron = ...)`(시간표대로). 같은 결과를 다른 방식으로.

### 7-3. 다음으로 미룬 것

- **4-2**: 석조무사 PhysicsBody 부착 + 접촉 시 AIRFORCE 이스터에그 (오버레이 + 비행기 + 폭탄 + 수간호사 5초 공포 도주)
- **4-3**: 박병장 비행기 단독 등장
- **4-4**: 이교수 NPC (상 난이도, 청진기 투사체, 일시 마비 효과)
- **`protocol Enemy` 추출**: NPC 종류가 늘어나면 공통점을 protocol로 묶기

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0 0건, P1 0건, P2 0건
- 빌드: BUILD SUCCEEDED, 경고 0건

### 7-5. 핵심 가치 — *건드리지 않는 기술*

이번 sprint에서 가장 큰 가치는 *얼마나 추가했나*가 아니라 **얼마나 건드리지 않았나**:

| 보존된 것 | 변경 0건 |
|---|---|
| `update()` 게임 루프 | ✅ |
| `configureContactRouter()` | ✅ |
| `endGame()` 4단 호출 | ✅ |
| EnemyNode·PlayerNode·NoteNode·ProjectileNode | ✅ |
| HUDNode·DPadNode | ✅ |
| SpawnSystem·ContactRouter·ScoreSystem | ✅ |
| TitleScene·ResultScene | ✅ |
| HighScoreRepository·StatisticsRepository·GameStats | ✅ |
| PhysicsCategory·ColorTokens·GameState | ✅ |

**추가된 것**:
- 신설 1파일 (52줄)
- 수정 4파일 (총 ~15줄 추가)

이 *외과 수술적 변경*이 가능했던 이유 = SKAction이 *자체 시간 관리*하므로 외부 시스템이 알 필요가 없음.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(h) 확인 (특히 (a)~(e) 한 바퀴)
[2] 다음 sprint: Phase 4-2 (석조무사 접촉 + 이스터에그)
```

> **이번 sprint 본질**: SpriteKit의 *두 번째 시간 모델* 등장. `update` 직접 갱신과 `SKAction` 위임은 같은 결과를 다른 방식으로 만든다. 정해진 경로 = SKAction이 자연스럽고, 동적 반응 = update가 자연스럽다. 이 둘을 구분할 줄 알면 *NPC 설계 도구 상자*가 두 배가 된다.
