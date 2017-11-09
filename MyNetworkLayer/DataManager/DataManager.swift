//
//  DataManager.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 11/10/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation

/// Put all custom request, params, headers here
class DataManager {
    static let shared: DataManager = {
        var manager = DataManager()
        return manager
    }()
    private var networkManager: NetworkManager
    private init() {
        networkManager = NetworkManager()
        networkManager.wrapper.delegate = self
    }
    /// Return base request domain
    private func getBaseRequestURL() -> String{
        return ""
    }
    
    /// Create request URL based on endPoint
    private func makeCurrentRequestWith(endPoint: String) -> String {
        return self.getBaseRequestURL() + "/\(endPoint)"
    }
    private func currentHeaderForRequest(extraHeaders: [String:String]?) -> [String: String] {
        var header: [String:String] = [:]
        if let extraHeaders = extraHeaders {
            header = extraHeaders
        }
        if let authorizationToken = getAuthorizationToken() {
            header["Authorization"] = authorizationToken
        }
        return header
    }
    private func getAuthorizationToken() -> String? {
        if let token = UserDefaults.standard.object(forKey: kAuthorizationToken) as? String {
            return token
        }
        return nil
    }
    private func createParameters(_ parameters: [String: AnyObject]?) -> [String: AnyObject] {
        var newParamters: [String: AnyObject] = [:]
        if let parameters = parameters {
            let keys = parameters.keys
            for key in keys {
                newParamters.updateValue(parameters[key]!, forKey: key)
            }
        }
        newParamters[kSecurityGuard] = kSecurityKey as AnyObject
        return newParamters
    }
    
    
}

extension DataManager: NetworkWrapperDelegate {
    func prehandleResponsePackage(_ responsePackage: ResponseData, forAuthenticate: Bool) {
        if forAuthenticate == true {
            // get authorization token here, forAuthenticate is used for login or renew token
        }
        // prehandle response, like get IPAdress from response, maybe ^_^
        
    }
    func handleSpecificError(code: Int) -> Bool {
        // return false if  you need to throw out error out of this function
        if code == 401 {
            // Unauthorized, fire some notification for app, maybe ^_^
        }
        return false
    }
}

extension DataManager {
    func sampleRequest(parameters: [String:AnyObject]?, header: [String:String]?, completion: @escaping NetworkCompletionHandler) {
        let endPoint = "expectedEndPoint"
        let requestURLString = makeCurrentRequestWith(endPoint: endPoint)
        let additionalHeaders = currentHeaderForRequest(extraHeaders: header)
        networkManager.wrapper.request(requestType: .get, requestURLString: requestURLString, parameters: createParameters(parameters), additionalHeaders: additionalHeaders, forAuthenticate: false, completionHandler: completion)
        
    }
}
