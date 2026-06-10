//
//  ProfileAvatarViewNode.swift
//  GanhoMusic Shared
//
//  R5 — 캐릭터 포트레이트(PixelPortraitSprite)와 커스텀 사진을 같은 v3 프레임으로 렌더.
//  프레임 톤: ink800 면 + line500 2px 보더 + gold 액센트 모서리 탭 (직각 — 패널만 라운드 허용).
//  커스텀 사진 경로(SKCropNode aspect-fill)는 기능 보존 — ProfileAvatarRepository API 무변경.
//

import SpriteKit
import UIKit

final class ProfileAvatarViewNode: SKNode {

    // MARK: - Properties
    private let faceNode = SKSpriteNode(color: Palette.ink800, size: .zero)
    private let borderNode = SKShapeNode()
    /// 좌상단 gold 액센트 탭 — v3 프레임 시그니처 (4×16 바, PixelPanel 헤더 액센트 동형).
    private let accentNode = SKSpriteNode(color: Palette.gold, size: .zero)
    private var portraitNode: SKSpriteNode?
    private var photoNode: SKSpriteNode?
    private var cropNode: SKCropNode?

    /// 내부 적층 — 면(0) < 콘텐츠(1) < 보더/액센트(2).
    private enum InnerZ {
        static let face: CGFloat = 0
        static let content: CGFloat = 1
        static let chrome: CGFloat = 2
    }

    // MARK: - Init
    override init() {
        super.init()
        faceNode.zPosition = InnerZ.face
        addChild(faceNode)
        borderNode.fillColor = .clear
        borderNode.strokeColor = Palette.line500
        borderNode.lineWidth = UILayout.v3BorderWidth
        borderNode.zPosition = InnerZ.chrome
        addChild(borderNode)
        accentNode.zPosition = InnerZ.chrome
        addChild(accentNode)
    }

    @available(*, unavailable, message: "Use init() instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Update (공개 시그니처 유지 — 호출측 변경 0)
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
        addPortrait(characterID: characterID)
    }

    private func updateFrame(size: CGSize) {
        faceNode.size = size
        borderNode.path = CGPath(
            rect: CGRect(x: (-size.width / 2).rounded(),
                         y: (-size.height / 2).rounded(),
                         width: size.width.rounded(),
                         height: size.height.rounded()),
            transform: nil
        )
        accentNode.size = CGSize(width: UILayout.Space.s4, height: UILayout.Space.s16)
        accentNode.position = CGPoint(
            x: (-size.width / 2 + UILayout.Space.s4 / 2).rounded(),
            y: (size.height / 2 - UILayout.Space.s16 / 2 - UILayout.Space.s4).rounded()
        )
    }

    /// 커스텀 사진 — SKCropNode aspect-fill (v2 기능 보존, 마스크만 v3 직각).
    private func addPhoto(texture: SKTexture, size: CGSize) {
        let crop = SKCropNode()
        let mask = SKSpriteNode(color: .white, size: size)
        crop.maskNode = mask
        crop.zPosition = InnerZ.content

        let node = SKSpriteNode(texture: texture)
        node.size = aspectFill(textureSize: texture.size(), targetSize: size)
        crop.addChild(node)

        cropNode = crop
        photoNode = node
        addChild(crop)
    }

    /// 캐릭터 포트레이트 — 24×24 ×2 = 48pt 정수 배율 (.nearest는 PixelSpriteRenderer 보장).
    private func addPortrait(characterID: CharacterID) {
        let node = SKSpriteNode(texture: PixelPortraitSprite.texture(for: characterID))
        node.size = CGSize(width: UILayout.R5.profileAvatarContentSide,
                           height: UILayout.R5.profileAvatarContentSide)
        node.zPosition = InnerZ.content
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
