# Sprint 9 Phase B 학습 노트 — 풀바디 2칸 크기 + 5명 정체성 + 픽셀 본체 가리기

## 한 줄 요약

게임 안에서 캐릭터가 너무 크고(화면 1/3 차지), 5명 모두 김간호처럼 보이던 문제를 해결했어요. 캐릭터를 2칸(64pt)으로 줄이고, 5명에게 각자 "표시"를 달아줬어요. 그리고 뒤에 깔려 있던 "픽셀 그림"은 안 보이게 가렸어요.

## 무슨 문제였나

사용자가 게임 화면을 캡처해 보내준 결과:

1. **캐릭터가 너무 큼** — 화면의 1/3을 차지. 원래는 2칸(약 64pt)이어야 함.
2. **정간호를 골라도 김간호처럼 보임** — 5명 모두 같은 몸 path를 공유하고 색만 바꿔서 그려서, 한눈에 누구인지 알 수 없음.
3. **픽셀 그림이 겹쳐 보임** — 풀바디 캐릭터 뒤에 옛날 픽셀 본체(32×40)가 그대로 보여서 모양이 어수선함.

## 어떻게 고쳤나

### 1. 캐릭터를 작게 — path 자체 축소

**비유**: 같은 그림을 *복사기에서 70%로 축소 인쇄*하는 것.

| 부위 | 옛날 | 새로 |
|---|---|---|
| 몸통 | 56×44 | 40×32 |
| 머리 (반지름) | 18 | 12 |
| 머리카락 | 32×10 | 22×7 |
| 모자 | 14×6 | 10×4 |
| 팔 (높이) | 28 | 20 |
| 다리 (높이) | 24 | 18 |

이렇게 path를 작게 그리고, scale도 0.35 → 0.92로 바꿨어요. (path가 작아져서 scale은 거의 1:1로 충분.)

**Spring 비유**: `application.yml`에 `page-size: 20`이라고 적어두면 모든 페이지가 20개씩 나오는 것과 같아요. 우리는 `GameConfig.swift`에 V9 상수를 10개 만들어두고, CharacterFullBodyNode에서 이 값을 참조해서 그렸어요. 숫자를 코드 안에 박지 않고(매직 넘버 금지!) 한 곳에서 관리.

```swift
// GameConfig.swift
static let playerFullBodyBodyWidthV9: CGFloat = 40   // 몸통 폭
static let playerFullBodyHeadRadiusV9: CGFloat = 12  // 머리 반지름
static let playerFullBodyScaleV9: CGFloat = 0.92     // 전체 배율
```

### 2. 5명에게 표시 달기 — Strategy 패턴

**비유**: 5명의 학생이 똑같은 교복을 입었는데, 한 명한테는 안경을, 한 명한테는 야구모자를, 한 명한테는 십자 배지를… 이렇게 *각자의 표시*를 달아줘서 누가 누구인지 구분.

**Spring 비유**: Strategy 패턴이에요. 같은 `buildBody()` 메서드 안에서 캐릭터 ID(`.kim`/`.jung`/`.geon`/`.im`/`.lee`)에 따라 *다른 전략(attach 함수)*을 끼워 넣는 거예요. Spring에서 `@Service`로 등록된 여러 구현체 중에서 조건에 맞는 것을 골라 호출하는 것과 비슷.

```swift
private func attachIdentityMarker(in container: SKNode, direction: Direction) {
    switch id {
    case .kim:  attachKimCrossMark(in: container)        // 빨강 십자
    case .jung: attachJungGlasses(in: container, direction: direction)  // 안경
    case .geon: attachGeonBaseballCap(in: container)     // 야구캡
    case .im:   attachImSidetail(in: container, direction: direction)   // 사이드테일
    case .lee:  attachLeePigtails(in: container)         // 양옆 묶음
    }
}
```

5명의 표시:

| 캐릭터 | 표시 | 어떻게 그렸나 |
|---|---|---|
| 김간호 | 빨강 십자 | 작은 사각형 2개를 십자 모양으로 |
| 정간호 | 둥근 안경 | 타원 2개 + 사이 연결선 1개 |
| 박건오 | 코랄 야구캡 | 둥근 사각형 (모자보다 위에 덧붙임) |
| 임수민 | 사이드테일 | 길쭉한 사각형 (오른쪽으로) |
| 이수민 | 양옆 묶음 | 작은 사각형 2개 (양쪽 머리 옆) |

### 3. 픽셀 본체 가리기 — 투명 색 합성

