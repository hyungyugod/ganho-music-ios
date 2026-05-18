# Phase 7-2 학습 노트 — Hard 맵 도입

## 오늘 만든 것

난이도 **중/상**을 고르면 게임 맵이 *완전히 달라져요*.

- **하**: 넓은 평지 + 중앙에 작은 기둥 1개 (기존)
- **중·상**: 네 모서리에 **방 4개** + 가운데에 **기둥 4개**

각 방은 *문이 한 칸*만 있어서 들어가면 숨을 수 있고, 동시에 *수간호사가 막아서면 갇혀요*. 양면성을 가진 공간이에요.

## 원본 웹 게임의 디자인을 *그대로* 옮긴 이야기

원본 웹 게임(`hyungyugod.github.io`)에는 이미 이 hard 맵이 있었어요. JavaScript로 짜여 있는 32열×20행 그리드. 그런데 모바일 버전은 *48열×24행*이라 그리드 자체가 더 커요 (드론 카메라 대응).

### 세 가지 옮김 전략을 비교했어요

| 옵션 | 전략 | 단점 |
|---|---|---|
| A | 원본 32×20을 모바일 정중앙에 *그대로* 배치 | 가장자리(좌우 8칸 / 위아래 2칸)가 텅 빔 |
| B | 비율 ×1.5/×1.2 곱해서 확대 | 방의 가로/세로 비율이 늘어남 (왜곡) |
| **C** | **원본의 *가장자리 거리*는 유지, *중앙 빈 공간만* 확장** | 디자인 의도 100% 보존 |

옵션 **C** 채택. 사용자가 *"디자인 같아야 한다"* 고 했으니까요.

### 수학적으로 "거울 대칭"이 작동하는지 확인

옵션 C는 *좌상 방* 좌표만 정하고, 나머지 우상/좌하/우하는 *공식* 으로 자동 계산:

```
우상 = 좌상의 좌우 거울  → mirroredC = 47 - c
좌하 = 좌상의 상하 거울  → mirroredR = 23 - r
우하 = 두 거울 모두 적용
```

검증:
- 좌상 가로벽 c=4~9 → 우상 c=38~43 (47-9=38, 47-4=43) ✓
- 좌상 세로벽 r=18~21 → 좌하 r=2~5 (23-21=2, 23-18=5) ✓
- 좌상 문 r=20 → 좌하 r=3 (23-20=3) ✓

수학적으로 *완벽한 대칭*. 한 셀이라도 어긋나면 QA가 잡았을 거예요. **0건**.

## "y축이 뒤집혀 있다"는 함정

원본 웹 게임은 *HTML5 캔버스* 라 **y가 아래로 증가**해요 (좌상단이 0,0). SpriteKit은 *수학 좌표계*라 **y가 위로 증가**해요 (좌하단이 0,0).

이걸 모르고 원본 좌표 `r=5` (원본 위쪽)를 모바일 r=5에 그대로 옮기면 — 시각적으로 *맵 아래쪽*에 방이 그려져요. 디자인 의도와 정반대.

해결: 원본 r=5 (위쪽) → 모바일 r=18 (`23-5=18`, 상하 거울). SpriteKit r=18은 *시각적으로 위쪽*이라 의도와 일치.

**Spring 비유** — JPA `@Entity`의 데이터베이스 열 ID와 객체 ID가 다를 때처럼, *좌표계의 기준점이 다른 두 시스템* 사이를 변환할 때 *공식을 명시적으로 작성*해야 안전해요. 본 sprint는 SPEC에 *"23-r 거울 적용"* 을 박아두었어요.

## "통짜 벽 + 빈 픽셀" 함정

세로벽에 문이 있어요. 좌상 방의 세로벽은 r=18~21 (4칸)인데 그 중 r=20 한 칸이 *문* 이라 비어 있어야 해요.

### 잘못된 방법 (안전해 보이지만 망함)
```swift
// 통짜 SKSpriteNode 1개 + 시각적으로만 비워 보이게
let wall = SKSpriteNode(color: .ganhoPaper, size: (1, 4))  // r=18~21 통짜
wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
```
이러면 *시각이 어떻든* PhysicsBody가 *4칸 전체*를 막아서 플레이어가 문으로 못 들어가요. 게임이 망가져요.

### 올바른 방법 (분리)
```swift
// SKSpriteNode 여러 개 — 문 한 칸을 건너뛰며 1×1 직사각형들
for r in rStart...rEnd where r != doorR {
    addRectPillar(cStart: c, cEnd: c, rStart: r, rEnd: r)
}
```
좌상 r=18,19,21이 *각각 별개* SKSpriteNode. r=20은 *아예 노드가 안 만들어짐* → 빈 공간 → PhysicsBody도 없음 → 플레이어 통과 가능.

**Spring 비유** — `@Transactional` 이 메서드 단위로 커밋되는 것처럼, *PhysicsBody는 노드 단위로 만들어진다*. 한 노드 안에 *빈 픽셀* 이 있어도 PhysicsBody는 *전체 직사각형* 으로 잡혀요. 그래서 *논리적으로 따로 떨어진 것은 노드도 따로* 만들어야 해요.

