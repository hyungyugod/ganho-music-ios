//
//  PixelButtonNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 버튼 3변형.
//  primary(coral 면+ink900 글자) / secondary(ink700 면+textHi) / ghost(보더만+textHi).
//  눌림(0.06s linear): 콘텐츠 y −2pt(섀도 고정 → 시각 오프셋 3→1) + 표면 어둡게.
//  발화: uiTap SFX + 주입 햅틱(옵셔널 — HapticsManager 싱글톤화 금지, SPEC 불일치 기록 12) + onTap.
//  R4 정비(§F-6): ghost 영구 투명 faceNode 생성 생략(faceNode 옵셔널화 — R3 P2 ①) +
//  primary 액센트 주입(면+섀도 색 쌍 — DifficultySelect 시작 버튼 소비).
//

import SpriteKit
import UIKit

/// v3 버튼. 직각 픽셀 면 + 하드섀도 + 최소 44pt 터치 영역.
final class PixelButtonNode: SKNode {

    /// 3변형 — switch exhaustive, default 금지.
    enum Variant {
        case primary, secondary, ghost
    }

    /// 발화 콜백. 호출측은 [weak self] 캡처 필수 (씬 보유 시 순환 참조 방지).
    var onTap: (() -> Void)?

    private let variant: Variant
    private let visualSize: CGSize
    private let haptics: HapticsManager?
    /// 눌림 이동 대상 (면 + 보더 + 라벨). 섀도는 고정 — 시각 오프셋 3→1 자동 성립.
    private let contentNode = SKNode()
    /// R4 — ghost는 면 자체를 만들지 않는다 (영구 투명 노드 생성 생략 — R3 P2 ①).
    private let faceNode: SKSpriteNode?
    private let borderNode: SKShapeNode?
    /// R4 — primary 액센트 주입 시 색 교체 대상 (ghost는 섀도도 없음 — nil).
    private var shadowNode: SKSpriteNode?
    private var isPressed = false
    /// R4 — primary 액센트 오버라이드 (면, 섀도/눌림면 색 쌍). nil = 기존 coral/coralDeep.
    private var primaryAccent: (face: UIColor, shadow: UIColor)?

    /// 내부 적층 — 섀도(0) < 콘텐츠(1: 면 < 보더 < 라벨).
    private enum InnerZ {
        static let shadow: CGFloat = 0
        static let content: CGFloat = 1
        static let face: CGFloat = 0
        static let border: CGFloat = 1
        static let label: CGFloat = 2
    }

    /// 눌림 액션 키 — withKey 멱등 (연타 시 자동 교체).
    private static let pressActionKey = "pixelButtonPress"

    // MARK: - Init
    /// - Parameters:
    ///   - title: 버튼 글자 (body 토큰).
    ///   - variant: 3변형.
    ///   - size: 시각 크기. 터치 영역은 최소 44pt로 자동 확장.
    ///   - haptics: 씬 소유 HapticsManager 주입 (기본 nil — 무햅틱).
    init(title: String, variant: Variant, size: CGSize, haptics: HapticsManager? = nil) {
        self.variant = variant
        self.visualSize = size
        self.haptics = haptics

        switch variant {
        case .primary, .secondary:
            faceNode = SKSpriteNode(color: Self.faceColor(variant: variant, pressed: false),
                                    size: size)
        case .ghost:
            faceNode = nil   // 보더+라벨만 — 투명 면 좀비 생성 0 (R4 §F-6)
        }
        switch variant {
        case .primary:
            borderNode = nil
        case .secondary, .ghost:
            borderNode = Self.makeBorder(size: size,
                                         color: Self.borderColor(variant: variant,
                                                                 pressed: false))
        }
        super.init()

        #if DEBUG
        // P2 ② 배선 — 눌림 섀도 시각 오프셋 정합: |하드섀도 y| − 눌림 하강 = 1 (문서화 상수 검증).
        assert(abs(UILayout.v3HardShadowOffset.dy) - UILayout.v3ButtonPressOffsetY
                == UILayout.v3ButtonPressedShadowGap,
               "v3ButtonPressedShadowGap 정합 위반 — 하드섀도/눌림 토큰을 함께 수정하라")
        #endif

        isUserInteractionEnabled = true
        buildHierarchy(title: title)
    }

