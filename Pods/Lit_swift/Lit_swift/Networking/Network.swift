//
//  Network.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/13.
//

import Foundation
import PromiseKit

func fetch<T: Decodable>(_ urlString: String, parameters: [String: Any], decodeType: T.Type) -> Promise<T> {
    return firstly {
         URLSession.shared.dataTask(.promise, with: try makeUrlRequest(urlString, parameters: parameters)).validate()
    }.map {
        if litLogEnable, let json = try? JSONSerialization.jsonObject(with: $0.data) {
            print(json)
        }
        return try JSONDecoder().decode(decodeType.self, from: $0.data)
    }
}

func makeUrlRequest(_ urlString: String, parameters: [String: Any]) throws -> URLRequest {
    let url = try urlString.asUrl()
    var rq = URLRequest(url: url)
    rq.httpMethod = "POST"
    rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
    rq.addValue(version, forHTTPHeaderField: "lit-js-sdk-version")
    rq.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    return rq
}
