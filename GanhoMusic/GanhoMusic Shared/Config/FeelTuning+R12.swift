//
//  FeelTuning+R12.swift
//  GanhoMusic Shared
//
//  R12 — 게임필 2차 + 오디오·아이덴티티: 신규 SFX Voice 4종 길이 토큰 + 목표 달성(#7)
//  골드 플래시 토큰. 주파수는 기존 FeelTuning.sfxMidi* 재사용 (신규 주파수 0).
//  R5/R7/R10 nested enum 컨벤션 답습.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R12 연출·SFX 튜닝 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R12 {
        // MARK: [B] 신규 Voice 4종 (ChiptuneSynth — init 사전 렌더 전용, 런타임 합성 0)
        /// 스킬 발동 기합 — square 상행 2음 C5→G5. 첫음 길이 (초).
        static let sfxSkillActivateFirstToneDuration: TimeInterval = 0.060
        /// 스킬 발동 기합 — 끝음 길이 (초). 총 0.06+0.09 = 150ms.
        static let sfxSkillActivateSecondToneDuration: TimeInterval = 0.090
        /// 목표 달성 팡파레 — triangle 아르페지오 4음(C5-E5-G5-C6) 음당 길이 (초).
        /// 총 4×90 = 360ms — comboMilestone(3음 180ms)보다 길고 화려.
        static let sfxGoalFanfareToneDuration: TimeInterval = 0.090
        /// near-miss "아슬!" — square 상행 글라이드 C6→G6, 80ms (휙 스침 톤).
        static let sfxNearMissDuration: TimeInterval = 0.080
        /// 졸업 스팅어 — triangle 상행 3음 C5→G5→C6 길이 (초). 총 0.08+0.12+0.20 = 400ms.
        static let sfxGraduationStingFirstToneDuration: TimeInterval = 0.080
        static let sfxGraduationStingSecondToneDuration: TimeInterval = 0.120
        static let sfxGraduationStingThirdToneDuration: TimeInterval = 0.200

        // MARK: #7 목표 달성 골드 풀스크린 플래시 (BombFlashNode 동형 — 텍스처 0·자가 소멸)
        /// 플래시 정점 알파. hitFlash(0.55)보다 절제 — 축하 톤, 시야 차단 0.
        static let goalFlashPeakAlpha: CGFloat = 0.35
        /// 플래시 fadeIn 길이 (초) — *번쩍* 임팩트.
        static let goalFlashFadeInDuration: TimeInterval = 0.06
        /// 플래시 fadeOut 길이 (초) — *잔향*. 총 노출 0.36s.
        static let goalFlashFadeOutDuration: TimeInterval = 0.30
    }
}
