//
//  AlamofireAPIWrapper.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 11/9/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation
import Alamofire
class AlamofireSessionManager:  NetworkSessionManager {
    override func createSession() -> AnyObject {
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.httpAdditionalHeaders = self.currentHeaderForRequest()
        manager.session.configuration.timeoutIntervalForRequest = 30
        manager.session.configuration.allowsCellularAccess = true
        return manager
    }
    override func currentHeaderForRequest() -> [String : String] {
        return super.currentHeaderForRequest()
    }
    
}
class AlamofireAPIWrapper: NetworkWrapper {
    
    var sessionManager: NetworkSessionManager = AlamofireSessionManager()
    var delegate: NetworkWrapperDelegate?
    func request(requestType: RequestTaskType, requestURLString: String, parameters: [String : AnyObject]?, additionalHeaders: [String : String]?, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        let session = sessionManager.session as! SessionManager
        switch requestType {
        case .get:
            session.request(requestURLString, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: additionalHeaders).responseString(queue: nil, encoding: String.Encoding.utf8, completionHandler: { response in
                self.completionHandle(response: response, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .post:
            session.request(requestURLString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseString(queue: nil, encoding: String.Encoding.utf8, completionHandler: {response in
                self.completionHandle(response: response, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .put:
            session.request(requestURLString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseString(queue: nil, encoding: String.Encoding.utf8, completionHandler: {response in
                self.completionHandle(response: response, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .delete:
            session.request(requestURLString, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: additionalHeaders).responseString(queue: nil, encoding: String.Encoding.utf8, completionHandler: {response in
               self.completionHandle(response: response, forAuthenticate: forAuthenticate,
                                                         completionHandler: completionHandler)
            })
        }
    }
    
    func download(requestURLString: String, parameters: [String : AnyObject]?, additionalHeaders: [String : String]?, dataType: DataType, completionHandler: @escaping NetworkCompletionHandler) {
        let session = sessionManager.session as! SessionManager
        session.download(requestURLString, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: additionalHeaders, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            let destinationURL = NetworkManagerUtilities.getDownloadDestinationPath(url: url, response: response)
            return (destinationURL, DownloadRequest.DownloadOptions.init(rawValue: 0))
        }).response(completionHandler: { (response) in
            if let error = response.error {
                let error = ErrorData.init(code: 9999, value: error.localizedDescription)
                completionHandler(error, nil)
            }
            else {
                self.completionHandleData(response: response, dataType: dataType, completionHandler: completionHandler)
            }
            return
        })
    }
    
    func upload(requestURLString: String, parameters: [String : AnyObject]?, imagePathInfos: [[String : String]], additionalHeaders: [String : String]?, method: RequestTaskType, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        let session = sessionManager.session as! SessionManager
        var convertedMethod: HTTPMethod = .post
        switch method {
        case .get:
            convertedMethod = .get
        case .post:
            convertedMethod = .post
        case .delete:
            convertedMethod = .delete
        case .put:
            convertedMethod = .put
        }
        session.upload(multipartFormData: { multipartFormData in
            if let parameters = parameters {
                for (key,value) in parameters{
                    if let value = value as? String {
                        if let data = value.data(using: String.Encoding.utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                    else if let value = value as? Dictionary<String, AnyObject> {
                        let data = NSKeyedArchiver.archivedData(withRootObject: value)
                        multipartFormData.append(data, withName: key)
                    }
                    else  {
                        let value = String.init(describing: value)
                        if let data = value.data(using: String.Encoding.utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            }
            
            self.addImageToMultipartFormData(multipartFormData: multipartFormData, imagePathInfos: imagePathInfos)
            
        }, usingThreshold: UInt64(), to: requestURLString, method: convertedMethod, headers: additionalHeaders, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .failure(let error):
                let errorData = ErrorData.init(code: 9999, value: error.localizedDescription)
                completionHandler(errorData, nil)
            case .success(request: let upload, streamingFromDisk: _, streamFileURL: _):
                upload.uploadProgress(closure: { (progress) in
                })
                upload.responseString(completionHandler: { (response) in
                    self.completionHandle(response: response, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
                })
            }
        })
    }
    
    func addImageToMultipartFormData(multipartFormData: Any, imagePathInfos: [[String : String]]) {
        for info in imagePathInfos {
            if let key = info["key"], let path = info["path"] {
                if path.count > 0 {
                    let url = URL(fileURLWithPath: path)
                    var fileName = "imageName"
                    var mimeType = "image/jpeg"
                    if let name = info["fileName"]  {
                        fileName = name
                    }
                    if let type = info["mimeType"] {
                        mimeType = type
                    }
                    let multipartFormData = multipartFormData as! MultipartFormData
                    multipartFormData.append(url, withName: key, fileName: fileName, mimeType: mimeType)
                    
                    
                }
            }
        }
    }
    
    func completionHandle(response: DataResponse<String>, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        if let error = response.error {
            let errorData = ErrorData.init(code: 9999, value: error.localizedDescription)
            completionHandler(errorData, nil)
            return
        }
        else {
            if let code = response.response?.statusCode {
                if code >= 200 && code <= 300 {
                    if let response = response.result.value {
                        if let convertedValue = NetworkManagerUtilities.convertValue(value: response) {
                            let responseData = ResponseData.init(code: code, value: convertedValue)
                            if let delegate = self.delegate {
                                delegate.prehandleResponsePackage(responseData, forAuthenticate: forAuthenticate)
                            }
                            
                            completionHandler(nil, responseData)
                            return
                        }
                    }
                    let errorData = ErrorData.init(code: 9999, value: "Somethings went wrong")
                    completionHandler(errorData, nil)
                    return
                }
                else {
                    var isSpecificError = false
                    if let delegate = self.delegate {
                        isSpecificError = delegate.handleSpecificError(code: code)
                    }
                    if isSpecificError == false{
                        var errorDescription = ""
                        if let response = response.result.value {
                            errorDescription = response
                        }
                        let errorData = ErrorData.init(code: code, value: errorDescription)
                        completionHandler(errorData, nil)
                    }
                    return
                }
            }
        }
    }
    
    func completionHandleData(response: Any, dataType: DataType, completionHandler: @escaping NetworkCompletionHandler) {
        if let response = response as? DefaultDownloadResponse {
            if let error = response.error {
                let errorData = ErrorData.init(code: 9999, value: error.localizedDescription)
                completionHandler(errorData, nil)
                return
            }
            else {
                if let code = response.response?.statusCode {
                    if code >= 200 && code <= 300 {
                        if let destinationURL = response.destinationURL {
                            NetworkManagerUtilities.responseDataAndCodeFrom(destinationURL: destinationURL, code: code, dataType: dataType, completionHandler: completionHandler)
                            return
                        }
                        let errorData = ErrorData.init(code: 9999, value: "Somethings went wrong")
                        completionHandler(errorData, nil)
                        return
                    }
                    else {
                        var haveSpecificError = false
                        if let delegate = self.delegate {
                            haveSpecificError = delegate.handleSpecificError(code: code)
                        }
                        if haveSpecificError == false{
                            let errorDescription = ""
                            let errorData = ErrorData.init(code: code, value: errorDescription)
                            completionHandler(errorData, nil)
                        }
                        return
                    }
                }
            }
        }     
    }
    
    
    
}
