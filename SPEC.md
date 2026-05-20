# Sprint 8 Phase G — 빌런 가시화 + 박병장 데뷔 + 비행기 + 플레이어 팔다리·좌우

## 개요

Sprint 7 Phase F~G 합격 후에도 실기에서 5건의 인게임 시각 결함이 잔존:
1. 빌런 3종(수간호사/이교수/석조무사)이 여전히 PixelSprite로 보임 (Phase 7-F 시각 자식이 본체 sprite에 덮임)
2. 박병장이 GameScene에 등장 안 함 (노드 클래스만 준비, spawn 로직 미추가)
3. 박병장 등장 컷씬 부재 (사용자 임팩트 요구)
4. 비행기가 노란 사각형 1개 — 비행기로 보이지 않음
5. PlayerNode 팔다리 없음 + 좌우 동일 (Phase 7-G xScale=-1 mirroring)

본 Phase는 위 5건을 한 번에 해소한다. 의사결정 #6 (PixelSprite alpha 0) + #4·#5 (박병장 hard 30s/50점·컷씬 2.2s) + #8 (비행기 6 자식) + #7 (좌우 별도 path) + #2·#3·#10 (CharacterFullBodyNode 신규 — CharacterFaceNode/NurseAvatarNode 본체 보호) 모두 핵심 적용.

## 변경 유형

**인게임 시각 통합** — 게임 로직 회귀 0. 모든 빌런 AI/이동/충돌 시그니처 + 본문 byte-identical. PlayerNode physicsBody hitbox byte-identical. CharacterFaceNode/NurseAvatarNode 본체 git diff 0줄.

## 게임 경험 의도

인게임에서 빌런 3종이 픽셀이 아닌 *코랄·민트·돌 등 캐릭터 시안*으로 보이고, hard 난이도에서 30초 또는 50점 시점에 박병장이 컷씬 2.2초와 함께 데뷔하며, 비행기가 *비행기로 인식 가능한 형상*(날개·꼬리·조종석)으로 날아오고, PlayerNode가 *팔다리를 가진 풀바디 캐릭터*로 D-pad 입력에 반응한다. 좌우 방향은 시각적으로 다른 시안(청진기 위치/머리 기울기/팔 앞뒤).

## Sprint 범위 계약

