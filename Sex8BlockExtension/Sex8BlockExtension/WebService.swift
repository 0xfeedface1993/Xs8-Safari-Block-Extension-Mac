//
//  WebService.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/6.
//  Copyright © 2017年 ascp. All rights reserved.
//

import AppKit

enum WebserviceError : Error {
    case badURL(message: String)
    case badSendJson(message: String)
    case badResponseJson(message: String)
    case emptyResponseData(message: String)
}

enum WebServiceMethod : String {
    case post = "POST"
    case get = "GET"
}

enum WebserviceBaseURL : String {
    case main = "http://127.0.0.1:8181/api"
}

struct WebserviceCaller<T> {
    var baseURL : WebserviceBaseURL
    var way : WebServiceMethod
    var method : String
    var paras : [String : String]?
    var rawData : Data?
    var execute : ((T?, Error?, ErrorResponse?)->())?
}

class Webservice {
    static let share = Webservice()
    var runningTask = [URLSessionDataTask]()
    private var session : URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    func read<P : Codable>(caller : WebserviceCaller<P>) throws {
        let responseHandler : (Data?, URLResponse?, Error?) -> Swift.Void = { (data, response, err) in
            if let e = err {
                caller.execute?(nil, e, nil)
                return
            }
            let jsonDecoder = JSONDecoder()
            guard let good = data else {
                caller.execute?(nil, WebserviceError.badResponseJson(message: "返回数据为空"), nil)
                return
            }
            if let errorResult = try? jsonDecoder.decode(ErrorResponse.self, from: good) {
                caller.execute?(nil, nil, errorResult)
                return
            }
            do {
                let json = try jsonDecoder.decode(P.self, from: good)
                caller.execute?(json, nil, nil)
            } catch {
                caller.execute?(nil, WebserviceError.badResponseJson(message: "错误的解析对象！请检查返回的JSON字符串是否符合解析的对象类型。\n\(String(data: good, encoding: .utf8) ?? "empty")"), nil)
            }
        }
        
        func handler(task: URLSessionDataTask) -> ((Data?, URLResponse?, Error?) -> Swift.Void) {
            return { (data, response, err) in
                if let index = self.runningTask.enumerated().map({ return $0.offset }).first {
                    self.runningTask.remove(at: index)
                }
                
                if let e = err {
                    caller.execute?(nil, e, nil)
                    return
                }
                let jsonDecoder = JSONDecoder()
                guard let good = data else {
                    caller.execute?(nil, WebserviceError.badResponseJson(message: "返回数据为空"), nil)
                    return
                }
                if let errorResult = try? jsonDecoder.decode(ErrorResponse.self, from: good) {
                    caller.execute?(nil, nil, errorResult)
                    return
                }
                do {
                    let json = try jsonDecoder.decode(P.self, from: good)
                    caller.execute?(json, nil, nil)
                } catch {
                    caller.execute?(nil, WebserviceError.badResponseJson(message: "错误的解析对象！请检查返回的JSON字符串是否符合解析的对象类型。\n\(String(data: good, encoding: .utf8) ?? "empty")"), nil)
                }
            }
        }
        
        switch caller.way {
        case .get:
            var urlString = caller.baseURL.rawValue.appending("?method=\(caller.method)")
            caller.paras?.forEach({ (key, value) in
                urlString.append("&\(key)=\(value)")
            })
            if let url = URL(string: urlString) {
                var request = URLRequest(url: url)
                request.httpMethod = caller.way.rawValue
                let task = session.dataTask(with: request, completionHandler: responseHandler)
                task.resume()
                runningTask.append(task)
                return
            }
            throw WebserviceError.badURL(message: "错误的url：" + urlString)
        case .post:
            let urlString = caller.baseURL.rawValue.appending("?method=\(caller.method)")
            do {
                var data : Data?
                if let paras = caller.paras {
                    data = paras.postParams().data(using: .utf8)
                }   else if let raw = caller.rawData {
                    data = raw
                }
                
                if let url = URL(string: urlString) {
                    var request = URLRequest(url: url)
                    request.httpBody = data
                    request.httpMethod = caller.way.rawValue
                    let task = session.dataTask(with: request, completionHandler: responseHandler)
                    task.resume()
                    runningTask.append(task)
                    return
                }
                throw WebserviceError.badURL(message: "错误的url：" + urlString)
            }   catch   {
                caller.execute?(nil, error, nil)
                return
            }
        }
    }
    
    func cancelAllTask() {
        runningTask.forEach { (task) in
            task.cancel()
        }
        runningTask.removeAll()
    }
}
