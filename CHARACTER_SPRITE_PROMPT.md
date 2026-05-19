# 캐릭터 스프라이트 AI 주문 프롬프트

> ⚠️ **현재 미사용 (백업 옵션)**: 사용자가 Figma에서 SVG 베이스로 직접 제작하는 워크플로우로 결정.
> 직접 제작 가이드는 `FIGMA_IMPORT_GUIDE.md` 참고.
> 이 문서는 나중에 자산 외주가 필요할 때 사용하는 백업으로 보존.

**프로젝트**: GanhoMusic iOS · 김간호는 음악박사
**목적**: 4명 × 16프레임 = 80장 PNG 캐릭터 스프라이트 외주 (AI 이미지 생성)
**참고 시안**: `mockups/character-concepts-v2.html` (v4 — 최종 디자인 확정)
**최종 사용처**: SpriteKit `SKTextureAtlas` (Sprint 4)

**v4 디자인 결정 (백업용으로 반영해둠)**:
- 김간호: 곱슬 번머리 + 헤드폰 (기본)
- 정간호: 안경 ⭕ + 핑크 러닝캡 + 곡괭이
- 건간호: 안경 ❌ + 갸름한 얼굴 + 자연스러운 눈 + 능청
- 임간호: 풀어내린 긴머리 + 자연스러운 고양이상 (솔리드 아몬드 회전 눈)
- 이간호: 곱슬 단발 + 앞머리 (강아지귀 ❌)

---

## 0. 사용 방법 (TL;DR)

1. **§1 Universal Style Anchor**를 매 생성마다 프롬프트 맨 위에 붙여넣기
2. **§3 캐릭터별 디스크립션** 중 해당 캐릭터 1명만 골라서 함께 붙여넣기
3. **§4 Frame 1 디스크립션**부터 16장 순차 생성 (같은 시드 / 같은 캐릭터 참조 유지)
4. 사진 첨부: 김간호 제외 4명은 본인 사진을 reference로 함께 업로드
5. **§5 출력 스펙** 검증 후 다운로드 → `Assets.xcassets`에 추가

---

## 1. Universal Style Anchor (필수, 매번 첨부)

영문 프롬프트 (AI 처리 정확도 ↑):

```
ART STYLE:
Cute cartoon chibi character sprite for a mobile game, top-down 3/4 isometric view, 
in the visual style of Brawl Stars and Cookie Run Kingdom. 
Warm pastel color palette. Soft round forms. Big head, small body (1:1.5 ratio).
Expressive face. Bold dark navy outlines (2-3px). Flat color fills with minimal cel-shading.
NOT pixel art. NOT photorealistic. NOT anime style. 

COLOR PALETTE (use exactly these HEX):
- Skin tone: #FFE2C6
- Outline color: #2D2A4A (deep navy, all line work)
- Background BG (use for nothing on the character itself): N/A — transparent
- Accent coral: #FF6B5B
- Accent mint: #9BE0CC
- Accent lavender: #B89DD9
- Accent gold: #FFB347
- Hair dark: #3A2418
- Cheek blush: #FFB6B0
- White (caps, accents): #FFFFFF

COMPOSITION:
- Full body character, feet at bottom center of canvas
- Character occupies ~70% of canvas height
- Empty space (transparent) on all sides
- Anchor point: bottom-center of canvas = character's feet
- No background, no scenery, no other characters, no text

OUTPUT:
- 288x432 pixels (will be used as @3x asset for iOS Retina display)
- PNG-24 with full alpha channel (transparent background)
- No drop shadows in the image itself (shadows added at runtime)
- Character should be clearly readable at 96x144 display size (1/3 scale)
```

한글 요약 (이해용):
- 브롤스타즈·쿠키런 톤의 카툰 치비
- 3/4 탑다운 뷰, 큰 머리·작은 몸 (1:1.5 비율)
- 진한 네이비 윤곽선 (2-3px)
- 따뜻한 파스텔 컬러 (정확한 HEX 위에 명시)
- **픽셀 아트 ❌ 사실주의 ❌ 애니메 ❌**
- 캔버스 288×432px, 투명 배경, 발이 하단 중앙
- 그림자·배경·텍스트 절대 넣지 말 것

---

## 2. 공통 의상 (모든 캐릭터 통일)

