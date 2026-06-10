//
//  PixelProgressBarNode.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 컴포넌트 (03_UI §5) — 세그먼트형 진행바.
//  8px 블록 + 1px 간격 (UILayout v3Progress*). XP·콤보 게이지·쿨다운 공용 범용 API.
//  세그먼트는 init 1회 생성 — setProgress는 색만 갱신 (노드 재생성 금지).
//

import SpriteKit
import UIKit

/// v3 진행바. 채움 색 파라미터 + 0...1 진행률.
final class PixelProgressBarNode: SKNode {

    private let fillColor: UIColor
    /// 빈 세그먼트 색 — 트랙 시인성 (호버/눌림 표면 토큰 재사용).
    private let emptyColor: UIColor = Palette.ink600
    private var segments: [SKSpriteNode] = []
    private var filledCount = 0

    /// 채움 애니 액션 키 — withKey 멱등 (연속 호출 시 자동 교체).
    private static let fillActionKey = "pixelProgressFill"

    // MARK: - Init
    /// - Parameters:
    ///   - size: 바 전체 크기. 세그먼트 수 = 폭에서 (블록 8px + 간격 1px) 단위로 산출.
    ///   - fillColor: 채움 색 (액센트 토큰 권장).
    init(size: CGSize, fillColor: UIColor) {
        self.fillColor = fillColor
        super.init()

        let unit = UILayout.v3ProgressSegmentWidth + UILayout.v3ProgressSegmentGap
        let count = max(1, Int((size.width + UILayout.v3ProgressSegmentGap) / unit))
        let contentWidth = CGFloat(count) * unit - UILayout.v3ProgressSegmentGap
        let startX = (-contentWidth / 2 + UILayout.v3ProgressSegmentWidth / 2).rounded()

        for index in 0..<count {
            let segment = SKSpriteNode(
                color: emptyColor,
                size: CGSize(width: UILayout.v3ProgressSegmentWidth, height: size.height)
            )
            segment.position = CGPoint(x: startX + CGFloat(index) * unit, y: 0)
            addChild(segment)
            segments.append(segment)
        }
    }

    @available(*, unavailable, message: "Use init(size:fillColor:) instead.")
    required init?(coder: NSCoder) {
        return nil
    }

    // MARK: - Progress
    /// 진행률 갱신 (0...1 클램프). animated=true면 좌→우 순차 채움
    /// (FeelTuning.v3ProgressFillDuration — 03_UI §7 XP 바 0.5s).
    func setProgress(_ value: CGFloat, animated: Bool) {
        let clamped = min(max(value, 0), 1)
        let targetCount = Int((CGFloat(segments.count) * clamped).rounded())
        removeAction(forKey: Self.fillActionKey)

        guard animated, targetCount != filledCount else {
            applyFilledCount(targetCount)
            return
        }

        // customAction — 매 프레임 색 대입만 (노드 생성·텍스처 생성 0).
        let startCount = filledCount
        let duration = FeelTuning.v3ProgressFillDuration
        let fill = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self = self else { return }
            let progress = min(max(elapsed / CGFloat(duration), 0), 1)
            let current = startCount + Int((CGFloat(targetCount - startCount) * progress).rounded())
            self.applyFilledCount(current)
        }
        run(Tween.curved(fill, .easeOutCubic), withKey: Self.fillActionKey)
    }

    /// 채움 상태 일괄 반영 — 세그먼트 색만 교체 (재생성·alpha 숨김 없음).
    private func applyFilledCount(_ count: Int) {
        let clampedCount = min(max(count, 0), segments.count)
        guard clampedCount != filledCount else { return }
        filledCount = clampedCount
        for (index, segment) in segments.enumerated() {
            segment.color = index < clampedCount ? fillColor : emptyColor
        }
    }
}
