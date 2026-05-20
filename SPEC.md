# Sprint 7 Phase F — 빌런 4종 시각 리뉴얼 + 박병장 신규

## 개요
수간호사(EnemyNode) · 이교수(ProfessorNode) · 석조무사(StoneGuardNode) 3종 빌런 시각만 강화하여 **5초 안에 누가 누군지 즉시 식별** 가능하게. 동시에 신규 빌런 **박병장(SergeantParkNode — 공군 청록 군복 + 항공 캡 + 검은 선글라스 + 골드 v자 계급장)** 노드 클래스 작성(시각 시안만, GameScene 등장 0건). **AI · 이동 · 충돌 · hitbox 코드는 0줄 손대지 않는다.**

## 변경 유형
**비주얼 + 신규 노드 클래스 1개** (시각 자식 SKShapeNode 추가, physicsBody·AI 0줄)

## 게임 경험 의도
- 빌런 4명이 시각 단서(차트/청진기/돌 갑옷/선글라스)만으로 즉시 판독
- 박병장은 게임 등장 0건이지만 *공군 병장 + 선글라스* 정체성 시각 시안 준비
- 4명 컨셉이 톤(권위자/교수/돌상/군인)과 색(navyDeep/코랄/회색/공군 청록)으로 충돌 0 식별

## Sprint 7 Phase F 범위 계약

### 허용
- EnemyNode/ProfessorNode/StoneGuardNode 시각 부착 코드만 갱신 (자식 SKShapeNode 추가)
- 신규 `Nodes/SergeantParkNode.swift` (시각 시안 전용)
- ColorTokens 박병장 3 + 석조무사 3 = 6 토큰 신규
- GameConfig Phase F V3 상수 ~22개
- 신규 `mockups/villains-and-player-directions-v1.html` 전반부 (4명 빌런 패널, 후반부 5명 4방향은 Phase G)

### 금지 (0줄)
- EnemyNode/ProfessorNode/StoneGuardNode AI/이동/충돌 로직 (update/startPatrol/startThrowingStethoscopes/startFleeing/apply/stopThrowing 시그니처+본문)
- physicsBody.size / categoryBitMask / collisionBitMask / contactTestBitMask
- 속도·waypoint 상수 (baseSpeedStart/End, professorSpeed, stoneGuardSpeed, waypoints)
- PhysicsCategory 비트마스크 추가/수정
- GameScene setupEnemy/setupStoneGuard/setupProfessor/addNormalMap/addHardMap 호출
- SergeantParkNode 게임 spawn (Sprint 8 후보)
- Phase A·B·C·D·E 결과물
- GameState/Managers/Repositories/Systems/SkillSystem/ScoreSystem/ContactRouter/SpawnSystem
- PlayerNode/NoteNode/ProjectileNode/StethoscopeNode (Phase G에서 PlayerNode 별도)

### 판단 기준
- "이 변경이 EnemyNode hitbox/AI/이동을 바꾸는가?" → YES면 금지
- "SergeantParkNode를 게임에 spawn시키는가?" → YES면 금지
- "시각 자식 노드 path/color/zPosition만 건드리는가?" → YES면 허용

## 변경 범위

### 수정 파일
- `Nodes/EnemyNode.swift` — setupVisualOverlay 신규 (외곽 헬로 + 차트 + 클립)
- `Nodes/ProfessorNode.swift` — setupVisualOverlay 신규 (청진기 mini disc + 튜브)
- `Nodes/StoneGuardNode.swift` — setupVisualOverlay 신규 + super.init color 변경(.ganhoPaper → .ganhoStoneGuardLight)
- `Config/ColorTokens.swift` — Phase F 6 토큰 추가
- `Config/GameConfig.swift` — Phase F V3 상수 ~22개

### 추가 파일
- `Nodes/SergeantParkNode.swift` — 신규 ~150 LOC, SKSpriteNode(.clear) 상속 + 6 attach 메서드
- `mockups/villains-and-player-directions-v1.html` — 전반부 4 패널 (Phase G에서 후반부 추가)

## 기능 상세

### 기능 1: EnemyNode 시각 보강 (수간호사)
- 외곽 헬로 SKShape(navyMuted alpha 0.18, zPos -0.1)
- 차트 SKShape(paper fill, navyDeep stroke, 우측 옆구리)
- 클립 SKShape(coralPrimary, 차트 위)
- `setupVisualOverlay()` 호출은 init 마지막 `zPosition = 5` 직후 1줄

