//
//  LogItem.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

final class LogData: ObservableObject {
    @Published var logs = [LogItem]()
    @Published var state: ActionState = .hange
    @Published var isOn: Bool = false {
        willSet {
            guard newValue != isOn else {
                return
            }
            
            if newValue {
                state = .running
                coodinator.start()
            }   else    {
                state = .hange
                DispatchQueue.global().async {
                    coodinator.stop()
                }
            }
        }
    }
}

struct LogItem: Identifiable {
    enum LogType {
        case log
        case error
    }
    
    var id: Int    
    var date: Date
    var type: LogType
    var message: String
    
    static func log(message: String) {
        let item = LogItem(id: logData.logs.count, date: Date(), type: .log, message: message)
        if Thread.isMainThread {
            justLog(item: item)
        }   else    {
            DispatchQueue.main.async {
                justLog(item: item)
            }
        }
    }
    
    static func log(error: String) {
        let item = LogItem(id: logData.logs.count, date: Date(), type: .error, message: error)
        if Thread.isMainThread {
            justLog(item: item)
        }   else    {
            DispatchQueue.main.async {
                justLog(item: item)
            }
        }
    }
    
    private static func justLog(item: LogItem) {
        if logData.logs.count >= 100 {
            logData.logs = [item]
        }
        logData.logs.insert(item, at: 0)
    }
}


let logData = LogData()
