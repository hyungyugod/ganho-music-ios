# Sprint 7 Phase G — 플레이어 4방향 스프라이트 + Direction 입력 layer

## 개요
인게임 PlayerNode가 D-Pad 입력 시 캐릭터 얼굴이 해당 방향(앞·뒤·좌·우)을 바라보도록. 신규 `Direction` enum과 `PlayerNode.facing(_:)` API 도입, DPadNode가 매 입력 갱신 직후 호출하는 *명시적 layer*로 분리. 5캐릭터 × 4방향 SVG path는 신규 `CharacterFaceNode.init(id:facing:)` 분기에서 관리. 인게임 PlayerNode는 4 CharacterFaceNode child를 미리 부착 후 `isHidden` 토글만으로 즉시 전환. left = right 미러링(scaleX = -1).

## 변경 유형
**비주얼 + 신규 Direction enum + DPad 연동 1줄** — 게임 로직(velocity·position·hitbox·입력 매핑) 0줄 변경.

## 게임 경험 의도
D-Pad를 위/아래/좌/우로 누르면 캐릭터 얼굴이 즉시 그 방향을 바라본다. "내가 조종하는 김간호가 내 명령을 듣고 있다"는 확신. 정지 시 마지막 방향 유지로 갑자기 정면 보는 어색함 제거.

## Sprint 7 Phase G 범위 계약

### 허용
1. 신규 `Models/Direction.swift` — Direction enum 4 case + `init?(vector:)` 변환
2. PlayerNode 4방향 child 미리 부착 + `facing(_:)` 메서드 + lastFacing 상태
3. CharacterFaceNode 신규 `init(id:facing:)` + 5×3 build helper (back + side)
4. DPadNode `onDirectionChanged` 클로저 + `updateDirection(forTouchLocation:)` 끝 1줄 호출
5. GameScene+Setup `setupDPad()` 콜백 등록 1줄
6. GameConfig 신규 상수 2개 (face child scale·zPos)
7. mockup 후반부 5×4 그리드 추가 (HTML 한 파일에 Phase F 전반부 + Phase G 후반부)

### 금지 (0줄)
1. PlayerNode 이동 로직 (update의 velocity·position 계산, currentDirection/speedMultiplier/baseSpeedStart byte-identical)
2. DPad 입력 매핑 변경 (updateDirection 본문 알고리즘 그대로, 끝 1줄만 추가)
3. hitbox/physicsBody 좌표·크기
4. PixelSprite texture 시스템 (loadTexture/refreshTexture/updatePixelDirection/tickWalkFrame 그대로)
5. CharacterFaceNode 기존 5 build (buildKimFace ~ buildLeeFace 본문 0건)
6. CharacterFaceNode.mini factory 정면 그대로 (ScoreboardScene 32px 회귀 0)
7. CharacterSelectScene/DifficultySelectScene/SkillExplanationScene/ResultScene/ScoreboardScene (Phase A~F 결과물 0줄)
8. GameState/PhysicsCategory/Managers/Repositories/Systems/다른 Scenes 0줄
9. 게임 로직 일체

## 변경 범위

### 수정 파일
- `Nodes/PlayerNode.swift` — 4 child face dict + `facing(_:)` + lastFacing + buildFacingChildren
- `Nodes/CharacterFaceNode.swift` — `init(id:facing:)` 분기 + `convenience init(id:)` delegation + buildBackFace + buildSideFace + 10 helper
- `Nodes/DPadNode.swift` — `onDirectionChanged` 클로저 + 1줄 호출
- `GameScene+Setup.swift` — `setupDPad()` 콜백 등록 1줄
- `Config/GameConfig.swift` — 상수 2개 (playerFaceChildScale=0.5, playerFaceChildZPosition=1)
- `mockups/villains-and-player-directions-v1.html` — 후반부 grid 20셀 추가

### 추가 파일
- `Models/Direction.swift` — Direction enum + init?(vector:)

## 기능 상세

### 기능 1: Direction enum 신규

`Models/Direction.swift`:
```swift
import CoreGraphics

/// 4방향 입력 의도. PlayerNode.facing(_:)이 받아 시각 child 토글.
/// PixelDirection(texture 갱신용)과 분리 — Direction은 입력 layer.
enum Direction: String {
    case front, back, left, right

    /// DPad currentDirection(단위 벡터)을 Direction으로 변환.
    /// dx > 0 → .right / dx < 0 → .left
    /// dy > 0 → .back (SK +y = 위) / dy < 0 → .front (SK -y = 아래)
    /// .zero → nil (호출자가 유지 처리)
    /// |dx| ≥ |dy| 우선 좌우 분기.
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

### 기능 2: PlayerNode.facing — 4 child isHidden 토글

```swift
// MARK: - Properties — Facing (Sprint 7 Phase G 신규)
private var faceNodes: [Direction: CharacterFaceNode] = [:]
private var lastFacing: Direction = .front

