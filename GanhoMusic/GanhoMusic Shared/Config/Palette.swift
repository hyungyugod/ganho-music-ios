//
//  Palette.swift
//  GanhoMusic Shared
//
//  R0 — 구 god-config(분할 전 단일 Config) 분해: 색 hex 문자열 + UIColor 인스턴스 상수.
//  값은 분할 전과 byte-equal. R3에서 v3 토큰으로 대체 예정.
//

import UIKit

/// 색 팔레트 네임스페이스 — hex 문자열·UIColor 상수의 단일 진실 원천.
/// case 없는 enum: 인스턴스화 차단 (왜: R3 팔레트 교체 시 단일 수정점).
enum Palette {
    // MARK: - Wall Tile (Runtime Compact)
    // WallTileNode 1셀(28×28pt) 색·zPos·이름 단일 진실 원천.
    // 단일 진실 원천: docs/ORIGINAL_GAME_ANALYSIS.md §1.3 + L84 (#2a2233 hex).
    // physicsBody 정책은 WallTileNode 본체에서 단일 응집(주의사항 11).

    /// 벽 셀 색(hex). 원본 픽셀 톤 — 옛 navyDeep을 본 Phase부터 대체.
    static let wallTileColorHex: String = "#2a2233"

    // MARK: - Checkerboard Floor (Phase 9-4)
    /// 체크보드 바닥 — 640개(32×20) SKSpriteNode를 컨테이너 한 개에 묶어 worldNode에 부착.
    /// physicsBody 0 부착(시각 전용). setupWorld()에서 1회만 빌드 → update() 안 호출 금지.

    /// 체크보드 floorA hex(피치 밝은 칸) — Sprint 3 v2: 웜 피치 톤. 메뉴 그라데이션과 자연 연속.
    /// (was #1a1722 다크 차콜 — Sprint 3에서 v2 디자인 시스템 통합)
    static let checkerboardFloorAHex: String = "#FFEFE0"
    /// 체크보드 floorB hex(피치 어두운 칸) — Sprint 3 v2: 살짝 더 짙은 피치 톤.
    /// (was #13111a 다크 차콜 — Sprint 3에서 v2 디자인 시스템 통합)
    static let checkerboardFloorBHex: String = "#FFDFC8"

    // MARK: - Tone Down Controls
    static let menuSolidBackgroundColor: UIColor = .ganhoPaper

    // MARK: - Sprint 5 · ResultScene v2 Layout
    /// 우드컷 도트 색 hex. mockup #FFEDC6 (종이 농염).
    static let diplomaDotHex: String = "#FFEDC6"

    // MARK: - Nurse Chief Patrol (Sprint 10 Phase D)
    /// 텔레그래프 ! 색. 원본 game.js L961 (#ff3b4e) byte-equal.
    static let nurseChiefTelegraphColor: UIColor = UIColor(
        red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x4E / 255.0, alpha: 1.0
    )

    // MARK: - F Projectile Visual (Sprint 10 Phase D)
    /// F 색. 원본 game.js L791 (#ff3b4e) byte-equal — telegraph와 동색 (danger 톤).
    static let fProjectileColor: UIColor = UIColor(
        red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x4E / 255.0, alpha: 1.0
    )
    /// A 색. 원본 game.js drawAItem (#ff6fa8) byte-equal — 분홍 매혹 톤.
    static let aItemColor: UIColor = UIColor(
        red: 0xFF / 255.0, green: 0x6F / 255.0, blue: 0xA8 / 255.0, alpha: 1.0
    )

    // MARK: - R2 캐릭터 시그니처 컬러 (02_GAME_FEEL §9 — PixelPalette 전용 키 추출값, SPEC §기능 9 고정)
    /// 캐릭터별 대표색. R2 사용처: skillSignature 파티클. R4 사용처: 선택창 글로우.
    /// switch exhaustive — default 금지 (신규 캐릭터 추가 시 컴파일러가 매핑 강제).
    static func character(_ id: CharacterID) -> UIColor {
        switch id {
        case .kim:  return UIColor(hex: "#5a4230")   // ganhoPixelBunShadow 'b' — 번머리 브라운
        case .jung: return UIColor(hex: "#c44a3d")   // ganhoPixelHatJung 'Z' — 러닝캡 적홍
        case .geon: return UIColor(hex: "#8a5a32")   // ganhoPixelBookCover 'O' — 책 표지 브라운
        case .im:   return UIColor(hex: "#ff9db0")   // ganhoPixelCatEar 'T' — 고양이귀 핑크
        case .lee:  return UIColor(hex: "#b07a58")   // ganhoPixelDogEar 'D' — 강아지귀 탠
        }
    }

    /// R2 — comboAura 10+ 단계 색 (violet 토큰 부재로 신설, SPEC §문서-코드 불일치 6 제안값).
    static let comboAuraViolet: UIColor = UIColor(hex: "#9B5DE5")

    // MARK: - Design Sprint 1 Ingame Readability
    static let ingameFloorAHex: String = "#494E78"
    static let ingameFloorBHex: String = "#2C2E4A"
    static let ingameWallFillHex: String = "#1A1B2E"
    static let ingameWallHighlightHex: String = "#7DCFB6"
    static let ingameWallShadowHex: String = "#0F0F1A"
    static let ingameDangerHex: String = "#D8315B"
    static let ingameDangerDeepHex: String = "#A4243B"
    static let ingameRewardHex: String = "#FFD23F"
    static let ingameRewardMintHex: String = "#7DCFB6"
    static let ingameControlFillHex: String = "#F4F1DE"
    static let ingameControlPressedHex: String = "#FFD23F"
    static let ingameControlDisabledHex: String = "#6C6C7A"
}

