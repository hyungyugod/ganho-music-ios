# QA 검수 보고서 — Phase 4-R · `protocol SelfDismissingNode` 추출 리팩터

순수 리팩터 sprint (기능 변화 0). 가중 분배: Swift 패턴 0.35 / 게임 로직 0.30 / 성능 안정성 0.20 / 기능 완성도 0.15.

---

## SPEC 기능 검증

- [PASS] **기능 1 — SelfDismissingNode.swift 신설**: `GanhoMusic Shared/Protocols/SelfDismissingNode.swift` 21줄. line 8 `import SpriteKit`, line 20 `protocol SelfDismissingNode: SKNode {}` 정확. 헤더 주석 + docstring 포함. SPEC 명시 코드와 1:1 일치.
- [PASS] **기능 2 — AirplaneNode.swift line 14**: `final class AirplaneNode: SKSpriteNode, SelfDismissingNode {` (콤마+공백 1개 정확).
- [PASS] **기능 3 — AirforceOverlayNode.swift line 15**: `final class AirforceOverlayNode: SKNode, SelfDismissingNode {`.
- [PASS] **기능 4 — BombFlashNode.swift line 15**: `final class BombFlashNode: SKSpriteNode, SelfDismissingNode {`.
- [PASS] **기능 5 — pbxproj 5곳 편집**:
  - 5-1 PBXBuildFile: `A1C0F1B00000000000000021` 추가 (BombFlashNode 0020 바로 다음).
  - 5-2 PBXFileReference: `A1C0F1A00000000000000021` 추가 (`path = SelfDismissingNode.swift`).
  - 5-3 PBXGroup `Protocols` 신설: `A1C0F1F00000000000000016`, `path = "GanhoMusic Shared/Protocols"`, children 1개.
  - 5-4 루트 그룹 `C75D461B...` children에 `A1C0F1F00000000000000016 /* Protocols */` 삽입 (Models 다음, iOS 앞).
  - 5-5 iOS Sources phase에 `A1C0F1B00000000000000021 /* SelfDismissingNode.swift in Sources */` 추가 (BombFlashNode 다음).
  - 5-6 tvOS `C75D46362FA627C20016BB86` / macOS `C75D46462FA627C20016BB86` Sources phase는 `files = ()` 빈 채로 보존 (확인 완료).

---

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- Swift 컴파일러 경고: **0건**
- Swift 컴파일러 에러: **0건**
- 비고: 시스템 메시지 `appintentsmetadataprocessor` 안내는 코드/리팩터와 무관한 Xcode 기본 동작.

---

## 회귀 검증 (모두 0줄 변경)

`git diff --name-only HEAD` 결과 (Shared/ 하위):
```
GanhoMusic Shared/Nodes/AirforceOverlayNode.swift
GanhoMusic Shared/Nodes/AirplaneNode.swift
GanhoMusic Shared/Nodes/BombFlashNode.swift
```
+ untracked: `GanhoMusic Shared/Protocols/SelfDismissingNode.swift` (신설)
+ `GanhoMusic.xcodeproj/project.pbxproj` (5곳 편집)

| 회귀 대상 | 변경 줄 수 | 비고 |
|---|---|---|
| 3 노드 본문(선언 줄 외) | 0 | diff 확인 — 각 파일 정확히 +1/-1 (선언 줄만) |
| 3 노드 헤더 주석 | 0 | 헤더 docstring 보존, Phase 4-R 라인 추가 X |
| GameScene / GameScene+Setup | 0 | git diff 결과 미수정 |
| 다른 노드(Player/Enemy/Stone/Note/Projectile/HUD/DPad) | 0 | 미수정 |
| Scenes(TitleScene/ResultScene) / Config / ColorTokens / Repositories / Models | 0 | 미수정 |
| Systems(ContactRouter/SpawnSystem/ScoreSystem) | 0 | 미수정 |
| macOS Sources phase | 0 | `files = ()` 보존 |
| tvOS Sources phase | 0 | `files = ()` 보존 |

