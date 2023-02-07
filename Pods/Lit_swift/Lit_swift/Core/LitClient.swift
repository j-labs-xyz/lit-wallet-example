//
//  LitSwiftSDK.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/4.
//

import Foundation
import PromiseKit
import TweetNacl
import web3
import Libecdsa_swift
import secp256k1
public class LitClient {
    
    let config: LitNodeClientConfig
    
    var connectedNodes: Set<String> = Set<String>()
    
    let serverKeys: [String: NodeCommandServerKeysResponse] = [:]
    
    var ready: Bool = false
    
    public var isReady: Bool {
        return ready
    }
    
    var subnetPubKey: String?
    
    var networkPubKey: String?
    
    var networkPubKeySet: String?
    
    
    var auth: [String: Any]?
    
    
    public func updateAuth(_ auth: [String: Any]) {
        self.auth = auth
    }
    
    public init(config: LitNodeClientConfig = LitNodeClientConfig()) {
        self.config = config
        
    }
    /// Connect to the LIT nodes.
    /// - Returns: A promise that resolves when the nodes are connected.
    public func connect() -> Promise<Void>  {
        // -- handshake with each node
        var urlGenerator = self.config.bootstrapUrls.makeIterator()
        let allPromises = AnyIterator<Promise<NodeCommandServerKeysResponse>> {
            guard let url = urlGenerator.next() else {
                return nil
            }
            return self.handshakeWithNode(url).then { response in
                self.connectedNodes.insert(url)
                return Promise<NodeCommandServerKeysResponse>.value(response)
            }
        }
        
        return when(fulfilled: allPromises, concurrently: 4).done { [weak self] nodeResponses in
            guard let `self` = self else { return }
            self.subnetPubKey = nodeResponses.map { $0.subnetPublicKey }.mostCommonString
            self.networkPubKey = nodeResponses.map { $0.networkPublicKey }.mostCommonString
            self.networkPubKeySet = nodeResponses.map { $0.networkPublicKeySet }.mostCommonString
            self.ready = true
        }
    }
    
