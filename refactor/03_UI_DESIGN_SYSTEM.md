# 03_UI_DESIGN_SYSTEM — 디자인 시스템 v3 "Night Shift" (R3·R4·R5)

> 컨셉: **야간 근무 병동의 네온**. 다크 잉크 베이스 + 심전도 민트 + 브랜드 코랄 + 스코어 골드.
> 모던 레트로 픽셀 — 픽셀의 또렷함 + 현대적 여백·정렬·모션. 레퍼런스 무드: Dead Cells 메뉴, Downwell의 절제, Vampire Survivors의 보상감.
> v2 카툰(크림 페이퍼·파스텔) 토큰·컴포넌트는 전면 폐기. 인게임 픽셀 HUD 톤(이미 완성)이 시각 언어의 모체다.

---

## 1. 디자인 원칙 5

1. **다크 베이스 위 네온 포인트** — 화면당 액센트 색 최대 2개. 나머지는 잉크 계열.
2. **픽셀은 또렷하게** — `.nearest` 필터, 정수 좌표 스냅, 블러 그림자 금지 → **하드 오프셋 섀도**(2~4px 단색).
3. **여백이 고급감** — 4pt 그리드. 요소 간 최소 12pt. 화면 가장자리 24pt+safe area.
4. **모든 등장은 모션과 함께** — 등장 staggered 60ms, easeOutBack. 정적 출현 금지.
5. **정보는 한 화면 한 주제** — 좀비 노드·중복 라벨 금지. 보조 정보는 칩으로 축약.

## 2. 컬러 토큰 (`Config/Palette.swift`)

기존 인게임 픽셀 톤 계승(★표 = 기존 값 재사용 — 연속성 보장):

| 토큰 | HEX | 용도 |
|---|---|---|
| `ink900` | `#0F0E15` ★(구 ganhoUIBg) | 씬 배경 |
| `ink800` | `#171A26` | 패널 배경 |
| `ink700` | `#232838` | 카드·버튼 표면 |
| `ink600` | `#2E3447` | 호버/눌림 표면 |
| `line500` | `#3A4154` | 기본 보더 2px |
| `textHi` | `#FFFCE0` ★ | 주 텍스트 |
| `textLo` | `#9BA3B8` | 보조 텍스트 |
| `coral` | `#FF6E5A` ★ | 브랜드·위험·hard |
| `coralDeep` | `#C44A3D` ★ | coral 하드섀도 |
| `gold` | `#FFD23F` ★ | 점수·별·normal |
| `goldDeep` | `#B8941F` | gold 하드섀도 |
| `mint` | `#4ADEC0` | 성공·심전도·easy |
| `mintDeep` | `#2A9D85` | mint 하드섀도 |
| `violet` | `#8C7BFF` | 스킬·레어·콤보 10+ |
| `character(.kim 등)` | PixelPalette에서 추출 | 캐릭터 시그니처 (02_GAME_FEEL §9) |

- 난이도 매핑: easy=mint / normal=gold / hard=coral (v2 Sprint 7 의미 계승).
- 글로우: 액센트색 alpha 0.30, 노드 뒤 1.4배 사각 1장 (SKEffectNode 블러 금지 — 성능).
- 사용 규칙: hex 직접 사용 금지, 반드시 `Palette.` 토큰 경유.

## 3. 타이포그래피 (`Config/Typography.swift`)

