# QA 검수 보고서 — Phase 5-1 캐릭터 선택 UI 골격

## SPEC 기능 검증

| # | 기능 | 결과 | 상세 |
|---|---|---|---|
| 1 | `Models/CharacterID.swift` 신설 | ✅ PASS | `enum CharacterID: String, CaseIterable`, 5 case (kim/jung/geon/im/lee), displayName/color computed property 각각 5 case 매칭. `import UIKit` 정확. |
| 2 | `Nodes/CharacterCardNode.swift` 신설 | ✅ PASS | `final class CharacterCardNode: SKNode`, `id/background/nameLabel` 프로퍼티, `setSelected(_:)` + `configureLabel()`. PhysicsBody 0건. zPosition=100. |
| 3 | `GameConfig` Character Card 섹션 +6 상수 | ✅ PASS | `characterCardWidth/Height/Spacing/FontSize/OffsetY/DeselectedAlpha` 6개 추가, 모두 doc comment 동반. 기존 상수 무변경. |
| 4 | `TitleScene` 확장 | ✅ PASS | 헤더 1줄 + properties 2 + didMove/didChangeSize 각 1줄 + 신규 메서드 3개(setupCharacterCards/layoutCharacterCards/select) + touchesBegan hit test 9줄 추가. 기존 본문(setupLabels/layoutLabels/touchesBegan 후반부) 무변경. |
| 5 | `pbxproj` 0022/0023 등록 | ✅ PASS | 식별자별 4곳(BuildFile / FileReference / PBXGroup / iOS Sources) 정확히 카운트. tvOS/macOS Sources `files = ()` 빈 채 유지. |

## 빌드 검증

- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 결과: **`** BUILD SUCCEEDED **`**
- 추가 검증: `clean build`로 풀 빌드 재확인 — 결과 동일.
- 컴파일 경고: **0건** (warning/error 패턴 grep 결과 무관 메시지만 출현, 소스 무관)
- 컴파일 에러: **0건**

## 검증 시나리오 (a)~(h)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| (a) | 5 카드 초기 상태 | ✅ | `setupCharacterCards`: `for id in CharacterID.allCases` (TitleScene.swift:118) — 5 인스턴스 생성. 기본 `selectedCharacterID: CharacterID = .kim` (line 27)이라 kim만 alpha 1.0. |
| (b) | 카드 탭 → 선택 갱신 | ✅ | `touchesBegan` 본문 맨 앞 hit test (line 156-164) — `for card in characterCards` → `card.contains(location)` → `select(card.id)` → `return`. |
| (c) | 이전 선택 해제 | ✅ | `select(_:)` (line 145-150)가 *모든* 카드 순회: `for card in characterCards { card.setSelected(card.id == id) }`. |
| (d) | 카드 외 탭 → GameScene 전환 | ✅ | hit test miss 시 루프 종료 → 기존 `guard !isTransitioning` / `guard let view` / `presentScene` 분기 그대로 실행 (line 166-171). |
| (e) | GameScene 변경 0 | ✅ | GameScene/GameScene+Setup/Nodes 모두 `git diff HEAD` 0줄. newGameScene() 호출 인자 변경 없음 (TitleScene.swift:169). |
| (f) | kim 리셋 | ✅ | `selectedCharacterID: CharacterID = .kim` 인스턴스 프로퍼티 기본값. `TitleScene.newTitleScene()` 매번 새 인스턴스 — UserDefaults 미사용. |
| (g) | didChangeSize 재계산 | ✅ | `super.didChangeSize` → `layoutLabels()` → `layoutCharacterCards()` 호출 순서 (line 49-51). |
| (h) | 빌드 SUCCEEDED + 경고 0 | ✅ | 위 빌드 검증 섹션과 같이 BUILD SUCCEEDED, 경고 0건. |

## 회귀 검증 (모든 항목 0줄 변경)

