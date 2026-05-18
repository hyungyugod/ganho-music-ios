# Phase 8-2 — 수간호사 픽셀 아트 이식

## 개요
원본 웹 게임(game.js L819-892)의 수간호사 픽셀 데이터 + 팔레트(13색)를 Swift로 byte-equal 이식. EnemyNode가 단색 사각형 → 백발 안경 픽셀 아트로 전환. 4방향 + 걷기 프레임 지원. throwArm(F 투척 모션)은 *본 sprint 범위 외* (다음 sprint).

## 변경 유형
**비주얼**

## Sprint 범위 계약

### 허용
1. `Models/PixelSprite.swift` 확장 — `nurseChiefData(direction:frame:)` 정적 메서드 추가 + base + up/left/right 분기 + step1/step2 프레임 분기
2. `Models/PixelPalette.swift` 확장 — `chiefPalette` 정적 dict 추가 (13키)
3. `Config/ColorTokens.swift` 확장 — 수간호사 색 13개 추가
4. `Nodes/EnemyNode.swift` 수정 — SKSpriteNode color → texture 모드. updatePixelDirection / tickWalkFrame 메서드 추가 (PlayerNode 동형). update에서 자기 velocity 기반 자동 갱신.

### 금지
1. throwArm F 투척 모션 — 다음 sprint
2. StoneGuard 픽셀 — 다음 sprint
3. 음표 / F / 카드 아바타 픽셀 — 다음 sprint
4. PlayerNode 변경 — 회귀 0
5. PixelSpriteRenderer 변경 — Phase 8-1에서 만든 인프라 그대로 사용
6. Game 로직 (적 추적/속도/충돌) 변경 — physicsBody 정책 보존

### 판단 기준
"이 변경 없으면 수간호사가 픽셀 아트로 안 보이는가?" → YES만 허용.

## 변경 범위

### 수정
- `Models/PixelSprite.swift` — 정적 메서드 + base 데이터 추가 (game.js L819-891)
- `Models/PixelPalette.swift` — `chiefPalette` static let 추가
- `Config/ColorTokens.swift` — `ganhoPixelChief*` 13색 추가
- `Nodes/EnemyNode.swift` — texture 모드 전환 + 픽셀 갱신 메서드
- `GameScene.swift` — update에서 enemy 픽셀 갱신 호출 추가 (PlayerNode 패턴 답습)

### 신규 파일 0개, pbxproj 변경 0건.

---

## 기능 1: PixelSprite.nurseChiefData

```swift
extension PixelSprite {
    /// 수간호사 픽셀 데이터. game.js L819-891 byte-equal.
    /// throwArm은 다음 sprint — 본 sprint는 idle/walk만.
    static func nurseChiefData(direction: PixelDirection, frame: PixelFrame) -> Frame {
        var base: Frame = [
            "................", // 0
            "....KKKKKKKK....", // 1 캡 상단
            "...KKKKXXKKKK...", // 2 캡 + 코럴 십자
            "..KkkkkkkkkkkK..", // 3 캡 밑단 음영
            "..HHSSSSSSSSHH..", // 4 이마 + 백발 옆선
            "..HhSSSSSSSShH..", // 5 백발 음영
            "..hSGGSSSSGGSh..", // 6 안경테
            "..hSGgSSSSgGSh..", // 7 안경 렌즈
            "..hSSNSSSSNSSh..", // 8 눈 밑 주름
            "..hSSSSMMSSSSh..", // 9 입
            "..hhSSNNNNSSHh..", // 10 팔자 + 턱선
            "...UUUUUUUUUU...", // 11 흰 간호사복 어깨
            "..UUUUVCCVUUUU..", // 12 옷깃 + 코럴 십자
            "..UUVVVVVVVVUU..", // 13 상의 음영
            "...UUUUUUUUUU...", // 14 상의 밑단
            "....UUUUUUUU....", // 15 하의
            "....UUU..UUU....", // 16
            "....UUU..UUU....", // 17
            "....BB....BB....", // 18 구두
            "....BB....BB...."  // 19
        ]
        switch direction {
        case .up:
            // game.js L844-852 — 캡 행 1-3 유지, 얼굴 4-10 백발 덮음
            base[4] = "..HHHHHHHHHHHH.."
            base[5] = "..HhHHHHHHHHhH.."
            base[6] = "..hHHHHHHHHHHh.."
            base[7] = "..hHHHHHHHHHHh.."
            base[8] = "..hHHHHHHHHHHh.."
            base[9] = "..hHHHHHHHHHHh.."
            base[10] = "..hhHHHHHHHHHh.."
        case .left:
            // game.js L853-858
            base[6] = "..hSSSSSSSGGSh.."
            base[7] = "..hSSSSSSSgGSh.."
            base[8] = "..hSSSSSSSNSSh.."
            base[9] = "..hSSSSMMSSSSh.."
            base[10] = "..hhSSNNNNSSHh.."
        case .right:
            // game.js L859-864
            base[6] = "..hSGGSSSSSSSh.."
            base[7] = "..hSGgSSSSSSSh.."
            base[8] = "..hSSNSSSSSSSh.."
            base[9] = "..hSSSSMMSSSSh.."
            base[10] = "..hhSSNNNNSSHh.."
        case .down: break
        }
        switch frame {
        case .step1:
            base[18] = "....BB...BBB...."
            base[19] = "....BBB...BB...."
        case .step2:
            base[18] = "....BBB...BB...."
            base[19] = "....BB...BBB...."
        case .idle: break
        }
        return base
    }
}
```

