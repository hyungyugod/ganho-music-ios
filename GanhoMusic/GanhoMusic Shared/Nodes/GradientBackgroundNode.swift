//
//  GradientBackgroundNode.swift
//  GanhoMusic Shared
//
//  Phase 10-2 · StartScene 모던 리스킨
//
//  세로 그라데이션 배경 노드. CGGradient + UIGraphicsImageRenderer로
//  *1회만* 텍스처 생성 → SKTexture 캐싱. 매 프레임 재생성 0.
//  StartScene 외에도 다른 씬에서 재사용 가능한 일반 컴포넌트.
//

import SpriteKit
import UIKit

/// 세로 그라데이션 SKSpriteNode. top → bottom으로 두 색상 보간.
/// 텍스처는 init에서 1회 생성 후 super.init에 주입 — 매 프레임 갱신 없음.
/// 씬 사이즈가 바뀌면 호출부에서 인스턴스를 *재생성*하는 패턴 (didChangeSize).
final class GradientBackgroundNode: SKSpriteNode {

    // MARK: - Init
    /// - Parameters:
    ///   - size: 그라데이션 텍스처 크기. 보통 씬 size.
    ///   - topColor: 상단 색.
    ///   - bottomColor: 하단 색.
    init(size: CGSize, topColor: UIColor, bottomColor: UIColor) {
        let texture = Self.makeGradientTexture(
            size: size,
            top: topColor,
            bottom: bottomColor
        )
        super.init(texture: texture, color: .clear, size: size)
        zPosition = GameConfig.startSceneGradientZPosition
        name = "gradientBackground"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Texture
    /// CGGradient를 UIGraphicsImageRenderer로 그려 SKTexture 반환.
    /// 실패(Core Graphics 컨텍스트/그라데이션 생성 실패) 시 단색 fallback —
    /// 강제 언래핑 0건, 강제 캐스팅 0건.
    private static func makeGradientTexture(
        size: CGSize,
        top: UIColor,
        bottom: UIColor
    ) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 1.0]
            ) else {
                // 그라데이션 생성 실패 시 top 단색으로 채움 — 시각 fallback.
                cgCtx.setFillColor(top.cgColor)
                cgCtx.fill(CGRect(origin: .zero, size: size))
                return
            }
            // 세로 그라데이션: y=height(상단) → y=0(하단). UIKit 좌표계 기준.
            cgCtx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }

    // MARK: - Init (3-stop, Sprint 1)

    /// 3색 세로 그라데이션 인스턴스 생성. top(0.0) → mid(0.5) → bottom(1.0).
    /// Sprint 2 메뉴 씬(StartScene 외)에서 ganhoBgWarmTop/Mid/Bottom 호출 예정.
    /// Sprint 1에서는 호출자 0 — 인프라만 준비.
    ///
    /// 구현 노트: SKSpriteNode designated init 체이닝 제약을 피하기 위해
    /// 기존 2-stop init을 한 번 호출한 뒤 texture를 교체하는 패턴.
    /// `texture`는 var 프로퍼티라 인스턴스 생성 후 변경 가능.
    static func threeStop(
        size: CGSize,
        topColor: UIColor,
        midColor: UIColor,
        bottomColor: UIColor
    ) -> GradientBackgroundNode {
        let node = GradientBackgroundNode(
            size: size,
            topColor: topColor,
            bottomColor: bottomColor
        )
        node.texture = makeGradientTexture3Stop(
            size: size,
            top: topColor,
            mid: midColor,
            bottom: bottomColor
        )
        return node
    }

    /// 3-stop CGGradient를 UIGraphicsImageRenderer로 그려 SKTexture 반환.
    /// 실패 시 top 단색 fallback — 강제 언래핑 0건.
    private static func makeGradientTexture3Stop(
        size: CGSize,
        top: UIColor,
        mid: UIColor,
        bottom: UIColor
    ) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let colors = [top.cgColor, mid.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 0.5, 1.0]
            ) else {
                cgCtx.setFillColor(top.cgColor)
                cgCtx.fill(CGRect(origin: .zero, size: size))
                return
            }
            cgCtx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        return SKTexture(image: image)
    }
}
