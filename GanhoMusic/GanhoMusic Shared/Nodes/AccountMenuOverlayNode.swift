//
//  AccountMenuOverlayNode.swift
//  GanhoMusic Shared
//
//  R5 재구성 — PixelDialogNode 기반 계정 메뉴 (로그아웃/계정 삭제 확인/busy).
//  공개 계약 byte-호환: AccountMenuOverlayMode·AccountMenuAction·init·update×2·action(at:) —
//  호출측(CharacterSelectScene touchesBegan → action(at:) 라우팅, +Overlays show/hide) 변경 0.
//  터치 함정 해소: PixelDialogNode·PixelButtonNode의 isUserInteractionEnabled를 꺼서
//  씬 touchesBegan 라우팅 계약을 보존한다 (SPEC §주의사항 1 — Firebase 경로 동작 필수).
//  모드 전환 = 노드 재구성 (busy=버튼 제거, 복귀=재생성) — v2의 숨김 토글 패턴 소멸 (좀비 0).
//

import SpriteKit

enum AccountMenuOverlayMode {
    case menu
    case confirmDelete
    case busy
}

enum AccountMenuAction {
    case linkApple
    case signOut
    case requestDeleteConfirmation
    case confirmDelete
    case cancel
}

final class AccountMenuOverlayNode: SKNode {

    // MARK: - Properties
    private let dialog: PixelDialogNode
    private let titleLabel = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
    private let bodyLabel = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
    /// 현재 모드의 (버튼, 액션) 쌍 — 모드 전환마다 전부 재구성 (좀비 0).
    private var buttonTargets: [(node: PixelButtonNode, action: AccountMenuAction)] = []
    private var mode: AccountMenuOverlayMode
    private var isAppleLinked: Bool
    /// 화면 크기 변화 감지 — 같은 크기 재호출(모드 전환)에서 등장 애니 재생 방지.
    private var lastSceneSize: CGSize = .zero

