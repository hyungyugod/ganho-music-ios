# 원본 웹게임 정밀 분석 — iOS 포팅용 단일 진실 원천 (SoT)

분석 대상:
- `hyungyugod.github.io/pages/game.html` (261줄)
- `hyungyugod.github.io/assets/js/game.js` (4583줄)
- `hyungyugod.github.io/assets/css/game.css` (1942줄)

iOS 버전은 **인게임을 원본과 1:1 픽셀 단위로 재현**한다. 메뉴/선택창은 보존, 조작은 키보드→dpad 변경.

모든 라인 번호는 `assets/js/game.js` 기준이다.

---

## 0. 게임 핵심 상수 (game.js L62~L74)

```js
const TILE = 20;             // 타일 크기 (픽셀)
const COLS = 32;             // 가로 타일 수
const ROWS = 20;             // 세로 타일 수
const CANVAS_W = 640;        // = COLS * TILE
const CANVAS_H = 400;        // = ROWS * TILE
const GAME_DURATION = 45;    // 게임 시간 (초)
const SPAWN_SAFE_DIST = 4;   // 스폰 안전지대 맨해튼 거리 (타일)
```

캔버스 크기 640×400, 종횡비 16:10. 모든 픽셀 좌표는 정수 픽셀 단위로 다뤄지고 `ctx.imageSmoothingEnabled = false` (L408).

배경색 (L4174): 다크 `#09080f`, 라이트 `#e8e7ec`.

---

## 1. 맵 / 벽 / 타일 시스템

### 1.1 데이터 모델 (L262~L313 `buildMap`)

- 20×32 2차원 배열, `0` = 빈칸, `1` = 벽.
- 외곽 1타일 둘레 전부 벽 (L264~L265).
- 충돌 판정 `isWallAt(map, px, py, w, h)` — 픽셀 AABB → 타일 충돌 (L315~L328). 4 코너 타일 모두 검사.

### 1.2 난이도별 맵 — 3종

`DIFFICULTY` map 속성 매핑 (L102~L104):
- `easy` (하): `'easy'` 맵
- `normal` (중): `'hard'` 맵 (구 hard 격하)
- `hard` (상): `'hard'` 맵 (실은 normal과 동일한 맵 종류이나 코드상 분기는 둘 다 `else`로 들어감)

**중요**: 실제 빌더는 `kind === 'easy'` / `kind === 'normal'` / `else (hard)` 3분기지만, DIFFICULTY 매핑은 `easy → 'easy'`, `normal → 'hard'`, `hard → 'hard'`이다. 즉 인게임에서:
- 하 난이도 = easy 맵 빌더
- 중·상 난이도 = else 분기(hard 맵 빌더) — 두 난이도가 같은 맵을 공유

#### 1.2.1 Easy 맵 (L267~L271)

중앙 기둥 1개:
```
r=8~11, c=15~16 → m[r][c] = 1  (4행 × 2열 = 2×4 픽셀상 40×80 기둥)
```

그 외엔 외곽 벽만. 가장 개방적인 필드.

#### 1.2.2 Normal 맵 (L272~L287, kind === 'normal' 분기, 코드에는 작성되어 있지만 DIFFICULTY 매핑으로는 도달 안 됨)

- 좌상 방: `m[5][c] = 1 for c in 4..10` (가로 벽) + `m[r][10] = 1 for r in 2..5` (세로 벽). `m[3][10] = 0` (문)
- 우하 방: `m[14][c] = 1 for c in 21..27` + `m[r][21] = 1 for r in 14..17`. `m[16][21] = 0` (문)
- 중앙 기둥: `m[r][c] = 1 for r in 9..10, c in 15..16` (2×2)

#### 1.2.3 Hard 맵 (L288~L310, else 분기 — 실제로 중/상 난이도 모두 이걸 씀)

4모서리 방 + 다수 기둥:
```
좌상 방: m[5][c]=1 c∈[4,9],  m[r][9]=1 r∈[2,5], m[3][9]=0 (문)
우상 방: m[5][c]=1 c∈[22,27], m[r][22]=1 r∈[2,5], m[3][22]=0 (문)
좌하 방: m[14][c]=1 c∈[4,9],  m[r][9]=1 r∈[14,17], m[16][9]=0 (문)
우하 방: m[14][c]=1 c∈[22,27], m[r][22]=1 r∈[14,17], m[16][22]=0 (문)
중앙 기둥: m[r][12]=1, m[r][19]=1 (r∈[9,10])
세로 더블 기둥: m[7][15]=m[7][16]=1, m[12][15]=m[12][16]=1
```

### 1.3 타일 색 (L414~L424 `themeColors`)

| 키 | 다크 | 라이트 |
|---|---|---|
| floorA | `#1a1825` | `#eceaf0` |
| floorB | `#15131e` | `#e2dfe8` |
| wall | `#2a2233` | `#d4ccd6` |
| wallHi | `#3a3245` | `#bfb6c0` |
| brand | `#c4847a` | `#b07068` |
| brandHi | `#d4a49c` | `#c48a82` |

### 1.4 타일 렌더 (L426~L445 `drawMap`)

- 벽: `wall` 색 풀필 + 상단 1행/좌측 1열에 `wallHi` 2px 하이라이트 (양각 효과)
- 바닥: `(r + c) & 1`로 체크무늬 (floorA/floorB)

---

## 2. 캐릭터 5명

### 2.1 공통 스펙

- 스프라이트 매트릭스: `NURSE_W = 16, NURSE_H = 20` (L454~L455)
- 렌더 SCALE = 2 → 화면상 32×40 픽셀 (L713)
- 히트박스: 14×14 (L985 `player`)
- 비율: 2.2등신 (치비/SD)
- 머리 정중앙 = 스프라이트 좌상단 기준 (cell 0, 16) ; oy = y - 24, ox = x - 8 (L715~L716)
- 걷기 프레임 토글: 0.15s마다 1↔2 (L3841)
- 걷기 프레임 시 oy -= 1 (1픽셀 보빙, reducedMotion이면 비활성)

### 2.2 스프라이트 베이스 (정면/down/frame 0) — L465~L486

이게 김간호의 정면 idle. 다른 캐릭터는 머리·소품만 덮어쓴다.

```
행0:  ................   투명
행1:  ......HHHH......   번 꼭대기
행2:  .....HbbbbH.....   번 본체 + 음영
행3:  ....HHbbbbHH....   번 밑단
행4:  ..HHHHHHHHHHHH..   두상 윗라인
행5:  ..HHSSSSSSSSHH..   잔머리 옆 + 이마
행6:  ..SSEESSSSEESS..   눈 동공 2점
행7:  ..SSELSSSSELSS..   눈 하이라이트 (흰자)
행8:  ..RSSSSMMSSSSR..   볼터치 R + 입 MM
행9:  ..SSSSSSSSSSSS..
행10: ...SSSSSSSSSS...   턱
행11: ....WWWWWWWW....   어깨/상의
행12: ...WWWWCCWWWW...   가슴 십자 상단
행13: ...WWWCCCCWWW...   가슴 십자 중단
행14: ....WWWWWWWW....   상의 밑단
행15: ....PPPPPPPP....   하의 시작
행16: ....PPP..PPP....
행17: ....PPP..PPP....
행18: ....BB....BB....   신발
행19: ....BB....BB....
```

키 문자 의미 (L448~L451): `S`=피부, `H`=머리/번, `b`=번 음영, `W`=흰옷, `C`=코럴 십자, `E`=눈 동공, `L`=눈 하이라이트, `R`=볼터치, `M`=입, `P`=하의, `B`=신발.

### 2.3 방향별 변형 (L489~L511)

#### up (뒷모습)
얼굴 행 4~10을 전부 `H` (머리카락)로 덮음. 번(행1~3)은 정면 동일.
```
행4: ..HHHHHHHHHHHH..
행5: ..HHHHHHHHHHHH..
행6: ..HHHHHHHHHHHH..
행7: ..HHHHHHHHHHHH..
행8: ..HHHHHHHHHHHH..
행9: ..HHHHHHHHHHHH..
행10: ...HHHHHHHHHH...
```

#### left (왼쪽 보기) — 오른쪽 눈만 표시 + 오른쪽 볼터치
```
행6: ..SSSSSSSSEESS..
행7: ..SSSSSSSSELSS..
행8: ..SSSSSMMSSSSR..
```

#### right — 왼쪽 눈만 표시 + 왼쪽 볼터치
```
행6: ..SSEESSSSSSSS..
행7: ..SSELSSSSSSSS..
행8: ..RSSSSMMSSSSS..
```

