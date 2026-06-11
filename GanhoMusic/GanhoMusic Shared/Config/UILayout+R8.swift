//
//  UILayout+R8.swift
//  GanhoMusic Shared
//
//  R8 — 캐릭터 선택 카드 일러스트·일시정지 v3 다이얼로그·Start 로고/칩 간격 토큰
//  (매직 넘버 0 원칙). R4~R7 nested enum 전례 답습 — R8 고유 수치·카피만 여기에 둔다.
//

import UIKit

extension UILayout {
    /// R8 레이아웃·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R8 {
        // MARK: 캐릭터 선택 카드 일러스트 (P0-2)
        /// 일러스트 자산 이름 접미 — "\(CharacterID.rawValue)\(suffix)" 조립의 단일 진실 원천.
        /// Assets.xcassets/Characters/ 5종(kim/jung/geon/im/lee) imageset과 1:1.
        static let characterIllustrationSuffix: String = "_down_idle_1"
        /// 카드 내 일러스트 표시 크기 — 96×144 자산의 2:3 비율 유지 축소 (카드 148×196 내).
        static let cardIllustrationSize = CGSize(width: 72, height: 108)
        /// 일러스트 중심 y (카드 좌표). 이름(-28)·칩(-64) 밴드와 비교차.
        static let cardIllustrationOffsetY: CGFloat = 34
        /// 시그니처 백드롭(해금 카드 한정 단색 사각) 크기 — 카드 면(148×196) 안에 완전 수납.
        static let cardIllustrationBackdropSize = CGSize(width: 104, height: 104)
        /// 백드롭 중심 y (카드 좌표). 상단 엣지 36+52=88 < 카드 상단 +98 — 수납 보장.
        static let cardIllustrationBackdropOffsetY: CGFloat = 36

        // MARK: 일시정지 다이얼로그 v3 (P1-2 — 구 PrimaryButtonNode 오버레이 대체)
        /// 다이얼로그 패널 크기 (PixelDialogNode panelSize).
        static let pausePanelSize = CGSize(width: 320, height: 200)
        /// 패널 헤더 제목.
        static let pauseTitleText: String = "일시정지"
        /// 계속(primary) 버튼 텍스트.
        static let pauseResumeText: String = "계속"
        /// 메인(ghost) 버튼 텍스트.
        static let pauseExitText: String = "메인"
        /// 버튼 시각 크기 — 2개 병치(132×2 + 간격) < 패널 폭 320 수납.
        static let pauseButtonSize = CGSize(width: 132, height: 44)
        /// 버튼 행 중심 y (패널 좌표). 헤더 아래·패널 하단 안.
        static let pauseButtonRowY: CGFloat = -48
        /// 버튼 중심의 패널 중심으로부터의 가로 오프셋 (±).
        static let pauseButtonOffsetX: CGFloat = 78

        // MARK: Start 로고 ↔ 프로필 칩 겹침 보정 (P2-1 사)
        /// 로고 상단 엣지와 프로필 칩 하단 엣지 사이 최소 세로 간격 (pt).
        static let startLogoChipClearance: CGFloat = 8
    }
}
