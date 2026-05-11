# 자체 점검 — Phase 5-1 캐릭터 선택 UI 골격

## SPEC 기능 체크
- [x] **기능 1**: `Models/CharacterID.swift` 신설 — enum 5 case + displayName/color (37줄)
- [x] **기능 2**: `Nodes/CharacterCardNode.swift` 신설 — SKNode 컨테이너 + setSelected + configureLabel (60줄)
- [x] **기능 3**: `Config/GameConfig.swift` Character Card 섹션 +6 상수 (width/height/spacing/fontSize/offsetY/deselectedAlpha)
- [x] **기능 4**: `Scenes/TitleScene.swift` 확장 — 헤더 1줄 + properties 2 + setup/layout/select 메서드 + touchesBegan hit test
- [x] **기능 5**: `pbxproj` 등록 — 식별자 0022(CharacterID)/0023(CharacterCardNode) 각 4곳 (BuildFile, FileReference, PBXGroup, Sources phase)

## 파일별 변경 줄 수
| 파일 | 변경 |
|---|---|
| `Models/CharacterID.swift` | 신설 +37줄 |
| `Nodes/CharacterCardNode.swift` | 신설 +60줄 |
| `Config/GameConfig.swift` | +14줄 (Character Card 섹션) |
| `Scenes/TitleScene.swift` | +35줄 (헤더 1 + props 4 + didMove 1 + didChangeSize 1 + 메서드 36 + touchesBegan hit test 9 + 주석) |
| `GanhoMusic.xcodeproj/project.pbxproj` | +8줄 (BuildFile×2, FileReference×2, Nodes group×1, Models group×1, iOS Sources×2) |

## OoS 미위반 체크
| 항목 | 상태 |
|---|---|
| PlayerNode/EnemyNode/StoneGuard/Note/Projectile/HUD/DPad/Airplane/AirforceOverlay/BombFlash 무변경 | 준수 (0줄 수정) |
| GameScene / GameScene+Setup / ResultScene 무변경 | 준수 (0줄 수정) |
| 스킬 시스템 / 캐릭터별 게임 로직 추가 X | 준수 |
| Repository / System / Manager 신설 X | 준수 |
| 새 ColorTokens 토큰 X (기존 5색 재사용) | 준수 (.ganhoPaper/.ganhoMint/.ganhoPinkNote/.ganhoYellowF/.ganhoBloodAccent + .ganhoBgDeep 라벨색) |
| 기존 GameConfig 상수 무변경 | 준수 (enemyFleeDuration 다음 *추가*만) |
| 기존 4 라벨 위치 무변경 (layoutLabels 본문 그대로) | 준수 |
| 기존 setupLabels 본문 무변경 | 준수 (didMove에서 setupCharacterCards 호출만 추가) |
| 기존 touchesBegan 본문 그대로 (앞에 hit test만 *추가*) | 준수 |
| update() / endGame() / contactRouter 무변경 | 준수 (TitleScene에는 update 없음) |
| macOS/tvOS Sources phase 무변경 | 준수 (iOS Sources만 +2줄) |
| Test 코드 추가 X | 준수 |

## Swift 패턴 준수
- 강제 언래핑 미사용: **준수** — `!` 0개. CharacterID/CharacterCardNode 전체 옵셔널 사용 없음. TitleScene touchesBegan은 `guard let touch = touches.first` / `guard let view = self.view` 패턴 그대로
- guard let 옵셔널 처리: **준수** — `guard let touch`, `guard let view`, `guard count > 0`
- MARK 섹션 구분: **준수** — `// MARK: - Properties`, `// MARK: - Init`, `// MARK: - Selection`, `// MARK: - Configure`, `// MARK: - Character Cards`
- GameConfig 상수 사용: **준수** — 모든 카드 크기/색/위치 값 GameConfig 참조, 매직 넘버 0개. `1.0` (선택 alpha)만 인라인 — *선택의 의미 자체*가 100% 표시이므로 상수화 불필요(deselectedAlpha만 GameConfig)
- weak self 캡처: **해당 없음** — 본 sprint 클로저 사용 없음 (SPEC §주의사항 명시)
- 네이밍: lowerCamelCase 변수/함수, UpperCamelCase 타입 — 준수
- 한국어 변수명 없음, 주석만 한국어 — 준수

