//
//  NightShiftBackdropNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 (03_UI §4 배경 공통) — "야간 병동" 공통 배경.
//  ① ink900 단색 ② 스타필드(2px 점 40개, 미세 트윙클) ③ 하단 심전도 라인(mint alpha 0.12,
//  8s 루프당 좌→우 펄스 1회). 총 노드 ≤ 50, 매 프레임 텍스처 생성 0 (사전 생성 + SKAction만).
//  R3에서는 어떤 기존 씬에도 부착하지 않는다 — DEBUG 갤러리 전용 렌더 (배선은 R4).
//

import SpriteKit
import UIKit

/// v3 공통 배경. zPosition = ZOrder.Layer.bg. 중심 원점 — 호출측이 화면 중앙에 배치.
final class NightShiftBackdropNode: SKNode {

    /// 내부 적층 — 단색(0) < 심전도 라인(1) < 펄스 광점(2) < 스타필드(3).
    /// ignoresSiblingOrder=true 환경 — 동일 z 의존 금지, 전부 명시 분리.
    private enum InnerZ {
        static let base: CGFloat = 0
        static let ekg: CGFloat = 1
        static let ekgPulse: CGFloat = 2
        static let stars: CGFloat = 3
    }

    /// 심전도 스파이크 형상 보조 수치 (설계서 외 재량 — 파형 모양만 담당).
    private enum EKGShape {
        /// 스파이크(심박) 반복 간격 (pt).
        static let beatSpacing: CGFloat = 160
        /// 스파이크 상승 높이 (pt).
        static let spikeHeight: CGFloat = 14
        /// 스파이크 하강 깊이 (pt).
        static let dipDepth: CGFloat = 6
        /// 스파이크 구간 가로 폭 (pt).
        static let spikeWidth: CGFloat = 24
        /// 펄스 광점 크기 (pt) — 라인 위를 달리는 밝은 세그먼트.
        static let pulseSize = CGSize(width: 24, height: 2)
        /// 펄스 광점 alpha — 라인(0.12)보다 또렷한 강조.
        static let pulseAlpha: CGFloat = 0.5
    }

    // MARK: - Init
    /// - Parameter size: 덮을 화면 크기 (scene.size).
    init(size: CGSize) {
        super.init()
        zPosition = ZOrder.Layer.bg

        let base = SKSpriteNode(color: Palette.ink900, size: size)
        base.zPosition = InnerZ.base
        addChild(base)

        addStarfield(size: size)
        addEKGLine(size: size)
    }

    @available(*, unavailable, message: "Use init(size:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Starfield (2px 점 40개 + 개별 트윙클 repeatForever)
    private func addStarfield(size: CGSize) {
        let halfW = size.width / 2
        let halfH = size.height / 2
        for _ in 0..<UILayout.v3BackdropStarCount {
            let star = SKSpriteNode(
                color: Palette.textHi,
                size: CGSize(width: UILayout.v3BackdropStarSide,
                             height: UILayout.v3BackdropStarSide)
            )
            star.position = CGPoint(x: CGFloat.random(in: -halfW...halfW).rounded(),
                                    y: CGFloat.random(in: -halfH...halfH).rounded())
            star.alpha = FeelTuning.v3BackdropStarAlphaLow
            star.zPosition = InnerZ.stars

            let half = TimeInterval.random(
                in: FeelTuning.v3BackdropTwinkleMinDuration...FeelTuning.v3BackdropTwinkleMaxDuration
            ) / 2
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: FeelTuning.v3BackdropStarAlphaHigh, duration: half),
                SKAction.fadeAlpha(to: FeelTuning.v3BackdropStarAlphaLow, duration: half)
            ])
            star.run(SKAction.repeatForever(twinkle))
            addChild(star)
        }
    }

    // MARK: - EKG Line (정적 path 1회 생성 + 펄스 이동 SKAction — 텍스처 생성 0)
    private func addEKGLine(size: CGSize) {
        let halfW = size.width / 2
        let y = (-size.height / 2 + UILayout.v3BackdropEKGBottomOffset).rounded()

        let line = SKShapeNode(path: Self.makeEKGPath(width: size.width))
        line.strokeColor = Palette.mint
        line.lineWidth = UILayout.v3BackdropEKGLineWidth
        line.alpha = UILayout.v3BackdropEKGAlpha
        line.position = CGPoint(x: 0, y: y)
        line.zPosition = InnerZ.ekg
        addChild(line)

        // 8초 루프당 좌→우 펄스 1회 — 광점이 라인을 가로지른 뒤 좌단 복귀 + 잔여 대기.
        let pulse = SKSpriteNode(color: Palette.mint, size: EKGShape.pulseSize)
        pulse.alpha = EKGShape.pulseAlpha
        pulse.position = CGPoint(x: -halfW, y: y)
        pulse.zPosition = InnerZ.ekgPulse
        let travel = SKAction.moveTo(x: halfW,
                                     duration: FeelTuning.v3BackdropEKGPulseTravelDuration)
        let reset = SKAction.moveTo(x: -halfW, duration: 0)
        let rest = SKAction.wait(
            forDuration: FeelTuning.v3BackdropEKGLoopDuration
                - FeelTuning.v3BackdropEKGPulseTravelDuration
        )
        pulse.run(SKAction.repeatForever(SKAction.sequence([travel, reset, rest])))
        addChild(pulse)
    }

    /// 심전도 파형 path — 평탄선 + beatSpacing마다 스파이크 1개. init 1회 생성 (정적).
    private static func makeEKGPath(width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let halfW = width / 2
        path.move(to: CGPoint(x: -halfW, y: 0))
        var x = -halfW + EKGShape.beatSpacing / 2
        while x + EKGShape.spikeWidth < halfW {
            let quarter = EKGShape.spikeWidth / 4
            path.addLine(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + quarter, y: EKGShape.spikeHeight))
            path.addLine(to: CGPoint(x: x + quarter * 2, y: -EKGShape.dipDepth))
            path.addLine(to: CGPoint(x: x + quarter * 3, y: 0))
            x += EKGShape.beatSpacing
        }
        path.addLine(to: CGPoint(x: halfW, y: 0))
        return path
    }
}
