//
//  PixelDialogNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 다이얼로그.
//  풀스크린 딤(ink900 alpha 0.6) + 중앙 패널(PixelPanelNode 재사용).
//  등장: 딤 페이드 인 + 패널 y +16 → 0 easeOutCubic 0.22s. 퇴장: 역재생 후 removeFromParent.
//  Firebase 로직과 무관한 순수 시각 컨테이너 — R5 계정 오버레이가 이 노드 기반으로 재구성 예정.
//

import SpriteKit
import UIKit

/// v3 다이얼로그. zPosition = ZOrder.Layer.overlay(200). 딤이 배후 터치 차단.
final class PixelDialogNode: SKNode {

    /// 패널 내부 콘텐츠 부착 슬롯 (버튼·라벨 등 — 패널 좌표계).
    let contentNode = SKNode()

    private let panel: PixelPanelNode
    private let dim: SKSpriteNode
    private var isDismissing = false

    /// 내부 적층 — 딤(0) < 패널(1) < 콘텐츠(3, 패널 내부 헤더 2 위).
    /// ignoresSiblingOrder=true 환경 — 동일 z 의존 금지, 전부 명시 분리.
    private enum InnerZ {
        static let dim: CGFloat = 0
        static let panel: CGFloat = 1
        static let content: CGFloat = 3
    }

    // MARK: - Init
    /// - Parameters:
    ///   - panelSize: 중앙 다이얼로그 패널 크기.
    ///   - title: 패널 헤더 제목 (옵션 — PixelPanelNode 헤더 슬롯).
    ///   - accent: 헤더 액센트 바 색 (옵션).
    init(panelSize: CGSize, title: String? = nil, accent: UIColor? = nil) {
        panel = PixelPanelNode(size: panelSize, title: title, accent: accent)
        dim = SKSpriteNode(color: Palette.ink900, size: .zero)
        super.init()

        zPosition = ZOrder.Layer.overlay
        // 딤이 배후 터치를 흡수 — 다이얼로그 노출 중 뒤 UI 오작동 차단.
        isUserInteractionEnabled = true

        dim.zPosition = InnerZ.dim
        addChild(dim)

        panel.zPosition = InnerZ.panel
        addChild(panel)

        contentNode.zPosition = InnerZ.content
        panel.addChild(contentNode)
    }

    @available(*, unavailable, message: "Use init(panelSize:title:accent:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Present (Motion.dialog 0.22s easeOutCubic)
    /// parent 좌표계 중앙에 등장. screenSize = 딤이 덮을 화면 크기 (scene.size).
    func present(in parent: SKNode, screenSize: CGSize) {
        removeFromParent()   // 멱등 — 이미 떠 있으면 재부착
        isDismissing = false
        parent.addChild(self)

        dim.size = screenSize
        dim.alpha = 0
        dim.run(SKAction.fadeAlpha(to: UILayout.v3DialogDimAlpha,
                                   duration: FeelTuning.Motion.dialog))

        // §5 "y +16 → 0" — 위에서 자리로 내려앉음.
        panel.position = CGPoint(x: 0, y: UILayout.Space.s16)
        panel.alpha = 0
        let settle = Tween.curved(
            SKAction.moveTo(y: 0, duration: FeelTuning.Motion.dialog), .easeOutCubic
        )
        let fadeIn = SKAction.fadeIn(withDuration: FeelTuning.Motion.dialog)
        panel.run(SKAction.group([settle, fadeIn]))
    }

    // MARK: - Dismiss (역재생 → removeFromParent — 좀비 금지)
    func dismiss(completion: (() -> Void)? = nil) {
        guard !isDismissing else { return }
        isDismissing = true

        dim.run(SKAction.fadeOut(withDuration: FeelTuning.Motion.dialog))
        let sink = Tween.curved(
            SKAction.moveTo(y: UILayout.Space.s16, duration: FeelTuning.Motion.dialog),
            .easeOutCubic
        )
        let fadeOut = SKAction.fadeOut(withDuration: FeelTuning.Motion.dialog)
        let finish = SKAction.run { [weak self] in
            self?.removeFromParent()
            completion?()
        }
        panel.run(SKAction.sequence([SKAction.group([sink, fadeOut]), finish]))
    }

    // MARK: - Touch (딤 영역 터치 흡수 — 의도적 no-op)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 배후 차단 전용. 닫기 동작은 contentNode의 버튼이 담당 (R5 정책 미정 — 보수적 무시).
    }
}
