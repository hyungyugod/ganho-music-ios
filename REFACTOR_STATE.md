# REFACTOR_STATE — 그랜드 리팩토링 v3 진행 상태

> 하네스가 자동 갱신한다. 단일 진실 원천: `refactor/00_MASTER_PLAN.md`

## Phase 현황

| Phase | 이름 | 상태 | 점수 | 시도 | 완료일 |
|---|---|---|---|---|---|
| R0 | 기반 정리 (행동 불변) | ✅ 합격 | 9.0/10 | 1 | 2026-06-10 |
| R1 | 엔진 코어 | ✅ 합격 | 8.6/10 | 2 | 2026-06-10 |
| R2 | 게임필 (juice) | ⏳ 대기 | - | 0 | - |
| R3 | 디자인 시스템 v3 인프라 | 🔒 미착수 | - | 0 | - |
| R4 | 메뉴 씬 재구축 | 🔒 미착수 | - | 0 | - |
| R5 | 결과·기록·프로필 재구축 | 🔒 미착수 | - | 0 | - |
| R6 | 메타 시스템 | 🔒 미착수 | - | 0 | - |
| R7 | 페이싱·콘텐츠 튜닝 | 🔒 미착수 | - | 0 | - |
| R8 | 통합 QA·릴리즈 준비 | 🔒 미착수 | - | 0 | - |

## 진행 로그

- 2026-06-10 설계서 v3 작성 완료 (refactor/00~03 + AGENT_PROMPT). R0 대기.
- 2026-06-10 **R0 합격 (1회차, 가중 9.0/10)** — GameConfig.swift(3,869줄) 소멸 → Config 7분할(GameplayTuning/FeelTuning/UILayout/Palette보류·Typography/ZOrder/StorageKeys 등), 호출부 111파일 갱신. 버전 suffix 309건 박멸(삭제 157·개명 152). 삭제 목록 9항 처리(CharacterFullBodyNode·GradientBackgroundNode 파일 삭제, ResultScene 좀비 라벨 7종, ColorTokens 미참조 27토큰, .codex/). PixelCharacterAnimating 프로토콜 추출(4노드, 중복 1벌화). UserDefaults 키 15종 StorageKeys 이동(byte-equal). 값 보존 전수 대조: 라이브 상수 변경 0건. P2 잔여: 전 씬 터치 주행 미실증(터치 자동화 부재) — R1 진입 전 수동 1회 권장.
- 2026-06-10 **R1 합격 (2회차, 가중 8.6/10)** — 신규 4파일(Core/EntityRegistry·ObjectPool·FrameStats + Rendering/TextureAtlasStore) + 수정 20파일. update 경로 enumerateChildNodes 0건(DangerWarnings 2·EnemyNode 1 제거, note/projectile/stethoscope name-query 전폐). ObjectPool 4종(F 12/Note 16/Steth 6/Popup 8 예열, 전 소멸 경로 회수화·이중 회수 가드·DEBUG 재사용 로그). 바닥 640→1노드(사전 렌더 텍스처, 시각 동일). static 텍스처 캐시 5벌 → TextureAtlasStore 단일화, 벽 타일 베이크 4→1노드, NoteNode halo·sparkle 베이크 3→1노드(2회차 — physicsBody 16×16 byte-equal). update 명시 파이프라인(input→…→registry.compact) + FrameStats(DEBUG 격리). BGM setRate 양자화 가드(~300회→≤16회). 노드 수 1,491 → easy 평시 269·최악 ~282(게이트 ≤300 충족). **R2 이관**: hard 평시 ~368 — F/청진기 가독성 자식 2종(near-miss 펄스 독립 scale 애니)이 행동 불변 제약상 R1 내 통합 불가 → R2 halo/outline 연출 재설계 시 ≤300 재충족할 것(오케스트레이터 게이트 해석 확정, QA_REPORT 2회차 근거). P2 잔여: GameScene.swift 415줄·GameScene+Setup.swift 487줄(300줄 규칙 이월, 후속 Phase 분리 검토)·런타임 스모크 미실증(시뮬레이터 수동 1회 권장 — easy·hard 각 1판, 풀 재사용 로그·FrameStats 노드 수 확인).