---

## 검증 시나리오 (a)~(g)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| (a) | SelfDismissingNode.swift 존재 + 구조 | **PASS** | line 8 `import SpriteKit`, line 20 `protocol SelfDismissingNode: SKNode {}` 정확. 본문 marker `{}` 비어 있음. |
| (b) | 3 노드 채택 | **PASS** | 각 선언 줄 `, SelfDismissingNode` 콤마+공백 1개 정확. `grep -n SelfDismissingNode` 결과 3 노드 + protocol 정의 라인 = 5건 (1 파일당 1건 + 정의 2건). |
| (c) | 3 노드 본문 변경 0 | **PASS** | `git diff Nodes/` 결과 각 파일 +1/-1 (선언 줄만). init/메서드/MARK/required init? 모두 보존. |
| (d) | GameScene/기타 변경 0 | **PASS** | git diff --name-only 결과 Swift 측은 3 노드만 수정 + Protocols/SelfDismissingNode.swift 신설. GameScene/Systems/Scenes/Repositories/Models/Config/Managers/HUDNode/DPadNode/PlayerNode/EnemyNode/NoteNode/ProjectileNode/StoneGuardNode 전부 미수정. |
| (e) | pbxproj 등록 정상 | **PASS** | `0021` 4건 정확 (BuildFile + FileReference + Sources phase + Protocols 그룹 children). 새 PBXGroup `A1C0F1F00000000000000016` 정의 1건 + 루트 children 참조 1건 = 2건. 루트 그룹 children에 Models 다음·iOS 앞 위치. |
| (f) | 빌드 | **PASS** | `** BUILD SUCCEEDED **`, Swift 경고 0, 에러 0. |
| (g) | 게임플레이 동일성 (정적) | **PASS** | 3 노드 본문 변경 0 + GameScene/Scenes/Systems 변경 0 + 시그니처(crossScreen/showAndDismiss/flash) 변경 0. marker protocol 채택은 런타임 동작 변화 0 (Swift dynamic dispatch 영향 없음, witness table 비어 있음). AIRFORCE 5단계 호출 경로 Phase 4-7과 동일. |

---

## 추가 제약 검증

- [PASS] **StoneGuardNode 채택 0** — `grep -n "SelfDismissingNode" StoneGuardNode.swift` 결과 0건. 영구 노드는 채택 안 함 (자가 소멸이 아닌 영구 보호 노드).
- [PASS] **protocol 메서드 0개 (marker)** — line 20 `protocol SelfDismissingNode: SKNode {}` 본문 `{}` 비어 있음. 메서드 시그니처 0, extension 0.
- [PASS] **콤마+공백 1개 정확** — 3 노드 모두 `, SelfDismissingNode` 패턴, 추가 공백 0.
- [PASS] **순수 리팩터 — 기능 변화 0** — diff 분석 결과 동작 영향 코드(메서드 본문/init/시그니처/상수/물리/액션) 변경 0.
- [PASS] **강제 언래핑 0** — 신설 파일 `!` 사용 0건 (옵셔널 신설 X).
- [PASS] **import SpriteKit** — SelfDismissingNode.swift에 포함 (SKNode 제약 위해 필수).

---

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

---

## P0 — 치명적 이슈

없음.

## P1 — 중요 이슈

없음.

## P2 — 권장 사항

없음. SPEC In Scope 5개 기능 모두 정확 구현. Out of Scope 항목 모두 미위반.

---

## 통과 항목

