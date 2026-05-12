# 자체 점검 — Phase 6-1 HapticsManager

전략: 1회차 — Phase 6 첫 진입 (Case 미적용)

---

## 1. 변경 파일 목록 (신규 1 + 수정 2 = 3개)

| # | 경로 | 변경 | 라인 변화 |
|---|---|---|---|
| 1 | `GanhoMusic/GanhoMusic Shared/Managers/HapticsManager.swift` | **신규** | +43 |
| 2 | `GanhoMusic/GanhoMusic Shared/GameScene.swift` | 수정 | +4 (헤더 1 + 본체 3) |
| 3 | `GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj` | 수정 | +13 (5곳) |

### diff 요약

**HapticsManager.swift (신규 43줄)**:
- `import UIKit`
- `final class HapticsManager`
- 프로퍼티 2개: `lightGenerator`, `heavyGenerator` (둘 다 `UIImpactFeedbackGenerator`)
- `init()`: 두 generator 초기화 + 둘 다 `prepare()` 워밍
- `light()`: `impactOccurred()` + 재워밍
- `heavy()`: `impactOccurred()` + 재워밍
- SPEC §기능1 코드와 1:1 일치 (강제 언래핑 0, 옵셔널 0)

**GameScene.swift (+4줄)**:
1. 헤더 주석 1줄 추가: `//  Phase 6-1 · HapticsManager 신설 + 노트 수집/게임오버 햅틱 트리거 2지점`
2. 시스템 섹션 `statsRepo` 다음 줄: `let haptics = HapticsManager()              // Phase 6-1 — 손맛 강화 (Manager 패턴 첫 등장)`
3. `configureContactRouter()`의 `onNoteCollected` 콜백 안 (`recordNoteHit` 다음, `note.run` 이전): `self.haptics.light()   // Phase 6-1 — 수집 손맛`
4. `endGame()`의 `gameState = .gameOver` 다음 줄 (`spawnSystem.stop()` 이전): `haptics.heavy()   // Phase 6-1 — 종료 무게감 (가드 통과 1회만)`

---

## 2. SPEC In Scope 4항목 충족

| # | In Scope 항목 | 충족 |
|---|---|---|
| 1 | HapticsManager 신설 (UIKit / final class / light·heavy generator + prepare 워밍) | ✅ §기능1 코드 그대로 |
| 2 | GameScene 프로퍼티 1줄 (`let haptics = HapticsManager()`) | ✅ statsRepo 다음 줄 |
| 3 | `onNoteCollected` 콜백 `haptics.light()` (recordNoteHit 다음, note.run 이전) | ✅ 위치 정확 |
| 4 | `endGame()` `haptics.heavy()` (`gameState = .gameOver` 다음 줄, `spawnSystem.stop()` 이전) | ✅ 멱등 가드 통과 후 |

---

## 3. Out of Scope 위반 0건

### GameScene.swift 다른 메서드 — 0건 변경
git diff로 확인됨. `init` / `required init?` / `newGameScene` / `didMove` / `didChangeSize` / `layoutDPad` / `layoutHUD` / `update` / `triggerAirforceEasterEgg` / `endGame`의 멱등 가드 외 부분 모두 손대지 않음.

### configureContactRouter의 다른 4 콜백 — 0건 변경
`onEnemyHit` / `onProjectileHitPlayer` / `onProjectileHitWall` / `onStoneGuardContact` 모두 원본 그대로.

### 다른 파일 — 0건 변경
git diff stat:
- TitleScene/ResultScene/HUDNode/PlayerNode/CharacterCardNode/Systems(3)/Repositories(3)/Models(2)/Protocols/Config(4)/GameScene+Setup 모두 변경 0줄
- macOS/tvOS Sources phase 비어있는 그대로

### 금지 사항 — 0건
- 사운드(AVFoundation) 미도입
- medium/rigid/soft 햅틱 미도입
- 콤보 마일스톤 / 이스터에그 햅틱 미도입
- DI mock 미도입
- 음소거 옵션 미도입
- GameConfig 새 상수 0건
- Repository 영속 저장 미연결

---

## 4. pbxproj 5 엔트리 실제 추가 라인 컨텍스트

ID 충돌 grep 사전 확인 결과:
- `A1C0F1B00000000000000025`: 0건
- `A1C0F1A00000000000000025`: 0건
- `A1C0F2000000000000000017`: 0건
→ 모두 미사용 ID, +1 재시도 불필요.

