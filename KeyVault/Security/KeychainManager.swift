import Foundation
import Security

/// Manages storing and retrieving the vault encryption key from the macOS Keychain.
/// The key is protected by the Secure Enclave and can be unlocked via Touch ID.
enum KeychainManager {

    private static let service = "com.keyvault.encryption-key"
    private static let saltAccount = "vault-salt"
    private static let keyAccount = "vault-key"
    private static let verificationAccount = "vault-verification"

    // MARK: - Encryption Key

    /// Store the derived encryption key in Keychain with biometric protection.
    static func storeKey(_ key: Data) throws {
        try deleteItem(account: keyAccount)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAccount,
            kSecValueData as String: key
        ]

        // Add biometric access control if available
        if let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .userPresence,  // Touch ID, Apple Watch, or passcode
            nil
        ) {
            query[kSecAttrAccessControl as String] = accessControl
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    /// Retrieve the encryption key from Keychain (triggers Touch ID if configured).
    static func retrieveKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAccount,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: "Unlock KeyVault"
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unableToRetrieve(status)
        }
        return data
    }

    /// Check if a key exists in Keychain without triggering biometric.
    static func keyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyAccount,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        // errSecInteractionNotAllowed means item exists but needs auth
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    // MARK: - Salt

    /// Store the PBKDF2 salt (not sensitive, but kept in Keychain for convenience).
    static func storeSalt(_ salt: Data) throws {
        try deleteItem(account: saltAccount)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: saltAccount,
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    /// Retrieve the stored salt.
    static func retrieveSalt() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: saltAccount,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unableToRetrieve(status)
        }
        return data
    }

    // MARK: - Verification Hash

    /// Store the password verification hash.
    static func storeVerificationHash(_ hash: Data) throws {
        try deleteItem(account: verificationAccount)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: verificationAccount,
            kSecValueData as String: hash,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    /// Retrieve the verification hash.
    static func retrieveVerificationHash() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: verificationAccount,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unableToRetrieve(status)
        }
        return data
    }

    // MARK: - Cleanup

    /// Delete all KeyVault Keychain items (used for reset).
    static func deleteAll() {
        for account in [keyAccount, saltAccount, verificationAccount] {
            try? deleteItem(account: account)
        }
    }

    private static func deleteItem(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
}

enum KeychainError: LocalizedError {
    case unableToStore(OSStatus)
    case unableToRetrieve(OSStatus)
    case unableToDelete(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToStore(let status):
            return "Keychain store failed: \(status)"
        case .unableToRetrieve(let status):
            return "Keychain retrieve failed: \(status)"
        case .unableToDelete(let status):
            return "Keychain delete failed: \(status)"
        }
    }
}
