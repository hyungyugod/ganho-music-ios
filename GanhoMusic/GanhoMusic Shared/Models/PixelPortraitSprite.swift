//
//  PixelPortraitSprite.swift
//  GanhoMusic Shared
//
//  R4 §F-5 — 5캐릭터 24×24 얼굴 포트레이트 + 빌런 아이콘 데이터·텍스처 팩토리.
//  각 캐릭터의 기존 PixelPalette.palette(for:) 키 문자만 사용 — 팔레트 신규 키 0.
//  헤어·액세서리(러닝캡/안경/고양이귀/강아지귀/번)로 5인 식별 (PixelSprite 오버레이 패턴 동형).
//  박병장 아이콘은 노드(SergeantParkNode)가 SKShapeNode 시안이라 픽셀 데이터 부재 →
//  신규 16×20 아이콘 데이터 추가 (SPEC §F-4 허용 — 색은 기존 ColorTokens 재사용, hex 0).
//  기존 PixelSprite.swift·PixelPalette.swift 변경 0줄 (불변 조건 4 — 신규 파일 추가만).
//  데이터 전용 파일 — 300줄 규칙 예외 대상 (SPEC §D), 보조 enum(DifficultyVillainIcon) 동거.
//

import SpriteKit
import UIKit

/// 난이도 카드 빌런 아이콘 식별자 (§C-11 시각 전용 — 게임 로직 분기 0).
enum DifficultyVillainIcon: CaseIterable {
    case nurseChief, stoneGuard, sergeantPark, professor
}

/// 24×24 포트레이트 데이터·텍스처 팩토리. case 없는 enum — 인스턴스화 차단.
/// 텍스처는 정적 캐시 1회 생성 (메인 스레드 전용 — SpriteKit 씬 빌드 경로) —
/// 매 프레임 텍스처 생성 금지 준수.
enum PixelPortraitSprite {

    /// 포트레이트 그리드 한 변 (px).
    static let gridSide: Int = 24

    // MARK: - Texture Factory (정적 캐시 — 씬 didMove/init 경로 1회 렌더)
    private static var portraitCache: [CharacterID: SKTexture] = [:]
    private static var villainCache: [DifficultyVillainIcon: SKTexture] = [:]

    /// 캐릭터 24×24 포트레이트 텍스처 (.nearest — PixelSpriteRenderer 보장).
    static func texture(for characterID: CharacterID) -> SKTexture {
        if let cached = portraitCache[characterID] { return cached }
        let texture = PixelSpriteRenderer.variableMatrixTexture(
            rows(for: characterID),
            width: gridSide,
            height: gridSide,
            palette: PixelPalette.palette(for: characterID)
        )
        portraitCache[characterID] = texture
        return texture
    }

    /// 빌런 아이콘 텍스처 — 수간호사/석조무사/이교수는 기존 PixelSprite 데이터 재사용,
    /// 박병장만 본 파일 신규 아이콘 데이터 (노드 init 부작용 우회 — SPEC 주의사항 6).
    static func villainTexture(_ icon: DifficultyVillainIcon) -> SKTexture {
        if let cached = villainCache[icon] { return cached }
        let texture: SKTexture
        switch icon {
        case .nurseChief:
            texture = PixelSpriteRenderer.texture(
                from: PixelSprite.nurseChiefData(direction: .down, frame: .idle),
                palette: PixelPalette.chiefPalette
            )
        case .stoneGuard:
            texture = PixelSpriteRenderer.texture(
                from: PixelSprite.stoneGuardData(direction: .down, frame: .idle),
                palette: PixelPalette.stoneGuardPalette
            )
        case .professor:
            texture = PixelSpriteRenderer.texture(
                from: PixelSprite.professorData(direction: .down, frame: .idle),
                palette: PixelPalette.professorPalette
            )
        case .sergeantPark:
            texture = PixelSpriteRenderer.texture(
                from: sergeantIconRows,
                palette: sergeantIconPalette
            )
        }
        villainCache[icon] = texture
        return texture
    }

    // MARK: - 포트레이트 데이터 (24×24 — 행별 정확히 24자 불변식)
    /// 공통 베이스 얼굴(rows 9~23) + 캐릭터별 헤어/액세서리 오버레이(rows 0~8, 일부 눈·뺨 행).
    static func rows(for characterID: CharacterID) -> [String] {
        var base = baseFace
        switch characterID {
        case .kim:  applyKim(&base)
        case .jung: applyJung(&base)
        case .geon: applyGeon(&base)
        case .im:   applyIm(&base)
        case .lee:  applyLee(&base)
        }
        return base
    }

