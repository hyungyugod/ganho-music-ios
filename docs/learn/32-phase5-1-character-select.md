# 32 · Phase 5-1 · 캐릭터 선택 UI 골격 — *5명, 색만 다른 카드* 🃏

> **이번 작업 한 줄**: TitleScene 하단에 5명(김간호/정간호/건간호/임간호/이간호) 카드를 가로 일렬로 띄우고 탭으로 선택을 바꿀 수 있게 한다. 선택된 카드만 또렷이 보이고 나머지는 흐리게. *게임 시작 시 선택 결과는 아직 무시* — UI 골격만 도입.

---

## 1. 왜?

GDD §4에서 게임은 *캐릭터 5명*을 골라 플레이. 자전적 배경(간호 5명이 *각자 작곡 동기*)이 게임 정체성. Phase 4 종결 후 첫 Phase 5 sprint는 *그 골격*만 — 화면에 5명을 띄우고 *고를 수 있다*는 사실만.

게임 로직 변화 0:
- PlayerNode 색·외형은 그대로 (캐릭터별 시각 차이는 5-3)
- 스킬은 그대로 없음 (5-4부터)
- GameScene 한 줄도 안 건드림 (호출 측 변경 0 정책)

> Spring 비유: 단일 페이지에 *드롭다운 5개*를 띄우고 *선택 UI만*. 선택 결과를 *백엔드로 보내는 건* 다음 PR.

---

## 2. Spring 비유 ⭐

| SpriteKit | Spring | 한 줄 설명 |
|---|---|---|
| `enum CharacterID` | `enum CharacterID { KIM, JUNG, GEON, IM, LEE }` | 5개 케이스 정해진 type |
| `CharacterCardNode` | UI 컴포넌트 (Vue/React `<CharacterCard>`) | 색 + 이름 + 선택 상태 표시 |
| TitleScene의 `selectedCharacterID` | 컴포넌트의 `selectedValue` state | *현재 선택*을 보관 |
| `touchesBegan`에서 *hit test* | `@click` 이벤트 핸들러 | 어느 카드를 탭했는지 식별 |
| 카드 알파 1.0 vs 0.5 | CSS `opacity: 1` vs `opacity: 0.5` | 선택 시각 표시 |

**핵심**: 본 sprint는 *UI*만. *비즈니스 로직*(스킬·외형 적용)은 다음 sprint.

---

## 3. 새로 배운 것 (Swift/SpriteKit) ⭐

### 3-1. **Swift `enum` 키워드 첫 도입 — 5 case**

```swift
enum CharacterID: String, CaseIterable {
    case kim, jung, geon, im, lee
}
```

- `enum`: *유한한 값* 표현 (Java enum과 동일 역할)
- `String` 적합성: *raw value*가 자동으로 case 이름 ("kim", "jung" 등)
- `CaseIterable`: `CharacterID.allCases`로 *모든 case 배열* 자동 생성 — `for case in .allCases` 가능

본 sprint의 큰 학습 — `enum`은 *상태 머신*의 표준 도구. 4-6의 `Bool isFleeing`이 *2개 상태*였다면 enum은 *N개 상태*.

> Spring 비유: `enum CharacterID { KIM, JUNG, GEON, IM, LEE }`. Swift는 *associated value* / *raw value* 풍부 — Java보다 강력.

### 3-2. **`CaseIterable` — 자동 .allCases**

```swift
for id in CharacterID.allCases {
    // 5번 반복
}
```

Swift가 *프로토콜 채택만으로* allCases 자동 생성. Java라면 직접 `values()` 호출.

> Spring 비유: `EnumSet.allOf(CharacterID.class)`와 동치. Swift는 더 간결.

### 3-3. **`SKNode + 자식 노드` 컨테이너 패턴 (3번째 답습)**

| Sprint | 컨테이너 노드 |
|---|---|
| 2-4 | HUDNode (SKNode + 3 SKLabelNode) |
| 4-4 | AirforceOverlayNode (SKNode + 1 SKLabelNode) |
| **5-1** | **CharacterCardNode (SKNode + 1 SKSpriteNode + 1 SKLabelNode)** |

같은 패턴 — *부모 = 좌표·zPosition·name*, *자식 = 시각 속성*. 책임 분리.

### 3-4. **`touchesBegan`에서 hit test — 새 패턴**

