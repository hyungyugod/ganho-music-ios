# Phase 9-8 — 박병장 비행기 이스터에그 (타이밍·난이도 정합화)

## 개요

석조무사 접촉 시 발화하는 "AIRFORCE 박병장 비행기" 이스터에그는 Phase 4-3~4-7에서 골격이 구현되어 있으나, Phase 9 시리즈의 *사용자 요청 시퀀스*와 *난이도 적용 범위*가 일부 불일치한다. 본 sprint는 **타이밍 4건 + 난이도 가드 1건**을 정밀 보정하여 GDD §7-7와 사용자 요청에 완전 일치시킨다. 신규 노드/액션/픽셀 아트는 일절 추가하지 않는다.

## 변경 유형

**게임플레이 + 비주얼 (혼합)** — 타이밍 보정 = 비주얼 시퀀스 재조정, 난이도 가드 = 게임플레이 흐름.

## 게임 경험 의도

이스터에그는 자전적 게임의 *심장*이다. 사용자(개발자)가 군 시절 경험한 "박병장이 비행기를 부른다"는 농담을 통해 자전성을 응집한다. 석조무사는 "잡혀갑니다" 경고로 겁을 주지만 접촉하면 *실은 아군*이었다는 반전으로 *코미디 비트*가 발생. 본 sprint는 그 호흡 박자(2.4s 오버레이 → 2s 비행기 → 폭탄 섬광)를 정확히 맞춰 *극의 리듬*을 복원한다. 석조무사가 hard 난이도에 등장하지 않는 GDD 규정은 "상 난이도는 이교수 청진기 톤"이라는 *집중 디자인*과 일치.

## Sprint 범위 계약

### 허용
1. `GameConfig.airforceOverlayDisplayDuration` 값 1.5 → **2.1** (사용자 요청 "오버레이 2.4초" = display 2.1 + fadeOut 0.3)
2. `GameConfig.bombFlashDelay` 값 2.1 → **3.4** (오버레이 종료 + 비행기 중앙 도달)
3. `GameConfig` 신상수 `airplaneDelayAfterOverlay: TimeInterval = 2.4` 추가
4. `triggerAirforceEasterEgg()` 안 비행기 등장 블록을 `SKAction.sequence([wait, run{attach}])` 지연 패턴으로 변경 + 첫 줄에 `if difficulty == .hard { return }` 가드 추가
5. `GameScene+Setup.setupStoneGuard()` 첫 줄에 `guard difficulty != .hard else { return }` 가드 추가
6. 두 파일 헤더 주석 1줄("Phase 9-8") 추가

### 금지
1. 신규 Swift 파일 추가 (AirplaneNode/AirforceOverlayNode/BombFlashNode/EnemyNode 모두 미접촉)
2. 신규 PixelSprite 데이터(박병장/비행기/폭탄 픽셀 아트) 추가
3. 새 ColorTokens / PhysicsCategory / SKAction 키 추가
4. EnemyNode.startFleeing 시그니처 변경 (4-6/4-7에서 완성)
5. SpawnSystem.fireImmediately 시그니처/내부 변경 (이미 구현)
6. `airforceTriggered` 1회 가드 정책 변경
7. Phase 9-1~9-7 영역 어떤 줄도 수정 금지

### 판단 기준
"이 변경이 없으면 사용자 요청 시퀀스(2.4 → 2 → 3.4)가 시뮬레이터에서 보이지 않는가?" → YES면 허용. "픽셀 아트가 시퀀스 작동에 필수인가?" → NO → 금지.

## 트리거 동작 정확 명시

1. **활성 조건**: `difficulty != .hard` 게임에서 *플레이어 ↔ 석조무사 첫 접촉* 1회.
2. **이중 발화 차단**: `airforceTriggered: Bool` 가드(현재 코드 그대로).
3. **게임당 1회**: 새 게임 시작 시 `false` 자동 리셋.
4. **hard 난이도 차단** (2중화):
   - (a) `setupStoneGuard()`에서 가드 → hard에서 stoneGuard 노드 자체가 worldNode에 미등록 → 접촉 발생 0
   - (b) `triggerAirforceEasterEgg()` 본문 첫 줄에도 가드 → 호출 경로 변경 시 회귀 차단

## 이스터에그 시퀀스 (trigger 시점 t=0 기준)

| t (초) | 이벤트 | 노드 | 액션 |
|---|---|---|---|
| 0.0 | 트리거 발화 + airforceTriggered=true | (가드 통과) | - |
| 0.0 | 오버레이 "나와라 박병장!" | `AirforceOverlayNode` (cameraNode 자식) | alpha=1 → wait 2.1 → fadeOut 0.3 → 자가 제거 (총 2.4s) |
| 0.0 | 수간호사 5초 도주 모드 시작 | `EnemyNode.startFleeing(duration: 5.0)` | isFleeing=true → 5초 후 onEnd 콜백 → fireImmediately() 1발 |
| 2.4 | 오버레이 완전 소멸 + 비행기 등장 | `AirplaneNode` (cameraNode 자식) | 좌측 바깥 → 우측 바깥, duration 2.0s |
| 3.4 | 비행기 화면 중앙 도달 + 폭탄 투하 | `BombFlashNode` (cameraNode 자식) | fadeIn 0.07 + fadeOut 0.35 = 420ms |
| 4.4 | 비행기 우측 바깥 도달 | (AirplaneNode SKAction.sequence) | removeFromParent |
| 5.0 | 수간호사 도주 종료 + F 1발 재발사 | `SpawnSystem.fireImmediately()` | 일반 fireProjectile() 1회 |