    @available(*, unavailable, message: "Use init(title:variant:size:haptics:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Build
    private func buildHierarchy(title: String) {
        // 터치 타깃 — 시각 크기가 44pt 미만이어도 히트 영역 보장 (03_UI §5 최소 터치 44pt).
        // SpriteKit 터치 배달은 자식 프레임 합 기준 — 투명 *기능* 노드 1장으로 영역을 확정.
        // (좀비 패턴 아님: 숨긴 시각 잔존이 아니라 처음부터 히트 전용 — RunButtonNode 확장 컨벤션 동계.)
        let hitTarget = SKSpriteNode(color: .clear, size: hitRect.size)
        hitTarget.zPosition = InnerZ.shadow
        addChild(hitTarget)

        // 하드섀도 — ghost는 면이 없어 섀도 생략 (보더만 변형).
        if variant != .ghost {
            let shadow = SKSpriteNode(color: Self.shadowColor(variant: variant), size: visualSize)
            shadow.position = CGPoint(x: UILayout.v3HardShadowOffset.dx,
                                      y: UILayout.v3HardShadowOffset.dy)
            shadow.zPosition = InnerZ.shadow
            addChild(shadow)
            shadowNode = shadow
        }

        contentNode.zPosition = InnerZ.content
        addChild(contentNode)

        if let faceNode = faceNode {
            faceNode.zPosition = InnerZ.face
            contentNode.addChild(faceNode)
        }

        if let borderNode = borderNode {
            borderNode.zPosition = InnerZ.border
            contentNode.addChild(borderNode)
        }

        let label = SKLabelNode(fontNamed: Typography.V3.body.fontName)
        label.text = title
        label.fontSize = Typography.V3.body.size
        label.fontColor = Self.titleColor(variant: variant)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.zPosition = InnerZ.label
        contentNode.addChild(label)
    }

    private static func makeBorder(size: CGSize, color: UIColor) -> SKShapeNode {
        let rect = CGRect(x: (-size.width / 2).rounded(),
                          y: (-size.height / 2).rounded(),
                          width: size.width.rounded(),
                          height: size.height.rounded())
        let border = SKShapeNode(rect: rect)   // 직각 — 패널만 라운드 허용 (03_UI §4)
        border.fillColor = .clear
        border.strokeColor = color
        border.lineWidth = UILayout.v3BorderWidth
        return border
    }

    // MARK: - Primary Accent (R4 §F-6 — DifficultySelect 시작 버튼이 소비)
    /// primary 변형의 면/섀도 색 쌍 교체. 기본값은 coral/coralDeep — 기존 호출부 무변경.
    /// secondary/ghost에는 의미 없음 — primary 외 호출은 무시 (시각 일관성 보호).
    func setPrimaryAccent(face: UIColor, shadow: UIColor) {
        guard variant == .primary else { return }
        primaryAccent = (face, shadow)
        faceNode?.color = currentFaceColor(pressed: isPressed)
        shadowNode?.color = shadow
    }

    /// 액센트 오버라이드 반영 면색 — primary 눌림은 섀도(Deep)색 면.
    private func currentFaceColor(pressed: Bool) -> UIColor {
        if variant == .primary, let accent = primaryAccent {
            return pressed ? accent.shadow : accent.face
        }
        return Self.faceColor(variant: variant, pressed: pressed)
    }

    // MARK: - Variant Colors (토큰 경유 — 03_UI §5)
    private static func faceColor(variant: Variant, pressed: Bool) -> UIColor {
        switch variant {
        case .primary:   return pressed ? Palette.coralDeep : Palette.coral
        case .secondary: return pressed ? Palette.ink600 : Palette.ink700
        case .ghost:     return Palette.ink900.withAlphaComponent(0)   // 미사용 — 면 미생성 (R4)
        }
    }

    private static func borderColor(variant: Variant, pressed: Bool) -> UIColor {
        switch variant {
        case .primary:   return Palette.coralDeep
        case .secondary: return Palette.line500
        case .ghost:     return pressed ? Palette.coral : Palette.line500   // 눌림 = 보더 액센트 강조
        }
    }

    private static func titleColor(variant: Variant) -> UIColor {
        switch variant {
        case .primary:           return Palette.ink900
        case .secondary, .ghost: return Palette.textHi
        }
    }

    private static func shadowColor(variant: Variant) -> UIColor {
        switch variant {
        case .primary:           return Palette.coralDeep
        case .secondary, .ghost: return Palette.ink900
        }
    }

    // MARK: - Hit Area (최소 44pt 보장 — 03_UI §5)
    /// 자기 좌표계 히트 영역 — 시각 크기와 44pt 중 큰 쪽.
    private var hitRect: CGRect {
        let width = max(visualSize.width, UILayout.v3MinTouchSide)
        let height = max(visualSize.height, UILayout.v3MinTouchSide)
        return CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
    }

    // MARK: - Press Visual (0.06s linear — §9 표가 linear 명시)
    private func setPressed(_ pressed: Bool) {
        guard isPressed != pressed else { return }
        isPressed = pressed
        let targetY = pressed ? -UILayout.v3ButtonPressOffsetY : 0
        contentNode.removeAction(forKey: Self.pressActionKey)
        contentNode.run(SKAction.moveTo(y: targetY, duration: FeelTuning.Motion.buttonPress),
                        withKey: Self.pressActionKey)
        faceNode?.color = currentFaceColor(pressed: pressed)
        borderNode?.strokeColor = Self.borderColor(variant: variant, pressed: pressed)
    }

    // MARK: - Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        setPressed(hitRect.contains(touch.location(in: self)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firedInside = isPressed
        setPressed(false)
        guard firedInside else { return }
        ChiptuneSynth.shared.play(.uiTap)
        haptics?.uiTap()
        onTap?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setPressed(false)
    }
}
