# QA 검수 보고서 — Phase 8-1 (픽셀 아트 인프라 + 5캐릭터 일괄 이식)

## 0. 사전 점검

| 항목 | 결과 |
|---|---|
| SPEC.md 존재 / 읽음 | OK (489줄) |
| SELF_CHECK.md 존재 / 읽음 | OK (399줄) |
| docs/swift-rules.md 읽음 | OK |
| 원본 단일 진실 원천 game.js L462-700 정독 | OK |
| Generator 산출물 git status | M 5 / 신규 3 / 회귀 0 영역 0줄 |

---

## 1. SPEC 기능 검증

| # | 기능 | 결과 | 비고 |
|---|---|---|---|
| 1 | PixelSprite 데이터 구조 + base + 방향/프레임 분기 | PASS | `Models/PixelSprite.swift` 273줄 |
| 2 | PixelPalette 공통 9키 + 캐릭터 5종 charMap | PASS | `Models/PixelPalette.swift` 82줄 |
| 3 | PixelSpriteRenderer (UIGraphicsImageRenderer + filteringMode .nearest) | PASS | `Nodes/PixelSpriteRenderer.swift` 45줄 |
| 4 | PlayerNode texture 모드 + apply/updatePixelDirection/tickWalkFrame | PASS | `Nodes/PlayerNode.swift` 183줄 |
| 5 | ColorTokens 픽셀 팔레트 27개 + UIColor(hex:) | PASS | `Config/ColorTokens.swift` L48-139 |
| 6 | GameConfig.pixelSpriteScale=2 + pixelWalkFrameInterval=0.18 | PASS | `Config/GameConfig.swift` L632-639 |
| 7 | GameScene.update 7줄 추가 (playing 가드 안쪽) | PASS | `GameScene.swift` L341-347 |
| 8 | pbxproj 3 신규 파일 등록 | PASS | git diff +12줄 |

---

## 2. 빌드 검증

- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- **결과: BUILD SUCCEEDED**
- 컴파일 에러: 0건
- 컴파일 경고: 0건 (`grep -E "warning:|error:"` 결과 — `AppIntents.framework dependency` 표준 metadata 안내 1건은 사용자 코드 무관)
- CodeSign: 성공
- Validate: 성공

---

## 3. 원본 game.js와의 byte-equal 정합성 (행 단위 직접 대조)

### 3-1. baseFrame — 정면 base (game.js L465-486)

20행 모두 byte-equal 확인:

| 행 | JS L465-486 | Swift PixelSprite.swift:41-62 |
|---|---|---|
| 1 | `'......HHHH......'` | `"......HHHH......"` ✓ |
| 5 | `'..HHSSSSSSSSHH..'` | `"..HHSSSSSSSSHH.."` ✓ |
| 6 | `'..SSEESSSSEESS..'` | `"..SSEESSSSEESS.."` ✓ |
| 8 | `'..RSSSSMMSSSSR..'` | `"..RSSSSMMSSSSR.."` ✓ |
| 13 | `'...WWWCCCCWWW...'` | `"...WWWCCCCWWW..."` ✓ |
| 18 | `'....BB....BB....'` | `"....BB....BB...."` ✓ |

### 3-2. 방향 분기 (game.js L488-511)

| 분기 | 확인 |
|---|---|
| `up` base[4..9] 모두 `..HHHHHHHHHHHH..` | PASS — Swift L71-76 일치 |
| `up` base[10] `...HHHHHHHHHH...` | PASS — Swift L77 일치 |
| `left` base[6] `..SSSSSSSSEESS..` | PASS — Swift L80 일치 |
| `right` base[8] `..RSSSSMMSSSSS..` | PASS — Swift L87 일치 |

### 3-3. 프레임 분기 (game.js L513-520)

| 프레임 | JS | Swift |
|---|---|---|
| step1 base[18] | `'....BB...BBB....'` | `"....BB...BBB...."` ✓ |
| step1 base[19] | `'....BBB...BB....'` | `"....BBB...BB...."` ✓ |
| step2 base[18] | `'....BBB...BB....'` | `"....BBB...BB...."` ✓ |
| step2 base[19] | `'....BB...BBB....'` | `"....BB...BBB...."` ✓ |

