//
//  ProfileDetailOverlayNode+Content.swift
//  GanhoMusic Shared
//
//  R5 — 모드별 콘텐츠 구성 (detail/avatarPicker/nicknamePrompt/busy).
//  카피는 기존 UILayout 텍스트 상수 재사용 (R4 §E-9). 버튼은 isUserInteractionEnabled=false —
//  씬 touchesBegan → action(at:) 라우팅 보존 (터치 함정 해소, SPEC §주의사항 1).
//

import SpriteKit
import UIKit

extension ProfileDetailOverlayNode {

    // MARK: - Modes (카피는 기존 UILayout 텍스트 상수 재사용 — R4 §E-9 패턴)
    /// R9 U2+U3 — 버튼 3행 재구성: 1행 프로필 편집(기존) / 2행 [기록][업적]+[닫기](주 위계) /
    /// 3행 계정 compact(위계 강등 — 탈퇴 primary 폐지, 전부 ghost).
    func configureDetail(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileDetailTitleText
        bodyLabel.text = snapshot.profileDetailIdentityText
        addMetricRow(snapshot: snapshot)

        // 1행 — 이름/아바타/사진 (기존 유지).
        layoutButtonRow([
            makeButton(text: UILayout.profileDetailEditNameText,
                       size: UILayout.R5.profileWideButtonSize,
                       action: .editProfileName, variant: .secondary),
            makeButton(text: UILayout.profileDetailChooseAvatarText,
                       size: UILayout.R5.profileWideButtonSize,
                       action: .chooseAvatar, variant: .secondary),
            makeButton(text: UILayout.profileDetailChoosePhotoText,
                       size: UILayout.R5.profileWideButtonSize,
                       action: .choosePhoto, variant: .secondary)
        ], y: UILayout.R5.profileFirstButtonRowY)

        // 3행 — 계정 compact (연동 상태별). 회원탈퇴 primary 금지 — ghost로 강등.
        // ⚠️ 등록 순서: 2행보다 *먼저* 등록 — action(at:)이 reversed() 순회라 44pt 터치
        // 확장이 겹치는 행간 띠에서 2행(주 위계, 후순 등록)이 우선 판정된다.
        let accountButton = snapshot.isAppleLinked
            ? makeButton(text: UILayout.accountMenuSignOutText,
                         size: UILayout.R9.profileCompactButtonSize,
                         action: .signOut, variant: .ghost)
            : makeButton(text: UILayout.authAppleButtonText,
                         size: UILayout.R9.profileCompactButtonSize,
                         action: .linkApple, variant: .ghost)
        layoutButtonRow([
            accountButton,
            makeButton(text: UILayout.accountMenuDeleteText,
                       size: UILayout.R9.profileCompactButtonSize,
                       action: .requestDeleteConfirmation, variant: .ghost)
        ], y: UILayout.R9.profileThirdButtonRowY)

        // 2행 — [기록][업적] 주 위계 + [닫기] (마지막 등록 = 터치 우선).
        layoutButtonRow([
            makeButton(text: UILayout.R6.scoreboardRecordsTabText,
                       size: UILayout.R5.profileButtonSize,
                       action: .openRecords, variant: .secondary),
            makeButton(text: UILayout.R6.scoreboardAchievementsTabText,
                       size: UILayout.R5.profileButtonSize,
                       action: .openAchievements, variant: .secondary),
            makeButton(text: UILayout.profileDetailCloseText,
                       size: UILayout.R5.profileButtonSize,
                       action: .close, variant: .ghost)
        ], y: UILayout.R5.profileSecondButtonRowY)
    }

    func configureAvatarPicker(avatar: ProfileAvatarSnapshot,
                                       unlockedCharacters: [CharacterID]) {
        titleLabel.text = UILayout.profileDetailAvatarPickerTitleText
        bodyLabel.text = UILayout.profileDetailAvatarPickerBodyText

        let optionCharacters = unlockedCharacters.isEmpty ? [.kim] : unlockedCharacters
        let optionSize = UILayout.R5.profileAvatarOptionSize
        let count = CGFloat(optionCharacters.count)
        let totalWidth = optionSize.width * count
            + UILayout.R5.profileAvatarOptionGap * max(0, count - 1)
        var cursorX = -totalWidth / 2 + optionSize.width / 2
        for characterID in optionCharacters {
            addAvatarOption(
                characterID: characterID,
                selected: avatar.selectedID.characterID == characterID,
                center: CGPoint(x: cursorX.rounded(),
                                y: UILayout.R5.profileAvatarOptionRowY)
            )
            cursorX += optionSize.width + UILayout.R5.profileAvatarOptionGap
        }

        layoutButtonRow([
            makeButton(text: UILayout.profileDetailChoosePhotoText,
                       size: UILayout.R5.profileWideButtonSize,
                       action: .choosePhoto, variant: .secondary),
            makeButton(text: UILayout.profileDetailCloseText,
                       size: UILayout.R5.profileButtonSize,
                       action: .close, variant: .ghost)
        ], y: UILayout.R5.profileSecondButtonRowY)
    }

    func configureNicknamePrompt(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileNicknamePromptTitleText
        bodyLabel.text = UILayout.profileNicknamePromptBodyText
        addMetricRow(snapshot: snapshot)
        layoutButtonRow([
            makeButton(text: UILayout.profileNicknamePromptButtonText,
                       size: UILayout.R5.profileWideButtonSize,
                       action: .editProfileName, variant: .primary),
            makeButton(text: UILayout.profileDetailCloseText,
                       size: UILayout.R5.profileButtonSize,
                       action: .close, variant: .ghost)
        ], y: UILayout.R5.profileSecondButtonRowY)
    }

