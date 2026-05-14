# Phase 6-15 — 뉴베스트 폴리싱 (NEW BEST! 결과의 영광)

## 한 줄 요약
ResultScene에 들어왔을 때 *이번 판 점수가 최고 기록*이면 화면 정중앙에 **큰 황금 "NEW BEST!"** 라벨이 0.3초 뒤에 *떠오르며 살짝 커졌다가* 정착해요 + **묵직한 진동** + **"딩!" 사운드** + 원래 BEST 라벨도 **황금 색으로 깜빡깜빡**. 6-13(시작)/6-14(끝)에 이은 *결과의 영광*. 신규 파일 0건.

---

## 무엇을 했나요?

두 식구만 살짝씩 손댔어요.

1. **ResultScene** — 신규 메서드 4개 (`configureNewBestLabel` / `scheduleNewBestReveal` / `revealNewBest` / `startBestLabelGoldBlink`) + 프로퍼티 3개(haptics, audio, newBestLabel) + setupLabels 분기 4줄 + layoutLabels 1줄
2. **GameConfig** — `MARK: - New Best (Phase 6-15)` 섹션 + 상수 10개

회귀 0줄: GameScene / TitleScene / HighScoreRepository / 자가 소멸 노드 8개 전체 / BGMPlayer / AudioManager / HapticsManager / HUDNode / Models / Protocols / Systems / ColorTokens — **23개 영역 미접촉**.

---

## 왜 이게 필요했을까? — "조용한 갱신"을 "축포"로

```
지금까지 (Phase 5-7까지)              이번 작업 후 (Phase 6-15)
신기록 달성:                            신기록 달성:
ResultScene 진입                        ResultScene 진입
    ↓                                       ↓
"★ NEW BEST! ★" 텍스트만 변함          (0.3초 후)
"700점" 점수 라벨                       ⚡ 큰 황금 "NEW BEST!" 등장
"BEST 🏆 700" 베스트 라벨              ⚡ 묵직한 진동 (heavy)
... 끝                                  ⚡ "딩!" 사운드 (NewMail)
                                        ⚡ BEST 라벨도 황금 깜빡임
                                            ↓
                                        "내가 최고 기록 세웠다!"
                                          → 신체로 통보
```

**조용한 텍스트 갱신**으로는 신기록 달성의 *체감*이 부족했어요.

학생 비유: 시험에서 *생애 최고점*을 받았는데 *작은 빨간 동그라미* 하나 그어진 채 시험지 받으면 "그래, 잘 봤구나"로 끝이잖아요. 그런데 선생님이 *큰 별 스티커* 붙여주고, *어깨 두드려주고*, 친구들이 *박수* 쳐주면 — "와! 내가 최고였구나!" 체감이 와요. 6-15가 게임에 그 *별 스티커 + 박수*를 추가한 거예요.

자전적 톤에서, 한 판 끝에 *신기록을 세웠다*는 사실은 *작곡 끝낸 새벽에 곡이 완성됐다는 자각의 순간*과 같아요. 그 자각을 *시각·청각·촉각*으로 동시에 통보 받아야 *진짜 완성*. 6-15가 그 완성의 멀티모달 마감.

---

## Phase 6의 *세 클라이맥스 가족*이 완성됐어요

```
6-13 시작 (출발의 개봉감)
    └ 3-2-1-GO! + heavy + NewMail
       ↓
6-14 끝 (마감의 긴박감)
    └ 5초 BGM rate↑ + HUD 빨강 깜빡임 + 매초 light
       ↓
6-15 결과 (영광의 통보) ← 지금
    └ NEW BEST! 황금 + heavy + NewMail + bestLabel 깜빡임
```

**시작/끝/결과**가 모두 멀티모달 클라이맥스. 한 판의 *3대 결정 순간*이 모두 시각·청각·촉각으로 전달돼요.

> **Spring 비유**: 결제 시스템에서 `OrderStarted`/`OrderCompleted`/`OrderRewarded` 3개 이벤트가 *모두* listener(시각/청각/촉각)를 가지는 것과 동형. 시작도 통보, 끝도 통보, *보상*도 통보 — 사용자가 *놓치는 결정 순간 0*.

