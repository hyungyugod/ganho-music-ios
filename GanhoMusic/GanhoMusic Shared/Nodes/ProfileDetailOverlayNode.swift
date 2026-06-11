//
//  ProfileDetailOverlayNode.swift
//  GanhoMusic Shared
//
//  R5 재구성 — PixelDialogNode 기반 개인 프로필 상세/아바타 피커/닉네임 프롬프트/busy.
//  공개 계약 byte-호환: ProfileDetailMode·ProfileDetailAction·init(sceneSize:)·
//  update(sceneSize:snapshot:avatar:repository:unlockedCharacters:mode:)·currentMode·action(at:).
//  닉네임 편집·사진 선택 NotificationCenter 플로우(씬 확장 소유)는 무변경.
//  터치 함정 해소: dialog·버튼 isUserInteractionEnabled 차단 — 씬 라우팅 보존 (SPEC §주의사항 1).
//  모드 전환 = dynamicNodes 전부 제거 후 재구성 (v2 좀비 0 패턴 계승).
//

import SpriteKit
import UIKit

enum ProfileDetailAction {
    case editProfileName
    case chooseAvatar
    case selectAvatar(CharacterID)
    case choosePhoto
    /// R9 U2 — Scoreboard 기록/업적 탭 직행 (복귀 시 프로필 재오픈 라우트).
    case openRecords
    case openAchievements
    case linkApple
    case signOut
    case requestDeleteConfirmation
    case close
}

enum ProfileDetailMode {
    case detail
    case avatarPicker
    case nicknamePrompt
    case busy
}

final class ProfileDetailOverlayNode: SKNode {

    // MARK: - Properties
    let dialog: PixelDialogNode   // +Content 공유 — R4 분할 전례
    let titleLabel = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
    let bodyLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    private let avatarView = ProfileAvatarViewNode()
    /// 모드별 재구성 노드 — update마다 전부 제거 후 재생성 (좀비 0).
    var dynamicNodes: [SKNode] = []   // +Content가 적재
    var actionTargets: [(node: SKNode, action: ProfileDetailAction)] = []
    private var lastSceneSize: CGSize = .zero
    private(set) var currentMode: ProfileDetailMode = .detail

    // MARK: - Init
    init(sceneSize: CGSize) {
        dialog = PixelDialogNode(panelSize: UILayout.R5.profileDialogPanelSize)
        super.init()
        name = "profileDetailOverlay"
        zPosition = ZOrder.profileDetailOverlayZPosition
        // 터치 함정 해소 — 씬 touchesBegan → action(at:) 라우팅 보존.
        dialog.isUserInteractionEnabled = false
        configureHeader()
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        lastSceneSize = sceneSize
        dialog.present(in: self, screenSize: sceneSize)
    }

    @available(*, unavailable, message: "Use init(sceneSize:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Header (아바타 + 제목 + 본문 — 전 모드 공통, 텍스트만 모드별 갱신)
    private func configureHeader() {
        titleLabel.fontSize = Typography.V3.h2.size
        titleLabel.fontColor = Palette.textHi
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        dialog.contentNode.addChild(titleLabel)

        bodyLabel.fontSize = Typography.V3.caption.size
        bodyLabel.fontColor = Palette.textLo
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.R5.profileBodyMaxWidth
        dialog.contentNode.addChild(bodyLabel)

        dialog.contentNode.addChild(avatarView)

        let panelSize = UILayout.R5.profileDialogPanelSize
        let leftX = -panelSize.width / 2 + UILayout.R5.profileHeaderInset
        let topY = panelSize.height / 2 - UILayout.R5.profileHeaderInset
        let frameSide = UILayout.R5.profileAvatarFrameSide
        avatarView.position = CGPoint(x: (leftX + frameSide / 2).rounded(),
                                      y: (topY - frameSide / 2).rounded())
        let textX = (leftX + frameSide + UILayout.R5.profileHeaderTextGap).rounded()
        titleLabel.position = CGPoint(x: textX,
                                      y: (topY - UILayout.R5.profileTitleOffsetY).rounded())
        bodyLabel.position = CGPoint(
            x: textX,
            y: (titleLabel.position.y - UILayout.R5.profileBodyBelowTitleGap).rounded()
        )
    }

    // MARK: - Update (공개 계약 — 시그니처 byte-호환)
    func update(sceneSize: CGSize,
                snapshot: CharacterHomeSnapshot,
                avatar: ProfileAvatarSnapshot,
                repository: ProfileAvatarRepository,
                unlockedCharacters: [CharacterID],
                mode: ProfileDetailMode) {
        currentMode = mode
        removeDynamicNodes()
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        if sceneSize != lastSceneSize {
            lastSceneSize = sceneSize
            dialog.present(in: self, screenSize: sceneSize)   // 딤 재설정 (멱등)
        }
        avatarView.update(
            snapshot: avatar,
            repository: repository,
            size: CGSize(width: UILayout.R5.profileAvatarFrameSide,
                         height: UILayout.R5.profileAvatarFrameSide)
        )

        switch mode {
        case .detail:
            configureDetail(snapshot: snapshot)
        case .avatarPicker:
            configureAvatarPicker(avatar: avatar, unlockedCharacters: unlockedCharacters)
        case .nicknamePrompt:
            configureNicknamePrompt(snapshot: snapshot)
        case .busy:
            configureBusy(snapshot: snapshot)
        }
    }

    private func removeDynamicNodes() {
        dynamicNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }
        dynamicNodes.removeAll()
        actionTargets.removeAll()
    }

    // MARK: - Action (공개 계약 — 패널 밖 탭 = close, 패널 안 비버튼 = nil)
    func action(at location: CGPoint) -> ProfileDetailAction? {
        guard !isHidden, currentMode != .busy else { return nil }
        guard let parent = parent else { return nil }
        let local = dialog.contentNode.convert(location, from: parent)
        for target in actionTargets.reversed() where target.node.contains(local) {
            ChiptuneSynth.shared.play(.uiTap)
            return target.action
        }
        let panelSize = UILayout.R5.profileDialogPanelSize
        let panelFrame = CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2,
                                width: panelSize.width, height: panelSize.height)
        if panelFrame.contains(convert(location, from: parent)) {
            return nil
        }
        return .close
    }
}
