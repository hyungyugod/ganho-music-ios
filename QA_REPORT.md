# QA 검수 보고서 — Phase 4-5 AIRFORCE 폭탄 화면 플래시

## SPEC 기능 검증

- [PASS] **기능 1 — `BombFlashNode` 클래스 신규**: `final class : SKSpriteNode`, `init`에서 `color: .ganhoPaper`, `size: .zero`, `name = "bombFlash"`, `zPosition = 250`, `alpha = 0` 모두 부여 확인. `flash(sceneSize:)`에서 `size = sceneSize`, `position = .zero` 갱신 후 `SKAction.sequence([wait, fadeIn, fadeOut, cleanup])` 정확. 자가 소멸 fire-and-forget 패턴 일치.
- [PASS] **기능 2 — `GameConfig.swift` 3 상수**: 209~216행에 `bombFlashDelay = 2.1`, `bombFlashFadeInDuration = 0.07`, `bombFlashFadeOutDuration = 0.35` 모두 `airforceOverlayFadeOutDuration` 다음 줄(Airforce 섹션 내부 끝)에 추가됨. 매직 넘버 0건.
- [PASS] **기능 3 — `GameScene.swift` 헤더 MARK + doc + 본문 3줄**: 헤더 26행 Phase 4-5 추가, doc 198행 Phase 4-5 코멘트 추가, 209~211행에 `let bomb = BombFlashNode()` / `cameraNode.addChild(bomb)` / `bomb.flash(sceneSize: size)` 3줄 정확. 기존 7줄(가드 2 + 비행기 4 + 오버레이 3) 한 줄도 변경 없음.
- [PASS] **기능 4 — `project.pbxproj` 4곳 식별자 0020 등록**: PBXBuildFile(31행 `A1C0F1B0...0020`), PBXFileReference(56행 `A1C0F1A0...0020`), Nodes 그룹 children(194행), iOS Sources phase(428행) 4곳 모두 일관 등록. macOS/tvOS Sources phase는 `files = ();` 빈 상태 유지.

## 빌드 검증

- 결과: **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 경고: 0건 (`grep -E "warning:|error:"` 결과 빈 출력)
- 에러: 0건

## 회귀 검증 (모두 변경 0줄)

| 파일 | 변경 줄 수 |
|---|---|
| `Nodes/AirplaneNode.swift` | 0 (CLEAN) |
| `Nodes/AirforceOverlayNode.swift` | 0 (CLEAN) |
| `Systems/ContactRouter.swift` | 0 (CLEAN) |
| `Config/PhysicsCategory.swift` | 0 (CLEAN) |
| `Nodes/StoneGuardNode.swift` | 0 (CLEAN) |
| `GameScene+Setup.swift` | 0 (CLEAN) |
| `Nodes/EnemyNode.swift` | 0 (CLEAN) |
| `Nodes/PlayerNode.swift` | 0 (CLEAN) |
| `Nodes/NoteNode.swift` | 0 (CLEAN) |
| `Nodes/ProjectileNode.swift` | 0 (CLEAN) |
| `Nodes/HUDNode.swift` | 0 (CLEAN) |
| `Nodes/DPadNode.swift` | 0 (CLEAN) |
| `Scenes/TitleScene.swift` | 0 (CLEAN) |
| `Scenes/ResultScene.swift` | 0 (CLEAN) |
| `Config/ColorTokens.swift` | 0 (CLEAN) |
| macOS Sources phase | `files = ();` 유지 |
| tvOS Sources phase | `files = ();` 유지 |
| 기존 GameConfig airplane 4 상수 | 줄 변경 0 |
| 기존 GameConfig airforceOverlay 3 상수 | 줄 변경 0 |
| 기존 trigger 7줄 (가드 2 + 비행기 4 + 오버레이 3) | 줄 변경 0 |

OoS 침범 0건. 모든 추가는 *순수 신규* 또는 *섹션 끝 append*.

## 검증 시나리오 (a)~(i) 결과

| # | 시나리오 | 검증 방법 | 결과 |
|---|---|---|---|
| (a) | `BombFlashNode()` 호출 1곳 | `grep -rn "BombFlashNode()"` → GameScene.swift:209 1건 | PASS |
| (b) | trigger 본문 폭탄 3줄 | GameScene.swift:209~211 `let bomb = BombFlashNode()` / `cameraNode.addChild(bomb)` / `bomb.flash(sceneSize: size)` 일치 | PASS |
| (c) | wait 2.1 정확 | BombFlashNode.swift:36 `SKAction.wait(forDuration: GameConfig.bombFlashDelay)`, GameConfig.swift:211 `bombFlashDelay = 2.1` | PASS |
| (d) | sequence 순서 `[wait, fadeIn, fadeOut, cleanup]` | BombFlashNode.swift:40 `run(.sequence([wait, fadeIn, fadeOut, cleanup]))` 정확 | PASS |
| (e) | sequence 마지막 `removeFromParent` | BombFlashNode.swift:39 `let cleanup = SKAction.removeFromParent()` 시퀀스 마지막 단계 | PASS |
| (f) | 게임 변경 0 | `update()` / `endGame()` / `gameState` / 콤보 / 점수 / HUD 미수정 | PASS |
| (g) | AI 변경 0 | Player/Enemy/Projectile/StoneGuard/SpawnSystem/ContactRouter 모두 0줄 변경 | PASS |
| (h) | `airforceTriggered` 가드 유지 | GameScene.swift:200~201 `if airforceTriggered { return } / airforceTriggered = true` 위치·내용 그대로. 폭탄 3줄은 가드 *아래* 위치 → 1회만 발화 보장 | PASS |
| (i) | 빌드 SUCCEEDED + 경고 0 | `** BUILD SUCCEEDED **`, `grep "warning:\|error:"` 빈 출력 | PASS |

