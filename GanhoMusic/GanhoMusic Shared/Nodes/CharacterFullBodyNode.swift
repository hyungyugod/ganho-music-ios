//
//  CharacterFullBodyNode.swift
//  GanhoMusic Shared
//
/// [Sprint 10 Phase A] 사용처 제거됨 — 후속 Phase에서 파일 삭제 후보. 본 Phase 본문 0줄 변경.
//
//  Sprint 8 Phase G · 인게임 풀바디 캐릭터 시각 (5명 × 4방향 = 20셀)
//  Sprint 9 Phase B · 2칸(64pt) 크기 축소 + 캐릭터별 정체성 자식 5종
//
//  CharacterFaceNode(얼굴 전용, 선택 화면)와 분리된 *풀바디 시각* 노드.
//  PlayerNode가 apply(_:) 시점에 자식으로 부착 — D-Pad 입력 시 팔다리 보이는 캐릭터 정체성.
//
//  Sprint 9 Phase B 변경:
//   - 풀바디 path 좌표/크기를 GameConfig V9 상수로 일괄 축소 (body 56×44 → 40×32, head r18 → r12 등).
//   - 캐릭터별 정체성 자식 1~2개 추가 — 5종 × 4방향 × switch exhaustive.
//     · .kim: 빨강 십자 (캡 위 작은 십자 2조각)
//     · .jung: 둥근 안경 2개 + bridge (정면/뒷면) — 측면은 한쪽 렌즈만
//     · .geon: 코랄 야구캡 (캡 위 덮기)
//     · .im: 사이드테일 (좌측면=좌, 우측면=우, 정/후면=우 기본)
//     · .lee: 양 옆 묶음 머리 (양쪽 작은 핀)
//   - left/right body 변형은 50×44 → 36×32, head x=±4 → ±2.5 비율 축소.
//
//  사용자 의사결정 #10 — CharacterFaceNode·NurseAvatarNode 본체 git diff 0줄 보장(본 파일은 신규).
//

import SpriteKit

/// 인게임 풀바디 캐릭터 노드. PlayerNode가 apply(_:)에서 자식으로 부착.
/// 4방향 container를 미리 build, facing(_:) 호출 시 isHidden 토글만 — 매 프레임 호출 비용 0.
/// 게임 로직(velocity/physicsBody/skill) 0건 변경 — 순수 시각 layer.
final class CharacterFullBodyNode: SKNode {

    // MARK: - Properties
    let id: CharacterID
    private var directionContainers: [Direction: SKNode] = [:]
    private(set) var currentFacing: Direction = .front

    // MARK: - Palette
    /// 캐릭터별 색 팔레트. id로 분기 — 1차는 *몸통/머리/모자 3색*만 차등.
    /// CharacterID.color(카드 배경색)와 일관성 유지 — 같은 캐릭터가 카드/인게임에서 같은 톤.
    private struct Palette {
        let body: UIColor    // 가운/스크럽 (몸통/팔/다리 공통)
        let hair: UIColor    // 머리카락 색 (head stroke)
        let cap: UIColor     // 간호사 캡 (머리 위 작은 사각형)
    }

