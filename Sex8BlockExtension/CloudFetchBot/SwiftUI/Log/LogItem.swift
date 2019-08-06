//
//  LogItem.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI

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
        if logs.count >= INT_MAX {
            logs.removeAll()
        }
        logs.append(LogItem(id: logs.count, date: Date(), type: .log, message: message))
    }
    
    static func log(error: String) {
        if logs.count >= INT_MAX {
            logs.removeAll()
        }
        logs.append(LogItem(id: logs.count, date: Date(), type: .error, message: error))
    }
}

var logs = [LogItem]()
