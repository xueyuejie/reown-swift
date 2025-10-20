import Foundation

public struct NetworkingClientFactory {

    public static func create(
        relayClient: RelayClient,
        groupIdentifier: String
    ) -> NetworkingInteractor {
        let logger = ConsoleLogger(prefix: "🕸️", loggingLevel: .off)

        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }

        let keychainStorage = UserDefaultsStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)
        return NetworkingClientFactory.create(relayClient: relayClient, logger: logger, keychainStorage: keychainStorage, keyValueStorage: keyValueStorage)
    }

    public static func create(relayClient: RelayClient, logger: ConsoleLogging, keychainStorage: KeychainStorageProtocol, keyValueStorage: KeyValueStorage, kmsLogger: ConsoleLogging = ConsoleLogger(prefix: "🔐", loggingLevel: .off)) -> NetworkingInteractor {
        let kms = KeyManagementUserDefaultsService(userDefaults: keychainStorage)

        let serializer = Serializer(kms: kms, logger: kmsLogger)

        let rpcHistory = RPCHistoryFactory.createForNetwork(keyValueStorage: keyValueStorage)

        return NetworkingInteractor(
            relayClient: relayClient,
            serializer: serializer,
            logger: logger,
            rpcHistory: rpcHistory)
    }
}
