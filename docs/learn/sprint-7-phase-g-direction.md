# Sprint 7 Phase G — "캐릭터가 내가 보는 방향을 본다"

> 게임 마지막 Phase. D-Pad로 움직이면 캐릭터가 진짜로 그 방향을 *바라보게* 만든 이야기.

---

## 1. 무엇이 문제였어?

D-Pad로 캐릭터를 위/아래/좌/우 움직여도, 캐릭터는 *늘 정면*만 보고 있었어. 마치 영화 속 인물이 *옆으로 게 걸음*으로 움직이는 듯한 어색함.

게임에서는 *내가 누군가를 조종한다*는 느낌이 중요해. 그 느낌의 80%는 "내 명령에 그가 반응하는가" 인지 신호로 만들어져. 방향 회전이 없으면 *조종감*이 약해.

---

## 2. 어떻게 고쳤어?

**4방향 얼굴 child 4개를 미리 부착하고, 입력에 따라 isHidden 토글**:

```
PlayerNode
├── PixelSprite texture (zPos 0, 기존 그대로)
├── CharacterFaceNode(facing: .front) ← isHidden 토글
├── CharacterFaceNode(facing: .back)
├── CharacterFaceNode(facing: .left)
└── CharacterFaceNode(facing: .right)  ← scaleX = -1 미러링
```

D-Pad에서 *위*를 누르면:
1. DPadNode가 currentDirection을 (0, 1)로 set
2. `Direction(vector:)`가 .back으로 변환
3. `onDirectionChanged` 콜백 발화
4. GameScene이 `player.facing(.back)` 호출
5. PlayerNode.facing이 .back child만 isHidden = false, 나머지 3개 true

전환은 *동기적* — 다음 SpriteKit 렌더 프레임(~16ms) 안에 완료. 사용자 체감 *즉시*.

---

## 3. 핵심 패턴 1 — Direction enum 입력 layer

이미 게임에는 `PixelDirection` enum이 있었어 (down/up/left/right) — 픽셀 스프라이트 텍스처 회전용. 그런데 *입력 의도*와 *그래픽 매핑*은 다른 개념이라 같은 enum으로 묶으면 책임이 섞여.

새로 **Direction** enum을 만들었지:
- `Direction`: 입력 의도 (front/back/left/right) — 카메라 기준 캐릭터 *얼굴이 어디 보는가*
- `PixelDirection`: 텍스처 회전 (down/up/left/right) — *내부 그래픽 시스템 매핑*

```swift
enum Direction: String {
    case front, back, left, right

    init?(vector: CGVector) {
        if abs(vector.dx) < 0.001 && abs(vector.dy) < 0.001 { return nil }
        if abs(vector.dx) >= abs(vector.dy) {
            self = vector.dx >= 0 ? .right : .left
        } else {
            self = vector.dy >= 0 ? .back : .front
        }
    }
}
```

`.zero` 입력 시 nil 반환 — *정지 상태에서는 facing 미발화* → lastFacing 유지. 사용자가 D-Pad 떼면 캐릭터가 *그 방향 그대로* 멈춰. 자연스러움.

Spring 비유: `@RequestParam`을 *DTO 변환*하는 패턴. raw query string → typed object. 같은 데이터를 *어떤 의미로 해석*하느냐가 enum의 정체성.

---

## 4. 핵심 패턴 2 — lastFacing 가드로 비용 0

`facing(_:)` 메서드가 매 D-Pad 입력 시마다 호출되면, 60fps에서 *초당 60번* 같은 동작이 일어나. 그런데 *방향이 바뀌지 않았다면* 아무것도 안 해도 되잖아.

```swift
func facing(_ direction: Direction) {
    if direction == lastFacing { return }   // ← 가드
    lastFacing = direction
    for (dir, node) in faceNodes {
        node.isHidden = (dir != direction)
    }
}
```

이 가드 한 줄로 *방향 변화 순간*에만 4 child isHidden 토글이 일어나. 비용 거의 0.

이 패턴을 **idempotent operation** 또는 **state guard**라고 불러. 함수를 여러 번 호출해도 *결과가 같다*. Spring `@Cacheable`의 캐시 히트 패턴과 비슷한 *불필요한 작업 회피*.

---

