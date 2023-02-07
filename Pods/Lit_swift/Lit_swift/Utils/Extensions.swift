//
//  Extensions.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/13.
//

import Foundation
import web3
extension Collection where Element == String {
    
    
    var mostCommonString: String? {
        return self.sorted { first, second in
            return self.filter({ $0 == first }).count > self.filter({ $0 == second }).count
        }.first
        
    }
}


extension String {
    func asUrl() throws -> URL {
        if let url = URL(string: self) {
            return url
        }
        throw LitError.INVALID_URL(self)
    }
    
    static func random(minimumLength min: Int, maximumLength max: Int) -> String {
        return random(
                    withCharactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
                    minimumLength: min,
                    maximumLength: max
                )
    }
    
    static func random(withCharactersInString string: String, minimumLength min: Int, maximumLength max: Int) -> String {
            guard min > 0 && max >= min else {
                return ""
            }
            
            let length: Int = (min < max) ? .random(in: min...max) : max
            var randomString = ""
            
            (1...length).forEach { _ in
                let randomIndex: Int = .random(in: 0..<string.count)
                let c = string.index(string.startIndex, offsetBy: randomIndex)
                randomString += String(string[c])
            }
            
            return randomString
    }
    
    func toISODate() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}

extension Collection where Element == String {
    func toBase64String() throws -> String {
       return try JSONSerialization.data(withJSONObject: self).base64EncodedString()
    }
    
    func toJsonString() throws -> String? {
        let data = try JSONSerialization.data(withJSONObject: self)
        return String(data: data, encoding: .utf8)
    }
}

extension Data {
    func toBase16String() -> String? {
        return self.web3.hexString.web3.noHexPrefix
    }
    
}


