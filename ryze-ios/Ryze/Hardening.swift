import Foundation
import Security
import CryptoKit
import UIKit

// MARK: - Keychain (device-only generic-password items)
enum Keychain {
    @discardableResult
    static func set(_ data: Data, for key: String) -> Bool {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
    static func get(_ key: String) -> Data? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        return SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess ? out as? Data : nil
    }
    static func delete(_ key: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key] as CFDictionary)
    }
}

// MARK: - Encrypted on-device store (AES-GCM, key in Keychain, file-protected)
// Replaces cleartext UserDefaults for the bank + game snapshots.
// ponytail: AES-GCM + Keychain-held key; device-bound by design (blob is unreadable after a restore, which is correct for a re-fetchable financial cache).
enum SecureStore {
    private static let keyTag = "ryze.datakey.v1"
    private static func key() -> SymmetricKey {
        if let d = Keychain.get(keyTag) { return SymmetricKey(data: d) }
        let k = SymmetricKey(size: .bits256)
        Keychain.set(k.withUnsafeBytes { Data($0) }, for: keyTag)
        return k
    }
    private static func url(_ name: String) -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(name).enc")
    }
    static func save(_ data: Data, _ name: String) {
        guard let sealed = try? AES.GCM.seal(data, using: key()).combined else { return }
        try? sealed.write(to: url(name), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    static func load(_ name: String) -> Data? {
        guard let blob = try? Data(contentsOf: url(name)),
              let box = try? AES.GCM.SealedBox(combined: blob),
              let clear = try? AES.GCM.open(box, using: key()) else { return nil }
        return clear
    }
    static func remove(_ name: String) { try? FileManager.default.removeItem(at: url(name)) }
}

// MARK: - Sensitive clipboard (auto-expires, never synced off-device)
enum Clip {
    static func copySensitive(_ s: String, seconds: TimeInterval = 60) {
        UIPasteboard.general.setItems([[UIPasteboard.typeAutomatic: s]],
                                      options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(seconds)])
    }
}
