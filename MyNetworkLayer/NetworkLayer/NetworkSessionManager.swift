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
    
    
}