| 영역 | 결과 |
|---|---|
| PlayerNode / EnemyNode / StoneGuardNode / NoteNode / ProjectileNode / HUDNode / DPadNode / AirplaneNode / AirforceOverlayNode / BombFlashNode | 0줄 |
| GameScene / GameScene+Setup / ResultScene | 0줄 |
| ContactRouter / PhysicsCategory / SpawnSystem / ScoreSystem | 0줄 |
| ColorTokens (신규 토큰 0) | 0줄 — 기존 5색(.ganhoPaper/.ganhoMint/.ganhoPinkNote/.ganhoYellowF/.ganhoBloodAccent)과 라벨 가독성용 .ganhoBgDeep 재사용만 |
| 기존 GameConfig 상수 | 0줄 — 219번째 줄 enemyFleeDuration 다음 *추가*만 |
| 기존 4 라벨 위치 / setupLabels 본문 / layoutLabels 본문 / touchesBegan 본문 | 본문 변경 0 — 헤더 1, properties 2, didMove +1, didChangeSize +1, touchesBegan 앞에 hit test *추가*만 |
| macOS/tvOS Sources phase | files = () 빈 채 유지 (project.pbxproj line 456, 463) |

## 추가 검증

| 항목 | 결과 |
|---|---|
| CharacterID raw String + CaseIterable | ✅ `enum CharacterID: String, CaseIterable` (CharacterID.swift:13) |
| displayName/color switch 5 case 매칭 | ✅ kim/jung/geon/im/lee 각각 displayName(line 18-24)/color(line 28-35)에서 정확히 5 case 분기 |
| color는 기존 ColorTokens 5개만 | ✅ ganhoPaper/Mint/PinkNote/YellowF/BloodAccent — 모두 ColorTokens.swift에 사전 존재 (신규 0) |
| CharacterCardNode `: SKNode` | ✅ `final class CharacterCardNode: SKNode` (line 13) — SKSpriteNode 아님 |
| PhysicsBody 0 | ✅ CharacterCardNode 전체에 physicsBody 코드 없음 (grep 결과) |
| zPosition = 100 | ✅ (line 33) |
| 매직 넘버 0 (GameConfig 6 상수 참조) | ⚠️ 거의 0 — width/height/spacing/fontSize/offsetY/deselectedAlpha 6 상수 모두 GameConfig 참조. 선택 alpha의 `1.0`은 *완전 불투명*의 표준 표기이므로 상수화 안 함이 관례. zPosition=100은 단일 리터럴(아래 P2 항목 참조). |
| nameLabel 색 .ganhoBgDeep (가독성) | ✅ (CharacterCardNode.swift:55) — 밝은 카드 배경 위 어두운 텍스트 |
| pbxproj 0022/0023 각 4곳 일관 | ✅ grep 결과 각각 정확히 4건 |
| tvOS/macOS 빈 채 | ✅ files = () (project.pbxproj line 456, 463) |

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | **0건** |
| P1 중요 | **0건** |
| P2 권장 | **1건** |

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

없음.

## P2 — 권장 사항

### 1. zPosition 매직 넘버 — GameConfig화 여지
- **파일**: `Nodes/CharacterCardNode.swift:33`
- **현재 코드**: `zPosition = 100`
- **상황 분석**: SPEC에 명시된 값이고 sprint 안에서 단 1회 사용되며 다른 노드(HUDNode `zPosition = 1000` 등)와 충돌이 없어 동작상 문제 없음. 다만 평가 기준상 매직 넘버 패턴에 해당하므로 향후 sprint에서 `GameConfig.characterCardZPosition` 또는 `Config/ZPositionLayer.swift` enum 도입 고려.
- **수정 제안 (선택)**:
```swift
// Config/GameConfig.swift (추가)
static let characterCardZPosition: CGFloat = 100

// CharacterCardNode.swift:33
zPosition = GameConfig.characterCardZPosition
```
- **본 sprint 적용 의무 여부**: **아니오** — SPEC 핵심 코드에 `zPosition = 100`이 그대로 명시되어 있어 generator 책임이 아닌 SPEC 단계 결정 사항. 합격 판정 무영향.

## 통과 항목