- **SPEC 정합성**: In Scope 5개 기능 1:1 일치, Out of Scope 15개 항목 모두 미위반.
- **빌드 클린**: BUILD SUCCEEDED + Swift 경고 0건.
- **회귀 0**: 변경 대상 외 모든 영역(GameScene, Systems, Scenes, Repositories, Models, Config, 다른 노드, macOS/tvOS Sources) 변경 줄 수 0.
- **Swift 패턴**: protocol 키워드 정확, class-constrained `: SKNode` 정확, 다중 채택 문법(콤마+공백) 정확, marker `{}` 비어 있음, 강제 언래핑 0.
- **SpriteKit 패턴**: 채택만 추가 — fire-and-forget SKAction.sequence 패턴 보존, didMove/dt/스폰/충돌 등 게임 로직 변경 0.
- **3 노드 본문 변경 0**: 헤더 주석 / init / required init? / 메서드 / MARK 전부 보존.
- **pbxproj**: 식별자 충돌 0, 들여쓰기 정합, tvOS/macOS Sources phase 보존.

---

## 채점

**순수 리팩터 sprint 가중 분배**: Swift 패턴 0.35 / 게임 로직 0.30 / 성능 안정성 0.20 / 기능 완성도 0.15.

### 항목별 점수

- **Swift 패턴 일관성: 10/10** — protocol 도입이 정확. class-constrained protocol(`: SKNode`)로 채택 타입을 SKNode 자손에 한정, 구조체/열거형 채택을 컴파일 타임에 차단. marker protocol 패턴(메서드 0, 본문 `{}`)으로 *역할 분류만* 표현. 다중 채택 문법(클래스 먼저 → protocol 콤마 구분) 준수. 강제 언래핑 0, 매직 넘버 0, 새 상수 0. docstring으로 protocol 의도 + 채택 노드 + 미래 확장 가능성 명시 — Spring `interface` 도입과 동치인 모범 패턴.

- **게임 로직 완성도: 10/10** — 동작 변화 0 보장. 3 노드 본문(SKAction.sequence fire-and-forget 패턴) 변경 0, GameScene/SpawnSystem/ContactRouter/ScoreSystem 변경 0, 시그니처(crossScreen/showAndDismiss/flash) 변경 0. marker protocol 채택은 witness table이 비어 있어 dynamic dispatch 영향 0 — AIRFORCE 5단계 호출 경로 Phase 4-7과 비트 단위로 동일.

- **성능 & 안정성: 10/10** — BUILD SUCCEEDED + Swift 경고 0건. 강제 언래핑 0, 신규 옵셔널 0, 신규 클로저 0(weak self 무관). 노드 정리는 기존 SKAction.removeFromParent 그대로 — 메모리 누수 위험 0. 컴파일러 부담도 marker protocol이라 코드 생성 추가량 사실상 0.

- **기능 완성도: 10/10** — SPEC In Scope 5개 기능(SelfDismissingNode.swift 신설 + 3 노드 선언 줄 패치 + pbxproj 5곳) 모두 SPEC 명시대로 정확 구현. Out of Scope 15개 항목 모두 미위반(GameScene 미수정, StoneGuardNode 미채택, macOS/tvOS Sources 빈 채로, protocol 메서드 0, extension 0).

### 가중 점수

`10×0.35 + 10×0.30 + 10×0.20 + 10×0.15 = 3.50 + 3.00 + 2.00 + 1.50 = 10.00 / 10.0`

---

## 최종 판정: **합격**

순수 리팩터 sprint의 목표(*분류 표현만 추가, 동작 변화 0, 빌드 클린*) 3가지 모두 달성. SPEC In Scope 5개 항목 1:1 일치, Out of Scope 위반 0, 빌드 클린, 회귀 0.

자기 점검(상단 "절대 관대하게 보지 마라" 재검토):
- 8.0 이상 점수가 관대한 판단인지 한 번 더 확인 → diff 범위가 *물리적으로* 선언 줄 3개 + 신설 파일 1개 + pbxproj 5곳으로 한정되어 *오답 가능 표면*이 극도로 작음. 모든 제약(콤마+공백, 식별자, 그룹 구조, Sources phase iOS-only, marker `{}`, StoneGuardNode 미채택)이 정확 검증됨. 관대한 판단 없음.

**구체적 개선 지시**: 없음 (수정 불필요).

