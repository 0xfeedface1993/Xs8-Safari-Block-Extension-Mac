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
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        CloudDataBase.share.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: HomeView().environmentObject(logData))
        window.makeKeyAndOrderFront(nil)
        
        print(">>> " + CloudDataBase.share.backgroundViewContext.description)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        CloudDataBase.share.saveContext()
    }


}