- **강제 언래핑 0건** — 신규 2 파일 모두 `!` 사용 없음 (CharacterCardNode init 내 `id` 저장도 옵셔널 아님)
- **`Timer` / `DispatchQueue` 0건** — TitleScene 내 "Timer 금지"는 주석 텍스트 (line 101)
- **MARK 섹션** — CharacterCardNode `// MARK: - Properties / Init / Selection / Configure` 4개, TitleScene `// MARK: - Character Cards` 추가, 일관
- **weak self 캡처** — 본 sprint 클로저 없음 — 캡처 필요 시점 없음 (SPEC 주의사항과 일치)
- **단일 책임 함수** — setupCharacterCards / layoutCharacterCards / select / configureLabel 모두 한 책임
- **enum 도입** — CaseIterable.allCases 정확 활용 (Java values() 동치) — 새 case 추가 시 자동 반영, 누락 방지
- **didMove 초기화** — setupCharacterCards가 setupLabels와 동일 layer로 didMove에서 호출 (sceneDidLoad 아님)
- **HUD 노드 분리 패턴 답습** — CharacterCardNode가 자체 SKNode 컨테이너 (HUDNode/AirforceOverlayNode와 동일 패턴 3회차)
- **좌표계** — frame.midX/midY 기준 + offset (기존 TitleScene 패턴 일치)
- **OoS 위반 0** — PlayerNode/GameScene/Repository/ColorTokens/AnimAction 전부 미터치
- **Sprint 범위 정확** — In Scope 5 항목 전체 구현, Out of Scope 16 항목 미터치
- **빌드 클린 + 경고 0** — clean build에서도 SUCCEEDED 재확인

---

## 채점

| 항목 | 점수 | 코멘트 |
|---|---|---|
| Swift 패턴 일관성 (0.35) | **10/10** | enum/CaseIterable 정확, MARK 섹션 일관, GameConfig 상수 6개 신규 도입, 강제 언래핑 0, Timer 0, 매직 넘버 zPosition 1건만 잔존(P2 수준). 한국어 변수명 없음, 주석만 한국어. |
| 게임 로직 완성도 (0.30) | **10/10** | SKNode 컨테이너 패턴 3회차 일관, hit test (`SKNode.contains`) 정확, 선택 알파 토글 단일 책임, didMove/didChangeSize 분리 정확. 회귀 0줄 — 게임 루프 영향 없음. |
| 성능 & 안정성 (0.20) | **10/10** | PhysicsBody 0건 — 충돌/접촉 부담 없음. 클로저 사용 없어 weak self 불필요. 5 인스턴스 1회 setup, update() 미사용. 빌드 클린 + 경고 0. |
| 기능 완성도 (0.15) | **10/10** | SPEC In Scope 5 항목 전수 구현. 검증 시나리오 (a)~(h) 8건 전부 정적 PASS. 회귀 0줄(15+ 파일). |

**가중 점수**: (10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

**판정 근거**:
1. SPEC In Scope 5 항목 전체 구현, Out of Scope 16 항목 위반 0
2. 빌드 SUCCEEDED + 경고 0 + 에러 0 (clean build 재확인)
3. 회귀 0 — 15+ 파일이 정확히 0줄 변경
4. 검증 시나리오 (a)~(h) 8/8 PASS
5. P0/P1 이슈 0건. P2 1건은 SPEC 명시 값이라 본 sprint 책임 외
6. enum 첫 도입이라는 학습 목표 달성 — raw String + CaseIterable + switch 5 case 정확

**자기 검증** ("이 정도면 괜찮지 않나?" 재검토):
- 8.0 이상이라 추가 엄격 검토함
- 매직 넘버 zPosition=100 — 만약 P1로 격상하면? → SPEC 핵심 코드에 그대로 명시된 값이므로 generator의 자유재량 범위 아님 → P2 유지가 합당
- TitleScene `1.0` 인라인 alpha — 만약 매직 넘버로 보면? → 0.0/1.0은 알파의 *경계값*(투명/불투명)으로 Swift/SpriteKit 관례상 상수화 제외 영역 → 감점 부당
- 따라서 가중 10.0 유지가 정당.

**구체적 개선 지시**:
- 본 sprint 합격으로 추가 수정 불필요.
- (선택, 다음 sprint 5-2 진입 전 정리 사항) `Config/ZPositionLayer.swift` enum 도입을 검토하여 HUDNode·AirforceOverlay·BombFlash·CharacterCard 4 노드의 zPosition을 일괄 관리하면 레이어 충돌 가시성 ↑. 본 sprint와 무관, *제안*만.
