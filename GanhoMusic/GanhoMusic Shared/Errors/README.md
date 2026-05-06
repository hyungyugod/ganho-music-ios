# Errors/

**Spring 대응**: `exceptions/` (얇게)
**역할**: 도메인 에러 타입 — `enum: Error`

Spring은 `Exception` 클래스 계층 + `@ExceptionHandler` 로 처리. Swift는 **`enum: Error` + `do/catch` 또는 `Result`** 로 더 간결.

게임 도메인 자체에는 에러가 적기 때문에 이 폴더는 **얇게 유지**한다 (Phase 7 백엔드 연동 시 본격화).

## 향후 들어올 파일

| 파일 | Phase | 역할 |
|---|---|---|
| `GameError.swift` | 7 | 게임 도메인 에러 (`sceneLoadFailed`, `audioInitFailed` 등) |
| `NetworkError.swift` | 7 | Supabase 통신 에러 |
| `AuthError.swift` | 7 | Apple Sign In 에러 |

## 컨벤션

```swift
enum GameError: Error, LocalizedError {
    case sceneLoadFailed(String)
    case audioInitFailed
    
    var errorDescription: String? {
        switch self {
        case .sceneLoadFailed(let name): return "\(name) 씬 로드 실패"
        case .audioInitFailed: return "오디오 초기화 실패"
        }
    }
}
```

## 관련 문서

- `docs/architecture-mapping.md` §1 매핑 표 — exceptions/ 항목
