//
//  TextureAtlasStore+Props.swift
//  GanhoMusic Shared
//
//  R2 · 병원 소품 베이크 — 구 HospitalPropNode 자식 셰이프(침대 3 / 커튼 5 / 캐비닛 3 / 카트 5)를
//  소품당 텍스처 1장으로 통합 (4~6노드 → 1노드, hard 평시 노드 게이트). 색·비율·선폭·알파는
//  구 자식 상수 그대로 — SpriteKit +y(위) ↔ UIKit +y(아래) 변환만 수행.
//

import SpriteKit
import UIKit

/// 소품 베이크 캐시 — extension은 저장 프로퍼티 불가, file-private enum이 담당.
private enum PropBakeCache {
    static var textures: [HospitalPropKind: SKTexture] = [:]
}

extension TextureAtlasStore {

    // MARK: - 병원 소품 베이크 (R2 — 소품당 4~6노드 → 1노드, hard 평시 노드 게이트)
    /// 캔버스가 소품 size 바깥 돌출분(셰이프 스트로크 절반 + 카트 바퀴 반지름)을 흡수하는 패딩.
    /// 4종 공통 최대치 — 대칭 패딩이라 소품 중심 정렬 불변.
    static var hospitalPropBakePadding: CGFloat {
        return UILayout.hospitalCartWheelRadius + UILayout.hospitalPropLineWidth
    }

    /// 병원 소품 베이크 — 구 HospitalPropNode 자식 셰이프(침대 3 / 커튼 5 / 캐비닛 3 / 카트 5)를
    /// 1장에 베이크. 색·비율·선폭·알파 전부 구 자식 상수 그대로 (UIKit y-down ↔ SpriteKit y-up 변환).
    static func hospitalPropTexture(kind: HospitalPropKind, size: CGSize) -> SKTexture {
        if let cached = PropBakeCache.textures[kind] { return cached }
        let pad = hospitalPropBakePadding
        let canvas = CGSize(width: size.width + pad * 2, height: size.height + pad * 2)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            switch kind {
            case .bed:      drawBed(cg, canvas: canvas, size: size)
            case .curtain:  drawCurtain(cg, canvas: canvas, size: size)
            case .cabinet:  drawCabinet(cg, canvas: canvas, size: size)
            case .cart:     drawCart(cg, canvas: canvas, size: size)
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        PropBakeCache.textures[kind] = texture
        return texture
    }

    /// 베이크 결과 스프라이트 크기 — 캔버스와 동일(패딩 포함). 중심 정렬이라 배치 좌표 불변.
    static func hospitalPropBakedSize(kind: HospitalPropKind, size: CGSize) -> CGSize {
        let pad = hospitalPropBakePadding
        return CGSize(width: size.width + pad * 2, height: size.height + pad * 2)
    }

    // MARK: 소품별 드로잉 (구 HospitalPropNode 빌더 1:1 — SpriteKit +y ↑ → UIKit y ↓ 변환)
    private static func fillRoundedRect(_ cg: CGContext, center: CGPoint, size: CGSize,
                                        fill: UIColor, stroke: UIColor) {
        let rect = CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2,
                          width: size.width, height: size.height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: UILayout.hospitalPropCornerRadius)
        fill.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = UILayout.hospitalPropLineWidth
        path.stroke()
        _ = cg   // 시그니처 통일 — UIBezierPath가 현재 컨텍스트에 직접 그림
    }

