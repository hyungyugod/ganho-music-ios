# Phase 4-R · `protocol SelfDismissingNode` 추출 리팩터

## 개요
4-3 AirplaneNode, 4-4 AirforceOverlayNode, 4-5 BombFlashNode 세 노드가 모두 *SKAction.sequence 마지막 단계 = removeFromParent*로 자가 소멸하는 fire-and-forget 패턴을 반복(3회 = Rule of three). 이를 새 `Protocols/SelfDismissingNode.swift` marker protocol로 분류 추출한다. **본 sprint는 순수 리팩터 — 기능 변화 0**.

## 변경 유형
**리팩터** — 순수 코드 정돈. 동작·시그니처·게임플레이 모두 변화 0.

## 게임 경험 의도
사용자 입장에서 *변화 0*. 모든 변화는 *코드 안의 의도 표현*에서만. AIRFORCE 이스터에그 5단계는 4-7과 *완전히 동일*하게 동작.

## Sprint 범위 계약

### In Scope (모두 필수)
1. 새 디렉터리 `GanhoMusic/GanhoMusic Shared/Protocols/` (실제 파일시스템 mkdir)
2. 새 파일 `Protocols/SelfDismissingNode.swift` (~15줄, marker protocol)
3. 3 노드(AirplaneNode/AirforceOverlayNode/BombFlashNode) 클래스 선언 줄에 `, SelfDismissingNode` *추가만*. 본문 한 줄도 변경 금지
4. pbxproj 등록: 식별자 `...0021` (BuildFile/FileReference/Sources phase) + 새 PBXGroup `Protocols`(`...016`) + 루트 그룹 children 갱신

### Out of Scope (위반 시 P0)
- protocol에 메서드 시그니처 추가 (marker `{}` 유지)
- protocol extension 추가
- 3 노드 시작 메서드 통일
- 3 노드 *본문* 한 줄도 변경
- 3 노드 헤더 주석 변경
- GameScene / GameScene+Setup 변경
- 다른 노드(Player/Enemy/Stone/Note/Projectile/HUD/DPad) 변경
- GameConfig / ColorTokens / PhysicsCategory / Repository / Stats / Scenes 변경
- ContactRouter / SpawnSystem / ScoreSystem 변경
- 새 GameConfig 상수
- update() / endGame() 변경
- 기능 동작 변경 (게임플레이 차이 0)
- macOS / tvOS Sources phase 수정
- Test 코드 추가
- StoneGuardNode를 SelfDismissingNode 채택 (영구 노드)

### 판단 기준
"이 변경이 없으면 `protocol SelfDismissingNode`로 *3 노드를 분류*할 수 있는가?" → NO만 In Scope.

## 변경 범위
- 신설 디렉터리: `GanhoMusic Shared/Protocols/`
- 신설 파일: `Protocols/SelfDismissingNode.swift`
- 수정: 3 노드 클래스 선언 줄 각 1줄
- 수정: pbxproj 5곳 (BuildFile / FileReference / 새 Group / 루트 children / Sources phase)

## 기능 상세

### 기능 1: `SelfDismissingNode.swift` 신설
- **구현 위치**: `GanhoMusic/GanhoMusic Shared/Protocols/SelfDismissingNode.swift`
- **정확한 최종 코드**:

```swift
//
//  SelfDismissingNode.swift
//  GanhoMusic Shared
//
//  Phase 4-R · 자가 소멸 노드 마커 protocol — Rule of three 추출
//

import SpriteKit

/// 자가 소멸 노드 마커 프로토콜.
/// 4-3 AirplaneNode부터 4-5 BombFlashNode까지 등장한 fire-and-forget 패턴
/// (SKAction.sequence 마지막 단계가 .removeFromParent())의 *역할 분류*.
/// 채택 노드는 SKNode 또는 그 자손이어야 한다(class-constrained).
/// 본 protocol은 *비어 있는 marker* — 미래 protocol extension으로 *공통 동작*을 추가 가능.
///
/// 채택 노드 (Phase 4-R 시점):
/// - AirplaneNode: crossScreen(sceneWidth:atY:) — Phase 4-3
/// - AirforceOverlayNode: showAndDismiss() — Phase 4-4
/// - BombFlashNode: flash(sceneSize:) — Phase 4-5
protocol SelfDismissingNode: SKNode {}
```

### 기능 2: AirplaneNode.swift 선언 줄 패치
- **위치**: line 14
- **Before**: `final class AirplaneNode: SKSpriteNode {`
- **After**: `final class AirplaneNode: SKSpriteNode, SelfDismissingNode {`
- 본문 한 줄도 변경 금지.

### 기능 3: AirforceOverlayNode.swift 선언 줄 패치
- **위치**: line 15
- **Before**: `final class AirforceOverlayNode: SKNode {`
- **After**: `final class AirforceOverlayNode: SKNode, SelfDismissingNode {`

