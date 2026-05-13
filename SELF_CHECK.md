# 자체 점검 — Phase 6-8 음표 수집 sparkle 파티클

전략: 1회차 — SPEC 그대로 구현.

---

## 1. SPEC 기능 4개 구현 확인

| # | 기능 | 구현 위치 | 상태 |
|---|---|---|---|
| 1 | GameConfig Sparkle 상수 6개 | `Config/GameConfig.swift` L267~284 (`// MARK: - Sparkle Effect (Phase 6-8)`) | OK |
| 2 | SparkleEffectNode 신설 (자가 소멸 4호) | `Nodes/SparkleEffectNode.swift` (신규, SelfDismissingNode 채택, SKNode + 8 SKShapeNode 자식) | OK |
| 3 | GameScene onNoteCollected sparkle 트리거 | `GameScene.swift` L208~221 (`configureContactRouter()` 내) + 헤더 L34 | OK |
| 4 | pbxproj 4지점 등록 | `GanhoMusic.xcodeproj/project.pbxproj` L32(BuildFile)/L65(FileReference)/L210(Nodes 그룹)/L478(Sources phase) | OK |

### 기능 1 — GameConfig 상수 6개 (위치: L267~284)
- `sparkleParticleCount: Int = 8`
- `sparkleParticleRadius: CGFloat = 2.0`
- `sparkleSpawnDistance: CGFloat = 24`
- `sparkleFadeDuration: TimeInterval = 0.5`
- `sparkleZPosition: CGFloat = 30`
- `sparkleEndScale: CGFloat = 0.2`

각 상수에 GDD 근거 주석 첨부 (왜 8, 왜 2.0, 왜 24, 왜 0.5, 왜 30, 왜 0.2).

### 기능 2 — SparkleEffectNode.swift
- `final class SparkleEffectNode: SKNode, SelfDismissingNode` — protocol 채택(4호 노드)
- `init()`: name/zPosition/buildParticles() — init 시점에만 자식 추가
- `private func buildParticles()`: 8개 SKShapeNode(circle r=2.0), fillColor=.white, strokeColor=.clear, position=.zero
- `func emit()`: 각 자식에 SKAction.group([move, fadeOut, scale]) 동시 실행 → 컨테이너는 sequence([wait 0.5s, removeFromParent])로 자가 제거
- self 미사용 → `[weak self]` 캡처 불필요

### 기능 3 — GameScene onNoteCollected 트리거 (5줄 + 주석 3줄)
순서 보장:
```swift
let sparkleOrigin = note.position     // ← removeFromParent 이전 캡처
let sparkle = SparkleEffectNode()
sparkle.position = sparkleOrigin
self.worldNode.addChild(sparkle)      // ← worldNode (cameraNode 아님)
sparkle.emit()
note.run(.removeFromParent())         // ← 캡처 이후 제거
```
파일 상단 주석에 `Phase 6-8 · 음표 수집 시 sparkle 8방향 방사 (시각 폴리싱)` 한 줄 추가.

### 기능 4 — pbxproj 4지점
- PBXBuildFile: `A1C0F1B00000000000000028 /* SparkleEffectNode.swift in Sources */ = ...`
- PBXFileReference: `A1C0F1A00000000000000028 /* SparkleEffectNode.swift */ = ...`
- Nodes 그룹 children: `A1C0F1A00000000000000028 /* SparkleEffectNode.swift */,`
- Sources build phase (iOS 타겟 `C75D46252FA627C20016BB86`): `A1C0F1B00000000000000028 /* SparkleEffectNode.swift in Sources */,`

UUID `0028` 신규 발급 — 기존 `0027` BGMPlayer 다음. 충돌 0.

---

## 2. 빌드 결과

```
** BUILD SUCCEEDED **
```

