//
//  SettingsDialogNode.swift
//  GanhoMusic Shared
//
//  R9 #1+#4 — 설정 다이얼로그 (PixelDialogNode 조립 — 신규 UI 패턴 발명 금지).
//  모드 2종: settings(효과음/진동 토글 + 정책/크레딧 + 닫기) / credits(인앱 텍스트 + 뒤로).
//  모드 전환 = dynamicNodes 전부 제거 후 재구성 (ProfileDetailOverlayNode 동형 — 좀비 0).
//  토글 상태 표현 = ScoreboardScene 탭 전례 동형 *재생성*: ON=secondary / OFF=ghost.
//  버튼은 PixelButtonNode onTap 자체 처리 (GameScene pause 다이얼로그 전례 — 양 호스트 공용).
//  정책 행은 privacyPolicyURLString이 빈 문자열이면 생성하지 않는다 (graceful — 좀비 아님).
//

import SpriteKit
import UIKit

extension Notification.Name {
    /// R9 #4 — 외부 링크 열기 요청 (씬 → GameViewController가 SFSafariViewController로).
    /// userInfo[UILayout.R9.externalLinkURLUserInfoKey] = URL. (.ganhoProfileNameEditRequested 패턴 동형)
    static let ganhoExternalLinkRequested = Notification.Name("ganhoExternalLinkRequested")
}

/// v3 설정 다이얼로그. PixelDialogNode(딤+패널)를 소유하고 present/dismiss를 위임.
/// 호스트(StartScene·GameScene)는 onClose에서 보유 참조를 nil로 정리한다.
final class SettingsDialogNode: SKNode {

    /// 2모드 — switch exhaustive, default 금지.
    enum Mode {
        case settings, credits
    }

    /// 닫기 완료(퇴장 애니 후 removeFromParent 직후) 콜백 — 호스트 참조 정리용. [weak self] 연결.
    var onClose: (() -> Void)?

    private let dialog: PixelDialogNode
    private let settings = SettingsRepository()
    /// 호스트 소유 햅틱 주입 (PixelButtonNode 컨벤션 — 싱글톤화 금지). nil = SFX만.
    private let haptics: HapticsManager?
    /// 모드별 재구성 노드 — 전환마다 전부 제거 후 재생성 (좀비 0).
    private var dynamicNodes: [SKNode] = []
    private(set) var mode: Mode = .settings

    // MARK: - Init
    init(haptics: HapticsManager? = nil) {
        self.haptics = haptics
        // 제목은 모드별 자체 헤더로 — PixelDialogNode 헤더는 init 고정이라 비사용 (ProfileDetail 동형).
        dialog = PixelDialogNode(panelSize: UILayout.R9.settingsPanelSize)
        super.init()
        name = "settingsDialog"
        addChild(dialog)
        reconfigure(mode: .settings)
    }

    @available(*, unavailable, message: "Use init(haptics:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Present / Dismiss (PixelDialogNode 위임)
    /// position: 씬 부착 = 씬 중앙 / cameraNode 부착 = .zero (카메라 좌표계 중심).
    func present(in parent: SKNode, screenSize: CGSize, position: CGPoint) {
        removeFromParent()   // 멱등
        parent.addChild(self)
        self.position = position
        dialog.present(in: self, screenSize: screenSize)
    }

    /// 화면 크기 변경 대응 — 딤 커버 재설정 (LoginChoiceDialogNode.updateLayout 동형).
    func updateLayout(in scene: SKScene) {
        position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        dialog.present(in: self, screenSize: scene.size)
    }

    /// 닫기 — 퇴장 애니(0.22s) 후 자신 제거 + onClose 1회 (dialog.isDismissing이 연타 차단).
    private func close() {
        dialog.dismiss { [weak self] in
            guard let self = self else { return }
            self.removeFromParent()
            self.onClose?()
        }
    }

    // MARK: - Mode (전부 제거 후 재구성 — 좀비 0)
    private func reconfigure(mode: Mode) {
        self.mode = mode
        dynamicNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }
        dynamicNodes.removeAll()
        switch mode {
        case .settings:
            buildSettings()
        case .credits:
            buildCredits()
        }
    }

    // MARK: - Settings Mode
    private func buildSettings() {
        addHeader(title: UILayout.R9.settingsTitleText)

        // R12 [A④] — BGM 토글 (효과음/진동 동형 재생성 패턴). BGMPlayer.play() 게이트가 소비,
        // 인게임 라이브 반영은 dismissPauseMenu 복귀 시 재평가 1곳 (SPEC 기능 9-5).
        let bgmOn = settings.isBGMEnabled
        let bgmButton = PixelButtonNode(
            title: bgmOn ? UILayout.R12.settingsBGMOnText : UILayout.R12.settingsBGMOffText,
            variant: bgmOn ? .secondary : .ghost,
            size: UILayout.R9.settingsToggleButtonSize,
            haptics: haptics
        )
        bgmButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.settings.setBGMEnabled(!self.settings.isBGMEnabled)
            self.reconfigure(mode: .settings)
        }
        layoutRow([bgmButton], y: UILayout.R12.settingsBGMRowY)

