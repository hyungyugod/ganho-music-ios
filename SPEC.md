# Phase 4-3 · AIRFORCE 이스터에그 시각 트리거 (stub 본체 채우기)

## 개요
4-2에서 만들어둔 `onStoneGuardContact = {}` stub을 *실제 본체*로 교체한다. 플레이어가 석조무사를 *처음* 통과하는 순간 화면 위쪽에 노란 비행기 한 마리가 좌→우로 2초간 가로질러 지나가고 자가 소멸한다. 1회 한정 순수 시각 이스터에그 — 점수/HUD/적/게임오버 로직은 한 줄도 건드리지 않는다.

## 변경 유형
**혼합** — 신규 노드 파일(`AirplaneNode`) + 비주얼 효과(SKAction 가로지르기) + GameScene에 1회 한정 트리거 메서드 신설.

## 게임 경험 의도
플레이어가 정해진 길을 걷는 석조무사를 *우연히* 통과한 순간, 화면 위쪽 라인을 노란 비행기가 좌→우로 슝~ 지나간다(2초). 게임 점수·HUD·적 행동·게임오버 조건은 *전혀* 영향 없는 순수 시각 이스터에그. 한 판 안에서 *1회만* 발동하며, 새 게임 시작 시 자동 리셋(새 GameScene 인스턴스 → 플래그 기본값 false).

## Sprint 범위 계약

### In Scope (필수, 이게 없으면 SPEC 미동작)
1. 새 파일 `Nodes/AirplaneNode.swift` (~40줄, SKSpriteNode 서브클래스 + crossScreen 메서드)
2. `Config/GameConfig.swift` Airforce Easter Egg 섹션 4상수 추가
3. `GameScene.swift`: 헤더 MARK 1줄 + `airforceTriggered` 프로퍼티 + `triggerAirforceEasterEgg()` 메서드 + onStoneGuardContact stub 본체 교체
4. `pbxproj` 식별자 0018 4곳 등록 (PBXBuildFile / PBXFileReference / Nodes 그룹 / iOS Sources phase)

### Out of Scope (모두 금지, 위반 시 P0)
- ContactRouter 변경 (콜백 시그니처·분기 그대로)
- PhysicsCategory 변경 (.airplane 같은 새 비트 0)
- StoneGuardNode 변경 (PhysicsBody·startPatrol 그대로)
- GameScene+Setup.swift 변경 (setupStoneGuard 그대로)
- 기존 GameConfig 상수 변경 (stoneGuard / player / enemy / projectile / note / hud / dpad / time / world 일체)
- EnemyNode·PlayerNode·NoteNode·ProjectileNode·HUDNode·DPadNode 변경
- TitleScene·ResultScene 변경
- ColorTokens 새 토큰 신설 (기존 `.ganhoYellowF`만 사용)
- update() 게임 루프 변경
- endGame() 변경
- physicsBody·collisionBitMask·contactTestBitMask 어디서도 손대지 않음 (비행기 = PhysicsBody 없음)
- 폭탄·수간호사 도주·오버레이 효과 (다음 sprint)
- 비행기 충돌 / 점수 / HUD / sound (다음 sprint)
- macOS / tvOS Sources phase 수정
- Test 코드 추가
- 새 Manager / Repository / System 신설

### 판단 기준
"이 변경이 없으면 'Player가 StoneGuard를 처음 통과 시 비행기가 화면 좌→우 1회 가로지르기'가 동작하는가?" → NO인 변경만 In Scope.

## 변경 범위

### 신설 파일 (1개)
- `GanhoMusic/GanhoMusic Shared/Nodes/AirplaneNode.swift` — SKSpriteNode 서브클래스, 색·크기·zPosition 부여 + `crossScreen(sceneWidth:atY:)` 자가 소멸 메서드

### 수정 파일 (3개)
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` (+1 섹션, +4 상수, ~6줄)
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` (+~12줄: 헤더 MARK 1줄 + 프로퍼티 1줄 + 메서드 6줄 + stub 본체 교체 1줄 + 주석 정리)
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` (4곳 식별자 0018)

## 기능 상세

### 기능 1: AirplaneNode.swift 신규 파일
- 설명: 노란 막대 비행기. init에서 색·크기·zPosition만 부여, SKAction은 외부 호출자가 `crossScreen(sceneWidth:atY:)`를 부르면 시작 (scene.size 의존이라 init에서 자동 시작 불가).
- 구현 위치: `GanhoMusic/GanhoMusic Shared/Nodes/AirplaneNode.swift` 신규 (~40줄)
- 핵심 코드 구조:

```swift
//
//  AirplaneNode.swift
//  GanhoMusic Shared
//
//  Phase 4-3 · AIRFORCE 이스터에그 비행기 — 좌→우 가로지르기 + 자가 소멸
//

