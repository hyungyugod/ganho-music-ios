//
//  Typography.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 전역 폰트 이름 + 라벨 최소 축소 배율 (전역 타입 스케일만).
//

import Foundation
import CoreGraphics
import UIKit   // R3 — v3 폰트 fallback 해석(UIFont 존재 검사). 합격 기준상 유일 허용 기존 줄 인접 추가.

/// 전역 타이포그래피 토큰 — 폰트 패밀리 이름과 라벨 스케일 한계.
/// case 없는 enum: 인스턴스화 차단 (왜: 폰트 교체를 한 줄 변경으로 봉인).
enum Typography {
    // MARK: - Sprint 1 Design Foundation
    static let labelMinimumScale: CGFloat = 0.78

    // MARK: - Typography (Sprint 1 · v2 Design System)
    // DESIGN_RENEWAL_REQUEST.md §3.2 폰트 시스템.
    // ttf 파일 실제 임포트는 사용자 후속 작업(Xcode add to target + Info.plist UIAppFonts).
    // 본 상수는 *이름만* 정의 — SKLabelNode(fontNamed:)는 ttf 미존재 시 시스템 폰트로 자동 fallback,
    // 컴파일 및 런타임 모두 깨지지 않음.

    /// Display 폰트 — 타이틀·UI 강조 (Jua-Regular). 모든 타이틀, 버튼 텍스트, HUD 값.
    static let fontDisplay: String = "Jua-Regular"
    /// Body 폰트 — 본문·설명 (GowunDodum-Regular). 태그라인, 스킬 설명, 카드 부제.
    static let fontBody: String = "GowunDodum-Regular"
    /// Numeric 폰트 — 수치 표시 (NotoSansKR-Bold). 점수·시간 등 정렬 필요한 숫자.
    static let fontNumeric: String = "NotoSansKR-Bold"

    // MARK: - Sprint 5 · ResultScene v2 Layout
    // DESIGN_RENEWAL_REQUEST.md §4.5 + mockups/result-screen-v2.html.
    // Sprint 5는 *추가만* — Phase 8-4 resultPanel* 상수는 *유지*. v2 상수가 별도 이름으로 공존.

    /// 명조 폰트 — 졸업장 한·영 제목 + 본문 (GowunBatang-Regular).
    /// ttf 미존재 시 SKLabelNode가 시스템 폰트로 자동 fallback — 컴파일/런타임 모두 안전.
    static let fontSerif: String = "GowunBatang-Regular"

    // MARK: - Sprint 10 Phase G · Airforce Easter Egg Pixel Tone
    /// 픽셀 톤 오버레이 폰트 이름. PressStart2P 미설치 → Menlo-Bold 폴백.
    /// 원본 game.js 픽셀 톤 텍스트와 시각 정합 — 시스템 폰트(.systemFont)는 anti-alias로 톤 깨짐.
    static let pixelOverlayFontName: String = "Menlo-Bold"

    // MARK: - Cutscene (Sprint 10 Phase H — 원본 1:1 5종 컷씬 시스템)
    /// 픽셀 톤 컷씬 폰트 이름. pixelOverlayFontName(Menlo-Bold)와 동일 값 — Phase H 컷씬 5종 모두
    /// *픽셀 톤 시각 일관성* 확보. 별도 상수로 분리해 미래 컷씬 전용 폰트 교체 시 한 줄 변경.
    /// CutsceneOverlayNode.present(fontName:)로 1줄 1줄 주입 — 본체 logic 미변경(SPEC §12).
    static let pixelCutsceneFontName: String = "Menlo-Bold"

    // MARK: - Sprint 10 Phase J · Pixel HUD/Effect Tokens (마지막 Phase)
    //
    // 인게임 HUD/오버레이/이펙트의 폰트·이펙트 토큰을 메뉴(v2 카툰 fontDisplay)와 분리.
    // SPEC §17 byte-equal — 색은 ColorTokens.ganhoPixelHud*/Combo*/Outline*/Hit*/TensionEdge에서.

    /// 인게임 픽셀 톤 폰트(Menlo-Bold). pixelOverlayFontName/pixelCutsceneFontName와 동일 값이나
    /// *의미 분리* — HUD/이펙트 lookup 전용 별도 상수. 미래 PressStart2P 도입 시 한 줄 교체 안전.
    static let fontPixel: String = "Menlo-Bold"
}