## SpriteKit 패턴 준수
- didMove(to:)에서 초기화: **준수** — setupCharacterCards()는 setupLabels()와 동일 layer로 didMove에서 호출
- dt 기반 이동: **해당 없음** — 본 sprint 이동/애니메이션 없음 (펄스/페이드 OoS)
- SKAction 스폰 패턴: **해당 없음** — 본 sprint 스폰 없음 (5장 setup 1회만)
- 충돌 후 노드 즉시 삭제 없음: **해당 없음** — PhysicsBody 부착 0
- HUD 노드 분리: **준수** — CharacterCardNode는 자체 SKNode 컨테이너(HUDNode/AirforceOverlayNode 답습)
- zPosition 명시: **준수** — 100 (HUD-수준 시각, AirforceOverlay 200·BombFlash 250보다 낮음)
- 좌표계 일관: **준수** — frame.midX/midY 기준 (TitleScene 기존 패턴 답습)

## 빌드 상태
- **xcodebuild build (iPhone 17 시뮬레이터, iOS 26.4.1)**: `** BUILD SUCCEEDED **`
- **클린 빌드 (clean build)**: `** BUILD SUCCEEDED **`
- CharacterID.swift + CharacterCardNode.swift 정상 컴파일 확인 (`SwiftCompile normal arm64 ...CharacterID.swift` / `...CharacterCardNode.swift` 로그 존재)
- 소스 코드 경고/에러: **0건**
- (시스템 도구 경고 1건: `appintentsmetadataprocessor: Metadata extraction skipped. No AppIntents.framework dependency found` — 소스 코드 무관한 정상 메시지로 기존 빌드에도 동일하게 출력됨)

## 검증 시나리오 (a)~(h)

| # | 시나리오 | 정적 검증 결과 |
|---|---|---|
| (a) | 5 카드 초기 상태 | ✅ `setupCharacterCards`에서 `for id in CharacterID.allCases` — 5 인스턴스 생성, 기본 `selectedCharacterID = .kim`만 alpha 1.0, 나머지 4장 alpha 0.5 |
| (b) | 정간호 탭 → 선택 갱신 | ✅ `touchesBegan` 본문 맨 앞 `for card in characterCards / if card.contains(location) / select(card.id) / return` |
| (c) | 다른 카드 탭 시 이전 선택 해제 | ✅ `select(_:)` 가 *모든* 카드 순회: `for card in characterCards { card.setSelected(card.id == id) }` — 새 선택만 1.0, 나머지 0.5 |
| (d) | 카드 외 탭 → GameScene 전환 | ✅ hit test 5장 모두 미스 시 루프 종료, 기존 `guard !isTransitioning` / `guard let view` / `presentScene` 분기 그대로 실행 |
| (e) | GameScene 시작 — PlayerNode 변경 0 | ✅ GameScene/GameScene+Setup/Nodes 0줄 변경. `newGameScene()` 호출 인자 변경 0 |
| (f) | ResultScene → TitleScene 복귀 — kim 리셋 | ✅ `selectedCharacterID: CharacterID = .kim` 인스턴스 프로퍼티 기본값 — `TitleScene.newTitleScene()`은 매번 새 인스턴스 생성, UserDefaults 저장 안 함 |
| (g) | didChangeSize — 카드 재계산 | ✅ `super.didChangeSize` → `layoutLabels()` → `layoutCharacterCards()` 호출 |
| (h) | 빌드 SUCCEEDED + 경고 0 | ✅ `import UIKit` (CharacterID — UIColor 필요), `import SpriteKit` (CharacterCardNode), GameConfig 6 상수로 매직 넘버 0 |

## 범위 외 미구현 항목
- **없음** — SPEC In Scope 전 항목(1~5) 완전 구현. Out of Scope 항목 모두 손대지 않음.
- 비고: 본 sprint(5-1)는 *UI 골격*만 — 선택 결과를 GameScene으로 전달(PlayerNode 색·외형 변경)하는 작업은 5-2 이후로 SPEC에 명시되어 있어 의도적으로 보류함.

## 학습 가치 달성
- Swift `enum` 첫 도입 (5 case, raw String, CaseIterable) — Java `enum` + `values()` 대응
- `.allCases` 자동 생성 — 컴파일러 합성으로 새 case 추가 시 자동 반영(누락 방지)
- SKNode 컨테이너 패턴 3회차 (HUD/AirforceOverlay/CharacterCard) — *부모 = 좌표/zPosition/name, 자식 = 시각 속성* 패턴 일관성
- `touchesBegan` hit test (`SKNode.contains`) — 노드 영역 판정 기본기
- 선택 시각 표시 = 알파 1.0/0.5 — 별도 테두리 노드 없이 1프로퍼티로 표현
- GameScene 호출 측 변경 0 정책 9 sprint 연속 — 책임 경계 유지
