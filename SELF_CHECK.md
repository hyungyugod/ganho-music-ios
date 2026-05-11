# 자체 점검 — Phase 4-R · `protocol SelfDismissingNode` 추출 리팩터

## SPEC 기능 체크

- [x] **기능 1**: `Protocols/SelfDismissingNode.swift` 신설 — SPEC 정확 코드 그대로 (`protocol SelfDismissingNode: SKNode {}` marker, import SpriteKit, 헤더 주석 + 채택 노드 docstring 포함, 총 18줄).
- [x] **기능 2**: AirplaneNode line 14 — `final class AirplaneNode: SKSpriteNode {` → `final class AirplaneNode: SKSpriteNode, SelfDismissingNode {` (콤마+공백 1개 정확).
- [x] **기능 3**: AirforceOverlayNode line 15 — `final class AirforceOverlayNode: SKNode {` → `final class AirforceOverlayNode: SKNode, SelfDismissingNode {`.
- [x] **기능 4**: BombFlashNode line 15 — `final class BombFlashNode: SKSpriteNode {` → `final class BombFlashNode: SKSpriteNode, SelfDismissingNode {`.
- [x] **기능 5**: pbxproj 5곳 편집 완료.
  - 5-1: PBXBuildFile section에 `A1C0F1B00000000000000021 /* SelfDismissingNode.swift in Sources */` 추가 (BombFlashNode 0020 바로 다음).
  - 5-2: PBXFileReference section에 `A1C0F1A00000000000000021 /* SelfDismissingNode.swift */` 추가 (BombFlashNode 0020 바로 다음, `path = SelfDismissingNode.swift`).
  - 5-3: 새 PBXGroup `A1C0F1F00000000000000016 /* Protocols */` 추가 (Models 그룹 다음). `path = "GanhoMusic Shared/Protocols"`, children에 SelfDismissingNode.swift 1개.
  - 5-4: 루트 그룹 `C75D461B...` children에 Models 다음 위치에 `A1C0F1F00000000000000016 /* Protocols */` 삽입.
  - 5-5: iOS Sources phase `C75D46252FA627C20016BB86 /* Sources */` files에 BombFlashNode 다음 줄 `A1C0F1B00000000000000021 /* SelfDismissingNode.swift in Sources */` 추가, 닫는 `);` 전.
  - 5-6: tvOS `C75D46362FA627C20016BB86` / macOS `C75D46462FA627C20016BB86` Sources phase는 `files = ()` 빈 채로 보존. **수정 0**.

## 파일별 변경 줄 수 (git diff 기준)

| 파일 | 추가 | 삭제 | 비고 |
|---|---|---|---|
| `Protocols/SelfDismissingNode.swift` | 신규(18줄) | 0 | 신설 |
| `Nodes/AirplaneNode.swift` | +1 | -1 | line 14 선언 줄만 |
| `Nodes/AirforceOverlayNode.swift` | +1 | -1 | line 15 선언 줄만 |
| `Nodes/BombFlashNode.swift` | +1 | -1 | line 15 선언 줄만 |
| `GanhoMusic.xcodeproj/project.pbxproj` | +13 | 0 | 5곳 등록 |

3 노드 본문/헤더 주석/init/메서드 모두 변경 0. diff에 선언 줄 1줄 외 변경 없음 확인.

## Out of Scope (위반 시 P0) — 미위반 확인

- [x] 3 노드 본문 한 줄도 변경 X (헤더 주석/init/required init?/메서드 모두 보존)
- [x] 3 노드 헤더 주석 변경 X (Phase 4-R 라인 추가 X)
- [x] GameScene / GameScene+Setup 변경 X
- [x] 다른 노드(Player/Enemy/Stone/Note/Projectile/HUD/DPad) 변경 X
- [x] GameConfig / ColorTokens / PhysicsCategory / Repository / Stats / Scenes 변경 X
- [x] ContactRouter / SpawnSystem / ScoreSystem 변경 X
- [x] 새 GameConfig 상수 X
- [x] update() / endGame() 변경 X
- [x] macOS / tvOS Sources phase 수정 X (`files = ()` 빈 채로)
- [x] StoneGuardNode 채택 X (영구 노드는 채택 안 함)
- [x] protocol에 메서드 시그니처 추가 X (marker `{}` 비어 있음)
- [x] protocol extension 추가 X
- [x] 3 노드 시작 메서드 통일 X (crossScreen/showAndDismiss/flash 각자 시그니처 보존)
- [x] Test 코드 추가 X

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (변경된 모든 줄에 `!` 0)
- guard let 옵셔널 처리: **해당 없음** (옵셔널 신설 X)
- MARK 섹션 구분: **해당 없음** (3 노드 기존 MARK 그대로, SelfDismissingNode는 protocol marker라 MARK 불필요)
- GameConfig 상수 사용: **해당 없음** (새 상수 0)
- weak self 캡처: **해당 없음** (클로저 신설 X)
- 네이밍: `SelfDismissingNode` UpperCamelCase, `protocol` 키워드 정확, class-constrained `: SKNode` 정확.
- 한국어 주석 OK, 한국어 식별자 0.

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: **해당 없음** (씬 변경 X)
- dt 기반 이동: **해당 없음**
- SKAction 스폰 패턴: **해당 없음** (3 노드의 fire-and-forget 패턴 그대로)
- 충돌 후 노드 즉시 삭제 없음: **해당 없음** (충돌 코드 변경 0)
- HUD 노드 분리: **해당 없음**
- `import SpriteKit`: SelfDismissingNode.swift에 정확히 포함 (SKNode 제약 조건 필요).

