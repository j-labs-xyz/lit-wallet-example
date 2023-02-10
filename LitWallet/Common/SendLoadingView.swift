//
//  SendLoadingView.swift
//  Example
//
//  Created by leven on 2023/1/31.
//

import Foundation
import FLAnimatedImage

class SendLoadingView: UIView {
    lazy var litLogo: FLAnimatedImageView = {
        let logo = FLAnimatedImageView()
        if let url = Bundle.main.url(forResource: "logo_gif", withExtension: "gif"), let data = try? Data(contentsOf: url) {
            let image = FLAnimatedImage(gifData: data)
            logo.animatedImage = image
        }
        logo.startAnimating()
        return logo
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0)
        self.addSubview(self.litLogo)
        self.litLogo.alpha = 0
        self.isUserInteractionEnabled = false
        litLogo.layer.cornerRadius = 8
        litLogo.layer.masksToBounds = true
        self.litLogo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
            make.size.equalTo(140)
        }
    }

    func startLoading() {
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.24)
            self.litLogo.alpha = 1
        }
        self.isUserInteractionEnabled = true
    }
    
    func stopLoading() {
        self.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, delay: 0) {
            self.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            self.litLogo.alpha = 0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
