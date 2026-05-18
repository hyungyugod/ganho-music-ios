# Phase 7-3 학습 노트 — 인트로 컷씬 (자가 소멸 노드 10호)

## 오늘 만든 것

게임을 시작하면 *바로* 카운트다운(3-2-1-GO!)이 뜨던 게, 이제는 그 *전에* 짧은 이야기 화면이 뜹니다:

```
어느 한적한 병동의 오후

수간호사가 순찰을 돈다. 그 틈을 타, 김간호는 주머니 속
작곡 노트를 슬쩍 꺼낸다… 음표를 모으자.

           TAP TO CONTINUE
```

- 난이도 **하/중**: 위 텍스트
- 난이도 **상**: "학교에서 나온 깐깐한 이교수가 오늘따라 청진기를 휘두른다…" (이교수 내러티브)
- `{NAME}`은 *지금 고른 캐릭터 이름*으로 자동 교체 (김간호/정간호/건간호/임간호/이간호)
- 화면 어디든 한 번 탭하면 사라지고 → 기존 카운트다운 → 게임 시작

## 왜 게임 시작 전에 이야기를 보여줘?

이 게임은 그냥 *점수 게임*이 아니에요. 사용자가 *간호 실습 중 작곡한* 자전 경험이고, 그 분위기가 게임 정체성이에요. 첫 화면에 "어느 한적한 병동의 오후"라는 *장소와 시간*을 박아두면 — 플레이어가 *내가 무슨 이야기를 플레이하는지* 알 수 있어요.

**Spring 비유** — REST API의 첫 화면이 `/` 루트가 아니라 `/welcome`에서 *"우리 서비스는 이런 거예요"* 인사하는 것과 비슷. 첫 인상이 *맥락*을 만들어요.

## "터치 트리거 자가 소멸" — 새로운 패턴

지금까지 자가 소멸 노드 9형제는 *시간 기반*이었어요:
- 1~9호 모두: `SKAction.wait(0.5초) → fadeOut → removeFromParent`

이번 10호 `CutsceneOverlayNode`는 *터치 기반*이에요:
- `touchesBegan` → `dismiss()` → `fadeOut → removeFromParent → onDismiss 콜백`

**왜 시간이 아니라 터치?** 컷씬은 *사용자가 텍스트를 다 읽었을 때* 사라져야 해요. 누군가는 3초 만에 읽고, 누군가는 10초 걸려요. 시간 고정은 *둘 다에게 부적절*. 그래서 *사용자가 준비됐다는 신호(탭)*를 기다려요.

**Spring 비유** — `@Async` 자동 트리거 vs `MessageQueue` 이벤트 트리거. 시간 기반이 자동 트리거라면, 터치 기반은 *외부 이벤트*가 트리거. 같은 자가 소멸이지만 *발사 조건이 다름*.

## "다중 탭 차단" — 2중 안전망

탭하면 `dismiss()` 가 호출돼요. 그런데 페이드아웃이 0.3초 걸려요. 그 사이에 *또 탭*하면? 콜백이 두 번 호출돼서 `showCountdown()`도 두 번 호출되고 → 카운트다운이 겹쳐서 게임이 망가져요.

해결: **2중 안전망**

```swift
private func dismiss() {
    isUserInteractionEnabled = false  // (1) SpriteKit 레벨에서 터치 차단
    let callback = onDismiss
    onDismiss = nil                    // (2) 콜백 자체를 nil로 만들기
    let fadeOut  = SKAction.fadeOut(withDuration: GameConfig.cutsceneFadeOutDuration)
    let cleanup  = SKAction.removeFromParent()
    let notify   = SKAction.run { callback?() }
    run(.sequence([fadeOut, cleanup, notify]))
}
```

(1) `isUserInteractionEnabled = false`로 OS 레벨에서 추가 터치를 *노드에 전달조차 안 함*.
(2) 그래도 어떤 경로로 `dismiss()`가 다시 호출돼도, `onDismiss`가 이미 nil이라 콜백 두 번 호출 0.

**Spring 비유** — `@Transactional`이 *중복 트랜잭션*을 막는 것과 `synchronized` 블록이 *동시 호출*을 막는 것을 **둘 다** 거는 셈. 한 겹은 못 미더우면 두 겹.

## GameState `.cutscene` — "상태 하나로 7개 시스템 자동 정지"

게임 루프는 `update(_:)` 메서드에서 매 프레임 돌아요. 거기 *맨 위*에 이런 한 줄이 있어요:

```swift
override func update(_ currentTime: TimeInterval) {
    guard gameState == .playing else { return }
    // ... 7개 시스템 (타이머/이동/카메라/적/콤보/끊김/HUD) ...
}
```

`gameState`가 `.playing`이 아니면 *모든 시스템이 멈춰요*. 컷씬 표시 중 `gameState = .cutscene`으로 바꿨으니까, 이 한 줄이 *마법처럼* 7개를 동시에 정지해요.

**Spring 비유** — `@ConditionalOnProperty("game.state", havingValue="playing")` 같은 거. 한 조건이 *수많은 빈* 의 활성화를 동시에 켜고 꺼요. *단일 진실 원천* 패턴.

이게 이번 sprint가 *회귀 0*을 유지할 수 있었던 이유. 컷씬 중 시스템 정지를 위해 *7개를 따로 정지*시킬 필요가 없었어요. *상태 하나만* 바꾸면 됐죠.

