# 자체 점검 — Phase 2-5 콤보 시스템 + 점수 ×2

전략: Case A (1회차) — SPEC.md를 정밀 적용. 별도 전략 분기 없음.

---

## SPEC §기능 1~5 구현 위치 (파일:라인)

### 기능 1: 콤보 카운터 + 윈도우 만료
- Properties (combo 변수): `GanhoMusic Shared/GameScene.swift:28`
- Properties (lastCollectAt 변수): `GanhoMusic Shared/GameScene.swift:29`
- update(_:) 만료 검사 블록: `GanhoMusic Shared/GameScene.swift:209-212`
  - 위치: 카운트다운(L204-207) **다음**, player 갱신(L215) **전** — 명세 준수
- 가드: `combo > 0` (L210) → `lastCollectAt = 0` 초기값 안전 처리

### 기능 2: didBegin 콤보 갱신 + 점수 분기
- 구현: `GanhoMusic Shared/GameScene.swift:284-291`
- 시점 변수: `let now = lastUpdateTime` (L284) — `lastUpdateTime` 재활용, 신규 시점 변수 0
- isInWindow 계산: `combo > 0 && now - lastCollectAt < GameConfig.comboWindow` (L285)
- combo 갱신: 삼항 연산자 (L286)
- score 분기: 삼항 연산자 줄바꿈 들여쓰기 정렬 (L287-289)
- lastCollectAt 갱신: L290
- 노드 제거: `note.run(.removeFromParent())` (L291) — 마지막 그대로 유지

### 기능 3: HUDNode 콤보 라벨 (조건부 표시)
- Properties (`comboLabel`): `GanhoMusic Shared/Nodes/HUDNode.swift:19`
- init 라벨 초기화: `GanhoMusic Shared/Nodes/HUDNode.swift:25`
- init configure 호출: `GanhoMusic Shared/Nodes/HUDNode.swift:29`
- init position: `GanhoMusic Shared/Nodes/HUDNode.swift:33` (`-hudFontSize * 1.4 * 2`)
- init addChild: `GanhoMusic Shared/Nodes/HUDNode.swift:36`
- update 시그니처: `GanhoMusic Shared/Nodes/HUDNode.swift:46`
- update 라벨 갱신: `GanhoMusic Shared/Nodes/HUDNode.swift:50-51`
  - `comboLabel.text = "🔥 \(combo)"` (L50)
  - `comboLabel.alpha = combo >= 2 ? GameConfig.hudAlpha : 0` (L51)
- `configure(_:)` 헬퍼 본문: 0 변경 (L56-63)

### 기능 4: GameConfig 콤보 상수 4개
- 새 MARK 섹션 + 4 상수: `GanhoMusic Shared/Config/GameConfig.swift:72-80`
  - L72: `// MARK: - Combo (Phase 2-5)` (HUD 섹션 직후)
  - L74: `comboWindow: TimeInterval = 2.5`
  - L76: `comboBonusThreshold: Int = 3`
  - L78: `scorePerNote: Int = 1`
  - L80: `scorePerNoteCombo: Int = 2`

### 기능 5: endGame HUD 인자 확장 + 콤보 라벨 비활성화
- 구현: `GanhoMusic Shared/GameScene.swift:302`
- `hud.update(score: score, remainingTime: 0, combo: 0)` — `combo: 0`로 alpha 0 강제
- 다른 4줄(L298-301: gameState/removeAction/currentDirection/velocity) 그대로

---

## P0 룰 grep 결과 (0건 항목)

| 룰 | 결과 |
|---|---|
| 강제 언래핑 `!` (fatalError 면제) | **0건** (3 파일 검색) |
| `Timer` 사용 | **0건** (단 1건은 "Timer 금지 룰 준수" 주석) |
| `print()` | **0건** |
| `as!` | **0건** |
| `fileprivate` | **0건** |
| `DispatchQueue.main.asyncAfter` | **0건** |
| `update(_:)` 안 `addChild()` | **0건** (콤보 라벨 addChild는 HUDNode init L36) |

---

## 회귀 보존 10 파일 mtime 0건 변경 확인

수정 전후 mtime 비교 (모두 일치):

| 파일 | mtime |
|---|---|
| `Nodes/PlayerNode.swift` | 1778048094 (변경 0) |
| `Nodes/DPadNode.swift` | 1778033228 (변경 0) |
| `Nodes/NoteNode.swift` | 1778048078 (변경 0) |
| `Config/PhysicsCategory.swift` | 1777879822 (변경 0) |
| `Config/GameState.swift` | 1777879818 (변경 0) |
| `Config/ColorTokens.swift` | 1777879830 (변경 0) |
| `iOS/AppDelegate.swift` | 1777725506 (변경 0) |
| `iOS/SceneDelegate.swift` | 1777863711 (변경 0) |
| `iOS/GameViewController.swift` | 1777798214 (변경 0) |
| `GanhoMusic.xcodeproj/project.pbxproj` | 1778050863 (변경 0) |

