//
//  ResponseData.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 10/10/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation
class ResponseData {
    var code: Int?
    var value: Any?
    init(code: Int, value: Any) {
        self.code = code
        self.value = value
    }
}
