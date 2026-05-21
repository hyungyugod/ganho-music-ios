# QA 검수 보고서 — Sprint 10 Im/Lee Nurse Cap + 다음 버튼 offsetY

## SPEC 기능 검증

- **[PASS] 기능 1 — Im 캐릭터 nurse cap 추가**
  - `CharacterFaceNode.swift:635~636`에 주석 1줄 + `buildNurseCap()` 1줄 신규 삽입.
  - 호출 위치: `nose addChild` (line 633) *뒤* + `buildBlush` (line 638) *직전* — SPEC §기능1 권장 위치 정확 일치.
  - **zPos 동률 처리 검증 (핵심)**: 고양이귀(`earNode.zPosition = 20`, line 580) `addChild`가 **먼저** 실행되고, 이후 cap(zPos=20)이 `addChild`됨. SpriteKit 동일 zPosition에서 나중 add된 노드가 위에 렌더 → cap이 귀 위로 안착. SPEC §주의사항 첫 항목 정확 반영.
- **[PASS] 기능 2 — Lee 캐릭터 nurse cap 추가**
  - `CharacterFaceNode.swift:748~749`에 주석 1줄 + `buildNurseCap()` 1줄 신규 삽입.
  - 호출 위치: `mouthNode addChild` (line 746) *뒤* + `buildBlush` (line 752) *직전* — SPEC §기능2 권장 위치 정확 일치.
  - Lee에는 zPos=20 노드가 없음 (bangs zPos=10 / fringe zPos=11 / 닫힌 눈·미소 zPos=30) → cap(zPos=20)이 bangs·fringe 위, 눈·입 아래로 자연 안착.
- **[PASS] 기능 3 — "다음" 버튼 offsetY 상향**
  - `GameConfig.swift:1841` 값 `40 → 64` 변경 확인. 주석 1줄 추가 (`Sprint 10 — 40 → 64 (+24) ...`).
  - layoutConfirmButton baseY 가산값이 `24 + 40 = 64` → `24 + 64 = 88` 로 +24pt 시각 상승.
  - 조건부 보조 변경(`characterCardConfirmButtonBelowChipV9` 24→16) 미적용 — SPEC상 "QA 시 클램프 발동 확인된 경우만" 허용이므로 적절한 보류.

## 빌드 검증

