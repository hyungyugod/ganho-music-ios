# 06 · Phase 2-1 · 맵 외곽 벽 시각화

> **이번 작업의 한 줄**: 지금까지 *검은 우주*였던 맵 가장자리에 **벽**을 그어서 "여기가 맵이다"를 시각으로 보여준다.
> 비유: 운동장 펜스를 처음으로 *보이게* 칠하는 것.

---

## 1. 한눈 요약

```
지금 (Phase 1-5)                         이번 작업 (Phase 2-1)
┌─────────────────────────┐             ┌─────────────────────────┐
│ ▣            ▣          │             │ ━━━━━━━━━━━━━━━━━━ ←벽   │
│   ┌─ 보이지 않는 ─┐     │             │ ┃                  ┃     │
│   │  맵 (960×480) │     │   ──→       │ ┃   맵 (960×480)   ┃     │
│   │     [□]       │     │             │ ┃     [□]          ┃     │
│   └───────────────┘     │             │ ┃                  ┃     │
│ ▣ corner 마커 4개 ▣     │             │ ━━━━━━━━━━━━━━━━━━      │
│ (임시 — 폐기)            │             │ corner 마커 폐기         │
└─────────────────────────┘             └─────────────────────────┘
       경계가 *추정*만 됨                    경계가 *눈에 보임*
```

**핵심 변화**: corner 마커는 1-2~1-5 동안 카메라 follow 검증용 임시물이었음. 외곽 벽이 들어오면 그 역할을 더 명확히 대체. **공간감이 처음으로 *완성*된다.**

---

## 2. 무엇을, 왜?

### 무엇을 만드나
| 만드는 것 | 한 줄 설명 |
|---|---|
| 외곽 벽 4개 (위/아래/좌/우) | `SKSpriteNode`, 두께 1타일(20pt), 맵 바깥쪽에 배치 |
| `addOuterWalls()` 신설 | `setupWorld()`가 호출. 4 벽을 worldNode 자식으로 추가 |
| corner 마커 4개 폐기 | `addCornerMarkers()` 함수 통째로 삭제 (역할이 외곽 벽으로 대체) |

### 왜 지금?
1. **Phase 1까지 *움직임*은 완성됐지만 *공간*이 추상적**. 박스가 어디서 어디까지 갈 수 있는지가 검은 영역으로만 짐작됨. 외곽 벽이 그어지면 "여기까지가 무대"라는 게 한 번에 인지됨.
2. **Phase 2 후속 작업의 기준선**. 음표/적이 스폰될 때 "맵 안 어디"라는 좌표 기준이 *눈에 보여야* 디버깅도 쉬움.
3. **corner 마커는 임시물**. 폐기 시점이 자연스럽게 외곽 벽 도입 시점과 일치.

### 무엇을 하지 않나
| 안 하는 것 | 미루는 곳 |
|---|---|
| 중앙 기둥 (GDD §6 easy 맵) | Phase 2-2 — SKPhysicsBody와 함께 |
| `SKPhysicsBody` 부착 | Phase 2-2 — 1-4 자체 클램프가 박스 갇힘 처리 중 |
| hard 맵 (모서리 방 4개) | Phase 4 (난이도 시스템과 함께) |
| 픽셀 아트 벽 텍스처 | Phase 6 |
| 새 ColorTokens 추가 | 기존 `.ganhoPaper` 활용 (1-1 자산 보존) |
| 음표 / 적 / HUD | Phase 2-2 이후 |

---

## 3. Spring 비유 🌱

### 3-1. 외곽 벽 = "도메인 경계의 시각화"
Spring으로 치면, 도메인 객체(`Order`)에 `validate()` 메서드만 있는 상태에서 → API 응답 DTO에 *유효 범위*를 명시하는 단계. PlayerNode 자체 클램프(1-4)가 *경계 검증*이고, 외곽 벽은 *경계의 시각 표현*. 검증과 표현은 별개.

| 1-4까지 | 2-1 |
|---|---|
| 박스가 맵 끝에서 멈춤 (검증) | 멈추는 자리에 벽이 *보임* (표현) |
| 사용자: "어, 더 안 가지네?" | 사용자: "아, 여기가 벽이구나" |