import SpriteKit

/// AIRFORCE 이스터에그 비행기. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·크기·zPosition만 부여하고, scene.size 의존인 SKAction은
/// 외부 호출자가 crossScreen(sceneWidth:atY:)을 부르는 시점에 시작한다.
/// SKAction.sequence([move, removeFromParent])로 자가 소멸(fire-and-forget).
final class AirplaneNode: SKSpriteNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.airplaneWidth,
            height: GameConfig.airplaneHeight
        )
        // 색: F 투사체와 동일 .ganhoYellowF — 주의 환기. 새 ColorTokens 신설 금지.
        super.init(texture: nil, color: .ganhoYellowF, size: size)
        name = "airplane"
        // HUD(100) 아래, 일반 노드(5) 위. 점수 라벨을 가리지 않으며 공중에 떠 있는 느낌.
        zPosition = 50
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cross
    /// 부모(cameraNode)에 addChild 직후 호출. 화면 좌측 바깥에서 시작 → 우측 바깥까지 이동 → 자가 제거.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 시작/끝 모두 화면 바깥(노드 폭만큼 여유).
    /// - Parameters:
    ///   - sceneWidth: 씬 가로 크기(scene.size.width). 좌우 바깥 좌표 계산용.
    ///   - y: cameraNode 좌표계 y (화면 중앙 기준). 화면 상단 가까이 = 양수.
    func crossScreen(sceneWidth: CGFloat, atY y: CGFloat) {
        let startX = -(sceneWidth / 2 + size.width)
        let endX   = +(sceneWidth / 2 + size.width)
        position = CGPoint(x: startX, y: y)
        let move    = SKAction.move(to: CGPoint(x: endX, y: y),
                                    duration: GameConfig.airplaneCrossDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([move, cleanup]))
    }
}
```

### 기능 2: GameConfig.swift Airforce Easter Egg 섹션 신설
- 설명: Stone Guard 섹션 *바로 다음*에 새 섹션을 두고 비행기 4상수 정의.
- 구현 위치: `Config/GameConfig.swift` — `stoneGuardWaypoints` 배열 닫는 `]` 다음 줄(파일 끝 `}` 직전)
- 핵심 코드 구조:

```swift
    // MARK: - Airforce Easter Egg (Phase 4-3)
    /// 비행기 가로 (pt). 가로로 긴 막대형.
    static let airplaneWidth: CGFloat = 32
    /// 비행기 세로 (pt). 가로형 비율.
    static let airplaneHeight: CGFloat = 16
    /// 비행기 좌→우 가로지르기 duration (초). 너무 빠르면 못 보고, 너무 느리면 게임 방해.
    static let airplaneCrossDuration: TimeInterval = 2.0
    /// 화면 상단에서 비행기 y 위치까지의 거리 (pt). cameraNode 자식 좌표계: y = +(halfH - 60).
    static let airplaneTopOffset: CGFloat = 60
```

### 기능 3: GameScene.swift 헤더 MARK 라인 1줄 추가
- 설명: 변경 이력 누적용 헤더 주석 1줄.
- 구현 위치: `GameScene.swift` 라인 23 (Phase 4-2 헤더 다음)
- 핵심 코드 구조:

```swift
//  Phase 4-2 · StoneGuardNode PhysicsBody 부착 + ContactRouter onStoneGuardContact stub
//  Phase 4-3 · AIRFORCE 이스터에그 — Player ↔ StoneGuard 첫 접촉 시 비행기 가로지르기 1회
//
```

### 기능 4: GameScene.swift `airforceTriggered` 프로퍼티 추가
- 설명: 1회 한정 이벤트 가드 Bool 플래그. private — 같은 파일·타입 한정. 게임 1판 = 새 GameScene 인스턴스이므로 자동 리셋(별도 reset 메서드 불필요).
- 구현 위치: `GameScene.swift` Properties 섹션의 *시스템 섹션 마지막*(statsRepo 다음, `// MARK: - Factory` *위*)에 1줄
- 핵심 코드 구조:

