//
//  ControlsHintNode.swift
//  GanhoMusic Shared
//
//  R9 #3 — 첫 판 조작 온보딩 힌트. cameraNode 자식 (D-Pad/스킬 버튼과 동일 좌표계).
//  D-Pad 4방향 화살표 펄스 + "드래그로 이동" / 스킬 버튼 액센트 글로우 + "탭하면 스킬 발동".
//  등장 페이드 인 → 유지 → 페이드 아웃 → removeFromParent 자동 소멸 (SKAction 시퀀스 —
//  Timer/asyncAfter 0, 잔존 노드 0). worldNode 비소속 — 일시정지(isPaused) 중에도 수명
//  진행 (SPEC §#3-5 허용). 총 수명 ~3.0s — easy 첫 발사 3.5s 이전 안전 창.
//

import SpriteKit
import UIKit

/// 첫 판 1회 조작 안내 오버레이. 생성 즉시 수명 시퀀스 시작 — 호출측은 attach만.
final class ControlsHintNode: SKNode {

    private static let lifetimeActionKey = "r9ControlsHintLifetime"

    // MARK: - Init
    /// - Parameters:
    ///   - dpadPosition: cameraNode 좌표계 D-Pad 중심 (scene.dpad.position).
    ///   - skillButtonPosition: cameraNode 좌표계 스킬 버튼 중심 (scene.skillButton.position).
    ///   - controlScale: DeviceLayoutProfile.ingameControlScale — 실제 컨트롤과 동일 배율.
    init(dpadPosition: CGPoint, skillButtonPosition: CGPoint, controlScale: CGFloat) {
        super.init()
        name = "controlsHint"
        // HUD(100) 위 일시 안내 밴드 — 기존 토큰 재사용 (R9 신규 z 상수는 설정 다이얼로그
        // 1개로 한정한 범위 계약 준수). 마일스톤 배너(중앙 상단)와 표시 영역 비겹침.
        zPosition = ZOrder.milestoneBannerZPosition
        addChild(makeDPadCluster(at: dpadPosition, scale: controlScale))
        addChild(makeSkillCluster(at: skillButtonPosition, scale: controlScale))
        runLifetime()
    }

    @available(*, unavailable, message: "Use init(dpadPosition:skillButtonPosition:controlScale:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Lifetime (등장 → 유지 → 소멸 — removeFromParent로 잔존 0)
    private func runLifetime() {
        alpha = 0
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: FeelTuning.R9.controlsHintFadeDuration),
            SKAction.wait(forDuration: FeelTuning.R9.controlsHintHoldDuration),
            SKAction.fadeOut(withDuration: FeelTuning.R9.controlsHintFadeDuration),
            SKAction.removeFromParent()
        ])
        run(sequence, withKey: Self.lifetimeActionKey)
    }

    // MARK: - D-Pad Cluster (4방향 화살표 펄스 + 캡션)
    private func makeDPadCluster(at position: CGPoint, scale: CGFloat) -> SKNode {
        let cluster = SKNode()
        cluster.position = position
        cluster.setScale(scale)
        // D-Pad 실제 화살표 기하(offset = dpadButtonSize)·글리프(^v<>) 그대로 — 시각 정합.
        let distance = GameplayTuning.dpadButtonSize
        let arrows: [(text: String, offset: CGPoint)] = [
            (UILayout.dpadUpIconText, CGPoint(x: 0, y: distance)),
            (UILayout.dpadDownIconText, CGPoint(x: 0, y: -distance)),
            (UILayout.dpadLeftIconText, CGPoint(x: -distance, y: 0)),
            (UILayout.dpadRightIconText, CGPoint(x: distance, y: 0))
        ]
        for arrow in arrows {
            let label = SKLabelNode(fontNamed: Typography.V3.h2.fontName)
            label.text = arrow.text
            label.fontSize = Typography.V3.h2.size
            label.fontColor = Palette.gold
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = arrow.offset
            label.run(Self.makePulse(withScale: true))
            cluster.addChild(label)
        }
        cluster.addChild(Self.makeCaption(
            text: UILayout.R9.controlsHintMoveCaptionText,
            y: GameplayTuning.dpadTouchRadius + UILayout.R9.controlsHintCaptionGap
        ))
        return cluster
    }

    // MARK: - Skill Cluster (액센트 글로우 — 단색 사각 1장, SKEffectNode 블러 금지)
    private func makeSkillCluster(at position: CGPoint, scale: CGFloat) -> SKNode {
        let cluster = SKNode()
        cluster.position = position
        cluster.setScale(scale)
        let glowSide = UILayout.skillButtonVisualRadius * 2 * Palette.glowScale
        let glow = SKSpriteNode(
            color: Palette.gold.withAlphaComponent(Palette.glowAlpha),
            size: CGSize(width: glowSide, height: glowSide)
        )
        glow.run(Self.makePulse(withScale: false))
        cluster.addChild(glow)
        // 캡션은 HUD 스킬 슬롯(버튼 위 +50) 위로 — 슬롯 라벨(스킬명/CD)과 비겹침.
        cluster.addChild(Self.makeCaption(
            text: UILayout.R9.controlsHintSkillCaptionText,
            y: GameplayTuning.hudSkillSlotOffsetY + UILayout.R9.controlsHintCaptionGap
        ))
        return cluster
    }

    // MARK: - Pieces
    private static func makeCaption(text: String, y: CGFloat) -> SKLabelNode {
        let caption = SKLabelNode(fontNamed: Typography.V3.body.fontName)
        caption.text = text
        caption.fontSize = Typography.V3.body.size
        caption.fontColor = Palette.textHi
        caption.horizontalAlignmentMode = .center
        caption.verticalAlignmentMode = .center
        caption.position = CGPoint(x: 0, y: y.rounded())
        return caption
    }

    /// 알파(+옵션 스케일) 왕복 펄스 — easeInEaseOut 호흡. 노드 소멸과 함께 자동 정지.
    private static func makePulse(withScale: Bool) -> SKAction {
        let half = FeelTuning.R9.controlsHintPulseHalfPeriod
        let dim = SKAction.fadeAlpha(to: FeelTuning.R9.controlsHintPulseLowAlpha, duration: half)
        dim.timingMode = .easeInEaseOut
        let brighten = SKAction.fadeAlpha(to: 1.0, duration: half)
        brighten.timingMode = .easeInEaseOut
        let alphaPulse = SKAction.sequence([dim, brighten])
        guard withScale else { return SKAction.repeatForever(alphaPulse) }
        let grow = SKAction.scale(to: FeelTuning.R9.controlsHintPulseScale, duration: half)
        grow.timingMode = .easeInEaseOut
        let shrink = SKAction.scale(to: 1.0, duration: half)
        shrink.timingMode = .easeInEaseOut
        let scalePulse = SKAction.sequence([grow, shrink])
        return SKAction.repeatForever(SKAction.group([alphaPulse, scalePulse]))
    }
}