### 3-2. corner 마커 폐기 = 임시 코드 제거
Spring에서도 흔한 패턴: 디버깅용 `@Slf4j` 로그를 정식 코드 작성 후 정리. corner 마커는 *카메라 follow 시각 검증* 임시물이었고 외곽 벽이 정식 표현이 들어오면 자연 폐기.

> 폐기 시점이 SPEC에 명시 안 되면 코드에 영원히 남음 → 매 Phase마다 "이거 왜 있는지?" 의문. 폐기 시점을 *지금* 못 박기.

---

## 4. Swift / SpriteKit 학습 포인트 📘

### 4-1. `SKSpriteNode`로 *얇고 긴* 벽 만들기
```swift
let topWall = SKSpriteNode(
    color: .ganhoPaper,
    size: CGSize(width: GameConfig.mapWidth, height: GameConfig.tileSize)  // 가로 960, 세로 20
)
topWall.position = CGPoint(
    x: GameConfig.mapWidth / 2,                          // 가로 중앙
    y: GameConfig.mapHeight + GameConfig.tileSize / 2    // 맵 위쪽 *바로 바깥*
)
worldNode.addChild(topWall)
```

`SKSpriteNode(color:size:)`는 단색 직사각형. 두께만 다르게 4개 만들면 위/아래/좌/우 벽. 벽 위치 산수가 핵심:

| 벽 | width | height | x | y |
|---|---|---|---|---|
| 위 (top) | mapWidth | tileSize | mapWidth/2 | mapHeight + tileSize/2 |
| 아래 (bottom) | mapWidth | tileSize | mapWidth/2 | -tileSize/2 |
| 좌 (left) | tileSize | mapHeight | -tileSize/2 | mapHeight/2 |
| 우 (right) | tileSize | mapHeight | mapWidth + tileSize/2 | mapHeight/2 |

**위치 핵심**: 벽이 *맵 바깥쪽*에 두께 1tile만큼. 박스가 맵 (0~960, 0~480) 안에 갇혀있고, 그 바로 바깥에 벽이 보이는 구조.

### 4-2. `for` 루프로 4 벽 작성 (코드 중복 회피)
4개를 일일이 풀어쓰지 말고 배열 + 루프:
```swift
struct WallSpec {
    let size: CGSize
    let position: CGPoint
}
let walls: [WallSpec] = [
    WallSpec(size: ..., position: ...),  // top
    WallSpec(size: ..., position: ...),  // bottom
    // ...
]
for spec in walls {
    let wall = SKSpriteNode(color: .ganhoPaper, size: spec.size)
    wall.position = spec.position
    worldNode.addChild(wall)
}
```

Phase 1-2의 corner 마커 패턴과 동일. **반복 패턴이 보이면 즉시 루프**.

### 4-3. *함수 통째로* 삭제 (corner 마커 폐기)
```swift
private func addCornerMarkers() {
    // ... 기존 본문 ...
}
```
이 함수를 통째로 삭제 + `setupWorld()`에서 `addCornerMarkers()` 호출 한 줄도 함께 삭제. **호출부와 정의부가 같이 사라져야 dead code 0건**. 1-5에서 `clampedCameraPosition` 폐기 패턴과 동일.

### 4-4. *임시물*에 폐기 시점 명시하기 (학습)
1-2 SPEC에 corner 마커를 도입할 때 *폐기 시점*까지 명시했었음 ("Phase 2 맵 타일 도입 시"). 1-5 SPEC에서 또 한 번 "1-5 OUT — Phase 2에서 정리"라고 짚어둠. → 2-1에서 자연스럽게 폐기 가능.

> Spring에서 `// TODO: remove after migration`보다 `// REMOVE: Phase X-Y` 같이 *시점*까지 적으면 더 강력. SPEC이 그 역할을 함.

### 4-5. `.ganhoPaper` 색 재활용
| 노드 | 색 | 위치 |
|---|---|---|
| D-Pad 버튼 | `.ganhoPaper` (alpha 0.3) | cameraNode 자식 (HUD) |
| 외곽 벽 | `.ganhoPaper` (alpha 1.0) | worldNode 자식 (월드) |

같은 색을 다른 alpha로 → **D-Pad는 반투명한 UI, 벽은 솔리드한 게임 오브젝트**. 시각 계층이 자동으로 분리됨. 새 토큰 추가 없이도 일관된 톤.

---

## 5. 산출물 (예정)

### 새로 만드는 파일
**없음.**