// MARK: - Facing (Sprint 7 Phase G)
func facing(_ direction: Direction) {
    if direction == lastFacing { return }
    lastFacing = direction
    for (dir, node) in faceNodes {
        node.isHidden = (dir != direction)
    }
}

// apply(_ characterID:) 본문 끝에 1줄 추가:
//   buildFacingChildren(for: characterID)

private func buildFacingChildren(for characterID: CharacterID) {
    // 이전 child 정리 — 캐릭터 전환 안전
    for (_, node) in faceNodes { node.removeFromParent() }
    faceNodes.removeAll()

    let scale = GameConfig.playerFaceChildScale  // 0.5
    for direction in [Direction.front, .back, .left, .right] {
        let face = CharacterFaceNode(id: characterID, facing: direction)
        face.setScale(scale)
        face.zPosition = GameConfig.playerFaceChildZPosition  // 1
        face.isHidden = (direction != lastFacing)
        addChild(face)
        faceNodes[direction] = face
    }
    // PixelSprite texture는 alpha 0으로 가리고 face child가 주 시각
    // (OQ-2 권장안 채택)
    self.alpha = 0  // ← PlayerNode 자체 texture alpha
    // 단 4 face child는 alpha 0이 부모에 곱해지므로 alpha 0이 됨
    // → 다른 패턴 필요. self.colorBlendFactor + color = .clear 사용 또는
    //    self.texture를 nil로 설정. Generator 판단.
}
```

> **중요**: PlayerNode self.alpha = 0은 child 모두 안 보이게 됨. 올바른 방법은 `self.texture = nil` 또는 `self.color = .clear` + `self.colorBlendFactor = 1`. Generator가 코드에서 안전한 방법 결정. 만약 시각 회귀 위험 크면 face child를 alpha 0.5로 텍스처 위에 살짝 얹는 (b) 대안 채택.

### 기능 3: CharacterFaceNode 4방향 분기

```swift
// 신규 init — 5×4 분기. 기존 본문 0건 변경.
init(id: CharacterID, facing: Direction) {
    super.init()
    name = "characterFace_\(id.rawValue)_\(facing.rawValue)"
    switch (id, facing) {
    case (_, .front):
        // 기존 build 호출 — front는 완전 재사용 (회귀 0)
        switch id {
        case .kim:  buildKimFace()
        case .jung: buildJungFace()
        case .geon: buildGeonFace()
        case .im:   buildImFace()
        case .lee:  buildLeeFace()
        }
    case (let id, .back):
        buildBackFace(id: id)
    case (let id, .left):
        buildSideFace(id: id)
    case (let id, .right):
        buildSideFace(id: id)
        xScale = -1  // 미러링
    }
}

// 기존 init(id:) — convenience delegation으로 시그니처 보존
convenience init(id: CharacterID) {
    self.init(id: id, facing: .front)
}

// 신규 build — 최소 viable 시안 (몸통 공유 + 헤어/뒤통수 silhouette)
private func buildBackFace(id: CharacterID) {
    buildHeadBase()
    switch id {
    case .kim:  buildKimHairBack()
    case .jung: buildJungHairBack()
    case .geon: buildGeonHairBack()
    case .im:   buildImHairBack()
    case .lee:  buildLeeHairBack()
    }
}

private func buildSideFace(id: CharacterID) {
    buildHeadBase()
    switch id {
    case .kim:  buildKimSide()
    case .jung: buildJungSide()
    case .geon: buildGeonSide()
    case .im:   buildImSide()
    case .lee:  buildLeeSide()
    }
}

// build{Char}HairBack / build{Char}Side — 10 메서드 신규
// 각 메서드는 기존 build{Char}Face path 좌표 부분 차용 + 단순화
// back: 헤어 silhouette 1개 큰 path + 눈/입 없음
// side: 헤어 한쪽 + 눈 1개 (sign=-1)
// buildHeadBase: 공유 헬퍼 (5 build에서 공통 head ellipse) 또는 기존 패턴 답습
```

> `buildHeadBase()`가 기존 5 build에 분리되어 있지 않으면 Generator가 신규 작성. 또는 각 build{Char}{Back/Side}이 자체 head ellipse path를 그림(중복 OK, 시각 일관성 우선).

### 기능 4: DPadNode → Direction 콜백

```swift
// MARK: - Callbacks (Sprint 7 Phase G 신규)
var onDirectionChanged: ((Direction) -> Void)?

