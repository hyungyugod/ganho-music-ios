//
//  HapticsManager.swift
//  GanhoMusic Shared
//
//  Phase 6-1 · 시스템 햅틱 피드백 캡슐화 (Manager 패턴 첫 등장)
//

import UIKit

/// 시스템 햅틱 발생기를 캡슐화한 매니저.
/// - light(): 노트 수집 등 가벼운 긍정 피드백
/// - heavy(): 게임오버 등 묵직한 종료 피드백
/// 시뮬레이터/햅틱 미지원 디바이스에서는 UIKit이 자동 noop 처리.
/// Spring 비유: side-effect 책임을 가진 @Service 빈. Repository(영속 책임)와 대비.
final class HapticsManager {

    // MARK: - Properties
    private let lightGenerator: UIImpactFeedbackGenerator
    private let heavyGenerator: UIImpactFeedbackGenerator

    // MARK: - Init
    init() {
        lightGenerator = UIImpactFeedbackGenerator(style: .light)
        heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        // 첫 트리거 지연 최소화를 위해 미리 워밍
        lightGenerator.prepare()
        heavyGenerator.prepare()
    }

    // MARK: - Triggers
    /// 가벼운 톡. 노트 수집 시 호출. 직후 prepare()로 다음 호출 대비.
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// 묵직한 한 방. 게임오버 시 호출. 직후 prepare()로 다음 호출 대비.
    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
}