### 수정하는 파일
| 파일 | 변경 |
|---|---|
| `GanhoMusic Shared/GameScene.swift` | (1) `addCornerMarkers()` 함수 통째로 삭제 + `setupWorld()`의 호출 한 줄 삭제, (2) `addOuterWalls()` 함수 신설 + `setupWorld()`에서 호출 |

### 절대 손대지 않는 파일
- `Nodes/PlayerNode.swift` (1-4 자체 클램프 보존, 0바이트)
- `Nodes/DPadNode.swift` (0바이트)
- `Config/GameConfig.swift` (외곽 벽 산수는 기존 상수 `mapWidth`/`mapHeight`/`tileSize`만 사용 — 새 상수 0건)
- `Config/GameState.swift`, `PhysicsCategory.swift`, `ColorTokens.swift` (0바이트)
- `iOS/AppDelegate.swift`, `SceneDelegate.swift`, `GameViewController.swift` (0바이트)
- `project.pbxproj` (0바이트)

### Xcode 멤버십
**필요 없음.** 새 .swift 파일 0건.

---

## 6. 검증 방법 ✅

### 6-1. 정량 검증
```bash
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```
- 빌드 에러 0, 경고 0
- `addCornerMarkers` 식별자 0건 (완전 폐기)
- `addOuterWalls` 함수 정의 1건, 호출 1건
- `GameConfig.cornerMarkerSize`는 GameConfig에 *그대로 존재* — 1-1 자산 보존 정책 (사용처는 0건이지만 GameConfig를 건드리지 않음)
- `!` 강제 언래핑 0건 (`fatalError` 면제)
- `Timer` / `print()` / `as!` / `fileprivate` / SKAction / SKPhysicsBody / physicsWorld 0건

### 6-2. 시각 검증 (사용자 시뮬레이터)
`⌘R` 후:
- (a) 맵 외곽에 4개 벽(연한 색 `.ganhoPaper`)이 *보임* — 맵 형체가 명확
- (b) 박스가 어느 가장자리로 가도 벽 *바로 안쪽*에서 멈춤 (1-4 자체 클램프 + 벽 시각화 일치)
- (c) corner 마커 4개(분홍) **사라짐** — 폐기됨
- (d) 박스가 항상 화면 정중앙 부근 (1-5 드론 follow 그대로)
- (e) D-Pad 우하단 고정, 작동 (1-3 그대로)
- (f) 가로 모드 강제 (Phase 0 그대로)

### 6-3. 회귀 (1-5 합격 자산 + 핫픽스)
- PlayerNode 자체 클램프 4줄 (1-4 §기능 1) 보존
- 카메라 드론 follow 한 줄 (`cameraNode.position = player.position`) 보존
- 1-3 핫픽스 `scaleMode = .resizeFill` 보존
- mapColumns=48, mapRows=24 (1-5 합격 값) 보존
- D-Pad 우하단 위치 산출 보존
- worldNode/cameraNode/player/dpad 4 인스턴스 보존

---

## 7. 사용자 결정 필요 사항 (학습 노트 단계)

### 결정 ① · 외곽 벽 색깔
| 옵션 | 시각 | 추천 |
|---|---|---|
| **A. `.ganhoPaper`** ⭐ | D-Pad와 같은 톤 — 자연스러운 통일감. alpha 1.0이라 D-Pad 0.3과 시각 계층 분리 | ⭐ — 1-1 자산 보존 |
| B. 새 색 토큰 추가 (예: 어두운 회색) | 더 묵직한 벽 느낌 | ColorTokens 수정 필요 (1-1 자산 변경) |

**왜 A?** ColorTokens.swift는 1-1 합격 자산. *수정 없이* 기존 토큰 재활용이 가장 안전. 톤 통일 보너스.

### 결정 ② · corner 마커 처리
| 옵션 | 결과 | 추천 |
|---|---|---|
| **A. 폐기** ⭐ | 외곽 벽이 역할 대체. 코드 깔끔 | ⭐ — 임시물의 자연 폐기 |
| B. 유지 | 외곽 벽 + 마커 둘 다 | 시각 노이즈 |

**왜 A?** 1-2부터 학습 노트가 corner 마커를 *임시 검증 도구*로 명시. 외곽 벽 도입 = 폐기 시점.