**검증식**:
- 오버레이 총 수명 = `airforceOverlayDisplayDuration(2.1)` + `airforceOverlayFadeOutDuration(0.3)` = **2.4초** ✓
- 비행기 가로지름 = `airplaneCrossDuration(2.0)` ✓
- 비행기 등장 시점 = `airplaneDelayAfterOverlay = 2.4`
- 비행기 중앙 도달 = 2.4 + 1.0 = **3.4**
- 폭탄 섬광 = 0.07 + 0.35 = **0.42초** ✓

## 노드 트리 / 부착 위치 (변경 없음)

```
GameScene
├── worldNode
│   ├── StoneGuardNode (easy/normal만 자식 등록)  ← *변경 지점 1*
│   └── ...
└── cameraNode
    ├── AirforceOverlayNode (zPosition=200, 2.4s 자가 소멸)
    ├── AirplaneNode (zPosition=50, 2.0s 자가 소멸)
    └── BombFlashNode (zPosition=250, 0.42s 자가 소멸)
```

**부착 위치 결정**: 세 노드 모두 cameraNode 자식. 이스터에그는 *연출* 이벤트 → 화면 좌표에 고정.

## EnemyNode 도망 모드 (변경 없음)

현재 4-6/4-7에서 완성된 패턴:
- `var isFleeing: Bool`
- `startFleeing(duration:onEnd:)` — SKAction.sequence
- `update`에서 `direction: isFleeing ? -1 : 1` 분기
- onEnd 콜백에서 GameScene이 `spawnSystem.fireImmediately()` 호출

**5초 동안 F 발사 중단 처리**: 사용자 요청 본문은 "F 재스폰 1배" 뿐. "5초 동안 F 발사 중단"은 명시 안 됨 → Sprint 범위 §금지 5로 명확히 배제. 발사 중단 로직 추가 금지.

## 새 픽셀 아트 필요 여부

**불필요**. 현재 SKSpriteNode 단색으로 충분:
- AirplaneNode: `.ganhoYellowF` 32×16 막대
- BombFlashNode: `.ganhoPaper` 풀스크린 누런 섬광
- AirforceOverlayNode: SKLabelNode "나와라 박병장!" + `.ganhoYellowF`

이유:
- 사용자 요청 본문에 픽셀 아트 명시 없음
- PixelSprite/Palette 추가는 Sprint 범위 §금지 2
- 미니멀이 *코미디 톤*과 더 잘 맞음 (과한 묘사보다 *암시*)

## 변경 범위

### 수정할 파일 (3개)

#### 1. `Config/GameConfig.swift`
- `airforceOverlayDisplayDuration: TimeInterval = 1.5` → **2.1** + 주석 갱신
- `bombFlashDelay: TimeInterval = 2.1` → **3.4** + 주석 갱신
- 신상수 추가:
  ```swift
  /// Phase 9-8 — 비행기 등장 지연(trigger 시점 t=0 기준).
  /// 오버레이 완전 소멸 = displayDuration(2.1) + fadeOutDuration(0.3) = 2.4초.
  /// 이 시점에 비행기가 화면 좌측에서 등장 → 우측까지 2초 가로지름.
  static let airplaneDelayAfterOverlay: TimeInterval = 2.4
  ```

#### 2. `GameScene.swift` — `triggerAirforceEasterEgg()` 메서드만

```swift
private func triggerAirforceEasterEgg() {
    if airforceTriggered { return }
    // Phase 9-8 — hard 난이도 다층 방어 가드. setupStoneGuard에서 이미 stoneGuard 미등록이라
    // 이 메서드 자체로 진입할 경로가 없으나, 호출 경로 변경 시 회귀 차단용 안전망.
    if difficulty == .hard { return }
    airforceTriggered = true

    // ... 기존 오버레이/도주 호출 그대로 (t=0에 발화) ...

    // Phase 9-8 — 비행기는 오버레이 완전 소멸 후 등장.
    let plane = AirplaneNode()
    let y = +(size.height / 2 - GameConfig.airplaneTopOffset)
    let wait = SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)
    let attach = SKAction.run { [weak self] in
        guard let self = self else { return }
        self.cameraNode.addChild(plane)
        plane.crossScreen(sceneWidth: self.size.width, atY: y)
    }
    cameraNode.run(.sequence([wait, attach]))

    // ... 기존 bombFlash 호출 그대로 (bombFlashDelay 상수만 3.4로 자동 갱신) ...
}
```

#### 3. `GameScene+Setup.swift` — `setupStoneGuard()` 메서드만

