# QA 검수 보고서 — Phase 7-2 · Hard 맵 도입

## SPEC 기능 검증

- **[PASS] 기능 1: setupMap() 분기 도입** — `GameScene+Setup.swift:19~23` setupWorld가 setupMap() 단일 호출로 추출. `GameScene+Setup.swift:27~35` setupMap이 addOuterWalls() 후 switch difficulty 분기. case `.easy` → addCentralPillar / case `.normal, .hard` → addHardMap. switch default 미사용.
- **[PASS] 기능 2: addHardMap()** — `GameScene+Setup.swift:39~99` 코너 방 4개(가로벽 4 + 세로벽 4 = 8 호출) + 중앙 기둥 4 호출 = 총 12 SPEC 좌표 호출.
- **[PASS] 기능 3: 헬퍼 3개** — `addHorizontalWall`(L102~104), `addVerticalWall`(L108~112), `addRectPillar`(L117~136) 모두 private.
- **[PASS] GameConfig 신규 상수 40개** — `Config/GameConfig.swift:484~533` `// MARK: - Hard Map (Phase 7-2)` 섹션 신설.

## 빌드 검증
- **BUILD SUCCEEDED** · 컴파일 에러 0건 · Swift 경고 0건

---

## 1. 옵션 C 좌표 표 완전 일치 — PASS

### 좌상/우상 거울 대칭 (47-c)
| 검증 | 좌상 | 우상 | 47-c | 결과 |
|---|---|---|---|---|
| 가로벽 c 시작 | 4 | 43 | 47-4=43 | ✓ |
| 가로벽 c 끝 | 9 | 38 | 47-9=38 | ✓ |
| 세로벽 c | 9 | 38 | 47-9=38 | ✓ |

### 좌상/좌하 상하 거울 (23-r)
| 검증 | 좌상 | 좌하 | 23-r | 결과 |
|---|---|---|---|---|
| 가로벽 r | 18 | 5 | 23-18=5 | ✓ |
| 세로벽 r 범위 | 18~21 | 2~5 | 23-21=2, 23-18=5 | ✓ |
| 문 r | 20 | 3 | 23-20=3 | ✓ |

### 중앙 기둥 대칭
- 세로 기둥 좌우 대칭 c=17 ↔ c=30 (17+30=47) ✓
- 세로 기둥 r=11~12 정중앙 (23/2=11.5) ✓
- 가로 기둥 c=23~24 정중앙 (47/2=23.5) ✓
- 가로 기둥 상하 대칭 r=15 ↔ r=8 (15+8=23) ✓

**한 셀 오차 0건**.

---

## 2. PhysicsBody 7줄 byte-equal — PASS

`addRectPillar` (L127~133)와 `addCentralPillar` (L205~211) diff 0줄:
```swift
let body = SKPhysicsBody(rectangleOf: pillarSize)
body.isDynamic           = false
body.friction            = 0
body.restitution         = 0
body.categoryBitMask     = PhysicsCategory.wall
body.collisionBitMask    = 0
body.contactTestBitMask  = 0
```

## 3. 세로벽 SKSpriteNode 분리 — PASS

`GameScene+Setup.swift:109`:
```swift
for r in rStart...rEnd where r != doorR {
    addRectPillar(cStart: c, cEnd: c, rStart: r, rEnd: r)
}
```

좌상/우상 r=18,19,21 (r=20 건너뜀) → 3개 노드. 좌하/우하 r=2,4,5 (r=3 건너뜀) → 3개 노드. PhysicsBody가 문을 막을 위험 차단.

## 4. setupMap switch default 미사용 — PASS

```swift
switch difficulty {
case .easy:    addCentralPillar()
case .normal, .hard:  addHardMap()
}
```
default 분기 0건. Difficulty enum 신규 case 추가 시 컴파일러 경고 자동.

## 5. 회귀 0 영역 — PASS

`git diff HEAD --name-only -- 'GanhoMusic/'` 결과 단 2개 파일만 변경:
- `GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic Shared/GameScene+Setup.swift`

지정된 회귀 0 영역 모두 0줄: GameScene/Title/Result, PlayerNode/EnemyNode/StoneGuard/Projectile/Note/DPad/카드노드들, 자가소멸 9개, HUD/ContactRouter/ScoreSystem/SpawnSystem/CameraShake, BGM/Audio/Haptics, ColorTokens/PhysicsCategory/GameState, Repositories 4개, Models/Protocols/Errors, iOS·tvOS·macOS GameViewController/AppDelegate/SceneDelegate, **pbxproj 0줄**.

## 6. easy 회귀 0 자연 차단 — PASS

addCentralPillar 함수 본체 git diff 0줄. case `.easy` → 기존 호출 그대로.

## 7. 벽 색 `.ganhoPaper` 1종 — PASS

addRectPillar L122: `SKSpriteNode(color: .ganhoPaper, size: pillarSize)`. 새 토큰 0건.

## 8. 외곽 벽 중복 0 — PASS

모든 c ∈ {4,9,17,23,24,30,38,43} ⊂ [4,43]. 모든 r ∈ {2,3,5,8,11,12,15,18,20,21} ⊂ [2,21]. 외벽 c=0/47, r=0/23과 중복 0.

## 9. 빌드 — PASS

`** BUILD SUCCEEDED **` · 에러 0 · 경고 0

## 10. 정적 검사 — PASS

| 패턴 | 결과 |
|---|---|
| 강제 언래핑 `!` (진짜 force-unwrap) | 0건 |
| 매직 넘버 | 0건 (모든 좌표 GameConfig 상수) |
| Timer / DispatchQueue | 0건 |
| print 디버그 잔존 | 0건 |

## 11. 원본 game.js 디자인 충실도 — PASS

원본 32×20 → 모바일 48×24 옵션 C 거울 대칭 변환 모두 검증 일치. 원본 4 코너 방 + 중앙 기둥 다수 디자인 의도 보존.

---

## P0 / P1 / P2: **0 / 0 / 0 건**

## 채점

- **Swift 패턴 일관성**: 10/10 (35%)
- **게임 로직 완성도**: 10/10 (30%)
- **성능 & 안정성**: 10/10 (20%)
- **기능 완성도**: 10/10 (15%)

**가중 점수: 10.0 / 10.0**

## 최종 판정: **합격**

구체적 개선 지시: 없음.
