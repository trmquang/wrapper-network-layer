//
//  NetworkLayer.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 10/3/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation
import Alamofire
import AFNetworking

typealias NetworkCompletionHandler = (_ error: ErrorData?, _ response: ResponseData?)->()


enum RequestTaskType {
    case get
    case post
    case put
    case delete
}
enum DataType {
    case image
    case data
    case string
}
enum LibType {
    case AFNetwoking
    case Alamofire
}

class NetworkManager {
   
    var wrapper: NetworkWrapper
    init() {
        wrapper = AlamofireAPIWrapper()
    }
}