## `setupMap()` — "단일 진입점" 패턴

지금까지 `setupWorld()`가 직접 `addOuterWalls()` + `addCentralPillar()` 두 줄을 호출했어요. 이제 그 사이에 *난이도 분기* 가 필요한데, 그걸 `setupWorld()`에 직접 박으면 책임이 흐려져요.

```swift
// Before
func setupWorld() {
    worldNode.position = .zero
    addChild(worldNode)
    addOuterWalls()
    addCentralPillar()
}

// After
func setupWorld() {
    worldNode.position = .zero
    addChild(worldNode)
    setupMap()                         // 단일 진입점에 위임
}

func setupMap() {
    addOuterWalls()                    // 공통
    switch difficulty {
    case .easy:           addCentralPillar()
    case .normal, .hard:  addHardMap()
    }
}
```

이제 `setupWorld`는 "월드 컨테이너 부착"만 책임지고, `setupMap`은 "맵 구조 결정"만 책임져요. 각자 한 가지 일.

**Spring 비유** — `@Service` 클래스가 너무 많은 책임을 가지면 *Facade 패턴* 으로 단일 진입점을 만들고 그 안에서 *세부 작업*을 분기해요. SRP(Single Responsibility Principle). 같은 발상.

## `default` 안 쓰는 이유 — enum의 안전 장치

```swift
switch difficulty {
case .easy:           addCentralPillar()
case .normal, .hard:  addHardMap()
// default 안 씀!
}
```

만약 미래에 누가 `Difficulty` enum에 `.extreme` 같은 새 케이스를 추가하면? Swift 컴파일러가 *"switch must be exhaustive"* 에러를 띄워줘요. 그러면 *반드시* 이 switch를 보고 .extreme에서 무엇을 할지 결정해야 해요.

만약 `default: addCentralPillar()` 같은 안일한 fallback을 두면? `.extreme`이 추가돼도 *컴파일이 통과*하고 *부지불식간에 easy 맵*이 사용돼요. 버그.

**Spring 비유** — `@JsonInclude(Include.NON_NULL)` 같이 *명시적 동작*을 강제하는 옵션. *모호함을 컴파일 타임에 잡아내는 가드레일*. enum과 switch의 조합은 Swift가 자랑하는 안전 장치예요.

## 헬퍼 함수의 응집도 — `addRectPillar`가 모든 일을 한다

```swift
private func addRectPillar(cStart: Int, cEnd: Int, rStart: Int, rEnd: Int) {
    // 1. 타일 좌표 → 픽셀 좌표 변환
    // 2. SKSpriteNode 생성 + 색
    // 3. PhysicsBody 정책 (category=wall, isDynamic=false, ...)
    // 4. worldNode에 추가
}
```

그리고 `addHorizontalWall` / `addVerticalWall`은 *얇은 wrapper*에요. 가로벽은 *1×n 직사각형*, 세로벽은 *문 한 칸 빼고 1×1을 여러 번 호출*. 본질은 둘 다 `addRectPillar`로 환원돼요.

```swift
private func addHorizontalWall(cStart: Int, cEnd: Int, r: Int) {
    addRectPillar(cStart: cStart, cEnd: cEnd, rStart: r, rEnd: r)
}

private func addVerticalWall(c: Int, rStart: Int, rEnd: Int, doorR: Int) {
    for r in rStart...rEnd where r != doorR {
        addRectPillar(cStart: c, cEnd: c, rStart: r, rEnd: r)
    }
}
```

**Spring 비유** — `JpaRepository`의 `save()`가 안에서 *모든 ORM 작업*을 하고, 비즈니스 코드는 단순히 `save()`를 부르는 것처럼. *복잡한 일은 한 곳에 모으고, 호출하는 쪽은 단순하게*. 같은 원리.

## 회귀 0의 다층 안전망

이번 sprint는 *2개 파일만* 변경했어요. 다른 모든 파일은 git diff 0줄. 이게 가능한 이유:

1. **`difficulty` 프로퍼티 이미 존재** — Phase 7-1에서 만들어둔 GameScene 인스턴스 프로퍼티. 이번엔 *읽기만* 함.
2. **`addCentralPillar` 본체 무변경** — easy 경로는 *기존 함수 그대로 호출*. 한 줄도 안 건드림.
3. **새 함수만 추가** — addHardMap / 헬퍼 3개는 *전부 신규*. 기존 호출자가 0이라 부작용 0.
4. **GameConfig는 *추가만*** — 기존 상수 0건 변경. 새 MARK 섹션 신설.
5. **pbxproj 변경 0** — 신규 파일 0개라 Xcode 프로젝트 등록 0.

**Spring 비유** — *Backwards-compatible API 추가*. 기존 호출자가 *아무것도 모르고도* 그대로 동작. *오직 새 호출자만* 새 기능을 본다. 큰 시스템의 변경 전략.

## 오늘의 한 줄

> *"원본 게임의 4-방-디자인을 모바일 48×24 그리드에 거울 대칭으로 옮기되, 공식 두 줄(47-c, 23-r)이 좌표 표 전체의 자기 검증을 한다"*
