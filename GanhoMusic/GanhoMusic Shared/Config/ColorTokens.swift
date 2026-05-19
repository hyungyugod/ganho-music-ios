//
//  ColorTokens.swift
//  GanhoMusic Shared
//
//  Phase 1-1 · Config Bootstrap
//

import UIKit

/// 게임 컬러 토큰. assets.md §1 16색 팔레트 기반.
/// Asset Catalog Color Set이 추가되면 자동으로 그 값이 우선 적용됨.
extension UIColor {

    // MARK: - Background
    /// 배경 (어두운 야간 병동). HEX #1A1B2E
    static let ganhoBgDeep = UIColor(named: "bgDeep")
        ?? UIColor(red: 0x1A / 255, green: 0x1B / 255, blue: 0x2E / 255, alpha: 1)

    // MARK: - Text / Player
    /// 김간호 가운 / HUD 텍스트. HEX #F4F1DE
    static let ganhoPaper = UIColor(named: "paperWhite")
        ?? UIColor(red: 0xF4 / 255, green: 0xF1 / 255, blue: 0xDE / 255, alpha: 1)

    // MARK: - Brand
    /// 김간호 머리띠 / 음표 보조 (민트). HEX #7DCFB6
    static let ganhoMint = UIColor(named: "mintHair")
        ?? UIColor(red: 0x7D / 255, green: 0xCF / 255, blue: 0xB6 / 255, alpha: 1)

    /// 음표 본체 ♪ (분홍). HEX #F6A6B2
    static let ganhoPinkNote = UIColor(named: "pinkNote")
        ?? UIColor(red: 0xF6 / 255, green: 0xA6 / 255, blue: 0xB2 / 255, alpha: 1)

    // MARK: - Enemy
    /// 수간호사 가운. HEX #A4243B. assets.md §1.
    static let ganhoCrimsonNurse = UIColor(named: "crimsonNurse")
        ?? UIColor(red: 0xA4 / 255, green: 0x24 / 255, blue: 0x3B / 255, alpha: 1)

    /// 수간호사 강조 / 피격 플래시. HEX #D8315B. assets.md §1.
    /// Phase 2-6 hotfix 2 — enemy 본체 색으로 사용 (ganhoCrimsonNurse는 어두워 가시성 ↓).
    static let ganhoBloodAccent = UIColor(named: "bloodAccent")
        ?? UIColor(red: 0xD8 / 255, green: 0x31 / 255, blue: 0x5B / 255, alpha: 1)

    // MARK: - Projectile
    /// F 투사체. HEX #FFD23F. assets.md §1 yellowF.
    static let ganhoYellowF = UIColor(named: "yellowF")
        ?? UIColor(red: 0xFF / 255, green: 0xD2 / 255, blue: 0x3F / 255, alpha: 1)

    // MARK: - Pixel Palette (Phase 8-1)
    // 원본 web game (game.js L645-655 common 9키 + L657-692 charMap 4종)의 hex 값을
    // *문자열 byte-equal* 변환. 모든 색은 #RRGGBB 6자리 소문자 — 원본 그대로.

    // 공통 9키 (game.js L645-655)
    /// 피부 — game.js 'S' #fbe0d0
    static let ganhoPixelSkin = UIColor(hex: "#fbe0d0")
    /// 흰옷 — game.js 'W' #ffffff
    static let ganhoPixelUniform = UIColor(hex: "#ffffff")
    /// 코럴 십자 — game.js 'C' #c4847a
    static let ganhoPixelCross = UIColor(hex: "#c4847a")
    /// 하의 — game.js 'P' #9ec9e8 (--nurse-pants fallback)
    static let ganhoPixelPants = UIColor(hex: "#9ec9e8")
    /// 신발 — game.js 'B' #a85f56
    static let ganhoPixelShoes = UIColor(hex: "#a85f56")
    /// 눈 동공 — game.js 'E' #2a1f25
    static let ganhoPixelEye = UIColor(hex: "#2a1f25")
    /// 흰자 하이라이트 — game.js 'L' #ffffff
    static let ganhoPixelEyeHighlight = UIColor(hex: "#ffffff")
    /// 볼터치 — game.js 'R' #f5a8a0
    static let ganhoPixelCheek = UIColor(hex: "#f5a8a0")
    /// 입 — game.js 'M' #c4847a
    static let ganhoPixelMouth = UIColor(hex: "#c4847a")

    // kim 전용 (game.js L687-691)
    /// kim 번머리 본체 — game.js 'H' #3a2a20 (--nurse-bun fallback)
    static let ganhoPixelBunHair = UIColor(hex: "#3a2a20")
    /// kim 번머리 음영 — game.js 'b' #5a4230 (--nurse-bun-shadow fallback)
    static let ganhoPixelBunShadow = UIColor(hex: "#5a4230")

