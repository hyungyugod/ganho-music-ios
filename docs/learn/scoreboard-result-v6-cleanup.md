# 기록보기 화면 호흡 + 실습 종료 화면 군더더기 정리 (V6)

## 한 줄 요약
**기록 보기** 화면에서 "캐릭터·난이도별 최고점수" 부제 글자와 표 첫 줄이 거의 같은 줄에 있어 답답했던 걸 풀었고, **실습 종료** 화면에서 큰 점수 아래에 또 작게 떠 있던 "SCORE" 캡션을 지워서 깔끔하게 정리했어요.

## 무엇이 바뀌었나

### 기록 보기 (ScoreboardScene)
1. **표 전체를 30pt 아래로** 내렸어요. 부제 글자(y=midY+112)와 표의 "하·중·상" 열 헤더(y=midY+110)가 거의 같은 위치라 시각적으로 겹쳐 보였거든요. 표를 내리니 32pt 호흡이 생겼어요.
2. **행 헤더 안의 작은 얼굴 그림과 한 글자(김/정/건/임/이) 사이 간격을 22pt → 32pt**로 넓혔어요. 더 이상 빽빽해 보이지 않아요.
3. **표의 마지막 행 ↔ 하단 "총 플레이 N회" 글자 사이 호흡을 24pt → 40pt**로 늘렸어요.

### 실습 종료 (ResultScene)
1. **"SCORE" 캡션 시각 제거**. 큰 0 옆에 ♪ 아이콘과 우측 "🏆 BEST 11" pill이 이미 있어서 SCORE라는 글자가 굳이 필요 없었어요. alpha=0으로 시각만 끄고 노드 트리(코드 구조)는 보존했어요.
2. **PLAYS / TOTAL 숫자의 투명도 회복**: 0.45 → 0.75. 옅으면 차분해 보일 줄 알았는데 오히려 어수선해서 또렷하게 다시 보이게.
3. **divider 선을 12pt 더 아래로** 내리고, **하단 3버튼(기록 보기 / 공유 / 다시 시작) 간격을 넓혀** 답답함 해소.

## 왜 이런 방식으로 했나

### "SCORE" 글자를 *없애지* 않고 *안 보이게* 한 이유
Swift에는 `alpha = 0` 이라는 마법이 있어요. 이 한 줄이면 화면에서 안 보이게 되지만, **노드는 살아있어요**. 왜 그렇게 했을까?

**Spring Boot 비유**: API에서 deprecated 필드를 제거하지 않고 응답에서만 제외하는 거랑 비슷해요. 다른 화면이나 액션(예: 신기록 시 깜빡임)이 이 라벨에 의존할 수 있어서, *코드 구조는 살려두고 화면 표시만 꺼두는* 게 안전합니다.

### V숫자 토큰 패턴
이번 작업에서 GameConfig에 **V6 토큰 8개**를 새로 만들었어요. 옛 토큰(V2/V3/V4/V10/V11)은 *값 그대로 두고*, 사용처(layoutXxx 함수)만 V6를 참조하도록 바꿨습니다.

- **이유**: 이 값(예: -68)을 다른 코드 어디서 또 쓸지 모르거든요. 직접 바꾸면 그 다른 곳이 망가질 위험이 있어요.
- **Spring Boot 비유**: `application-v1.yml` 그대로 두고 `application-v6.yml`을 새로 만들어서 일부 컴포넌트만 v6 프로필로 전환하는 느낌.

### "단일 진실 원천(Single Source of Truth)"
divider(가로선)의 위치가 바뀌면, 그 아래 stat 영역도 자동으로 같이 움직여요. 왜? 코드에서 stat의 y좌표를 **divider 좌표 기준 상대값**으로 계산하기 때문이에요:

```swift
let statValueY = GameConfig.resultDividerOffsetYV6 - GameConfig.resultStatGapFromDividerV11
```

이렇게 하면 "divider 한 곳만 옮기면 stat도 따라간다" → 두 곳을 따로 관리할 일이 없어 실수 0.

### Layout 함수가 두 번 호출되는 이유
SpriteKit에서 `layoutLabels()` 같은 함수는 두 군데서 불려요:
1. `didMove(to:)` — 씬이 처음 화면에 올라올 때
2. `didChangeSize(_:)` — 화면 크기가 바뀔 때 (회전이나 멀티태스킹)

그래서 layout 함수 안에서 좌표 계산을 *frame 기준*으로 해야 화면 크기 변화에도 안전해요. 우리 V6 변경도 모두 `frame.midX`, `frame.midY` 기준이라 안전합니다.

## 핵심 파일 수정 내용
- [GameConfig.swift](GanhoMusic/GanhoMusic Shared/Config/GameConfig.swift) — `// MARK: - Sprint V6` 섹션 신설 + V6 토큰 8개 (+42 LOC)
- [ScoreboardScene.swift](GanhoMusic/GanhoMusic Shared/Scenes/ScoreboardScene.swift) — `matrixOriginTopY`, `rowHeaderFace/NamePosition`, `layoutAll()`의 stat 산식 4곳 V6 참조 (4줄)
- [ResultScene.swift](GanhoMusic/GanhoMusic Shared/Scenes/ResultScene.swift) — `setupLabels()`에 `scoreSubLabel.alpha = 0` 추가, `setupStats()` stat 4라벨 alpha V6, `layoutLabels()`의 divider/statValueY/버튼 3개 X V6 참조 (~9줄)

## 핵심 수치
- ScoreboardScene: 부제 ↔ 열 헤더 **2pt → 32pt** 호흡
- ResultScene: score row ↔ stat 영역 **74pt → 86pt** 호흡
- 버튼 사이 간격: scoreboard↔share **110pt → 130pt** / share↔restart **150pt → 155pt**

## 다음에 응용할 수 있는 점
- 화면에 글자가 답답해 보일 때 → **부모 컨테이너의 y offset 한 곳만** 바꿔보세요. 자식들은 상대 위치라 같이 움직임.
- 어떤 요소를 *없애야 할지* 망설여질 때 → 일단 **alpha=0**으로 시각만 꺼보고, 그래도 화면이 멀쩡하면 진짜 제거 결정. 안전한 단계적 삭제.
- 옛 코드의 상수 값을 그대로 두고 새 값을 추가하고 싶을 때 → **V숫자 접미사** 토큰 패턴.

## QA 결과
- 가중 점수: 9.35 / 10
- 빌드: BUILD SUCCEEDED
- 비전제(GameScene/Systems/다른 Scenes/저장소) 변경: 0줄 ✅
- V3/V4/V10/V11 토큰 11종 값 byte-identical 보존 ✅
