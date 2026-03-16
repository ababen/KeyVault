import Foundation
import CryptoKit

/// Handles AES-256-GCM encryption and decryption of field values.
enum VaultCrypto {

    struct EncryptedPayload {
        let ciphertext: Data
        let nonce: Data
        let tag: Data
    }

    /// Encrypt a plaintext string using AES-256-GCM.
    static func encrypt(_ plaintext: String, using key: SymmetricKey) throws -> EncryptedPayload {
        guard let data = plaintext.data(using: .utf8) else {
            throw VaultCryptoError.encodingFailed
        }
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(data, using: key, nonce: nonce)

        guard let combined = sealed.combined else {
            throw VaultCryptoError.encryptionFailed
        }

        // combined = nonce (12 bytes) + ciphertext + tag (16 bytes)
        let nonceData = Data(nonce)
        let ciphertext = sealed.ciphertext
        let tag = sealed.tag

        return EncryptedPayload(ciphertext: Data(ciphertext), nonce: nonceData, tag: Data(tag))
    }

    /// Decrypt ciphertext using AES-256-GCM.
    static func decrypt(ciphertext: Data, nonce: Data, tag: Data, using key: SymmetricKey) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw VaultCryptoError.decodingFailed
        }
        return plaintext
    }

    /// Encrypt and store value into a SecureField.
    static func encryptField(_ value: String, into field: SecureField, using key: SymmetricKey) throws {
        let payload = try encrypt(value, using: key)
        field.encryptedValue = payload.ciphertext
        field.nonce = payload.nonce
        field.authTag = payload.tag
    }

    /// Decrypt a SecureField's value.
    static func decryptField(_ field: SecureField, using key: SymmetricKey) throws -> String {
        try decrypt(
            ciphertext: field.encryptedValue,
            nonce: field.nonce,
            tag: field.authTag,
            using: key
        )
    }
}

enum VaultCryptoError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Failed to encode plaintext"
        case .decodingFailed: return "Failed to decode decrypted data"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed — wrong password?"
        }
    }
}