### (1) PBXBuildFile section
```
A1C0F1B00000000000000024 /* CharacterPreferenceRepository.swift in Sources */ = ...
+ A1C0F1B00000000000000025 /* HapticsManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000025 /* HapticsManager.swift */; };
A1C0F1B00000000000000017 /* StoneGuardNode.swift in Sources */ = ...
```

### (2) PBXFileReference section
```
A1C0F1A00000000000000024 /* CharacterPreferenceRepository.swift */ = ...
+ A1C0F1A00000000000000025 /* HapticsManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HapticsManager.swift; sourceTree = "<group>"; };
A1C0F1A00000000000000017 /* StoneGuardNode.swift */ = ...
```

### (3) 신규 PBXGroup `Managers` (Protocols 직후)
```
A1C0F1F00000000000000016 /* Protocols */ = { ... };
+ A1C0F2000000000000000017 /* Managers */ = {
+     isa = PBXGroup;
+     children = (
+         A1C0F1A00000000000000025 /* HapticsManager.swift */,
+     );
+     name = Managers;
+     path = "GanhoMusic Shared/Managers";
+     sourceTree = "<group>";
+ };
C75D461B2FA627C10016BB86 = { ... mainGroup ... };
```

### (4) 루트 mainGroup children (Protocols 뒤, GanhoMusic iOS 앞)
```
A1C0F1F00000000000000016 /* Protocols */,
+ A1C0F2000000000000000017 /* Managers */,
C75D462B2FA627C20016BB86 /* GanhoMusic iOS */,
```

### (5) iOS PBXSourcesBuildPhase files (CharacterCardNode 뒤)
```
A1C0F1B00000000000000023 /* CharacterCardNode.swift in Sources */,
+ A1C0F1B00000000000000025 /* HapticsManager.swift in Sources */,
);
runOnlyForDeploymentPostprocessing = 0;
```
**macOS/tvOS Sources phase는 빈 채로 유지** (`C75D46362FA627C20016BB86` / `C75D46462FA627C20016BB86` 모두 files=() 그대로).

---

## 5. 빌드 결과

