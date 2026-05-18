# 자체 점검 — Phase 8-2 수간호사 픽셀 아트 이식

## 변경된 파일 (git diff --name-only)
```
GanhoMusic/GanhoMusic Shared/Config/ColorTokens.swift
GanhoMusic/GanhoMusic Shared/Models/PixelPalette.swift
GanhoMusic/GanhoMusic Shared/Models/PixelSprite.swift
GanhoMusic/GanhoMusic Shared/Nodes/EnemyNode.swift
SPEC.md
```
정확히 SPEC 허용 범위 4개 Swift 파일만 수정. 신규 파일 0개. pbxproj 변경 0건.

## SPEC 기능 체크

- [x] **기능 1 PixelSprite.nurseChiefData** — `extension PixelSprite` (PixelSprite.swift L276-352)에 정적 메서드 추가. base 20행 + up/left/right 분기 + step1/step2 프레임 분기 모두 game.js와 byte-equal.
- [x] **기능 2 PixelPalette.chiefPalette** — `extension PixelPalette` (PixelPalette.swift L85-106) 14키 dict. game.js L905-919 chiefPaletteCache 1:1 (의미상 유니크 14키, 'P'는 'U'와 동일 hex라 통일).
- [x] **기능 3 ColorTokens 14색** — `// MARK: - Chief Palette (Phase 8-2)` 섹션 (ColorTokens.swift L118-150). 14개 색 상수 (Skin/Wrinkle/Hair/HairShadow/Cap/CapShadow/Cross/Glass/GlassLens/Uniform/UniformShadow/Accent/Shoes/Mouth).
- [x] **기능 4 EnemyNode 픽셀 모드** — SKSpriteNode init이 `texture:` 모드 (EnemyNode.swift L42-78). pixelDirection / pixelFrame / frameAccumulator 인스턴스 프로퍼티 (L32-39). updatePixelDirection / tickWalkFrame / refreshTexture private 메서드 (L150-200). physicsBody 카테고리/충돌/contact 정책 *완전 보존*.
- [x] **기능 5 GameScene update 호출** — PlayerNode 패턴 답습 *변형*: EnemyNode가 자기 `update(deltaTime:targetPosition:speedT:)` 안에서 갱신 호출 (L145-147). 따라서 **GameScene 변경 0** — SPEC 주의사항 6의 권장 방식.

## 라인 매핑 (game.js ↔ Swift)

| game.js | Swift |
|---|---|
| L820-841 base 20행 | PixelSprite.swift L286-307 |
| L844-852 up 7행 | PixelSprite.swift L313-319 |
| L853-858 left 5행 | PixelSprite.swift L322-326 |
| L859-864 right 5행 | PixelSprite.swift L329-333 |
| L869-870 frame 1 (step1) 2행 | PixelSprite.swift L341-342 |
| L872-873 frame 2 (step2) 2행 | PixelSprite.swift L344-345 |
| L905-919 palette 14색 | ColorTokens.swift L123-150 |

## byte-equal 확인 (일부 행 인용)

### base 20행
```
JS L820 [00] '................'   Swift L286 "................"
JS L823 [03] '..KkkkkkkkkkkK..'   Swift L289 "..KkkkkkkkkkkK.."
JS L827 [07] '..hSGgSSSSgGSh..'   Swift L293 "..hSGgSSSSgGSh.."
JS L832 [12] '..UUUUVCCVUUUU..'   Swift L298 "..UUUUVCCVUUUU.."
JS L840 [19] '....BB....BB....'   Swift L306 "....BB....BB...."
```
20행 모두 일치 (Python 추출 + 시각 대조).

### 방향 분기 17행
```
JS L846 up base[5]    '..HhHHHHHHHHhH..'   Swift L314 "..HhHHHHHHHHhH.."
JS L854 left base[6]  '..hSSSSSSSGGSh..'   Swift L322 "..hSSSSSSSGGSh.."
JS L860 right base[6] '..hSGGSSSSSSSh..'   Swift L329 "..hSGGSSSSSSSh.."
JS L858 left base[10] '..hhSSNNNNSSHh..'   Swift L326 "..hhSSNNNNSSHh.."
```
17행 모두 일치 (up 7 + left 5 + right 5).

### 프레임 분기 4행
```
JS L869 frame 1 base[18] '....BB...BBB....'   Swift L341 "....BB...BBB...."
JS L870 frame 1 base[19] '....BBB...BB....'   Swift L342 "....BBB...BB...."
JS L872 frame 2 base[18] '....BBB...BB....'   Swift L344 "....BBB...BB...."
JS L873 frame 2 base[19] '....BB...BBB....'   Swift L345 "....BB...BBB...."
```
4행 모두 일치.

