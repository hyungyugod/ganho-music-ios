# Sprint 7 Phase G · QA Report

## 최종 점수 (가중 평균)

| 카테고리 | 가중치 | 점수 | 기여 |
|---|---|---|---|
| 게임 로직 회귀 0 | 40% | 10.0 | 4.00 |
| Swift 패턴 | 20% | 9.5 | 1.90 |
| 비주얼 일관성 | 25% | 9.0 | 2.25 |
| 가독성 & UX | 15% | 9.5 | 1.43 |
| **합계** | 100% | | **9.58 / 10** |

## 판정: ✅ 합격

전 카테고리 통과선(9.0/7.0/7.0/7.0) 초과 + 보호 영역 0줄 + 빌드 SUCCEEDED.

---

## 카테고리별 상세

### 게임 로직 회귀 0 — 10.0/10

- PlayerNode 이동 로직 byte-identical (update의 velocity·position 계산, init physicsBody rectangleOf 16×20, freeze, updatePixelDirection, tickWalkFrame, refreshTexture, loadTexture)
- physicsBody 좌표·크기 byte-identical
- DPad updateDirection 알고리즘 byte-identical (`|dx|≥|dy|` if/else, 끝 4줄 if-let만 추가)
- touchesEnded/Cancelled .zero set 콜백 미발화 (정지 시 유지)
- Direction.init?(vector:) .zero → nil 보장
- CharacterFaceNode front 5 build 본문 byte-identical (576 lines unchanged)
- CharacterFaceNode.mini factory 0줄 변경 (ScoreboardScene 회귀 0)
- PixelSprite texture 시스템 0줄
- 보호 영역 git diff 0줄 (Phase A~F 결과물, GameScene/GameState/PhysicsCategory/Managers/Repositories/Systems, NoteNode/ProjectileNode/StethoscopeNode/4 villain nodes)

### Swift 패턴 — 9.5/10

- 강제 언래핑 0건, Timer 0건, switch default 0건 (4 case exhaustive)
- guard/if let 패턴 일관
- MARK 구분 일관 (`Sprint 7 Phase G`)
- GameConfig 외부화 (playerFaceChildScale=0.5, ZPosition=1, 매직 넘버 0)
- weak self 캡처 — setupDPad의 콜백 등록 명시
- enum String rawValue 활용 (디버거 식별)

P2 -0.5: CharacterFaceNode 1101 lines (spritekit-rules §11 300줄 한계 추가 초과) — 후속 분리 후보.

### 비주얼 일관성 — 9.0/10

- face child 자연 정합 (scale 0.5 × ±32~34 좌표계 → ±16~17pt vs PlayerNode visual 32×40)
- zPos 1로 texture(zPos 0) 위 자연 오버레이 (OQ-2 자연 겹침 채택)
- 5×4 path 시안 완비 (10 helper 모두 navy/hairBrown/skin 토큰 재사용)
- left/right 미러링 path 중복 0 (xScale=-1)
- mockup 후반부 정확 20셀

P2 -1.0: back/side 헤어 색이 hairBrown 단색 위주 — 캐릭터별 보강 후보.

### 가독성 & UX — 9.5/10

- Direction enum 좌표 약속 doc-comment 명시 (dx/dy → front/back/left/right + 임계값 0.001 + |dx|≥|dy| 우선)
- PixelDirection vs Direction 분리 명시 (두 enum 책임 분리)
- lastFacing 가드 의도 doc (매 프레임 호출 비용 0)
- buildFacingChildren 캐릭터 전환 안전 주석

P2 -0.5: PlayerNode 307 lines 단일 책임 한계 근접 — PlayerFacingComponent 분리 후속 후보.

---

## 회귀 검증 grep

| 검증 | 결과 |
|---|---|
| Direction 4 case + init? | ✅ |
| PlayerNode 신규 프로퍼티 (faceNodes/lastFacing) | ✅ |
| PlayerNode.facing | ✅ |
| CharacterFaceNode 신규 init(id:facing:) + convenience init(id:) | ✅ |
| mini factory 보존 | ✅ |
| 기존 5 build 본문 boundary 0 | ✅ (576 lines unchanged) |
| 신규 back/side 분기 + 10 helper | ✅ |
| DPad onDirectionChanged + 1줄 호출 | ✅ |
| DPad updateDirection 본문 byte-identical | ✅ |
| GameScene+Setup 콜백 등록 + [weak self] | ✅ |
| GameConfig 상수 2개 | ✅ |
| pbxproj Direction.swift 등록 4줄 | ✅ |
| 강제 언래핑 (5 파일) | **0건** ✅ |
| Timer (5 파일) | **0건** ✅ |
| switch default | **0건** ✅ |
| Mockup Phase G 20셀 | ✅ |

---

## 보호 영역 git diff 0줄

| 보호 그룹 | 결과 |
|---|---|
| Phase A·B·C·D·E·F 결과물 | 0줄 ✅ |
| GameScene/GameState/PhysicsCategory/Managers/Repositories/Systems | 0줄 ✅ |
| NoteNode/ProjectileNode/StethoscopeNode/4 villain nodes | 0줄 ✅ |
| CharacterFaceNode 기존 5 build 본문 | 0줄 ✅ (576 lines diff 0) |
| CharacterFaceNode.mini factory | 0줄 ✅ |
| PlayerNode 이동/physicsBody/PixelSprite 시스템 | 0줄 ✅ |
| DPad updateDirection if/else 본문 | 0줄 ✅ |

전체 변경: Direction.swift(신규) + PlayerNode/CharacterFaceNode/DPadNode/GameScene+Setup/GameConfig(수정) + pbxproj(등록) + mockup(후반부 추가).

---

## 빌드 결과

**BUILD SUCCEEDED** ✅

- 컴파일 에러: 0
- 신규 워닝: 0
- 무관 워닝 3건(폰트 duplicate)

---

## Sprint 7 전체 요약 (모든 Phase 합격 🎉)

| Phase | 작업 | QA 점수 |
|---|---|---|
| **A** | 캐릭터 카드 NIKKE 4:5 리뉴얼 | **9.45** |
| **B** | 스킬 설명 겹침 해소 | **9.77** |
| **C** | 난이도 카드 색 위계 | **9.83** |
| **D** | 결과창 정리 + ScoreboardScene 신설 | **9.83** |
| **E** | 카운트다운 오버레이 | **9.76** |
| **F** | 빌런 4종 시각 리뉴얼 + 박병장 신규 | **9.10** |
| **G** | 플레이어 4방향 스프라이트 + Direction layer | **9.58** |

**Sprint 7 평균: 9.62 / 10.0** — 모든 Phase 통과선(7.5) 큰 폭 초과, 합격 7회/7회 (100%).

---

## 최종 판정: ✅ 합격 (9.58/10) + Sprint 7 전체 완료 (9.62/10)

**잔존 P2 (모든 Phase 합격 영향 0)**:
1. CharacterFaceNode 1101 lines — `+Front/+Back/+Side` extension 분리 후보
2. back/side 헤어 색 캐릭터별 보강 후보
3. PlayerNode PixelSprite + face child 하이브리드 정리 후보
4. Phase F 시각 디테일 매직 넘버 8건 정리
5. V3 상수 명명 규칙 일괄 정리
