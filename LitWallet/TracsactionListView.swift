//
//  TracsactionListView.swift
//  LitWallet
//
//  Created by leven on 2023/2/9.
//

import Foundation
import UIKit
import PromiseKit

class TransactionListView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No transaction"
        label.textColor = UIColor.black.withAlphaComponent(0.3)
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: .main), forCellReuseIdentifier: "TransactionTableViewCell")
        return tableView
    }()
    
    var didClickTxn: ((String) -> Void)?
    var didClickAddress: ((String) -> Void)?

    
    var address: String? {
        didSet {
            self.refreshData()
        }
    }
    
    private var transactions: [TransactionListResponse.Transaction] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI() {
        self.backgroundColor = UIColor.white
        let titleLabel = UILabel()
        titleLabel.text = "Transactions:"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        self.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(20)
        }
        self.addSubview(self.tableView)
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
        }
        self.tableView.contentInset = UIEdgeInsets.zero
        
        self.addSubview(self.emptyLabel)
        self.emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(100)
        }
    }
    
    func refreshData() {
        let url = URL(string: "https://api-testnet.polygonscan.com/api?module=account&action=txlist&address=\(self.address ?? "")&startblock=0&endblock=99999999&page=1&offset=100&sort=asc&apikey=C2NKH69QW7YI8ZYVFJBFPK9GFZDZS41YBI")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let _ = URLSession.shared.dataTask(.promise ,with: request).done { [weak self] res in
            guard let self = self else { return }
            do {
                let model = try JSONDecoder().decode(TransactionListResponse.self, from: res.data)
                self.getInternalTransaction(model.result.sorted(by: { $0.timeStamp > $1.timeStamp }))
            } catch {
                print(error)
            }
        }
    }
    
    func getInternalTransaction(_ transactions: [TransactionListResponse.Transaction]) {
        let url = URL(string: "https://api-testnet.polygonscan.com/api?module=account&action=txlistinternal&address=\(self.address ?? "")&startblock=0&endblock=99999999&page=1&offset=100&sort=asc&apikey=C2NKH69QW7YI8ZYVFJBFPK9GFZDZS41YBI")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let _ = URLSession.shared.dataTask(.promise ,with: request).done { [weak self] res in
            guard let self = self else { return }
            do {
                let model = try JSONDecoder().decode(TransactionListResponse.self, from: res.data)
                var transactions = transactions
                transactions.append(contentsOf: model.result)
                self.transactions = transactions
                self.tableView.reloadData()
            } catch {
                print(error)
            }
            self.emptyLabel.isHidden = self.transactions.count > 0
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
        let transaction = self.transactions[indexPath.row]
        cell.mineAddress = self.address ?? ""
        cell.transaction = transaction
        cell.didClickTxn = { [weak self] in
            guard let self = self else { return }
            self.didClickTxn?(transaction.hash)
        }
        
        cell.didClickAddress = { [weak self] in
            guard let self = self else { return }
            self.didClickAddress?(self.address == transaction.from ? transaction.to : transaction.from)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
}


struct TransactionListResponse: Codable {
    var status: String = ""
    var message: String = ""
    var result: [Transaction] = []
    struct Transaction: Codable {
        var blockNumber: String = ""
        var timeStamp: String = ""
        var hash: String = ""
        var from: String = ""
        var to: String = ""
        var value: String = ""
    }
}