        // 효과음 토글 — 탭 시 값 반전 + 행 재생성 (불변 스타일 PixelButtonNode 정석).
        let sfxOn = settings.isSFXEnabled
        let sfxButton = PixelButtonNode(
            title: sfxOn ? UILayout.R9.settingsSFXOnText : UILayout.R9.settingsSFXOffText,
            variant: sfxOn ? .secondary : .ghost,
            size: UILayout.R9.settingsToggleButtonSize,
            haptics: haptics
        )
        sfxButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.settings.setSFXEnabled(!self.settings.isSFXEnabled)
            self.reconfigure(mode: .settings)
        }
        layoutRow([sfxButton], y: UILayout.R9.settingsSFXRowY)

        // 진동 토글 — 동형.
        let hapticsOn = settings.isHapticsEnabled
        let hapticsButton = PixelButtonNode(
            title: hapticsOn ? UILayout.R9.settingsHapticsOnText : UILayout.R9.settingsHapticsOffText,
            variant: hapticsOn ? .secondary : .ghost,
            size: UILayout.R9.settingsToggleButtonSize,
            haptics: haptics
        )
        hapticsButton.onTap = { [weak self] in
            guard let self = self else { return }
            self.settings.setHapticsEnabled(!self.settings.isHapticsEnabled)
            self.reconfigure(mode: .settings)
        }
        layoutRow([hapticsButton], y: UILayout.R9.settingsHapticsRowY)

        // 정책/크레딧 행 — 정책은 URL 확정 시에만 행 생성 (#4 graceful).
        var linkButtons: [PixelButtonNode] = []
        if !UILayout.R9.privacyPolicyURLString.isEmpty,
           let url = URL(string: UILayout.R9.privacyPolicyURLString) {
            let privacyButton = PixelButtonNode(
                title: UILayout.R9.settingsPrivacyButtonText,
                variant: .ghost,
                size: UILayout.R9.settingsPrivacyButtonSize,
                haptics: haptics
            )
            privacyButton.onTap = {
                NotificationCenter.default.post(
                    name: .ganhoExternalLinkRequested,
                    object: nil,
                    userInfo: [UILayout.R9.externalLinkURLUserInfoKey: url]
                )
            }
            linkButtons.append(privacyButton)
        }
        let creditsButton = PixelButtonNode(
            title: UILayout.R9.settingsCreditsButtonText,
            variant: .ghost,
            size: UILayout.R9.settingsCreditsButtonSize,
            haptics: haptics
        )
        creditsButton.onTap = { [weak self] in self?.reconfigure(mode: .credits) }
        linkButtons.append(creditsButton)
        layoutRow(linkButtons, y: UILayout.R9.settingsLinkRowY)

        let closeButton = PixelButtonNode(
            title: UILayout.profileDetailCloseText,
            variant: .secondary,
            size: UILayout.R9.settingsCloseButtonSize,
            haptics: haptics
        )
        closeButton.onTap = { [weak self] in self?.close() }
        layoutRow([closeButton], y: UILayout.R9.settingsCloseRowY)
    }

    // MARK: - Credits Mode (#4 — 인앱 텍스트)
    private func buildCredits() {
        addHeader(title: UILayout.R9.settingsCreditsTitleText)

        let body = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
        body.text = UILayout.R9.creditsBodyText
        body.fontSize = Typography.V3.caption.size
        body.fontColor = Palette.textLo
        body.numberOfLines = 0
        body.preferredMaxLayoutWidth = UILayout.R9.creditsBodyMaxWidth
        body.horizontalAlignmentMode = .center
        body.verticalAlignmentMode = .top
        body.position = CGPoint(x: 0, y: UILayout.R9.creditsBodyTopY)
        addDynamic(body)

        let backButton = PixelButtonNode(
            title: UILayout.R9.settingsBackButtonText,
            variant: .ghost,
            size: UILayout.R9.settingsCloseButtonSize,
            haptics: haptics
        )
        backButton.onTap = { [weak self] in self?.reconfigure(mode: .settings) }
        layoutRow([backButton], y: UILayout.R9.settingsCloseRowY)
    }

    // MARK: - Pieces
    /// 모드별 헤더 — PixelPanelNode 헤더 시각 동형 (좌측 4px 액센트 바 + h2 좌정렬).
    private func addHeader(title: String) {
        let leftX = (-UILayout.R9.settingsPanelSize.width / 2 + UILayout.Space.s16).rounded()
        let bar = SKSpriteNode(
            color: Palette.gold,
            size: CGSize(width: UILayout.Space.s4, height: UILayout.Space.s16)
        )
        bar.position = CGPoint(x: leftX + UILayout.Space.s4 / 2, y: UILayout.R9.settingsHeaderY)
        addDynamic(bar)

        let label = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
        label.text = title
        label.fontSize = Typography.V3.h2.size
        label.fontColor = Palette.textHi
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: (leftX + UILayout.Space.s4 + UILayout.Space.s8).rounded(),
                                 y: UILayout.R9.settingsHeaderY)
        addDynamic(label)
    }

    /// 가로 중앙 정렬 행 배치 — 시각 폭 합 + s12 간격 (LoginChoiceDialogNode 배치 동형).
    private func layoutRow(_ buttons: [PixelButtonNode], y: CGFloat) {
        guard !buttons.isEmpty else { return }
        let gap = UILayout.Space.s12
        let totalWidth = buttons.reduce(CGFloat.zero) { result, button in
            result + button.calculateAccumulatedFrame().width
        } + gap * CGFloat(max(0, buttons.count - 1))
        var cursorX = -totalWidth / 2
        for button in buttons {
            let width = button.calculateAccumulatedFrame().width
            button.position = CGPoint(x: (cursorX + width / 2).rounded(), y: y)
            cursorX += width + gap
            addDynamic(button)
        }
    }

    private func addDynamic(_ node: SKNode) {
        dynamicNodes.append(node)
        dialog.contentNode.addChild(node)
    }

    #if DEBUG
    /// 스크린샷 자동화 전용 — 크레딧 모드 직행 (simctl 터치 주입 불가 우회,
    /// GANHO_AUTO_PAUSE 전례 동형. 릴리즈 빌드 비포함).
    func debugShowCredits() {
        reconfigure(mode: .credits)
    }
    #endif
}