    public func getSessionSigs(_ params: GetSessionSigsProps) -> Promise<Any> {
        var sessionKey: SessionKeyPair
        do {
            sessionKey = try getSessionKey(params.sessionKey)
        } catch {
            return Promise(error: error)
        }
    
        let sessionKeyUrl = getSessionKeyUri(sessionKey.publicKey)
        
        guard let capabilities = getSessionCapabilities(params.sessionCapabilities, resources: params.resource) else {
            return Promise(error: LitError.INIT_KEYPAIR_ERROR)
        }
        
        let expiration = params.expiration ?? getExpirationDate(1000 * 60 * 60 * 24)
        return getWalletSig(chain: params.chain, capabilities: capabilities ,switchChain: params.switchChain, expiration: expiration, sessionKeyUri: sessionKeyUrl, authNeededCallback: params.authNeededCallback).then { [weak self]authSig in
            guard let self = self else { return Promise<Any>(error: LitError.COMMON)}
            let sessionExpiration = self.getExpirationString(60 * 60 * 24)
            let signingTemplate: [String: Any] = [
                "sessionKey": sessionKey.publicKey,
                "resources": params.resource,
                "capabilities" : [authSig.toBody()],
                "issuedAt": self.getExpirationString(0),
                "expiration": sessionExpiration
            ]
            
            var signatures: [String: Any] = [:]
            do {
                try self.connectedNodes.forEach { node in
                    var toSign = signingTemplate
                    toSign["nodeAddress"] = node
                    
                    let keyData = sessionKey.secretKey
                    let messageData = (try? JSONSerialization.data(withJSONObject: toSign)) ?? Data()
                    
                    let signature = try NaclSign.signDetached(message: messageData, secretKey: keyData.web3.hexData ?? Data()).web3.hexString.web3.noHexPrefix
                    
                    signatures[node] = [
                        "sig": signature,
                        "derivedVia" : "litSessionSignViaNacl",
                        "signedMessage" : String(data: messageData, encoding: .utf8),
                        "address" : sessionKey.publicKey,
                        "algo": "ed25519"
                    ]
                }
            } catch {
                return Promise<Any>.init(error: error)
            }
            
            return Promise<Any>.value(signatures)
        }
    }
    
    
    public func getSessionKey(_ supposedSessionKey: String?) throws -> SessionKeyPair {
        let keyPair = try NaclSign.KeyPair.keyPair()
        if let publicKey = keyPair.publicKey.toBase16String(), let secretKey = keyPair.secretKey.toBase16String() {
            return SessionKeyPair(publicKey: publicKey, secretKey: secretKey)
        }
        throw LitError.INIT_KEYPAIR_ERROR
    }
    

    
   public func signSessionKey(_ params: SignSessionKeyProp) -> Promise<JsonAuthSig> {
        if self.ready == false {
            return Promise(error: LitError.LIT_NODE_CLIENT_NOT_READY_ERROR)
        }
        
      
       if let addressKey = self.computeAddress(publicKey: params.pkpPublicKey) {
           let ethereumAddress = EthereumAddress(addressKey)
           let expiration = (params.expiration ?? getExpirationDate(24 * 60 * 60 * 1000))
           let nonce = String.random(minimumLength: 96, maximumLength: 128)
           var siweMessage: SiweMessage!
           do {
               siweMessage = try SiweMessage(domain: "localhost",
                                             address: ethereumAddress.toChecksumAddress(),
                                             statement: "Lit Protocol PKP session signature",
                                             uri: URL(string: params.sessionKey)!,
                                             version: "1",
                                             chainId: 1,
                                             nonce: nonce,
                                             issuedAt: Date(),
                                             expirationTime: expiration,
                                             notBefore: nil,
                                             requestId: nil,
                                             resources: params.resouces.compactMap({ URL(string: $0) }))
               
           } catch {
               return Promise(error: error)
           }
           let siweMessageString = siweMessage.description
           
           let reqBody = SessionRequestBody(sessionKey: params.sessionKey, authMethods: params.authMethods, pkpPublicKey: params.pkpPublicKey, authSig: nil, siweMessage: siweMessageString)
           
           
           var urlGenerator = self.connectedNodes.makeIterator()
           let allPromises = AnyIterator<Promise<NodeShareResponse>> {
               guard let url = urlGenerator.next() else {
                   return nil
               }
               return self.getSignSessionKeyShares(url, params: reqBody)
           }
           return Promise<JsonAuthSig> { resolver in
              let _ = when(fulfilled: allPromises, concurrently: 4).done ({ [weak self] nodeResponses in
                   guard let `self` = self else {
                       return resolver.reject(LitError.COMMON)
                   }
                   
                   let signedDataList = nodeResponses.compactMap( { $0.signedData?.sessionSig })
                   
                   let sigType =  signedDataList.map { $0.sigType }.mostCommonString
                   let siweMessage =  signedDataList.compactMap { $0.siweMessage }.mostCommonString ?? ""

                   if sigType == SigTYpe.BLS.rawValue {
                       let _ = self.combineBlsShares(shares: signedDataList, networkPubKeySet: self.networkPubKeySet ?? "")
                   } else if sigType == SigTYpe.ECDSA.rawValue {
                       let res = self.combineEcdsaShares(shares: signedDataList)
                       if let r = res["r"] as? String, let s = res["s"] as? String, let recid = res["recid"] as? UInt8, let signature = self.joinSignature(r: r, v: recid, s: s) {
                           let jsonAuthSig = JsonAuthSig(sig: signature, derivedVia: "web3.eth.personal.sign via Lit PKP", signedMessage: siweMessage, address: ethereumAddress.value)
                           return resolver.fulfill(jsonAuthSig)
                       }
                   }
                   return resolver.reject(LitError.COMMON)
              }).catch { error in
                  return resolver.reject(error)
              }
           }
       }
        
        return Promise(error: LitError.INVALID_PUBLIC_KEY)
    }
    
    func combineBlsShares(shares: [NodeShare], networkPubKeySet: String) -> [String: Any] {
        
        return [:]
    }
    
    func combineEcdsaShares(shares: [NodeShare]) -> [String: Any] {
        let r_x = shares[0].localX
        let r_y = shares[0].localY
        let publicKey = shares[0].publicKey
        let dataSigned = "0x" + shares[0].dataSigned
        let validShares = shares.map { $0.signatureShare }
        let validSharesJson = try? validShares.toJsonString()
        if let res = combine_signature(r_x, ry: r_y, shares: validSharesJson ?? "") {
            return res
        }
        return [:]
    }
    
    func getSessionSignatures(_ signedData: [NodeShareResponse]) -> [String: Any] {
    
        return [:]
    }
    
    func getWalletSig(chain: Chain,
                      capabilities:
    [String] = [], switchChain: Bool,
                      expiration: Date?,
                      sessionKeyUri: String,
                      authNeededCallback: AuthNeededCallback?) -> Promise<JsonAuthSig> {
        if let authNeededCallback = authNeededCallback {
            var jsonString: String
            do {
                jsonString = try capabilities.toBase64String()
            } catch {
                return Promise(error: error)
            }
            return authNeededCallback(chain, ["urn:recap:lit:session:" + jsonString], switchChain, expiration ?? getExpirationDate(24 * 60 * 60 * 1000), sessionKeyUri)
        } else {
            return checkAndSignAuthMessage(CheckAndSignAuthParams(chain: chain, resource: capabilities, sessionCapabilities:capabilities, switchChain: switchChain, url: sessionKeyUri))
        }
    }
    