- 명령: `xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- 결과: **BUILD SUCCEEDED**
- 경고 `warning:` 또는 에러 `error:` 매칭 행: **0건** (AppIntents.framework 무관 메타데이터 경고 제외)

---

## 3. 회귀 0줄 강제 항목 — git status 확인

| 영역 | 변경 여부 |
|---|---|
| `Managers/AudioManager.swift` | 미변경 |
| `Managers/HapticsManager.swift` | 미변경 |
| `Managers/BGMPlayer.swift` | 미변경 |
| `Systems/ScoreSystem.swift` | 미변경 |
| `Systems/ContactRouter.swift` | 미변경 |
| `Systems/SpawnSystem.swift` | 미변경 |
| `Scenes/TitleScene.swift` | 미변경 |
| `Scenes/ResultScene.swift` | 미변경 |
| `Repositories/*` (High/Stats/Pref) | 미변경 |
| `Models/*` (DTO/CharacterID/GameStats) | 미변경 |
| `Protocols/SelfDismissingNode.swift` | 미변경 (채택만, 변경 0) |
| `Nodes/*` (기존 Player/Enemy/Note/Projectile/HUD/DPad/StoneGuard/Airplane/AirforceOverlay/BombFlash/CharacterCard) | 미변경 |
| `Config/ColorTokens.swift` | 미변경 (SKColor.white 사용) |
| `Config/PhysicsCategory.swift` | 미변경 (새 카테고리 0) |
| `Config/GameState.swift` | 미변경 |
| `Errors/*` | 미변경 |

`git status` 결과: 수정 3 + 신규 1 = SPEC 4지점 정확 일치.
```
modified:   GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift
modified:   GanhoMusic/GanhoMusic Shared/GameScene.swift
modified:   GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj
Untracked:  GanhoMusic/GanhoMusic Shared/Nodes/SparkleEffectNode.swift
```

`git diff --stat`: GameConfig +18, GameScene +9, pbxproj +4. 라인 수가 SPEC 의도와 일치 (5~6줄 + 주석/MARK 헤더).

---

## 4. 특별 검증

| 항목 | 결과 |
|---|---|
| 강제 언래핑 `!` 0개 | OK — SparkleEffectNode/GameScene 모두 `guard let` 또는 옵셔널 미사용 |
| Timer 0개, SKAction만 | OK — `SKAction.moveBy / fadeOut / scale / wait / removeFromParent` |
| 매직 넘버 0개 (모두 GameConfig 경유) | OK — 8 (count), 2.0 (radius), 24 (distance), 0.5 (duration), 30 (z), 0.2 (endScale) 모두 GameConfig 상수 경유. 유일한 수치 리터럴 `2`는 `(2 * CGFloat.pi)`로 *수학 정의*(원 한 바퀴 = 2π)라 상수화 대상 아님 |
| SelfDismissingNode 채택 (4호 노드) | OK — `final class SparkleEffectNode: SKNode, SelfDismissingNode` (AirplaneNode/AirforceOverlayNode/BombFlashNode에 이은 4호) |
| SKAction.group vs sequence 정확 적용 | OK — group([move, fade, scale]) = 동시 진행 (자식 8개에 각각 run), sequence([wait, removeFromParent]) = 컨테이너 자가 제거 |
| note.position 캡처 ↔ removeFromParent 순서 | OK — `let sparkleOrigin = note.position` 먼저, `note.run(.removeFromParent())` 마지막 (clause 끝) |
| sparkle이 worldNode에 add됨 | OK — `self.worldNode.addChild(sparkle)` (cameraNode 아님 — note와 같은 좌표계 → 카메라 follow 시 함께 이동) |
| 새 ColorTokens 추가 0 | OK — `SKColor.white` 직접 사용. ColorTokens.swift 미변경 |
| 새 효과음 추가 0 | OK — AudioManager.swift 미변경, audio.play 신규 케이스 0 |
| 새 햅틱 추가 0 | OK — HapticsManager.swift 미변경 |
| 새 PhysicsCategory 추가 0 | OK — PhysicsCategory.swift 미변경, sparkle에 physicsBody 부착 0 |
| update() 안 addChild 0 | OK — buildParticles()는 init 시점에만 호출 |
| `[weak self]` 캡처 유지 | OK — onNoteCollected 클로저 첫 줄 `[weak self]` 보존, sparkle.emit() 안은 self 미사용 → 캡처 불필요 |
| GameScene/ContactRouter/ScoreSystem/SpawnSystem 시그니처 변경 0 | OK — onNoteCollected 콜백 시그니처 동일, 본문만 5줄 추가 |

---

## 5. 검증 시나리오 정적 추적

### (a) 빌드
- xcodebuild → **BUILD SUCCEEDED**, 경고 0
- pbxproj 4지점 모두 등록 확인 (`grep -c "SparkleEffectNode"` = 4)

### (b) 음표 수집 시각 효과
정적 추적:
1. 음표 충돌 → `ContactRouter.didBegin` → `onNoteCollected(note)` 콜백
2. `note.position` 캡처 (worldNode 좌표계)
3. `SparkleEffectNode()` 생성 → 8개 SKShapeNode 자식 (모두 (0,0))
4. `sparkle.position = sparkleOrigin` (note 위치로 이동)
5. `worldNode.addChild(sparkle)` (player/enemy와 같은 좌표계)
6. `sparkle.emit()`:
   - 자식 0 (angle 0°): dx=+24, dy=0 — 오른쪽
   - 자식 1 (angle 45°): dx≈+17, dy≈+17 — 우상
   - 자식 2 (angle 90°): dx=0, dy=+24 — 위
   - ... (8방향 45° 균등)
   - 각 자식: group([move 0.5s, fadeOut 0.5s, scale to 0.2 over 0.5s]) 동시 실행
7. 0.5초 후 컨테이너 자체 sequence([wait, removeFromParent]) 발화 → ARC 해제

### (c) 회귀 검증
- ScoreSystem: `scoreSystem.recordNoteHit` 호출 그대로 — 점수/콤보 영향 0
- ContactRouter: `onNoteCollected` 시그니처 동일 (`(NoteNode) -> Void`)
- SpawnSystem: 변경 0
- AudioManager/HapticsManager/BGMPlayer: 변경 0
- 다른 Nodes (Player/Enemy/Projectile/HUD/Card/Airplane/Bomb/AirforceOverlay/StoneGuard): 변경 0
- Phase 1~6 회귀: 이동/수집/점수/HUD/적/F/게임오버/ResultScene/캐릭터선택/AIRFORCE/사운드/햅틱/BGM 페이드/Interruption/Lifecycle 모두 코드 경로 동일

### (d) 멱등성/메모리
- onNoteCollected는 ContactRouter.didBegin 1회 → 음표 1개당 sparkle 1회
- sparkle 컨테이너는 `run(.sequence([wait 0.5, removeFromParent]))`로 자가 제거 — 외부 정리 0
- ARC: scene 종료 시 worldNode 자식 모두 자동 해제, sparkle도 동일

### (e) 성능
- 음표 수집 빈도 ~1~2/sec (noteSpawnInterval=1.5)
- sparkle 1개당 8 SKShapeNode + 8 SKAction.group + 1 sequence = ~17 객체
- 동시 sparkle 최대 ~3~4 (0.5초 수명, 1~2/sec 빈도) = ~24~32 SKShapeNode
- SKShapeNode(circleOfRadius:)는 path 1개 GPU 친화적 — 60fps 영향 무시 가능

### (f) 음원 부재 / 기타 환경
- BGMPlayer 음원 부재 시 → bgm.play()는 noop이지만 sparkle 동작 영향 0 (독립 경로)
- 시뮬레이터: SKShapeNode는 텍스처 캐시 없이 path만 렌더 → GPU 친화적
- 캐릭터 선택 영향 0: characterID는 PlayerNode 색에만 영향, sparkle 흐름과 무관

---

## 6. 범위 외 미구현 항목

없음. SPEC "허용" 5개 항목 모두 구현, "금지" 항목 0건 위반.
