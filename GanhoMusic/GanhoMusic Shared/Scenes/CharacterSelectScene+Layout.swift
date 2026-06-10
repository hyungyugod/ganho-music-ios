//
//  CharacterSelectScene+Layout.swift
//  GanhoMusic Shared
//
//  R4 §F-2 — 프리뷰·캐러셀·상하단 바 구성과 배치 분리 (1파일 300줄 규칙 대응).
//  카드·텍스처는 didMove 1회 생성, 스와이프 시 위치/선택 상태만 갱신 (주의사항 5).
//

import SpriteKit

extension CharacterSelectScene {

    // MARK: - Setup (좌측 프리뷰)
    func setupPreview() {
        let spriteSize = UILayout.R4.selectPreviewSpriteSize
        let glow = SKSpriteNode(color: Palette.character(selectedCharacterID),
                                size: CGSize(width: spriteSize.width * Palette.glowScale,
                                             height: spriteSize.height * Palette.glowScale))
        glow.alpha = Palette.glowAlpha
        glow.zPosition = ZOrder.Layer.props
        previewGlow = glow
        addChild(glow)

        let sprite = SKSpriteNode()
        sprite.size = spriteSize
        sprite.zPosition = ZOrder.Layer.characters
        previewSprite = sprite
        addChild(sprite)

        previewNameLabel.fontSize = Typography.V3.h1.size
        previewNameLabel.fontColor = Palette.textHi
        previewNameLabel.horizontalAlignmentMode = .center
        previewNameLabel.verticalAlignmentMode = .center
        previewNameLabel.zPosition = ZOrder.Layer.hud
        addChild(previewNameLabel)

        previewTagLabel.fontSize = Typography.V3.caption.size
        previewTagLabel.fontColor = Palette.textLo
        previewTagLabel.horizontalAlignmentMode = .center
        previewTagLabel.verticalAlignmentMode = .center
        previewTagLabel.zPosition = ZOrder.Layer.hud
        addChild(previewTagLabel)
    }

    // MARK: - Setup (캐러셀)
    func setupCarousel() {
        carouselCrop.zPosition = ZOrder.Layer.characters
        carouselCrop.addChild(carouselContainer)
        addChild(carouselCrop)
        rebuildCarousel()
    }

    /// 카드 5장 (재)구성 — didMove 1회 + 계정 변화(언락 갱신) 시에만. 스와이프 시 호출 금지.
    func rebuildCarousel() {
        for card in carouselCards {
            card.removeFromParent()
        }
        carouselCards = characters.map { id in
            let state = unlockStates[id]
                ?? CharacterUnlockRules.state(
                    for: id,
                    graduations: graduationRepo.current,
                    scores: perDifficultyScoreRepo.current,
                    totalStars: currentTotalStarsForUnlock()   // R6 §F3 — 별 기반 OR 합류
                )
            let card = PixelCharacterCardNode(
                characterID: id,
                portraitTexture: portraitTextures[id] ?? PixelPortraitSprite.texture(for: id),
                unlockState: state
            )
            carouselContainer.addChild(card)
            return card
        }
        updateCarousel(animated: false)
    }

    // MARK: - Setup (상단·하단)
    func setupTopBar() {
        let back = PixelButtonNode(title: UILayout.R4.selectBackButtonText,
                                   variant: .ghost,
                                   size: UILayout.R4.backButtonSize)
        back.onTap = { [weak self] in self?.transitionToStart() }
        back.zPosition = ZOrder.Layer.hud
        backButton = back
        addChild(back)
        rebuildProfileChip()
    }

    /// 프로필 칩 (재)구성 — 닉네임 변경 등 계정 변화 시 텍스트 갱신 (PixelChipNode 텍스트 불변 → 재생성).
    func rebuildProfileChip() {
        profileChip?.removeFromParent()
        let chip = PixelChipNode(text: profileChipText(), style: .accent(Palette.mint))
        chip.zPosition = ZOrder.Layer.hud
        profileChip = chip
        addChild(chip)
        layoutTopBar()
    }

    private func profileChipText() -> String {
        if let nickname = homeSnapshot.authProfile?.nickname, !nickname.isEmpty {
            return nickname
        }
        if let displayName = homeSnapshot.authProfile?.displayName, !displayName.isEmpty {
            return displayName
        }
        return UILayout.R4.profileChipFallbackText
    }