    func checkNeedToResignSessionKey(siweMessage: SiweMessage, walletSignature: String, sessionKeyUri: String, resources: [String], sessionCapabilities: [String]) -> Promise<Bool> {
        var needToResign = false
        
        
    
        
        
        
        return .value(needToResign)
    }

    
    func checkAndSignAuthMessage(_ signProps: CheckAndSignAuthParams) -> Promise<JsonAuthSig> {
        var signProps = signProps
        let chainInfo = ALL_LIT_CHAINS[signProps.chain]
        
        if chainInfo == nil {
            return Promise.init(error: LitError.UNSUPPORTED_CHAIN_EXCEPTION(signProps.chain.rawValue))
        }
        
        if signProps.expiration == nil {
            signProps.expiration = getExpirationDate(1000 * 60 * 60 * 24 * 7)
        }
        if chainInfo?.vmType == .EVM {
            return checkAndSignEVMAuthMessage()
        } else if chainInfo?.vmType == .CVM {
            return checkAndSignCosmosAuthMessage()
        } else if chainInfo?.vmType == .SVM {
            return checkAndSignSolAuthMessage()
        } else {
            return Promise.init(error: LitError.UNSUPPORTED_CHAIN_EXCEPTION(signProps.chain.rawValue))
        }
    }
    
    func checkAndSignEVMAuthMessage() -> Promise<JsonAuthSig> {
        return .value(JsonAuthSig(sig: "", derivedVia: "", signedMessage: "", address: ""))
    }
    
    func checkAndSignSolAuthMessage() -> Promise<JsonAuthSig> {
        return .value(JsonAuthSig(sig: "", derivedVia: "", signedMessage: "", address: ""))
    }
    
    func checkAndSignCosmosAuthMessage() -> Promise<JsonAuthSig> {
        return .value(JsonAuthSig(sig: "", derivedVia: "", signedMessage: "", address: ""))
    }
    
    func handshakeWithNode(_ url: String) -> Promise<NodeCommandServerKeysResponse> {
        let urlWithPath = "\(url)/web/handshake"
        let parameters = ["clientPublicKey" : "test"]
        return fetch(urlWithPath, parameters: parameters, decodeType: NodeCommandServerKeysResponse.self)
    }
    
    func getSignSessionKeyShares(_ url: String,
                                 params: SessionRequestBody) -> Promise<NodeShareResponse> {
        let urlWithPath = url + "/web/sign_session_key"
        let parameters = params.toBody()
        
        return fetch(urlWithPath, parameters: parameters, decodeType: NodeShareResponse.self)
    }

}

 public extension LitClient {
    func getSessionKeyUri(_ publicKey: String) -> String {
        return LIT_SESSION_KEY_URI + publicKey
    }
    
    func getSessionCapabilities(_ capabilities: [String]?, resources: [String]) -> [String]? {
        var capabilities = capabilities ?? []
        if capabilities.count == 0 {
            capabilities = resources.map({
                let (protocolType, _) = parseResource($0)
                return "\(protocolType)Capability://*"
            })
        }
        return capabilities
        
    }
    
    func parseResource(_ resource: String) -> (protocolType: String, resourceId: String) {
        return (resource.components(separatedBy: "://").first ?? "", resource.components(separatedBy: "://").last ?? "")
    }
    
    func getExpirationString(_ appendSeconds: TimeInterval) -> String {
        let date = Date(timeIntervalSinceNow: appendSeconds)
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    func getExpirationDate(_ appendSeconds: TimeInterval) -> Date {
        let date = Date(timeIntervalSinceNow: appendSeconds)
        return date
    }
    
     func computeAddress(publicKey: String) -> String? {
         var pkpPublicKeyData = publicKey.web3.hexData
         pkpPublicKeyData = pkpPublicKeyData?.dropFirst()
         if let pkpPublicKeyHash = pkpPublicKeyData?.web3.keccak256 {
             let address = pkpPublicKeyHash.subdata(in: 12..<pkpPublicKeyHash.count)
             return address.web3.hexString
         }
         return nil
     }
     
     func joinSignature(r: String, v: UInt8, s: String) -> String? {
         guard  let rData = r.web3.hexData,  let sData = s.web3.hexData else {
             return nil
         }
         var signature = rData
         signature.append(sData)
         if v == 1 {
             signature.append(contentsOf: [0x1c])
         } else {
             signature.append(contentsOf: [0x1b])
         }
         return signature.web3.hexString
     }
    
}
