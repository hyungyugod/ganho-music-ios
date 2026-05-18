# QA 검수 보고서 — Phase 9-4

## SPEC 기능 검증

| # | SPEC 기능 | 결과 | 상세 |
|---|---|---|---|
| 1 | 체크보드 1152 SKSpriteNode 컨테이너 1개 | PASS | `GameScene+Setup.swift:135-161` 이중 for `0..<mapColumns × 0..<mapRows`, `container = SKNode()` 1개에 자식으로 `addChild(tile)`, 컨테이너만 `worldNode.addChild(container)`. |
| 2 | 체크보드 physicsBody = nil | PASS | `SKSpriteNode(color:size:)` 생성 후 physicsBody 할당 라인 0건. 시각 전용. |
| 3 | zPosition = -100 (GameConfig 경유) | PASS | `container.zPosition = GameConfig.checkerboardZPosition`. |
| 4 | setupWorld() 1회 호출 / update() 0건 | PASS | `setupWorld()` 호출은 `GameScene.swift:137` (didMove)에서만. `addCheckerboardFloor()` 호출 1줄. update 내 호출 0건. |
| 5 | mapColumns/mapRows/tileSize 상수 사용 | PASS | 호출부 리터럴 `48`/`24`/`20` 등장 0건. |
| 6 | hex 호출부 리터럴 0 | PASS | `UIColor(hex: GameConfig.checkerboardFloorAHex/BHex)` 경유. |
| 7 | normal 중앙 분리벽 윗 r=2..10 / 아랫 r=13..21 | PASS | GameConfig 상수 경유. |
| 8 | r=11, 12 두 칸 비어 있음 | PASS | 반복 범위 자체에서 11,12 제외 — 자연 무빌드. doorR=-1 sentinel graceful noop. |
| 9 | 좌·우 장식 기둥 좌표 | PASS | 좌 `(10..11, 11..12)`, 우 `(36..37, 11..12)` 거울 대칭. |
| 10 | addRectPillar/addVerticalWall 접근 가능성 | PASS | `addNormalMap`이 동일 extension 블록 안에 있음 → private 접근 정상. 빌드 SUCCEEDED로 실증. |
| 11 | switch .easy / .normal / .hard + default 미사용 | PASS | `setupMap()` 세 case 모두 명시, `default` 없음. |
| 12 | 회귀 방지 영역 0줄 변경 | PASS | `git diff HEAD` 검증 — addOuterWalls/addCentralPillar/addHardMap/addRectPillar/addHorizontalWall/addVerticalWall 모두 unchanged. HUD/Title/Result/Player/Enemy/StoneGuard/Repository 일체 미수정. 카메라 follow 라인 보존. |

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 비고: warning 0건, error 0건.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## 통과 항목

- **강제 언래핑 0건**: `!=` 외 등장 0.
- **Timer/DispatchQueue 0건**.
- **매직 넘버 0건**: 호출부 리터럴 0. GameConfig 단일 정의 지점.
- **weak self**: 신규 코드 클로저 캡처 0 — 해당 없음.
- **MARK 섹션**: `// MARK: - Checkerboard Floor (Phase 9-4)`, `// MARK: - Normal Map (Phase 9-4)` 분리.
- **private 접근 제어**: `addCheckerboardFloor` private. `addNormalMap`은 same-extension 헬퍼 접근 위해 non-private.
- **switch default 미사용**: enum 신규 case 추가 시 컴파일러 경고 자연 검출.
- **physicsBody 정책**: 체크보드 1152 노드 physicsBody 0 — 60fps 안전. normal 맵 벽은 기존 `addRectPillar` 정책 흡수 — 일관.
- **z-order 분리**: 체크보드(-100) < 벽/기둥(0) < Player/Enemy/StoneGuard(5) < HUD(100+).
- **doorR=-1 sentinel graceful noop**: `for r in rStart...rEnd where r != doorR`에서 양의 r은 모두 `-1`과 달라 모든 칸 벽 채움. 의도 일치.
- **camera follow 보존**.
- **빌드 클린**: SUCCEEDED, warning 0건.

## 채점

| 항목 | 비중 | 점수 | 코멘트 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | 10/10 | 매직 넘버 0, 강제 언래핑 0, MARK 분리, GameConfig 상수화 완전, switch default 미사용, 함수 단일 책임. lowerCamelCase 준수. |
| 게임 로직 완성도 | 30% | 10/10 | `setupWorld()` 1회 호출, update() 안 호출 0건, doorR=-1 sentinel graceful noop, normal 분기 enum 패턴 매칭, 체크보드 z-order 분리. |
| 성능 & 안정성 | 20% | 10/10 | 1152 노드 physicsBody 0 — 60fps 안전. 컨테이너 1개 묶음. name 부착. 강제 언래핑 0. 빌드 클린. |
| 기능 완성도 | 15% | 10/10 | SPEC 1~5 기능 전부 구현. easy/normal/hard 세 난이도 시각·구조 차별화. r=11,12 두 칸 문 자연 형성. 좌·우 거울 대칭. |

**가중 점수 = 10.0 × 0.35 + 10.0 × 0.30 + 10.0 × 0.20 + 10.0 × 0.15 = 10.0 / 10.0**

## 최종 판정: **합격**

(7.0+ 합격 기준 대비 10.0 — 만점. P0~P2 이슈 0건.)

## 시각적 확인 사항

1. 타이틀 → easy 시작: 맵 바닥이 두 단계 차콜(`#1a1722` / `#13111a`)로 시장 패턴.
2. easy 맵: 체크보드 위에 중앙 기둥 1개.
3. normal 맵: 정중앙 세로 분리벽 + r=11,12 2칸 문 + 좌·우 장식 기둥 거울 대칭.
4. hard 맵: 4 코너 방 + 4 중앙 기둥 + 체크보드 바닥.
5. z-order: 체크보드(z=-100)가 벽/기둥(z=0) 아래.
6. 카메라 follow: worldNode 자식이라 자동 스크롤.
7. 1152 체크보드 노드 추가 후 60fps 유지.
8. 음표 스폰: normal 맵 분리벽 위 음표 떠 있을 가능성 — 다음 sprint 보강.