기존 TitleScene `touchesBegan`은 *화면 어디든 탭 → GameScene 전환*. 본 sprint는:
- 카드 영역 탭 → *선택 변경* (GameScene 전환 X)
- 그 외 영역 탭 → *기존 동작* (GameScene 전환)

```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isTransitioning else { return }
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    
    // 1) 카드 hit test 먼저
    for (id, card) in characterCards {
        if card.contains(location) {
            select(id)
            return   // 카드 탭 시 GameScene 전환 *안 함*
        }
    }
    
    // 2) 그 외 영역 → 기존 동작
    isTransitioning = true
    // ... presentScene ...
}
```

**핵심**: `SKNode.contains(_:)`로 *터치 좌표가 노드 영역 안인지* 검사. SpriteKit 표준 메서드.

### 3-5. **알파 1.0 vs 0.5 — 선택 시각 표시**

```swift
func setSelected(_ selected: Bool) {
    alpha = selected ? 1.0 : 0.5
}
```

CSS `opacity` 직관과 동일. 별도 테두리·하이라이트 노드 추가하지 않고 *알파 1개*로 표현 — 최소한.

> 미래: 테두리 노드 추가, 펄스 애니메이션 등 *시각 강조* sprint 분리 가능.

### 3-6. **GameScene 호출 측 변경 0 (Phase 4부터 8 sprint 연속)**

본 sprint도:
- GameScene 0줄 변경
- GameScene+Setup 0줄
- 모든 노드(Player/Enemy/Stone/...) 0줄
- 모든 시스템 0줄

TitleScene에 *기능 추가*만 — Phase 4-2~4-7~4-R~5-1 *9 sprint 연속* 호출 측 변경 0. *분리해서 작게* 정책이 *체화*된 상태.

---

## 4. 무엇을 만드나?

### 새 파일 (2개)
| 파일 | 역할 |
|---|---|
| `Models/CharacterID.swift` | enum + CaseIterable. id/displayName/color 프로퍼티 |
| `Nodes/CharacterCardNode.swift` | SKNode 컨테이너 + 색 사각형 + 이름 라벨. `setSelected(_:)` 메서드 |

### 고치는 파일 (3개 + pbxproj)
| 파일 | 변경 |
|---|---|
| `Config/GameConfig.swift` | 캐릭터 카드 섹션 신설 + 상수 (cardSize / spacing / offsetY / selectedAlpha / deselectedAlpha) |
| `Scenes/TitleScene.swift` | 5 카드 배치 + `selectedCharacterID` 프로퍼티 + touchesBegan에 hit test 추가 + layoutLabels에 카드 위치 |
| pbxproj | CharacterID.swift (식별자 0022, Models 그룹) + CharacterCardNode.swift (식별자 0023, Nodes 그룹) — 각각 4곳 |

### Out of Scope
- PlayerNode 색·외형 변경
- 스킬 시스템
- 캐릭터별 게임 로직
- GameScene 변경
- 선택 결과를 GameScene에 *전달* (다음 sprint 5-2)
- 캐릭터 정보 영구 저장 (Repository)
- 카드 애니메이션 (펄스 등)

### 5 캐릭터 색 (잠정)
ColorTokens 기존 7색에서 5개 선택:
- 김간호 (kim) — `.ganhoPaper` (가운, 기본)
- 정간호 (jung) — `.ganhoMint` (활동적인 민트)
- 건간호 (geon) — `.ganhoPinkNote` (책 표지 분홍)
- 임간호 (im) — `.ganhoYellowF` (긴머리, 노랑)
- 이간호 (lee) — `.ganhoBloodAccent` (단발, 강한 빨강)

> 새 ColorTokens 신설 X — 기존만 재사용.

### 한 그림으로

```
┌─────────────────────────────────────────────┐
│           김간호는 음악박사                  │   ← titleLabel
│                                              │
│              BEST 🏆 12                      │   ← bestLabel
│              PLAYS 5                          │   ← playsLabel
│                                              │
│            TAP TO START                       │   ← promptLabel (깜빡)
│                                              │
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                ← 5-1 신규: 5 카드
│   │김│ │정│ │건│ │임│ │이│                  (현재 김간호 선택 = alpha 1.0,
│   └──┘ └──┘ └──┘ └──┘ └──┘                   나머지 alpha 0.5)
└─────────────────────────────────────────────┘
```

---

