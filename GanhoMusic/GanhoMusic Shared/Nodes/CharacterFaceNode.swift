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
    /// Sprint 7 Phase G — 5 캐릭터 × 4방향 분기. 단일 진입점.
    /// `.front` 케이스는 *기존 5 build 메서드를 그대로 재호출* → 정면 결과 byte-identical(회귀 0).
    /// `.back`/`.left`/`.right`는 신규 build{Back,Side} 헬퍼 — 머리 외곽 + 헤어 silhouette + (side: 한쪽 눈).
    /// `.right`는 `.left`를 그린 뒤 xScale = -1로 미러링 — path 중복 0.
    init(id: CharacterID, facing: Direction) {
        super.init()
        name = "characterFace_\(id.rawValue)_\(facing.rawValue)"
        switch facing {
        case .front:
            // 기존 5 build 본문 byte-identical 재호출 — 정면 결과 회귀 0.
            switch id {
            case .kim:  buildKimFace()
            case .jung: buildJungFace()
            case .geon: buildGeonFace()
            case .im:   buildImFace()
            case .lee:  buildLeeFace()
            }
        case .back:
            buildBackFace(id: id)
        case .left:
            buildSideFace(id: id)
        case .right:
            buildSideFace(id: id)
            xScale = -1  // 좌측 path 미러링 — 우측 전용 path 0 (코드 중복 회피).
        }
    }

    /// 5 캐릭터 분기 — 기존 호출자 시그니처 보존(CharacterSelectScene 등 회귀 0).
    /// `.front` 결과로 위임 → 본 init이 단순 1줄 delegation이라 기존 호출 결과 byte-identical.
    convenience init(id: CharacterID) {
        self.init(id: id, facing: .front)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Mini Factory (Sprint 7 Phase D)
    /// ScoreboardScene 행 헤더용 32pt 미니 얼굴 — 기존 `init(id:)` 결과를 0.47x로 축소.
    /// 신규 시각 자식 0건 — `setScale`만 적용해 코드 재사용. 카드 외부 부착 안전.
    /// `0.47 ≈ 32 / 68`(CharacterFaceNode head ellipse ry 34 × 2 = 68 → 32pt 목표).
    static func mini(id: CharacterID) -> CharacterFaceNode {
        let face = CharacterFaceNode(id: id)
        face.setScale(GameConfig.scoreboardMiniFaceScale)
        face.name = "miniFace_\(id.rawValue)"
        return face
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
    /// 기준 SVG: mockups/svg-exports/kim.svg (v1) — 형태 일치 확인. 좌표 스케일은 작은 좌표계(±32~±34) 유지.
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

    // MARK: - 2. Jung (핑크 러닝캡 + 안경 + 땀방울)
    /// 기준 SVG: mockups/svg-exports/jung.svg (v2) — 완전 재작성.
    /// 핑크 러닝캡(#FF8E80) + 챙(#C44A3D) + 안경(원형 + 흰 빛) + 결연한 눈썹 + 땀방울.
    /// 스파이크/곡괭이/헤드밴드 모두 제거.
    /// SVG ±64~±88 좌표계 → 코드 ±32~±44 (절반 축소).
    private func buildJungFace() {
        buildHeadBase()

        // 짧은 어두운 머리(모자에 거의 가려짐) — SVG `<path d="M -56 -20 Q -60 -44 -32 -48 L 32 -48 Q 60 -44 56 -20 ..."/>` 축소.
        // 좌표: SVG(-56,-20) → SK(-28, 10), SVG(-32,-48) → SK(-16, 24), SVG(32,-48) → SK(16, 24), SVG(56,-20) → SK(28, 10).
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -28, y: 10))
        hair.addQuadCurve(to: CGPoint(x: -16, y: 24), control: CGPoint(x: -30, y: 22))
        hair.addLine(to: CGPoint(x: 16, y: 24))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 10), control: CGPoint(x: 30, y: 22))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 16), control: CGPoint(x: 18, y: 16))
        hair.addQuadCurve(to: CGPoint(x: -28, y: 10), control: CGPoint(x: -18, y: 16))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")   // SVG fill="#1F1410"
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)

        // 핑크 러닝캡 본체 — SVG `<path d="M -44 -44 Q -44 -72 0 -76 Q 44 -72 44 -44 L 36 -36 L -36 -36 Z"/>` 축소.
        // 좌표: SVG(-44,-44) → SK(-22, 22), SVG(0,-76) → SK(0, 38), SVG(44,-44) → SK(22, 22).
        let cap = CGMutablePath()
        cap.move(to: CGPoint(x: -22, y: 22))
        cap.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -22, y: 36))
        cap.addQuadCurve(to: CGPoint(x: 22, y: 22), control: CGPoint(x: 22, y: 36))
        cap.addLine(to: CGPoint(x: 18, y: 18))
        cap.addLine(to: CGPoint(x: -18, y: 18))
        cap.closeSubpath()
        let capNode = SKShapeNode(path: cap)
        capNode.fillColor = UIColor(hex: "#FF8E80")  // SVG fill="#FF8E80" 핑크
        capNode.strokeColor = Self.navy
        capNode.lineWidth = 2.5
        capNode.lineJoin = .round
        capNode.zPosition = 20
        addChild(capNode)

        // 캡 챙 — SVG `<path d="M -60 -32 Q -40 -44 0 -44 Q 40 -44 60 -32 L 52 -24 L -52 -24 Z"/>` 축소.
        let brim = CGMutablePath()
        brim.move(to: CGPoint(x: -30, y: 16))
        brim.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: -20, y: 22))
        brim.addQuadCurve(to: CGPoint(x: 30, y: 16), control: CGPoint(x: 20, y: 22))
        brim.addLine(to: CGPoint(x: 26, y: 12))
        brim.addLine(to: CGPoint(x: -26, y: 12))
        brim.closeSubpath()
        let brimNode = SKShapeNode(path: brim)
        brimNode.fillColor = UIColor(hex: "#C44A3D")  // SVG fill="#C44A3D" 짙은 코랄
        brimNode.strokeColor = Self.navy
        brimNode.lineWidth = 2
        brimNode.lineJoin = .round
        brimNode.zPosition = 21
        addChild(brimNode)

        // 캡 로고(작은 흰색 원) — SVG `<circle cx="0" cy="-56" r="8"/>` 축소 → SK(0, 28) r=4.
        let logo = SKShapeNode(circleOfRadius: 4)
        logo.fillColor = .white
        logo.strokeColor = Self.navy
        logo.lineWidth = 1.5
        logo.position = CGPoint(x: 0, y: 28)
        logo.zPosition = 22
        addChild(logo)

        // 결연한 눈썹 — SVG `<path d="M -36 -20 L -16 -24"/>`/우측 대칭, 좌측 안쪽이 살짝 들림.
        // 좌측: SK(-18, 10) → SK(-8, 12). 우측: SK(8, 12) → SK(18, 10).
        let browLeft = CGMutablePath()
        browLeft.move(to: CGPoint(x: -18, y: 10))
        browLeft.addLine(to: CGPoint(x: -8, y: 12))
        let browLeftNode = SKShapeNode(path: browLeft)
        browLeftNode.strokeColor = Self.navy
        browLeftNode.lineWidth = 2.5
        browLeftNode.fillColor = .clear
        browLeftNode.lineCap = .round
        browLeftNode.zPosition = 30
        addChild(browLeftNode)

        let browRight = CGMutablePath()
        browRight.move(to: CGPoint(x: 8, y: 12))
        browRight.addLine(to: CGPoint(x: 18, y: 10))
        let browRightNode = SKShapeNode(path: browRight)
        browRightNode.strokeColor = Self.navy
        browRightNode.lineWidth = 2.5
        browRightNode.fillColor = .clear
        browRightNode.lineCap = .round
        browRightNode.zPosition = 30
        addChild(browRightNode)

        // 둥근 안경 렌즈 좌우 — SVG `<circle cx="±24" cy="-4" r="18"/>` 축소 → SK(±12, 2) r=9.
        for sign in [-1.0, 1.0] {
            let lens = SKShapeNode(circleOfRadius: 9)
            lens.fillColor = Self.glassesLens
            lens.strokeColor = Self.navy
            lens.lineWidth = 3
            lens.position = CGPoint(x: 12 * CGFloat(sign), y: 2)
            lens.zPosition = 40
            addChild(lens)

            // 결연한 동공 — SVG `<circle cx="±24" cy="-2" r="4"/>` 축소 → r=2.
            let pupil = SKShapeNode(circleOfRadius: 2)
            pupil.fillColor = Self.navy
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: 12 * CGFloat(sign), y: 1)
            pupil.zPosition = 41
            addChild(pupil)

            // 안경 빛 — SVG `<ellipse cx="-30 or 18" cy="-10" rx="5" ry="3"/>` 축소 → ry=1.5.
            let shine = SKShapeNode(ellipseOf: CGSize(width: 5, height: 3))
            shine.fillColor = UIColor.white.withAlphaComponent(0.6)
            shine.strokeColor = .clear
            // 좌측 렌즈는 좌상단 빛, 우측 렌즈는 우상단 빛.
            let shineDx: CGFloat = sign < 0 ? -3 : 3
            shine.position = CGPoint(x: 12 * CGFloat(sign) + shineDx, y: 5)
            shine.zPosition = 42
            addChild(shine)
        }

        // 안경 다리(가운데 가로 라인) — SVG `<line x1="-6" y1="-4" x2="6" y2="-4"/>` 축소.
        let bridge = CGMutablePath()
        bridge.move(to: CGPoint(x: -3, y: 2))
        bridge.addLine(to: CGPoint(x: 3, y: 2))
        let bridgeNode = SKShapeNode(path: bridge)
        bridgeNode.strokeColor = Self.navy
        bridgeNode.lineWidth = 2
        bridgeNode.fillColor = .clear
        bridgeNode.zPosition = 40
        addChild(bridgeNode)

        // 러너의 거친 호흡 입 — SVG `<path d="M -8 22 Q 0 32 8 22"/>` 축소 → SK y=-11~-16.
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -4, y: -11))
        mouth.addQuadCurve(to: CGPoint(x: 4, y: -11), control: CGPoint(x: 0, y: -16))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.5
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        // 살짝 벌어진 입 안쪽(어두운 타원) — SVG `<ellipse cx="0" cy="28" rx="7" ry="4" fill alpha 0.4"/>`.
        let mouthInner = SKShapeNode(ellipseOf: CGSize(width: 6, height: 3))
        mouthInner.fillColor = Self.navy.withAlphaComponent(0.4)
        mouthInner.strokeColor = .clear
        mouthInner.position = CGPoint(x: 0, y: -14)
        mouthInner.zPosition = 31
        addChild(mouthInner)

        // 땀방울(우측 위) — SVG `<path d="M 56 -20 Q 60 -12 64 -20 Q 60 -8 56 -20 Z" fill="#9BCDF0"/>`.
        // 축소 → SK(28~32, 10). 작은 물방울 모양.
        let sweat = CGMutablePath()
        sweat.move(to: CGPoint(x: 28, y: 10))
        sweat.addQuadCurve(to: CGPoint(x: 32, y: 10), control: CGPoint(x: 30, y: 6))
        sweat.addQuadCurve(to: CGPoint(x: 28, y: 10), control: CGPoint(x: 30, y: 4))
        sweat.closeSubpath()
        let sweatNode = SKShapeNode(path: sweat)
        sweatNode.fillColor = UIColor(hex: "#9BCDF0")  // SVG fill="#9BCDF0" 파스텔 블루
        sweatNode.strokeColor = Self.navy
        sweatNode.lineWidth = 1.5
        sweatNode.zPosition = 41
        addChild(sweatNode)

        // 태양에 그을린 볼터치(코랄 톤) — SVG `<ellipse cx="-44" cy="16" rx="10" ry="5" fill="#E87B6A" alpha 0.5"/>`.
        for sign in [-1.0, 1.0] {
            let cheek = SKShapeNode(ellipseOf: CGSize(width: 10, height: 5))
            cheek.fillColor = UIColor(hex: "#E87B6A").withAlphaComponent(0.5)
            cheek.strokeColor = .clear
            cheek.position = CGPoint(x: 22 * CGFloat(sign), y: -8)
            cheek.zPosition = 29
            addChild(cheek)
        }
    }

    // MARK: - 3. Geon (라벤더 너스캡 + 큰 둥근 검은 눈 + 위 머리 한 점 tuft)
    /// 기준 SVG: mockups/svg-exports/geon.svg (v6) — 완전 재작성 (쿠키런 톤).
    /// 어두운 머리(#1F1410) + 큰 둥근 검은 눈(rx=9 ry=12) + 위 한 점 tuft + 작은 미소.
    /// 안경/책 제거.
    /// SVG ±64~±88 좌표계 → 코드 ±32~±44 (절반 축소).
    private func buildGeonFace() {
        buildHeadBase()

        // 어두운 머리 단순 실루엣 — SVG `<path d="M -64 -20 Q -76 -76 -32 -76 ..."/>` 축소.
        // SVG(-64,-20) → SK(-32, 10), SVG(-32,-76) → SK(-16, 38), SVG(32,-76) → SK(16, 38), SVG(64,-20) → SK(32, 10).
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -32, y: 10))
        hair.addQuadCurve(to: CGPoint(x: -16, y: 38), control: CGPoint(x: -38, y: 38))
        hair.addQuadCurve(to: CGPoint(x: 16, y: 38), control: CGPoint(x: 0, y: 42))
        hair.addQuadCurve(to: CGPoint(x: 32, y: 10), control: CGPoint(x: 38, y: 38))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: 24, y: 24))
        hair.addQuadCurve(to: CGPoint(x: -32, y: 10), control: CGPoint(x: -24, y: 24))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")  // SVG fill="#1F1410"
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2.5
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)

        // 위 머리 한 점 tuft (귀여운 포인트) — SVG `<path d="M -6 -76 Q 0 -88 6 -76 ..."/>` 축소.
        let tuft = CGMutablePath()
        tuft.move(to: CGPoint(x: -3, y: 38))
        tuft.addQuadCurve(to: CGPoint(x: 3, y: 38), control: CGPoint(x: 0, y: 44))
        tuft.addQuadCurve(to: CGPoint(x: -1, y: 41), control: CGPoint(x: 1, y: 41))
        tuft.addQuadCurve(to: CGPoint(x: -3, y: 38), control: CGPoint(x: -3, y: 41))
        tuft.closeSubpath()
        let tuftNode = SKShapeNode(path: tuft)
        tuftNode.fillColor = UIColor(hex: "#1F1410")
        tuftNode.strokeColor = Self.navy
        tuftNode.lineWidth = 1.5
        tuftNode.lineJoin = .round
        tuftNode.zPosition = 11
        addChild(tuftNode)

        buildNurseCap()

        // 큰 둥근 검은 눈 (chibi 정석) — SVG `<ellipse cx="±22" cy="-2" rx="9" ry="12"/>` 축소 → rx=4.5, ry=6.
        for sign in [-1.0, 1.0] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 9, height: 12))
            eye.fillColor = Self.navy
            eye.strokeColor = .clear
            eye.position = CGPoint(x: 11 * CGFloat(sign), y: 1)
            eye.zPosition = 30
            addChild(eye)

            // 단일 흰 highlight — SVG `<circle cx="-24 or 20" cy="-6" r="3.6"/>` 축소 → r=1.8.
            let hl = SKShapeNode(circleOfRadius: 1.8)
            hl.fillColor = .white
            hl.strokeColor = .clear
            let hlDx: CGFloat = sign < 0 ? -1 : -1
            hl.position = CGPoint(x: 11 * CGFloat(sign) + hlDx, y: 3)
            hl.zPosition = 31
            addChild(hl)
        }

        // 작은 미소 — SVG `<path d="M -8 28 Q 0 34 8 28"/>` 축소 → SK y=-14.
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

        buildBlush(radiusX: 5, radiusY: 3, cy: 10, alpha: 0.65)
    }

    // MARK: - 4. Im (긴머리 + 가운데 가르마 + 작은 고양이귀 + 큰 둥근 눈)
    /// 기준 SVG: mockups/svg-exports/im.svg (v6) — 부분 재이식 (수염 제거).
    /// 긴머리 좌우 + 가운데 가르마 앞머리 + 작은 고양이귀 + 큰 둥근 눈 + 흰 highlight + 분홍 고양이코.
    /// **수염 제거 + 고양이눈 → 큰 둥근 눈 교체 + 앞머리 가운데 가르마 path 갱신.**
    private func buildImFace() {
        // 긴머리(좌우) — 머리 베이스보다 먼저 그림(뒤에 깔리도록).
        // SVG: `<path d="M -68 -16 Q -88 56 -72 116 ..."/>` 축소 → ±34~±36 좌표.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let hair = CGMutablePath()
            hair.move(to: CGPoint(x: 34 * s, y: 8))
            hair.addQuadCurve(to: CGPoint(x: 36 * s, y: -28), control: CGPoint(x: 44 * s, y: -28))
            hair.addQuadCurve(to: CGPoint(x: 22 * s, y: -48), control: CGPoint(x: 30 * s, y: -50))
            hair.addLine(to: CGPoint(x: 20 * s, y: -28))
            hair.addQuadCurve(to: CGPoint(x: 28 * s, y: 10), control: CGPoint(x: 30 * s, y: -10))
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

        // 가운데 가르마 앞머리 — SVG `<path d="M -64 -20 Q -72 -76 -28 -80 L -4 -64 L 0 -72 L 4 -64 L 28 -80 ..."/>` 축소.
        // 핵심: 가운데 V자(가르마)가 명확히 보이도록 짧은 라인 segment 두 개 추가.
        let bangs = CGMutablePath()
        bangs.move(to: CGPoint(x: -32, y: 10))
        bangs.addQuadCurve(to: CGPoint(x: -14, y: 40), control: CGPoint(x: -36, y: 38))
        bangs.addLine(to: CGPoint(x: -2, y: 32))   // V자 좌측 아래 — 가르마.
        bangs.addLine(to: CGPoint(x: 0, y: 36))    // V자 정점.
        bangs.addLine(to: CGPoint(x: 2, y: 32))    // V자 우측 아래 — 가르마.
        bangs.addLine(to: CGPoint(x: 14, y: 40))
        bangs.addQuadCurve(to: CGPoint(x: 32, y: 10), control: CGPoint(x: 36, y: 38))
        bangs.addQuadCurve(to: CGPoint(x: 2, y: 22), control: CGPoint(x: 22, y: 22))
        bangs.addLine(to: CGPoint(x: -2, y: 22))
        bangs.addQuadCurve(to: CGPoint(x: -32, y: 10), control: CGPoint(x: -22, y: 22))
        bangs.closeSubpath()
        let bangsNode = SKShapeNode(path: bangs)
        bangsNode.fillColor = Self.hairBrown
        bangsNode.strokeColor = Self.navy
        bangsNode.lineWidth = 2
        bangsNode.lineJoin = .round
        bangsNode.zPosition = 10
        addChild(bangsNode)

        // 작은 고양이 귀(삼각형) — SVG `<path d="M -40 -68 L -28 -44 L -16 -68 Z"/>` 축소.
        // 좌측: SK(-20, 34) ~ (-14, 22) ~ (-8, 34). 작아짐.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let ear = CGMutablePath()
            ear.move(to: CGPoint(x: 20 * s, y: 34))
            ear.addLine(to: CGPoint(x: 14 * s, y: 22))
            ear.addLine(to: CGPoint(x: 8 * s, y: 34))
            ear.closeSubpath()
            let earNode = SKShapeNode(path: ear)
            earNode.fillColor = Self.hairBrown
            earNode.strokeColor = Self.navy
            earNode.lineWidth = 2
            earNode.lineJoin = .round
            earNode.zPosition = 20
            addChild(earNode)

            // 귀 안쪽 분홍 — SVG `<path d="M -32 -60 L -28 -52 L -24 -60 Z"/>` 축소.
            let inner = CGMutablePath()
            inner.move(to: CGPoint(x: 16 * s, y: 30))
            inner.addLine(to: CGPoint(x: 14 * s, y: 26))
            inner.addLine(to: CGPoint(x: 12 * s, y: 30))
            inner.closeSubpath()
            let innerNode = SKShapeNode(path: inner)
            innerNode.fillColor = Self.blush
            innerNode.strokeColor = .clear
            innerNode.zPosition = 21
            addChild(innerNode)
        }

        // 큰 둥근 검은 눈(chibi 정석) — SVG `<ellipse cx="±22" cy="-2" rx="10" ry="13"/>` 축소 → rx=5, ry=6.5.
        for sign in [-1.0, 1.0] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 10, height: 13))
            eye.fillColor = Self.navy
            eye.strokeColor = .clear
            eye.position = CGPoint(x: 11 * CGFloat(sign), y: 1)
            eye.zPosition = 30
            addChild(eye)

            // 단일 흰 highlight — SVG `<circle cx="-24 or 20" cy="-6" r="4"/>` 축소 → r=2.
            let hl = SKShapeNode(circleOfRadius: 2)
            hl.fillColor = .white
            hl.strokeColor = .clear
            let hlDx: CGFloat = sign < 0 ? -1 : -1
            hl.position = CGPoint(x: 11 * CGFloat(sign) + hlDx, y: 3)
            hl.zPosition = 31
            addChild(hl)
        }

        // 작은 미소 — SVG `<path d="M -6 26 Q 0 32 6 26"/>` 축소 → SK y=-13.
        let mouth = CGMutablePath()
        mouth.move(to: CGPoint(x: -3, y: -13))
        mouth.addQuadCurve(to: CGPoint(x: 3, y: -13), control: CGPoint(x: 0, y: -16))
        let mouthNode = SKShapeNode(path: mouth)
        mouthNode.strokeColor = Self.navy
        mouthNode.lineWidth = 2.3
        mouthNode.fillColor = .clear
        mouthNode.lineCap = .round
        mouthNode.zPosition = 30
        addChild(mouthNode)

        // 분홍 고양이 코(작게) — SVG `<ellipse cx="0" cy="14" rx="3" ry="2.4"/>` 축소 → rx=1.5, ry=1.2.
        let nose = SKShapeNode(ellipseOf: CGSize(width: 3, height: 2.4))
        nose.fillColor = Self.pinkNose
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: -7)
        nose.zPosition = 30
        addChild(nose)

        buildBlush(radiusX: 5, radiusY: 3, cy: 10, alpha: 0.65)
    }

    // MARK: - 5. Lee (곱슬 단발 + side curls + 닫힌 눈 미소)
    /// 기준 SVG: mockups/svg-exports/lee.svg (v3) — 부분 재이식 (강아지귀 제거).
    /// 곱슬 단발 side curls + 앞머리 + 닫힌 눈 미소(SVG 시그너처) + 따뜻한 미소.
    /// **강아지귀 ellipse 제거 + side curls + curl detail dots 추가 + 동그란 눈 → 닫힌 눈 path 교체 + 혀 제거.**
    private func buildLeeFace() {
        // Side curls (좌우 곱슬 — 머리 베이스보다 먼저 그려 뒤에 깔림).
        // SVG `<path d="M -64 -16 Q -76 16 -72 44 Q -68 68 -56 76 Q -44 56 -52 36 Q -64 16 -60 -20 Z"/>` 축소.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let curl = CGMutablePath()
            curl.move(to: CGPoint(x: 32 * s, y: 8))
            curl.addQuadCurve(to: CGPoint(x: 36 * s, y: -22), control: CGPoint(x: 38 * s, y: -8))
            curl.addQuadCurve(to: CGPoint(x: 28 * s, y: -38), control: CGPoint(x: 34 * s, y: -34))
            curl.addQuadCurve(to: CGPoint(x: 26 * s, y: -18), control: CGPoint(x: 22 * s, y: -28))
            curl.addQuadCurve(to: CGPoint(x: 30 * s, y: 10), control: CGPoint(x: 32 * s, y: -8))
            curl.closeSubpath()
            let curlNode = SKShapeNode(path: curl)
            curlNode.fillColor = Self.hairBrown
            curlNode.strokeColor = Self.navy
            curlNode.lineWidth = 2
            curlNode.lineJoin = .round
            curlNode.zPosition = -1
            addChild(curlNode)
        }

        // Curl detail dots (좌우 위·아래 한 쌍씩) — SVG `<circle cx="±60" cy="40" r="8"/>` + `<circle cx="±52" cy="64" r="6"/>` 축소.
        let curlDotCoords: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
            (-30, -20, 4),
            (30, -20, 4),
            (-26, -32, 3),
            (26, -32, 3)
        ]
        for coord in curlDotCoords {
            let dot = SKShapeNode(circleOfRadius: coord.r)
            dot.fillColor = Self.hairBrown
            dot.strokeColor = Self.navy
            dot.lineWidth = 1.5
            dot.position = CGPoint(x: coord.x, y: coord.y)
            dot.zPosition = 1
            addChild(dot)
        }

        buildHeadBase()

        // 앞머리 — SVG `<path d="M -56 -28 Q -64 -64 -32 -68 L -16 -56 L -4 -64 L 4 -64 L 16 -56 L 32 -68 ..."/>` 축소.
        let bangs = CGMutablePath()
        bangs.move(to: CGPoint(x: -28, y: 14))
        bangs.addQuadCurve(to: CGPoint(x: -16, y: 34), control: CGPoint(x: -32, y: 32))
        bangs.addLine(to: CGPoint(x: -8, y: 28))
        bangs.addLine(to: CGPoint(x: -2, y: 32))
        bangs.addLine(to: CGPoint(x: 2, y: 32))
        bangs.addLine(to: CGPoint(x: 8, y: 28))
        bangs.addLine(to: CGPoint(x: 16, y: 34))
        bangs.addQuadCurve(to: CGPoint(x: 28, y: 14), control: CGPoint(x: 32, y: 32))
        bangs.addQuadCurve(to: CGPoint(x: 8, y: 22), control: CGPoint(x: 18, y: 22))
        bangs.addQuadCurve(to: CGPoint(x: -8, y: 22), control: CGPoint(x: 0, y: 24))
        bangs.addQuadCurve(to: CGPoint(x: -28, y: 14), control: CGPoint(x: -18, y: 22))
        bangs.closeSubpath()
        let bangsNode = SKShapeNode(path: bangs)
        bangsNode.fillColor = Self.hairBrown
        bangsNode.strokeColor = Self.navy
        bangsNode.lineWidth = 2
        bangsNode.lineJoin = .round
        bangsNode.zPosition = 10
        addChild(bangsNode)

        // 작은 fringe 디테일 점(앞머리 텍스처) — SVG `<circle cx="±36" cy="-44" r="5" opacity 0.4"/>` 축소.
        for sign in [-1.0, 1.0] {
            let dot = SKShapeNode(circleOfRadius: 2.5)
            dot.fillColor = UIColor(hex: "#1F1410").withAlphaComponent(0.4)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: 18 * CGFloat(sign), y: 22)
            dot.zPosition = 11
            addChild(dot)
        }

        // 닫힌 눈 미소 (SVG 시그너처) — SVG `<path d="M -32 -4 Q -20 -16 -12 -2"/>` 축소.
        // 좌측: SK(-16, 2) Q (-10, 8) (-6, 1). 우측 대칭.
        for sign in [-1.0, 1.0] {
            let s = CGFloat(sign)
            let eye = CGMutablePath()
            eye.move(to: CGPoint(x: 16 * s, y: 2))
            eye.addQuadCurve(
                to: CGPoint(x: 6 * s, y: 1),
                control: CGPoint(x: 10 * s, y: 8)
            )
            let eyeNode = SKShapeNode(path: eye)
            eyeNode.strokeColor = Self.navy
            eyeNode.lineWidth = 2.8
            eyeNode.fillColor = .clear
            eyeNode.lineCap = .round
            eyeNode.zPosition = 30
            addChild(eyeNode)
        }

        // 따뜻한 미소 — SVG `<path d="M -12 24 Q 0 36 12 24"/>` 축소 → SK y=-12.
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

        // 강한 볼터치(따뜻한·축제 느낌) — SVG `<ellipse cx="-44" cy="20" rx="14" ry="8" alpha 0.75"/>` 축소 → rx=7, ry=4.
        buildBlush(radiusX: 7, radiusY: 4, cy: 10, alpha: 0.75)
    }

    // MARK: - Sprint 7 Phase G · Back Face (5 캐릭터 뒤통수)
    /// 뒷모습 — 머리 외곽(공유 head ellipse) + 헤어 silhouette만. 눈/입 없음(자연 톤).
    /// 5 캐릭터 헤어 색은 동일(hairBrown) — 실루엣 차이는 후속 sprint에서 보강 후보.
    /// front 5 build 본문 byte-identical 보존(주의사항 5) — 본 분기는 *별도 path*를 그림.
    private func buildBackFace(id: CharacterID) {
        buildHeadBase()
        switch id {
        case .kim:  buildKimHairBack()
        case .jung: buildJungHairBack()
        case .geon: buildGeonHairBack()
        case .im:   buildImHairBack()
        case .lee:  buildLeeHairBack()
        }
    }

    /// 측면 — 머리 외곽 + 헤어 한쪽 + 눈 1개(앞쪽).
    /// .left 호출 시만 그려지고, .right는 init(id:facing:)에서 xScale=-1로 미러링.
    private func buildSideFace(id: CharacterID) {
        buildHeadBase()
        switch id {
        case .kim:  buildKimSide()
        case .jung: buildJungSide()
        case .geon: buildGeonSide()
        case .im:   buildImSide()
        case .lee:  buildLeeSide()
        }
    }

    // MARK: - Helpers — Back Hair (5 캐릭터)
    /// 김간호 뒷모습 — 번머리 silhouette 큰 path. 모자(흰 너스캡)는 표시.
    private func buildKimHairBack() {
        // 큰 뒤통수 헤어 — front bun과 유사한 외곽이지만 *얼굴 디테일 0*.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -28, y: 12))
        hair.addQuadCurve(to: CGPoint(x: -18, y: 32), control: CGPoint(x: -32, y: 28))
        hair.addQuadCurve(to: CGPoint(x: 18, y: 32), control: CGPoint(x: 0, y: 36))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 12), control: CGPoint(x: 32, y: 28))
        hair.addQuadCurve(to: CGPoint(x: 0, y: -18), control: CGPoint(x: 30, y: -10))
        hair.addQuadCurve(to: CGPoint(x: -28, y: 12), control: CGPoint(x: -30, y: -10))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 너스캡은 뒤에서도 보임 (윗부분).
        buildNurseCap()
    }

    /// 정간호 뒷모습 — 핑크 러닝캡 뒤 + 짧은 머리. 캡 뒷부분(둥근 윗면).
    private func buildJungHairBack() {
        // 짧은 머리 silhouette.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -28, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 36), control: CGPoint(x: -30, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 10), control: CGPoint(x: 30, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 0, y: -16), control: CGPoint(x: 26, y: -8))
        hair.addQuadCurve(to: CGPoint(x: -28, y: 10), control: CGPoint(x: -26, y: -8))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 핑크 러닝캡 뒷부분 (둥근 윗부분만).
        let cap = CGMutablePath()
        cap.move(to: CGPoint(x: -22, y: 22))
        cap.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -22, y: 36))
        cap.addQuadCurve(to: CGPoint(x: 22, y: 22), control: CGPoint(x: 22, y: 36))
        cap.addLine(to: CGPoint(x: 18, y: 18))
        cap.addLine(to: CGPoint(x: -18, y: 18))
        cap.closeSubpath()
        let capNode = SKShapeNode(path: cap)
        capNode.fillColor = UIColor(hex: "#FF8E80")
        capNode.strokeColor = Self.navy
        capNode.lineWidth = 2.5
        capNode.lineJoin = .round
        capNode.zPosition = 20
        addChild(capNode)
    }

    /// 건간호 뒷모습 — 너스캡 뒤 + 어두운 머리.
    private func buildGeonHairBack() {
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -32, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 38), control: CGPoint(x: -38, y: 38))
        hair.addQuadCurve(to: CGPoint(x: 32, y: 10), control: CGPoint(x: 38, y: 38))
        hair.addQuadCurve(to: CGPoint(x: 0, y: -18), control: CGPoint(x: 30, y: -8))
        hair.addQuadCurve(to: CGPoint(x: -32, y: 10), control: CGPoint(x: -30, y: -8))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2.5
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        buildNurseCap()
    }

    /// 임간호 뒷모습 — 긴머리 전체 silhouette.
    private func buildImHairBack() {
        // 큰 긴머리 — 어깨까지 흘러내림(타원형 큰 silhouette).
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -34, y: 8))
        hair.addQuadCurve(to: CGPoint(x: -22, y: -48), control: CGPoint(x: -44, y: -28))
        hair.addLine(to: CGPoint(x: 22, y: -48))
        hair.addQuadCurve(to: CGPoint(x: 34, y: 8), control: CGPoint(x: 44, y: -28))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 36), control: CGPoint(x: 36, y: 32))
        hair.addQuadCurve(to: CGPoint(x: -34, y: 8), control: CGPoint(x: -36, y: 32))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
    }

    /// 이간호 뒷모습 — 곱슬 단발 silhouette + 작은 컬 디테일 dot 2개.
    private func buildLeeHairBack() {
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -30, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 0, y: 36), control: CGPoint(x: -32, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 30, y: 10), control: CGPoint(x: 32, y: 32))
        hair.addQuadCurve(to: CGPoint(x: 0, y: -22), control: CGPoint(x: 28, y: -10))
        hair.addQuadCurve(to: CGPoint(x: -30, y: 10), control: CGPoint(x: -28, y: -10))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 컬 디테일 dot 2개(어깨선 위치).
        for sign in [-1.0, 1.0] {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = Self.hairBrown
            dot.strokeColor = Self.navy
            dot.lineWidth = 1.5
            dot.position = CGPoint(x: 22 * CGFloat(sign), y: 0)
            dot.zPosition = 11
            addChild(dot)
        }
    }

    // MARK: - Helpers — Side Face (5 캐릭터, .left 기준)
    /// 김간호 측면 — 번머리 한쪽 + 눈 1개(앞쪽).
    /// 좌측 향 기준: 머리·헤어 silhouette이 *좌측*으로 살짝 기울고, 눈은 *얼굴 우측(0~+10)* 1개.
    /// path는 .left 기준으로 그리고, init(id:facing:)에서 .right일 때만 xScale=-1.
    private func buildKimSide() {
        // 헤어 — 뒤쪽(우측) 절반에 번머리. 좌측은 얼굴 윤곽 따라 흘러내림.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -22, y: 12))
        hair.addQuadCurve(to: CGPoint(x: -12, y: 30), control: CGPoint(x: -26, y: 28))
        hair.addQuadCurve(to: CGPoint(x: 18, y: 32), control: CGPoint(x: 4, y: 36))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 8), control: CGPoint(x: 32, y: 24))
        hair.addQuadCurve(to: CGPoint(x: 18, y: -10), control: CGPoint(x: 28, y: -6))
        hair.addLine(to: CGPoint(x: -10, y: 16))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 12), control: CGPoint(x: -18, y: 14))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)

        // 눈 1개(앞쪽 = 좌측 향이므로 화면 좌측, 좌표 x=-8).
        let eye = SKShapeNode(ellipseOf: CGSize(width: 5, height: 6))
        eye.fillColor = Self.navy
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -8, y: 2)
        eye.zPosition = 30
        addChild(eye)
    }

    /// 정간호 측면 — 핑크 캡 + 짧은 머리 한쪽 + 눈 1개.
    private func buildJungSide() {
        // 짧은 머리.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -22, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 18, y: 22), control: CGPoint(x: 0, y: 30))
        hair.addQuadCurve(to: CGPoint(x: 28, y: 0), control: CGPoint(x: 30, y: 14))
        hair.addLine(to: CGPoint(x: -10, y: 14))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 10), control: CGPoint(x: -18, y: 12))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 핑크 러닝캡 (옆에서 보면 챙 + 크라운 한쪽 윤곽).
        let cap = CGMutablePath()
        cap.move(to: CGPoint(x: -20, y: 22))
        cap.addQuadCurve(to: CGPoint(x: 14, y: 30), control: CGPoint(x: -8, y: 34))
        cap.addLine(to: CGPoint(x: 22, y: 20))
        cap.addLine(to: CGPoint(x: -18, y: 18))
        cap.closeSubpath()
        let capNode = SKShapeNode(path: cap)
        capNode.fillColor = UIColor(hex: "#FF8E80")
        capNode.strokeColor = Self.navy
        capNode.lineWidth = 2
        capNode.lineJoin = .round
        capNode.zPosition = 20
        addChild(capNode)
        // 캡 챙 (앞쪽으로 살짝 튀어나옴 — 좌측 향이므로 화면 좌측).
        let brim = SKShapeNode(rectOf: CGSize(width: 14, height: 3))
        brim.fillColor = UIColor(hex: "#C44A3D")
        brim.strokeColor = Self.navy
        brim.lineWidth = 1.5
        brim.position = CGPoint(x: -16, y: 16)
        brim.zPosition = 21
        addChild(brim)
        // 눈 1개(앞쪽).
        let eye = SKShapeNode(circleOfRadius: 2)
        eye.fillColor = Self.navy
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -10, y: 2)
        eye.zPosition = 30
        addChild(eye)
    }

    /// 건간호 측면 — 어두운 머리 + 너스캡 + 둥근 큰 눈 1개.
    private func buildGeonSide() {
        // 어두운 머리 한쪽.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -22, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 18, y: 32), control: CGPoint(x: 0, y: 38))
        hair.addQuadCurve(to: CGPoint(x: 30, y: 6), control: CGPoint(x: 34, y: 24))
        hair.addLine(to: CGPoint(x: -10, y: 14))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 10), control: CGPoint(x: -18, y: 12))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = UIColor(hex: "#1F1410")
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2.5
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        buildNurseCap()
        // 큰 둥근 검은 눈 1개(앞쪽).
        let eye = SKShapeNode(ellipseOf: CGSize(width: 8, height: 10))
        eye.fillColor = Self.navy
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -8, y: 2)
        eye.zPosition = 30
        addChild(eye)
        // 흰 highlight.
        let hl = SKShapeNode(circleOfRadius: 1.5)
        hl.fillColor = .white
        hl.strokeColor = .clear
        hl.position = CGPoint(x: -9, y: 4)
        hl.zPosition = 31
        addChild(hl)
    }

    /// 임간호 측면 — 긴머리 한쪽 + 고양이귀 1개 + 큰 둥근 눈 1개.
    private func buildImSide() {
        // 긴머리 한쪽 — 어깨까지 흘러내림(좌측 향이라 머리 뒤쪽 = 우측).
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -22, y: 8))
        hair.addQuadCurve(to: CGPoint(x: 14, y: -42), control: CGPoint(x: 38, y: -28))
        hair.addLine(to: CGPoint(x: 22, y: -42))
        hair.addQuadCurve(to: CGPoint(x: 30, y: 8), control: CGPoint(x: 40, y: -20))
        hair.addQuadCurve(to: CGPoint(x: 14, y: 32), control: CGPoint(x: 30, y: 28))
        hair.addQuadCurve(to: CGPoint(x: -10, y: 16), control: CGPoint(x: 0, y: 22))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 8), control: CGPoint(x: -16, y: 10))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 고양이 귀 1개(뒤쪽).
        let ear = CGMutablePath()
        ear.move(to: CGPoint(x: 18, y: 34))
        ear.addLine(to: CGPoint(x: 12, y: 22))
        ear.addLine(to: CGPoint(x: 6, y: 34))
        ear.closeSubpath()
        let earNode = SKShapeNode(path: ear)
        earNode.fillColor = Self.hairBrown
        earNode.strokeColor = Self.navy
        earNode.lineWidth = 2
        earNode.lineJoin = .round
        earNode.zPosition = 20
        addChild(earNode)
        // 큰 둥근 눈 1개(앞쪽).
        let eye = SKShapeNode(ellipseOf: CGSize(width: 8, height: 11))
        eye.fillColor = Self.navy
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -8, y: 2)
        eye.zPosition = 30
        addChild(eye)
        // 흰 highlight.
        let hl = SKShapeNode(circleOfRadius: 1.8)
        hl.fillColor = .white
        hl.strokeColor = .clear
        hl.position = CGPoint(x: -9, y: 4)
        hl.zPosition = 31
        addChild(hl)
    }

    /// 이간호 측면 — 곱슬 단발 한쪽 + 닫힌 눈 미소 1개.
    private func buildLeeSide() {
        // 곱슬 단발 한쪽.
        let hair = CGMutablePath()
        hair.move(to: CGPoint(x: -22, y: 10))
        hair.addQuadCurve(to: CGPoint(x: 16, y: 32), control: CGPoint(x: 0, y: 34))
        hair.addQuadCurve(to: CGPoint(x: 30, y: 8), control: CGPoint(x: 34, y: 24))
        hair.addQuadCurve(to: CGPoint(x: 20, y: -16), control: CGPoint(x: 30, y: -6))
        hair.addLine(to: CGPoint(x: -10, y: 14))
        hair.addQuadCurve(to: CGPoint(x: -22, y: 10), control: CGPoint(x: -18, y: 12))
        hair.closeSubpath()
        let hairNode = SKShapeNode(path: hair)
        hairNode.fillColor = Self.hairBrown
        hairNode.strokeColor = Self.navy
        hairNode.lineWidth = 2
        hairNode.lineJoin = .round
        hairNode.zPosition = 10
        addChild(hairNode)
        // 컬 디테일 dot 1개(뒷부분).
        let dot = SKShapeNode(circleOfRadius: 3)
        dot.fillColor = Self.hairBrown
        dot.strokeColor = Self.navy
        dot.lineWidth = 1.5
        dot.position = CGPoint(x: 22, y: -10)
        dot.zPosition = 11
        addChild(dot)
        // 닫힌 눈 미소 1개(앞쪽 — SVG 시그너처).
        let eye = CGMutablePath()
        eye.move(to: CGPoint(x: -12, y: 2))
        eye.addQuadCurve(to: CGPoint(x: -4, y: 1), control: CGPoint(x: -8, y: 7))
        let eyeNode = SKShapeNode(path: eye)
        eyeNode.strokeColor = Self.navy
        eyeNode.lineWidth = 2.5
        eyeNode.fillColor = .clear
        eyeNode.lineCap = .round
        eyeNode.zPosition = 30
        addChild(eyeNode)
    }
}
