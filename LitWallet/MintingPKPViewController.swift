//
//  MintingPKPViewController.swift
//  Example
//
//  Created by leven on 2023/1/9.
//

import Foundation
import UIKit
import SnapKit
import FLAnimatedImage

class MintingPKPViewController: UIViewController {
    
    lazy var litLogo: FLAnimatedImageView = {
        let logo = FLAnimatedImageView()
        if let url = Bundle.main.url(forResource: "logo_gif", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            let image = FLAnimatedImage(gifData: data)
            logo.animatedImage = image
        }
        logo.startAnimating()
        return logo
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.init(named: "close"), for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()


    let OAuthClient: LitOAuthClient
    
    lazy var mintingInfoLabel = UILabel()

    let googleTokenString: String
    let completionHandler: (String?, String?, String?) -> Void
    
    init(googleTokenString: String, completionHandler: @escaping (_ pkpEthAddress: String?, _ pkpPublicKey: String?, _ errorString: String?) -> Void) throws {
        self.googleTokenString = googleTokenString
        self.completionHandler = completionHandler
        if let relayServer = Bundle.main.object(forInfoDictionaryKey: "RELAY_SERVER") as? String {
            self.OAuthClient = LitOAuthClient(relay: relayServer)
        } else {
            throw WalletError.empty_relay_server
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        
        self.view.addSubview(self.litLogo)
        self.litLogo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
            make.size.equalTo(140)
        }
        
        mintingInfoLabel.numberOfLines = 0
        mintingInfoLabel.text = "Minting PKP..."
        mintingInfoLabel.textColor = .white
        mintingInfoLabel.textAlignment = .center
        mintingInfoLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        self.view.addSubview(mintingInfoLabel)
       
        mintingInfoLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalTo(40)
            make.top.equalTo(self.litLogo.snp.bottom).offset(10)
        }
        
        self.view.addSubview(self.closeButton)
        self.closeButton.snp.makeConstraints { make in
            make.right.equalTo(-12)
            make.top.equalTo(15)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        self.closeButton.alpha = 0
        self.closeButton.addTarget(self, action: #selector(closeVC), for: .touchUpInside)
        self.handleLoggedInToGoogle(self.googleTokenString)
    }
    
    @objc
    func closeVC() {
        self.dismiss(animated: true) {[weak self] in
            guard let `self` = self else { return }
            self.completionHandler(nil, nil, "Something is wrong")
        }
    }
    
    func showOrHideCloseButton(show: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.closeButton.alpha = show ? 1 : 0
        }
    }
    
    func handleLoggedInToGoogle(_ tokenString: String) {
        
        self.showOrHideCloseButton(show: false)
        
        self.mintingInfoLabel.text = "Minting a new Lit PKP..."
        
        OAuthClient.handleLoggedInToGoogle(tokenString) { [weak self] requestId, error in
            guard let `self` = self else { return }
            if let requestId = requestId {
                self.requestPKP(with: requestId)
            } else if let errorMsg = error {
                self.showOrHideCloseButton(show: true)
                self.mintingInfoLabel.text = errorMsg
            }
        }
    }
    
    func requestPKP(with requestId: String) {
        
        self.mintingInfoLabel.text = "Minting a new Lit PKP with request id: \(requestId)"

        OAuthClient.pollRequestUntilTerminalState(with: requestId) { [weak self] result, error in
            guard let `self` = self else { return }
            if let result = result {
                let pkpEthAddress = result["pkpEthAddress"] as? String ?? ""
                let pkpPublicKey = result["pkpPublicKey"] as? String ?? ""
                
                self.dismiss(animated: true) { [weak self] in
                    guard let `self` = self else { return }
                    self.completionHandler(pkpEthAddress, pkpPublicKey, nil)
                }
            } else if let errorMsg = error {
                self.showOrHideCloseButton(show: true)
                self.mintingInfoLabel.text = errorMsg
            }
        }
    }
}
