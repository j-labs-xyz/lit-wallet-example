//
//  WalletManager.swift
//  Example
//
//  Created by leven on 2023/1/30.
//

import Foundation
import HandyJSON
import litSwift
import web3
import PromiseKit
import KeychainSwift
class WalletManager {
    static let shared: WalletManager = WalletManager()

    lazy var litClient: LitClient = LitClient()

    lazy var web3 = EthereumHttpClient(url: URL(string: LIT_CHAINS[.mumbai]?.rpcUrls.first ?? "")!)

    var currentWallet: WalletModel? {
        didSet {
            if let _ = currentWallet {
                self.saveCurWallet()
            }
        }
    }
    
    init() {
        initWallet()
        let _ = self.litClient.connect().done {
            print("Lit connected!")
        }
    }
    
    func initWallet() {
        self.currentWallet = self.loadCurrentWallet()
    }

}

extension WalletManager {
    func getBalance() -> Promise<Double> {
        return Promise<Double> { resolver in
            if let currentWallet = currentWallet {
                WalletManager.shared.web3.eth_getBalance(address: EthereumAddress(currentWallet.address), block: EthereumBlock.Latest) { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        DispatchQueue.main.async {
                            resolver.reject(error)
                        }
                    case .success(let res):
                        let value = (UInt64(res.web3.hexString.web3.noHexPrefix, radix: 16) ?? 0).toEth
                        print("Value: \(value)")
                        print("Hex: \(res.web3.hexString)")
                        currentWallet.balance = value
                        self.currentWallet = currentWallet
                        self.saveCurWallet()
                        DispatchQueue.main.async {
                            resolver.fulfill(value)
                        }
                    }
                }
            } else {
                resolver.reject(LitError.clientDeinit)
            }
        }
    }
    func send(toAddress: String, value: String) -> Promise<String> {
        return self.litClient.sendPKPTransaction(toAddress: toAddress, fromAddress: currentWallet!.address, value: value, data: "0x", chain: .mumbai, auth: currentWallet!.sessionSigs, publicKey: currentWallet!.publicKey, gasPrice: "0x2e90edd000", gasLimit: "0x7530")
    }
}

private let walletLocalKey = "local_lit_wallets"
private let curWalletLocalKey = "cur_local_lit_wallets"

extension WalletManager {
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: curWalletLocalKey)
    }
    
    func removeCurWallet() {
        let wallets = _removeCurWallet()
        KeychainSwift().set(wallets.toJSONString() ?? "", forKey: walletLocalKey)
    }
    
    func _removeCurWallet() -> [WalletModel] {
        var wallets: [WalletModel] = loadAllWalletes()
        wallets.removeAll(where: { ($0.userInfo?.email) == (currentWallet?.userInfo?.email ?? "") })
        return wallets
    }

    func saveCurWallet() {
        var wallets: [WalletModel] = _removeCurWallet()
        if let currentWallet = currentWallet {
            wallets.append(currentWallet)
            UserDefaults.standard.set(currentWallet.userInfo?.email ?? "", forKey: curWalletLocalKey)
        }
        KeychainSwift().set(wallets.toJSONString() ?? "", forKey: walletLocalKey)
    }
    
    func loadCurrentWallet() -> WalletModel? {
        let curWalletEmail = UserDefaults.standard.string(forKey: curWalletLocalKey)
        return loadAllWalletes().first(where: { $0.userInfo?.email == curWalletEmail })
    }
    
    func loadWallet(by email: String) -> WalletModel? {
        return loadAllWalletes().first(where: { $0.userInfo?.email == email })
    }
    
    func loadAllWalletes() -> [WalletModel] {
        if let jsonString = KeychainSwift().get(walletLocalKey){
            return [WalletModel].deserialize(from: jsonString)?.compactMap { $0 } ?? []
        }
        return []
    }
}


class WalletModel: HandyJSON {
    var userInfo: UserInfo?
    var balance: Double = 0
    var address: String = ""
    var publicKey: String = ""
    var sessionSigs: [String: Any] = [:]
    required init() {}
}



class UserInfo: HandyJSON {
    var avatar: String?
    var name: String = ""
    var email: String = ""
    required init() {}
}


