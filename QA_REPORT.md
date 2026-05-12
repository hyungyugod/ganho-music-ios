# QA 검수 보고서 — Phase 5-R · PlayerNode.apply(_:) 단일 진입점 리팩터

## SPEC 기능 검증

- **[PASS] 기능 1 — `apply(_ characterID: CharacterID)` 신설**
  - `PlayerNode.swift:57-60` 시그니처 `func apply(_ characterID: CharacterID)` 정확 (단일 인자, 외부 레이블 `_`, 반환값 없음).
  - 본문 정확히 2줄: `color = characterID.color` / `speedMultiplier = characterID.playerSpeedMultiplier`. guard/if/print/SKAction/추가 setter 0건.
  - 순서 `color` → `speedMultiplier` — 5-3 직접 setter와 동일.
  - `self` 생략 관용 표기, 한 메서드 내 표기 통일.
  - `// MARK: - Apply` 섹션이 `// MARK: - Update`(PlayerNode.swift:62) 바로 위에 위치 — Init → Apply → Update 의미 흐름 정확.

- **[PASS] 기능 2 — `setupPlayer()` 단일 호출로 교체**
  - `GameScene+Setup.swift:113` `player.apply(characterID)` 한 줄로 통합.
  - `player.position = …` (109-112)는 위치 그대로, `worldNode.addChild(player)` (114)는 위치 그대로.
  - 5-2/5-3 흐름 주석은 호출 옆 인라인 주석 1줄로 통합 (정보 손실 0).
  - git diff 확인 — 본 sprint의 진정한 변경은 `-1행 +1행` 단일 라인 교체.

- **[PASS] 기능 3 — PlayerNode 헤더 갱신**
  - `PlayerNode.swift:8` `//  Phase 5-R · CharacterID 단일 진입점 메서드 apply(_:) 추출 (순수 리팩터)` 추가.
  - 기존 1-3 / 2-2 / 5-3 라인(4-7) 그대로 유지.

## 빌드 검증

- **결과: BUILD SUCCEEDED** (xcodebuild generic/iOS Simulator Debug)
- Swift 컴파일 에러 0 / 경고 0 (AppIntents 메타 추출 외)
- 산출물: `GanhoMusic.app` 정상 생성

## 회귀 검증 (5-R sprint 0줄 변경 확인 — 5-3/5-4 누적 변경은 제외)

| 파일 | 5-R sprint 변경 |
|---|---|
| `GameScene.swift` | 0줄 (git diff에 변화 없음) |
| `Models/CharacterID.swift` | 0줄 (5-3 누적 +13행만 존재, playerSpeedMultiplier prop 그대로) |
| `Scenes/TitleScene.swift` | 0줄 |
| `Nodes/HUDNode.swift` | 0줄 (5-4 누적 +23행만 존재) |
| `Config/GameConfig.swift` | 0줄 (5-4 누적 +4행만 존재) |
| `Config/ColorTokens.swift` | 0줄 |
| 기타 Nodes/Systems/Repositories/Errors | 0줄 |
| pbxproj | 0줄 (파일 추가/삭제 없음) |

→ Out of Scope 위반: 0건

## 기능 변화 0 정적 추적 — 5 캐릭터 시나리오

**Before (5-3 종결)**:
```
setupPlayer():
  player.position = (mapW/4, mapH/2)
  player.color = characterID.color                            ← setter A
  player.speedMultiplier = characterID.playerSpeedMultiplier  ← setter B
  worldNode.addChild(player)
```

**After (5-R)**:
```
setupPlayer():
  player.position = (mapW/4, mapH/2)
  player.apply(characterID)
    └─ self.color = characterID.color                            ← setter A (동일)
    └─ self.speedMultiplier = characterID.playerSpeedMultiplier  ← setter B (동일)
  worldNode.addChild(player)
```

| # | 시나리오 | `color` 결과 | `speedMultiplier` 결과 | 5-3과 동일 |
|---|---|---|---|---|
| (a) | `.kim` | `.ganhoPaper` | `1.00` | PASS |
| (b) | `.jung` | `.ganhoMint` | `1.10` | PASS |
| (c) | `.geon` | `.ganhoPinkNote` | `0.90` | PASS |
| (d) | `.im` | `.ganhoYellowF` | `0.95` | PASS |
| (e) | `.lee` | `.ganhoBloodAccent` | `1.05` | PASS |

추가 검증:
- 두 setter 호출 순서(color → speedMultiplier) 유지 — `PlayerNode.swift:58-59`에서 확인.
- 두 setter 모두 `worldNode.addChild(player)` 이전 실행 — 5-3과 동일 타이밍.
- `apply(_:)` 본문 동기 실행(SKAction/dispatch_async 없음) — 5-3 직접 setter와 실행 시점 비트 단위 동일.
- `CharacterID.swift`는 5-R sprint에서 0줄 변경 → 반환값 동일.

→ **기능 변화: 0**

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- **Swift 패턴 일관성**: 강제 언래핑 0, Timer/DispatchQueue 0, 매직 넘버 0(신규 상수 추가 없음), `MARK: - Apply` 섹션 신설로 클래스 구조 순서 정합. 함수 단일 책임(`apply`는 캐릭터 정체성 적용만). 외부 레이블 `_` Swift 관용 표기.
- **게임 로직 완성도**: SpriteKit 초기화 흐름(didMove → setupPlayer → apply) 그대로. dt 기반 이동 영향 0, SKPhysics/SKAction 미접촉. 노드 즉시 삭제 없음. PhysicsCategory 비트마스크 정의 미변경.
- **성능 & 안정성**: 빌드 클린(에러 0/경고 0). 강제 언래핑 0. weak self 클로저 미사용(클로저 자체 없음). 메모리 누수 가능성 0.
- **기능 완성도**: SPEC In Scope 3항목 모두 충족, Out of Scope 위반 0. 5 캐릭터 시나리오 전부 5-3과 비트 단위 동일.
- **Phase 4-R DNA 일관성**: "공통 패턴을 한 곳으로 추출, 기능 변화 0"이라는 동일한 리팩터 결을 5-R도 충실히 계승.

## 채점

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (35%) | **10/10** | MARK 섹션 신설, 함수 단일 책임, `self` 생략 관용, 외부 레이블 `_` — 모든 패턴 정합. 헤더 누적 기록 보존. |
| 게임 로직 완성도 (30%) | **10/10** | 기능 변화 0 = 회귀 0. 호출 시점·순서·우변 모두 5-3과 동일. didMove → setupPlayer → apply 흐름 보존. |
| 성능 & 안정성 (20%) | **10/10** | 빌드 클린, 강제 언래핑 0, 클로저 없음, 동기 실행만. side effect 0. |
| 기능 완성도 (15%) | **10/10** | In Scope 3 완전 충족, Out of Scope 위반 0, 5 캐릭터 정적 추적 비트 단위 동일. |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

순수 리팩터의 모범 사례. 본 sprint의 핵심 검증 포인트인 "기능 변화 0"이 정적 추적·빌드·시그니처 검증 3축 모두에서 입증됨. 두 setter 호출 위치만 PlayerNode 내부로 옮긴 *최소 침습* 변경이며, SPEC의 시그니처·본문 줄수·위치(Init → Apply → Update)·헤더 1줄 추가 등 모든 디테일 요구사항이 한 치 어긋남 없이 충족됨. Phase 4-R(SelfDismissingNode protocol)과 동일한 DNA — "공통 구조를 한 곳에 모음" — 를 일관되게 적용한 학습 가치 높은 sprint.

**구체적 개선 지시**: 없음. 현 구현 그대로 commit 권장.
