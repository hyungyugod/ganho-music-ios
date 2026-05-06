# 10 · Phase 2-5 · 콤보 시스템 + 점수 ×2

> **이번 작업의 한 줄**: 음표를 *연달아* 빨리 모으면 콤보가 쌓이고, 3콤보부터 점수가 *2배*로 들어온다.
> 비유: 농구 자유투에서 1~2번 들어가면 보통 점수, 3번째부터 *연속 보너스*. 손이 식으면(2.5초 안에 못 모으면) 콤보 0으로 리셋.

---

## 1. 한눈 요약

```
지금 (Phase 2-4)                          이번 작업 (Phase 2-5)
┌────────────────────────┐                ┌────────────────────────┐
│ 🎵 5   ⏱ 00:30         │                │ 🎵 5   ⏱ 00:30   🔥 4  │ ← 콤보 라벨 신규
│ ━━━━━━━━━━━━━━━━━━     │                │ ━━━━━━━━━━━━━━━━━━     │
│ ┃    ♪    ♪       ┃    │      ──→       │ ┃    ♪    ♪       ┃    │
│ ┃    │██│   ♪     ┃    │                │ ┃    │██│   ♪     ┃    │
│ ┃ [□] 닿으면 +1    ┃    │                │ ┃ [□] 콤보3+면 +2  ┃    │
│ ━━━━━━━━━━━━━━━━━━     │                │ ━━━━━━━━━━━━━━━━━━     │
│ 점수 가산 *고정*       │                │ 콤보 길이에 따라 *2배* │
└────────────────────────┘                └────────────────────────┘
       *모두 동등*                              *연속이 보상*
```

**핵심 변화 세 가지**:
1. **콤보 카운터** — `combo: Int` 변수 + 마지막 수집 시각 `lastCollectAt`. 2.5초 윈도우 안 재수집 = `combo += 1`, 윈도우 만료 = `combo = 0` 리셋.
2. **점수 분기** — 콤보 ≥ 3에서 수집한 음표는 +2점, 그 외는 +1점. GDD §8 정확 일치.
3. **HUD 콤보 라벨** — `🔥 N` 형태. 콤보 0/1이면 *숨김*(alpha 0), 2 이상부터 보임.

**부수 변화**: `lastUpdateTime`(2-4)을 *시점 비교용으로 재활용* — 새 변수 0건. didBegin이 4줄 → 8줄로 확장.

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 변경 | 한 줄 설명 |
|---|---|
| `GameConfig` 상수 4개 추가 | `comboWindow`, `comboBonusThreshold`, `scorePerNote`, `scorePerNoteCombo` |
| `GameScene` 변수 2개 추가 | `private var combo: Int = 0`, `private var lastCollectAt: TimeInterval = 0` |
| `GameScene.update(_:)` 만료 검사 추가 | 카운트다운 다음, `combo > 0 && currentTime - lastCollectAt > comboWindow`이면 `combo = 0` |
| `GameScene.didBegin` 콤보 갱신 + 점수 분기 | 윈도우 안이면 `combo += 1`, 아니면 `combo = 1`. 점수 가산은 임계 비교 |
| `GameScene.endGame()` HUD 인자 확장 | `hud.update(score: score, remainingTime: 0, combo: 0)` |
| `HUDNode` 콤보 라벨 추가 + `update` 시그니처 확장 | `comboLabel: SKLabelNode` + `update(score:remainingTime:combo:)`. 콤보 < 2면 `alpha = 0` |