### 팔레트 14색 (15엔트리 중 'P'='U' 통일 후)
```
'S' #f5d5c0   ganhoPixelChiefSkin          #f5d5c0
'N' #c08878   ganhoPixelChiefWrinkle       #c08878
'H' #e8e4e8   ganhoPixelChiefHair          #e8e4e8
'h' #c8c4cc   ganhoPixelChiefHairShadow    #c8c4cc
'K' #ffffff   ganhoPixelChiefCap           #ffffff
'k' #e6dde6   ganhoPixelChiefCapShadow     #e6dde6
'X' #ff7b7b   ganhoPixelChiefCross         #ff7b7b
'G' #1f1a1f   ganhoPixelChiefGlass         #1f1a1f
'g' #e8c8b8   ganhoPixelChiefGlassLens     #e8c8b8
'U' #f4f0ee   ganhoPixelChiefUniform       #f4f0ee
'V' #d8d2d0   ganhoPixelChiefUniformShadow #d8d2d0
'C' #ff7b7b   ganhoPixelChiefAccent        #ff7b7b
'B' #1a1214   ganhoPixelChiefShoes         #1a1214
'M' #6b3a3a   ganhoPixelChiefMouth         #6b3a3a
```
14색 모두 hex 일치. ('P'=#f4f0ee는 'U'와 동일하므로 단일 Uniform 토큰. sprite 데이터에서 'P' 키 등장 없음.)

## 회귀 0 영역 grep 결과

`chief` 토큰을 참조하는 파일 검색:
```bash
grep -rn "nurseChiefData\|chiefPalette\|ganhoPixelChief" "GanhoMusic/GanhoMusic Shared/"
```
결과: 오직 ColorTokens.swift / PixelPalette.swift / PixelSprite.swift / EnemyNode.swift 4개 파일만 일치. PixelSpriteRenderer.swift, PlayerNode.swift, StoneGuardNode.swift, ProjectileNode.swift, NoteNode.swift, DPadNode.swift, HUDNode.swift, GameScene.swift, GameScene+Setup.swift, TitleScene.swift, ResultScene.swift 미접촉. Managers/Repositories/Systems/Protocols/Models(GameStats/CharacterID/Difficulty)/Config(GameConfig/PhysicsCategory/GameState) 미접촉. iOS/tvOS/macOS 진입점 미접촉.

**PixelSpriteRenderer.swift 절대 미접촉** — Phase 8-1 인프라 그대로 재사용.

## Swift 패턴 준수

- 강제 언래핑 미사용: **준수** (`!` 신규 도입 0건. EnemyNode `physicsBody?.velocity`는 옵셔널 체이닝, 기존)
- guard let 옵셔널 처리: **준수** (Renderer의 `guard let color = palette[char] else { continue }` 기존 그대로)
- MARK 섹션 구분: **준수** (`// MARK: - Chief Palette (Phase 8-2)` / `// MARK: - Pixel Sprite (Phase 8-2)` / `// MARK: - Nurse Chief Sprite (Phase 8-2)`)
- GameConfig 상수 사용: **준수** (`pixelSpriteScale` / `pixelWalkFrameInterval` / `enemyWidth` / `enemyHeight` 재사용, 매직 넘버 0)
- weak self 캡처: **준수** (startFleeing의 SKAction 클로저 2개 모두 `[weak self]` — 기존 패턴 보존)

## SpriteKit 패턴 준수

- didMove(to:)에서 초기화: **해당 없음** (Node init에서 텍스처 1회 생성)
- dt 기반 이동: **준수** (tickWalkFrame이 frameAccumulator에 deltaTime 누적, GameConfig.pixelWalkFrameInterval 임계 시 토글)
- SKAction 스폰 패턴: **해당 없음** (스폰/액션 신규 0건. startFleeing의 sequence는 기존)
- 충돌 후 노드 즉시 삭제 없음: **준수** (충돌 로직 미접촉)
- HUD 노드 분리: **해당 없음** (HUD 미접촉)
- Timer 미사용: **준수** (Timer 신규 0건)
- 매 프레임 addChild 없음: **준수** (refreshTexture는 texture 프로퍼티만 갱신, 노드 추가 없음. 변경 없는 프레임에는 비용 0 — pixelDirection / pixelFrame 동등성 체크 후 분기)

## 빌드 상태

```
xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj \
           -target "GanhoMusic iOS" \
           -sdk iphonesimulator \
           EXCLUDED_SOURCE_FILE_NAMES="Main.storyboard" \
           clean build
```
- **결과**: `** BUILD SUCCEEDED **`
- **경고**: 0개 (`grep -E "warning:|error:"`로 검사 — appintentsmetadataprocessor 시스템 정보만 출력, 컴파일 경고 0)
- **에러**: 0개

## 정적 검사

- `git diff main --stat`에서 본 sprint 변경 4개 파일이 명확히 표면화
- pbxproj 미변경 (`git diff main GanhoMusic/GanhoMusic.xcodeproj/project.pbxproj`는 *기존 7개 커밋*의 누적분일 뿐, 본 sprint 변경 0)
- 신규 파일 0개 (`git status` 결과의 modified 4개만, untracked는 build/ 디렉토리뿐)

## 범위 외 미구현 (의도된)

- **throwArm 모션** — game.js L877-889 F 투척 팔 올림. SPEC 금지 §1, 다음 sprint.
- **StoneGuard 픽셀** — SPEC 금지 §2.
- **음표 / F / 카드 아바타 픽셀** — SPEC 금지 §3.

## 추가 정리 (필수 연동 변경)

PixelPalette.swift / ColorTokens.swift 주석에 "13키"라고 잘못 기재된 부분을 "14키"로 통일 (사용자 명세 부합). 코드 동작 변경 0, 주석 문구만 조정.