## 기능 2: PixelPalette.chiefPalette

```swift
extension PixelPalette {
    /// 수간호사 팔레트 13색. game.js L905-919 1:1.
    static let chiefPalette: [Character: UIColor] = [
        "S": .ganhoPixelChiefSkin,        // #f5d5c0
        "N": .ganhoPixelChiefWrinkle,     // #c08878
        "H": .ganhoPixelChiefHair,        // #e8e4e8
        "h": .ganhoPixelChiefHairShadow,  // #c8c4cc
        "K": .ganhoPixelChiefCap,         // #ffffff
        "k": .ganhoPixelChiefCapShadow,   // #e6dde6
        "X": .ganhoPixelChiefCross,       // #ff7b7b
        "G": .ganhoPixelChiefGlass,       // #1f1a1f
        "g": .ganhoPixelChiefGlassLens,   // #e8c8b8
        "U": .ganhoPixelChiefUniform,     // #f4f0ee
        "V": .ganhoPixelChiefUniformShadow, // #d8d2d0
        "C": .ganhoPixelChiefAccent,      // #ff7b7b
        "B": .ganhoPixelChiefShoes,       // #1a1214
        "M": .ganhoPixelChiefMouth        // #6b3a3a
    ]
}
```

## 기능 3: ColorTokens 13색 신설

`Config/ColorTokens.swift`에 `// MARK: - Chief Palette (Phase 8-2)` 섹션 + 13개 hex:

```swift
static let ganhoPixelChiefSkin = UIColor(hex: "#f5d5c0")
static let ganhoPixelChiefWrinkle = UIColor(hex: "#c08878")
static let ganhoPixelChiefHair = UIColor(hex: "#e8e4e8")
static let ganhoPixelChiefHairShadow = UIColor(hex: "#c8c4cc")
static let ganhoPixelChiefCap = UIColor(hex: "#ffffff")
static let ganhoPixelChiefCapShadow = UIColor(hex: "#e6dde6")
static let ganhoPixelChiefCross = UIColor(hex: "#ff7b7b")
static let ganhoPixelChiefGlass = UIColor(hex: "#1f1a1f")
static let ganhoPixelChiefGlassLens = UIColor(hex: "#e8c8b8")
static let ganhoPixelChiefUniform = UIColor(hex: "#f4f0ee")
static let ganhoPixelChiefUniformShadow = UIColor(hex: "#d8d2d0")
static let ganhoPixelChiefAccent = UIColor(hex: "#ff7b7b")
static let ganhoPixelChiefShoes = UIColor(hex: "#1a1214")
static let ganhoPixelChiefMouth = UIColor(hex: "#6b3a3a")
```

