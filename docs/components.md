# 컴포넌트 목록 & 작업 체크리스트 — GanhoMusic iOS

현재 구현 상태와 앞으로 만들 컴포넌트 목록.
Generator가 새 기능 추가 전 반드시 읽고 현재 상태를 파악한다.

**선행 참조 문서**:
- `docs/game-design.md` — 게임 디자인 결정 (왜 이 컴포넌트를 만드는가)
- `docs/architecture-mapping.md` — Spring(clonebose) ↔ Swift/SpriteKit 매핑 (멘탈 모델)
- `docs/spritekit-rules.md` §11 — 파일 분리 전략 (어디에 만드는가)
- `docs/assets.md` — 컬러/폰트/사운드 토큰 (어떻게 보이게 만드는가)

**플랫폼 정책**: iOS 타겟만 정식 지원. `GanhoMusic tvOS/`, `GanhoMusic macOS/` 폴더는 Xcode 템플릿 잔여물이며 수정 금지.

---

## 현재 구현 상태 (Phase 0 완료 기준)

| 파일 | 상태 | 설명 |
|---|---|---|
| `GameScene.swift` | ✅ 템플릿 | Xcode 기본 SpriteKit 템플릿. Hello World 씬. |
| `GameViewController.swift` | ✅ 템플릿 | SKView에 씬 로드하는 기본 코드 |
| `AppDelegate.swift` | ✅ 템플릿 | 앱 생명주기 기본 |
| `Assets.xcassets` | ✅ 빈 상태 | 이미지/사운드 에셋 없음 |

> **Phase 0 완료**: Xcode 프로젝트 생성, iPhone 전용 설정, Landscape 설정, 시뮬레이터 첫 빌드 성공.

---

## 컴포넌트 구현 로드맵

### Phase 1 — 플레이어 이동 (진행 예정)

| 컴포넌트 | 권장 위치 | 상태 |
|---|---|---|
| `GameConfig` 상수 enum | `Config/GameConfig.swift` | ⬜ 미구현 |
| `GameState` enum | `Config/GameState.swift` | ⬜ 미구현 |
| `PhysicsCategory` 비트마스크 | `Config/PhysicsCategory.swift` | ⬜ 미구현 |
| `ColorTokens` extension | `Config/ColorTokens.swift` | ⬜ 미구현 |
| `PlayerNode` (김간호 픽셀) | `Nodes/PlayerNode.swift` | ⬜ 미구현 |
| 스와이프 이동 입력 | `Systems/InputSystem.swift` | ⬜ 미구현 |
| 화면 경계 충돌 | `Scenes/GameScene.swift` | ⬜ 미구현 |

### Phase 2 — 핵심 게임 루프

| 컴포넌트 | 권장 위치 | 상태 |
|---|---|---|
| `NoteNode` 음표 ♪ | `Nodes/NoteNode.swift` | ⬜ 미구현 |
| 음표 스폰 시스템 (BPM 동기) | `Systems/SpawnSystem.swift` | ⬜ 미구현 |
| 음표 수집 충돌 감지 | `Scenes/GameScene.swift` (delegate) | ⬜ 미구현 |
| 점수 / 콤보 시스템 | `Systems/ScoreSystem.swift` | ⬜ 미구현 |
| 비트 동기 / On-Beat 판정 | `Systems/BeatSystem.swift` | ⬜ 미구현 |
| `HUDNode` (점수/타이머/콤보) | `Nodes/HUDNode.swift` | ⬜ 미구현 |
| 45초 타이머 | `Scenes/GameScene.swift` | ⬜ 미구현 |
| `EnemyNode` 수간호사 NPC | `Nodes/EnemyNode.swift` | ⬜ 미구현 |
| `ProjectileNode` F 투사체 | `Nodes/ProjectileNode.swift` | ⬜ 미구현 |
| 보호막(Shield) 시스템 | `Systems/ScoreSystem.swift` | ⬜ 미구현 |

### Phase 3 — UI 화면 흐름

