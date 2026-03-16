import Foundation
import CryptoKit
import SwiftUI

/// Central app state managing vault lock/unlock and the active encryption key.
@MainActor
final class AppState: ObservableObject {
    @Published var isUnlocked = false
    @Published var isFirstLaunch: Bool
    @Published var error: String?

    private(set) var encryptionKey: SymmetricKey?
    let autoLock: AutoLock

    init() {
        self.autoLock = AutoLock(timeoutMinutes: 5)
        self.isFirstLaunch = !KeychainManager.keyExists()
    }

    // MARK: - First Launch Setup

    /// Set up the vault with a new master password.
    func setup(password: String, confirmPassword: String) throws {
        guard password == confirmPassword else {
            throw AppStateError.passwordMismatch
        }
        guard password.count >= 8 else {
            throw AppStateError.passwordTooShort
        }

        let salt = KeyDerivation.generateSalt()
        guard let key = KeyDerivation.deriveKey(from: password, salt: salt) else {
            throw AppStateError.keyDerivationFailed
        }

        let verificationHash = KeyDerivation.computeVerificationHash(for: key)
        let keyData = key.withUnsafeBytes { Data($0) }

        // Store in Keychain
        try KeychainManager.storeSalt(salt)
        try KeychainManager.storeVerificationHash(verificationHash)
        try KeychainManager.storeKey(keyData)

        self.encryptionKey = key
        self.isFirstLaunch = false
        self.isUnlocked = true
        autoLock.unlock()
    }

    // MARK: - Unlock with Touch ID / Keychain

    /// Attempt to unlock using the Keychain (triggers Touch ID).
    func unlockWithBiometric() {
        do {
            let keyData = try KeychainManager.retrieveKey()
            self.encryptionKey = SymmetricKey(data: keyData)
            self.isUnlocked = true
            self.error = nil
            autoLock.unlock()
        } catch {
            self.error = "Biometric unlock failed. Please enter your master password."
        }
    }

    // MARK: - Unlock with Password

    /// Unlock by entering the master password manually.
    func unlockWithPassword(_ password: String) throws {
        let salt = try KeychainManager.retrieveSalt()
        let verificationHash = try KeychainManager.retrieveVerificationHash()

        guard let key = KeyDerivation.verifyPassword(password, salt: salt, verificationHash: verificationHash) else {
            throw AppStateError.wrongPassword
        }

        // Re-store the key in Keychain (refreshes biometric access)
        let keyData = key.withUnsafeBytes { Data($0) }
        try KeychainManager.storeKey(keyData)

        self.encryptionKey = key
        self.isUnlocked = true
        self.error = nil
        autoLock.unlock()
    }

    // MARK: - Lock

    func lock() {
        encryptionKey = nil
        isUnlocked = false
        autoLock.lock()
    }
}

enum AppStateError: LocalizedError {
    case passwordMismatch
    case passwordTooShort
    case keyDerivationFailed
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .passwordMismatch: return "Passwords do not match"
        case .passwordTooShort: return "Password must be at least 8 characters"
        case .keyDerivationFailed: return "Failed to derive encryption key"
        case .wrongPassword: return "Incorrect master password"
        }
    }
}
