//
//  Difficulty.swift
//  GanhoMusic Shared
//
//  Phase 7-1 · 난이도 3단계 시스템 (하/중/상) — enum + 부속 속성(displayName/subtitle/color)
//

import UIKit

/// 3 난이도 식별자. raw String — case 이름이 그대로 raw value("easy", "normal", "hard").
/// CaseIterable 채택으로 `.allCases` 자동 생성 — TitleScene이 3 카드 일괄 생성에 사용.
/// CharacterID(5-1)와 동형 패턴 — Spring `enum implements GrantedAuthority` 같은 식별자 토큰.
enum Difficulty: String, CaseIterable {
    case easy, normal, hard

    /// 카드 라벨에 표시되는 한국어 이름. GDD §5 기준.
    var displayName: String {
        switch self {
        case .easy:   return "하"
        case .normal: return "중"
        case .hard:   return "상"
        }
    }

    /// 카드 부제 라벨. 난이도의 *톤*을 짧은 한글 문구로 전달 — "어렵다"가 아니라 "이 게임의 색".
    var subtitle: String {
        switch self {
        case .easy:   return "처음 실습용"
        case .normal: return "박자와 회피 균형"
        case .hard:   return "이교수까지 등장"
        }
    }

    /// 카드 배경색. ColorTokens 기존 3색 재사용 — 새 토큰 신설 X.
    /// 민트(여유) → 노랑(긴장) → 핏빛(위협) 톤 그라데이션.
    var color: UIColor {
        switch self {
        case .easy:   return .ganhoMint
        case .normal: return .ganhoYellowF
        case .hard:   return .ganhoBloodAccent
        }
    }

    /// Sprint 2 — 짧은 1자 라벨. DarkContextChipNode 뱃지에 표시. displayName과 동일하지만
    /// 의미 단위 분리 — *카드 라벨*과 *뱃지*의 호출 의도를 코드 레벨에서 구분.
    /// 게임 로직 분기 0 — 순수 시각 라벨용 computed property.
    var shortName: String {
        switch self {
        case .easy:   return "하"
        case .normal: return "중"
        case .hard:   return "상"
        }
    }

    /// Sprint 7 — 카드에 부착되는 한 줄 풀이. subtitle보다 길고 *경험의 톤*을 전달.
    /// DifficultyCardNode의 descriptionLabel에만 사용 — 게임 로직 분기 0, 순수 시각 라벨용.
    /// `: CustomStringConvertible` 채택은 *하지 않는다* — `String(describing:)` 동작 변경
    /// 회귀를 막기 위함(SPEC §주의사항 4).
    var description: String {
        switch self {
        case .easy:   return "느린 템포로 패턴을 익혀요"
        case .normal: return "표준 템포로 점수와 회피를 같이 봐요"
        case .hard:   return "청진기까지 피해 가야 합니다"
        }
    }

    /// Sprint 2 — 결과 화면/졸업 판정이 같은 목표 점수를 읽도록 하는 얇은 래퍼.
    var targetScore: Int {
        switch self {
        case .easy:
            return GameConfig.targetScoreByDifficulty[.easy] ?? Int.max
        case .normal:
            return GameConfig.targetScoreByDifficulty[.normal] ?? Int.max
        case .hard:
            return GameConfig.targetScoreByDifficulty[.hard] ?? Int.max
        }
    }

    // MARK: - Sprint 7 Phase C · Card hierarchy colors
    //
    // 카드 자체의 *색 위계* 표현용 4 lookup. 기존 `.color`(.ganhoMint / .ganhoYellowF /
    // .ganhoBloodAccent)는 그대로 보존 — 다른 사용처(예: 점 dot)의 색이 회귀하지 않도록 분리.
    // 본 lookup은 DifficultyCardNode init/setSelected에서만 사용. 게임 로직 분기 0.
    // 3 case exhaustive switch — default 미사용으로 enum 확장 시 컴파일 가드 보장.

    /// Sprint 7 Phase C — 카드 그라데이션 상단 색(밝은 톤). 카드 fill의 주 색상.
    var cardFillTop: UIColor {
        switch self {
        case .easy:   return .ganhoDifficultyEasyMint
        case .normal: return .ganhoDifficultyMidGold
        case .hard:   return .ganhoDifficultyHardCoral
        }
    }

    /// Sprint 7 Phase C — 카드 그라데이션 하단 색(짙은 톤). SpriteKit SKShapeNode는 그라데이션
    /// fill 직접 지원이 없어 *strokeColor* 및 cardStrokeColor 동기화에 사용.
    var cardFillBottom: UIColor {
        switch self {
        case .easy:   return .ganhoDifficultyEasyDeep
        case .normal: return .ganhoDifficultyMidDeep
        case .hard:   return .ganhoDifficultyHardDeep
        }
    }

    /// Sprint 7 Phase C — 카드 stroke 정색(선택 시). 미선택 시는 알파 0.4 곱해서 사용.
    /// cardFillBottom과 동일 hex — 의미 단위 분리(stroke 호출 명확성).
    var cardStrokeColor: UIColor {
        switch self {
        case .easy:   return .ganhoDifficultyEasyDeep
        case .normal: return .ganhoDifficultyMidDeep
        case .hard:   return .ganhoDifficultyHardDeep
        }
    }

    /// Sprint 7 Phase C — 선택 카드 뒤 라디얼 글로우 색(밝은 톤). cardFillTop과 동일 hex.
    /// 의미 단위 분리 — *글로우*는 fill과 별도 역할(외곽 후광)이라 호출부 가독성을 위해 분리.
    var cardGlowColor: UIColor {
        switch self {
        case .easy:   return .ganhoDifficultyEasyMint
        case .normal: return .ganhoDifficultyMidGold
        case .hard:   return .ganhoDifficultyHardCoral
        }
    }
}
