# Xcode 임포트 가이드

방금 디스크에 만든 9개 디렉터리를 **Xcode 프로젝트에 그룹으로 등록**해야 컴파일 대상이 된다.
디스크에만 있고 Xcode가 인식하지 못하면 그 폴더의 `.swift` 파일은 빌드 시 무시된다.

---

## 1. 현재 상태

디스크에는 9개 디렉터리가 있다 (`GanhoMusic Shared/` 아래):
```
Scenes/  Nodes/  Systems/  Repositories/  Models/(DTO/)
Managers/  Config/  Errors/  Resources/
```

각 폴더에 `README.md` placeholder 1개씩만 들어있다 (컴파일 대상 아님).

Xcode 프로젝트(`GanhoMusic.xcodeproj`)는 **아직 모름**. 다음 단계로 등록해야 한다.

---

## 2. 등록 방법 (3가지 옵션)

### 옵션 A: 수동 그룹 추가 (가장 안전·전통적)

1. Xcode 열기 → 좌측 네비게이터에서 `GanhoMusic Shared` 그룹 우클릭
2. **"New Group from Template"** 또는 **"Add Files to 'GanhoMusic'..."** 선택
3. 파인더가 열리면 디스크의 `Scenes` 폴더 선택 → **Add**
4. 다이얼로그에서:
   - ✅ **"Create groups"** (Create folder references X)
   - ✅ Target: `GanhoMusic iOS` 체크
5. 같은 방식으로 8개 폴더 반복 (`Nodes/`, `Systems/`, ...)

**장점**: 명시적·예측 가능
**단점**: 9번 반복 노가다

### 옵션 B: 한 번에 드래그 (옵션 A 단축)

1. Finder에서 디스크의 `Scenes/`, `Nodes/`, ..., `Resources/` 9개 폴더를 동시 선택
2. Xcode 네비게이터의 `GanhoMusic Shared` 그룹으로 **드래그**
3. 다이얼로그:
   - ✅ "Copy items if needed" — **체크 해제** (이미 같은 위치에 있음)
   - ✅ "Create groups"
   - ✅ Target: `GanhoMusic iOS`
4. Add

**장점**: 한 번에 끝
**주의**: "Copy items if needed" 를 켜면 파일이 두 번 복사되어 깨짐 — 반드시 해제

### 옵션 C: Synchronized Folders (Xcode 16+, 신기능)

Xcode 26.x 사용 중이므로 가능. 디스크 폴더를 그대로 동기화 — 새 파일을 디스크에 만들면 자동 인식.

1. Xcode → File → Add Files → 폴더 선택
2. **"Folders" 옵션에서 "Create folder references"** 선택 (옵션 A·B와 반대)
3. 폴더가 파란색 그룹이 아닌 **회색 폴더** 아이콘으로 보이면 성공

**장점**: 디스크 = Xcode 동기화. 클로드코드가 새 파일 만들면 즉시 인식
**단점**: 일부 빌드 설정에서 예외 동작. 익숙해질 시간 필요

**추천**: 처음에는 **옵션 B** 로 시작. 익숙해지면 옵션 C로 전환.

---

## 3. README.md 처리

각 디렉터리의 `README.md` 는 컴파일 대상이 아니라 문서. Xcode에서 등록은 하되 **타겟 멤버십 체크 해제**:

1. README.md 클릭
2. 우측 File Inspector → "Target Membership"
3. `GanhoMusic iOS` 체크 해제

또는 그냥 README는 Xcode에 등록하지 않고 디스크에만 둠 (네비게이터에서 안 보이게).

---

## 4. 기존 파일 이동 (`GameScene.swift` → `Scenes/`)

이건 **빌드 깨질 위험** 있어 신중히:

1. Xcode 네비게이터에서 `GameScene.swift` 우클릭 → **"Show in Finder"** — 현재 위치 확인
2. Xcode 네비게이터에서 `GameScene.swift` 를 `Scenes/` 그룹 위로 **드래그**
   - 다이얼로그가 뜨면 "Move" 선택 (디스크에서도 이동)
3. 빌드(⌘R) 로 검증
4. **빌드 실패 시**:
   - `Info.plist` 의 storyboard 참조 확인
   - `GameScene(fileNamed:)` 호출 위치 확인 — 번들 경로는 평탄해서 보통 OK

`.sks` 파일과 `Assets.xcassets` 는 **Phase 4 이후 폴리싱 시점**에 옮기는 걸 권장. 지금 옮기면 SpriteKit 씬 파일 참조가 깨지기 쉬움.

---

## 5. 검증 체크리스트

- [ ] 9개 그룹이 `GanhoMusic Shared` 아래에 보인다
- [ ] 각 그룹의 README.md가 보이거나(타겟 해제) 안 보임(미등록)
- [ ] ⌘B 빌드 성공
- [ ] ⌘R 시뮬레이터 실행 후 기존 Hello World 화면 정상 동작
- [ ] 콘솔에 "Failed to load GameScene.sks" 같은 에러 없음

---

## 6. 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| 빌드 시 "Cannot find type 'GameConfig'" | 그룹은 등록했지만 타겟 멤버십 X | 파일 클릭 → File Inspector → Target Membership 체크 |
| "Build input file cannot be found" | 디스크 경로와 .pbxproj 경로 불일치 | 파일 우클릭 → Delete → "Remove Reference" → 다시 Add |
| README.md가 빌드 결과에 포함됨 | Target Membership 켜져있음 | 체크 해제 |
| Synchronized 폴더에서 새 파일 안 보임 | Xcode 캐시 | Product → Clean Build Folder |

---

## 7. Phase 1 시작 직전 마지막 점검

- [ ] 디렉터리 9개가 Xcode 네비게이터에 보임
- [ ] `GameViewController.swift` 빌드 정상 (이전 단계에서 강제 언래핑 제거 완료)
- [ ] `Info.plist` Landscape 설정 완료
- [ ] 시뮬레이터에서 기존 Hello World 정상 동작
- [ ] git commit 으로 현재 상태 스냅샷 (Phase 1 시작 직전 체크포인트)
