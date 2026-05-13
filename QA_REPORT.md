# QA 검수 보고서 — Phase 6-10 · 콤보 마일스톤 텍스트 팝업

## SPEC 기능 검증

| # | 기능 | 결과 |
|---|---|---|
| 1 | ComboPopupNode 신설 (자가 소멸 6호) | PASS — `Nodes/ComboPopupNode.swift` 78줄. `final class ComboPopupNode: SKNode, SelfDismissingNode` 채택 |
| 2 | GameConfig Combo Popup 상수 6개 | PASS — `GameConfig.swift:305-321` Combo Popup 섹션 신설, 6개 상수 모두 정의 + 사용 |
| 3 | GameScene Properties triggeredComboMilestones | PASS — `GameScene.swift:75-78` `private var triggeredComboMilestones: Set<Int> = []` 신설 |
| 4 | onNoteCollected 클로저 마일스톤 검사 5+줄 | PASS — `GameScene.swift:239-248` sparkle.emit() 이후, note.removeFromParent() 이전 정확 |
| 5 | pbxproj 4지점 등록 (UUID 0031) | PASS — PBXBuildFile/PBXFileReference/Nodes children/Sources phase, 충돌 0 |

## 빌드 검증

- **결과**: BUILD SUCCEEDED
- **명령**: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- **에러**: 0
- **경고**: 0

## 회귀 0줄 검증 (`git diff`)

본 sprint 변경 파일:
- `Config/GameConfig.swift` +18 -0
- `GameScene.swift` +16 -0
- `project.pbxproj` +4 -0
- `Nodes/ComboPopupNode.swift` (신규, 78줄)

**0줄 미접촉**:
- 시스템: ScoreSystem / ContactRouter / SpawnSystem
- 매니저: AudioManager / HapticsManager / BGMPlayer
- 노드: HUDNode / Sparkle / HitFlash / BombFlash / Player / Enemy / Note / Projectile / Airplane / AirforceOverlay / CharacterCard
- 인프라: CameraShakeAction / ColorTokens / SelfDismissingNode / PhysicsCategory
- 씬: TitleScene / ResultScene
- 데이터: Repositories / Models / Protocols

→ SPEC §금지 항목 100% 준수.

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 1건 (SPEC 외 영역) |

### P2 권장 사항 (SPEC 외 — 다음 sprint 처리 대상)
- **SelfDismissingNode protocol 주석 업데이트**: 채택 노드 주석이 Phase 4-R 시점 3개에서 멈춰 있음. 6호까지 누적됐으니 6개 목록 업데이트 권장. 단 본 sprint는 "재사용만" 명시로 회귀 0줄 원칙 우선 — 별도 polish sprint에 처리.

## 핵심 사항 15개 검증 매트릭스

| # | 검증 항목 | 결과 |
|---|---|---|
| 1 | ComboPopupNode가 SelfDismissingNode 채택 (6호) | PASS |
| 2 | SKLabelNode 자식 보유, init(milestone:)에서 텍스트/색 결정 | PASS |
| 3 | animate(): SKAction.group([moveUp, fadeOut, scaleUp]) + sequence([group, removeFromParent]) | PASS |
| 4 | private static func color(for:) — 매핑 + default `.ganhoPaper` fallback | PASS |
| 5 | GameConfig 6개 상수 모두 사용됨 | PASS |
| 6 | 멱등성 가드 — Set<Int> contains/insert 패턴 | PASS |
| 7 | 마일스톤 검사 위치 정확 (sparkle.emit() 이후, removeFromParent 이전) | PASS |
| 8 | 옵션 B 폴링 — scoreSystem.combo 읽기만, ScoreSystem 변경 0 | PASS |
| 9 | 색 토큰 4개 모두 ColorTokens.swift 실재 | PASS (.ganhoPaper / .ganhoPinkNote / .ganhoYellowF / .ganhoBloodAccent) |
| 10 | 매직 넘버 0, 강제 언래핑 0, Timer 0 | PASS |
| 11 | [weak self] + guard let self 패턴 유지 | PASS |
| 12 | 빌드 BUILD SUCCEEDED + 경고 0 | PASS |
| 13 | 회귀 0줄 (16개 영역) | PASS |
| 14 | SPEC §금지 위반 0 | PASS |
| 15 | pbxproj 4지점 UUID 0031 충돌 0 | PASS |

## 통과 항목 (강점)

- **옵션 B 폴링의 정확한 채택**: `scoreSystem.combo` 읽기만으로 ScoreSystem 변경 0줄. 콜백 추가 시 단위 테스트 다시 짜야 하는 부담 회피.
- **멱등성 Set 가드의 우아함**: `triggeredComboMilestones.contains` → `insert` 패턴이 idempotency-key와 동형. 한 판 내 같은 마일스톤 재발화 0 보장.
- **자가 소멸 6호 패턴 정확 답습**: Sparkle(4호)/HitFlash(5호)와 정확히 같은 구조 — addChild → animate() → 자가 제거. 호출자(GameScene)는 5줄로 끝.
- **SKAction.group의 정확한 활용**: move + fade + scale 3채널을 *같은 1초 동안 동시* 진행. `CompletableFuture.allOf` 패턴과 동형.
- **시각 위계 (마일스톤 등급별 색 차등)**: HTTP 상태 코드 색상 비유와 정확히 동형 — 등급이 올라갈수록 강렬한 색. 인지 비용을 색에 위임.
- **HUD vs 팝업 책임 분리**: HUDNode comboLabel(지속 정보) vs ComboPopupNode(일회성 임팩트). read API vs event listener의 명확한 분리.
- **graceful fallback**: 색 매핑 switch default `.ganhoPaper` — 미래 마일스톤 추가 시 안전한 기본값.

## 채점

| 항목 | 점수 | 코멘트 |
|---|---:|---|
| Swift 패턴 일관성 (35%) | **10/10** | MARK 5섹션, guard let, GameConfig 상수, final class, 단일 책임 |
| 게임 로직 완성도 (30%) | **10/10** | 옵션 B 폴링으로 ScoreSystem 무손, 멱등성 Set 가드, SKAction group/sequence 정확 조합, 자가 소멸 6호 패턴 답습 |
| 성능 & 안정성 (20%) | **10/10** | 강제 언래핑 0, Timer 0, [weak self] 유지, 자가 소멸로 메모리 누수 0, 빌드 클린 |
| 기능 완성도 (15%) | **10/10** | SPEC 5개 기능 + 헤더 주석 + 미세 항목 100% 구현, 회귀 0줄 |

**가중 점수**: (10×0.35) + (10×0.30) + (10×0.20) + (10×0.15) = **10.0 / 10**

## 최종 판정: ✅ **합격**

**개선 지시**: 없음.

본 sprint는 SPEC가 명확하고 Generator가 완벽히 답습한 모범 사례. 자가 소멸 6호 패턴이 4호/5호와 정확히 같은 구조로 누적되어, 미래 7호 추가 시 ComboPopupNode를 reference로 쓸 수 있다.

핵심 가치:
1. ScoreSystem 시그니처 변경 없이 *폴링*으로 콤보 마일스톤 감지 → 결합도 ↓
2. `Set<Int>` 멱등성 가드 → 한 판 내 시각 노이즈 0
3. 색 차등으로 *시각 위계* 표현 → "어느 등급"을 1초 안에 전달
4. HUD 라벨(지속 정보) vs 팝업(일회성 임팩트) 책임 분리 → 채널 명확
5. 회귀 0줄 — 16개 영역 git diff 검증 통과
