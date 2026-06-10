//
//  TextureAtlasStore+R2.swift
//  GanhoMusic Shared
//
//  R2 · 베이크 텍스처 — F/청진기 가독성 자식 통합(노드 게이트) + 파티클 텍셀 + 걷기 먼지.
//  (병원 소품 베이크는 TextureAtlasStore+Props.swift.) R1 NoteNode 베이크 동일 기법
//  (그리기 순서 halo → 본체 → outline).
//  near-miss 펄스는 normal/pulse 베이크 변형 교차 — pulse 변형은 halo/outline만 기존 펄스
//  스케일(1.22/1.18)로 확대해 그린다(본체 불변). 캔버스는 pulse 변형 halo 바깥끝까지 단일 식.
//

import SpriteKit
import UIKit

/// R2 베이크 캐시 보관소 — extension은 저장 프로퍼티를 가질 수 없어 file-private enum이 담당.
/// 시맨틱은 본체 static 캐시와 동일(씬 재시작에도 워밍 유지).
private enum R2BakeCache {
    static var fProjectile: [TextureAtlasStore.FProjectileBakeVariant: SKTexture] = [:]
    static var stethoscopeNormal: SKTexture?
    static var stethoscopePulse: SKTexture?
    static var particleTexel: SKTexture?
    static var walkDust: SKTexture?
}

extension TextureAtlasStore {

    // MARK: - F 투사체 베이크 3종
    /// F 베이크 변형 3종. 매혹 중 펄스 없음(기존 가드 시맨틱) — enchanted는 단일 변형.
    enum FProjectileBakeVariant {
        case normal, normalPulse, enchanted
    }

    /// F 베이크 한 변 (pt) — pulse 시 halo 스트로크 바깥끝까지. NoteNode noteBakedSideLength 패턴.
    static var fProjectileBakedSideLength: CGFloat {
        let pulse = GameplayTuning.projectileNearMissPulseScale
        return (UILayout.projectileDangerHaloRadius * pulse
                + UILayout.ingameObjectHaloLineWidth * pulse / 2) * 2
    }

    /// 청진기 베이크 한 변 (pt) — pulse 시 halo 스트로크 바깥끝까지 (정사각 — 회전 시각과 정합).
    static var stethoscopeBakedSideLength: CGFloat {
        let pulse = GameplayTuning.stethoscopeNearMissPulseScale
        return (UILayout.stethoscopeReadableHaloRadius * pulse
                + UILayout.ingameObjectHaloLineWidth * pulse / 2) * 2
    }

    /// F 투사체 베이크 — 구 자식 2종(halo 원 zPos -1 / outline 사각 zPos +1)을 본체와 1장으로.
    /// 색·알파·선폭·반경 전부 구 자식 상수 그대로. physicsBody 16×16은 본 텍스처와 무관(불변).
    static func fProjectileBakedTexture(_ variant: FProjectileBakeVariant) -> SKTexture {
        if let cached = R2BakeCache.fProjectile[variant] { return cached }
        let side = fProjectileBakedSideLength
        let isPulse = variant == .normalPulse
        let shapeScale = isPulse ? GameplayTuning.projectileNearMissPulseScale : 1
        let isEnchanted = variant == .enchanted

        let haloStroke = isEnchanted
            ? UIColor.ganhoIngameRewardMint.withAlphaComponent(UILayout.projectileDangerHaloAlpha)
            : UIColor.ganhoIngameDanger.withAlphaComponent(UILayout.projectileDangerHaloAlpha)
        let haloFill = isEnchanted
            ? UIColor.ganhoIngameReward.withAlphaComponent(UILayout.ingameObjectHaloAlpha)
            : UIColor.ganhoIngameDangerDeep.withAlphaComponent(UILayout.ingameObjectHaloAlpha)
        let outlineColor: UIColor = isEnchanted ? .ganhoPixelHudWhite : .ganhoPixelOutlineBlack
        let bodyColor = isEnchanted ? Palette.aItemColor : Palette.fProjectileColor

        let texture = bakeProjectileReadability(
            side: side, shapeScale: shapeScale,
            haloRadius: UILayout.projectileDangerHaloRadius,
            haloStroke: haloStroke, haloFill: haloFill,
            bodyImage: UIImage(cgImage: PixelSpriteRenderer.fProjectileTexture(color: bodyColor).cgImage()),
            bodySize: CGSize(width: GameplayTuning.fProjectileVisualSize,
                             height: GameplayTuning.fProjectileVisualSize),
            outlineSize: CGSize(width: GameplayTuning.fProjectileVisualSize,
                                height: GameplayTuning.fProjectileVisualSize),
            outlineColor: outlineColor,
            outlineWidth: UILayout.projectileOutlineWidth
        )
        R2BakeCache.fProjectile[variant] = texture
        return texture
    }

