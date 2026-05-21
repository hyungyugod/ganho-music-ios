//
//  IntroVillainCutsceneNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase H · 빌런 경고 컷씬 정적 팩토리 (introStoneGuard / introProfessor)
//
//  원본 game.js L226~L233 — intro dismiss 직후 난이도별 분기:
//  · easy/normal → introStoneGuard ("잡혀갑니다" 거짓 경고 — 실제로는 박병장 비행기 이스터에그)
//  · hard        → introProfessor ("청진기에 맞으면 정지" 진짜 경고)
//
//  CutsceneOverlayNode 본체 0줄 변경 + CutsceneTexts 단일 진실 원천 + Menlo-Bold 픽셀 폰트 주입.
//  자가 소멸 노드 정적 팩토리 패턴 — IntroCutsceneNode·MidCutsceneNode와 동형.
//

import SpriteKit

/// 빌런 경고 컷씬 정적 팩토리.
/// 호출부에서 `present(scene:difficulty:onDismiss:)` 한 줄이면 난이도 분기까지 끝남 —
/// 호출부 switch 코드 0(가독성·안전성↑).
enum IntroVillainCutsceneNode {

    /// 난이도에 따라 석조무사 또는 이교수 경고 컷씬 present.
    /// - Parameters:
    ///   - scene: 컷씬을 부착할 GameScene. scene.cameraNode 자식.
    ///   - difficulty: 난이도. easy/normal → introStoneGuard, hard → introProfessor.
    ///   - onDismiss: 사용자 탭 후 fadeOut 종료 시점 호출. 호출부에서 .countdown 전환 + showCountdown 책임.
    static func present(scene: GameScene,
                        difficulty: Difficulty,
                        onDismiss: @escaping () -> Void) {
        let texts: (title: String, body: String)
        switch difficulty {
        case .easy, .normal:
            texts = CutsceneTexts.introStoneGuard
        case .hard:
            texts = CutsceneTexts.introProfessor
        }
        CutsceneOverlayNode.present(
            title: texts.title,
            body: texts.body,
            parent: scene.cameraNode,
            sceneSize: scene.size,
            fontName: GameConfig.pixelCutsceneFontName,
            onDismiss: onDismiss
        )
    }
}
