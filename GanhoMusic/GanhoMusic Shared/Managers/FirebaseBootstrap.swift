//
//  FirebaseBootstrap.swift
//  GanhoMusic Shared
//
//  Firebase SDK 초기화 진입점.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrap {
    private static var didConfigure = false

    @discardableResult
    static func configureIfAvailable() -> Bool {
        #if canImport(FirebaseCore)
        guard !didConfigure else { return true }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            FirebaseDiagnostics.error("GoogleService-Info.plist not found. Running in local-only mode.")
            return false
        }
        FirebaseApp.configure()
        didConfigure = true
        FirebaseDiagnostics.info("Configured.")
        return true
        #else
        FirebaseDiagnostics.error("FirebaseCore module is not linked. Running in local-only mode.")
        return false
        #endif
    }
}
