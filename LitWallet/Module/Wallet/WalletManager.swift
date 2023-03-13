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
import GoogleAPIClientForREST
import GoogleSignIn

class WalletManager {
    static let shared: WalletManager = WalletManager()

    lazy var litClient: LitClient = LitClient()

    lazy var web3 = EthereumHttpClient(url: URL(string: LIT_CHAINS[.mumbai]?.rpcUrls.first ?? "")!)

    lazy var driveService = GTLRDriveService()

    private var cachedWallets: [WalletModel] = []
    
    var currentWallet: WalletModel?
    
    init() {
        let _ = self.litClient.connect().done {
            print("Lit connected!")
        }
//        LitSwift.enableLog = true
    }
    
    func initCurrentWallet(_ completion: @escaping () -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn() { user, error in
            if let user = GIDSignIn.sharedInstance.currentUser {
                WalletManager.shared.driveService.authorizer = user.fetcherAuthorizer
                WalletManager.shared.loadAllWalletFromDriver { _, _, _ in
                    self.currentWallet = self.getCurrentWallet()
                    completion()
                }
            } else {
               completion()
            }
        }
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

private let walletDriveName = "lit_wallets"

private let curWalletLocalKey = "cur_local_lit_wallets"

extension WalletManager {
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: curWalletLocalKey)
    }

    func saveCurWallet() {
        if let currentWallet = currentWallet {
            saveWallet(currentWallet) { _, _ in
                
            }
            UserDefaults.standard.set(currentWallet.userInfo?.email ?? "", forKey: curWalletLocalKey)
        }
    }
    
    func getCurrentWallet() -> WalletModel? {
        let curWalletEmail = UserDefaults.standard.string(forKey: curWalletLocalKey)
        return getAllWalletes().first(where: { $0.userInfo?.email == curWalletEmail })
    }
    
    func getWallet(by email: String) -> WalletModel? {
        return getAllWalletes().first(where: { $0.userInfo?.email == email })
    }
    
    func getAllWalletes() -> [WalletModel] {
        return self.cachedWallets
    }
}

extension WalletManager {
    
    func saveWallet(_ wallet: WalletModel, completionHandler: @escaping (GTLRDrive_File?, Error?) -> Void) {
        loadAllWalletFromDriver { [weak self] wallets,file,error in
            guard let self = self else { return }
            if let error = error {
                completionHandler(nil, error)
            } else if var wallets = wallets {
                wallets.removeAll(where: { $0.userInfo?.email == wallet.userInfo?.email})
                wallets.append(wallet)
                self.addWallets(wallets, file: file, completionHandler: completionHandler)
            } else {
                self.addWallets([wallet], file: file, completionHandler: completionHandler)
            }
        }
    }
    
    func loadWallet(_ email: String,  completionHandler: @escaping (WalletModel?, Error?) -> Void) {
        loadAllWalletFromDriver { wallets, _, error in
            completionHandler(wallets?.first(where: { $0.userInfo?.email == email}), error)
        }
    }
    
    func loadAllWalletFromDriver(_ completionHandler: @escaping ([WalletModel]?, GTLRDrive_File?, Error?) -> Void) {
        let q = "name = '\(walletDriveName)'"
        let query = GTLRDriveQuery_FilesList.query()
        query.q = q
        query.pageSize = 10
        query.fields =  "files(id,name,mimeType,modifiedTime),nextPageToken"
        self.driveService.executeQuery(query) { [weak self]ticket, res, error in
            guard let self = self else { return }
            if let error = error {
                completionHandler(nil, nil, error)
            } else {
                if let files = res as? GTLRDrive_FileList, let target = files.files?.first(where: { $0.name == walletDriveName}) {
                    self.loadWalletFileContent(target) { wallets, error in
                        self.cachedWallets = wallets ?? []
                        completionHandler(wallets, target, error)
                    }
                } else {
                    self.cachedWallets = []
                    completionHandler(nil, nil, nil)
                }
            }
        }
    }
    
    
    func addWallets(_ wallets: [WalletModel], file: GTLRDrive_File?, completionHandler: @escaping (GTLRDrive_File?, Error?) -> Void) {
        if let content = wallets.toJSONString(prettyPrint: true) {
            let metaData = GTLRDrive_File()
            metaData.name = walletDriveName
            metaData.mimeType = "text/plain"
            
            let params = GTLRUploadParameters(data: content.data(using: .utf8) ?? Data(), mimeType: "text/plain")
            var query: GTLRDriveQuery!
            if let file = file {
                query = GTLRDriveQuery_FilesUpdate.query(withObject: metaData, fileId: file.identifier ?? "", uploadParameters: params)
            } else {
                query = GTLRDriveQuery_FilesCreate.query(withObject: metaData, uploadParameters: params)
            }
            self.driveService.executeQuery(query) { ticket, res, error in
                if let error = error {
                    completionHandler(nil, error)
                } else if let file = res as? GTLRDrive_File {
                    completionHandler(file, nil)
                } else {
                    completionHandler(nil, WalletError.failed_save_drive)
                }
            }
        }
    }
    
    func loadWalletFileContent(_ file: GTLRDrive_File, completionHandler: @escaping ([WalletModel]?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: file.identifier ?? "")
        self.driveService.executeQuery(query) { ticket, res, error in
            if let error = error {
                completionHandler(nil, error)
            } else {
                if let contentData = res as? GTLRDataObject, let jsonString = String.init(data: contentData.data, encoding: .utf8), let models = [WalletModel].deserialize(from: jsonString)?.compactMap({ $0 }) {
                    completionHandler(models, nil)
                } else {
                    completionHandler(nil, WalletError.empty_drive_wallet)

                }
            }
        }
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