### 왜 지금?
1. **2-4에서 *수집은 시각화* 됐지만 *모든 수집이 동등***. 게임이 *반복적*. 콤보가 들어오면 *전략*이 생김 — "지금 빨리 가면 ×2 노릴 수 있다".
2. **HUD가 *이미* 있음** = 콤보 라벨 추가가 *한 줄*. Phase 2-4 빌드 위에 올라타기 가장 가벼운 sub-feature.
3. **Phase 2-6(적) 진입 전 *보상 설계 완성***. 적이 들어오면 "F를 피해 빨리 모아야 한다"가 메커니즘인데, 콤보 보상이 없으면 *왜 빨리* 모아야 하는지 약함. 콤보가 *밀어붙이는 동기*.
4. **GDD §8 명세 완전 구현**. 점수 룰, 콤보 윈도우, 임계 모두 GDD 그대로.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| 사운드 (콤보 단계별 음계 C4→A5) | Phase 6 |
| 콤보 라벨 색 펄스 / 크기 강조 | Phase 6 폴리싱 |
| 콤보 깨질 때 시각 효과 (페이드아웃 등) | Phase 6 |
| Best 콤보 / UserDefaults | Phase 3 |
| 화캉스 보너스 (콤보 +2) | Phase 4 |
| 임간호 스킬 A 수집 점수 ×2 | Phase 5 (캐릭터 스킬과 함께) |
| 적 NPC / F 투사체 | Phase 2-6 |

---

## 3. Spring 비유 🌱

### 3-1. 콤보 = "rolling window aggregation"
| 개념 | Spring/Reactive | 본 작업 |
|---|---|---|
| 윈도우 | `Flux.windowTimeout(2.5초)` | `comboWindow: 2.5` |
| 트리거 시점 | `Instant.now()` | `lastUpdateTime` |
| 윈도우 만료 | onTimeout → flush | `combo = 0` 리셋 |
| 누적값 | `reduce(0, +)` | `combo += 1` |

Reactive Streams의 *시간 윈도우 집계*와 동치. 다만 Reactive는 *비동기 스트림*, 게임은 *60Hz 동기 루프* — 의미는 같고 호스트만 다름.

### 3-2. 점수 분기 = "비즈니스 룰의 *임계 분기*"
```swift
score += combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo
    : GameConfig.scorePerNote
```
Spring으로 치면 `Order.calculateTotal()` 안 *수량 임계*에 따른 단가 분기:
```java
total += quantity >= bulkThreshold ? bulkUnitPrice : standardUnitPrice;
```
*임계와 단가를 모두 상수로 추출*하면 GDD 변경 시 1줄. 룰 자체가 *데이터*가 됨.

### 3-3. `lastUpdateTime` 재활용 = "기존 인프라의 부수 사용"
2-4에서 *dt 계산용*으로 둔 `lastUpdateTime`을 콤보 만료 검사·콤보 갱신 시점 비교에도 그대로 사용. *새 변수 0*. Spring DI 컨테이너의 빈을 여러 컴포넌트가 공유하는 패턴.

> **함정 피하기**: 게임 일시정지 도입 시(Phase 3) `lastUpdateTime`은 시뮬레이션 시간이므로 정지 중엔 갱신 안 됨. 콤보 윈도우도 *함께 정지* — 의도된 결과.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `lastCollectAt: TimeInterval = 0` + `combo > 0` 가드 (Optional 회피)
```swift
private var lastCollectAt: TimeInterval = 0   // 0 = "아직 수집 0건"

// update 안 만료 검사
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}
```

**왜 Optional 안 씀?** `lastCollectAt: TimeInterval?`도 가능하지만 매번 `if let`. *0 초기값* + `combo > 0` 가드 조합이 더 깔끔. 첫 수집 전엔 `combo = 0`이라 만료 검사 자체를 건너뜀 → 0과 비교 안 됨.

**함정**: `lastCollectAt`을 `0`으로 초기화하는 건 *시점 비교의 의미상 부정확*하지만, *combo > 0 가드*로 *논리적으로 안전*. 가독성을 위해 *주석으로 명시* 필수.

### 4-2. `lastUpdateTime` 재활용 — didBegin에서 currentTime 접근
```swift
func didBegin(_ contact: SKPhysicsContact) {
    // ... noteBody 식별 ...
    let now = lastUpdateTime   // ⭐ update가 받은 마지막 currentTime
    let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
    combo = isInWindow ? combo + 1 : 1
    score += combo >= GameConfig.comboBonusThreshold
        ? GameConfig.scorePerNoteCombo
        : GameConfig.scorePerNote
    lastCollectAt = now
    note.run(.removeFromParent())
}
```

