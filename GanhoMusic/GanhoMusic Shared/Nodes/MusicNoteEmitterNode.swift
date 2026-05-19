//
//  MusicNoteEmitterNode.swift
//  GanhoMusic Shared
//
//  Phase 10-2 · StartScene 모던 리스킨
//
//  떠다니는 음표 파티클 컨테이너. 화면 하단에서 살구색 ♪/♫/♩가 천천히 위로 떠오르며 fade.
//  SKAction.repeatForever로 스폰 — Timer 사용 0.
//  동시 표시 상한 GameConfig.musicNoteEmitterMaxConcurrent로 가드.
//  자식 음표가 화면 위로 사라지면 자가 removeFromParent — addChild 누적 없음.
//

import SpriteKit
import UIKit

/// 음표 파티클 컨테이너. SKNode 서브클래스 — 자식 SKLabelNode들을 스폰/관리.
/// 사용 패턴: StartScene에서 `MusicNoteEmitterNode(sceneSize: size)` 생성 후 addChild.
/// 씬 사이즈 변경 시 재생성 권장 — sceneSize 의존.
final class MusicNoteEmitterNode: SKNode {

    // MARK: - Properties
    /// 음표 스폰 좌표 계산에 사용되는 씬 사이즈. 컨테이너 자신은 (0,0)에 두고
    /// 자식 라벨을 sceneSize 범위 내에 배치하는 *컨테이너-내부 좌표계* 패턴.
    private let sceneSize: CGSize
    /// 현재 화면에 떠 있는 음표 개수. 상한 가드용. spawnOneNote 진입부에서 체크.
    /// 클로저에서 self?를 통해 감소 — 동시성 충돌 없음(SKAction은 메인스레드 직렬).
    private var activeCount: Int = 0
    /// 음표 글리프 후보. randomElement 실패 시 ♪ fallback.
    private let glyphCandidates: [String] = ["♪", "♫", "♩"]
    /// 스폰 액션 키. stopEmitting 시 제거용.
    private let spawnActionKey = "musicNoteSpawn"

    // MARK: - Init
    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()
        name = "musicNoteEmitter"
        zPosition = GameConfig.startSceneMusicNoteZPosition
        startEmitting()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Emission
    /// SKAction.repeatForever 스폰 시작. didMove 안 거치고 init에서 즉시 시작 —
    /// 컨테이너가 addChild되는 즉시 음표가 떠오르기 시작.
    private func startEmitting() {
        let spawn = SKAction.run { [weak self] in
            self?.spawnOneNote()
        }
        let wait = SKAction.wait(forDuration: GameConfig.musicNoteEmitterSpawnInterval)
        let sequence = SKAction.sequence([spawn, wait])
        run(SKAction.repeatForever(sequence), withKey: spawnActionKey)
    }

    /// 음표 1개 스폰. activeCount 상한 가드 → 라벨 생성 → 액션 시퀀스 부착.
    /// 모든 클로저 `[weak self]` — emitter 소멸 시 메모리 누수 0.
    private func spawnOneNote() {
        guard activeCount < GameConfig.musicNoteEmitterMaxConcurrent else { return }
        let glyph = glyphCandidates.randomElement() ?? "♪"
        let label = SKLabelNode(text: glyph)
        label.fontSize = GameConfig.musicNoteEmitterFontSize
        label.fontColor = .ganhoAccentCoral
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.alpha = 0
        let startX = CGFloat.random(in: 0...sceneSize.width)
        label.position = CGPoint(
            x: startX,
            y: GameConfig.musicNoteEmitterStartYOffset
        )
        addChild(label)
        activeCount += 1

        let drift = CGFloat.random(
            in: -GameConfig.musicNoteEmitterDriftRange...GameConfig.musicNoteEmitterDriftRange
        )
        let rise = SKAction.moveBy(
            x: drift,
            y: sceneSize.height + GameConfig.musicNoteEmitterRiseEndYMargin
                - GameConfig.musicNoteEmitterStartYOffset,
            duration: GameConfig.musicNoteEmitterRiseDuration
        )
        let fadeIn = SKAction.fadeAlpha(
            to: GameConfig.musicNoteEmitterMaxAlpha,
            duration: GameConfig.musicNoteEmitterFadeInDuration
        )
        let fadeOut = SKAction.fadeOut(
            withDuration: GameConfig.musicNoteEmitterFadeOutDuration
        )
        // rise와 병렬로 진행되, 상승 종료 직전에 fadeOut 시작.
        let fadeOutDelay = max(
            0,
            GameConfig.musicNoteEmitterRiseDuration
                - GameConfig.musicNoteEmitterFadeOutDuration
        )
        let waitThenFadeOut = SKAction.sequence([
            SKAction.wait(forDuration: fadeOutDelay),
            fadeOut
        ])
        let riseAndFade = SKAction.group([rise, waitThenFadeOut])
        let decrement = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.activeCount = max(0, self.activeCount - 1)
        }
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([fadeIn, riseAndFade, decrement, remove]))
    }

    // MARK: - Control
    /// 스폰 중단. 씬 전환 시 호출 — 액션 키만 제거하고 떠 있는 음표는 자가 정리.
    func stopEmitting() {
        removeAction(forKey: spawnActionKey)
    }
}