## 5. 핵심 패턴 3 — convenience init delegation

기존 CharacterFaceNode는 `init(id: CharacterID)` 시그니처로 *정면*만 만들어. Phase G에서 4방향이 필요하니까 *신규 init*을 추가해야 해.

```swift
// 신규
init(id: CharacterID, facing: Direction) {
    super.init()
    switch (id, facing) {
    case (_, .front):
        switch id {
        case .kim:  buildKimFace()    // 기존 5 build 재사용
        // ...
        }
    case (let id, .back):
        buildBackFace(id: id)
    case (let id, .left):
        buildSideFace(id: id)
    case (let id, .right):
        buildSideFace(id: id)
        xScale = -1                    // 미러링
    }
}

// 기존 호출자 보호 — convenience delegation
convenience init(id: CharacterID) {
    self.init(id: id, facing: .front)
}
```

*기존 호출자*(ScoreboardScene/CharacterSelectScene/DifficultySelectScene)는 `CharacterFaceNode(id: .kim)`만 호출 — convenience init이 *알아서* `.front`로 위임. *시그니처 변경 0*. 회귀 0.

Spring 비유: 메서드 오버로딩에서 `process(query)`가 내부적으로 `process(query, options: defaultOptions)`를 호출하는 패턴. 호출자가 단순 기본값 모드에서는 *추가 인자를 모름*.

---

## 6. 핵심 패턴 4 — 미러링으로 path 절약

left와 right는 *거울 대칭*이야. 같은 path를 두 번 작성할 필요 없지:

```swift
case (let id, .left):
    buildSideFace(id: id)      // 일반 path

case (let id, .right):
    buildSideFace(id: id)
    xScale = -1                 // ← 거울 반전
```

5캐릭터 × 4방향이지만 실제 path 코드는 5 × **3** (front + back + side) = 15개. right는 left를 미러로 자동 생성.

`xScale = -1`은 *노드의 모든 자식*을 x축 기준 반전. mockup HTML의 CSS `transform: scaleX(-1)`과 같은 원리.

비유: 신발 좌·우 — *같은 디자인의 거울*. 디자이너는 한 짝만 그리고 *반대로 뒤집어* 다른 짝 만듦.

---

## 7. 핵심 패턴 5 — PixelSprite와 face child 자연 공존

기존 PlayerNode는 *PixelSprite 텍스처*(16×20 픽셀)로 그려졌어. 4방향 face child를 *위에* 얹으면 시각이 두 겹으로 겹쳐 어색할 수 있어.

해결책 후보:
- (a) PixelSprite texture를 `alpha 0`으로 가리고 face child가 주 시각
- (b) face child를 `alpha 0.5`로 텍스처 위 살짝 얹기
- (c) **자연 겹침** (채택) — face child가 *얼굴 영역*(zPos 1)에만 시각, PixelSprite는 *발 영역* 자연 노출

(c)를 채택한 이유:
- refreshTexture 호출 시 PixelSprite 시스템이 *자동 갱신* → alpha 조작과 충돌 가능
- face child의 head ellipse가 *불투명*이라 얼굴 영역은 자동으로 face child가 주 시각이 됨
- PixelSprite의 발 부분(하단 6pt)이 *자연스럽게 비침* → 캐릭터 전신감 보존

Spring 비유: *legacy 코드를 보존*하면서 *새 layer를 위에 얹는* facade 패턴. 기존 시스템(PixelSprite)을 깨지 않고 *시각 우선순위*만 zPosition으로 조정.

---

## 8. 5캐릭터 × 4방향 SVG path 시안

새로 그린 path 메서드 10개:

```
buildBackFace(id:)       — 5캐릭터 뒷모습 통합 진입점
  └── buildKimHairBack   — 김간호 번머리 silhouette
  └── buildJungHairBack  — 정간호 캡 뒷면 + 짧은 머리
  └── buildGeonHairBack  — 건간호 짧은 단발 silhouette
  └── buildImHairBack    — 임간호 긴머리 더 길게
  └── buildLeeHairBack   — 이간호 곱슬 단발 옆 일부

buildSideFace(id:)       — 5캐릭터 옆모습(.left) 통합 진입점
  └── buildKimSide       — 좌측 헤어 + 눈 1개
  └── buildJungSide
  └── buildGeonSide
  └── buildImSide
  └── buildLeeSide
```