### 2.4 걷기 프레임 (L513~L520)

신발(B)만 교차:
```
frame 1:  18: ....BB...BBB....   19: ....BBB...BB....
frame 2:  18: ....BBB...BB....   19: ....BB...BBB....
```

### 2.5 캐릭터별 머리·소품 오버레이

5명 모두 같은 베이스에서 시작하고 머리/소품 행만 덮어쓴다. 코드 L526~L627.

#### 2.5.1 김간호 (kim) — 기본 번머리

- ID: `'kim'`
- 별명: '번머리 실습생'
- 스킬: **없음** (L182)
- 베이스 그대로. 머리는 `H` (번), `b` (번 음영).

#### 2.5.2 정간호 (jung) — 근육 + 곡괭이

- 별명: '곡괭이 근육'
- L529~L551
- 짧은머리 본체 `J`, 음영 `j`. 어깨 2px 확장(W 행 11/14 좌우 1px씩 추가). 오른쪽 옆구리에 곡괭이 (자루 `k`/헤드 `K`).

```
행1: ................
행2: ....JJJJJJJJ....
행3: ...JJJJJJJJJJ...
행4: ..JJJJJJJJJJJJ..
행5: ..jjSSSSSSSSjj..
행11: ...WWWWWWWWWW...    (어깨 확장)
행14: ...WWWWWWWWWW...
곡괭이 (오른쪽 옆구리):
행10: ....SSSSSSSSSS KK
행11: ...WWWWWWWWWW kK
행12: ...WWWWCCWWWW .K
행13: ...WWWCCCCWWW .K
행14: ...WWWWWWWWWW .K
행15: ....PPPPPPPP .K
```

up(뒷모습)에서는 행 6~10도 `J`로 덮음.

#### 2.5.3 건간호 (geon) — 안경 + 책

- 별명: '안경과 책'
- L552~L581
- 단정 머리 `G`/`g`, 안경테 `F`, 렌즈 `f`. 책 표지 `O`, 속지 `p`.

```
행1: ................
행2: .....GGGGGGGG...
행3: ....GGGGGGGGGG..
행4: ..GGGGGGGGGGGG..
행5: ..GGSSSSSSSSGG..
정면 눈자리에 안경:
행6: ..SSFFSSSSFFSS..
행7: ..SSFfSSSSfFSS..
left  6: ..SSSSSSSSFFSS..  7: ..SSSSSSSSfFSS..
right 6: ..SSFFSSSSSSSS..  7: ..SSFfSSSSSSSS..
오른손 책:
행12: ...WWWWCCWWWW OO
행13: ...WWWCCCCWWW Op
행14: ....WWWWWWWW OO
```

#### 2.5.4 임간호 (im) — 긴머리 + 고양이귀

- 별명: '긴머리 냥'
- L582~L601
- 긴머리 `I`/`i`, 고양이귀 머리띠 `T`. 어깨 아래로 양옆에 머리가 흘러내림 (행 11~14).

```
행1: ....T......T....
행2: ...TT.IIII.TT...
행3: ....IIIIIIII....
행4: ..IIIIIIIIIIII..
행5: ..IISSSSSSSSII..
어깨 아래 긴머리:
행11: iI..WWWWWWWW..Ii
행12: iI.WWWWCCWWWW.Ii
행13: iI.WWWCCCCWWW.Ii
행14: iI..WWWWWWWW..Ii
```

up에서는 행 6~10도 `I`로 덮음.

#### 2.5.5 이간호 (lee) — 단발 + 강아지귀

- 별명: '단발 댕댕'
- L602~L626
- 단발 본체 `Q`, 음영 `q`, 강아지귀 `D`.

```
행1: ................
행2: ...DDQQQQQQQQDD...   (강아지 귀가 정수리 양 끝)
                  실제 코드: '...DD' + base[2].substr(5,11) + 'DD...'
                  → base[2]='.....QQQQQQQQ...' → '...DD' + 'QQQQQQ' + 'DD...'
                  = '...DDQQQQQQDD...'
행3: '...DD' + base[3].substr(5,11) + 'DD...'
       base[3]='....QQQQQQQQQQ..' → '...DD'+'QQQQQQ'+'DD...' = '...DDQQQQQQDD...'
행4: ..QQQQQQQQQQQQ..
행5: ..QQSSSSSSSSQQ..
정면/좌/우는 얼굴 가장자리 행 6~8에 q 음영 오버레이:
overlayEdge(row) = 'qq' + row.substring(2,14) + 'qq'
```

**중요**: 임/이의 머리 키는 `L`/`I`와 충돌하지 않도록 `Q`/`q`, `D`로 분리되어 있다. 자세한 주석은 L694~L696.

### 2.6 캐릭터별 팔레트 (L645~L699 `getNursePalette`)

#### 공통 색 (모든 캐릭터 동일)
```js
'S': '#fbe0d0',   // 피부
'W': '#ffffff',   // 흰옷
'C': '#c4847a',   // 코럴 십자 (브랜드)
'P': '#9ec9e8' (다크) / '#7fb5d8' (라이트),   // 하의 (--nurse-pants)
'B': '#a85f56',   // 신발
'E': '#2a1f25',   // 눈 동공
'L': '#ffffff',   // 흰자
'R': '#f5a8a0',   // 볼터치
'M': '#c4847a'    // 입
```

#### 캐릭터별 머리·소품 색 (다크 모드 기준 / 라이트 모드는 CSS 변수에서 살짝 어두워짐)

| 캐릭터 | 키 | 다크 색 | 라이트 색 |
|---|---|---|---|
| kim | H (번) | `#3a2a20` | `#2e2018` |
| kim | b (번 음영) | `#5a4230` | `#4a3428` |
| jung | J (짧은머리) | `#2a1a12` | `#1f1410` |
| jung | j (머리 음영) | `#180c08` | `#0f0806` |
| jung | K (곡괭이 헤드) | `#9aa0a8` | `#85898f` |
| jung | k (곡괭이 자루) | `#7a4f2a` | `#6a431f` |
| geon | G (단정머리) | `#30221c` | `#26180f` |
| geon | g (머리 음영) | `#1a0f0a` | `#120a06` |
| geon | F (안경테) | `#1f1a1f` | `#2a242a` |
| geon | f (렌즈) | `#e8f0f8` | (동일) |
| geon | O (책 표지) | `#8a5a32` | `#7a4a24` |
| geon | p (책 속지) | `#f6ebd9` | (동일) |
| im | I (긴머리) | `#3a2618` | `#2e1c10` |
| im | i (머리 음영) | `#22150c` | `#180c06` |
| im | T (고양이귀) | `#ff9db0` | `#e87a92` |
| lee | Q (단발) | `#5a3a22` | `#4a2c18` |
| lee | q (음영) | `#3a2414` | `#2c180a` |
| lee | D (강아지귀) | `#b07a58` | `#986648` |

### 2.7 능력치 (L99 주석)

> 능력치는 모두 동일합니다.

이동 속도는 난이도에서만 차등, 캐릭터별로는 차이가 없다. 스킬만 다르다.

### 2.8 스킬 시스템 (L183~L188 `SKILLS`)

| 캐릭터 | 스킬명 | 설명 | durationMs | cooldownMs | 약칭 (HUD) |
|---|---|---|---|---|---|
| kim | (없음) | — | — | — | — |
| jung | 암벽등반 돌진 | 바라보는 방향으로 3타일 돌진 + 앞 벽 1칸 분쇄 | 260 | 22000 | 돌진 |
| geon | 북클럽 소집 | 주변 6타일 안의 음표 한번에 끌어와 수집 | 0 (즉발) | 20000 | 소집 |
| im | 나는야 모범생 | 수간호사 매혹: F → A로 전환, A 먹으면 점수 2배. **게임당 1회** | 1500 | 0 | 모범 |
| lee | 대만여행 | 가장 먼 빈 타일로 순간이동 + 0.5초 무적 | 500 | 22000 | 여행 |

추가 상수 (L194~L197):
```js
JUNG_DASH_TILES = 3;
JUNG_DASH_PX = 60;          // 3 * 20
JUNG_BREAK_RADIUS = 18;     // 미사용 (벽 분쇄는 corner 검사로 처리)
GEON_MAGNET_RADIUS = 120;   // 6 * TILE
```

#### 2.8.1 jung 돌진 구현 (L3607~L3647)

