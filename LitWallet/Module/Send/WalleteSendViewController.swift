//
//  WalleteSendViewController.swift
//  Example
//
//  Created by leven on 2023/1/30.
//

import UIKit
import web3
import Toast_Swift
import JKCategories
import WebKit
import SafariServices
import BigInt
class WalleteSendViewController: UIViewController {

    @IBOutlet weak var transactionIdLabel: UILabel!
    
    @IBOutlet weak var toAddressInput: UITextField!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var valueInput: UITextField!
    @IBOutlet weak var addressPasteButton: UIButton!
    
    var isSending: Bool = false {
        didSet {
            if isSending {
                self.loadingView.startLoading()
            } else {
                self.loadingView.stopLoading()
            }
        }
    }
    
    lazy var loadingView = SendLoadingView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Send"
        addressPasteButton.addTarget(self, action: #selector(didClickAddressPaste), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(didClickSend), for: .touchUpInside)
        self.sendButton.layer.cornerRadius = 4
        self.sendButton.layer.masksToBounds = true
        self.sendButton.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalTo(-safeBottomHeight - 20)
            make.height.equalTo(50)
        }
        self.view.addSubview(self.loadingView)
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.balanceLabel.text = (WalletManager.shared.currentWallet?.balance ?? 0.0).str_6f
        self.transactionIdLabel.addTap { [weak self] in
            guard let self = self, (self.transactionIdLabel.text?.count ?? 0) > 10 else { return }
            let vc = SFSafariViewController(url: URL(string: "https://mumbai.polygonscan.com/tx/\(self.transactionIdLabel.text ?? "")")!)
            self.present(vc, animated: true)
        }
        
        self.view.addTap { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
        }
    }
    
    @objc func didClickAddressPaste() {
        self.toAddressInput.text = UIPasteboard.general.string
    }
    @objc func didClickSend() {
        self.view.endEditing(true)
        self.send()
    }
    
    func send() {
        guard self.isSending == false else {
            return
        }
        guard let wallet = WalletManager.shared.currentWallet, let value = self.valueInput.text?.toDouble(), value >= 0 && value <= wallet.balance, let weiValue = value.toWei else {
           return
        }
        guard let toAddress = self.toAddressInput.text, toAddress.web3.isAddress else {
            return
        }

        self.isSending = true
        let hexV = weiValue.web3.hexString ?? ""
        WalletManager.shared.send(toAddress: toAddress, value: hexV).done { [weak self] tx in
            guard let self = self else { return }
            self.isSending = false
            self.transactionIdLabel.text = tx
        }.catch { [weak self]err in
            guard let self = self else { return }
            print(err)
            self.isSending = false
            UIWindow.toast(msg: err.localizedDescription)
        }
    }

}