    func setupFooter() {
        footerLabel.fontSize = Typography.V3.body.size
        footerLabel.fontColor = Palette.textLo
        footerLabel.horizontalAlignmentMode = .center
        footerLabel.verticalAlignmentMode = .center
        footerLabel.zPosition = ZOrder.Layer.hud
        addChild(footerLabel)

        let start = PixelButtonNode(title: UILayout.R4.selectStartButtonText,
                                    variant: .primary,
                                    size: UILayout.R4.ctaButtonSize)
        start.onTap = { [weak self] in self?.transitionToNext() }
        start.zPosition = ZOrder.Layer.hud
        startButton = start
        addChild(start)
    }

    /// 브리핑 버튼 — 스킬 보유 + 해금 캐릭터 선택 시에만 add (§F-2, isHidden 게이트 금지).
    /// 잠금 캐릭터 제외는 §C-9 흐름 보호 — 브리핑→난이도 경로의 잠금 우회 차단 (SELF_CHECK 기록).
    func updateBriefingButton() {
        let needsButton = selectedCharacterID.skill != .none && isSelectedCharacterUnlocked
        if needsButton {
            guard briefingButton == nil else { return }
            let briefing = PixelButtonNode(title: UILayout.R4.selectBriefingButtonText,
                                           variant: .ghost,
                                           size: UILayout.R4.secondaryCTAButtonSize)
            briefing.onTap = { [weak self] in self?.transitionToBriefing() }
            briefing.zPosition = ZOrder.Layer.hud
            briefingButton = briefing
            addChild(briefing)
        } else {
            briefingButton?.removeFromParent()
            briefingButton = nil
        }
        layoutFooter()
    }

    // MARK: - Layout
    func layoutScene() {
        layoutTopBar()
        layoutPreview()
        layoutCarousel()
        layoutFooter()
    }

