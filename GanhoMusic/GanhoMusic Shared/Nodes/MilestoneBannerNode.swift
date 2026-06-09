//
//  MilestoneBannerNode.swift
//  GanhoMusic Shared
//
//  인게임 상단 점수 마일스톤 안내 배너 (자가 소멸 노드 11호).
//  ComboPopupNode / ToastLabelNode 자가 소멸 노드 패턴 답습.
//

import SpriteKit

/// 인게임 상단 중앙에서 fadeIn → hold → fadeOut으로 1회 떴다 사라지는 순수 시각 안내 배너.
/// 게임 정지·dim·입력차단 없음 — 플레이 흐름을 끊지 않고 격려 문구만 스쳐 지나간다.
/// PhysicsBody 부착 0 — 순수 시각. cameraNode 자식으로 부착해 카메라 follow와 무관하게 화면 고정.
///
/// ComboPopupNode 패턴 정확 답습 — 차이는 진입 방식(fadeIn 시작) + 위치(상단 중앙 고정) +
/// 색(HUD 옐로 격려 톤) + 자가 소멸 시퀀스(fadeIn → hold → fadeOut). 외부 진입점은 정적
/// 팩토리 `spawn(text:parent:)` 단일 — 호출부가 position 설정을 누락할 수 없게 강제한다.
///
/// SelfDismissingNode 채택 — 자가 소멸 노드 마커 프로토콜 일관성 유지.
final class MilestoneBannerNode: SKNode, SelfDismissingNode {

    // MARK: - Properties
    /// 안내 문구를 보여주는 라벨. SKNode 본체는 좌표/액션 호스트, label은 시각 콘텐츠.
    /// ComboPopupNode와 동형 구조.
    private let label: SKLabelNode

    // MARK: - Init (private — spawn factory에서만 호출)
    /// 외부 호출자가 *반드시* `spawn` 정적 팩토리를 거치도록 강제 → position 설정 누락 같은
    /// 사용자 실수 컴파일 타임 차단. ComboPopupNode / ToastLabelNode와 동일 패턴.
    private init(text: String) {
        // 인게임 픽셀 톤 일관 — ComboPopupNode와 동일 fontPixel(Menlo-Bold).
        self.label = SKLabelNode(fontNamed: GameConfig.fontPixel)
        self.label.text = text
        super.init()
        name = "milestoneBanner"
        zPosition = GameConfig.milestoneBannerZPosition
        alpha = 0   // fadeIn 시작점 — 등장 시 부드럽게 떠오른다.
        configureLabel()
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Spawn (static factory — 외부 유일 진입점)
    /// 인게임 상단 중앙에 안내 배너를 띄우는 자가 소멸 노드.
    /// - Parameters:
    ///   - text: 표시 문구. 호출부에서 절반=`"\(남은개수)"+GameConfig.milestoneHalfSuffix` / 근접=`milestoneNearText` 전달.
    ///   - parent: 부착 부모. 호출부에서 `cameraNode` 전달 — (0,0)이 화면 중앙, +y가 위.
    static func spawn(text: String, parent: SKNode) {
        let node = MilestoneBannerNode(text: text)
        // cameraNode 자식 → 화면 중앙 기준 상단 1/4 부근. HUD 슬롯 행과 겹치지 않는 고정 양수.
        node.position = CGPoint(x: 0, y: GameConfig.milestoneBannerOffsetY)
        parent.addChild(node)
        node.animate()
    }

    // MARK: - Animate (private — spawn에서만 호출)
    /// 부모 addChild 직후 호출. fadeIn → hold → fadeOut → removeFromParent 시퀀스로 자가 제거.
    /// self 미사용 → [weak self] 캡처 불필요 (ComboPopupNode.animate() 패턴 답습).
    private func animate() {
        let fadeIn  = SKAction.fadeIn(withDuration: GameConfig.milestoneBannerFadeDuration)
        let hold    = SKAction.wait(forDuration: GameConfig.milestoneBannerHoldDuration)
        let fadeOut = SKAction.fadeOut(withDuration: GameConfig.milestoneBannerFadeDuration)
        let cleanup = SKAction.removeFromParent()
        run(.sequence([fadeIn, hold, fadeOut, cleanup]))
    }

    // MARK: - Configure
    /// 라벨 스타일 — HUD 옐로(격려/강조 톤), 중앙 정렬. cameraNode 자식 (0,0) = 화면 중앙.
    /// 라벨은 본 노드 좌표계 (0,0)에 부착 → 본 노드 position이 곧 라벨 표시 위치.
    private func configureLabel() {
        label.fontSize = GameConfig.milestoneBannerFontSize
        // .ganhoPixelHudYellow — HUD 옐로와 동일 톤. *남은 거리* 안내를 HUD와 한 톤으로 묶는다.
        label.fontColor = .ganhoPixelHudYellow
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
    }
}
