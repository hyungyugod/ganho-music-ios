//
//  PixelSprite.swift
//  GanhoMusic Shared
//
//  Phase 8-1 · 원본 웹 게임 game.js L462-627 픽셀 데이터 *byte-equal* 이식.
//  16×20 문자열 배열 + 5캐릭터 오버레이 4개 함수.
//
//  JavaScript ↔ Swift 변환 규칙:
//    1) JS `'....HHHH....'` → Swift `"....HHHH...."` (따옴표만 변경)
//    2) JS `base[N].substring(0, 14) + 'KK'` → Swift `String(base[N].prefix(14)) + "KK"`
//    3) JS `s.replace('II..', 'iI..').replace('..II', '..Ii')`
//       → Swift `s.replacingOccurrences(of: "II..", with: "iI..").replacingOccurrences(of: "..II", with: "..Ii")`
//

import Foundation

/// 김간호(kim)/정간호(jung)/건간호(geon)/임간호(im)/이간호(lee) 5캐릭터 ×
/// 4방향(down/up/left/right) × 3프레임(idle/step1/step2)의 16×20 픽셀 데이터.
/// 원본 game.js L462-627 nurseSprite 함수와 *byte-equal* 동형.
enum PixelSprite {

    /// 행 = 0..19, 각 행은 16 문자. 색 코드 1문자는 PixelPalette에서 해석. `.`은 투명.
    typealias Frame = [String]

    // MARK: - Public Entry
    /// 캐릭터 + 방향 + 프레임 → 16×20 문자열 배열. game.js `nurseSprite(dir, frame, charId)`와 동형.
    static func data(for characterID: CharacterID,
                     direction: PixelDirection,
                     frame: PixelFrame) -> Frame {
        var base = baseFrame(direction: direction, frame: frame)
        applyOverlay(&base, for: characterID, direction: direction)
        return base
    }

    // MARK: - Base Frame (game.js L465-520)
    /// 기본 정면 base + 방향 분기(up/left/right) + 프레임 분기(step1/step2).
    /// game.js L465-520과 *byte-equal* 일치.
    private static func baseFrame(direction: PixelDirection, frame: PixelFrame) -> Frame {
        // 16x20 — 번(행 1-3) + 헤어라인/이마(행 4-5) + 얼굴(행 6-10) + 몸통/다리(행 11-19)
        // game.js L465-486 정면 base 그대로.
        var base: Frame = [
            "................", // 0
            "......HHHH......", // 1 번 꼭대기 (4픽셀 둥근 윗면)
            ".....HbbbbH.....", // 2 번 본체 + 음영
            "....HHbbbbHH....", // 3 번 밑단 + 베이스
            "..HHHHHHHHHHHH..", // 4 두상 윗라인 (헤어라인)
            "..HHSSSSSSSSHH..", // 5 잔머리 옆 + 이마
            "..SSEESSSSEESS..", // 6 눈 동공
            "..SSELSSSSELSS..", // 7 눈 하이라이트
            "..RSSSSMMSSSSR..", // 8 볼터치 + 작은 입
            "..SSSSSSSSSSSS..", // 9
            "...SSSSSSSSSS...", // 10 턱
            "....WWWWWWWW....", // 11 어깨/상의 시작
            "...WWWWCCWWWW...", // 12 가슴 십자 상단
            "...WWWCCCCWWW...", // 13 가슴 십자 중단
            "....WWWWWWWW....", // 14 상의 밑단
            "....PPPPPPPP....", // 15 하의 시작
            "....PPP..PPP....", // 16
            "....PPP..PPP....", // 17
            "....BB....BB....", // 18 발
            "....BB....BB...."  // 19
        ]

        // 방향별 얼굴 처리 (game.js L488-511)
        switch direction {
        case .up:
            // 뒷모습 — 번 실루엣(행 1-3) 유지 + 얼굴 자리 전체를 머리카락으로
            base[1] = "......HHHH......" // 번 꼭대기 (정면과 동일)
            base[2] = ".....HbbbbH....." // 번 본체 + 음영
            base[3] = "....HHbbbbHH...." // 번 밑단
            base[4] = "..HHHHHHHHHHHH.."
            base[5] = "..HHHHHHHHHHHH.."
            base[6] = "..HHHHHHHHHHHH.."
            base[7] = "..HHHHHHHHHHHH.."
            base[8] = "..HHHHHHHHHHHH.."
            base[9] = "..HHHHHHHHHHHH.."
            base[10] = "...HHHHHHHHHH..."
        case .left:
            // 오른쪽 눈만 + 오른쪽 볼
            base[6] = "..SSSSSSSSEESS.."
            base[7] = "..SSSSSSSSELSS.."
            base[8] = "..SSSSSMMSSSSR.."
        case .right:
            // 왼쪽 눈만 + 왼쪽 볼
            base[6] = "..SSEESSSSSSSS.."
            base[7] = "..SSELSSSSSSSS.."
            base[8] = "..RSSSSMMSSSSS.."
        case .down:
            break
        }

        // 걷기 프레임 — 발만 교차 (행 18-19, game.js L513-520)
        switch frame {
        case .step1:
            base[18] = "....BB...BBB...."
            base[19] = "....BBB...BB...."
        case .step2:
            base[18] = "....BBB...BB...."
            base[19] = "....BB...BBB...."
        case .idle:
            break
        }

        return base
    }