```
xcodebuild -project "GanhoMusic/GanhoMusic.xcodeproj" \
  -scheme "GanhoMusic iOS" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

- **BUILD SUCCEEDED** ✅
- `grep -E "warning:|error:" | grep -v "AppIntents"`: **0줄** ✅
- AppIntents 경고는 빈 framework 의존성 관련 자동 메시지로 SPEC 9번 주의사항에 명시된 무시 가능 항목.

---

## 6. 검증 시나리오 (a)~(h) 정적 추적

### (a) 빌드 클린
- BUILD SUCCEEDED, warning/error 0건 확인 (위 5번)
- `Cannot find 'HapticsManager' in scope` 미발생 — pbxproj 5곳 정합

### (b) 시뮬레이터 noop
- `UIImpactFeedbackGenerator`는 iOS 시스템 API, 시뮬레이터에서 자동 무시
- 게임 진행/스코어/HUD 모두 동일 동작 (이번 sprint는 진동 호출 외 로직 0건 추가)

### (c) 실기기 라이트 햅틱
- `onNoteCollected` 콜백은 NoteNode와 PhysicsContact 발생 시마다 호출
- `recordNoteHit` 직후 `haptics.light()` → 매 수집마다 1회
- `prepare()` 재워밍 → 연속 수집 시 끊김 방지 (SPEC §결정3)

### (d) 실기기 헤비 햅틱 — 3경로
1. **45초 만료**: `update()` → `remainingTime <= 0` → `endGame()` → 가드 통과 → `haptics.heavy()`
2. **적 접촉**: `onEnemyHit` 콜백 → `endGame()` → 가드 통과 → `haptics.heavy()`
3. **F 피격**: `onProjectileHitPlayer` 콜백 → `endGame()` → 가드 통과 → `haptics.heavy()`

세 경로 모두 동일 `endGame()` 진입 → 동일 `haptics.heavy()` 1회.

### (e) 멱등 가드 회귀 ⭐
```swift
private func endGame() {
    if gameState == .gameOver { return }   // 가드 — 두 번째 호출 즉시 return
    gameState = .gameOver                  // ← 첫 호출만 여기까지 옴
    haptics.heavy()                        // ← 가드 *뒤*에 있어 첫 호출만 트리거
    spawnSystem.stop()
    ...
}
```
F 피격 + 적 접촉 동시 발생 → 두 콜백 모두 `endGame()` 호출 → 첫 호출만 `gameState = .gameOver` 통과 + 헤비 햅틱 1회 → 두 번째는 가드에서 즉시 return → **헤비 햅틱 2회 트리거 안 됨**. ResultScene presentScene도 가드 뒤에 있어 1회만 호출 (기존 Phase 3-3 보장 유지).

햅틱을 가드 *앞*에 넣었다면 중복 발화 위험이 있었을 것 — SPEC §결정4와 정확히 일치.

### (f) Phase 4 회귀 (AIRFORCE)
- `triggerAirforceEasterEgg()` 내부에 `endGame()` 호출 0건 (확인: GameScene.swift 라인 220~236)
- StoneGuard 첫 접촉 → 비행기/오버레이/폭탄/도주/F 재스폰 발화 → heavy 햅틱 트리거 안 됨 ✅
- airforceTriggered 가드 / AirplaneNode / AirforceOverlayNode / BombFlashNode / enemy.startFleeing / spawnSystem.fireImmediately — 모두 원본 그대로 ✅

### (g) Phase 5 회귀 (캐릭터)
- characterID stored property: 원본 그대로 (라인 68)
- init(size:characterID:): 원본 그대로 (라인 73~76)
- newGameScene(characterID:) factory: 원본 그대로 (라인 83~87)
- HUD 우상단 이름 / ResultScene characterName 전달: 원본 그대로 (라인 264~267)
- 노트 수집 시 light 햅틱은 캐릭터 무관 (`onNoteCollected` 콜백 내 분기 없음) ✅

### (h) Out of Scope 회귀
`git diff --stat`:
```
GanhoMusic/GanhoMusic Shared/GameScene.swift    | +4
GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj | +13
신규: GanhoMusic/GanhoMusic Shared/Managers/HapticsManager.swift
```
정확히 SPEC 명세 3개 파일만 변경, 다른 Swift 파일 0건 변경 ✅

---

## 7. docs/learn/phase-6-1-haptics-manager.md 학습 노트

작성 완료 (절대경로):
`/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/affectionate-elion-d0363a/docs/learn/phase-6-1-haptics-manager.md`

### 주요 비유 매핑

| 개념 | Spring 비유 | 중학생 비유 |
|---|---|---|
| Manager 패턴 | `@Service` 빈 (이메일 발송 같은 행동 전담) | "진동 담당 상자" |
| Repository vs Manager | `@Repository`(상태) vs `@Service`(행동) | "데이터 적기 vs 부르릉 떨기" |
| prepare() 워밍 | 캐시 워밍 (서버 뜨자마자 데이터 미리 올리기) | "시동 미리 걸어두기" |
| light/heavy enum case | 다형성 (같은 인터페이스, 다른 구현) | "톡 vs 툭, 같은 동작 다른 느낌" |
| 멱등 가드 | 트랜잭션 idempotent 보장 | "두 번 눌러도 한 번만 실행되는 자물쇠" |

전문용어 최소화, 일상 비유(시동 걸기, 모터, 상자) 우선 — `docs/learn/STYLE.md` 톤 준수.

---

## Swift 패턴 준수 체크
- 강제 언래핑(`!`) 미사용: **준수** (HapticsManager 내 옵셔널 0)
- `guard let` / `if let` 옵셔널 처리: **준수** (기존 `onNoteCollected`의 `guard let self`, `endGame`의 `guard let view` 그대로)
- `MARK:` 섹션 구분: **준수** (HapticsManager에 `MARK: - Properties` / `MARK: - Init` / `MARK: - Triggers` 3구역)
- `GameConfig` 상수 사용: **해당 없음** (SPEC §주의사항3 — 강도는 enum case로 충분, 새 상수 0)
- `weak self` 캡처: **준수** (기존 `onNoteCollected`의 `[weak self]` 캡처에 진동 호출 1줄만 추가, 패턴 변경 0)

## SpriteKit 패턴 준수 체크
- `didMove(to:)`에서 초기화: **해당 없음** (HapticsManager는 stored property로 GameScene init과 동시 생성)
- `dt` 기반 이동: **해당 없음** (이번 sprint는 이동 로직 변경 0)
- `SKAction` 스폰 패턴: **해당 없음** (Timer 도입 0, 지연 호출 0)
- 충돌 후 노드 즉시 삭제 없음: **준수** (기존 `note.run(.removeFromParent())` 패턴 유지, 햅틱 호출은 그 *전*에 위치)
- HUD 노드 분리: **해당 없음**

## 빌드 상태
- 예상 빌드 에러: **없음** (BUILD SUCCEEDED 확인됨)
- 주의 필요 경고: **없음** (AppIntents 무시 후 0줄)

## 범위 외 미구현 항목
- **없음**. SPEC §Out of Scope 모든 항목 미접촉.
