# Sprint 1 - Result Navigation and New Best Layout

## 목표

결과 화면에서 빈 공간을 눌렀을 때 의도치 않게 메인으로 돌아가는 동작을 제거한다. 사용자가 명확히 누를 수 있는 `메인으로` 버튼을 추가하고, `NEW BEST` 표시 위치를 더 자연스럽게 조정한다.

## 현재 상태

- `ResultScene`에는 `shareButton`, `restartButton`, `scoreboardButton`이 있다.
- `touchesBegan`에서 share/restart/scoreboard가 아닌 모든 터치는 `StartScene.newStartScene()`으로 전환된다.
- 주석도 "그 외는 StartScene 전환"이라고 되어 있어 현재 동작이 의도적으로 남아 있지만, 실기기에서는 오작동처럼 느껴진다.
- `newBestLabel`은 별도 노드로 중앙 근처에 배치되고, `bestPill`도 신기록 상태를 표시한다. 두 신기록 표시가 서로 애매하게 겹친다.

## 변경 의도

결과 화면은 사용자가 점수를 보고 다음 행동을 고르는 화면이어야 한다. 빈 공간 탭은 아무 일도 하지 않고, 화면 전환은 버튼만 담당하게 만든다. 신기록 표시는 "작은 장식"이 아니라 점수 근처의 명확한 보상 상태로 정리한다.

## 구현 범위

### Phase A - 빈 공간 터치 제거

- `ResultScene.touchesBegan`의 마지막 fallback StartScene 전환을 삭제한다.
- 빈 공간 터치는 `return` 또는 noop으로 끝낸다.
- share sheet 표시 중에는 기존처럼 다른 전환을 차단한다.
- 졸업장 overlay 표시 중 차단 로직은 유지한다.

### Phase B - 메인 버튼 추가

- `ResultScene`에 `mainButton`을 추가한다.
- 추천 텍스트: `메인으로`.
- 버튼 스타일은 `PrimaryButtonNode` 또는 `GlassPillNode` 중 하나를 선택한다.
  - 권장: `GlassPillNode`, 이유는 `restartButton`이 주 액션이고 메인 복귀는 보조 액션이기 때문이다.
- 기존 하단 3버튼 구조는 4버튼이 되므로 폭 계산을 갱신한다.
- 버튼 우선순위:
  1. `다시 시작`
  2. `기록 보기`
  3. `공유/자랑하기`
  4. `메인으로`

### Phase C - 버튼 레이아웃 재정리

현재 `layoutButtons()`는 3개 버튼의 총 폭을 계산한다. 4개 버튼으로 바뀌면 작은 landscape에서 잘릴 수 있다.

권장 레이아웃:

```text
[기록 보기] [공유/자랑하기] [다시 시작] [메인으로]
```

좁은 화면에서는:

```text
[기록] [공유] [다시] [메인]
```

구현 방법:

- `resultButtonTotalWidth(scale:)`에 `mainButtonWidth`를 포함한다.
- 좁은 화면용 compact text는 우선 보류하고, scale을 낮춰 대응한다.
- 버튼 간 gap은 기존 `resultWideButtonGapV7`를 사용하되 필요하면 `resultMainButtonWidth`와 `resultButtonCompactScale`을 조정한다.

### Phase D - NEW BEST 위치 정리

현재 `newBestLabel`과 `bestPill`이 모두 신기록을 말한다. 한쪽은 보상, 한쪽은 기록 정보로 역할을 나눈다.

권장안:

- `titleLabel`: `NEW BEST!`를 큰 제목으로 유지한다.
- `bestPill`: 점수 오른쪽 또는 아래에 `신기록` 배지로 명확히 둔다.
- `newBestLabel`: 기존 중앙 뜨는 작은 라벨은 제거하거나 점수 위 작은 보상 pulse로 이동한다.

1차 구현 선택:

- `newBestLabel`은 점수 영역 바로 위, `scoreLabel`과 `titleLabel` 사이에 배치한다.
- `newBestLabel`이 `bestPill`과 겹치지 않도록 `layoutPrimaryResultLabels`에서 위치를 하나의 metrics로 통합한다.
- `NEW BEST` 문구 중복이 심하면 `newBestLabel` 텍스트를 `최고 기록 갱신`으로 바꾼다.

## 예상 수정 파일

- `GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift`
- `GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift`

## 보존할 것

- `restartButton`의 같은 캐릭터/난이도 재도전 흐름.
- `scoreboardButton`의 ResultReturnContext 전달.
- `shareButton`의 공유 시트 중복 방지.
- 졸업장 overlay 표시 중 터치 차단.

## 수용 기준

- 결과 화면 빈 공간을 눌러도 메인으로 이동하지 않는다.
- `메인으로` 버튼을 눌렀을 때만 `StartScene`으로 이동한다.
- `다시 시작`, `기록 보기`, `공유/자랑하기`, `메인으로` 버튼이 모두 독립적으로 작동한다.
- 작은 landscape 화면에서 버튼 텍스트가 잘리지 않는다.
- `NEW BEST` 표시가 점수/버튼/Best pill과 겹치지 않는다.

## 리스크와 대응

- 리스크: 4버튼 하단 배치가 좁아질 수 있다.
  - 대응: 보조 버튼은 `GlassPillNode`로 작게 두고, scale 계산을 강화한다.
- 리스크: 기존 사용자에게 빈 공간 탭 복귀가 익숙했을 수 있다.
  - 대응: 명시적 `메인으로` 버튼을 같은 하단 액션 그룹에 둔다.
- 리스크: 신기록 표시를 지우면 보상감이 약해질 수 있다.
  - 대응: 라벨 자체는 유지하되 위치와 중복 문구만 정리한다.

