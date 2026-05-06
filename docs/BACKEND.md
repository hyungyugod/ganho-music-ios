# 백엔드 설계서 — GanhoMusic iOS
**완전 무료 (Apple Developer $99 제외) 클라우드 아키텍처**

---

## 1. 기술 스택 결정

| 역할 | 선택 | 이유 |
|---|---|---|
| **백엔드 + DB** | **Supabase** | PostgreSQL + Auth + API 통합. 무료 플랜 충분. |
| **인증** | **Apple Sign In** | App Store 필수 요구사항 + Supabase 기본 지원 |
| **iOS 클라이언트** | **supabase-swift** | 공식 Swift SDK. Codable 기반. |
| **서버 코드** | **없음** | Supabase가 REST API 자동 생성 → 별도 서버 불필요 |

### 왜 Supabase인가
- 컴퓨터 꺼놔도 Supabase 클라우드에서 24시간 돌아감
- PostgreSQL 기반 → SQL로 리더보드 쿼리 쉬움
- Apple Sign In 공식 지원
- 무료 플랜에서 MAU 50,000명까지 인증 무료
- 대시보드에서 DB 데이터 실시간 확인 가능

### ⚠️ 무료 플랜 주의사항
| 제한 | 내용 | 대응 |
|---|---|---|
| DB 용량 | 500MB | 게임 기록만 저장하면 수년치도 OK |
| **자동 슬립** | **1주일 비활성 시 프로젝트 자동 중단** | 첫 요청 시 5~10초 재시작 지연 발생. 인디 앱은 허용 범위. |
| Bandwidth | 5GB/월 | 텍스트 데이터만 저장하면 무관 |
| 프로젝트 수 | 2개 | 충분 |

> 나중에 유저가 늘면 $25/월 Pro 플랜으로 업그레이드. 그 전까지 완전 무료.

---

## 2. 아키텍처 흐름

```
[iPhone 앱]
     │
     │  HTTPS (supabase-swift SDK)
     ▼
[Supabase Cloud]
  ├─ Auth        ← Apple Sign In JWT 검증
  ├─ PostgreSQL  ← 유저 프로필, 점수 기록, 리더보드
  └─ Row Level Security (RLS) ← 내 데이터만 읽기/쓰기
```

---

## 3. 인증 흐름 (Apple Sign In)

```
1. 유저가 앱에서 "Apple로 로그인" 탭
2. iOS ASAuthorizationAppleIDProvider 호출
3. Apple이 Identity Token (JWT) 반환
4. supabase.auth.signInWithIdToken(provider: .apple, idToken: ...) 호출
5. Supabase가 Apple JWT 검증 → 자체 세션 토큰 발급
6. 이후 모든 API 요청에 세션 토큰 자동 첨부
```

### App Store 규정
> **Apple 정책**: 앱에 소셜 로그인(Google, Kakao 등)이 있으면 반드시 Apple Sign In도 제공해야 함.
> 이 게임은 Apple Sign In만 제공하므로 규정 완전 충족.

### 익명 플레이 지원
- 로그인 없이 게임 가능 → 기록은 UserDefaults에만 저장
- 로그인 후 → 서버 동기화 + 글로벌 리더보드 참여
- 기존 로컬 기록 → 로그인 시 서버로 마이그레이션

---

## 4. 데이터베이스 스키마

### 테이블 1: `profiles`
```sql
CREATE TABLE profiles (
  id          UUID REFERENCES auth.users PRIMARY KEY,
  username    TEXT,                          -- 닉네임 (선택)
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 테이블 2: `scores`
```sql
CREATE TABLE scores (
  id            BIGSERIAL PRIMARY KEY,
  user_id       UUID REFERENCES profiles(id) ON DELETE CASCADE,
  character_id  TEXT NOT NULL,              -- 'kim' | 'jung' | 'geon' | 'im' | 'lee'
  difficulty    TEXT NOT NULL,              -- 'easy' | 'normal' | 'hard'
  score         INT NOT NULL,
  max_combo     INT DEFAULT 0,
  notes_collected INT DEFAULT 0,
  game_duration FLOAT DEFAULT 45,          -- 실제 플레이 시간 (게임오버 시 단축)
  graduated     BOOLEAN DEFAULT FALSE,     -- 목표 점수 달성 여부
  played_at     TIMESTAMPTZ DEFAULT NOW()
);
```

### 뷰: `leaderboard` (리더보드)
```sql
-- 캐릭터×난이도별 최고 기록 TOP 100
CREATE VIEW leaderboard AS
SELECT
  p.username,
  s.character_id,
  s.difficulty,
  MAX(s.score) AS best_score,
  RANK() OVER (
    PARTITION BY s.character_id, s.difficulty
    ORDER BY MAX(s.score) DESC
  ) AS rank