**왜 `lastUpdateTime`?** `didBegin`은 SpriteKit *충돌 단계*에서 호출 — `update(_:)`의 `currentTime`을 직접 받지 않음. `CACurrentMediaTime()`을 쓸 수도 있지만 *시뮬레이션 시간*이 아니라 *시스템 시간*이라 일시정지 시 어긋남. `lastUpdateTime`은 update에서 매 프레임 갱신되므로 *최대 1프레임(16ms) 지연*에 그치고 정지/시간배율과 동기.

**Spring 비유**: `@RequestScope`로 받은 timestamp을 같은 요청 내 다른 메서드에서 재사용 — *컨텍스트 전파*.

### 4-3. 삼항 연산자 + 상수 분리 (점수 분기)
```swift
score += combo >= GameConfig.comboBonusThreshold
    ? GameConfig.scorePerNoteCombo    // 2
    : GameConfig.scorePerNote          // 1
```
3-stage 구조: *임계 검사 → 단가 선택 → 가산*. 매직 넘버 0 (1, 2, 3 모두 GameConfig). 로직만 봐도 의도 자명.

**함정**: Swift 삼항 줄바꿈 시 들여쓰기로 *의도 명시* 필수. 한 줄로 쓰면 가독성 ↓.

### 4-4. 콤보 라벨 *조건부 표시* — `alpha = combo >= 2 ? 1 : 0`
```swift
// HUDNode.update 안
comboLabel.text = "🔥 \(combo)"
comboLabel.alpha = combo >= 2 ? GameConfig.hudAlpha : 0
```

**왜 alpha 0?** `isHidden = true`도 가능하지만 *보임/숨김 전환*이 매 프레임 반복되면 SpriteKit 내부 트리 갱신 비용. alpha 변경은 *셰이더 단계*라 비용 0. 60Hz 매 프레임 토글 안전.

**함정**: 콤보 0→1 전환 시 라벨이 *번쩍*하면 어색. 1까지는 안 보이고 2부터 등장하는 게 자연스러움 (사용자가 "곧 ×2가 올 것" 기대).

### 4-5. HUDNode `update(...)` 시그니처 *확장* — 호출처 1곳만 변경
```swift
// 기존 (2-4)
func update(score: Int, remainingTime: TimeInterval)

// 확장 (2-5)
func update(score: Int, remainingTime: TimeInterval, combo: Int)
```

**왜 단순 추가?** 호출처가 GameScene 2곳(`update(_:)` + `endGame()`)밖에 없어 시그니처 변경 비용 *최소*. `combo: Int = 0` 디폴트 인자도 가능하지만 *모든 호출처가 명시*하는 게 의미 분명.

**Spring 비유**: `@RequestParam` 확장 — 새 파라미터 추가 시 호출처가 *1군데*면 디폴트 없이도 깔끔.

### 4-6. update 만료 검사 위치 — 카운트다운 *다음*
```swift
guard gameState == .playing else { return }
remainingTime = max(0, remainingTime - dt)
if remainingTime <= 0 { endGame(); return }

// Phase 2-5 — 콤보 만료 검사 (gameOver 가드 *다음*에)
if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
    combo = 0
}

// 1) D-Pad 입력 ...
```

**왜 이 위치?** *gameOver 진입 시*엔 콤보 검사 의미 없음 (early return). *플레이 중*에만 콤보가 흘러감. 카운트다운 검사 *다음*이 자연스러움. player 갱신 *전*이라 콤보 변경이 그 프레임 hud.update에 즉시 반영.