학생 비유: 운동회에서 출발 신호(탕!) + 마지막 5초 함성(우와아!) + 1등 시상식(빛나는 트로피) — 세 순간 모두 *큰 무대*. 게임도 똑같이 *세 무대*가 완성.

---

## 핵심 결정 — *옵션 B (ResultScene 내부 라벨)*의 우아함

NewBest 표현을 어떻게 만들 것인가에 두 갈래가 있었어요.

```
[옵션 A] NewBestNode 자가 소멸 9호 신설        [옵션 B] ResultScene 내부 라벨 ← 채택
─────────────────────────────────                ───────────────────────────────────
+ 자가 소멸 노드 패턴 일관성                      + 신규 파일 0건 (6-14 정책 답습)
+ pbxproj 4지점 등록 (UUID 0034)                  + ResultScene 캡슐화 안쪽
+ 다른 Scene에서 재사용 가능                       + 라벨 1개 추가만 — 최소 변경
- 재사용 가능성 사실상 0                          - 자가 소멸 패턴은 깨짐 (영구 표시)
- 새 파일 1개 = 학습 부담                         - 하지만 ResultScene은 *한 판 1회* 표시
                                                     → ARC 자동 정리로 메모리 0
```

**옵션 B 채택 이유**:
1. **재사용성 0**: CountdownNode/ComboBreakNode는 *일반 위젯*이라 다른 Scene에서 쓸 수도 있지만, NewBest는 ResultScene *전용 표현* — 별도 노드로 추출할 필요 없음
2. **신규 파일 0 정책**: 6-14가 *가장 작은 sprint*를 만든 직후 → 6-15도 같은 흐름 유지
3. **수명 단순성**: 자가 소멸 노드는 1초 후 사라지지만 NewBest는 *씬이 살아있는 동안* 표시 → 자가 소멸 패턴이 *맞지 않음*. ResultScene이 TitleScene으로 전환되며 ARC가 자동 정리.

> **Spring 비유**: 어떤 기능을 *별도 빈*으로 분리할지 *컴포넌트 내부 private 메서드*로 둘지 결정 — *재사용성*과 *책임 영역*에 따라. NewBest는 ResultScene의 단일 책임 안쪽이라 분리 불필요.

---

## Swift / SpriteKit 학습 포인트

### 4-1. SKScene도 SKNode — 씬 자체에 SKAction 부착

```swift
private func scheduleNewBestReveal() {
    let wait = SKAction.wait(forDuration: GameConfig.newBestRevealDelay)
    let reveal = SKAction.run { [weak self] in
        self?.revealNewBest()
    }
    run(.sequence([wait, reveal]))   // ⭐ self.run — SKScene이 SKNode 상속
}
```

**왜 `self.run`?**
- `SKScene`은 `SKEffectNode → SKNode`를 상속받음. *씬 자체도 노드*라서 SKAction 부착 가능
- 별도 컨테이너 노드(cameraNode 등) 불필요 — 그냥 `run(...)` 호출
- ResultScene은 카메라 없음 (정적 UI) → 씬 자체가 SKAction 컨테이너

> **Spring 비유**: `@Service` 클래스 자체에 `@Scheduled` 메서드 부착 — 별도 worker 빈 안 만들고 *서비스가 자기 잡 자기가 실행*.

### 4-2. Timer 금지 → SKAction.wait + SKAction.run (Swift 규칙 9)

```swift
// ❌ 절대 금지 (자동 감점)
Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
    self.revealNewBest()
}

// ❌ 절대 금지 (자동 감점)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    self.revealNewBest()
}

// ✅ 권장 — SKAction 시퀀스
let wait = SKAction.wait(forDuration: 0.3)
let reveal = SKAction.run { [weak self] in self?.revealNewBest() }
run(.sequence([wait, reveal]))
```

**왜 Timer를 피하나?**
- **씬 라이프사이클과 동기화**: SKAction은 씬이 일시정지되면 *자동 정지*. Timer는 백그라운드에서도 돌아 *예상 못한 발화* 위험
- **씬 해제 시 자동 정리**: ResultScene이 dealloc되면 SKAction도 ARC로 같이 정리. Timer는 `invalidate()` 명시적 호출 필요
- **테스트 일관성**: SKAction은 SpriteKit 시간축, Timer는 RunLoop 시간축 — 두 시간축 혼용은 디버깅 지옥

