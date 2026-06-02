//
//  CharacterPortraitNode.swift
//  GanhoMusic Shared
//
//  Sprint 2 · Character account home full-body preview.
//

import SpriteKit
import UIKit

/// 캐릭터 홈의 전신 프리뷰 노드. PNG 자산 우선, 없으면 픽셀 렌더러로 fallback한다.
final class CharacterPortraitNode: SKNode {

    // MARK: - Properties
    private let sprite = SKSpriteNode()
    private var maxSize: CGSize
    private(set) var characterID: CharacterID

    // MARK: - Init
    init(characterID: CharacterID, maxSize: CGSize) {
        self.characterID = characterID
        self.maxSize = maxSize
        super.init()
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        sprite.zPosition = GameConfig.characterHomeCharacterZPosition
        addChild(sprite)
        update(characterID: characterID)
        startIdleBreathing()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update
    func update(characterID: CharacterID) {
        self.characterID = characterID
        let texture = Self.texture(for: characterID)
        sprite.texture = texture
        sprite.size = aspectFit(textureSize: texture.size(), maxSize: maxSize)
    }

    func setMaxSize(_ size: CGSize) {
        maxSize = size
        guard let texture = sprite.texture else { return }
        sprite.size = aspectFit(textureSize: texture.size(), maxSize: maxSize)
    }

    // MARK: - Texture
    private static func texture(for characterID: CharacterID) -> SKTexture {
        let rawName = "\(characterID.rawValue)_down_idle_1"
        let candidateNames = [
            "Characters/\(rawName)",
            rawName
        ]
        for assetName in candidateNames {
            if UIImage(named: assetName) != nil {
                let texture = SKTexture(imageNamed: assetName)
                texture.filteringMode = .linear
                return texture
            }
        }

        let frame = PixelSprite.data(for: characterID, direction: .down, frame: .idle)
        let palette = PixelPalette.palette(for: characterID)
        return PixelSpriteRenderer.texture(from: frame, palette: palette)
    }

    // MARK: - Layout
    private func aspectFit(textureSize: CGSize, maxSize: CGSize) -> CGSize {
        guard textureSize.width > 0, textureSize.height > 0 else { return maxSize }
        let widthScale = maxSize.width / textureSize.width
        let heightScale = maxSize.height / textureSize.height
        let scale = min(widthScale, heightScale)
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    // MARK: - Animation
    private func startIdleBreathing() {
        let up = SKAction.scale(
            to: GameConfig.characterHomePortraitBreathScale,
            duration: GameConfig.characterHomePortraitBreathDuration
        )
        up.timingMode = .easeInEaseOut
        let down = SKAction.scale(
            to: 1.0,
            duration: GameConfig.characterHomePortraitBreathDuration
        )
        down.timingMode = .easeInEaseOut
        sprite.run(
            SKAction.repeatForever(SKAction.sequence([up, down])),
            withKey: GameConfig.characterHomePortraitBreathActionKey
        )
    }
}
