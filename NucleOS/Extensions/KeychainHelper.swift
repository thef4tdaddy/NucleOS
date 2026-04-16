//
//  KeychainHelper.swift
//  NucleOS
//
//  Secure Keychain wrapper for storing LLM provider API keys
//

import Foundation
import Security

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case getFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed: \(KeychainError.message(for: status))"
        case .getFailed(let status):
            return "Keychain get failed: \(KeychainError.message(for: status))"
        case .deleteFailed(let status):
            return "Keychain delete failed: \(KeychainError.message(for: status))"
        }
    }

    private static func message(for status: OSStatus) -> String {
        if let msg = SecCopyErrorMessageString(status, nil) as String? {
            return "\(msg) (\(status))"
        }
        return "status: \(status)"
    }
}

// MARK: - KeychainHelper

enum KeychainHelper {

    // MARK: Key Constants

    static let groqAPIKey = "com.nucleos.apikey.groq"
    static let anthropicAPIKey = "com.nucleos.apikey.anthropic"
    static let openAIAPIKey = "com.nucleos.apikey.openai"

    private static let service = "com.nucleos.NucleOS"

    // MARK: Save

    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.saveFailed(errSecParam)
        }

        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.deleteFailed(deleteStatus)
        }

        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: Get

    static func get(key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.getFailed(errSecDecode)
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.getFailed(status)
        }
    }

    // MARK: Delete

    static func delete(key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
