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
        case .easy:   return "여유로운 실습"
        case .normal: return "긴장의 병동"
        case .hard:   return "이교수의 청진기"
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
}
