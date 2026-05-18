# Phase 8-1 학습 노트 — 픽셀 아트 인프라 + 5캐릭터 일괄 이식

## 오늘 만든 것

지금까지 게임 안에서 *민트색 사각형* 이었던 김간호가 **진짜 픽셀 아트**가 됐어요. 그것도 *원본 웹 게임과 픽셀 단위로 동일*.

```
......HHHH......      ← 번 머리 꼭대기
.....HbbbbH.....      ← 번 본체 (음영)
..HHHHHHHHHHHH..      ← 헤어라인
..SSEESSSSEESS..      ← 눈 동공
..RSSSSMMSSSSR..      ← 볼터치 + 입
....WWWWWWWW....      ← 간호사복
...WWWCCCCWWW...      ← 가슴 십자 표시
....PPPPPPPP....      ← 하의 (파란색)
....BB....BB....      ← 신발
```

위/아래/왼/오른 4방향 회전 + 걷기 애니메이션(idle/step1/step2 교차) 모두 구현. 5명 캐릭터(김/정/건/임/이) 모두 자동 적용.

## "데이터로 그림 그리기"

원본 게임의 천재적인 부분: **그림 파일(PNG) 없이 *문자열 배열*로 픽셀 그림을 정의**.

```javascript
// game.js 원본
const base = [
  '......HHHH......',
  '..SSEESSSSEESS..',
  '....WWWWWWWW....',
  ...
]
```

