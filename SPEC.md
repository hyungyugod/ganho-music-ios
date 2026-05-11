# Phase 4-4 (C) — "나와라 박병장!" AIRFORCE 오버레이

## 개요

Phase 4-3에서 구현된 AIRFORCE 이스터에그(비행기 좌→우 가로지르기)에 "나와라 박병장!" 노란 텍스트 오버레이를 화면 정중앙에 추가한다. 비행기와 *동시*에 등장 → 1.5초 표시 → 0.3초 페이드아웃 → 자가 제거(총 수명 1.8초). 사용자 입력 없음(자동), 게임 일시정지 없음. 새 노드 1개(`AirforceOverlayNode`), `GameConfig` 3상수, `GameScene.triggerAirforceEasterEgg()` 본문 3줄 추가가 전부.

## 변경 유형

**혼합** — 신규 노드 클래스(`AirforceOverlayNode`) + 비주얼 효과(SKLabelNode + fadeOut) + 게임플레이 메서드 본문 확장(`triggerAirforceEasterEgg`).

## 게임 경험 의도

플레이어가 석조무사를 처음 통과하는 순간, 화면 정중앙에 노란색 텍스트 **"나와라 박병장!"**이 1.5초간 또렷이 떠 있다가 0.3초에 걸쳐 자연스럽게 사라진다. 그 사이 화면 위쪽에서는 비행기가 좌→우로 가로지른다(4-3) — 두 효과가 *동시*에 발화해 "박병장이 호출되자 비행기가 응답한다"는 의미를 명확히 전달한다. 점수·HUD·D-Pad·게임 로직은 모두 정상 진행되며, 시각 알림만 추가된다.

## Sprint 범위 계약

- **허용**: SPEC 기능의 정상 동작에 필수적인 최소 연동 변경 — 신규 노드 1개 파일, `GameConfig` 3상수 추가, `GameScene.swift` 4줄(헤더 MARK 1 + trigger 본문 3), pbxproj 4곳 0019 등록
- **금지**: SPEC에 없는 독립적인 새 기능/효과 추가
- **판단 기준**: "이 변경이 없으면 'Player가 StoneGuard 첫 통과 시 화면 중앙에 \"나와라 박병장!\"이 1.5초 + 페이드 0.3초 표시'가 동작하는가?" → YES면 허용, NO면 금지

### In Scope (4건, 모두 필수)

1. `Nodes/AirforceOverlayNode.swift` 신규 (~50줄, `final class : SKNode`)
2. `Config/GameConfig.swift` — Airforce Easter Egg 섹션 끝(airplaneTopOffset 다음)에 3상수 추가
3. `GameScene.swift` — 헤더 MARK 1줄 + `triggerAirforceEasterEgg()` 본문 끝에 3줄 추가
4. `GanhoMusic.xcodeproj/project.pbxproj` — 4곳 0019 식별자 등록 (AirplaneNode 0018 패턴 답습)

### Out of Scope (위반 시 P0)

- `AirplaneNode.swift` 변경 (한 줄도)
- `ContactRouter` / `PhysicsCategory` / `StoneGuardNode` / `GameScene+Setup.swift` 변경
- 기존 `GameConfig` 상수 값/이름 변경 (airplane 4상수 / stoneGuard / 그 외 일체)
- 다른 노드 변경 (Enemy/Player/Note/Projectile/HUD/DPad)
- `TitleScene` / `ResultScene` 변경
- `ColorTokens` 신 토큰 신설 (기존 `.ganhoYellowF` 재사용)
- `update()` / `endGame()` 변경
- 폭탄·수간호사 도주·사운드 (다음 sprint)
- 사용자 입력 처리 (오버레이 터치/확인 버튼 — 자동 페이드만)
- 게임 일시정지·`gameState` 변경
- `airforceTriggered` 가드 로직 변경 (4-3 그대로)
- 비행기와 오버레이 *순서 의존성* 도입 (둘이 독립 노드)
- macOS / tvOS Sources phase 수정 (현재 비어 있음 — 그대로 유지)
- 테스트 코드 추가

## 변경 범위

### 추가할 파일 (1개)
- `GanhoMusic/GanhoMusic Shared/Nodes/AirforceOverlayNode.swift` — `final class AirforceOverlayNode: SKNode`. 자식 `SKLabelNode` 1개. `showAndDismiss()` 메서드로 자가 소멸.