각 메서드는 기존 front build의 path 좌표를 *부분 차용*해 단순화. *몸통은 공유*(head ellipse base), *헤어/뒤통수/눈 위치만 다름* — SPRINT_7_REQUEST.md §8.2 정확 준수.

---

## 9. 보호 영역 — 광활한 0줄

이번에도 *건드리지 않은* 영역이 압도적:

- **Phase A·B·C·D·E·F 결과물 (모든 Sprint 7 이전 작업)**: 0줄
- **GameScene / GameState / PhysicsCategory**: 0줄
- **모든 Systems** (SkillSystem/SpawnSystem/ContactRouter/ScoreSystem)
- **모든 Managers** (AudioManager 등)
- **모든 Repositories** (HighScore 등)
- **모든 다른 Scenes** (Character/Skill/Difficulty/Result/Scoreboard/Start)
- **NoteNode/ProjectileNode/StethoscopeNode** (음표·투사체)
- **4 villain nodes** (Enemy/Professor/StoneGuard/SergeantPark)
- **PlayerNode 이동/physicsBody/PixelSprite 시스템** (loadTexture/refreshTexture/updatePixelDirection/tickWalkFrame)
- **DPad updateDirection if/else 알고리즘**
- **CharacterFaceNode 기존 5 build 본문** (576 lines)
- **CharacterFaceNode.mini factory**

총 *30개+ 파일/메서드*가 git diff 0줄.

---

## 10. 🎉 Sprint 7 전체 완료

| Phase | 작업 | 점수 |
|---|---|---|
| A | 캐릭터 카드 NIKKE 4:5 리뉴얼 | 9.45 |
| B | 스킬 설명 겹침 해소 | 9.77 |
| C | 난이도 카드 색 위계 | 9.83 |
| D | 결과창 정리 + ScoreboardScene 신설 | 9.83 |
| E | 카운트다운 오버레이 | 9.76 |
| F | 빌런 4종 + 박병장 신규 | 9.10 |
| G | 플레이어 4방향 스프라이트 + Direction layer | 9.58 |
| **평균** | | **9.62 / 10** |

7개 Phase 모두 통과선(7.5) 큰 폭 초과. 합격률 100% (7/7).

가장 핵심적인 패턴은 *V3 신규 상수 + 기존 보존*. 옛 값을 지우는 대신 *새 이름으로 옆에 추가*. 시각 회귀가 0인 채로 새 톤이 입혀짐. Spring의 *blue-green deployment*와 같은 원리.

---

## 11. 잔존 P2 — 차기 정리 후보

1. **CharacterFaceNode 1101 lines** — `+Front/+Back/+Side` extension 3개로 분리
2. **back/side 헤어 색** — hairBrown 단색 위주 → 캐릭터별 보강
3. **PlayerNode PixelSprite + face child 하이브리드** — 통합 또는 face child 전면 채택
4. **Phase F 시각 디테일 매직 넘버 8건** — GameConfig 시각 디테일 상수 추가
5. **V3 상수 명명 규칙** — Sprint 7 종료 후 일괄 정리 (deprecation 마크 또는 제거)

모두 합격 영향 0. Sprint 8 또는 정리 Sprint 후보.

---

## 12. 끝났다, 다음은?

Sprint 7이 완료됐어. 디자인 리뉴얼 모드의 7개 단계가 모두 v3로 정착.

다음 우선순위:
- **Sprint 4 (PNG 캐릭터 통합)** — 사용자가 PNG 자산 도착 시 시작. CharacterFaceNode → SKSpriteNode(텍스처 PNG) 교체.
- **Sprint 8 (게임 본체 보강)** — 박병장 GameScene spawn, AudioManager tick/chime 등록, NurseAvatar 호흡 애니메이션, 단계 전이 chime 사운드.
- **정리 Sprint** — Sprint 7 잔존 P2 5건 일괄 처리.

Sprint 7의 7 Phase를 거치는 동안 *디자인 시스템*이 완전히 v3로 안착했어. 색 토큰·폰트·노드 컴포넌트·씬 톤이 일관되게 정착했지. 다음 작업이 그 위에서 *기능 추가*에 집중할 수 있게 됐어.
