# 김간호는 음악박사 — Mobile Edition

> 간호학과 학생 김간호가 수간호사의 호통(F 투사체)을 피하며 음표를 모아 음악박사가 되는 픽셀 액션 게임.
> 웹 버전(640×400)을 영감 삼아 iPhone Landscape 전용으로 재설계한 모바일 포팅 학습 프로젝트.

## 프로젝트 정체성

- **장르**: 픽셀 dodge-collect + 가벼운 리듬 요소
- **세션 길이**: 45초 (모바일 짧은 호흡)
- **타겟**: iPhone Landscape, iOS 16.0+
- **개발 스택**: Swift 5 / SpriteKit / SwiftUI(메뉴 영역, 추후) / Xcode 26.x

## 학습 목표

이 프로젝트는 단순 게임 출시가 아니라 두 가지 동시 학습:

1. **iOS 게임 개발 베이스라인** — Swift / SpriteKit 패턴 체득
2. **AI 협업 파이프라인 운영** — Planner → Generator → Evaluator 3-Agent 하네스로 기능 단위 자동화

### Spring(Java) 경험자라면 시작 순서

폴더 구조를 의도적으로 clonebose(Spring) 와 비슷하게 가져갔다. **익숙한 폴더 이름으로 멘탈 모델 절반은 이식하고**, 나머지 절반(Swift 고유 문법)에 학습 노력을 집중하기 위함.

1. `docs/architecture-mapping.md` 정독 — Spring → SpriteKit 폴더 매핑 + Swift 고유 패턴
2. `docs/swift-rules.md` — Swift 컨벤션 (강제 언래핑·Timer 금지 등)
3. `docs/spritekit-rules.md` §11 — 실제 디렉터리 구조
4. `docs/game-design.md` — "왜 이렇게 만드는가"

## 빌드 / 실행

```bash
# 시뮬레이터 실행
open GanhoMusic/GanhoMusic.xcodeproj
# Xcode에서 ⌘R (시뮬레이터: iPhone 15 권장)

# CLI 빌드 검증
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
  -scheme "GanhoMusic iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

## 진척률

| Phase | 내용 | 상태 |
|---|---|---|
| 0 | Xcode 프로젝트 초기 셋업, Landscape 설정 | ✅ 완료 |
| 1 | 플레이어 이동, 입력, 화면 경계 | ⬜ 진행 예정 |
| 2 | 음표 스폰, 점수, HUD, 적 NPC, 타이머 | ⬜ |
| 3 | 타이틀 / 결과 화면, 최고 기록 | ⬜ |
| 4 | 폴리싱 (효과음, BGM, 진동, 픽셀 아트) | ⬜ |

## 문서 지도

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | AI 협업 하네스 운영 룰 |
| `docs/architecture-mapping.md` | **Spring(clonebose) ↔ Swift/SpriteKit 매핑** (Spring 출신자 필독) |
| `docs/game-design.md` | 게임 디자인 결정 (코어 루프, 톤, 점수 등) |
| `docs/GDD.md` | 웹 버전 동일 기능 명세 (v2.0, 전체 게임 정의) |
| `docs/BACKEND.md` | Supabase 기반 백엔드 설계 (Phase 7) |
| `docs/swift-rules.md` | Swift 코딩 컨벤션 |
| `docs/spritekit-rules.md` | SpriteKit 노드/씬/물리/액션 패턴 + 디렉터리 구조 |
| `docs/xcode-import-guide.md` | 디스크 디렉터리를 Xcode에 그룹으로 등록하는 절차 |
| `docs/assets.md` | 컬러 팔레트, 폰트, 사운드 정책 |
| `docs/components.md` | 구현 컴포넌트 목록 + 작업 체크리스트 |
| `.claude/agents/*.md` | Planner / Generator / Evaluator 서브에이전트 정의 |

## 멀티플랫폼 정책

`GanhoMusic tvOS/`, `GanhoMusic macOS/` 폴더는 Xcode 템플릿 잔여물이며 **유지보수 대상 아님**. iOS 타겟만 정식 지원.

## 라이선스

학습 프로젝트. 라이선스 미정.
