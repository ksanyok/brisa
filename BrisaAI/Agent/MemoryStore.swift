import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private let service = "ai.brisa.mac"
    private let accountAPI = "openai_api_key"

    func setAPIKey(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: accountAPI]
        SecItemDelete(query as CFDictionary)
        let add: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrService as String: service,
                                  kSecAttrAccount as String: accountAPI,
                                  kSecValueData as String: data,
                                  kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        SecItemAdd(add as CFDictionary, nil)
    }

    func getAPIKey() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: accountAPI,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return String(data: data, encoding: .utf8) }
        return nil
    }
}

final class MemoryStore {
    static let shared = MemoryStore()
    private let fileURL: URL
    private var cache: [String: Any] = [:]

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BrisaAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("memory.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { cache = [:]; return }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            cache = obj
        }
    }

    func save() {
        if let data = try? JSONSerialization.data(withJSONObject: cache, options: [.prettyPrinted]) {
            try? data.write(to: fileURL)
        }
    }

    func get(_ key: String) -> Any? { cache[key] }
    func set(_ key: String, value: Any) { cache[key] = value; save() }
}