> **Spring 비유**: `@Async` 메서드 안에서 *프레임워크 lifecycle*과 동기화된 비동기 처리 vs *직접 new Thread()* — 후자는 cleanup 누락 위험. SKAction = 프레임워크 위임.

### 4-3. `withKey` + 자연 멱등 — 같은 키 재호출 시 자동 교체

```swift
private func startBestLabelGoldBlink() {
    bestLabel.fontColor = .ganhoYellowF
    let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.5)
    let fadeIn  = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
    let cycle = SKAction.sequence([fadeOut, fadeIn])
    bestLabel.run(.repeatForever(cycle), withKey: "newBestBlink")
    //                                     ↑ 핵심
}
```

**`withKey`의 마법**:
- 같은 키로 *재호출*하면 SpriteKit이 *이전 액션 자동 제거* + 새 액션 부착
- 별도 `removeAction(forKey:)` 호출 불필요 (자연 멱등)
- 본 sprint에서는 한 판에 1회만 호출되지만, *미래의 안전망*

**6-14 `tensionBlink`와 동일 패턴**:
- ResultScene과 GameScene 양쪽에서 *동형 코드*
- 학습 부담 0 — 한 패턴만 알면 됨

> **Spring 비유**: 같은 ID로 `Scheduler.schedule(job)` 재호출 시 이전 잡 자동 취소. ID 기반 멱등.

### 4-4. ARC + Scene 라이프사이클 = 자동 정리

```swift
private func startBestLabelGoldBlink() {
    // ... repeatForever 부착 ...
    bestLabel.run(.repeatForever(cycle), withKey: "newBestBlink")
}

// ❌ 보통은 이런 cleanup 코드 필요할 듯
// override func willMove(from view: SKView) {
//     bestLabel.removeAction(forKey: "newBestBlink")
// }

// ✅ 실제로는 cleanup 코드 0건
// → ResultScene이 TitleScene으로 전환되며 dealloc
// → bestLabel도 함께 dealloc
// → 부착된 SKAction도 ARC로 자동 정리
```

**왜 명시적 cleanup 불필요?**
- ResultScene은 *한 판 1회* 표시되고 사라짐 (TitleScene 복귀)
- 씬 해제 시 *모든 자식 노드* + *부착된 액션* 모두 ARC로 정리
- `repeatForever`도 부모 노드가 사라지면 *자동 정지*

**자가 소멸 노드 8개와의 비교**:
- 자가 소멸 노드: *자기 자신*이 `removeFromParent()` 호출 (수명 1초)
- ResultScene 라벨: *씬 전환*이 정리 트리거 (수명 = 씬 수명)
- 둘 다 *명시적 cleanup 0줄* — 정리 방식이 다를 뿐

> **Spring 비유**: `@PreDestroy` 안 쓰고 *컨테이너 해제*에 cleanup 맡기는 패턴. ARC는 컨테이너 같음.

### 4-5. `isNewBest` 분기 — *진짜 작은* 회귀 차단

```swift
private func setupLabels() {
    // ... 기존 6개 라벨 setup 그대로 ...
    addChild(promptLabel)
    layoutLabels()

    // Phase 6-15 — 신기록일 때만 분기 진입
    if isNewBest {
        configureNewBestLabel()
        scheduleNewBestReveal()
    }
}
```

**`if isNewBest` 한 줄의 우아함**:
- 신기록 아닐 때: 분기 진입 0건 → newBestLabel addChild 0건, haptics/audio 호출 0건, bestLabel.fontColor 변경 0건
- *자연 차단* — 추가 가드 코드 0줄
- 기존 게임 흐름(700점 미만 일반 플레이)에 *완전 무영향*

**한 가지 if문의 책임**:
- *언제 발화하는지* 결정 → setupLabels 마지막 4줄
- *어떻게 발화하는지*는 4개 메서드(configure/schedule/reveal/blink)가 책임
- 단일 책임 분리

