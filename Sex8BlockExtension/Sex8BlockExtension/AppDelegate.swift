//
//  AppDelegate.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var user : User?
    @IBOutlet weak var openItem: NSMenuItem!
    @IBAction func chooseDirection(_ sender: NSMenuItem) {
        let fileManage = NSStoryboard(name: NSStoryboard.Name(rawValue: "FileManageStoryboard"), bundle: Bundle.main)
        let window = fileManage.instantiateInitialController() as! NSWindowController
        NSApp.runModal(for: window.window!)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
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
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        guard let modelURL = Bundle.main.url(forResource: "NetdiskModel", withExtension: "momd") else {
            fatalError("failed to find data model")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "com.kmvc.group.safari"), fileURL = URL(string: "NetdiskModel.sql", relativeTo: dirURL)
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
            let moc = NSManagedObjectContext(concurrencyType:.mainQueueConcurrencyType)
            moc.persistentStoreCoordinator = psc
            let container = NSPersistentContainer(name: "NetdiskModel", managedObjectModel: mom)
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error)")
                }
            })
            return container
        } catch {
            fatalError("Error configuring persistent store: \(error)")
        }
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        guard let modelURL = Bundle.main.url(forResource: "NetdiskModel", withExtension: "momd") else {
            fatalError("failed to find data model")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "com.kmvc.group.safari"), fileURL = URL(string: "new.sqlite3", relativeTo: dirURL)
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: options)
            let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
            moc.persistentStoreCoordinator = psc
            return moc
        } catch {
            fatalError("Error configuring persistent store: \(error)")
        }
    }()
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = managedObjectContext//persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
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
                let context = self.managedObjectContext
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
        let context = managedObjectContext
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
}



