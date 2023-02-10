//
//  TransactionTableViewCell.swift
//  LitWallet
//
//  Created by leven on 2023/2/9.
//

import UIKit
import SwifterSwift

class TransactionTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var fromAddress: UIButton!
    @IBOutlet weak var txnLabel: UIButton!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    var didClickTxn: (() -> Void)?
    var didClickAddress: (() -> Void)?

    var mineAddress: String = ""
    var transaction: TransactionListResponse.Transaction? {
        didSet {
            if let transaction = transaction {
                typeLabel.text = transaction.from == mineAddress ? "To:" : "From:"
                fromAddress.setTitle(transaction.from == mineAddress ? transaction.to : transaction.from, for: .normal)
                txnLabel.setTitle(transaction.hash, for: .normal)
                valueLabel.text = ((transaction.value.toDouble() ?? 0) / Double(pow(Double(10), Double(18)))).str_6f
                ageLabel.text = Date(timeIntervalSince1970: transaction.timeStamp.toDouble() ?? 0).string()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fromAddress.addTarget(self, action: #selector(clickAddress), for: .touchUpInside)
        txnLabel.addTarget(self, action: #selector(clickTxn), for: .touchUpInside)

    }

    @objc func clickAddress() {
        didClickAddress?()
    }
    
    @objc func clickTxn() {
        didClickTxn?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.addShadow(ofColor: UIColor.black.withAlphaComponent(0.08), radius: 8, offset: CGSize(width: 10, height: 10), opacity: 1)
    }
    
}
