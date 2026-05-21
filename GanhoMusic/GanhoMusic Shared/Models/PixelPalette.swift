//
//  PixelPalette.swift
//  GanhoMusic Shared
//
//  Phase 8-1 · 원본 web game game.js L637-697 getNursePalette 함수 byte-equal 이식.
//  공통 9키(S/W/C/P/B/E/L/R/M) + 캐릭터별 charMap을 합쳐 1글자 → UIColor 맵으로 반환.
//

import UIKit

/// 픽셀 1글자 코드 → UIColor 매핑. 공통 9키는 전 캐릭터 공유, 캐릭터 전용 키는 CharacterID로 분기.
/// PixelSpriteRenderer에서 String 배열 + 이 dict로 SKTexture를 생성.
enum PixelPalette {

    /// 공통 팔레트 — 5캐릭터 모두 공유. game.js L645-655.
    private static let common: [Character: UIColor] = [
        "S": .ganhoPixelSkin,         // 피부
        "W": .ganhoPixelUniform,      // 흰옷
        "C": .ganhoPixelCross,        // 코럴 십자
        "P": .ganhoPixelPants,        // 하의
        "B": .ganhoPixelShoes,        // 신발
        "E": .ganhoPixelEye,          // 눈 동공
        "L": .ganhoPixelEyeHighlight, // 흰자 하이라이트
        "R": .ganhoPixelCheek,        // 볼터치
        "M": .ganhoPixelMouth         // 입
    ]

    // MARK: - Public Entry
    /// CharacterID → 그 캐릭터의 풀 팔레트 dict 반환. 공통 9키 + 캐릭터별 키 병합.
    /// game.js의 `Object.assign({}, common, charMap)`와 byte-equal 동형 —
    /// charMap이 common을 덮는다. (lee의 경우 'L' 키가 charMap에는 없으므로 공통의 흰자 그대로 사용.)
    static func palette(for characterID: CharacterID) -> [Character: UIColor] {
        var merged = common
        for (key, value) in charMap(for: characterID) {
            merged[key] = value
        }
        return merged
    }

    // MARK: - Character-specific charMap (game.js L657-692)
    /// 캐릭터별 전용 키 dict. game.js의 분기 5개와 동형.
    /// `kim`은 기본 번머리(H/b). `lee`는 'L'(흰자)와 충돌 회피 위해 단발은 Q/q, 강아지귀는 D.
    private static func charMap(for characterID: CharacterID) -> [Character: UIColor] {
        switch characterID {
        case .jung:
            return [
                "J": .ganhoPixelHairJung,
                "j": .ganhoPixelHairJungShadow,
                "K": .ganhoPixelPickHead,   // 헤드(금속)
                "k": .ganhoPixelPickHandle  // 자루(갈색)
            ]
        case .geon:
            return [
                "G": .ganhoPixelHairGeon,
                "g": .ganhoPixelHairGeonShadow,
                "F": .ganhoPixelGlassFrame, // 안경테
                "f": .ganhoPixelGlassLens,  // 렌즈(반사)
                "O": .ganhoPixelBookCover,  // 책 표지
                "p": .ganhoPixelBookPage    // 책 속지
            ]
        case .im:
            return [
                "I": .ganhoPixelHairIm,
                "i": .ganhoPixelHairImShadow,
                "T": .ganhoPixelCatEar
            ]
        case .lee:
            // 공통 'L'(흰자)와 키 충돌을 피해 단발은 'Q'/'q', 강아지귀는 'D'로 분리. (game.js L680-685)
            return [
                "Q": .ganhoPixelHairLee,
                "q": .ganhoPixelHairLeeShadow,
                "D": .ganhoPixelDogEar
            ]
        case .kim:
            // kim — 기본 번머리. (game.js L687-691)
            return [
                "H": .ganhoPixelBunHair,
                "b": .ganhoPixelBunShadow
            ]
        }
    }
}

// MARK: - Chief Palette (Phase 8-2)
extension PixelPalette {
    /// 수간호사(EnemyNode) 픽셀 팔레트 14키. game.js L905-919 chiefPaletteCache 1:1.
    /// 원본 cache는 15엔트리(S/N/H/h/K/k/X/G/g/U/V/C/P/B/M) — 그 중 'P'(하의)는 'U'(uniform)와
    /// 동일 hex `#f4f0ee`로 통일되어 있고, 본 sprite 데이터(L820-841)에서 'P' 키 자체가
    /// 등장하지 않는다. 따라서 의미상 유니크한 14키만 매핑.
    /// PixelSpriteRenderer는 팔레트에 없는 문자를 *투명*으로 처리하므로 안전.
    static let chiefPalette: [Character: UIColor] = [
        "S": .ganhoPixelChiefSkin,          // 피부
        "N": .ganhoPixelChiefWrinkle,       // 주름/피부 음영
        "H": .ganhoPixelChiefHair,          // 백발
        "h": .ganhoPixelChiefHairShadow,    // 백발 음영
        "K": .ganhoPixelChiefCap,           // 간호사 캡
        "k": .ganhoPixelChiefCapShadow,     // 캡 음영
        "X": .ganhoPixelChiefCross,         // 캡 코럴 십자
        "G": .ganhoPixelChiefGlass,         // 안경테
        "g": .ganhoPixelChiefGlassLens,     // 렌즈(피부 변형)
        "U": .ganhoPixelChiefUniform,       // 흰 간호사복
        "V": .ganhoPixelChiefUniformShadow, // 흰옷 음영
        "C": .ganhoPixelChiefAccent,        // 코럴 악센트(옷깃 중앙)
        "B": .ganhoPixelChiefShoes,         // 검정 구두
        "M": .ganhoPixelChiefMouth          // 입술
    ]
}

