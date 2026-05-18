# QA 검수 보고서 — Phase 8-2 수간호사 픽셀 아트 이식

## SPEC 기능 검증

- **[PASS] 기능 1 — PixelSprite.nurseChiefData** : `PixelSprite.swift` L281-351에 정적 메서드 추가. base 20행(L287-306) + up 7행(L313-319) + left 5행(L322-326) + right 5행(L329-333) + step1 2행(L341-342) + step2 2행(L344-345). game.js L820-873과 *문자 단위* 일치 (Python 비교 스크립트로 검증, base/up/left/right/step1/step2 모두 True).
- **[PASS] 기능 2 — PixelPalette.chiefPalette** : `PixelPalette.swift` L84-107 extension에 14키 dict 추가. game.js L905-919의 의미상 유니크 14키와 1:1. 'P'(하의)는 game.js에서 'U'(uniform)와 동일 hex `#f4f0ee`이고 sprite 데이터(L820-841)에서 'P' 문자가 등장하지 않으므로 단일 Uniform 토큰으로 통일 — Renderer가 미정의 문자를 투명 처리하므로 안전.
- **[PASS] 기능 3 — ColorTokens 14색 hex** : `ColorTokens.swift` L118-151 `// MARK: - Chief Palette (Phase 8-2)` 섹션. 14개 hex 전부 game.js L905-919와 일치 (#f5d5c0 / #c08878 / #e8e4e8 / #c8c4cc / #ffffff / #e6dde6 / #ff7b7b / #1f1a1f / #e8c8b8 / #f4f0ee / #d8d2d0 / #ff7b7b / #1a1214 / #6b3a3a).
- **[PASS] 기능 4 — EnemyNode 픽셀 모드** : `EnemyNode.swift` L42-78 init에서 `super.init(texture: initialTexture, color: .clear, size: visualSize)` — 단색 `.ganhoBloodAccent` 제거됨. pixelDirection/pixelFrame/frameAccumulator 인스턴스 프로퍼티(L35-39). updatePixelDirection/tickWalkFrame/refreshTexture 메서드(L154-200). physicsBody는 `physicsSize` 사용 — `enemyWidth × enemyHeight` 그대로 유지. category/collision/contact 비트마스크 정책 한 줄도 미변경.
- **[PASS] 기능 5 — EnemyNode 자기 update 처리** : `EnemyNode.update` 내부 L142-147에서 자기 자신을 호출. GameScene.swift는 정확히 0줄 변경 (`git diff HEAD --numstat`로 검증). 기존 `enemy.update(deltaTime:targetPosition:speedT:)` 시그니처 보존, 호출 사이트(GameScene.swift L356) 변경 0.

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug clean build`
- **경고**: 0건 (Swift 컴파일 warning/error grep 결과 0줄. appintentsmetadataprocessor의 "No AppIntents.framework dependency found"는 시스템 정보 — 컴파일 경고 아님).
- **에러**: 0건.
- **비고**: 작업환경에 iPhone 15 시뮬레이터 미설치라 iPhone 17(현재 사용 가능한 최신 표준 시뮬레이터)로 빌드. iOS 16.6 target.

## byte-equal 정합성 핵심 인용

### base 20행 (game.js L820-841 ↔ PixelSprite.swift L286-307)
```
JS L823 [03] '..KkkkkkkkkkkK..'   Swift L289 "..KkkkkkkkkkkK.."
JS L825 [05] '..HhSSSSSSSShH..'   Swift L292 "..HhSSSSSSSShH.."
JS L827 [07] '..hSGgSSSSgGSh..'   Swift L294 "..hSGgSSSSgGSh.."
JS L831 [10] '..hhSSNNNNSSHh..'   Swift L297 "..hhSSNNNNSSHh.."
JS L833 [12] '..UUUUVCCVUUUU..'   Swift L299 "..UUUUVCCVUUUU.."
JS L840 [19] '....BB....BB....'   Swift L306 "....BB....BB...."
```
Python 비교 결과: `base 20 rows match: True`. 모든 행 16자.

### 방향 분기 17행
- up 7행: `up 7 rows match: True` (JS L846-852 ↔ Swift L313-319)
- left 5행: `left 5 rows match: True` (JS L854-858 ↔ Swift L322-326)
- right 5행: `right 5 rows match: True` (JS L860-864 ↔ Swift L329-333)

핵심 인용:
```
JS L846 up base[4]    '..HHHHHHHHHHHH..'   Swift L313 "..HHHHHHHHHHHH.."
JS L854 left base[6]  '..hSSSSSSSGGSh..'   Swift L322 "..hSSSSSSSGGSh.."
JS L860 right base[6] '..hSGGSSSSSSSh..'   Swift L329 "..hSGGSSSSSSSh.."
```

### 프레임 분기 4행 (game.js L869-873 ↔ PixelSprite.swift L341-345)
```
JS L869 frame=1 base[18] '....BB...BBB....'   Swift L341 "....BB...BBB...."
JS L870 frame=1 base[19] '....BBB...BB....'   Swift L342 "....BBB...BB...."
JS L872 frame=2 base[18] '....BBB...BB....'   Swift L344 "....BBB...BB...."
JS L873 frame=2 base[19] '....BB...BBB....'   Swift L345 "....BB...BBB...."
```
`step1 2 rows match: True   step2 2 rows match: True`.

## 회귀 0 영역 git diff 검증

`git diff HEAD --name-only -- GanhoMusic/` 결과 — 정확히 4개 파일:
```
GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift
GanhoMusic/GanhoMusic Shared/Models/PixelPalette.swift
GanhoMusic/GanhoMusic Shared/Models/PixelSprite.swift
GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift
```

회귀 0 영역 각 파일의 `git diff HEAD | wc -l` 결과 (모두 0):

| 파일 | diff 라인 |
|---|---|
| PlayerNode.swift | 0 |
| StoneGuardNode.swift | 0 |
| ProjectileNode.swift | 0 |
| NoteNode.swift | 0 |
| DPadNode.swift | 0 |
| HUDNode.swift | 0 |
| PixelSpriteRenderer.swift | 0 |
| GameScene.swift | 0 |
| GameScene+Setup.swift | 0 |
| TitleScene.swift | 0 |
| ResultScene.swift | 0 |
| GameConfig.swift | 0 |
| PhysicsCategory.swift | 0 |
| GameState.swift | 0 |
| CharacterID.swift | 0 |
| Difficulty.swift | 0 |
| GameStats.swift | 0 |
| **project.pbxproj** | **0** |

신규 파일: **0개**. 시스템/매니저/리포지토리/프로토콜 미접촉. iOS/tvOS/macOS 진입점 미접촉.

## EnemyNode 물리 정책 보존 검증

`git diff HEAD -- 'GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift'` 인용:

```diff
-        super.init(texture: nil, color: .ganhoBloodAccent, size: size)
+        super.init(texture: initialTexture, color: .clear, size: visualSize)
```

```diff
-        let body = SKPhysicsBody(rectangleOf: size)
+        let body = SKPhysicsBody(rectangleOf: physicsSize)
```

- `physicsSize = CGSize(width: GameConfig.enemyWidth, height: GameConfig.enemyHeight)` — 기존 size와 *완전 동일*. hitbox 회귀 0.
- `body.categoryBitMask = PhysicsCategory.enemy`, `collisionBitMask = PhysicsCategory.wall`, `contactTestBitMask = PhysicsCategory.player` — diff 0줄.
- `isDynamic / allowsRotation / friction / restitution / linearDamping` 5개 속성 — diff 0줄.

물리 정책 보존 PASS.

## EnemyNode 자기 update 방식 검증

GameScene.swift L356 (변경 0):
```swift
enemy.update(deltaTime: dt, targetPosition: player.position, speedT: curveT)
```

EnemyNode.update 내부 L142-147 (신규):
```swift
updatePixelDirection(newVelocity)
let isMoving = abs(newVelocity.dx) > 1.0 || abs(newVelocity.dy) > 1.0
tickWalkFrame(deltaTime: deltaTime, isMoving: isMoving)
```

GameScene에 enemy 픽셀 처리용 추가 라인 **0**. PlayerNode와는 다른 방식 — PlayerNode는 GameScene이 두 메서드(`updatePixelDirection` / `tickWalkFrame`)를 외부 호출하지만, EnemyNode는 자기 update 안에서 자기 호출. SPEC 주의사항 §6의 권장 방식이며 *GameScene 변경 최소화* 목표 달성.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 1건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항

### 1. EnemyNode.isMoving 임계값 1.0 vs PlayerNode 0.1 비대칭
- **파일**: `Nodes/EnemyNode.swift:146`
- **현재 코드**: `let isMoving = abs(newVelocity.dx) > 1.0 || abs(newVelocity.dy) > 1.0`
- **참조**: `GameScene.swift:345` 에서 PlayerNode 용도로 `> 0.1` 사용.
- **영향**: 게임 로직에는 영향 없음(enemy 속도는 보통 60+ pt/s라 1.0 임계 충분히 만족). 단순 일관성 차원의 경미한 비대칭. PlayerNode의 `0.1`은 *noise floor*라는 의미 주석이 있는 동일 역할 매직 수치이므로, EnemyNode도 `GameConfig.velocityNoiseFloor` 같은 단일 상수로 추출하면 의미가 더 또렷해질 수 있다. 본 sprint 범위는 아님. 다음 sprint(throwArm 이식) 시 함께 정리 가능.

## 정적 검사 결과

- **강제 언래핑(`!`)**: 변경 4개 파일 모두 0건. `EnemyNode.swift`에 `!=` 만 등장 (5건, 비교 연산자라 안전).
- **Timer**: 0건 (전체 변경 코드).
- **DispatchQueue**: 0건 (전체 변경 코드. BGMPlayer.swift의 기존 사용은 본 sprint 변경 0줄로 무관).
- **매직 넘버**: 의미 있는 새 매직 넘버 0건. `1.0` (noise floor) / `0.1` (direction noise floor)는 floating-point 임계로 GameConfig 승격 불요 — 단 P2의 일관성 항목 참조.
- **guard let / 옵셔널 처리**: `physicsBody?.velocity` 옵셔널 체이닝 사용 (기존 패턴), `magnitude > 0` 가드(NaN 방지).
- **MARK 섹션 구분**: 3파일에 `// MARK: - Chief Palette (Phase 8-2)` / `// MARK: - Nurse Chief Sprite (Phase 8-2)` / `// MARK: - Pixel Sprite State (Phase 8-2)` / `// MARK: - Pixel Sprite (Phase 8-2)` 추가.
- **GameConfig 상수**: `enemyWidth / enemyHeight / pixelSpriteScale / pixelWalkFrameInterval` 재사용. 신규 상수 0개 (SPEC 요구사항 부합).
- **[weak self]**: startFleeing의 SKAction 클로저 2개 모두 `[weak self]` — 기존 패턴 그대로.

## 통과 항목

- byte-equal 정합성 (base 20 + up 7 + left 5 + right 5 + step1 2 + step2 2 = **41행** 모두 일치)
- chiefPalette 14키 + 14 hex 모두 1:1
- ColorTokens 14색 신설 + MARK 섹션
- EnemyNode physicsBody 정책 완전 보존 (size / category / collision / contact / dynamic 정책 diff 0)
- 회귀 0 영역 18개 파일 + pbxproj 모두 diff 0
- 신규 파일 0개
- BUILD SUCCEEDED + 컴파일 경고 0
- GameScene 0줄 변경(자기 update 방식 채택)
- throwArm 미구현(SPEC 범위 외, 의도된 미구현)

---

## 채점

| 축 | 점수 |
|---|---|
| Swift 패턴 일관성 | 9.7 / 10 (강제 언래핑 0, Timer/DispatchQueue 0, MARK/guard/weak self 준수. P2 1건은 임계값 일관성 — 마이너) |
| 게임 로직 완성도 | 10.0 / 10 (physicsBody 정책 완전 보존 + GameScene 0줄 + 도주 모드 호환 + 시그니처 호환 — 회귀 0 완벽) |
| 성능 & 안정성 | 10.0 / 10 (texture 재생성을 변경 순간에만 — 정지 시 비용 0. ARC 자동 정리. NaN 가드 + 임계값 가드 모두 존재. 빌드 경고 0) |
| 기능 완성도 | 10.0 / 10 (41행 byte-equal + 14키 + 14 hex + EnemyNode 5메서드 완비. SPEC 5개 기능 모두 검증) |

**가중 점수**: (9.7 + 10.0 + 10.0 + 10.0) / 4 = **9.93 / 10**

## 최종 판정: **합격**

원본 web game game.js L819-919을 **41행 sprite 데이터 + 14키 팔레트 + 14색 hex** 모두 byte-equal로 이식. EnemyNode의 physicsBody 정책을 완전 보존하여 게임 로직 회귀를 0으로 차단했고, EnemyNode가 자기 update 안에서 픽셀 텍스처를 갱신하는 *자가 처리* 방식을 채택하여 GameScene을 0줄 변경하는 데 성공했다 (SPEC 주의사항 §6의 권장 방식). 회귀 0 영역 18개 파일 + pbxproj 모두 diff 0줄이며, BUILD SUCCEEDED + 컴파일 경고 0. SPEC이 의도한 throwArm 미구현은 다음 sprint로 명시 분리되어 있다.

**구체적 개선 지시 (선택, 다음 sprint 통합 가능)**:
1. `EnemyNode.swift:146`의 `1.0` 임계값과 `GameScene.swift:345`의 `0.1` 임계값을 `GameConfig.velocityNoiseFloor` 단일 상수로 추출하면 PlayerNode/EnemyNode 픽셀 모션 임계가 의미적으로 통일된다 (P2, 본 sprint 범위 외).
2. Phase 8-3에서 `throwArm` 이식 시 `nurseChiefData(direction:frame:throwArm:)` 시그니처로 확장하고 game.js L877-889의 3분기(left/right/down) base[10]/base[11] 변형을 그대로 옮길 수 있다 (SPEC 미래 계약과 정합).
