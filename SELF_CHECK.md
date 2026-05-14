# 자체 점검 — Phase 6-14 타이머 긴박감

전략: 1회차 — 신규 구현. 이전 sprint 6-13(CountdownNode)의 시간 대칭점.

## SPEC 기능 체크

- [x] **기능 1 — BGMPlayer rate API**: `enableRate = true` 1줄(init), `rate = 1.0` 1줄(stop DispatchWorkItem 안), `setRate(_:)` + `resetRate()` 2개 메서드 (MARK Tension)
- [x] **기능 2 — HUDNode 깜빡임 API**: `startTensionBlink()` + `stopTensionBlink()` 2개 메서드 (MARK Tension). fontColor 직접 교체 패턴 (SKAction.run + wait 4단 sequence + repeatForever + withKey). `timeLabel`만 접근 — scoreLabel/comboLabel/nameLabel 미접촉
- [x] **기능 3 — GameScene 5초 긴박감 폴링**: `update(_:)`의 `remainingTime -= dt` 직후 + 0초 early return 직후에 폴링 블록 28줄. 첫 진입 1회 가드(`!tensionStarted` → `hud.startTensionBlink()`), 매 프레임 rate 보간(`bgm.setRate(...)`), 매초 정수 변화 시 `haptics.light()` (4회)
- [x] **기능 4 — endGame 정리**: `bgm.stop()` 다음 줄에 `hud.stopTensionBlink()` 1줄 (멱등 가드 안쪽)
- [x] **기능 5 — GameConfig 상수 5개**: `tensionWindow`(5.0 TimeInterval) / `tensionRateBase`(1.0 Float) / `tensionRateMax`(1.15 Float) / `tensionBlinkHalfPeriod`(0.5 TimeInterval) / `tensionBlinkActionKey`("tensionBlink" String). MARK: - Tension (Phase 6-14) 섹션 신설

## 변경 라인 수 (git diff --stat)

| 파일 | +라인 |
|---|---|
| `Config/GameConfig.swift` | +16 |
| `Managers/BGMPlayer.swift` | +22 |
| `Nodes/HUDNode.swift` | +26 |
| `GameScene.swift` | +40 |

총 4 파일, +104줄 / -0줄 (Swift 코드만, MD 산출물 제외).

## Swift 패턴 준수

- 강제 언래핑(`!`) 미사용: 준수 — `guard let player = player else { return }` (BGMPlayer.setRate) / `Int(ceil(...))` 캐스팅만
- guard let 옵셔널 처리: 준수 — `setRate`에서 player 옵셔널 가드
- MARK 섹션 구분: 준수 — 4 파일 모두 `MARK: - Tension (Phase 6-14)` 신설
- GameConfig 상수 사용: 준수 — 매직 넘버 0건. 5.0/1.0/1.15/0.5/"tensionBlink" 모두 GameConfig 상수
- weak self 캡처: 준수 — HUDNode.startTensionBlink의 SKAction.run 2개 모두 `[weak self]` 캡처

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 해당 없음(추가 setup 없음) — 폴링 블록은 update 내부, 초기화는 신규 프로퍼티 기본값(false/-1)으로 자동
- dt 기반 이동: 해당 없음(이번 sprint는 시간 비교/햅틱/rate). 단, rate 보간식은 `remainingTime`(dt 누적) 기반 → 프레임레이트 독립
- SKAction 스폰 패턴: 준수 — `SKAction.run` + `SKAction.wait(forDuration:)` + `SKAction.sequence` + `SKAction.repeatForever` + `withKey` 멱등 (Timer 0건, DispatchQueue.asyncAfter 0건)
- 충돌 후 노드 즉시 삭제 없음: 준수 — 본 sprint는 충돌 분기 미접촉, ContactRouter 변경 0
- HUD 노드 분리: 준수 — `timeLabel`은 HUDNode private. 외부 GameScene은 신규 메서드 `startTensionBlink()`/`stopTensionBlink()`로만 호출(캡슐화 보존)

## 빌드 상태

