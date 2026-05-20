# Sprint 7 Phase F — "4명의 적, 누가 누군지 5초 안에"

> 게임에 등장하는 빌런 3명을 *식별하기 쉽게* 정비하고, 신규 빌런 박병장(공군 + 선글라스)의 시각 시안을 미리 만든 이야기.

---

## 1. 무엇이 문제였어?

게임 중 빌런이 화면에 나타나도 *누가 누군지* 한눈에 안 보였어:

- **수간호사**: 흰 가운만 보이고 권위자다움이 약해
- **이교수**: 청진기 휘두르는 교수인데 *청진기 액세서리*가 시각상 없어
- **석조무사**: 단순한 회색 박스 — 어떤 적인지 모름

그리고 사용자가 새 빌런 *박병장*(공군 + 선글라스)을 시리즈에 추가하고 싶어해.

---

## 2. 어떻게 고쳤어?

**각 빌런에 *식별 시그널* 자식 노드를 부착**:

| 빌런 | 추가한 시각 자식 |
|---|---|
| **수간호사 (EnemyNode)** | 외곽 헬로(navyMuted 0.18) + 차트(paper) + 클립(coral) |
| **이교수 (ProfessorNode)** | 청진기 mini disc(coral) + 튜브 |
| **석조무사 (StoneGuardNode)** | 회색 갑옷 SKShape + 일자눈 2개 + 본체 color 변경 |
| **박병장 (SergeantParkNode 신규)** | 청록 군복 + 항공 캡 + 검은 선글라스 + 골드 v자 계급장 2개 |

핵심: **AI/이동/충돌 코드는 0줄도 안 건드림**. 시각 자식만 추가. 게임 플레이는 *그대로*.

---

## 3. 핵심 패턴 1 — "텍스처 위에 자식 SKShape 부착"

기존 빌런 3종은 *픽셀 텍스처*(16×20 픽셀 데이터 → SKTexture)로 그려져 있었어. 이걸 *교체*하면 회귀 위험이 커.

대신 **텍스처 위에 자식 SKShapeNode를 살짝 얹는** 방식을 썼지. 마치 캐릭터 일러스트 위에 *스티커 한 장 더* 붙이는 느낌.

```swift
// EnemyNode init 안
private func setupVisualOverlay() {
    let halo = SKShapeNode(rectOf: ...)  // 외곽 헬로
    halo.zPosition = -0.1  // 텍스처 *뒤*
    addChild(halo)

    let chart = SKShapeNode(rectOf: ...)  // 차트
    chart.zPosition = 0.1   // 텍스처 *위*
    addChild(chart)
}
```

zPosition을 `-0.1, 0.1, 0.2`처럼 *작은 상대값*으로 두면 픽셀 텍스처(zPos 0) 앞·뒤에 정확히 끼워 넣을 수 있어. 큰 양수(예: 100)는 안 됨 — 다른 게임 노드 트리(HUD 100 등)와 충돌.

Spring 비유: 기존 `@Controller`에 새 `@RequestMapping`을 *추가*하는 것 vs 기존 메서드를 *재작성*하는 것. 전자가 회귀 안전.

---

## 4. 핵심 패턴 2 — StoneGuard color 값만 교체

석조무사는 픽셀 텍스처가 *없고* 단순한 회색 박스였어. 그래서 `super.init(texture: nil, color: .ganhoPaper, ...)` 호출 — color 인자 *값*만 갈아끼웠지:

```swift
// 변경 전
super.init(texture: nil, color: .ganhoPaper, size: size)

// 변경 후 (Sprint 7 Phase F)
super.init(texture: nil, color: .ganhoStoneGuardLight, size: size)
```

*시그니처는 byte-identical*. 시각만 회색 톤으로 명확해짐. 그 위에 갑옷 SKShape + 일자눈 SKShape 부착.

비유: 옷의 *색깔만* 바꾸는 게 아니라 *라벨 텍스트*는 그대로 두는 패턴. 데이터 마이그레이션 같은 어려운 작업이 아님.

---

## 5. 핵심 패턴 3 — 신규 SergeantParkNode "시각 시안만"

박병장은 *완전히 새* 빌런 노드. 그런데 *게임 등장은 0건* — 이번 Sprint에서는 시각 시안만 만들고, 다음 Sprint 8에서 GameScene에 spawn 추가 예정.

```swift
final class SergeantParkNode: SKSpriteNode {
    init() {
        super.init(texture: nil, color: .clear, size: visualSize)
        // physicsBody 부착 0건
        // SKAction 시퀀스 0건
        // update 메서드 0건
        attachShadow()       // 발 밑 ellipse
        attachBody()         // 청록 군복
        attachHead()         // 살구색 얼굴
        attachCap()          // 항공 캡
        attachSunglasses()   // 검은 선글라스
        attachRank()         // 골드 v자 2개
    }
}
```

