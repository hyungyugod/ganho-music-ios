# Phase 9-4 — 체크보드 바닥 + Normal 난이도 전용 맵

## 이번에 한 일을 한 줄로

게임 바닥을 *체스판처럼* 두 가지 색깔이 번갈아 깔리게 하고, "중(normal)" 난이도에 *방 두 개를 오가는 새로운 지도*를 만들었다.

---

## 왜 이걸 했나?

지난 Phase 8에서 타이틀/리절트/HUD 같은 *바깥쪽 UI*는 모두 코럴 톤 카드 디자인으로 통일했어. 그런데 정작 *게임 화면 안*은 그냥 검은색 배경이라 "다른 게임으로 넘어온 느낌"이 났어. 그래서 게임 바닥에도 같은 톤을 깔아주는 게 첫 번째 목표.

두 번째 목표는 난이도 정체성. "중" 난이도가 그동안 "상" 난이도와 *완전히 똑같은 지도*를 썼어. 이번에 "중"만의 지도(좌우 방 + 가운데 문)를 만들어서 진짜로 *다른 게임 경험*을 줬어.

---

## 무엇을 만들었나?

### 1. 체크보드 바닥 (시각만, 1152개 타일)

맵은 가로 48칸 × 세로 24칸 = 1152칸으로 이루어져 있어. 한 칸마다 작은 사각형 노드를 하나씩 깔았어.

```swift
for c in 0..<GameConfig.mapColumns {
    for r in 0..<GameConfig.mapRows {
        let color = ((c + r) % 2 == 0) ? floorA : floorB
        // 사각형 만들어서 컨테이너에 붙임
    }
}
```

`(c + r) % 2 == 0` 이 한 줄이 *체스판 패턴*의 비결이야. 가로+세로 좌표 합이 짝수면 색 A, 홀수면 색 B. 그러면 자연스럽게 두 색이 엇갈리게 깔려.

### 2. 1152개 노드를 컨테이너 한 개로 묶기

1152개를 worldNode에 *직접* 다 붙이면 worldNode의 자식 목록이 어마어마하게 길어져. 그래서 빈 SKNode 컨테이너 하나 만들고, 그 안에 1152개를 다 넣고, 컨테이너 하나만 worldNode에 붙였어.

Spring Boot 비유로 치면 — Controller에서 1152개 모델을 `model.addAttribute` 1152번 부르는 대신, *한 번에 List<Model> 한 덩어리*로 넘기는 거랑 같아.

```swift
let container = SKNode()  // 빈 봉투
// ... 1152개 타일을 container 안에 다 넣고
worldNode.addChild(container)  // 봉투 하나만 워크스페이스에 붙임
```

### 3. physicsBody 없음 (성능의 핵심)

만약 1152개 노드 각각에 *물리 효과*(부딪힐 수 있는 박스)를 붙이면 게임이 매 프레임마다 1152번 물리 계산을 해야 해. 60fps가 박살나. 그래서 "이건 *그냥 그림*이야, 부딪히지 않아"라고 SpriteKit한테 알려주려고 `physicsBody`를 아예 안 붙였어.

Spring Boot 비유 — `@Entity` 안 붙은 단순 DTO 같은 거. DB에 안 들어가고 JPA가 신경 안 쓰니까 빠르지.

### 4. zPosition = -100 (깊이 순서)

zPosition은 *위/아래 겹침 순서*야. 숫자가 클수록 *위*(앞), 작을수록 *아래*(뒤).

- 체크보드 바닥: `-100` (제일 뒤)
- 외곽 벽 / 기둥: `0` (기본)
- 캐릭터들 (Player/Enemy/StoneGuard): `5` (앞)
- HUD: `100` (제일 앞)

이렇게 하면 자연스럽게 *체크보드는 바닥에 깔리고 그 위에 벽, 그 위에 캐릭터*가 보여.

### 5. setupWorld()에서 1회만 호출

체크보드는 게임이 시작할 때 한 번만 깔면 끝. 매 프레임마다 다시 그릴 필요 없어. 그래서 `setupWorld()` 안에서 *딱 한 번* `addCheckerboardFloor()`를 호출했어.

```swift
func setupWorld() {
    worldNode.position = .zero
    addChild(worldNode)
    addCheckerboardFloor()  // 1회만!
    setupMap()
}
```

`update()` 안에서는 절대 호출 안 해. Spring 비유 — `@Bean` 등록 한 번 하고 끝, 매 요청마다 다시 만들면 메모리 폭발.

### 6. Normal 맵 — 방 두 개 + 가운데 문

좌표를 그림으로 그리면:

```
r=23 [외곽 벽 top                  ]
r=22                  |
r=21                  |  (분리벽)
r=20                  |
...                   |
r=13                  |
r=12   [좌방 기둥]    .   [우방 기둥]   ← 문! 분리벽이 비어있음
r=11   [좌방 기둥]    .   [우방 기둥]   ← 문!
r=10                  |
r=9                   |
...                   |
r=2                   |  (분리벽)
r=1
r=0  [외곽 벽 bottom              ]
       0  10  20 23  30  40  47
```

`c=23`(가로 23번째 칸)에 세로로 벽을 쌓되, `r=11, 12` 두 칸은 *비워서* 플레이어가 좌↔우 방을 오갈 수 있는 문을 만들었어.

비결은 `addVerticalWall`을 *두 번* 호출하는 거야:
- 윗 절반: `r=2..10`까지만 벽
- 아랫 절반: `r=13..21`까지만 벽
- 사이의 `r=11, 12`는 아무도 안 건드려서 자연스럽게 비어있는 *문*이 됨