### 수정할 파일 (3개)
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift` — Airforce Easter Egg 섹션 *끝*에 3상수 추가
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` — 헤더 MARK 1줄 + `triggerAirforceEasterEgg()` 본문 *마지막*에 3줄 추가
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 4곳 0019 식별자 등록

## 기능 상세

### 기능 1 — `AirforceOverlayNode` 신규 노드
- **설명**: "나와라 박병장!" 텍스트를 1.5초 표시 → 0.3초 페이드아웃 → 자가 제거하는 SKNode 컨테이너. PhysicsBody 없음, 입력 처리 없음, 순수 시각.
- **구현 위치**: `GanhoMusic/GanhoMusic Shared/Nodes/AirforceOverlayNode.swift` (신규)
- **참조 패턴**: `Nodes/HUDNode.swift`(SKNode 컨테이너 + 자식 SKLabelNode)와 `Nodes/AirplaneNode.swift`(SKAction.sequence 자가 소멸)
- **핵심 코드 구조**:

```swift
//
//  AirforceOverlayNode.swift
//  GanhoMusic Shared
//
//  Phase 4-4 · AIRFORCE 오버레이 — "나와라 박병장!" 텍스트 + 자가 페이드아웃
//

import SpriteKit

/// AIRFORCE 이스터에그 호출 텍스트 오버레이. PhysicsBody 부착 0 — 순수 시각.
/// 자식 SKLabelNode 1개("나와라 박병장!") 컨테이너.
/// init에서 색·폰트·정렬·zPosition만 부여하고, 외부 호출자가 showAndDismiss()를
/// 부르는 시점에 SKAction.sequence([wait, fadeOut, removeFromParent])로 자가 소멸.
/// AirplaneNode 패턴 답습 — fire-and-forget.
final class AirforceOverlayNode: SKNode {

    // MARK: - Properties
    private let label: SKLabelNode

    // MARK: - Init
    override init() {
        label = SKLabelNode(text: "나와라 박병장!")
        super.init()
        name = "airforceOverlay"
        // HUD(100) 위 — 이스터에그 강조. AirplaneNode(50)보다도 위. 1.8초만 존재.
        zPosition = 200
        configureLabel()
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Show / Dismiss
    /// 부모(cameraNode)에 addChild 직후 호출. 1.5초 대기 → 0.3초 페이드아웃 → 자가 제거.
    /// self 미사용 — [weak self] 캡처 불필요.
    func showAndDismiss() {
        let wait    = SKAction.wait(forDuration: GameConfig.airforceOverlayDisplayDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.airforceOverlayFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, fadeOut, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — 색은 비행기와 통일(.ganhoYellowF), 중앙 정렬.
    /// cameraNode 자식 (0,0) = 화면 중앙. label position도 (0,0)으로 두면 화면 정중앙.
    private func configureLabel() {
        label.fontSize = GameConfig.airforceOverlayFontSize
        label.fontColor = .ganhoYellowF
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
```

**주의**:
- `label`을 `let` 프로퍼티로 보유하되 외부 노출 0(private).
- `position = .zero`(라벨 자체) — 부모(`AirforceOverlayNode`) 자체 position은 호출자가 0으로 두므로 화면 정중앙(`cameraNode` 자식 (0,0) = 화면 중앙).
- `name = "airforceOverlay"`는 디버깅 편의.
- 폰트 패밀리 지정 안 함(시스템 기본).

### 기능 2 — `GameConfig` 3상수 추가
- **설명**: 오버레이 폰트 크기·표시 시간·페이드아웃 시간 매직 넘버 제거.
- **구현 위치**: `Config/GameConfig.swift`, `// MARK: - Airforce Easter Egg (Phase 4-3)` 섹션 *내부 끝*. `airplaneTopOffset` 줄 다음에 추가. 새 MARK 신설 금지(기존 섹션에 합류).
- **추가 코드(정확한 형태)**:

```swift
    /// "나와라 박병장!" 오버레이 폰트 크기 (pt). HUD(18)보다 크고 화면 중앙 가독성 우선.
    static let airforceOverlayFontSize: CGFloat = 28
    /// "나와라 박병장!" 오버레이 표시 시간 (초). 페이드아웃 시작 전 또렷이 떠 있는 구간.
    static let airforceOverlayDisplayDuration: TimeInterval = 1.5
    /// "나와라 박병장!" 오버레이 페이드아웃 길이 (초). alpha 1 → 0 보간 시간.
    /// 총 수명 = displayDuration(1.5) + fadeOutDuration(0.3) = 1.8초.
    static let airforceOverlayFadeOutDuration: TimeInterval = 0.3
```

