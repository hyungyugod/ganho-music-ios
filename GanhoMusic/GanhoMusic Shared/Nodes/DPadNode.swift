//
//  DPadNode.swift
//  GanhoMusic Shared
//
//  Phase 1-3 · 반투명 4방향 D-Pad
//

import SpriteKit

/// 4방향 D-Pad. 자체 touch 이벤트를 받아 currentDirection을 갱신한다.
/// 외부엔 read-only로 노출 — PlayerNode를 직접 알지 않는다.
final class DPadNode: SKNode {

    // MARK: - Properties
    private let upButton:    SKSpriteNode
    private let downButton:  SKSpriteNode
    private let leftButton:  SKSpriteNode
    private let rightButton: SKSpriteNode

    /// 외부 노출 — 지금 누르고 있는 방향 (정규화 단위 벡터). 안 누르면 .zero.
    /// 4방향 단일 정책 — 한 번에 .up/.down/.left/.right 중 하나.
    private(set) var currentDirection: CGVector = .zero

    // MARK: - Init
    override init() {
        let buttonSize = CGSize(
            width:  GameConfig.dpadButtonSize,
            height: GameConfig.dpadButtonSize
        )
        upButton    = SKSpriteNode(color: .ganhoPaper, size: buttonSize)
        downButton  = SKSpriteNode(color: .ganhoPaper, size: buttonSize)
        leftButton  = SKSpriteNode(color: .ganhoPaper, size: buttonSize)
        rightButton = SKSpriteNode(color: .ganhoPaper, size: buttonSize)

        super.init()

        // 자기 자신 좌표계: 중심(0,0) 기준, 십자 배치.
        // 버튼 사이 간격 = dpadButtonSize (서로 맞붙지 않게 한 칸 띄움).
        let offset = GameConfig.dpadButtonSize
        upButton.position    = CGPoint(x:  0,       y: +offset)
        downButton.position  = CGPoint(x:  0,       y: -offset)
        leftButton.position  = CGPoint(x: -offset,  y:  0)
        rightButton.position = CGPoint(x: +offset,  y:  0)

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
    }
}
