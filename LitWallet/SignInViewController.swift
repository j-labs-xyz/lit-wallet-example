//
//  SignInViewController.swift
//  Example
//
//  Created by leven on 2023/1/9.
//

import Foundation
import UIKit
import SnapKit
import FLAnimatedImage
import GoogleSignIn
import litSwift
import PromiseKit
class SignInViewController: UIViewController {

    lazy var googleLogo: UIImageView = {
        let logo = UIImageView()
        logo.image = UIImage(named: "google_logo")
        return logo
    }()
    
    lazy var litLogo: UIImageView = {
        let logo = UIImageView()
        logo.image = UIImage(named: "lit_logo")
        return logo
    }()
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
        
    }()
    lazy var siginButton = UIButton(type: .custom)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
    }
    
    func initUI() {
        self.view.backgroundColor = UIColor.black

       
        let transformIcon = UIImageView()
        transformIcon.image = UIImage.init(named: "transform")
        transformIcon.contentMode = .scaleAspectFit
        self.view.addSubview(transformIcon)
        transformIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 40))
        }
        
        self.view.addSubview(self.litLogo)
        self.litLogo.snp.makeConstraints { make in
            make.centerY.equalTo(transformIcon)
            make.right.equalTo(transformIcon.snp.left).offset(0)
            make.size.equalTo(160)
        }
        
        self.view.addSubview(self.googleLogo)
        self.googleLogo.snp.makeConstraints { make in
            make.centerY.equalTo(transformIcon)
            make.left.equalTo(transformIcon.snp.right).offset(30)
            make.size.equalTo(90)
        }
        
        siginButton.setTitle("Sign   in", for: .normal)
        siginButton.setTitleColor(UIColor.white, for: .normal)
        siginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        siginButton.addTarget(self, action: #selector(gotoSignin), for: .touchUpInside)
        self.view.addSubview(siginButton)
        siginButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalTo(-safeBottomHeight - 20)
            make.height.equalTo(50)
        }
        siginButton.layer.borderWidth = 1
        siginButton.layer.borderColor = UIColor.white.cgColor
        siginButton.layer.cornerRadius = 4
        
        self.view.addSubview(self.infoLabel)
        self.infoLabel.snp.makeConstraints { make in
            make.left.right.equalTo(siginButton)
            make.top.equalTo(self.googleLogo.snp.bottom).offset(0)
            make.bottom.equalTo(siginButton.snp.top).offset(-20)
        }
    }
    
    var tokenString: String = ""
    var wallet: WalletModel = WalletModel()
    
    @objc
    func gotoSignin() {
        self.infoLabel.text = "Signing in with Google OAuth..."
        self.siginButton.isHidden = true
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] res, err in
            guard let `self` = self else { return }
            if let profile = res?.user.profile, let tokenString = res?.user.idToken?.tokenString {
                print(tokenString)
                self.tokenString = tokenString
                if let wallet = WalletManager.shared.loadWallet(by: profile.email) {
                    self.infoLabel.text = "Loading the existing Lit PKP..."
                    self.wallet = wallet
                    self.didMintPKP(pkpEthAddress: self.wallet.address, pkpPublicKey: self.wallet.publicKey, profile: profile)
                } else {
                    self.infoLabel.text = "Starting to mint a new Lit PKP..."
                    let userInfo = UserInfo()
                    userInfo.avatar = profile.imageURL(withDimension: 300)?.absoluteString
                    userInfo.name = profile.name
                    userInfo.email = profile.email
                    self.wallet.userInfo = userInfo
    
                    let vc = try! MintingPKPViewController(googleTokenString: tokenString) { pkpEthAddress, pkpPublicKey, errorString in
                        if let pkpEthAddress = pkpEthAddress, let pkpPublicKey = pkpPublicKey {
                            self.didMintPKP(pkpEthAddress: pkpEthAddress, pkpPublicKey: pkpPublicKey, profile: profile)
                        } else {
                            self.siginButton.isHidden = false
                        }
                    }
                    vc.isModalInPresentation = true
                    self.present(vc, animated: true)
                }
                
            } else {
                self.siginButton.isHidden = false
            }
        }
    }
    
    var litClient: LitClient {
        return WalletManager.shared.litClient
    }

    func getSignature() {
        let authNeededCallback: AuthNeededCallback = { [weak self]chain, resources, switchChain, expiration, url in
<<<<<<< HEAD
            guard let self = self else { return Promise(error: LitError.COMMON) }
            let props = SignSessionKeyProp(
                sessionKey: url,
                authMethods: [AuthMethod(authMethodType: 6, accessToken: self.tokenString)],
                pkpPublicKey: self.wallet.publicKey,
                expiration: expiration,
                resouces: resources ?? [],
                chain: chain)
=======
            guard let self = self else {
                return Promise(error: LitError.clientDeinit)
            }
            let props = SignSessionKeyProp(sessionKey: url, authMethods: [AuthMethod(authMethodType: 6, accessToken: self.tokenString)], pkpPublicKey: self.wallet.publicKey, expiration: expiration, resouces: resources ?? [], chain: chain)
>>>>>>> f79fb82 (- lit update)
            return self.litClient.signSessionKey(props)
        }
        //https://developer.litprotocol.com/SDK/Explanation/WalletSigs/sessionSigs
        let props = GetSessionSigsProps(expiration: Date(timeIntervalSinceNow: 1000 * 60 * 60 * 24),
                                        chain: .mumbai,
                                        resource: [
                                            "litEncryptionCondition://*",
                                            "litSigningCondition://*",
                                            "litPKP://*",
                                            "litRLI://*",
                                            "litAction://*"
                                        ],
                                        switchChain: false,
                                        authNeededCallback: authNeededCallback)
        self.infoLabel.text = """
        pkpPublicKey: \(self.wallet.publicKey)
        
        pkpEthAddress: \(self.wallet.address)
        
        Getting Signature...
        """
        
        if self.litClient.isReady == false {
            let _ = self.litClient.connect().then {
                return self.litClient.getSessionSigs(props)
            }.done { [weak self] res in
                guard let self = self else { return }
                self.wallet.sessionSigs = res
                self.gotoWallet()
                self.infoLabel.text =  """
    pkpPublicKey: \(self.wallet.publicKey)
    pkpEthAddress: \(self.wallet.address)
    Signature: \(res)
    """
            }.catch { [weak self]err in
                guard let self = self else { return }
                UIWindow.toast(msg: err.localizedDescription)
                self.siginButton.isHidden = false
            }
        } else {
            let _ = self.litClient.getSessionSigs(props).done { [weak self] res in
                guard let self = self else { return }
                self.wallet.sessionSigs = res
                self.gotoWallet()
                self.infoLabel.text =  """
    pkpPublicKey: \(self.wallet.publicKey)
    pkpEthAddress: \(self.wallet.address)
    Signature: \(res)
    """
            }.catch {  [weak self]err in
                guard let self = self else { return }
                UIWindow.toast(msg: err.localizedDescription)
                self.siginButton.isHidden = false
            }
        }
        
      
    }
    
    func didMintPKP(pkpEthAddress: String, pkpPublicKey: String, profile: GIDProfileData) {
        self.wallet.publicKey = pkpPublicKey
        self.wallet.address = pkpEthAddress
        self.infoLabel.text = """
        pkpPublicKey: \(pkpPublicKey)
        
        pkpEthAddress: \(pkpEthAddress)
        
        Getting Signature...
        """
        self.getSignature()


    }
    
    func gotoWallet() {
        WalletManager.shared.currentWallet = self.wallet
        let vc = WalletViewController(wallet: self.wallet)
        if let window =  (UIApplication.shared.delegate as? AppDelegate)?.window {
            window.rootViewController = UINavigationController(rootViewController: vc)
        }
    }
}
