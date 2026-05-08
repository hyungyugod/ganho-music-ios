//
//  GameViewController.swift
//  GanhoMusic iOS
//
//  Created by HG on 5/2/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // self.view 가 SKView 가 아니면 즉시 알리고 안전하게 종료한다.
        // (강제 언래핑 `as!` 는 swift-rules.md §3 위반이라 사용하지 않음)
        guard let skView = self.view as? SKView else {
            assertionFailure("Root view must be SKView. Check Main.storyboard.")
            return
        }

        // Phase 3-1+2 — 첫 진입은 TitleScene. 사용자가 의도적으로 탭해야 GameScene 시작.
        let scene = TitleScene.newTitleScene()
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true

        // 디버그 오버레이는 DEBUG 빌드에서만 표시 (릴리즈에 노출 금지)
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif
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
