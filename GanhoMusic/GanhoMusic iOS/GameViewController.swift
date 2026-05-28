//
//  GameViewController.swift
//  GanhoMusic iOS
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    private let accountRepository = FirebaseAccountRepository()
    private let showLoginPageNotification = Notification.Name("GanhoMusicShowLoginPage")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // self.view 가 SKView 가 아니면 즉시 알리고 안전하게 종료한다.
        // (강제 언래핑 `as!` 는 swift-rules.md §3 위반이라 사용하지 않음)
        guard let skView = self.view as? SKView else {
            assertionFailure("Root view must be SKView. Check Main.storyboard.")
            return
        }

        // root view(SKView)는 iOS가 윈도우 전체에 자동 mount한다. frame을 직접 만지면
        // safeAreaInsets 재계산 → viewSafeAreaInsetsDidChange 재호출 → frame 재설정의
        // 무한 재귀가 발생한다(2026-05 사고). 잘림 해소가 필요하면 SKScene 측에서
        // view.safeAreaInsets를 받아 노드 배치 시 회피해야 한다.

        skView.ignoresSiblingOrder = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showLoginPageFromNotification),
            name: showLoginPageNotification,
            object: nil
        )

        if accountRepository.currentAuthMode() == .personal {
            presentStartScene()
        } else {
            showLoginPage(animated: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func presentStartScene() {
        guard let skView = view as? SKView else { return }
        let scene = StartScene.newStartScene()
        skView.presentScene(scene, transition: .fade(withDuration: GameConfig.sceneTransitionDuration))
    }

    @objc private func showLoginPageFromNotification() {
        showLoginPage(animated: true)
    }

    private func showLoginPage(animated: Bool) {
        view.subviews
            .compactMap { $0 as? LoginOverlayView }
            .forEach { $0.removeFromSuperview() }

        let page = LoginOverlayView(frame: view.bounds)
        page.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        page.alpha = animated ? 0 : 1
        page.onFinished = { [weak self] in
            self?.presentStartScene()
        }
        view.addSubview(page)
        if animated {
            UIView.animate(withDuration: 0.22) {
                page.alpha = 1
            }
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

    // MARK: - SafeArea Policy
    /// SKView frame은 직접 만지지 않는다(2026-05 무한재귀 사고 기록).
    /// safeArea 회피는 각 SKScene이 view.safeAreaInsets를 읽어 노드 좌표에 가산하는 방식만 허용.
    /// 본 메서드는 정책을 코드에 명시하기 위해 존재 — 본문은 super 호출만.
    /// 실제 회피 로직은 `SceneSafeArea.insets(for:)`를 거쳐 각 씬의 `layoutXxx()`가 담당.
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // 의도적 no-op. SKScene가 SceneSafeArea.insets(for:)로 직접 읽는다.
    }
}