**금지**: airplane 4상수(`airplaneWidth`, `airplaneHeight`, `airplaneCrossDuration`, `airplaneTopOffset`) 값/이름 변경 금지.

### 기능 3 — `GameScene.swift` 본문 확장
- **설명**: (a) 헤더 MARK 1줄 추가, (b) `triggerAirforceEasterEgg()` 본문 *마지막*에 오버레이 3줄 추가. 기존 비행기 부분은 한 줄도 변경 금지.

**(a) 헤더 MARK 추가** — 기존 `//  Phase 4-3 · AIRFORCE 이스터에그 …` 라인 *바로 다음 줄*에:

```swift
//  Phase 4-4 · AIRFORCE 오버레이 — "나와라 박병장!" 텍스트 자가 페이드아웃
```

**(b) `triggerAirforceEasterEgg()` 본문 확장** — 기존 메서드의 *마지막* 비행기 부분 *뒤에* 오버레이 3줄을 추가. 비행기 부분은 *위에 두고* 오버레이는 *뒤에*. 가드 안쪽이어야 함.

수정 후 최종 형태:

```swift
    // MARK: - Easter Egg
    /// Player ↔ StoneGuard 첫 접촉 시 호출. 1회 한정 가드 후 비행기 1마리를 cameraNode에 부착,
    /// 좌→우 가로지르기 SKAction 실행. AirplaneNode가 자가 소멸하므로 GameScene은 후속 정리 0건.
    /// 점수/HUD/적/게임오버 로직 일체 미접촉 — 순수 시각 이스터에그.
    /// Phase 4-4 — 동일 가드 안쪽에 AirforceOverlayNode("나와라 박병장!") 동시 부착.
    /// 두 노드는 서로 모르며 각자 자기 SKAction으로 자가 소멸(fire-and-forget).
    private func triggerAirforceEasterEgg() {
        if airforceTriggered { return }
        airforceTriggered = true
        let plane = AirplaneNode()
        cameraNode.addChild(plane)
        let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
        plane.crossScreen(sceneWidth: size.width, atY: y)
        let overlay = AirforceOverlayNode()
        cameraNode.addChild(overlay)
        overlay.showAndDismiss()
    }
```

**금지**:
- 비행기 4줄(`AirplaneNode()` / `cameraNode.addChild(plane)` / `let y = ...` / `plane.crossScreen(...)`) 한 줄도 변경 금지.
- `airforceTriggered` 가드 위치 이동 금지.
- `cameraNode` 외 부착지 금지.
- 오버레이 위치 설정 코드 추가 금지.
- 메서드 분리 금지.

### 기능 4 — `project.pbxproj` 4곳 0019 등록
- **설명**: AirplaneNode(0018) 패턴을 정확히 답습한 0019 식별자로 신규 파일 등록.

**4-1. PBXBuildFile** (0018 다음에 1줄 추가):
```
		A1C0F1B00000000000000019 /* AirforceOverlayNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000019 /* AirforceOverlayNode.swift */; };
```

**4-2. PBXFileReference** (0018 다음에 1줄 추가):
```
		A1C0F1A00000000000000019 /* AirforceOverlayNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AirforceOverlayNode.swift; sourceTree = "<group>"; };
```

**4-3. Nodes 그룹 children** (AirplaneNode 다음 1줄 추가):
```
				A1C0F1A00000000000000019 /* AirforceOverlayNode.swift */,
```

**4-4. iOS Sources phase** (AirplaneNode 다음 1줄 추가):
```
				A1C0F1B00000000000000019 /* AirforceOverlayNode.swift in Sources */,
```

**금지**:
- tvOS / macOS Sources phase 수정 금지
- 0019 외 식별자 사용 금지
- `path` 디렉터리 포함 금지 (AirplaneNode와 동일하게 상대 파일명만)

## 검증 시나리오 (a)~(i)