    private static func fillRect(_ cg: CGContext, center: CGPoint, size: CGSize, color: UIColor) {
        color.setFill()
        cg.fill(CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2,
                       width: size.width, height: size.height))
    }

    /// SpriteKit 자식 좌표(+y 위) → UIKit 캔버스 좌표(+y 아래).
    private static func canvasPoint(_ canvas: CGSize, dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: canvas.width / 2 + dx, y: canvas.height / 2 - dy)
    }

    private static func drawBed(_ cg: CGContext, canvas: CGSize, size: CGSize) {
        fillRoundedRect(cg, center: canvasPoint(canvas, dx: 0, dy: 0), size: size,
                        fill: .ganhoPaper, stroke: .ganhoIngameWallShadow)
        let pillowSize = CGSize(width: size.width * UILayout.hospitalBedPillowWidthRatio,
                                height: size.height * UILayout.hospitalBedPillowHeightRatio)
        let pillowCenter = canvasPoint(canvas, dx: -size.width * UILayout.hospitalBedPillowOffsetXRatio,
                                       dy: size.height * UILayout.hospitalBedPillowOffsetYRatio)
        fillRoundedRect(cg, center: pillowCenter, size: pillowSize,
                        fill: .ganhoIngameRewardMint, stroke: .ganhoIngameWallHighlight)
        let blanketSize = CGSize(width: size.width * UILayout.hospitalBedBlanketWidthRatio,
                                 height: size.height * UILayout.hospitalBedBlanketHeightRatio)
        let blanketCenter = canvasPoint(canvas, dx: size.width * UILayout.hospitalBedBlanketOffsetXRatio,
                                        dy: -size.height * UILayout.hospitalBedBlanketOffsetYRatio)
        fillRoundedRect(cg, center: blanketCenter, size: blanketSize,
                        fill: .ganhoIngameFloorB, stroke: .ganhoIngameWallHighlight)
    }

    private static func drawCurtain(_ cg: CGContext, canvas: CGSize, size: CGSize) {
        let railHeight = UILayout.hospitalCurtainRailHeight
        fillRect(cg, center: canvasPoint(canvas, dx: 0, dy: size.height / 2 - railHeight / 2),
                 size: CGSize(width: size.width, height: railHeight), color: .ganhoIngameWallShadow)
        let stripeWidth = size.width / CGFloat(UILayout.hospitalCurtainStripeCount)
        for index in 0..<UILayout.hospitalCurtainStripeCount {
            let base: UIColor = index % 2 == 0 ? .ganhoIngameWallHighlight : .ganhoIngameRewardMint
            let stripeX = -size.width / 2 + stripeWidth / 2 + CGFloat(index) * stripeWidth
            fillRect(cg, center: canvasPoint(canvas, dx: stripeX, dy: -railHeight / 2),
                     size: CGSize(width: stripeWidth, height: size.height - railHeight),
                     color: base.withAlphaComponent(UILayout.hospitalPropSoftAlpha))
        }
    }

    private static func drawCabinet(_ cg: CGContext, canvas: CGSize, size: CGSize) {
        fillRoundedRect(cg, center: canvasPoint(canvas, dx: 0, dy: 0), size: size,
                        fill: .ganhoIngameWallHighlight, stroke: .ganhoIngameWallShadow)
        let drawerHeight = size.height / CGFloat(UILayout.hospitalCabinetDrawerCount)
        let drawerSize = CGSize(width: size.width * UILayout.hospitalCabinetDrawerWidthRatio,
                                height: drawerHeight * UILayout.hospitalCabinetDrawerHeightRatio)
        for index in 0..<UILayout.hospitalCabinetDrawerCount {
            let drawerY = -size.height / 2 + drawerHeight / 2 + CGFloat(index) * drawerHeight
            fillRoundedRect(cg, center: canvasPoint(canvas, dx: 0, dy: drawerY),
                            size: drawerSize, fill: .ganhoIngameFloorA, stroke: .ganhoIngameWallShadow)
        }
    }

    private static func drawCart(_ cg: CGContext, canvas: CGSize, size: CGSize) {
        let traySize = CGSize(width: size.width,
                              height: size.height * UILayout.hospitalCartTrayHeightRatio)
        let trayCenter = canvasPoint(canvas, dx: 0,
                                     dy: size.height * UILayout.hospitalCartTrayOffsetYRatio)
        fillRoundedRect(cg, center: trayCenter, size: traySize,
                        fill: .ganhoPaper, stroke: .ganhoIngameWallShadow)
        let legSize = CGSize(width: UILayout.hospitalCartLegWidth,
                             height: size.height * UILayout.hospitalCartLegHeightRatio)
        let wheelRadius = UILayout.hospitalCartWheelRadius
        for dx in [-size.width * UILayout.hospitalCartLegOffsetXRatio,
                   size.width * UILayout.hospitalCartLegOffsetXRatio] {
            let legY = -size.height * UILayout.hospitalCartLegOffsetYRatio
            fillRect(cg, center: canvasPoint(canvas, dx: dx, dy: legY),
                     size: legSize, color: .ganhoIngameWallShadow)
            let wheelCenter = canvasPoint(canvas, dx: dx, dy: -size.height / 2)
            UIColor.ganhoIngameWallShadow.setFill()
            cg.fillEllipse(in: CGRect(x: wheelCenter.x - wheelRadius, y: wheelCenter.y - wheelRadius,
                                      width: wheelRadius * 2, height: wheelRadius * 2))
        }
    }
}
