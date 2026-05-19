//
//  NurseAvatarNode.swift
//  GanhoMusic Shared
//
//  Sprint 6 · 메인화면 김간호 큰 그림 SVG → SKShapeNode 코드화
//
//  StartScene 좌측에 배치되는 김간호 큰 그림(머리/모자/헤드폰/팔/쉿 손가락).
//  mockup `main-screen-v2.html`의 `<svg class="character" viewBox="-150 -160 300 360">` 전체를 코드화.
//
//  좌표 변환 — SVG y-down → SpriteKit y-up. 모든 SVG y 값에 `-1` 곱하기.
//  레이어 zPosition 내부 순서:
//    어깨(-5) < 사이드헤어 뒤(-3) < 머리/목(0) < 앞머리(5) < 모자(10) < 헤드폰 밴드(15)
//    < 헤드폰 컵(20) < 얼굴 디테일(25) < 팔(30) < 손가락 끝(35).
//
//  빌드 순서: shoulders → collar → neck → head → bangs → cap+cross → headphones → eyebrows
//             → eyes(감은 미소) → blush → shh mouth → arm + finger.
//

import SpriteKit

/// 메인화면 김간호 큰 그림 컨테이너. PNG 자산 없이도 mockup 시각을 충실 재현.
/// 외부에서 `.position` + `.setScale(...)` 만 잡으면 된다.
/// PNG swap 호환 — `SKNode` 서브클래스. 향후 SKSpriteNode(texture:)로 교체 시 좌표·zPosition 보존.
final class NurseAvatarNode: SKNode {

    // MARK: - Raw color tokens (mockup SVG 그대로)
    /// 스크럽 상의 fill(#9BE0CC) — ColorTokens `ganhoScrubMint` 동일.
    private static let scrubMint = UIColor.ganhoScrubMint
    /// 외곽선 stroke(#2D2A4A) — `ganhoNavyDeep` 동일.
    private static let navy = UIColor.ganhoNavyDeep
    /// 모자 흰색.
    private static let capWhite = UIColor.white
    /// V-collar 흰색.
    private static let collarWhite = UIColor.white
    /// 단추 + 헤드폰 cup + 십자 + 헤드폰 밴드(#FF6B5B) — `ganhoCoralPrimary` 동일.
    private static let coral = UIColor.ganhoCoralPrimary
    /// 헤드폰 cup inner(#C44A3D) — `ganhoCoralShadow` 동일.
    private static let coralShadow = UIColor.ganhoCoralShadow
    /// 머리카락(#3A2418) — raw, mockup 그대로.
    private static let hairBrown = UIColor(hex: "#3A2418")
    /// 피부(#FFE2C6) — `ganhoSkinTone` 동일.
    private static let skin = UIColor.ganhoSkinTone
    /// 볼터치(#FFB6B0) — 분홍 톤.
    private static let blush = UIColor(hex: "#FFB6B0")
    /// 쉿 입 fill(#FF8E80) — `ganhoCoralLight` 동일.
    private static let mouthCoral = UIColor.ganhoCoralLight

