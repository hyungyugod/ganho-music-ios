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

// MARK: - Toilet Sprite (Phase 9-6)
extension PixelSprite {
    /// 변기(ToiletNode) 16×20 픽셀 데이터.
    /// SPEC.md §기능 2 toiletData() 16×16 디자인 + 상단 4행 transparent padding 추가.
    /// PixelSpriteRenderer가 고정 16×20 사양이므로 데이터도 20행으로 정합.
    ///
    /// 색 코드: '.'=투명, 'W'=본체(흰색 도자기), 's'=시트(회색 림), 'C'=물(코럴 액센트).
    /// 행 0-3: 상단 transparent padding (renderer 16×20 정합).
    /// 행 4-8: 시트 + 림 + 물 (변기 윗부분, 좌석 영역).
    /// 행 9-19: 본체 다리 + 받침 (변기 아랫부분).
    static func toiletData() -> Frame {
        // Sprint 10 Phase E · 원본 game.js drawToilet (L756~L869) 16×16 fillRect 5단계를
        // 16×20 매트릭스로 변환 (상단 4행 padding). 의미 영역 row 5~17.
        // 색 코드: 'W'=흰 도자기, 's'=회색 시트/뚜껑 테두리, 'B'=옅은 파랑 물, 'K'=검정 구멍.
        // 1) row 5: 뚜껑 — fillRect(3,1,10,1)=s
        // 2) row 6~10: 물탱크 — fillRect(3,2,10,4)=W (4행 + 위 행 1)
        // 3) row 12: 시트 테두리 — fillRect(1,8,14,1)=s
        // 4) row 13~14: 시트 본체 — fillRect(1,8,14,5)=W (시트 흰 영역)
        // 5) row 15: 물 + 구멍 — fillRect(5,11,6,1)=B(물), fillRect(7,11,2,2)=K(구멍 상단)
        // 6) row 16: 구멍 하단 — fillRect(7,11,2,2)=K
        // 7) row 17: 추가 흰 — fillRect(2,13,12,1)=W
        return [
            "................", // 0  (padding)
            "................", // 1  (padding)
            "................", // 2  (padding)
            "................", // 3  (padding)
            "................", // 4  (padding)
            "...ssssssssss...", // 5  뚜껑 oy=1 (fillRect 3,1,10,1)
            "...WWWWWWWWWW...", // 6  물탱크 oy=2
            "...WWWWWWWWWW...", // 7  물탱크 oy=3
            "...WWWWWWWWWW...", // 8  물탱크 oy=4
            "...WWWWWWWWWW...", // 9  물탱크 oy=5 (마감)
            "................", // 10 빈 간격
            "................", // 11 빈 간격
            ".ssssssssssssss.", // 12 시트 테두리 oy=8 (fillRect 1,8,14,1)
            ".WWWWWWWWWWWWWW.", // 13 시트 oy=9
            ".WWWWWWWWWWWWWW.", // 14 시트 oy=10
            ".WWWWBBKKBBWWWW.", // 15 물(5,11,6,1)+구멍 상단(7,11,2,2)
            ".WWWWWWKKWWWWWW.", // 16 구멍 하단(7,12,2,1)
            ".WWWWWWWWWWWWWW.", // 17 흰 추가 oy=13 (fillRect 2,13,12,1)
            "................", // 18 (padding)
            "................"  // 19 (padding)
        ]
    }
}

