# Phase 4-5 (D) — AIRFORCE 폭탄 화면 플래시

## 개요
AIRFORCE 이스터에그 시퀀스의 *세 번째 단계*. 오버레이가 사라진 0.3초 뒤(trigger 후 2.1s), 화면 전체가 0.42초 동안 누런 섬광(`.ganhoPaper`)으로 *번쩍* 한 뒤 자가 소멸. 게임 로직은 변하지 않으며 *순수 시각 임팩트*만 추가한다.

## 변경 유형
**혼합** — 신규 노드(`BombFlashNode`) + 비주얼 효과(풀스크린 사각형 + fadeIn/fadeOut) + `GameScene.triggerAirforceEasterEgg()` 본문 확장(3줄).

## 게임 경험 의도
오버레이("나와라 박병장!")가 사라진 0.3초 뒤, 화면 전체가 누런 섬광으로 *번쩍* 했다가 0.35초에 걸쳐 잔상처럼 사라진다. AIRFORCE 시퀀스(비행기→오버레이→**폭탄**)의 *클라이맥스 시각 임팩트*. 게임 진행(player/적/F/점수/HUD)은 정상 진행되며 시각 효과만 추가된다.

## Sprint 범위 계약

### In Scope (모두 필수)
1. **새 파일** `GanhoMusic Shared/Nodes/BombFlashNode.swift` (~50줄)
2. **수정** `Config/GameConfig.swift` — Airforce Easter Egg 섹션 *내부 끝*에 3상수 추가
3. **수정** `GameScene.swift` — 헤더 MARK 1줄 + `triggerAirforceEasterEgg()` 본문 끝에 폭탄 3줄 + doc 코멘트 1줄
4. **수정** `project.pbxproj` — 식별자 0020로 4곳 등록

### Out of Scope (모두 금지, 위반 시 P0)
- `AirplaneNode` / `AirforceOverlayNode` 한 줄도 변경 금지
- `ContactRouter` / `PhysicsCategory` / `StoneGuardNode` / `GameScene+Setup` 변경 금지
- 기존 `GameConfig` 상수(airplane 4 + airforceOverlay 3 + 그 외) 변경 금지
- 다른 노드(Enemy/Player/Note/Projectile/HUD/DPad) 변경 금지
- `TitleScene` / `ResultScene` 변경 금지
- `ColorTokens` 새 토큰 신설 금지 (기존 `.ganhoPaper` 재사용)
- `update()` / `endGame()` / `airforceTriggered` 가드 위치 변경 금지
- 수간호사 도주 / F 재스폰 효과 추가 금지 (다음 sprint 4-6, 4-7)
- 사운드 / 햅틱 / 진동 / 게임 일시정지 / `gameState` 변경 금지
- `BombFlashNode`에 `PhysicsBody` 부착 금지
- macOS / tvOS Sources phase 수정 금지
- Test 코드 추가 금지
- 자가 소멸 노드 패턴 *protocol 추출* 금지 (별도 리팩터 sprint로)

### 판단 기준
"이 변경이 없으면 'Player가 StoneGuard 첫 통과 시 트리거 후 2.1s 뒤 화면 전체가 0.42초간 누런 섬광' 동작이 되는가?" → **NO**만 In Scope.

## 변경 범위

### 수정할 파일
- `GanhoMusic Shared/Config/GameConfig.swift` — Airforce 섹션 끝에 +3 상수
- `GanhoMusic Shared/GameScene.swift` — 헤더 MARK 1줄 + doc 1줄 + 트리거 본문 끝 3줄
- `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` — 4곳 (식별자 `0020`)

### 추가할 파일
- `GanhoMusic Shared/Nodes/BombFlashNode.swift`

## 기능 상세

### 기능 1: `BombFlashNode` 클래스
- **설명**: 화면 전체를 덮는 누런 섬광 사각형. 외부에서 `flash(sceneSize:)` 호출 시 4단 SKAction 시퀀스로 자가 소멸.
- **구현 위치**: 신규 파일 `GanhoMusic Shared/Nodes/BombFlashNode.swift`
- **참고 패턴**: `AirforceOverlayNode`(0019) / `AirplaneNode`(0018) — init에서 시각 속성만 부여, 외부 호출자가 메서드 호출 시점에 SKAction 시작.

