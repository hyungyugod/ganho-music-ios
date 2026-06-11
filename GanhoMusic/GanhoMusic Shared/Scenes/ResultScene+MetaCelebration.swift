//
//  ResultScene+MetaCelebration.swift
//  GanhoMusic Shared
//
//  R7 §F5/F6 — 캐릭터 해금 배너 + 업적 달성 토스트 순차 연출.
//  전부 revealCompleted 합류점 *이후* 발화 — R5 6단계 타이밍·스킵 멱등 구조 diff 0 (SPEC 주의 5).
//  ResultScene+Reveal(301줄) 한도로 별도 분리 — 300줄 규칙 (본 파일 책임: 메타 보상 연출만).
//

import SpriteKit

extension ResultScene {

    /// 순차 연출 시퀀스 액션 키 — 씬 소유 SKAction (Timer/asyncAfter 금지).
    private static let metaCelebrationKey = "r7MetaCelebration"

    /// revealButtons(정상 완료·스킵 공용 단일 합류점)의 revealCompleted 확정 직후 1회 호출.
    /// 해금 배너(메타 루프 최대 보상)가 업적 토스트보다 *먼저* (SPEC §F6 — 더 큰 보상 우선).
    /// 재발화 0: Scoreboard 복귀 시 runMetaForReturn이 newAchievements/newlyUnlockedCharacters를
    /// 빈 배열로 소거 — items가 비어 자연 noop.
    func startMetaCelebrationSequence() {
        guard let runMeta = runMeta else { return }
        var items: [(text: String, isUnlock: Bool)] = []
        for characterID in runMeta.newlyUnlockedCharacters {
            items.append(("\(characterID.displayName)\(UILayout.R7.resultUnlockBannerSuffix)", true))
        }
        for achievement in runMeta.newAchievements {
            items.append(("\(UILayout.R7.resultAchievementToastPrefix)\(achievement.displayName)", false))
        }
        guard !items.isEmpty else { return }
        var actions: [SKAction] = [.wait(forDuration: FeelTuning.R7.metaToastFirstDelay)]
        for item in items {
            actions.append(SKAction.run { [weak self] in
                self?.presentMetaToast(text: item.text, isUnlock: item.isUnlock)
            })
            actions.append(.wait(forDuration: FeelTuning.R7.metaToastInterval))
        }
        run(.sequence(actions), withKey: Self.metaCelebrationKey)
    }

    /// 토스트 1장 — 등장(슬라이드+페이드 easeOutCubic) → 유지 → 퇴장 → removeFromParent (좀비 0).
    /// 동시 1장: interval(1.6s) ≥ 장당 수명(1.5s). 위치는 발화 시점 frame 기준 —
    /// 회전 중에는 SKAction 자연 진행 (비상주 ~1.5s 노드라 layoutAll 비합류, SPEC 주의 5).
    /// 좌상단 코너 앵커 — 중앙 상단은 컨텍스트 칩·verdict와 겹침 실측 → 빈 코너로 회피.
    private func presentMetaToast(text: String, isUnlock: Bool) {
        let chip = PixelChipNode(
            text: text,
            style: .accent(isUnlock ? Palette.gold : Palette.mint)
        )
        // 졸업장 오버레이(diplomaZPosition 300) *아래* — 졸업장 터치 흡수 계약 침범 금지 (SPEC §F5).
        chip.zPosition = ZOrder.Layer.overlay
        let safe = menuSafeInsets()
        let target = CGPoint(
            x: (frame.minX + safe.left + UILayout.v3ScreenEdgeInset
                + chip.chipSize.width / 2).rounded(),
            y: frame.maxY - UILayout.R7.resultMetaToastTopInset
        )
        chip.position = CGPoint(x: target.x, y: target.y + FeelTuning.R7.metaToastSlideDistance)
        chip.alpha = 0   // 등장 애니 시작값 — 즉시 fade-in 진행 (좀비 아님, levelUpChip 전례)
        addChild(chip)
        // 사운드·햅틱 — 기존 Voice 재사용 (ChiptuneSynth 신규 Voice 금지, SPEC 범위 계약).
        synth.play(isUnlock ? .starReveal(index: FeelTuning.R7.metaToastUnlockVoiceIndex) : .uiTap)
        if isUnlock {
            haptics.starPop()
        } else {
            haptics.medium()
        }
        let appear = SKAction.group([
            Tween.curved(SKAction.moveTo(y: target.y,
                                         duration: FeelTuning.R7.metaToastAppearDuration),
                         .easeOutCubic),
            SKAction.fadeIn(withDuration: FeelTuning.R7.metaToastAppearDuration)
        ])
        let hold = SKAction.wait(forDuration: FeelTuning.R7.metaToastHoldDuration)
        let exit = SKAction.group([
            Tween.curved(SKAction.moveTo(y: target.y + FeelTuning.R7.metaToastSlideDistance,
                                         duration: FeelTuning.R7.metaToastExitDuration),
                         .easeOutCubic),
            SKAction.fadeOut(withDuration: FeelTuning.R7.metaToastExitDuration)
        ])
        chip.run(.sequence([appear, hold, exit, .removeFromParent()]))
    }
}
