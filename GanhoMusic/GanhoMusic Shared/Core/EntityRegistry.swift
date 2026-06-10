//
//  EntityRegistry.swift
//  GanhoMusic Shared
//
//  R1 · 동적 엔티티 3종(F 투사체·음표·청진기)의 카운트/순회 캐시.
//  설계서: refactor/01_CODE_ARCHITECTURE.md §7.
//

import SpriteKit

/// 매 프레임 `enumerateChildNodes(withName:)` 트리 순회를 대체하는 동적 엔티티 캐시.
/// 왜: DangerWarnings가 프레임당 2회 + F 발사 캡 검사(update 경로) 등이 수시로 전체 노드
/// 트리를 이름으로 순회했다 — 후반 하드 탄막(F 22 + 청진기 8)에서 트리가 클수록 비용이 커진다.
/// 등록 배열 직접 순회/카운트로 비용을 엔티티 수에만 비례하게 고정한다.
/// 소유: GameScene 인스턴스 1개(씬 생애주기 동일 — static 금지, stale 참조 차단).
/// 등록/해제는 풀 경유 spawn(obtain→register→addChild)/회수(unregister→recycle)의 원자 쌍이 담당.
final class EntityRegistry {

    // MARK: - Caches
    /// 활성 F 투사체. 매혹된 F 포함 — 구 name="projectile" enumerate와 동일 시맨틱
    /// (매혹 F도 name 유지, AItemNode는 별도 타입이라 자연 비포함).
    private(set) var projectiles: [FProjectileNode] = []
    /// 활성 음표.
    private(set) var notes: [NoteNode] = []
    /// 활성 청진기.
    private(set) var stethoscopes: [StethoscopeNode] = []

    // MARK: - Register / Unregister
    /// spawn 시 호출. idempotent — 이미 등록된 노드의 재등록은 noop(중복 카운트 사고 차단).
    /// 등록 3타입 외 노드는 무시 — SKNode 시그니처는 설계서 §7 계약(호출부 분기 없는 단일 진입점).
    func register(_ node: SKNode) {
        if let projectile = node as? FProjectileNode {
            if !projectiles.contains(where: { $0 === projectile }) {
                projectiles.append(projectile)
            }
        } else if let note = node as? NoteNode {
            if !notes.contains(where: { $0 === note }) {
                notes.append(note)
            }
        } else if let stethoscope = node as? StethoscopeNode {
            if !stethoscopes.contains(where: { $0 === stethoscope }) {
                stethoscopes.append(stethoscope)
            }
        }
    }

    /// 회수 시 호출. idempotent — 미등록 노드 해제는 noop
    /// (이중 회수 경로: 벽 충돌 + TTL 만료가 같은 노드를 두 번 해제해도 안전).
    func unregister(_ node: SKNode) {
        if let projectile = node as? FProjectileNode {
            projectiles.removeAll { $0 === projectile }
        } else if let note = node as? NoteNode {
            notes.removeAll { $0 === note }
        } else if let stethoscope = node as? StethoscopeNode {
            stethoscopes.removeAll { $0 === stethoscope }
        }
    }

    // MARK: - Compact
    /// 부모를 잃었는데 unregister가 누락된 참조의 안전망 청소 — GameScene.update 말미 프레임당 1회.
    /// 정상 회수 경로(unregister → recycle)에서는 제거 대상 0건. 풀 보관 노드는 항상
    /// unregister가 선행되므로 여기 잡히지 않는다. n ≤ 동시 캡(≈46) — 스캔 비용 무시 가능.
    func compact() {
        projectiles.removeAll { $0.parent == nil }
        notes.removeAll { $0.parent == nil }
        stethoscopes.removeAll { $0.parent == nil }
    }
}
