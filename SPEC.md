# 4-Bug Fix Sprint — 갇힘 + 난이도 + ResultScene 겹침 + CharacterSelect 헤더

## 개요

수간호사(EnemyNode)가 `collisionBitMask = PhysicsCategory.wall` 설정으로 인해 waypoint 경로상 벽에 막혀 패트롤이 stuck 되는 4가지 독립 버그를 수정한다. 원본 game.js에서 수간호사는 벽을 자유롭게 통과하므로 iOS에서도 동일하게 맞춰야 한다. easy 난이도 F 발사 주기와 음표 spawn 밀도를 높이고, ResultScene stat 영역과 버튼의 y 좌표 겹침, CharacterSelectScene 헤더 타이틀 위치와 부제목을 정리한다.

## 변경 유형

게임플레이 + 비주얼 혼합

## 게임 경험 의도

수간호사가 어떤 난이도의 맵에서도 벽을 통과해 정해진 경로를 순환하며 F 투사체를 지속적으로 발사해야 플레이어가 긴장감을 느낄 수 있다. easy 난이도도 투사체 밀도가 충분해야 회피 플레이의 재미가 살아나며, 결과 화면과 캐릭터 선택 화면은 어떤 기기 크기에서도 UI 요소가 겹치지 않아야 한다.

## Sprint 범위 계약

- **허용**: EnemyNode.init 물리 충돌 비트마스크 1줄 수정, GameConfig spawn rate 상수 조정(easy 전용), ResultScene layoutLabels() 3곳 y 오프셋 상수 교체, CharacterSelectScene setupHeader() 부제목 숨김 1줄, GameConfig에 V11 상수 4개 추가
- **금지**: 새 적/스킬/씬 추가, 기존 게임 흐름 변경, PixelSprite·PixelPalette·PixelSpriteRenderer·CharacterFaceNode·NurseAvatarNode 본체 변경, 메뉴 씬 6개 중 CharacterSelectScene setupHeader()/layoutHeader() 이외 변경, SPEC에 없는 새 이펙트 추가
- **판단 기준**: "이 변경이 없으면 SPEC 기능이 제대로 동작하지 않는가?" → YES면 허용, NO면 금지

## 변경 범위

### 수정할 파일

- `GanhoMusic Shared/Nodes/EnemyNode.swift`: init의 `collisionBitMask = PhysicsCategory.wall` → `0`
- `GanhoMusic Shared/Config/GameConfig.swift`: easy spawn rate 상수 3개 수정 + V11 레이아웃 상수 4개 추가
- `GanhoMusic Shared/Scenes/ResultScene.swift`: `layoutLabels()` 내 3곳 상수 교체
- `GanhoMusic Shared/Scenes/CharacterSelectScene.swift`: `setupHeader()` 부제목 숨김 1줄 + `layoutHeader()` 상수 교체

### 추가할 파일

없음

## 기능 상세

### 기능 1: 수간호사 벽 통과 (갇힘 + F 미생성 해결)

- **설명**: 원본 game.js에서 수간호사는 직접 픽셀 좌표를 갱신하며 벽 타일과 물리 충돌이 없다. iOS 이식에서 `collisionBitMask = PhysicsCategory.wall`이 추가돼 normal/hard 맵의 방 구조 벽에 막히면 waypoint snap 조건(`dist <= step`)이 영구적으로 불충족 → 패트롤 stuck. `collisionBitMask = 0`으로 변경해 원본과 동일하게 벽을 통과시킨다.
- **구현 위치**: `EnemyNode.swift` — `// MARK: - Init` 내부, physicsBody 설정 블록
- **핵심 코드 구조**:
  ```swift
  // BEFORE
  body.collisionBitMask    = PhysicsCategory.wall
  
  // AFTER (원본 game.js 1:1 — 수간호사는 벽 물리 반응 없음)
  body.collisionBitMask    = 0
  ```
- **중요**: `body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall`은 **절대 변경 금지**. contact(감지)와 collision(물리 반응)은 독립 비트마스크다.

### 기능 2: easy 난이도 spawn rate 상향

- **설명**: easy 난이도의 F 발사 주기(3.5→2.5초)가 너무 길고 음표 동시 최대(5개)가 적어 게임이 싱겁다. 발사 주기를 2.5→1.2초로, 음표 spawn 간격을 1.5→1.2초로, 동시 최대를 6개로 올린다. normal/hard는 현재 수치 유지.
- **구현 위치**: `GameConfig.swift` — `// MARK: - Difficulty` 섹션의 Dictionary 리터럴

### 기능 3: ResultScene stat 영역 ↔ 버튼 겹침 수정

- **설명**: iPhone Landscape에서 stat 그룹과 버튼 Y좌표가 충돌. stat y를 위로 올리고 버튼 inset을 줄여 40pt 이상 여백 확보. titleLabel도 +90으로 올려 scoreLabel 상단과 간격 확보.
- **GameConfig에 추가할 상수**:
  - `resultTitleOffsetYV11: CGFloat = 90` (70→90)
  - `resultStatGapFromDividerV11: CGFloat = 14` (28→14)
  - `resultButtonBottomInsetV11: CGFloat = 30` (56→30)
- **기존 상수 보존**: 삭제 금지

### 기능 4: CharacterSelectScene 헤더 겹침 수정 + 부제목 완전 제거

- **설명**: 헤더 y를 +145→+160으로 올려 카드 영역과 여백 확보. 부제목 "친구마다 다른 스킬과 이동속도를 가져요"는 `isHidden = true`로 완전 숨김.
- **GameConfig에 추가할 상수**:
  - `characterSelectHeaderOffsetYV11: CGFloat = 160` (145→160)
- **isHidden vs removeFromParent**: `removeFromParent()` 금지. `isHidden = true` 사용.

## 주의사항

1. **EnemyNode contact 비트마스크 보존**: `body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall` 변경 금지. collision만 0으로 바꾼다.
2. **GameConfig 기존 상수 삭제 금지**: V11 상수를 **추가**하고 호출부만 교체.
3. **변경 금지 파일**: `PixelSprite.swift`, `PixelPalette.swift`, `PixelSpriteRenderer.swift`, `CharacterFaceNode.swift`, `NurseAvatarNode.swift` 본체.
4. **easy 맵 벽 통과 시각**: easy에서 수간호사가 외곽 벽을 통과하는 장면이 보일 수 있다. 원본 game.js도 동일 동작이므로 허용 범위.