- **핵심 코드 구조**:
```swift
//
//  BombFlashNode.swift
//  GanhoMusic Shared
//
//  Phase 4-5 · AIRFORCE 폭탄 화면 플래시 — 누런 섬광 + 자가 소멸
//

import SpriteKit

/// AIRFORCE 이스터에그 폭탄 화면 플래시. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·zPosition·name·alpha=0만 부여하고, scene.size 의존인
/// size·position·SKAction은 외부 호출자가 flash(sceneSize:) 부르는 시점에 시작한다.
/// SKAction.sequence([wait, fadeIn, fadeOut, removeFromParent])로 자가 소멸(fire-and-forget).
/// AirplaneNode / AirforceOverlayNode 패턴 답습 — 자가 소멸 노드 3회차.
final class BombFlashNode: SKSpriteNode {

    // MARK: - Init
    init() {
        super.init(texture: nil, color: .ganhoPaper, size: .zero)
        name = "bombFlash"
        zPosition = 250
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flash
    /// 부모(cameraNode)에 addChild 직후 호출. scene.size로 풀스크린 크기 부여 →
    /// wait(2.1) → fadeIn(0.07) → fadeOut(0.35) → 자가 제거.
    /// self 미사용 — [weak self] 캡처 불필요.
    func flash(sceneSize: CGSize) {
        size = sceneSize
        position = .zero
        let wait    = SKAction.wait(forDuration: GameConfig.bombFlashDelay)
        let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.bombFlashFadeInDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.bombFlashFadeOutDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([wait, fadeIn, fadeOut, cleanup]))
    }
}
```

### 기능 2: `GameConfig.swift` Airforce 섹션 +3 상수
- **설명**: 폭탄 플래시 타이밍 3상수. alpha는 fadeIn이 자동으로 0→1 보간하므로 별도 상수 불필요.
- **구현 위치**: `airforceOverlayFadeOutDuration` 다음 줄.
- **삽입 코드**:
```swift
    /// 폭탄 화면 플래시 시작 지연 (초). 오버레이 닫힘(1.5+0.3=1.8) + 300ms = 2.1.
    /// trigger 시점 t=0 기준. 수동 검증: airforceOverlayDisplayDuration + airforceOverlayFadeOutDuration + 0.3.
    static let bombFlashDelay: TimeInterval = 2.1
    /// 폭탄 화면 플래시 fadeIn 길이 (초). alpha 0 → 1 빠른 보간 — *번쩍* 임팩트.
    static let bombFlashFadeInDuration: TimeInterval = 0.07
    /// 폭탄 화면 플래시 fadeOut 길이 (초). alpha 1 → 0 느린 보간 — *잔상* 효과.
    /// 총 표시 길이 = fadeIn(0.07) + fadeOut(0.35) = 0.42초.
    static let bombFlashFadeOutDuration: TimeInterval = 0.35
```

### 기능 3: `GameScene.swift` 헤더 MARK + 트리거 본문 확장
- **설명**: 헤더 1줄 + doc 1줄 + 본문 끝 3줄. 기존 비행기 4줄·오버레이 3줄은 한 줄도 변경 금지.

- **헤더 MARK 추가** (`Phase 4-4` 라인 다음 줄):
```swift
//  Phase 4-5 · AIRFORCE 폭탄 화면 플래시 — 오버레이 닫힘 후 300ms → 420ms 섬광
```

- **doc 코멘트 1줄 추가** (`Phase 4-4` doc 줄 다음):
```swift
    /// Phase 4-5 — 동일 가드 안쪽에 BombFlashNode 폭탄 플래시도 동시 발화, 자가 소멸.
```

- **본문 확장** — `overlay.showAndDismiss()` 다음 줄에 3줄 추가:
```swift
        let bomb = BombFlashNode()
        cameraNode.addChild(bomb)
        bomb.flash(sceneSize: size)
```

- **최종 모습**:
```swift
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
    let bomb = BombFlashNode()
    cameraNode.addChild(bomb)
    bomb.flash(sceneSize: size)
}
```

