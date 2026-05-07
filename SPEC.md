# Phase 2-11 — ContactRouter 분리 (리팩터)

## 개요
GameScene의 `didBegin` / `handleProjectileContact` / `handleNoteContact`를 **ContactRouter.swift**로 이전.
콜백 4개로 효과는 GameScene에 위임. **기능 변화 0**.

## 변경 유형
**리팩터** — 충돌 분기 책임 분리, 게임 동작 변화 0.

## Sprint 범위 계약

### 허용 (IN)
- 신설 1 파일: `Systems/ContactRouter.swift`
- 수정 1 파일: `GanhoMusic Shared/GameScene.swift`
- pbxproj 1건: ContactRouter.swift 등록

### 금지 (OUT)
- 기능 변화 0
- 콤보/점수 상태 분리 → 다음 sprint(2-12 ScoreSystem)
- 다른 노드 / Config / iOS 3 파일 / SpawnSystem 변경 0

## 변경 범위

### 신설 파일

```swift
//
//  ContactRouter.swift
//  GanhoMusic Shared
//
//  Phase 2-11 · 충돌 처리 분기를 GameScene에서 분리
//

import SpriteKit

/// SpriteKit 물리 충돌 알림(SKPhysicsContactDelegate)을 받아 카테고리별로 분기.
/// 효과는 콜백으로 위임 — GameScene 직접 모름. 결합도 ↓.
/// NSObject 상속 필수 (SKPhysicsContactDelegate가 Obj-C 프로토콜).
final class ContactRouter: NSObject, SKPhysicsContactDelegate {

    // MARK: - Callbacks
    /// player ↔ enemy 접촉 시.
    var onEnemyHit: () -> Void = {}
    /// player ↔ projectile 접촉 시.
    var onProjectileHitPlayer: () -> Void = {}
    /// projectile ↔ wall 접촉 시. 인자: 제거할 projectile 노드.
    var onProjectileHitWall: (SKNode) -> Void = { _ in }
    /// player ↔ note 접촉 시. 인자: 제거할 note 노드.
    var onNoteCollected: (SKNode) -> Void = { _ in }

    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories & PhysicsCategory.enemy != 0 {
            onEnemyHit()
            return
        }
        if categories & PhysicsCategory.projectile != 0 {
            handleProjectileContact(contact)
            return
        }
        if categories & PhysicsCategory.note != 0 {
            handleNoteContact(contact)
        }
    }

    // MARK: - Private
    private func handleProjectileContact(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if categories & PhysicsCategory.player != 0 {
            onProjectileHitPlayer()
            return
        }
        if categories & PhysicsCategory.wall != 0 {
            let projectileBody = contact.bodyA.categoryBitMask == PhysicsCategory.projectile
                ? contact.bodyA
                : contact.bodyB
            guard let node = projectileBody.node else { return }
            onProjectileHitWall(node)
        }
    }

    private func handleNoteContact(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let noteBody: SKPhysicsBody?
        if bodyA.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyA
        } else if bodyB.categoryBitMask == PhysicsCategory.note {
            noteBody = bodyB
        } else {
            noteBody = nil
        }
        guard let node = noteBody?.node else { return }
        onNoteCollected(node)
    }
}
```

### GameScene 변경

#### 1. 클래스 선언 — `SKPhysicsContactDelegate` 채택 제거
```swift
// 기존
class GameScene: SKScene, SKPhysicsContactDelegate {

// 변경 후
class GameScene: SKScene {
```

#### 2. 멤버 추가
```swift
// 노드 트리 다음
private let spawnSystem = SpawnSystem()       // (2-10 그대로)
private let contactRouter = ContactRouter()   // Phase 2-11
```

#### 3. didMove 변경
```swift
// 기존:
physicsWorld.contactDelegate = self   // Phase 2-3

// 변경 후:
configureContactRouter()              // 콜백 등록
physicsWorld.contactDelegate = contactRouter
```

