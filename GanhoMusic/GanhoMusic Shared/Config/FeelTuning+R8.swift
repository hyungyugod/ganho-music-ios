//
//  FeelTuning+R8.swift
//  GanhoMusic Shared
//
//  R8 — 캐릭터 선택 카드 일러스트 조화 이펙트(백드롭 알파·idle 부유) + DEBUG 자동 일시정지
//  타이밍. R5/R7 네임스페이스 컨벤션 답습 — 전부 토큰 경유, SKAction만 사용.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R8 연출 튜닝 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R8 {
        // MARK: 카드 일러스트 조화 이펙트 (P0-2)
        /// 시그니처 백드롭 알파 — 대면적(104×104)이라 glowAlpha(0.30)보다 약하게.
        static let cardIllustrationBackdropAlpha: CGFloat = 0.22
        /// idle 부유 — 일러스트 스프라이트 y 왕복 거리 (pt). 선택+해금 카드 한정.
        static let cardIllustrationFloatDistance: CGFloat = 3
        /// idle 부유 반주기 (초). easeInEaseOut 왕복 — 총 1.8s 주기의 잔잔한 호흡.
        static let cardIllustrationFloatHalfPeriod: TimeInterval = 0.9
        /// 부유 SKAction 키 — withKey 멱등 (선택 토글 연타 시 자동 교체).
        static let cardIllustrationFloatActionKey: String = "r8IllustrationFloat"

        // MARK: DEBUG 자동 일시정지 (P1-2 — simctl 터치 주입 불가 우회, T6 스크린샷 전용)
        /// GANHO_AUTO_PAUSE=1 시 presentPauseMenu 발화까지 대기 (초).
        /// GANHO_SKIP_CUTSCENE=1 조합 필수 — 컷씬 중이면 .playing 가드가 안전망으로 무시.
        /// R8 실측 조정 3.0 → 8.0: SKIP_CUTSCENE 경로도 카운트다운(3·2·1·GO ≈ 4.2s)을
        /// 지나므로 3.0s 시점은 .countdown — 가드에 막혀 영구 미발화. 8.0s = 게임 시작
        /// 후 ~4초 시점 (T6 시뮬 1차 캡처에서 미발화 실측 후 보정).
        static let debugAutoPauseDelay: TimeInterval = 8.0
    }
}