### 기능 2: ProfessorNode 시각 보강 (이교수)
- 청진기 mini disc SKShape(coralPrimary, coralShadow stroke, 좌측 옆구리)
- 청진기 튜브 SKShape(coralLight, disc 위)
- `setupVisualOverlay()` 호출은 init `startPatrol()` 직전 1줄
- **StethoscopeNode 투사체와 완전 무관 — 액세서리 시각만**

### 기능 3: StoneGuardNode 시각 보강 (석조무사)
- super.init color: `.ganhoPaper` → `.ganhoStoneGuardLight` (값 변경만, 시그니처 byte-identical)
- 사각 갑옷 SKShape(stoneGuardDark fill, stoneGuardOutline stroke 0.8)
- 일자눈 2개 SKShape(navyDeep, rectOf 2×0.8, 좌우 대칭)
- `setupVisualOverlay()` 호출은 init `startPatrol()` 직전 1줄
- **physicsBody.size 인자 변경 0 — GameConfig.stoneGuardWidth/Height 그대로**

### 기능 4: SergeantParkNode 신규 (박병장)
- SKSpriteNode(.clear) 상속 (기존 빌런 3종 패턴 일관)
- 6 attach 메서드:
  - `attachShadow()` — 발 밑 ellipse, zPos -0.1
  - `attachBody()` — 청록 군복 rect, zPos 0.1
  - `attachHead()` — 살구색 circle, zPos 0.2
  - `attachCap()` — 청록 crown + 검정 visor, zPos 0.3/0.35
  - `attachSunglasses()` — 검정 rect, zPos 0.4 (얼굴 위)
  - `attachRank()` — 골드 v자 2개 chevron path, zPos 0.25
- **physicsBody/AI/SKAction/update 0건**

```swift
final class SergeantParkNode: SKSpriteNode {
    init() {
        let visualSize = CGSize(
            width:  GameConfig.sergeantParkWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.sergeantParkHeight * GameConfig.pixelSpriteScale)
        super.init(texture: nil, color: .clear, size: visualSize)
        name = "sergeantPark"
        zPosition = 5
        attachShadow(); attachBody(); attachHead(); attachCap(); attachSunglasses(); attachRank()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func attachShadow() {
        let shadow = SKShapeNode(ellipseOf: GameConfig.sergeantShadowSize)
        shadow.fillColor = .black.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: GameConfig.sergeantShadowOffsetY)
        shadow.zPosition = -0.1
        addChild(shadow)
    }

    private func attachBody() {
        let body = SKShapeNode(rectOf: GameConfig.sergeantBodySize, cornerRadius: 1.5)
        body.fillColor = .ganhoAirforceTeal
        body.strokeColor = .ganhoAirforceTealLight
        body.lineWidth = 0.6
        body.position = CGPoint(x: 0, y: GameConfig.sergeantBodyOffsetY)
        body.zPosition = 0.1
        addChild(body)
    }

    private func attachHead() {
        let head = SKShapeNode(circleOfRadius: GameConfig.sergeantHeadRadius)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = .ganhoCoralShadow
        head.lineWidth = 0.4
        head.position = CGPoint(x: 0, y: GameConfig.sergeantHeadOffsetY)
        head.zPosition = 0.2
        addChild(head)
    }

    private func attachCap() {
        let crown = SKShapeNode(rectOf: GameConfig.sergeantCapCrownSize, cornerRadius: 1.5)
        crown.fillColor = .ganhoAirforceTeal
        crown.strokeColor = .ganhoAirforceTealLight
        crown.lineWidth = 0.5
        crown.position = CGPoint(x: 0, y: GameConfig.sergeantCapCrownOffsetY)
        crown.zPosition = 0.3
        addChild(crown)

        let visor = SKShapeNode(rectOf: GameConfig.sergeantCapVisorSize)
        visor.fillColor = .ganhoSunglassesBlack
        visor.strokeColor = .clear
        visor.position = CGPoint(x: 0, y: GameConfig.sergeantCapVisorOffsetY)
        visor.zPosition = 0.35
        addChild(visor)
    }

    private func attachSunglasses() {
        let glasses = SKShapeNode(rectOf: GameConfig.sergeantSunglassesSize, cornerRadius: 0.6)
        glasses.fillColor = .ganhoSunglassesBlack
        glasses.strokeColor = .ganhoNavyDeep
        glasses.lineWidth = 0.4
        glasses.position = CGPoint(x: 0, y: GameConfig.sergeantSunglassesOffsetY)
        glasses.zPosition = 0.4
        addChild(glasses)
    }

    private func attachRank() {
        for index in 0..<GameConfig.sergeantRankChevronCount {
            let chevron = makeChevronNode()
            chevron.position = CGPoint(
                x: GameConfig.sergeantRankOffsetX,
                y: GameConfig.sergeantRankOffsetY
                    + CGFloat(index) * GameConfig.sergeantRankChevronGap)
            chevron.zPosition = 0.25
            addChild(chevron)
        }
    }

    private func makeChevronNode() -> SKShapeNode {
        let path = UIBezierPath()
        let w = GameConfig.sergeantChevronWidth
        let h = GameConfig.sergeantChevronHeight
        path.move(to: CGPoint(x: -w / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -h))
        path.addLine(to: CGPoint(x:  w / 2, y: 0))
        let shape = SKShapeNode(path: path.cgPath)
        shape.strokeColor = .ganhoMusicGold
        shape.lineWidth = GameConfig.sergeantChevronLineWidth
        shape.fillColor = .clear
        return shape
    }
}
```