    // jung 전용 (game.js L658-663)
    /// jung 짧은머리 본체 — game.js 'J' #2a1a12
    static let ganhoPixelHairJung = UIColor(hex: "#2a1a12")
    /// jung 짧은머리 음영 — game.js 'j' #180c08
    static let ganhoPixelHairJungShadow = UIColor(hex: "#180c08")
    /// jung 곡괭이 헤드(금속) — game.js 'K' #9aa0a8
    static let ganhoPixelPickHead = UIColor(hex: "#9aa0a8")
    /// jung 곡괭이 자루(갈색) — game.js 'k' #7a4f2a
    static let ganhoPixelPickHandle = UIColor(hex: "#7a4f2a")

    // geon 전용 (game.js L665-672)
    /// geon 단정 머리 본체 — game.js 'G' #30221c
    static let ganhoPixelHairGeon = UIColor(hex: "#30221c")
    /// geon 단정 머리 음영 — game.js 'g' #1a0f0a
    static let ganhoPixelHairGeonShadow = UIColor(hex: "#1a0f0a")
    /// geon 안경테 — game.js 'F' #1f1a1f
    static let ganhoPixelGlassFrame = UIColor(hex: "#1f1a1f")
    /// geon 안경 렌즈(반사) — game.js 'f' #e8f0f8
    static let ganhoPixelGlassLens = UIColor(hex: "#e8f0f8")
    /// geon 책 표지 — game.js 'O' #8a5a32
    static let ganhoPixelBookCover = UIColor(hex: "#8a5a32")
    /// geon 책 속지 — game.js 'p' #f6ebd9
    static let ganhoPixelBookPage = UIColor(hex: "#f6ebd9")

    // im 전용 (game.js L674-678)
    /// im 긴머리 본체 — game.js 'I' #3a2618
    static let ganhoPixelHairIm = UIColor(hex: "#3a2618")
    /// im 긴머리 음영 — game.js 'i' #22150c
    static let ganhoPixelHairImShadow = UIColor(hex: "#22150c")
    /// im 고양이귀 머리띠 — game.js 'T' #ff9db0
    static let ganhoPixelCatEar = UIColor(hex: "#ff9db0")

    // lee 전용 (game.js L681-685)
    /// lee 단발 본체 — game.js 'Q' #5a3a22 (단발은 흰자 'L'과 키 충돌 회피 위해 Q/q)
    static let ganhoPixelHairLee = UIColor(hex: "#5a3a22")
    /// lee 단발 음영 — game.js 'q' #3a2414
    static let ganhoPixelHairLeeShadow = UIColor(hex: "#3a2414")
    /// lee 강아지귀 머리띠 — game.js 'D' #b07a58
    static let ganhoPixelDogEar = UIColor(hex: "#b07a58")

    // MARK: - Chief Palette (Phase 8-2)
    // 원본 web game (game.js L905-919 chiefPaletteCache)의 hex 값을 *문자열 byte-equal* 변환.
    // 백발 + 안경 + 간호사 캡 + 흰 간호사복 + 얼굴 주름의 나이 든 수간호사.
    // 14개 색 토큰 — 원본 cache 15엔트리 중 'P'(하의)는 'U'(uniform)와 같은 hex `#f4f0ee`라
    // 단일 'Uniform' 토큰으로 통일. sprite 데이터에서도 'P' 키는 등장하지 않는다.

    /// 피부 — game.js 'S' #f5d5c0
    static let ganhoPixelChiefSkin = UIColor(hex: "#f5d5c0")
    /// 주름/피부 음영 — game.js 'N' #c08878
    static let ganhoPixelChiefWrinkle = UIColor(hex: "#c08878")
    /// 백발 본체 — game.js 'H' #e8e4e8
    static let ganhoPixelChiefHair = UIColor(hex: "#e8e4e8")
    /// 백발 음영 — game.js 'h' #c8c4cc
    static let ganhoPixelChiefHairShadow = UIColor(hex: "#c8c4cc")
    /// 간호사 캡 — game.js 'K' #ffffff
    static let ganhoPixelChiefCap = UIColor(hex: "#ffffff")
    /// 캡 음영 — game.js 'k' #e6dde6
    static let ganhoPixelChiefCapShadow = UIColor(hex: "#e6dde6")
    /// 캡 코럴 십자 — game.js 'X' #ff7b7b
    static let ganhoPixelChiefCross = UIColor(hex: "#ff7b7b")
    /// 안경테 — game.js 'G' #1f1a1f
    static let ganhoPixelChiefGlass = UIColor(hex: "#1f1a1f")
    /// 렌즈 안(피부 변형) — game.js 'g' #e8c8b8
    static let ganhoPixelChiefGlassLens = UIColor(hex: "#e8c8b8")
    /// 흰 간호사복 — game.js 'U' #f4f0ee
    static let ganhoPixelChiefUniform = UIColor(hex: "#f4f0ee")
    /// 흰옷 음영 — game.js 'V' #d8d2d0
    static let ganhoPixelChiefUniformShadow = UIColor(hex: "#d8d2d0")
    /// 코럴 악센트(옷깃 중앙) — game.js 'C' #ff7b7b
    static let ganhoPixelChiefAccent = UIColor(hex: "#ff7b7b")
    /// 검정 구두 — game.js 'B' #1a1214
    static let ganhoPixelChiefShoes = UIColor(hex: "#1a1214")
    /// 입술 — game.js 'M' #6b3a3a
    static let ganhoPixelChiefMouth = UIColor(hex: "#6b3a3a")