→ **신설 파일 0건** → Xcode 멤버십 trigger 안 됨 → `project.pbxproj` 0바이트 변경 확정.

---

## 주요 식별자 등장 횟수

| 식별자 | GameConfig | HUDNode | GameScene | 합계 | SPEC 요구 |
|---|---|---|---|---|---|
| `combo` | 2 | 8 | 9 | **19** | ≥ 6 ✅ |
| `comboWindow` | 1 | 0 | 2 | **3** | ≥ 2 ✅ |
| `comboBonusThreshold` | 1 | 0 | 1 | **2** | 1 ✅ |
| `scorePerNote` | 1 | 0 | 1 | **2** | 1 ✅ |
| `scorePerNoteCombo` | 1 | 0 | 1 | **2** | 1 ✅ |

(GameConfig는 정의 1건 + 주석/MARK 등 부수 등장. SPEC 요구 횟수는 모두 충족.)

---

## 빌드 결과

```
xcodebuild -project /Users/hg/Desktop/ganho-music-ios/GanhoMusic/GanhoMusic.xcodeproj \
           -scheme "GanhoMusic iOS" \
           -destination 'platform=iOS Simulator,name=iPhone 17' build
...
** BUILD SUCCEEDED **
```

빌드 경고 0건 (변경 영역). 컴파일 에러 0건.

---

## 매직 넘버 표현 방식

| 원래 값 | 표현 방식 | 위치 |
|---|---|---|
| 2.5 | `GameConfig.comboWindow` | GameScene:210, GameScene:285 |
| 3 | `GameConfig.comboBonusThreshold` | GameScene:287 |
| 1 | `GameConfig.scorePerNote` | GameScene:289 |
| 2 | `GameConfig.scorePerNoteCombo` | GameScene:288 |
| `1.4 * 2` | 자명한 산수 (3번째 줄 = 줄간격×2) | HUDNode:33 |
| `>= 2` (콤보 라벨 표시 임계) | 인라인 정수 리터럴 (1콤보=일반수집, 2부터 등장) | HUDNode:51 |

`hudFontSize * 1.4 * 2`는 SPEC에서 자명한 산수로 명시. `>= 2`는 GDD §8 콤보 라벨 표시 정책의 자명한 임계치 (별도 상수화 시 의미 분산).

---

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (3 파일 검색 0건, fatalError 면제)
- guard let 옵셔널 처리: **준수** (`guard let note = noteBody?.node else { return }` 그대로 유지)
- MARK 섹션 구분: **준수** (`// MARK: - Combo (Phase 2-5)` 신규, 기존 함수 단위 MARK 0 변경)
- GameConfig 상수 사용: **준수** (2.5/3/1/2 모두 상수 추출)
- weak self 캡처: **해당 없음** (Phase 2-5 클로저 0개 신규. spawn loop의 `[weak self]`는 그대로)
- Optional 회피 패턴: **준수** (`lastCollectAt: TimeInterval = 0` + `combo > 0` 가드)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: **준수** (변경 없음)
- dt 기반 이동: **준수** (변경 없음)
- SKAction 스폰 패턴: **준수** (변경 없음)
- 충돌 후 노드 즉시 삭제 없음: **준수** (`note.run(.removeFromParent())` 그대로 유지)
- HUD 노드 분리: **준수** (cameraNode 자식 구조 유지)
- update 안 addChild 0건: **준수** (콤보 라벨 addChild는 HUDNode init만)
- 콤보 라벨 alpha 분기: **준수** (`isHidden` 토글 회피로 트리 갱신 비용 0)

---

## 변경 LOC 추정

| 파일 | +추가 | -삭제 | 순증 |
|---|---|---|---|
| `Config/GameConfig.swift` | 10 | 0 | +10 |
| `Nodes/HUDNode.swift` | 6 | 1 | +5 |
| `GanhoMusic Shared/GameScene.swift` | 13 | 3 | +10 |
| **합계** | **29** | **4** | **+25** |

(교체된 줄: HUDNode update 시그니처 1줄, GameScene `score += 1` 1줄, GameScene endGame `hud.update` 1줄 → SPEC 명세대로)

---

## 범위 외 미구현 항목

OUT 영역 모두 미구현(SPEC 준수):

- 사운드 (콤보 단계별 음계 C4→A5) — Phase 2-7 후속
- 콤보 시각 강조 (펄스/색 변화/페이드아웃) — Phase 3 후속
- Best 콤보 / UserDefaults — Phase 3 후속
- 화캉스 보너스 (변기, 콤보 +2) — Phase 3+ 후속
- 임간호 스킬 A 수집 점수 ×2 — Phase 3+ 후속
- 적 NPC, F 투사체, 청진기 — Phase 3+ 후속
- `Systems/` 폴더 신규 진입 — 본 Phase는 GameScene 안 직접 구현

회귀 보존 10 파일 0바이트 변경, `project.pbxproj` 0바이트 변경 모두 확정.