    // MARK: - Init
    init(sceneSize: CGSize, isAppleLinked: Bool, mode: AccountMenuOverlayMode) {
        self.mode = mode
        self.isAppleLinked = isAppleLinked
        self.dialog = PixelDialogNode(panelSize: UILayout.R5.accountDialogPanelSize)
        super.init()
        name = "accountMenuOverlay"
        zPosition = ZOrder.accountMenuOverlayZPosition
        // 터치 함정 해소 — 다이얼로그가 터치를 삼키면 씬의 action(at:) 라우팅이 죽는다.
        dialog.isUserInteractionEnabled = false
        configureStaticLabels()
        update(sceneSize: sceneSize, isAppleLinked: isAppleLinked, mode: mode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    private func configureStaticLabels() {
        titleLabel.fontSize = Typography.V3.h2.size
        titleLabel.fontColor = Palette.textHi
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: UILayout.R5.accountDialogTitleOffsetY)
        dialog.contentNode.addChild(titleLabel)

        bodyLabel.fontSize = Typography.V3.caption.size
        bodyLabel.fontColor = Palette.textLo
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.preferredMaxLayoutWidth = UILayout.R5.accountDialogBodyMaxWidth
        bodyLabel.position = CGPoint(x: 0, y: UILayout.R5.accountDialogBodyOffsetY)
        dialog.contentNode.addChild(bodyLabel)
    }

    // MARK: - Update (공개 계약 — 시그니처 byte-호환)
    func update(sceneSize: CGSize, isAppleLinked: Bool, mode: AccountMenuOverlayMode) {
        self.mode = mode
        self.isAppleLinked = isAppleLinked
        update(sceneSize: sceneSize)
    }

    func update(sceneSize: CGSize, isAppleLinked: Bool) {
        self.isAppleLinked = isAppleLinked
        update(sceneSize: sceneSize)
    }

    private func update(sceneSize: CGSize) {
        position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        if sceneSize != lastSceneSize {
            lastSceneSize = sceneSize
            // 딤 커버 재설정 + 등장 — present는 멱등 (크기 변화·최초 1회만, 모드 전환 시 재생 0).
            dialog.present(in: self, screenSize: sceneSize)
        }
        updateText()
        rebuildButtons()
    }

    /// 카피는 기존 UILayout.accountMenu*/auth* 텍스트 상수 재사용 (R4 §E-9 패턴).
    private func updateText() {
        switch mode {
        case .menu:
            titleLabel.text = UILayout.accountMenuMenuTitleText
            bodyLabel.text = isAppleLinked
                ? UILayout.accountMenuLinkedBodyText
                : UILayout.accountMenuGuestBodyText
        case .confirmDelete:
            titleLabel.text = UILayout.accountMenuConfirmTitleText
            bodyLabel.text = UILayout.accountMenuConfirmBodyText
        case .busy:
            titleLabel.text = UILayout.accountMenuBusyTitleText
            bodyLabel.text = UILayout.accountMenuBusyBodyText
        }
    }

    // MARK: - Buttons (모드 전환 = 전부 재구성 — LoginChoiceDialogNode 패턴, isHidden 게이트 0)
    private func rebuildButtons() {
        for target in buttonTargets {
            target.node.removeFromParent()
        }
        buttonTargets = []

        let specs = buttonSpecs()
        guard !specs.isEmpty else { return }
        let gap = UILayout.R5.accountDialogButtonGap
        let total = specs.reduce(0) { $0 + $1.size.width } + gap * CGFloat(specs.count - 1)
        var cursorX = -total / 2
        for spec in specs {
            let button = PixelButtonNode(title: spec.title,
                                         variant: spec.variant,
                                         size: spec.size)
            // 씬 touchesBegan → action(at:) 라우팅 보존 — 버튼 자체 터치 처리 차단.
            button.isUserInteractionEnabled = false
            button.position = CGPoint(x: (cursorX + spec.size.width / 2).rounded(),
                                      y: UILayout.R5.accountDialogButtonRowY)
            dialog.contentNode.addChild(button)
            buttonTargets.append((node: button, action: spec.action))
            cursorX += spec.size.width + gap
        }
    }

    /// 모드별 버튼 구성. 삭제 = primary(coral 면) — destructive 위계 유지.
    private func buttonSpecs() -> [(title: String, variant: PixelButtonNode.Variant,
                                    size: CGSize, action: AccountMenuAction)] {
        let buttonSize = UILayout.R5.accountDialogButtonSize
        let cancelSize = UILayout.R5.accountDialogCancelButtonSize
        switch mode {
        case .menu:
            let accountAction: (title: String, variant: PixelButtonNode.Variant,
                                size: CGSize, action: AccountMenuAction) = isAppleLinked
                ? (UILayout.accountMenuSignOutText, .secondary, buttonSize, .signOut)
                : (UILayout.authAppleButtonText, .secondary, buttonSize, .linkApple)
            return [
                accountAction,
                (UILayout.accountMenuDeleteText, .primary, buttonSize,
                 .requestDeleteConfirmation),
                (UILayout.accountMenuCancelText, .ghost, cancelSize, .cancel)
            ]
        case .confirmDelete:
            return [
                (UILayout.accountMenuConfirmDeleteText, .primary, buttonSize, .confirmDelete),
                (UILayout.accountMenuCancelText, .ghost, cancelSize, .cancel)
            ]
        case .busy:
            return []   // busy = 버튼 제거 (재구성으로 소멸 — isHidden 아님)
        }
    }

    // MARK: - Action (공개 계약 — 씬 좌표 location → 버튼 hit-test)
    func action(at location: CGPoint) -> AccountMenuAction? {
        guard !isHidden, mode != .busy else { return nil }
        guard let parent = parent else { return nil }
        // 버튼은 dialog.contentNode 자식 — contains는 부모 좌표계 점을 받으므로 거기로 변환.
        let local = dialog.contentNode.convert(location, from: parent)
        for target in buttonTargets where target.node.contains(local) {
            ChiptuneSynth.shared.play(.uiTap)   // 씬 라우팅 경로라 버튼 자체 SFX 미발화 — 등가 보강
            return target.action
        }
        return nil
    }
}
