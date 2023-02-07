//
//  LitClient.swift
//  LitOAuthPKPSignUp
//
//  Created by leven on 2023/1/4.
//

import Foundation
import litSwift

import Alamofire
public class LitOAuthClient {
    
    let relayApi: String
    
    let session: Session
    
    public init(relay: String) {
        self.relayApi = relay
       
        let manager = MyServerTrustPolicyManager(evaluators: [:])
        let configuration = URLSessionConfiguration.af.default
        configuration.headers = HTTPHeaders(["Content-Type" : "application/json"])
        self.session = Session(configuration: configuration, serverTrustManager: manager)
    }
    
    
    public func handleLoggedInToGoogle(_ credential: String,
                                              completionHandler: @escaping (_ requestId: String?, _ error: String?) -> Void) {
    
        session.request(relayApi + "auth/google",
                        method: .post,
                        parameters: ["idToken": credential],
                        encoder: JSONParameterEncoder.default).response { response in
            if let data = response.data, let dataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let code = response.response?.statusCode ?? 400
                if code < 200 || code >= 400 {
                    let error = dataDict["error"] as? String ?? "Something wrong with the API call"
                    completionHandler(nil, error)
                } else if let requestId = dataDict["requestId"] as? String {
                    completionHandler(requestId, nil)
                } else {
                    let error = "Empty requestId"
                    completionHandler(nil,error)
                }
            } else {
                completionHandler(nil, "Something wrong with the API call")
            }
        }
    }
    
    public func pollRequestUntilTerminalState(with requestId: String,
                                              completionHandler: @escaping (_ result: [String: Any]?, _ error: String?) -> Void) {
        
        session.request(relayApi + "auth/status/" + requestId).response { response in
            if let data = response.data, let dataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let code = response.response?.statusCode ?? 400
                if code < 200 || code >= 400 {
                    let error = dataDict["error"] as? String ?? "Something wrong with the API call"
                    completionHandler(nil, error)
                } else if let status = dataDict["status"] as? String, status == "Succeeded" {
                    completionHandler(dataDict, nil)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        guard let `self` = self else { return }
                        self.pollRequestUntilTerminalState(with: requestId, completionHandler: completionHandler)
                    }
                }
            } else {
                completionHandler(nil, "Something wrong with the API call")
            }
        }
    }
}

class MyServerTrustPolicyManager: ServerTrustManager {
    open override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return DisabledTrustEvaluator()
    }
}