    // MARK: - 청진기 베이크 2종
    /// 청진기 베이크 — 구 자식 2종(halo 원 / highlight 사각 hudYellow)을 본체와 1장으로.
    /// 베이크 전체가 본체와 함께 회전 — 구 자식 회전 동반과 시각 동일 (halo는 원이라 회전 불변).
    static func stethoscopeBakedTexture(pulsing: Bool) -> SKTexture {
        if pulsing, let cached = R2BakeCache.stethoscopePulse { return cached }
        if !pulsing, let cached = R2BakeCache.stethoscopeNormal { return cached }
        let side = stethoscopeBakedSideLength
        let shapeScale = pulsing ? GameplayTuning.stethoscopeNearMissPulseScale : 1
        let haloStroke = UIColor.ganhoIngameDanger
            .withAlphaComponent(UILayout.stethoscopeReadableHaloAlpha)
        let haloFill = UIColor.ganhoIngameDangerDeep
            .withAlphaComponent(UILayout.ingameObjectHaloAlpha * UILayout.ingameHalfAlphaMultiplier)
        let bodySize = CGSize(width: GameplayTuning.stethoscopeWidth,
                              height: GameplayTuning.stethoscopeHeight)

        let texture = bakeProjectileReadability(
            side: side, shapeScale: shapeScale,
            haloRadius: UILayout.stethoscopeReadableHaloRadius,
            haloStroke: haloStroke, haloFill: haloFill,
            bodyImage: UIImage(cgImage: PixelSpriteRenderer.stethoscopeTexture().cgImage()),
            bodySize: bodySize,
            outlineSize: bodySize,
            outlineColor: .ganhoPixelHudYellow,
            outlineWidth: UILayout.ingameObjectHaloLineWidth
        )
        if pulsing {
            R2BakeCache.stethoscopePulse = texture
        } else {
            R2BakeCache.stethoscopeNormal = texture
        }
        return texture
    }

    /// F/청진기 공용 베이크 본체 — halo(fill→stroke) → 픽셀 본체(.none 보간) → outline 순.
    /// shapeScale은 구 펄스의 자식 scale 효과 재현: halo 반경·outline 사각·선폭에만 곱한다(본체 불변).
    private static func bakeProjectileReadability(side: CGFloat, shapeScale: CGFloat,
                                                  haloRadius: CGFloat,
                                                  haloStroke: UIColor, haloFill: UIColor,
                                                  bodyImage: UIImage, bodySize: CGSize,
                                                  outlineSize: CGSize, outlineColor: UIColor,
                                                  outlineWidth: CGFloat) -> SKTexture {
        let center = side / 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            // 1) halo (구 zPos -1) — SKShapeNode 렌더 순서 동일: fill 먼저, stroke 위.
            let scaledRadius = haloRadius * shapeScale
            let haloRect = CGRect(x: center - scaledRadius, y: center - scaledRadius,
                                  width: scaledRadius * 2, height: scaledRadius * 2)
            haloFill.setFill()
            cg.fillEllipse(in: haloRect)
            haloStroke.setStroke()
            cg.setLineWidth(UILayout.ingameObjectHaloLineWidth * shapeScale)
            cg.strokeEllipse(in: haloRect)
            // 2) 본체 픽셀 (구 zPos 0) — 보간 끔 = .nearest 정수 확대와 동일 픽셀 블록.
            cg.interpolationQuality = .none
            bodyImage.draw(in: CGRect(x: center - bodySize.width / 2,
                                      y: center - bodySize.height / 2,
                                      width: bodySize.width, height: bodySize.height))
            // 3) outline/highlight (구 zPos +1).
            let scaledOutline = CGSize(width: outlineSize.width * shapeScale,
                                       height: outlineSize.height * shapeScale)
            outlineColor.setStroke()
            cg.stroke(CGRect(x: center - scaledOutline.width / 2,
                             y: center - scaledOutline.height / 2,
                             width: scaledOutline.width, height: scaledOutline.height),
                      width: outlineWidth * shapeScale)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    // MARK: - 파티클 텍셀
    /// 파티클 단색 사각 텍셀 (3×3 흰색) — EffectDirector가 particleColor 틴트로 채색.
    static func particleTexelTexture() -> SKTexture {
        if let cached = R2BakeCache.particleTexel { return cached }
        let side = FeelTuning.particleTexelSide
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        R2BakeCache.particleTexel = texture
        return texture
    }

    // MARK: - 걷기 먼지 (2px 사각 2개 베이크 — 퍼프당 1노드)
    /// 걷기 먼지 텍스처 캔버스 크기 — 사각 2개가 ±halfGap에 배치되는 한 장.
    static var walkDustTextureSize: CGSize {
        return CGSize(width: FeelTuning.walkDustHalfGap * 2 + FeelTuning.walkDustSquareSide,
                      height: FeelTuning.walkDustSquareSide)
    }

    /// 걷기 먼지 — 2px 사각 2개(좌우 ±halfGap)를 1장에 베이크 (구 자식 2스프라이트 대체).
    static func walkDustTexture() -> SKTexture {
        if let cached = R2BakeCache.walkDust { return cached }
        let size = walkDustTextureSize
        let side = FeelTuning.walkDustSquareSide
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.ganhoIngameWallShadow.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            ctx.fill(CGRect(x: size.width - side, y: 0, width: side, height: side))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        R2BakeCache.walkDust = texture
        return texture
    }
}
