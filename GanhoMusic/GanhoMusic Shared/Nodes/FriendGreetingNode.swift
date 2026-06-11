//
//  FriendGreetingNode.swift
//  GanhoMusic Shared
//
//  R10 U6 C-2 · 우정 상호 인사 말풍선 (자가 소멸 노드 11호) — 이스터에그에서
//  석조무사와 박병장이 만나는 순간의 짧은 문답 1줄.
//  자가 소멸 패턴 답습 (CutsceneOverlayNode 헤더의 1~10호 전례) — 시간 트리거형:
//  wait(delay) → 등장(fade+pop) → hold → fadeOut → removeFromParent (좀비 0).
//  PhysicsBody 0 — 순수 시각. 칩은 PixelChipNode 재사용(v3 디자인 시스템) + 꼬리 삼각형.
//

import SpriteKit
import UIKit

/// 우정 인사 말풍선. 외부 진입점은 정적 팩토리 `spawn` 1개 — init private
/// (ScorePopupNode 9호 답습: position/알파/액션 설정 누락을 컴파일 타임에 차단).
final class FriendGreetingNode: SKNode, SelfDismissingNode {

    /// 내부 적층 — 꼬리(0) < 칩(1).
    private enum InnerZ {
        static let tail: CGFloat = 0
        static let chip: CGFloat = 1
    }

    // MARK: - Spawn (정적 팩토리)
    /// 말풍선을 parent에 부착하고 수명 시퀀스를 시작한다.
    /// - Parameters:
    ///   - text: 말풍선 카피 (FeelTuning.R10 상수만 — 호출부 리터럴 금지).
    ///   - accent: 화자 액센트색 (칩 보더/꼬리 stroke).
    ///   - position: parent 좌표계 내 중심 위치.
    ///   - zPosition: parent 좌표계 내 z (월드 자식=상대값 / 카메라=ZOrder 파생값).
    ///   - parent: 부착 대상 (석조무사 본체 또는 cameraNode).
    ///   - delay: 등장 지연 (초) — 두 말풍선 순차 노출용.
    static func spawn(text: String, accent: UIColor, at position: CGPoint,
                      zPosition: CGFloat, parent: SKNode, delay: TimeInterval) {
        let node = FriendGreetingNode(text: text, accent: accent)
        node.position = position
        node.zPosition = zPosition
        node.alpha = 0
        node.setScale(FeelTuning.R10.friendGreetingPopStartScale)
        parent.addChild(node)

        // wait → (fadeIn ∥ easeOutBack 팝) → hold → fadeOut → 자가 소멸. Timer/asyncAfter 0.
        let wait = SKAction.wait(forDuration: delay)
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: FeelTuning.R10.friendGreetingFadeInDuration),
            Tween.curved(
                SKAction.scale(to: 1.0,
                               duration: FeelTuning.R10.friendGreetingFadeInDuration),
                .easeOutBack
            )
        ])
        let hold = SKAction.wait(forDuration: FeelTuning.R10.friendGreetingHoldDuration)
        let fadeOut = SKAction.fadeOut(
            withDuration: FeelTuning.R10.friendGreetingFadeOutDuration
        )
        node.run(.sequence([wait, appear, hold, fadeOut, .removeFromParent()]))
    }

    // MARK: - Init (private — spawn 경유 강제)
    private init(text: String, accent: UIColor) {
        super.init()
        name = "friendGreeting"

        let chip = PixelChipNode(text: text, style: .accent(accent))
        chip.zPosition = InnerZ.chip
        addChild(chip)

        // 꼬리 삼각형 — 칩 하단 중앙에서 아래로 (말풍선 시그널). 칩 accent 변형과 동일 톤.
        let halfWidth = FeelTuning.R10.friendGreetingTailWidth / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -halfWidth, y: 0))
        path.addLine(to: CGPoint(x: halfWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -FeelTuning.R10.friendGreetingTailHeight))
        path.close()
        let tail = SKShapeNode(path: path.cgPath)
        tail.fillColor = Palette.ink800
        tail.strokeColor = accent
        tail.lineWidth = UILayout.v3BorderWidth
        tail.position = CGPoint(x: 0, y: -chip.chipSize.height / 2)
        tail.zPosition = InnerZ.tail
        addChild(tail)
    }

    @available(*, unavailable, message: "Use spawn(text:accent:at:zPosition:parent:delay:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
