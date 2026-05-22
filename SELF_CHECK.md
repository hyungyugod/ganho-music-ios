# 자체 점검

전략: Case A — 초회 구현. SPEC 기능 4종 전항 구현.

## SPEC 기능 체크

- [x] 기능 1 (수간호사 벽 통과): EnemyNode.swift init physicsBody에서 `collisionBitMask = PhysicsCategory.wall` → `0`으로 변경. contactTestBitMask는 변경 없음.
- [x] 기능 2 (easy spawn rate 상향): GameConfig.swift에서 `projectileFireIntervalStartByDifficulty` easy 3.5→1.2, `noteSpawnIntervalByDifficulty` easy 1.5→1.2, `noteMaxConcurrentByDifficulty` easy 5→6으로 수정. normal/hard 현행 유지.
- [x] 기능 3 (ResultScene stat/버튼 겹침 수정): `layoutLabels()`에서 titleLabel y→`resultTitleOffsetYV11`(90), stat gap→`resultStatGapFromDividerV11`(14), 버튼 bottomInset→`resultButtonBottomInsetV11`(30)으로 교체. 기존 V4/V9/V7+ 상수 보존.
- [x] 기능 4 (CharacterSelect 헤더 겹침 + 부제 숨김): `setupHeader()`에 `headerSubLabel.isHidden = true` 1줄 추가. `layoutHeader()`에서 `characterSelectHeaderOffsetYV10`→`characterSelectHeaderOffsetYV11`(160)으로 교체.
- [x] V11 상수 4개 추가: `resultTitleOffsetYV11`(90), `resultStatGapFromDividerV11`(14), `resultButtonBottomInsetV11`(30), `characterSelectHeaderOffsetYV11`(160) — 기존 상수 삭제 없음.

## Swift 패턴 준수

- 강제 언래핑 미사용: 준수 (변경된 코드 모두 ! 없음)
- guard let 옵셔널 처리: 준수 (기존 패턴 유지)
- MARK 섹션 구분: 준수 (`// MARK: - 4-Bug Fix Sprint · V11 Layout Constants` 신규 섹션 추가)
- GameConfig 상수 사용: 준수 (매직 넘버 없음, 모든 값 상수로 명명)
- weak self 캡처: 준수 (해당 없음 — 클로저 신규 작성 없음)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: 준수 (기존 패턴 유지)
- dt 기반 이동: 준수 (EnemyNode 패트롤 velocity 계산 변경 없음)
- SKAction 스폰 패턴: 준수 (해당 없음)
- 충돌 후 노드 즉시 삭제 없음: 준수 (충돌 처리 변경 없음)
- HUD 노드 분리: 준수 (해당 없음)

## 빌드 상태

- 예상 빌드 에러: 없음
  - `resultTitleOffsetYV11`, `resultStatGapFromDividerV11`, `resultButtonBottomInsetV11`, `characterSelectHeaderOffsetYV11` 4개 상수 모두 GameConfig에 정의됨.
  - 참조 파일(ResultScene.swift, CharacterSelectScene.swift)에서 정확한 이름으로 사용.
  - EnemyNode의 `collisionBitMask = 0`은 UInt32 리터럴 0으로 타입 정합.
- 주의 필요 경고: 없음

## 범위 외 미구현 항목

없음. SPEC §Sprint 범위 계약의 허용 항목 전부 구현. 금지 항목 미접촉 확인:
- PixelSprite / PixelPalette / PixelSpriteRenderer 본체 변경 없음.
- CharacterFaceNode / NurseAvatarNode 본체 변경 없음.
- 메뉴 씬 6개 중 CharacterSelectScene setupHeader()/layoutHeader() 이외 변경 없음.
- 새 적/스킬/씬 추가 없음.
- SPEC에 없는 새 이펙트 추가 없음.