6개 attach 메서드로 신체 구성 요소를 분리. 각 메서드는 *단일 책임* — head 그리기, cap 그리기, ...

이 패턴의 장점:
- 다음 Sprint 8에서 physicsBody 추가할 때 *시각은 그대로*. AI 코드만 별도 메서드(`startPatrol()` 등)로 추가.
- 다른 빌런(EnemyNode 등)과 *구조 일관* — 학습 비용 0.

Spring 비유: `@Component`를 만들지만 `@Service`/`@Repository` 의존성 주입 없이 *순수 데이터 객체*로만 등록. 비즈니스 로직은 나중에 추가.

---

## 6. v자 계급장 만들기

박병장의 *공군 병장 계급장*은 골드 v자 2개. SpriteKit의 `SKShapeNode`로 어떻게 v자를?

`UIBezierPath`로 *세 점을 잇는* 경로 → cgPath 변환 → SKShapeNode:

```swift
private func makeChevronNode() -> SKShapeNode {
    let path = UIBezierPath()
    let w = GameConfig.sergeantChevronWidth   // 5
    let h = GameConfig.sergeantChevronHeight  // 2.5
    path.move(to: CGPoint(x: -w/2, y: 0))    // 왼쪽 위
    path.addLine(to: CGPoint(x: 0, y: -h))   // 가운데 아래
    path.addLine(to: CGPoint(x: w/2, y: 0))  // 오른쪽 위
    let shape = SKShapeNode(path: path.cgPath)
    shape.strokeColor = .ganhoMusicGold
    shape.lineWidth = 1.0
    shape.fillColor = .clear   // 윤곽선만 — fill 없음
    return shape
}
```

`fillColor = .clear`로 *윤곽선*만 그려. v자는 *닫힌* 도형이 아니라 *3점 stroke*. 마치 영문 V를 손으로 그린 느낌.

2개의 chevron은 세로로 나란히 배치(`y offset`이 점점 위로) → 병장 계급 표현.

---

## 7. 보호 영역 — 광활한 0줄

이번에도 손대지 않은 파일이 많아:

- **GameScene / GameScene+Setup** (게임 메인 씬)
- **PhysicsCategory** (충돌 비트마스크)
- **모든 Models** (GameState 등)
- **모든 Systems** (SkillSystem/SpawnSystem/ContactRouter/ScoreSystem)
- **모든 Repositories** (HighScore 등)
- **모든 Managers** (AudioManager 등)
- **PlayerNode/NoteNode/ProjectileNode/StethoscopeNode** (플레이어 측 4개)
- **Phase A·B·C·D·E 결과물 일체**

총 *20개+ 파일*이 git diff 0줄. 시각 부착만 추가하고 *주변을 깨끗하게 보존*.

---

## 8. 잔존 P1/P2 — 차후 정리 후보

### P1: 시각 디테일 매직 넘버 8건

코드에 `cornerRadius: 0.6`, `lineWidth: 0.5` 같은 *직접 숫자*가 8군데 남아 있어. 평소엔 *GameConfig 상수로 외화*하는 게 원칙이지만, *시각 디테일*(스트로크 굵기·모서리 둥글기)이라 SPEC에서 묵시적 허용 영역이라 P0가 아닌 P1.

Phase G 시작 시 `enemyVisualChartCornerRadius`, `stoneGuardArmorCornerRadius`, `sergeantBodyCornerRadius` 등 *시각 디테일 상수* 7~10개 추가하면 깔끔히 해소.

### P2: StoneGuard eyeSize 토큰화

`let eyeSize = CGSize(width: 2, height: 0.8)` 한 줄도 GameConfig로. 0초 작업.

두 항목 모두 *합격 영향 0*. 시각 회귀 위험 없음.

---

## 9. 다음(Phase G)은 뭐야?

**플레이어 5명 4방향 스프라이트.**

현재 PlayerNode는 *정면 한 방향*만 렌더링. D-pad로 위·아래·왼쪽·오른쪽 움직여도 *얼굴이 정면*이라 어색해.

Phase G에서:
- 5명 캐릭터 각각 4방향(front/back/left/right) SVG path 시안 → SKShapeNode child 4종 미리 부착
- DPadNode가 방향 입력을 PlayerNode에 전달할 때 `PlayerNode.facing(_ direction: Direction)` 호출
- 방향별 차이는 *머리 회전 + 헤어 흐름 + 청진기/뱃지 위치*만 다르게 (몸통 공유)
- left/right는 mirroring(scaleX = -1)로 한 쪽만 작성

`Direction` enum 신규:
```swift
enum Direction: String {
    case front, back, left, right
}
```

이동 로직(velocity·position 계산)과 hitbox는 *0건* 건드림. 방향 변환은 *추가 layer*일 뿐.

변경 LOC ~300 예상. Phase F 다음 마지막 단계.
