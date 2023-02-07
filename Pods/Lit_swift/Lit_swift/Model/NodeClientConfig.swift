//
//  LitNodeClientConfig.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/13.
//

import Foundation

public enum LitNetwork: String {
    case jalapeno
    case serrano
    case localhost
    case mumbai
    case custom
    
    public var networks: [String] {
        switch self {
        case .jalapeno:
            return [
                "https://node2.litgateway.com:7370",
                "https://node2.litgateway.com:7371",
                "https://node2.litgateway.com:7372",
                "https://node2.litgateway.com:7373",
                "https://node2.litgateway.com:7374",
                "https://node2.litgateway.com:7375",
                "https://node2.litgateway.com:7376",
                "https://node2.litgateway.com:7377",
                "https://node2.litgateway.com:7378",
                "https://node2.litgateway.com:7379",
              ]
        case .serrano:
            return [
                "https://serrano.litgateway.com:7370",
                "https://serrano.litgateway.com:7371",
                "https://serrano.litgateway.com:7372",
                "https://serrano.litgateway.com:7373",
                "https://serrano.litgateway.com:7374",
                "https://serrano.litgateway.com:7375",
                "https://serrano.litgateway.com:7376",
                "https://serrano.litgateway.com:7377",
                "https://serrano.litgateway.com:7378",
                "https://serrano.litgateway.com:7379",
                  
            ]
        case .localhost:
            return [
                "http://localhost:7470",
                "http://localhost:7471",
                "http://localhost:7472",
                "http://localhost:7473",
                "http://localhost:7474",
                "http://localhost:7475",
                "http://localhost:7476",
                "http://localhost:7477",
                "http://localhost:7478",
                "http://localhost:7479",
            ]
        case .mumbai:
            return [
                "https://polygon-mumbai.litgateway.com:7370",
                "https://polygon-mumbai.litgateway.com:7371",
                "https://polygon-mumbai.litgateway.com:7372",
            ]
        case .custom:
            return []
        }
    }
}

public class LitNodeClientConfig {
    var alertWhenUnauthorized: Bool
    var minNodeCount: Int
    var debug: Bool
    var bootstrapUrls: [String]
    var litNetwork: LitNetwork
    public init(alertWhenUnauthorized: Bool = true,
                minNodeCount: Int = 6,
                debug: Bool = true,
                bootstrapUrls: [String] = LitNetwork.jalapeno.networks,
                litNetwork: LitNetwork = LitNetwork.jalapeno) {
        self.alertWhenUnauthorized = alertWhenUnauthorized
        self.minNodeCount = minNodeCount
        self.debug = debug
        self.bootstrapUrls = bootstrapUrls
        self.litNetwork = litNetwork
    }
}
