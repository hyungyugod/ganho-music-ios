# Figma 임포트 + PNG export 가이드

**프로젝트**: GanhoMusic iOS · 김간호는 음악박사
**목적**: SVG 5명 → Figma에서 다듬기 + 16프레임 만들기 → PNG export → SpriteKit 통합
**선행 자산**: `mockups/svg-exports/` (5개 SVG 파일)

---

## 0. 흐름 한눈에

```
mockups/svg-exports/kim.svg
  │
  ↓ Figma에 드래그앤드롭
  │
[Figma에서 다듬기]
  ├─ 얼굴 디테일 수정 (선 굵기, 색 미세 조정)
  ├─ 몸통 추가 (Common Outfit 템플릿 활용)
  └─ 16프레임 복제 (4방향 × idle/walk × 2)
  │
  ↓ PNG @1x/@2x/@3x export
  │
GanhoMusic/Assets.xcassets/Characters/kim.imageset/
  ├─ kim_down_idle_1.png       (@1x: 96×144)
  ├─ kim_down_idle_1@2x.png    (192×288)
  └─ kim_down_idle_1@3x.png    (288×432)
```

---

## 1. SVG → Figma 임포트 (3가지 방법)

### 방법 A. 드래그앤드롭 (가장 쉬움) ⭐
1. Figma 새 프로젝트 열기
2. Finder에서 `mockups/svg-exports/kim.svg` 파일을 Figma 캔버스로 드래그
3. SVG가 벡터 그룹으로 자동 임포트 — 모든 path/circle이 편집 가능한 레이어로

### 방법 B. 복사 → 붙여넣기 (텍스트 편집기에서)
1. SVG 파일을 텍스트 에디터에서 열기
2. `<svg>` 태그 전체 복사
3. Figma 캔버스에서 ⌘V → 자동 벡터 변환

### 방법 C. Plugin "SVG to Figma"
- 더 정밀한 변환이 필요할 때만. 보통 A/B로 충분.

---

## 2. Figma에서 다듬는 5단계

### Step 1. 임포트한 그룹을 컴포넌트로 변환
- 임포트된 그룹 선택 → 우클릭 → "Create component" (⌥⌘K)
- 이름: `Character/Kim/Head` 같은 슬래시 네이밍 (Figma 폴더 자동 생성)

### Step 2. 머리 색·디테일 미세 조정
- 머리 path 선택 → 우측 Fill 패널에서 색 변경
- 윤곽선이 마음에 안 들면 Stroke 두께 조정 (기본 5px)
- HEX 일관성 유지: `mockups/svg-exports/*.svg` 상단 주석에 캐릭터별 색 토큰 명시

### Step 3. 몸통 추가 (Common Outfit 템플릿)
**한 번만 만들고 5명에 재사용**:

```
Body Template (288×288 frame):
├─ 흰 nurse top (둥근 사각형 #FFFFFF, navy outline)
├─ 빨간 십자 chest emblem (#FF6B5B)
├─ 양 옆 팔 (흰 ellipse + 끝에 피부톤 손)
├─ 다리 2개 (캐릭터별 scrubs 색)
└─ 흰 sneakers 2개 (#FFFFFF)
```

각 캐릭터의 머리(SVG)와 결합해서 풀바디 완성. 캐릭터마다 scrubs 색만 바꾸면 됨:
- 김간호: 민트 #9BE0CC
- 정간호: 민트 #9BE0CC
- 건간호: 라벤더 #B89DD9
- 임간호: 네이비/블랙 #2D2A4A
- 이간호: 코랄 #C44A3D

### Step 4. 캔버스 사이즈 맞추기
- Figma Frame 1개를 **288×432** 픽셀로 만들기 (캐릭터당)
- 캐릭터 발 끝이 프레임 하단 ~10px 위에 오도록 정렬
- 캔버스 배경은 **투명** (Frame의 Fill을 None으로)

