//
//  ProfileAvatarViewNode.swift
//  GanhoMusic Shared
//
//  캐릭터 초상화와 커스텀 사진을 동일한 프로필 프레임으로 렌더링한다.
//

import SpriteKit
import UIKit

final class ProfileAvatarViewNode: SKNode {

    // MARK: - Properties
    private let frameNode = SKShapeNode()
    private var portraitNode: CharacterPortraitNode?
    private var photoNode: SKSpriteNode?
    private var cropNode: SKCropNode?

    // MARK: - Init
    override init() {
        super.init()
        frameNode.zPosition = ZOrder.profileAvatarFrameZPosition
        addChild(frameNode)
    }

    @available(*, unavailable, message: "Use init() instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Update
    func update(snapshot: ProfileAvatarSnapshot,
                repository: ProfileAvatarRepository,
                size: CGSize) {
        updateFrame(size: size)
        removeCurrentContent()

        if snapshot.selectedID == .customPhoto,
           let texture = repository.customPhotoTexture(for: snapshot) {
            addPhoto(texture: texture, size: size)
            return
        }

        let characterID = snapshot.selectedID.characterID ?? .kim
        addPortrait(characterID: characterID, size: size)
    }

    private func updateFrame(size: CGSize) {
        frameNode.path = CGPath(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerWidth: UILayout.profileAvatarFrameCornerRadius,
            cornerHeight: UILayout.profileAvatarFrameCornerRadius,
            transform: nil
        )
        // v2 톤: 어두운 네이비+골드 → 밝은 크림+코랄 (Summary·Detail 양쪽 자동 일관 적용)
        frameNode.fillColor = UIColor.ganhoPaper.withAlphaComponent(UILayout.profileAvatarFrameFillAlpha)
        frameNode.strokeColor = UIColor.ganhoCoralPrimary.withAlphaComponent(UILayout.profileAvatarFrameStrokeAlpha)
        frameNode.lineWidth = UILayout.profileAvatarFrameLineWidth
    }

    private func addPhoto(texture: SKTexture, size: CGSize) {
        let crop = SKCropNode()
        let mask = SKShapeNode(
            rectOf: size,
            cornerRadius: UILayout.profileAvatarFrameCornerRadius
        )
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        crop.zPosition = ZOrder.profileAvatarContentZPosition

        let node = SKSpriteNode(texture: texture)
        node.size = aspectFill(textureSize: texture.size(), targetSize: size)
        node.zPosition = ZOrder.profileAvatarContentZPosition
        crop.addChild(node)

        cropNode = crop
        photoNode = node
        addChild(crop)
    }

    private func addPortrait(characterID: CharacterID, size: CGSize) {
        let contentSize = CGSize(
            width: max(0, size.width - UILayout.profileAvatarContentInset * 2),
            height: max(0, size.height - UILayout.profileAvatarContentInset * 2)
        )
        let node = CharacterPortraitNode(characterID: characterID, maxSize: contentSize)
        node.position = CGPoint(x: 0, y: -contentSize.height / 2)
        node.zPosition = ZOrder.profileAvatarContentZPosition
        portraitNode = node
        addChild(node)
    }

    private func removeCurrentContent() {
        [portraitNode, photoNode, cropNode].forEach { node in
            node?.removeAllActions()
            node?.removeFromParent()
        }
        portraitNode = nil
        photoNode = nil
        cropNode = nil
    }

    private func aspectFill(textureSize: CGSize, targetSize: CGSize) -> CGSize {
        guard textureSize.width > 0,
              textureSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return targetSize
        }
        let widthScale = targetSize.width / textureSize.width
        let heightScale = targetSize.height / textureSize.height
        let scale = max(widthScale, heightScale)
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }
}
