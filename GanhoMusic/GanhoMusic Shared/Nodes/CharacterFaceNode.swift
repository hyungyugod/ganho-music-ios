//
//  CharacterFaceNode.swift
//  GanhoMusic Shared
//
//  Sprint 6 · 캐릭터 5명 얼굴 SVG → SKShapeNode 코드화
//
//  CharacterSelectScene 5장 카드 *위에* 부착되어 PNG 자산 없이도 5명을 시각 식별 가능하게 한다.
//  mockup `character-select-v2.html`의 5개 `<svg class="avatar" viewBox="-50 -55 100 110">` 안의
//  path/circle/ellipse/rect 좌표를 그대로 옮긴 SKShapeNode 조합.
//
//  좌표 변환 — SVG는 y-down, SpriteKit은 y-up. 모든 SVG y 값에 `-1` 곱하기.
//  레이어 zPosition 내부 순서: 머리(0) < 헤드폰 밴드(5) < 헤어 베이스(10) < 모자(20) < 얼굴 디테일(30) < 액세서리(40).
//  PNG swap 호환 — `SKNode` 서브클래스. 향후 `SKSpriteNode(texture:)`로 교체 시 좌표·zPosition 보존.
//

import SpriteKit

/// 5 캐릭터 얼굴 컨테이너. 카드 외부에 부착 — CharacterCardNode 내부 변경 0건 정책.
/// init(id:)만 노출 — 5명 분기는 내부 build* 메서드.
final class CharacterFaceNode: SKNode {

    // MARK: - Raw color tokens (mockup SVG 그대로 — ColorTokens v2와 hex 동일)
    /// 베이스 머리 fill(#FFE2C6) — ColorTokens `ganhoSkinTone` 동일 hex.
    private static let skin = UIColor.ganhoSkinTone
    /// 머리·디테일 stroke + 눈/입 path(#2D2A4A) — ColorTokens `ganhoNavyDeep` 동일.
    private static let navy = UIColor.ganhoNavyDeep
    /// 머리카락 fill(#3A2418) — mockup 5명 공통. 일회용 raw — ColorTokens에 동일 hex 토큰 없음.
    private static let hairBrown = UIColor(hex: "#3A2418")
    /// 모자 본체 fill(#FFFFFF) — ColorTokens `UIColor.white`로 대체 가능하나 가독성 위해 명시.
    private static let capWhite = UIColor.white
    /// 모자 적십자 fill(#FF6B5B) — ColorTokens `ganhoCoralPrimary` 동일.
    private static let capCross = UIColor.ganhoCoralPrimary
    /// 볼 fill(#FFB6B0) — 5명 공통 볼터치.
    private static let blush = UIColor(hex: "#FFB6B0")
    /// 정간호 헤어밴드 골드 점(#FFB347) — `ganhoMusicGold` 동일.
    private static let bandDot = UIColor.ganhoMusicGold
    /// 정간호 곡괭이 자루(#8B5A2B) — raw, 단일 사용처.
    private static let pickHandle = UIColor(hex: "#8B5A2B")
    /// 정간호 곡괭이 헤드(#888) — raw, 단일 사용처.
    private static let pickHead = UIColor(hex: "#888888")
    /// 건간호 안경 렌즈(rgba(220,230,255,0.4)) — raw, 단일 사용처.
    private static let glassesLens = UIColor(red: 220.0/255, green: 230.0/255, blue: 255.0/255, alpha: 0.4)
    /// 건간호 책 표지(#B89DD9) — `ganhoLavenderSoft` 동일.
    private static let bookCover = UIColor.ganhoLavenderSoft
    /// 임간호/이간호 분홍 코·혀(#FF8E80) — `ganhoCoralLight` 동일.
    private static let pinkNose = UIColor.ganhoCoralLight