### 3-4. jung 오버레이 (game.js L526-551)

| 행 | JS | Swift PixelSprite.swift:131-153 |
|---|---|---|
| base[2] | `'....JJJJJJJJ....'` | `"....JJJJJJJJ...."` ✓ |
| base[5] | `'..jjSSSSSSSSjj..'` | `"..jjSSSSSSSSjj.."` ✓ |
| up base[10] | `'...JJJJJJJJJJ...'` | `"...JJJJJJJJJJ..."` ✓ |
| base[11] | `'...WWWWWWWWWW...'` | `"...WWWWWWWWWW..."` ✓ |
| 곡괭이 base[10] `+ 'KK'` | `substring(0, 14) + 'KK'` | `String(...prefix(14)) + "KK"` ✓ |
| 곡괭이 base[11] `+ 'kK'` | ditto | ditto ✓ |
| 곡괭이 base[12..15] `+ '.K'` | ditto | ditto ✓ |

길이 invariant: `..." (14) + "KK"` = 16 — 유지됨.

### 3-5. geon 오버레이 (game.js L552-581)

| 행 | JS | Swift PixelSprite.swift:159-189 |
|---|---|---|
| base[2] | `'.....GGGGGGGG...'` | `".....GGGGGGGG..."` ✓ |
| base[5] | `'..GGSSSSSSSSGG..'` | `"..GGSSSSSSSSGG.."` ✓ |
| down 안경 base[6] | `'..SSFFSSSSFFSS..'` | `"..SSFFSSSSFFSS.."` ✓ |
| down 렌즈 base[7] | `'..SSFfSSSSfFSS..'` | `"..SSFfSSSSfFSS.."` ✓ |
| left base[6] | `'..SSSSSSSSFFSS..'` | `"..SSSSSSSSFFSS.."` ✓ |
| right base[6] | `'..SSFFSSSSSSSS..'` | `"..SSFFSSSSSSSS.."` ✓ |
| 책 base[12] `+ 'OO'` | `substring(0, 14) + 'OO'` | `String(...prefix(14)) + "OO"` ✓ |
| 책 base[13] `+ 'Op'` | ditto | ditto ✓ |
| 책 base[14] `+ 'OO'` | ditto | ditto ✓ |

up 분기에서 geon은 안경/책 *없이* 머리만 — JS L559-577의 else 분기 안에 안경 처리가 있고, 책은 분기 *밖*에서 무조건 적용. Swift L186-189에서도 if-else 블록 *밖*에서 책을 무조건 적용 → JS 흐름과 정합.

### 3-6. im 오버레이 (game.js L582-601)

| 행 | JS | Swift PixelSprite.swift:196-214 |
|---|---|---|
| base[1] | `'....T......T....'` | `"....T......T...."` ✓ |
| base[2] | `'...TT.IIII.TT...'` | `"...TT.IIII.TT..."` ✓ |
| base[5] | `'..IISSSSSSSSII..'` | `"..IISSSSSSSSII.."` ✓ |
| base[11] chain replace | `'II..WWWWWWWW..II'.replace('II..','iI..').replace('..II','..Ii')` | `"II..WWWWWWWW..II".replacingOccurrences(of:"II..",with:"iI..").replacingOccurrences(of:"..II",with:"..Ii")` ✓ |
| base[12] | `'iI.WWWWCCWWWW.Ii'` | `"iI.WWWWCCWWWW.Ii"` ✓ |
| base[13] | `'iI.WWWCCCCWWW.Ii'` | `"iI.WWWCCCCWWW.Ii"` ✓ |
| base[14] | `'iI..WWWWWWWW..Ii'` | `"iI..WWWWWWWW..Ii"` ✓ |
| up base[10] | `'..IIIIIIIIIIII..'` | `"..IIIIIIIIIIII.."` ✓ (kim의 up base[10]=`...HHHHHHHHHH...`와 다른 *왼쪽 끝까지* 패턴 — JS와 정확 일치) |

