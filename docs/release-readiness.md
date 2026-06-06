# Release Readiness Checklist

- App Store Connect Privacy Nutrition Label이 `PrivacyInfo.xcprivacy`와 일치하는지 확인
- Firebase Authentication Apple provider의 Services ID / OAuth code flow 설정 확인
- Firestore security rules가 로그인한 사용자의 `users/{uid}` parent document 및 `scores`/`progress` subcollection delete를 허용하는지 확인
- 실제 기기에서 Apple 로그인 -> 로그아웃 -> 재로그인 -> 계정 삭제 -> 게스트 재생성 확인
- TestFlight 업로드 후 privacy manifest 경고/ITMS-91053 메일이 없는지 확인