    // MARK: - Game UI Tokens (Phase 8-3)
    /// 원본 웹게임 style.css :root CSS 변수 1:1 매핑.
    /// 원본 hex 값 byte-equal — 디자인 단일 진실 원천 = style.css L3-46.
    /// Spring 비유: application.yml의 디자인 토큰을 Swift 상수로 옮긴 형태.

    /// --bg #0f0e15 (어두운 매트 배경)
    static let ganhoUIBg = UIColor(hex: "#0f0e15")
    /// --bg-dark #09080f (더 깊은 검정)
    static let ganhoUIBgDark = UIColor(hex: "#09080f")
    /// --bg-card rgba(23,21,30,0.82) — 카드 배경(반투명)
    static let ganhoUIBgCard = UIColor(hex: "#17151e").withAlphaComponent(0.82)
    /// --brand #c4847a (코럴, 메인 강조색)
    static let ganhoUIBrand = UIColor(hex: "#c4847a")
    /// --brand-light #d4a49c (밝은 코럴, 텍스트 강조)
    static let ganhoUIBrandLight = UIColor(hex: "#d4a49c")
    /// --brand-12 rgba(196,132,122,0.12) — 선택 카드 배경
    static let ganhoUIBrand12 = UIColor(hex: "#c4847a").withAlphaComponent(0.12)
    /// --brand-20 rgba(196,132,122,0.20)
    static let ganhoUIBrand20 = UIColor(hex: "#c4847a").withAlphaComponent(0.20)
    /// --brand-40 rgba(196,132,122,0.40)
    static let ganhoUIBrand40 = UIColor(hex: "#c4847a").withAlphaComponent(0.40)
    /// --brand-60 rgba(196,132,122,0.60) — 선택 카드 보더
    static let ganhoUIBrand60 = UIColor(hex: "#c4847a").withAlphaComponent(0.60)
    /// --text #eeeeee (기본 텍스트)
    static let ganhoUIText = UIColor(hex: "#eeeeee")
    /// --text-muted #aaaaaa (보조 텍스트)
    static let ganhoUITextMuted = UIColor(hex: "#aaaaaa")
    /// --text-dim #555555 (희미한 텍스트)
    static let ganhoUITextDim = UIColor(hex: "#555555")
    /// --border rgba(255,255,255,0.07) — 보더 라인
    static let ganhoUIBorder = UIColor.white.withAlphaComponent(0.07)
    /// game-overlay 배경 #09080f α=0.78 — 게임 영역 차단 반투명
    static let ganhoUIOverlayBg = UIColor(hex: "#09080f").withAlphaComponent(0.78)

    // MARK: - Toilet Bonus (Phase 9-6)
    /// 변기 본체(흰색 도자기) — 픽셀 코드 'W'. assets.md §1 ganhoPaper 패밀리의 톤다운 변형.
    /// 어두운 BG(#1A1B2E) 위에서 도자기 광택을 표현하기 위해 ganhoPaper(#F4F1DE)보다 살짝 밝고
    /// 회색 톤이 섞인 #f4f0ee — Phase 8-2 ganhoPixelChiefUniform과 동일 hex로 디자인 통일성 유지.
    static let ganhoToiletBowl = UIColor(hex: "#f4f0ee")
    /// 변기 시트(좌석 림) — 픽셀 코드 's'. 본체(#f4f0ee)보다 어두운 회색.
    /// 본체와의 명도 대비로 시트의 입체감 표현. Phase 8-2 ganhoPixelChiefUniformShadow(#d8d2d0)보다
    /// 더 회색 — 변기 시트의 *경계선* 역할 강조.
    static let ganhoToiletSeat = UIColor(hex: "#b8b3ad")
    /// 변기 안 물(코럴 액센트) — 픽셀 코드 'C'. Phase 8-3 ganhoUIBrand(#c4847a) 패밀리의 액센트 변형.
    /// "화캉스" 농담의 코럴 톤 — 음표 분홍(#F6A6B2)과 다른 *주황 코럴*로 별도 정체성.
    static let ganhoToiletAccent = UIColor(hex: "#ff8a7a")