**픽셀 한글 폰트 도입**: [Galmuri](https://github.com/quiple/galmuri) (SIL OFL — 임베드 허용).

- 확보 절차: ① `Galmuri11.ttf`·`Galmuri14.ttf`·`Galmuri9.ttf`를 리포에서 받아 `Resources/Fonts/` 추가 ② Info.plist `UIAppFonts` 등록 ③ DEBUG에서 `UIFont(name:)` nil 검증 assert ④ PostScript 이름은 다운로드 후 실측해 Typography에 기록.
- 네트워크 불가 시: 사용자에게 파일 요청을 보고하고, **fallback 체인으로 빌드는 항상 성공**해야 함: Galmuri → DungGeunMo → 기존 Jua/GowunDodum.

| 토큰 | 폰트 | 크기 | 용도 |
|---|---|---|---|
| `display` | Galmuri14 | 44pt | 씬 타이틀·verdict |
| `h1` | Galmuri14 | 30pt | 카드 제목·점수 |
| `h2` | Galmuri11 | 22pt | 섹션 제목 |
| `body` | Galmuri11 | 17pt | 본문·버튼 |
| `caption` | Galmuri9 | 13pt | 칩·메타 |
| `prose` | GowunDodum | 16pt | 긴 설명문 예외 (스킬 인용문 등 2줄+) |
| `hudScore` | Galmuri14 | 40pt | 인게임 점수 |

- 자간: 픽셀 폰트 기본값. 줄간: 폰트 크기 ×1.45.
- 기존 Menlo-Bold 인게임 HUD는 Galmuri로 교체 (Sprint 10.6 카운트다운 회귀 P2도 이때 해소 — 큰 폰트 120pt 렌더 검증 필수).

## 4. 형태·간격·레이어

- **간격 스케일**: 4 / 8 / 12 / 16 / 24 / 32 / 48 (`UILayout.spacing`).
- **코너**: 픽셀 컨셉 = 직각 기본. 패널만 4pt 라운드 허용. v2 알약(height/2) 전면 폐기.
- **보더**: 2px `line500`. 강조 시 액센트색.
- **하드섀도**: 우하단 (x+0, y-3) 단색 Deep 계열. 블러 0.
- **ZOrder** (`Config/ZOrder.swift`): bg 0 / floor 10 / props 20 / collectibles 30 / characters 40 / projectiles 50 / effects 60 / vignette 80 / HUD 100 / overlay 200 / transition 300. 전 노드가 이 토큰만 사용.
- **배경 공통**: `ink900` 단색 + ①스타필드(2px 점 40개, 미세 트윙클) ②하단 심전도 라인(mint alpha 0.12, 8s 루프로 좌→우 펄스 1회) — `NightShiftBackdropNode` 1개로 공통화, 모든 메뉴 씬 공유.

## 5. 컴포넌트 키트 (R3, `Nodes/UI/`)

| 컴포넌트 | 명세 |
|---|---|
| `PixelPanelNode` | ink800 + 2px line500 + 하드섀도. 헤더 슬롯(h2 + 좌측 4px 액센트 바) 옵션 |
| `PixelButtonNode` | 3변형: primary(coral 면+ink900 글자) / secondary(ink700 면+textHi) / ghost(보더만). 눌림: y-2px 이동+섀도 1px+표면 어둡게, 0.06s. 탭 SFX·햅틱 내장. 최소 터치 44pt |
| `PixelChipNode` | caption + 아이콘 슬롯. 변형: 정보(ink700)/액센트(색 보더)/잠금(textLo) |
| `PixelProgressBarNode` | 세그먼트형(8px 블록+1px 간격). 채움 색 파라미터. XP·콤보 게이지·쿨다운 공용 |
| `PixelCardNode` | 캐릭터/난이도 카드 베이스. 선택 시: 액센트 보더 + 글로우 + scale 1.04 (easeOutBack 0.18s) |
| `PixelDialogNode` | overlay 200 레이어. 등장: ink900 alpha 0.6 딤 + 다이얼로그 y+16→0 easeOutCubic 0.22s |

기존 `GlassPillNode`·`PrimaryButtonNode`·`OverlayActionButtonNode`·`DarkContextChipNode`는 R4·R5에서 참조 0건 달성 후 삭제.

## 6. 화면별 사양 (R4)

### 6-1. StartScene — "야간 병동 로비"

```
┌──────────────────────────────────────────────┐
│  [Lv.4 책임 간호사]              [프로필] [설정]│ ← 상단 칩 라인
│                                              │
│        ♪ 김간호는 음악박사 ♪                   │ ← 픽셀 로고타입(Galmuri14 52pt, gold)
│           [김간호 대형 픽셀 idle]              │ ← 48×64 신규 픽셀 아트, 2프레임 bob 0.6s
│                                              │
│            ▶ 탭하여 시작                       │ ← textHi, 1.2s 블링크
│  [🔥 오늘의 도전: 황금 변기 · 14:22 남음]        │ ← 일일 도전 칩(R6 전까지 숨김)
└──────────────────────────────────────────────┘
```
- 김간호 대형 픽셀(48×64)은 기존 16×20 데이터를 **참조해 새로 그린** PixelSprite 데이터 (NurseAvatarNode SVG 폐기 대체).
- 로그인 오버레이는 `PixelDialogNode`로 재구성, Firebase 플로우 로직 불변.

### 6-2. CharacterSelectScene — 스와이프 캐러셀 계승

- 좌측 40%: 선택 캐릭터 **풀바디 픽셀 확대**(인게임 16×20 ×9 스케일, walk 2프레임 idle) + 시그니처 글로우 + 이름(h1) + 칭호급 한 줄.
- 우측 60%: `PixelCardNode` 캐러셀 (중앙 1 + 양옆 반쯤, Sprint 8 결정 계승). 카드 = 얼굴 픽셀(신규 24×24 포트레이트 데이터 5종) + 이름 + 스킬 칩 + 별 현황(`★ 7/9`).
- 잠금 카드: 실루엣(ink600 단색 처리) + `★24 필요` 칩.
- 하단: 선택 캐릭터 스킬 요약 1줄 + [브리핑 보기 ghost] [출발 primary].
- `CharacterFaceNode`(SVG 1,107줄) 삭제. 포트레이트는 PixelSpriteRenderer 재사용.

### 6-3. SkillBriefingScene (구 SkillExplanation) — "작전 브리핑"

- 좌: 포트레이트 카드(캐러셀과 동일 컴포넌트 재사용, 카드 뒤집힘 등장 0.3s).
- 우: `PixelPanelNode` — 스킬명(h1+시그니처색) / 인용문(prose, 좌측 3px 액센트 바) / 칩 3개(쿨다운·범위·발동). 하단 [뒤로 ghost] [난이도 선택 primary].
- 김간호(스킬 없음)는 이 씬 스킵 유지.

### 6-4. DifficultySelectScene

- 3 `PixelCardNode` 가로 배치 (mint/gold/coral). 카드 내용: 난이도명(h2) / 목표 점수(h1) / 등장 빌런 픽셀 아이콘 행 / 내 최고 기록 칩 / 별 현황 ★★☆.
- 선택 시 카드 확대 + 나머지 dim. 하단 [시작 primary — 선택 색 따라감].

### 6-5. 공통

- 모든 메뉴 씬 `BaseMenuScene` 상속 통일 (ResultScene 포함 — 현재 단독 이탈 해소).
- 뒤로가기: 좌상단 ghost 버튼 통일. 브레드크럼 칩 폐지(정보 과밀 원인).

## 7. ResultScene 재작성 (R5) — "보상의 무대"

연출 시퀀스 (총 ~2.4s, 탭으로 스킵 가능):

1. 0.0s: verdict 스탬프 — "졸업!"(mint)/"유급…"(coral), display 56pt, scale 1.6→1.0 easeOutBack + 셰이크 soft + 도장 SFX
2. 0.4s: 점수 카운트업 0→N (0.8s, 60Hz 갱신, 틱 SFX 피치 점진 상승, hudScore)
3. 1.2s: 별 3개 순차 팝 (0.15s 간격, easeOutBack, 별당 SFX 상승음). 미달 별은 빈 윤곽
4. 1.7s: XP 바 증가 (`PixelProgressBarNode`, 0.5s) + 레벨업 시 칭호 배지 슬라이드인
5. 2.1s: 신기록이면 `NEW RECORD` 칩 블링크 / 실패 시 "{gap}점 부족" 칩
6. 하단 버튼 등장: [다시 도전 primary] [캐릭터 변경 secondary] [기록 ghost]

- 정보는 위 6요소 + 콤보 최고·수집 수 칩 2개가 전부. 현 30+ 노드 → **15노드 이하**, ≤600줄, BaseMenuScene 상속.
- 실패 시에도 획득 XP는 표시 (손실 회피 완화 — "다시" 유도).

## 8. Scoreboard·프로필 (R5)

- Scoreboard: 캐릭터×난이도 15셀 그리드 (셀 = 별·최고점). 탭 전환: [기록] [업적(R6)]. 픽셀 테이블 스타일.
- 계정 오버레이(`AccountMenuOverlayNode` 등): `PixelDialogNode` 기반 재구성, Firebase 로직 불변.
- 프로필 칩(Start 상단): 아바타(선호 캐릭터 포트레이트) + Lv + 칭호.

## 9. 모션 표준 (`FeelTuning.motion`)

| 용도 | 시간 | 커브 |
|---|---|---|
| 버튼 눌림 | 0.06s | linear |
| 카드 선택 | 0.18s | easeOutBack |
| 요소 등장 (stagger 60ms) | 0.22s | easeOutCubic |
| 다이얼로그 | 0.22s | easeOutCubic |
| 씬 전환 | 0.35s | easeInOutQuad |

**씬 전환 (R3 `SceneRouter`)**: 전 씬 `SKTransition.fade` 일괄 폐기 → 진행 방향 push(앞으로=좌로 밀기, 뒤로=우로 밀기) + 인게임 진입만 **픽셀 디졸브**(8px 블록 체커 페이드 0.4s). 전환 SFX 동반.

## 10. 인게임 HUD 보정 (R7과 연동)

- Sprint 10-J 픽셀 HUD 골격 유지. 폰트만 Menlo→Galmuri 교체 (§3).
- 추가: 콤보 게이지(02_GAME_FEEL §8), 목표 진행 미니 바(상단, mint), 스킬 슬롯 쿨다운 숫자+세그먼트 링.
- 비네트·텔레그래프·근접 경고 등 기존 연출 전부 유지.

## 11. 금지 사항

- SKEffectNode 실시간 블러, height/2 알약 코너, 크림/파스텔 배경, SVG path 캐릭터 부활, fade 단독 씬 전환, 시스템 폰트 노출(fallback 최후 단계 제외), 노드 숨김(alpha=0) 잔존.
