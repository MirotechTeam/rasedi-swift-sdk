import Foundation
import CryptoKit
import Security

public enum AuthError: Error {
    case unsupportedKeyFormat
    case signingError
}

public class Auth {
    private let privateKeyPem: String
    private let keyId: String
    
    public init(privateKeyPem: String, keyId: String) {
        self.privateKeyPem = privateKeyPem
        self.keyId = keyId
    }
    
    public func getKeyId() -> String {
        return keyId
    }
    
    public func makeSignature(method: String, relativeUrl: String) throws -> String {
        let rawSign = "\(method) || \(self.keyId) || \(relativeUrl)"
        guard let data = rawSign.data(using: .utf8) else {
            throw AuthError.signingError
        }
        
        let cleanedPem = self.privateKeyPem
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let keyData = Data(base64Encoded: cleanedPem) else {
            throw AuthError.unsupportedKeyFormat
        }
        
        // 1. Try Ed25519 check by approximate OID prefix (bytes 9-11)
        if keyData.count > 16, keyData[9] == 0x2B, keyData[10] == 0x65, keyData[11] == 0x70 {
            let seedBytes = keyData.suffix(32)
            if seedBytes.count == 32 {
                do {
                    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: seedBytes)
                    let signature = try privateKey.signature(for: data)
                    return signature.base64EncodedString()
                } catch {
                    // Fallthrough
                }
            }
        }
        
        // 2. Try SecKey for RSA / EC P-256
        let isRSA = privateKeyPem.contains("RSA")
        var attributes: [String: Any] = [
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeyType as String: isRSA ? kSecAttrKeyTypeRSA : kSecAttrKeyTypeECSECPrimeRandom
        ]
        
        // Some systems require the key size if it's raw EC but since it's DER encoded PKCS8/SEC1, SecKeyCreateWithData usually handles it.
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            // Sometimes kSecAttrKeyTypeEC isn't correctly inferred without explicitly setting it to kSecAttrKeyTypeEC
            attributes[kSecAttrKeyType as String] = isRSA ? kSecAttrKeyTypeRSA : kSecAttrKeyTypeEC
            guard let retrySecKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
                throw AuthError.unsupportedKeyFormat
            }
            return try sign(with: retrySecKey, data: data, isRSA: isRSA)
        }
        
        return try sign(with: secKey, data: data, isRSA: isRSA)
    }
    
    private func sign(with secKey: SecKey, data: Data, isRSA: Bool) throws -> String {
        let algorithm: SecKeyAlgorithm = isRSA ? .rsaSignatureMessagePKCS1v15SHA256 : .ecdsaSignatureMessageX962SHA256
        
        guard SecKeyIsAlgorithmSupported(secKey, .sign, algorithm) else {
            throw AuthError.unsupportedKeyFormat
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(secKey, algorithm, data as CFData, &error) as Data? else {
            throw AuthError.signingError
        }
        
        if isRSA {
            return signature.base64EncodedString()
        } else {
            // Extract raw R and S components from DER for EC
            let rawRS = convertECDSASignatureDERToRawRS(signature)
            return rawRS.base64EncodedString()
        }
    }
    
    private func convertECDSASignatureDERToRawRS(_ derSignature: Data) -> Data {
        let bytes = [UInt8](derSignature)
        guard bytes.count > 4, bytes[0] == 0x30 else { return derSignature }
        
        var index = 2
        if bytes[1] > 0x80 {
            index += Int(bytes[1] - 0x80)
        }
        
        guard index < bytes.count, bytes[index] == 0x02 else { return derSignature }
        index += 1
        var rLength = Int(bytes[index])
        index += 1
        var rStart = index
        if rLength > 0 && bytes[rStart] == 0x00 && rLength > 32 {
            rStart += 1
            rLength -= 1
        }
        guard rStart + rLength <= bytes.count else { return derSignature }
        let rBytes = bytes[rStart..<(rStart + rLength)]
        index = rStart + rLength
        
        guard index < bytes.count, bytes[index] == 0x02 else { return derSignature }
        index += 1
        var sLength = Int(bytes[index])
        index += 1
        var sStart = index
        if sLength > 0 && bytes[sStart] == 0x00 && sLength > 32 {
            sStart += 1
            sLength -= 1
        }
        guard sStart + sLength <= bytes.count else { return derSignature }
        let sBytes = bytes[sStart..<(sStart + sLength)]
        
        var rawSignature = Data()
        let rPadding = 32 - rBytes.count
        if rPadding > 0 { rawSignature.append(Data(repeating: 0, count: rPadding)) }
        rawSignature.append(contentsOf: rBytes)
        
        let sPadding = 32 - sBytes.count
        if sPadding > 0 { rawSignature.append(Data(repeating: 0, count: sPadding)) }
        rawSignature.append(contentsOf: sBytes)
        
        return rawSignature.count == 64 ? rawSignature : derSignature
    }
}
