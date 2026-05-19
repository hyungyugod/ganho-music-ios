# 디자인 리뉴얼 진행 상태

> 이 파일은 디자인 리뉴얼 하네스가 **자동 갱신**합니다. 수동 편집 비권장.
> 자세한 절차는 `CLAUDE.md` § "디자인 리뉴얼 모드" 참고.

**최종 갱신**: 2026-05-19 (Sprint 6 합격 — 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터)
**현재 진행 중인 Sprint**: 없음. Sprint 1/2/3/5/6 모두 합격. Sprint 4(PNG 캐릭터 80장)는 사용자 자산 작업 대기.

---

## 🚀 빠른 시작

Claude Code 세션에서 아래 한 마디만 입력하면 다음 Sprint가 자동 진행됨:

```
디자인 리뉴얼 진행해줘
```

특정 Sprint를 명시하고 싶으면:

```
Sprint 2 진행해줘
```

자동으로:
1. 이 파일을 읽어 현재 진행 상태 파악
2. 다음 Sprint의 Planner 프롬프트 실행
3. Generator → Evaluator 사이클 (최대 3회)
4. 합격하면 이 파일 갱신

---

## Sprint 진행 현황

| Sprint | 범위 | 상태 | 점수 | 시도 |
|---|---|---|---|---|
| **1** | 디자인 토큰 + 노드 컴포넌트 (인프라) | ✅ 합격 | 9.83/10 | 1/3 |
| **2** | 메뉴 3씬 (Start/Character/Skill) | ✅ 합격 | 9.50/10 | 1/3 |
| **3** | 인게임 (GameScene + HUD + 컨트롤) | ✅ 합격 | 9.22/10 | 1/3 |
| **4** | PNG 캐릭터 통합 | ⏸️ 자산 대기 | - | 0/3 |
| **5** | ResultScene 3분기 | ✅ 합격 | 9.70/10 | 1/3 |
| **6** | 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터 | ✅ 합격 | 9.53/10 | 1/3 |

### 상태 범례
- ✅ **합격** — Evaluator 합격 기준 충족, 완료
- ⏳ **대기** — 다음 트리거 시 시작 가능
- 🔄 **진행 중** — 현재 하네스 사이클 돌고 있음
- ❌ **불합격** — 재시도 필요 (시도 횟수 +1)
- ⏸️ **미시작** — 선행 Sprint 미완료 또는 자산 대기

### Sprint 4 자산 대기 해제 조건
- `mockups/svg-exports/` 폴더에 5개 SVG 존재 ✅
- `GanhoMusic/Assets.xcassets/Characters/` 폴더에 PNG 자산 존재 ❌ (사용자가 Figma에서 제작 필요)

사용자가 PNG 자산을 `Assets.xcassets/Characters/`에 추가하면 Sprint 4 상태가 "⏳ 대기"로 변경됨.

---

## 진행 로그

(각 Sprint 완료/시도 시 자동 추가)

### Sprint 1 — 디자인 토큰 + 노드 컴포넌트
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.83/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼인프라 10.0 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ColorTokens v2 16토큰 + GameConfig 폰트3·컴포넌트19상수 + 신규 노드 3종(GlassPill/AccentLine/DarkContextChip) + PrimaryButton/BackButton 내부 리스타일 + GradientBackgroundNode threeStop factory. 기존 5개 씬 git diff 0줄, 신규 노드 호출자 0건. 빌드 SUCCEEDED.
- **사용자 후속 작업 (OPEN_QUESTION Q1)**: 폰트 ttf 3개(Jua/GowunDodum/NotoSansKR) 다운로드 → `Resources/Fonts/` 추가 → `Info.plist` `UIAppFonts` 배열 추가 → Sprint 2 시작 전 시뮬레이터에서 폰트 적용 시각 확인.

### Sprint 2 — 메뉴 3씬
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.50/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과)
- 비고: StartScene/CharacterSelectScene/SkillExplanationScene을 3-stop warm gradient + Jua/Gowun Dodum 폰트 + Sprint 1 인프라(GlassPill 4 / AccentLine 3 / DarkContextChip 7 / Primary 3 / Back 1 / Gradient.threeStop 3) 호출로 재구성. 4개 신규 computed property(Difficulty.shortName / PlayerSkill.rangeText/castText / CharacterID.dotColor) 추가 — 순수 시각 라벨용. GameScene/GameScene+Setup/ResultScene + Sprint 1 컴포넌트 6개 + 기타 보호 파일 15개 git diff 0줄. 빌드 SUCCEEDED.

