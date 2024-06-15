//
//  Ed25519.swift
//
//
//  Created by Amir Abbas Mousavian on 9/9/23.
//

import Foundation
import Crypto

extension Crypto.Curve25519.Signing.PublicKey: CryptoECPublicKey {
    static var curve: JSONWebKeyCurve { .ed25519 }
    
    public var storage: JSONWebValueStorage {
        var result = AnyJSONWebKey()
        result.keyType = .octetKeyPair // Ed25519 is OKP per RFC8037
        result.curve = Self.curve
        result.xCoordinate = rawRepresentation
        return result.storage
    }
    
    public static func create(storage: JSONWebValueStorage) throws -> Self {
        let keyData = AnyJSONWebKey(storage: storage)
        guard let x = keyData.xCoordinate, !x.isEmpty else {
            throw CryptoKitError.incorrectKeySize
        }
        return try .init(rawRepresentation: x)
    }
}

extension Crypto.Curve25519.KeyAgreement.PublicKey: CryptoECPublicKey {
    static var curve: JSONWebKeyCurve { .x25519 }
    
    public var storage: JSONWebValueStorage {
        var result = AnyJSONWebKey()
        result.keyType = .octetKeyPair // X25519 is OKP per RFC8037
        result.curve = Self.curve
        result.xCoordinate = rawRepresentation
        return result.storage
    }
    
    public static func create(storage: JSONWebValueStorage) throws -> Self {
        let keyData = AnyJSONWebKey(storage: storage)
        guard let x = keyData.xCoordinate, !x.isEmpty else {
            throw CryptoKitError.incorrectKeySize
        }
        return try .init(rawRepresentation: x)
    }
}

extension Crypto.Curve25519.Signing.PublicKey: JSONWebValidatingKey {
    public func verifySignature<S, D>(_ signature: S, for data: D, using _: JSONWebSignatureAlgorithm) throws where S: DataProtocol, D: DataProtocol {
        if !isValidSignature(signature, for: data) {
            throw CryptoKitError.authenticationFailure
        }
    }
}

extension Crypto.Curve25519.Signing.PublicKey: CryptoEdKeyPortable {}

extension Crypto.Curve25519.KeyAgreement.PublicKey: CryptoEdKeyPortable {}

extension Crypto.Curve25519.Signing.PrivateKey: JSONWebSigningKey, CryptoECPrivateKey {
    public init(algorithm _: any JSONWebAlgorithm) throws {
        self.init()
    }
    
    public func signature<D>(_ data: D, using _: JSONWebSignatureAlgorithm) throws -> Data where D: DataProtocol {
        try signature(for: data)
    }
}

extension Crypto.Curve25519.KeyAgreement.PrivateKey: CryptoECPrivateKey {
    public init(algorithm _: any JSONWebAlgorithm) throws {
        self.init()
    }
}

extension Crypto.Curve25519.Signing.PrivateKey: CryptoEdKeyPortable {}

extension Crypto.Curve25519.KeyAgreement.PrivateKey: CryptoEdKeyPortable {}

protocol CryptoEdKeyPortable: JSONWebKeyImportable, JSONWebKeyExportable {
    var rawRepresentation: Data { get }
    
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
}

extension CryptoEdKeyPortable {
    public init<D>(importing key: D, format: JSONWebKeyFormat) throws where D: DataProtocol {
        switch format {
        case .raw:
            if key.regions.count == 1, let keyData = key.regions.first {
                try self.init(rawRepresentation: keyData)
            } else {
                try self.init(rawRepresentation: Data(key))
            }
        case .jwk:
            self = try JSONDecoder().decode(Self.self, from: Data(key))
        default:
            throw JSONWebKeyError.invalidKeyFormat
        }
    }
    
    public func exportKey(format: JSONWebKeyFormat) throws -> Data {
        switch format {
        case .raw:
            return rawRepresentation
        case .jwk:
            return try jwkRepresentation
        default:
            throw JSONWebKeyError.invalidKeyFormat
        }
    }
}