    func configureBusy(snapshot: CharacterHomeSnapshot) {
        titleLabel.text = UILayout.profileDetailBusyTitleText
        bodyLabel.text = UILayout.profileDetailBusyBodyText
        addMetricRow(snapshot: snapshot)
    }

    // MARK: - Pieces
    /// 지표 3종 (플레이·최고점·누적) — caption 제목 + body 값.
    private func addMetricRow(snapshot: CharacterHomeSnapshot) {
        let items = [
            (UILayout.characterHomePlayCountLabelText,
             "\(snapshot.playCount)\(UILayout.characterHomePlaySuffixText)"),
            (UILayout.characterHomeBestScoreLabelText,
             "\(snapshot.highScore)\(UILayout.characterHomePointSuffixText)"),
            (UILayout.characterHomeTotalScoreLabelText,
             "\(snapshot.totalScore)\(UILayout.characterHomePointSuffixText)")
        ]
        let width = UILayout.R5.profileMetricWidth
        let gap = UILayout.R5.profileMetricGap
        let totalWidth = width * CGFloat(items.count) + gap * CGFloat(items.count - 1)
        var cursorX = -totalWidth / 2 + width / 2
        for item in items {
            let title = makeLabel(text: item.0, token: Typography.V3.caption,
                                  color: Palette.textLo)
            title.position = CGPoint(x: cursorX.rounded(),
                                     y: UILayout.R5.profileMetricTitleOffsetY)
            addDynamicNode(title)
            let value = makeLabel(text: item.1, token: Typography.V3.body,
                                  color: Palette.textHi)
            value.position = CGPoint(x: cursorX.rounded(),
                                     y: UILayout.R5.profileMetricValueOffsetY)
            addDynamicNode(value)
            cursorX += width + gap
        }
    }

    /// 아바타 옵션 카드 — 24×24 포트레이트 ×2(정수 배율 .nearest) + 선택 = 액센트 보더/글로우.
    private func addAvatarOption(characterID: CharacterID, selected: Bool, center: CGPoint) {
        let optionSize = UILayout.R5.profileAvatarOptionSize
        let accent = Palette.character(characterID)

        if selected {
            // 글로우 — 액센트색 alpha 0.30 사각 1장, 1.4배 (03_UI §2 — SKEffectNode 블러 금지).
            let glow = SKSpriteNode(
                color: accent.withAlphaComponent(Palette.glowAlpha),
                size: CGSize(width: optionSize.width * Palette.glowScale,
                             height: optionSize.height * Palette.glowScale)
            )
            glow.position = center
            addDynamicNode(glow)
        }

        let face = SKSpriteNode(color: Palette.ink700, size: optionSize)
        face.position = center
        addDynamicNode(face, action: .selectAvatar(characterID))

        let border = SKShapeNode(rect: CGRect(
            x: (center.x - optionSize.width / 2).rounded(),
            y: (center.y - optionSize.height / 2).rounded(),
            width: optionSize.width, height: optionSize.height
        ))
        border.fillColor = .clear
        border.strokeColor = selected ? accent : Palette.line500
        border.lineWidth = UILayout.v3BorderWidth
        addDynamicNode(border)

        let portraitSide = UILayout.R5.profileAvatarOptionPortraitSide
        let portrait = SKSpriteNode(texture: PixelPortraitSprite.texture(for: characterID))
        portrait.size = CGSize(width: portraitSide, height: portraitSide)
        portrait.position = CGPoint(x: center.x,
                                    y: center.y + UILayout.R5.profileAvatarOptionPortraitOffsetY)
        addDynamicNode(portrait)

        let label = makeLabel(text: characterID.displayName, token: Typography.V3.caption,
                              color: selected ? Palette.textHi : Palette.textLo)
        label.position = CGPoint(x: center.x,
                                 y: center.y + UILayout.R5.profileAvatarOptionLabelOffsetY)
        addDynamicNode(label)
    }

    private func makeButton(text: String, size: CGSize,
                            action: ProfileDetailAction,
                            variant: PixelButtonNode.Variant) -> PixelButtonNode {
        let button = PixelButtonNode(title: text, variant: variant, size: size)
        // 씬 touchesBegan → action(at:) 라우팅 보존 — 버튼 자체 터치 처리 차단.
        button.isUserInteractionEnabled = false
        actionTargets.append((node: button, action: action))
        return button
    }

    private func layoutButtonRow(_ buttons: [PixelButtonNode], y: CGFloat) {
        guard !buttons.isEmpty else { return }
        let gap = UILayout.R5.profileButtonGap
        let totalWidth = buttons.reduce(CGFloat.zero) { result, button in
            result + button.calculateAccumulatedFrame().width
        } + gap * CGFloat(max(0, buttons.count - 1))
        var cursorX = -totalWidth / 2
        for button in buttons {
            let width = button.calculateAccumulatedFrame().width
            button.position = CGPoint(x: (cursorX + width / 2).rounded(), y: y)
            cursorX += width + gap
            addDynamicNode(button)
        }
    }

    private func makeLabel(text: String, token: Typography.V3.Token,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: token.fontName)
        label.text = text
        label.fontSize = token.size
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    private func addDynamicNode(_ node: SKNode, action: ProfileDetailAction? = nil) {
        dynamicNodes.append(node)
        if let action = action {
            actionTargets.append((node: node, action: action))
        }
        dialog.contentNode.addChild(node)
    }
}
