//
//  SplashViewController.swift
//  Example
//
//  Created by leven on 2023/1/5.
//

import Foundation
import UIKit
import SnapKit
import FLAnimatedImage
class SplashViewController: UIViewController {
    
    lazy var logoImageView: FLAnimatedImageView = {
        let logo = FLAnimatedImageView()
        if let url = Bundle.main.url(forResource: "logo_gif", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            let image = FLAnimatedImage(gifData: data)
            logo.animatedImage = image
        }
        return logo
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
        logoImageView.loopCompletionBlock = { [weak self] _ in
            guard let `self` = self else { return }
            self.gotoHomeVC()
            
        }
        logoImageView.startAnimating()
    }
    var needRefresh: Bool = false
    func gotoHomeVC() {
        if let window =  (UIApplication.shared.delegate as? AppDelegate)?.window {
            if needRefresh || WalletManager.shared.currentWallet == nil {
                window.rootViewController = SignInViewController()
            } else if let wallet = WalletManager.shared.currentWallet {
                let vc = WalletViewController(wallet: wallet)
                window.rootViewController = UINavigationController(rootViewController: vc)
            }
        }
    }
    
}