### 기능 4: BombFlashNode.swift 선언 줄 패치
- **위치**: line 15
- **Before**: `final class BombFlashNode: SKSpriteNode {`
- **After**: `final class BombFlashNode: SKSpriteNode, SelfDismissingNode {`

### 기능 5: project.pbxproj — 식별자 `0021` 4곳 + Protocols 그룹

#### 5-1. PBXBuildFile section (BombFlashNode 0020 다음)
```
		A1C0F1B00000000000000021 /* SelfDismissingNode.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1C0F1A00000000000000021 /* SelfDismissingNode.swift */; };
```

#### 5-2. PBXFileReference section (BombFlashNode 0020 다음)
```
		A1C0F1A00000000000000021 /* SelfDismissingNode.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SelfDismissingNode.swift; sourceTree = "<group>"; };
```

#### 5-3. 새 PBXGroup `Protocols` (Models 그룹 다음)
```
		A1C0F1F00000000000000016 /* Protocols */ = {
			isa = PBXGroup;
			children = (
				A1C0F1A00000000000000021 /* SelfDismissingNode.swift */,
			);
			name = Protocols;
			path = "GanhoMusic Shared/Protocols";
			sourceTree = "<group>";
		};
```

#### 5-4. 루트 그룹 `C75D461B...` children 갱신 (Models 다음에 Protocols 삽입)
```
				A1C0F1E00000000000000014 /* Models */,
				A1C0F1F00000000000000016 /* Protocols */,
				C75D462B2FA627C20016BB86 /* GanhoMusic iOS */,
```

#### 5-5. iOS Sources phase files 갱신 (BombFlashNode 다음, `);` 닫기 전)
```
				A1C0F1B00000000000000020 /* BombFlashNode.swift in Sources */,
				A1C0F1B00000000000000021 /* SelfDismissingNode.swift in Sources */,
			);
```

#### 5-6. tvOS / macOS Sources phase
**그대로 — files = () 빈 채로 유지**. 수정 시 P0.

## 검증 시나리오 (a)~(g)

| # | 시나리오 | 정적 검증 |
|---|---|---|
| (a) | SelfDismissingNode.swift 존재 + 구조 | `protocol SelfDismissingNode: SKNode {}` 정확, `import SpriteKit` |
| (b) | 3 노드 채택 | 각 선언 줄에 `, SelfDismissingNode` 정확 |
| (c) | 3 노드 본문 변경 0 | diff로 선언 줄 외 변경 0 확인 |
| (d) | GameScene/기타 변경 0 | 그 외 모든 파일 변경 0 |
| (e) | pbxproj 등록 정상 | 0021 4곳 + Protocols PBXGroup + 루트 children |
| (f) | 빌드 | BUILD SUCCEEDED + 경고 0 |
| (g) | 게임플레이 동일성 | AIRFORCE 5단계 동작 4-7과 동일 (정적: 검증 시나리오 a~i가 4-7 그대로) |

## 학습 가치
- `protocol` 키워드 첫 도입
- Class-constrained protocol (`: SKNode`)
- Marker protocol — 메서드 0개
- 클래스 + protocol 다중 채택 문법
- Rule of three 추출 시점
- `Protocols/` 새 디렉터리 — 프로젝트 구조 진화
- 순수 리팩터 sprint — 기능 변화 0

## 주의사항

### Swift / SpriteKit
- `import SpriteKit` 필수 (SKNode 제약)
- 3 노드 import는 *이미 있음* — 추가 X
- 헤더 주석에 Phase 4-R 라인 추가 X
- 콤마+공백 1개 정확 (`, SelfDismissingNode`)
- 채택 순서: 클래스 먼저, protocol 뒤

### pbxproj
- 새 PBXGroup 식별자 `A1C0F1F00000000000000016` — 다른 그룹과 충돌 0
- PBXBuildFile/PBXFileReference 식별자 `...0021` — BombFlashNode 0020 다음
- `path = SelfDismissingNode.swift` (디렉터리 미포함, 그룹의 path가 디렉터리 정의)
- 루트 그룹 children에 Models 다음 위치
- iOS Sources phase에만 추가, tvOS/macOS 빈 채로

### 파일 시스템
- `Protocols/` 디렉터리 실제 mkdir 필요
- SelfDismissingNode.swift는 그 안에 배치

### Generator 절대 하지 말 것
- 3 노드 본문 1줄 변경 → P0
- protocol에 메서드 추가 → P0
- GameScene / GameScene+Setup 변경 → P0
- StoneGuardNode 채택 → P0
- macOS / tvOS Sources phase 수정 → P0
- 새 GameConfig 상수 → P0

## Generator 작업 순서
1. `mkdir -p "GanhoMusic/GanhoMusic Shared/Protocols"`
2. SelfDismissingNode.swift 작성
3. AirplaneNode line 14 콤마 패치
4. AirforceOverlayNode line 15 콤마 패치
5. BombFlashNode line 15 콤마 패치
6. pbxproj 5곳 편집
7. xcodebuild → SUCCEEDED 확인
8. SELF_CHECK.md 작성
