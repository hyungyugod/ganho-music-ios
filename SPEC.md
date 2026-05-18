# Phase 8-1 — 픽셀 아트 인프라 + 5캐릭터 일괄 이식

## 개요
원본 웹 게임(game.js L462-630, L640-700)의 *16×20 문자열 배열 픽셀 데이터*와 *색 팔레트 매핑*을 Swift로 그대로 이식. PlayerNode가 단색 사각형 → 픽셀 아트 모자이크로 전환. 5캐릭터(kim/jung/geon/im/lee) × 4방향(down/up/left/right) × 3프레임(idle/step1/step2) 일괄 처리.

## 변경 유형
**비주얼** (시각 폴리싱 큰 단위)

## Sprint 범위 계약

### 허용
1. `Models/PixelSprite.swift` 신규 — 16×20 String 배열 + 정적 데이터 (5캐릭터 베이스 + 오버레이)
2. `Models/PixelPalette.swift` 신규 — Character → [Character: UIColor] 색 매핑
3. `Nodes/PixelSpriteRenderer.swift` 신규 — String 배열 + 팔레트 → SKTexture 변환. UIGraphicsBeginImageContextWithOptions + CGContext + UIImage + SKTexture(image:).
4. `PlayerNode.swift` 수정 — SKSpriteNode `color:` 단색 모드 제거 + `texture:` 픽셀 렌더링. `apply(_ characterID:)`에서 캐릭터별 텍스처 갱신. update에서 dir/frame 갱신 시 텍스처 교체.
5. `ColorTokens.swift` 확장 — 픽셀 팔레트 색 ~25개 (skin/hair/cross/pants/shoes/eyes/etc) 추가
6. `GameConfig` 확장 — `pixelSpriteScale: CGFloat = 2` (16×20 → 32×40), 프레임 사이클 주기 등
7. `pbxproj` 신규 3 파일 등록

### 금지
1. 수간호사(EnemyNode) 픽셀 — 다음 sprint
2. 음표/F/StoneGuard 픽셀 디테일 — 다음 sprint
3. 다크/라이트 테마 토글 — 별도 sprint
4. 캐릭터 카드 아바타 픽셀 (CharacterCardNode) — 다음 sprint
5. SKAction.animate(withTextures:) 자동 애니메이션 — 본 sprint는 PlayerNode가 *수동으로* dir/frame 결정 후 텍스처 교체

### 판단 기준
"이 변경 없으면 김간호가 픽셀 아트로 안 보이는가?" → YES만 허용.

## 변경 범위

### 신규
- `Models/PixelSprite.swift` — 데이터 정의 (5캐릭터 ~500줄)
- `Models/PixelPalette.swift` — 색 매핑 (5캐릭터 분기 ~100줄)
- `Nodes/PixelSpriteRenderer.swift` — String → SKTexture 변환 (~80줄)

### 수정
- `Nodes/PlayerNode.swift` — SKSpriteNode texture 모드. dir/frame 인스턴스 프로퍼티 + setter에서 텍스처 교체. update에서 walking 시 step1/step2 토글.
- `Config/ColorTokens.swift` — 픽셀 팔레트 색 추가 (`ganhoPixelSkin`, `ganhoPixelBunHair` 등 ~25개)
- `Config/GameConfig.swift` — pixelSpriteScale, pixelWalkFrameInterval 등 신규 상수
- `pbxproj` 신규 3 파일 등록

### 회귀 0 영역 (절대 미접촉)
- EnemyNode / StoneGuard / ProjectileNode / NoteNode / DPadNode / HUDNode
- 자가 소멸 노드 11호 (Airplane~Diploma)
- CharacterCardNode / DifficultyCardNode
- ContactRouter / ScoreSystem / SpawnSystem / CameraShakeAction
- BGMPlayer / AudioManager / HapticsManager
- Repositories 4종 / Models (CharacterID, Difficulty, GameStats) / Protocols / Errors
- GameScene / GameScene+Setup / TitleScene / ResultScene
- iOS·tvOS·macOS 진입점

## 기능 상세