// MARK: - Toilet Palette (Sprint 10 Phase E)
extension PixelPalette {
    /// 변기(ToiletNode) 픽셀 팔레트 4키 — 원본 game.js drawToilet (L756~L869) byte-equal.
    /// 'W'=#ffffff 흰 도자기, 's'=#cfd3da 회색 시트/뚜껑, 'B'=#a9d6ef 옅은 파랑 물, 'K'=#1a1a22 검정 구멍.
    /// **inline UIColor literal** 사용 — ColorTokens 본체 신설 0(SPEC §변경 금지 우회).
    /// PixelSpriteRenderer가 팔레트에 없는 문자를 *투명*으로 처리하므로 '.' 키는 등록 불필요.
    static let toiletPalette: [Character: UIColor] = [
        "W": UIColor(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0, alpha: 1.0),
        "s": UIColor(red: 0xCF / 255.0, green: 0xD3 / 255.0, blue: 0xDA / 255.0, alpha: 1.0),
        "B": UIColor(red: 0xA9 / 255.0, green: 0xD6 / 255.0, blue: 0xEF / 255.0, alpha: 1.0),
        "K": UIColor(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x22 / 255.0, alpha: 1.0)
    ]
}

// MARK: - Professor Palette (Phase 9-7)
extension PixelPalette {
    /// 이교수(ProfessorNode) 픽셀 팔레트. chiefPalette와 동형 구조 — *별도 dict*라 키 충돌 없음.
    /// 신규 토큰 4개(머리/머리 음영/콧수염/바지) + 기존 토큰 재사용(피부/흰셔츠/안경/구두/입).
    /// 같은 키 'P'가 공통 dict(파란 하의 ganhoPixelPants)와 *다른 색*이지만 본 dict만 단독 사용되므로 충돌 없음.
    /// PixelSpriteRenderer는 호출 시 단일 dict만 사용 → 자연 분리.
    static let professorPalette: [Character: UIColor] = [
        "S": .ganhoPixelSkin,                  // 피부 (공통 재사용)
        "H": .ganhoPixelProfessorHair,         // 회색 머리 (신규)
        "h": .ganhoPixelProfessorHairShadow,   // 머리 음영 (신규)
        "G": .ganhoPixelGlassFrame,            // 안경테 (geon 재사용)
        "f": .ganhoPixelGlassLens,             // 렌즈 (geon 재사용)
        "m": .ganhoPixelProfessorMustache,     // 콧수염 (신규, 'M' 입과 분리 위해 소문자)
        "M": .ganhoPixelMouth,                 // 입 (공통 재사용)
        "W": .ganhoPixelUniform,               // 흰 셔츠 (공통 재사용)
        "P": .ganhoPixelProfessorPants,        // 검은 바지 (신규, 공통 'P'와 같은 키지만 dict 분리)
        "B": .ganhoPixelChiefShoes             // 검은 구두 (chief 재사용)
    ]
}

// MARK: - Stone Guard Palette (Sprint 10 Phase F)
extension PixelPalette {
    /// 석조무사(StoneGuardNode) 픽셀 팔레트.
    /// 원본 game.js L3175~L3192 stoneGuardPaletteCache byte-equal 이식 — 7키.
    /// 'H'=#1a1418 검정 머리, 'K'=#e8c9a6 피부, 'E'=#2a2228 날카로운 눈,
    /// 'U'=#2a3550 남색 교복, 'u'=#1a2238 교복 음영, 'P'=#1f2533 바지, 'B'=#0f0f12 검정 구두.
    /// **inline UIColor literal** 사용 — ColorTokens 본체 신설 0(SPEC §변경 금지 우회).
    /// 같은 키('H'/'P'/'B')가 공통/professor dict와 다른 색이지만 dict 분리되어 충돌 없음.
    /// PixelSpriteRenderer가 팔레트에 없는 문자를 *투명*으로 처리하므로 '.' 키는 등록 불필요.
    static let stoneGuardPalette: [Character: UIColor] = [
        "H": UIColor(red: 0x1A / 255.0, green: 0x14 / 255.0, blue: 0x18 / 255.0, alpha: 1.0),
        "K": UIColor(red: 0xE8 / 255.0, green: 0xC9 / 255.0, blue: 0xA6 / 255.0, alpha: 1.0),
        "E": UIColor(red: 0x2A / 255.0, green: 0x22 / 255.0, blue: 0x28 / 255.0, alpha: 1.0),
        "U": UIColor(red: 0x2A / 255.0, green: 0x35 / 255.0, blue: 0x50 / 255.0, alpha: 1.0),
        "u": UIColor(red: 0x1A / 255.0, green: 0x22 / 255.0, blue: 0x38 / 255.0, alpha: 1.0),
        "P": UIColor(red: 0x1F / 255.0, green: 0x25 / 255.0, blue: 0x33 / 255.0, alpha: 1.0),
        "B": UIColor(red: 0x0F / 255.0, green: 0x0F / 255.0, blue: 0x12 / 255.0, alpha: 1.0)
    ]
}