각 문자가 *색상 코드*:
- `.` = 투명
- `H` = 머리카락 (#3a2a20)
- `S` = 피부 (#fbe0d0)
- `W` = 간호사복 (#ffffff)
- `C` = 가슴 십자 (#c4847a)
- `P` = 하의 (#9ec9e8)
- `B` = 신발 (#a85f56)
- `E`/`L` = 눈/하이라이트

이 데이터를 *그대로* Swift에 옮겼어요. 문자 하나도 안 바꾸고. 즉 *원본과 픽셀 단위로 100% 동일*.

**Spring 비유** — `application.yml`이 *설정 데이터*인 것처럼, 픽셀 그림도 *데이터*로 표현 가능. *데이터 우선 사고*. 일단 데이터로 만들면 *재사용*과 *변경*이 쉬워요.

## 5캐릭터의 "베이스 + 오버레이" 구조

5명이 *완전히 다른 그림*은 아니에요. 모두 *간호사복 입은 사람*인데 *머리·소품*만 달라요:
- **kim**: 번머리 (기본)
- **jung**: 짧은 머리 + 곡괭이 (근육질)
- **geon**: 안경 + 책
- **im**: 긴 머리 + 고양이귀
- **lee**: 단발 + 강아지귀

원본 게임은 영리하게 *base를 만들고 그 위에 오버레이*하는 방식이에요:

```swift
private static func applyOverlay(_ base: inout Frame,
                                  for characterID: CharacterID,
                                  direction: PixelDirection) {
    switch characterID {
    case .kim: break  // 기본 그대로
    case .jung: applyJungOverlay(&base, direction: direction)
    case .geon: applyGeonOverlay(&base, direction: direction)
    case .im:   applyImOverlay(&base, direction: direction)
    case .lee:  applyLeeOverlay(&base, direction: direction)
    }
}
```

각 오버레이는 *base의 특정 행을 자기 색으로 덮어씀*. 예를 들어 jung은:
```swift
base[2] = "....JJJJJJJJ...."   // 짧은머리 본체
base[10] = String(base[10].prefix(14)) + "KK"  // 곡괭이 헤드
```

base 행 10의 *오른쪽 끝 2픽셀*만 곡괭이로 덮어쓰는 거예요. 머리·곡괭이만 다르고 *얼굴, 옷, 신발은 공통*.

**Spring 비유** — `@Override` + `@SuperBuilder`. 부모 클래스의 기본을 깔고 자식이 *일부*만 재정의. *상속이 아닌 합성*에 가깝지만 발상은 같음.

## "JavaScript → Swift" 문자열 처리 함정

JavaScript의 `substring(0, 14)`는 *0번부터 13번까지 14개 문자*. Swift의 `prefix(14)`도 같지만 *반환 타입이 `Substring`* 이라 `String(...)`으로 한 번 더 감싸야 해요.

```javascript
// JavaScript
base[10] = base[10].substring(0, 14) + 'KK';
```

```swift
// Swift
base[10] = String(base[10].prefix(14)) + "KK"
```

또 chain replace는:
```javascript
'II..WWWWWWWW..II'.replace('II..', 'iI..').replace('..II', '..Ii')
```
```swift
"II..WWWWWWWW..II"
    .replacingOccurrences(of: "II..", with: "iI..")
    .replacingOccurrences(of: "..II", with: "..Ii")
```

**Spring 비유** — Kotlin `replace().replace()` 체이닝과 동일. *문자열 API 이름만 다르고 의미는 같음*. Cross-language 함수형 문자열 처리는 거의 표준화됐어요.

## "데이터 → 텍스처" 변환 — UIGraphicsImageRenderer

문자열 배열을 화면에 어떻게 그릴까요? 두 방법:

1. **각 픽셀별 SKSpriteNode 320개 만들기** — 16×20 = 320개 노드. 캐릭터 1명에 320개 × 5명 × 4방향 × 3프레임 = 19,200개. *너무 많음*. 성능 죽음.

2. **`UIGraphicsImageRenderer`로 16×20 UIImage 그린 후 SKTexture로 감싸기** — *1개 SKTexture* 만 만들고 *교체* 만 함. 성능 좋음.

채택은 2번:

```swift
static func texture(from sprite: PixelSprite.Frame,
                    palette: [Character: UIColor]) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 20))
    let image = renderer.image { ctx in
        for (row, line) in sprite.enumerated() {
            for (col, char) in line.enumerated() {
                guard let color = palette[char] else { continue }
                color.setFill()
                ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
            }
        }
    }
    let texture = SKTexture(image: image)
    texture.filteringMode = .nearest   // 픽셀 perfect
    return texture
}
```

핵심: **`filteringMode = .nearest`**. 기본값(`.linear`)은 픽셀이 *번지는* 효과로 부드럽게 만들어요. 픽셀 아트는 *날카로워야* 멋있으니까 `.nearest`로 강제.

**Spring 비유** — `@CacheEvict` 없이 *데이터를 매번 재생성* 하는 패턴. 단, 재생성 빈도가 *높지 않으면* OK. 우리는 *방향 변경 시* 또는 *0.18초마다 step 교차* 만 재생성.

## "수동 vs 자동 애니메이션"

SpriteKit에는 `SKAction.animate(withTextures:timePerFrame:)`로 *자동 텍스처 교체* 기능이 있어요. 그런데 우리는 *수동*으로 가요. 왜?

- **자동**: 무한 루프로 step1↔step2 교차. 정지해도 계속 걸어가는 척.
- **수동**: 매 update에서 velocity 확인 → 정지면 idle, 움직이면 step1↔step2 교차.

수동이 *게임 로직*과 맞아요. 우리는 *정지 시 idle* 이 자연스러운 동작이라.

```swift
func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) {
    guard isMoving else {
        if pixelFrame != .idle {
            pixelFrame = .idle
            refreshTexture()   // 정지 시 idle로 즉시 전환
        }
        return
    }
    frameAccumulator += deltaTime
    if frameAccumulator >= GameConfig.pixelWalkFrameInterval {
        frameAccumulator = 0
        pixelFrame = (pixelFrame == .step1) ? .step2 : .step1
        refreshTexture()
    }
}
```

**Spring 비유** — `@Scheduled(fixedDelay)` 자동 vs 수동 *Polling*. *상태에 따라 다른 동작*이 필요하면 수동이 낫고, 항상 같은 동작이면 자동이 편함.

## 회귀 0의 마법 — 게임 로직은 0건 변경

이번 sprint에서 가장 중요한 건 *게임이 안 깨졌다*는 거예요. 픽셀 아트 도입으로 게임 동작이 *전혀* 영향 안 받았어요.

- `physicsBody` 크기 16×20 *그대로*
- `collisionBitMask` *그대로*
- `velocity` 적용 *그대로*
- 점수/콤보/F 투사체/충돌 *전부 동일*

PlayerNode가 시각적으로만 *32×40 픽셀 아트*(scale 2배)로 보이고 *충돌은 16×20 hitbox 그대로*. 시각과 게임플레이의 *분리*.

**Spring 비유** — *DTO vs Entity* 분리. *사용자에게 보이는 것*과 *데이터베이스가 저장하는 것*이 달라도 됨. 시각(DTO)과 게임 로직(Entity)도 같은 발상.

회귀 0 검증: 18개 path 모두 git diff *0줄*. EnemyNode/StoneGuard/HUD/시스템·매니저·리포지토리·모델 전부 미접촉.

## 오늘의 한 줄

> *"원본 게임의 *문자열 픽셀 그림 90행* 과 *27개 색상 hex* 를 byte-equal로 옮기되, 게임 로직은 한 줄도 안 건드린다 — 시각과 동작의 완벽한 분리."*
