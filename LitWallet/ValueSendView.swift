//
//  ValueSendView.swift
//  Example
//
//  Created by leven on 2023/1/30.
//

import UIKit
import SnapKit
class ValueSendView: UIView {
    
    lazy var contentView = UIView()
    
    lazy var inputField = UITextField()

    var clickSend: ((Double) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let sendButton = UIButton(type: .custom)
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        sendButton.backgroundColor = UIColor.black
        sendButton.layer.cornerRadius = 8
        sendButton.layer.masksToBounds = true
        sendButton.addTarget(self, action: #selector(didClickSend), for: .touchUpInside)
        self.addSubview(sendButton)
        
        sendButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 38))
        }
        inputField.borderStyle = .none
        inputField.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        inputField.placeholder = "Input value"
        inputField.keyboardType = .numberPad
        self.addSubview(inputField)
        inputField.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalTo(sendButton.snp.right).offset(-12)
            make.height.equalTo(36)
        }
        
    }
    
    @objc func didClickSend() {
        if let num = NumberFormatter().number(from: self.inputField.text ?? "0") {
            let value = num.doubleValue
            if value >= 0 {
                self.clickSend?(value)
                self.inputField.resignFirstResponder()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
}