체인 replace 결과 검산: `II..WWWWWWWW..II` → 첫 replace로 `iI..` 치환 → `iI..WWWWWWWW..II` → 두 번째 replace로 `..Ii` 치환 → `iI..WWWWWWWW..Ii` (16자). JS `String.prototype.replace`의 첫 매치만 치환하는 동작과 Swift `replacingOccurrences`의 전체 치환 동작 *결과상 동일* — 각 패턴이 문자열에 1번만 등장하므로 무관.

### 3-7. lee 오버레이 (game.js L602-627)

| 행 | JS | Swift PixelSprite.swift:221-242 |
|---|---|---|
| base[2] | `'.....QQQQQQQQ...'` | `".....QQQQQQQQ..."` ✓ |
| base[5] | `'..QQSSSSSSSSQQ..'` | `"..QQSSSSSSSSQQ.."` ✓ |
| up base[10] | `'...QQQQQQQQQQ...'` | `"...QQQQQQQQQQ..."` ✓ |
| overlayEdge `'qq'+row.substring(2,14)+'qq'` | JS substring(2,14) = index 2..13 = 12자 | Swift `chars[2..<14]` = 12자 ✓ → `"qq" + middle + "qq"` = 16자 ✓ |
| 강아지귀 `'...DD'+base[2].substring(5,11)+'DD...'` | substring(5,11) = 6자 | `chars[5..<11]` = 6자 ✓ → `"...DD" + middle + "DD..."` = 5+6+5=16자 ✓ |

`overlayEdge` Swift 구현 (PixelSprite.swift:248-253)과 `leeSubstring5to11` (L256-259) 모두 JS substring 의미와 *byte-equal*. 두 헬퍼가 16자 invariant를 정확히 보존.

### 3-8. palette hex (game.js L645-690)

`grep ganhoPixel` 결과 27개 색 토큰 모두 hex byte-equal:

| 키 | 원본 hex | Swift |
|---|---|---|
| S | `#fbe0d0` | L54 `"#fbe0d0"` ✓ |
| W | `#ffffff` | L56 ✓ |
| C | `#c4847a` | L58 ✓ |
| P | `#9ec9e8` | L60 ✓ |
| B | `#a85f56` | L62 ✓ |
| E | `#2a1f25` | L64 ✓ |
| L | `#ffffff` | L66 ✓ |
| R | `#f5a8a0` | L68 ✓ |
| M | `#c4847a` | L70 ✓ |
| H/b | `#3a2a20` / `#5a4230` | L74/76 ✓ |
| J/j | `#2a1a12` / `#180c08` | L80/82 ✓ |
| K/k | `#9aa0a8` / `#7a4f2a` | L84/86 ✓ |
| G/g | `#30221c` / `#1a0f0a` | L90/92 ✓ |
| F/f | `#1f1a1f` / `#e8f0f8` | L94/96 ✓ |
| O/p | `#8a5a32` / `#f6ebd9` | L98/100 ✓ |
| I/i | `#3a2618` / `#22150c` | L104/106 ✓ |
| T | `#ff9db0` | L108 ✓ |
| Q/q | `#5a3a22` / `#3a2414` | L112/114 ✓ |
| D | `#b07a58` | L116 ✓ |

총 **27개 토큰 100% byte-equal**.

---

## 4. 회귀 0 영역 검증

`git diff HEAD --` 결과:

| 영역 | 결과 |
|---|---|
| EnemyNode / StoneGuard / Projectile / Note / DPad / HUD | 0줄 |
| 자가 소멸 노드 11호 (Airplane/Airforce/Bomb/HitFlash/Sparkle/Countdown/ComboBreak/ComboPopup/Cutscene/Diploma/ScorePopup) | 0줄 |
| Character/Difficulty Card | 0줄 |
| Systems (ContactRouter / SpawnSystem / ScoreSystem / CameraShakeAction) | 0줄 |
| Scenes (TitleScene / ResultScene) / GameScene+Setup | 0줄 |
| Models (CharacterID / Difficulty / GameStats) | 0줄 |
| Protocols / Repositories 6종 / Managers 3종 | 0줄 |
| iOS / tvOS / macOS 진입점 | 0줄 |

위 18개 path 일괄 diff `wc -l` → **0**. SPEC 회귀 0 계약 완전 준수.