```
COMMON OUTFIT (all 5 characters wear this base):
- White short-sleeve nurse top (#FFFFFF) with a small chest pocket
- Pants/scrubs bottom in character-specific color (see §3)
- Optional: tiny red cross emblem (#FF6B5B) on chest pocket
- Optional: small white nurse cap on top of head (white with red cross), 
  positioned to NOT cover signature hair features
- White sneakers (#FFFFFF)
- Character holds a small accessory in one hand (see §3 per character)
```

---

## 3. 캐릭터 5명 (각각 따로 생성)

### 3.1 김간호 (Kim) — 사진 없음, 디스크립션만

```
CHARACTER: Kim ("Kim-ganho", 김간호)
TYPE: young Korean female nursing student, 20s, the protagonist

DISTINCTIVE FEATURES (must include):
- Curly/permed dark brown hair (#3A2418), shoulder-length with bouncy curls 
  forming a halo shape (Korean "번머리" perm style)
- Large coral red over-ear headphones (#FF6B5B) on top of head, 
  visible from front view, with a small dark navy band
- Small white nurse cap (#FFFFFF with #FF6B5B cross) tucked between the curls
- Closed-eye happy smile (∩ ∩ shape eyes), warm friendly expression
- Pink cheek blush
- Mint green scrubs bottom (#9BE0CC)
- Holding a small white music note (♪) in one hand, colored #FFB347 (gold)

PERSONALITY VIBE: cheerful, energetic, music-loving nursing student
```

### 3.2 정간호 (Jung) — 마라톤 사진 첨부

```
CHARACTER: Jung ("Jung-ganho", 정간호)
TYPE: young Korean male, athletic build, 20s
REFERENCE PHOTO: [attach the marathon photo - male runner with glasses and pink cap]

CAPTURE THESE FROM PHOTO:
- Round black-framed glasses (signature feature from photo) - thick rims
- Determined, focused facial expression - strong dark eyebrows angled inward
- Athletic build (slightly broader shoulders than other characters)
- Short dark hair, mostly tucked under cap

ADD THESE (game-specific):
- Coral/pink running cap (#FF8E80) with small "G+" logo or red cross
- Subtle sweat drop on cheek (#9BCDF0 light blue) for athletic vibe
- Small white nurse cap tucked behind running cap
- Mint green scrubs (#9BE0CC) for top accent — but main shirt is white
- Holding a small cartoon pickaxe in right hand: 
  silver pickaxe head (#9AA0A8), wood handle (#8B5A2B)
- Subtle blush in coral-red tone (#E87B6A) — sun-tanned runner look

EXPRESSION: determined, slightly mouth-open as if breathing during exercise
PERSONALITY VIBE: athletic, disciplined, runner energy
```

### 3.3 건간호 (Geon) — 졸업 사진 첨부

```
CHARACTER: Geon ("Geon-ganho", 건간호)
TYPE: young Korean male, slim build, 20s
REFERENCE PHOTO: [attach the graduation photo - male in cap and gown]

CAPTURE THESE FROM PHOTO:
- Straight dark brown hair (#1F1410) with forward-falling fringe/bangs 
  covering forehead in an uneven, slightly messy way
- Slim oval face shape
- Narrow, young-looking eyes
- Slightly mischievous, cheeky expression (he ate his own diploma — playful humor)

ADD THESE (game-specific):
- Round black-framed glasses (smaller frame than Jung's)
- White nurse cap (#FFFFFF with red cross) on top of head
- Lavender scrubs bottom (#B89DD9)
- Holding a small lavender book in left hand: 
  cover #B89DD9, pages #F6EBD9, with a tiny ribbon bookmark
- Tongue slightly poking out from one corner of mouth (referencing diploma-eating joke)
- Pink cheek blush

EXPRESSION: mischievous half-smile, slight tongue, asymmetric
PERSONALITY VIBE: nerdy but playful, bookish jokester
```

### 3.4 임간호 (Im) — 전시회 사진 첨부

