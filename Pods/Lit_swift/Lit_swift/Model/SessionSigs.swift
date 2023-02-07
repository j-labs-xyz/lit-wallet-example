//
//  SessionSigs.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/13.
//

import Foundation
import PromiseKit

public typealias AuthNeededCallback = (_ chain: Chain, _ resources: [String]?, _ switchChain: Bool, _ expiration: Date, _ url: String) -> Promise<JsonAuthSig>

public struct GetSessionSigsProps {
    let expiration: Date?
    let chain: Chain
    let resource: [String]
    let sessionCapabilities: [String] = []
    let switchChain: Bool
    let authNeededCallback: AuthNeededCallback?
    let sessionKey: String?
    public init(expiration: Date?, chain: Chain, resource: [String], switchChain: Bool, authNeededCallback: AuthNeededCallback?, sessionKey: String? = nil) {
        self.expiration = expiration
        self.chain = chain
        self.resource = resource
        self.switchChain = switchChain
        self.authNeededCallback = authNeededCallback
        self.sessionKey = sessionKey
    }
}

struct CheckAndSignAuthParams {
    var expiration: Date?
    let chain: Chain
    let resource: [String]
    let sessionCapabilities: [String]?
    let switchChain: Any?
    let url: String
}

public struct SessionKeyPair {
    let publicKey: String
    let secretKey: String
    public init(publicKey: String, secretKey: String) {
        self.publicKey = publicKey
        self.secretKey = secretKey
    }
}

public struct AuthMethod {
    let authMethodType: Int
    let accessToken: String
    public init(authMethodType: Int, accessToken: String) {
        self.authMethodType = authMethodType
        self.accessToken = accessToken
    }
    
    func toBody() -> [String: Any] {
        return [
            "authMethodType": authMethodType,
            "accessToken": accessToken
        ]
        
    }
    
}

public struct SignSessionKeyProp {
    let sessionKey: String
    
    let authMethods: [AuthMethod]
    
    let pkpPublicKey: String
    
    let expiration: Date?
    

    let resouces: [String]
    
    let chain: Chain
    
    public init(sessionKey: String, authMethods: [AuthMethod], pkpPublicKey: String, expiration: Date?, resouces: [String], chain: Chain) {
        self.sessionKey = sessionKey
        self.authMethods = authMethods
        self.pkpPublicKey = pkpPublicKey
        self.expiration = expiration
        self.resouces = resouces
        self.chain = chain
    }
}


struct SessionRequestBody {
    let sessionKey: String
    let authMethods: [AuthMethod]
    let pkpPublicKey: String
    let authSig: JsonAuthSig?
    let siweMessage: String
    
    func toBody() -> [String: Any] {
        return [
            "sessionKey" : sessionKey,
            "authMethods" : authMethods.map {
                    [
                        "authMethodType" : $0.authMethodType,
                    "accessToken" : $0.accessToken
                    ]
                },
            "pkpPublicKey" : pkpPublicKey,
//            "authSig" : authSig?.toBody() ?? "",
            "siweMessage" : siweMessage
            ]
    }
    init(sessionKey: String, authMethods: [AuthMethod], pkpPublicKey: String, authSig: JsonAuthSig?, siweMessage: String) {
        self.sessionKey = sessionKey
        self.authMethods = authMethods
        self.pkpPublicKey = pkpPublicKey
        self.authSig = authSig
        self.siweMessage = siweMessage
    }
}

public struct JsonAuthSig {
    public let sig: String
    let derivedVia: String
    let signedMessage: String
    let address: String
    public func toBody() -> [String: Any] {
        let p: [String: Any] = [
            "sig" : sig,
            "derivedVia" : derivedVia,
            "signedMessage" : signedMessage,
            "address" : address

        ]
        return p
    }
    public init(sig: String, derivedVia: String, signedMessage: String, address: String) {
        self.sig = sig
        self.derivedVia = derivedVia
        self.signedMessage = signedMessage
        self.address = address
    }
    
}

let LIT_SESSION_KEY_URI = "lit:session:"