    // MARK: - Init
    init(id: CharacterID) {
        self.id = id
        super.init()
        buildAllDirections()
        // 초기 facing은 .front — 정지 상태에서 카메라 정면 (CharacterFaceNode 톤 일관).
        directionContainers[.front]?.isHidden = false
        startIdleBreath()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Facing
    /// PlayerNode.facing(_:)에서 호출. isHidden 토글만 → 다음 SK 프레임(~16ms) 안 전환.
    /// 같은 방향 재호출 noop — currentFacing 가드.
    func facing(_ direction: Direction) {
        guard direction != currentFacing else { return }
        directionContainers[currentFacing]?.isHidden = true
        directionContainers[direction]?.isHidden = false
        currentFacing = direction
    }

    // MARK: - Build
    /// 4방향 container 일괄 build. 모두 isHidden=true 시작, init 마지막에 .front만 노출.
    private func buildAllDirections() {
        for direction in [Direction.front, .back, .left, .right] {
            let container = SKNode()
            container.isHidden = true
            buildBody(in: container, direction: direction)
            directionContainers[direction] = container
            addChild(container)
        }
    }

    /// 방향별 body 분기. 1차는 *김간호 패턴 공유* — 색만 다름.
    /// Sprint 9 Phase B — 각 buildXxxBody 끝에서 attachIdentityMarker로 캐릭터별 정체성 부착.
    private func buildBody(in container: SKNode, direction: Direction) {
        let palette = colorPalette(for: id)
        switch direction {
        case .front: buildFrontBody(in: container, palette: palette)
        case .back:  buildBackBody(in: container, palette: palette)
        case .left:  buildLeftBody(in: container, palette: palette)
        case .right: buildRightBody(in: container, palette: palette)
        }
        attachIdentityMarker(in: container, direction: direction)
    }

    /// CharacterID별 색 팔레트 lookup. switch default 미사용 — 5 case exhaustive.
    /// 모든 색은 ColorTokens 기존 토큰 재사용 — 신규 토큰 0.
    private func colorPalette(for id: CharacterID) -> Palette {
        switch id {
        case .kim:  return Palette(body: .ganhoPaper,        hair: .ganhoNavyDeep, cap: .ganhoCoralLight)
        case .jung: return Palette(body: .ganhoScrubMint,    hair: .ganhoNavyDeep, cap: .ganhoPaper)
        case .geon: return Palette(body: .ganhoBgWarmTop,    hair: .ganhoNavyDeep, cap: .ganhoCoralPrimary)
        case .im:   return Palette(body: .ganhoLavenderSoft, hair: .ganhoNavyDeep, cap: .ganhoPaper)
        case .lee:  return Palette(body: .ganhoBloodAccent,
                                   hair: .ganhoNavyDeep, cap: .ganhoPaper)
        }
    }

    // MARK: - Body Paths

    /// 정면 body — 어깨/몸통/머리/모자/팔×2/다리×2.
    /// 좌표 약속: (0,0) = 캐릭터 중심. 머리 위쪽(+y), 다리 아래쪽(-y).
    /// 모든 노드는 container 자식 — 외부 facing 토글 시 isHidden 1개로 전체 전환.
    /// Sprint 9 Phase B — V9 상수로 일괄 축소(body 56×44 → 40×32, head r18 → r12 등).
    private func buildFrontBody(in container: SKNode, palette: Palette) {
        // 어깨/몸통 (가장 뒤)
        let bodySize = CGSize(width: GameConfig.playerFullBodyBodyWidthV9,
                              height: GameConfig.playerFullBodyBodyHeightV9)
        let body = SKShapeNode(rectOf: bodySize, cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 0, y: -12)
        body.zPosition = 0
        container.addChild(body)

        // 다리 2개 (몸통 아래) — V9 leg height 18, offsetY -34
        attachLegs(in: container, palette: palette, offsetY: -34)

        // 팔 2개 (몸통 옆) — V9 body width 40 → ±22 (체크 좌표 절반 + 2)
        attachArm(in: container, palette: palette, x: -22, prefix: "armL")
        attachArm(in: container, palette: palette, x:  22, prefix: "armR")

        // 머리 (가장 위) — V9 r12, y=14
        let head = SKShapeNode(circleOfRadius: GameConfig.playerFullBodyHeadRadiusV9)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: 0, y: 14)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락 (머리 위 반원 hint) — V9 22×7, y=21
        let hairSize = CGSize(width: GameConfig.playerFullBodyHairWidthV9,
                              height: GameConfig.playerFullBodyHairHeightV9)
        let hair = SKShapeNode(rectOf: hairSize, cornerRadius: 5)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: 0, y: 21)
        hair.zPosition = 11
        container.addChild(hair)

        // 간호사 캡 (머리 위 작은 사각형) — V9 10×4, y=25
        let capSize = CGSize(width: GameConfig.playerFullBodyCapWidthV9,
                             height: GameConfig.playerFullBodyCapHeightV9)
        let cap = SKShapeNode(rectOf: capSize, cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 0, y: 25)
        cap.zPosition = 12
        container.addChild(cap)

