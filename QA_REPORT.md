# QA 검수 보고서 — Phase 6-11

## SPEC 기능 검증

- **PASS — 기능 1: AudioManager.SFX 케이스 2개 추가**
  - `comboMilestoneSoft`, `comboMilestoneStrong` 케이스가 `enum SFX`에 추가됨 (`AudioManager.swift:23-24`).
  - `fileName` switch: 두 케이스 모두 `nil` 반환 (line 32-33) → systemSoundID 폴백 경로 자동 사용.
  - `systemSoundID` switch: `comboMilestoneSoft=1057` (Tink, 노트 수집과 연장선), `comboMilestoneStrong=1025` (NewMail, 묵직하지만 긍정) — SPEC §"기능 1" 매핑과 일치 (line 45-46).
  - `allCases` 배열 4개로 확장됨 (line 69). `for` 루프에서 `fileName==nil` 케이스는 `guard let name` 가드로 자동 continue → 회귀 0.

- **PASS — 기능 2: HapticsManager.medium() 추가**
  - `mediumGenerator` 프로퍼티 추가 (line 21), `init`에서 `.medium` 스타일 인스턴스화 + `prepare()` 워밍 (line 27, 31).
  - `medium()` 메서드 (line 44-47): `impactOccurred()` → `prepare()` 패턴 — `light()`/`heavy()`와 100% 동형. 인덴트·코멘트 구조까지 대칭.
  - 헤더 docstring에도 `medium()` 라인 추가 (line 13).

- **PASS — 기능 3: GameScene helper `playComboMilestoneFeedback(for:)`**
  - GameScene **private** 메서드로 추가 — 옵션 A 채택 정확히 반영 (line 272-288).
  - 위치: `// MARK: - Combo Milestone Feedback (Phase 6-11)` 섹션이 `// MARK: - Easter Egg` 바로 앞 (line 262). MARK 위계 자연.
  - 4-way switch + graceful default: 3/5 → `light()+.comboMilestoneSoft`, 10 → `medium()+.comboMilestoneSoft`, 20 → `heavy()+.comboMilestoneStrong`, default → `light()+.comboMilestoneSoft`. SPEC §"기능 3" 매핑 표와 1:1 일치.

- **PASS — 기능 4: 가드 안쪽 통합**
  - 멱등성 가드(line 243-244) **안쪽**에 `self.playComboMilestoneFeedback(for: currentCombo)` 1줄 prepend (line 250).
  - 6-10 기존 3줄(ComboPopupNode 생성 → cameraNode 부착 → animate)이 위치 그대로 유지 (line 251-253). 회귀 0.
  - 호출 순서: 햅틱 → 사운드 (helper 내부) → 시각 (애니메이션) — 촉각→청각→시각 시간축 일관.
  - 헤더 주석에 `Phase 6-11` 한 줄 추가 (line 36).

## 빌드 검증

- **결과: BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 컴파일 경고: 0건
- 컴파일 에러: 0건

## Sprint 회귀 0 — 20개 영역 검증

`git diff --name-only HEAD` 결과 변경된 Swift 파일은 **3개뿐**:
```
GanhoMusic/GanhoMusic Shared/GameScene.swift
GanhoMusic/GanhoMusic Shared/Managers/AudioManager.swift
GanhoMusic/GanhoMusic Shared/Managers/HapticsManager.swift
```

미접촉 확인:
- ScoreSystem / ContactRouter / SpawnSystem / CameraShakeAction — `Systems/` 0건
- HUDNode / PlayerNode / EnemyNode / NoteNode / ProjectileNode / StoneGuardNode / DPadNode / AirplaneNode / AirforceOverlayNode / BombFlashNode / HitFlashNode / SparkleEffectNode / CharacterCardNode / **ComboPopupNode** — `Nodes/` 0건 (특히 ComboPopupNode 시각 코드 미접촉)
- BGMPlayer — `Managers/BGMPlayer.swift` 0건
- Repositories (HighScore/Statistics/CharacterPreference) — `Repositories/` 0건
- Models (GameStats, CharacterID) — `Models/` 0건
- Protocols (SelfDismissingNode) — `Protocols/` 0건
- TitleScene / ResultScene — `Scenes/` 0건
- ColorTokens / GameConfig (특히 `comboMilestones` 배열) / PhysicsCategory / GameState — `Config/` 0건
- `GameScene+Setup.swift` 0건
- `*.pbxproj` 0건 (신규 파일 0개라 등록 변경 불필요 — Phase 6-10과 결이 다름)