// MARK: - Sprint 10 Phase G · Airforce Pixel Palette (inline UIColor — ColorTokens 본체 0줄)
// SPEC §11 "대안" — ColorTokens 본체 변경 0줄 위해 같은 모듈 내 UIColor extension으로 우회.
// Phase E 변기 패턴(stethoscopePalette inline literal) 동형. 호출부는 .ganhoPixelPlaneBody 등 .자 접근.
// 상단 import UIKit(line 13) 재사용 — 같은 파일이므로 추가 import 0.

extension UIColor {
    /// 비행기 동체 본색 — 원본 game.js L3334 'A' #aab3c7. 항공기 메탈 회색 톤.
    static let ganhoPixelPlaneBody = UIColor(hex: "#aab3c7")
    /// 비행기 조종석 창문 — 원본 game.js L3334 'W' #e2e7ef. 밝은 청회 광택.
    static let ganhoPixelPlaneWindow = UIColor(hex: "#e2e7ef")
    /// 폭탄 화면 플래시 본색 — 누런 흰색. 원본 game.js 폭탄 saturation 1.3 톤 환산.
    /// 순백(#ffffff) 대신 #fffce0 — 따뜻한 섬광(폭발) 정체성.
    static let ganhoPixelFlashWhite = UIColor(hex: "#fffce0")
    /// "나와라 박병장!" 픽셀 톤 경고색 — 골드(#FFD23F). ganhoYellowF와 hex 동일하나 *의미 단위 분리*
    /// (픽셀 오버레이 lookup용) — Difficulty/Brand 토큰 분리 규칙 동형.
    static let ganhoPixelWarning = UIColor(hex: "#FFD23F")
}

// MARK: - R3 디자인 시스템 v3 "Night Shift" (03_UI §2)
//
// 사용 규칙: v3 UI에서 hex 직접 사용 금지 — 반드시 Palette 토큰 경유.
// SKEffectNode 블러 글로우 금지(성능) — 액센트색 alpha 0.30 사각 1장 (glowAlpha/glowScale).
// 기존 v2 상수는 무변경 — v3 토큰은 *추가만* (R3 합격 게이트).
extension Palette {
    // 잉크 베이스 (다크) — 씬 배경 → 패널 → 카드/버튼 표면 → 눌림 표면 순.
    /// 씬 배경. ★표 설계서 주장(구 ganhoUIBg)과 달리 코드에 전례 없음 — 신규 값 (SPEC 불일치 기록 2).
    static let ink900: UIColor = UIColor(hex: "#0F0E15")
    /// 패널 배경.
    static let ink800: UIColor = UIColor(hex: "#171A26")
    /// 카드·버튼 표면.
    static let ink700: UIColor = UIColor(hex: "#232838")
    /// 호버/눌림 표면.
    static let ink600: UIColor = UIColor(hex: "#2E3447")
    /// 기본 보더 2px.
    static let line500: UIColor = UIColor(hex: "#3A4154")

    // 텍스트
    /// 주 텍스트 ★(ganhoPixelHudWhite #FFFCE0 계승).
    static let textHi: UIColor = UIColor(hex: "#FFFCE0")
    /// 보조 텍스트.
    static let textLo: UIColor = UIColor(hex: "#9BA3B8")

    // 액센트 — 코랄(브랜드·위험·hard) / 골드(점수·별·normal) / 민트(성공·심전도·easy) / 바이올렛(스킬·레어·콤보 10+)
    /// 브랜드·위험·hard ★(ganhoPixelHudCoral 계승).
    static let coral: UIColor = UIColor(hex: "#FF6E5A")
    /// coral 하드섀도 ★(ganhoCoralShadow/ganhoPixelHatJung 계승).
    static let coralDeep: UIColor = UIColor(hex: "#C44A3D")
    /// 점수·별·normal ★(ganhoPixelHudYellow/ganhoYellowF 계승).
    static let gold: UIColor = UIColor(hex: "#FFD23F")
    /// gold 하드섀도.
    static let goldDeep: UIColor = UIColor(hex: "#B8941F")
    /// 성공·심전도·easy.
    static let mint: UIColor = UIColor(hex: "#4ADEC0")
    /// mint 하드섀도.
    static let mintDeep: UIColor = UIColor(hex: "#2A9D85")
    /// 스킬·레어·콤보 10+. 기존 comboAuraViolet(#9B5DE5)와 별개 신규 토큰 — 공존 (SPEC 불일치 기록 3).
    static let violet: UIColor = UIColor(hex: "#8C7BFF")

    // 글로우 규칙 (03_UI §2) — SKEffectNode 블러 금지: 액센트색 alpha 0.30 사각 1장, 노드 뒤 1.4배.
    /// 글로우 사각 alpha.
    static let glowAlpha: CGFloat = 0.30
    /// 글로우 사각 크기 배율 (노드 대비).
    static let glowScale: CGFloat = 1.4

    /// 난이도 매핑 (03_UI §2) — easy=mint / normal=gold / hard=coral.
    /// switch exhaustive — default 금지 (`Palette.character(_:)`와 동형).
    static func difficulty(_ d: Difficulty) -> UIColor {
        switch d {
        case .easy:   return mint
        case .normal: return gold
        case .hard:   return coral
        }
    }

    /// 난이도 하드섀도(Deep) 매핑 — `difficulty(_:)`의 짝 (R4 §F-4 시작 버튼 면/섀도 색 쌍).
    /// switch exhaustive — default 금지.
    static func difficultyDeep(_ d: Difficulty) -> UIColor {
        switch d {
        case .easy:   return mintDeep
        case .normal: return goldDeep
        case .hard:   return coralDeep
        }
    }
}
