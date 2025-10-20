import Foundation
import Security

public protocol UserDefaultsServiceProtocol {
    func add(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    func delete(_ query: CFDictionary) -> OSStatus
}

public final class UserDefaultsServiceWrapper: UserDefaultsServiceProtocol {

    private let defaults = UserDefaults.standard

    public init() { }

    /// 模拟 Keychain 的 add 操作
    public func add(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        guard let dict = attributes as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String,
              let data = dict[kSecValueData as String] as? Data else {
            return errSecParam // 参数错误
        }

        // 防止重复添加
        if defaults.object(forKey: account) != nil {
            return errSecDuplicateItem
        }

        defaults.set(data, forKey: account)
        return errSecSuccess
    }

    /// 模拟 Keychain 的 copyMatching 操作
    public func copyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        guard let dict = query as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        guard let data = defaults.data(forKey: account) else {
            return errSecItemNotFound
        }

        if let res = result {
            res.pointee = data as CFData
        }

        return errSecSuccess
    }

    /// 模拟 Keychain 的 update 操作
    public func update(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        guard let queryDict = query as? [String: Any],
              let account = queryDict[kSecAttrAccount as String] as? String,
              let updateDict = attributesToUpdate as? [String: Any],
              let data = updateDict[kSecValueData as String] as? Data else {
            return errSecParam
        }

        guard defaults.object(forKey: account) != nil else {
            return errSecItemNotFound
        }

        defaults.set(data, forKey: account)
        return errSecSuccess
    }

    /// 模拟 Keychain 的 delete 操作
    public func delete(_ query: CFDictionary) -> OSStatus {
        guard let dict = query as? [String: Any],
              let account = dict[kSecAttrAccount as String] as? String else {
            return errSecParam
        }

        defaults.removeObject(forKey: account)
        return errSecSuccess
    }
}