```
CHARACTER: Im ("Im-ganho", 임간호)
TYPE: young Korean female, slim, 20s
REFERENCE PHOTO: [attach the photo of woman crouching in all black]

CAPTURE THESE FROM PHOTO:
- Hair worn in a tight high bun on top of head (#3A2418), 
  with a few loose strands/wisps falling down on both sides of the face
- Calm, observant, slightly mysterious expression
- Refined elegant posture
- All-black aesthetic

ADD THESE (game-specific):
- Subtle black cat ears poking up through the hair bun (#3A2418 outer, #FFB6B0 inner)
- Almond-shaped cat-like eyes (slightly angled upward at outer corners), 
  drawn as filled dark navy shapes with one tiny white highlight dot each
- 2-3 subtle whisker lines on each cheek (drawn as thin straight lines, very faint)
- Small pink cat nose (#FF8E80)
- Small white nurse cap (red cross) tucked in front of hair bun
- Black scrubs bottom (#2D2A4A) — matches her all-black photo aesthetic
- Holding a small magical sparkle/charm in one hand (#FFB347 gold star)

EXPRESSION: calm, slight closed-mouth smile, cat-like elegance
PERSONALITY VIBE: mysterious, refined, cat-like grace
```

### 3.5 이간호 (Lee) — 크리스마스 트리 사진 첨부

```
CHARACTER: Lee ("Lee-ganho", 이간호)
TYPE: young Korean female, soft features, 20s
REFERENCE PHOTO: [attach the Christmas tree photo - woman with long wavy hair in red sweater]

CAPTURE THESE FROM PHOTO:
- Long brown wavy hair (#3A2418), shoulder-length and below, 
  with soft natural waves and a middle parting
- Bangs covering forehead, parted slightly in the middle
- Soft round-ish face shape
- Warm, gentle, genuine smile (most prominent photo feature)
- Cozy, warm festive energy

ADD THESE (game-specific):
- Small floppy dog ears (#3A2418 outer, #FFB6B0 inner) 
  on top of head, positioned at angles — like a friendly puppy
- Curved happy-eyes (closed smile shape: ⌒ ⌒)
- Strong pink cheek blush (#FFB6B0) — warm festive vibe
- Small white nurse cap (red cross) tucked between dog ears
- Coral-red scrubs bottom (#C44A3D) — matches her red sweater from photo
- Holding a small heart sparkle (#FF8E80) or musical note in one hand

EXPRESSION: warm beaming smile, eyes closed in joy, very approachable
PERSONALITY VIBE: warm, cheerful, friendly puppy energy
```

---

## 4. Frame 매트릭스 (16장 / 캐릭터)

각 캐릭터마다 16번 생성. 같은 캐릭터 참조 / 같은 시드 유지가 핵심.

### 명명 규칙
```
<character>_<direction>_<state>_<frame>.png

예시:
kim_down_idle_1.png
kim_down_idle_2.png
kim_down_walk_1.png
kim_down_walk_2.png
kim_up_idle_1.png
... (16장 / 캐릭터)
```

`<character>`: `kim` / `jung` / `geon` / `im` / `lee`
`<direction>`: `down` (정면) / `up` (뒷면) / `left` (좌측) / `right` (우측)
`<state>`: `idle` (대기) / `walk` (걷기)
`<frame>`: `1` / `2`

### Frame별 디스크립션 (영문 — AI에 그대로 추가)

#### Down (정면, 뷰어를 향함)

| Frame | English Prompt Addition |
|---|---|
| `down_idle_1` | "Standing still, facing the camera directly (front view). Body slightly elongated, as if inhaling. Both feet planted, weight even." |
| `down_idle_2` | "Standing still, facing camera. Body slightly compressed (2-3% shorter), as if exhaling — natural breathing cycle." |
| `down_walk_1` | "Walking forward toward camera. Left leg stepping forward, right arm swinging forward, slight forward lean. Slight bounce up." |
| `down_walk_2` | "Walking forward toward camera. Right leg stepping forward, left arm swinging forward. Slight bounce down (touching ground)." |

#### Up (뒷면, 카메라에 등을 보임)

| Frame | English Prompt Addition |
|---|---|
| `up_idle_1` | "Standing still, back facing camera (rear view). Signature hair/accessories visible from behind (curls, bun, glasses temple, headphones). Breathing in pose." |
| `up_idle_2` | "Standing still, back facing camera. Breathing out pose (slightly compressed)." |
| `up_walk_1` | "Walking away from camera (back view). Left leg stepping, right arm swinging. Slight up bounce." |
| `up_walk_2` | "Walking away from camera. Right leg stepping, left arm swinging. Down bounce." |

#### Left (좌측 측면 — 캐릭터가 화면 왼쪽을 향함)

