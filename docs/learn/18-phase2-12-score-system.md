# 18 · Phase 2-12 · 점수와 콤보 분리 — ScoreSystem 🎯

> **이번 작업 한 줄**: 점수/콤보 *상태*와 *갱신 로직*을 별도 파일(`ScoreSystem.swift`)로 옮긴다. **기능 변화 0**.

---

## 1. 왜 또?

리팩터 3단계 마지막. 지금까지:
- 2-10: SpawnSystem (음표/F 생성)
- 2-11: ContactRouter (충돌 분기)
- **2-12: ScoreSystem (점수/콤보) ← 이번**

이제 GameScene이 *조율자*만 됨. 각 시스템이 자기 책임을 가짐.

```
GameScene (조율)
├─ SpawnSystem (생성)
├─ ContactRouter (충돌 분기)
└─ ScoreSystem (점수/콤보)  ← 신설
```

---

## 2. 무엇을 옮기나?

GameScene에 있던:
- 멤버: `score`, `combo`, `lastCollectAt`
- 로직: 콤보 윈도우 만료 검사 (`update` 안)
- 로직: 음표 수집 시 콤보+점수 갱신 (`onNoteCollected` 콜백 안)

→ ScoreSystem.swift로 이전.

GameScene은 ScoreSystem에서 *현재 점수/콤보 조회*만 함 (HUD 갱신 위해).

---

## 3. 새로 배운 것

### 3-1. **상태와 로직을 함께** — Encapsulation(캡슐화)
```swift
final class ScoreSystem {
    private(set) var score: Int = 0       // 외부 read 가능, write 불가
    private(set) var combo: Int = 0
    private var lastCollectAt: TimeInterval = 0
    
    func recordNoteHit(at now: TimeInterval) {
        // 콤보 윈도우 검사 + 갱신
        let isInWindow = combo > 0 && now - lastCollectAt < GameConfig.comboWindow
        combo = isInWindow ? combo + 1 : 1
        score += combo >= GameConfig.comboBonusThreshold
            ? GameConfig.scorePerNoteCombo
            : GameConfig.scorePerNote
        lastCollectAt = now
    }
    
    func tickComboExpiry(currentTime: TimeInterval) {
        if combo > 0, currentTime - lastCollectAt > GameConfig.comboWindow {
            combo = 0
        }
    }
    
    func reset() {
        score = 0
        combo = 0
        lastCollectAt = 0
    }
}
```

### 3-2. **`private(set)` — 읽기는 공개, 쓰기는 비공개**
> 외부에서 *읽을 수만 있고 못 바꿈*.

```swift
private(set) var score: Int = 0
```

GameScene이 `scoreSystem.score`로 *읽기는 가능*. 하지만 `scoreSystem.score = 999` 같은 *직접 쓰기는 컴파일 에러*. 점수 변경은 *반드시 recordNoteHit() 메서드*를 통해서만.

**Spring 비유**: `@Getter`만 있고 `@Setter`는 private. 비즈니스 로직 거치지 않은 *상태 변경* 차단.

### 3-3. **메서드로 행동 표현**
```swift
recordNoteHit(at:)        // "음표 맞았어"
tickComboExpiry(currentTime:)  // "지금 시간으로 콤보 만료 검사"
reset()                   // "리셋"
```

GameScene이 ScoreSystem에 *명령*. 내부에서 어떻게 처리하는지는 *몰라도 됨* — 추상화.

---

## 4. 새로 만든 것

### 새 파일
- `Systems/ScoreSystem.swift` — final class. score / combo / lastCollectAt 보유. 3개 public 메서드.

### 고친 파일
- `GameScene.swift`:
  - 멤버 3개(`score`/`combo`/`lastCollectAt`) *제거*
  - `private let scoreSystem = ScoreSystem()` 멤버 추가
  - `update`에서 `scoreSystem.tickComboExpiry(currentTime:)` 호출
  - `update`에서 `hud.update(score: scoreSystem.score, ..., combo: scoreSystem.combo)` 갱신
  - `onNoteCollected` 콜백에서 `scoreSystem.recordNoteHit(at: lastUpdateTime)` 호출
  - `endGame`에서 `hud.update(score: scoreSystem.score, ...)` 갱신

### Xcode pbxproj
- ScoreSystem.swift 등록

---

## 5. 직접 확인할 것

⌘R 후 — *2-11과 똑같이*:

| # | 봐야 할 것 |
|---|---|
| (a) | 음표 수집 시 점수 +1 (콤보 미발동) |
| (b) | 빨리 3개 연속 수집 시 콤보 라벨 등장 + 점수 ×2 |
| (c) | 2.5초 지나면 콤보 리셋 |
| (d) | HUD 점수/시간/콤보 정상 |
| (e) | 게임 종료 시 점수 보존 |

**기능 변화 0**.

---

## 6. 사용자 결정 (모두 추천대로)

| 결정 | 선택 | 왜 |
|---|---|---|
| 분리 단위 | ScoreSystem 1개 | 점수/콤보는 한 책임 |
| 상태 접근 | `private(set)` | 외부 직접 쓰기 방지 |
| 메서드 | recordNoteHit / tickComboExpiry / reset | 명확한 행동 단위 |

---

## 7. 회고

### 7-1. 막혔던 것
**없음.** 9.675/10 합격. 산식 라인별 동등성 검증 완료.

### 7-2. 새로 배운 것
1. **`private(set)` 접근 제어** — 외부 *읽기 OK*, 외부 *쓰기 차단*. 비즈니스 로직 거치지 않은 직접 변경 방지.
2. **상태와 로직을 함께 캡슐화** — score/combo가 *어디 있는지*보다 *누가 변경하는지*가 중요. ScoreSystem이 *유일한 변경 주체*.
3. **메서드로 행동 표현** — `recordNoteHit(at:)` / `tickComboExpiry` / `reset()`. 외부에서 *행동 단위*로 호출.
4. **시간 출처 분리** — recordNoteHit이 *now를 인자로 받음*. 테스트 시 *임의 시각* 주입 가능.
5. **리팩터 시리즈 마무리** — SpawnSystem(2-10) → ContactRouter(2-11) → ScoreSystem(2-12). 각 시스템 책임 분리. GameScene은 *조율자*.

### 7-3. 다음으로 미룬 것
- **Phase 3 진입** — 게임오버 화면 / 다시 시작 / 최고 기록.
- **Phase 4** — 난이도 normal / hard.

### 7-4. 평가 점수
- **가중평균: 9.675 / 10 — 합격**

### 7-5. 리팩터 시리즈 종합

| Phase | sprint | GameScene 줄 수 |
|---|---|---|
| 2-9 | (리팩터 전) | 446 |
| 2-10 | SpawnSystem 분리 | 354 (-92) |
| 2-11 | ContactRouter 분리 | 324 (-30) |
| 2-12 | ScoreSystem 분리 | **315 (-9)** |

**총 -131줄 (-29%)**. 코드 책임 명확. 다음 Phase 진입할 깨끗한 토대 완성.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(e) 확인
[2] 다음 sprint: Phase 3 (게임오버 화면)
```

> **이번 sprint 본질**: 리팩터 3단계 마무리. GameScene이 *조율자*가 되고, 각 시스템이 *자기 책임*을 가짐. 다음 단계(Phase 3+) 진입할 *깨끗한 토대*.
