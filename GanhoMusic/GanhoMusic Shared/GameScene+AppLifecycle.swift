//
//  GameScene+AppLifecycle.swift
//  GanhoMusic Shared
//
//  R9 #2 — 백그라운드 전환 자동 일시정지 (UIApplication 노티 직구독 — BGMPlayer selector 전례,
//  SceneDelegate 무변경) + R9 #1 진입점 ② 인게임 설정 다이얼로그 제시
//  (+GameState 300줄 상한 보호 — 동거 배치, SPEC §#1-6).
//

import SpriteKit
import UIKit

extension GameScene {

    // MARK: - App Lifecycle (#2 — 배선만: 동결/복원·입력 차단은 기존 v3 일시정지 경로 byte-보존)
    /// didMove 1회 등록. selector 방식 — NotificationCenter는 옵저버를 강참조하지 않아
    /// 토큰 프로퍼티 불요 (BGMPlayer 전례). 해제는 willMove(removeObserver)와 쌍.
    func setupAppLifecycleObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    /// 전화 수신·홈 전환 등 → 자동 일시정지. presentPauseMenu 내부 가드
    /// (pauseDialog == nil, gameState == .playing)가 상태 분기를 전부 처리 —
    /// 카운트다운/컷씬/게임오버/이미 일시정지 중에는 자연 noop (이중 발화 0).
    @objc private func handleAppWillResignActive() {
        presentPauseMenu()
    }

    /// 씬 이탈 시 옵저버 해제 (등록/해제 쌍). removeObserver(self) 일괄 —
    /// GameScene의 selector 방식 옵저버는 이것뿐이라 안전 (SPEC §#2-1).
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - In-Game Settings (#1 진입점 ② — 일시정지 [설정] 버튼이 호출)
    /// cameraNode 부착 — worldNode 비소속이라 동결(isPaused) 중에도 등장 애니 정상 구동.
    /// z = settingsDialogZPosition(430): pauseDialog(420) 위 — 딤이 일시정지 버튼 터치 흡수.
    /// 설정 닫기 → 일시정지 다이얼로그 그대로 유지 (게임은 이미 동결 — 추가 상태 조작 0).
    func presentInGameSettingsDialog() {
        guard settingsDialog == nil else { return }
        let dialog = SettingsDialogNode(haptics: haptics)
        dialog.zPosition = ZOrder.settingsDialogZPosition
        dialog.onClose = { [weak self] in self?.settingsDialog = nil }
        settingsDialog = dialog
        dialog.present(in: cameraNode, screenSize: size, position: .zero)
    }
}
