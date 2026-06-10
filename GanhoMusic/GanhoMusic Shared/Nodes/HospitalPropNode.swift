//
//  HospitalPropNode.swift
//  GanhoMusic Shared
//
//  Sprint 6 - Visual-only hospital props.
//  R2 - 자식 셰이프(침대 3 / 커튼 5 / 캐비닛 3 / 카트 5)를 TextureAtlasStore 베이크 1장으로 통합 —
//       소품당 4~6노드 → 1노드 (hard 평시 노드 게이트). 색·비율·선폭·알파는 구 자식 상수 그대로.
//

import SpriteKit

enum HospitalPropKind {
    case bed
    case curtain
    case cabinet
    case cart
}

/// 병실 분위기를 보강하는 충돌 없는 시각 전용 소품 — 베이크 텍스처 단일 스프라이트.
final class HospitalPropNode: SKSpriteNode {

    // MARK: - Init
    init(kind: HospitalPropKind, size: CGSize) {
        let texture = TextureAtlasStore.hospitalPropTexture(kind: kind, size: size)
        super.init(texture: texture, color: .clear,
                   size: TextureAtlasStore.hospitalPropBakedSize(kind: kind, size: size))
        name = "hospitalProp"
        zPosition = ZOrder.hospitalPropZPosition
    }

    @available(*, unavailable, message: "Use init(kind:size:) instead.")
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
