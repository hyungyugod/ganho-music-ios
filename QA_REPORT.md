# QA 검수 보고서 — Phase 6-14 타이머 긴박감

## SPEC 기능 검증

- **[PASS] 기능 1 — BGMPlayer rate API**: `enableRate = true`가 `init()` 안 `numberOfLoops = -1` 직전(BGMPlayer.swift:56), 즉 `prepareToPlay()` 전에 정확히 설정됨 (Apple 권장 순서). `setRate(_:)`/`resetRate()` 2개 메서드 신설(232–241), `guard let player = player else { return }` 옵셔널 가드. `stop()` 내부 DispatchWorkItem 안에 `self.player?.rate = 1.0` 1줄 추가(138), 옵셔널 체이닝으로 강제 언래핑 0건. 6-4~6-7 본문(페이드 인/아웃, Interruption, 라이프사이클) 변경 0.

- **[PASS] 기능 2 — HUDNode 깜빡임 API**: `startTensionBlink()`/`stopTensionBlink()` 2개 메서드 신설(HUDNode.swift:94–112). `timeLabel`만 접근 — `scoreLabel`/`comboLabel`/`nameLabel`/`update`/`setCharacterName`/`configure`/`init` 본문 0건 접촉. `SKAction.run + wait` 4단 sequence + `repeatForever` + `withKey: GameConfig.tensionBlinkActionKey` 패턴(SKLabelNode colorize 회피). `[weak self]` 캡처가 toRed/toBase 두 클로저 모두에 적용. stop 시 `fontColor = .ganhoPaper`로 즉시 잔상 0 복원.

- **[PASS] 기능 3 — GameScene 5초 폴링**: 신규 프로퍼티 2개(GameScene.swift:94 `tensionStarted: Bool = false`, 98 `lastRemainingTimeSecond: Int = -1`). 폴링 위치가 `remainingTime -= dt` 직후(235) + `endGame()` early return 후(236–239), `guard gameState == .playing else { return }`(231) 안쪽. 5초 윈도우 진입 가드(245), 1회 setup 가드(247–250), 매 프레임 rate 보간(254–257, Float 캐스팅 일관), 매초 정수 변화 시 `haptics.light()` (261–267, 5→4→3→2→1 정확 4회).

- **[PASS] 기능 4 — endGame 정리**: `hud.stopTensionBlink()` 1줄 추가(GameScene.swift:460), `bgm.stop()` 다음 + `spawnSystem.stop()` 전, 멱등 가드(`if gameState == .gameOver { return }`) 안쪽. 0초 만료/F 피격/enemy 접촉 모든 경로가 endGame()으로 수렴 → 자동 정리.

- **[PASS] 기능 5 — GameConfig 상수 5개**: `MARK: - Tension (Phase 6-14)` 신설(GameConfig.swift:358–372). `tensionWindow: TimeInterval = 5.0`, `tensionRateBase: Float = 1.0`, `tensionRateMax: Float = 1.15`, `tensionBlinkHalfPeriod: TimeInterval = 0.5`, `tensionBlinkActionKey: String = "tensionBlink"`. AVAudioPlayer.rate(Float) 시그니처와 정확 일치. 매직 넘버 0건.

## 빌드 검증
- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO`
- Swift 컴파일 에러: 0건
- Swift 컴파일 경고: 0건

## Sprint 범위 검증
- 신규 파일: 0건 (git status untracked Swift 0건)
- pbxproj 변경: 0건
- 수정 Swift 파일: 정확히 4개 (Config/GameConfig.swift, Managers/BGMPlayer.swift, Nodes/HUDNode.swift, GameScene.swift)
- 추가 라인: GameConfig +16, BGMPlayer +22, HUDNode +26, GameScene +40 = +104줄 / -0줄

## 회귀 0 영역 미접촉 검증
미수정 확인: 자가 소멸 노드 8개 전체(AirplaneNode/AirforceOverlayNode/BombFlashNode/SparkleEffectNode/HitFlashNode/ComboPopupNode/ComboBreakNode/CountdownNode), ContactRouter, ScoreSystem, SpawnSystem, CameraShakeAction, PlayerNode/EnemyNode/DPadNode/NoteNode/ProjectileNode/StoneGuardNode/CharacterCardNode, TitleScene/ResultScene/GameScene+Setup, AudioManager/HapticsManager, Repositories 3종, Models 2종, Protocols, ColorTokens/PhysicsCategory/GameState. 모두 0건 변경.

## 카운트다운 시간 비교차 검증
폴링 블록(245–268)이 `guard gameState == .playing else { return }`(231) 안쪽에 위치 → `.countdown` 상태에서 자동 차단. `startGameProperly()`(176–190)가 `bgm.play()` 직후 `.playing` 전환을 동시 수행하므로 카운트다운 중 BGM 미재생 + rate 변경 호출 자체가 발생 불가. 시간상 비교차 0.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목
- 강제 언래핑(`!`) 0건 — `grep` 결과의 `!`는 모두 논리 부정(`!tensionStarted`, `!self.triggeredComboMilestones.contains(...)`)
- Timer / DispatchQueue.asyncAfter 신규 호출 0건
- guard let / [weak self] 옵셔널 처리 일관
- MARK 섹션 4 파일 모두 `MARK: - Tension (Phase 6-14)`로 통일
- AVAudioPlayer.rate(Float) ↔ GameConfig.tensionRate*(Float) 타입 일관
- SKAction `withKey` 멱등 + `tensionStarted` Bool 이중 멱등
- HUDNode 캡슐화 보존 (timeLabel은 private 유지)
- BGMPlayer 6-5/6-6/6-7 페이드/Interruption/라이프사이클 로직 본문 변경 0

## 채점

**항목별 점수**:
- Swift 패턴 일관성: 10/10
- 게임 로직 완성도: 10/10
- 성능 & 안정성: 10/10
- 기능 완성도: 10/10

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

**구체적 개선 지시**: 없음. 본 sprint는 SPEC를 정확히 그대로 옮긴 1회차 구현으로, 5개 기능 모두 만점이며 빌드 클린·회귀 0·범위 0. 다음 sprint로 진행 가능.