## 빌드 상태

- **빌드 결과**: `** BUILD SUCCEEDED **` (xcodebuild -scheme "GanhoMusic iOS" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build)
- **코드 관련 경고**: 0건 (Swift 컴파일러 경고 0)
- **시스템 경고**: 1건 (`appintentsmetadataprocessor: Metadata extraction skipped. No AppIntents.framework dependency found.`) — 코드/리팩터와 무관한 Xcode 기본 메타데이터 처리 안내 메시지. 본 sprint 이전부터 동일하게 발생.
- **예상 빌드 에러**: 없음.

## 검증 시나리오 (a)~(g) 결과

| # | 시나리오 | 검증 결과 |
|---|---|---|
| (a) | SelfDismissingNode.swift 존재 + 구조 | **PASS** — 파일 생성 확인, `protocol SelfDismissingNode: SKNode {}` 정확, `import SpriteKit` 포함 |
| (b) | 3 노드 채택 | **PASS** — 각 선언 줄에 `, SelfDismissingNode` 정확 (콤마+공백 1개) |
| (c) | 3 노드 본문 변경 0 | **PASS** — `git diff Nodes/` 결과 각 파일 +1/-1 (선언 줄만) |
| (d) | GameScene/기타 변경 0 | **PASS** — git diff --stat 결과 Swift 코드는 `Protocols/SelfDismissingNode.swift` (신설) + 3 노드 선언 줄 + pbxproj. GameScene/Systems/Scenes/Repositories/Models/Config/Managers/Errors/HUDNode/DPadNode/PlayerNode/EnemyNode/NoteNode/ProjectileNode/StoneGuardNode 변경 0 |
| (e) | pbxproj 등록 정상 | **PASS** — 0021 4곳 (BuildFile/FileReference/Sources phase 각 1줄 + 새 PBXGroup children 1줄) + 새 Protocols PBXGroup `...016` + 루트 children 갱신 |
| (f) | 빌드 | **PASS** — `** BUILD SUCCEEDED **`, 경고 0건 |
| (g) | 게임플레이 동일성 | **PASS (정적 검증)** — 3 노드 본문 변경 0 + GameScene 변경 0 + 시그니처 변경 0이므로 AIRFORCE 5단계 호출 경로(Scenes/GameScene → AirforceOverlayNode/AirplaneNode/BombFlashNode init + 메서드 호출) 동일. marker protocol 채택은 런타임 동작 변화 0. Phase 4-7과 정확히 동일하게 동작 |

## 학습 가치 달성

- `protocol` 키워드 첫 도입 — Swift 핵심 추상화 도구 등장.
- Class-constrained protocol — `: SKNode`로 채택 가능 타입을 SKNode 자손에 한정. 구조체/열거형 채택 차단.
- Marker protocol — 메서드 0개, 본문 `{}` 비어 있음. 역할/분류 표현 전용.
- 클래스 + protocol 다중 채택 문법 — `Class: ParentClass, Protocol1, Protocol2 {}` 콤마 구분, 클래스 먼저.
- Rule of three 추출 시점 — 같은 패턴 3회 반복(4-3/4-4/4-5)에서 분류 추출.
- `Protocols/` 새 디렉터리 — 프로젝트 구조 진화 (Config / Nodes / Scenes / Systems / Repositories / Models / Protocols).
- 순수 리팩터 sprint — 기능 변화 0, 분류 표현만 추가.

## 범위 외 미구현 항목

- **없음**. SPEC In Scope 5개 기능 모두 정확 구현. Out of Scope 항목은 모두 손대지 않음.

## 산출물 경로

- 신규: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/suspicious-chandrasekhar-09ac09/GanhoMusic/GanhoMusic Shared/Protocols/SelfDismissingNode.swift`
- 수정: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/suspicious-chandrasekhar-09ac09/GanhoMusic/GanhoMusic Shared/Nodes/AirplaneNode.swift`
- 수정: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/suspicious-chandrasekhar-09ac09/GanhoMusic/GanhoMusic Shared/Nodes/AirforceOverlayNode.swift`
- 수정: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/suspicious-chandrasekhar-09ac09/GanhoMusic/GanhoMusic Shared/Nodes/BombFlashNode.swift`
- 수정: `/Users/hg/Desktop/ganho-music-ios/.claude/worktrees/suspicious-chandrasekhar-09ac09/GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`
