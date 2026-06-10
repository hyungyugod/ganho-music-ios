//
//  FeelTuning+R3.swift
//  GanhoMusic Shared
//
//  R3 디자인 시스템 v3 "Night Shift" — 모션 토큰 (03_UI §9) + 전환 SFX·배경 보조 타이밍.
//  수치 원칙: 03_UI §9 표 그대로. 표 외 보조 수치는 SPEC 주의사항 9 재량 범위.
//

import Foundation
import CoreGraphics

// MARK: - R3 모션·전환 상수 (03_UI §9)
extension FeelTuning {

    /// v3 모션 표준 — 시간 토큰. 커브는 주석의 Tween.Curve를 호출부에서 `Tween.curved(_:_:)`로 적용.
    enum Motion {
        /// 버튼 눌림 — linear (§9 표가 linear 명시 — R2 "linear 금지" 규칙의 설계서 예외).
        static let buttonPress: TimeInterval = 0.06
        /// 카드 선택 — Tween.Curve.easeOutBack.
        static let cardSelect: TimeInterval = 0.18
        /// 요소 등장 — Tween.Curve.easeOutCubic.
        static let appear: TimeInterval = 0.22
        /// 등장 stagger 60ms (03_UI §1 원칙 4 "staggered 60ms").
        static let appearStagger: TimeInterval = 0.06
        /// 다이얼로그 등장/퇴장 — Tween.Curve.easeOutCubic.
        static let dialog: TimeInterval = 0.22
        /// 씬 전환 (SceneRouter push). 커브 easeInOutQuad는 §9 요구이나 시스템 전환 API가
        /// 타이밍 함수 주입 불가(고정 곡선) — duration 0.35만 준수 (SPEC 불일치 기록 10).
        static let sceneTransition: TimeInterval = 0.35
        /// 인게임 진입 픽셀 디졸브 — 8px 블록 체커가 걷히는 시간 (§9).
        static let pixelDissolve: TimeInterval = 0.4
    }

    // MARK: 전환 SFX (02_GAME_FEEL §6 표 외 신규 — 03_UI §9 "전환 SFX 동반" 요구, SPEC 기능 4)
    /// sceneTransition voice 길이 (초). 요구 상한 0.2s 이하 — 짧은 상행 스윕.
    static let sfxSceneTransitionDuration: TimeInterval = 0.12

    // MARK: v3 진행바 채움 (03_UI §7 시퀀스 4 "XP 바 증가 0.5s" 선행 정의 — R5 배선)
    /// PixelProgressBarNode.setProgress(animated:) 채움 애니 길이 (초).
    static let v3ProgressFillDuration: TimeInterval = 0.5

    // MARK: v3 공통 배경 보조 타이밍 (03_UI §4 — NightShiftBackdropNode)
    /// 심전도 펄스 루프 주기 (초) — "8초 루프당 좌→우 펄스 1회".
    static let v3BackdropEKGLoopDuration: TimeInterval = 8.0
    /// 펄스가 좌→우로 가로지르는 시간 (초). 루프 주기 내 이동 구간.
    static let v3BackdropEKGPulseTravelDuration: TimeInterval = 1.6
    /// 스타필드 트윙클 한 사이클 최소/최대 길이 (초) — 개별 점이 무작위로 받음.
    static let v3BackdropTwinkleMinDuration: TimeInterval = 0.8
    static let v3BackdropTwinkleMaxDuration: TimeInterval = 2.4
    /// 트윙클 alpha 하한/상한 — 미세 반짝임 (소멸 아님 — repeatForever 루프).
    static let v3BackdropStarAlphaLow: CGFloat = 0.15
    static let v3BackdropStarAlphaHigh: CGFloat = 0.55
}
