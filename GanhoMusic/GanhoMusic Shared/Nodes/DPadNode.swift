//
//  DPadNode.swift
//  GanhoMusic Shared
//
//  Phase 1-3 · 반투명 4방향 D-Pad
//  Sprint 3 · v2 디자인 시스템 — 4 SKShapeNode(white α + navy α stroke) + 중앙 데드존
//

import SpriteKit

/// 4방향 D-Pad. 자체 touch 이벤트를 받아 currentDirection을 갱신한다.
/// 외부엔 read-only로 노출 — PlayerNode를 직접 알지 않는다.
/// Sprint 3 — 4 SKSpriteNode → 4 SKShapeNode 라운드 사각형 + 중앙 데드존 추가.
/// **touch 메서드 4개 본문 + updateDirection 알고리즘 + currentDirection 타입 완전 보존.**
final class DPadNode: SKNode {

    // MARK: - Properties
    /// Sprint 3 — SKSpriteNode → SKShapeNode. 외부 노출 없는 private 프로퍼티라
    /// 타입 교체가 호출자에 영향 0.
    private let upButton:    SKShapeNode
    private let downButton:  SKShapeNode
    private let leftButton:  SKShapeNode
    private let rightButton: SKShapeNode
    /// 중앙 데드존 — navy α 라운드 사각형. 시각만, 터치 흡수 0.
    private let centerDeadzone: SKShapeNode

    /// 외부 노출 — 지금 누르고 있는 방향 (정규화 단위 벡터). 안 누르면 .zero.
    /// 4방향 단일 정책 — 한 번에 .up/.down/.left/.right 중 하나.
    private(set) var currentDirection: CGVector = .zero

    // MARK: - Callbacks (Sprint 7 Phase G)
    /// 방향 입력이 *비-제로*로 갱신된 직후 발화되는 콜백.
    /// .zero(touchesEnded/Cancelled)는 발화하지 않음 → 정지 시 마지막 방향 유지.
    /// 구독자(GameScene)는 PlayerNode.facing(_:)에 위임 — 입력 매핑 알고리즘 변경 0.
    var onDirectionChanged: ((Direction) -> Void)?

    // MARK: - Init
    override init() {
        let buttonSize = CGSize(
            width:  GameConfig.dpadButtonSize,
            height: GameConfig.dpadButtonSize
        )
        // Sprint 3 — SKShapeNode 라운드 사각형. fillColor=white α, strokeColor=navy α.
        upButton    = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        downButton  = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        leftButton  = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        rightButton = SKShapeNode(rectOf: buttonSize, cornerRadius: GameConfig.dpadButtonCornerRadius)
        let deadzoneSize = CGSize(
            width:  GameConfig.dpadCenterDeadzoneSize,
            height: GameConfig.dpadCenterDeadzoneSize
        )
        centerDeadzone = SKShapeNode(
            rectOf: deadzoneSize,
            cornerRadius: GameConfig.dpadCenterDeadzoneCornerRadius
        )

        super.init()

        // 자기 자신 좌표계: 중심(0,0) 기준, 십자 배치.
        // 버튼 사이 간격 = dpadButtonSize (서로 맞붙지 않게 한 칸 띄움).
        let offset = GameConfig.dpadButtonSize
        upButton.position    = CGPoint(x:  0,       y: +offset)
        downButton.position  = CGPoint(x:  0,       y: -offset)
        leftButton.position  = CGPoint(x: -offset,  y:  0)
        rightButton.position = CGPoint(x: +offset,  y:  0)
        centerDeadzone.position = .zero

        // Sprint 3 — fill/stroke 색 일괄. white 0.75 + navy α 0.25 stroke + 두께 2.
        for button in [upButton, downButton, leftButton, rightButton] {
            button.fillColor = UIColor.white
                .withAlphaComponent(GameConfig.dpadButtonFillAlpha)
            button.strokeColor = UIColor.ganhoNavyDeep
                .withAlphaComponent(GameConfig.dpadButtonStrokeAlpha)
            button.lineWidth = GameConfig.dpadButtonStrokeLineWidth
        }

        // 중앙 데드존 — navy α 0.4. strokeColor=clear.
        centerDeadzone.fillColor = UIColor.ganhoNavyDeep
            .withAlphaComponent(GameConfig.dpadCenterDeadzoneAlpha)
        centerDeadzone.strokeColor = .clear

        addChild(centerDeadzone)
        addChild(upButton)
        addChild(downButton)
        addChild(leftButton)
        addChild(rightButton)

        alpha = GameConfig.dpadAlpha          // 자식까지 일괄 반투명
        isUserInteractionEnabled = true       // 핵심! 안 켜면 touch가 부모로 흐름

        upButton.name    = "dpadUp"
        downButton.name  = "dpadDown"
        leftButton.name  = "dpadLeft"
        rightButton.name = "dpadRight"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touch (4방향 단일 정책)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateDirection(forTouchLocation: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateDirection(forTouchLocation: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentDirection = .zero
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentDirection = .zero
    }

    // MARK: - Direction Resolution
    /// 자기 자신 좌표계 기준 touch 위치를 4방향 단일 벡터로 변환.
    /// 정책: |dx| >= |dy|면 좌우, 아니면 상하. 대각선/중심 deadzone 없음 (1-3 단순화).
    private func updateDirection(forTouchLocation location: CGPoint) {
        if abs(location.x) >= abs(location.y) {
            currentDirection = CGVector(dx: location.x >= 0 ? 1 : -1, dy: 0)
        } else {
            currentDirection = CGVector(dx: 0, dy: location.y >= 0 ? 1 : -1)
        }
        // Sprint 7 Phase G — 방향 갱신 직후 콜백 발화 (currentDirection 알고리즘 0건 변경).
        // .zero 입력은 Direction.init?(vector:)가 nil 반환 → 자연 noop. touchesEnded/Cancelled는
        // 본 함수를 호출하지 않으므로(.zero set만 함) 정지 시 콜백 미발화 → 마지막 방향 유지.
        if let dir = Direction(vector: currentDirection) {
            onDirectionChanged?(dir)
        }
    }
}