    /// 베이스 — 얼굴(눈 3행·뺨·입·턱) + 목 + 흰 가운 어깨 + 코랄 십자. 헤어는 오버레이가 채운다.
    private static let baseFace: [String] = [
        "........................", // 00 (헤어 오버레이)
        "........................", // 01
        "........................", // 02
        "........................", // 03
        "........................", // 04
        "........................", // 05
        "....SSSSSSSSSSSSSSSS....", // 06 이마
        "...SSSSSSSSSSSSSSSSSS...", // 07
        "...SSSSSSSSSSSSSSSSSS...", // 08
        "...SSEEESSSSSSSSEEESS...", // 09 눈 상단
        "...SSELLSSSSSSSSELLSS...", // 10 눈 하이라이트
        "...SSEEESSSSSSSSEEESS...", // 11 눈 하단
        "...RRSSSSSSSSSSSSSSRR...", // 12 볼터치
        "...SSSSSSSMMMMSSSSSSS...", // 13 입
        "...SSSSSSSSSSSSSSSSSS...", // 14
        "....SSSSSSSSSSSSSSSS....", // 15 턱 테이퍼
        ".....SSSSSSSSSSSSSS.....", // 16
        ".......SSSSSSSSSS.......", // 17 턱
        ".........SSSSSS.........", // 18 목
        "......WWWWWWWWWWWW......", // 19 어깨
        "....WWWWWWWWWWWWWWWW....", // 20 가운
        "...WWWWWWWWCCWWWWWWWW...", // 21 십자 상단
        "...WWWWWWWCCCCWWWWWWW...", // 22 십자 중단
        "...WWWWWWWWCCWWWWWWWW..."  // 23 십자 하단
    ]

    /// 김간호 — 번머리 (H/b).
    private static func applyKim(_ base: inout [String]) {
        base[0] = "..........HHHH.........."
        base[1] = ".........HbbbbH........."
        base[2] = "........HHbbbbHH........"
        base[3] = "......HHHHHHHHHHHH......"
        base[4] = "....HHHHHHHHHHHHHHHH...."
        base[5] = "...HHHHHHHHHHHHHHHHHH..."
        base[6] = "...HHHSSSSSSSSSSSSHHH..."
        base[7] = "...HHSSSSSSSSSSSSSSHH..."
        base[8] = "...HSSSSSSSSSSSSSSSSH..."
    }

    /// 정간호 — 적홍 러닝캡 (Z/z) + 짧은머리 (J/j) + 둥근 검정 안경 (Y/y).
    private static func applyJung(_ base: inout [String]) {
        base[1] = "........ZZZZZZZZ........"
        base[2] = "......ZZZZZZZZZZZZ......"
        base[3] = ".....ZZZZZZZZZZZZZZ....."
        base[4] = "....ZZZZZZZZZZZZZZZZ...."
        base[5] = "...zzzzzzzzzzzzzzzzzz..."
        base[6] = "...JJJSSSSSSSSSSSSJJJ..."
        base[7] = "...JJSSSSSSSSSSSSSSJJ..."
        base[8] = "...jSSSSSSSSSSSSSSSSj..."
        base[9] = "...SSYYYYSSSSSSYYYYSS..."
        base[10] = "...SSYyyYSSSSSSYyyYSS..."
        base[11] = "...SSYYYYSSSSSSYYYYSS..."
    }

    /// 건간호 — 단정 머리 (G/g) + 뿔테 안경 (F/f).
    private static func applyGeon(_ base: inout [String]) {
        base[1] = ".......GGGGGGGGGG......."
        base[2] = ".....GGGGGGGGGGGGGG....."
        base[3] = "....GGGGGGGGGGGGGGGG...."
        base[4] = "...GGGGGGGGGGGGGGGGGG..."
        base[5] = "...GGGGGGGGGGGGGGGGGG..."
        base[6] = "...GGGSSSSSSSSSSSSGGG..."
        base[7] = "...GGSSSSSSSSSSSSSSGG..."
        base[8] = "...gSSSSSSSSSSSSSSSSg..."
        base[9] = "...SSFFFFSSSSSSFFFFSS..."
        base[10] = "...SSFffFSSSSSSFffFSS..."
        base[11] = "...SSFFFFSSSSSSFFFFSS..."
    }