| # | 시나리오 | 봐야 할 것 | 정적 검증 방법 |
|---|---|---|---|
| (a) | 게임 시작, 석조무사 미접촉 | 오버레이 0건 | `triggerAirforceEasterEgg()` 호출 경로가 `onStoneGuardContact` 콜백뿐 |
| (b) | Player가 석조무사 첫 통과 | 화면 정중앙 노란 "나와라 박병장!" + 비행기 동시 등장 | `triggerAirforceEasterEgg()` 본문에 `AirforceOverlayNode()` / `cameraNode.addChild(overlay)` / `overlay.showAndDismiss()` 3줄 존재 |
| (c) | ~1.5초 후 | 오버레이 페이드아웃 시작 | `showAndDismiss()` 시퀀스 정확: `wait(1.5) → fadeOut(0.3) → removeFromParent()` |
| (d) | ~1.8초 후 | 오버레이 완전 사라짐 | `airforceOverlayDisplayDuration + airforceOverlayFadeOutDuration == 1.8` |
| (e) | 재통과 시 | 오버레이·비행기 모두 0 | `airforceTriggered` 가드 진입부 그대로 |
| (f) | 점수·HUD | 영향 0 | `update()` / `endGame()` / `scoreSystem` / `hud` 한 줄도 변경 없음 |
| (g) | D-Pad | 정상 입력 | `dpad` / `player.currentDirection` / `player.update` 변경 없음 |
| (h) | 게임오버 잔존 | ResultScene 전환 시 ARC 자동 해제 | `endGame()` 변경 없음 — `cameraNode` 자식 overlay도 함께 해제 |
| (i) | pbxproj 정합성 | 빌드 SUCCEEDED + 경고 0 | 4곳 식별자가 모두 정확히 1회 등장. tvOS/macOS 0019 0건 |

## 학습 가치 (Spring 비유)

| 학습 항목 | 한 줄 설명 | Spring 비유 |
|---|---|---|
| 자가 소멸 노드 패턴 2회차 | AirplaneNode `[move, removeFromParent]` → AirforceOverlayNode `[wait, fadeOut, removeFromParent]`. 두 번 반복 = 인식 단계 | 같은 fire-and-forget 패턴 두 서비스 등장 |
| `SKLabelNode` 중앙 정렬 | `.center` 정렬로 화면 정중앙 anchor | `text-align: center` |
| `SKAction.wait + fadeOut + removeFromParent` | 3단 시퀀스 토스트 패턴 표준 | 토스트 라이브러리 duration + fadeOut |
| 호출 측 변경 0 패턴 3 sprint 연속 | ContactRouter / PhysicsCategory / StoneGuardNode 0줄 | `@EventListener` 신규 리스너 추가만 |
| `triggerAirforceEasterEgg` 본문 *확장* | 단일 이스터에그 응집. 메서드 분리 X | 한 도메인 이벤트 = 한 핸들러 |
| `zPosition = 200` | HUD(100) 위 — 1.8초만 존재 | CSS z-index 토스트 |
| 색 토큰 재사용 (`.ganhoYellowF`) | 비행기와 통일 | brand color token 재사용 |

## 주의사항

### 코드 패턴
- **강제 언래핑 금지**: 모든 프로퍼티 non-optional.
- **매직 넘버 금지**: 폰트 크기 28 / 표시 1.5 / 페이드 0.3은 모두 GameConfig 상수.
- **`[weak self]` 캡처 불필요**: showAndDismiss self 미참조.
- **Timer 금지**: SKAction.wait 사용.

### SpriteKit
- **PhysicsBody 부착 0**: 충돌 없음.
- **부착지**: 반드시 `cameraNode.addChild(overlay)`. worldNode/self/hud 금지.
- **zPosition = 200**: HUD(100) 위.
- **노드 순서**: 비행기 *먼저*, 오버레이 *뒤에*. 실행은 동시.

### 빌드 / pbxproj
- **0019 식별자**: 4곳 정확. AirplaneNode 0018 패턴 답습.
- **tvOS/macOS**: 그대로 유지.
- **path 상대성**: `AirforceOverlayNode.swift`(디렉터리 미포함).

### 텍스트 정확성
- **"나와라 박병장!"** — 띄어쓰기 1회, 느낌표 1개. 변형 금지.

### 가드 정합성
- `airforceTriggered` 가드는 *비행기 + 오버레이 둘 다*를 막아야 함. 가드 → 플래그 → 비행기 → 오버레이 순.

### 메서드 doc 코멘트
- 기존 doc 3줄 그대로 유지. 4-4 동작 설명 2줄 *추가*.