## 5. 직접 확인할 것

⌘R 후:

| # | 시나리오 | 봐야 할 것 |
|---|---|---|
| (a) | 게임 첫 진입 | TitleScene에 5 캐릭터 카드 가로 일렬. 김간호(kim)만 또렷(alpha 1.0), 나머지 4명 흐림(alpha 0.5) |
| (b) | 카드 영역 탭 (예: 정간호) | 정간호 alpha 1.0, 김간호 alpha 0.5. GameScene 전환 *안 됨* |
| (c) | 다른 카드 탭 (예: 이간호) | 이간호 alpha 1.0, 정간호 alpha 0.5 |
| (d) | 카드 *외 영역* 탭 (예: 화면 상단) | 기존 동작 — GameScene으로 fade 전환 |
| (e) | GameScene 시작 | 4-R과 *완전 동일* — PlayerNode 색·외형 변화 0 (선택 결과 무시) |
| (f) | 한 판 종료 → ResultScene → TitleScene 복귀 | 다시 김간호 선택 상태 (선택 영구 저장 X — 다음 sprint) |
| (g) | 시각 회전 (가로 → 세로 또는 다른 viewport) | 카드 위치 재계산 (didChangeSize 호출) |
| (h) | 빌드 | BUILD SUCCEEDED + 경고 0 |

> **핵심**: 사용자는 *카드를 본다 + 고를 수 있다*까지만. 게임 안 변화 0.

---

## 6. 사용자 결정 (이미 합의)

| 결정 | 선택 | 왜 |
|---|---|---|
| 본 sprint 범위 | 카드 UI 골격만 | 선택 결과 GameScene 전달은 5-2 |
| 카드 시각 | 사각형 + 이름 라벨 | 픽셀 아트 텍스처는 Phase 6 |
| 카드 색 | ColorTokens 5개 재사용 (.ganhoPaper/Mint/PinkNote/YellowF/BloodAccent) | 새 토큰 신설 X |
| 선택 표시 | 알파 1.0 vs 0.5 | 가장 단순. 테두리/펄스는 추후 |
| 선택 변경 | 카드 탭 (`SKNode.contains`) | 모바일 직관 UI |
| 기본 선택 | kim (김간호) | GDD §4 첫 케이스, 스킬 없음(가장 단순) |
| 게임 시작 시 선택 결과 | **무시** (PlayerNode 변경 X) | 다음 sprint(5-2)로 분리 |
| 카드 영구 저장 | **X** | 매 진입마다 kim으로 리셋. 영구 저장은 5-2+ |
| 가로 배치 | YES (5 카드 일렬) | 가로 게임 → 가로 캐러셀 자연 |
| 새 ColorTokens | **금지** | 기존 토큰 재사용 |

---

## 7. 회고

### 7-1. 막혔던 것

**없음.** 한 사이클 만점 합격(10.0/10). Phase 5의 첫 sprint를 1회 통과로 마침.

### 7-2. 새로 배운 것

1. **Swift `enum` 키워드 첫 도입** — Java enum과 *역할 동일*. raw String + CaseIterable 채택으로 *값 + 반복* 동시 제공.
2. **`raw String` enum** — `case kim, jung, geon, im, lee`만 쓰면 *case 이름이 자동으로 raw value*("kim", "jung", ...). 별도 `= "kim"` 명시 불필요. Swift 고유 편의.
3. **`CaseIterable` protocol** — `.allCases`를 *자동 생성*. Java `values()` 동치. `for id in CharacterID.allCases` 패턴.
4. **`switch self` 패턴** — enum 내부에서 *각 case별 매핑*. computed property로 `displayName`/`color` 정의.
5. **SKNode 컨테이너 패턴 3회차** — HUDNode(2-4) → AirforceOverlayNode(4-4) → CharacterCardNode(5-1). 부모는 *좌표·zPosition·name*, 자식은 *시각 속성*.
6. **`touchesBegan` hit test** — `SKNode.contains(_:)`로 *터치 좌표가 노드 영역 안인지* 검사. SpriteKit 표준 메서드. Vue/React `@click` 핸들러와 직관 동일.
7. **알파 1.0 vs 0.5 = 선택 시각 표시** — CSS `opacity` 직관. 별도 테두리/하이라이트 노드 추가 없이 *알파 1개*로 표현.
8. **GameScene 호출 측 변경 0 정책 9 sprint 연속** — Phase 4-2 → 4-3 → 4-4 → 4-5 → 4-6 → 4-7 → 4-R → 5-1. *분리해서 작게* 정책 *체화*. PlayerNode/EnemyNode/GameScene 모두 변경 0.