    // MARK: - Overlay Dispatch (game.js L522-627)
    /// `kim`은 base 그대로(번머리). 그 외는 헤더 영역(행 1~5) + 소품을 자기 실루엣으로 덮어쓴다.
    private static func applyOverlay(_ base: inout Frame,
                                     for characterID: CharacterID,
                                     direction: PixelDirection) {
        switch characterID {
        case .kim:
            // 'kim'은 기본 번머리(이미 base에 반영)이므로 추가 변형 없음. (game.js L523 주석 그대로)
            break
        case .jung:
            applyJungOverlay(&base, direction: direction)
        case .geon:
            applyGeonOverlay(&base, direction: direction)
        case .im:
            applyImOverlay(&base, direction: direction)
        case .lee:
            applyLeeOverlay(&base, direction: direction)
        }
    }

    // MARK: - jung Overlay (game.js L526-551)
    /// 근육질 짧은머리 — 각진 넓은 머리 + 상의 어깨 2px 확장 + 오른손 곡괭이(세로).
    /// 'J'=짧은머리 본체, 'j'=음영. 어깨 행(11)을 넓혀 근육질 인상.
    private static func applyJungOverlay(_ base: inout Frame, direction: PixelDirection) {
        base[1] = "................"
        base[2] = "....JJJJJJJJ...."
        base[3] = "...JJJJJJJJJJ..."
        base[4] = "..JJJJJJJJJJJJ.."
        base[5] = "..jjSSSSSSSSjj.."
        if direction == .up {
            base[6] = "..JJJJJJJJJJJJ.."
            base[7] = "..JJJJJJJJJJJJ.."
            base[8] = "..JJJJJJJJJJJJ.."
            base[9] = "..JJJJJJJJJJJJ.."
            base[10] = "...JJJJJJJJJJ..."
        }
        // 어깨 확장 (좌우 1px씩)
        base[11] = "...WWWWWWWWWW..."
        base[14] = "...WWWWWWWWWW..."
        // 곡괭이 — 오른쪽 옆구리, 세로 자루(K1) + 헤드(K2) 2픽셀
        // 행 11~17 오른쪽에 자루, 행 10에 헤드 (game.js L546-551)
        base[10] = String(base[10].prefix(14)) + "KK"      // 헤드 우상단
        base[11] = String(base[11].prefix(14)) + "kK"
        base[12] = String(base[12].prefix(14)) + ".K"
        base[13] = String(base[13].prefix(14)) + ".K"
        base[14] = String(base[14].prefix(14)) + ".K"
        base[15] = String(base[15].prefix(14)) + ".K"
    }

    // MARK: - geon Overlay (game.js L552-581)
    /// 단정 머리 + 안경 + 책 — 뿔테 안경(G/g), 오른손 책(O/p).
    private static func applyGeonOverlay(_ base: inout Frame, direction: PixelDirection) {
        base[1] = "................"
        base[2] = ".....GGGGGGGG..."
        base[3] = "....GGGGGGGGGG.."
        base[4] = "..GGGGGGGGGGGG.."
        base[5] = "..GGSSSSSSSSGG.."
        if direction == .up {
            base[6] = "..GGGGGGGGGGGG.."
            base[7] = "..GGGGGGGGGGGG.."
            base[8] = "..GGGGGGGGGGGG.."
            base[9] = "..GGGGGGGGGGGG.."
            base[10] = "...GGGGGGGGGG..."
        } else {
            // 눈 자리에 안경 (E→F 테, L→f 렌즈) — left/right에서 한쪽만 덮이도록 별도 처리
            switch direction {
            case .down:
                base[6] = "..SSFFSSSSFFSS.." // 안경테
                base[7] = "..SSFfSSSSfFSS.." // 렌즈
            case .left:
                base[6] = "..SSSSSSSSFFSS.."
                base[7] = "..SSSSSSSSfFSS.."
            case .right:
                base[6] = "..SSFFSSSSSSSS.."
                base[7] = "..SSFfSSSSSSSS.."
            case .up:
                break // 위 분기에서 처리됨
            }
        }
        // 오른손 책 — 갈색 표지(O) + 속지(p). 몸통 오른쪽 옆. (game.js L579-581)
        base[12] = String(base[12].prefix(14)) + "OO"
        base[13] = String(base[13].prefix(14)) + "Op"
        base[14] = String(base[14].prefix(14)) + "OO"
    }

