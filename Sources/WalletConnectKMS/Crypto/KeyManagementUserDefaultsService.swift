import Foundation

public class KeyManagementUserDefaultsService: KeyManagementServiceProtocol {
    enum Error: Swift.Error {
        case keyNotFound
    }

    private var userDefaults: KeychainStorageProtocol

    public init(userDefaults: KeychainStorageProtocol) {
        self.userDefaults = userDefaults
    }

    public func createX25519KeyPair() throws -> AgreementPublicKey {
        let privateKey = AgreementPrivateKey()
        try setPrivateKey(privateKey)
        return privateKey.publicKey
    }

    public func createSymmetricKey(_ topic: String) throws -> SymmetricKey {
        let key = SymmetricKey()
        try setSymmetricKey(key, for: topic)
        return key
    }

    public func setSymmetricKey(_ symmetricKey: SymmetricKey, for topic: String) throws {
        try userDefaults.add(symmetricKey, forKey: topic)
    }

    public func setPrivateKey(_ privateKey: AgreementPrivateKey) throws {
        try userDefaults.add(privateKey, forKey: privateKey.publicKey.hexRepresentation)
    }

    public func setPublicKey(publicKey: AgreementPublicKey, for topic: String) throws {
        try userDefaults.add(publicKey, forKey: topic)
    }

    public func setAgreementSecret(_ agreementSecret: AgreementKeys, topic: String) throws {
        try userDefaults.add(agreementSecret, forKey: topic)
    }

    public func setTopic(_ topic: String, for key: String) throws {
        try userDefaults.add(topic, forKey: key)
    }

    public func deleteTopic(for key: String) {
        do {
            try userDefaults.delete(key: key)
        } catch {
            print("Error deleting topic: \(error)")
        }
    }

    public func getSymmetricKey(for topic: String) -> SymmetricKey? {
        do {
            return try userDefaults.read(key: topic) as SymmetricKey
        } catch {
            return nil
        }
    }

    public func getSymmetricKeyRepresentable(for topic: String) -> Data? {
        if let key = getAgreementSecret(for: topic)?.sharedKey {
            return key.rawRepresentation
        } else {
            return getSymmetricKey(for: topic)?.rawRepresentation
        }
    }

    public func getPrivateKey(for publicKey: AgreementPublicKey) throws -> AgreementPrivateKey? {
        do {
            return try userDefaults.read(key: publicKey.hexRepresentation) as AgreementPrivateKey
        } catch UserDefaultsError.itemNotFound {
            return nil
        } catch {
            throw error
        }
    }

    public func getTopic(for key: String) -> String? {
        do {
            return try userDefaults.read(key: key) as String
        } catch {
            return nil
        }
    }

    public func getAgreementSecret(for topic: String) -> AgreementKeys? {
        do {
            return try userDefaults.read(key: topic) as AgreementKeys
        } catch {
            return nil
        }
    }

    public func getPublicKey(for topic: String) -> AgreementPublicKey? {
        do {
            return try userDefaults.read(key: topic) as AgreementPublicKey
        } catch {
            return nil
        }
    }

    public func deletePrivateKey(for publicKey: String) {
        do {
            try userDefaults.delete(key: publicKey)
        } catch {
            print("Error deleting private key: \(error)")
        }
    }

    public func deleteAgreementSecret(for topic: String) {
        do {
            try userDefaults.delete(key: topic)
        } catch {
            print("Error deleting agreement key: \(error)")
        }
    }

    public func deleteSymmetricKey(for topic: String) {
        do {
            try userDefaults.delete(key: topic)
        } catch {
            print("Error deleting symmetric key: \(error)")
        }
    }

    public func deletePublicKey(for topic: String) {
        do {
            try userDefaults.delete(key: topic)
        } catch {
            print("Error deleting public key: \(error)")
        }
    }

    public func performKeyAgreement(selfPublicKey: AgreementPublicKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        guard let privateKey = try getPrivateKey(for: selfPublicKey) else {
            print("Key Agreement Error: Private key not found for public key: \(selfPublicKey.hexRepresentation)")
            throw KeyManagementUserDefaultsService.Error.keyNotFound
        }
        return try KeyManagementUserDefaultsService.generateAgreementKey(from: privateKey, peerPublicKey: hexRepresentation)
    }

    public func deleteAll() throws {
        try userDefaults.deleteAll()
    }

    static func generateAgreementKey(from privateKey: AgreementPrivateKey, peerPublicKey hexRepresentation: String) throws -> AgreementKeys {
        let peerPublicKey = try AgreementPublicKey(rawRepresentation: Data(hex: hexRepresentation))
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerPublicKey)
        let sharedKey = sharedSecret.deriveSymmetricKey()
        return AgreementKeys(sharedKey: sharedKey, publicKey: privateKey.publicKey)
    }
}
