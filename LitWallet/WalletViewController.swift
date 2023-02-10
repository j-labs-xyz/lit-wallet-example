//
//  WalleteViewController.swift
//  Example
//
//  Created by leven on 2023/1/9.
//

import Foundation
import SnapKit
import UIKit
import GoogleSignIn
import Kingfisher
import litSwift
import web3
import SafariServices

class WalletViewController: UIViewController {

    let wallet: WalletModel
    init(wallet: WalletModel) {
        self.wallet = wallet
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var avatarImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.contentMode = .scaleAspectFill
        imageV.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        return imageV
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    
    lazy var balanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 45, weight: .heavy)
        return label
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.backgroundColor = UIColor.black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        return button
    }()
    
    lazy var receiveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Receive", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 4
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    lazy var sendView = ValueSendView()
    lazy var transactionListView = TransactionListView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.updateUI()
    }
    
    func initUI() {
        self.title = "Wallet"
        self.view.backgroundColor = .white
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.emailLabel)

        self.avatarImageView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(safeTopHeight + 44 + 30)
            make.size.equalTo(80)
        }
        self.avatarImageView.layer.cornerRadius = 40
        self.avatarImageView.layer.masksToBounds = true
        self.avatarImageView.layer.borderWidth = 0.5
        self.avatarImageView.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
            
        
        self.nameLabel.snp.makeConstraints { make in
            make.left.equalTo(self.avatarImageView.snp.right).offset(12)
            make.centerY.equalTo(self.avatarImageView).offset(-15)
        }
        self.emailLabel.snp.makeConstraints { make in
            make.left.equalTo(self.nameLabel)
            make.top.equalTo(self.nameLabel.snp.bottom).offset(6)
        }
        
        let profileLineV = UIView()
        profileLineV.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        self.view.addSubview(profileLineV)
        profileLineV.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.avatarImageView.snp.bottom).offset(20)
            make.height.equalTo(0.5)
        }
        
        let balanceTitleLabel = UILabel()
        balanceTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        balanceTitleLabel.text = "Balance:"
        
        self.view.addSubview(balanceTitleLabel)
        self.view.addSubview(self.balanceLabel)

        balanceTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(profileLineV.snp.bottom).offset(20)
            make.right.equalTo(-16)
        }
        
        self.balanceLabel.text = "0"
        self.balanceLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(balanceTitleLabel.snp.bottom).offset(10)
            make.right.equalTo(-16)
        }
        
        
         
        let bottomStackView = UIStackView()
        bottomStackView.spacing = 20
        bottomStackView.axis = .horizontal
        bottomStackView.distribution = .fillEqually
        bottomStackView.addArrangedSubview(sendButton)
        bottomStackView.addArrangedSubview(receiveButton)
        self.view.addSubview(bottomStackView)
        bottomStackView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalTo(-safeBottomHeight - 20)
            make.height.equalTo(50)
        }
        
        self.view.addSubview(self.transactionListView)
        self.transactionListView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.balanceLabel.snp.bottom)
            make.bottom.equalTo(bottomStackView.snp.top).offset(-8)
        }
        self.transactionListView.didClickTxn = { [weak self]txn in
            guard let self = self else { return }
            self.gotoPolygonScan(url: URL(string: "https://mumbai.polygonscan.com/tx/\(txn)")!)
            
        }
        
        self.transactionListView.didClickAddress = { [weak self] address in
            guard let self = self else { return }
            self.gotoPolygonScan(url: URL(string: "https://mumbai.polygonscan.com/address/\(address)")!)
        }
        
        self.view.addSubview(self.sendView)
        self.sendView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.snp.bottom)
            make.height.equalTo(50)
        }
        
        self.sendButton.addTarget(self, action: #selector(clickSend), for: .touchUpInside)
        self.receiveButton.addTarget(self, action: #selector(clickReceive), for: .touchUpInside)
        self.navigationController?.navigationBar.tintColor = .black
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "logout")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action:  #selector(logout)), UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)]
        self.refreshData()
    }

    
    func refreshData() {
        if self.isViewLoaded && self.view.window != nil {
            self.retriveBalance()
            self.transactionListView.address = WalletManager.shared.currentWallet?.address.lowercased()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            self.refreshData()
        }
    }
    
    func updateUI() {
        self.avatarImageView.kf.setImage(with: URL(string:  self.wallet.userInfo?.avatar ?? "")!)
        self.nameLabel.text = self.wallet.userInfo?.name
        self.emailLabel.text = self.wallet.userInfo?.email
    }
    
    @objc func logout() {
        let alertVC = UIAlertController(title: "Sure to log out?", message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertVC.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            WalletManager.shared.logout()
            if let window =  (UIApplication.shared.delegate as? AppDelegate)?.window {
                window.rootViewController = SignInViewController()
            }
        }))
        self.present(alertVC, animated: true)
    }
    
    @objc
    func clickSend() {
        let vc = WalleteSendViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @objc
    func clickReceive() {
        self.navigationController?.pushViewController(WalletAddressViewController(), animated: true)
    }
    
    func gotoPolygonScan(url: URL) {
        let vc = SFSafariViewController(url: url)
        self.present(vc, animated: true)
    }
    
    func retriveBalance() {
        if let balance = WalletManager.shared.currentWallet?.balance {
            self.balanceLabel.text = balance.str_6f
        }
        let _ = WalletManager.shared.getBalance().done { [weak self]balance in
            guard let self = self else { return }
            self.balanceLabel.text = (balance).str_6f
        }
    }
    
}