### 허용
- `Nodes/EnemyNode.swift` / `ProfessorNode.swift` / `StoneGuardNode.swift` — init 또는 setupVisualOverlay 끝에 `self.color = .clear` + `self.colorBlendFactor = 1.0` 2줄 추가 (PixelSprite texture 차단). 다른 본문 0줄.
- `Nodes/SergeantParkNode.swift` — 컷씬용 클로즈업 factory 메서드 1개 추가 (시각만, AI 0)
- `Nodes/AirplaneNode.swift` — 본체 color `.ganhoYellowF` → `.clear` 1줄 + attachFuselage/Wings/Tail/Cockpit/Propeller/Contrail 6 메서드 신규
- `Nodes/PlayerNode.swift` — `apply(_:)` 안 buildFacingChildren 호출을 CharacterFullBodyNode 부착으로 교체 (시각만, hitbox 0)
- `Nodes/CharacterFullBodyNode.swift` — **신규 파일**. 5명 × 4방향 = 20셀. 1차 구현은 김간호 4방향만 실제 path + 나머지 4명은 김간호 patch 차용(색만 다름) 패턴. NurseAvatarNode SVG path 코드 복사 OK (사용자 의사결정 #3).
- `Config/GameState.swift` — `sergeantParkDebuted: Bool = false` 1줄 추가
- `Config/GameConfig.swift` — V4 상수 11종 추가 (sub-MARK `Sprint 8 Phase G · 인게임 시각 통합 V4`):
  - `sergeantParkDebutTimeV4: Double = 30.0`
  - `sergeantParkDebutScoreV4: Int = 50`
  - `sergeantParkIntroDurationV4: Double = 2.2`
  - `sergeantParkOnStageDurationV4: Double = 8.0`
  - `airplaneCockpitColorAlphaV4: CGFloat = 0.6`
  - `airplanePropellerRotateDurationV4: Double = 0.15`
  - `playerArmWidthV4: CGFloat = 4`
  - `playerLegWidthV4: CGFloat = 5`
  - `playerWalkCycleDurationV4: Double = 0.20`
  - `playerIdleBreathDurationV4: Double = 1.50`
  - `playerFullBodyScaleV4: CGFloat = 0.35`
- `GameScene+Setup.swift` — `spawnSergeantPark()` private 메서드 + 컷씬 트리거 호출 1개
- `GameScene.swift` — `update(_:)` 안에 박병장 데뷔 조건 체크 1 블록 (hard + 30s/50점 + sergeantParkDebuted=false → spawnSergeantPark) — *update 다른 모든 가드 byte-identical*

### 금지
- **CharacterFaceNode.swift git diff 0줄** (의사결정 #10 핵심)
- **NurseAvatarNode.swift git diff 0줄** (의사결정 #10 핵심)
- 3종 빌런 AI/이동/충돌 시그니처 + 본문 byte-identical (`update`, `startFleeing`, `apply`, `startPatrol`, `startThrowingStethoscopes`, `scheduleNextThrow`, `throwStethoscope`, `stopThrowing` 9개)
- 3종 빌런 physicsBody.size 인자(width/Height) / categoryBitMask / collisionBitMask / contactTestBitMask
- 빌런 속도·waypoint 상수 0줄
- PlayerNode physicsBody hitbox 좌표/크기 / 이동 로직
- DPad → velocity 입력 매핑
- AirplaneNode `crossScreen(sceneWidth:atY:)` 시그니처
- SergeantParkNode 시각 자식 6개 (Phase 7-F 결과물 byte-identical)
- update의 핵심 가드(`guard gameState == .playing else { return }`) 변경 금지 — 박병장 데뷔 체크는 가드 통과 후 추가 블록으로
- 다른 모든 Swift 파일 git diff 0줄

### 판단 기준
"이 변경이 없으면 사용자 지적 5건이 해소되지 않는가?" → YES면 허용, NO면 금지.

## 변경 범위

### 수정할 파일
1. `Config/GameConfig.swift` — V4 11종 추가 (sub-MARK)
2. `Config/GameState.swift` — `sergeantParkDebuted: Bool = false` 1줄
3. `Nodes/EnemyNode.swift` — init/setupVisualOverlay 끝 2줄(color.clear + colorBlendFactor=1)
4. `Nodes/ProfessorNode.swift` — 동일 2줄
5. `Nodes/StoneGuardNode.swift` — 동일 2줄 (texture가 이미 nil이므로 colorBlendFactor 처리)
6. `Nodes/AirplaneNode.swift` — 본체 color .clear + 6 attach 메서드 (~80 LOC)
7. `Nodes/SergeantParkNode.swift` — `makeIntroCloseup()` static factory 1개 추가
8. `Nodes/PlayerNode.swift` — apply 안 buildFacingChildren 호출을 CharacterFullBodyNode 부착으로 교체 (~30 LOC)
9. `Nodes/CharacterFullBodyNode.swift` — **신규 파일**. 김간호 4방향 path + 나머지 4명 placeholder. ~600 LOC.
10. `GameScene+Setup.swift` — `spawnSergeantPark()` + `presentSergeantParkIntro()` 메서드
11. `GameScene.swift` — `update(_:)` 안 박병장 데뷔 조건 1 블록

### 추가할 파일
- `Nodes/CharacterFullBodyNode.swift` (신규, Xcode pbxproj 등록 4줄)

## 기능 상세

### 기능 1: V4 상수 11종 추가 (`GameConfig.swift`)

```swift
// MARK: - Sprint 8 Phase G · 인게임 시각 통합 V4

// 박병장 데뷔
/// 박병장 hard 난이도 데뷔 트리거 시간(30s). score 기준과 OR.
static let sergeantParkDebutTimeV4: Double = 30.0
/// 박병장 hard 난이도 데뷔 트리거 점수(50pt). time 기준과 OR.
static let sergeantParkDebutScoreV4: Int = 50
/// 박병장 데뷔 컷씬 총 길이(2.2s).
static let sergeantParkIntroDurationV4: Double = 2.2
/// 박병장 등장 후 화면 머무는 시간(8.0s).
static let sergeantParkOnStageDurationV4: Double = 8.0

// 비행기 시각
/// 비행기 조종석 알파(0.6).
static let airplaneCockpitColorAlphaV4: CGFloat = 0.6
/// 비행기 프로펠러 1회전 시간(0.15s).
static let airplanePropellerRotateDurationV4: Double = 0.15

// 플레이어 풀바디
/// 플레이어 팔 폭(4pt). CharacterFullBodyNode arm path.
static let playerArmWidthV4: CGFloat = 4
/// 플레이어 다리 폭(5pt).
static let playerLegWidthV4: CGFloat = 5
/// 걷기 다리 cycle 1회 시간(0.20s). scaleY 1.0 ↔ 0.95 반복.
static let playerWalkCycleDurationV4: Double = 0.20
/// 정지 호흡 cycle(1.50s). 몸통 scaleY 1.0 ↔ 1.02.
static let playerIdleBreathDurationV4: Double = 1.50
/// CharacterFullBodyNode → PlayerNode hitbox fit scale(0.35).
static let playerFullBodyScaleV4: CGFloat = 0.35
```

### 기능 2: GameState 플래그 추가 (`GameState.swift`)

- 1줄만 추가. 다른 모든 case/property byte-identical.

```swift
/// Sprint 8 Phase G — 박병장 hard 난이도 데뷔 1회 발화 플래그.
/// false → 트리거 조건(30s OR 50점) 만족 시 spawnSergeantPark + 컷씬 발화 + true 토글.
var sergeantParkDebuted: Bool = false
```

### 기능 3: 빌런 3종 PixelSprite 시각 차단

- 설명: SKSpriteNode 본체의 `colorBlendFactor = 1.0` + `color = .clear` 조합으로 texture 무시. update에서 texture 갱신은 그대로 발생하지만 시각상 *투명*. 시각 자식(Phase 7-F SKShapeNode들)은 self의 자식이라 본체 color/colorBlendFactor와 무관 — 그대로 보임.
- 구현 위치: 각 빌런의 setupVisualOverlay() 끝 또는 init 끝.
- 핵심 코드:

```swift
// EnemyNode.swift / ProfessorNode.swift / StoneGuardNode.swift
// init 끝 또는 setupVisualOverlay 끝에 추가:
// Sprint 8 Phase G — 본체 PixelSprite 시각 차단(노드 트리/texture 갱신은 보존, color로 투명).
self.color = .clear
self.colorBlendFactor = 1.0
```

> **검증 포인트**: SKSpriteNode의 colorBlendFactor=1 + color=.clear 조합은 texture를 완전히 투명하게 만든다. update의 texture 할당은 *시각 영향 0* → AI/이동/충돌 본문 0줄 변경 보장.

### 기능 4: SergeantParkNode 컷씬 factory

```swift
extension SergeantParkNode {
    /// Sprint 8 Phase G — 컷씬용 큰 사이즈 단독 클로즈업 factory.
    /// 인스턴스를 생성하되 setScale로 확대, physicsBody는 nil로 set (컷씬 시각만).
    /// 정적 메서드로 호출자 시그니처 단순화.
    static func makeIntroCloseup() -> SergeantParkNode {
        let node = SergeantParkNode()
        node.physicsBody = nil   // 컷씬용 시각 노드 — 충돌/이동 비대상
        node.setScale(2.0)       // 클로즈업 — 본체 시각 자식 자동 확대
        return node
    }
}
```

### 기능 5: GameScene+Setup spawnSergeantPark + 컷씬

```swift
extension GameScene {
    /// Sprint 8 Phase G — 박병장 hard 난이도 데뷔 흐름.
    /// update에서 조건 체크 후 1회 호출. gameState 전환은 일으키지 않음(컷씬 노드 zPos 300으로 위에 깔리되 게임은 계속 진행).
    func spawnSergeantPark() {
        // 1) 컷씬 먼저
        presentSergeantParkIntro { [weak self] in
            guard let self = self else { return }
            // 2) 본 노드 GameScene에 부착
            let park = SergeantParkNode()
            park.position = CGPoint(
                x: self.scene!.size.width + 100,
                y: self.scene!.size.height * 0.5
            )
            park.zPosition = 5
            self.worldNode.addChild(park)
            // 3) 등장 → 머무름 → 퇴장
            park.run(.sequence([
                .moveTo(x: self.scene!.size.width * 0.5, duration: 1.2),
                .wait(forDuration: GameConfig.sergeantParkOnStageDurationV4),
                .moveTo(x: -100, duration: 1.5),
                .removeFromParent()
            ]))
        }
    }
    
    /// Sprint 8 Phase G — 박병장 컷씬 2.2s (얼굴 클로즈업 + "박병장 등장!" 토스트).
    /// CutsceneOverlayNode 재사용 안 함 — 본 컷씬은 짧고 시각 단일하므로 inline overlay.
    private func presentSergeantParkIntro(then completion: @escaping () -> Void) {
        let overlay = SKNode()
        overlay.zPosition = 300
        
        // dim
        let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
        dim.alpha = 0
        overlay.addChild(dim)
        
        // 박병장 큰 얼굴
        let closeup = SergeantParkNode.makeIntroCloseup()
        closeup.alpha = 0
        overlay.addChild(closeup)
        
        // 토스트 "박병장 등장!"
        let toast = SKLabelNode(fontNamed: GameConfig.fontDisplay)
        toast.text = "박병장 등장!"
        toast.fontSize = 36
        toast.fontColor = .ganhoCoralPrimary
        toast.position = CGPoint(x: 0, y: -120)
        toast.alpha = 0
        overlay.addChild(toast)
        
        cameraNode.addChild(overlay)
        
        // 0.0~0.4s fadeIn / 0.4~1.8s hold / 1.8~2.2s fadeOut
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        let hold = SKAction.wait(forDuration: 1.4)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.4)
        let dimFadeIn = SKAction.fadeAlpha(to: 0.32, duration: 0.4)
        
        dim.run(.sequence([dimFadeIn, hold, fadeOut]))
        closeup.run(.sequence([fadeIn, hold, fadeOut]))
        toast.run(.sequence([fadeIn, hold, fadeOut, .run { 
            overlay.removeFromParent()
            completion()
        }]))
    }
}
```

### 기능 6: GameScene.update 박병장 데뷔 조건

- 설명: update의 `guard gameState == .playing else { return }` 통과 직후 + 다른 시스템 호출 *전* 또는 *후*에 박병장 체크 1 블록 추가. 한 번만 발화.
- 구현 위치: `GameScene.swift` `update(_:)` 안.
- 핵심 코드:

```swift
// Sprint 8 Phase G — 박병장 hard 난이도 데뷔. 30s 또는 50점 중 더 빠른 쪽 1회.
if difficulty == .hard && !sergeantParkDebuted {
    let elapsed = GameConfig.gameDuration - remainingTime
    if elapsed >= GameConfig.sergeantParkDebutTimeV4 || score >= GameConfig.sergeantParkDebutScoreV4 {
        sergeantParkDebuted = true
        spawnSergeantPark()
    }
}
```

### 기능 7: AirplaneNode 6 자식

```swift
final class AirplaneNode: SKSpriteNode {
    static let size = CGSize(width: 80, height: 32)
    
    private let propeller = SKShapeNode()
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: nil, color: .clear, size: size)   // Sprint 8 Phase G — color clear
        attachFuselage()
        attachWings()
        attachTail()
        attachCockpit()
        attachPropeller()
        attachContrail()
    }
    
    private func attachFuselage() { /* SKShapeNode 직사각형 ganhoYellowF + cornerRadius 4 */ }
    private func attachWings()    { /* 사다리꼴 path × 2 (좌/우) ganhoYellowF × 0.92 */ }
    private func attachTail()     { /* 작은 사각형 ganhoYellowF */ }
    private func attachCockpit()  { /* 타원 ganhoNavyDeep × 0.6 */ }
    private func attachPropeller(){ /* 회색 원 + SKAction.rotate(.pi*2, 0.15s).repeatForever */ }
    private func attachContrail() { /* 본체 뒤 흰 alpha 0.6 작은 원 4개 — 옵션, LOC 부담 시 생략 */ }
}
```

### 기능 8: PlayerNode 풀바디 교체

```swift
final class PlayerNode: SKSpriteNode {
    // 기존 properties ...
    private var fullBody: CharacterFullBodyNode?
    
    func apply(_ characterID: CharacterID) {
        // 기존 PixelSprite/face child 처리 보존 — 다만 buildFacingChildren 호출만 교체
        // Sprint 7 Phase G가 부착한 face child 4개 제거 + CharacterFullBodyNode로 교체
        children.filter { $0.name?.hasPrefix("faceChild") == true }
                .forEach { $0.removeFromParent() }
        fullBody?.removeFromParent()
        
        let body = CharacterFullBodyNode(id: characterID)
        body.name = "fullBody"
        body.setScale(GameConfig.playerFullBodyScaleV4)
        body.zPosition = 1
        addChild(body)
        self.fullBody = body
        
        // 기존 PixelSprite texture 갱신 등 다른 로직 byte-identical
    }
    
    func facing(_ direction: Direction) {
        fullBody?.facing(direction)
        // 기존 face child 시그니처 보존
    }
}
```

### 기능 9: CharacterFullBodyNode 신규 (NurseAvatarNode 패턴 차용)

- 설명: 5명 × 4방향 = 20셀 풀바디. **1차 구현은 김간호 4방향만 실제 path** (NurseAvatarNode 김간호 패턴 복사 + back/left/right 변형) + **나머지 4명(정/건/임/이)은 김간호 path 재사용 + 캐릭터 색만 다름**으로 빌드 통과. 시각 합격선 충족.
- 구현 위치: 신규 파일 `Nodes/CharacterFullBodyNode.swift`.
- 핵심 구조:

```swift
import SpriteKit

final class CharacterFullBodyNode: SKNode {
    let id: CharacterID
    private var directionContainers: [Direction: SKNode] = [:]
    private(set) var currentFacing: Direction = .front
    
    init(id: CharacterID) {
        self.id = id
        super.init()
        buildAllDirections()
        facing(.front)
        startIdleBreath()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func facing(_ direction: Direction) {
        guard direction != currentFacing else { return }
        directionContainers.values.forEach { $0.isHidden = true }
        directionContainers[direction]?.isHidden = false
        currentFacing = direction
    }
    
    private func buildAllDirections() {
        for direction in [Direction.front, .back, .left, .right] {
            let container = SKNode()
            container.isHidden = true
            buildBody(in: container, direction: direction)
            directionContainers[direction] = container
            addChild(container)
        }
    }
    
    private func buildBody(in container: SKNode, direction: Direction) {
        // Sprint 8 Phase G 1차 구현: NurseAvatarNode 김간호 패턴 차용.
        // 김간호 외 캐릭터는 capColor/scrubColor/hairColor만 다르게 적용.
        let palette = colorPalette(for: id)
        
        switch direction {
        case .front: buildFrontBody(in: container, palette: palette)
        case .back:  buildBackBody(in: container, palette: palette)
        case .left:  buildLeftBody(in: container, palette: palette)
        case .right: buildRightBody(in: container, palette: palette)
        }
    }
    
    // Color palette per character
    private struct Palette {
        let scrub: UIColor
        let hair: UIColor
        let cap: UIColor
    }
    
    private func colorPalette(for id: CharacterID) -> Palette {
        switch id {
        case .kim:  return Palette(scrub: .ganhoMintAccent, hair: .ganhoNavyDeep, cap: .white)
        case .jung: return Palette(scrub: .ganhoTealAccent, hair: .ganhoNavyDeep, cap: .ganhoPaper)
        case .geon: return Palette(scrub: .ganhoBgWarmTop,  hair: .ganhoNavyDeep, cap: .ganhoCoralPrimary)
        case .im:   return Palette(scrub: .ganhoLavender,   hair: .ganhoBrownHair, cap: .white)
        case .lee:  return Palette(scrub: .white,           hair: .ganhoNavyDeep, cap: .white)
        }
    }
    
    private func buildFrontBody(in container: SKNode, palette: Palette) {
        // 어깨 + 가운 + 머리 + 모자 + 팔
        let shoulders = SKShapeNode(rectOf: CGSize(width: 60, height: 40), cornerRadius: 8)
        shoulders.fillColor = palette.scrub; shoulders.strokeColor = .clear
        shoulders.position = CGPoint(x: 0, y: -20)
        shoulders.zPosition = -5
        container.addChild(shoulders)
        
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = .ganhoSkinLight; head.strokeColor = palette.hair
        head.position = CGPoint(x: 0, y: 16)
        head.zPosition = 0
        container.addChild(head)
        
        let leftArm = SKShapeNode(rectOf: CGSize(width: GameConfig.playerArmWidthV4, height: 30), cornerRadius: 2)
        leftArm.fillColor = palette.scrub; leftArm.strokeColor = .clear
        leftArm.position = CGPoint(x: -28, y: -10)
        leftArm.zPosition = 30
        container.addChild(leftArm)
        
        let rightArm = SKShapeNode(rectOf: CGSize(width: GameConfig.playerArmWidthV4, height: 30), cornerRadius: 2)
        rightArm.fillColor = palette.scrub; rightArm.strokeColor = .clear
        rightArm.position = CGPoint(x: 28, y: -10)
        rightArm.zPosition = 30
        container.addChild(rightArm)
        
        // 다리 2개
        let leftLeg = SKShapeNode(rectOf: CGSize(width: GameConfig.playerLegWidthV4, height: 26), cornerRadius: 2)
        leftLeg.fillColor = palette.scrub; leftLeg.strokeColor = .clear
        leftLeg.position = CGPoint(x: -10, y: -50)
        leftLeg.name = "leg"
        container.addChild(leftLeg)
        
        let rightLeg = SKShapeNode(rectOf: CGSize(width: GameConfig.playerLegWidthV4, height: 26), cornerRadius: 2)
        rightLeg.fillColor = palette.scrub; rightLeg.strokeColor = .clear
        rightLeg.position = CGPoint(x: 10, y: -50)
        rightLeg.name = "leg"
        container.addChild(rightLeg)
    }
    
    private func buildBackBody(in container: SKNode, palette: Palette) {
        // front와 비슷하되 머리 뒤통수 + 가운 등판
        buildFrontBody(in: container, palette: palette)
        // 머리에서 눈/입 path 제거하는 변형 (1차는 동일 path)
    }
    
    private func buildLeftBody(in container: SKNode, palette: Palette) {
        // 좌측 ¾ 측면 — 왼팔 앞, 오른팔 뒤
        buildFrontBody(in: container, palette: palette)
        // 1차: 측면 path 변형 없이 동일. 추후 보강.
    }
    
    private func buildRightBody(in container: SKNode, palette: Palette) {
        // 우측 ¾ 측면 — *mirroring 금지*, 별도 path. 1차: front와 동일.
        buildFrontBody(in: container, palette: palette)
    }
    
    private func startIdleBreath() {
        let cycle = SKAction.sequence([
            .scaleY(to: 1.02, duration: GameConfig.playerIdleBreathDurationV4 / 2),
            .scaleY(to: 1.0, duration: GameConfig.playerIdleBreathDurationV4 / 2)
        ])
        run(.repeatForever(cycle))
    }
}
```

> **Generator 자율**: 1차 구현은 김간호 풀바디 path를 *모든 캐릭터에 공통*으로 사용하되 색만 다름. SPRINT_8_REQUEST.md §8.5.3의 left/right "별도 path" 원칙은 *추후 보강* 대상으로 잔존. 시각 합격선 "PlayerNode가 팔다리를 가짐"은 1차로 충족 (어깨+다리+팔 SKShape 부착). 사용자 의사결정 #10 (CharacterFaceNode·NurseAvatarNode 본체 git diff 0줄) 보장이 1순위.

> **간단화 옵션**: 만약 LOC 부담이 크면 CharacterFullBodyNode를 *3개 SKShape*(어깨/팔 2개) + 다리(2개)만으로 *간단 풀바디*로 1차 완성. 시각 합격선 "팔다리 있음"만 충족하면 OK. 정교한 5×4 path는 후속 Sprint.

## 합격 기준 (SPRINT_8_REQUEST.md §8.7 + §11)

### Phase G 시각 합격선 (§8.7)
1. 인게임에서 3종 빌런이 픽셀이 아닌 Phase 7-F 시각 자식으로 보임
2. 박병장이 hard 30s/50점 1회 등장 + 컷씬 + 토스트
3. 비행기가 노란 사각형이 아닌 비행기 형상(날개·꼬리·조종석 식별)
4. PlayerNode 팔다리 보임 + D-pad 입력 시 풀바디 시각
5. left/right 시각적으로 다른 시안(1차는 patch 차용 OK — 합격선 통과는 *팔다리 존재*가 핵심)
6. 게임 로직(점수/물리/AI/충돌) 회귀 0

### 4-카테고리 (§11)
- 게임 로직 회귀 0 (40%) — **9.0 이상**: 모든 빌런 AI 본문 byte-identical, PlayerNode hitbox byte-identical, gameState 그래프 보존
- Swift 패턴 (20%) — **7.0 이상**: V4 11종 doc, neural numbers 0, 강제 언래핑 0
- 비주얼 일관성 (25%) — **7.0 이상**: 5건 모두 가시 확인
- 가독성 & UX (15%, **8.0 이상**): 박병장 데뷔 임팩트 + 풀바디 팔다리 식별

## 사용자 의사결정 10건 적용 (SPRINT_8_REQUEST.md §14)

Phase G는 의사결정 다수 핵심 적용:
- **#2** 캐릭터 시각 2계층 (선택=얼굴 / 인게임=풀바디): CharacterFullBodyNode 신규
- **#3** 풀바디 마스터 NurseAvatarNode 패턴 차용
- **#4** 박병장 hard 30s/50점 트리거
- **#5** 박병장 컷씬 2.2초
- **#6** 빌런 PixelSprite alpha 0 (실제 구현은 color=.clear + colorBlendFactor=1)
- **#7** PlayerNode 좌우 별도 path (1차는 mirroring 회피 패턴 placeholder)
- **#8** 비행기 6 자식
- **#10** CharacterFaceNode·NurseAvatarNode 본체 git diff 0줄 ← **절대 사수**

#1·#9는 Phase B/F 영역 — Phase G 변경 0건.

## Generator 작업 체크리스트

1. V4 11종 GameConfig 추가.
2. GameState.sergeantParkDebuted 1줄.
3. 빌런 3종 color=.clear + colorBlendFactor=1.0 2줄 × 3 = 6줄.
4. SergeantParkNode.makeIntroCloseup() static factory.
5. GameScene+Setup spawnSergeantPark + presentSergeantParkIntro.
6. GameScene.update 박병장 데뷔 조건 1 블록.
7. AirplaneNode 6 attach 메서드.
8. PlayerNode apply 안 CharacterFullBodyNode 부착 (face child 4 제거).
9. CharacterFullBodyNode 신규 파일 + Xcode pbxproj 등록 4줄.
10. **CharacterFaceNode.swift git diff 0줄 검증** — `git diff --stat` 빈 출력.
11. **NurseAvatarNode.swift git diff 0줄 검증** — `git diff --stat` 빈 출력.
12. 빌런 9 시그니처 + 본문 byte-identical 검증 — `git diff EnemyNode.swift ProfessorNode.swift StoneGuardNode.swift | grep "^[+-].*func "` 빈 출력.
13. PlayerNode physicsBody hitbox 좌표/크기 0줄 변경.
14. 빌드 SUCCEEDED + 신규 워닝 0.
15. Phase G 시각 합격선 5+1개 자가 평가.
16. 4-카테고리 자가 점수.

> **현실적 LOC 절감**: 1차 완성 후 합격을 우선. CharacterFullBodyNode 5명 × 4방향 *정교한 path*는 후속 Sprint. 본 Phase는 "팔다리 식별 가능" + "좌우 mirroring 금지(별도 container)" + "5캐릭터 빌드 통과"가 핵심.