```swift
    let statsRepo = StatisticsRepository()      // Phase 3-5 — 누적 통계 영구 저장소

    // Phase 4-3 — AIRFORCE 이스터에그 1회 한정 가드. true가 되면 재발동 안 함.
    // 새 GameScene 인스턴스에서 자동 false로 리셋됨.
    private var airforceTriggered: Bool = false

    // MARK: - Factory
```

### 기능 5: GameScene.swift `triggerAirforceEasterEgg()` 메서드 신설
- 설명: 1회 가드 → AirplaneNode 생성 → cameraNode 자식으로 부착 → crossScreen 호출. cameraNode 자식이라 화면 고정 좌표계.
- 구현 위치: `GameScene.swift` `configureContactRouter()` 메서드 *직후*, `// MARK: - Game State` *바로 위*. 별도 `// MARK: - Easter Egg` 섹션으로 묶는다.
- 핵심 코드 구조:

```swift
    // MARK: - Easter Egg
    /// Player ↔ StoneGuard 첫 접촉 시 호출. 1회 한정 가드 후 비행기 1마리를 cameraNode에 부착,
    /// 좌→우 가로지르기 SKAction 실행. AirplaneNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    /// 점수/HUD/적/게임오버 로직 일체 미접촉 — 순수 시각 이스터에그.
    private func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        airforceTriggered = true
        let plane = AirplaneNode()
        cameraNode.addChild(plane)
        let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
        plane.crossScreen(sceneWidth: size.width, atY: y)
    }

    // MARK: - Game State
```

### 기능 6: GameScene.swift onStoneGuardContact stub 본체 교체
- 설명: 4-2의 빈 stub `{ }`를 `[weak self]` 캡처 + triggerAirforceEasterEgg() 호출로 교체. 콜백 시그니처(`() -> Void`) 그대로 — ContactRouter 0줄 변경.
- 구현 위치: `GameScene.swift` `configureContactRouter()` 메서드 안, `contactRouter.onStoneGuardContact = ...` 블록
- 핵심 코드 구조:

```swift
        contactRouter.onStoneGuardContact = { [weak self] in
            self?.triggerAirforceEasterEgg()
        }
```

> 기존 stub 안 `// Phase 4-2 — stub. 4-3에서 이스터에그 트리거 본체가 들어옴.` 주석은 **제거**한다.

### 기능 7: project.pbxproj — AirplaneNode 4곳 등록
- 설명: 식별자 `0018` (StoneGuardNode `0017` 다음 자유 슬롯). 4-1과 동일 정책으로 iOS Sources phase에만 등록 (tvOS / macOS 수정 0).
- 구현 위치: 4곳, StoneGuardNode 0017 등록 *바로 다음 줄*에 동일 패턴으로 추가

**(1) PBXBuildFile section**:
```
		A1C0F1B00000000000000018 /* AirplaneNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000018 /* AirplaneNode.swift */; };
```

**(2) PBXFileReference section**:
```
		A1C0F1A00000000000000018 /* AirplaneNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirplaneNode.swift; sourceTree = "<group>"; };
```

**(3) Nodes 그룹 children** (`StoneGuardNode.swift` 다음):
```
				A1C0F1A00000000000000018 /* AirplaneNode.swift */,
```

**(4) iOS Sources phase files** (`StoneGuardNode.swift in Sources` 다음, `);` 닫기 전):
```
				A1C0F1B00000000000000018 /* AirplaneNode.swift in Sources */,
```

> tvOS / macOS Sources phase는 4-1·4-2와 동일 정책으로 *그대로 둔다*.

## 검증 시나리오 (a)~(i) — Evaluator 정적 검증 항목