| 컴포넌트 | 권장 위치 | 상태 |
|---|---|---|
| `TitleScene` 타이틀 화면 | `Scenes/TitleScene.swift` | ⬜ 미구현 |
| `GameOverScene` 결과 화면 | `Scenes/GameOverScene.swift` | ⬜ 미구현 |
| 최고 기록 저장 (UserDefaults) | `Repositories/ScoreRepository.swift` | ⬜ 미구현 |
| `Score` 값 객체 | `Models/Score.swift` | ⬜ 미구현 |
| 화면 전환 애니메이션 | `Scenes/GameScene.swift` (presentScene) | ⬜ 미구현 |

### Phase 4 — 폴리싱

| 컴포넌트 | 권장 위치 | 상태 |
|---|---|---|
| `AudioManager` 효과음 | `Managers/AudioManager.swift` | ⬜ 미구현 |
| BGM (FL Studio 자체 제작) | `Managers/AudioManager.swift` + `Resources/` | ⬜ 미구현 |
| `HapticsManager` 진동 피드백 | `Managers/HapticsManager.swift` | ⬜ 미구현 |
| 앱 아이콘 | `Resources/Assets.xcassets/AppIcon` | ⬜ 미구현 |
| 픽셀 아트 스프라이트 | `Resources/Assets.xcassets/Sprites.spriteatlas` | ⬜ 미구현 |

### Phase 7 — 백엔드 연동 (BACKEND.md 참조)

| 컴포넌트 | 권장 위치 | 상태 |
|---|---|---|
| Supabase 클라이언트 초기화 | `Managers/SupabaseManager.swift` | ⬜ 미구현 |
| Apple Sign In | `Scenes/TitleScene.swift` + Manager | ⬜ 미구현 |
| `LeaderboardRepository` | `Repositories/LeaderboardRepository.swift` | ⬜ 미구현 |
| `ScoreDTO` (서버 통신용) | `Models/DTO/ScoreDTO.swift` | ⬜ 미구현 |
| 리더보드 화면 | `Scenes/LeaderboardScene.swift` | ⬜ 미구현 |

---

## 게임 세계관 레퍼런스

웹 버전에서 가져오는 설정값 (모바일 재설계 기준):

| 요소 | 웹 버전 | 모바일 버전 |
|---|---|---|
| 화면 크기 | 640×400 (가로) | iPhone Landscape 풀스크린 |
| 게임 시간 | 45초 | 45초 유지 |
| 조작 | 키보드 WASD/화살표 | 스와이프 또는 D-Pad |
| 플레이어 | 김간호 픽셀 캐릭터 | 동일 세계관, 단순화된 픽셀 |
| 적 | 수간호사 (F 투사체) | 동일 |
| 수집물 | 음표 (♪) | 동일 |
| 난이도 | 하/중/상 | MVP는 단일 난이도 |
| 캐릭터 선택 | 5명 | MVP는 김간호 1명 |

---

## 작업 체크리스트 (Generator가 구현 완료 후 체크)

### Swift 패턴
- [ ] 강제 언래핑(`!`) 미사용
- [ ] `guard let` / `if let` 옵셔널 처리
- [ ] `MARK:` 섹션 구분 사용
- [ ] 매직 넘버 → `GameConfig` enum 상수화
- [ ] 클로저 내 `[weak self]` 캡처

### SpriteKit 패턴
- [ ] 초기화는 `didMove(to:)`에서
- [ ] `dt` (delta time) 기반 이동
- [ ] 스폰은 `SKAction.repeatForever` 사용 (Timer 금지)
- [ ] 충돌 처리 후 노드 즉시 삭제 금지 (다음 프레임에)
- [ ] HUD 노드 별도 분리

### 게임 로직
- [ ] `GameState` enum으로 상태 관리
- [ ] `PhysicsCategory` 비트마스크 정의
- [ ] 씬 종료 시 액션/타이머 정리

### 빌드
- [ ] Xcode 빌드 에러 0개
- [ ] 시뮬레이터 실행 확인
- [ ] 콘솔 경고 최소화