## `triggeredComboMilestones` Set 정책 검증

GameScene 내 4지점 모두 6-10 패턴 유지:
- Line 79: `private var triggeredComboMilestones: Set<Int> = []` — 선언 + 자동 리셋 (인스턴스 라이프사이클)
- Line 244: 가드 조건 `!self.triggeredComboMilestones.contains(currentCombo)`
- Line 245: 가드 통과 시 `insert(currentCombo)`
- Line 248: 신규 주석에서 변수명 언급만

`removeAll()` 호출 0건 — `endGame()` / `didMove(to:)` 어디에도 추가되지 않음. **Set의 위치/의미/리셋 정책 변경 0건**.

## AudioManager exhaustive switch 검증

`grep -n "default:" AudioManager.swift` → 출력 0줄.
- `fileName` switch: 4 케이스 exhaustive, default 없음
- `systemSoundID` switch: 4 케이스 exhaustive, default 없음
6-2 정책(컴파일러가 새 케이스 누락 강제 검출) 유지.

(참고: GameScene의 `playComboMilestoneFeedback`는 `Int` 입력이라 exhaustive 불가 → graceful fallback `default` 의도적 포함. SPEC §"기능 3"의 명시 정책과 일치.)

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## Swift 패턴 검증

- 강제 언래핑(`!`) 신규 도입: **0건** (변경 라인 grep 결과 깨끗)
- `Timer` / `DispatchQueue` 사용: 0건
- 매직 넘버: AudioManager의 1025/1057 시스템 사운드 ID는 SPEC §"주의사항"에 따라 Apple 도메인 상수로 enum 내부에 유지 — 정책 일관(GameConfig로 옮기지 않음이 옳음)
- `guard let` / `if let` 옵셔널 처리: AudioManager init 내 `guard let name`, `guard let url`, `guard let player` 3단 가드 유지
- `[weak self]` 캡처: 기존 `onNoteCollected` 클로저 시그니처 변경 0건. helper는 `self.` 명시 호출 (이미 unwrap된 컨텍스트)
- `MARK:` 섹션: 신규 `// MARK: - Combo Milestone Feedback (Phase 6-11)` 추가 — Easter Egg/Game State 앞에 자연 위치
- 네이밍: `comboMilestoneSoft` / `comboMilestoneStrong` / `mediumGenerator` / `medium()` / `playComboMilestoneFeedback` 모두 lowerCamelCase
- 함수 단일 책임: helper 28줄 — 마일스톤→피드백 분기만 담당

## SpriteKit 패턴 검증

- 신규 SKAction / SKNode 생성: 0건 (사운드/햅틱은 매니저 호출만 — SPEC 금지 항목 준수)
- 충돌 콜백 내 즉시 노드 삭제: 없음. helper는 부수효과(haptic/audio)만 호출, `note.run(.removeFromParent())`는 기존 SKAction 경유 패턴 그대로 유지 (line 255)
- HUD 노드 분리: HUDNode 변경 0건
- `didMove(to:)` 초기화 / dt 기반 이동 / SKAction 스폰 / PhysicsCategory: 본 sprint 미접촉 영역

## 성능 검증

- `prepare()` 캐시 워밍: HapticsManager init에서 mediumGenerator.prepare() 1회 + `medium()` 호출 직후 1회 — light/heavy와 동형 패턴. 첫 트리거 지연 최소화 정책 일관
- AudioManager 캐시: `players[SFX: AVAudioPlayer]` 캐시 구조 유지. fileName==nil인 신규 케이스는 캐시에 들어가지 않고 systemSoundID 폴백 — 메모리 0
- AVAudioSession 카테고리: 변경 0건. BGMPlayer의 .playback 덮어쓰기 순서 영향 없음 (SPEC §"주의사항" 정합)

