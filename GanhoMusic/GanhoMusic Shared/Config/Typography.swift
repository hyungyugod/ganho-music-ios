//
//  Typography.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 전역 폰트 이름 + 라벨 최소 축소 배율 (전역 타입 스케일만).
//

import Foundation
import CoreGraphics

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