FROM scores s
JOIN profiles p ON s.user_id = p.id
GROUP BY p.username, s.character_id, s.difficulty;
```

### Row Level Security (RLS)
```sql
-- scores: 본인 기록만 INSERT/SELECT 가능
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "본인 기록만 삽입"
  ON scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "본인 기록 조회"
  ON scores FOR SELECT
  USING (auth.uid() = user_id);

-- 리더보드는 전체 공개
CREATE POLICY "리더보드 전체 공개"
  ON scores FOR SELECT
  USING (true);  -- leaderboard 뷰는 별도 정책
```

---

## 5. iOS 클라이언트 연동

### Supabase Swift SDK 설치
```
Xcode → File → Add Package Dependencies
URL: https://github.com/supabase/supabase-swift
```

### 초기화 (`AppDelegate.swift`)
```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
    supabaseKey: "YOUR_ANON_KEY"
)
```

### Apple Sign In 구현
```swift
import AuthenticationServices
import Supabase

func signInWithApple() async throws {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.fullName, .email]

    // Identity Token 받기
    let result = try await withCheckedThrowingContinuation { ... }

    // Supabase에 전달
    try await supabase.auth.signInWithIdToken(
        credentials: .init(provider: .apple, idToken: result.identityToken)
    )
}
```

### 점수 저장
```swift
struct ScoreRecord: Encodable {
    let userId: UUID
    let characterId: String
    let difficulty: String
    let score: Int
    let maxCombo: Int
    let graduated: Bool
}

func saveScore(_ record: ScoreRecord) async throws {
    try await supabase
        .from("scores")
        .insert(record)
        .execute()
}
```

### 내 최고 기록 조회
```swift
func fetchMyBest(characterId: String, difficulty: String) async throws -> Int {
    let response = try await supabase
        .from("scores")
        .select("score")
        .eq("character_id", value: characterId)
        .eq("difficulty", value: difficulty)
        .order("score", ascending: false)
        .limit(1)
        .execute()
    // 파싱 후 반환
}
```

### 리더보드 조회
```swift
func fetchLeaderboard(characterId: String, difficulty: String) async throws -> [LeaderboardEntry] {
    try await supabase
        .from("leaderboard")
        .select()
        .eq("character_id", value: characterId)
        .eq("difficulty", value: difficulty)
        .order("rank", ascending: true)
        .limit(100)
        .execute()
        .value
}
```

---

## 6. 앱 기능 추가 (백엔드 연동)

### 종료 화면에 추가할 기능
- ✅ 서버 점수 저장 (게임 끝날 때마다)
- ✅ 글로벌 순위 표시 ("전체 {rank}위")
- ✅ 리더보드 탭 (캐릭터×난이도별 TOP 10)

### 새 화면: 프로필
- Apple 계정 연동 상태
- 총 플레이 횟수, 총 수집 음표, 누적 플레이 시간
- 졸업장 보유 캐릭터 목록

---

## 7. 구현 단계 (Phase 7로 추가)

### Phase 7 — 백엔드 연동

**7-1. Supabase 프로젝트 세팅**
1. supabase.com 가입 → 프로젝트 생성
2. SQL Editor에서 스키마 실행 (§4 참조)
3. Authentication → Apple Provider 활성화
4. Apple Developer Console에서 Sign In with Apple 설정

**7-2. iOS 앱 세팅**
1. supabase-swift 패키지 추가
2. Apple Sign In capability 추가 (Xcode → Signing & Capabilities)
3. SupabaseClient 초기화 코드 추가

**7-3. 기능 구현 순서**
1. Apple Sign In 로그인/로그아웃
2. 게임 종료 시 점수 서버 저장
3. 종료 화면에 글로벌 순위 표시
4. 리더보드 화면 추가
5. 로컬 기록 → 서버 마이그레이션

---

## 8. 비용 정리

| 항목 | 비용 |
|---|---|
| Apple Developer Program | **$99/년** (필수) |
| Supabase 무료 플랜 | **$0** |
| 서버 비용 | **$0** (Supabase 클라우드) |
| 도메인 | **$0** (불필요) |
| **총합** | **$99/년** |

> 앱 유저가 수천 명 넘어가면 Supabase $25/월 고려.
> 그 전까지 완전 무료.