### 기능 1: PixelSprite 데이터 구조

```swift
/// 원본 game.js L462-630 동형. 16×20 문자열 배열 + 캐릭터별 오버레이.
enum PixelSprite {
    /// 행 = 0..19, 각 행은 16 문자. 색 코드는 PixelPalette에서 해석.
    typealias Frame = [String]

    /// 캐릭터 + 방향 + 프레임 → 16×20 문자열 배열
    static func data(for characterID: CharacterID,
                     direction: PixelDirection,
                     frame: PixelFrame) -> Frame {
        var base = baseFrame(direction: direction, frame: frame)
        applyOverlay(&base, for: characterID, direction: direction)
        return base
    }

    private static func baseFrame(direction: PixelDirection, frame: PixelFrame) -> Frame {
        // game.js L465-486 정면 base (kim 번머리 기본)
        var base: Frame = [
            "................", // 0
            "......HHHH......", // 1 번 꼭대기
            ".....HbbbbH.....", // 2 번 본체
            "....HHbbbbHH....", // 3 번 밑단
            "..HHHHHHHHHHHH..", // 4 헤어라인
            "..HHSSSSSSSSHH..", // 5 잔머리+이마
            "..SSEESSSSEESS..", // 6 눈
            "..SSELSSSSELSS..", // 7 눈 하이라이트
            "..RSSSSMMSSSSR..", // 8 볼+입
            "..SSSSSSSSSSSS..", // 9
            "...SSSSSSSSSS...", // 10 턱
            "....WWWWWWWW....", // 11 어깨/상의
            "...WWWWCCWWWW...", // 12 가슴 십자 상단
            "...WWWCCCCWWW...", // 13 가슴 십자 중단
            "....WWWWWWWW....", // 14 상의 밑단
            "....PPPPPPPP....", // 15 하의 시작
            "....PPP..PPP....", // 16
            "....PPP..PPP....", // 17
            "....BB....BB....", // 18 발
            "....BB....BB...."  // 19
        ]
        // 방향 분기 (game.js L488-511)
        switch direction {
        case .up:
            base[1] = "......HHHH......"
            base[2] = ".....HbbbbH....."
            base[3] = "....HHbbbbHH...."
            base[4] = "..HHHHHHHHHHHH.."
            base[5] = "..HHHHHHHHHHHH.."
            base[6] = "..HHHHHHHHHHHH.."
            base[7] = "..HHHHHHHHHHHH.."
            base[8] = "..HHHHHHHHHHHH.."
            base[9] = "..HHHHHHHHHHHH.."
            base[10] = "...HHHHHHHHHH..."
        case .left:
            base[6] = "..SSSSSSSSEESS.."
            base[7] = "..SSSSSSSSELSS.."
            base[8] = "..SSSSSMMSSSSR.."
        case .right:
            base[6] = "..SSEESSSSSSSS.."
            base[7] = "..SSELSSSSSSSS.."
            base[8] = "..RSSSSMMSSSSS.."
        case .down: break
        }
        // 프레임 분기 (game.js L513-520)
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

    private static func applyOverlay(_ base: inout Frame,
                                     for characterID: CharacterID,
                                     direction: PixelDirection) {
        switch characterID {
        case .kim: break  // 기본 번머리, base 그대로
        case .jung: applyJungOverlay(&base, direction: direction)
        case .geon: applyGeonOverlay(&base, direction: direction)
        case .im:   applyImOverlay(&base, direction: direction)
        case .lee:  applyLeeOverlay(&base, direction: direction)
        }
    }

    // applyJungOverlay/applyGeonOverlay/applyImOverlay/applyLeeOverlay는 game.js L526-627
    // 정확히 동형 — 문자열 치환 패턴 그대로.
}

enum PixelDirection: String {
    case down, up, left, right
}

enum PixelFrame {
    case idle, step1, step2
}
```

**game.js L526-627의 jung/geon/im/lee 오버레이 4개 함수를 정확히 옮긴다.**

### 기능 2: PixelPalette 색 매핑