// MARK: - R3 디자인 시스템 v3 "Night Shift" (03_UI §3)
//
// 픽셀 한글 폰트 Galmuri 도입 + fallback 체인. 기존 v2 상수(fontDisplay/fontBody/…)는 무변경.
// 인게임 HUD의 Menlo→Galmuri 교체는 R7로 이연 (SPEC 불일치 기록 9) — R3는 토큰 정의까지만.
extension Typography {
    /// v3 타입 토큰 — 토큰당 (fontName, size). 폰트 이름은 앱 수명 동안 정적 1회 해석.
    enum V3 {
        /// (폰트 이름, 크기) 쌍 — SKLabelNode(fontNamed: token.fontName) + fontSize = token.size.
        struct Token {
            let fontName: String
            let size: CGFloat
        }

        // 03_UI §3 표 그대로 — 7토큰.
        /// 로고타입 — StartScene 1줄 로고 전용 (Galmuri14 52pt).
        /// R4 신설 — 03_UI §6-1 수치 그대로 (SPEC §C-10: §3 표에 52pt 토큰 부재 → 추가만).
        static let logo = Token(fontName: galmuri14, size: 52)
        /// verdict 스탬프 — ResultScene "졸업!/유급…" 전용 (Galmuri14 56pt).
        /// R5 신설 — 03_UI §7 "display 56pt" (SPEC 기능 2: V3.display 44pt와 별도 신규 토큰).
        static let verdict = Token(fontName: galmuri14, size: 56)
        /// 씬 타이틀·verdict (Galmuri14 44pt).
        static let display = Token(fontName: galmuri14, size: 44)
        /// 카드 제목·점수 (Galmuri14 30pt).
        static let h1 = Token(fontName: galmuri14, size: 30)
        /// 섹션 제목 (Galmuri11 22pt).
        static let h2 = Token(fontName: galmuri11, size: 22)
        /// 본문·버튼 (Galmuri11 17pt).
        static let body = Token(fontName: galmuri11, size: 17)
        /// 칩·메타 (Galmuri9 13pt).
        static let caption = Token(fontName: galmuri9, size: 13)
        /// 긴 설명문 예외 — 스킬 인용문 등 2줄+ (GowunDodum 16pt). 체인 불필요 — 번들 보장 폰트.
        static let prose = Token(fontName: Typography.fontBody, size: 16)
        /// 인게임 점수 (Galmuri14 40pt). 실제 HUD 배선은 R7.
        static let hudScore = Token(fontName: galmuri14, size: 40)

        /// 줄간 — 폰트 크기 × 1.45 (03_UI §3).
        static let lineHeightMultiplier: CGFloat = 1.45

        // MARK: fallback 해석 (03_UI §3 — Galmuri → DungGeunMo → 번들 보장 폰트)
        // PostScript 이름은 2026-06-10 quiple/galmuri dist ttf에서 실측: "Galmuri14-Regular" 등
        // (full name "Galmuri14 Regular"). 최종 단계 Jua-Regular는 번들 보장 — 시스템 폰트 노출 0 (§11).

        /// Galmuri14 계열 해석 결과 (display/h1/hudScore).
        static let galmuri14: String = resolveFontName(
            candidates: ["Galmuri14-Regular", "Galmuri14", "DungGeunMo"],
            bundleGuaranteedFallback: Typography.fontDisplay
        )
        /// Galmuri11 계열 해석 결과 (h2/body).
        static let galmuri11: String = resolveFontName(
            candidates: ["Galmuri11-Regular", "Galmuri11", "DungGeunMo"],
            bundleGuaranteedFallback: Typography.fontDisplay
        )
        /// Galmuri9 계열 해석 결과 (caption).
        static let galmuri9: String = resolveFontName(
            candidates: ["Galmuri9-Regular", "Galmuri9", "DungGeunMo"],
            bundleGuaranteedFallback: Typography.fontDisplay
        )

        /// UIFont 존재 검사용 임시 크기 — 어떤 양수든 동작(이름 조회 목적).
        private static let fontProbeSize: CGFloat = 17

        /// 후보를 순서대로 UIFont(name:size:) 검사해 첫 가용 이름 채택 — 정적 1회 해석.
        /// 전부 실패 시 번들 보장 폰트로 종착 (시스템 폰트 노출 없음 — §11).
        private static func resolveFontName(candidates: [String],
                                            bundleGuaranteedFallback: String) -> String {
            for name in candidates where UIFont(name: name, size: fontProbeSize) != nil {
                #if DEBUG
                print("[Typography.V3] 폰트 해석: \(candidates.first ?? "?") → \(name)")
                #endif
                return name
            }
            #if DEBUG
            print("[Typography.V3] 폰트 해석 실패 — fallback: \(bundleGuaranteedFallback)")
            #endif
            return bundleGuaranteedFallback
        }
    }
}
