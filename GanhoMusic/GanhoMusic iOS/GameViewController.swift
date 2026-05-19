//
//  GameViewController.swift
//  GanhoMusic iOS
//
//  Created by HG on 5/2/26.
//
//  Sprint 7 · 잘림 해소 + 카드 시인성 강화
//   - SKView를 view.safeAreaLayoutGuide.layoutFrame에 mount하여
//     iPhone 17 Pro landscape의 Dynamic Island / 홈 인디케이터 영역 침범 제거.
//   - view.backgroundColor에 .ganhoBgWarmTop를 fallback으로 깔아 노치 영역
//     비주얼 연속성을 유지(그라데이션 배경은 safe area 안에서만 그려짐).
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sprint 7 — 시스템 보장 fallback. safe area 바깥(노치/홈 인디케이터 영역)에서도
        // warm 톤이 유지되도록 view.backgroundColor에 그라데이션 top 색을 깐다.
        // GradientBackgroundNode는 SKView frame을 따라가므로 노치 영역은 비게 되며,
        // 이 fallback이 시각 연속성을 책임진다.
        view.backgroundColor = .ganhoBgWarmTop

        // self.view 가 SKView 가 아니면 즉시 알리고 안전하게 종료한다.
        // (강제 언래핑 `as!` 는 swift-rules.md §3 위반이라 사용하지 않음)
        guard let skView = self.view as? SKView else {
            assertionFailure("Root view must be SKView. Check Main.storyboard.")
            return
        }

        // Sprint 7 — Storyboard 풀스크린 제약을 코드 frame으로 override.
        // safe area 인셋이 viewDidLoad 시점엔 .zero 일 수 있으므로
        // 실제 정확한 frame은 viewDidLayoutSubviews / viewSafeAreaInsetsDidChange에서 다시 적용한다.
        skView.translatesAutoresizingMaskIntoConstraints = true
        skView.autoresizingMask = []   // 자동 리사이즈 끔 — relayoutSKView가 직접 조정
        skView.frame = view.safeAreaLayoutGuide.layoutFrame

        // Phase 10-1a — 첫 진입은 StartScene (구 TitleScene → 4단계 분리 시작점).
        // 사용자가 *시작 버튼*을 명시 탭해야 다음 단계(CharacterSelect)로 진행.
        let scene = StartScene.newStartScene()
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true

        // 디버그 오버레이는 DEBUG 빌드에서만 표시 (릴리즈에 노출 금지)
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
    }

    /// Sprint 7 — 회전 / multitasking으로 safe area inset이 바뀔 때 SKView도 따라간다.
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        relayoutSKView()
    }

    /// Sprint 7 — 첫 layout 패스에서 safeAreaLayoutGuide.layoutFrame이 확정된 시점에
    /// SKView frame을 다시 한 번 정렬. 회전 후에도 호출된다.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        relayoutSKView()
    }

    // MARK: - Safe Area Relayout (Sprint 7)

    /// SKView frame을 view.safeAreaLayoutGuide.layoutFrame에 동기화.
    /// frame 동일성 체크로 didChangeSize 무한 호출을 막는다.
    private func relayoutSKView() {
        guard let skView = self.view as? SKView else { return }
        let target = view.safeAreaLayoutGuide.layoutFrame
        // 동일 frame이면 skip — SKScene.didChangeSize 폭주 방지.
        if skView.frame != target {
            skView.frame = target
        }
    }

    // MARK: - Orientation

    /// iPhone Landscape 전용 게임. 회전을 가로로만 허용한다.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    // MARK: - Status Bar / Home Indicator

    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// 풀스크린 게임 경험을 위해 홈 인디케이터를 자동 숨김.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// 화면 가장자리에서 시스템 제스처(스와이프 업 등) 인식을 한 번 늦춰
    /// 게임 입력과 충돌하지 않도록 한다.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom, .top]
    }
}