GameScene.swift diff은 SPEC §"GameScene update 1줄"이 명시한 7줄(주석 포함) 추가 — playing 가드 안쪽 L341-347. 그 외 변경 0.

---

## 5. 정적 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 2건 (지적사항 §7) |

### P0 — 치명적 이슈: 없음

- 강제 언래핑(`!`): 신규 4 파일 + 수정 3 파일 모두 0건 (단, `fatalError` 안의 `init(coder:)`는 SKSpriteNode 표준 패턴이라 제외)
- `Timer.` / `DispatchQueue.`: 0건
- 빌드 에러: 0건
- 크래시 위험 패턴: 없음 (옵셔널 dict lookup은 `??`/`guard let`로 모두 보호)
- 물리 충돌 델리게이트 내 노드 즉시 삭제: N/A (본 sprint 미접촉)

### P1 — 중요 이슈: 없음

- 매직 넘버: 없음 (16/20 그리드는 `spriteWidth`/`spriteHeight` private 상수로 분리, 0.18은 `pixelWalkFrameInterval`, 2배 스케일은 `pixelSpriteScale`)
- guard let / if let / ?? 옵셔널 처리: 준수 (`player.physicsBody?.velocity ?? .zero`, `palette[char]`의 `guard let color`)
- 단일 책임 원칙: 함수 평균 10~20줄, 헬퍼(`overlayEdge`/`leeSubstring5to11`)로 분리
- MARK 섹션 구분: 신규 4 파일 모두 `// MARK: - …` 적극 사용
- weak self: 신규 코드에 closure 캡처 없음 (UIGraphicsImageRenderer의 ctx 블록에 self 미사용)
- SpriteKit 패턴: didMove(to:) 미접촉, dt 기반 (`tickWalkFrame(deltaTime:)`), `filteringMode = .nearest` 명시

### P2 — 권장 사항

#### 1. GameScene.swift 파일 크기 (594줄)
- **위반 규칙**: spritekit-rules.md §11 — GameScene.swift 300줄 미만 유지 권고.
- **현재**: 594줄. *본 sprint와 무관* — Phase 6/7 누적 결과. 본 sprint는 7줄만 추가했음.
- **수정 제안**: 다음 sprint(Phase 8-2 등)에서 GameScene+Combat, GameScene+Cutscene 같은 extension 파일로 분리 권장. 본 sprint의 채점에는 *감점 반영하지 않음* — 회귀 0 영역의 누적 상태이며 본 sprint 책임 아님.

#### 2. `if direction == .up` vs switch 일관성
- **파일**: `Models/PixelSprite.swift:136, 164, 201, 226`
- **위반 규칙**: 의도된 스타일 — JS의 `if (dir === 'up')` 패턴 byte-equal 보존을 위한 선택. switch와 if의 혼용이 *어색하지 않은가* 검토했으나, JS와의 1:1 매핑성이 더 우선이라는 SPEC §주의사항 5와 정합.
- **수정 제안**: 변경 불필요. 현재 형태가 game.js와의 시각적 1:1 대응에 *더 안전*. P2 정보 표시 목적으로만 기록.

---

## 6. 채점

### 평가 기준 (가중 점수 4축)

| 영역 | 비중 | 점수 | 가중치 적용 |
|---|---|---|---|
| Swift 패턴 일관성 | 35% | 10/10 | 3.50 |
| 게임 로직 완성도 | 30% | 10/10 | 3.00 |
| 성능 & 안정성 | 20% | 10/10 | 2.00 |
| 기능 완성도 | 15% | 10/10 | 1.50 |
| **가중 점수** |  |  | **10.0/10** |

### 점수 근거

#### Swift 패턴 일관성: 10/10
- 강제 언래핑 0건, Timer/DispatchQueue 0건, 매직 넘버 0건
- guard let / ?? / if let 옵셔널 처리 일관
- MARK 섹션 적극 사용, 함수 단일 책임 원칙 준수
- 네이밍 lowerCamelCase + 한국어 주석 규칙 일관
- `UIColor(hex:)` 확장에 명백한 sentinel(magenta) fallback — Spring 비유까지 주석에 명시 (사용자 학습 컨텍스트 존중)