### 7. 색 두 가지 — `#1a1722`와 `#13111a`

원본 웹 게임의 *카드 패널 색깔*(`#17151e`)과 *어두운 배경*(`#09080f`) 사이의 중간 톤 두 개를 골랐어. 너무 비슷하면 체크보드인지 알아볼 수 없고, 너무 다르면 시각 노이즈. 미묘하게 다른 두 차콜이 *깊이감*만 살짝 주는 정도.

---

## Swift/SpriteKit 패턴 메모

### private 메서드 접근 — *같은 파일* 안에 둬야 함

`addRectPillar`와 `addVerticalWall`은 `private`이야. Swift에서 `private`은 *같은 파일+같은 타입*에서만 접근 가능해. 그래서 새로 만든 `addNormalMap()`을 *반드시* `GameScene+Setup.swift` 같은 파일 안에 둬야 했어.

만약 다른 파일에 뒀으면 컴파일러가 "addVerticalWall is inaccessible due to 'private' protection"이라고 화냈을 거야.

Spring Boot 비유 — `private` 메서드는 *같은 Service 클래스 안에서만 쓰는 헬퍼*야. 다른 Service에서 부르려면 `protected`나 `public`으로 바꿔야 하잖아.

### 매직 넘버 0건

모든 좌표/색깔/zPosition을 `GameConfig.swift`에 상수로 빼뒀어. 호출하는 쪽 코드(`GameScene+Setup.swift`)에는 `48`, `24`, `"#1a1722"` 같은 *날 숫자/문자열*이 단 하나도 없어. 다 `GameConfig.mapColumns`처럼 이름이 붙은 상수를 통해 가져와.

Spring Boot 비유 — `application.yml`에 `app.batch.size: 100` 적고 코드에서 `@Value("${app.batch.size}")` 가져오는 거. 절대 코드에 `100`을 직접 박지 않잖아.

### switch에 default 없음

```swift
switch difficulty {
case .easy:   addCentralPillar()
case .normal: addNormalMap()
case .hard:   addHardMap()
}
```

`default:` 케이스를 일부러 안 썼어. 왜냐면 나중에 누가 `Difficulty` enum에 `.veryHard`를 추가하면 Swift 컴파일러가 *바로* "이 switch에 .veryHard 처리가 없다"고 경고를 띄워주거든. `default`가 있으면 그냥 조용히 default로 빨려 들어가서 버그를 못 잡아.

Spring Boot 비유 — `@Valid` 안 붙은 DTO가 잘못된 값이 들어와도 조용히 통과되는 거랑 같음. 컴파일러가 못 본 척하는 게 *나쁜* 거야.

---

## 회귀 방지 (안 건드린 부분)

이번 작업의 진짜 핵심은 *고치지 말아야 할 것*들. 다음은 한 글자도 안 건드렸어:

- `addOuterWalls()` — 외곽 벽 4개
- `addCentralPillar()` — easy 중앙 기둥
- `addHardMap()` — hard 맵 전체
- `addRectPillar / addHorizontalWall / addVerticalWall` — 헬퍼 3개
- Player/Enemy/StoneGuard 노드, HUD, TitleScene, ResultScene 등

Phase 7-2~Phase 8-5에서 쌓아온 결과물에 한 줄도 손대지 않고, *추가*만 한 거지 *변경*은 안 했어. 이게 회귀(이미 잘 되던 게 다시 망가짐)를 막는 비결.

Spring Boot 비유 — 기존 Service 클래스 메서드를 *수정*하는 대신, *새 메서드*를 추가하기. 옛 호출자들은 영향 0.

---

## 자주 헷갈리는 부분

### "1152개나 만들면 느려지지 않나?"

SKSpriteNode는 *시각 렌더링*은 GPU가 알아서 배치 처리해줘서 빠른 편이야. 진짜 느려지는 건 *물리 시뮬레이션*이지. 그래서 physicsBody만 안 붙이면 1152개도 거의 무료에 가까워.

비유 — Spring에서 List<DTO> 1152개 들고 있는 건 가볍지만, 그 1152개를 다 DB에 INSERT 치려면 느린 거랑 같음. *데이터 메모리에 있는 것*과 *연산이 도는 것*은 다른 비용.

### "doorR=-1 sentinel이 뭐야?"

`addVerticalWall(c:rStart:rEnd:doorR:)` 함수는 doorR 한 칸만 비워두고 나머지는 다 벽으로 채워. 그런데 *문이 필요 없을 때*는 어떻게 부르지? 그래서 `-1`(-있을 수 없는 row 번호)을 넘기면 *전부 다 벽*이 되도록 했어. 

```swift
for r in rStart...rEnd where r != doorR { ... }
// r은 0..23 사이 값이라 r != -1 은 *항상* true → 모든 r에 벽
```

이게 "sentinel value" 패턴. 특수한 의미를 가진 값을 약속으로 정해 두는 거. Spring 비유 — `userId == -1`이면 "익명 사용자"로 약속하는 것과 같음.

---

## 다음 Phase 미리보기

- 체크보드는 깔렸는데, *normal 맵의 분리벽 위에 음표가 떠 있는 문제*는 의도적으로 다음 sprint로 미뤘어. SpawnSystem의 `randomNotePosition()`이 벽을 피해서 스폰하도록 정밀화해야 함.
- 체크보드 색을 *난이도별로 다르게* 줘서 시각적으로도 난이도가 구분되게 하는 옵션도 고민 중.
