//
//  FeelTuning+R4.swift
//  GanhoMusic Shared
//
//  R4 메뉴 씬 재구축 — 모션 보조 토큰 (SPEC §D 신규).
//  Motion 7토큰(FeelTuning+R3)은 그대로 소비하고, R4 씬 전용 보조 타이밍·알파만 추가.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R4 메뉴 모션 보조 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R4 {
        // MARK: StartScene (§F-1)
        /// 김간호 대형 픽셀 idle bob 한 사이클 길이 (2프레임 교차).
        static let heroBobCycle: TimeInterval = 0.6
        /// "▶ 탭하여 시작" 블링크 한 사이클 길이 (fadeAlpha 루프 — 시각 펄스, 소멸 아님).
        static let tapToStartBlinkCycle: TimeInterval = 1.2
        /// 블링크 하한 alpha — 0 금지(좀비 오인 방지 + 가독 유지).
        static let tapToStartBlinkLowAlpha: CGFloat = 0.3

        // MARK: CharacterSelectScene (§F-2)
        /// 좌측 풀바디 프리뷰 walk 2프레임 교차 — 프레임당 길이 (한 사이클 = ×2).
        static let previewStepDuration: TimeInterval = 0.3
        /// 캐러셀 미선택 카드 dim alpha (선택 카드 1.0 대비).
        static let carouselDimAlpha: CGFloat = 0.55
        /// 캐러셀 카드 슬라이드(선택 이동) 길이 — easeOutCubic.
        static let carouselSlideDuration: TimeInterval = 0.22

        // MARK: SkillBriefingScene (§F-3)
        /// 좌측 카드 뒤집힘 등장 — xScale 0→1 (03_UI §6-3 "카드 뒤집힘 0.3s").
        static let cardFlipIn: TimeInterval = 0.3

        // MARK: DifficultySelectScene (§F-4)
        /// 미선택 난이도 카드 dim alpha.
        static let difficultyDimAlpha: CGFloat = 0.55
    }
}
