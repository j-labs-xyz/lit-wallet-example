//
//  Constants.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/14.
//
 
import Foundation

var ALL_LIT_CHAINS: LITChain<LITChainRequiredProps> = {
    var chains: LITChain<LITChainRequiredProps> = [:]
    chains.merge(LIT_CHAINS) { _, new in new }
    chains.merge(LIT_SVM_CHAINS) { _, new in new }
    chains.merge(LIT_COSMOS_CHAINS) { _, new in new }
    return chains
}()


public let LIT_CHAINS: LITChain<LITEVMChain> = [
    .ethereum : LITEVMChain(contractAddress: "0xA54F7579fFb3F98bd8649fF02813F575f9b3d353",
                            chainId: 1,
                            type: "ERC1155",
                            name: "Ethereum",
                            symbol: "ETH",
                            decimals: 18,
                            rpcUrls: ["https://eth-mainnet.alchemyapi.io/v2/EuGnkVlzVoEkzdg0lpCarhm8YHOxWVxE"],
                            blockExplorerUrls: ["https://etherscan.io"],
                            vmType: .EVM),
    .polygon : LITEVMChain(contractAddress: "0x7C7757a9675f06F3BE4618bB68732c4aB25D2e88",
                           chainId: 137,
                           type: "ERC1155",
                           name: "Polygon",
                           symbol: "MATIC",
                           decimals: 18,
                           rpcUrls: ["https://polygon-rpc.com"],
                           blockExplorerUrls: ["https://explorer.matic.network"],
                           vmType: .EVM),
    .mumbai: LITEVMChain(contractAddress: "0xc716950e5DEae248160109F562e1C9bF8E0CA25B",
                         chainId: 80001,
                         type: "ERC1155",
                         name: "Mumbai",
                         symbol: "MATIC",
                         decimals: 18,
                         rpcUrls: ["https://rpc-mumbai.maticvigil.com/v1/96bf5fa6e03d272fbd09de48d03927b95633726c"],
                         blockExplorerUrls: ["https://mumbai.polygonscan.com"],
                         vmType: .EVM)
    
]


let LIT_SVM_CHAINS: LITChain<LITSVMChain> = [
    .solana : LITSVMChain(name: "Solana",
                          symbol: "SOL",
                          decimals: 9,
                          rpcUrls: ["https://api.mainnet-beta.solana.com"],
                          blockExplorerUrls: ["https://explorer.solana.com/"],
                          vmType: .SVM),
    .solanaDevnet : LITSVMChain(name: "Solana Devnet",
                          symbol: "SOL",
                          decimals: 9,
                          rpcUrls: ["https://api.devnet.solana.com"],
                          blockExplorerUrls: ["https://explorer.solana.com/"],
                                vmType: .SVM),
    .solanaTestnet : LITSVMChain(name: "Solana Testnet",
                          symbol: "SOL",
                          decimals: 9,
                          rpcUrls: ["https://api.testnet.solana.com"],
                          blockExplorerUrls: ["https://explorer.solana.com/"],
                                 vmType: .SVM)
]

let LIT_COSMOS_CHAINS: LITChain<LITCosmosChain> = [
    .cosmos : LITCosmosChain(chainId: "cosmoshub-4",
                             name: "Cosmos",
                             symbol: "ATOM",
                             decimals: 6,
                             rpcUrls: ["https://lcd-cosmoshub.keplr.app"],
                             blockExplorerUrls: ["https://atomscan.com/"],
                             vmType: .CVM),
    .kyve : LITCosmosChain(chainId: "korellia",
                           name: "Kyve",
                           symbol: "KYVE",
                           decimals: 6,
                           rpcUrls: ["https://api.korellia.kyve.network"],
                           blockExplorerUrls: ["https://explorer.kyve.network/"],
                           vmType: .CVM),
]

typealias LITSVMChain = LITChainRequiredProps


class LITCosmosChain: LITChainRequiredProps {
    let chainId: String
    init(chainId: String, name: String, symbol: String, decimals: Int, rpcUrls: [String], blockExplorerUrls: [String], vmType: VMType) {
        self.chainId = chainId
        super.init(name: name, symbol: symbol, decimals: decimals, rpcUrls: rpcUrls, blockExplorerUrls: blockExplorerUrls, vmType: vmType)
    }
}


public enum Chain: String {
    case ethereum
    case polygon
    case mumbai
    /// LIT_CHAINS
    case solana
    case solanaDevnet
    case solanaTestnet
    
    /// LIT_COSMOS_CHAINS
    case cosmos
    case kyve
    case evmosCosmos
}

enum VMType: String {
    case EVM
    case SVM
    case CVM
}

enum SigTYpe: String {
    case BLS
    case ECDSA
}

enum EitherType: String {
    case ERROR
    case SUCCESS
}

public typealias LITChain<T> = [Chain: T]

public class LITChainRequiredProps {
    let name: String
    let symbol: String
    let decimals: Int
    public let rpcUrls: [String]
    let blockExplorerUrls: [String]
    let vmType: VMType
    init(name: String, symbol: String, decimals: Int, rpcUrls: [String], blockExplorerUrls: [String], vmType: VMType) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.rpcUrls = rpcUrls
        self.blockExplorerUrls = blockExplorerUrls
        self.vmType = vmType
    }
}

public class LITEVMChain: LITChainRequiredProps {
    let contractAddress: String?
    let chainId: Int
    let type: String?
    init(contractAddress: String?, chainId: Int, type: String?, name: String, symbol: String, decimals: Int, rpcUrls: [String], blockExplorerUrls: [String], vmType: VMType) {
        self.contractAddress = contractAddress
        self.chainId = chainId
        self.type = type
        super.init(name: name, symbol: symbol, decimals: decimals, rpcUrls: rpcUrls, blockExplorerUrls: blockExplorerUrls, vmType: vmType)
    }
}
