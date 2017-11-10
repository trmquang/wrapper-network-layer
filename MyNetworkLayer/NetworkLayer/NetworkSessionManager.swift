//
//  NetworkSessionManager.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 11/9/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation

class NetworkSessionManager {
   
    var session: AnyObject!
    init () {
        session = createSession()
    }
    func createSession() -> AnyObject {
       return "Not Implemented" as AnyObject
    }
    
    func currentHeaderForRequest() -> [String: String] {
        let header: [String:String] = [:]
        
        return header
    }
    func createParameters(_ parameters: [String: AnyObject]?) -> [String: AnyObject] {
        var newParamters: [String: AnyObject] = [:]
        if let parameters = parameters {
            let keys = parameters.keys
            for key in keys {
                newParamters.updateValue(parameters[key]!, forKey: key)
            }
        }
        
        return newParamters
    }
    
}