```swift
func setupStoneGuard() {
    // Phase 9-8 — hard 난이도는 이교수 톤 집중. 석조무사 미등장 (GDD §7-6 "하/중 전용").
    guard difficulty != .hard else { return }
    let first = GameConfig.stoneGuardWaypoints[0]
    stoneGuard.position = CGPoint(x: first.x, y: first.y)
    worldNode.addChild(stoneGuard)
}
```

### 추가할 파일

**없음** — 본 sprint는 *순수 보정 sprint*.

## 회귀 방지 (Phase 9-1 ~ 9-7 영역 0줄)

특히 다음 파일은 *읽기만* 하고 한 줄도 수정하지 않는다:
- AirplaneNode.swift / AirforceOverlayNode.swift / BombFlashNode.swift
- EnemyNode.swift / StoneGuardNode.swift / ProjectileNode.swift
- SpawnSystem.swift / ContactRouter.swift
- PixelSprite.swift / PixelPalette.swift
- Difficulty.swift / PhysicsCategory.swift
- 모든 Phase 9-5/9-6/9-7 추가 파일

## 매직 넘버 정책

GameScene 본문에 *어떤 숫자 리터럴도 출현하지 않는다*. `SKAction.wait(forDuration: GameConfig.airplaneDelayAfterOverlay)` 1건만 신규 호출.

## 주요 패턴 / 주의사항

1. **SKAction.sequence 지연 attach**: AirplaneNode 시그니처 불변. cameraNode.run([wait, run{attach}]) 패턴.
2. **[weak self] 캡처 필수**: 지연 attach 클로저 안 `self.cameraNode` / `self.size` 접근 — endGame 가능성 대비.
3. **단방향 의존성 유지**: GameScene → 노드 호출만. 노드 → GameScene 콜백은 onEnd 1건(도주 종료 → fireImmediately).
4. **멱등성**: `airforceTriggered` 가드 + `difficulty == .hard` 가드 2중.
5. **endGame 중 이스터에그**: SKAction은 계속 진행되나 이스터에그 노드는 cameraNode 자식 → presentScene 시 자동 정리.
6. **fireImmediately 가드**: 5초 도주 종료 후 self.spawnSystem nil 시 자연 noop (이미 4-7에 캡처).
7. **hard 가드 2중화**: setupStoneGuard 가드 (a) + triggerAirforceEasterEgg 가드 (b) — 미래 디버그 경로 회귀 차단. Spring `@PreAuthorize` + Controller 자체 검증 답습.
8. **사용자 요청 텍스트 해석**: "F 재스폰 1배" = 도주 종료 후 즉시 1발 발사. "5초 동안 F 발사 중단"은 본문에 없음 → 배제.

## 평가 가중치

- Swift 패턴 35% — GameConfig 상수 + guard 패턴 + [weak self]
- 게임 로직 30% — SKAction 지연 attach + 멱등성 가드
- 성능 & 안정성 20% — 신규 노드 0, 매직 넘버 0, 강제 언래핑 0
- 기능 완성도 15% — 사용자 요청 시퀀스 + hard 차단

## Generator 작업 체크리스트

1. GameConfig.swift `airforceOverlayDisplayDuration` 1.5 → 2.1, 주석 갱신
2. GameConfig.swift `bombFlashDelay` 2.1 → 3.4, 주석 갱신
3. GameConfig.swift Airforce 섹션에 `airplaneDelayAfterOverlay = 2.4` 신상수 추가
4. GameScene.swift `triggerAirforceEasterEgg()` 첫 줄에 `if difficulty == .hard { return }` 추가
5. GameScene.swift `triggerAirforceEasterEgg()` 비행기 부착 블록을 지연 패턴으로 교체. [weak self]
6. GameScene+Setup.swift `setupStoneGuard()` 첫 줄에 `guard difficulty != .hard else { return }` 추가
7. 두 파일 헤더에 "Phase 9-8" 한 줄 주석 추가

## 시뮬레이터 수동 검증 시나리오

| 단계 | 액션 | 기대 결과 |
|---|---|---|
| (a) | easy 게임 진입 | stoneGuard 좌하단(200,100)에서 패트롤 시작 |
| (b) | player → stoneGuard 충돌 | "나와라 박병장!" 오버레이 즉시 표시 (2.4초 유지) |
| (c) | t=0~2.4 | 수간호사 도주 시작 (5초간) |
| (d) | t=2.4 | 오버레이 소멸 + 비행기 좌측 등장 |
| (e) | t=3.4 | 비행기 중앙 도달 시 화면 누런 섬광(420ms) |
| (f) | t=4.4 | 비행기 우측 바깥 도달, 제거 |
| (g) | t=5.0 | 수간호사 정상 추적 복귀 + F 1발 재발사 |
| (h) | stoneGuard 재접촉 | airforceTriggered=true → noop |
| (i) | normal 게임 | (a)~(h) 동일 시퀀스 |
| (j) | hard 게임 | stoneGuard 미등장. 이교수만 활동 |
| (k) | 게임 재시작 → easy | airforceTriggered=false 리셋 → 다시 1회 발화 |
