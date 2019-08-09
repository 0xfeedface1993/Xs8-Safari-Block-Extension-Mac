//
//  AppDelegate.swift
//  CloudFetchBot
//
//  Created by virus1994 on 2018/6/6.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let host = NSHostingController(rootView: HomeView().environmentObject(logData))
        NSApp.keyWindow?.contentViewController = host
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