### 결정 ③ · 중앙 기둥 (GDD §6 easy 맵 명세)
| 옵션 | 시점 | 추천 |
|---|---|---|
| A. Phase 2-1에 포함 | 외곽 벽 + 기둥 한 번에 | 박스가 기둥 *통과*하는 어색함 |
| **B. Phase 2-2로 미룸** ⭐ | SKPhysicsBody와 함께 | ⭐ — 1 SPEC = 1 sub-feature |

**왜 B?** 중앙 기둥은 *충돌*이 본질. 시각화만 하면 박스가 통과해서 어색. SKPhysicsBody 도입(Phase 2-2)과 함께 묶는 게 자연스러움.

---

## 8. SPEC에 들어갈 핵심 제약 (Planner에게 전달)

- **변경 유형**: 비주얼 (외곽 벽 시각화)
- **게임 경험 의도**:
  > "맵 가장자리에 벽이 보인다 — 검은 우주가 끝나는 자리가 명확해진다. 박스가 어느 끝으로 가도 벽 안쪽에서 멈춘다. corner 마커는 사라지고 외곽 벽이 그 역할을 대체한다."
- **Sprint 범위 계약**:
  - **IN**: GameScene.swift 수정만 (`addCornerMarkers()` 함수 통째 삭제 + `setupWorld()` 호출 1줄 삭제, `addOuterWalls()` 신설 + `setupWorld()` 호출 1줄 추가). 정확히 1 파일.
  - **OUT**: 새 .swift 파일 / GameConfig 변경 / ColorTokens 변경 / 중앙 기둥 / SKPhysicsBody / 음표 / 적 / HUD / hard 맵
- **준수 룰**:
  - `!` 0건 (`fatalError` 면제)
  - `Timer` / `print()` / `as!` / `fileprivate` / SKAction / SKPhysicsBody / physicsWorld 0건
  - `update()` 안 `addChild()` 0건 (셋업 단계만)
  - 매직 넘버 0건 — 4 벽 산수는 모두 `GameConfig.mapWidth/mapHeight/tileSize` 조합
  - `for` 루프로 4 벽 생성 (코드 중복 회피)
  - 외곽 벽 색 = `.ganhoPaper` (alpha 1.0, 명시 불필요 = 기본값)
- **회귀 보존 (1-5 + 1-4 + 1-3 + 1-1)**:
  - PlayerNode/DPadNode/Config 4파일/iOS 3파일/pbxproj 모두 0바이트
  - 1-3 핫픽스 `scaleMode = .resizeFill` 그대로
  - `mapColumns=48`, `mapRows=24` (1-5 값) 그대로
  - 카메라 drone follow 한 줄 그대로
  - GameConfig 모든 상수 0바이트 (외곽 벽 산수는 기존 상수 재활용)

---

## 9. 회고 (작업 후 채움) 📝

### 9-1. 막혔던 것
**없었음.** 정확히 1 파일 수정 + 함수 1개 폐기 + 함수 1개 신설. 1차 빌드 통과, 회귀 10 파일 0바이트, P0 위반 0. 가장 작은 변경 단위로 큰 시각 변화를 만들어낸 사례.

### 9-2. Spring과 다르네 싶었던 것
1. **함수 *통째* 삭제 + 호출부 함께 삭제 패턴**: dead code 0건이 되려면 정의와 호출이 동시에 사라져야 함. 1-5의 `clampedCameraPosition` 폐기 패턴 재사용.
2. ***임시물*에 폐기 시점을 SPEC에 미리 명시**: corner 마커는 1-2 도입 시 학습 노트에 "Phase 2 맵 타일 도입 시 폐기" 명시. 1-5에서도 OUT 항목으로 짚어둠 → 2-1에서 자연스러운 폐기. Spring `// TODO`보다 *시점*까지 적는 게 강력함을 다시 확인.
3. **`.ganhoPaper` 토큰 재활용 + alpha로 시각 계층 분리**: D-Pad는 alpha 0.3, 외곽 벽은 1.0 — 같은 색인데 자연스럽게 *UI vs 월드*가 분리됨. 새 ColorTokens 추가 안 해도 되고 1-1 자산 보존.
4. **`WallSpec` *지역* 구조체 패턴**: 함수 안에서만 쓰는 struct는 함수 안에 정의. 외부 파일/폴더(`Models/` 같은)로 분리하지 않는 게 응집도 ↑. Java로 치면 *익명 inner class*에 가까움.
5. **벽 위치 산수의 mental check**: top wall y = `mapH + halfT` → 벽 *바닥*이 mapH에 닿고 *위쪽*이 mapH+t. 좌표가 노드 *중심* 기준이라는 SpriteKit 관습을 매번 확인 필요. 1-4 자체 클램프 산수와 같은 mental model.
6. **`for spec in walls` 패턴**: 1-2 corner 마커 패턴(`for point in positions`)과 일관. 4번 풀어쓰기 vs 루프의 차이 — 코드 줄 수는 비슷하지만 *추가 벽이 생길 때* 루프가 한 줄만 추가하면 됨.

