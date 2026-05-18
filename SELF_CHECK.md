# Self-Check — Phase 9-4

## 변경된 파일 목록 + 라인 수

| 파일 | 라인 추가 | 변경 내용 |
|---|---|---|
| `GanhoMusic Shared/GameScene+Setup.swift` | +70 (331줄 총계) | `setupWorld()` 1줄 추가, `setupMap()` switch 분기 재구성, `addNormalMap()` 신설, `addCheckerboardFloor()` 신설 |
| `GanhoMusic Shared/Config/GameConfig.swift` | +49 (760줄 총계) | "MARK: - Checkerboard Floor (Phase 9-4)" 4상수 + "MARK: - Normal Map (Phase 9-4)" 13상수 추가 |

빌드 결과: **BUILD SUCCEEDED** (iOS simulator, Xcode 26.5 / iOS 16.6)

---

## SPEC.md 각 항목 충족 여부

### 기능 1: 체크보드 바닥
- [x] 48×24 = 1152개 SKSpriteNode 생성 (`GameConfig.mapColumns × GameConfig.mapRows` 이중 for 루프)
- [x] 컨테이너 1개에 자식으로 묶음 (`SKNode()` → `worldNode.addChild(container)`)
- [x] `setupWorld()`에서 1회만 호출, `update()` 안 호출 0건
- [x] 각 타일 `physicsBody = nil`(미부착) — 시각 전용
- [x] `zPosition = GameConfig.checkerboardZPosition (-100)`
- [x] 컨테이너 `name = GameConfig.checkerboardContainerName`
- [x] 두 색 hex 상수 (`#1a1722` / `#13111a`)를 `GameConfig.checkerboardFloorAHex/BHex`로 분리
- [x] `(c + r) % 2 == 0` 시장 패턴 교차

### 기능 2: easy 맵 (변경 없음)
- [x] `addCentralPillar()` 0줄 수정 — Phase 7-2 회귀 0

### 기능 3: normal 맵
- [x] `addNormalMap()` 신설, 같은 파일 extension 안에 둠 (`addRectPillar`/`addVerticalWall` private 접근 위함)
- [x] 중앙 세로 분리벽 c=23, 윗 절반 r=2..10 + 아랫 절반 r=13..21
- [x] 가운데 r=11~12 두 칸 자연스럽게 비어 *문* 형성
- [x] 좌방 장식 기둥 2×2 (c=10..11, r=11..12)
- [x] 우방 장식 기둥 2×2 (c=36..37, r=11..12) 거울 대칭
- [x] `doorR: GameConfig.normalMapNoDoorSentinel (-1)` sentinel 사용 — graceful noop 확인

### 기능 4: hard 맵 (변경 없음)
- [x] `addHardMap()` 0줄 수정
- [x] switch에서 `.hard` 단독 case로 분리 (의도 명확화)
- [x] switch `default` 미사용 — Phase 7-2 패턴 답습

### 기능 5: setupBackground (변경 없음)
- [x] `backgroundColor = .ganhoBgDeep` 유지

---

## 매직 넘버 / 강제 언래핑 / Timer 사용 0건 확인

### 매직 넘버 0건
- 호출부(`GameScene+Setup.swift`)에 신규 코드 리터럴 0건:
  - `48`, `24` 없음 → `GameConfig.mapColumns`, `GameConfig.mapRows`
  - `"#1a1722"`, `"#13111a"` 없음 → `GameConfig.checkerboardFloorAHex/BHex`
  - `-100` 없음 → `GameConfig.checkerboardZPosition`
  - `"checkerboardFloor"` 없음 → `GameConfig.checkerboardContainerName`
  - `23`, `2`, `10`, `13`, `21`, `10`, `11`, `12`, `36`, `37`, `-1` 모두 `GameConfig.normalMap*` 상수
- `GameConfig.swift` 내부의 리터럴은 *단일 정의 지점*에 존재 — Phase 7-2 패턴과 동일

### 강제 언래핑 0건
- 신규 코드(`addNormalMap`, `addCheckerboardFloor`)에 `!` 사용 0건
- `grep "!"` 결과: `!=` 비교 연산자만 검출 (forced unwrap 아님)

### Timer 0건
- `Timer.scheduledTimer` / `Timer.publish` 등 0건
- `DispatchQueue.main.asyncAfter` 0건
- 체크보드는 *1회만* 빌드 → 반복 액션 자체가 불필요

