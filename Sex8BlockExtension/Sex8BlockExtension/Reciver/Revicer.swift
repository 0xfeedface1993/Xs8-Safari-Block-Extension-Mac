//
//  Revicer.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2019/4/7.
//  Copyright © 2019 ascp. All rights reserved.
//

import Foundation

let reciverNotificationName = NSNotification.Name(rawValue: "com.ascp.distrubution.notification.netdisk.add")

protocol Reciver {
    func reciver(notification: Notification)
}

struct RemoteNetDisk: Codable {
    var title: String
    var format: String
    var msk: String
    var pageurl: String
    var passwod: String
    var size: String
    var time: String
    var downloadLink: String
    var links: [String]
    var pics: [String]
}

extension Reciver {
    func addRemoteNetdisk(oberserver: AnyObject, selector: Selector) {
        DistributedNotificationCenter.default().addObserver(oberserver, selector: selector, name: reciverNotificationName, object: nil)
    }
    
    func removeRemoteNetdisk(oberserver: AnyObject) {
        DistributedNotificationCenter.default().removeObserver(oberserver, name: reciverNotificationName, object: nil)
    }
}
