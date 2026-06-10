//
//  PixelHeroSprite.swift
//  GanhoMusic Shared
//
//  R4 §F-1·§F-5 — StartScene 김간호 대형 픽셀 48×64 × 2프레임(bob).
//  기존 16×20 김간호(PixelSprite)의 실루엣(번 헤어·흰 가운·코랄 십자)과 팔레트 키 문자
//  (H/b/S/W/C/P/B/E/L/R/M — PixelPalette.palette(for: .kim) 전부 기존 키)를 참조해 새로 그림.
//  저작은 24×32 절반 해상도 — expand2x()가 가로·세로 2배 복제해 48×64 프레임을 산출
//  (대칭 보장 + 행 길이 불변식 검증 용이). frame2는 코드 파생(1px 하강 bob — SPEC §F-5 재량).
//  기존 PixelSprite.swift·PixelPalette.swift 변경 0줄 (불변 조건 4 — 신규 파일 추가만).
//

import Foundation

/// 김간호 대형(48×64) 픽셀 데이터 전용 네임스페이스. case 없는 enum — 인스턴스화 차단.
/// 렌더는 `PixelSpriteRenderer.texture(rows:palette:scale:)` 경유 — 텍스처는 호출측이
/// didMove 1회 생성 후 보관 (매 프레임 텍스처 생성 금지).
enum PixelHeroSprite {

    /// 산출 그리드 폭/높이 (px) — 48×64.
    static let gridWidth: Int = 48
    static let gridHeight: Int = 64

    /// idle 2프레임 (48×64) — [기본, bob(1px 하강)].
    static var idleFrames: [[String]] {
        let frame1 = expand2x(art)
        // bob — 상단에 투명 1행 삽입 + 최하단(투명) 1행 제거 = 전신 1px 하강.
        // art 최하단 2행이 투명이라 발 잘림 0 (불변식: art[30]·art[31] 투명).
        let blank = String(repeating: ".", count: gridWidth)
        let frame2 = [blank] + frame1.dropLast()
        return [frame1, frame2]
    }

    // MARK: - 원화 (24×32 — expand2x로 48×64 산출)
    // 행별 정확히 24자 불변식. 키: H 번머리 / b 번 음영 / S 피부 / E 눈 / L 흰자 하이라이트 /
    // R 볼터치 / M 입 / W 흰 가운 / C 코랄 십자 / P 하의 / B 신발 — 전부 kim 기존 팔레트 키.
    private static let art: [String] = [
        "........................", // 00
        ".........HHHHHH.........", // 01 번 꼭대기
        "........HbbbbbbH........", // 02 번 본체
        ".......HbbbbbbbbH.......", // 03 번 본체
        "......HHbbbbbbbbHH......", // 04 번 밑단
        "....HHHHHHHHHHHHHHHH....", // 05 헤어라인 상단
        "...HHHHHHHHHHHHHHHHHH...", // 06 두상 돔
        "...HHHSSSSSSSSSSSSHHH...", // 07 잔머리 옆 + 이마
        "...HHSSSSSSSSSSSSSSHH...", // 08 이마
        "...SSSSSSSSSSSSSSSSSS...", // 09 얼굴
        "...SSSEEESSSSSSEEESSS...", // 10 눈 상단
        "...SSSELLSSSSSSELLSSS...", // 11 눈 하이라이트
        "...SSSEEESSSSSSEEESSS...", // 12 눈 하단
        "...RRSSSSSSMMSSSSSSRR...", // 13 볼터치 + 입
        "...SSSSSSSSSSSSSSSSSS...", // 14
        "....SSSSSSSSSSSSSSSS....", // 15 턱 테이퍼
        "......SSSSSSSSSSSS......", // 16 턱
        ".....WWWWWWWWWWWWWW.....", // 17 어깨
        "....WWWWWWWWWWWWWWWW....", // 18 상의
        "....WWWWWWCCCCWWWWWW....", // 19 십자 상단
        "....WWWWWCCCCCCWWWWW....", // 20 십자 중단
        "....WWWWWWCCCCWWWWWW....", // 21 십자 하단
        "....WWWWWWWWWWWWWWWW....", // 22 상의
        ".....WWWWWWWWWWWWWW.....", // 23 상의 밑단
        ".....WWWWWWWWWWWWWW.....", // 24 가운 자락
        "......PPPPPPPPPPPP......", // 25 하의
        "......PPPPP..PPPPP......", // 26 다리
        "......PPPPP..PPPPP......", // 27 다리
        "......BBBB....BBBB......", // 28 신발
        "......BBBB....BBBB......", // 29 신발
        "........................", // 30 (bob 여유 행)
        "........................"  // 31 (bob 여유 행)
    ]

    /// 가로·세로 2배 복제 — 24×32 → 48×64. 행 단위 순수 변환 (데이터 파생, 로직 분기 0).
    private static func expand2x(_ rows: [String]) -> [String] {
        return rows.flatMap { row -> [String] in
            let doubled = row.map { String(repeating: String($0), count: 2) }.joined()
            return [doubled, doubled]
        }
    }
}