### 기능 4: `project.pbxproj` 4곳 등록 (식별자 `0020`)
- **설명**: `AirforceOverlayNode` (0019) 패턴 정확 답습. iOS Sources phase에만 등록.

- **위치 1 — PBXBuildFile** (0019 다음):
```
		A1C0F1B00000000000000020 /* BombFlashNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000020 /* BombFlashNode.swift */; };
```

- **위치 2 — PBXFileReference** (0019 다음):
```
		A1C0F1A00000000000000020 /* BombFlashNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BombFlashNode.swift; sourceTree = "<group>"; };
```

- **위치 3 — Nodes 그룹 children** (AirforceOverlayNode 다음):
```
				A1C0F1A00000000000000020 /* BombFlashNode.swift */,
```

- **위치 4 — iOS Sources phase** (AirforceOverlayNode 다음):
```
				A1C0F1B00000000000000020 /* BombFlashNode.swift in Sources */,
```

## 검증 시나리오 (a)~(i) — 정적 검증

| # | 시나리오 | 정적 검증 방법 |
|---|---|---|
| (a) | 미접촉 시 폭탄 0 | `BombFlashNode()` 호출이 `triggerAirforceEasterEgg()` 1곳뿐 |
| (b) | trigger 시 폭탄 3줄 존재 | 본문 끝 3줄(`BombFlashNode()`/`cameraNode.addChild(bomb)`/`bomb.flash(sceneSize: size)`) |
| (c) | ~1.8s 시점 폭탄 미등장 | `wait(forDuration: bombFlashDelay)` 첫 액션, `bombFlashDelay = 2.1` 확인 |
| (d) | ~2.1s 시점 fadeIn 시작 | sequence `[wait, fadeIn, fadeOut, cleanup]` 순서 정확 |
| (e) | ~2.5s 시점 removeFromParent | sequence 마지막 단계가 `removeFromParent()` |
| (f) | 게임 변경 0 | `update()` / `endGame()` / `gameState` 미변경 |
| (g) | AI 변경 0 | `Player` / `Enemy` / `Projectile` / `EnemyNode` / `SpawnSystem` 미변경 |
| (h) | 재통과 시 0 | `airforceTriggered` 가드 그대로 |
| (i) | 빌드 SUCCEEDED + 경고 0 | pbxproj 4곳 0020 등록 일관, 컴파일 에러/경고 0 |

## 학습 가치
- `SKAction.fadeIn(withDuration:)` 첫 도입 (fadeOut의 정확한 반대)
- 풀스크린 사각형 + `scene.size` 의존 노드 — init/메서드 책임 분리 (AirplaneNode 패턴 답습)
- **자가 소멸 노드 패턴 3회차** — Rule of three 도달 (`protocol SelfDismissingNode` 추출 *후보 인식*만, 추출은 별도 sprint)
- 비대칭 fadeIn/fadeOut (0.07s vs 0.35s) — *번쩍 + 잔상* 시각 곡선
- **호출 측 변경 0 정책 4 sprint 연속** (4-2, 4-3, 4-4, 4-5)

## 주의사항
- **alpha = 0 초기화 필수**: 없으면 fadeIn 첫 프레임에 alpha=1로 즉시 가시 → "번쩍" 효과 사라짐
- **size .zero init**: SKSpriteNode super.init에 `size: .zero` 전달. flash 메서드가 sceneSize로 갱신
- **`cameraNode.addChild(bomb)` 정확**: worldNode/self/hud 금지
- **`zPosition = 250`**: HUD(100), AirforceOverlay(200) 위
- **`[weak self]` 캡처 불필요**: flash self 미사용
- **`bombFlashDelay = 2.1` 합산 검증**: 1.5 + 0.3 + 0.3 = 2.1
- **`.ganhoPaper` 재사용**: ColorTokens 새 토큰 신설 금지
- **pbxproj `0020` 4곳 일관성**: PBXBuildFile은 `A1C0F1B0...0020`, PBXFileReference는 `A1C0F1A0...0020`
- **macOS / tvOS Sources phase 미변경**
- **기존 7줄(가드 2 + 비행기 4 + 오버레이 3) 한 줄도 변경 금지**: 폭탄 3줄은 *추가만*
