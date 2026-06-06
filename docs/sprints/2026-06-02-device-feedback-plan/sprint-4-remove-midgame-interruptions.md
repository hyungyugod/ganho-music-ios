# Sprint 4 - Remove Midgame Interruptions

## 목표

게임 중간에 두 번 정도 나와서 진행을 끊는 멘트/컷씬을 제거한다. 플레이 중 흐름을 멈추지 않게 하고, 필요한 피드백은 비차단 HUD/이펙트만 남긴다.

## 현재 상태

- `GameScene.update`에서 `triggerMidCutsceneIfNeeded()`를 호출한다.
- `GameScene+Cutscene.triggerMidCutsceneIfNeeded()`는 남은 시간 30초/15초 부근에 mid1/mid2를 보여준다.
- mid 컷씬은 `gameState = .cutscene`으로 바꾸고 `CutsceneOverlayNode`를 띄워 플레이를 멈춘다.
- 사용자는 "게임 중간에 나오는 멘트들은 다 없애도 될 것 같다. 2번 정도 나온다"고 했다. 이는 mid1/mid2와 정확히 맞다.

## 변경 의도

인트로/튜토리얼성 안내와 게임 중간 차단 멘트를 분리한다. 이번 Sprint에서는 게임 플레이 도중 나오는 mid1/mid2만 제거한다. 점수 팝업, 콤보 팝업, 피격 이펙트처럼 즉시 읽히는 비차단 피드백은 유지한다.

## 구현 범위

### Phase A - mid 컷씬 비활성화

선택지:

1. `triggerMidCutsceneIfNeeded()`를 항상 false로 반환.
2. `GameScene.update`에서 호출 자체를 제거.
3. `GameConfig.enableMidGameCutscenes = false` 상수를 두고 가드 처리.

권장: 3번.

이유:

- 추후 다시 켜야 할 때 구조가 남는다.
- QA에서 "중간 멘트 제거" 범위를 한눈에 볼 수 있다.
- `CutsceneTexts`와 `MidCutsceneNode`는 dead code가 되더라도 바로 삭제하지 않아도 된다.

예상 흐름:

```swift
func triggerMidCutsceneIfNeeded() -> Bool {
    guard GameConfig.enableMidGameCutscenes else { return false }
    ...
}
```

### Phase B - cutscene state side effect 확인

- mid 컷씬 제거 후 `cutscenesShown`에는 intro 관련 key만 남는다.
- `remainingTime`은 더 이상 mid 컷씬 중 멈추지 않는다.
- `gameState`가 `.playing`으로 계속 유지된다.

### Phase C - 피드백 유지 여부 정리

유지:

- `ScorePopupNode`
- `ComboPopupNode`
- `ComboBreakNode`
- `HitFlashNode`
- 위험 경고 시각 레이어
- HUD tension blink

제거/비활성:

- `MidCutsceneNode.presentMid1`
- `MidCutsceneNode.presentMid2`

보류:

- 인트로 컷씬과 villain warning은 게임 시작 전 안내라 이번 Sprint에서 제거하지 않는다.
- 박병장/석조무사/이교수 특수 이벤트 컷씬은 별도 게임 규칙 설명 성격이라 이번 Sprint에서 건드리지 않는다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/GameScene+Cutscene.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`
- `GanhoMusic/GanhoMusic Shared/GameScene.swift` 확인 대상

## 수용 기준

- 한 판 플레이 중 30초/15초 부근에서 컷씬/멘트 overlay가 뜨지 않는다.
- mid 컷씬 때문에 플레이가 멈추지 않는다.
- 인트로/카운트다운/게임 종료 흐름은 유지된다.
- 콤보/점수/피격 같은 비차단 피드백은 유지된다.

## 리스크와 대응

- 리스크: mid 컷씬 제거로 서사 정보가 사라진다.
  - 대응: 캐릭터 홈이나 스킬 설명 쪽에 서사를 남기고 인게임은 플레이 중심으로 둔다.
- 리스크: 기존 `cutscenesShown` 관련 주석과 실제 동작이 달라진다.
  - 대응: 주석을 `enableMidGameCutscenes` 기준으로 갱신한다.
- 리스크: gameState 전환 제거로 테스트가 필요하다.
  - 대응: 45초를 끝까지 진행해 result 전환을 확인한다.