### Step 5. 컴포넌트 → 16프레임 인스턴스
- Step 1에서 만든 컴포넌트를 16번 복제
- 프레임마다 약간씩 변형:
  - **idle_1**: 기본
  - **idle_2**: 전체를 Y축 1~2px 위로 (호흡 들이마시기)
  - **walk_1**: 양 다리 살짝 벌리고 Y축 1px 위로
  - **walk_2**: 양 다리 반대 방향 + Y축 -1px 아래로 (착지)
  - **방향(up/down/left/right)**: 머리·몸통을 좌우반전 또는 뒷모습으로 재구성

⚡ **속도 팁**: 4방향 16프레임을 다 만들기 너무 많으면, **down_idle_1 1장만 만들고 SpriteKit에서 SKAction.scaleY로 폴폴폴 처리** 가능. (코드량이 더 적음)

---

## 3. PNG export 설정

### 캐릭터별 imageset 구조
Xcode `Assets.xcassets`에 다음처럼 저장:

```
Assets.xcassets/
└─ Characters/
   ├─ kim_down_idle_1.imageset/
   │   ├─ kim_down_idle_1.png       (@1x — 96×144)
   │   ├─ kim_down_idle_1@2x.png    (192×288)
   │   └─ kim_down_idle_1@3x.png    (288×432)
   ├─ kim_down_idle_2.imageset/
   ├─ ...
   └─ lee_right_walk_2.imageset/
```

### Figma에서 export 설정
1. Frame 1개 선택 (288×432)
2. 우측 Design 패널 맨 아래 **Export** 섹션
3. **3개 export 추가** (`+` 버튼 3번):
   - **0.33×** PNG, suffix `` (빈칸) → @1x용 (96×144)
   - **0.67×** PNG, suffix `@2x` → @2x용 (192×288)
   - **1×** PNG, suffix `@3x` → @3x용 (288×432)
4. 또는 Figma plugin **"Export Resizer"** 쓰면 한 번에 3가지 사이즈 일괄 export

### 일괄 export 워크플로우
- 16프레임 모두 위 3개 export 설정 적용
- Cmd+Shift+E → "Export selected items"
- Finder에서 `Characters/` 폴더로 일괄 저장
- Xcode에 드래그앤드롭 → "Copy items if needed" 체크

---

## 4. 명명 규칙 (PNG 파일명)

```
<character>_<direction>_<state>_<frame>.png

예시:
kim_down_idle_1.png    kim_down_idle_2.png    kim_down_walk_1.png    kim_down_walk_2.png
kim_up_idle_1.png      kim_up_idle_2.png      kim_up_walk_1.png      kim_up_walk_2.png
kim_left_idle_1.png    kim_left_idle_2.png    kim_left_walk_1.png    kim_left_walk_2.png
(right는 left 좌우반전으로 코드에서 처리 — 12장 / 캐릭터로 절감 가능)
```

- `<character>`: `kim` / `jung` / `geon` / `im` / `lee`
- `<direction>`: `down` (정면) / `up` (뒷면) / `left` (좌측) / `right` (우측, 옵션)
- `<state>`: `idle` (대기) / `walk` (걷기)
- `<frame>`: `1` / `2`

---

## 5. SpriteKit에서 사용 (Sprint 4)

### SKTextureAtlas로 묶기
```swift
let kimAtlas = SKTextureAtlas(named: "kim")
let kimDownIdle = [
    kimAtlas.textureNamed("kim_down_idle_1"),
    kimAtlas.textureNamed("kim_down_idle_2")
]
```

### 폴폴폴 idle 애니메이션
```swift
let idleAnimation = SKAction.animate(
    with: kimDownIdle,
    timePerFrame: 0.4
)
playerNode.run(SKAction.repeatForever(idleAnimation))
```

### 걷기 애니메이션 + 폴폴폴 바운스
```swift
let walkAnim = SKAction.animate(with: kimDownWalk, timePerFrame: 0.12)
let bounce = SKAction.sequence([
    SKAction.scaleY(to: 1.05, duration: 0.06),
    SKAction.scaleY(to: 0.97, duration: 0.06)
])
let combined = SKAction.group([
    SKAction.repeatForever(walkAnim),
    SKAction.repeatForever(bounce)
])
playerNode.run(combined)
```

### 좌·우 미러 (12프레임 절감)
```swift
// right walk는 left frames + xScale 반전
if direction == .right {
    sprite.xScale = -1
    sprite.run(leftWalkAnim)
} else {
    sprite.xScale = 1
    sprite.run(leftWalkAnim)
}
```

