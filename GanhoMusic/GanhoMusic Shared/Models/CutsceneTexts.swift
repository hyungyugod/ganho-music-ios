//
//  CutsceneTexts.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase H · 5종 컷씬 본문 단일 진실 원천
//
//  원본 game.js L200~L233 `CUTSCENES =` 객체와 1:1 매핑.
//  intro(난이도×캐릭터) / mid1(캐릭터) / mid2(공통) / introStoneGuard / introProfessor.
//
//  TODO(원본 정합): 원본 game.js의 L200~L233 한국어 본문을 직접 grep해
//  byte-equal로 일치시킬 것. 본 파일은 docs/ORIGINAL_GAME_ANALYSIS.md §7.6 요약 +
//  기존 GameConfig 정합 텍스트(professorWarningBody / stoneGuardWarningBody) 보존 +
//  intro/mid1 캐릭터별 본문은 합리적 한국어 placeholder. 추후 게임.js 직접 추출 후 갱신.
//

import Foundation

/// 5종 컷씬 본문 단일 진실 원천. 호출부 리터럴 노출 금지.
/// 모든 lookup은 switch case 5개 exhaustive — `default` 미사용(미래 캐릭터/난이도 추가 시 자연 컴파일 에러).
/// CutsceneTexts는 정적 enum — 인스턴스 0, 상태 0, 순수 lookup.
enum CutsceneTexts {

    // MARK: - intro (난이도 × 캐릭터)

    /// 인트로 컷씬 본문. 난이도(easy/normal vs hard) × 캐릭터(5명) = 10 케이스.
    /// 원본 game.js L200~L221 — 난이도별 본문 차이는 hard에서 *이교수 등장*을 미리 알리는 톤.
    /// 캐릭터별 본문 차이는 각자의 *작곡 동기/성격*을 한 줄로 환기.
    /// `displayName` 토큰 치환은 호출부에서 미리 처리(여기는 *완성된 한국어*만 반환).
    static func intro(difficulty: Difficulty, character: CharacterID) -> (title: String, body: String) {
        let title = "어느 한적한 병동의 오후"
        let body: String
        switch difficulty {
        case .easy, .normal:
            body = introBodyEasyNormal(character: character)
        case .hard:
            body = introBodyHard(character: character)
        }
        return (title, body)
    }

    /// easy/normal 인트로 본문 — 수간호사 순찰 톤 + 캐릭터별 속마음.
    /// TODO(원본 정합): game.js L200~L210 추출 후 byte-equal 갱신.
    /// 현재는 docs §7.6 + 기존 iOS Phase 7-3 `showIntroCutscene` 본문(GameScene L205) 보존.
    private static func introBodyEasyNormal(character: CharacterID) -> String {
        switch character {
        case .kim:
            return "수간호사가 순찰을 돈다. 그 틈을 타, 김간호는 주머니 속 작곡 노트를 슬쩍 꺼낸다… 음표를 모으자."
        case .jung:
            return "수간호사가 순찰을 돈다. 정간호는 가벼운 발놀림으로 복도를 누비며 음표를 줍는다."
        case .geon:
            return "수간호사가 순찰을 돈다. 건간호는 안경을 고쳐 쓰며 책 사이에 흩어진 음표를 모은다."
        case .im:
            return "수간호사가 순찰을 돈다. 임간호는 긴 머리를 쓸어 넘기며 음표가 떨어진 자리를 살핀다."
        case .lee:
            return "수간호사가 순찰을 돈다. 이간호는 단발을 흔들며 즐겁게 음표 사이를 누빈다."
        }
    }

    /// hard 인트로 본문 — 이교수 청진기 위협 톤 + 캐릭터별 결기.
    /// TODO(원본 정합): game.js L211~L221 추출 후 byte-equal 갱신.
    /// 현재는 기존 iOS Phase 7-3 hard 본문(GameScene L207) 보존 + 캐릭터별 한 줄 추가.
    private static func introBodyHard(character: CharacterID) -> String {
        let common = "학교에서 나온 깐깐한 이교수가 오늘따라 청진기를 휘두른다. 날아오는 청진기를 피하며 음표를 모으자. 수간호사는 언제나 그렇듯 순찰을 돈다."
        let mood: String
        switch character {
        case .kim:  mood = "김간호는 입을 꾹 다물고 노트를 펼친다."
        case .jung: mood = "정간호는 가볍게 어깨를 풀며 자세를 낮춘다."
        case .geon: mood = "건간호는 안경 너머로 침착하게 호흡을 가다듬는다."
        case .im:   mood = "임간호는 머리를 묶으며 결의를 다진다."
        case .lee:  mood = "이간호는 한 번 크게 숨을 들이쉰다."
        }
        return common + " " + mood
    }

    // MARK: - mid1 (캐릭터별 속마음)

    /// 경과 15초(timeLeft ≤ 30) 시점 캐릭터별 속마음.
    /// 원본 game.js L211~L222 — 5명 캐릭터별 짧은 독백.
    /// TODO(원본 정합): game.js 직접 grep 후 byte-equal 갱신.
    static func mid1(character: CharacterID) -> (title: String, body: String) {
        let title = "잠시 숨을 고른다"
        let body: String
        switch character {
        case .kim:
            body = "벌써 절반인가… 김간호는 노트의 페이지를 한 장 더 넘긴다."
        case .jung:
            body = "발은 가볍고 손은 빠르다. 정간호는 다음 음표를 찾아 뛴다."
        case .geon:
            body = "이 정도 박자는 외울 수 있어. 건간호는 잠시 호흡을 정돈한다."
        case .im:
            body = "리듬이 머릿속에서 그려진다. 임간호는 작게 흥얼거린다."
        case .lee:
            body = "재미있다. 이간호는 단발을 흔들며 다음 모서리를 돈다."
        }
        return (title, body)
    }

    // MARK: - mid2 (공통)

    /// 경과 30초(timeLeft ≤ 15) 시점 공통 본문 — 수간호사의 시선이 좁혀지는 압박감.
    /// 원본 game.js L223~L225 — 캐릭터 비독립 공통 본문.
    /// TODO(원본 정합): game.js 직접 grep 후 byte-equal 갱신.
    static let mid2: (title: String, body: String) = (
        title: "수간호사의 눈초리",
        body: "수간호사의 시선이 점점 좁아진다. 남은 시간 안에 마지막 멜로디까지 모아내자."
    )

    // MARK: - introStoneGuard (easy/normal)

    /// easy/normal 난이도 인트로 직후 발화되는 *석조무사* 거짓 경고 컷씬.
    /// 원본 game.js L226~L228 — "마주치면 잡혀갑니다" 거짓 경고(실제로는 박병장 비행기 이스터에그 트리거).
    /// 기존 GameConfig.stoneGuardWarningTitle/Body(Phase 10-1d 정합 텍스트) 재사용 — 회귀 0.
    static let introStoneGuard: (title: String, body: String) = (
        title: GameConfig.stoneGuardWarningTitle,
        body: GameConfig.stoneGuardWarningBody
    )

    // MARK: - introProfessor (hard)

    /// hard 난이도 인트로 직후 발화되는 *이교수 청진기* 경고 컷씬.
    /// 원본 game.js L229~L233 — "청진기에 맞으면 정지" 경고.
    /// 기존 GameConfig.professorWarningTitle/Body(Phase 9-7 정합 텍스트) 재사용 — 회귀 0.
    static let introProfessor: (title: String, body: String) = (
        title: GameConfig.professorWarningTitle,
        body: GameConfig.professorWarningBody
    )
}