    // MARK: - Init
    override init() {
        super.init()
        name = "nurseAvatar"
        buildShoulders()
        buildCollar()
        buildButton()
        buildNeck()
        buildHead()
        buildSideHair()
        buildBangs()
        buildNurseCap()
        buildHeadphones()
        buildEyebrows()
        buildEyes()
        buildBlush()
        buildShhMouth()
        buildArmAndFinger()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layered Build Methods

    /// 스크럽 어깨 — `<path d="M -130 200 Q -110 100 -55 92 L 55 92 Q 110 100 130 200 Z"/>`
    /// SVG y → SK -y.
    private func buildShoulders() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -130, y: -200))
        path.addQuadCurve(to: CGPoint(x: -55, y: -92), control: CGPoint(x: -110, y: -100))
        path.addLine(to: CGPoint(x: 55, y: -92))
        path.addQuadCurve(to: CGPoint(x: 130, y: -200), control: CGPoint(x: 110, y: -100))
        path.closeSubpath()
        let shoulders = SKShapeNode(path: path)
        shoulders.fillColor = Self.scrubMint
        shoulders.strokeColor = Self.navy
        shoulders.lineWidth = GameConfig.nurseAvatarOutlineWidth
        shoulders.lineJoin = .round
        shoulders.zPosition = -5
        addChild(shoulders)
    }

    /// V collar — `<path d="M -20 96 L 0 135 L 20 96 Z"/>` 흰색.
    private func buildCollar() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -20, y: -96))
        path.addLine(to: CGPoint(x: 0, y: -135))
        path.addLine(to: CGPoint(x: 20, y: -96))
        path.closeSubpath()
        let collar = SKShapeNode(path: path)
        collar.fillColor = Self.collarWhite
        collar.strokeColor = Self.navy
        collar.lineWidth = 3
        collar.lineJoin = .round
        collar.zPosition = -4
        addChild(collar)
    }

    /// 코랄 단추 — `<circle cx="0" cy="160" r="5"/>`.
    private func buildButton() {
        let button = SKShapeNode(circleOfRadius: 5)
        button.fillColor = Self.coral
        button.strokeColor = Self.navy
        button.lineWidth = 2
        button.position = CGPoint(x: 0, y: -160)
        button.zPosition = -3
        addChild(button)
    }

    /// 목 — `<rect x="-18" y="55" width="36" height="42"/>` 중심 (0, -76).
    /// SVG y=55, h=42 → 중심 = -(55 + 42/2) = -76.
    private func buildNeck() {
        let neck = SKShapeNode(rectOf: CGSize(width: 36, height: 42))
        neck.fillColor = Self.skin
        neck.strokeColor = Self.navy
        neck.lineWidth = 3
        neck.position = CGPoint(x: 0, y: -76)
        neck.zPosition = 0
        addChild(neck)
    }

    /// 머리 — `<ellipse cx="0" cy="0" rx="65" ry="70"/>`.
    private func buildHead() {
        let head = SKShapeNode(ellipseOf: CGSize(width: 130, height: 140))
        head.fillColor = Self.skin
        head.strokeColor = Self.navy
        head.lineWidth = GameConfig.nurseAvatarOutlineWidth
        head.position = .zero
        head.zPosition = 0
        addChild(head)
    }

    /// 사이드 헤어 좌우 — `<path d="M -68 -10 Q -72 35 -60 60 L -50 35 Q -58 5 -52 -25 Z"/>` 등.
    private func buildSideHair() {
        // 좌측.
        let left = CGMutablePath()
        left.move(to: CGPoint(x: -68, y: 10))
        left.addQuadCurve(to: CGPoint(x: -60, y: -60), control: CGPoint(x: -72, y: -35))
        left.addLine(to: CGPoint(x: -50, y: -35))
        left.addQuadCurve(to: CGPoint(x: -52, y: 25), control: CGPoint(x: -58, y: -5))
        left.closeSubpath()
        let leftHair = SKShapeNode(path: left)
        leftHair.fillColor = Self.hairBrown
        leftHair.strokeColor = Self.navy
        leftHair.lineWidth = 3
        leftHair.lineJoin = .round
        leftHair.zPosition = -3
        addChild(leftHair)

        // 우측 — 부호 반전.
        let right = CGMutablePath()
        right.move(to: CGPoint(x: 68, y: 10))
        right.addQuadCurve(to: CGPoint(x: 60, y: -60), control: CGPoint(x: 72, y: -35))
        right.addLine(to: CGPoint(x: 50, y: -35))
        right.addQuadCurve(to: CGPoint(x: 52, y: 25), control: CGPoint(x: 58, y: -5))
        right.closeSubpath()
        let rightHair = SKShapeNode(path: right)
        rightHair.fillColor = Self.hairBrown
        rightHair.strokeColor = Self.navy
        rightHair.lineWidth = 3
        rightHair.lineJoin = .round
        rightHair.zPosition = -3
        addChild(rightHair)
    }

    /// 앞머리 — `<path d="M -60 -25 Q -50 -55 -20 -55 Q 0 -62 22 -55 Q 50 -55 60 -28 Q 40 -42 15 -38 Q -10 -42 -38 -38 Q -55 -38 -60 -25 Z"/>`
    private func buildBangs() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -60, y: 25))
        path.addQuadCurve(to: CGPoint(x: -20, y: 55), control: CGPoint(x: -50, y: 55))
        path.addQuadCurve(to: CGPoint(x: 22, y: 55), control: CGPoint(x: 0, y: 62))
        path.addQuadCurve(to: CGPoint(x: 60, y: 28), control: CGPoint(x: 50, y: 55))
        path.addQuadCurve(to: CGPoint(x: 15, y: 38), control: CGPoint(x: 40, y: 42))
        path.addQuadCurve(to: CGPoint(x: -38, y: 38), control: CGPoint(x: -10, y: 42))
        path.addQuadCurve(to: CGPoint(x: -60, y: 25), control: CGPoint(x: -55, y: 38))
        path.closeSubpath()
        let bangs = SKShapeNode(path: path)
        bangs.fillColor = Self.hairBrown
        bangs.strokeColor = Self.navy
        bangs.lineWidth = 3
        bangs.lineJoin = .round
        bangs.zPosition = 5
        addChild(bangs)
    }

    /// Nurse cap + 적십자 — translate(-3, -55) 적용된 모자 본체 + 십자.
    /// SVG translate(-3, -55) → SK translate(-3, 55).
    private func buildNurseCap() {
        let capContainer = SKNode()
        capContainer.position = CGPoint(x: -3, y: 55)
        capContainer.zPosition = 10
        addChild(capContainer)

        // `<path d="M -30 5 Q -30 -25 0 -28 Q 30 -25 30 5 L 26 8 L -26 8 Z"/>`
        let capPath = CGMutablePath()
        capPath.move(to: CGPoint(x: -30, y: -5))
        capPath.addQuadCurve(to: CGPoint(x: 0, y: 28), control: CGPoint(x: -30, y: 25))
        capPath.addQuadCurve(to: CGPoint(x: 30, y: -5), control: CGPoint(x: 30, y: 25))
        capPath.addLine(to: CGPoint(x: 26, y: -8))
        capPath.addLine(to: CGPoint(x: -26, y: -8))
        capPath.closeSubpath()
        let cap = SKShapeNode(path: capPath)
        cap.fillColor = Self.capWhite
        cap.strokeColor = Self.navy
        cap.lineWidth = 3
        cap.lineJoin = .round
        capContainer.addChild(cap)

        // 적십자 — translate(0, -10) 적용 → SK (0, 10).
        let crossContainer = SKNode()
        crossContainer.position = CGPoint(x: 0, y: 10)
        capContainer.addChild(crossContainer)

        // `<rect x="-3.5" y="-9" width="7" height="18" rx="1"/>` 중심 (0, 0).
        let vBar = SKShapeNode(rectOf: CGSize(width: 7, height: 18), cornerRadius: 1)
        vBar.fillColor = Self.coral
        vBar.strokeColor = .clear
        crossContainer.addChild(vBar)

        // `<rect x="-9" y="-3.5" width="18" height="7" rx="1"/>` 중심 (0, 0).
        let hBar = SKShapeNode(rectOf: CGSize(width: 18, height: 7), cornerRadius: 1)
        hBar.fillColor = Self.coral
        hBar.strokeColor = .clear
        crossContainer.addChild(hBar)
    }

    /// 헤드폰 — 밴드 + 컵 좌우.
    private func buildHeadphones() {
        // 밴드 — `<path d="M -72 -8 Q -72 -75 0 -75 Q 72 -75 72 -8"/>`
        let bandPath = CGMutablePath()
        bandPath.move(to: CGPoint(x: -72, y: 8))
        bandPath.addQuadCurve(to: CGPoint(x: 0, y: 75), control: CGPoint(x: -72, y: 75))
        bandPath.addQuadCurve(to: CGPoint(x: 72, y: 8), control: CGPoint(x: 72, y: 75))
        let band = SKShapeNode(path: bandPath)
        band.strokeColor = Self.coral
        band.lineWidth = GameConfig.nurseAvatarHeadphoneBandWidth
        band.fillColor = .clear
        band.lineCap = .round
        band.zPosition = 15
        addChild(band)

        // 컵 좌우 — `<ellipse cx="±70" cy="3" rx="16" ry="22"/>`
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            // 외곽 컵.
            let outer = SKShapeNode(ellipseOf: CGSize(width: 32, height: 44))
            outer.fillColor = Self.coral
            outer.strokeColor = Self.navy
            outer.lineWidth = GameConfig.nurseAvatarOutlineWidth
            outer.position = CGPoint(x: 70 * s, y: -3)
            outer.zPosition = 20
            addChild(outer)

            // 내부 어두운 코랄.
            let inner = SKShapeNode(ellipseOf: CGSize(width: 18, height: 28))
            inner.fillColor = Self.coralShadow
            inner.strokeColor = .clear
            inner.position = CGPoint(x: 68 * s, y: -3)
            inner.zPosition = 21
            addChild(inner)
        }
    }

    /// 눈썹 좌우 — `<path d="M -30 -22 Q -22 -26 -14 -22"/>`
    private func buildEyebrows() {
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 30 * s, y: 22))
            path.addQuadCurve(
                to: CGPoint(x: 14 * s, y: 22),
                control: CGPoint(x: 22 * s, y: 26)
            )
            let brow = SKShapeNode(path: path)
            brow.strokeColor = Self.navy
            brow.lineWidth = 3.5
            brow.fillColor = .clear
            brow.lineCap = .round
            brow.zPosition = 25
            addChild(brow)
        }
    }

    /// 감은 미소 눈 — `<path d="M -28 -5 Q -22 -12 -14 -5"/>`
    private func buildEyes() {
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 28 * s, y: 5))
            path.addQuadCurve(
                to: CGPoint(x: 14 * s, y: 5),
                control: CGPoint(x: 22 * s, y: 12)
            )
            let eye = SKShapeNode(path: path)
            eye.strokeColor = Self.navy
            eye.lineWidth = 4
            eye.fillColor = .clear
            eye.lineCap = .round
            eye.zPosition = 25
            addChild(eye)
        }
    }

    /// 볼터치 좌우 — `<ellipse cx="±38" cy="18" rx="11" ry="7" opacity="0.55"/>`
    private func buildBlush() {
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let cheek = SKShapeNode(ellipseOf: CGSize(width: 22, height: 14))
            cheek.fillColor = Self.blush.withAlphaComponent(0.55)
            cheek.strokeColor = .clear
            cheek.position = CGPoint(x: 38 * s, y: -18)
            cheek.zPosition = 25
            addChild(cheek)
        }
    }

    /// 쉿 입 — `<ellipse cx="0" cy="25" rx="6" ry="7"/>` 작은 O.
    private func buildShhMouth() {
        let mouth = SKShapeNode(ellipseOf: CGSize(width: 12, height: 14))
        mouth.fillColor = Self.mouthCoral
        mouthInner: do {
            mouth.strokeColor = Self.navy
            mouth.lineWidth = 2.5
        }
        mouth.position = CGPoint(x: 0, y: -25)
        mouth.zPosition = 25
        addChild(mouth)
    }

    /// 팔 + 손가락 — 피부톤 두꺼운 라인 + navy 외곽선 라인 + 손가락 끝 타원.
    /// SVG path: `M 60 130 Q 50 90 30 60 Q 18 40 8 25` — 어깨에서 입 근처까지.
    private func buildArmAndFinger() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 60, y: -130))
        path.addQuadCurve(to: CGPoint(x: 30, y: -60), control: CGPoint(x: 50, y: -90))
        path.addQuadCurve(to: CGPoint(x: 8, y: -25), control: CGPoint(x: 18, y: -40))

        // 살 라인.
        let armSkin = SKShapeNode(path: path)
        armSkin.strokeColor = Self.skin
        armSkin.lineWidth = GameConfig.nurseAvatarArmWidth
        armSkin.fillColor = .clear
        armSkin.lineCap = .round
        armSkin.zPosition = 30
        addChild(armSkin)

        // navy 외곽선(opacity 0.85).
        let armOutline = SKShapeNode(path: path)
        armOutline.strokeColor = Self.navy.withAlphaComponent(0.85)
        armOutline.lineWidth = 3
        armOutline.fillColor = .clear
        armOutline.lineCap = .round
        armOutline.zPosition = 31
        addChild(armOutline)

        // 손가락 끝 — `<ellipse cx="6" cy="22" rx="8" ry="7"/>`
        let finger = SKShapeNode(ellipseOf: CGSize(width: 16, height: 14))
        finger.fillColor = Self.skin
        finger.strokeColor = Self.navy
        finger.lineWidth = 2.5
        finger.position = CGPoint(x: 6, y: -22)
        finger.zPosition = 35
        addChild(finger)
    }
}