---

## 6. 빠른 워크플로우 (현실적 시간)

### 옵션 A. 풀세트 (16프레임 / 캐릭터 × 5 = 80장)
**예상**: 8~12시간 / 캐릭터 × 5명 = 40~60시간

### 옵션 B. 좌·우 미러 절감 (12프레임 / 캐릭터 × 5 = 60장)
**예상**: 30~45시간 (왼쪽만 그리고 코드에서 반전)

### 옵션 C. 폴폴폴 트릭만 사용 (4프레임 / 캐릭터 × 5 = 20장)
**예상**: 8~15시간

```
캐릭터당 4프레임:
- down_idle_1 (메인)
- up_idle_1 (뒷면)
- left_idle_1 (옆면)
- (right는 left 미러)

SKAction.scaleY로 폴폴폴 처리:
- 정지 시 호흡: scaleY 1.0 ↔ 1.02 (idle)
- 이동 시 바운스: scaleY 1.05 ↔ 0.97 (walk)
- 방향 전환만 PNG 교체
```

⭐ **추천: 옵션 C로 먼저 시작** — 작업량 1/4로 줄이고 게임에서 어떻게 보이는지 빠르게 확인.
나중에 욕심 나면 walk_2 프레임 추가하면 됨.

---

## 7. 캐릭터별 Figma 작업 체크리스트

각 캐릭터당:

- [ ] SVG 임포트 완료
- [ ] 컴포넌트로 변환
- [ ] 머리 디테일 자신만의 터치 추가 (선 굵기·색 미세 조정)
- [ ] 몸통 연결 (Common Outfit 템플릿)
- [ ] 캐릭터 색 적용 (scrubs)
- [ ] 288×432 frame 안에 배치 (발 끝 하단 정렬)
- [ ] 본인 동의 한 번 더 확인 (정·건·임·이간호 — 실존 인물)
- [ ] down_idle_1 1장 먼저 export → 게임에 임시 임포트해서 사이즈·톤 확인
- [ ] OK면 나머지 프레임 export

---

## 8. 자주 발생하는 문제

| 문제 | 원인 | 해결 |
|---|---|---|
| 임포트한 SVG가 깨져 보임 | Figma의 SVG 파서 한계 (복잡한 path) | 영향받은 path만 재드로잉 |
| PNG export가 흐릿함 | 해상도 부족 | 0.33×/0.67×/1× 3개 export 설정 확인 |
| 캐릭터 발이 화면 밖 | 프레임 anchor 미정렬 | 288×432 프레임 안에 발 끝이 y=420 근처 오도록 |
| 캐릭터 윤곽선이 흐림 | Figma의 anti-aliasing | Stroke 두께 늘리거나 PNG export 사이즈 키우기 |
| 5명 톤이 안 맞음 | 디자인 결정 변경됨 | `mockups/character-concepts-v2.html` v4를 항상 단일 진실 원천으로 |

---

## 9. 작업 우선순위 (현실적 권장)

1. **김간호 1장만 먼저** — down_idle_1 작은 사이즈 PNG 1장 export → 게임에 임포트 → 실제 게임 화면에서 어떻게 보이는지 확인 → 톤·사이즈·디테일 결정
2. 톤 잡히면 나머지 4명도 down_idle_1만 먼저 (5명 첫 프레임 확정)
3. 5명 다 OK면 → 옵션 C(4프레임/캐릭터)로 1차 게임 통합
4. 게임플레이 만족스러우면 → 옵션 B(12프레임)로 폴폴폴 강화
5. 더 가고 싶으면 → 옵션 A(16프레임)로 완성

---

**문서 작성**: Claude (Cowork mode) · 2026-05-19
**참고**:
- `DESIGN_RENEWAL_REQUEST.md` §8 (PNG 자산 스펙)
- `CHARACTER_SPRITE_PROMPT.md` (AI 외주용 대안 — 현재 미사용)
- `mockups/character-concepts-v2.html` v4 (캐릭터 시안 최종)
- `mockups/svg-exports/*.svg` (5명 SVG 추출 파일)
