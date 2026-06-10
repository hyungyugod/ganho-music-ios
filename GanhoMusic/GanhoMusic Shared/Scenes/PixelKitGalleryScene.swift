//
//  PixelKitGalleryScene.swift
//  GanhoMusic Shared
//
//  R3 DEBUG 전용 — Pixel 컴포넌트 키트 "단독 렌더 확인" 갤러리 (SPEC 기능 7).
//  파일 전체 #if DEBUG — 릴리즈 빌드에 0바이트 기여.
//  부팅: 스킴 환경변수 PIXELKIT_GALLERY=1 (GameViewController DEBUG 분기).
//

#if DEBUG
import SpriteKit
import UIKit

/// 6컴포넌트 + NightShiftBackdropNode 전수 배치 갤러리.
/// 버튼 = 탭 SFX·눌림 애니 / 카드 = 탭 선택 토글 / 다이얼로그 = present·dismiss 확인.
final class PixelKitGalleryScene: SKScene {

    private var animatedBar: PixelProgressBarNode?
    private var cards: [PixelCardNode] = []
    private var dialog: PixelDialogNode?

    /// 갤러리 데모 보조 수치 — DEBUG 전용 배치 값 (릴리즈 미포함, 토큰 외 재량).
    private enum Demo {
        static let panelSize = CGSize(width: 280, height: 150)
        static let buttonSize = CGSize(width: 160, height: 44)
        static let barSize = CGSize(width: 220, height: 10)
        static let cardSize = CGSize(width: 120, height: 160)
        static let dialogPanelSize = CGSize(width: 320, height: 180)
        static let staticBarProgress: CGFloat = 0.6
        static let animLoopPeriod: TimeInterval = 2.0
        static let columnXRatio: (left: CGFloat, center: CGFloat, right: CGFloat) = (0.2, 0.5, 0.8)
    }

    // MARK: - Factory
    class func newGalleryScene() -> PixelKitGalleryScene {
        let scene = PixelKitGalleryScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
        return scene
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = Palette.ink900
        removeAllChildren()   // resize/재진입 멱등
        cards.removeAll()
        animatedBar = nil
        dialog = nil
        buildGallery()
    }

    // MARK: - Build
    private func buildGallery() {
        // ① 공통 배경 — R3 유일 배선처 (기존 씬 부착 금지, SPEC 주의사항 8).
        let backdrop = NightShiftBackdropNode(size: size)
        backdrop.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(backdrop)

        let leftX = (size.width * Demo.columnXRatio.left).rounded()
        let centerX = (size.width * Demo.columnXRatio.center).rounded()
        let rightX = (size.width * Demo.columnXRatio.right).rounded()
        let topY = (size.height - UILayout.v3ScreenEdgeInset - Demo.panelSize.height / 2).rounded()

        // ② 패널 (헤더 포함)
        let panel = PixelPanelNode(size: Demo.panelSize, title: "야간 병동", accent: Palette.mint)
        panel.position = CGPoint(x: leftX, y: topY - UILayout.Space.s24)
        panel.zPosition = ZOrder.Layer.hud
        addChild(panel)

        // ③ 버튼 3변형 (탭 SFX·눌림 애니 — primary는 다이얼로그 데모 트리거)
        buildButtons(at: CGPoint(x: leftX, y: panel.position.y
                                 - Demo.panelSize.height / 2 - UILayout.Space.s48))

        // ④ 칩 3변형
        buildChips(at: CGPoint(x: centerX, y: topY))

        // ⑤ 진행바 — 고정 0.6 + 2초 주기 0→1 반복. 칩 3개 열(높이+간격 ×3) 아래로 배치.
        let chipsColumnHeight = (UILayout.v3ChipHeight + UILayout.v3MinElementGap) * 3
        buildProgressBars(at: CGPoint(x: centerX,
                                      y: (topY - chipsColumnHeight - UILayout.Space.s24).rounded()))

        // ⑥ 카드 2장 (탭 선택 토글)
        buildCards(centerX: rightX, y: topY - Demo.cardSize.height / 2)
    }