## 기능 4: EnemyNode 픽셀 모드 전환

```swift
final class EnemyNode: SKSpriteNode {
    private var pixelDirection: PixelDirection = .down
    private var pixelFrame: PixelFrame = .idle
    private var frameAccumulator: TimeInterval = 0

    override init() {
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: .down, frame: .idle),
            palette: PixelPalette.chiefPalette
        )
        super.init(texture: texture, color: .clear,
                   size: CGSize(width: 16 * GameConfig.pixelSpriteScale,
                                height: 20 * GameConfig.pixelSpriteScale))
        // 기존 physicsBody / collision / contact 정책 그대로
    }

    func updatePixelDirection(_ velocity: CGVector) {
        let newDir: PixelDirection
        if abs(velocity.dx) > abs(velocity.dy) {
            newDir = velocity.dx >= 0 ? .right : .left
        } else if abs(velocity.dy) > 0.1 {
            newDir = velocity.dy >= 0 ? .up : .down
        } else {
            return
        }
        if newDir != pixelDirection {
            pixelDirection = newDir
            refreshTexture()
        }
    }

    func tickWalkFrame(deltaTime: TimeInterval, isMoving: Bool) {
        guard isMoving else {
            if pixelFrame != .idle {
                pixelFrame = .idle
                refreshTexture()
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

    private func refreshTexture() {
        texture = PixelSpriteRenderer.texture(
            from: PixelSprite.nurseChiefData(direction: pixelDirection,
                                              frame: pixelFrame),
            palette: PixelPalette.chiefPalette
        )
    }
}
```

## 기능 5: GameScene.update enemy 픽셀 갱신 호출

PlayerNode 패턴 답습. update의 `.playing` 가드 안 enemy 처리 직후:

```swift
let enemyVelocity = enemy.physicsBody?.velocity ?? .zero
enemy.updatePixelDirection(CGVector(dx: enemyVelocity.dx, dy: enemyVelocity.dy))
enemy.tickWalkFrame(deltaTime: dt, isMoving: enemyVelocity.length > 1.0)
```

또는 PlayerNode가 자기 처리하듯 EnemyNode가 자기 update 메서드 안에서 처리. 어느 방식이든 GameScene 변경 최소화 우선.

## 회귀 0 자연 차단

1. **EnemyNode init 시그니처 호환** — 외부 호출 변경 0
2. **physicsBody / collision / contact 정책 보존** — 게임 로직 0 영향
3. **PlayerNode / StoneGuard 미접촉** — 본 sprint 범위는 EnemyNode만
4. **PixelSpriteRenderer 그대로** — Phase 8-1 인프라 재사용
5. **GameConfig pixelSpriteScale / pixelWalkFrameInterval 재사용** — 신규 상수 0
6. **throwArm 미구현** — F 투척 신호 인터페이스 도입 0건 (다음 sprint)

## 주의사항

1. **수간호사 hitbox** — PlayerNode와 마찬가지로 *시각 32×40* 이지만 *physicsBody 그대로 유지*. 적 충돌 판정 변경 0.
2. **EnemyNode init 시그니처** — 현재 어떻게 호출되는지 확인. 보통 setupEnemy() 안. 시그니처 호환.
3. **byte-equal 검증** — game.js L820-841 (base 20행), L844-864 (방향 3분기 17행), L867-873 (프레임 분기 4행). 한 문자라도 어긋나면 픽셀 깨짐.
4. **chiefPalette `#ffffff` 두 키** — K(캡)과 game.js의 'L'(흰자) 충돌 없음 — 수간호사는 'L' 미사용. 깔끔.
5. **velocity length 계산** — CGVector에 length 확장 있는지 확인. 없으면 `sqrt(dx² + dy²)` 또는 단순 abs 비교.
6. **EnemyNode가 자기 update 처리** — GameScene 변경 최소화 측면에서 권장. PlayerNode와 동일 패턴.
