//
//  MidCutsceneNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase H · 중반 컷씬 정적 팩토리 (mid1 / mid2)
//
//  원본 game.js L2417/L2469 — timeLeft 임계 도달 시 1회 발화.
//  · mid1: timeLeft ≤ 30 (캐릭터별 속마음)
//  · mid2: timeLeft ≤ 15 ("수간호사의 눈초리" 공통)
//
//  CutsceneOverlayNode 본체 0줄 변경 + CutsceneTexts 단일 진실 원천 + Menlo-Bold 픽셀 폰트 주입.
//  자가 소멸 노드 정적 팩토리 패턴 — IntroCutsceneNode·IntroVillainCutsceneNode와 동형.
//

import SpriteKit

/// 중반 컷씬 2종(mid1·mid2) 정적 팩토리.
/// mid1은 캐릭터별 분기, mid2는 캐릭터 비독립 공통. 두 메서드 모두 정적 — 인스턴스 0.
enum MidCutsceneNode {

    /// mid1 (timeLeft ≤ 30) — 캐릭터별 속마음 컷씬.
    /// - Parameters:
    ///   - scene: 컷씬을 부착할 GameScene. scene.cameraNode 자식.
    ///   - character: 캐릭터별 본문 분기 — CutsceneTexts.mid1 lookup.
    ///   - onDismiss: 사용자 탭 후 fadeOut 종료 시점 호출. 호출부에서 .playing 복귀 책임.
    static func presentMid1(scene: GameScene,
                            character: CharacterID,
                            onDismiss: @escaping () -> Void) {
        let texts = CutsceneTexts.mid1(character: character)
        CutsceneOverlayNode.present(
            title: texts.title,
            body: texts.body,
            parent: scene.cameraNode,
            sceneSize: scene.size,
            fontName: GameConfig.pixelCutsceneFontName,
            onDismiss: onDismiss
        )
    }

    /// mid2 (timeLeft ≤ 15) — "수간호사의 눈초리" 공통 컷씬.
    /// 캐릭터/난이도 분기 0 — CutsceneTexts.mid2 정적 상수 직접 사용.
    /// - Parameters:
    ///   - scene: 컷씬을 부착할 GameScene.
    ///   - onDismiss: 사용자 탭 후 fadeOut 종료 시점 호출. 호출부에서 .playing 복귀 책임.
    static func presentMid2(scene: GameScene,
                            onDismiss: @escaping () -> Void) {
        let texts = CutsceneTexts.mid2
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
