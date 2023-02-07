//
//  Error.swift
//  LitProtocolSwiftSDK
//
//  Created by leven on 2023/1/13.
//

import Foundation
public enum LitError: Error {
    case INVALID_URL(String)
    case INIT_KEYPAIR_ERROR
    case UNSUPPORTED_CHAIN_EXCEPTION(String)
    case LIT_NODE_CLIENT_NOT_READY_ERROR
    case INVALID_PUBLIC_KEY
    case INVALID_CHAIN
    
    case unexpectedReturnValue
    case COMMON
}
