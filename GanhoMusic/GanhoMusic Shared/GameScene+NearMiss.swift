//
//  GameScene+NearMiss.swift
//  GanhoMusic Shared
//
//  R7 §F2 — near-miss 보너스 폴링 / R8 P1-1 — 판정 기준을 중심거리 22px → 충돌 히트박스
//  가장자리(민코프스키 확장 AABB) 10px 셸로 retune (구 기준은 대각 사각지대로 발화 불능).
//  update 파이프라인 "projectiles 슬롯" 전속 — 콤보 타이머(게임 수치)를 바꾸므로
//  effects 단계("수치 무변경" 계약) 배속 금지 (SPEC 주의 2).
//  DangerWarnings의 거리 계산과 중복 순회(프레임당 registry 2회)는 수십 개 규모라 허용 —
//  통합 최적화 금지 (계약 혼합 위험, SPEC 주의 2).
//

import SpriteKit

/// R7 §F2 — near-miss 추적 상태 보유 투사체 (F·청진기 공용 폴링 윈도우).
/// stored property는 각 노드 본체가 선언 (extension 불가) — 본 프로토콜은 루프 공용화 전용.
protocol NearMissTrackable: AnyObject {
    /// 히트박스 가장자리 10px 셸 진입 여부. 비무적 상태 진입 프레임에 set.
    var nearMissEntered: Bool { get set }
    /// 보상 부여 완료 — 투사체 1개당 1회 상한.
    var nearMissAwarded: Bool { get set }
    var position: CGPoint { get }
    /// R8 — 충돌 히트박스 절반 크기 (민코프스키 확장 입력). computed — 전부 GameplayTuning
    /// 기존 상수 참조, 신규 수치 0.
    var nearMissHalfExtents: CGSize { get }
}

extension FProjectileNode: NearMissTrackable {
    var nearMissHalfExtents: CGSize {
        CGSize(width: GameplayTuning.fProjectileSize / 2,
               height: GameplayTuning.fProjectileSize / 2)
    }
}

extension StethoscopeNode: NearMissTrackable {
    var nearMissHalfExtents: CGSize {
        CGSize(width: GameplayTuning.stethoscopeWidth / 2,
               height: GameplayTuning.stethoscopeHeight / 2)
    }
}

// MARK: - Near-miss Bonus Polling (R7 §F2 / R8 가장자리 셸)
extension GameScene {

    /// 매 프레임 projectiles 슬롯에서 호출. registry 배열 직접 순회 — update 내 힙 할당 0.
    /// hitstop tick early-return·.playing 가드 *뒤*라 동결·일시정지 중 폴링 자동 차단 (SPEC 주의 4).
    func updateNearMissBonusPhase() {
        let band = FeelTuning.R7.nearMissEdgeBand
        let bandSquared = band * band
        let playerPosition = player.position
        let playerInvulnerable = player.isInvulnerable
        for projectile in registry.projectiles {
            // 매혹 F는 수집물 — 회피 보상 비대상 (SPEC §F2 isEnchanted 제외).
            // 보류 플래그도 무효화 — 매혹 해제 후 셸 밖 이탈이 오발 보상으로 새는 엣지 차단.
            if projectile.isEnchanted {
                projectile.nearMissEntered = false
                continue
            }
            trackNearMiss(projectile, playerPosition: playerPosition,
                          bandSquared: bandSquared, playerInvulnerable: playerInvulnerable)
        }
        for stethoscope in registry.stethoscopes {
            trackNearMiss(stethoscope, playerPosition: playerPosition,
                          bandSquared: bandSquared, playerInvulnerable: playerInvulnerable)
        }
    }

    /// 판정 규칙 (SPEC §F2 계약 보존 + R8 기하 교체 — evaluator 검증 기준):
    /// - 기하: 충돌 히트박스 가장자리 기준 10px 셸. 민코프스키 확장 AABB(플레이어 절반 +
    ///   투사체 절반)로부터의 바깥 거리(ex, ey)가 셸 안이면 "스침" — 축정렬·대각 전방위 균일
    ///   (구 22px 중심거리의 대각 사각지대 해소). 충돌 자체(ex=ey=0)도 셸 내부로 포함되지만
    ///   피격은 physics contact가 먼저 처리 — 판정 우선순위 무변경.
    /// - 진입: 셸 내 + 비무적 프레임에 entered set. 무적 중 진입분은 제외 (스킬 무적 통과 ≠ 회피).
    ///   동결(frozen)은 피격 가능 상태라 별도 가드 없음 — 포함.
    /// - 부여: entered 선 투사체가 셸 *밖으로 이탈*한 프레임 1회. 셸 안에서 회수(피격·벽·TTL)
    ///   되면 이탈 프레임이 없어 자연 미부여 (보수적) — 풀 복원(resetForReuse)이 플래그 리셋.
    private func trackNearMiss(_ node: NearMissTrackable, playerPosition: CGPoint,
                               bandSquared: CGFloat, playerInvulnerable: Bool) {
        // 민코프스키 확장 AABB 바깥 거리 — 0이면 히트박스 접촉/관통 (update 내 힙 할당 0).
        let ex = max(0, abs(node.position.x - playerPosition.x)
                        - (GameplayTuning.playerWidth / 2 + node.nearMissHalfExtents.width))
        let ey = max(0, abs(node.position.y - playerPosition.y)
                        - (GameplayTuning.playerHeight / 2 + node.nearMissHalfExtents.height))
        if ex * ex + ey * ey <= bandSquared {
            if !playerInvulnerable {
                #if DEBUG
                // 진입(보류) 로그 — "진입 후 셸 내 회수 = 미부여" 보수 판정의 QA 식별용.
                if !node.nearMissEntered {
                    print("[NearMiss] 셸 진입 (보류 — 이탈 시 부여)")
                }
                #endif
                node.nearMissEntered = true
            }
            return
        }
        guard node.nearMissEntered, !node.nearMissAwarded else { return }
        node.nearMissAwarded = true
        awardNearMissBonus()
    }

    /// 보상 3종 — ① 콤보 윈도우 연장(이벤트마다, combo 0이면 ScoreSystem이 noop)
    /// ② "아슬!" 마이크로 팝업 ③ nearMiss 햅틱. ②③은 0.25s 쿨다운 내 1회 (스팸 가드).
    private func awardNearMissBonus() {
        scoreSystem.extendComboWindow(at: lastUpdateTime)
        #if DEBUG
        // R7 시각 증빙 게이트 ② — 시뮬 콘솔 발화 로그 (릴리즈 미포함).
        let elapsed = GameplayTuning.gameDuration - remainingTime
        print("[NearMiss] 아슬! combo=\(scoreSystem.combo) elapsed=\(String(format: "%.2f", elapsed))s")
        #endif
        guard lastUpdateTime - lastNearMissFeedbackAt >= FeelTuning.R7.nearMissFeedbackCooldown else {
            return
        }
        lastNearMissFeedbackAt = lastUpdateTime
        // 기존 ToastLabelNode 재사용 (신규 텍스처 생성 금지) — 자가 소멸 노드라 좀비 0.
        ToastLabelNode.spawn(
            text: UILayout.R7.nearMissPopupText,
            at: CGPoint(x: player.position.x,
                        y: player.position.y + UILayout.R7.nearMissPopupOffsetY),
            parent: worldNode
        )
        haptics.nearMiss()
    }
}