    private func layoutTopBar() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let topY = (frame.maxY - safe.top - UILayout.v3ScreenEdgeInset
                    - UILayout.R4.backButtonSize.height * scale / 2).rounded()
        backButton?.setScale(scale)
        backButton?.position = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + UILayout.R4.backButtonSize.width * scale / 2).rounded(),
            y: topY
        )
        if let chip = profileChip {
            chip.setScale(scale)
            chip.position = CGPoint(
                x: (frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
                    - chip.chipSize.width * scale / 2).rounded(),
                y: topY
            )
        }
    }

    private func layoutPreview() {
        let scale = menuCompactScale()
        let centerX = (frame.minX + frame.width * UILayout.R4.selectPreviewCenterXRatio).rounded()
        let centerY = (frame.midY + UILayout.R4.selectPreviewCenterYOffset * scale).rounded()
        previewGlow?.setScale(scale)
        previewSprite?.setScale(scale)
        previewGlow?.position = CGPoint(x: centerX, y: centerY)
        previewSprite?.position = CGPoint(x: centerX, y: centerY)
        previewNameLabel.setScale(scale)
        previewTagLabel.setScale(scale)
        let previewHalfHeight = UILayout.R4.selectPreviewSpriteSize.height * scale / 2
        let nameY = (centerY - previewHalfHeight - UILayout.R4.selectPreviewNameGap * scale).rounded()
        previewNameLabel.position = CGPoint(x: centerX, y: nameY)
        previewTagLabel.position = CGPoint(
            x: centerX,
            y: (nameY - UILayout.R4.selectPreviewTagGap * scale).rounded()
        )
    }

    private func layoutCarousel() {
        let scale = menuCompactScale()
        let clipLeftX = frame.minX + frame.width * UILayout.R4.selectCarouselClipLeftRatio
        let clipWidth = frame.maxX - clipLeftX
        let centerY = (frame.midY + UILayout.R4.selectCarouselCenterYOffset * scale).rounded()
        carouselCrop.position = CGPoint(x: (clipLeftX + clipWidth / 2).rounded(), y: centerY)
        // 마스크 — 클립 영역 사각 1장. didChangeSize마다 크기 재설정.
        let maskHeight = UILayout.R4.characterCardSize.height * scale * Palette.glowScale
            + UILayout.Space.s48
        carouselCrop.maskNode = SKSpriteNode(
            color: Palette.textHi,
            size: CGSize(width: clipWidth, height: maskHeight)
        )
        carouselContainer.setScale(scale)
        positionCarouselCards(animated: false)
    }

    /// 카드 x = (idx − currentIndex) × step — 중앙 1 + 양옆 반쯤 (클립 경계 걸침).
    func positionCarouselCards(animated: Bool) {
        let step = (frame.width * UILayout.R4.selectCarouselStepRatio
                    / menuCompactScale()).rounded()
        for (index, card) in carouselCards.enumerated() {
            let targetX = CGFloat(index - currentIndex) * step
            card.removeAction(forKey: CharacterSelectScene.carouselSlideActionKey)
            if animated {
                let slide = Tween.curved(
                    SKAction.moveTo(x: targetX,
                                    duration: FeelTuning.R4.carouselSlideDuration),
                    .easeOutCubic
                )
                card.run(slide, withKey: CharacterSelectScene.carouselSlideActionKey)
            } else {
                card.position = CGPoint(x: targetX, y: 0)
            }
        }
    }

    private func layoutFooter() {
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        let centerX = (frame.minX + frame.width
                       * UILayout.R4.selectCarouselCenterXRatio).rounded()
        let buttonY = (frame.minY + safe.bottom
                       + UILayout.R4.ctaBottomInset * scale).rounded()
        startButton?.setScale(scale)
        briefingButton?.setScale(scale)
        if let briefing = briefingButton {
            let total = (UILayout.R4.secondaryCTAButtonSize.width
                         + UILayout.R4.selectFooterButtonGap
                         + UILayout.R4.ctaButtonSize.width) * scale
            briefing.position = CGPoint(
                x: (centerX - total / 2
                    + UILayout.R4.secondaryCTAButtonSize.width * scale / 2).rounded(),
                y: buttonY
            )
            startButton?.position = CGPoint(
                x: (centerX + total / 2
                    - UILayout.R4.ctaButtonSize.width * scale / 2).rounded(),
                y: buttonY
            )
        } else {
            startButton?.position = CGPoint(x: centerX, y: buttonY)
        }
        footerLabel.setScale(scale)
        footerLabel.position = CGPoint(
            x: centerX,
            y: (frame.minY + safe.bottom
                + UILayout.R4.selectFooterLabelBottomInset * scale).rounded()
        )
    }

    // MARK: - Selection Visuals (프리뷰·하단 라벨 갱신)
    func updatePreviewContent() {
        guard let sprite = previewSprite else { return }
        let unlocked = isSelectedCharacterUnlocked
        if let textures = previewTextures[selectedCharacterID], !textures.isEmpty {
            sprite.removeAction(forKey: CharacterSelectScene.previewWalkActionKey)
            sprite.texture = textures[0]
            let walk = SKAction.animate(with: textures,
                                        timePerFrame: FeelTuning.R4.previewStepDuration,
                                        resize: false,
                                        restore: false)
            sprite.run(SKAction.repeatForever(walk), withKey: CharacterSelectScene.previewWalkActionKey)
        }
        // 잠금 — 실루엣 (ink600 colorBlend, 카드와 동일 처리).
        sprite.color = Palette.ink600
        sprite.colorBlendFactor = unlocked ? 0 : 1
        previewGlow?.color = Palette.character(selectedCharacterID)
        previewNameLabel.text = selectedCharacterID.displayName
        previewNameLabel.fontColor = unlocked ? Palette.textHi : Palette.textLo
        previewTagLabel.text = selectedCharacterID.tag
    }

    /// 스킬 요약 *1줄* 라벨 (§F-2 — fullDescription은 브리핑 씬 담당, 여기선 짧은 요약).
    func updateFooterContent() {
        let unlockState = unlockStates[selectedCharacterID]
        if unlockState?.isUnlocked == true {
            let skill = selectedCharacterID.skill
            footerLabel.text = skill == .none
                ? UILayout.R4.selectFooterNoSkillText
                : "\(UILayout.R4.selectFooterSkillPrefix)\(skill.displayName) · \(UILayout.R4.briefingChipRangePrefix)\(skill.rangeText)"
        } else {
            footerLabel.text = unlockState?.requirementText ?? UILayout.characterHomeLockedText
        }
    }
}
