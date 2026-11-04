import CryptoSwift
import Foundation

struct AESUtils {
    static func randomString(length: Int) -> String {
        let letters = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    static func aesEncrypt(data: String, key: String, iv: String) -> String? {
        do {
            let keyBytes = Array(key.utf8.prefix(16))
            let ivBytes = Array(iv.utf8.prefix(16))
            let plaintext = Array(data.utf8)

            let aes = try AES(key: keyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
            let encrypted = try aes.encrypt(plaintext)

            return Data(encrypted).base64EncodedString()
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }

    static func encryptPassword(password: String, salt: String?) -> String {
        guard let key = salt, !key.isEmpty else {
            return password
        }

        let salt = randomString(length: 64)
        let iv = randomString(length: 16)
        let combinedData = salt + password

        if let encryptedData = aesEncrypt(data: combinedData, key: key, iv: iv) {
            return encryptedData
        } else {
            return password
        }
    }
}