> **Spring 비유**: `@ConditionalOnProperty("isNewBest")` 빈 활성화 — 조건 분기로 *모든 코드*를 자동 차단.

---

## 산출물

**수정 (2 파일, +107줄)**:
- `Scenes/ResultScene.swift` (+85줄) — Properties 3개 + 신규 메서드 4개 + setupLabels 분기 4줄 + layoutLabels 1줄 + 헤더 1줄
- `Config/GameConfig.swift` (+22줄) — MARK New Best + 상수 10개

**신규 파일**: 0건
**pbxproj 변경**: 0건

---

## 검증 방법

### 정량
- ✅ `xcodebuild` BUILD SUCCEEDED (iPhone 17 시뮬레이터)
- ✅ 컴파일 경고 0건, 에러 0건
- ✅ `git diff --name-only HEAD`: 2개 파일만
- ✅ GameScene / TitleScene / 자가 소멸 노드 8개 / Managers / HUDNode / Repositories / Models / Protocols / Systems / ColorTokens 변경 0줄
- ✅ Sprint 회귀 0 영역 23개 미접촉
- ✅ Timer / DispatchQueue.main.asyncAfter 호출 0건
- ✅ AudioManager.SFX 신규 케이스 0건, ColorTokens 신규 색 0건
- ✅ QA 점수: **10.0 / 10.0** (Swift 10, 로직 10, 성능 10, 완성도 10)

### 시각 (사용자가 시뮬레이터에서 확인)
- [ ] 게임 시작 → 점수 충분히 쌓아 신기록 달성 → 0초 도달 또는 F 피격 → ResultScene 진입
- [ ] ResultScene 진입 직후 점수 라벨 표시 인지 (0.3초)
- [ ] 0.3초 후 화면 정중앙에 큰 황금 "NEW BEST!" 라벨이 *fade-in*되며 살짝 *커졌다가 원래 크기*로 정착
- [ ] "NEW BEST!" 등장과 동시에 (실기기) heavy 진동 + NewMail 사운드 "딩!"
- [ ] BEST 라벨 색이 황금으로 바뀌고 alpha 1.0↔0.5로 1초 주기 깜빡임 시작
- [ ] 화면 탭 → TitleScene 복귀 → 깜빡임 자동 정지
- [ ] 신기록 *아닐 때*: "NEW BEST!" 라벨 등장 0, BEST 라벨 색 변경 0, 햅틱 0, 사운드 0 (회귀 0 검증)
- [ ] 다음 게임에서 또 신기록 → ResultScene 새 인스턴스 → "NEW BEST!" 다시 등장 (멱등 가드 인스턴스 자동 리셋)

### 시뮬레이터 한계
- 햅틱 heavy는 시뮬레이터에서 noop — 실기기 필요
- NewMail 1025 사운드는 시뮬레이터에서도 들림

---

## 회고

### 막혔던 것
없음. SPEC 단계에서:
- `HighScoreRepository.record(_:) -> Bool` API 이미 존재 확인 → 새 API 0건
- `isNewBest` ResultScene init 주입 이미 동작 확인 → GameScene 미접촉
- `bestLabel` 기존 분기 (`★ NEW BEST! ★` / `BEST 🏆 N`) 미접촉 결정
- `SKScene.run()` 사용 가능 확인 (SKScene이 SKNode 상속)

→ Generator가 빌드 1회로 통과. **15번째 sprint의 누적된 SPEC 사전 검증**이 작동.

### Spring과 다르네 싶었던 것
1. **`SKScene` 자체에 SKAction 부착**: Spring `@Service` 클래스에 직접 잡 부착하는 패턴과 동형 — 별도 worker 불필요
2. **ARC + Scene 라이프사이클 자동 정리**: Spring `@PreDestroy` 안 쓰고 *컨테이너 해제*에 맡기는 패턴
3. **`withKey` 자연 멱등**: ID 기반 잡 관리와 동형. SpriteKit이 *자동* 처리
4. **`if isNewBest` 자연 차단**: Spring `@ConditionalOnProperty`와 동형 — 조건 1줄이 *모든 코드* 자동 차단