```swift
/// 문자 → UIColor 매핑. 공통 9키 + 캐릭터별 키 (kim:H/b, jung:J/j/K/k, geon:G/g/F/f/O/p, im:I/i/T, lee:Q/q/D).
enum PixelPalette {
    /// 공통 팔레트 (game.js L645-655)
    private static let common: [Character: UIColor] = [
        "S": .ganhoPixelSkin,        // #fbe0d0 피부
        "W": .ganhoPixelUniform,     // #ffffff 흰옷
        "C": .ganhoPixelCross,       // #c4847a 코럴 십자
        "P": .ganhoPixelPants,       // #9ec9e8 하의
        "B": .ganhoPixelShoes,       // #a85f56 신발
        "E": .ganhoPixelEye,         // #2a1f25 눈동공
        "L": .ganhoPixelEyeHighlight,// #ffffff 흰자
        "R": .ganhoPixelCheek,       // #f5a8a0 볼터치
        "M": .ganhoPixelMouth        // #c4847a 입
    ]

    static func palette(for characterID: CharacterID) -> [Character: UIColor] {
        var merged = common
        let charSpecific: [Character: UIColor]
        switch characterID {
        case .kim:
            charSpecific = ["H": .ganhoPixelBunHair, "b": .ganhoPixelBunShadow]
        case .jung:
            charSpecific = [
                "J": .ganhoPixelHairJung, "j": .ganhoPixelHairJungShadow,
                "K": .ganhoPixelPickHead, "k": .ganhoPixelPickHandle
            ]
        case .geon:
            charSpecific = [
                "G": .ganhoPixelHairGeon, "g": .ganhoPixelHairGeonShadow,
                "F": .ganhoPixelGlassFrame, "f": .ganhoPixelGlassLens,
                "O": .ganhoPixelBookCover, "p": .ganhoPixelBookPage
            ]
        case .im:
            charSpecific = [
                "I": .ganhoPixelHairIm, "i": .ganhoPixelHairImShadow,
                "T": .ganhoPixelCatEar
            ]
        case .lee:
            // game.js L681-685: "L"(흰자)와 충돌 회피 위해 단발은 "Q"/"q"
            charSpecific = [
                "Q": .ganhoPixelHairLee, "q": .ganhoPixelHairLeeShadow,
                "D": .ganhoPixelDogEar
            ]
        }
        for (k, v) in charSpecific { merged[k] = v }
        return merged
    }
}
```

### 기능 3: PixelSpriteRenderer

String 배열 + 팔레트 → SKTexture 변환. UIGraphicsImageRenderer + CGContext + UIImage + SKTexture(image:).

```swift
enum PixelSpriteRenderer {
    /// 16×20 문자열 배열을 픽셀 단위 UIImage → SKTexture로 변환.
    /// filteringMode = .nearest로 픽셀 완벽 보존.
    static func texture(from sprite: PixelSprite.Frame,
                        palette: [Character: UIColor]) -> SKTexture {
        let width = 16
        let height = 20
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
            for (row, line) in sprite.enumerated() where row < height {
                for (col, char) in line.enumerated() where col < width {
                    guard let color = palette[char] else { continue }  // "." 등은 투명
                    color.setFill()
                    ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest  // 픽셀 perfect
        return texture
    }
}
```

### 기능 4: PlayerNode 픽셀 모드 전환