- xcodebuild 빌드 결과: **`** BUILD SUCCEEDED **`**
- 명령: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO`
- 예상 빌드 에러: 없음 (실제 빌드 성공으로 검증)
- 주의 필요 경고: 없음 (Swift 컴파일 단계 경고 0건). AppIntents.framework 관련 메시지는 본 sprint 외 시스템 노트.

## pbxproj / 신규 파일 검증

- pbxproj 변경 0건: 준수 — `git status`에 `*.pbxproj` 변경 0건
- 신규 파일 0건: 준수 — `git status`에 Untracked file 0건 (산출물 SELF_CHECK.md / SPEC.md 외)
- 4 파일 모두 *modified* 상태로만 변경

## 핵심 결정 검증

- `enableRate = true` 위치: BGMPlayer.swift init() 안 — `p.numberOfLoops = -1` *직전* + `p.prepareToPlay()` *직전* (Apple 권장 순서)
- `Float` 타입 일관성: GameConfig.tensionRateBase / tensionRateMax 모두 `Float` 선언. update 안 `let progress = Float((...))`, `let clamped = max(Float(0), min(Float(1), progress))`, `let rate = ... * clamped` 전부 Float 연산. AVAudioPlayer.rate(Float) 시그니처와 정확 일치 — 캐스팅 오류 0
- 카운트다운(.countdown) 상태에서 폴링 미발화: 준수 — 폴링 블록이 `guard gameState == .playing else { return }` 가드 *안쪽*에 위치 → .countdown 상태에선 자동 차단. BGM은 startGameProperly() 호출 전까지 play() 미진입 → 비교차 0
- ColorTokens 변경 0건: 준수 — 신규 색 추가 0. `.ganhoBloodAccent` / `.ganhoPaper` 재사용만

## "6-13까지의 회귀 0 영역" 미접촉 검증

`git diff --stat` 기준, 본 sprint가 수정한 파일은 정확히 4개:
- `Config/GameConfig.swift` — *추가 only* (MARK Tension 신설), 기존 상수 0건 수정
- `Managers/BGMPlayer.swift` — *추가 only* (init 1줄, stop DispatchWorkItem 안 1줄, MARK Tension 신설 2 메서드). 6-5/6-6/6-7 페이드/Interruption/라이프사이클 로직 미접촉
- `Nodes/HUDNode.swift` — *추가 only* (MARK Tension 신설 2 메서드). init/configure/update/setCharacterName 미접촉. scoreLabel/comboLabel/nameLabel 0건 접근
- `Scenes/GameScene.swift` — 헤더 주석 1줄, 프로퍼티 2개, update 폴링 블록 1개, endGame stopTensionBlink 1줄. **자가 소멸 노드 8개, ContactRouter, ScoreSystem, SpawnSystem, configureContactRouter 본문, triggerAirforceEasterEgg, showCountdown, startGameProperly, didMove, factory 미접촉**

미수정 파일 (회귀 0 검증):
- AirplaneNode / AirforceOverlayNode / BombFlashNode / SparkleEffectNode / HitFlashNode / ComboPopupNode / ComboBreakNode / CountdownNode — 0건
- ContactRouter / ScoreSystem / SpawnSystem / CameraShakeAction — 0건
- PlayerNode / EnemyNode / DPadNode / NoteNode / ProjectileNode / StoneGuardNode / CharacterCardNode — 0건
- TitleScene / ResultScene / GameScene+Setup — 0건
- AudioManager / HapticsManager — 0건
- Repositories(HighScore / Statistics / CharacterPreference) — 0건
- Models(GameStats / CharacterID) — 0건
- Protocols(SelfDismissingNode) — 0건
- Config(PhysicsCategory / GameState / **ColorTokens**) — 0건
- pbxproj — 0건

## 의사 결정 트레이스

- **0초 도달 시 폴링 차단**: `remainingTime <= 0` 시 early return이 위에 있으므로 폴링 블록 진입 전 `endGame()` 호출 → 햅틱 정확 4회(5→4, 4→3, 3→2, 2→1) 발화 후 정지. SPEC §주의사항 1 일치
- **rate 보간 분모**: SPEC §"BGM rate 변경 메커니즘 결정"은 "(5 - remainingTime) / 4"라고 적었으나 본문 핵심 코드 구조와 "기능 3: 핵심 코드 구조"에서는 "/ 5" (= tensionWindow). 후자가 실제 코드, 더 명확(5초→1.0, 0초→1.15 정확 매핑). `progress = (tensionWindow - remainingTime) / tensionWindow` 채택
- **rate 보간 안전망**: `max(Float(0), min(Float(1), progress))` 클램프 추가 — remainingTime이 tensionWindow를 살짝 초과/미만 시 rate 범위 보호. Apple 0.5~2.0 권장 범위 안전 유지
- **early return 직후 vs early return 직전**: SPEC 핵심 코드 구조는 early return 후에 폴링이 옴 (`if remainingTime <= 0 { endGame(); return }` *다음 줄*에 `if remainingTime <= GameConfig.tensionWindow { ... }`). 이게 0초 햅틱 차단 보장. 채택

## 범위 외 미구현 항목

- 없음. SPEC 5개 기능 모두 구현. ColorTokens / pbxproj / 6-13 이전 sprint 산출물 일체 미접촉.