        // 눈 2개 (정면) — V9 y=17
        for sign in [-1, 1] {
            let eye = SKShapeNode(circleOfRadius: 1.4)
            eye.fillColor = .ganhoNavyDeep
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(sign) * 4, y: 17)
            eye.zPosition = 12
            container.addChild(eye)
        }
    }

    /// 뒷모습 — 머리카락이 머리 전체 덮음, 눈 없음. 몸통/팔/다리는 front와 동일.
    private func buildBackBody(in container: SKNode, palette: Palette) {
        // 몸통 — V9 40×32, y=-12
        let bodySize = CGSize(width: GameConfig.playerFullBodyBodyWidthV9,
                              height: GameConfig.playerFullBodyBodyHeightV9)
        let body = SKShapeNode(rectOf: bodySize, cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 0, y: -12)
        container.addChild(body)

        // 다리·팔 — V9 좌표
        attachLegs(in: container, palette: palette, offsetY: -34)
        attachArm(in: container, palette: palette, x: -22, prefix: "armL")
        attachArm(in: container, palette: palette, x:  22, prefix: "armR")

        // 머리 (뒷통수 — skinTone 보이지 않고 hair가 거의 다 덮음) — V9 r12, y=14
        let head = SKShapeNode(circleOfRadius: GameConfig.playerFullBodyHeadRadiusV9)
        head.fillColor = palette.hair
        head.strokeColor = palette.hair
        head.lineWidth = 0
        head.position = CGPoint(x: 0, y: 14)
        head.zPosition = 10
        container.addChild(head)

        // 캡 (뒷면) — V9 10×4, y=25
        let capSize = CGSize(width: GameConfig.playerFullBodyCapWidthV9,
                             height: GameConfig.playerFullBodyCapHeightV9)
        let cap = SKShapeNode(rectOf: capSize, cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 0, y: 25)
        cap.zPosition = 12
        container.addChild(cap)
    }

    /// 좌측 ¾ 측면 — 본체 약간 좌로 시각적 이동 + 머리 좌측 살짝 회전 hint.
    /// *mirroring 금지* — 별도 path. 1차는 살짝 좌로 치우친 정면 변형.
    /// Sprint 9 Phase B — V9 비율 축소(50×44 → 36×32, head x=±4 → ±2.5).
    private func buildLeftBody(in container: SKNode, palette: Palette) {
        // 몸통 — 좌측에 살짝 치우침 — V9 36×32 (정면 40×32 대비 살짝 좁힘)
        let body = SKShapeNode(rectOf: CGSize(width: 36, height: GameConfig.playerFullBodyBodyHeightV9), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: -1.5, y: -12)
        container.addChild(body)

        // 다리·팔
        attachLegs(in: container, palette: palette, offsetY: -34)
        // 좌측 측면 — 왼팔 앞(z 높음), 오른팔 뒤(z 낮음)
        attachArm(in: container, palette: palette, x: -15, prefix: "armL", zOverride: 14)
        attachArm(in: container, palette: palette, x:  12, prefix: "armR", zOverride: 1)

        // 머리 (좌로 살짝 치우침) — V9 r12, x=-2.5, y=14
        let head = SKShapeNode(circleOfRadius: GameConfig.playerFullBodyHeadRadiusV9)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: -2.5, y: 14)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락 — V9 21×8 cornerRadius 4
        let hair = SKShapeNode(rectOf: CGSize(width: 21, height: 8), cornerRadius: 4)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: -4, y: 20)
        hair.zPosition = 11
        container.addChild(hair)

        // 캡 — V9 9×4
        let cap = SKShapeNode(rectOf: CGSize(width: 9, height: GameConfig.playerFullBodyCapHeightV9), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: -2.5, y: 25)
        cap.zPosition = 12
        container.addChild(cap)

        // 옆 얼굴 — 눈 1개만 (왼쪽) — V9 y=17
        let eye = SKShapeNode(circleOfRadius: 1.4)
        eye.fillColor = .ganhoNavyDeep
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -6, y: 17)
        eye.zPosition = 12
        container.addChild(eye)
    }

    /// 우측 ¾ 측면 — *mirroring 금지*, 별도 path. left와 좌표 부호 반전한 *별도 path*.
    /// Sprint 9 Phase B — V9 비율 축소.
    private func buildRightBody(in container: SKNode, palette: Palette) {
        // 몸통 — 우측에 살짝 치우침 — V9 36×32
        let body = SKShapeNode(rectOf: CGSize(width: 36, height: GameConfig.playerFullBodyBodyHeightV9), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 1.5, y: -12)
        container.addChild(body)

        // 다리·팔 — 좌우 반전 별도 좌표
        attachLegs(in: container, palette: palette, offsetY: -34)
        attachArm(in: container, palette: palette, x:  15, prefix: "armR", zOverride: 14)
        attachArm(in: container, palette: palette, x: -12, prefix: "armL", zOverride: 1)

        // 머리 (우로 살짝 치우침) — V9 r12, x=2.5, y=14
        let head = SKShapeNode(circleOfRadius: GameConfig.playerFullBodyHeadRadiusV9)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: 2.5, y: 14)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락 — V9 21×8
        let hair = SKShapeNode(rectOf: CGSize(width: 21, height: 8), cornerRadius: 4)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: 4, y: 20)
        hair.zPosition = 11
        container.addChild(hair)

        // 캡 — V9 9×4
        let cap = SKShapeNode(rectOf: CGSize(width: 9, height: GameConfig.playerFullBodyCapHeightV9), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 2.5, y: 25)
        cap.zPosition = 12
        container.addChild(cap)

        // 옆 얼굴 — 눈 1개만 (오른쪽) — V9 y=17
        let eye = SKShapeNode(circleOfRadius: 1.4)
        eye.fillColor = .ganhoNavyDeep
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 6, y: 17)
        eye.zPosition = 12
        container.addChild(eye)
    }

    // MARK: - Identity Marker (Sprint 9 Phase B)

    /// 캐릭터별 정체성 자식 부착. 5종 × 4방향 = 20셀 모두 *방향 인자*만 받아 분기.
    /// switch exhaustive — default 없음(5 case 모두 명시).
    /// zPos 13: cap(12), eye(12), hair(11), head(10) 위 적층.
    /// 측면에서는 좌표 부호 반전 또는 한쪽만 표시 — 한 분기당 1~2 자식.
    private func attachIdentityMarker(in container: SKNode, direction: Direction) {
        switch id {
        case .kim:  attachKimCrossMark(in: container)
        case .jung: attachJungGlasses(in: container, direction: direction)
        case .geon: attachGeonBaseballCap(in: container)
        case .im:   attachImSidetail(in: container, direction: direction)
        case .lee:  attachLeePigtails(in: container)
        }
    }

    /// .kim — 빨강 십자 (캡 위, 2조각). vertical 2×3 + horizontal 5×2, fill ganhoCoralPrimary.
    /// 4방향 동일 (캡 중앙 위라 측면에서도 같은 위치에서 보임).
    private func attachKimCrossMark(in container: SKNode) {
        // 수직 막대
        let vertical = SKShapeNode(rectOf: CGSize(width: 2, height: 3), cornerRadius: 0.4)
        vertical.fillColor = .ganhoCoralPrimary
        vertical.strokeColor = .clear
        vertical.position = CGPoint(x: 0, y: 26)
        vertical.zPosition = 13
        vertical.name = "kimCrossV"
        container.addChild(vertical)

        // 수평 막대
        let horizontal = SKShapeNode(rectOf: CGSize(width: 5, height: 2), cornerRadius: 0.4)
        horizontal.fillColor = .ganhoCoralPrimary
        horizontal.strokeColor = .clear
        horizontal.position = CGPoint(x: 0, y: 26)
        horizontal.zPosition = 13
        horizontal.name = "kimCrossH"
        container.addChild(horizontal)
    }

    /// .jung — 둥근 안경 2개 + bridge. 정/후면은 양쪽 렌즈, 측면은 한쪽 렌즈만.
    /// ellipse 6×4 × 2, stroke ganhoNavyDeep w=0.7, fill clear.
    /// position (±4, 17) 정면, (-6, 17) 좌측, (6, 17) 우측.
    /// .back은 머리 뒤라 안경 안 보임 — case .back은 noop (자식 0).
    private func attachJungGlasses(in container: SKNode, direction: Direction) {
        switch direction {
        case .front:
            for sign in [-1, 1] {
                let lens = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
                lens.fillColor = .clear
                lens.strokeColor = .ganhoNavyDeep
                lens.lineWidth = 0.7
                lens.position = CGPoint(x: CGFloat(sign) * 4, y: 17)
                lens.zPosition = 13
                lens.name = "jungLens"
                container.addChild(lens)
            }
            // bridge — 2×0.7 line between lenses
            let bridge = SKShapeNode(rectOf: CGSize(width: 2, height: 0.7), cornerRadius: 0.3)
            bridge.fillColor = .ganhoNavyDeep
            bridge.strokeColor = .clear
            bridge.position = CGPoint(x: 0, y: 17)
            bridge.zPosition = 13
            bridge.name = "jungBridge"
            container.addChild(bridge)
        case .back:
            // 뒷모습 — 안경 미표시
            break
        case .left:
            let lens = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
            lens.fillColor = .clear
            lens.strokeColor = .ganhoNavyDeep
            lens.lineWidth = 0.7
            lens.position = CGPoint(x: -6, y: 17)
            lens.zPosition = 13
            lens.name = "jungLens"
            container.addChild(lens)
        case .right:
            let lens = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
            lens.fillColor = .clear
            lens.strokeColor = .ganhoNavyDeep
            lens.lineWidth = 0.7
            lens.position = CGPoint(x: 6, y: 17)
            lens.zPosition = 13
            lens.name = "jungLens"
            container.addChild(lens)
        }
    }

    /// .geon — 코랄 야구캡 (캡 위 덮기). rect 22×7 cornerRadius 7, fill ganhoCoralPrimary.
    /// cap을 *대체하지 않고* 그 위에 부착(zPos 13). 4방향 동일 위치.
    private func attachGeonBaseballCap(in container: SKNode) {
        let cap = SKShapeNode(rectOf: CGSize(width: 22, height: 7), cornerRadius: 7)
        cap.fillColor = .ganhoCoralPrimary
        cap.strokeColor = .ganhoNavyDeep
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 0, y: 26)
        cap.zPosition = 13
        cap.name = "geonBaseballCap"
        container.addChild(cap)
    }

    /// .im — 사이드테일 (오른쪽으로 흐르는 묶음). rect 4×10 cornerRadius 2, hair color.
    /// 정/후면 = 우측, 좌측면 = 좌측, 우측면 = 우측 (모두 +방향이 자연스러우나 측면은 시각 부호 일치).
    private func attachImSidetail(in container: SKNode, direction: Direction) {
        let xPosition: CGFloat
        switch direction {
        case .front, .back, .right: xPosition = 8
        case .left:                 xPosition = -8
        }
        let tail = SKShapeNode(rectOf: CGSize(width: 4, height: 10), cornerRadius: 2)
        tail.fillColor = .ganhoNavyDeep
        tail.strokeColor = .clear
        tail.position = CGPoint(x: xPosition, y: 20)
        tail.zPosition = 13
        tail.name = "imSidetail"
        container.addChild(tail)
    }

    /// .lee — 양 옆 묶음 머리 (양쪽 작은 핀). rect 4×6 cornerRadius 2 ×2, position (±10, 21).
    /// 4방향 동일 — 양쪽 묶음은 모든 각도에서 보임 (살짝 hair 끝과 겹침은 정상).
    private func attachLeePigtails(in container: SKNode) {
        for sign in [-1, 1] {
            let pigtail = SKShapeNode(rectOf: CGSize(width: 4, height: 6), cornerRadius: 2)
            pigtail.fillColor = .ganhoNavyDeep
            pigtail.strokeColor = .clear
            pigtail.position = CGPoint(x: CGFloat(sign) * 10, y: 21)
            pigtail.zPosition = 13
            pigtail.name = "leePigtail"
            container.addChild(pigtail)
        }
    }

    // MARK: - Helpers

    /// 다리 2개 (좌/우). 몸통 아래 부착. GameConfig.playerLegWidthV4 폭.
    /// Sprint 9 Phase B — height V4(24) → V9(18). name = "leg" — 추후 보강에서 walk cycle scaleY 토글에 사용.
    private func attachLegs(in container: SKNode, palette: Palette, offsetY: CGFloat) {
        let legSize = CGSize(width: GameConfig.playerLegWidthV4,
                             height: GameConfig.playerFullBodyLegHeightV9)
        for sign in [-1, 1] {
            let leg = SKShapeNode(rectOf: legSize, cornerRadius: 2)
            leg.fillColor = palette.body
            leg.strokeColor = palette.hair
            leg.lineWidth = 0.5
            leg.position = CGPoint(x: CGFloat(sign) * 7, y: offsetY)
            leg.zPosition = -1
            leg.name = "leg"
            container.addChild(leg)
        }
    }

    /// 팔 1개. zOverride로 측면 시 앞/뒤 적층 조정.
    /// GameConfig.playerArmWidthV4 폭 — 풀바디 일관 톤.
    /// Sprint 9 Phase B — height V4(28) → V9(20).
    private func attachArm(in container: SKNode,
                            palette: Palette,
                            x: CGFloat,
                            prefix: String,
                            zOverride: CGFloat = 1) {
        let armSize = CGSize(width: GameConfig.playerArmWidthV4,
                             height: GameConfig.playerFullBodyArmHeightV9)
        let arm = SKShapeNode(rectOf: armSize, cornerRadius: 2)
        arm.fillColor = palette.body
        arm.strokeColor = palette.hair
        arm.lineWidth = 0.5
        arm.position = CGPoint(x: x, y: -12)
        arm.zPosition = zOverride
        arm.name = prefix
        container.addChild(arm)
    }

    // MARK: - Animation
    /// 정지 호흡 cycle — 몸통 scaleY 1.0 ↔ 1.02 반복.
    /// CharacterFullBodyNode 자체에 적용 — 모든 자식 container 일괄 호흡.
    /// 무한 반복 — [weak] 캡처 불요(self가 action 소유자).
    private func startIdleBreath() {
        let halfDuration = GameConfig.playerIdleBreathDurationV4 / 2
        let breatheOut = SKAction.scaleY(to: 1.02, duration: halfDuration)
        let breatheIn = SKAction.scaleY(to: 1.0, duration: halfDuration)
        let cycle = SKAction.sequence([breatheOut, breatheIn])
        run(.repeatForever(cycle))
    }
}
