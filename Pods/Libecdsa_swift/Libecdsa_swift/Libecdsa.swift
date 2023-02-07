//
//  Libecdsa.swift
//  Libecdsa_swift
//
//  Created by leven on 2023/1/25.
//

import Foundation
import Libecdsa_swift.libecdsa
public func combine_signature(_ rx: String, ry: String, shares: String) -> [String: Any]? {
    if let cs = combine_signature_raw(rx, ry, shares) {
        let res = String(cString: cs)
        if let data = res.data(using: .utf8), let res = try? JSONSerialization.jsonObject(with: data) {
            return res as? [String: Any]
        }
    }
    return nil
}
