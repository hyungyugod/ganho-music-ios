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