> Spring 비유: `enum CharacterID { KIM, JUNG, GEON, IM, LEE }` + 5개 카드 UI 컴포넌트. *백엔드(GameScene) 변경 0* — 미래 PR에서 *선택 결과를 게임에 적용*.

### 7-3. 다음으로 미룬 것

- **5-2**: 선택 결과 GameScene 전달 (`GameScene.newGameScene(characterID:)` init 주입)
- **5-3**: 선택 캐릭터별 PlayerNode 색 적용 (CharacterID.color → PlayerNode.color)
- **5-4**: 첫 스킬 도입 (정간호 돌진 또는 건간호 음표 흡수)
- **5-5+**: 4개 스킬 + 쿨다운 HUD + 스킬 버튼 (D-Pad 왼쪽)
- **카드 시각 강화**: 테두리/펄스 애니메이션 (별도 sprint)
- **선택 영구 저장**: 마지막 캐릭터 선택을 UserDefaults에 (별도 sprint)
- **컷씬 시스템**: GDD §9 인트로/중간/이교주 경고 (Phase 5 후반)

### 7-4. 평가 점수

- **가중평균: 10.0 / 10 — 만점 합격** 🎉
- 항목별: Swift 패턴 10 / 게임 로직 10 / 성능·안정성 10 / 기능 완성도 10
- P0/P1 0건, P2 1건(zPosition=100 매직 넘버 — SPEC 명시값, 합격 무영향)
- 빌드: BUILD SUCCEEDED, 경고 0건
- diff: 신설 2파일(CharacterID 37줄 + CharacterCardNode 60줄) + 수정 3파일

### 7-5. 핵심 가치 — *Phase 4 종결 → Phase 5 자연 진입*

| 보존된 것 | 변경 0건 |
|---|---|
| PlayerNode / EnemyNode / StoneGuardNode / NoteNode / ProjectileNode | ✅ |
| HUDNode / DPadNode | ✅ |
| AirplaneNode / AirforceOverlayNode / BombFlashNode | ✅ |
| GameScene / GameScene+Setup | ✅ |
| ResultScene | ✅ |
| ContactRouter / PhysicsCategory / SpawnSystem / ScoreSystem | ✅ |
| 기존 GameConfig 상수 (스토너가드 / Airforce 7상수 / 그 외) | ✅ |
| ColorTokens (5색 재사용, 신설 0) | ✅ |
| TitleScene 기존 4 라벨 위치 / setupLabels / layoutLabels 본문 | ✅ |
| 기존 touchesBegan 본문 (앞에 hit test만 추가) | ✅ |
| macOS / tvOS Sources phase | ✅ |
| update / endGame / airforceTriggered | ✅ |

**추가된 것**:
- CharacterID.swift (37줄, enum + 매핑)
- CharacterCardNode.swift (60줄, 컨테이너)
- GameConfig Character Card 섹션 6 상수
- TitleScene 확장 (~35줄)
- pbxproj 4곳 × 2파일

**Phase 4 (4-1 ~ 4-R) 종결 후 Phase 5의 *깔끔한 첫 단추***. 게임 안 변화 0이지만 *코드 구조가 미래의 5-2 ~ 5-N을 받아들일 준비* 완료. `enum CharacterID`는 *Phase 5 전체의 척추* — 다음 sprint들이 이 enum을 *주변에서* 확장.

---

## 8. 다음 작업

```
[1] 시뮬레이터에서 §5 (a)~(h) 확인 (카드 탭으로 선택 변경)
[2] 다음 sprint 후보:
    - 5-2: 선택 결과를 GameScene에 전달 (init 주입)
    - 5-3: 선택 캐릭터별 PlayerNode 색 적용
    - 5-4: 첫 스킬 도입 (정간호 돌진 또는 건간호 음표 흡수)
```

> **이번 sprint 본질**: Phase 5의 *첫 단추* — UI 골격. 5-2(전달), 5-3(외형), 5-4+(스킬)로 *분리해서 작게* 진행. `enum` 키워드 첫 도입으로 Swift *값 타입* 학습 폭이 한 단계 넓어짐.
