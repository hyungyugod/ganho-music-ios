//
//  PixelSpriteRenderer.swift
//  GanhoMusic Shared
//
//  Phase 8-1 · 16×20 문자열 배열 + 팔레트 → SKTexture 변환.
//  UIGraphicsImageRenderer로 1픽셀 1셀 fill → SKTexture(image:) + filteringMode = .nearest.
//

import SpriteKit
import UIKit

/// PixelSprite.Frame(16×20 String 배열) + 1글자→UIColor 팔레트 → SKTexture 변환기.
/// PlayerNode가 방향/프레임 변경 시 호출 → texture 프로퍼티 교체.
/// SKTexture는 ARC 자동 정리되므로 이전 텍스처 명시 해제 불필요.
enum PixelSpriteRenderer {

    /// 픽셀 스프라이트 한 변의 셀 수. 가로 16, 세로 20.
    private static let spriteWidth: Int = 16
    private static let spriteHeight: Int = 20

    /// 16×20 문자열 배열을 픽셀 단위 UIImage → SKTexture로 변환.
    /// `.`(점) 문자나 팔레트에 없는 문자는 fill 생략 → 투명 픽셀로 남는다.
    /// filteringMode = .nearest로 픽셀 perfect 보존 (linear는 *번지는* 효과).
    static func texture(from sprite: PixelSprite.Frame,
                        palette: [Character: UIColor]) -> SKTexture {
        let size = CGSize(width: spriteWidth, height: spriteHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            for (row, line) in sprite.enumerated() where row < spriteHeight {
                let chars = Array(line)
                for col in 0..<min(chars.count, spriteWidth) {
                    let char = chars[col]
                    // "." 등 팔레트에 없는 문자는 투명 — fill 생략.
                    guard let color = palette[char] else { continue }
                    color.setFill()
                    ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        // 픽셀 perfect 보존 — 기본값 .linear는 확대 시 *번지는* 효과로 픽셀 톤 파괴.
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Sprint 10 Phase D · 12×12 F/A 가변 helper
    // 원본 game.js drawF(L783~L812) / drawAItem byte-equal — 12셀 매트릭스 단색 fill.
    // 본체 16×20 texture(_:palette:)와 시그니처 충돌 0 — 별도 static 메서드로 추가.
    // 매트릭스는 game.js의 픽셀 그리기 순서(좌→우, 위→아래) 따름 — 1셀 = 1px → SKTexture .nearest 확대.

    /// F 12×12 픽셀 매트릭스. 원본 drawF (game.js L783~L812) byte-equal.
    /// "1" = 색칠, "." = 투명. 첫 행이 위쪽.
    private static let fMatrix: [String] = [
        "............",
        "..11111111..",
        "..11111111..",
        "..11........",
        "..11........",
        "..111111....",
        "..111111....",
        "..11........",
        "..11........",
        "..11........",
        "..11........",
        "............"
    ]

    /// A 12×12 픽셀 매트릭스. 원본 drawAItem byte-equal.
    private static let aMatrix: [String] = [
        "............",
        ".....11.....",
        "....1111....",
        "....1111....",
        "...11..11...",
        "...11..11...",
        "..11111111..",
        "..11111111..",
        "..11....11..",
        "..11....11..",
        "..11....11..",
        "............"
    ]

    /// F 12×12 텍스처 1회 생성 helper. 단색(color) fill.
    /// 호출부: FProjectileNode.init — 인스턴스마다 1회 호출, SKTexture는 ARC 자동 정리.
    /// 가변 크기 helper (본체 16×20 spriteWidth/Height와 독립).
    static func fProjectileTexture(color: UIColor) -> SKTexture {
        return matrixTexture(fMatrix, color: color)
    }

    /// A 12×12 텍스처 1회 생성 helper. 단색(color) fill.
    /// 호출부: AItemNode.init.
    static func aItemTexture(color: UIColor) -> SKTexture {
        return matrixTexture(aMatrix, color: color)
    }

    /// 12×12 가변 매트릭스 → 단색 SKTexture. "1" 채움, 그 외 투명.
    /// fProjectileTexture / aItemTexture 공통 백엔드 — DRY.
    private static func matrixTexture(_ matrix: [String], color: UIColor) -> SKTexture {
        let dim = GameConfig.fProjectileMatrixSize   // 12
        let size = CGSize(width: dim, height: dim)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            for (row, line) in matrix.enumerated() where row < dim {
                let chars = Array(line)
                for col in 0..<min(chars.count, dim) {
                    guard chars[col] == "1" else { continue }
                    color.setFill()
                    ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Sprint 10 Phase E · 음표 12×12 fillRect 5단계 직접 호출
    // 원본 game.js drawNote (L730~L785) byte-equal. 매트릭스가 아니라 fillRect 호출 순서를 그대로 옮긴다.
    // (다른 helper와 달리 String 매트릭스 우회 — 8분 음표 머리/기둥/깃발 5단계가 매트릭스로 표현 곤란.)
    // 16×16 SKTexture(매트릭스 12×12 + ox=2 oy=2 padding 2px씩). PhysicsBody size(16)와 정합.

    /// 음표 16×16 텍스처. 원본 fillRect 5단계 + 1픽셀 하이라이트.
    /// 호출부: NoteNode.init — 인스턴스마다 1회 호출, SKTexture는 ARC 자동 정리.
    /// brand = .ganhoMusicGold 재사용, brandHi = UIColor.white. ColorTokens 본체 신설 0.
    static func notePixelTexture() -> SKTexture {
        let size = CGSize(width: 16, height: 16)
        let brand = UIColor.ganhoMusicGold
        let brandHi = UIColor.white
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let ox: CGFloat = 2
            let oy: CGFloat = 2
            brand.setFill()
            // 1. 머리 (3 fillRect — 원본 L730~L740)
            cg.fill(CGRect(x: ox + 1, y: oy + 7, width: 6, height: 4))
            cg.fill(CGRect(x: ox + 2, y: oy + 6, width: 4, height: 1))
            cg.fill(CGRect(x: ox + 2, y: oy + 11, width: 4, height: 1))
            // 2. 기둥 (세로 7px)
            cg.fill(CGRect(x: ox + 6, y: oy + 1, width: 1, height: 7))
            // 3. 깃발 상단 (가로 4px)
            cg.fill(CGRect(x: ox + 6, y: oy + 1, width: 4, height: 1))
            // 4. 깃발 우측 (세로 3px)
            cg.fill(CGRect(x: ox + 9, y: oy + 1, width: 1, height: 3))
            // 5. 깃발 중간 (가로 2px)
            cg.fill(CGRect(x: ox + 7, y: oy + 4, width: 2, height: 1))
            // 6. 하이라이트 1px (흰)
            brandHi.setFill()
            cg.fill(CGRect(x: ox + 2, y: oy + 7, width: 1, height: 1))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Sprint 10 Phase E · 청진기 14×8 매트릭스 helper
    // 원본 game.js L2922~L2960 drawStethoscope byte-equal.
    // matrix=14×8, palette={t:#2a2228, B:#d8d4dc, m:#c8c8d0}.
    // 본체 texture(_:palette:)와 시그니처 충돌 0 — 가변 크기 helper.

    /// 청진기 14×8 픽셀 매트릭스. 원본 L2922~L2960 byte-equal.
    /// 't'=프레임(검정), 'B'=흉부판(밝은 회색), 'm'=고무관(중간 회색), '.'=투명.
    private static let stethoscopeMatrix: [String] = [
        "..tt......tt..", // 0
        "..tt......tt..", // 1
        "..tt......tt..", // 2
        "...tt....tt...", // 3
        "....tttttt....", // 4
        "....tBBBBt....", // 5
        "....BBBBBB....", // 6
        ".....mmmm....."  // 7
    ]

    /// 청진기 14×8 픽셀 팔레트. 원본 색 hex 그대로 inline UIColor literal — ColorTokens 본체 신설 0.
    private static let stethoscopePalette: [Character: UIColor] = [
        "t": UIColor(red: 0x2A / 255.0, green: 0x22 / 255.0, blue: 0x28 / 255.0, alpha: 1.0),
        "B": UIColor(red: 0xD8 / 255.0, green: 0xD4 / 255.0, blue: 0xDC / 255.0, alpha: 1.0),
        "m": UIColor(red: 0xC8 / 255.0, green: 0xC8 / 255.0, blue: 0xD0 / 255.0, alpha: 1.0)
    ]

    /// 청진기 14×8 텍스처. 호출부: StethoscopeNode.init — 1회 호출, SKTexture ARC 자동 정리.
    static func stethoscopeTexture() -> SKTexture {
        return variableMatrixTexture(stethoscopeMatrix, width: 14, height: 8, palette: stethoscopePalette)
    }

    /// 가변 크기(W×H) 매트릭스 → 다색 SKTexture. 청진기 14×8 / 향후 다른 사이즈 공용 백엔드.
    /// 본체 texture(_:palette:) 16×20 고정 시그니처와 달리 width/height 명시 — 본체 본문 변경 0.
    static func variableMatrixTexture(_ matrix: [String],
                                      width: Int,
                                      height: Int,
                                      palette: [Character: UIColor]) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            for (row, line) in matrix.enumerated() where row < height {
                let chars = Array(line)
                for col in 0..<min(chars.count, width) {
                    guard let color = palette[chars[col]] else { continue }
                    color.setFill()
                    ctx.fill(CGRect(x: col, y: row, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - Sprint 10 Phase G · rows/palette/scale 가변 helper
    // 원본 game.js 비행기 16×5 등 SCALE 가변 매트릭스용 — variableMatrixTexture에 정수 scale 추가.
    // 호출부: AirplaneNode.init — SCALE=3 → 48×15 px → SKTexture .nearest 확대.
    // 본체 16×20/12×12 helper와 시그니처 충돌 0(이름/인자 형태 모두 분리).

    /// 가변 (W×H) 매트릭스 + 정수 scale → SKTexture. "." 또는 팔레트 미등록 문자 = 투명.
    /// matrix의 행 길이는 row마다 다를 수 있고(짧으면 우측 투명), height/width로 클램프.
    /// 호출부: AirplaneNode (16×5×SCALE3 → 48×15).
    static func texture(rows: [String],
                        palette: [Character: UIColor],
                        scale: Int) -> SKTexture {
        let height = rows.count
        let width = rows.map { $0.count }.max() ?? 0
        // 픽셀 단위 그리기 후 SKTexture .nearest로 정수 확대.
        // 캔버스는 원본 셀 크기 1셀=1px — 시각 size는 호출부가 .size()로 조회 후 확대 결정.
        let pixelW = width * scale
        let pixelH = height * scale
        let size = CGSize(width: pixelW, height: pixelH)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            for (row, line) in rows.enumerated() where row < height {
                let chars = Array(line)
                for col in 0..<min(chars.count, width) {
                    guard let color = palette[chars[col]] else { continue }
                    color.setFill()
                    ctx.fill(CGRect(x: col * scale, y: row * scale, width: scale, height: scale))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}