    private func buildButtons(at origin: CGPoint) {
        let variants: [(String, PixelButtonNode.Variant)] = [
            ("출발 (다이얼로그)", .primary), ("보조", .secondary), ("뒤로", .ghost)
        ]
        for (index, (title, variant)) in variants.enumerated() {
            let button = PixelButtonNode(title: title, variant: variant, size: Demo.buttonSize)
            let stepY = Demo.buttonSize.height + UILayout.v3MinElementGap
            button.position = CGPoint(x: origin.x, y: (origin.y - CGFloat(index) * stepY).rounded())
            button.zPosition = ZOrder.Layer.hud
            if variant == .primary {
                button.onTap = { [weak self] in
                    self?.presentDemoDialog()
                }
            }
            addChild(button)
        }
    }

    private func buildChips(at origin: CGPoint) {
        let chips: [PixelChipNode] = [
            PixelChipNode(text: "정보 칩", style: .info),
            PixelChipNode(text: "액센트 칩", style: .accent(Palette.violet)),
            PixelChipNode(text: "잠금 칩", style: .locked)
        ]
        for (index, chip) in chips.enumerated() {
            let stepY = UILayout.v3ChipHeight + UILayout.v3MinElementGap
            chip.position = CGPoint(x: origin.x, y: (origin.y - CGFloat(index) * stepY).rounded())
            chip.zPosition = ZOrder.Layer.hud
            addChild(chip)
        }
    }

    private func buildProgressBars(at origin: CGPoint) {
        let staticBar = PixelProgressBarNode(size: Demo.barSize, fillColor: Palette.gold)
        staticBar.position = origin
        staticBar.zPosition = ZOrder.Layer.hud
        staticBar.setProgress(Demo.staticBarProgress, animated: false)
        addChild(staticBar)

        let animBar = PixelProgressBarNode(size: Demo.barSize, fillColor: Palette.mint)
        animBar.position = CGPoint(x: origin.x,
                                   y: (origin.y - Demo.barSize.height - UILayout.Space.s16).rounded())
        animBar.zPosition = ZOrder.Layer.hud
        addChild(animBar)
        animatedBar = animBar

        // 2초 주기 0→1 반복 — setProgress(animated:)가 채움 애니 담당, 루프는 씬이 구동.
        let loop = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.animatedBar?.setProgress(0, animated: false)
                self?.animatedBar?.setProgress(1, animated: true)
            },
            SKAction.wait(forDuration: Demo.animLoopPeriod)
        ]))
        animBar.run(loop)
    }

    private func buildCards(centerX: CGFloat, y: CGFloat) {
        let accents = [Palette.gold, Palette.coral]
        for (index, accent) in accents.enumerated() {
            let card = PixelCardNode(size: Demo.cardSize, accent: accent)
            let offset = (CGFloat(index) - 0.5) * (Demo.cardSize.width + UILayout.Space.s24)
            card.position = CGPoint(x: (centerX + offset).rounded(), y: y - UILayout.Space.s24)
            card.zPosition = ZOrder.Layer.hud

            let label = SKLabelNode(fontNamed: Typography.V3.caption.fontName)
            label.text = "카드 \(index + 1)"
            label.fontSize = Typography.V3.caption.size
            label.fontColor = Palette.textHi
            label.verticalAlignmentMode = .center
            card.contentNode.addChild(label)

            addChild(card)
            cards.append(card)
        }
    }

    // MARK: - Dialog Demo
    private func presentDemoDialog() {
        let dialog = PixelDialogNode(panelSize: Demo.dialogPanelSize,
                                     title: "다이얼로그", accent: Palette.coral)
        let close = PixelButtonNode(title: "닫기", variant: .secondary, size: Demo.buttonSize)
        close.position = CGPoint(x: 0, y: (-Demo.dialogPanelSize.height / 2
                                           + UILayout.Space.s16 + Demo.buttonSize.height / 2).rounded())
        close.onTap = { [weak self] in
            self?.dialog?.dismiss { }
            self?.dialog = nil
        }
        dialog.contentNode.addChild(close)
        dialog.position = CGPoint(x: frame.midX, y: frame.midY)
        dialog.present(in: self, screenSize: size)
        self.dialog = dialog
    }

    // MARK: - Touch (카드 선택 토글 — 카드는 씬이 판정, 03_UI §5 컨벤션)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for card in cards where card.calculateAccumulatedFrame().contains(location) {
            card.setSelected(!card.isSelected, animated: true)
            return
        }
    }
}
#endif