#### 게임 로직 완성도: 10/10
- physicsBody 크기 *그대로* 16×20 보존 — 게임 hitbox 회귀 0 (SPEC 계약 정확 이행)
- velocity / collisionBitMask / contactTestBitMask 변경 0
- 텍스처 갱신은 *변경 순간에만* — 정지 시 비용 0
- velocity 임계값 0.1 가드로 미세 잔존 속도의 텍스처 흔들림 방지
- `apply(_ characterID:)` 단일 진입점 패턴 보존

#### 성능 & 안정성: 10/10
- SKTexture는 ARC 자동 해제 — 메모리 누수 0
- `filteringMode = .nearest` 명시 — 픽셀 perfect 보존
- `updatePixelDirection` / `tickWalkFrame`은 매 프레임 호출되어도 *조건부* refreshTexture — 정지 시 CPU 0
- UIGraphicsImageRenderer는 iOS 표준 효율 API (UIGraphicsBeginImageContextWithOptions 대비 자동 컬러스페이스 관리)
- 빌드 경고 0건

#### 기능 완성도: 10/10
- SPEC 6개 기능 + GameScene 1줄 추가 + pbxproj 3 파일 등록 100% 완료
- game.js L462-627 **byte-equal** 검증 — base 20행 + 방향 16행 + 프레임 4행 + jung 12행 + geon 14행 + im 12행 + lee 12행 = **총 90행 모두 일치**
- 팔레트 hex **27개 모두 일치**
- 회귀 0 영역 18개 path 모두 0줄 diff

---

## 7. 통과 항목

- 빌드: BUILD SUCCEEDED, 경고 0
- 정적 분석: 강제 언래핑 0 / Timer 0 / DispatchQueue 0
- 게임 hitbox: physicsBody 크기 보존 (회귀 0)
- 회귀 0 영역: 18개 path 모두 git diff 0줄
- byte-equal 정합성: 90행 + 27 hex 모두 일치
- Swift 컨벤션: 네이밍 / 옵셔널 / MARK / 매직 넘버 / 단일 책임 모두 준수
- 사용자 학습 컨텍스트(Spring 비유) 주석에 반영됨

---

## 8. 최종 판정

# 합격 (10.0/10)

### 핵심 평가

원본 game.js L462-627의 픽셀 데이터 90행과 L645-690의 팔레트 27 hex를 **단 한 문자의 오차 없이** Swift로 byte-equal 이식. JavaScript의 `substring(start, end)` 의미와 Swift `Array.subscript(range)`의 인덱스 차이(JS는 end 미포함, Swift `..<`도 미포함)를 헬퍼(`overlayEdge`, `leeSubstring5to11`)로 byte-equal 보존. JS의 chain replace 패턴은 `replacingOccurrences` 체인으로 의미 보존. physicsBody / velocity / collisionBitMask / contactTestBitMask 미접촉으로 게임 로직 회귀 0. 회귀 0 영역 18개 path 모두 0줄 diff.

검수 중 *한 번 더 엄격하게 보았을 때*에도 P0/P1 등급 이슈 0건. P2 권장사항 2건은 모두 본 sprint와 무관(GameScene 누적 크기) 또는 의도된 선택(JS와의 1:1 시각 대응)이라 점수 감점 없음. 가중 점수 4축에서 모두 10점이 정당한 결과 — 본 sprint는 *픽셀 정합성*이라는 단일 목표를 측정 가능한 기준(byte-equal)으로 100% 달성.

### 후속 sprint 권고 (참고용, 본 합격 판정과 무관)

1. **Phase 8-2 (EnemyNode 픽셀화)**: 같은 PixelSpriteRenderer 인프라를 EnemyNode에도 적용. 본 sprint의 PixelSprite enum을 `static func enemyData(...)`로 확장하거나 별도 enum 분리.
2. **GameScene 분리**: 594줄 → 300줄 미만 권고. extension 파일(GameScene+Combat, GameScene+Lifecycle)로 분할.
3. **테스트 카탈로그**: TitleScene에서 5캐릭터 선택 → 인게임에서 4방향 D-Pad 입력 → 발 프레임 교차 시각 확인. 회귀 0 영역이라 시각 검사만 권고.

