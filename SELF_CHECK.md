# Sprint 7 Phase E — 자체 점검

전략: **Case A** — Sprint 7 Phase A·B·C·D 합격(QA 9.25+) 흐름 그대로 유지. SPEC 사양 정밀 적용 + 회귀 0 우선.

## 변경 파일 목록

| 파일 | 변경 유형 | 추가 LOC | 제거 LOC | 비고 |
|---|---|---|---|---|
| `GanhoMusic Shared/Nodes/CountdownNode.swift` | 수정 | +18 | -6 | init Jua / step 색 3 / fontSize 2 / GO scale 2 |
| `GanhoMusic Shared/GameScene.swift` | 수정 | +25 | -2 | showCountdown dim 시퀀스 |
| `GanhoMusic Shared/Config/GameConfig.swift` | 수정 | +21 | 0 | V3 상수 9개 + MARK 1 |
| `mockups/countdown-overlay-v1.html` | 신규 | +247 | 0 | 4프레임 시안 |
| **합계** | — | **+311** | **-8** | Swift 변경분 ~52 LOC (사양 ~62 부합) |

`git diff --stat HEAD` 결과 — Swift 3 + mockup 1, 정확.

## SPEC 기능 체크

- [x] **기능 1: CountdownNode 시각 v3 보강** — init SKLabelNode(fontNamed: fontDisplay) / step 색 3개 navyDeep / setup fontSize 2개 (숫자 120 / GO 140) / GO scale 1.2→1.8 / GO 색 coralPrimary
- [x] **기능 2: GameScene.showCountdown dim 오버레이** — cameraNode에 navyDeep dim 부착(z=240) → fadeIn 0.2 → CountdownNode start → onComplete에서 fadeOut 0.2 + removeFromParent + startGameProperly
- [x] **기능 3: GameConfig V3 신규 상수 9개** — countdownNumberFontSizeV3 / countdownGoFontSizeV3 / countdownGoStartScaleV3 / countdownGoEndScaleV3 / countdownDimAlpha / countdownDimFadeInDuration / countdownDimFadeOutDuration / countdownDimZPosition / countdownDimNodeName
- [x] **기능 4: mockups/countdown-overlay-v1.html** — 4프레임 (3·2·1·GO!) 가로 4열 · 각 카드 16:9 미니 게임 화면 + dim 0.32 + 중앙 라벨 · 3·2·1 navy / GO! 코랄 · Jua 폰트 · 캡션 + 상단 타이틀 + 하단 메모 · JS 0줄

## 핵심 byte-identical 검증

- [x] **CountdownNode.start(onTick:onGo:onComplete:) 시그니처 byte-identical** — 인자 3개 이름/타입/순서 모두 동일. `@escaping` 마커 동일.
- [x] **CountdownNode.init() override 시그니처 byte-identical** — `override init()` 그대로. 내부 `SKLabelNode(text: "")` → `SKLabelNode(fontNamed:)` 한 줄 교체만.
- [x] **기존 fadeIn(0.1)/hold(0.7)/fadeOut(0.2) 상수 값 변경 0** — GameConfig 348~365 라인 0줄 수정. 기존 `countdownGoEndScale(1.3)`도 상수 자체 보존 (참조만 V3로 교체).
- [x] **dim zPosition < CountdownNode zPosition** — `countdownDimZPosition(240) < countdownZPosition(250)` ✓
- [x] **SKAction.sequence 안 .run { [weak self] in self?... } 캡처** — onComplete 내부 `dim.run(.sequence([fadeOut, cleanup, startGame]))`의 startGame SKAction.run에 `[weak self]` 캡처 명시.
- [x] **startGameProperly 호출 시점 — dim fadeOut 후로 0.2s 미뤄짐 (총 4.0s 일치)** — 3·2·1(3.0) + GO!(0.8) + dim fadeOut(0.2) = 4.0s.
- [x] **GameState 전이 .countdown → .playing 시점 byte-identical** — startGameProperly 내부 `gameState = .playing` 0줄 변경. 호출 시점만 0.2s 후로 자연 이동.
- [x] **spawnSystem.start 호출 위치 byte-identical** — startGameProperly 함수 0줄 변경.
- [x] **showCountdown 외 GameScene 다른 함수 손대지 않음** — git diff 확인: 264~313 라인 (showCountdown만)

## 보호 영역 0줄 확인

`git diff --stat HEAD --` 다음 경로 — **출력 0줄**:

- DPadNode / SkillButtonNode — 0줄
- Systems/ (SkillSystem / SpawnSystem / ContactRouter / ScoreSystem 포함) — 0줄
- Managers/ (AudioManager 포함) — 0줄
- Repositories/ — 0줄
- GameScene+Setup — 0줄 (변경된 파일에 미포함)
- GameState enum / PhysicsCategory — 0줄 (Models/ 미변경)
- Phase A·B·C·D 결과물 일체:
  - CharacterCardNode / CharacterSelectScene / CharacterID / PlayerSkill — 0줄
  - SkillExplanationScene — 0줄
  - DifficultyCardNode / DifficultySelectScene / Difficulty — 0줄
  - ResultScene / ScoreboardScene — 0줄
  - CharacterFaceNode / GlassPillNode / DarkContextChipNode / PrimaryButtonNode / BackButtonNode / StoryBoxNode — 0줄
  - ColorTokens — 0줄

## Swift 패턴 준수

- **강제 언래핑 0건**: 신규 코드에서 `!` 사용 0. dim 변수 등 모두 `let` 직접 할당.
- **guard let 옵셔널 처리**: onComplete `guard let self = self else { return }`, startGame `[weak self] in self?.startGameProperly()` 패턴 일관.
- **MARK 섹션 구분**: GameConfig `MARK: - Countdown V3 (Sprint 7 Phase E)` 신규 / GameScene MARK 보강 `(Phase 6-13 · Sprint 7 Phase E)`.
- **GameConfig 상수 사용**: 9개 신규 상수 모두 GameConfig.* 참조. 매직 넘버 0건.
- **weak self 캡처**: 클로저 3개 (`onTick`, `onGo`, `onComplete`) 외부 + 내부 SKAction.run의 startGame까지 모두 `[weak self]` 명시.

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 신규 dim은 showCountdown 안에서 생성/추가, didMove에서 이미 showCountdown 호출. 외부 lifecycle 진입점 0변경.
- **dt 기반 이동**: 신규 코드에 update 진입 0. dt 무관.
- **SKAction 스폰 패턴**: dim fadeIn/fadeOut 모두 SKAction. Timer 0건.
- **Timer 0건**: 신규 코드에 Timer/dispatchAfter 사용 0. SKAction.sequence + SKAction.wait/fadeOut만.
- **충돌 후 노드 즉시 삭제 없음**: dim removeFromParent는 fadeOut(0.2) 완료 후 SKAction.sequence로 호출 — 즉시 삭제 아님. CountdownNode 자체는 기존 sequence에서 cleanup 처리(0변경).
- **HUD 노드 분리**: 변경 없음.
- **update()-내-addChild 0건**: dim addChild는 showCountdown 1회 호출 시점, update 진입 아님.

## switch default / Force-unwrap / Timer 누락 확인

- switch default 0건 (switch 사용 자체 0건)
- Force-unwrap (`!`) 0건
- Timer / DispatchQueue.main.asyncAfter 0건

## 빌드 결과

- **상태**: `BUILD SUCCEEDED`
- **컴파일 에러**: 0
- **신규 워닝**: 0 (기존 폰트 중복 build phase 워닝 3개는 사전 존재)

## OPEN_QUESTION 4개 처리 상태

- [x] **OQ-1**: CountdownNode 시그니처 — 기존 `init()` + `start(onTick:onGo:onComplete:)` 그대로 유지 (SPEC 결정 반영). `static func bigCenter` / `func start(completion:)` 신설 0건.
- [x] **OQ-2**: 입력 게이트 — 추가 코드 0줄. 기존 `gameState == .playing` 가드 그대로.
- [x] **OQ-3**: GO! 종료 직후 첫 음표 — 시점 정확. dim fadeOut 0.2s 후 startGameProperly → spawnSystem.start. 첫 spawn은 dim 사라진 직후.
- [x] **OQ-4**: AudioManager 키 — tick/chime 미추가. Phase E 사운드 코드 변경 0.

## 범위 외 미구현 항목

없음 — SPEC 명세 100% 반영. 범위 외 변경 0건.

## 추가 노트

- `countdownGoEndScale(1.3)` 등 V2 상수는 보존(혹시 참조 잔존 가능성 대비). CountdownNode 내부에서 V3 상수로 모두 교체 완료 (`countdownGoEndScale` 참조 0, `countdownGoEndScaleV3` 참조 1).
- dim 자가 소멸과 CountdownNode 자가 소멸이 *서로 독립*된 SKAction.sequence로 보장 — 한쪽 실패 시 다른 쪽 잔류 위험 0 (dim은 본인 sequence로, CountdownNode는 기존 cleanup으로).
- Jua-Regular ttf 누락 시 SKLabelNode는 시스템 폰트로 fallback — 빌드 워닝 0건 확인됨 (폰트 번들 기존 보장).