```swift
final class PlayerNode: SKSpriteNode {
    private var pixelDirection: PixelDirection = .down
    private var pixelFrame: PixelFrame = .idle
    private var frameAccumulator: TimeInterval = 0
    private var currentCharacterID: CharacterID = .kim

    // 기존 init은 size + color(.ganhoMint) 사용
    // 신규 init은 texture 초기화
    override init() {
        let texture = PixelSpriteRenderer.texture(
            from: PixelSprite.data(for: .kim, direction: .down, frame: .idle),
            palette: PixelPalette.palette(for: .kim)
        )
        super.init(texture: texture, color: .clear,
                   size: CGSize(width: 16 * GameConfig.pixelSpriteScale,
                                height: 20 * GameConfig.pixelSpriteScale))
        // physicsBody 등 기존 설정 유지...
    }

    func apply(_ characterID: CharacterID) {
        currentCharacterID = characterID
        refreshTexture()
        // 기존 speedMultiplier 적용은 별도 메서드 유지
    }

    /// update에서 매 프레임 호출. 이동 방향 변경 시 dir 갱신 + 텍스처 교체.
    func updatePixelDirection(_ velocity: CGVector) {
        let newDir: PixelDirection
        if abs(velocity.dx) > abs(velocity.dy) {
            newDir = velocity.dx >= 0 ? .right : .left
        } else if abs(velocity.dy) > 0.1 {
            newDir = velocity.dy >= 0 ? .up : .down
        } else {
            // 정지 — 마지막 방향 유지
            return
        }
        if newDir != pixelDirection {
            pixelDirection = newDir
            refreshTexture()
        }
    }

    /// update에서 매 프레임 호출. 걷는 중일 때 step1/step2 교차.
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
            from: PixelSprite.data(for: currentCharacterID,
                                    direction: pixelDirection,
                                    frame: pixelFrame),
            palette: PixelPalette.palette(for: currentCharacterID)
        )
    }
}
```

**GameScene.update**에서 PlayerNode에 velocity + dt 전달하면 자동 갱신 — *기존 GameScene 코드 변경 0*. PlayerNode가 자기 update 메서드 안에서 처리.

### 기능 5: ColorTokens 픽셀 팔레트 ~25개 신설

`Config/ColorTokens.swift`에 `// MARK: - Pixel Palette (Phase 8-1)` 섹션:

```swift
static let ganhoPixelSkin = UIColor(hex: "#fbe0d0")
static let ganhoPixelUniform = UIColor(hex: "#ffffff")
static let ganhoPixelCross = UIColor(hex: "#c4847a")
static let ganhoPixelPants = UIColor(hex: "#9ec9e8")
static let ganhoPixelShoes = UIColor(hex: "#a85f56")
static let ganhoPixelEye = UIColor(hex: "#2a1f25")
static let ganhoPixelEyeHighlight = UIColor(hex: "#ffffff")
static let ganhoPixelCheek = UIColor(hex: "#f5a8a0")
static let ganhoPixelMouth = UIColor(hex: "#c4847a")
// kim
static let ganhoPixelBunHair = UIColor(hex: "#3a2a20")
static let ganhoPixelBunShadow = UIColor(hex: "#5a4230")
// jung
static let ganhoPixelHairJung = UIColor(hex: "#2a1a12")
static let ganhoPixelHairJungShadow = UIColor(hex: "#180c08")
static let ganhoPixelPickHead = UIColor(hex: "#9aa0a8")
static let ganhoPixelPickHandle = UIColor(hex: "#7a4f2a")
// geon
static let ganhoPixelHairGeon = UIColor(hex: "#30221c")
static let ganhoPixelHairGeonShadow = UIColor(hex: "#1a0f0a")
static let ganhoPixelGlassFrame = UIColor(hex: "#1f1a1f")
static let ganhoPixelGlassLens = UIColor(hex: "#e8f0f8")
static let ganhoPixelBookCover = UIColor(hex: "#8a5a32")
static let ganhoPixelBookPage = UIColor(hex: "#f6ebd9")
// im
static let ganhoPixelHairIm = UIColor(hex: "#3a2618")
static let ganhoPixelHairImShadow = UIColor(hex: "#22150c")
static let ganhoPixelCatEar = UIColor(hex: "#ff9db0")
// lee
static let ganhoPixelHairLee = UIColor(hex: "#5a3a22")
static let ganhoPixelHairLeeShadow = UIColor(hex: "#3a2414")
static let ganhoPixelDogEar = UIColor(hex: "#b07a58")
```

**UIColor(hex:) 확장 추가 필요** — 기존 ColorTokens에 있는지 확인. 없으면 `extension UIColor { init(hex: String) }` 헬퍼 추가.

### 기능 6: GameConfig 픽셀 상수

