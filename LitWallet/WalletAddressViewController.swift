//
//  WalletAddressViewController.swift
//  Example
//
//  Created by leven on 2023/1/30.
//

import UIKit
import SafariServices

class WalletAddressViewController: UIViewController {
    @IBOutlet weak var faucetButton: UIButton!
    @IBOutlet weak var qrIcon: UIImageView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Wallet Address"
        if let address = WalletManager.shared.currentWallet?.address, let image = UIImage.createQRCode(size: 300, dataStr: address) {
            self.qrIcon.image = image
            self.addressLabel.text = address
        }
        
        self.copyButton.addTarget(self, action: #selector(didClickCopy), for: .touchUpInside)
        self.faucetButton.addTarget(self, action: #selector(didClickFaucet), for: .touchUpInside)

    }
    
    @objc func didClickCopy() {
        UIPasteboard.general.string = WalletManager.shared.currentWallet?.address ?? ""
    }
    
    @objc func didClickFaucet() {
        let vc = SFSafariViewController(url: URL(string: "https://faucet.polygon.technology/")!)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
