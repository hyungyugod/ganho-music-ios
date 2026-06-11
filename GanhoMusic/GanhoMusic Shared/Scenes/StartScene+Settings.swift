//
//  StartScene+Settings.swift
//  GanhoMusic Shared
//
//  R9 #1 진입점 ① — Start 우상단 설정 버튼 + SettingsDialogNode 제시.
//  본체(StartScene.swift)는 stored property·호출 1줄씩만 증분 (309줄 기존 부채 — 분할은 R13).
//

import SpriteKit

extension StartScene {

    // MARK: - Settings Button (ghost compact — 프로필 칩 아래 적층, 우측 엣지 정렬)
    func setupSettingsButton() {
        let button = PixelButtonNode(title: UILayout.R9.settingsTitleText,
                                     variant: .ghost,
                                     size: UILayout.R9.startSettingsButtonSize)
        button.onTap = { [weak self] in self?.presentSettingsDialog() }
        button.zPosition = ZOrder.Layer.hud
        settingsButton = button
        addChild(button)
        layoutSettingsButton()
        // DEBUG 부팅 분기(GANHO_BOOT_SCENE=startSettings) — 스크린샷 자동화용 즉시 오픈.
        if shouldOpenSettingsOnEntry {
            shouldOpenSettingsOnEntry = false
            presentSettingsDialog()
        }
    }

    /// 우상단 — 프로필 칩(v3ScreenEdgeInset 우측 엣지)과 동일 엣지 정렬 + 칩 아래 적층.
    /// y는 고정 inset (칩은 인증 로드 후 비동기 생성 — 칩 유무와 무관한 단일 좌표).
    func layoutSettingsButton() {
        guard let button = settingsButton else { return }
        let safe = menuSafeInsets()
        let scale = menuCompactScale()
        button.setScale(scale)
        button.position = CGPoint(
            x: (frame.maxX - safe.right - UILayout.v3ScreenEdgeInset
                - UILayout.R9.startSettingsButtonSize.width * scale / 2).rounded(),
            y: (frame.maxY - safe.top - UILayout.R9.startSettingsButtonTopInset * scale).rounded()
        )
    }

    // MARK: - Settings Dialog
    /// 다이얼로그 제시 — zPosition 기본(wrapper 0 + PixelDialog overlay 200, loginDialog 동형).
    /// StartScene엔 경합 다이얼로그 z 없음 — 신규 z 상수 불요.
    func presentSettingsDialog() {
        guard settingsDialog == nil, loginDialog == nil, !isTransitioning else { return }
        let dialog = SettingsDialogNode()
        dialog.onClose = { [weak self] in self?.settingsDialog = nil }
        settingsDialog = dialog
        dialog.present(in: self, screenSize: size,
                       position: CGPoint(x: frame.midX, y: frame.midY))
        #if DEBUG
        // 스크린샷 자동화 — GANHO_SETTINGS_CREDITS=1이면 크레딧 모드 직행 (릴리즈 경로 0).
        if ProcessInfo.processInfo.environment["GANHO_SETTINGS_CREDITS"] == "1" {
            dialog.debugShowCredits()
        }
        #endif
    }
}