| # | 시나리오 | 정적 검증 방법 |
|---|---|---|
| (a) | StoneGuard 미접촉 시 비행기 0건 | `AirplaneNode()` 생성 호출이 `triggerAirforceEasterEgg()` 내부 1곳에만 존재 — Grep으로 확인. didMove·update에 직접 호출 없음. |
| (b) | 통과 시 비행기 1회 등장 | `triggerAirforceEasterEgg()` 본문: ① `if airforceTriggered { return }` ② `airforceTriggered = true` ③ `AirplaneNode()` 인스턴스화 ④ `cameraNode.addChild(plane)` ⑤ `plane.crossScreen(...)`. AirplaneNode.crossScreen 본문: `SKAction.sequence([move, removeFromParent])` 정확. |
| (c) | 재통과 시 비행기 0건 | `airforceTriggered = true`가 메서드 본문 *2번째 줄*. 가드 통과 후 즉시 한 번만 발사. |
| (d) | HUD / 점수 변화 0 | `triggerAirforceEasterEgg()` 본문에 `scoreSystem`, `hud`, `remainingTime`, `gameState`, `endGame` 참조 0건 — Grep으로 확인. AirplaneNode.swift 전체에 `scoreSystem`, `hud` 참조 0건. |
| (e) | player / enemy / F 영향 0 | AirplaneNode.swift 전체에 `physicsBody`, `SKPhysicsBody`, `categoryBitMask`, `contactTestBitMask`, `collisionBitMask` 0건. PhysicsCategory 0건 참조. |
| (f) | cameraNode 자식 부착 | `triggerAirforceEasterEgg()` 본문에 `cameraNode.addChild(plane)` 명시. `worldNode.addChild(plane)` 0건. `self.addChild` 0건. |
| (g) | 게임오버 시 비행기 잔존 → ARC 자동 해제 | `endGame()` 본문 0줄 변경. ResultScene `presentScene` 호출이 GameScene 트리 전체를 ARC 해제하므로 자동 정리. 별도 cleanup 코드 *불필요*. |
| (h) | 재시작 시 리셋 | `airforceTriggered: Bool = false` 가 *기본값* 명시. 새 GameScene 인스턴스 → 자동 false. |
| (i) | 빌드 SUCCEEDED + 경고 0건 | pbxproj 0018 4곳 모두 등록. 식별자 충돌 0(0017이 마지막 사용 식별자). AirplaneNode.swift `import SpriteKit` 1건. `final class AirplaneNode: SKSpriteNode` 시그니처. `required init?(coder:)` 명시. |

## 주의사항

### Swift / SpriteKit 안전 패턴
- AirplaneNode 자체에 PhysicsBody **부착 금지** — 시각만, 충돌 0.
- `[weak self]` 캡처는 4-3에서 *비로소* 의미를 가짐 — onStoneGuardContact 본체에서 self.triggerAirforceEasterEgg() 호출.
- `triggerAirforceEasterEgg()`는 `private func` — 외부에서 직접 호출 차단.
- `airforceTriggered`는 `private var` — 같은 파일·같은 타입 한정. GameScene+Setup.swift extension에서 접근 *불필요*.
- `required init?(coder:)`에 `fatalError(...)`는 강제 언래핑이 *아니다* — SKNode 서브클래스의 표준 패턴.
- 비행기 zPosition 50 = HUD(100) 아래 / 일반 노드(5) 위.
- 매직 넘버 금지 — 비행기 32×16, duration 2.0, topOffset 60은 모두 `GameConfig.airplane*` 상수 참조.

### pbxproj 규칙
- 식별자 0018: StoneGuardNode 0017 패턴 정확 답습. PBXBuildFile 접두사 `A1C0F1B0`, PBXFileReference 접두사 `A1C0F1A0`.
- tvOS / macOS Sources phase는 *그대로 둠*.
- iOS Sources phase에만 추가.

### 게임 경험 보존
- 비행기는 **반드시 cameraNode 자식**, worldNode 자식 금지. worldNode 자식이면 player 이동 시 비행기도 같이 흘러가서 어색함.
- 1회 한정: 한 게임 안에서만 *1회*. 새 GameScene 인스턴스(재시작)에서는 다시 1회 가능.
- 점수·HUD·게임오버·적·F 어디에도 영향 0.

### 빌드 에러 가능성
- `AirplaneNode.swift`가 pbxproj 4곳에 모두 등록 안 되면 컴파일 누락 → `Cannot find 'AirplaneNode' in scope` 에러.
- 식별자 0018 충돌 가능성: 현재 0017이 마지막 사용. 0018 자유 슬롯 확인 완료.
- `cameraNode.addChild(plane)` 호출이 `cameraNode`가 씬 트리에 추가된 *후*여야 하는데, didMove에서 setupCamera 완료 이후에만 stoneGuard 접촉 발생이라 순서 안전.
