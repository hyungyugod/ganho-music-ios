# 자체 점검

Phase 6-13 — 게임 시작 카운트다운 3 → 2 → 1 → GO! (자가 소멸 노드 8호 CountdownNode)

## 변경 파일 및 라인 수

| 파일 | 신규/수정 | 변경 라인 수 |
|---|---|---|
| `Nodes/CountdownNode.swift` | 신규 | +112줄 (헤더/주석 포함 — 본문 ~75줄 + 주석) |
| `Config/GameState.swift` | 수정 | +2줄 (`.countdown` case + 헤더 한 줄) |
| `Config/GameConfig.swift` | 수정 | +19줄 (MARK 섹션 + 상수 8개 + doc comment) |
| `GameScene.swift` | 수정 | +43줄 / -14줄 (헤더 1줄 + showCountdown 19줄 + startGameProperly 17줄 + didMove 끝 재구성. 기존 spawnSystem.start/gameState=playing/bgm.play 14줄을 startGameProperly로 이동) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +4줄 (UUID 0033 4지점: PBXBuildFile / PBXFileReference / PBXGroup / PBXSourcesBuildPhase) |

## SPEC 기능 체크

- [x] **기능 1 — GameState.countdown case 추가**: `Config/GameState.swift` 11~17줄. `case waiting` 직후, `case playing` 직전 위치. 주석으로 *update의 모든 시스템 정지* 의도 명시.
- [x] **기능 2 — GameConfig 카운트다운 상수 8개**: `Config/GameConfig.swift` 끝부분 `// MARK: - Countdown (Phase 6-13)` 섹션. countdownFontSize(96) / countdownFadeInDuration(0.1) / countdownHoldDuration(0.7) / countdownFadeOutDuration(0.2) / countdownGoEndScale(1.3) / countdownGoFadeOutDuration(0.4) / countdownGoHoldDuration(0.5) / countdownZPosition(250).
- [x] **기능 3 — CountdownNode 신규 (자가 소멸 노드 8호)**: `Nodes/CountdownNode.swift`. `SelfDismissingNode` 채택. `start(onTick:onGo:onComplete:)` 진입점 1개. `SKAction.sequence([step3, step2, step1, stepGo, cleanup, notify])` 자가 실행. stepAction (일반 3/2/1) + goAction (GO! scale 펄스) 두 헬퍼로 분리. `removeFromParent` *다음* notify 위치라 onComplete 호출 시점에 노드가 이미 트리에서 빠진 상태.
- [x] **기능 4 — GameScene 흐름 재구성**: `didMove(to:)` 끝부분에서 spawnSystem.start / gameState = .playing / bgm.play 3블록을 제거하고 `gameState = .countdown` + `showCountdown()` 2줄로 교체. `// MARK: - Countdown (Phase 6-13)` 신규 섹션에 `showCountdown()` + `startGameProperly()` 헬퍼 추가. spawnSystem.start 인자(scene/world/player/enemy/progressProvider) 시그니처 *그대로* 유지.

## GameState exhaustive switch 검증

```
grep -rn "switch.*gameState" GanhoMusic --include="*.swift" → 0 hits
grep -rn "case .playing" GanhoMusic --include="*.swift" →
  GameScene.swift: gameState 동등성 비교 5곳(`==`/`!=` 형식, switch 아님)
  AudioManager.swift: case .gameOver — AudioManager.SFX enum (다른 enum, 무관)
```

**결론**: GameState를 exhaustive하게 다루는 switch 0건. `.countdown` 추가로 break되는 컴파일 지점 0건. `gameState == .playing` / `gameState == .gameOver` 동등성 비교만 사용 — `.countdown` 추가는 *모든 동등성 비교가 false를 반환*하는 안전한 확장.

## ColorTokens 4색 존재 확인

