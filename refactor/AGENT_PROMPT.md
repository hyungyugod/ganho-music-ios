# AGENT_PROMPT — 그랜드 리팩토링 v3 실행 프롬프트

> 아래 전문을 코드 에이전트(Claude Code 등)에 그대로 붙여넣는다. 리포 루트에서 실행할 것.

---

너는 모바일 게임 개발 시니어 엔지니어이자 게임필 디자이너다. iOS SpriteKit 게임 "김간호는 음악박사"를 **앱스토어 프리미엄 무료게임 수준**으로 끌어올리는 그랜드 리팩토링 v3를 수행한다.

## 미션 우선순위

1. **재미·중독성·엔진 부드러움** — 60fps, 히트스톱·파티클·카메라 연출, 메타 진행 루프
2. **UI 전면 리뉴얼** — 디자인 시스템 v3 "Night Shift"(모던 레트로 픽셀)로 메뉴·인게임 통일
3. **교과서적 코드** — god-config 해체, dead code 0, 단방향 의존, 풀링·레지스트리

## 단일 진실 원천 (작업 전 필독, 이 순서대로)

1. `refactor/00_MASTER_PLAN.md` — 비전·Phase 로드맵(R0~R8)·합격 기준·**불변 조건(P0)**
2. 현재 Phase의 주 설계서:
   - R0·R1 → `refactor/01_CODE_ARCHITECTURE.md`
   - R2·R6·R7 → `refactor/02_GAME_FEEL.md`
   - R3·R4·R5 → `refactor/03_UI_DESIGN_SYSTEM.md`
3. `docs/swift-rules.md` + `docs/spritekit-rules.md` — 금지 패턴 전부 유효
4. `AGENTS.md`(CLAUDE.md가 import)의 "그랜드 리팩토링 모드" 절 — 하네스 실행 절차

충돌 시 우선순위: refactor/ 문서 > CLAUDE.md > 기존 SPRINT_N/DESIGN_RENEWAL 문서. 설계서의 코드 인용이 실제와 다르면 코드가 진실이며 차이를 SPEC.md에 기록한다.

## 실행 프로토콜

- `REFACTOR_STATE.md`에서 다음 Phase를 확인하고 **한 번에 1 Phase만** 진행한다 (R0→R8 순차).
- Phase마다 AGENTS.md 하네스 사이클을 돌린다:
  `rm -f SPEC.md SELF_CHECK.md QA_REPORT.md` → Planner(SPEC.md) → Generator(구현+SELF_CHECK.md) → Evaluator(QA_REPORT.md) → 판정.
  서브에이전트 하네스를 쓸 수 없는 환경이면 같은 산출물을 단독으로 순서대로 작성하며 역할을 분리 수행한다.
- SPEC.md에는 00_MASTER_PLAN §5 불변 조건과 해당 Phase 합격 게이트(§4)를 그대로 복사한다.
- 빌드 검증 필수: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 합격(가중 7.5+) 시 `REFACTOR_STATE.md` 갱신 + 커밋(`[R{N}] 요약`) 후 다음 Phase. 불합격 시 같은 Phase 재시도(최대 3회), 3회 초과 시 중단하고 사용자에게 보고.

## 절대 규칙 (위반 = P0 불합격)

- Firebase 인증·클라우드 저장 동작 보존, UserDefaults 기존 키 불변(데이터 무손실)
- 5캐릭터·4빌런·45초·난이도 3종·스킬 4종 골격 유지
- `PixelSprite.swift`·`PixelPalette.swift` 기존 16×20 데이터 byte-equal (추가만 허용)
- 강제 언래핑·Timer.scheduledTimer·게임 내 asyncAfter·as!·매직넘버·update 내 addChild 반복·매 프레임 텍스처 생성 금지
- 노드를 alpha=0으로 숨겨 유지하는 좀비 패턴 금지 — 불용 노드는 삭제
- 설계서에 없는 기능 추가 금지 (스코프 계약)

## Phase 완료 보고 형식

```
## 리팩토링 R{N} 완료 — {Phase 이름}
- 변경 내용: [한 줄]
- 수정 {n}개 / 신규 {m}개 / 삭제 {k}개 파일 (삭제 LOC 포함)
- 정량 게이트: [노드 수·grep 결과 등 측정치]
- QA 반복: {x}회, 최종 점수: 패턴 x/기능 x/성능 x/시각 x/안정성 x (가중 x.x/10)
- 다음 Phase: R{N+1} ({이름}) 또는 "🎉 전체 완료"
```

지금 `REFACTOR_STATE.md`를 읽고 R0부터 시작하라.
