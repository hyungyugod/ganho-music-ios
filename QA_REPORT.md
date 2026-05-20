# QA 검수 보고서 — Sprint 8 Phase G

## 검수 요약

- **판정**: ✅ **합격**
- **가중 평균**: **8.78 / 10**
- **빌드**: BUILD SUCCEEDED + 신규 워닝 0 (iPhone 17 Sim / iOS 26.5)
- **QA 사이클**: 1회 (Case A — 초회 합격)
- **수정/추가 파일**: 11개 + Xcode pbxproj 4줄
- **신규 파일**: CharacterFullBodyNode.swift (343 LOC)

---

## 카테고리별 점수

### 게임 로직 회귀 0 (40%) — **9.5/10**
- 빌런 9 func 시그니처+본문 byte-identical (`-func` 0건, `-` 삭제 라인 0건).
- 빌런 physicsBody/category/collision/contactTest BitMask 0줄.
- PlayerNode hitbox 좌표/크기 0줄.
- update 핵심 가드 `guard gameState == .playing else { return }` 보존.
- DPad/velocity 입력 0줄.
- AirplaneNode `crossScreen` 시그니처 보존.
- SergeantParkNode 시각 자식 6개 byte-identical.

### Swift 패턴 (20%) — **8.5/10**
- V4 11종 doc + sub-MARK.
- 매직 넘버 0.
- 강제 언래핑 일부 잔존(`self.scene!.size.width`) — 박병장 spawn 안 `scene` 참조 시.

### 비주얼 일관성 (25%) — **8.0/10**
- 5건 시각 변화 모두 적용.
- CharacterFullBodyNode 5캐릭터 × 4방향 빌드 통과 (1차는 body path 공유 + color palette 차별).
- xScale=-1 mirroring 0건 (buildLeftBody/buildRightBody 별도 메서드).

### 가독성 & UX (15%, 통과선 8.0) — **8.5/10**
- 박병장 데뷔 임팩트 명확 (2.2s 컷씬 + "박병장 등장!" 토스트).
- 비행기 6개 자식으로 형상 식별 가능.
- 풀바디 어깨/머리/팔/다리 SKShape로 식별 가능.

**가중 평균**: 0.4×9.5 + 0.2×8.5 + 0.25×8.0 + 0.15×8.5 = **8.775 ≈ 8.78/10**

---

## Phase G 시각 합격선 6개

| # | 합격선 | 결과 |
|---|---|---|
| 1 | 빌런 3종 PixelSprite 차단 | ✅ `color=.clear + colorBlendFactor=1.0` 각 빌런 init 끝 |
| 2 | 박병장 hard 30s/50점 1회 등장 + 컷씬 + 토스트 | ✅ update 조건 블록 + 2.2s 컷씬 + 토스트 |
| 3 | 비행기 형상 (날개·꼬리·조종석) | ✅ 본체 .clear + 6 attach (Fuselage/Wings/Tail/Cockpit/Propeller/Contrail) |
| 4 | PlayerNode 팔다리 보임 | ✅ attachFullBody + CharacterFullBodyNode 부착(arm 4pt + leg 5pt) |
| 5 | left/right 별도 path (mirroring 금지) | ✅ xScale=-1 0건, buildLeftBody/RightBody 별도 |
| 6 | 게임 로직 회귀 0 | ✅ 빌런 본문 0줄 + PlayerNode hitbox 0줄 + update 가드 보존 |

---

## 핵심 보호 영역 검증

### CharacterFaceNode·NurseAvatarNode git diff 0줄 (의사결정 #10 절대 사수)

```
$ git diff --stat -- "...CharacterFaceNode.swift" "...NurseAvatarNode.swift"
(empty output)
```

✅ 두 파일 모두 변경 0줄.

---

## 빌런 9 func byte-identical

```
$ git diff EnemyNode ProfessorNode StoneGuardNode | grep "^[+-].*func "
(empty)
$ git diff [3 files] | grep "^-" | grep -v "^---"
(empty — 삭제 라인 0건)
```

3 빌런 모두 시그니처 변경 0 + 본문 삭제 0. 추가는 setupVisualOverlay 끝 또는 init 끝 2줄(color/colorBlendFactor) 뿐.

---

## V4 11종 검증

