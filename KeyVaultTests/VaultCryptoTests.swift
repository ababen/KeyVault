import XCTest
import CryptoKit
@testable import KeyVault

final class VaultCryptoTests: XCTestCase {

    let testKey = SymmetricKey(size: .bits256)

    func testEncryptDecryptRoundTrip() throws {
        let plaintext = "sk-test-1234567890abcdef"
        let payload = try VaultCrypto.encrypt(plaintext, using: testKey)
        let decrypted = try VaultCrypto.decrypt(
            ciphertext: payload.ciphertext,
            nonce: payload.nonce,
            tag: payload.tag,
            using: testKey
        )
        XCTAssertEqual(decrypted, plaintext)
    }

    func testDecryptWithWrongKeyFails() throws {
        let plaintext = "secret-value"
        let payload = try VaultCrypto.encrypt(plaintext, using: testKey)
        let wrongKey = SymmetricKey(size: .bits256)

        XCTAssertThrowsError(try VaultCrypto.decrypt(
            ciphertext: payload.ciphertext,
            nonce: payload.nonce,
            tag: payload.tag,
            using: wrongKey
        ))
    }

    func testEncryptProducesDifferentNonces() throws {
        let plaintext = "same-value"
        let payload1 = try VaultCrypto.encrypt(plaintext, using: testKey)
        let payload2 = try VaultCrypto.encrypt(plaintext, using: testKey)
        // Each encryption should use a unique nonce
        XCTAssertNotEqual(payload1.nonce, payload2.nonce)
    }

    func testEmptyStringEncryption() throws {
        let plaintext = ""
        let payload = try VaultCrypto.encrypt(plaintext, using: testKey)
        let decrypted = try VaultCrypto.decrypt(
            ciphertext: payload.ciphertext,
            nonce: payload.nonce,
            tag: payload.tag,
            using: testKey
        )
        XCTAssertEqual(decrypted, plaintext)
    }

    func testUnicodeEncryption() throws {
        let plaintext = "🔑 API Key: café-naïve-résumé"
        let payload = try VaultCrypto.encrypt(plaintext, using: testKey)
        let decrypted = try VaultCrypto.decrypt(
            ciphertext: payload.ciphertext,
            nonce: payload.nonce,
            tag: payload.tag,
            using: testKey
        )
        XCTAssertEqual(decrypted, plaintext)
    }
}

final class KeyDerivationTests: XCTestCase {

    func testDeriveKeyProducesConsistentResults() {
        let password = "test-master-password"
        let salt = KeyDerivation.generateSalt()
        let key1 = KeyDerivation.deriveKey(from: password, salt: salt)
        let key2 = KeyDerivation.deriveKey(from: password, salt: salt)
        XCTAssertNotNil(key1)
        XCTAssertNotNil(key2)
        // Same password + same salt = same key
        let data1 = key1!.withUnsafeBytes { Data($0) }
        let data2 = key2!.withUnsafeBytes { Data($0) }
        XCTAssertEqual(data1, data2)
    }

    func testDifferentPasswordsProduceDifferentKeys() {
        let salt = KeyDerivation.generateSalt()
        let key1 = KeyDerivation.deriveKey(from: "password1", salt: salt)
        let key2 = KeyDerivation.deriveKey(from: "password2", salt: salt)
        let data1 = key1!.withUnsafeBytes { Data($0) }
        let data2 = key2!.withUnsafeBytes { Data($0) }
        XCTAssertNotEqual(data1, data2)
    }

    func testVerificationHashWorks() {
        let password = "my-master-pass"
        let salt = KeyDerivation.generateSalt()
        let key = KeyDerivation.deriveKey(from: password, salt: salt)!
        let hash = KeyDerivation.computeVerificationHash(for: key)

        // Correct password should verify
        let verified = KeyDerivation.verifyPassword(password, salt: salt, verificationHash: hash)
        XCTAssertNotNil(verified)

        // Wrong password should fail
        let failed = KeyDerivation.verifyPassword("wrong-pass", salt: salt, verificationHash: hash)
        XCTAssertNil(failed)
    }
}