## `showCountdown()`을 *그대로* 호출하기

기존 흐름:
```
didMove → gameState = .countdown → showCountdown()
                                          ↓ (CountdownNode 자가 소멸 후)
                                    startGameProperly()
```

새 흐름:
```
didMove → gameState = .cutscene → showIntroCutscene()
                                          ↓ (CutsceneOverlayNode 탭 후)
                                    gameState = .countdown
                                    showCountdown()    ← 기존 그대로!
                                          ↓ (CountdownNode 자가 소멸 후)
                                    startGameProperly()
```

`showCountdown()`은 *한 줄도 안 건드렸어요*. 그냥 더 *뒤로 미뤘을* 뿐. 카운트다운 로직, 타이밍, 사운드 전부 동일.

**Spring 비유** — Interceptor를 *하나 더 끼워넣음*. 기존 컨트롤러는 그대로, 그 *앞에* 새 인터셉터를 두는 것. *기존 코드를 안 바꾸고 새 단계를 추가*하는 게 Open/Closed Principle.

## `{NAME}` 치환 — 토큰 패턴

원본 텍스트:
```
"수간호사가 순찰을 돈다. 그 틈을 타, {NAME}는 주머니 속..."
```

Swift 한 줄로 치환:
```swift
let body = template.replacingOccurrences(of: "{NAME}", with: characterID.displayName)
```

이렇게 하면:
- 김간호 선택: "수간호사가 순찰을 돈다. 그 틈을 타, **김간호**는 주머니 속..."
- 임간호 선택: "수간호사가 순찰을 돈다. 그 틈을 타, **임간호**는 주머니 속..."

5명 캐릭터 ✕ 3 난이도 = 15개 텍스트를 *하나의 템플릿 + 한 줄 치환*으로 처리. 만약 캐릭터가 늘어나도 텍스트는 그대로.

**Spring 비유** — `MessageSource.getMessage("welcome.user", new Object[]{username})` 같은 i18n 패턴. *템플릿과 데이터를 분리*해 둬요.

## `numberOfLines = 0` — iOS의 자동 줄바꿈

원본 hard 텍스트는 ~70자 (한 줄로 표시하면 화면을 벗어남). 줄바꿈을 *수동으로 \n으로 표시*할 수도 있지만, 화면 크기가 다양해서 어려워요.

SKLabelNode가 iOS 11부터 자동 줄바꿈을 지원해요:
```swift
bodyLabel.numberOfLines = 0  // 0 = "필요한 만큼 자동"
bodyLabel.preferredMaxLayoutWidth = sceneSize.width * 0.7  // 최대 폭 (70%)
```

이러면 SpriteKit이 *알아서* 단어 경계에서 줄바꿈해요. 화면 1024 폭이면 716pt 안에 맞춤. 더 작은 화면(예: 아이폰 미니)이면 더 좁은 폭에서 더 많은 줄로.

**Spring 비유** — CSS의 `max-width: 70%` + `word-wrap: break-word`. *컨테이너가 알아서* 줄을 끊어줘요. 수동 \n보다 *반응형*.

## `cameraNode` vs `worldNode` — 부착 부모의 의미

게임에는 두 가지 좌표계가 있어요:
- **worldNode**: 게임 월드. 플레이어, 음표, 적, 맵 타일이 자식. 카메라 따라 시프트됨.
- **cameraNode**: 카메라. HUD, 카운트다운, 컷씬이 자식. 화면에 고정됨.

컷씬은 **cameraNode** 자식이에요. 왜?
- 카메라가 이동해도 *화면 중앙 고정*
- 월드 좌표가 달라도 *항상 같은 자리*
- HUD/카운트다운과 같은 *글로벌 시그널*

만약 worldNode에 붙였다면 — 컷씬이 *플레이어 위치*에 따라 보이는 자리가 바뀌었을 거예요. 부적절.

**Spring 비유** — `@RequestScope` (요청마다 새로) vs `@ApplicationScope` (앱 전체 하나). 어느 *컨텍스트*에 속하느냐가 *어떻게 보이느냐*를 결정.

## 회귀 0의 마법 — 5파일만 변경

이번 sprint, *5파일만* 변경했어요:
1. `GameState.swift` (+2): case 1개 추가
2. `GameConfig.swift` (+33): 상수 11개 추가
3. `GameScene.swift` (+40/-2): didMove 2줄 교체 + 메서드 1개 신설
4. `CutsceneOverlayNode.swift` (신규): 컷씬 노드
5. `pbxproj` (+4): 신규 파일 등록

다른 *35+ 파일*은 git diff **0줄**. 거대한 회귀 위험 차단의 비결:
- `gameState` 한 줄로 모든 시스템 자동 정지
- CountdownNode는 *호출 시점만 미룬* 거지 코드 미접촉
- 새 case 추가가 다른 switch에 영향 안 미침(grep 0건)
- 컷씬 노드가 *자기 책임*을 다 캡슐화 (private init + 자체 dismiss)

**Spring 비유** — *비침습적(non-invasive) 변경*. 기존 시스템을 바깥에서 *조립만 다르게* 해서 새 동작을 만드는 것. 큰 시스템의 핵심 변경 전략.

## 오늘의 한 줄

> *"게임 시작 1.5초의 침묵이, 이 게임이 누구의 이야기인지 알려준다 — 카운트다운 전에 호흡 한 번."*