- 현재 `p.dir`로 단위 벡터 결정 (vx, vy).
- `STEP = TILE/2 = 10` 단위로 전진, 누적 `traveled < 60`.
- 매 스텝 `isWallAt` 검사 — 벽 만나면:
  - 4 코너(`(nx,ny), (nx+w-1,ny), (nx,ny+h-1), (nx+w-1,ny+h-1)`) 중 첫 벽 타일을 0으로 변경.
  - 파티클 14개, 효과음 180Hz/0.12s.
  - 중단.
- 발동 후 invincibleUntil = now + 260ms.

#### 2.8.2 geon 소집 구현 (L3649~L3687)

- 플레이어 중심 ± 6*20 = 120px 이내 음표 전체 수집.
- 0개면 false 반환 (쿨다운 미소모).
- 각 음표마다 콤보+1, 점수 누산 (정상 공식과 동일). 마지막 1회만 사운드.
- 각 위치에 파티클 4개.

#### 2.8.3 im 매혹 구현 (L3689~L3693, L191~L193 isImCharmed)

- 즉시 `state.obstacles` 모든 `o.type = 'A'`로 변환.
- `state.skill.activeUntil = now + 1500`. 이 동안 새로 스폰되는 F도 `'A'` 타입으로 생성됨 (L2571, L2786 `isImCharmed` 확인).
- 발동 후 `state.skill.readyAt = Infinity`, `state.skill.usedOnce = true` (게임당 1회 차단, L3580~L3585).

#### 2.8.4 lee 워프 구현 (L3695~L3739)

- 전체 빈 타일 중 플레이어 타일에서 맨해튼 거리 최대인 타일 선택.
- 단, 수간호사·이교수 각각 SPAWN_SAFE_DIST(4 타일) 이내 제외.
- 좌표: `bestTile.c * 20 + 3, bestTile.r * 20 + 3` (히트박스 14 + 3px 패딩 → 타일 중앙 근접).
- invincibleUntil = now + 500ms.
- 출발/도착 파티클 각 10개.

---

## 3. 빌런들

### 3.1 수간호사 (Chief Nurse) — 메인 적

기본 풀필. 모든 난이도에서 활성. F를 던지는 메인 빌런.

#### 3.1.1 스프라이트 (L819~L892 `nurseChiefSprite`)

16×20, 베이스 정면:
```
행0:  ................
행1:  ....KKKKKKKK....   간호사 캡
행2:  ...KKKKXXKKKK...   캡 + 코럴 십자 X
행3:  ..KkkkkkkkkkkK..   캡 밑단(음영 k)
행4:  ..HHSSSSSSSSHH..   이마 + 백발 옆선
행5:  ..HhSSSSSSSShH..   백발 음영
행6:  ..hSGGSSSSGGSh..   안경테 G
행7:  ..hSGgSSSSgGSh..   안경 렌즈 g
행8:  ..hSSNSSSSNSSh..   눈 밑 주름 N
행9:  ..hSSSSMMSSSSh..   입 M
행10: ..hhSSNNNNSSHh..   팔자 주름 + 턱선
행11: ...UUUUUUUUUU...   흰 간호사복 어깨
행12: ..UUUUVCCVUUUU..   옷깃 + 코럴 십자 C, 음영 V
행13: ..UUVVVVVVVVUU..   상의 음영
행14: ...UUUUUUUUUU...
행15: ....UUUUUUUU....   하의 (간호사복과 동일)
행16: ....UUU..UUU....
행17: ....UUU..UUU....
행18: ....BB....BB....   검정 구두
행19: ....BB....BB....
```

up/left/right 방향별 face 변형 — L844~L865 참고.
걷기 프레임 (1, 2) — 발 교차, frame 1: `....BB...BBB....` / `....BBB...BB....` (L867~L874).

#### 3.1.2 투척 자세 (throwArm) — L877~L889

상의 측면에 흰 소매 한 줄을 올림. 방향에 따라 좌/우/중앙 분기.

```
left:  base[10] = '..UUhhNNNNSSHh..'
       base[11] = '..UUUUUUUUUU....'
right: base[10] = '..hhSSNNNNhhUU..'
       base[11] = '....UUUUUUUUUU..'
else:  base[10] = '..UUhSNNNNShUU..'
       base[11] = '..UUUUUUUUUUUU..'
```

#### 3.1.3 팔레트 (L897~L922 `getChiefPalette`)

```
S: #f5d5c0           피부 (살짝 어두움)
N: #c08878 (D) / #a06860 (L)    주름
H: #e8e4e8 (D) / #d8d0d8 (L)    백발
h: #c8c4cc (D) / #a89ea8 (L)    백발 음영
K: #ffffff (D) / #fafafa (L)    캡
k: #e6dde6 (D) / #d8d0d0 (L)    캡 음영
X: var(--brand) = #c4847a (D) / #b07068 (L)   캡 코럴 십자
G: #1f1a1f                       안경테
g: #e8c8b8                       렌즈 안 (피부 톤)
U: #f4f0ee (D) / #ffffff (L)    흰 간호사복
V: #d8d2d0 (D) / #c0b8b8 (L)    옷 음영
C: var(--brand)                  옷깃 코럴
P: #f4f0ee                       하의 (간호사복 통일)
B: #1a1214                       구두
M: #6b3a3a                       입술
```

#### 3.1.4 매혹 하트 오버레이 (L941~L953)

