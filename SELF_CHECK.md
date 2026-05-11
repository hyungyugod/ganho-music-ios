# 자체 점검 — Phase 4-5 AIRFORCE 폭탄 화면 플래시

## 파일별 변경 줄 수

| 파일 | 변경 형태 | 줄 수 |
|---|---|---|
| `GanhoMusic Shared/Nodes/BombFlashNode.swift` | 신규 | 44줄 (헤더+클래스 본문) |
| `GanhoMusic Shared/Config/GameConfig.swift` | 수정 (Airforce 섹션 끝 +6줄: doc 3 + 상수 3) | +6 |
| `GanhoMusic Shared/GameScene.swift` | 수정 (헤더 MARK 1줄 + doc 1줄 + 본문 3줄) | +5 |
| `GanhoMusic.xcodeproj/project.pbxproj` | 수정 (식별자 0020 4곳) | +4 |

**합계**: 신규 1 파일(44줄) + 기존 3 파일(+15줄). 모든 변경 *추가만*, 기존 줄 변경 0.

---

## SPEC 기능 체크

- [x] **기능 1 — `BombFlashNode` 클래스**: `final class : SKSpriteNode`, `init`에서 `color: .ganhoPaper`, `size: .zero`, `name = "bombFlash"`, `zPosition = 250`, `alpha = 0`. `flash(sceneSize:)`에서 size·position 갱신 후 `SKAction.sequence([wait(2.1), fadeIn(0.07), fadeOut(0.35), removeFromParent()])`.
- [x] **기능 2 — `GameConfig.swift` 3 상수 추가**: `bombFlashDelay = 2.1`, `bombFlashFadeInDuration = 0.07`, `bombFlashFadeOutDuration = 0.35`. 위치: `airforceOverlayFadeOutDuration` *다음 줄* (Airforce 섹션 내부 끝).
- [x] **기능 3 — `GameScene.swift` 헤더 MARK + doc + 본문 3줄**: 헤더 26행 (Phase 4-4 다음에 Phase 4-5), doc 198행 (Phase 4-4 doc 다음 줄), `triggerAirforceEasterEgg()` 본문 끝 209-211행 3줄.
- [x] **기능 4 — `project.pbxproj` 4곳 0020 등록**: PBXBuildFile(31행) / PBXFileReference(56행) / Nodes 그룹 children(194행) / iOS Sources phase(428행). macOS/tvOS Sources는 빈 채로 유지.

---

## OoS 미위반 체크리스트

| OoS 항목 | 검증 결과 |
|---|---|
| `AirplaneNode.swift` 미변경 | 변경 없음 (Read만) |
| `AirforceOverlayNode.swift` 미변경 | 변경 없음 (Read만) |
| `ContactRouter` 미변경 | 변경 없음 |
| `PhysicsCategory` 미변경 | 변경 없음 |
| `StoneGuardNode` 미변경 | 변경 없음 |
| `GameScene+Setup` 미변경 | 변경 없음 |
| 기존 GameConfig 상수(airplane 4 + airforceOverlay 3 + 그 외) 미변경 | 추가만 — 기존 줄 0건 수정 |
| 다른 노드/시스템/씬 미변경 | 변경 없음 |
| `ColorTokens` 새 토큰 신설 0 | `.ganhoPaper` 재사용 |
| `update()` 미변경 | 변경 없음 |
| `endGame()` 미변경 | 변경 없음 |
| `airforceTriggered` 가드 위치 미변경 | trigger 함수 최상단 그대로 |
| 기존 trigger 본문 7줄(가드 2 + 비행기 4 + 오버레이 3) 미변경 | 한 줄도 안 건드림 — 3줄 *추가만* |
| macOS/tvOS Sources phase 미수정 | 두 phase 모두 `files = ();` 빈 채로 유지 |
| `BombFlashNode`에 PhysicsBody 부착 0 | `physicsBody` 키워드 본 파일 0건 |

---

## Swift 패턴 준수

- **강제 언래핑 미사용**: BombFlashNode·GameConfig·GameScene 추가분에 `!` 0건
- **guard let 옵셔널 처리**: 옵셔널 분기 발생 없음 (모두 값 타입)
- **MARK 섹션 구분**: BombFlashNode에 `// MARK: - Init`, `// MARK: - Flash` 2개. GameScene 헤더에 Phase 4-5 코멘트 추가.
- **GameConfig 상수 사용**: 매직 넘버 0 — `bombFlashDelay`, `bombFlashFadeInDuration`, `bombFlashFadeOutDuration` 3상수 전부 사용. 색은 `.ganhoPaper`.
- **weak self 캡처**: BombFlashNode.flash에 클로저 없음 — 캡처 불필요 (SPEC §3.5 주석과 일치)