### 4-7. `currentTime` 매개변수 *직접 사용* (update 안)
```swift
override func update(_ currentTime: TimeInterval) {
    // ...
    if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
        combo = 0
    }
}
```
`currentTime`은 update 매개변수로 들어옴. 만료 검사에 *그 자체* 사용 가능 — `lastUpdateTime`보다 *더 정확* (이전 프레임 값이 아니라 *지금* 값). 다만 update 안에서만 가능 — didBegin에선 `lastUpdateTime` 재활용.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.**

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | 상수 4개 추가 — `comboWindow=2.5`, `comboBonusThreshold=3`, `scorePerNote=1`, `scorePerNoteCombo=2`. 새 MARK `// MARK: - Combo (Phase 2-5)` |
| `Nodes/HUDNode.swift` | (1) `private let comboLabel: SKLabelNode` 추가, (2) init에서 `configure(comboLabel)` + 위치 `(0, -hudFontSize * 1.4 * 2)` + addChild, (3) `update(score:remainingTime:combo:)` 시그니처 확장 + 콤보 라벨 텍스트/alpha 갱신 |
| `GanhoMusic Shared/GameScene.swift` | (1) Properties에 `private var combo: Int = 0`, `private var lastCollectAt: TimeInterval = 0` 추가, (2) `update(_:)`에 콤보 만료 검사 + `hud.update`에 `combo:` 인자 추가, (3) `didBegin`에 콤보 갱신 + 점수 분기, (4) `endGame()`의 `hud.update`에 `combo: 0` 추가 |

### 절대 손대지 않는 파일
- `Nodes/PlayerNode.swift`, `Nodes/DPadNode.swift`, `Nodes/NoteNode.swift` (0바이트)
- `Config/PhysicsCategory.swift`, `Config/GameState.swift`, `Config/ColorTokens.swift` (0바이트)
- iOS 3 파일 (0바이트)
- `project.pbxproj` (0바이트 — *신설 파일 0건*이라 등록 변경도 0)

### Xcode 멤버십
**필요 없음.** 신설 파일 0건이라 `pbxproj` 변경 0건. 2-3/2-4의 fallback 정책 trigger 안 됨.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `combo` 등장 ≥ 6건 (GameScene 변수/만료 검사/didBegin 갱신/점수 분기/endGame, HUDNode 라벨 갱신)
- `comboWindow` 등장 ≥ 2건 (update + didBegin)
- `comboBonusThreshold` 등장 1건 (didBegin 점수 분기)
- `scorePerNote` 등장 1건, `scorePerNoteCombo` 등장 1건
- `Timer` / `print()` / `as!` / `fileprivate` / 강제 언래핑 `!` 0건
- 매직 넘버 0건 (2.5/3/1/2 모두 GameConfig)
- `update(_:)` 안 `addChild()` 0건 (HUD 라벨 추가는 HUDNode init만)

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 시작 직후 콤보 라벨 *안 보임* (alpha 0)
- (b) 음표 1개 수집 — 점수 +1, 콤보 라벨 여전히 안 보임 (combo=1)
- (c) 2.5초 *안에* 음표 2개 더 수집 — 점수 +1+1, 콤보 라벨 `🔥 3` 등장 (combo=3)
- (d) 2.5초 *안에* 4번째 수집 — 점수 +**2** (콤보 보너스 발동), 라벨 `🔥 4`
- (e) 2.5초 *지나서* 수집 — 콤보 라벨 사라짐, 점수 +1, 콤보 1로 리셋
- (f) 시간 만료(00:00) 시 콤보 라벨도 사라짐 (combo=0 강제)
- (g) 점수/시간 라벨, 박스/벽/기둥/음표/D-Pad/카메라 follow 모두 2-4 그대로

### 6-3. 회귀 (1-5 + 2-1 + 2-2 + 2-3 + 2-4 + 핫픽스)
- PlayerNode/DPadNode/NoteNode 0바이트
- Config 3 파일(PhysicsCategory/GameState/ColorTokens) 0바이트
- iOS 3 파일 / project.pbxproj 0바이트
- 1-3 핫픽스 / 1-5 카메라 follow / 2-1 외곽 벽 / 2-2 기둥 + gravity / 2-3 spawn + didBegin 식별 / 2-4 HUD 점수·시간 라벨 + endGame 모두 동작 보존
- HUDNode init의 *기존 두 라벨* 위치/스타일 그대로 (콤보 라벨만 *추가*)

