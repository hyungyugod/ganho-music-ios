//
//  LoginChoiceDialogNode.swift
//  GanhoMusic Shared
//
//  R4 §F-1 — 로그인 선택 다이얼로그 (PixelDialogNode 기반).
//  게스트/Apple/취소 PixelButtonNode 3개 + 상태 텍스트. busy 시 버튼 제거+상태 표시,
//  idle 복귀 시 재구성 — isHidden/alpha 게이트 0 (좀비 금지).
//  Firebase 로직은 보유하지 않는다 — 순수 시각 + 콜백 (StartScene이 플로우 소유).
//  UX 카피는 기존 UILayout.loginChoice* 텍스트 상수 그대로 재사용 (§E-9).
//

import SpriteKit
import UIKit

/// v3 로그인 선택 다이얼로그. PixelDialogNode(딤+패널)를 소유하고 present/dismiss를 위임.
final class LoginChoiceDialogNode: SKNode {

    /// 2모드 — switch exhaustive, default 금지 (idle/busy).
    enum Mode {
        case idle, busy
    }

    /// 버튼 콜백 — 호출측(StartScene)이 [weak self]로 연결.
    var onGuest: (() -> Void)?
    var onApple: (() -> Void)?
    var onCancel: (() -> Void)?

    private let dialog: PixelDialogNode
    private let bodyLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    private let statusLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    private var buttons: [PixelButtonNode] = []
    private(set) var mode: Mode = .idle

    // MARK: - Init
    override init() {
        dialog = PixelDialogNode(panelSize: UILayout.R4.loginDialogPanelSize,
                                 title: UILayout.loginChoiceTitleText,
                                 accent: Palette.coral)
        super.init()
        addChild(dialog)

        // 본문 — 기존 카피 그대로 (loginChoiceBodyText).
        bodyLabel.text = UILayout.loginChoiceBodyText
        bodyLabel.fontSize = Typography.V3.caption.size
        bodyLabel.fontColor = Palette.textLo
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.R4.loginDialogBodyMaxWidth
        bodyLabel.position = CGPoint(x: 0, y: UILayout.R4.loginDialogBodyOffsetY)
        dialog.contentNode.addChild(bodyLabel)

        // 상태 텍스트 — busy/실패 메시지. 평시 빈 문자열 (라벨 자체는 항상 부착 — 상태 텍스트 슬롯).
        statusLabel.text = ""
        statusLabel.fontSize = Typography.V3.caption.size
        statusLabel.fontColor = Palette.gold
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: 0, y: UILayout.R4.loginDialogStatusOffsetY)
        dialog.contentNode.addChild(statusLabel)

        rebuildButtons()
    }

    @available(*, unavailable, message: "Use init() instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Present / Dismiss (PixelDialogNode 위임)
    /// 씬 중앙에 등장. 딤이 배후 터치를 흡수 — 노출 중 뒤 UI 오작동 차단.
    func present(in scene: SKScene) {
        removeFromParent()   // 멱등
        scene.addChild(self)
        position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        dialog.present(in: self, screenSize: scene.size)
    }

    /// 즉시 제거 — 씬 전환 직전 등 애니메이션 불필요 경로 (좀비 0).
    func removeImmediately() {
        removeAllActions()
        removeFromParent()
    }

    /// 화면 크기 변경 대응 — 딤 커버 재설정 (PixelDialogNode.present 멱등 재호출).
    func updateLayout(in scene: SKScene) {
        position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        dialog.present(in: self, screenSize: scene.size)
    }

    // MARK: - Mode (busy = 버튼 제거 + 상태 / idle = 버튼 재구성 — 좀비 0)
    func setMode(_ newMode: Mode, statusText: String) {
        mode = newMode
        statusLabel.text = statusText
        switch newMode {
        case .busy:
            removeButtons()
        case .idle:
            if buttons.isEmpty {
                rebuildButtons()
            }
        }
    }

    private func removeButtons() {
        for button in buttons {
            button.removeFromParent()
        }
        buttons = []
    }

    /// 게스트(secondary) / Apple(primary) / 취소(ghost) — 가로 1행.
    private func rebuildButtons() {
        removeButtons()

        let guest = PixelButtonNode(title: UILayout.loginChoiceGuestButtonText,
                                    variant: .secondary,
                                    size: UILayout.R4.loginDialogButtonSize)
        guest.onTap = { [weak self] in self?.onGuest?() }

        let apple = PixelButtonNode(title: UILayout.loginChoiceAppleButtonText,
                                    variant: .primary,
                                    size: UILayout.R4.loginDialogButtonSize)
        apple.onTap = { [weak self] in self?.onApple?() }

        let cancel = PixelButtonNode(title: UILayout.loginChoiceCancelButtonText,
                                     variant: .ghost,
                                     size: UILayout.R4.loginDialogCancelButtonSize)
        cancel.onTap = { [weak self] in self?.onCancel?() }

        buttons = [guest, apple, cancel]

        // 가로 중앙 정렬 — 버튼 시각 폭 합 + 간격으로 배치 (정수 스냅).
        let widths = [UILayout.R4.loginDialogButtonSize.width,
                      UILayout.R4.loginDialogButtonSize.width,
                      UILayout.R4.loginDialogCancelButtonSize.width]
        let gap = UILayout.Space.s12
        let total = widths.reduce(0, +) + gap * CGFloat(widths.count - 1)
        var cursorX = -total / 2
        for (index, button) in buttons.enumerated() {
            let width = widths[index]
            button.position = CGPoint(x: (cursorX + width / 2).rounded(),
                                      y: UILayout.R4.loginDialogButtonRowY)
            cursorX += width + gap
            dialog.contentNode.addChild(button)
        }
    }
}