---

## SpriteKit 패턴 준수

- **didMove(to:)에서 초기화**: 본 sprint는 didMove 손 안 댐 — 기존 초기화 흐름 유지
- **dt 기반 이동**: 해당 없음 (이동 없는 alpha 액션만)
- **SKAction 스폰 패턴**: `SKAction.wait` / `fadeIn` / `fadeOut` / `removeFromParent` 4단 sequence — Timer 0
- **충돌 후 노드 즉시 삭제 없음**: 본 노드는 충돌 비참여 (PhysicsBody 없음). 자기 액션 sequence 마지막 단계에서 자가 `removeFromParent` — `didBegin` 안 아님
- **HUD 노드 분리**: 본 노드는 `cameraNode`에 부착 (`hud`와 분리). `zPosition = 250`으로 HUD(100), AirforceOverlay(200) 위
- **`addChild`는 액션 외부 1회**: `update()` 내부 호출 0 — `triggerAirforceEasterEgg()` 1회만 호출

---

## 빌드 상태

```
$ xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" \
             -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
...
** BUILD SUCCEEDED **
```

- **빌드 에러**: 0건
- **빌드 경고**: 0건 (`grep -E "warning:|error:" 결과 빈 출력)
- **링크/CodeSign**: GanhoMusic.app 정상 생성

---

## 검증 시나리오 (a)~(i) 정적 검증 결과

| # | 시나리오 | 검증 방법 | 결과 |
|---|---|---|---|
| (a) | 미접촉 시 폭탄 0 | `grep -rn "BombFlashNode()"` → 호출 1곳 (GameScene.swift:209, `triggerAirforceEasterEgg` 안) | ✅ PASS |
| (b) | trigger 시 폭탄 3줄 | GameScene.swift:209-211 `let bomb = BombFlashNode()` / `cameraNode.addChild(bomb)` / `bomb.flash(sceneSize: size)` 3줄 일치 | ✅ PASS |
| (c) | ~1.8s 시점 폭탄 미등장 | `bombFlashDelay = 2.1` (GameConfig.swift:211), sequence 첫 액션이 `wait(forDuration: bombFlashDelay)` (BombFlashNode.swift:37) | ✅ PASS |
| (d) | ~2.1s 시점 fadeIn 시작 | sequence 순서 정확: `[wait, fadeIn, fadeOut, cleanup]` (BombFlashNode.swift:40) | ✅ PASS |
| (e) | ~2.5s 시점 removeFromParent | sequence 마지막 액션 `SKAction.removeFromParent()` (BombFlashNode.swift:39) | ✅ PASS |
| (f) | 게임 변경 0 | `update()` / `endGame()` / `gameState` / `airforceTriggered` 가드 위치 미변경. 기존 7줄 trigger 본문 미변경. | ✅ PASS |
| (g) | AI 변경 0 | Player·Enemy·Projectile·EnemyNode·SpawnSystem·StoneGuard·ContactRouter·PhysicsCategory 미수정 | ✅ PASS |
| (h) | 재통과 시 0 | `if airforceTriggered { return }` (GameScene.swift:201) trigger 최상단 가드 그대로. 폭탄 3줄은 가드 *아래* 위치 — 한 번만 발화 보장 | ✅ PASS |
| (i) | 빌드 SUCCEEDED + 경고 0 | xcodebuild 결과 `** BUILD SUCCEEDED **`, `grep "warning:\|error:"` 빈 출력. pbxproj 4곳 0020 식별자 일관 (PBXBuildFile A1C0F1B0...0020, PBXFileReference A1C0F1A0...0020) | ✅ PASS |

---

## 범위 외 미구현 항목

- 수간호사 도주 효과: SPEC OoS — Phase 4-6에서 처리
- F 재스폰 변형 효과: SPEC OoS — Phase 4-7에서 처리
- 사운드 / 햅틱: SPEC OoS
- 자가 소멸 노드 protocol 추출(`SelfDismissingNode`): SPEC OoS — Rule of three 도달했으나 별도 리팩터 sprint로 보류 (학습 가치 § "*추출은 별도 sprint로*")
- ColorTokens 새 토큰: SPEC OoS — `.ganhoPaper` 재사용

본 sprint 범위는 **순수 시각 임팩트 1건 추가**이며 SPEC In Scope 4개(BombFlashNode 신규 / GameConfig 3 상수 / GameScene 헤더+doc+3줄 / pbxproj 4곳)를 모두 완수.