    // MARK: - Professor Palette (Phase 9-7)
    /// 이교수(ProfessorNode) 픽셀 팔레트 — 회색 머리 + 콧수염 + 검은 바지의 깐깐한 대학교수 톤.
    /// 다른 토큰 재사용 최대화 — 피부('S'=ganhoPixelSkin), 흰셔츠('W'=ganhoPixelUniform),
    /// 안경테('G'=ganhoPixelGlassFrame), 렌즈('f'=ganhoPixelGlassLens), 신발('B'=ganhoPixelChiefShoes 검정)
    /// 모두 기존 토큰을 그대로 사용. 신규는 머리/머리 음영/콧수염/바지 4개만.

    /// 회색 머리 본체 — 픽셀 코드 'H'. 백발(ganhoPixelChiefHair #e8e4e8)보다 어두운 *중년 회색*.
    /// 수간호사 백발과의 시각 분리 — 이교수는 *살아있는 회색*, 수간호사는 *나이 든 백발*.
    static let ganhoPixelProfessorHair = UIColor(hex: "#7a7570")
    /// 회색 머리 음영 — 픽셀 코드 'h'. ganhoPixelProfessorHair 패밀리의 어두운 변형.
    static let ganhoPixelProfessorHairShadow = UIColor(hex: "#5a5550")
    /// 콧수염 — 픽셀 코드 'm'. 거의 검정에 가까운 어두운 갈색.
    /// 입('M'=ganhoPixelMouth #c4847a)과 키 충돌 회피 위해 소문자 'm' 사용.
    static let ganhoPixelProfessorMustache = UIColor(hex: "#2a2025")
    /// 검은 바지 — 픽셀 코드 'P'. 공통 'P'(ganhoPixelPants #9ec9e8 파란 하의)와 *다른 색*이지만
    /// professorPalette는 별도 dict라 충돌 없음 — 같은 키 'P'가 dict별로 다른 색.
    /// ganhoPixelChiefShoes(#1a1214 검정)와 유사 — 깐깐한 정장 톤.
    static let ganhoPixelProfessorPants = UIColor(hex: "#1f1a1f")

    // MARK: - Accent (Phase 10-2 · 병동의 새벽 톤)
    /// StartScene 리스킨용 액센트 패밀리. 기존 ganhoUIBrand(#c4847a, 어두운 코럴)와 *별도 네이밍*으로
    /// 충돌 회피. 본 패밀리는 "야간 병동 위로 떠오르는 새벽 멜로디" 톤 — teal 그라데이션 + 살구 음표.

    /// 그라데이션 하단 + 제목 글로우 외곽. 시원하고 채도 높은 청록 — 새벽 톤.
    /// ganhoMint(#7DCFB6)와 *다른* 더 차가운 청록.
    static let ganhoAccentTeal = UIColor(hex: "#5BD7CF")
    /// 그라데이션 상단. 딥블루-틸 중간 톤 — 어두운 야간 병동의 깊이.
    static let ganhoAccentTealDeep = UIColor(hex: "#1E3A4C")
    /// 음표 파티클 본체 + 선택 카드 링 글로우 + BEST/PLAYS 액센트.
    /// 밝고 따뜻한 살구색 — ganhoUIBrand(#c4847a)보다 *밝은* 떠오르는 멜로디 톤.
    static let ganhoAccentCoral = UIColor(hex: "#FFB59A")
}

// MARK: - UIColor Hex Init (Phase 8-1)
extension UIColor {
    /// `"#rrggbb"` 또는 `"rrggbb"` 6자리 hex 문자열에서 UIColor 생성.
    /// 원본 web game의 hex 리터럴(#fbe0d0 등)을 그대로 옮기기 위한 헬퍼.
    /// 파싱 실패 시 magenta로 graceful fallback — *눈에 띄게* 잘못된 hex를 표면화한다.
    /// Spring 비유: 환경설정 파싱 실패 시 명백한 sentinel 값을 노출하는 패턴.
    convenience init(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("#") {
            raw = String(raw.dropFirst())
        }
        guard raw.count == 6, let value = UInt32(raw, radix: 16) else {
            // 잘못된 hex는 즉시 시각 인식 가능한 magenta로 표시 — 디버깅 친화.
            self.init(red: 1, green: 0, blue: 1, alpha: 1)
            return
        }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8)  & 0xFF) / 255.0
        let b = CGFloat( value        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