---

## 7. 사용자 결정 필요 사항

### 결정 ① · 콤보 윈도우 / 임계 / 가산 점수
| 옵션 | 값 | 추천 |
|---|---|---|
| **A. GDD §8 명세 그대로** ⭐ | `comboWindow=2.5`, `comboBonusThreshold=3`, +1/+2 | ⭐ — GDD 정확 일치 |
| B. 다른 값 | 사용자 디자인 | GDD 갱신 부담 |

**왜 A?** GDD §8 "콤보 3 이상 수집 시 ×2", "마지막 수집 후 2.5초 이내 재수집 안 하면 초기화" 두 줄 그대로 변환.

### 결정 ② · 콤보 라벨 표시 정책
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 콤보 ≥ 2부터 보임** ⭐ | 0/1은 alpha 0. 2부터 등장 → "곧 ×2가 올 것" 기대감 | ⭐ — 시각 노이즈 최소 + 학습 효과 |
| B. 항상 보임 | "🔥 0" 등 항상 표시. UI 안정 | 0이 *지속*되면 시야 노이즈 |
| C. 콤보 ≥ 3부터 보임 | ×2 임계와 정확 일치 | 사용자가 *왜* 등장했는지 학습 어려움 |

**왜 A?** 1콤보는 단순 수집과 다를 게 없음. 2부터 보이면 *임계 직전 긴장감*. 3 도달 시 자연스럽게 ×2 발동 인지.

### 결정 ③ · 콤보 시점 변수 — `lastUpdateTime` 재활용 vs 새 변수
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. `lastUpdateTime` 재활용 + `lastCollectAt` 신규** ⭐ | 콤보용 시점 변수 1개만 추가 (`lastCollectAt`). 시점 *비교*는 `lastUpdateTime`(didBegin) 또는 `currentTime`(update 안) | ⭐ — 변수 최소 |
| B. `currentTime` 별도 저장 (`private var currentTime`) | didBegin에서도 항상 currentTime 정확 | 변수 1개 추가, 의미 중복 |

**왜 A?** `lastUpdateTime`은 이미 dt 계산용으로 *항상 최신*. 1프레임(16ms) 지연은 콤보 윈도우 2500ms에 비해 무시 가능. *기존 인프라 재활용*이 가장 깔끔.

### 결정 ④ · 콤보 라벨 위치
| 옵션 | 위치 | 추천 |
|---|---|---|
| **A. 시간 라벨 *다음*(3번째 줄)** ⭐ | scoreLabel(0,0) → timeLabel(0, -h*1.4) → comboLabel(0, -h*1.4*2) | ⭐ — 자연 누적 |
| B. 시간 라벨 *옆*(같은 줄) | 가로 배치. 화면 폭 1024라 가능 | 라벨 폭 변동 시 충돌 |
| C. 화면 *우상단* | D-Pad와 균형 | 새 좌표 산출 추가 |

**왜 A?** 기존 두 라벨 패턴 그대로 *세로 누적*. 줄간격 1.4 일관. 향후 베스트 라벨 추가 시도 같은 패턴.

### 결정 ⑤ · 콤보 시각 강조 (펄스/색)
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 단순 등장만 (alpha 0→0.85)** ⭐ | 깔끔. 점수 ×2 발동은 *점수 라벨 +2*로 간접 인지 | ⭐ — 1 SPEC = 1 sub-feature |
| B. + 콤보 3 도달 시 펄스/색 변화 | 발동 강조 | 시각 폴리싱 (Phase 6) |
| C. + 콤보 깨질 때 페이드아웃 | 정서적 피드백 | Phase 6 |

**왜 A?** 시각 폴리싱은 Phase 6에서 일괄. 본 sub-feature는 *콤보 로직*이 본질.