`Config/ColorTokens.swift` 12~47줄 전수 검사:
- `.ganhoBloodAccent` — 40줄 (#D8315B 빨강) → 사용: 단계 "3"
- `.ganhoYellowF` — 45줄 (#FFD23F 노랑) → 사용: 단계 "2"
- `.ganhoPinkNote` — 30줄 (#F6A6B2 분홍) → 사용: 단계 "1"
- `.ganhoMint` — 26줄 (#7DCFB6 민트) → 사용: "GO!"

**결론**: 4색 모두 정의됨. 대체 발생 0건.

## 빌드 명령 결과

```
xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -configuration Debug build
```

- **결과**: `** BUILD SUCCEEDED **`
- **에러**: 0건
- **경고**: 0건 (`grep -iE "warning:|error:"` 출력 없음)

## pbxproj 4지점 UUID 0033 등록 확인

`grep -n "CountdownNode\|0033"` 결과:
```
 44 (PBXBuildFile):              A1C0F1B00000000000000033 /* CountdownNode.swift in Sources */ = {...}
 82 (PBXFileReference):          A1C0F1A00000000000000033 /* CountdownNode.swift */ = {...}
226 (PBXGroup `Nodes`):          A1C0F1A00000000000000033 /* CountdownNode.swift */,
498 (PBXSourcesBuildPhase):      A1C0F1B00000000000000033 /* CountdownNode.swift in Sources */,
```

**4지점 모두 등록 완료**. UUID 0032 ComboBreakNode 패턴 답습.

## SPEC §"6-12까지의 회귀 0 영역" 미접촉 검증

- **ComboBreakNode**: 미접촉. 자가 소멸 노드 7호 그대로 유지. (확인: 변경 파일 5개에 ComboBreakNode.swift 없음.)
- **ComboPopupNode**: 미접촉. 6-10 색 매핑 / animate 그대로.
- **BGMPlayer**: 미접촉. `bgm.play()` 호출 시점만 `didMove` → `startGameProperly`로 이동 — 호출 자체는 동일.
- **SpawnSystem**: 미접촉. `spawnSystem.start(scene:world:player:enemy:progressProvider:)` 인자 시그니처 그대로 이동 (이름·순서·내용 변경 0). `progressProvider` 클로저의 `[weak self]` 캡처도 그대로.
- **HapticsManager / AudioManager**: 미접촉. `haptics.light()` / `haptics.heavy()` / `audio.play(.comboMilestoneStrong)` 재사용. SFX 케이스 추가 0건.
- **ContactRouter / ScoreSystem / HUDNode / DPadNode / EnemyNode / PlayerNode / StoneGuardNode / NoteNode / ProjectileNode / 나머지 자가 소멸 노드 6개**: 미접촉.
- **TitleScene / ResultScene / Repositories / Models / Protocols**: 미접촉.

## update()의 `guard gameState == .playing` 본문 미수정 확인

`GameScene.swift` 179줄: `guard gameState == .playing else { return }` — **변경 0줄**. update 본문 코드 *어디도* 수정 안 함. `.countdown` 상태 진입 시 이 가드가 *자동으로* 7개 시스템(타이머 감소·콤보 만료·플레이어 이동·player.update·카메라 follow·enemy.update·HUD 갱신·콤보 끊김 폴링) 모두 차단.

**의도 검증**: `gameState == .countdown` 상태에서 `.playing`과 비교 → false → 가드 통과 못 함 → return. 추가 가드 코드 0줄. SPEC 핵심 통찰 그대로 구현.

## spawnSystem.start 인자 그대로 이동 확인

**Before (didMove 끝, 삭제됨)**:
```swift
spawnSystem.start(
    scene: self,
    world: worldNode,
    player: player,
    enemy: enemy,
    progressProvider: { [weak self] in
        guard let self = self else { return 0 }
        return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
    }
)
gameState = .playing
bgm.play()
```

**After (startGameProperly 본문, 추가됨)**:
```swift
spawnSystem.start(
    scene: self,
    world: worldNode,
    player: player,
    enemy: enemy,
    progressProvider: { [weak self] in
        guard let self = self else { return 0 }
        return Double(1.0 - self.remainingTime / GameConfig.gameDuration)
    }
)
gameState = .playing
bgm.play()
```

**diff 0** — 인자 5개 모두 이름·순서·내용 동일. `[weak self]` 캡처 그대로. 본문 14줄 통째 이동 + 호출 시점만 GO! 콜백으로 늦춤.

## Swift 패턴 준수

- **강제 언래핑 미사용**: 준수 — CountdownNode / GameScene 신규 코드에 `!` 0건. `guard let self = self else { return }` 패턴 사용.
- **guard let 옵셔널 처리**: 준수 — 모든 클로저 내 `[weak self]` 캡처 후 `guard let self = self else { return }` 명시. (단순 `self?.method()` 호출은 옵셔널 체이닝으로 처리.)
- **MARK 섹션 구분**: 준수 — CountdownNode에 `// MARK: - Properties / Init / Start / Step Actions / Configure` 5개 섹션. GameScene에 `// MARK: - Countdown (Phase 6-13)` 신규. GameConfig에 `// MARK: - Countdown (Phase 6-13)` 신규.
- **GameConfig 상수 사용**: 준수 — CountdownNode 본문에 매직 넘버 0건. 모든 폰트 크기·duration·scale·zPosition을 `GameConfig.countdown*` 상수 참조.
- **weak self 캡처**: 준수 — CountdownNode의 `SKAction.run` 안에서 `self.label.text = ...` 사용 시 `[weak self]` + `guard let self`. GameScene의 `showCountdown` 클로저 3개 모두 `[weak self]`. `startGameProperly`의 `progressProvider` 클로저도 `[weak self]` (기존 패턴 그대로 이동).

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 준수 — gameState 전환(.waiting → .countdown)과 카운트다운 노드 부착이 didMove 안에서. 다른 setup* 호출들 위치 미변경.
- **dt 기반 이동**: 해당 없음 (CountdownNode는 SKAction 타임라인 기반 — dt 비의존).
- **SKAction 스폰 패턴**: 준수 — Timer 사용 0건. 4단계 시퀀스 모두 `SKAction.sequence` + `SKAction.run` + `SKAction.fadeIn` / `SKAction.fadeOut` / `SKAction.scale` / `SKAction.wait` 표준 액션 조합.
- **충돌 후 노드 즉시 삭제 없음**: 해당 없음 (CountdownNode는 PhysicsBody 없음 — 충돌 경로 무관). 자가 소멸은 `SKAction.removeFromParent()`로 액션 시퀀스 마지막에 안전하게 처리.
- **HUD 노드 분리**: 준수 — CountdownNode는 cameraNode 자식으로 부착 (HUDNode와 같은 부착 정책). worldNode와 분리됨.

## 범위 외 미구현 항목

- **카운트다운 스킵 기능 (탭 건너뛰기)**: SPEC §"Sprint 범위 계약"에서 *금지* — 사용자 요청에 따라 강제 시청. 미구현.
- **카운트다운 숫자 다국어 / 난이도별 차등**: 금지 — 미구현.
- **ColorTokens 신규 색**: 금지 — 기존 4색 재사용. 미구현.
- **AudioManager.SFX 신규 케이스**: 금지 — `comboMilestoneStrong` 재사용. 미구현.

모든 미구현 항목은 SPEC의 "금지" 목록에 명시된 의도적 미포함.

## 추가 안전성 검증

- **SelfDismissingNode marker protocol 채택**: CountdownNode가 `SKNode, SelfDismissingNode` 채택 — 자가 소멸 노드 8호임을 문서화. marker라 컴파일러 강제 없음, 의도 표현용.
- **첫 setup 액션의 alpha = 0 리셋**: 매 단계 시작 시 `self.label.alpha = 0` — 직전 단계의 fadeOut이 alpha를 0으로 떨어뜨리지만 방어 코딩으로 명시.
- **첫 setup 액션의 setScale(1.0) 리셋**: 매 일반 단계 시작 시 scale 리셋 — GO! 단계에서 1.3으로 커진 값의 잔류 방지(현재는 자가 소멸이라 영향 없지만 방어 코딩).
- **goAction의 hold/scaleUp group 동기 종료**: 둘 다 duration = `countdownGoHoldDuration(0.5)` → 정확히 동시 종료 후 fadeOut 시작.
- **GameScene `showCountdown`의 onGo 클로저**: `guard let self = self else { return }` 후 self.haptics + self.audio 2회 호출 — 동일 self 참조 일관성. (onTick은 단발 호출이라 옵셔널 체이닝, onComplete는 단발이라 옵셔널 체이닝.)