### 9-3. 다음 작업으로 이월된 결정 (Phase 2-2 진입 시)
1. **SKPhysicsBody 도입**: 중앙 기둥 추가 시 박스가 통과하면 어색 → SKPhysicsBody가 충돌 처리. 외곽 벽도 PhysicsBody 부착하면 1-4 자체 클램프와 *이중 안전망*. 정책 충돌 가능성 검토 필요 (자체 클램프 유지 vs 제거).
2. **중앙 기둥 시각화 + 충돌**: GDD §6 easy 맵 명세 ("외곽 벽 + 중앙 기둥 1개, 2×4타일"). 위치는 맵 정중앙(mapW/2, mapH/2)에 width=2tile, height=4tile.
3. **`PhysicsCategory` 활용**: 1-1에 정의된 `player`/`note`/`enemy`/`wall` 비트마스크를 처음으로 사용. 1-1 자산이 *드디어* 활성화.
4. **벽도 PhysicsBody 부착 시 .ganhoPaper 잔존**: Phase 2-2에서 벽이 PhysicsBody를 가지면 외곽 벽은 *충돌 + 시각* 둘 다 담당. 본 2-1의 시각 표현은 그대로 보존 가능.
5. **PlayerNode 자체 클램프 → SKPhysicsBody collisionBitMask로 대체 검토**: 자체 클램프 4줄(1-4)이 PhysicsBody가 들어오면 중복일 수도. 검토 후 결정 — 안전망으로 둘 다 유지하는 게 보통.

### 9-4. 평가 점수 (QA_REPORT.md 기준)
- Swift 패턴 (35%): **9.5 / 10** — `for` 루프 / `WallSpec` 지역 struct / private / MARK 모두 정석
- 게임 로직 (30%): **10 / 10** — SPEC §기능 1~2 1바이트 일치, 폐기·신설 깔끔
- 성능 (20%): **10 / 10** — `update()` 안 노드 생성 0, 빌드 클린
- 기능 완성도 (15%): **10 / 10** — `BUILD SUCCEEDED`, P0 위반 0
- **가중평균: 9.83 / 10 — 합격 (Phase 1~2 통틀어 최고점)**

### 9-5. 사용자가 직접 확인할 것 ✅
시뮬레이터 `⌘R` 후 6가지:
- (a) 맵 외곽에 4개 벽 (`.ganhoPaper` 색, alpha 1.0 솔리드) — 위/아래/좌/우
- (b) 박스가 어느 가장자리로 가도 벽 안쪽에서 멈춤 (1-4 자체 클램프 + 벽 시각화 일치)
- (c) corner 마커 4개(분홍) **사라짐** ← Phase 2-1 핵심 변화 1
- (d) 박스가 항상 화면 정중앙 부근 (1-5 드론 follow 그대로)
- (e) D-Pad 우하단 고정, 작동 (1-3 그대로)
- (f) 가로 모드 강제 (Phase 0 그대로)

> **추가 관찰 포인트**: 박스가 맵 가장자리에 가까워지면 벽이 화면에 들어와 *맵 끝* 신호가 자연스러움. 1-5의 "검은 영역 살짝 보임"보다 더 명확한 경계.

---

## 10. 다 읽었다면 다음은?

```
[1] §7 결정 3건 사용자 OK
[2] rm -f SPEC.md SELF_CHECK.md QA_REPORT.md
[3] Planner   → SPEC.md
[4] Generator → GameScene 수정 + SELF_CHECK.md
[5] Evaluator → QA_REPORT.md
[6] 합격 시 §9 회고 채우고 → Phase 2-2 (중앙 기둥 + SKPhysicsBody)로
```