### 결정 ⑥ · 콤보 라벨 폰트/색
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 점수/시간 라벨과 동일 (`.ganhoPaper`, hudFontSize)** ⭐ | configure 헬퍼 그대로 적용. 새 토큰 0 | ⭐ — 일관성 |
| B. 콤보 전용 색 (`.ganhoPinkNote` 등) | 시각 강조 | Phase 6 폴리싱 |

**왜 A?** 본 sub-feature는 *기능*. 시각 차별화는 Phase 6. configure 헬퍼 한 번 호출로 끝.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 게임플레이 + 비주얼 (콤보 로직 + 라벨 시각화)
- **게임 경험 의도**:
  > "음표를 2.5초 안에 연속으로 모으면 콤보가 쌓인다. 3콤보부터 점수가 2배. 콤보 ≥ 2일 때 좌상단에 🔥 N 라벨이 등장한다. 게임이 *반복적 수집*에서 *연속 압박이 보상*인 구조로 진화한다."
- **Sprint 범위 계약**:
  - **IN**: 신설 파일 0. 수정 3 파일 (GameConfig 상수 4개, HUDNode 라벨 추가 + update 시그니처 확장, GameScene 변수 2개 + update 만료 검사 + didBegin 콤보 갱신/점수 분기 + endGame hud.update 인자 확장).
  - **OUT**: 사운드(콤보 음계) / 콤보 시각 펄스/색/페이드 / Best 콤보 / 화캉스 보너스 / 임간호 스킬 A / 적 NPC / 신설 파일.
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / `DispatchQueue.main.asyncAfter` 0건
  - `update(_:)` 안 `addChild()` 0건 (콤보 라벨은 HUDNode init에서만)
  - 매직 넘버 0건 — 2.5/3/1/2 모두 `GameConfig.combo*`/`scorePerNote*`. 라벨 위치 *2*(3번째 줄)는 자명한 산수
  - `lastCollectAt` *0 초기값* + `combo > 0` 가드 (Optional 회피)
  - 콤보 만료 검사 위치: `update(_:)` 안 카운트다운 *다음*, player 갱신 *전*
  - didBegin 콤보 시점은 `lastUpdateTime` 재활용 (새 변수 0)
  - 콤보 라벨 alpha = `combo >= 2 ? hudAlpha : 0` (조건부 표시)
  - HUDNode `update(score:remainingTime:combo:)` 시그니처 — 모든 호출처가 *명시*
  - configure 헬퍼는 *콤보 라벨에도 적용* — 폰트/색/정렬 일관
- **회귀 보존 (1-5 + 2-1 + 2-2 + 2-3 + 2-4 + 핫픽스)**:
  - PlayerNode / DPadNode / NoteNode / Config 3 파일 / iOS 3 파일 / pbxproj 모두 0바이트
  - 1-3 / 1-5 / 2-1 / 2-2 / 2-3 / 2-4 동작 보존
  - HUDNode 기존 두 라벨 (`scoreLabel`, `timeLabel`) 위치/스타일/text 형식 그대로

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없음.** Phase 2-3/2-4 자산이 깔끔히 깔려 있어서 *콤보 로직만* 추가하는 패턴이 정확히 들어맞음. 신설 파일 0 → `project.pbxproj` 변경 0 → 2-3에서 23줄 과변경했던 함정 자체가 재현 안 됨. 1차 빌드 SUCCEEDED + P0 0건 + 회귀 10/10. *가장 작은 변경 단위*로 게임플레이가 한 단계 진화.

> **인사이트**: SPEC §"신설 파일 0" 명시가 Generator의 *과설계 회피*에 큰 효과. "Systems/SpawnSystem.swift 분리"나 "ScoreSystem 분리" 같은 *유혹*을 SPEC OUT으로 못 박아 차단. 1 SPEC = 1 sub-feature 원칙이 가장 깨끗하게 작동한 sprint.