// updateDirection(forTouchLocation:) 끝에 1줄 추가:
if let dir = Direction(vector: currentDirection) {
    onDirectionChanged?(dir)
}
// .zero 입력 시 init?(vector:)가 nil 반환 → 자연 noop (정지 시 유지)
```

### 기능 5: GameScene+Setup 콜백 등록

```swift
func setupDPad() {
    cameraNode.addChild(dpad)
    // Sprint 7 Phase G — DPad 입력 방향 → PlayerNode.facing(_:) 위임
    dpad.onDirectionChanged = { [weak self] direction in
        self?.player.facing(direction)
    }
    layoutDPad()
}
```

### 기능 6: GameConfig 신규 상수

```swift
// MARK: - Player Facing (Sprint 7 Phase G)
/// PlayerNode 4 CharacterFaceNode child의 scale (0.5 = ±17pt 폭, player 가로 32pt와 근사).
static let playerFaceChildScale: CGFloat = 0.5
/// PlayerNode texture(zPos 0) 위 face child zPosition (작은 양수).
static let playerFaceChildZPosition: CGFloat = 1
```

### 기능 7: mockup 후반부 5×4 그리드

`mockups/villains-and-player-directions-v1.html`의 Phase G placeholder를 *실제 그리드*로 치환:
- 5행(캐릭터) × 4열(front/back/left/right) = 20 셀
- 각 셀 SVG viewBox=-50 -55 100 110 (CharacterFaceNode 동일)
- front: 기존 5 build 동일 path
- back: 헤어 silhouette + 눈 없음
- side: 헤어 한쪽 + 눈 1개 (left는 그대로, right는 transform scaleX(-1))
- 각 행 좌측에 캐릭터 약칭 + 색 chip

## 합격 기준 (SPRINT_7_REQUEST.md §8.5)

- D-pad 방향 입력 시 0.05s 안에 스프라이트 전환 (isHidden 동기 토글 → 다음 SK frame ~16ms)
- 4방향 시각 명확히 구분 (front vs back vs side)
- 정지 시 마지막 방향 유지 (.zero 입력 시 facing 미발화)
- PlayerNode hitbox/이동/스킬/DPad 입력 매핑 회귀 0

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
| Models/Direction.swift (신규) | ~30 |
| Nodes/PlayerNode.swift | ~50 |
| Nodes/CharacterFaceNode.swift | ~150 (10 helper) |
| Nodes/DPadNode.swift | ~10 |
| GameScene+Setup.swift | ~5 |
| Config/GameConfig.swift | ~10 |
| mockups/villains-and-player-directions-v1.html | ~80 (후반부 추가) |
| **합계** | **~335** (Swift ~255, SPRINT_7_REQUEST 예상 ~300) |

## OPEN_QUESTION

**OQ-1 (결정됨)**: 4방향 path 위치 — **CharacterFaceNode 확장** 채택. 신규 `init(id:facing:)` 분기 + 10 helper. 기존 5 build 본문 byte-identical. mini factory(.front) 회귀 0.

**OQ-2 (결정됨)**: PlayerNode texture vs face child 시각 충돌 — **PixelSprite texture를 alpha 0 또는 .clear color**로 가리고 face child가 주 시각. 단 Generator는 `self.alpha = 0`이 child에 곱해지지 않게 `self.texture = nil` 또는 `self.color = .clear; self.colorBlendFactor = 1` 패턴 채택. 시각 회귀 위험 시 대안: face child alpha 0.5로 텍스처 위 살짝 얹기.

**OQ-3 (결정됨)**: DPad 함수 — `updateDirection(forTouchLocation:)` 끝에 1줄 추가. touchesEnded/Cancelled의 `.zero` set은 콜백 미발화 (정지 시 유지). Direction.init?(vector:)가 .zero에서 nil 반환 → 자연 noop.

## 주의사항

1. 강제 언래핑 0 — Direction.init?(vector:)는 Optional, `if let` 패턴
2. 매직 넘버 0 — playerFaceChildScale / playerFaceChildZPosition GameConfig 외화
3. weak self 캡처 — onDirectionChanged 클로저
4. MARK 섹션 일관
5. left/right 미러링 — `xScale = -1`만, PlayerNode 자체 xScale은 건드림 0 (physicsBody 무관)
6. `lastFacing` 가드 — facing 매 프레임 호출 시 noop (비용 0)
7. CharacterFaceNode.convenience init(id:) — 기존 호출자 회귀 0
8. PixelDirection (down/up/left/right) vs Direction (front/back/left/right) — 타입 분리 안전
9. Models/Direction.swift Xcode pbxproj 등록 필요 (ScoreboardScene/SergeantParkNode 패턴 참고)
10. CharacterFaceNode 파일 ~300+ LOC 도달 시 후속 리팩터 후보 (이번 sprint는 단일 파일)

## 관련 파일 (절대 경로)

- 수정: `GanhoMusic/GanhoMusic Shared/Nodes/PlayerNode.swift`, `CharacterFaceNode.swift`, `DPadNode.swift`, `GameScene+Setup.swift`, `Config/GameConfig.swift`
- 신규: `Models/Direction.swift`, mockup 후반부 추가
- pbxproj: Models/Direction.swift 등록 (4줄)
