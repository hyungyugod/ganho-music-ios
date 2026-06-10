//
//  ObjectPool.swift
//  GanhoMusic Shared
//
//  R1 · 생성/파괴가 반복되는 동적 노드의 재사용 풀 + Poolable 계약.
//  설계서: refactor/01_CODE_ARCHITECTURE.md §8 (프로토콜 동거 — 설계서가 한 묶음으로 제시).
//

import SpriteKit

/// 풀에 보관됐다 재사용되는 노드의 계약.
/// 재사용 노드는 신품과 동일 상태여야 한다 — 잔존 SKAction(TTL/pull 등)·alpha·scale·velocity·
/// 자식 노드 상태 같은 *이전 사용 흔적*을 전부 지울 책임이 구현체에 있다.
protocol Poolable: AnyObject {
    /// 풀 보관 직전(recycle 내부) 호출. 호출 후 노드는 신품 init 직후와 동일 상태.
    func resetForReuse()
}

/// SKNode 재사용 풀.
/// 왜: F/음표/청진기/점수팝업은 45초 동안 수십 회 생성·파괴되는데, 노드+physicsBody 생성과
/// ARC 해제 비용이 프레임 스파이크의 원인 — 보관/재사용으로 비용을 평탄화한다(R2 juice의 바닥).
/// 소유: GameScene 인스턴스(씬과 함께 해제 — static 풀 금지, stale scene 참조 차단).
/// 보관 노드는 항상 removeFromParent 상태(부모 없음) — alpha=0 좀비 패턴 금지 규칙 준수.
final class ObjectPool<T: SKNode & Poolable> {

    // MARK: - Storage
    private var storage: [T] = []
    private let factory: () -> T

    #if DEBUG
    /// 재사용 확인 카운터 — R1 합격 게이트 "풀 재사용 로그" 증빙용. 릴리즈 빌드 미포함.
    private var reuseCount: Int = 0
    #endif

    // MARK: - Lifecycle
    /// - Parameter factory: 풀이 비었을 때 신품을 만드는 클로저.
    ///   self/씬 캡처 없는 순수 생성만 전달할 것(풀-씬 순환 참조 차단).
    init(factory: @escaping () -> T) {
        self.factory = factory
    }

    /// didMove 직후 1회 예열 — 첫 스폰 웨이브의 생성 스파이크 제거.
    /// 보관 수가 이미 count 이상이면 noop(멱등).
    func preheat(count: Int) {
        guard count > storage.count else { return }
        for _ in storage.count..<count {
            let node = factory()
            node.resetForReuse()
            storage.append(node)
        }
    }

    // MARK: - Obtain / Recycle
    /// 보관분이 있으면 재사용, 없으면 factory로 신품 생성.
    func obtain() -> T {
        if let node = storage.popLast() {
            #if DEBUG
            reuseCount += 1
            print("[ObjectPool] \(T.self) 재사용 #\(reuseCount) (보관 잔여 \(storage.count))")
            #endif
            return node
        }
        return factory()
    }

    /// 회수: removeFromParent → resetForReuse → 보관 (설계서 §8 순서).
    /// idempotent — 같은 노드가 두 경로(벽 충돌 + TTL 만료, purge + contact 등)로 들어와도
    /// 중복 보관 0 (identity 검사). 보관 수 상한은 두지 않음 — 동시 캡이 자연 상한.
    func recycle(_ node: T) {
        guard !storage.contains(where: { $0 === node }) else { return }
        node.removeFromParent()
        node.resetForReuse()
        storage.append(node)
    }
}
