//
//  AppDelegate.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa
import KSCrash
import IOKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UpdateProtocol {
    var user : User?
    var selectItem: NetDisk?
    
    @IBOutlet weak var openItem: NSMenuItem!
    @IBAction func chooseDirection(_ sender: NSMenuItem) {
        let fileManage = NSStoryboard(name: NSStoryboard.Name(rawValue: "FileManageStoryboard"), bundle: Bundle.main)
        let window = fileManage.instantiateInitialController() as! NSWindowController
        NSApp.runModal(for: window.window!)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let hockeyKey = "5d8cfac924774e6e872eaee45ef8a24d"
        let hockey = KSCrashInstallationHockey.sharedInstance()
        hockey?.appIdentifier = hockeyKey
        hockey?.userID = ""
        hockey?.contactEmail = ""
        hockey?.crashDescription = "Crash Form \(model() ?? "unkown")"
        hockey?.install()
        KSCrash.sharedInstance().deleteBehaviorAfterSendAll = KSCDeleteNever
        hockey?.sendAllReports(completion: { (reporsts, completed, err) in
            if completed {
                print("send reports: \(reporsts?.count ?? 0)")
            }   else    {
                print("Fialed send crash reports! \(err?.localizedDescription ?? "opps")")
            }
        })
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        NotificationCenter.default.post(name: TableViewRefreshName, object: nil)
//        print("active")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当前还显示窗口就不管了
        guard !flag else {
            return false
        }
        // 只重新打开主页窗口
        for item in sender.windows {
            if let main = item.identifier?.rawValue, main == "main" {
                item.makeKeyAndOrderFront(nil)
                return true
            }
        }
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = DataBase.share.managedObjectContext//persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                DispatchQueue.main.async {
                    NSApplication.shared.presentError(nserror)
                }
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return DataBase.share.persistentContainer.viewContext.undoManager
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = DataBase.share.persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == NSApplication.ModalResponse.alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    func resetAllRecords(in entity : String) {
        let alert = NSAlert()
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")
        alert.messageText = "确定删除所有数据？"
        alert.informativeText = "删除后不可恢复！"
        alert.alertStyle = .warning
        alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: {
            code in
            switch code {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                let context = DataBase.share.managedObjectContext
                let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
                do {
                    try context.execute(deleteRequest)
                    try context.save()
                } catch {
                    print ("There was an error")
                }
                break
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                
                break
            default:
                break
            }
        })
        
    }
    
    func resetAllBadRecords() {
        let context = DataBase.share.managedObjectContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Pic")
        deleteFetch.predicate = NSPredicate(format: "pic == NULL", argumentArray: nil)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    /// 获取设备型号
    ///
    /// - Returns: 设备型号
    func model() -> String? {
        let platformExport = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if platformExport > 0 {
            let productName = IORegistryEntryCreateCFProperty(platformExport, "product-name" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as! Data
            if let str = String(data: productName, encoding: .utf8) {
                return str
            }
        }
        return nil
    }
    
    @IBAction func findNewVersion(_ sender: Any) {
        checkUpdate()
    }
}