```swift
// MARK: - Pixel Sprite (Phase 8-1)
static let pixelSpriteScale: CGFloat = 2  // 16×20 → 32×40 (Phase 5 PlayerNode size 16×20과 비교해 2배)
static let pixelWalkFrameInterval: TimeInterval = 0.18  // step1↔step2 교차 주기
```

기존 `playerSize` (16×20) 그대로 유지. PlayerNode size를 GameConfig.pixelSpriteScale × playerSize로 갱신할지 결정. *현재 16×20pt 그대로* 두면 너무 작아 보일 수 있음 — pixelSpriteScale로 2배 확대해 32×40pt 화면 픽셀.

physicsBody 크기는 *원래 hitbox 크기 그대로* 유지 (게임 로직 회귀 0).

## 회귀 0 자연 차단

1. **PlayerNode init 시그니처 호환** — 외부 호출 변경 0 (생성자만 내부 변경)
2. **apply(_ characterID:) 그대로** — 5-3의 캐릭터 분기 호출 호환
3. **physicsBody / velocity / collisionBitMask 미접촉** — 게임 로직 0 영향
4. **EnemyNode / StoneGuard 단색 유지** — 본 sprint 범위는 PlayerNode만
5. **GameScene.update 호출 패턴 보존** — PlayerNode가 자기 update에서 픽셀 처리
6. **scale 적용은 size 인자에서 1회만** — 매 프레임 setScale 0회

## 주의사항

1. **이미지 좌표계 vs SpriteKit 좌표계** — UIGraphicsImageRenderer는 *y가 아래로 증가*, SpriteKit은 *y가 위로 증가*. SKTexture(image:)가 자동 처리하지만 *행 0이 위쪽인지 아래쪽인지* 확인 필요. 원본 게임에서 행 0이 *맨 위* (번 꼭대기). SKTexture가 UIImage를 *그대로* 표시하므로 SpriteKit에서도 행 0이 *위쪽*에 보이도록 자동 처리. 단, 만약 *상하 뒤집힘* 증상 발생하면 UIImage 생성 시 `ctx.translateBy + scaleBy(1, -1)` 처리 필요.

2. **filteringMode .nearest 필수** — 픽셀 perfect 보존. 기본값 .linear는 *번지는* 효과.

3. **텍스처 재생성 빈도** — refreshTexture()는 *방향/프레임 변경 시에만* 호출. 매 update에서 *조건 확인 후* 변경 시에만 재생성. step1↔step2 교차는 0.18초마다 1회.

4. **메모리 관리** — SKTexture는 ARC 자동 정리. PlayerNode가 매번 texture 프로퍼티 갱신 시 이전 텍스처는 자동 해제. 누적 0.

5. **5캐릭터 오버레이 정확성** — game.js L526-627의 4개 오버레이 함수를 *byte-equal* 변환. 한 문자라도 오차 시 픽셀 깨짐. 특히 `base[N].substring(0, 14) + 'XX'` 패턴은 Swift `String.prefix(14) + "XX"` 또는 `String(base[N].prefix(14)) + "XX"`.

6. **CharacterID.rawValue 매핑** — Swift CharacterID enum과 game.js의 'kim'/'jung'/'geon'/'im'/'lee'가 일치 확인. 이미 일치(Phase 5에서 정의).

7. **UIColor(hex:) 확장** — 기존 ColorTokens.swift에 hex init 헬퍼 있으면 재사용. 없으면 새로 추가.

8. **physicsBody 크기 보존** — 픽셀 스프라이트가 시각적으로 32×40이 되어도 physicsBody는 원래 14×14 또는 16×16 그대로. 게임 hitbox 변경 0.

9. **layout & camera follow** — PlayerNode 크기 변경이 카메라 follow / 충돌 / 맵 경계에 영향 0인지 확인. PlayerNode position은 *중심*이므로 size 변경 시 *시각만* 커짐, 위치 좌표 동일.

10. **GameScene.update에서 PlayerNode.tickWalkFrame 호출 추가 필요** — 자동 갱신을 위해 매 update에서 PlayerNode에 dt 전달. 추가 1줄.