// MARK: - Professor Sprite (Phase 9-7)
extension PixelSprite {
    /// 이교수(ProfessorNode) 16×20 픽셀 데이터.
    /// nurseChiefData(direction:frame:) 패턴 정확 답습 — 16×20 + 방향 4 + 프레임 3.
    /// 깐깐한 대학교수: 회색 머리 + 안경 + 콧수염 + 흰 셔츠 + 검은 바지.
    ///
    /// 색 코드: '.'=투명, 'S'=피부, 'H'=회색 머리, 'h'=머리 음영,
    /// 'G'=안경테, 'f'=렌즈, 'm'=콧수염, 'M'=입(공통 토큰), 'W'=흰셔츠,
    /// 'P'=검은 바지, 'B'=검은 구두.
    static func professorData(direction: PixelDirection, frame: PixelFrame) -> Frame {
        // 기본 정면 base — 행 1-3 머리, 4-10 얼굴, 11-14 셔츠, 15-17 바지, 18-19 구두.
        var base: Frame = [
            "................", // 0
            "....HHHHHHHH....", // 1  머리 윗부분
            "...HHHHHHHHHH...", // 2  머리 중앙
            "..HHHHHHHHHHHH..", // 3  머리 밑단
            "..HhSSSSSSSShH..", // 4  헤어라인 + 이마
            "..hSSSSSSSSSSh..", // 5  이마 음영
            "..hSGGSSSSGGSh..", // 6  안경테
            "..hSGfSSSSfGSh..", // 7  안경 렌즈(눈)
            "..hSSSSSSSSSSh..", // 8  눈 밑
            "..hSSSmmmmSSSh..", // 9  콧수염
            "..hSSSSMMSSSSh..", // 10 입
            "....WWWWWWWW....", // 11 흰 셔츠 어깨
            "...WWWWWWWWWW...", // 12 셔츠 가슴
            "...WWWWWWWWWW...", // 13 셔츠 중단
            "....WWWWWWWW....", // 14 셔츠 밑단
            "....PPPPPPPP....", // 15 검은 바지 시작
            "....PPP..PPP....", // 16
            "....PPP..PPP....", // 17
            "....BB....BB....", // 18 구두
            "....BB....BB...."  // 19
        ]

        // 방향별 얼굴 — nurseChiefData(L843-864) 패턴 답습.
        switch direction {
        case .up:
            // 뒷통수 — 얼굴 자리 전체를 머리로 덮음.
            base[4]  = "..HHHHHHHHHHHH.."
            base[5]  = "..HhHHHHHHHHhH.."
            base[6]  = "..hHHHHHHHHHHh.."
            base[7]  = "..hHHHHHHHHHHh.."
            base[8]  = "..hHHHHHHHHHHh.."
            base[9]  = "..hHHHHHHHHHHh.."
            base[10] = "..hhHHHHHHHHHh.."
        case .left:
            // 오른쪽 눈/안경만 + 콧수염은 가운데 유지.
            base[6]  = "..hSSSSSSSGGSh.."
            base[7]  = "..hSSSSSSSfGSh.."
            base[8]  = "..hSSSSSSSSSSh.."
            base[9]  = "..hSSSmmmmSSSh.."
            base[10] = "..hSSSSMMSSSSh.."
        case .right:
            // 왼쪽 눈/안경만 + 콧수염은 가운데 유지.
            base[6]  = "..hSGGSSSSSSSh.."
            base[7]  = "..hSGfSSSSSSSh.."
            base[8]  = "..hSSSSSSSSSSh.."
            base[9]  = "..hSSSmmmmSSSh.."
            base[10] = "..hSSSSMMSSSSh.."
        case .down:
            break
        }

        // 걷기 프레임 — 발만 교차 (행 18-19). nurseChiefData/baseFrame 패턴 동일.
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

// MARK: - Stone Guard Sprite (Sprint 10 Phase F)
extension PixelSprite {
    /// 석조무사(StoneGuardNode) 16×20 픽셀 데이터.
    /// 원본 game.js L3120~L3169 stoneGuardSprite byte-equal 이식. nurseChiefData/professorData 패턴 동형.
    ///
    /// 색 코드: '.'=투명, 'H'=짧은 검정 머리, 'K'=피부, 'E'=날카로운 눈,
    /// 'U'=남색 교복, 'u'=교복 음영(단추 라인), 'P'=바지, 'B'=검정 구두.
    /// 입 생략(단호) — drawStoneGuard는 입 픽셀 칠 없음.
    static func stoneGuardData(direction: PixelDirection, frame: PixelFrame) -> Frame {
        // 기본 정면 base — 원본 L3120~L3140 byte-equal 16×20 매트릭스.
        var base: Frame = [
            "................", // 0
            ".....HHHHHH.....", // 1  짧은 검정 머리 꼭대기
            "....HHHHHHHH....", // 2  머리 본체
            "....HHHHHHHH....", // 3  머리 밑단
            "....HKKKKKKH....", // 4  이마 + 헤어라인
            "....KKKKKKKK....", // 5  얼굴 상단
            "....KEKKKKEK....", // 6  날카로운 눈 2점
            "....KKKKKKKK....", // 7
            "....KKKKKKKK....", // 8  입 생략(단호)
            "....KKKKKKKK....", // 9
            "...UUUUUUUUUU...", // 10 교복 상의
            "..UUUuUUUUuUUU..", // 11 단추 라인 u
            "..UUUuUUUUuUUU..", // 12
            "..UUUuUUUUuUUU..", // 13
            "..UUUUUUUUUUUU..", // 14
            "...UUUUUUUUUU...", // 15
            "....PPPP.PPPP...", // 16 바지 (가운데 1px 빈공간)
            "....PPPP.PPPP...", // 17
            "....BBBB.BBBB...", // 18 검정 구두
            "....BBBB.BBBB..."  // 19
        ]

        // 방향별 얼굴 — 원본 L3142~L3158 byte-equal 분기.
        switch direction {
        case .up:
            // 뒷통수 — 얼굴 자리 전체를 머리로 덮음.
            base[4]  = "....HHHHHHHH...."
            base[5]  = "....HHHHHHHH...."
            base[6]  = "....HHHHHHHH...."
            base[7]  = "....HHHHHHHH...."
            base[8]  = "....HHHHHHHH...."
            base[9]  = "....HHHHHHHH...."
        case .left:
            // 오른쪽 눈만(좌측 응시).
            base[6] = "....KKKKKKEK...."
        case .right:
            // 왼쪽 눈만(우측 응시).
            base[6] = "....KEKKKKKK...."
        case .down:
            break
        }

        // 걷기 프레임 — 발만 교차 (행 18-19). 원본 L3160~L3168 byte-equal.
        switch frame {
        case .step1:
            base[18] = "....BBB...BBB..."
            base[19] = "....BBBB.BBB...."
        case .step2:
            base[18] = "....BBB.BBBB...."
            base[19] = "....BBB...BBB..."
        case .idle:
            break
        }

        return base
    }
}