**비유**: 그림 위에 *투명한 종이*를 겹쳐서 아래 그림이 안 보이게.

`PlayerNode`는 원래 픽셀 텍스처를 그리는 클래스라(SKSpriteNode), 풀바디를 자식으로 붙여도 본체 픽셀이 그대로 보였어요. 

가장 *안전한 방법*은 `color = .clear` + `colorBlendFactor = 1.0`을 set하는 거예요:

```swift
// PlayerNode.swift attachFullBody 끝부분
self.color = .clear
self.colorBlendFactor = 1.0
```

이러면 SpriteKit이 *텍스처를 가리고 투명 색만 합성*해서, 시각적으로는 안 보이게 됨. 그런데 `physicsBody`(충돌 박스)는 색이랑 전혀 상관없으니까, 게임 로직(이동·충돌)은 0줄 영향 받아요.

**왜 `alpha = 0`은 안 되나**: alpha를 0으로 만들면 자식(풀바디)까지 전부 사라져요. 부모-자식 alpha는 곱셈으로 전파되거든요. 그래서 *color 합성*으로만 가려야 해요.

**Spring 비유**: `@JsonIgnore`로 응답 JSON에서 특정 필드만 숨기는 것과 비슷. 객체 자체는 그대로 두고, 클라이언트(여기선 사용자 눈)한테 보일 때만 가리기.

## 어떻게 검증했나

```bash
xcodebuild build  # SUCCEEDED
git diff PlayerNode.swift | grep "physicsBody|velocity"
# (실제 로직 변경 0줄 — 주석 1줄만 매치)
git diff CharacterFaceNode.swift  # 0줄
git diff NurseAvatarNode.swift    # 0줄
git diff EnemyNode.swift          # 0줄
```

## 무엇을 배웠나

1. **path 축소 + scale 보정 조합**: scale만 0.5로 줄이는 것보다, path를 미리 줄여놓고 scale 0.92로 미세조정하는 게 정확도가 높아요. (저해상도 그림을 50% 축소하면 흐릿해지지만, 처음부터 작은 path로 그리면 또렷해요.)

2. **Strategy 패턴 in SpriteKit**: 한 노드 안에서 캐릭터마다 *다른 시각 자식*을 부착할 때, switch + 별도 helper 함수로 분리하면 nested if-else 지옥을 피할 수 있어요. case마다 메서드 1개씩 — 단일 책임 원칙.

3. **switch exhaustive (default 없음)**: `default` 안 쓰는 게 *오히려 안전*이에요. CharacterID에 새 케이스(예: 박병장)가 추가되면 Swift 컴파일러가 *빌드 에러*로 알려줘서, 누락된 attach 메서드를 까먹지 않게 도와줘요. Spring의 `enum`을 `when` 식으로 처리할 때 모든 case 명시하는 것과 같음.

4. **color 합성 vs alpha vs size**:
   - `alpha = 0` → 자식까지 사라짐 (위험)
   - `size = .zero` → 자식 가시 영역 절단 가능 (위험)
   - `color = .clear + colorBlendFactor = 1.0` → 본체만 투명, 자식은 그대로 (안전) ✓

5. **변경 위치 정확히 2곳 약속**: PlayerNode는 게임 로직 핵심 클래스라 거의 *건드리지 말 것*. 이번에는 `setScale` 1줄 교체 + 끝 부분 3줄 추가 = 정확히 2곳. *나머지 모든 라인 0줄 변경*을 git diff로 검증.

## 이번 작업의 핵심 교훈

> **"Path 자체를 작게 그려놓고, scale은 마지막 미세조정용"**

처음에는 path는 그대로 두고 scale 0.5로 줄여볼까 생각했어요. 하지만 그렇게 하면 강한 stroke(테두리)도 같이 가늘어져서 흐릿하게 보여요. path를 미리 작은 좌표로 그리면 *stroke 굵기는 유지*되면서 전체만 작아지니까, 또렷한 캐릭터가 나와요.

> **"동일한 메서드 안에서도 ID별로 다른 자식을 끼워 넣는 = Strategy 패턴"**

`buildBody()` 메서드는 하나지만, 그 끝에서 `attachIdentityMarker()`가 ID별로 다른 helper를 호출. *공통 부분(몸통/머리/팔다리)*은 그대로 두고 *차이 부분(표시)*만 갈아끼우기. 이게 Spring의 인터페이스 + 구현체 분리와 같은 정신이에요.
