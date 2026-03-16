import Foundation
import CryptoKit

/// Derives a 256-bit symmetric key from a master password using PBKDF2.
enum KeyDerivation {

    /// Number of PBKDF2 iterations. 100k+ for strong resistance to brute-force.
    static let iterations = 100_000

    /// Salt length in bytes.
    static let saltLength = 32

    /// Generate a cryptographically random salt.
    static func generateSalt() -> Data {
        var salt = Data(count: saltLength)
        salt.withUnsafeMutableBytes { buffer in
            _ = SecRandomCopyBytes(kSecRandomDefault, saltLength, buffer.baseAddress!)
        }
        return salt
    }

    /// Derive a 256-bit key from a master password and salt using PBKDF2-SHA256.
    static func deriveKey(from password: String, salt: Data) -> SymmetricKey? {
        guard let passwordData = password.data(using: .utf8) else { return nil }

        var derivedKey = Data(count: 32) // 256 bits
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBuffer in
            salt.withUnsafeBytes { saltBuffer in
                passwordData.withUnsafeBytes { passwordBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        guard result == kCCSuccess else { return nil }
        return SymmetricKey(data: derivedKey)
    }

    /// Verify a password against a stored salt by re-deriving the key and comparing
    /// with a verification hash stored alongside the salt.
    static func verifyPassword(_ password: String, salt: Data, verificationHash: Data) -> SymmetricKey? {
        guard let key = deriveKey(from: password, salt: salt) else { return nil }
        let hash = computeVerificationHash(for: key)
        guard hash == verificationHash else { return nil }
        return key
    }

    /// Compute a SHA-256 hash of the derived key for verification purposes.
    /// This lets us check if the password is correct without storing the key itself.
    static func computeVerificationHash(for key: SymmetricKey) -> Data {
        let keyData = key.withUnsafeBytes { Data($0) }
        let hash = SHA256.hash(data: keyData)
        return Data(hash)
    }
}

// CommonCrypto bridge for PBKDF2
import CommonCrypto