### 평가 점수
- Swift 패턴: 10/10
- 게임 로직: 10/10
- 성능: 10/10
- 완성도: 10/10
- **가중: 10.0 / 10.0**

### 사용자 직접 확인할 것
- 신기록 달성 시 0.3초 지연이 *드라마틱한지* (필요시 `newBestRevealDelay` 0.5초로 조정)
- 황금색 "NEW BEST!"가 bestLabel과 *겹쳐 보이는 위치*가 자연스러운지 (필요시 `newBestOffsetY`로 위/아래 분리)
- scale pulse 1.0→1.2→1.0이 *적절한 임팩트*인지 (필요시 `newBestEndScalePeak` 조정)
- heavy 진동이 시작(6-13 GO!) / 끝(피격) heavy와 *맥락 구분*되는지 (씬 전환으로 자연 구분 보장)
- BEST 라벨 깜빡임 1초 주기가 너무 빠른지 (필요시 `newBestBlinkHalfPeriod` 조정)

### 다음 sprint 후보
- **Phase 6 종결**: 픽셀 아트 + 앱 아이콘 (Phase 6 원래 스코프 마지막 항목)
- **Phase 7**: Supabase 백엔드 (Apple Sign In + 리더보드)
- **6-16 카운트다운 스킵**: 화면 탭으로 GO! 점프
- **6-16 BGM 곡 선택 / 난이도**: 게임 시작 전 옵션 화면

---

## 멀티모달 가족 — 15번째 sprint의 누적

| 이벤트 | 촉각 | 청각 | 시각 |
|---|---|---|---|
| 시작 카운트다운 (6-13) | light×3 + heavy | NewMail (GO!) | CountdownNode 3-2-1-GO! |
| 5초 긴박감 (6-14) | light×4 (매초) | BGM rate 1.0→1.15 | HUD 빨강 깜빡임 |
| **신기록 (6-15)** | **heavy×1** | **NewMail** | **NEW BEST! 황금 + bestLabel 깜빡임** |
| 노트 수집 (6-1/6-2/6-8) | light | Tink 1057 | Sparkle 8방향 |
| 콤보 마일스톤 (6-10/6-11) | light/medium/heavy | Tink/NewMail | ComboPopup ↑ |
| 콤보 끊김 (6-12) | heavy | (제외) | ComboBreak ↓ |
| 피격 (6-1/6-2/6-9) | heavy | Boop 1073 | HitFlash 빨강 |
| 게임오버 (6-2/6-5) | heavy | Boop 1073 | (Scene 전환) |

**Phase 6 시리즈가 15번째 sprint를 거치며 *피드백 시스템*이 완전 마감**됐어요. 한 판의 *시작·진행·끝·결과* 모든 결정 순간이 멀티모달. 이번 6-15가 *결과의 영광*을 채워 시리즈 완성.

---

## 한 줄 교훈

> **"가장 큰 영광은 *기존 자산을 다시 빛나게 하는 것*이다."**

이번 sprint에서:
- 신규 파일 0건
- 신규 SFX 케이스 0건 (`.comboMilestoneStrong` 재사용)
- 신규 색 0건 (`.ganhoYellowF` 재사용)
- 신규 매니저 0건 (HapticsManager / AudioManager 재사용)
- 신규 노드 0건 (라벨 1개만 추가)

*기존 자산*만 조합해서 *완전히 새로운 클라이맥스 순간*을 만들었어요. 황금색 라벨 + 6-11 사운드 + heavy 햅틱 + 깜빡임 = NewBest 영광.

> **Spring 비유**: *기존 빈*과 *기존 이벤트*만 조합해서 새 비즈니스 로직 만들기. 새 클래스 0건, 새 의존성 0건, 새 설정 0건 — *조합의 힘*.

같은 NewMail 사운드라도:
- 6-11에서는 *콤보 x20 클라이맥스*
- 6-13에서는 *출발 GO!*
- 6-15에서는 *신기록 영광*

*같은 자원, 다른 맥락* = 사용자에겐 *세 개의 다른 경험*. 자원 절약의 미학.

Phase 6은 이제 **15번째 sprint**까지 누적. 시작/끝/결과의 세 클라이맥스 완성. 다음은 어디로 가도 자연.
