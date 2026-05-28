//
//  FirebaseDiagnostics.swift
//  GanhoMusic Shared
//
//  Firebase 연결 상태를 Xcode 콘솔과 시뮬레이터 로그에서 확인하기 위한 진단 로거.
//

import Foundation
import os

enum FirebaseDiagnostics {
    private static let logger = Logger(subsystem: "com.hg.GanhoMusic", category: "Firebase")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        #if DEBUG
        print("[Firebase] \(message)")
        #endif
    }

    static func error(_ message: String, error: Error? = nil) {
        let detail = error.map { detailedDescription(for: $0) } ?? ""
        let output = detail.isEmpty ? message : "\(message) \(detail)"
        logger.error("\(output, privacy: .public)")
        #if DEBUG
        print("[Firebase] \(output)")
        #endif
    }

    private static func detailedDescription(for error: Error) -> String {
        let nsError = error as NSError
        var parts = [
            "domain=\(nsError.domain)",
            "code=\(nsError.code)"
        ]

        if !nsError.localizedDescription.isEmpty {
            parts.append("message=\(nsError.localizedDescription)")
        }

        if let reason = nsError.localizedFailureReason, !reason.isEmpty {
            parts.append("reason=\(reason)")
        }

        return "(\(parts.joined(separator: ", ")))"
    }
}
