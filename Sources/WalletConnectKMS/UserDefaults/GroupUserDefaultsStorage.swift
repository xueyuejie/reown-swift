
import Foundation

public final class GroupUserDefaultsStorage: KeychainStorageProtocol {
    private let defaults: UserDefaults
    private let accessGroup: String

    public init(serviceIdentifier: String) {
        self.accessGroup = serviceIdentifier
        // 使用 App Group 的 UserDefaults，如果不需要 AppGroup 可改成 standard
        if let suite = UserDefaults(suiteName: serviceIdentifier) {
            self.defaults = suite
        } else {
            self.defaults = UserDefaults.standard
        }
    }

    // MARK: - Add

    public func add<T>(_ item: T, forKey key: String) throws where T: GenericPasswordConvertible {
        let data = item.rawRepresentation
        defaults.set(data, forKey: key)
    }

    // MARK: - Read

    public func read<T>(key: String) throws -> T where T: GenericPasswordConvertible {
        guard let data = defaults.data(forKey: key) else {
            throw UserDefaultsError(errSecItemNotFound)
        }
        return try T(rawRepresentation: data)
    }

    // MARK: - Delete

    public func delete(key: String) throws {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Delete All

    public func deleteAll() throws {
        // 遍历所有 key 删除（仅清理这个命名空间的 key）
        for (key, _) in defaults.dictionaryRepresentation() {
            defaults.removeObject(forKey: key)
        }
    }
}