    // MARK: - im Overlay (game.js L582-601)
    /// 긴머리 + 고양이귀 머리띠 — 머리가 어깨 아래까지 내려온다. 정수리 삼각 귀 2칸.
    /// 'I'=긴머리, 'i'=음영, 'T'=고양이귀.
    private static func applyImOverlay(_ base: inout Frame, direction: PixelDirection) {
        base[1] = "....T......T...."
        base[2] = "...TT.IIII.TT..."
        base[3] = "....IIIIIIII...."
        base[4] = "..IIIIIIIIIIII.."
        base[5] = "..IISSSSSSSSII.."
        if direction == .up {
            base[6] = "..IIIIIIIIIIII.."
            base[7] = "..IIIIIIIIIIII.."
            base[8] = "..IIIIIIIIIIII.."
            base[9] = "..IIIIIIIIIIII.."
            base[10] = "..IIIIIIIIIIII.."
        }
        // 어깨 아래 긴머리 — 상의 양옆에 2줄 머리 (행 11~14, game.js L598-601)
        base[11] = "II..WWWWWWWW..II"
            .replacingOccurrences(of: "II..", with: "iI..")
            .replacingOccurrences(of: "..II", with: "..Ii")
        base[12] = "iI.WWWWCCWWWW.Ii"
        base[13] = "iI.WWWCCCCWWW.Ii"
        base[14] = "iI..WWWWWWWW..Ii"
    }

    // MARK: - lee Overlay (game.js L602-627)
    /// 단발 웨이브 + 강아지 귀 — 턱선 길이 단발.
    /// 'Q'=단발본체(흰자 'L'과 키 충돌 회피), 'q'=웨이브 음영, 'D'=강아지귀.
    private static func applyLeeOverlay(_ base: inout Frame, direction: PixelDirection) {
        base[1] = "................"
        base[2] = ".....QQQQQQQQ..."
        base[3] = "....QQQQQQQQQQ.."
        base[4] = "..QQQQQQQQQQQQ.."
        base[5] = "..QQSSSSSSSSQQ.."
        if direction == .up {
            base[6] = "..QQQQQQQQQQQQ.."
            base[7] = "..QQQQQQQQQQQQ.."
            base[8] = "..QQQQQQQQQQQQ.."
            base[9] = "..QQQQQQQQQQQQ.."
            base[10] = "...QQQQQQQQQQ..."
        } else {
            // 좌우 웨이브 음영 — 행 6~8 가장자리. 기존 face 행에 q 음영을 가장자리에 얹는다.
            // game.js L618: const overlayEdge = (row) => 'qq' + row.substring(2, 14) + 'qq'
            base[6] = overlayEdge(base[6])
            base[7] = overlayEdge(base[7])
            base[8] = overlayEdge(base[8])
        }
        // 강아지 귀 — 정수리 양쪽 아래로 처진 2×2 블록 (행 2~3)
        // base[2]/base[3]의 좌·우 끝에 D 덮어쓰기 (game.js L625-626)
        base[2] = "...DD" + leeSubstring5to11(base[2]) + "DD..."
        base[3] = "...DD" + leeSubstring5to11(base[3]) + "DD..."
    }

    // MARK: - lee Overlay Helpers
    /// JS `'qq' + row.substring(2, 14) + 'qq'`와 byte-equal.
    /// JS substring(2, 14): index 2..13(끝 미포함) = 12자 → Swift index 2..<14 = 12자.
    private static func overlayEdge(_ row: String) -> String {
        // 16자 보장된 row에서 [2, 14) 구간 12자 추출 후 "qq" + ... + "qq" = 16자 복원.
        let chars = Array(row)
        let middle = String(chars[2..<14])
        return "qq" + middle + "qq"
    }

    /// JS `row.substring(5, 11)`와 byte-equal — index 5..10(끝 미포함) = 6자.
    private static func leeSubstring5to11(_ row: String) -> String {
        let chars = Array(row)
        return String(chars[5..<11])
    }
}

// MARK: - Direction & Frame Enums

/// 4방향 픽셀 스프라이트 키. game.js dir 인자와 raw value 매핑.
enum PixelDirection: String {
    case down, up, left, right
}