## 호출 순서 검증 (촉각→청각→시각)

`onNoteCollected` 가드 안쪽 (line 245-253):
1. `self.playComboMilestoneFeedback(for: currentCombo)` — 햅틱(촉각) → 사운드(청각)
2. `ComboPopupNode` 생성/addChild/`animate()` — 시각

인간 지각 시간축(0~10ms → ~30ms → 60ms+)과 코드 라인 순서 일치. 6-2 학습 노트 §"코드 순서: 햅틱→사운드" 정책 답습.

## 통과 항목

- SPEC §"Sprint 범위 계약" 6개 허용 항목 중 5개 정확히 구현, 1개(GameConfig 하단 상수)는 SPEC §"기능 3" 결정 옵션 A 채택으로 자연 미사용
- SPEC §"금지" 7개 항목 모두 준수 (ComboPopupNode 시각 미접촉, 회귀 0 영역 20개 미접촉, comboMilestones 배열 미변경, 새 SKAction/SKNode 0건, Set 가드 위치/의미 미변경, BGM 로직 미변경, GameConfig 미수정)
- 멱등성 — 같은 콤보 마일스톤에 햅틱/사운드/시각 1회만 발화 (Set 가드 안쪽 발화 보장)
- `print()` 디버그 코드 0건

---

## 채점

**항목별 점수**:
- Swift 패턴 일관성: **10/10** → MARK 신설, lowerCamelCase, guard let, exhaustive switch, `[weak self]` 유지, helper 단일 책임 — P2 수준 불일치도 0건
- 게임 로직 완성도: **10/10** → 멱등성 가드 안쪽 발화로 1회 보장, 호출 순서(촉각→청각→시각) SPEC 정책과 정확히 일치, 회귀 0 영역 20개 완전 미접촉
- 성능 & 안정성: **10/10** → BUILD SUCCEEDED + 경고 0, 강제 언래핑 0건, `prepare()` 캐시 워밍 light/heavy와 동형 적용, AVAudioPlayer 캐시 구조 보존
- 기능 완성도: **10/10** → SPEC §"기능 1~4" 4개 모두 구현, 헤더 주석/MARK 섹션/docstring까지 누락 0건, 마일스톤 매핑 표와 helper switch 1:1 일치

**가중 점수 계산**: (10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = **10.0 / 10.0**

## 최종 판정: **합격**

### 관대함 자가 점검
"10.0은 관대한 것 아닌가?" 재검토했지만:
- 강제 언래핑·매직 넘버 신규 도입 0건 (변경된 3 파일 전수 grep)
- `triggeredComboMilestones` 4지점 모두 6-10 패턴 그대로 (선언/contains/insert/주석 위치)
- `default` 절: AudioManager 0건 (exhaustive), GameScene는 SPEC §"기능 3"이 명시한 graceful fallback — 의도된 포함
- 빌드 결과 SUCCEEDED + 경고 0
- pbxproj 미변경 (신규 파일 0개라 등록 불필요 — SPEC §"주의사항" 일관)
- 20개 회귀 0 영역 `git diff` 전수 검사 OK
- 호출 순서·매핑·MARK 위치·문서주석까지 SPEC과 1:1 일치

감점 사유를 찾지 못함. 부수 변경(scope creep) 없음. **10.0 유지**.

### 구체적 개선 지시
**없음** — 모든 항목이 SPEC 정책과 정확히 일치하며 회귀 위험 0. 추가 sprint(예: 자작 음원 추가) 시점에 `comboMilestoneSoft`/`comboMilestoneStrong`의 `fileName`을 `"combosoft"`/`"combostrong"`로 갈아끼우는 변경만 OCP로 자연 활성화 — 본 sprint에선 변경 불필요.
