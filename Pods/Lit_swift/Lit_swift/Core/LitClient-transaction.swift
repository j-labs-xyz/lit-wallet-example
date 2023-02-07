//
//  LitClient-transaction.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/27.
//

import Foundation
import PromiseKit
import web3

public extension LitClient {
    
    func sendPKPTransaction(toAddress: String, fromAddress: String, value: String, data: String, chain:Chain, publicKey: String, gasPrice: String?, gasLimit: String?) -> Promise<String> {
        
        return Promise<String> { resolver in
            let _ = signPKPTransaction(toAddress: toAddress, value: value, data: data, chain: chain, publicKey: publicKey, gasPrice: gasPrice, gasLimit: gasLimit).done { res in
                guard let res = res as? [String: Any] else { return resolver.reject(LitError.COMMON) }
                
                var transactionModel: EthereumTransaction?
                if var transaction = res["response"] as? [String: Any] {
                    transaction["from"] = fromAddress
                    let transactionData = try? JSONSerialization.data(withJSONObject: transaction)
                    do {
                        transactionModel = try JSONDecoder().decode(EthereumTransaction.self, from: transactionData ?? Data())

                    } catch {
                        resolver.reject(error)
                    }
                }
                let value = transactionModel?.value?.web3.hexString ?? ""
                let gasPrice = transactionModel?.gasPrice?.web3.hexString ?? ""

                print("From:\(transactionModel?.from?.value ?? "")")
                print("To:\(transactionModel?.to.value ?? "")")
                print("Value: \(value)")
                print("GasPrice: \(gasPrice)")

                transactionModel?.data = Data()
                transactionModel?.chainId = LIT_CHAINS[chain]!.chainId
                print("-------------")
                
                if let transactionModel = transactionModel,
                   let signature = res["signature"] as? [String: Any],
                    let r = (signature["r"] as? String)?.web3.hexData,
                   let s = (signature["s"] as? String)?.web3.hexData,
                    var recid = signature["recid"] as? Int,
                   let joinedSignature = self.joinSignature(r: (signature["r"] as? String) ?? "", v: UInt8(signature["recid"] as? Int ?? 0), s: (signature["s"] as? String) ?? "") {
                    print("R: \(r.web3.hexString)")
                    print("S: \(s.web3.hexString)")
                    print("Recid: \(recid)")
                    print("joinedSignature: \(joinedSignature)")
                    recid = recid == 1 ? 28 : 27
                    recid += (transactionModel.chainId ?? -1) * 2 + 8


                    let signedTransactionModel = SignedTransaction(transaction: transactionModel, v: recid, r: r, s: s)
                    if let transactionHex = signedTransactionModel.raw?.web3.hexString {
                        let web3 = EthereumHttpClient(url: URL(string: LIT_CHAINS[chain]?.rpcUrls.first ?? "")!)
                        Task {
                            do {
                                let data = try await web3.networkProvider.send(method: "eth_sendRawTransaction", params:  [transactionHex], receive: String.self)
                                if let resDataString = data as? String{
                                    print("Transaction: \(resDataString)")
                                    resolver.fulfill(resDataString)
                                } else {
                                    resolver.reject(LitError.unexpectedReturnValue)
                                }
                            } catch {
                                resolver.reject(error)
                            }
                        }
                    } else {
                        resolver.reject(LitError.unexpectedReturnValue)
                    }
                } else {
                    resolver.reject(LitError.unexpectedReturnValue)
                }
            }.catch { error in
                resolver.reject(error)
            }
        }

    }
    
    func signPKPTransaction(toAddress: String, value: String, data: String, chain:Chain, publicKey: String, gasPrice: String?, gasLimit: String?) -> Promise<Any> {
        guard self.isReady else {
            return Promise(error: LitError.COMMON)
        }
        
        guard let chainId = LIT_CHAINS[chain]?.chainId else {
            return Promise(error: LitError.INVALID_CHAIN)
        }
        
        guard let auth = self.auth else {
            return Promise(error: LitError.COMMON)
        }
        
        let signLitTransaction = """
        (async () => {
          const fromAddressParam = ethers.utils.computeAddress(publicKey);
          const latestNonce = await LitActions.getLatestNonce({ address: fromAddressParam, chain });
          const txParams = {
            nonce: latestNonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: toAddress,
            value: value,
            chainId: chainId,
            data: data,
          };

          LitActions.setResponse({ response: JSON.stringify(txParams) });
          
          const serializedTx = ethers.utils.serializeTransaction(txParams);
          const rlpEncodedTxn = ethers.utils.arrayify(serializedTx);
          const unsignedTxn =  ethers.utils.arrayify(ethers.utils.keccak256(rlpEncodedTxn));

          const sigShare = await LitActions.signEcdsa({ toSign: unsignedTxn, publicKey, sigName });
        })();
        """
        
        let jsParams: [String: Any] = [
            "publicKey" : publicKey,
            "chain": chain.rawValue,
            "sigName": "sessionSig",
            "chainId" :  chainId,
            "toAddress": toAddress,
            "value": value,
            "data" : data,
            "gasPrice" : gasPrice ?? "0x4A817C800",
            "gasLimit" : gasLimit ?? 5000.web3.hexString
        ]
        return self.executeJs(code: signLitTransaction, ipfsId: nil, authSig: nil, sessionSigs: auth, authMethods: nil, jsParams: jsParams)
    }
}
