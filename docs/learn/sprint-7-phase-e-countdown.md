# Sprint 7 Phase E — "3·2·1·GO! 게임이 곧 시작돼"

> 게임 시작 후 1~2초간 화면이 멈춘 듯 보이는 문제를 해결하고, 영화 시작 전 카운트다운처럼 준비 시간을 시각화한 이야기.

---

## 1. 무엇이 문제였어?

게임을 시작하면 약 1~2초간 *입력은 막혀 있는데 화면은 그냥 평소대로*야. 사용자는 "어? 고장났나? 왜 안 움직이지?" 하면서 D-pad를 마구 눌러봐도 반응이 없었지.

원인: 게임 시작 직전에 컷씬 dismiss → spawn 시스템 준비 등 *내부 초기화 시간*이 있는데 그 시간 동안 *시각 피드백 0*이었어.

---

## 2. 어떻게 고쳤어?

영화 시작 전 카운트다운을 빌려왔어:

```
0.0s ┃ 화면 살짝 어두워짐(navyDeep 32% dim)
0.0s ~ 1.0s ┃ "3" navy 120pt 등장 → 페이드아웃
1.0s ~ 2.0s ┃ "2"
2.0s ~ 3.0s ┃ "1"
3.0s ~ 3.8s ┃ "GO!" coral 140pt → 큰 펄스 (1.2→1.8)
3.8s ~ 4.0s ┃ dim 페이드아웃 + 게임 시작 (입력 활성화)
```

화면이 *살짝* 어두워지니까 "지금은 준비 시간"이란 메시지가 즉시 전달돼. 게임 월드는 보이지만 *시작 전*임을 알 수 있지. 신호등의 빨강처럼.

3·2·1은 **차분한 navy 톤**(긴장 누적), GO!는 **따뜻한 코랄**(폭발적 시작)으로 색 대비. 비유하자면 영화관 광고 → 본편 시작의 *분위기 전환* 같은 효과.

---

## 3. 기존 CountdownNode를 재활용

놀랍게도 *이미* CountdownNode가 있었어. Phase 6-13에서 만들어진 클래스. 시그니처도 거의 완벽:

```swift
func start(
    onTick: @escaping (Int) -> Void,   // 3·2·1 각 단계
    onGo: @escaping () -> Void,         // GO!
    onComplete: @escaping () -> Void    // 완료
)
```

문제는 *시각만* 옛날 톤이었어:
- 색이 빨강·노랑·분홍·민트 (Sprint 7 v3는 navy + coral 한 가지로 통일)
- 폰트가 시스템 폰트 (Jua 적용 안 됨)
- 사이즈 96pt (사양은 숫자 120 / GO 140)
- GO! scale 1.0→1.3 (사양은 1.2→1.8 더 큰 펄스)

그래서 *4가지만 보강*하고 시그니처는 0줄 변경. "이건 새로 만들 게 아니라 화장만 다시 하는 거야" 패턴이지.

Spring 비유: 기존 `@RestController`의 `@RequestMapping`은 그대로 두고, 응답 DTO의 toJSON 포맷터만 새 톤으로 교체. 호출자 측은 *변경 0*.

---

## 4. dim 오버레이 — "준비 시간" 시각 신호

CountdownNode는 *숫자*만 책임지고, dim 오버레이는 GameScene이 직접 관리해. 책임 분리.

```swift
// GameScene.showCountdown 안
let dim = SKSpriteNode(color: .ganhoNavyDeep, size: size)
dim.alpha = 0  // 자연 페이드인
dim.zPosition = 240   // CountdownNode 250보다 뒤 → 숫자가 dim 위에 떠 보임
dim.name = "countdownDim"
cameraNode.addChild(dim)
dim.run(.fadeAlpha(to: 0.32, duration: 0.2))   // 0.2초 페이드인
```

`alpha 0.32`는 *살짝만* 어두워. 0.5 같이 진하면 게임 월드가 안 보여서 답답. 0.2면 너무 옅어 신호가 약함. 0.32가 *딱 좋은 균형* — 평면 사진의 *반사 광*처럼 살며시.

---

## 5. weak self 이중 캡처 — 메모리 누수 방지

게임 시작 시퀀스 끝부분이 이렇게 생겼어:

```swift
onComplete: { [weak self] in
    guard let self = self else { return }
    let fadeOut = SKAction.fadeOut(withDuration: 0.2)
    let cleanup = SKAction.removeFromParent()
    let startGame = SKAction.run { [weak self] in self?.startGameProperly() }
    dim.run(.sequence([fadeOut, cleanup, startGame]))
}
```

`[weak self]`가 *두 곳*에 있어:
- 외부 `onComplete: { [weak self] in ... }` — 콜백 자체
- 내부 `SKAction.run { [weak self] in ... }` — sequence 안 한 단계

왜? 외부 클로저는 `guard let self = self`로 강한 참조를 만든 *후* 내부 SKAction.run에 전달되는데, 그 안에서 *다시* self를 캡처하면 *강한 참조 사이클* 위험이 있어. 그래서 두 번 모두 `[weak self]`.

비유: 도서관에서 책을 빌릴 때 *대출증* 한 번만 보여주는 게 아니라, *반납할 때*도 다시 검사. 사이클을 만들지 않으려면 진입·이탈 둘 다 약한 참조.