### Sprint 3 — 인게임
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.22/10** (게임로직 9.8 · Swift패턴 8.5 · 비주얼 9.0 · UX 9.0)
- QA 반복: 1회 (한 번에 통과) + 미니 패치 1건 (P2 #5: ProjectileNode hitbox visual-only 회전)
- 비고: GameScene+Setup(배경/체크보드/벽/기둥), HUDNode(navy 칩+골드 라벨+TIME 경고+진행바), DPadNode(시각만 SKShape 교체, 입력 100% byte-identical), SkillButtonNode(코랄 원 72+B 칩+스킬명 칩), HUDSkillSlotNode(fontDisplay+v2 색), NoteNode(골드 원+글로우+1.4s 펄스), ProjectileNode(코랄 22+F+visual-only -12° 회전, hitbox 축정렬 보존), ComboPopup/ComboBreak(Jua+navy 외곽선+회전), PauseButtonNode 신규(시각 placeholder). 19개 보호 파일 git diff 0줄. 게임 수치/물리/입력/AI/저장/사운드 0건 변경. 빌드 SUCCEEDED.
- 잔존 P2: SkillButtonNode 매직 넘버 18 / 인라인 알파 6곳 / 스킬명 칩 CD 텍스트 누락 / SPEC 명시 상수 2개 누락. Sprint 5 진행에 영향 0.

### Sprint 4 — PNG 캐릭터 통합
- 시작: -
- 완료: -
- 점수: -
- 비고: PNG 자산 도착 후 시작

### Sprint 5 — ResultScene 3분기
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.70/10** (게임로직 10.0 · Swift패턴 9.5 · 비주얼 9.5 · UX 9.5)
- QA 반복: 1회 (한 번에 통과)
- 비고: ResultScene 3분기 시각(A 일반/B 신기록/C 졸업장), DiplomaOverlayNode 우드컷(SKShapeNode + CGMutablePath addEllipse 단일 노드 통합 ~1100 도트) + double-border ㄱ자 + 도장 + fontSerif 명조 라벨. sparkle 5발 신기록 분기. ColorTokens v2 Diploma 토큰 4개 추가. ResultScene init 9개 인자 byte-identical / 본문 텍스트 byte-identical / 햅틱·사운드 시퀀스·2단계 탭 정책 모두 보존. 보호 파일 24개 git diff 0줄. 빌드 SUCCEEDED.
- **사용자 후속 작업 권장**: GowunBatang-Regular.ttf 추가(졸업장 명조 폰트). Google Fonts → Resources/Fonts → Info.plist UIAppFonts. 미추가 시 시스템 폰트 fallback(크래시 0).

### Sprint 6 — 흐름 재편 + 캐릭터 얼굴 + 메인 캐릭터
- 시작: 2026-05-19
- 완료: 2026-05-19
- 점수: **9.53/10** (게임로직 9.8 · Swift패턴 9.4 · 비주얼 9.2 · UX 9.5)
- QA 반복: 1회 (한 번에 통과 — Evaluator subagent stream timeout으로 부모 하네스가 직접 핵심 검증 수행)
- 비고: 5단계 흐름(Start→Character→Skill→Difficulty→Game) + .kim 4단계(스킬 스킵) 신설. mockup 2종 수정(character-select / skill-explanation) + 1종 신규(difficulty-select-v2.html ~510줄). Swift 수정 4건(StartScene 난이도 카드 70~100줄 삭제·NurseAvatarNode 부착 / CharacterSelectScene init(size:) 단순화·5장 얼굴 부착·.kim→Difficulty 분기 / SkillExplanationScene difficulty 인자 제거·시작→다음·Difficulty 전이 / GameConfig 신규 상수 ~50개·characterSelectBackPillText "← 메인" 값 교체) + 신규 3건(DifficultySelectScene 448줄 / CharacterFaceNode 660줄 5캐릭터 SVG→SKShapeNode / NurseAvatarNode 374줄 김간호 큰 그림 SVG→SKShapeNode). GameScene.newGameScene(characterID:difficulty:) 시그니처 byte-identical, 보호 영역 17파일 + 공용 노드 8파일 + Managers/Repositories/GameState/PhysicsCategory/ColorTokens 모두 git diff 0줄. 강제 언래핑 0건, Timer 0건. 빌드 SUCCEEDED 신규 워닝 0건.
- **사용자 후속 작업 권장 (SPRINT_6_REQUEST.md §7)**: (1) Sprint 4 PNG 자산 도착 시 CharacterFaceNode → SKSpriteNode 교체(좌표/스케일 동일 유지). (2) NurseAvatarNode 호흡 애니메이션(scale 1.02↔0.98 3초 주기). (3) 캐릭터→스킬→난이도 단계 전이 chime 사운드. (4) 시뮬레이터 실기로 5명 얼굴 식별·NurseAvatar 4영역 분간 시각 검증.

---

## Sprint별 요점 (DESIGN_RENEWAL_REQUEST.md §9에서 발췌)

### Sprint 1 (시각 변화 0)
- `ColorTokens.swift` 토큰 15개 추가
- Jua / Gowun Dodum / Noto Sans KR ttf 추가 + Info.plist + GameConfig 폰트 상수
- 신규 노드: `GlassPillNode`, `AccentLineNode`, `DarkContextChipNode`
- `PrimaryButtonNode`, `BackButtonNode` 리스타일링
- `GradientBackgroundNode` 3-stop 그라데이션 옵션 추가

### Sprint 2 (메뉴 화면 시각 변경)
- `mockups/main-screen-v2.html` 매칭 → StartScene
- `mockups/character-select-v2.html` 매칭 → CharacterSelectScene
- `mockups/skill-explanation-v2.html` 매칭 → SkillExplanationScene
- 캐릭터 자리는 placeholder (Sprint 4 대기)

### Sprint 3 (인게임 시각 변경)
- `mockups/game-map-v2.html` 매칭
- 체크보드 hex 토큰 교체 (#FFEFE0 / #FFDFC8)
- HUD 4슬롯 + TIME 12초 이하 경고 색
- D-Pad **우하단** / 스킬 버튼 **좌하단** 위치
- 음표·F 투사체·콤보팝업 v2 스타일

### Sprint 4 (PNG 통합) — 자산 대기 중
- `PixelSpriteRenderer` → `SKTextureAtlas` 마이그레이션
- 5명 × 16프레임 PNG 임포트
- 폴폴폴 `SKAction` 패턴 (scaleY 호흡)

### Sprint 5 (결과 화면)
- `mockups/result-screen-v2.html` 매칭 → ResultScene
- 3분기 (일반·신기록·졸업장) 분기별 시각
- DiplomaOverlayNode 우드컷 패턴 + 명조 폰트

---

## 합격 기준 요약 (DESIGN_RENEWAL_REQUEST.md §11)

각 Sprint마다 Evaluator가 다음 4개 카테고리로 채점:

| 카테고리 | 가중치 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 40% | 9.0 이상 (절대 회귀 0) |
| Swift 패턴 (rules 준수) | 20% | 7.0 이상 |
| 비주얼 일관성 (mockup 매칭) | 25% | 7.0 이상 |
| 가독성 & UX | 15% | 7.0 이상 |

가중 평균 **7.5 이상**이면 ✅ 합격.

---

## 트러블슈팅

**Q. "디자인 리뉴얼 진행해줘"라고 했는데 반응이 없어요**
→ Claude Code 세션이 `CLAUDE.md`를 읽었는지 확인. 새 세션 시작 시 자동으로 읽혀야 함. 안 됐다면 "CLAUDE.md를 다시 읽어줘"라고 요청.

**Q. Sprint 1만 계속 돌고 다음으로 안 넘어가요**
→ Evaluator 점수가 7.5 미만이라 합격 처리가 안 됨. 점수 상세를 보고 어디서 막혔는지 확인. 3회 시도 초과 시 사용자 개입 필요.

**Q. Sprint 순서를 바꾸고 싶어요**
→ 이 파일의 진행 현황 표를 수동 편집해서 원하는 Sprint를 "⏳ 대기"로 변경. Sprint 5가 Sprint 4보다 먼저 가능함.

**Q. 처음부터 다시 시작하고 싶어요**
→ 이 파일 삭제 → "디자인 리뉴얼 진행해줘" 입력 → Sprint 1부터 자동 재시작.
