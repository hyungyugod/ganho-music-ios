//
//  CharacterID.swift
//  GanhoMusic Shared
//
//  Phase 5-1 · 캐릭터 선택 UI 골격 — 5명 enum (id/displayName/color)
//  Phase 5-3 · 캐릭터별 이동속도 차등 (speedMultiplier 주입)
//

import UIKit

/// 5 캐릭터 식별자. raw String — case 이름이 그대로 raw value("kim", "jung"...).
/// CaseIterable 채택으로 `.allCases` 자동 생성 — TitleScene이 5 카드 일괄 생성에 사용.
/// 본 sprint(5-1)는 *UI 골격*만 — 스킬·외형 적용은 5-2 이후.
enum CharacterID: String, CaseIterable {
    case kim, jung, geon, im, lee

    /// 카드 라벨에 표시되는 한국어 이름. GDD §4 기준.
    var displayName: String {
        switch self {
        case .kim:  return "김간호"
        case .jung: return "정간호"
        case .geon: return "건간호"
        case .im:   return "임간호"
        case .lee:  return "이간호"
        }
    }

    /// 카드 배경색. ColorTokens 기존 5색 재사용 — 새 토큰 신설 X.
    var color: UIColor {
        switch self {
        case .kim:  return .ganhoPaper
        case .jung: return .ganhoMint
        case .geon: return .ganhoPinkNote
        case .im:   return .ganhoYellowF
        case .lee:  return .ganhoBloodAccent
        }
    }

    /// Sprint 10 Phase I — 원본 game.js L317 1:1 정합. 5명 모두 1.0 통일.
    /// 캐릭터 정체성은 *스킬*에서만 분기 — 이동속도는 원본과 동일하게 균질.
    /// 회귀: 기존 ±10% 미세 차등(jung 1.10/geon 0.90 등) 사라짐. 원본 정합 우선 (OQ-D).
    /// PlayerNode.apply(characterID)가 speedMultiplier에 set → update(deltaTime:) velocity 산출에 사용.
    /// switch 제거 — 5명 모두 동일값이라 분기 불필요. 호출처(라벨 표시 6곳)는 모두 ×1.00으로 자연 일치.
    var playerSpeedMultiplier: CGFloat {
        return 1.0
    }

    /// Phase 9-5 — 캐릭터별 능동 스킬. `.kim`은 .none (스킬 없음 = 정공법 정체성).
    /// SkillSystem.configure(scene:skill:)에 전달되어 활성 스킬 확정.
    /// switch default 미사용 — 5 case exhaustive(미래 신규 케이스 추가 시 자연 컴파일 에러).
    var skill: PlayerSkill {
        switch self {
        case .kim:  return .none
        case .jung: return .dashClimb
        case .geon: return .bookClubRally
        case .im:   return .charmStudent
        case .lee:  return .taiwanTrip
        }
    }

    /// Phase 10-1b — 캐릭터 선택 화면 카드 아래 표시되는 짧은 태그(특징 1줄).
    /// displayName(이름)과 분리 — 같은 카드 위치에 *이름 위에 태그* 톤으로 풍부한 정보 전달.
    /// 카드 *외부* SKLabelNode로 표시되어 CharacterCardNode 내부 변경 0건.
    var tag: String {
        switch self {
        case .kim:  return "번머리 실습생"
        case .jung: return "곡괭이 근육"
        case .geon: return "안경과 책"
        case .im:   return "긴머리 냥"
        case .lee:  return "단발 댕댕"
        }
    }

    /// Sprint 2 — 캐릭터 선택 카드 우상단의 작은 색 점(반지름 4) 컬러.
    /// v2 토큰 패밀리(coralLight/scrubMint/lavenderSoft/musicGold) 재사용 — 신규 토큰 0.
    /// `.kim`/`.lee`는 같은 코랄 패밀리지만 카드 위치(좌측/우측 끝)로 시각 분리.
    /// 게임 로직 분기 0 — 순수 시각 라벨용 computed property.
    var dotColor: UIColor {
        switch self {
        case .kim:  return .ganhoCoralLight
        case .jung: return .ganhoScrubMint
        case .geon: return .ganhoLavenderSoft
        case .im:   return .ganhoMusicGold
        case .lee:  return .ganhoCoralLight
        }
    }

    // MARK: - Sprint 7 Phase A — NIKKE 카드 시각용 메타데이터

    /// 카드 좌하단 등급 배지에 표시할 정수(1·2·3 = I·II·III).
    /// switch default 미사용 — 5 case exhaustive. 순수 시각 lookup, 게임 로직 분기 0.
    /// 매핑(OQ-3 결정):
    ///   - 김간호 II (주인공, 정공법 → 중간)
    ///   - 정간호 I (이동속도 +10% 기본 등급)
    ///   - 건간호 III (북클럽 6타일 광역, 가장 *희귀*)
    ///   - 임간호 II (전역 매혹 게임당 1회 — 위력 III급이지만 제약으로 II)
    ///   - 이간호 I (대시 클라임 기본 등급)
    var rarity: Int {
        switch self {
        case .jung: return 1
        case .kim:  return 2
        case .geon: return 3
        case .im:   return 2
        case .lee:  return 1
        }
    }

    /// 카드 좌상단 헥사 아이콘 안에 표시할 속성 이모지 단문자.
    /// 5종(⚡ 번개/💧 물/🌿 풀/🌙 달/🌸 꽃) — 캐릭터별 색 토큰(dotColor)과 시각 짝.
    /// 게임 로직 분기 0 — 순수 시각 lookup.
    var elementSymbol: String {
        switch self {
        case .kim:  return "🌸"
        case .jung: return "🌿"
        case .geon: return "🌙"
        case .im:   return "⚡"
        case .lee:  return "💧"
        }
    }
}