ARC 비유 (Swift 메모리 관리): Spring의 `@PreDestroy`처럼 컴포넌트가 *깔끔히* 해제되도록 의식적으로 약한 참조를 깔아두는 패턴.

---

## 6. 보호 영역 — 광활한 0줄

이번 Phase에서 *건드리지 않은* 파일이 너무 많아 자랑할 만해:

- DPadNode / SkillButtonNode (입력 노드)
- SkillSystem / SpawnSystem / ContactRouter / ScoreSystem (시스템 4종)
- AudioManager / HapticManager (매니저)
- 모든 Repositories (HighScore/Statistics/PerDifficultyScore/Graduation)
- GameState enum / PhysicsCategory (게임 상태/물리 카테고리)
- ColorTokens (색 토큰 추가 0)
- 모든 다른 Scenes (Character/Skill/Difficulty/Result/Scoreboard/Start)
- Phase A·B·C·D 결과물 (CharacterCardNode/SkillExplanationScene/DifficultyCardNode/ResultScene/ScoreboardScene/CharacterFaceNode 등)

총 *20개+ 파일*이 0줄. 카운트다운 4초 시각만 새로 그렸을 뿐.

이게 *디자인 리뉴얼 모드 하네스*의 가치 — 작업 범위가 매우 좁고 *주변*을 깨끗하게 보존해.

---

## 7. dim fadeOut 후 startGameProperly — 시각 연속감

원래 startGameProperly() 함수는 spawnSystem.start + gameState = .playing 전환 같은 *게임 시작 로직*을 담아. 본체 0줄 변경.

대신 *호출 시점*만 0.2초 미뤘어:

```swift
let startGame = SKAction.run { [weak self] in self?.startGameProperly() }
dim.run(.sequence([fadeOut, cleanup, startGame]))
```

이렇게 하면:
1. GO! 페이드아웃 → CountdownNode 자가 소멸
2. dim 페이드아웃 (0.2초)
3. dim 제거 (cleanup)
4. *바로 그 순간* startGameProperly() 호출 → spawnSystem.start → 첫 음표 spawn

화면이 *밝아지자마자* 음표가 등장해. 시각적으로 부드러운 연속감.

만약 fadeOut을 안 기다리고 startGameProperly를 *먼저* 호출하면? dim이 아직 어두운 상태에서 음표가 dim 너머로 *흐릿하게* 등장. 어색해.

---

## 8. 입력 게이트는 이미 완벽

평소엔 입력 게이트 코드를 *추가*하는 게 일반적인데, 이번엔 *추가 0줄*. 왜?

기존 GameScene에 이런 가드가 *이미* 있었어:

```swift
override func update(_ currentTime: TimeInterval) {
    guard gameState == .playing else { return }   // ← 이 한 줄
    // ... dpad 입력 → player 이동 ...
}
```

게임 상태가 `.countdown`인 동안에는 update의 가드가 입력을 *자동 차단*. 카운트다운 끝나면 startGameProperly()가 `.playing`으로 전환 → 가드 통과 → 입력 활성화. *완벽한 동기화*.

Spring 비유: 컨트롤러 메서드에 `@PreAuthorize("hasState('PLAYING')")` 같은 가드를 미리 설정. 상태가 바뀌면 *자동*으로 접근 허용/차단. 별도 추가 로직 0.

---

## 9. 잔존 P2 — 추후 정리 후보

1. **V3 상수 명명**: `countdownGoEndScale`(V2 1.3)과 `countdownGoEndScaleV3`(1.8)이 공존. V2 상수가 더 이상 사용되지 않으면 Sprint 7 종료 후 deprecation 마크 또는 제거.
2. **사운드 등록**: 현재 tick/chime 전용 키 없음. Sprint 8에서 AudioManager에 `.countdownTick` / `.countdownGo` 추가 시, chime 길이가 dim fadeOut 0.2s보다 *길거나 같게* 설계.
3. **mockup 5번째 프레임**: 4프레임만 정적. dim fadeIn/fadeOut 전이 프레임을 1개 추가하면 mockup 매칭률 100%.

세 가지 모두 합격 영향 0 — 차기 정리 가능.

---

## 10. 다음(Phase F)은 뭐야?

**빌런 4종 시각 리뉴얼 + 박병장 신규.**

게임에 등장하는 빌런 4명:
- 수간호사 (EnemyNode) — 흰 가운 + 둥근 안경 + 차트
- 이교수 (ProfessorNode) — 청진기 + 갈색 머리
- 석조무사 (StoneGuardNode) — 회색 돌상 + 일자눈 + 방패
- **박병장 (SergeantParkNode 신규)** — 공군 청록 군복 + 검은 선글라스 + 항공 캡

기존 3종은 *시각만* 리뉴얼 (AI / hitbox 0 변경). 박병장은 *신규 SwiftKit 노드 클래스* 추가. 단 GameScene spawn 로직에는 *아직 등장 안 함* — 시각 시안 + 노드 클래스만 준비. 추후 Sprint 8에서 GameScene addHardMap에 spawn 로직 추가 가능.

변경 LOC ~500 예상. Phase F는 시각 작업이라 깊이는 얕지만 *4명*을 다루므로 코드량 큼.
