//
//  SafariExtensionHandler.swift
//  Torrilste
//
//  Created by virus1994 on 2017/6/18.
//  Copyright © 2017年 ascp. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
//        page.getPropertiesWithCompletionHandler { properties in
//            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
//        }
        switch messageName {
        case "CatchDownloadLinks":
            print("\(userInfo ?? [:])")
            saveDownloadLink(data: userInfo!)
            break
        default:
            break
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
        window.getActiveTab(completionHandler: {
            tab in
            tab?.getActivePage(completionHandler: {
                page in
                page!.dispatchMessageToScript(withName: "copyDonloadLink", userInfo: ["b":"a"])
                print("post it!")
            })
        })
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    //MARK: - Core Data
    func saveDownloadLink(data: [String : Any]) {
        let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into: managedObjectContext) as! NetDisk
        netdisk.creattime = NSDate()
        netdisk.fileName = data["fileName"] as? String
        netdisk.title = data["title"] as? String
        netdisk.passwod = data["passwod"] as? String
        
        if let allLink = data["links"] as? [String] {
            for sLink in allLink {
                let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: managedObjectContext) as! Link
                link.creattime = NSDate()
                link.link = sLink
                link.linknet = netdisk
            }
        }
        
        if let allLink = data["pics"] as? [String]  {
            for sLink in allLink {
                let link = NSEntityDescription.insertNewObject(forEntityName: "Pic", into: managedObjectContext) as! Pic
                link.creattime = NSDate()
                link.pic = sLink
                link.picnet = netdisk
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
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
        
        let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "com.kmvc.group.safari"), fileURL = URL(string: "NetdiskModel.sql", relativeTo: dirURL)
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
            let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
            moc.persistentStoreCoordinator = psc
            return moc
        } catch {
            fatalError("Error configuring persistent store: \(error)")
        }
    }()
}