#### 4. configureContactRouter 신설
```swift
/// ContactRouter의 4개 콜백을 등록. didMove 안에서 1회 호출.
/// 콤보/점수 로직은 onNoteCollected 콜백 안에 *그대로 인라인* — Phase 2-12에서 분리 예정.
private func configureContactRouter() {
    contactRouter.onEnemyHit = { [weak self] in
        self?.endGame()
    }
    contactRouter.onProjectileHitPlayer = { [weak self] in
        self?.endGame()
    }
    contactRouter.onProjectileHitWall = { node in
        node.run(.removeFromParent())
    }
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
}
```

#### 5. 3개 메서드 *제거*
- `func didBegin(_ contact: SKPhysicsContact)` 통째로 제거
- `private func handleProjectileContact(_ contact: SKPhysicsContact)` 제거
- `private func handleNoteContact(_ contact: SKPhysicsContact)` 제거

`// MARK: - Contact` 섹션 제거.

## 준수 룰

| # | 룰 | 검증 |
|---|---|---|
| 1 | ContactRouter.swift 신설 + final class + NSObject + SKPhysicsContactDelegate | grep |
| 2 | 콜백 4개 (onEnemyHit / onProjectileHitPlayer / onProjectileHitWall / onNoteCollected) | grep |
| 3 | didBegin 본문 — 분기 우선순위 enemy → projectile → note | diff |
| 4 | handleProjectileContact / handleNoteContact 본문 — 기존 GameScene과 동등 | diff |
| 5 | GameScene에서 SKPhysicsContactDelegate 채택 *제거* | grep |
| 6 | GameScene에서 didBegin / handleProjectileContact / handleNoteContact *제거* | grep 0건 |
| 7 | configureContactRouter 신설 + didMove에서 호출 1건 | grep |
| 8 | physicsWorld.contactDelegate = contactRouter | grep |
| 9 | 콜백 등록 4건 + [weak self] 캡처 (3건 — onProjectileHitWall은 self 미사용이라 제외) | grep |
| 10 | 콤보/점수 로직 onNoteCollected 안에 *기존 그대로* (lastUpdateTime, combo, lastCollectAt, scorePerNote/Combo, comboBonusThreshold, comboWindow) | diff |
| 11 | 매직 넘버 0건 | grep |
| 12 | 강제 언래핑 / Timer / print / as! / fileprivate / DispatchQueue 0건 | grep |
| 13 | pbxproj ContactRouter 등록 4지점 | grep |
| 14 | BUILD SUCCEEDED | xcodebuild |

## 회귀 보존

| 영역 | 변경 |
|---|---|
| Config 4 파일 | 0 |
| Nodes 6 파일 | 0 |
| Systems/SpawnSystem.swift | 0 |
| iOS 3 파일 | 0 |
| GameScene 의 setup* / didChangeSize / update / endGame | 0 |
| HUDNode `update(score:remainingTime:combo:)` 시그니처 | 0 |
| 콤보/점수 멤버 (combo / score / lastCollectAt) | 0 (위치 그대로, 다음 sprint에서 ScoreSystem으로 이전) |

## 기능 동등성

리팩터 전(2-10) vs 후(2-11):
- enemy 접촉 → endGame
- F ↔ player → endGame
- F ↔ wall → projectile 제거
- note 수집 → 콤보/점수 갱신 + note 제거
- physicsWorld.contactDelegate가 *어떤 객체*든, didBegin 호출 결과가 동일

## 주의사항
- ContactRouter는 NSObject 상속 필수 (Obj-C 프로토콜 채택)
- 콜백 변수에 함수 저장 — 매번 새 클로저 할당 시 메모리 누수 가능. didMove에서 1회만 등록.
- 등록 안 된 콜백은 빈 함수 `{}` 또는 `{ _ in }` 기본값이라 크래시 없음
- `[weak self]` 누락 시 GameScene이 ContactRouter에 의해 영원히 살아있음 — retain cycle