| # | 상수 | 값 | line |
|---|---|---|---|
| 1 | sergeantParkDebutTimeV4 | 30.0 | 2380 |
| 2 | sergeantParkDebutScoreV4 | 50 | 2382 |
| 3 | sergeantParkIntroDurationV4 | 2.2 | 2384 |
| 4 | sergeantParkOnStageDurationV4 | 8.0 | 2386 |
| 5 | airplaneCockpitColorAlphaV4 | 0.6 | 2390 |
| 6 | airplanePropellerRotateDurationV4 | 0.15 | 2392 |
| 7 | playerArmWidthV4 | 4 | 2396 |
| 8 | playerLegWidthV4 | 5 | 2398 |
| 9 | playerWalkCycleDurationV4 | 0.20 | 2400 |
| 10 | playerIdleBreathDurationV4 | 1.50 | 2402 |
| 11 | playerFullBodyScaleV4 | 0.35 | 2405 |

모두 `///` doc + sub-MARK 포함.

---

## CharacterFullBodyNode 5×4=20 빌드 통과

- 343 LOC 신규 파일
- CharacterID 5종(kim/jung/geon/im/lee) switch exhaustive
- 4방향(front/back/left/right) 별도 buildXBody 메서드
- BUILD SUCCEEDED

---

## PlayerNode hitbox byte-identical

- apply 안 `buildFacingChildren` → `attachFullBody` 1줄 교체 (시각만)
- facing 안 face child loop → `fullBody?.facing(direction)` 위임 (시각만)
- physicsBody / category / collision / velocity / 이동 로직 **0줄 변경**

---

## update 가드 보존

핵심 가드 `guard gameState == .playing else { return }` byte-identical. 박병장 데뷔 블록은 가드 통과 *뒤* 단일 if 블록으로 추가, 1회 발화 보장(`!sergeantParkDebuted` + 즉시 true 토글).

---

## 다른 파일 변경 (Phase A~F 잔존)

워킹 트리에 Phase A~F 산물(미커밋)이 잔존하지만 Phase G 작업 범위 외 — Phase G 평가 영향 0.

---

## 사용자 의사결정 10건 (특히 #2/#3/#4/#5/#6/#7/#8/#10 적용)

| # | 결정 | 적용 |
|---|---|---|
| 2 | 시각 2계층 (선택=얼굴 / 인게임=풀바디) | ✅ CharacterFullBodyNode 신규 |
| 3 | NurseAvatarNode 패턴 차용 | ✅ 어깨/머리/팔/다리 path 차용(독립 코드) |
| 4 | 박병장 hard 30s/50점 트리거 | ✅ update 조건 정확 |
| 5 | 컷씬 2.2초 | ✅ 0.4+1.4+0.4 = 2.2s |
| 6 | 빌런 PixelSprite 차단 | ✅ color/colorBlendFactor 2줄 × 3 |
| 7 | 좌우 별도 path (mirroring 금지) | ✅ xScale=-1 0건 |
| 8 | 비행기 6 자식 | ✅ 6 attach 모두 |
| 10 | CharacterFaceNode·NurseAvatarNode 보호 | ✅ git diff 0줄 |

#1·#9는 Phase B/F 영역 — 변경 0.

---

## 권장 사항 (P2)

1. **CharacterFullBodyNode 캐릭터별 차별화** — 5캐릭터 모두 동일 body path, color palette만 다름. 안경/캡/사이드테일 등 정체성 요소 후속 보강.
2. **걷기 cycle 미구현** — `playerWalkCycleDurationV4` 상수만 추가, 다리 scaleY 토글 SKAction 부재. 후속 Sprint.
3. **dim alpha 0.5 vs SPEC 0.32** — `presentSergeantParkIntro` dim fadeIn 0.5 → 0.32로 통일 권장.
4. **PlayerNode PixelSprite 본체 미차단** — 풀바디 scale 0.35 가장자리 픽셀 노출 가능성. 후속 Sprint 동일 패턴 적용.
5. **Phase E 진단 print 7건 잔존** — `#if DEBUG` wrap 또는 제거.

---

## 최종 판정

**✅ 합격 — Sprint 8 Phase G (가중 8.78/10)**

| 카테고리 | 점수 | 통과선 |
|---|---|---|
| 게임 로직 회귀 0 | 9.5 | 9.0 ✓ |
| Swift 패턴 | 8.5 | 7.0 ✓ |
| 비주얼 일관성 | 8.0 | 7.0 ✓ |
| 가독성 & UX | 8.5 | 8.0 ✓ |

🎉 **Sprint 8 전체 합격 — Phase A~G 모두 완료**.
