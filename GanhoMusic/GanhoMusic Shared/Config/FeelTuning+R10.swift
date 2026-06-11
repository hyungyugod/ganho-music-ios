//
//  FeelTuning+R10.swift
//  GanhoMusic Shared
//
//  R10 — 박병장 데뷔 연출 강화(U5: 스팅어·토스트 스탬프·방향성 킥·체류 셰이크) +
//  우정 스토리(U6: 컷씬 카메오·이스터에그 상호 인사 말풍선) 토큰. 카피 상수 포함 —
//  호출부 리터럴 0 (매직넘버 금지). R5/R9 nested enum 컨벤션 답습.
//

import Foundation
import CoreGraphics

extension FeelTuning {
    /// R10 연출 튜닝·카피 토큰 네임스페이스. case 없는 enum — 인스턴스화 차단.
    enum R10 {
        // MARK: U5 ① 데뷔 스팅어 (ChiptuneSynth.Voice.sergeantDebut — init 사전 렌더 전용)
        /// 스팅어 첫음 MIDI (G2 = 43). 거물 등장 — 기존 voice 최저음(C4=60)보다 한참 아래.
        static let sfxSergeantDebutMidiLow: Int = 43
        /// 스팅어 끝음 MIDI (C3 = 48). 완전4도 상행 — 군용 나팔(두움·빠암) 톤.
        static let sfxSergeantDebutMidiHigh: Int = 48
        /// 스팅어 첫음 길이 (초).
        static let sfxSergeantDebutShortToneDuration: TimeInterval = 0.18
        /// 스팅어 끝음 길이 (초). 총 0.18+0.32 = 0.5s — 컷씬 fadeIn(0.4s)과 hold 초입에 걸침.
        static let sfxSergeantDebutLongToneDuration: TimeInterval = 0.32

        // MARK: U5 ② 토스트 스탬프 등장 (easeOutBack — fadeIn 구간 내 병행 액션)
        /// 토스트 시작 스케일. 1.4 → 1.0 수축 — 도장 찍히는 무게감 (ResultScene verdict 전례).
        static let sergeantToastStampStartScale: CGFloat = 1.4
        /// 스탬프 수축 길이 (초). 컷씬 fadeIn(0.4s)과 동일 — fade 시퀀스 타이밍 무접촉.
        static let sergeantToastStampDuration: TimeInterval = 0.4

        // MARK: U5 ③ 방향성 킥 (본 노드 진입 시작 시)
        /// 박병장 우→좌 진입 — 카메라 좌향 킥 단위 벡터 (CameraDirector.kick 인자).
        static let sergeantEntryKickDirection = CGVector(dx: -1, dy: 0)

        // MARK: U6 C-1 컷씬 석조무사 카메오 (시각 전용 — physicsBody nil, overlay 자식 자가 소멸)
        /// 카메오 스케일. 클로즈업(2.0)보다 작게 — "무전으로 부른 친구"의 원경감.
        static let sergeantIntroCameoScale: CGFloat = 1.2
        /// 카메오 x 오프셋 (overlay 좌표, 클로즈업 중심 기준 좌측).
        static let sergeantIntroCameoOffsetX: CGFloat = -116
        /// 카메오 y 오프셋. 클로즈업보다 살짝 아래 — 스케일 차이의 원근 정렬.
        static let sergeantIntroCameoOffsetY: CGFloat = -14

        // MARK: U6 C-2 이스터에그 상호 인사 (FriendGreetingNode — 자가 소멸 11호)
        // 카피 초안 1 채택 — ⚠️ 사용자 검수 권장 포인트 (말풍선 ≤10자/개).
        /// 석조무사 말풍선 카피.
        static let friendGreetingStoneGuardText: String = "왔는가, 병장."
        /// 박병장 말풍선 카피.
        static let friendGreetingSergeantText: String = "맡겨라, 친구!"
        /// 석조무사 말풍선 y 오프셋 (석조무사 자식 좌표 — 픽셀 본체 40pt 위 여백).
        static let friendGreetingStoneGuardOffsetY: CGFloat = 34
        /// 석조무사 말풍선 상대 zPosition (석조무사 z=5 기준 자식 — 월드 요소 위로).
        static let friendGreetingLocalZPosition: CGFloat = 10
        /// 박병장 말풍선 x 오프셋 (cameraNode 좌표 — 클로즈업 우측 옆).
        static let friendGreetingSergeantOffsetX: CGFloat = 104
        /// 박병장 말풍선 y 오프셋 (sergeantCloseupOffsetY 기준 위쪽 가산).
        static let friendGreetingSergeantOffsetY: CGFloat = 30
        /// 박병장 말풍선 zPosition — 클로즈업(210) 바로 위.
        static let friendGreetingOverlayZPosition: CGFloat = ZOrder.sergeantCloseupZPosition + 1
        /// 두 번째 말풍선(박병장)·스파크 지연 (초). 클로즈업 fadeIn(0.1s) 후 — 문답 호흡.
        static let friendGreetingSecondDelay: TimeInterval = 0.7
        /// 말풍선 등장 페이드 길이 (초).
        static let friendGreetingFadeInDuration: TimeInterval = 0.15
        /// 말풍선 완전 노출 유지 길이 (초). 0.7 지연 + 1.4 수명 = 2.1s ≤ 클로즈업 2.2s 수납.
        static let friendGreetingHoldDuration: TimeInterval = 1.0
        /// 말풍선 퇴장 페이드 길이 (초).
        static let friendGreetingFadeOutDuration: TimeInterval = 0.25
        /// 말풍선 팝 시작 스케일 (easeOutBack 1.0 도달 — 등장 펀치).
        static let friendGreetingPopStartScale: CGFloat = 0.7
        /// 말풍선 꼬리 삼각형 가로/세로 (pt). 칩 하단 중앙 — "말풍선" 시그널.
        static let friendGreetingTailWidth: CGFloat = 10
        static let friendGreetingTailHeight: CGFloat = 6
    }
}
