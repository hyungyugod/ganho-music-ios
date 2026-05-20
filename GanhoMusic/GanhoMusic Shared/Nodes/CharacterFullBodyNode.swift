//
//  CharacterFullBodyNode.swift
//  GanhoMusic Shared
//
//  Sprint 8 Phase G · 인게임 풀바디 캐릭터 시각 (5명 × 4방향 = 20셀)
//
//  CharacterFaceNode(얼굴 전용, 선택 화면)와 분리된 *풀바디 시각* 노드.
//  PlayerNode가 apply(_:) 시점에 자식으로 부착 — D-Pad 입력 시 팔다리 보이는 캐릭터 정체성.
//
//  1차 구현 정책(SPEC §"간단화 옵션"):
//   - 풀바디 path는 김간호 패턴 공유(어깨/몸통/머리/팔×2/다리×2 SKShape) + 캐릭터별 *색만 다름*.
//   - left/right 별도 container — *mirroring 금지*(SPRINT_8_REQUEST §14 의사결정 #7).
//     1차는 path 공유, 추후 보강 sprint에서 청진기 위치/머리 기울기 등 차별화.
//   - 시각 합격선: "팔다리 식별 가능" + "5캐릭터 빌드 통과" 충족.
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
    /// 추후 보강 sprint에서 left/right 별도 path(청진기 위치/팔 앞뒤) 작성 예정.
    private func buildBody(in container: SKNode, direction: Direction) {
        let palette = colorPalette(for: id)
        switch direction {
        case .front: buildFrontBody(in: container, palette: palette)
        case .back:  buildBackBody(in: container, palette: palette)
        case .left:  buildLeftBody(in: container, palette: palette)
        case .right: buildRightBody(in: container, palette: palette)
        }
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
    private func buildFrontBody(in container: SKNode, palette: Palette) {
        // 어깨/몸통 (가장 뒤)
        let body = SKShapeNode(rectOf: CGSize(width: 56, height: 44), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 0, y: -16)
        body.zPosition = 0
        container.addChild(body)

        // 다리 2개 (몸통 아래)
        attachLegs(in: container, palette: palette, offsetY: -48)

        // 팔 2개 (몸통 옆)
        attachArm(in: container, palette: palette, x: -32, prefix: "armL")
        attachArm(in: container, palette: palette, x:  32, prefix: "armR")

        // 머리 (가장 위)
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: 0, y: 20)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락 (머리 위 반원 hint)
        let hair = SKShapeNode(rectOf: CGSize(width: 32, height: 10), cornerRadius: 5)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: 0, y: 30)
        hair.zPosition = 11
        container.addChild(hair)

        // 간호사 캡 (머리 위 작은 사각형, 빨간 십자)
        let cap = SKShapeNode(rectOf: CGSize(width: 14, height: 6), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 0, y: 36)
        cap.zPosition = 12
        container.addChild(cap)

        // 눈 2개 (정면)
        for sign in [-1, 1] {
            let eye = SKShapeNode(circleOfRadius: 1.6)
            eye.fillColor = .ganhoNavyDeep
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(sign) * 5, y: 22)
            eye.zPosition = 12
            container.addChild(eye)
        }
    }

    /// 뒷모습 — 머리카락이 머리 전체 덮음, 눈 없음. 몸통/팔/다리는 front와 동일.
    private func buildBackBody(in container: SKNode, palette: Palette) {
        // 몸통
        let body = SKShapeNode(rectOf: CGSize(width: 56, height: 44), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 0, y: -16)
        container.addChild(body)

        // 다리·팔
        attachLegs(in: container, palette: palette, offsetY: -48)
        attachArm(in: container, palette: palette, x: -32, prefix: "armL")
        attachArm(in: container, palette: palette, x:  32, prefix: "armR")

        // 머리 (뒷통수 — skinTone 보이지 않고 hair가 거의 다 덮음)
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = palette.hair
        head.strokeColor = palette.hair
        head.lineWidth = 0
        head.position = CGPoint(x: 0, y: 20)
        head.zPosition = 10
        container.addChild(head)

        // 캡 (뒷면)
        let cap = SKShapeNode(rectOf: CGSize(width: 14, height: 6), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 0, y: 36)
        cap.zPosition = 12
        container.addChild(cap)
    }

    /// 좌측 ¾ 측면 — 본체 약간 좌로 시각적 이동 + 머리 좌측 살짝 회전 hint.
    /// *mirroring 금지* — 별도 path. 1차는 살짝 좌로 치우친 정면 변형.
    private func buildLeftBody(in container: SKNode, palette: Palette) {
        // 몸통 — 좌측에 살짝 치우침
        let body = SKShapeNode(rectOf: CGSize(width: 50, height: 44), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: -2, y: -16)
        container.addChild(body)

        // 다리·팔
        attachLegs(in: container, palette: palette, offsetY: -48)
        // 좌측 측면 — 왼팔 앞(z 높음), 오른팔 뒤(z 낮음)
        attachArm(in: container, palette: palette, x: -22, prefix: "armL", zOverride: 14)
        attachArm(in: container, palette: palette, x:  18, prefix: "armR", zOverride: 1)

        // 머리 (좌로 살짝 치우침)
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: -4, y: 20)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락
        let hair = SKShapeNode(rectOf: CGSize(width: 30, height: 12), cornerRadius: 6)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: -6, y: 28)
        hair.zPosition = 11
        container.addChild(hair)

        // 캡
        let cap = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: -4, y: 36)
        cap.zPosition = 12
        container.addChild(cap)

        // 옆 얼굴 — 눈 1개만 (왼쪽)
        let eye = SKShapeNode(circleOfRadius: 1.6)
        eye.fillColor = .ganhoNavyDeep
        eye.strokeColor = .clear
        eye.position = CGPoint(x: -9, y: 22)
        eye.zPosition = 12
        container.addChild(eye)
    }

    /// 우측 ¾ 측면 — *mirroring 금지*, 별도 path. left와 좌표 부호 반전한 *별도 path*.
    private func buildRightBody(in container: SKNode, palette: Palette) {
        // 몸통 — 우측에 살짝 치우침
        let body = SKShapeNode(rectOf: CGSize(width: 50, height: 44), cornerRadius: 8)
        body.fillColor = palette.body
        body.strokeColor = palette.hair
        body.lineWidth = 0.8
        body.position = CGPoint(x: 2, y: -16)
        container.addChild(body)

        // 다리·팔 — 좌우 반전 별도 좌표
        attachLegs(in: container, palette: palette, offsetY: -48)
        attachArm(in: container, palette: palette, x:  22, prefix: "armR", zOverride: 14)
        attachArm(in: container, palette: palette, x: -18, prefix: "armL", zOverride: 1)

        // 머리 (우로 살짝 치우침)
        let head = SKShapeNode(circleOfRadius: 18)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = palette.hair
        head.lineWidth = 1.0
        head.position = CGPoint(x: 4, y: 20)
        head.zPosition = 10
        container.addChild(head)

        // 머리카락
        let hair = SKShapeNode(rectOf: CGSize(width: 30, height: 12), cornerRadius: 6)
        hair.fillColor = palette.hair
        hair.strokeColor = .clear
        hair.position = CGPoint(x: 6, y: 28)
        hair.zPosition = 11
        container.addChild(hair)

        // 캡
        let cap = SKShapeNode(rectOf: CGSize(width: 12, height: 6), cornerRadius: 1)
        cap.fillColor = palette.cap
        cap.strokeColor = palette.hair
        cap.lineWidth = 0.5
        cap.position = CGPoint(x: 4, y: 36)
        cap.zPosition = 12
        container.addChild(cap)

        // 옆 얼굴 — 눈 1개만 (오른쪽)
        let eye = SKShapeNode(circleOfRadius: 1.6)
        eye.fillColor = .ganhoNavyDeep
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 9, y: 22)
        eye.zPosition = 12
        container.addChild(eye)
    }

    // MARK: - Helpers

    /// 다리 2개 (좌/우). 몸통 아래 부착. GameConfig.playerLegWidthV4 폭.
    /// name = "leg" — 추후 보강에서 walk cycle scaleY 토글에 사용.
    private func attachLegs(in container: SKNode, palette: Palette, offsetY: CGFloat) {
        let legSize = CGSize(width: GameConfig.playerLegWidthV4, height: 24)
        for sign in [-1, 1] {
            let leg = SKShapeNode(rectOf: legSize, cornerRadius: 2)
            leg.fillColor = palette.body
            leg.strokeColor = palette.hair
            leg.lineWidth = 0.5
            leg.position = CGPoint(x: CGFloat(sign) * 10, y: offsetY)
            leg.zPosition = -1
            leg.name = "leg"
            container.addChild(leg)
        }
    }

    /// 팔 1개. zOverride로 측면 시 앞/뒤 적층 조정.
    /// GameConfig.playerArmWidthV4 폭 — 풀바디 일관 톤.
    private func attachArm(in container: SKNode,
                            palette: Palette,
                            x: CGFloat,
                            prefix: String,
                            zOverride: CGFloat = 1) {
        let armSize = CGSize(width: GameConfig.playerArmWidthV4, height: 28)
        let arm = SKShapeNode(rectOf: armSize, cornerRadius: 2)
        arm.fillColor = palette.body
        arm.strokeColor = palette.hair
        arm.lineWidth = 0.5
        arm.position = CGPoint(x: x, y: -16)
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
