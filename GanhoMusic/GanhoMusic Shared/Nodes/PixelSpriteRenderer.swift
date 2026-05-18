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
}
