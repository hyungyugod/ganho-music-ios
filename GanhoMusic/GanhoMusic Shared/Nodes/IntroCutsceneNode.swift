//
//  IntroCutsceneNode.swift
//  GanhoMusic Shared
//
//  Sprint 10 Phase H · 인트로 컷씬 정적 팩토리 (자가 소멸 노드 답습)
//
//  원본 game.js L2268 — startGame 직후 250ms 후 인트로 컷씬 표시.
//  CutsceneOverlayNode 본체 0줄 변경 + CutsceneTexts 단일 진실 원천 + Menlo-Bold 픽셀 폰트 주입.
//
//  자가 소멸 노드 정적 팩토리 패턴(IntroVillainCutsceneNode·MidCutsceneNode와 동형) —
//  외부에 인스턴스 노출 0, 정적 메서드 1개로 모든 호출이 끝남.
//

import SpriteKit

/// 인트로 컷씬 250ms 지연 + 본문 lookup + 폰트 주입을 한 함수로 묶은 정적 팩토리.
/// Spring 비유: Spring MVC interceptor의 preHandle — 본 비즈니스 로직(게임 시작) *직전*에
/// 짧은 호흡을 두고 사용자 정체성을 환기. 한 번의 응답(탭) 후 자동 dispose.
enum IntroCutsceneNode {

    /// 인트로 컷씬을 250ms 지연 후 present.
    /// - Parameters:
    ///   - scene: 컷씬을 부착할 GameScene. scene.cameraNode 자식으로 표시.
    ///   - character: 캐릭터별 본문 분기 — CutsceneTexts.intro lookup.
    ///   - difficulty: 난이도별 본문 분기 — easy/normal vs hard.
    ///   - delay: present 직전 대기 시간. 기본값 GameConfig.cutsceneIntroDelay (0.25s) — 원본 L2268.
    ///   - onDismiss: 사용자 탭 후 fadeOut 종료 시점에 호출. [weak self] 캡처는 호출부 책임.
    static func present(scene: GameScene,
                        character: CharacterID,
                        difficulty: Difficulty,
                        delay: TimeInterval = GameConfig.cutsceneIntroDelay,
                        onDismiss: @escaping () -> Void) {
        let texts = CutsceneTexts.intro(difficulty: difficulty, character: character)
        // SKAction.wait → SKAction.run 시퀀스. scene 자체에 run하므로 scene 해제 시 자동 멈춤.
        // [weak scene] 캡처 — 250ms 동안 씬 전환 가능성 대비 (자가 해제 안전망).
        let wait = SKAction.wait(forDuration: delay)
        let attach = SKAction.run { [weak scene] in
            guard let scene = scene else { return }
            CutsceneOverlayNode.present(
                title: texts.title,
                body: texts.body,
                parent: scene.cameraNode,
                sceneSize: scene.size,
                fontName: GameConfig.pixelCutsceneFontName,
                onDismiss: onDismiss
            )
        }
        scene.run(.sequence([wait, attach]))
    }
}
