//
//  CloudKitService.swift
//  NucleOS
//
//  Protocol, real implementation, and mock for CloudKit / iCloud Family Sharing sync
//

import Foundation

// MARK: - SharedData

/// Strongly typed model for data shared via iCloud Family Sharing.
struct SharedData: Sendable, Equatable {
    let familyMemberCount: Int
    let lastSyncDate: Date
    let sharedLists: [String]
    let syncStatus: SyncStatus

    enum SyncStatus: String, Sendable, Equatable {
        case upToDate = "up-to-date"
        case syncing
        case error
    }
}

// MARK: - Protocol

protocol CloudKitServiceProtocol {
    func fetchSharedData() async throws -> SharedData
    func syncData() async throws
}

// MARK: - Errors

enum CloudKitServiceError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "CloudKitService is not implemented yet. CloudKit integration is still pending."
        }
    }
}

// MARK: - Real Implementation

/// Concrete implementation that will integrate with CloudKit for iCloud and Family Sharing sync.
class CloudKitService: CloudKitServiceProtocol {

    func fetchSharedData() async throws -> SharedData {
        // TODO: Query the shared CloudKit database for family-shared records
        throw CloudKitServiceError.notImplemented
    }

    func syncData() async throws {
        // TODO: Push local changes and pull remote changes from CloudKit
        throw CloudKitServiceError.notImplemented
    }
}

// MARK: - Mock Implementation

/// Mock implementation with realistic hardcoded data for SwiftUI previews and testing.
class MockCloudKitService: CloudKitServiceProtocol {

    func fetchSharedData() async throws -> SharedData {
        return SharedData(
            familyMemberCount: 3,
            lastSyncDate: Date(),
            sharedLists: ["Groceries", "Weekend Plans", "Family Goals"],
            syncStatus: .upToDate
        )
    }

    func syncData() async throws {
        // No-op for mock — pretend sync completed successfully
    }
}
