//
//  SergeantParkNode.swift
//  GanhoMusic Shared
//
//  Sprint 7 Phase F · 박병장 — 공군 청록 군복 + 항공 캡 + 검정 선글라스 + 골드 v자 계급장.
//  본 sprint는 *시각 시안만* 준비. **GameScene 등장 0건** — 실제 spawn은 Sprint 8 후보.
//  physicsBody / SKAction / update / AI **0줄** — SKSpriteNode(.clear) + 자식 SKShapeNode 6종.
//
//  부모 클래스 결정 근거(OQ-1): SPEC.md §OPEN_QUESTION-1 — EnemyNode/StoneGuardNode/ProfessorNode 3종이
//  모두 SKSpriteNode 상속이라 패턴 일관성 우선. SPRINT_7_REQUEST.md §7.2 "SKShapeNode" 명시는 *추후 변경 가능*.
//

import SpriteKit

/// 박병장 NPC 시각 시안. **GameScene에서 spawn하지 않는다** — Sprint 8 후보.
/// 6개 자식 SKShapeNode 부착으로 *공군 병장 + 선글라스* 정체성 시각화.
/// 모든 좌표/크기는 SKSpriteNode 중심(0,0) 기준, GameConfig V3 상수만 사용 — 매직 넘버 0.
final class SergeantParkNode: SKSpriteNode {

    // MARK: - Init
    init() {
        // 시각 크기: pixelSpriteScale(2배) — 32×40pt 화면 픽셀.
        // 기존 빌런 3종(EnemyNode/StoneGuardNode/ProfessorNode) 패턴 동형.
        let visualSize = CGSize(
            width:  GameConfig.sergeantParkWidth  * GameConfig.pixelSpriteScale,
            height: GameConfig.sergeantParkHeight * GameConfig.pixelSpriteScale
        )
        // texture: nil + color: .clear — SKShapeNode 자식만 보이는 *시각 컨테이너*.
        super.init(texture: nil, color: .clear, size: visualSize)
        name = "sergeantPark"
        // 다른 빌런(zPos 5)과 동급 — 음표/벽(0) 위, HUD(100) 아래.
        zPosition = 5

        // 6 자식 노드 부착 — *순서가 곧 z 누적 순서*. 외부에서 호출할 필요 없음.
        attachShadow()
        attachBody()
        attachHead()
        attachCap()
        attachSunglasses()
        attachRank()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Attach (시각만, 6 메서드)

    /// 발 밑 ellipse 그림자 — alpha 0.18. zPos -0.1 → 부모(5) 뒤로 배치.
    /// 다른 빌런과 동일한 *부유감 안정* 톤.
    private func attachShadow() {
        let shadow = SKShapeNode(ellipseOf: GameConfig.sergeantShadowSize)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: GameConfig.sergeantShadowOffsetY)
        shadow.zPosition = -0.1
        addChild(shadow)
    }

    /// 공군 청록 군복 몸통 — corner radius 1.5pt로 살짝 둥근 사각형.
    /// stroke는 light tone — 군복 텍스처의 *광원 표현*.
    private func attachBody() {
        let body = SKShapeNode(rectOf: GameConfig.sergeantBodySize, cornerRadius: 1.5)
        body.fillColor = .ganhoAirforceTeal
        body.strokeColor = .ganhoAirforceTealLight
        body.lineWidth = 0.6
        body.position = CGPoint(x: 0, y: GameConfig.sergeantBodyOffsetY)
        body.zPosition = 0.1
        addChild(body)
    }

    /// 살구색 얼굴 — circleOfRadius 6pt. coralShadow stroke로 얼굴 윤곽.
    /// ganhoSkinTone(#FFE2C6 살구색)은 ColorTokens에 이미 존재(line 256) — 재사용.
    private func attachHead() {
        let head = SKShapeNode(circleOfRadius: GameConfig.sergeantHeadRadius)
        head.fillColor = .ganhoSkinTone
        head.strokeColor = .ganhoCoralShadow
        head.lineWidth = 0.4
        head.position = CGPoint(x: 0, y: GameConfig.sergeantHeadOffsetY)
        head.zPosition = 0.2
        addChild(head)
    }

    /// 항공 캡(앞창 있는 모자) — 크라운(둥근 윗부분) + 차양(검정 앞창) 2층 구조.
    /// 크라운은 공군 청록, 차양은 sunglassesBlack — *조종사 캡* 정체성.
    private func attachCap() {
        let crown = SKShapeNode(rectOf: GameConfig.sergeantCapCrownSize, cornerRadius: 1.5)
        crown.fillColor = .ganhoAirforceTeal
        crown.strokeColor = .ganhoAirforceTealLight
        crown.lineWidth = 0.5
        crown.position = CGPoint(x: 0, y: GameConfig.sergeantCapCrownOffsetY)
        crown.zPosition = 0.3
        addChild(crown)

        let visor = SKShapeNode(rectOf: GameConfig.sergeantCapVisorSize)
        visor.fillColor = .ganhoSunglassesBlack
        visor.strokeColor = .clear
        visor.position = CGPoint(x: 0, y: GameConfig.sergeantCapVisorOffsetY)
        visor.zPosition = 0.35
        addChild(visor)
    }

    /// 검정 선글라스 — 가로로 긴 직사각형. navyDeep stroke로 *프레임 두께* 표현.
    /// 얼굴(zPos 0.2) 위에 부착(zPos 0.4) — 눈 영역 전체 덮음 = *박병장 정체성 핵심*.
    private func attachSunglasses() {
        let glasses = SKShapeNode(
            rectOf: GameConfig.sergeantSunglassesSize,
            cornerRadius: 0.6
        )
        glasses.fillColor = .ganhoSunglassesBlack
        glasses.strokeColor = .ganhoNavyDeep
        glasses.lineWidth = 0.4
        glasses.position = CGPoint(x: 0, y: GameConfig.sergeantSunglassesOffsetY)
        glasses.zPosition = 0.4
        addChild(glasses)
    }

    /// 우측 어깨 v자 계급장 2개 — 골드 stroke chevron. 병장(2 chevron) 의미.
    /// for-loop로 chevron 개수만큼 부착 → GameConfig.sergeantRankChevronCount 변경 시 자동 반영.
    private func attachRank() {
        for index in 0..<GameConfig.sergeantRankChevronCount {
            let chevron = makeChevronNode()
            chevron.position = CGPoint(
                x: GameConfig.sergeantRankOffsetX,
                y: GameConfig.sergeantRankOffsetY
                    + CGFloat(index) * GameConfig.sergeantRankChevronGap
            )
            chevron.zPosition = 0.25
            addChild(chevron)
        }
    }

    /// 단일 v자 chevron 노드 생성. path는 3점(좌 → 중앙 아래 → 우)으로 *뒤집힌 V* 모양.
    /// 골드 stroke + fill clear — *얇은 골드 선* 톤. SKShapeNode path API 사용.
    private func makeChevronNode() -> SKShapeNode {
        let path = UIBezierPath()
        let halfWidth  = GameConfig.sergeantChevronWidth / 2
        let depth      = GameConfig.sergeantChevronHeight
        path.move(to:    CGPoint(x: -halfWidth, y:  0))
        path.addLine(to: CGPoint(x:  0,         y: -depth))
        path.addLine(to: CGPoint(x:  halfWidth, y:  0))
        let shape = SKShapeNode(path: path.cgPath)
        shape.strokeColor = .ganhoMusicGold
        shape.lineWidth   = GameConfig.sergeantChevronLineWidth
        shape.fillColor   = .clear
        return shape
    }
}
