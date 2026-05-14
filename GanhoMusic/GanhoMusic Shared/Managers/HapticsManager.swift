//
//  HapticsManager.swift
//  GanhoMusic Shared
//
//  Phase 6-1 · 시스템 햅틱 피드백 캡슐화 (Manager 패턴 첫 등장)
//  Phase 6-11 · medium() 추가 — 콤보 마일스톤 x10 황금기 전용 (3감각 완성 sprint 2/2)
//

import UIKit

/// 시스템 햅틱 발생기를 캡슐화한 매니저.
/// - light(): 노트 수집 등 가벼운 긍정 피드백
/// - medium(): 콤보 마일스톤 x10(황금기) 전용 중간 강도 (Phase 6-11)
/// - heavy(): 게임오버 등 묵직한 종료 피드백
/// 시뮬레이터/햅틱 미지원 디바이스에서는 UIKit이 자동 noop 처리.
/// Spring 비유: side-effect 책임을 가진 @Service 빈. Repository(영속 책임)와 대비.
final class HapticsManager {

    // MARK: - Properties
    private let lightGenerator: UIImpactFeedbackGenerator
    private let mediumGenerator: UIImpactFeedbackGenerator   // Phase 6-11 — light/heavy 사이 중간 톤
    private let heavyGenerator: UIImpactFeedbackGenerator

    // MARK: - Init
    init() {
        lightGenerator  = UIImpactFeedbackGenerator(style: .light)
        mediumGenerator = UIImpactFeedbackGenerator(style: .medium)   // Phase 6-11
        heavyGenerator  = UIImpactFeedbackGenerator(style: .heavy)
        // 첫 트리거 지연 최소화를 위해 미리 워밍
        lightGenerator.prepare()
        mediumGenerator.prepare()   // Phase 6-11 — light/heavy와 동형 캐시 워밍 패턴
        heavyGenerator.prepare()
    }

    // MARK: - Triggers
    /// 가벼운 톡. 노트 수집 시 호출. 직후 prepare()로 다음 호출 대비.
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Phase 6-11 — 콤보 마일스톤 x10(황금기) 전용 중간 강도. 직후 prepare()로 다음 호출 대비.
    /// light/heavy 사이 강도는 Apple 표준이라 별도 튜닝 불필요.
    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// 묵직한 한 방. 게임오버 시 호출. 직후 prepare()로 다음 호출 대비.
    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
}