| Frame | English Prompt Addition |
|---|---|
| `left_idle_1` | "Standing still, side view facing screen-left. Profile clearly shows nose, hair, accessory silhouette. Breathing in pose." |
| `left_idle_2` | "Side view facing screen-left. Breathing out pose." |
| `left_walk_1` | "Walking to screen-left. Front leg stepping out, back leg pushing. Visible profile motion." |
| `left_walk_2` | "Walking to screen-left. Legs in opposite phase. Slight head bob." |

#### Right (우측 측면 — 캐릭터가 화면 오른쪽을 향함)

**옵션 A (16장 풀세트)**: Left와 동일하지만 좌우 반전된 별도 4프레임 생성

**옵션 B (12장 + 코드 반전)**: Right는 생략하고 게임 코드에서 `xScale = -1`로 좌우 반전 (좌측 4프레임 재활용)

→ **추천: 옵션 B** — AI 생성 4장 절감, 일관성 보장 + 코드 한 줄 변경(`sprite.xScale = -1`)
→ 옵션 A 선택 시 위 Left 디스크립션을 "screen-right" 로 바꿔서 4장 추가 생성

---

## 5. 출력 스펙 (다운로드 후 검증)

| 항목 | 값 | 검증 방법 |
|---|---|---|
| 해상도 | 288×432px (@3x용) | 다운로드 후 미리보기에서 크기 확인 |
| 포맷 | PNG-24 + 알파 채널 | 투명 배경이 그대로 보여야 함 (체크무늬) |
| 캐릭터 비율 | 캔버스 높이의 ~70% | 발 끝이 캔버스 하단 ~10px 위 |
| 앵커 | 발 끝 = 캔버스 하단 중앙 | Photoshop/Preview에서 확인 |
| 배경 | 완전 투명 | 흰 배경·체크무늬 배경 ❌ |
| 외곽선 | #2D2A4A 네이비 일관 | 갈색·검정 ❌ |
| 그림자 | 캐릭터 자체엔 없음 | 발 아래 회색 타원 ❌ (런타임에서 추가) |

@1x, @2x 자동 생성: Xcode가 @3x만 있어도 자동 스케일 다운하므로 @3x만 받아도 OK. 더 깔끔하게 가려면 @1x(96×144), @2x(192×288)도 별도 생성.

---

## 6. 도구별 사용 팁

### A. Nano Banana / Gemini 2.5 Flash Image (⭐ 가장 추천)
**강점**: 같은 캐릭터의 다른 포즈 생성 시 일관성 압도적.

1. 첫 프롬프트: §1 + §3.x (한 캐릭터) + §4 `down_idle_1` 디스크립션 + 사진 첨부
2. 결과물 받으면 이어서: "Same character, now show the {direction} {state} {frame}" 형식으로 15장 추가 요청
3. 한 세션 안에서 16장 전부 생성 (캐릭터 일관성 유지)
4. 새 캐릭터 들어갈 때 새 세션 시작

### B. Midjourney (--cref 옵션)
**강점**: 아트 퀄리티 최고. 단점: 캐릭터 일관성은 Nano Banana만큼 정확하지 않음.

1. 사진을 Discord에 업로드 → URL 복사
2. 프롬프트: `[§1 + §3.x + §4 frame description] --cref [photo_url] --cw 80 --seed 12345 --ar 2:3`
3. 16장 모두 **같은 시드** 유지 (`--seed 12345`)
4. `--cw 80` = 캐릭터 일관성 강도 80%

### C. ChatGPT 4o Image Gen / DALL-E 3
**강점**: 무료/저렴, 한국어 가능. 단점: 캐릭터 일관성 가장 약함.

1. 첫 채팅: §1 + §3.x + 사진 첨부
2. "이 캐릭터를 ${frame_description} 자세로 그려줘" 16번 반복
3. 매번 "위와 같은 캐릭터, 같은 의상, 같은 헤어스타일로" 강조

### D. Stable Diffusion (LoRA 학습) — 고급
**강점**: 가장 정밀. 단점: 기술 진입장벽 高.

1. 사진 10~20장으로 LoRA 학습 (Kohya GUI 등)
2. 학습된 LoRA + ControlNet OpenPose로 16 포즈 정밀 제어
3. 5명 × LoRA 5개 학습 = 시간 多 — 본격 게임 출시용