### 9-2. Spring과 다르네 싶었던 것
1. **Optional 회피 = "센티널 값 + 가드"**: `lastCollectAt: TimeInterval?` 대신 `= 0` + `combo > 0` 가드. Java로 치면 `Long lastCollectAt = 0L` + `combo > 0`로 의미 분기. Optional이 *문법적으로 정당*하지만 *논리적으로 가드*가 더 깔끔할 때가 있다는 것. **언어가 권장한다고 늘 옳은 건 아님**.
2. **삼항 연산자의 *줄바꿈 + 들여쓰기 정렬***: `score += combo >= threshold ? bonus : standard`를 한 줄에 쓰면 가독성 ↓. `?`/`:`을 다음 줄로 *동일 들여쓰기*로 떨어뜨리면 임계 검사 → 분기 → 가산이 *읽기 쉬움*. Java는 보통 한 줄로 쓰지만 Swift 컨벤션은 *줄바꿈 + 정렬*. 코드도 *문서*다.
3. **`lastUpdateTime` 재활용 = "기존 빈의 부수 사용"**: 2-4에서 dt 계산용으로 둔 변수를 콤보 만료 검사·didBegin 시점 비교에 그대로 사용. *새 변수 0*. Spring DI 컨테이너 빈을 여러 컴포넌트가 공유하는 패턴. **인프라 변수는 *설계 시점에 다목적 가능성*을 열어두는 게 가치**.
4. **`alpha` 분기 vs `isHidden` 토글**: 라벨 보임/숨김에 둘 다 사용 가능. `alpha`는 GPU 셰이더 단계라 비용 0, `isHidden`은 SpriteKit 노드 트리 갱신 비용 발생. *60Hz 매 프레임 토글*이라면 alpha가 안전. SwiftUI `opacity` vs `hidden()`도 같은 차이. **렌더링 파이프라인 위치를 알면 비용이 보임**.
5. **시그니처 *확장*만으로 호출처 일괄 갱신**: `update(score:remainingTime:)` → `update(score:remainingTime:combo:)` 시그니처 추가가 컴파일 에러로 *호출처를 자동 식별*. Swift의 *명명된 인자 강제*가 큰 안전망 — Java처럼 익명 인자라면 어떤 호출처가 새 인자를 빠뜨렸는지 컴파일러가 못 잡음. **명명 인자 = 무료 회귀 검사**.
6. **rolling window aggregation = `flux.window(2.5초)`의 명령형 버전**: Reactive Streams의 *시간 윈도우*를 SpriteKit의 60Hz 게임 루프에서 dt 비교로 구현. 같은 *수학적 개념* (시간 윈도우 + 누적 + 만료 리셋), 다른 *호스트* (비동기 스트림 vs 동기 게임 루프). **개념과 구현은 분리해서 학습**.
7. **`gameState != .playing` 가드 + `combo: 0` 인자의 *이중 보호***: endGame 후 `combo` 변수 자체는 리셋 안 해도 *update 가드*로 만료 검사 진입 안 함. 그러나 *라벨 표시*는 별개라 `combo: 0` 인자로 강제 숨김. **상태(state)와 표시(display)의 분리** — Spring `@Service` vs `@RestController`와 같은 SoC.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-6 진입 시)
1. **수간호사 적 NPC (Phase 2-6)**: EnemyNode + PhysicsCategory.enemy 활성화 (1-1 정의 5단계 sleep 후 활성). 플레이어 추적 AI: `update(_:)`에서 `enemy.position`을 `player.position` 방향으로 매 프레임 이동. 속도는 GameConfig.enemyBaseSpeed 신규.
2. **F 투사체 (Phase 2-6)**: ProjectileNode + PhysicsCategory 신설(투사체 비트마스크 추가). 적이 일정 주기로 player 방향으로 발사. SKAction 패턴 (각도 계산 + linearVelocity).
3. **didBegin 분기 확장 (Phase 2-6)**: 현재 player↔note만 처리. F↔player 또는 적↔player 추가 시 `if/else if/else nil` 사슬이 길어짐 → switch 또는 분리 함수(`handleNoteContact`/`handleEnemyContact`) 검토.
4. **F 피격 시 endGame 재호출 (Phase 2-6)**: 현재 endGame은 *시간 만료*만 진입. F 피격도 같은 endGame을 호출 — 그러면 endGame이 *진입 사유*에 따라 다르게 동작해야 할 수도(현재는 *동일*, 나중에 사유별 라벨 메시지 분기 가능).
5. **Systems/ 폴더 분리 (Phase 2-6 또는 2-7)**: 적/투사체 스폰까지 추가되면 GameScene이 비대해짐. 적·투사체 스폰을 `Systems/EnemySystem.swift`로 분리 검토. 음표 spawn 4 헬퍼와 함께 옮길지 별도 둘지 결정 필요.
6. **콤보 사운드 (Phase 6)**: GDD §15 — C장조 스케일 (C4→D4→…→A5). 콤보 단계별 음계 상승. 본 sprint에서 OUT.
7. **콤보 시각 강조 (Phase 6 폴리싱)**: 콤보 3 도달 시 펄스/색 변화. 9-2에서 알파/렌더링 비용 정리됨 → SKAction.sequence([fadeAlpha, fadeAlpha]) 패턴 후보.
8. **시간 ≤10초 빨간색 강조 (GDD §2)**: HUDNode `update`에서 `timeLabel.fontColor = remainingTime <= 10 ? .ganhoPinkNote : .ganhoPaper` 한 줄 분기. 폴리싱 후보.
9. **Best 콤보 + UserDefaults (Phase 3)**: 게임오버 시 `combo > bestCombo`이면 갱신. HUDNode에 `bestComboLabel` 추가.
10. **임간호 스킬 A 수집 점수 ×2 (Phase 5)**: 캐릭터 스킬 시스템과 함께. NoteNode에 `kind: NoteKind` 추가 ('standard'/'A')하고 didBegin 점수 분기에 `kind == .A ? score * 2 : score` 추가.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.5 / 10** — 강제 언래핑 0 / 매직 넘버 0 / MARK 일관성 / guard let 유지 / GameConfig 상수 4개 추출
- 게임 로직 (30%): **9.5 / 10** — 만료 검사 위치 정확 / didBegin 6줄 갱신 / `lastUpdateTime` 재활용 / SKAction·dt·GameState 가드 유지
- 성능 (20%): **9.5 / 10** — BUILD SUCCEEDED / [weak self] 보존 / alpha 분기로 트리 갱신 비용 회피 / Optional 회피 안전
- 기능 완성도 (15%): **10 / 10** — SPEC 1~5 정확히 구현 / OUT 0건 / 회귀 10/10 / pbxproj 변경 0
- **가중평균: 9.6 / 10 — 합격** (1회차 통과, 2-4와 동률)

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 7가지:
- (a) 시작 직후 콤보 라벨 안 보임
- (b) 1번째 수집: 점수 +1, 콤보 안 보임
- (c) 2.5초 안 3번째 수집: 콤보 라벨 `🔥 3` 등장, 점수 +1
- (d) 2.5초 안 4번째 수집: 점수 +2 (×2 발동), 라벨 `🔥 4`
- (e) 2.5초 *지나서* 수집: 콤보 사라짐, 점수 +1, combo=1로 리셋
- (f) 시간 00:00 도달 시 콤보 라벨 사라짐
- (g) 점수·시간 라벨/박스/벽/기둥/음표/D-Pad/카메라는 2-4 그대로

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 6건 사용자 OK (모두 추천대로 가는지)
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → GameConfig/HUDNode/GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-6 (수간호사 적 + F 투사체 + endGame 재호출)으로
```

> **2-5 본질**: 게임이 *연속 압박이 보상*인 구조로 진화. 적이 들어와도 (Phase 2-6) "왜 빨리 모아야 하는지"가 명확. *보상 설계*가 *위험 설계* 전에 와야 게임이 균형 잡힘.