### weak self
- 신규 코드에 클로저 캡처 자체가 없음(단순 for 루프 + 동기 메서드 호출) → 해당 없음

---

## 회귀 방지 영역 0줄 변경 확인

| 영역 | 변경 라인 수 | 검증 방법 |
|---|---|---|
| `addOuterWalls()` | 0 | git diff 확인 |
| `addCentralPillar()` | 0 | git diff 확인 |
| `addHardMap()` | 0 | git diff 확인 |
| `addRectPillar()` | 0 | git diff 확인 |
| `addHorizontalWall()` | 0 | git diff 확인 |
| `addVerticalWall()` | 0 | git diff 확인 |
| `setupBackground()` | 0 | git diff 확인 |
| `setupPlayer/setupEnemy/setupStoneGuard` | 0 | git diff 확인 |
| `setupCamera/setupDPad/setupHUD` | 0 | git diff 확인 |
| GameScene.swift (본체) | 0 | git diff 확인 — 본 sprint는 GameScene+Setup만 |
| Player/Enemy/StoneGuard/Note/Projectile 노드 | 0 | 파일 자체 미수정 |
| HUD/TitleScene/ResultScene/Repository | 0 | 파일 자체 미수정 |
| SpawnSystem `randomNotePosition()` | 0 | SPEC 명시: 다음 sprint 보강 |
| 카메라 follow (`update()` 안) | 0 | GameScene.swift 미수정 |

`setupWorld()`와 `setupMap()`만 *최소 변경*. `setupWorld()`는 1줄 추가(addCheckerboardFloor 호출), `setupMap()`은 switch 본문만 한 줄→세 줄로 분기 재구성(외부 의미 변화 0, 의도 명확).

---

## Swift / SpriteKit 패턴 준수

- [x] 강제 언래핑 미사용
- [x] guard let / if let 옵셔널 처리 (해당 없음 — 옵셔널 등장 없음)
- [x] MARK 섹션 구분 (`// MARK: - Checkerboard Floor (Phase 9-4)`, `// MARK: - Normal Map (Phase 9-4)`)
- [x] GameConfig 상수 사용 (매직 넘버 0)
- [x] weak self 캡처 (해당 없음 — 클로저 미사용)
- [x] didMove(to:)에서 초기화 (setupWorld → addCheckerboardFloor)
- [x] dt 기반 이동 (해당 없음 — 정적 빌더)
- [x] SKAction 스폰 패턴 (해당 없음 — 1회 빌드)
- [x] 충돌 후 노드 즉시 삭제 없음 (해당 없음 — 충돌 무관)
- [x] HUD 노드 분리 (해당 없음 — HUD 미변경)
- [x] private 접근 제어자 사용 — `addCheckerboardFloor` private (외부 호출 차단)
- [x] switch default 미회피 — enum 신규 case 시 컴파일러 경고로 검출

---

## 빌드 상태

- 예상 빌드 에러: **없음** (실제 `xcodebuild` 통과 확인)
- 주의 필요 경고: **없음**

---

## 범위 외 미구현 항목

- **SpawnSystem `randomNotePosition()` normal 맵 벽 회피**: SPEC.md 명시 — 본 sprint 의도적 미구현. 음표가 normal 맵 분리벽 위에 떠도 *플레이어 통과 가능성*은 영향 없음(단지 시각 노이즈). 다음 sprint 보강.
- 그 외 미구현 항목 없음.

---

## 자체 점수 예상 (10점 만점)

| 항목 | 가중치 | 예상 점수 | 근거 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | 10.0 | 매직 넘버 0건, 강제 언래핑 0건, MARK 분리, GameConfig 상수화 완전, switch default 미사용 |
| 게임 로직 완성도 | 30% | 10.0 | setupWorld() 1회만 호출, doorR=-1 sentinel graceful noop 확인, normal 분기 enum 패턴 매칭 |
| 성능 & 안정성 | 20% | 10.0 | 1152개 physicsBody 0, 컨테이너 1개로 묶음, name 부착, 강제 언래핑 0건 |
| 기능 완성도 | 15% | 10.0 | 체크보드 모든 난이도 공통, normal 문 r=11~12 두 칸 정확히 비움 |

**가중 평균 예상: 10.0 / 10**

빌드 통과 확인 완료. 회귀 방지 영역(Phase 7-2~8-5 산출물) 한 글자도 안 건드림.