---

## 7. 추천 워크플로우 (효율 순)

```
Day 1 (3시간)
├─ §1 Universal Style을 ChatGPT/Gemini에 한 번 학습시키기
├─ 김간호 16장 생성 → Assets.xcassets에 임포트 → 게임에서 1장만 테스트
└─ 톤·비율 OK 확인되면 다음 캐릭터 진행

Day 2 (4시간)
└─ 정·건·임·이간호 사진 첨부해서 각 16장 → 총 64장

Day 3 (2시간)
├─ 80장 전수 검사 (스펙 §5)
├─ 일관성 안 맞는 프레임 5~10장 재생성
└─ Assets.xcassets에 5개 그룹으로 정리 (kim/, jung/, geon/, im/, lee/)
```

총 예상: **~9시간 + AI 사용료**. 옵션 B(12장/캐릭터) 선택 시 60장 = ~6.5시간.

---

## 8. QC 체크리스트 (각 PNG마다)

다운로드 직후 빠르게 확인:

- [ ] 배경 완전 투명 (PNG 미리보기에서 체크무늬 보임)
- [ ] 캐릭터 발 끝이 캔버스 하단 ~10px 위 (앵커 정확)
- [ ] 윤곽선이 #2D2A4A 일관 (다른 갈색·검정 섞임 ❌)
- [ ] 캐릭터 자체에 그림자 없음 (있으면 지우개로 삭제 or 재생성)
- [ ] 같은 캐릭터의 다른 프레임과 비교 시 동일인이라고 인식됨
- [ ] 디스플레이 96×144px(@1x) 축소 후에도 표정 식별 가능

---

## 9. 자주 발생하는 문제 & 해결

| 문제 | 원인 | 해결 |
|---|---|---|
| 배경이 흰색으로 채워짐 | "transparent background" 강조 부족 | 프롬프트에 `PNG with alpha, transparent background, no background fill` 명시 |
| 캐릭터마다 윤곽선 색·굵기 다름 | 시드 다름 | Midjourney `--seed` 동일 유지 / Nano Banana 같은 세션 유지 |
| 안경·소품이 프레임마다 사라짐 | reference 약함 | "MUST keep glasses in every frame" 강조 + 사진 reference 다시 첨부 |
| 손이 이상하게 그려짐 (AI 흔한 문제) | 해상도 부족 | 손이 보이지 않는 포즈로 변경 or 소품(책·곡괭이)을 손 위치에 배치 |
| 좌·우 비대칭 (얼굴 한쪽만 그려짐) | "full body, both sides visible" 누락 | 프롬프트에 명시 |
| 픽셀 아트로 나옴 | 픽셀 키워드 누락 | `NOT pixel art, smooth cartoon vector style` 강조 |

---

## 10. 부록 — 빠른 복사용 한 줄 템플릿

캐릭터 1명, 프레임 1개 생성용 한 줄 (Universal + Character + Frame 결합):

```
[Universal Style §1] + [Character §3.X] + [Frame §4 description] + "Generate one PNG, 288x432, transparent background, anchor feet at bottom-center."
```

예시 (김간호 정면 idle_1):
```
ART STYLE: Cute cartoon chibi character sprite for a mobile game, top-down 3/4 isometric view, 
in the visual style of Brawl Stars and Cookie Run Kingdom. Bold dark navy outlines (#2D2A4A, 2-3px). 
Flat color fills, NOT pixel art, NOT photorealistic.
CHARACTER: Kim-ganho, young Korean female nursing student, curly permed dark brown hair 
forming a halo shape, large coral red headphones (#FF6B5B), small white nurse cap with red cross 
tucked in curls, closed-eye happy smile, pink cheeks, mint green scrubs (#9BE0CC), 
holding a small gold music note (#FFB347), wearing white nurse top.
POSE: Standing still, facing camera directly, body slightly elongated as if inhaling, 
both feet planted, arms relaxed at sides.
OUTPUT: 288x432px PNG, transparent background, full body, feet at bottom-center of canvas, 
no shadows, no background, no text.
```

---

**작성**: Claude (Cowork mode) · 2026-05-19
**참고 문서**: `DESIGN_RENEWAL_REQUEST.md` §8 (자산 스펙)
**시안 참고**: `mockups/character-concepts-v2.html`
