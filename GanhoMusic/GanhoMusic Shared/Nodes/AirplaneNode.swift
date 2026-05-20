//
//  AirplaneNode.swift
//  GanhoMusic Shared
//
//  Phase 4-3 · AIRFORCE 이스터에그 비행기 — 좌→우 가로지르기 + 자가 소멸
//  Sprint 8 Phase G · 비행기 형상 6 자식(fuselage/wings/tail/cockpit/propeller/contrail) — 노란 사각형 → 비행기.
//

import SpriteKit

/// AIRFORCE 이스터에그 비행기. PhysicsBody 부착 0 — 순수 시각.
/// init에서 색·크기·zPosition만 부여하고, scene.size 의존인 SKAction은
/// 외부 호출자가 crossScreen(sceneWidth:atY:)을 부르는 시점에 시작한다.
/// SKAction.sequence([move, removeFromParent])로 자가 소멸(fire-and-forget).
/// Sprint 8 Phase G — 본체 color .clear + 6 자식 SKShape로 *비행기 형상* 구성.
final class AirplaneNode: SKSpriteNode, SelfDismissingNode {

    // MARK: - Init
    init() {
        let size = CGSize(
            width:  GameConfig.airplaneWidth,
            height: GameConfig.airplaneHeight
        )
        // Sprint 8 Phase G — 본체는 *시각 컨테이너*로만 동작. 색은 6 자식이 담당.
        // crossScreen 시그니처(sceneWidth:atY:) byte-identical 보존.
        super.init(texture: nil, color: .clear, size: size)
        name = "airplane"
        // HUD(100) 아래, 일반 노드(5) 위. 점수 라벨을 가리지 않으며 공중에 떠 있는 느낌.
        zPosition = 50

        // Sprint 8 Phase G — 6 자식 부착. 순서가 곧 z 누적 순서(작게 보이는 것부터).
        attachContrail()    // 본체 뒤 흰 트레일 (가장 뒤)
        attachFuselage()    // 노란 동체 (중심)
        attachWings()       // 날개 2장
        attachTail()        // 꼬리
        attachCockpit()     // 조종석 (반투명 네이비)
        attachPropeller()   // 회전 프로펠러 (가장 앞)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cross
    /// 부모(cameraNode)에 addChild 직후 호출. 화면 좌측 바깥에서 시작 → 우측 바깥까지 이동 → 자가 제거.
    /// cameraNode 자식 좌표계: (0,0) = 화면 중앙. 시작/끝 모두 화면 바깥(노드 폭만큼 여유).
    /// - Parameters:
    ///   - sceneWidth: 씬 가로 크기(scene.size.width). 좌우 바깥 좌표 계산용.
    ///   - y: cameraNode 좌표계 y (화면 중앙 기준). 화면 상단 가까이 = 양수.
    func crossScreen(sceneWidth: CGFloat, atY y: CGFloat) {
        let startX = -(sceneWidth / 2 + size.width)
        let endX   = +(sceneWidth / 2 + size.width)
        position = CGPoint(x: startX, y: y)
        let move    = SKAction.move(to: CGPoint(x: endX, y: y),
                                    duration: GameConfig.airplaneCrossDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([move, cleanup]))
    }

    // MARK: - Attach (Sprint 8 Phase G · 시각 자식 6개)

    /// 동체(fuselage) — 본체 노란색 가로 직사각형. 비행기의 *몸통* 역할.
    /// corner radius로 살짝 둥글려 *유선형 항공기* 톤. zPos 0.1 → 본체(50) 위.
    private func attachFuselage() {
        let fuselageSize = CGSize(
            width:  size.width * 0.85,
            height: size.height * 0.45
        )
        let fuselage = SKShapeNode(rectOf: fuselageSize, cornerRadius: 4)
        fuselage.fillColor = .ganhoYellowF
        fuselage.strokeColor = .clear
        fuselage.zPosition = 0.1
        addChild(fuselage)
    }

    /// 날개(wings) — 위·아래 2장. 사다리꼴(BezierPath) — 가운데 넓고 끝이 좁은 *항공 날개* 톤.
    /// 노란색 ×0.92 톤다운 → 동체와 *경계 인식*. zPos 0.15 → 동체 위.
    private func attachWings() {
        let wingColor = UIColor.ganhoYellowF.withAlphaComponent(0.92)
        let halfWidth = size.width * 0.25
        let halfHeight = size.height * 0.6

        // 위 날개
        let topPath = UIBezierPath()
        topPath.move(to:    CGPoint(x: -halfWidth, y: 0))
        topPath.addLine(to: CGPoint(x:  halfWidth, y: 0))
        topPath.addLine(to: CGPoint(x:  halfWidth * 0.5, y:  halfHeight))
        topPath.addLine(to: CGPoint(x: -halfWidth * 0.5, y:  halfHeight))
        topPath.close()
        let topWing = SKShapeNode(path: topPath.cgPath)
        topWing.fillColor = wingColor
        topWing.strokeColor = .clear
        topWing.position = CGPoint(x: -size.width * 0.05, y: 0)
        topWing.zPosition = 0.15
        addChild(topWing)

        // 아래 날개
        let bottomPath = UIBezierPath()
        bottomPath.move(to:    CGPoint(x: -halfWidth, y: 0))
        bottomPath.addLine(to: CGPoint(x:  halfWidth, y: 0))
        bottomPath.addLine(to: CGPoint(x:  halfWidth * 0.5, y: -halfHeight))
        bottomPath.addLine(to: CGPoint(x: -halfWidth * 0.5, y: -halfHeight))
        bottomPath.close()
        let bottomWing = SKShapeNode(path: bottomPath.cgPath)
        bottomWing.fillColor = wingColor
        bottomWing.strokeColor = .clear
        bottomWing.position = CGPoint(x: -size.width * 0.05, y: 0)
        bottomWing.zPosition = 0.15
        addChild(bottomWing)
    }

    /// 꼬리(tail) — 뒤쪽 끝 작은 수직 사각형. *항공기 꼬리 날개* 정체성.
    /// 동체와 같은 노란색. zPos 0.12 → 동체 바로 위, 날개 아래.
    private func attachTail() {
        let tailSize = CGSize(
            width:  size.width * 0.12,
            height: size.height * 0.85
        )
        let tail = SKShapeNode(rectOf: tailSize, cornerRadius: 1.5)
        tail.fillColor = .ganhoYellowF
        tail.strokeColor = .clear
        tail.position = CGPoint(x: -size.width * 0.40, y: size.height * 0.15)
        tail.zPosition = 0.12
        addChild(tail)
    }

    /// 조종석(cockpit) — 동체 앞쪽 위에 타원 반투명 네이비.
    /// 알파 0.6 → *유리창* 느낌. zPos 0.2 → 동체·날개 위.
    private func attachCockpit() {
        let cockpitSize = CGSize(
            width:  size.width * 0.22,
            height: size.height * 0.55
        )
        let cockpit = SKShapeNode(ellipseOf: cockpitSize)
        cockpit.fillColor = UIColor.ganhoNavyDeep.withAlphaComponent(GameConfig.airplaneCockpitColorAlphaV4)
        cockpit.strokeColor = .clear
        cockpit.position = CGPoint(x: size.width * 0.20, y: size.height * 0.05)
        cockpit.zPosition = 0.2
        addChild(cockpit)
    }

    /// 프로펠러(propeller) — 가장 앞 회전 작은 회색 원 + 십자 선.
    /// SKAction.rotate × repeatForever로 무한 회전. zPos 0.3 → 가장 위.
    private func attachPropeller() {
        let hub = SKShapeNode(circleOfRadius: size.height * 0.18)
        hub.fillColor = .ganhoNavyMuted
        hub.strokeColor = .ganhoNavyDeep
        hub.lineWidth = 0.5
        hub.position = CGPoint(x: size.width * 0.42, y: 0)
        hub.zPosition = 0.3
        addChild(hub)

        // 회전하는 십자 블레이드 (hub 자식)
        let bladeContainer = SKNode()
        bladeContainer.zPosition = 0.01
        hub.addChild(bladeContainer)

        let bladeSize = CGSize(width: 1.5, height: size.height * 0.55)
        let bladeV = SKShapeNode(rectOf: bladeSize)
        bladeV.fillColor = .ganhoNavyDeep
        bladeV.strokeColor = .clear
        bladeContainer.addChild(bladeV)

        let bladeH = SKShapeNode(rectOf: CGSize(width: bladeSize.height, height: bladeSize.width))
        bladeH.fillColor = .ganhoNavyDeep
        bladeH.strokeColor = .clear
        bladeContainer.addChild(bladeH)

        // 무한 회전. [weak] 캡처 불요 — bladeContainer는 hub의 자식이라 self 강참조 없음.
        let rotate = SKAction.rotate(byAngle: .pi * 2,
                                     duration: GameConfig.airplanePropellerRotateDurationV4)
        bladeContainer.run(.repeatForever(rotate))
    }

    /// 트레일(contrail) — 본체 뒤쪽 흰 작은 원 4개로 *비행운* 표현.
    /// 알파 0.6 → 살짝 보이는 톤. zPos -0.1 → 동체 뒤로 배치.
    private func attachContrail() {
        let radius = size.height * 0.14
        for index in 0..<4 {
            let puff = SKShapeNode(circleOfRadius: radius)
            puff.fillColor = UIColor.white.withAlphaComponent(0.55 - CGFloat(index) * 0.08)
            puff.strokeColor = .clear
            let x = -size.width * 0.55 - CGFloat(index) * (radius * 1.8)
            puff.position = CGPoint(x: x, y: 0)
            puff.zPosition = -0.1
            addChild(puff)
        }
    }
}
