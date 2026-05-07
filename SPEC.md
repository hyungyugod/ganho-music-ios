# Phase 2-12 — ScoreSystem 분리 (리팩터)

## 개요
GameScene의 score / combo / lastCollectAt 멤버 + 콤보 갱신 로직을 **ScoreSystem.swift**로 이전.
GameScene은 ScoreSystem 메서드를 *호출*만. **기능 변화 0**.

## 변경 유형
**리팩터** — 점수/콤보 책임 분리, 게임 동작 변화 0.

## Sprint 범위 계약

### 허용 (IN)
- 신설 1 파일: `Systems/ScoreSystem.swift`
- 수정 1 파일: `GanhoMusic Shared/GameScene.swift`
- pbxproj 1건: ScoreSystem.swift 등록

### 금지 (OUT)
- 기능 변화 0
- HUDNode 시그니처 변경 0
- 다른 Systems / Nodes / Config / iOS 3 파일 변경 0

## 변경 범위

### 신설 파일

```swift
//
//  ScoreSystem.swift
//  GanhoMusic Shared
//
//  Phase 2-12 · 점수 / 콤보 상태 + 갱신 로직 분리
//

import Foundation

/// 점수와 콤보 상태를 관리하는 시스템.
/// 외부(GameScene)는 read-only로 score/combo 조회 + 메서드로 상태 변경.
final class ScoreSystem {

    // MARK: - State (read-only 외부 노출)
    /// 현재 점수 (음표 수집 누적).
    private(set) var score: Int = 0
    /// 현재 콤보 (연속 수집 카운트).
    private(set) var combo: Int = 0
    /// 마지막 수집 시각. 콤보 윈도우 만료 검사에 사용. 0 = "아직 수집 0건".
    private var lastCollectAt: TimeInterval = 0

    // MARK: - Mutations
    /// 음표 1개 수집을 기록. 콤보 윈도우 검사 + 콤보 갱신 + 점수 가산.
    /// - Parameter now: 현재 게임 시각 (보통 lastUpdateTime).
    func recordNoteHit(at now: TimeInterval) {
        let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
        combo = isInWindow ? combo + 1 : 1
        score += combo >= GameConfig.comboBonusThreshold
            ? GameConfig.scorePerNoteCombo
            : GameConfig.scorePerNote
        lastCollectAt = now
    }

    /// 콤보 윈도우 만료 검사. update 안에서 매 프레임 호출.
    /// - Parameter currentTime: 현재 SpriteKit 시각.
    func tickComboExpiry(currentTime: TimeInterval) {
        if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
            combo = 0
        }
    }

    /// 모든 상태 리셋. 게임 재시작 등에서 사용 (Phase 3 이후).
    func reset() {
        score = 0
        combo = 0
        lastCollectAt = 0
    }
}
```

### GameScene 변경

#### 1. 멤버 제거 + 추가
```swift
// 제거 (3 멤버):
private var score: Int = 0
private var combo: Int = 0
private var lastCollectAt: TimeInterval = 0

// 추가:
private let scoreSystem = ScoreSystem()
```

#### 2. update 안 콤보 만료 검사 변경
```swift
// 기존 (2-11):
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}

// 변경 후 (2-12):
scoreSystem.tickComboExpiry(currentTime: currentTime)
```

#### 3. update 안 HUD 갱신 변경
```swift
// 기존:
hud.update(score: score, remainingTime: remainingTime, combo: combo)

// 변경 후:
hud.update(score: scoreSystem.score, remainingTime: remainingTime, combo: scoreSystem.combo)
```

#### 4. configureContactRouter의 onNoteCollected 콜백 변경
```swift
// 기존 (2-11):
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    let now = self.lastUpdateTime
    let isInWindow = self.combo > 0 && now - self.lastCollectAt < GameConfig.comboWindow
    self.combo = isInWindow ? self.combo + 1 : 1
    self.score += self.combo >= GameConfig.comboBonusThreshold
        ? GameConfig.scorePerNoteCombo
        : GameConfig.scorePerNote
    self.lastCollectAt = now
    note.run(.removeFromParent())
}

// 변경 후 (2-12):
contactRouter.onNoteCollected = { [weak self] note in
    guard let self = self else { return }
    self.scoreSystem.recordNoteHit(at: self.lastUpdateTime)
    note.run(.removeFromParent())
}
```

#### 5. endGame 안 HUD 호출 변경
```swift
// 기존:
hud.update(score: score, remainingTime: 0, combo: 0)

// 변경 후:
hud.update(score: scoreSystem.score, remainingTime: 0, combo: 0)
```
- **`combo: 0` 인자는 *그대로 유지***. endGame은 *시각 강제 0* 의도. scoreSystem.combo는 *진짜 상태*는 보존, 표시만 0.

## 준수 룰

| # | 룰 | 검증 |
|---|---|---|
| 1 | ScoreSystem.swift 신설 + final class | grep |
| 2 | private(set) score / combo + private lastCollectAt | grep |
| 3 | recordNoteHit(at:) 메서드 | grep |
| 4 | tickComboExpiry(currentTime:) 메서드 | grep |
| 5 | reset() 메서드 | grep |
| 6 | GameScene에서 score / combo / lastCollectAt 멤버 *제거* | grep 0건 |
| 7 | GameScene에 `private let scoreSystem = ScoreSystem()` 추가 | grep |
| 8 | update에서 scoreSystem.tickComboExpiry 호출 1건 | grep |
| 9 | onNoteCollected 콜백 본문이 *3줄로 단순화* (recordNoteHit + note.run) | diff |
| 10 | hud.update 호출 시 scoreSystem.score / scoreSystem.combo 사용 | grep |
| 11 | endGame의 hud.update에 `combo: 0` 인자 *그대로* | diff |
| 12 | 매직 넘버 0건 | grep |
| 13 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | grep |
| 14 | pbxproj ScoreSystem 등록 4지점 | grep |
| 15 | BUILD SUCCEEDED | xcodebuild |

## 회귀 보존

| 영역 | 변경 |
|---|---|
| Config 4 파일 | 0 |
| Nodes 6 파일 | 0 |
| Systems/SpawnSystem.swift / ContactRouter.swift | 0 |
| iOS 3 파일 | 0 |
| GameScene 의 setup* / didChangeSize / endGame (HUD 라인 외 그대로) | 0 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 |
| 콤보 산식 / 점수 산식 (모두 ScoreSystem.recordNoteHit으로 *그대로 이전*) | 0 |

## 기능 동등성

리팩터 전(2-11) vs 후(2-12):
- 음표 수집 → 콤보 갱신 + 점수 가산: ScoreSystem.recordNoteHit이 *기존 산식 그대로* 수행
- 콤보 윈도우 만료: ScoreSystem.tickComboExpiry가 *기존 가드 그대로* 수행
- HUD 표시: scoreSystem.score / scoreSystem.combo로 *값만 다른 출처*, 결과 동일
- endGame combo: 0 표시: 기존 그대로 (실제 콤보 상태는 *보존*, 표시만 0)

## 주의사항

- ScoreSystem 멤버는 `private(set)` — GameScene에서 *읽기만*. 변경은 메서드 통해서만.
- recordNoteHit은 *지금 시각*을 인자로 받음 — 시간 출처 분리 (테스트 용이).
- reset()은 본 sprint *호출 안 함*. Phase 3 게임 재시작에서 사용 예정.
- HUD endGame combo: 0은 *의도된 시각 표시* — scoreSystem.combo와 *별개* 처리.