/// 3프레임 픽셀 스프라이트 키. game.js frame 인자(0/1/2)와 의미 매핑:
/// idle = frame 0 (정지 양발), step1 = frame 1, step2 = frame 2.
enum PixelFrame {
    case idle, step1, step2
}

// MARK: - Nurse Chief Sprite (Phase 8-2)
extension PixelSprite {
    /// 수간호사(EnemyNode) 16×20 픽셀 데이터.
    /// game.js L819-874 `nurseChiefSprite(dir, frame, throwArm)` *byte-equal* 이식.
    /// 본 sprint는 idle/walk만 — `throwArm` (F 투척 모션, game.js L877-889)은 다음 sprint.
    /// 백발 + 안경 + 간호사 캡 + 흰 간호사복 + 얼굴 주름의 나이 든 수간호사.
    static func nurseChiefData(direction: PixelDirection, frame: PixelFrame) -> Frame {
        // 기본 정면 base — game.js L820-841 정확 일치.
        // 색 코드: '.'=투명, 'S'=피부, 'N'=주름, 'H'=백발, 'h'=백발 음영,
        // 'K'=캡, 'k'=캡 음영, 'X'=캡 코럴 십자, 'G'=안경테, 'g'=렌즈,
        // 'U'=흰 간호사복, 'V'=흰옷 음영, 'C'=코럴 악센트, 'B'=구두, 'M'=입.
        var base: Frame = [
            "................", // 0
            "....KKKKKKKK....", // 1  간호사 캡 상단
            "...KKKKXXKKKK...", // 2  캡 + 코럴 십자
            "..KkkkkkkkkkkK..", // 3  캡 밑단(음영)
            "..HHSSSSSSSSHH..", // 4  이마 + 백발 옆선
            "..HhSSSSSSSShH..", // 5  백발 음영
            "..hSGGSSSSGGSh..", // 6  안경테
            "..hSGgSSSSgGSh..", // 7  안경 렌즈(눈)
            "..hSSNSSSSNSSh..", // 8  눈 밑 주름
            "..hSSSSMMSSSSh..", // 9  입
            "..hhSSNNNNSSHh..", // 10 팔자 주름 + 턱선
            "...UUUUUUUUUU...", // 11 흰 간호사복 어깨
            "..UUUUVCCVUUUU..", // 12 옷깃 + 코럴 십자
            "..UUVVVVVVVVUU..", // 13 상의 음영
            "...UUUUUUUUUU...", // 14 상의 밑단
            "....UUUUUUUU....", // 15 하의(흰 간호사복)
            "....UUU..UUU....", // 16
            "....UUU..UUU....", // 17
            "....BB....BB....", // 18 구두
            "....BB....BB...."  // 19
        ]

        // 방향별 얼굴 — game.js L843-864. 뒷통수(up)는 캡·백발로 덮고, 좌우는 안경·주름 편향.
        switch direction {
        case .up:
            // 캡 행 1-3 유지, 얼굴 영역(4-10)만 백발로 덮음. game.js L844-852.
            base[4]  = "..HHHHHHHHHHHH.."
            base[5]  = "..HhHHHHHHHHhH.."
            base[6]  = "..hHHHHHHHHHHh.."
            base[7]  = "..hHHHHHHHHHHh.."
            base[8]  = "..hHHHHHHHHHHh.."
            base[9]  = "..hHHHHHHHHHHh.."
            base[10] = "..hhHHHHHHHHHh.."
        case .left:
            // game.js L853-858 — 안경/주름을 오른쪽으로 편향.
            base[6]  = "..hSSSSSSSGGSh.."
            base[7]  = "..hSSSSSSSgGSh.."
            base[8]  = "..hSSSSSSSNSSh.."
            base[9]  = "..hSSSSMMSSSSh.."
            base[10] = "..hhSSNNNNSSHh.."
        case .right:
            // game.js L859-864 — 안경/주름을 왼쪽으로 편향.
            base[6]  = "..hSGGSSSSSSSh.."
            base[7]  = "..hSGgSSSSSSSh.."
            base[8]  = "..hSSNSSSSSSSh.."
            base[9]  = "..hSSSSMMSSSSh.."
            base[10] = "..hhSSNNNNSSHh.."
        case .down:
            break
        }

        // 걷기 프레임 — 발만 교차 (행 18-19, game.js L867-873).
        switch frame {
        case .step1:
            base[18] = "....BB...BBB...."
            base[19] = "....BBB...BB...."
        case .step2:
            base[18] = "....BBB...BB...."
            base[19] = "....BB...BBB...."
        case .idle:
            break
        }

        return base
    }
}