### 기능 5: ColorTokens 신규 6 토큰

`// MARK: - Sprint 7 Phase F · Airforce Sergeant + Stone Guard tonal`:
```swift
static let ganhoAirforceTeal       = UIColor(hex: "#3A6F7F")
static let ganhoAirforceTealLight  = UIColor(hex: "#5A8F9F")
static let ganhoSunglassesBlack    = UIColor(hex: "#1A1A1A")
static let ganhoStoneGuardLight    = UIColor(hex: "#A0A0A8")
static let ganhoStoneGuardDark     = UIColor(hex: "#5A5670")  // hex 동일 → navyMuted (의미 분리)
static let ganhoStoneGuardOutline  = UIColor(hex: "#7A7570")
```

> ganhoSkinTone이 ColorTokens에 없으면 Generator가 추가 (#FFD9B8 살구색 추정), 또는 기존 paperLight 등 재사용.

### 기능 6: GameConfig Phase F V3 상수 ~22개

`// MARK: - Sprint 7 Phase F · Villain Visual V3`:
```swift
// EnemyNode (수간호사)
static let enemyVisualHaloWidth: CGFloat  = 22
static let enemyVisualHaloHeight: CGFloat = 28
static let enemyVisualHaloAlpha: CGFloat  = 0.18
static let enemyVisualChartSize = CGSize(width: 6, height: 8)
static let enemyVisualChartOffset = CGPoint(x: 10, y: -2)

// ProfessorNode (이교수)
static let professorStethoIconRadius: CGFloat = 2.2
static let professorStethoIconOffset = CGPoint(x: -11, y: -6)
static let professorStethoTubeWidth: CGFloat  = 1.2
static let professorStethoTubeHeight: CGFloat = 6

// StoneGuardNode (석조무사)
static let stoneGuardEyeOffsetX: CGFloat = 4
static let stoneGuardEyeOffsetY: CGFloat = 5

// SergeantParkNode (박병장)
static let sergeantParkWidth: CGFloat  = 16
static let sergeantParkHeight: CGFloat = 20
static let sergeantShadowSize = CGSize(width: 18, height: 4)
static let sergeantShadowOffsetY: CGFloat = -18
static let sergeantBodySize = CGSize(width: 18, height: 14)
static let sergeantBodyOffsetY: CGFloat = -6
static let sergeantHeadRadius: CGFloat   = 6
static let sergeantHeadOffsetY: CGFloat  = 6
static let sergeantCapCrownSize = CGSize(width: 16, height: 6)
static let sergeantCapCrownOffsetY: CGFloat = 13
static let sergeantCapVisorSize = CGSize(width: 18, height: 2)
static let sergeantCapVisorOffsetY: CGFloat = 9
static let sergeantSunglassesSize = CGSize(width: 11, height: 3)
static let sergeantSunglassesOffsetY: CGFloat = 5
static let sergeantRankChevronCount: Int = 2
static let sergeantRankOffsetX: CGFloat  = 6
static let sergeantRankOffsetY: CGFloat  = -1
static let sergeantRankChevronGap: CGFloat = 3
static let sergeantChevronWidth: CGFloat = 5
static let sergeantChevronHeight: CGFloat = 2.5
static let sergeantChevronLineWidth: CGFloat = 1.0
```

### 기능 7: mockups/villains-and-player-directions-v1.html (전반부)
- 폭 1024 × 높이 768
- 4 패널 가로 정렬 (각 220×320, gap 16)
- 각 패널: SVG 96×120 + 핵심 시각 요소 라벨 + 색 키 hex
- 폰트 Jua + Gowun Dodum
- 배경 warm gradient
- Phase G에서 후반부 5명 4방향 추가 예정 (HTML 한 파일)

## 합격 기준 (SPRINT_7_REQUEST.md §7.4)

- 4명 빌런 5초 안에 시각 식별
- SergeantParkNode 컴파일 OK + mockup 시각 그려짐
- 기존 3종 hitbox byte-identical (physicsBody.size/categoryBitMask/collisionBitMask/contactTestBitMask)
- AI/이동/충돌 0줄 (update/startPatrol/startThrowingStethoscopes/scheduleNextThrow/throwStethoscope/apply 본문)
- GameScene 0줄 (addNormalMap/addHardMap/setupEnemy/setupStoneGuard/setupProfessor)
- 강제 언래핑 0, Timer 0, 매직 넘버 0
- mockup ↔ Swift 시각 85% 일치

| 카테고리 | 가중 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 |
| Swift 패턴 | 20% | 7.0 |
| 비주얼 일관성 | 25% | 7.0 |
| 가독성 & UX | 15% | 7.0 |

가중 평균 7.5 이상 합격.

## 변경 LOC 추정치

| 파일 | LOC |
|---|---|
| EnemyNode.swift | ~26 |
| ProfessorNode.swift | ~21 |
| StoneGuardNode.swift | ~32 |
| SergeantParkNode.swift (신규) | ~150 |
| ColorTokens.swift | ~20 |
| GameConfig.swift | ~90 |
| mockups/villains-and-player-directions-v1.html (신규) | ~200 |
| **합계** | **~540** |

SPRINT_7_REQUEST.md §1 추정 ~500 ±10%.

## OPEN_QUESTION (모두 결정됨)

**OQ-1**: SergeantParkNode 부모 클래스 — **SKSpriteNode(.clear, size) + 자식 SKShapeNode 6종** 채택. 기존 빌런 3종 패턴 일관성. SPRINT_7_REQUEST.md §7.2 "SKShapeNode" 명시는 *추후 변경 가능*하나 본 SPEC은 일관성 우선.

**OQ-2**: EnemyNode 픽셀 텍스처 톤 흐림 — **자식 SKShapeNode 추가만**(차트 + 헬로). 픽셀 텍스처 완전 교체는 회귀 위험 크고 Phase F 범위 초과 (Sprint 8 후보).

**OQ-3**: StoneGuardNode 단색 박스 → 신규 PixelSprite 변환 — **현 단색 + 자식 SKShape 부착으로 충분**. PixelSprite stoneGuardData 정식 변환은 Sprint 8 후보.

**OQ-4**: hitbox 보존 검증 — Evaluator는 `SKPhysicsBody(rectangleOf: size)` size 인자 (GameConfig.enemyWidth/Height 등)가 byte-identical인지 grep 비교.

## 주의사항

- 강제 언래핑 0, 매직 넘버 0 (모든 사이즈는 GameConfig V3)
- update() 안 addChild 0 — setupVisualOverlay는 init에서 1회만
- weak self 클로저 미사용 (정적 부착)
- 자식 SKShapeNode position은 부모 SKSpriteNode 중심 (0,0) 기준, zPos는 부모 zPos 5 기준 상대값
- EnemyNode 픽셀 텍스처와 시각 자식 겹침: offset 신중 (sprite center 기준 우측 옆구리), zPos 0.1~0.2로 텍스처 위
- mockup vs SpriteKit 차이: mockup HTML SVG는 자유로운 path, SpriteKit은 rectOf/circleOf/path 추상화 — 85% 일치 합격선

## 관련 파일

- 수정: `Nodes/EnemyNode.swift`, `Nodes/ProfessorNode.swift`, `Nodes/StoneGuardNode.swift`, `Config/ColorTokens.swift`, `Config/GameConfig.swift`
- 신규: `Nodes/SergeantParkNode.swift`, `mockups/villains-and-player-directions-v1.html`
- 참조: `Config/PhysicsCategory.swift`, `GameScene.swift` (호출 위치 확인용, 0줄 변경)
