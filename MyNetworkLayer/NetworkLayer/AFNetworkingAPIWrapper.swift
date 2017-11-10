//
//  AFNetworkingAPIWrapper.swift
//  MyNetworkLayer
//
//  Created by Quang Minh Trinh on 11/9/17.
//  Copyright © 2017 Quang Minh Trinh. All rights reserved.
//

import Foundation
import AFNetworking
class AFNetworkingSessionManager:  NetworkSessionManager {
    override func createSession() -> AnyObject {
        let sessionManager = AFHTTPSessionManager()
        
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        
        sessionManager.responseSerializer = AFJSONResponseSerializer()
        
        var newAcceptableContentTypes: Set<String> = sessionManager.responseSerializer.acceptableContentTypes!
        newAcceptableContentTypes.insert("text/html")
        newAcceptableContentTypes.insert("text/plain")
        sessionManager.responseSerializer.stringEncoding = String.Encoding.utf8.rawValue
        sessionManager.responseSerializer.acceptableContentTypes = newAcceptableContentTypes
        sessionManager.requestSerializer.timeoutInterval = 30
        return sessionManager
    }
    
}
class AFNetworkingAPIWrapper: NetworkWrapper {
    func completionHandleData(response: Any, dataType: DataType, completionHandler: @escaping NetworkCompletionHandler) {
        
        if let response = response as? (urlResponse: URLResponse,filePath: URL) {
            let httpResponse = response.urlResponse as! HTTPURLResponse
            let code = httpResponse.statusCode
            if code >= 200 && code <= 300 {
                let destinationURL = response.filePath
                NetworkManagerUtilities.responseDataAndCodeFrom(destinationURL: destinationURL, code: code, dataType: dataType, completionHandler: completionHandler)
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
                    let multipartFormData = multipartFormData as! AFMultipartFormData
                    do {
                        try multipartFormData.appendPart(withFileURL: url, name: key, fileName: fileName, mimeType: mimeType)
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    var sessionManager: NetworkSessionManager = AFNetworkingSessionManager()
    var delegate: NetworkWrapperDelegate?

    
    func request(requestType: RequestTaskType, requestURLString: String, parameters: [String : AnyObject]?, additionalHeaders: [String : String]?, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        
        let session = sessionManager.session as! AFHTTPSessionManager
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                session.requestSerializer.setValue(value, forHTTPHeaderField: key)
            }
        }
        switch requestType {
        case .get:
            session.get(requestURLString, parameters: parameters, progress: nil, success: { (task, responseObject) in
                self.completionHandle(task: task, responseObject: responseObject, error: nil, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            }, failure: { (task, error) in
                self.completionHandle(task: task, responseObject: nil, error: error, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .post:
            session.post(requestURLString, parameters: parameters, progress: nil, success: { (task, responseObject) in
                self.completionHandle(task: task, responseObject: responseObject, error: nil, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            }, failure: { (task, error) in
                self.completionHandle(task: task, responseObject: nil, error: error, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .put:
            session.put(requestURLString, parameters: parameters, success: { (task, responseObject) in
                self.completionHandle(task: task, responseObject: responseObject, error: nil, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            }, failure: { (task, error) in
                self.completionHandle(task: task, responseObject: nil, error: error, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        case .delete:
            session.delete(requestURLString, parameters: parameters, success: { (task, responseObject) in
                self.completionHandle(task: task, responseObject: responseObject, error: nil, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            }, failure: { (task, error) in
                self.completionHandle(task: task, responseObject: nil, error: error, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
            })
        }
        
    }
    func upload(requestURLString: String, parameters: [String : AnyObject]?, imagePathInfos: [[String : String]], additionalHeaders: [String : String]?, method: RequestTaskType, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        let session = sessionManager.session as! AFHTTPSessionManager
        session.post(requestURLString, parameters: parameters, constructingBodyWith: { (multipartFormData) in
           self.addImageToMultipartFormData(multipartFormData: multipartFormData, imagePathInfos: imagePathInfos)
        }, progress: nil, success: { (task, responseObject) in
            self.completionHandle(task: task, responseObject: responseObject, error: nil, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
        }, failure: { (task, error) in
           self.completionHandle(task: task, responseObject: nil, error: error, forAuthenticate: forAuthenticate, completionHandler: completionHandler)
        })
    }
    func download(requestURLString: String, parameters: [String : AnyObject]?, additionalHeaders: [String : String]?, dataType: DataType, completionHandler: @escaping NetworkCompletionHandler) {
        let session = sessionManager.session as! AFHTTPSessionManager
        if let requestURL = URL.init(string: requestURLString) {
            let request = URLRequest.init(url: requestURL)
            let downloadTask = session.downloadTask(with: request, progress: nil, destination: { (url, response) -> URL in
                return NetworkManagerUtilities.getDownloadDestinationPath(url: url, response: response)
            }, completionHandler: { (urlResponse, url, error) in
                if let error = error {
                    let error = ErrorData.init(code: 9999, value: error.localizedDescription)
                    completionHandler(error, nil)
                }
                else {
                    self.completionHandleData(response: (urlResponse, url), dataType: dataType, completionHandler: completionHandler)
                }
            })
            downloadTask.resume()
        }
        
    }
    
    func completionHandle(task: URLSessionDataTask?, responseObject: Any?,  error: Error?, forAuthenticate: Bool, completionHandler: @escaping NetworkCompletionHandler) {
        if let responseObject = responseObject {
            if let convertedValue = NetworkManagerUtilities.convertValue(value: responseObject) {
                if let urlResponse = task?.response as? HTTPURLResponse {
                    let code = urlResponse.statusCode
                    if code >= 200 && code < 300 {
                        let responseData = ResponseData.init(code: code, value: convertedValue)
                        if let delegate = self.delegate {
                            delegate.prehandleResponsePackage(responseData, forAuthenticate:  forAuthenticate)
                        }
                        
                        completionHandler(nil, responseData)
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
                    }
                }
            }
            else {
                let errorData = ErrorData.init(code: 9999, value: "Somethings went wrong")
                completionHandler(errorData, nil)
                return
            }
        }
        else if let error = error {
            if let task = task {
                if let urlResponse = task.response as? HTTPURLResponse {
                    let code = urlResponse.statusCode
                    var isSpecificError = false
                    if let delegate = self.delegate {
                        isSpecificError = delegate.handleSpecificError(code: code)
                    }
                   
                    if isSpecificError == false {
                        let errorDescription = error.localizedDescription
                        let errorData = ErrorData.init(code: code, value: errorDescription)
                        completionHandler(errorData, nil)
                    }
                }
            }
        }
    }
}

