//
//  SentryConfig.swift
//  NucleOS
//
//  Configures and initialises the Sentry SDK.
//  DSN is read from Info.plist (key: SENTRY_DSN) — never hardcoded.
//  No PII is collected: task titles, event names, and health values are
//  explicitly excluded from all breadcrumbs and events.
//

import Foundation
#if canImport(Sentry)
import Sentry
#endif

enum SentryConfig {

    // MARK: - Setup

    /// Initialises the Sentry SDK.
    /// Call this once, before the first `WindowGroup` is created in `NucleOSApp`.
    static func setup() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !dsn.isEmpty,
              dsn != "REPLACE_WITH_YOUR_SENTRY_DSN" else {
            // DSN not configured — skip Sentry initialisation in development.
            return
        }

#if canImport(Sentry)
        SentrySDK.start { options in
            options.dsn = dsn

            // Sample 100 % of traces in DEBUG, 20 % in Release.
#if DEBUG
            options.tracesSampleRate = 1.0
#else
            options.tracesSampleRate = 0.2
#endif

            options.enableAppHangTracking = true
            options.enableCrashHandler = true

            // Privacy: strip any user-identifying information.
            options.sendDefaultPii = false

            // Privacy: filter breadcrumbs to ensure no PII leaks.
            // Task titles, event names, and health values must never appear.
            options.beforeBreadcrumb = { breadcrumb in
                // Discard breadcrumbs that might carry user content.
                let sensitiveCategories: Set<String> = ["ui.click", "ui.lifecycle"]
                if sensitiveCategories.contains(breadcrumb.category ?? "") {
                    return nil
                }
                // Redact breadcrumb fields that may contain PII
                breadcrumb.message = nil
                if var data = breadcrumb.data {
                    data.removeValue(forKey: "title")
                    data.removeValue(forKey: "task")
                    data.removeValue(forKey: "input")
                    breadcrumb.data = data
                }
                return breadcrumb
            }

            // Privacy: scrub event-level fields and all breadcrumbs before sending.
            options.beforeSend = { event in
                // Nil out event-level PII fields
                event.message = nil
                event.user = nil

                // Clear contexts, extra, and tags that may contain PII
                if event.context != nil {
                    event.context = [:]
                }
                if event.extra != nil {
                    event.extra = [:]
                }
                if event.tags != nil {
                    event.tags = [:]
                }

                // Redact all breadcrumbs in the event
                if let breadcrumbs = event.breadcrumbs {
                    for breadcrumb in breadcrumbs {
                        breadcrumb.message = nil
                        if var data = breadcrumb.data {
                            data.removeValue(forKey: "title")
                            data.removeValue(forKey: "task")
                            data.removeValue(forKey: "input")
                            breadcrumb.data = data
                        }
                    }
                }

                return event
            }
        }
#endif
    }

    // MARK: - Performance Spans

    /// Wraps an async throwing operation in a Sentry performance span.
    /// The operation name must be a generic technical label — never a user value.
    /// - Parameters:
    ///   - operation: Sentry operation string (e.g. `"db.query"`).
    ///   - name: Human-readable span name (no PII).
    ///   - block: The work to instrument.
    /// - Returns: The value produced by `block`.
    @discardableResult
    static func traced<T>(
        operation: String,
        name: String,
        block: () async throws -> T
    ) async rethrows -> T {
#if canImport(Sentry)
        let span = SentrySDK.startTransaction(name: name, operation: operation)
        do {
            let result = try await block()
            span.finish(status: .ok)
            return result
        } catch {
            span.finish(status: .internalError)
            throw error
        }
#else
        return try await block()
#endif
    }
}