//
//  Webservice.swift
//  S8Blocker
//
//  Created by virus1993 on 2017/10/12.
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
    case main = "http://14d8856q96.imwork.net"
    case aliyun = "http://120.78.89.159/api"
    case debug = "http://14d8856q96.imwork.net:13649"
    func url(method: WebserviceMethodPath) -> URL {
        return URL(string: self.rawValue + method.rawValue)!
    }
}

enum WebserviceMethodPath : String {
    case registerDevice = "/api/v1/addDevice"
    case findDevice = "/api/v1/findDevice"
}

class WebserviceCaller<T: Codable, X: Codable> {
    var baseURL : WebserviceBaseURL
    var way : WebServiceMethod
    var method : WebserviceMethodPath
    var paras : X?
    var rawData : Data?
    var execute : ((T?, Error?, ErrorResponse?)->())?
    
    init(url: WebserviceBaseURL, way: WebServiceMethod, method: WebserviceMethodPath) {
        self.baseURL = url
        self.way = way
        self.method = method
    }
}

class Webservice {
    static let share = Webservice()
    var runningTask = [URLSessionDataTask]()
    private var session : URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()
    
    func read<P : Codable, X: Codable>(caller : WebserviceCaller<P, X>) throws {
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
            let urlString = caller.baseURL.rawValue.appending("?method=\(caller.method.rawValue)")
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
            let urlString = caller.baseURL.url(method: caller.method).absoluteString
            do {
                var data : Data?
                if let paras = caller.paras {
                    let encoder = JSONEncoder()
                    data = try? encoder.encode(paras)
                }   else if let raw = caller.rawData {
                    data = raw
                }
                
                if let url = URL(string: urlString) {
                    var request = URLRequest(url: url)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