    // MARK: - Init
    /// 5 캐릭터 분기 — 단일 진입점. 카드 외부에서 `.position`만 잡으면 된다.
    init(id: CharacterID) {
        super.init()
        name = "characterFace_\(id.rawValue)"
        switch id {
        case .kim:  buildKimFace()
        case .jung: buildJungFace()
        case .geon: buildGeonFace()
        case .im:   buildImFace()
        case .lee:  buildLeeFace()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Common Builders
    /// 5명 공통 머리 베이스 타원. mockup `<ellipse cx="0" cy="0" rx="32" ry="34" fill="#FFE2C6" stroke="#2D2A4A" stroke-width="2.5"/>`.
    /// zPosition 0 — 가장 안쪽.
    private func buildHeadBase() {
        let head = SKShapeNode(
            ellipseOf: CGSize(
                width: GameConfig.characterFaceHeadRadiusX * 2,
                height: GameConfig.characterFaceHeadRadiusY * 2
            )
        )
        head.fillColor = Self.skin
        head.strokeColor = Self.navy
        head.lineWidth = GameConfig.characterFaceOutlineWidth
        head.position = .zero
        head.zPosition = 0
        addChild(head)
    }

    /// 5명 공통 nurse cap. mockup `<path d="M -15 -28 Q -15 -42 0 -44 Q 15 -42 15 -28 L 12 -25 L -12 -25 Z"/>`.
    /// SVG y-down → SpriteKit y-up: y 부호 반전.
    private func buildNurseCap() {
        let path = CGMutablePath()
        // SVG: M -15 -28 → SK: (-15, 28)
        path.move(to: CGPoint(x: -15, y: 28))
        // SVG: Q -15 -42 0 -44 → SK: cp(-15, 42) end(0, 44)
        path.addQuadCurve(to: CGPoint(x: 0, y: 44), control: CGPoint(x: -15, y: 42))
        // SVG: Q 15 -42 15 -28 → SK: cp(15, 42) end(15, 28)
        path.addQuadCurve(to: CGPoint(x: 15, y: 28), control: CGPoint(x: 15, y: 42))
        // SVG: L 12 -25 → SK: (12, 25)
        path.addLine(to: CGPoint(x: 12, y: 25))
        // SVG: L -12 -25 → SK: (-12, 25)
        path.addLine(to: CGPoint(x: -12, y: 25))
        path.closeSubpath()
        let cap = SKShapeNode(path: path)
        cap.fillColor = Self.capWhite
        cap.strokeColor = Self.navy
        cap.lineWidth = 2
        cap.zPosition = 20
        addChild(cap)

        // 적십자 — `rect x="-2" y="-38" w=4 h=9` + `rect x="-4.5" y="-35.5" w=9 h=4`.
        // SVG rect (x,y,w,h)는 좌상단. SKShapeNode rectOf: 는 중심 기준.
        // 변환: 중심 = (x + w/2, -(y + h/2)) — y 부호 반전.
        let vBar = SKShapeNode(rectOf: CGSize(width: 4, height: 9))
        vBar.fillColor = Self.capCross
        vBar.strokeColor = .clear
        vBar.position = CGPoint(x: 0, y: 33.5)  // (-2 + 4/2, -(-38 + 9/2))
        vBar.zPosition = 21
        addChild(vBar)

        let hBar = SKShapeNode(rectOf: CGSize(width: 9, height: 4))
        hBar.fillColor = Self.capCross
        hBar.strokeColor = .clear
        hBar.position = CGPoint(x: 0, y: 33.5)  // (-4.5 + 9/2, -(-35.5 + 4/2))
        hBar.zPosition = 21
        addChild(hBar)
    }

    /// 양쪽 볼터치 타원. 5명 공통(임간호는 더 작음 — 별도 처리).
    /// mockup `<ellipse cx="-18" cy="8" rx="5" ry="3" fill="#FFB6B0" opacity="0.6"/>`.
    private func buildBlush(radiusX: CGFloat = 5, radiusY: CGFloat = 3, cy: CGFloat = 8, alpha: CGFloat = 0.6) {
        for sign in [-1.0, 1.0] {
            let cheek = SKShapeNode(ellipseOf: CGSize(width: radiusX * 2, height: radiusY * 2))
            cheek.fillColor = Self.blush.withAlphaComponent(alpha)
            cheek.strokeColor = .clear
            // SVG cy="8" → SK y = -8
            cheek.position = CGPoint(x: 18 * CGFloat(sign), y: -cy)
            cheek.zPosition = 30
            addChild(cheek)
        }
    }

    // MARK: - 1. Kim (번머리 + 모자 + 헤드폰)
    /// mockup char-card[0] — 번머리(curly bangs) + nurse cap + 헤드폰 + 미소눈.
    private func buildKimFace() {
        buildHeadBase()

        // 번머리 — `<path d="M -28 -12 Q -32 -28 -18 -32 Q -10 -34 0 -32 Q 10 -34 18 -32 Q 32 -28 28 -12 Q 20 -22 10 -20 Q 0 -22 -10 -20 Q -20 -22 -28 -12 Z"/>`
        let bun = CGMutablePath()
        bun.move(to: CGPoint(x: -28, y: 12))
        bun.addQuadCurve(to: CGPoint(x: -18, y: 32), control: CGPoint(x: -32, y: 28))
        bun.addQuadCurve(to: CGPoint(x: 0, y: 32), control: CGPoint(x: -10, y: 34))
        bun.addQuadCurve(to: CGPoint(x: 18, y: 32), control: CGPoint(x: 10, y: 34))
        bun.addQuadCurve(to: CGPoint(x: 28, y: 12), control: CGPoint(x: 32, y: 28))
        bun.addQuadCurve(to: CGPoint(x: 10, y: 20), control: CGPoint(x: 20, y: 22))
        bun.addQuadCurve(to: CGPoint(x: -10, y: 20), control: CGPoint(x: 0, y: 22))
        bun.addQuadCurve(to: CGPoint(x: -28, y: 12), control: CGPoint(x: -20, y: 22))
        bun.closeSubpath()
        let hair = SKShapeNode(path: bun)
        hair.fillColor = Self.hairBrown
        hair.strokeColor = Self.navy
        hair.lineWidth = 2
        hair.zPosition = 10
        addChild(hair)

        // 컬 디테일 작은 원 2개.
        for sign in [-1.0, 1.0] {
            let curl = SKShapeNode(circleOfRadius: 3)
            curl.fillColor = Self.hairBrown
            curl.strokeColor = Self.navy
            curl.lineWidth = 1.5
            curl.position = CGPoint(x: 22 * CGFloat(sign), y: 22)
            curl.zPosition = 11
            addChild(curl)
        }

        buildNurseCap()

        // 헤드폰 — `<path d="M -34 -2 Q -34 -38 0 -38 Q 34 -38 34 -2" stroke="#FF6B5B" stroke-width="5" fill="none"/>`
        let bandPath = CGMutablePath()
        bandPath.move(to: CGPoint(x: -34, y: 2))
        bandPath.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -34, y: 38))
        bandPath.addQuadCurve(to: CGPoint(x: 34, y: 2), control: CGPoint(x: 34, y: 38))
        let band = SKShapeNode(path: bandPath)
        band.strokeColor = Self.capCross
        band.lineWidth = 5
        band.fillColor = .clear
        band.lineCap = .round
        band.zPosition = 5
        addChild(band)

        // 헤드폰 컵 좌우 — `<ellipse cx="±34" cy="2" rx="7" ry="10" fill="#FF6B5B" stroke="#2D2A4A" stroke-width="2"/>`
        for sign in [-1.0, 1.0] {
            let cup = SKShapeNode(ellipseOf: CGSize(width: 14, height: 20))
            cup.fillColor = Self.capCross
            cup.strokeColor = Self.navy
            cup.lineWidth = 2
            // SVG cy="2" → SK y = -2
            cup.position = CGPoint(x: 34 * CGFloat(sign), y: -2)
            cup.zPosition = 40
            addChild(cup)
        }

        // 미소눈 좌우 — `<path d="M -14 -2 Q -10 -6 -6 -2"/>`
        for sign in [-1.0, 1.0] {
            let eye = CGMutablePath()
            eye.move(to: CGPoint(x: 14 * CGFloat(sign), y: 2))
            eye.addQuadCurve(
                to: CGPoint(x: 6 * CGFloat(sign), y: 2),
                control: CGPoint(x: 10 * CGFloat(sign), y: 6)
            )
            let eyeNode = SKShapeNode(path: eye)
            eyeNode.strokeColor = Self.navy
            eyeNode.lineWidth = 2.5
            eyeNode.fillColor = .clear
            eyeNode.lineCap = .round
            eyeNode.zPosition = 30
            addChild(eyeNode)
        }

        // 입 — `<path d="M -5 12 Q 0 16 5 12"/>`
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -5, y: -12))
        mouth.addQuadCurve(to: CGPoint(x: 5, y: -12), control: CGPoint(x: 0, y: -16))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.5
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        buildBlush()
    }

    // MARK: - 2. Jung (스파이크 헤어 + 헤어밴드 + 곡괭이)
    /// mockup char-card[1] — 짧은 스파이크 머리 + 헤드밴드 + 작은 모자(기울어진) + 결연한 눈.
    private func buildJungFace() {
        buildHeadBase()

        // 스파이크 머리 — `<path d="M -28 -18 L -22 -30 L -14 -22 L -6 -32 L 0 -22 L 6 -32 L 14 -22 L 22 -30 L 28 -18 Q 20 -22 0 -22 Q -20 -22 -28 -18 Z"/>`
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -28, y: 18))
        hair.addLine(to: CGPoint(x: -22, y: 30))
        hair.addLine(to: CGPoint(x: -14, y: 22))
        hair.addLine(to: CGPoint(x: -6, y: 32))
        hair.addLine(to: CGPoint(x: 0, y: 22))
        hair.addLine(to: CGPoint(x: 6, y: 32))
        hair.addLine(to: CGPoint(x: 14, y: 22))
        hair.addLine(to: CGPoint(x: 22, y: 30))
        hair.addLine(to: CGPoint(x: 28, y: 18))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: 20, y: 22))
        hair.addQuadCurve(to: CGPoint(x: -28, y: 18), control: CGPoint(x: -20, y: 22))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.zPosition = 10
        addChild(hairNode)

        // 헤드밴드 — `<rect x="-30" y="-12" width="60" height="8" rx="2"/>` 중심 (0, 8).
        let band = SKShapeNode(rectOf: CGSize(width: 60, height: 8), cornerRadius: 2)
        band.fillColor = Self.capCross
        band.strokeColor = Self.navy
        band.lineWidth = 2
        band.position = CGPoint(x: 0, y: 8)
        band.zPosition = 11
        addChild(band)

        // 헤드밴드 골드 점.
        let bandDot = SKShapeNode(circleOfRadius: 2)
        bandDot.fillColor = Self.bandDot
        bandDot.strokeColor = .clear
        bandDot.position = CGPoint(x: 0, y: 8)
        bandDot.zPosition = 12
        addChild(bandDot)

        // 작은 nurse cap(기울어진) — 별도 path. transform rotate(-8deg).
        let cap = CGMutablePath()
        cap.move(to: CGPoint(x: -13, y: 22))
        cap.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -13, y: 36))
        cap.addQuadCurve(to: CGPoint(x: 13, y: 22), control: CGPoint(x: 13, y: 36))
        cap.addLine(to: CGPoint(x: 10, y: 19))
        cap.addLine(to: CGPoint(x: -10, y: 19))
        cap.closeSubpath()
        let capNode = SKShapeNode(path: cap)
        capNode.fillColor = Self.capWhite
        capNode.strokeColor = Self.navy
        capNode.lineWidth = 2
        capNode.zRotation = -.pi / 180 * 8  // -8deg
        capNode.zPosition = 20
        addChild(capNode)

        // 결연한 눈 — `<path d="M -16 -2 L -8 -2"/>` 가로 라인.
        for sign in [-1.0, 1.0] {
            let eye = CGMutablePath()
            eye.move(to: CGPoint(x: 16 * CGFloat(sign), y: 2))
            eye.addLine(to: CGPoint(x: 8 * CGFloat(sign), y: 2))
            let eyeNode = SKShapeNode(path: eye)
            eyeNode.strokeColor = Self.navy
            eyeNode.lineWidth = 3
            eyeNode.fillColor = .clear
            eyeNode.lineCap = .round
            eyeNode.zPosition = 30
            addChild(eyeNode)

            // 결연한 눈썹 — `<path d="M -18 -10 L -8 -8"/>`
            let brow = CGMutablePath()
            brow.move(to: CGPoint(x: 18 * CGFloat(sign), y: 10))
            brow.addLine(to: CGPoint(x: 8 * CGFloat(sign), y: 8))
            let browNode = SKShapeNode(path: brow)
            browNode.strokeColor = Self.navy
            browNode.lineWidth = 2.5
            browNode.fillColor = .clear
            browNode.lineCap = .round
            browNode.zPosition = 30
            addChild(browNode)
        }

        // 자신감 미소.
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -6, y: -12))
        mouth.addQuadCurve(to: CGPoint(x: 6, y: -12), control: CGPoint(x: 0, y: -18))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.5
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        buildBlush(radiusX: 4, radiusY: 2.5, cy: 10, alpha: 0.5)

        // 곡괭이 미니 아이콘 — translate(28, 28) rotate(40deg).
        let pickContainer = SKNode()
        pickContainer.position = CGPoint(x: 28, y: -28)
        pickContainer.zRotation = -.pi / 180 * 40
        pickContainer.zPosition = 40
        addChild(pickContainer)

        let handle = SKShapeNode(rectOf: CGSize(width: 3, height: 18))
        handle.fillColor = Self.pickHandle
        handle.strokeColor = Self.navy
        handle.lineWidth = 1.2
        // SVG rect y=-12, h=18 → 중심 y = -(- 12 + 9) = 3 → SK 3.
        handle.position = CGPoint(x: 0, y: 3)
        pickContainer.addChild(handle)

        let headPath = CGMutablePath()
        headPath.move(to: CGPoint(x: -8, y: 12))
        headPath.addLine(to: CGPoint(x: 8, y: 10))
        headPath.addLine(to: CGPoint(x: 6, y: 8))
        headPath.addLine(to: CGPoint(x: -6, y: 10))
        headPath.closeSubpath()
        let pickHead = SKShapeNode(path: headPath)
        pickHead.fillColor = Self.pickHead
        pickHead.strokeColor = Self.navy
        pickHead.lineWidth = 1.2
        pickContainer.addChild(pickHead)
    }

    // MARK: - 3. Geon (안경 + 책 + 단정한 머리)
    /// mockup char-card[2] — 단정한 갈래 머리 + nurse cap + 안경 + 책 미니.
    private func buildGeonFace() {
        buildHeadBase()

        // 단정한 머리.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -28, y: 14))
        hair.addQuadCurve(to: CGPoint(x: -14, y: 34), control: CGPoint(x: -32, y: 32))
        hair.addLine(to: CGPoint(x: -2, y: 30))
        hair.addLine(to: CGPoint(x: 2, y: 30))
        hair.addLine(to: CGPoint(x: 14, y: 34))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 14), control: CGPoint(x: 32, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 2, y: 24), control: CGPoint(x: 18, y: 24))
        hair.addLine(to: CGPoint(x: -2, y: 24))
        hair.addQuadCurve(to: CGPoint(x: -28, y: 14), control: CGPoint(x: -18, y: 24))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.zPosition = 10
        addChild(hairNode)

        buildNurseCap()

        // 안경 — `<circle cx="±12" cy="-1" r="9"/>` 렌즈 + 가운데 다리.
        for sign in [-1.0, 1.0] {
            let lens = SKShapeNode(circleOfRadius: 9)
            lens.fillColor = Self.glassesLens
            lens.strokeColor = Self.navy
            lens.lineWidth = 2.5
            lens.position = CGPoint(x: 12 * CGFloat(sign), y: 1)
            lens.zPosition = 40
            addChild(lens)

            // 렌즈 안 동공.
            let pupil = SKShapeNode(circleOfRadius: 2)
            pupil.fillColor = Self.navy
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: 12 * CGFloat(sign), y: 1)
            pupil.zPosition = 41
            addChild(pupil)
        }

        // 안경 다리 가운데 — `<line x1="-3" y1="-1" x2="3" y2="-1"/>`
        let bridge = CGMutablePath()
        bridge.move(to: CGPoint(x: -3, y: 1))
        bridge.addLine(to: CGPoint(x: 3, y: 1))
        let bridgeNode = SKShapeNode(path: bridge)
        bridgeNode.strokeColor = Self.navy
        bridgeNode.lineWidth = 2
        bridgeNode.fillColor = .clear
        bridgeNode.zPosition = 40
        addChild(bridgeNode)

        // 입 — `<path d="M -4 14 Q 0 17 4 14"/>`
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -4, y: -14))
        mouth.addQuadCurve(to: CGPoint(x: 4, y: -14), control: CGPoint(x: 0, y: -17))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.5
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        buildBlush(radiusX: 4, radiusY: 2.5, cy: 10, alpha: 0.55)

        // 책 미니 — translate(-28, 30): SK 좌표 (-28, -30).
        let bookContainer = SKNode()
        bookContainer.position = CGPoint(x: -28, y: -30)
        bookContainer.zPosition = 40
        addChild(bookContainer)

        let book = SKShapeNode(rectOf: CGSize(width: 12, height: 8), cornerRadius: 1)
        book.fillColor = Self.bookCover
        book.strokeColor = Self.navy
        book.lineWidth = 1.5
        bookContainer.addChild(book)

        let spine = CGMutablePath()
        spine.move(to: CGPoint(x: 0, y: -4))
        spine.addLine(to: CGPoint(x: 0, y: 4))
        let spineNode = SKShapeNode(path: spine)
        spineNode.strokeColor = Self.navy
        spineNode.lineWidth = 1
        spineNode.fillColor = .clear
        bookContainer.addChild(spineNode)
    }

    // MARK: - 4. Im (긴머리 + 고양이귀 + 수염)
    /// mockup char-card[3] — 좌우 긴머리 + 앞머리 + 고양이귀 + 고양이눈 + 수염 + 분홍 코.
    private func buildImFace() {
        // 긴머리(좌우) — 머리 베이스보다 먼저 그림(뒤에 깔리도록).
        // 좌측: `<path d="M -30 -10 Q -38 30 -28 50 L -20 30 Q -28 0 -22 -22 Z"/>`
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let hair = CGMutablePath()
            hair.move(to: CGPoint(x: 30 * s, y: 10))
            hair.addQuadCurve(to: CGPoint(x: 28 * s, y: -50), control: CGPoint(x: 38 * s, y: -30))
            hair.addLine(to: CGPoint(x: 20 * s, y: -30))
            hair.addQuadCurve(to: CGPoint(x: 22 * s, y: 22), control: CGPoint(x: 28 * s, y: 0))
            hair.closeSubpath()
            let hairNode = SKShapeNode(path: hair)
            hairNode.fillColor = Self.hairBrown
            hairNode.strokeColor = Self.navy
            hairNode.lineWidth = 2
            hairNode.lineJoin = .round
            hairNode.zPosition = -1  // 머리 베이스보다 뒤.
            addChild(hairNode)
        }

        buildHeadBase()

        // 앞머리 — `<path d="M -28 -14 Q -32 -32 0 -34 Q 32 -32 28 -14 Q 18 -22 0 -22 Q -18 -22 -28 -14 Z"/>`
        let bangs = CGMutablePath()
        bangs.move(to: CGPoint(x: -28, y: 14))
        bangs.addQuadCurve(to: CGPoint(x: 0, y: 34), control: CGPoint(x: -32, y: 32))
        bangs.addQuadCurve(to: CGPoint(x: 28, y: 14), control: CGPoint(x: 32, y: 32))
        bangs.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: 18, y: 22))
        bangs.addQuadCurve(to: CGPoint(x: -28, y: 14), control: CGPoint(x: -18, y: 22))
        bangs.closeSubpath()
        let bangsNode = SKShapeNode(path: bangs)
        bangsNode.fillColor = Self.hairBrown
        bangsNode.strokeColor = Self.navy
        bangsNode.lineWidth = 2
        bangsNode.zPosition = 10
        addChild(bangsNode)

        // 고양이 귀 — `<path d="M -22 -32 L -16 -22 L -10 -30 Z"/>` 좌, 우는 부호 반전.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let ear = CGMutablePath()
            ear.move(to: CGPoint(x: 22 * s, y: 32))
            ear.addLine(to: CGPoint(x: 16 * s, y: 22))
            ear.addLine(to: CGPoint(x: 10 * s, y: 30))
            ear.closeSubpath()
            let earNode = SKShapeNode(path: ear)
            earNode.fillColor = Self.hairBrown
            earNode.strokeColor = Self.navy
            earNode.lineWidth = 2
            earNode.lineJoin = .round
            earNode.zPosition = 20
            addChild(earNode)

            // 귀 안쪽 분홍 — `<path d="M -19 -28 L -16 -24 L -13 -28 Z" fill="#FFB6B0"/>`
            let inner = CGMutablePath()
            inner.move(to: CGPoint(x: 19 * s, y: 28))
            inner.addLine(to: CGPoint(x: 16 * s, y: 24))
            inner.addLine(to: CGPoint(x: 13 * s, y: 28))
            inner.closeSubpath()
            let innerNode = SKShapeNode(path: inner)
            innerNode.fillColor = Self.blush
            innerNode.strokeColor = .clear
            innerNode.zPosition = 21
            addChild(innerNode)
        }

        // 고양이눈 — `<path d="M -16 -3 Q -10 -8 -6 -1 Q -10 -2 -16 -3 Z"/>`
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let eye = CGMutablePath()
            eye.move(to: CGPoint(x: 16 * s, y: 3))
            eye.addQuadCurve(to: CGPoint(x: 6 * s, y: 1), control: CGPoint(x: 10 * s, y: 8))
            eye.addQuadCurve(to: CGPoint(x: 16 * s, y: 3), control: CGPoint(x: 10 * s, y: 2))
            eye.closeSubpath()
            let eyeNode = SKShapeNode(path: eye)
            eyeNode.fillColor = Self.navy
            eyeNode.strokeColor = .clear
            eyeNode.zPosition = 30
            addChild(eyeNode)
        }

        // 수염 — 4가닥(좌우 위/아래).
        let whiskerCoords: [(start: CGPoint, end: CGPoint)] = [
            (CGPoint(x: -30, y: -6), CGPoint(x: -22, y: -6)),
            (CGPoint(x: -30, y: -10), CGPoint(x: -22, y: -9)),
            (CGPoint(x: 22, y: -6), CGPoint(x: 30, y: -6)),
            (CGPoint(x: 22, y: -9), CGPoint(x: 30, y: -10))
        ]
        for (start, end) in whiskerCoords {
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: end)
            let whisker = SKShapeNode(path: path)
            whisker.strokeColor = Self.navy
            whisker.lineWidth = 1.5
            whisker.fillColor = .clear
            whisker.zPosition = 30
            addChild(whisker)
        }

        // 냥 입 — `<path d="M -4 10 Q 0 14 4 10 Q 8 14 4 10"/>`
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -4, y: -10))
        mouth.addQuadCurve(to: CGPoint(x: 4, y: -10), control: CGPoint(x: 0, y: -14))
        mouth.addQuadCurve(to: CGPoint(x: 4, y: -10), control: CGPoint(x: 8, y: -14))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        // 분홍 코.
        let nose = SKShapeNode(ellipseOf: CGSize(width: 4, height: 3))
        nose.fillColor = Self.pinkNose
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: -6)
        nose.zPosition = 30
        addChild(nose)
    }

    // MARK: - 5. Lee (단발 + 강아지귀 + 동그란 눈 + 혀)
    /// mockup char-card[4] — Bob cut + 처진 강아지귀 + 동그란 흥분된 눈 + 혀 내민 미소.
    private func buildLeeFace() {
        buildHeadBase()

        // Bob cut — `<path d="M -30 -8 Q -32 -32 0 -34 Q 32 -32 30 -8 L 28 12 Q 22 6 22 -10 Q 0 -22 -22 -10 Q -22 6 -28 12 Z"/>`
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -30, y: 8))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 34), control: CGPoint(x: -32, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 30, y: 8), control: CGPoint(x: 32, y: 32))
        hair.addLine(to: CGPoint(x: 28, y: -12))
        hair.addQuadCurve(to: CGPoint(x: 22, y: 10), control: CGPoint(x: 22, y: -6))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 10), control: CGPoint(x: 0, y: 22))
        hair.addQuadCurve(to: CGPoint(x: -28, y: -12), control: CGPoint(x: -22, y: -6))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)

        // 강아지 귀(처진) — `<ellipse cx="-26" cy="-4" rx="6" ry="14" transform="rotate(-20 -26 -4)"/>`
        // SVG y=-4 → SK y=4. SVG rotate(-20deg) → SK 양의 회전.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let ear = SKShapeNode(ellipseOf: CGSize(width: 12, height: 28))
            ear.fillColor = Self.hairBrown
            ear.strokeColor = Self.navy
            ear.lineWidth = 2
            ear.position = CGPoint(x: 26 * s, y: 4)
            ear.zRotation = .pi / 180 * 20 * s  // SVG -20deg, +20deg → SK 부호 반전
            ear.zPosition = 20
            addChild(ear)

            let innerEar = SKShapeNode(ellipseOf: CGSize(width: 6, height: 16))
            innerEar.fillColor = Self.blush
            innerEar.strokeColor = .clear
            innerEar.position = CGPoint(x: 26 * s, y: 0)
            innerEar.zRotation = .pi / 180 * 20 * s
            innerEar.zPosition = 21
            addChild(innerEar)
        }

        // 동그란 눈.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let eye = SKShapeNode(circleOfRadius: 4)
            eye.fillColor = Self.navy
            eye.strokeColor = .clear
            eye.position = CGPoint(x: 12 * s, y: 1)
            eye.zPosition = 30
            addChild(eye)

            // 흰자 highlight.
            let hl = SKShapeNode(circleOfRadius: 1.5)
            hl.fillColor = .white
            hl.strokeColor = .clear
            hl.position = CGPoint(x: (12 * s) + (sign < 0 ? 1 : 1), y: 2)
            hl.zPosition = 31
            addChild(hl)
        }

        // 미소 — `<path d="M -6 12 Q 0 18 6 12"/>`
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -6, y: -12))
        mouth.addQuadCurve(to: CGPoint(x: 6, y: -12), control: CGPoint(x: 0, y: -18))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.5
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        // 분홍 혀 — `<ellipse cx="0" cy="16" rx="3" ry="2"/>` → SK y=-16.
        let tongue = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        tongue.fillColor = Self.pinkNose
        tongue.strokeColor = .clear
        tongue.position = CGPoint(x: 0, y: -16)
        tongue.zPosition = 30
        addChild(tongue)

        buildBlush()
    }
}
