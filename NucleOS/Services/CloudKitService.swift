//
//  CloudKitService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for CloudKit / iCloud Family Sharing sync
//

import Foundation

// MARK: - Protocol

protocol CloudKitServiceProtocol {
    func fetchSharedData() async throws -> [String: any Sendable]
    func syncData() async throws
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with CloudKit for iCloud and Family Sharing sync.
class CloudKitService: CloudKitServiceProtocol {

    func fetchSharedData() async throws -> [String: any Sendable] {
        // TODO: Query the shared CloudKit database for family-shared records
        return [:]
    }

    func syncData() async throws {
        // TODO: Push local changes and pull remote changes from CloudKit
    }
}

// MARK: - Mock Implementation

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
class MockCloudKitService: CloudKitServiceProtocol {

    func fetchSharedData() async throws -> [String: any Sendable] {
        return [
            "familyMemberCount": 3,
            "lastSyncDate": ISO8601DateFormatter().string(from: Date()),
            "sharedLists": ["Groceries", "Weekend Plans", "Family Goals"],
            "syncStatus": "up-to-date"
        ]
    }

    func syncData() async throws {
        // No-op for mock — pretend sync completed successfully
    }
}
