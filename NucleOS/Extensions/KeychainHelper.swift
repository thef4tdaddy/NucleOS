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
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed with status: \(status)"
        case .getFailed(let status):
            return "Keychain get failed with status: \(status)"
        case .deleteFailed(let status):
            return "Keychain delete failed with status: \(status)"
        case .itemNotFound:
            return "Keychain item not found"
        }
    }
}

// MARK: - KeychainHelper

enum KeychainHelper {

    // MARK: Key Constants

    static let groqAPIKey = "com.nucleos.apikey.groq"
    static let anthropicAPIKey = "com.nucleos.apikey.anthropic"
    static let openAIAPIKey = "com.nucleos.apikey.openai"

    // MARK: Save

    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.saveFailed(errSecParam)
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete any existing item before saving (result intentionally ignored)
        _ = SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: Get

    static func get(key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
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
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