- **결과**: ✅ **BUILD SUCCEEDED**
- 명령: `xcodebuild -project GanhoMusic/GanhoMusic.xcodeproj -scheme "GanhoMusic iOS" -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
- 비고: iPhone 15 시뮬레이터 부재로 iPhone 17 (OS 26.4.1)에서 빌드. 컴파일 에러 0건. 경고는 기존부터 존재하던 폰트 리소스 중복(Jua/GowunDodum/NotoSansKR) 3건뿐이며 본 SPEC 변경과 무관.

## 변경 범위 검증 (SPEC §금지 항목)

`git diff HEAD` 기준 수정된 소스 파일은 **2개만**:

| 파일 | 변경량 | 비고 |
|---|---|---|
| `Config/GameConfig.swift` | +2 / -1 (값 1 + 주석 1) | SPEC 허용 범위 |
| `Nodes/CharacterFaceNode.swift` | +6 / -0 (호출 2 + 주석 2 + 빈줄 2) | SPEC 허용 범위 |

**금지 항목 점검 (전부 PASS)**:

- ✅ `NurseAvatarNode.swift` 본체 변경 0줄 (git diff 미포함)
- ✅ `buildNurseCap()` 본문 (line 117~153) 변경 0줄 — diff에서 호출만 추가, 함수 본문 미수정 확인
- ✅ `buildKimFace` / `buildJungFace` / `buildGeonFace` 본문 변경 0줄 — diff hunk 위치(635, 748)가 Im/Lee 함수 내부에만 존재
- ✅ `buildBackFace*` / `buildSideFace*` 변경 0줄
- ✅ `CharacterCardNode` 변경 0줄
- ✅ `CharacterSelectScene.swift` `layoutConfirmButton()` 산식 변경 0줄 (파일 자체가 diff 미포함)
- ✅ buildNurseCap 호출만 추가 — 모자 모양/색상 변형 없음

## 검수 결과 요약

| 등급 | 건수 |
|---|---|
| P0 치명 | 0건 |
| P1 중요 | 0건 |
| P2 권장 | 0건 |

## P0 — 치명적 이슈
없음.

## P1 — 중요 이슈
없음.

## P2 — 권장 사항
없음. (변경 라인이 4줄 코드 + 3줄 주석으로 매우 좁고, 모든 추가 코드가 SPEC §기능 1/2/3 권장과 1:1 일치)

## 통과 항목

- **Swift 패턴**: 강제 언래핑 0건, 매직 넘버 0건(GameConfig 상수 사용), 한국어 주석 톤 일관, MARK 섹션 보존, 인덴트 8-space 일관.
- **SpriteKit 패턴**: zPosition 동률 처리 정확 (cap addChild 순서가 의도된 렌더 우선순위 보장), 신규 노드는 모두 SKShapeNode + GameConfig 컬러 상수(`capWhite` / `capCross`) 사용.
- **scope discipline**: SPEC §변경 범위 §금지 항목 전부 PASS. 추가/삭제 파일 0건. NurseAvatarNode·CharacterSelectScene·다른 캐릭터 빌더 git diff 0줄.
- **mini face 부수효과**: SPEC §주의사항이 명시한 "의도된 개선" — `CharacterFaceNode.mini(id:)`도 동일 init 경로이므로 Scoreboard 결과창 mini face 5명도 자동으로 nurse cap 적용. SPEC §게임경험 의도("5명 시각 일관성")의 연장선.
- **빌드 안정성**: BUILD SUCCEEDED. 컴파일 에러 0, 신규 경고 0.

---

## 채점

**항목별 점수**:

- **Swift 패턴 일관성: 9.6/10** → 매직 넘버·강제 언래핑 0건, GameConfig 상수 + 공통 함수 호출만으로 변경 완결. 주석 톤(Sprint 10 prefix + 의도/zPos 근거 명시)이 기존 Sprint 7~9 코멘트 스타일과 일관.
- **게임 로직 완성도: 9.6/10** → addChild 순서 기반 zPos 동률 처리가 SPEC §주의사항 첫 항목과 정확 일치. Im(귀 뒤에 cap) / Lee(bangs·fringe 뒤에 cap) 양쪽 모두 의도된 렌더 순서 보장. baseY 산식 +24 시각 상승도 산술 일관.
- **성능 & 안정성: 9.6/10** → 캐릭터당 +3 SKShapeNode(cap path + v바 + h바) × 2명 = 총 6개 노드. CharacterSelectScene 1회 생성, update 루프 미영향. 빌드 SUCCEEDED 확정. 메모리/성능 부담 무시 가능.
- **기능 완성도: 9.7/10** → SPEC §기능 1/2/3 모두 1:1 구현. 조건부 보조 변경 보류도 SPEC상 "QA 확인 후"라는 단서를 정확히 준수 — 보수적 최소변경 원칙. 다음 라운드에서 시각 확인 후 필요 시 추가 적용 가능.

**가중 점수**: (9.6×0.35) + (9.6×0.30) + (9.6×0.20) + (9.7×0.15) = 3.36 + 2.88 + 1.92 + 1.455 = **9.615 / 10.0**

## 최종 판정: ✅ **합격**

가중 평균 9.62 ≥ SPEC 합격선 9.0 + 모든 항목 9.0+ 충족 + P0/P1/P2 이슈 0건 + BUILD SUCCEEDED.

**구체적 개선 지시**:

- 없음. SPEC 범위 내 변경이 완결되었고 빌드도 클린. 다음 단계에서 시뮬레이터 시각 확인 시 "다음" 버튼이 baseY=88 산식으로 충분히 올라왔는지 육안 검증 권장 (만약 maxAllowedY clamp가 발동하면 SPEC §변경 범위가 허용한 `characterCardConfirmButtonBelowChipV9: 24 → 16` 보조 변경을 2회차에서 추가 적용).