## 추가 검증 항목

- **alpha = 0 init**: BombFlashNode.swift:22 — fadeIn 첫 프레임 즉시 가시화 방지, *번쩍* 임팩트 보장
- **size = .zero init / flash에서 갱신**: BombFlashNode.swift:19, 34 — scene.size 의존 분리 (AirplaneNode 패턴 답습)
- **zPosition = 250**: BombFlashNode.swift:21 — HUD(100), AirforceOverlay(200) 위로 정확 배치
- **`cameraNode.addChild(bomb)` 단일 호출**: GameScene.swift:210, worldNode/self/hud 사용 0
- **매직 넘버 0건**: 2.1, 0.07, 0.35 모두 GameConfig 상수로만 참조 — flash 메서드 내부에 숫자 리터럴 없음
- **bombFlashDelay = 2.1 합산 검증**: `1.5 (displayDuration) + 0.3 (fadeOutDuration) + 0.3 (간격) = 2.1` 일치, doc 주석에도 명시
- **`.ganhoPaper` 재사용**: ColorTokens 새 토큰 신설 0, 기존 토큰만 참조
- **`[weak self]` 캡처 불필요 정확**: flash 메서드는 self·인스턴스 프로퍼티 미사용 (sceneSize 파라미터로 받음). 액션 시퀀스 내부에 `run` 클로저 없음 → 캡처 부재가 정상

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음. 자가 소멸 노드 3회차 도달(AirplaneNode / AirforceOverlayNode / BombFlashNode)로 `protocol SelfDismissingNode` 추출 *후보 인식*은 SPEC §학습가치에 명시되어 있고, 추출 자체는 별도 sprint(OoS)로 의도적 보류 — 본 sprint 범위 밖이므로 감점 사유 아님.

## 통과 항목

- Swift 패턴: 강제 언래핑 0 (BombFlashNode 본문 `!` 0건, `fatalError`만 init(coder:) 표준 패턴), guard 불필요(옵셔널 분기 없음), MARK 2개(`Init`, `Flash`), 한글 변수명 0, 매직 넘버 0
- SpriteKit 패턴: SKAction.sequence 4단(wait → fadeIn → fadeOut → removeFromParent), Timer/DispatchQueue 0, dt 무관(시각 액션), didMove 미변경(기존 골격 보존), HUD와 분리(cameraNode 자식 zPosition 250)
- 충돌 안정성: PhysicsBody 부착 0 (순수 시각), didBegin 내부 노드 즉시 삭제 미발생 (자기 액션 마지막 단계가 self.removeFromParent — SKAction 컨텍스트로 안전)
- 메모리: 클로저 자체 0 → 캡처 누수 위험 0, SKAction.sequence 종료 시 자가 detach
- 파일 분리: 신규 SKNode 서브클래스가 `Nodes/` 디렉터리에 정확 배치, `GameScene.swift` 246줄(300 미만 유지)
- Sprint 범위: SPEC In Scope 4개 모두 충족, OoS 14개 항목 위반 0
- 게임 디자인 정합성: `.ganhoPaper` 16색 팔레트 내 토큰, "나와라 박병장!" 톤 보존, 시퀀스 클라이맥스 임팩트 의도와 일치

---

## 채점

| 항목 | 비중 | 점수 | 코멘트 |
|---|---|---|---|
| Swift 패턴 일관성 | 0.35 | **10/10** | 강제 언래핑 0, 매직 넘버 0, MARK 분리, 네이밍·doc 주석 모범적. GameConfig 3상수 추가도 섹션 위치 정확. |
| 게임 로직 완성도 | 0.30 | **10/10** | SKAction.sequence 4단 정확, Timer/DispatchQueue 0, 자가 소멸 패턴 일관, `airforceTriggered` 1회 가드 그대로. |
| 성능 & 안정성 | 0.20 | **10/10** | 빌드 SUCCEEDED + 경고 0, 클로저 0 → 캡처 누수 위험 0, PhysicsBody 0, 자가 detach로 메모리 누수 없음. |
| 기능 완성도 | 0.15 | **10/10** | SPEC 4개 기능 + 시나리오 (a)~(i) 9개 + 추가 검증 7개 항목 모두 PASS. OoS 14항 위반 0. |

**가중 점수**: (10 × 0.35) + (10 × 0.30) + (10 × 0.20) + (10 × 0.15) = **10.00 / 10.0**

## 최종 판정: **합격**

자체 점검(SELF_CHECK.md)과 실제 코드·빌드 결과가 100% 일치한다. SPEC의 "기존 줄 변경 0 + 신규/추가만" 정책을 정확히 준수했고, 회귀 영향 범위는 정확히 0이다. AirplaneNode / AirforceOverlayNode 답습 3회차 도달로 자가 소멸 노드 패턴이 *Rule of three* 단계에 들어섰으며, SPEC도 protocol 추출을 **다음 sprint로 의도적 보류**한 점이 명시되어 있어 본 sprint 범위 결정도 합리적이다.

**구체적 개선 지시**: 없음. 다음 sprint 후보 — Phase 4-6(수간호사 도주 효과), Phase 4-7(F 재스폰 변형), 또는 자가 소멸 노드 protocol 추출 리팩터 sprint.
