import Foundation
import SwiftData

@Model
final class SecureField {
    var id: UUID
    var label: String
    /// The encrypted value stored at rest. Use VaultCrypto to decrypt.
    var encryptedValue: Data
    /// Nonce used for this field's AES-GCM encryption
    var nonce: Data
    /// Tag for AES-GCM authentication
    var authTag: Data
    var isSensitive: Bool
    var sortOrder: Int
    var entry: Entry?

    init(
        label: String,
        encryptedValue: Data = Data(),
        nonce: Data = Data(),
        authTag: Data = Data(),
        isSensitive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.label = label
        self.encryptedValue = encryptedValue
        self.nonce = nonce
        self.authTag = authTag
        self.isSensitive = isSensitive
        self.sortOrder = sortOrder
    }
}