    /// 임간호 — 긴머리 (I/i) + 고양이귀 (T). 얼굴 옆까지 머리가 흐른다.
    private static func applyIm(_ base: inout [String]) {
        base[0] = "......TT........TT......"
        base[1] = ".....TTTIIIIIIIITTT....."
        base[2] = "....IIIIIIIIIIIIIIII...."
        base[3] = "....IIIIIIIIIIIIIIII...."
        base[4] = "...IIIIIIIIIIIIIIIIII..."
        base[5] = "...IIIIIIIIIIIIIIIIII..."
        base[6] = "...IIISSSSSSSSSSSSIII..."
        base[7] = "...IISSSSSSSSSSSSSSII..."
        base[8] = "...IISSSSSSSSSSSSSSII..."
        base[9] = "...IIEEESSSSSSSSEEEII..."
        base[10] = "...IIELLSSSSSSSSELLII..."
        base[11] = "...IIEEESSSSSSSSEEEII..."
        base[12] = "...IiSSRSSSSSSSSRSSiI..."
        base[13] = "...IiSSSSSMMMMSSSSSiI..."
        base[14] = "...IiSSSSSSSSSSSSSSiI..."
    }

    /// 이간호 — 단발 웨이브 (Q/q) + 강아지귀 (D). 턱선 길이 단발.
    private static func applyLee(_ base: inout [String]) {
        base[1] = ".......QQQQQQQQQQ......."
        base[2] = "....DDQQQQQQQQQQQQDD...."
        base[3] = "....DDQQQQQQQQQQQQDD...."
        base[4] = "...QQQQQQQQQQQQQQQQQQ..."
        base[5] = "...QQQQQQQQQQQQQQQQQQ..."
        base[6] = "...QQQSSSSSSSSSSSSQQQ..."
        base[7] = "...QQSSSSSSSSSSSSSSQQ..."
        base[8] = "...qQSSSSSSSSSSSSSSQq..."
        base[9] = "...qqEEESSSSSSSSEEEqq..."
        base[10] = "...qqELLSSSSSSSSELLqq..."
        base[11] = "...qqEEESSSSSSSSEEEqq..."
        base[12] = "...qqSSRSSSSSSSSRSSqq..."
    }

    // MARK: - 박병장 아이콘 (16×20 — 행별 정확히 16자 불변식)
    // 공군 청록 군복 + 항공 캡 + 검정 선글라스 + 골드 계급장 — SergeantParkNode 시안 정체성 계승.
    private static let sergeantIconRows: [String] = [
        "................", // 00
        "....TTTTTTTT....", // 01 캡 크라운
        "...TTTTTTTTTT...", // 02 캡 본체
        "..XXXXXXXXXXXX..", // 03 차양 (검정)
        "..ttSSSSSSSStt..", // 04 캡 가장자리 + 이마
        "..SSSSSSSSSSSS..", // 05 얼굴
        "..SXXXXXXXXXXS..", // 06 선글라스 (연결 에비에이터)
        "..SXXXSSSSXXXS..", // 07 렌즈 하단
        "..SSSSSMMSSSSS..", // 08 입
        "...SSSSSSSSSS...", // 09 턱
        "....TTTTTTTT....", // 10 군복 어깨
        "...TTTTTTTTTT...", // 11
        "...TTTGGGGTTT...", // 12 골드 계급장 상단
        "...TTTTGGTTTT...", // 13 계급장 V 하단
        "...TTTTTTTTTT...", // 14
        "....TTTTTTTT....", // 15
        "....TTT..TTT....", // 16 하의
        "....TTT..TTT....", // 17
        "....BB....BB....", // 18 신발
        "....BB....BB...."  // 19
    ]

    /// 박병장 아이콘 팔레트 — 전부 기존 ColorTokens 재사용 (hex 리터럴 0 — 게이트 2).
    private static let sergeantIconPalette: [Character: UIColor] = [
        "T": .ganhoAirforceTeal,       // 군복·캡 본체
        "t": .ganhoAirforceTealLight,  // 캡 하이라이트
        "X": .ganhoSunglassesBlack,    // 선글라스·차양
        "G": .ganhoMusicGold,          // 골드 계급장
        "S": .ganhoPixelSkin,          // 피부 (공통 재사용)
        "M": .ganhoPixelMouth,         // 입 (공통 재사용)
        "B": .ganhoPixelChiefShoes     // 검정 구두 (chief 재사용)
    ]
}