`isImCharmed`가 true일 때 안경 렌즈 위에 3×3 픽셀 하트 핑크(#ff4d8d)로 그림.
좌측 눈 `(c, r) = (3, 6)`, 우측 눈 `(c, r) = (9, 6)`.

#### 3.1.5 패트롤 경로 — **AI는 BFS/A* 아닌 단순 4지점 사각 순환**

L2584~L2638 `initNurseChief`:

| 난이도 | 패트롤 포인트 | 속도(px/s) |
|---|---|---|
| easy | `(60, 60) → (560, 60)` 좌상 ↔ 우상 왕복 (2점) | 40 |
| normal | `(60,60) → (560,340) → (560,60) → (60,340)` Z패턴 (4점) | 60 |
| hard | `(60,60) → (560,60) → (560,340) → (60,340)` 4모서리 시계방향 (4점) | 100 |

좌표:
```
leftX  = TILE * 3        = 60
rightX = TILE * (32-4)   = 560
topY   = TILE * 3        = 60
bottomY = TILE * (20-4)  = 320  (실제 코드 (ROWS-4) = 16 → 16*20=320)
```

**잠깐, 다시 확인**: `bottomY = TILE * (ROWS - 4) = 20 * 16 = 320`이 맞다. 위 표 normal/hard의 340은 오타. **bottomY = 320**.

시작 위치: 플레이어 spawn에서 맨해튼이 아닌 유클리드(`Math.hypot`)로 가장 먼 패트롤 포인트 선택 (L2618~L2628). 첫 프레임 즉사 방지.

#### 3.1.6 추격 로직 — **추격 안 함**

수간호사는 **순찰만 한다**. 플레이어를 향해 추격하는 로직 없음. 위협은 F 투척으로만.

#### 3.1.7 이동 (L2689~L2709)

- 현재 목표 포인트까지 선형 이동. `step = speed * dt`.
- `dist <= step`이면 도착 처리 + 다음 인덱스로.
- 그렇지 않으면 단위벡터 × step 누산.
- 방향(dir) 갱신: 주이동축 기준 (`|dx| > |dy|` ? 좌우 : 상하).

#### 3.1.8 걷기 프레임 (L2711~L2720)

frameAcc += dt, 0.18초마다 frame 1↔2 토글. reducedMotion이면 frame 0 고정.

#### 3.1.9 투척 타이머 (L2722~L2743)

상태 머신:
- `telegraphUntil === 0` (대기): `throwTimer -= dt`. 0 이하 → 텔레그래프 시작 (`telegraphUntil = now + 400ms`).
- `telegraphUntil > 0` (텔레그래프): 머리 위에 빨간 `!` 깜빡임 표시.
- `now >= telegraphUntil` (투척): 실제 F 스폰 (`spawnObstacleFromChief`), `throwArmUntil = now + 180ms`, `throwTimer = lerp(spawnInterval[0], spawnInterval[1], curveT())`.

`curveT()` = 1 - (timeLeft / 45) — 시간이 흐를수록 0→1로 증가.

#### 3.1.10 F 투척 로직 (L2746~L2791 `spawnObstacleFromChief`)

- 플레이어 중심 방향 단위 벡터 + 단위각 `baseAngle = atan2(dy, dx)`.
- `burst = throwBurst` (난이도별), 각 발사체는 ±15° 스프레드 + ±0.025rad 랜덤 흔들림.
- 시작점: 수간호사 위치 + 단위벡터 × 12px.
- 맵 경계 클램프, 벽 위면 `findEmptyTile` 폴백.
- F 타입은 `isImCharmed(now) ? 'A' : 'F'`.

#### 3.1.11 텔레그래프 그래픽 (L960~L974 `drawTelegraph`)

수간호사 머리 위 y - 42에 빨간 `!` 표시. 120ms 단위 깜빡임. reducedMotion이면 항상 표시.
색: 다크 `#ff3b4e`, 라이트 `#e8283a`.

#### 3.1.12 본체 접촉 즉사 (L3991~L4017)

`CHIEF_HB = 14` 히트박스. 플레이어 14×14와 AABB 검사. 무적 중이면 스킵.
충돌 시: hits++, combo=0, 효과음 110→82Hz, 셰이크+게임오버 비네트, `gameoverReason = 'hit'`, endGame.

### 3.2 이교수 (Professor Lee) — **상 난이도만**

수간호사와 협공. 청진기를 던져 플레이어를 2초간 정지시킴 (즉사 X).

#### 3.2.1 상수 (L109~L115 `PROFESSOR`)
```js
patrolSpeed:    70   px/s
throwInterval:  [2.5, 1.4]  sec (시간 경과 보간)
stethoSpeed:    220  px/s   (청진기 속도)
stethoMax:      4    동시 상한
freezeDuration: 2000 ms     (정지 시간)
```

#### 3.2.2 스프라이트 (L2799~L2868 `professorSprite`)

16×20 베이스 정면:
```
행0:  ................
행1:  ....HHHHHHHH....   머리 윗단
행2:  ...HcHHHHHHcH...   뽀글 컬 c
행3:  ..HcHHHHHHHHcH..
행4:  ..HHHSSSSSSHHH..   헤어라인 + 이마
행5:  ..HHSSSSSSSSHH..
행6:  ..HhSGGSSGGShH..   안경테 G
행7:  ..HhSGgSSgGShH..   안경 렌즈 g
행8:  ..HhSSNSSNSShH..   눈 밑 음영
행9:  ..HhSSSMMSSShH..   입 M (얇은 한줄)
행10: ..HhhSNNNNShhH..   턱 + 머리 어깨까지
행11: ...JJAAWWAAJJ...   자켓 + V넥 A + 흰 셔츠 W
행12: ..JJJJAWWAJJJJ..
행13: ..JjjjAWWAjjjJ..   자켓 음영 j
행14: ..JJJJJJJJJJJJ..
행15: ...JJJJJJJJJJ...
행16: ....JJJ..JJJ....   하의
행17: ....JJJ..JJJ....
행18: ....BB....BB....   구두
행19: ....BB....BB....
```

up: 행 4~10 전체 머리 `H`로 덮음.
left/right: 안경/입 한쪽 편향.
throwArm (L2854~L2865): 자켓 소매 어깨 위로 올림 — 방향별 패턴 3종.
걷기 프레임 (1, 2): 수간호사와 같은 패턴.

#### 3.2.3 팔레트 (L2873~L2896)

```
S: #f5d5c0       피부
N: #c08878       음영
H: #1a1216 (D) / #221820 (L)   검정 뽀글머리
h: #0c080a (D) / #120c10 (L)   머리 음영
c: #2a1e22 (D) / #3a2a30 (L)   컬 하이라이트
G: #1f1a1f                      안경테
g: #e8c8b8                      렌즈 안
M: #5a3030                      입
J: #181418 (D) / #1f1a20 (L)   검정 자켓
j: #0a0608 (D) / #100a10 (L)   자켓 음영
A: #3a2e34 (D) / #4a3a44 (L)   V넥 칼라
W: #e8e4e8                      흰 셔츠
B: #0a0608                      구두
```

#### 3.2.4 패트롤 (L2983~L3019 `initProfessor`)

8자(figure-8) 경로 4점:
```
(120, 100) → (520, 280) → (520, 100) → (120, 280)
leftX=120 (TILE*6), rightX=520 (TILE*25), topY=100 (TILE*5), bottomY=280 (TILE*14)
```

수간호사(외곽 4모서리)와 다른 동선으로 협공. farthest-first로 spawn에서 먼 점 시작. 첫 투척까지 3.0초 대기.

이동 로직은 수간호사와 동일 (L3026~L3050). 속도만 70px/s.

#### 3.2.5 청진기 투척 (L3084~L3106 `spawnStethoscopeFromProfessor`)

- 텔레그래프 0.4s 후 발사.
- 동시 상한 `stethoMax = 4`.
- 발사 시점 플레이어 방향 단위벡터 × `stethoSpeed = 220` 속도.
- 시작점: 이교수 위치 + 단위벡터 × 12px.
- 다음 투척 간격: `lerp(2.5, 1.4, curveT())`.

#### 3.2.6 청진기 투사체 (L2922~L2960 `drawStethoscope`)

14×8 도트, SCALE=2 → 28×16 화면 크기. 비행 중 자체 회전 `now/100 % 2π`.

```
'..tt......tt..'
'..tt......tt..'
'..tt......tt..'
'...tt....tt...'
'....tttttt....'
'....tBBBBt....'
'....BBBBBB....'
'.....mmmm.....'
```

색: t=튜브 `#2a2228`(prof-stethoscope-tube), B=벨 `#d8d4dc`(bell), m=림 `#c8c8d0`(rim).

#### 3.2.7 청진기 충돌 (L4060~L4084)

- 12×12 히트박스. 무적 중 스킵.
- 청진기 소멸 (관통 X).
- `stethoToastUntil = now + 1000` (토스트 1초 표시 — 캔버스 상단 2단 박스).
- `frozenUntil = now + 1000 + 2000 = now + 3000` (토스트 종료 후 2초 정지가 시작되도록 직렬화).
- combo = 0, hits는 증가 안 함.
- 효과음 440→220Hz 2연타.

#### 3.2.8 본체 접촉 즉사 (L4019~L4044)

수간호사와 동일하게 즉사. HB 14.

#### 3.2.9 청진기 텔레그래프 (L2965~L2976)

코럴핑크 `!` 표시 (수간호사 빨강과 구분). 다크 `#ff7b7b`, 라이트 `#e85a6a`.

### 3.3 석조무사 (Stone Guard) — **하/중 난이도만**

투척 없는 조무래기. 접촉 시 이스터에그(박병장) 발동.

#### 3.3.1 상수 (L119~L122 `STONE_GUARD`)
```js
patrolSpeed: 55  px/s
hitbox:      14
```

#### 3.3.2 스프라이트 (L3120~L3169 `stoneGuardSprite`)

16×20 베이스 정면:
```
행0:  ................
행1:  .....HHHHHH.....   짧은 검정 머리
행2:  ....HHHHHHHH....
행3:  ....HHHHHHHH....
행4:  ....HKKKKKKH....   이마 + 헤어라인
행5:  ....KKKKKKKK....   얼굴 상단
행6:  ....KEKKKKEK....   날카로운 눈 2점
행7:  ....KKKKKKKK....
행8:  ....KKKKKKKK....   입 생략(단호)
행9:  ....KKKKKKKK....
행10: ...UUUUUUUUUU...   교복 상의
행11: ..UUUuUUUUuUUU..   단추 라인 u
행12: ..UUUuUUUUuUUU..
행13: ..UUUuUUUUuUUU..
행14: ..UUUUUUUUUUUU..
행15: ...UUUUUUUUUU...
행16: ....PPPP.PPPP...   바지 (가운데 1px 빈공간)
행17: ....PPPP.PPPP...
행18: ....BBBB.BBBB...   검정 구두
행19: ....BBBB.BBBB...
```

up: 얼굴 행 모두 머리로 덮음. left/right: 눈 한쪽 치우침.
걷기 프레임 (1, 2):
```
1: 18: ....BBB...BBB...   19: ....BBBB.BBB....
2: 18: ....BBB.BBBB....   19: ....BBB...BBB...
```

#### 3.3.3 팔레트 (L3175~L3192)

```
U: #2a3550 (D) / #23304a (L)   남색 교복
u: #1a2238 (D) / #141c30 (L)   교복 음영
P: #1f2533 (D) / #181e2a (L)   바지
K: #e8c9a6 (D) / #dcb894 (L)   피부
H: #1a1418 (D) / #0e0a0e (L)   검정 머리
E: #2a2228 (D) / #1a141a (L)   눈
B: #0f0f12 (D) / #080808 (L)   구두
```

#### 3.3.4 패트롤 (L3221~L3274 `initStoneGuard`)

4지점 사각 순환:
```
leftX=80 (TILE*4), rightX=540 (TILE*27), topY=80 (TILE*4), bottomY=300 (TILE*15)
```

벽 타일이면 BFS 없이 인접 빈 셀 선형 탐색으로 클램프 (L3236~L3255).
farthest-first 시작. frameAcc 토글 0.22초.

#### 3.3.5 접촉 시 이스터에그 발동 (L4046~L4058)

- 즉사 X. `triggerAirforceEasterEgg(now)` 호출.
- 석조무사 active=false (퇴장).
- 박병장 경고 오버레이 노출.

### 3.4 박병장 비행기 (이스터에그)

#### 3.4.1 상수 (L127~L144 `AIRFORCE`)
```js
flyDuration:     2400  ms  비행기 화면 통과 시간
planeSpeed:      320   px/s
planeY:          40    상단 고정 y
planeW:          48
planeH:          14
fleeDuration:    5000  ms  수간호사 도망 시간
fleeSpeed:       180   px/s
bombDropDelay:   300   ms  오버레이 닫힘 후 폭탄까지 지연
bombFlashDuration: 420 ms
bombY:           140   px  폭탄 낙하 y
respawnCountMultiplier: 1.0  F 재시딩 비율
title: '나와라 박병장!'
subtitle: '석조무사가 학창시절 같은반 친구 박병장을 불러 실습생을 도와줍니다!'
```

#### 3.4.2 비행기 스프라이트 (L3328~L3336 `airplaneSprite`)

16×5 도트, SCALE=3 → 48×15 화면 크기:
```
.......A........
.AAA.AAAAWAAA.A.
AAAAAAAAAAAAAAA.
.AAA.AAAAWAAA.A.
.......A........
```
A=동체/날개 회색 (다크 `#aab3c7`, 라이트 `#444b5c`), W=창문 `#e2e7ef`.

#### 3.4.3 3단계 상태 머신

**1단계 — 접촉** (L3350~L3376 `triggerAirforceEasterEgg`):
- 석조무사 active=false
- 게임 루프 정지 (running=false, cancelAnimationFrame)
- 입력 초기화
- DOM 오버레이 `overlayAirforce` 노출 (제목 "나와라 박병장!", 부제 + "확인을 누르면 박병장이 출동합니다")
- 포커스: `btnAirforceContinue`

**2단계 — 확인 클릭** (L3382~L3412 `onAirforceContinue`):
- 오버레이 닫음
- 비행기 스폰: `x = -48 (planeW), y = 40 (planeY), expiresAt = now + 2400, pendingBombDrop = now + 300`
- 수간호사 flee 시작 (`startChiefFlee`)
- 효과음 120→90Hz (저음 엔진음)
- 게임 루프 재개, lastTs 보정, F 스폰 타이머 보정

**3단계 — 폭탄 투하** (L3419~L3447 `dropBomb`):
- `pendingBombDrop` 도달 시 발동
- `state.obstacles`에서 type === 'F' 전부 삭제 (A는 보존)
- canvasWrap에 `is-bomb-flash` 클래스 420ms (밝기 2.4배 + 채도 1.3배)
- 폭발 파티클 22개 (CANVAS_W/2, bombY=140)
- 효과음 80→55Hz 2연타
- 셰이크 500ms

#### 3.4.4 수간호사 flee (L3454~L3470 `startChiefFlee`)

- 맵 중앙 반대편 코너 방향 단위벡터 (`dx = chief.x >= 320 ? 1 : -1` 등) × 1/√2.
- fleeUntil = now + 5000, 5초간 fleeSpeed 180px/s로 후퇴.
- 텔레그래프·투척 타이머 무력화 (`throwTimer = 99`).
- 패트롤/투척 모두 차단 (L2650~L2675 update에서 fleeUntil>now면 일찍 return).

#### 3.4.5 flee 종료 후 복귀 (L2678~L2687)

- F 재시딩: `Math.round(obstacles * 1.0) - 현재 F 개수`만큼 `spawnObstacle()`.
- 효과음 220Hz (수간호사 복귀 신호).

#### 3.4.6 비행기 업데이트/렌더 (L3477~L3514)

- 위치 `x += 320 * dt`
- `now >= expiresAt || x > 640` → active=false
- 렌더는 SCALE=3 도트.

---

## 4. 음표 시스템

### 4.1 스프라이트 (L730~L750 `drawNote`)

12×12 8분 음표. 두 색만 사용:
- 본체: themeColors().brand
- 하이라이트: themeColors().brandHi

픽셀 패턴 (좌표는 ox, oy 기준):
```
머리: fillRect(ox+1, oy+7, 6, 4) + (ox+2, oy+6, 4, 1) + (ox+2, oy+11, 4, 1)
하이라이트: fillRect(ox+2, oy+7, 1, 1)   brandHi
기둥: fillRect(ox+6, oy+1, 1, 7)
깃발 상단: fillRect(ox+6, oy+1, 4, 1)
깃발 우측: fillRect(ox+9, oy+1, 1, 3)
깃발 중간: fillRect(ox+7, oy+4, 2, 1)
```

bob 애니메이션: `Math.sin((now/220) + bobSeed) * 1.2` y 오프셋 (L4180).

### 4.2 스폰 (L2526~L2542 `spawnNote`)

- 플레이어 타일 + 석조무사 타일 회피 (4타일 거리).
- 좌표: `tile.c * 20 + (20-12)/2 = tile.c*20 + 4`.
- 1개당 데이터: `{x, y, born, bobSeed}`.

### 4.3 동시 개수 / TTL — 난이도별 (L102~L104)

| 난이도 | 동시 음표 수 (notes) | TTL (ms) |
|---|---|---|
| easy | 5 | Infinity (영구) |
| normal | 4 | 3500 |
| hard | 4 | 2800 |

매 프레임 `while (state.notes.length < diff.notes) spawnNote();` (L3904) — 부족하면 자동 보충.

### 4.4 TTL 만료 (L3901~L3903)

`now - born >= ttl`이면 삭제. 마지막 1초는 120ms 단위 깜빡임 (L4183~L4185).

### 4.5 수집 판정 (L3915~L3949)

- 12×12 AABB 충돌.
- 콤보 +1, collected +1.
- 점수 가산 (콤보 보너스):
  - combo >= 7: +4
  - combo >= 5: +3
  - combo >= 3: +2
  - 그 외: +1
- 사운드: SCALE_FREQS[min(combo-1, 9)] 0.09s
- 파티클: 기본 6개, combo≥3: 10개, combo≥7: 14개

### 4.6 C장조 스케일 사운드 (L161 SCALE_FREQS)

```js
[261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00]
// C4 D4 E4 G4 A4 C5 D5 E5 G5 A5
```

### 4.7 화캉스 보너스 변기 — 특수 아이템

#### 4.7.1 상수 (L165~L171 `TOILET`)
```js
spawnInterval:   12  sec
spawnChance:     0.15
ttl:             8000  ms
bonusMultiplier: 2
toastDuration:   900   ms
```

#### 4.7.2 스프라이트 (L756~L781 `drawToilet`)

16×16. 다음 색만 사용:
- 흰색 `#ffffff` (물탱크/시트)
- 연회색 `#cfd3da` (뚜껑/시트 테두리)
- 옅은 파랑 `#a9d6ef` (물 하이라이트)
- 검정 `#1a1a22` (중앙 구멍)
- 외곽 그림자 `rgba(0,0,0,0.25)`

```
물탱크: fillRect(ox+3, oy+1, 10, 5)  흰
뚜껑: fillRect(ox+3, oy+1, 10, 1)    연회색
시트: fillRect(ox+1, oy+8, 14, 5) + (ox+2, oy+13, 12, 1)  흰
시트 테두리: fillRect(ox+1, oy+8, 14, 1)  연회색
물: fillRect(ox+5, oy+11, 6, 1)  옅은 파랑
구멍: fillRect(ox+7, oy+11, 2, 2)  검정
```

#### 4.7.3 스폰 (L2548~L2558)

매 12초 주기마다 15% 확률 굴림. 동시 최대 1개. 플레이어 타일 회피.

#### 4.7.4 수집 (L3952~L3986)

- 16×16 AABB.
- 콤보 +2 (음표 수집 2회분 반복).
- 점수도 2회 가산 (각각 콤보 보너스 적용).
- 사운드: SCALE_FREQS 2연타 (한 음 위까지 두 번).
- 파티클 16개.
- 토스트 900ms ("화캉스 보너스!").

#### 4.7.5 토스트 렌더 (L4278~L4299)

캔버스 상단 (cx, 40) 위치, 220×36 박스. 다크 배경 `#3a2a10` + 텍스트 `#ffd580`. 라이트는 `#fff5d6` 배경 + `#8a5a00` 텍스트.

---

## 5. F 투사체 / A (매혹) 투사체

### 5.1 F 스프라이트 (L783~L812 `drawObstacle` type='F')

12×12. 흰 테두리 + 빨간 F 글자.

```
외곽 섀도: fillRect(ox+1, oy+1, 12, 12)   rgba(0,0,0,0.25)
흰 테두리: fillRect(ox, oy, 12, 12)        #ffffff
빨간 F:
  fillRect(ox+2, oy+1, 8, 2)    가로 상단
  fillRect(ox+2, oy+1, 2, 10)   세로 왼쪽
  fillRect(ox+2, oy+5, 6, 2)    중간 가로
```

색: 다크 `#ff3b4e`, 라이트 `#e8283a`.

### 5.2 A 스프라이트 (L793~L805, type='A')

매혹 상태 F가 A로 전환. 분홍색 글자.

```
외곽 섀도 + 흰 테두리 (F와 동일)
A 본체 (분홍):
  fillRect(ox+5, oy+1, 2, 2)    꼭짓점
  fillRect(ox+4, oy+3, 1, 2)    좌 경사
  fillRect(ox+7, oy+3, 1, 2)    우 경사
  fillRect(ox+3, oy+5, 1, 6)    좌 다리
  fillRect(ox+8, oy+5, 1, 6)    우 다리
  fillRect(ox+4, oy+7, 4, 2)    가로획
```

색: 다크 `#ff6fa8`, 라이트 `#e84d8d`.

### 5.3 데이터 모델 (L2566~L2573 `spawnObstacle`)

```js
{ x, y, dx, dy, type: 'F' | 'A' }
```

초기 4방향 랜덤. `dx, dy ∈ {-1, 0, 1}`.

### 5.4 이동 / 벽 반사 (L3852~L3870 update)

매 프레임 `dx*oStep, dy*oStep` 전진. 벽 충돌 시 랜덤 4방향 재시도, 최대 4회. 못 움직이면 그 자리에서 멈춤.

속도: `currentObsSpeed() = lerp(obsBaseSpeed, obsMaxSpeed, curveT())` (L253~L256).

### 5.5 F 충돌 즉사 (L4110~L4138)

12×12 AABB. 무적 중 스킵. 충돌 → hits++, combo=0, 셰이크, 비네트, endGame.

### 5.6 A 수집 (L4087~L4108)

콤보 +1, 점수 가산 후 ×2 (`state.score += gain * 2`). 사운드 2음 상승 (마지막+1.26배).

---

## 6. 난이도 시스템 (L101~L105 `DIFFICULTY`)

### 6.1 전체 표

| 항목 | easy (하) | normal (중) | hard (상) |
|---|---|---|---|
| baseSpeed (플레이어, px/s) | 140 | 160 | 160 |
| maxSpeed (플레이어, px/s) | 210 | 250 | 250 |
| notes (동시 음표) | 5 | 4 | 4 |
| noteTtl (ms) | ∞ | 3500 | 2800 |
| obstacles (초기 F) | 1 | 5 | 6 |
| obsBaseSpeed (F, px/s) | 60 | 170 | 200 |
| obsMaxSpeed (F, px/s) | 110 | 290 | 340 |
| stun (ms) | 400 | 700 | 700 |
| map | 'easy' | 'hard' | 'hard' |
| spawnInterval ([base, max], sec) | [3.5, 2.0] | [1.0, 0.35] | [0.8, 0.25] |
| maxObstacles (F 상한) | 2 | 10 | 14 |
| throwBurst (1회 투척 수) | 1 | 3 | 4 |

**참고**: `stun`은 코드에서 정의되어 있지만 실제 사용되는 곳은 청진기 freezeDuration(2000ms 별도)으로 대체된 듯하다. F 즉사 시 stunUntil은 사용되지 않는다.

### 6.2 목표 점수 (L95 `TARGET_SCORE`)

| 난이도 | 목표 |
|---|---|
| easy | 60 |
| normal | 50 |
| hard | 30 |

### 6.3 빌런 활성 매트릭스

| 난이도 | 수간호사 | 이교수 | 석조무사 | 박병장 (이스터에그) |
|---|---|---|---|---|
| easy | ✅ | ❌ | ✅ | ✅ (석조무사 접촉 시) |
| normal | ✅ | ❌ | ✅ | ✅ |
| hard | ✅ | ✅ | ❌ | ❌ |

`startGame` (L2207~L2218): hard일 때 professor 활성, easy/normal일 때 stoneGuard 활성.

### 6.4 시간 보간 (L243~L256)

- `curveT() = 1 - (timeLeft / 45)` — 0(시작) → 1(종료).
- `lerp(a, b, t)` 0~1 클램프.
- 플레이어 속도, F 속도, F 스폰 간격, 이교수 청진기 간격 모두 시간 따라 가속.

---

## 7. 이스터에그 / 숨겨진 요소

### 7.1 박병장 (= 이미 §3.4에서 설명)

석조무사 접촉이 트리거. 안내 컷씬 `introStoneGuard` (L226~L228)에는 "마주치면 잡혀갑니다"라고 거짓 경고가 나옴 — 실제로는 아군 비행기가 출동하는 반전.

### 7.2 화캉스 보너스 변기 (= 이미 §4.7)

15% 확률 12초마다 굴림. 발견 자체가 깜짝 이벤트.

### 7.3 매혹된 수간호사 (im 스킬)

수간호사가 F 대신 A를 던지게 됨. 안경 위에 핑크 하트눈 표시 (L941~L953).

### 7.4 졸업장 시스템 (L1748~L2105)

3난이도 모두 목표 달성 시 캐릭터별로 졸업장 발급. 한 번 졸업한 캐릭터는 카드에 "🎓 졸업" 뱃지. 720×1000 PNG 다운로드 가능.

### 7.5 HG의 실제 작곡 트랙 링크

성공 엔딩(타임오버 + 목표 달성) 시 "🎵 HG가 실습때 만든 노래 듣기" 버튼 노출. YouTube 링크 (`https://www.youtube.com/watch?v=_lIkCnyABVA`).

### 7.6 컷씬 5종 (L200~L233 `CUTSCENES`)

| ID | 트리거 | 비고 |
|---|---|---|
| intro | startGame 직후 250ms (L2268) | 난이도별 분기 (easy/normal vs hard) |
| mid1 | timeLeft <= 30 (경과 15초) | 캐릭터별 속마음 분기 |
| mid2 | timeLeft <= 15 (경과 30초) | "수간호사의 눈초리" |
| introStoneGuard | intro 종료 후 (easy/normal) | "잡혀갑니다" |
| introProfessor | intro 종료 후 (hard) | "청진기에 맞으면 정지" |

각 컷씬은 1회만 표시 (`state.cutscenesShown` Set 추적).

---

## 8. 게임 흐름 / 승리 조건

### 8.1 화면 흐름

```
시작 오버레이 (overlayStart)
  → 난이도 선택 (easy/normal/hard)
  → "시작" 클릭
→ 캐릭터 선택 오버레이 (overlayCharacter) — 5명 카드 그리드
  → "이 친구로 시작" 클릭
→ (스킬 있는 캐릭터면) 스킬 설명 오버레이 (overlaySkill)
  → "시작" 클릭
→ startGame (L2161)
  → intro 컷씬 250ms 후
  → [게임 진행]
    · 경과 15s → mid1 컷씬
    · 경과 30s → mid2 컷씬
    · F/수간호사/이교수 접촉 → endGame('hit')
    · 청진기 → 2초 정지
    · 석조무사 접촉 (easy/normal) → 박병장 이스터에그
    · 타임 0초 → endGame('time')
→ 종료 오버레이 (overlayEnd)
  → 점수 + 최대콤보 + 피격 + 정확도 + 캐릭터별 기록 표시
  → 성공 시 HG 트랙 링크 노출
  → 신규 졸업 시 0.9초 후 졸업장 오버레이
  → 다시 플레이 / 난이도 다시 / 홈으로
```

### 8.2 점수 산출 공식 (L3922~L3931)

```js
let gain = 1;
if (combo >= 7) gain += 3;     // 7+ → 4점
else if (combo >= 5) gain += 2; // 5~6 → 3점
else if (combo >= 3) gain += 1; // 3~4 → 2점
// 그 외: 1점
score += gain;
```

A(매혹) 수집은 `gain * 2`. 변기는 gain을 2번 합산.

### 8.3 게임 오버 조건

- F 12×12 충돌 (L4117) → `gameoverReason = 'hit'`
- 수간호사 본체 14×14 충돌 (L3996) → 'hit'
- 이교수 본체 14×14 충돌 (L4025) → 'hit'
- 타이머 0초 도달 (L4148) → `gameoverReason = 'time'`

stunUntil / frozenUntil은 게임 오버를 일으키지 않음.

### 8.4 종료 메시지 분기 (L2354~L2381)

- hit + 미달: "수간호사에게 걸렸어요!"
- 성공 (score >= target): "노래를 무사히 만들었어요!" + HG 트랙 링크
  - 신기록이면: "음표 N개로 신곡 완성. 수간호사도 모르는 {name}의 첫 트랙이 태어났다."
  - 아니면: "N개. 좋은 후렴이지만 {name}는 더 높은 코드를 원한다."
- time + 미달:
  - score >= target - 1: "한 음만 더 있었으면…"
  - 그 외: "수간호사의 눈을 피해가며 모은 N점… (목표 X / 획득 Y)"

### 8.5 통계 (L2384~L2391)

- 최대 콤보 (maxCombo)
- F 피격 (hits) — F·수간호사·이교수 본체 충돌 합산, 청진기는 포함 X
- 정확도: `collected / (collected + hits) * 100%` (분모 0이면 100%)

---

## 9. 비주얼 디테일

### 9.1 색 팔레트 — 다크 / 라이트

#### 기본 (style.css L4~L23)
```css
다크:
  --bg: #0f0e15
  --bg-card: rgba(23, 21, 30, 0.82)
  --brand: #c4847a (코럴)
  --brand-light: #d4a49c
  --text: #eee
  --text-muted: #aaa

라이트 (html.light):
  --bg: #f5f4f8
  --bg-card: rgba(255, 255, 255, 0.82)
  --brand: #b07068
  --brand-light: #c48a82
  --text: #1a1a2e
  --text-muted: #555
```

#### 게임 전용 (game.css L7~L113) — 위 §3.1.3, §3.2.3, §3.3.3, §2.6에서 다 다룸.

### 9.2 캔버스 비주얼 효과 (game.css)

| 효과 | 클래스 | 지속 | 정의 |
|---|---|---|---|
| F 피격 셰이크 | `.is-shake` | 250ms | `translate(±2~4px)` 5단계 (L301~L324) |
| 게임오버 비네트 | `.is-gameover` | 600ms | inset box-shadow 빨강 0→80px→0 (L306~L315) |
| 박병장 폭탄 섬광 | `.is-bomb-flash` | 420ms | filter brightness 1→2.4 채도 1.3 (L597~L605) |

### 9.3 폰트

- 본문: `Inter, Noto Sans KR, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`
- 졸업장: `Cormorant Garamond, Georgia, "Times New Roman", serif` (영문) + `Noto Sans KR` (한글)
- HUD 숫자: `font-variant-numeric: tabular-nums`

### 9.4 HUD 레이아웃 (game.html L40~L64)

상단 가로 바 형태 5칸:
- Time (45)
- Score (0)
- Combo (0)
- Best (0)
- Skill (— with conic-gradient 쿨다운 링)

화면 비율: `.game-canvas-wrap` aspect-ratio 16/10.

### 9.5 효과음 (전부 WebAudio 사인파 — L382~L401 `playTone`)

| 이벤트 | 주파수 | 길이 |
|---|---|---|
| 음표 수집 | SCALE_FREQS[combo-1] | 0.09s |
| 변기 수집 | SCALE_FREQS[i] + 한음위 | 0.09s 2연타 |
| 스킬 발동 | 660 → 880 | 0.08s + 0.1s |
| F 피격 / 수간호사 본체 / 이교수 본체 | 110 → 82 | 0.25s + 0.35s |
| 청진기 명중 | 440 → 220 | 0.08s + 0.15s |
| 수간호사 투척 | 220 | 0.06s |
| 이교수 청진기 발사 | 180 | 0.07s |
| 비행기 엔진 | 120 → 90 | 0.4s + 0.5s |
| 폭탄 폭발 | 80 → 55 | 0.4s + 0.55s |
| 수간호사 복귀 | 220 | 0.08s |
| 게임 종료 (성공) | 988 | 0.22s |
| 게임 종료 (실패) | 165 | 0.3s |

볼륨: 0.0001 → 0.15 → 0.0001 exponential ramp (gain).

BGM 없음.

### 9.6 파티클 (L3523~L3556)

3×3 픽셀 사각형, 코럴색(brandHi). 수명 0.4~0.7초.
- 초기 속도: 60~150 px/s 랜덤 방향
- 초기 vy: -30 (상향)
- 중력: vy += 120 * dt
- 알파 = life / maxLife

### 9.7 음표 bob 애니메이션 (L4180)

`y_offset = sin((now/220) + bobSeed) * 1.2`

### 9.8 청진기 자체 회전 (L4235)

`rot = (now / 100) % (Math.PI * 2)` — 매 100ms마다 1라디안.

---

## 10. 저장소 / 영속 데이터

### 10.1 LocalStorage 키 (L68~L72)

| 키 | 용도 |
|---|---|
| `pixelNurseBest` | 구 스키마 (마이그레이션용 보존) |
| `pixelNurseBestByChar` | 신 스키마: `{version:2, records:{kim:{easy,normal,hard}, ...}}` |
| `pixelNurseChar` | 마지막 선택 캐릭터 ID (실제로는 시작 시 항상 'kim' 기본) |
| `pixelNurseGraduates` | `{version:1, graduated:{[id]: ISOString}}` |
| `theme` | 'light' or null(dark) |

### 10.2 점수 정규화 (L1072~L1077)

`normalizeBestScore(v) = clamp(Number(v) || 0, 0, 9999)`.

---

## 11. 입력 / 조작

### 11.1 키보드 매핑 (L2108~L2113 `KEY_MAP`)

```js
ArrowUp / KeyW    → up
ArrowDown / KeyS  → down
ArrowLeft / KeyA  → left
ArrowRight / KeyD → right
ShiftLeft / ShiftRight → 스킬 발동
```

### 11.2 키 처리 (L2138~L2156)

- 오버레이 열려 있으면 키 무시 + `state.keys[dir] = false`.
- 그 외엔 `state.keys[dir] = true/false` 토글.

### 11.3 이동 처리 (L3813~L3836)

- 4 키 OR 합산 → vx, vy.
- 둘 다 0이 아니면 0.7071 보정 (대각선).
- `pSpeed = currentPlayerSpeed()` × dt.
- X축 / Y축 순서대로 별도 충돌 검사 (벽 끼임 방지).
- stunned(F 잔상) 또는 frozen(청진기) 시 입력 차단.

### 11.4 모바일 입력 (L4360~L4541)

원본은 다음 2종 동시 지원:
- 캔버스 탭/드래그 → 상대방향 4방향 (DEAD_ZONE = 8px) (L4476~L4541)
- 하단 D-pad (`.game-keypad`) — 4방향 + 중앙 스킬 버튼 (L4390~L4454)

**iOS 포팅 시**: 위 두 가지 중 D-pad 만 사용 (사용자 요구). 캔버스 탭은 불필요.

---

## 12. iOS 포팅 시 주의점

### 12.1 좌표 / 비율

- 캔버스 640×400 → SpriteKit scene size로 그대로 사용 가능. 가로(landscape) 전용.
- 모든 스프라이트는 SCALE=2 (16×20 매트릭스 → 32×40 화면). 작은 픽셀 단위 fillRect → SpriteKit의 SKShapeNode 또는 SKSpriteNode + 텍스처 캐시.

### 12.2 추천 SpriteKit 구조

```
GameScene (640×400 anchor 0,0 bottomLeft 또는 topLeft 결정 필요)
├── BackgroundNode (단색 floor)
├── MapNode (벽 타일, 한 번만 그리고 캐시)
├── NotesLayer (8분 음표들)
├── ToiletsLayer (변기)
├── ObstaclesLayer (F/A)
├── StethoscopesLayer (회전 청진기)
├── NPCLayer (수간호사, 이교수, 석조무사)
├── PlayerNode
├── ParticlesLayer (SKEmitterNode 또는 SKShapeNode 풀)
├── AirplaneLayer (이스터에그)
└── HUD (별도 카메라 또는 overlay)
```

- 좌표계: 원본은 좌상단 (0,0) Y 아래로 증가. SpriteKit은 좌하단 (0,0) Y 위로 증가. **모든 y는 `400 - y`로 변환 필요**.
- `drawNurse`의 `oy = y - 24` 같은 오프셋도 좌표계 차이 반영해야 함.

### 12.3 픽셀 스프라이트 렌더 전략

원본은 매 프레임 fillRect 320회 호출. iOS에서는 너무 느릴 수 있다.

**권장**: 각 캐릭터 × 방향 × 프레임 × (throwArm) 조합을 한 번씩 그려 `SKTexture`로 캐싱.

- 김간호: 4방향 × 3프레임 = 12장
- 정/건/임/이: 동일 12장씩 × 4명 = 48장
- 수간호사: 4방향 × 3프레임 × 2(throwArm) × 2(hearted) = 48장
- 이교수: 4방향 × 3프레임 × 2(throwArm) = 24장
- 석조무사: 4방향 × 3프레임 = 12장
- 비행기: 1장
- 음표/F/A/변기/청진기: 각 1장 (청진기는 회전 위해 SKAction.rotate)

총 ~150장 텍스처. 한 번에 atlas로 묶어 GPU 메모리에 올리는 것이 베스트.

### 12.4 dpad 입력 (사용자 요구)

키보드 KEY_MAP 대신 4개 SKSpriteNode 버튼:
- 위/아래/왼쪽/오른쪽 + 스킬 1버튼
- `touchesBegan` / `touchesMoved` / `touchesEnded`로 누적 `state.keys[dir]` 갱신.
- 동시 2개 키 (대각선) 지원 필수.

### 12.5 텔레그래프·셰이크·섬광 효과

- CSS `is-shake` → `SKAction.sequence([SKAction.move..., ...])` 5단계 0.25s.
- CSS `is-gameover` 비네트 → SKShapeNode 풀스크린 빨간 inset glow 0.6s.
- CSS `is-bomb-flash` 브라이트 → `SKEffectNode` + CIFilter brightness ramp 또는 풀스크린 흰 SKSpriteNode 알파 펄스 420ms.

### 12.6 사운드

WebAudio 사인파 → SpriteKit에서는 `AVAudioEngine`으로 직접 사인파 생성 가능. 또는 30~50개 미리 .caf 사운드 파일로 굽기 (간단).

각 주파수·길이는 표준이라 미리 만들어 두기 권장:
- C4~A5 스케일 10음
- 110/82 (F 피격)
- 660/880 (스킬)
- 440/220 (청진기)
- 220 (수간호사 투척)
- 180 (이교수)
- 120/90 (비행기)
- 80/55 (폭발)
- 988/165 (게임 끝)

### 12.7 LocalStorage → UserDefaults

`pixelNurseBestByChar`, `pixelNurseGraduates`, `pixelNurseChar` 그대로 키 이름 유지 가능 (혹은 iOS 컨벤션에 맞춰 `com.hgfolio.pixelnurse.bestByChar` 등으로 변경).

### 12.8 컷씬 / 오버레이

원본은 HTML 오버레이. iOS에선 SwiftUI 오버레이 또는 SKNode 풀스크린 모달. **SwiftUI 오버레이가 더 자연스럽고 접근성 우수** (이미 메뉴 화면은 SwiftUI 사용 중이라 일관성).

### 12.9 reducedMotion

`UIAccessibility.isReduceMotionEnabled` 사용. 원본의 `reducedMotion` 분기를 그대로 적용:
- 걷기 보빙 비활성
- 텔레그래프 깜빡임 정적 표시
- 파티클 비활성
- 셰이크 비활성

### 12.10 가장 까다로운 부분 (TOP 5)

1. **수간호사 F 투척 + 텔레그래프 + 매혹 A 전환**: 상태 머신 3단계(대기/텔레그래프/투척) + 매 F마다 isImCharmed 체크.
2. **박병장 이스터에그**: 게임 루프 정지 + DOM 오버레이 + 폭탄 투하 예약 + F 전멸 + 수간호사 flee 5초.
3. **이교수 청진기**: 토스트 1초 → 정지 2초 직렬화 + 회전 투사체.
4. **5명 캐릭터 스프라이트 16×20 매트릭스 그대로 옮기기**: 한 줄도 빠뜨리지 않고 base 16×20 배열을 그대로 재현해야 픽셀 단위 일치. `nurseSprite` 함수 전체 (L462~L630) 통째로 Swift로 옮기는 게 가장 안전.
5. **lee의 워프 최적 타일 탐색**: 매 호출마다 19×30 타일 전체 스캔. iOS도 동일 알고리즘으로 충분히 빠름.

### 12.11 절대 변경 금지 (사용자 요구)

다음은 원본 그대로 1:1 재현:
- 맵 벽 배치 (3종 모두)
- 캐릭터 5명 스프라이트 매트릭스 (16×20)
- 빌런 3명 스프라이트 매트릭스
- 빌런 AI 패턴 (패트롤 경로, 속도, 투척 로직)
- 음표 모양, 크기, 색
- 난이도별 모든 숫자 (속도, TTL, 스폰 간격, F 상한, throwBurst, 목표 점수)
- 이스터에그 모든 타이밍
- 캐릭터 능력 수치 (스킬 쿨다운, 지속시간, 효과 범위)
- 점수 가산 공식 (3+/5+/7+ 보너스, A ×2, 변기 ×2)

---

## 13. 부록: 주요 함수 위치 인덱스

| 함수 | 라인 | 역할 |
|---|---|---|
| `buildMap(kind)` | 261 | 맵 2D 배열 생성 |
| `isWallAt(map, px, py, w, h)` | 315 | 픽셀 AABB → 타일 충돌 |
| `findEmptyTile(map, rng, avoid)` | 337 | 빈 타일 탐색 (안전지대) |
| `nurseSprite(dir, frame, charId)` | 462 | 플레이어 16×20 매트릭스 생성 |
| `getNursePalette(charId)` | 637 | 캐릭터별 색 팔레트 |
| `drawNurse` | 709 | 플레이어 렌더 |
| `drawNote` | 730 | 음표 12×12 |
| `drawToilet` | 756 | 변기 16×16 |
| `drawObstacle` | 783 | F/A 12×12 |
| `nurseChiefSprite` | 819 | 수간호사 매트릭스 |
| `getChiefPalette` | 897 | 수간호사 팔레트 |
| `drawNurseChief` | 924 | 수간호사 렌더 |
| `drawTelegraph` | 960 | 수간호사 ! |
| `state` 전역 | 979 | 모든 게임 상태 |
| `startGame` | 2161 | 게임 시작 |
| `endGame` | 2271 | 게임 종료 |
| `triggerCutscene` | 2417 | 컷씬 트리거 |
| `resumeFromCutscene` | 2469 | 컷씬 닫기 후 재개 |
| `spawnNote` | 2526 | 음표 스폰 |
| `spawnObstacle` | 2560 | F 초기 스폰 |
| `initNurseChief` | 2584 | 수간호사 초기화 |
| `updateNurseChief` | 2646 | 수간호사 매 프레임 |
| `spawnObstacleFromChief` | 2751 | F 투척 발사 |
| `professorSprite` | 2799 | 이교수 매트릭스 |
| `getProfessorPalette` | 2873 | 이교수 팔레트 |
| `drawProfessor` | 2898 | 이교수 렌더 |
| `drawStethoscope` | 2922 | 청진기 14×8 |
| `initProfessor` | 2983 | 이교수 초기화 |
| `updateProfessor` | 3026 | 이교수 매 프레임 |
| `spawnStethoscopeFromProfessor` | 3084 | 청진기 발사 |
| `stoneGuardSprite` | 3120 | 석조무사 매트릭스 |
| `drawStoneGuard` | 3197 | 석조무사 렌더 |
| `initStoneGuard` | 3221 | 석조무사 초기화 |
| `updateStoneGuard` | 3281 | 석조무사 매 프레임 |
| `triggerAirforceEasterEgg` | 3350 | 박병장 1단계 |
| `onAirforceContinue` | 3382 | 박병장 2단계 |
| `dropBomb` | 3419 | 박병장 3단계 |
| `startChiefFlee` | 3454 | 수간호사 도주 |
| `updateAirplane` | 3477 | 비행기 매 프레임 |
| `drawAirplane` | 3494 | 비행기 렌더 |
| `spawnParticles` | 3523 | 파티클 생성 |
| `updateParticles` | 3543 | 파티클 물리 |
| `tryActivateSkill` | 3567 | 스킬 발동 시도 |
| `executeSkill(id, now)` | 3604 | 캐릭터별 스킬 실행 |
| `update(dt, now)` | 3805 | 메인 update 루프 |
| `render(now)` | 4173 | 메인 render 루프 |
| `loop(ts)` | 4343 | rAF 진입점 |

---

문서 끝. 작성 시점: 2026-05-21.
