//
//  CoreDataExtension.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/9/24.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation
import CoreData


/// CoreData 执行状态
///
/// - success: 成功
/// - failed: 失败
enum SaveState {
    case success
    case failed
}


/// 页面模型
struct PageData : Equatable {
    var links : [String]
    var password : String
    var title : String
    var pics : [String]
    var fileName : String
    var url : String
    init(data : [String:Any]?) {
        links = data?["links"] as? [String] ?? []
        pics = data?["pics"] as? [String] ?? []
        password = data?["passwod"] as? String ?? ""
        title = data?["title"] as? String ?? ""
        fileName = data?["fileName"] as? String ?? ""
        url = data?["url"] as? String ?? ""
    }
    
    static func ==(lhs: PageData, rhs: PageData) -> Bool {
        return lhs.url == rhs.url
    }
}


/// 单例数据库类 
class DataBase {
    static let share = DataBase()
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
        
        let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "com.kmvc.group.safari"), fileURL = URL(string: "new.sqlite3", relativeTo: dirURL)
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
    
    // 检查是否已经存在数据
    static func checkPropertyExist<T: NSFetchRequestResult>(entity: String, property: String, value: String) -> T? {
        let fetch = NSFetchRequest<T>(entityName: entity)
        fetch.predicate = NSPredicate(format: "SELF.\(property) == '\(value)'")
        do {
            let datas = try DataBase.share.managedObjectContext.fetch(fetch)
            return datas.first
        } catch {
            fatalError("Failed to fetch \(property): \(error)")
        }
    }
    
    
    /// 保存页面信息
    ///
    /// - Parameters:
    ///   - data: js脚本返回的页面数据，是键值对
    ///   - completion: 执行回调
    func saveDownloadLink(data: PageData, completion: ((SaveState) -> ())?) {
        if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "pageurl", value: data.url) {
            print("------- netdisk exists ------ : \(data.url)")
            completion?(.success)
            return
        }
        let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into:  DataBase.share.managedObjectContext) as! NetDisk
        netdisk.creattime = Date()
        netdisk.fileName = data.fileName
        netdisk.title = data.title
        netdisk.passwod = data.password
        netdisk.pageurl = data.url
        netdisk.pic = nil
        netdisk.link = nil
        
        for sLink in data.links {
            if let exitLink : Link = DataBase.checkPropertyExist(entity: Link.className(), property: "link", value: sLink) {
                netdisk.addToLink(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: DataBase.share.managedObjectContext) as! Link
            link.creattime = Date()
            link.link = sLink
            link.addToLinknet(netdisk)
        }
        
        for sLink in data.pics {
            if let exitLink : Pic = DataBase.checkPropertyExist(entity: Pic.className(), property: "pic", value: sLink) {
                netdisk.addToPic(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Pic", into: DataBase.share.managedObjectContext) as! Pic
            link.creattime = Date()
            link.pic = sLink
            link.addToPicnet(netdisk)
        }
        
        do {
            let context = DataBase.share.managedObjectContext
            if !context.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            }
            if context.hasChanges {
                try context.save()
            }
            completion?(.success)
        } catch {
            completion?(.failed)
            print("Failure to save context: \(error)")
        }
    }
    
    func saveFetchBotDownloadLink(data: ContentInfo, completion: ((SaveState) -> ())?) {
        if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "pageurl", value: data.page) {
            print("------- netdisk exists ------ : \(data.page)")
            completion?(.success)
            return
        }
        if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "title", value: data.title) {
            print("------- netdisk exists ------ : \(data.title)")
            completion?(.success)
            return
        }
        let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into:  DataBase.share.managedObjectContext) as! NetDisk
        netdisk.creattime = Date()
        netdisk.fileName = ""
        netdisk.title = data.title
        netdisk.passwod = data.passwod
        netdisk.pageurl = data.page
        netdisk.msk = data.msk
        netdisk.time = data.time
        netdisk.format = data.format
        netdisk.size = data.size
        netdisk.pic = nil
        netdisk.link = nil
        
        for sLink in data.downloafLink {
            if let exitLink : Link = DataBase.checkPropertyExist(entity: Link.className(), property: "link", value: sLink) {
                netdisk.addToLink(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: DataBase.share.managedObjectContext) as! Link
            link.creattime = Date()
            link.link = sLink
            link.addToLinknet(netdisk)
        }
        
        for sLink in data.imageLink {
            if let exitLink : Pic = DataBase.checkPropertyExist(entity: Pic.className(), property: "pic", value: sLink) {
                netdisk.addToPic(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Pic", into: DataBase.share.managedObjectContext) as! Pic
            link.creattime = Date()
            link.pic = sLink
            link.addToPicnet(netdisk)
        }
        
        do {
            let context = DataBase.share.managedObjectContext
            if !context.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            }
            if context.hasChanges {
                try context.save()
            }
            completion?(.success)
        } catch {
            completion?(.failed)
            print("Failure to save context: \(error)")
        }
    }
    
    func save(downloadLinks: [ContentInfo], completion: ((SaveState) -> ())?) {
        for data in downloadLinks {
            if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "pageurl", value: data.page) {
                print("------- netdisk exists ------ : \(data.page)")
                completion?(.success)
                return
            }
            if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "title", value: data.title) {
                print("------- netdisk exists ------ : \(data.title)")
                completion?(.success)
                return
            }
            let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into:  DataBase.share.managedObjectContext) as! NetDisk
            netdisk.creattime = Date()
            netdisk.fileName = ""
            netdisk.title = data.title
            netdisk.passwod = data.passwod
            netdisk.pageurl = data.page
            netdisk.msk = data.msk
            netdisk.time = data.time
            netdisk.format = data.format
            netdisk.size = data.size
            netdisk.pic = nil
            netdisk.link = nil
            
            for sLink in data.downloafLink {
                if let exitLink : Link = DataBase.checkPropertyExist(entity: Link.className(), property: "link", value: sLink) {
                    netdisk.addToLink(exitLink)
                    continue
                }
                let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: DataBase.share.managedObjectContext) as! Link
                link.creattime = Date()
                link.link = sLink
                link.addToLinknet(netdisk)
            }
            
            for sLink in data.imageLink {
                if let exitLink : Pic = DataBase.checkPropertyExist(entity: Pic.className(), property: "pic", value: sLink) {
                    netdisk.addToPic(exitLink)
                    continue
                }
                let link = NSEntityDescription.insertNewObject(forEntityName: "Pic", into: DataBase.share.managedObjectContext) as! Pic
                link.creattime = Date()
                link.pic = sLink
                link.addToPicnet(netdisk)
            }
        }
        
        do {
            let context = DataBase.share.managedObjectContext
            if !context.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            }
            if context.hasChanges {
                try context.save()
            }
            completion?(.success)
        } catch {
            completion?(.failed)
            print("Failure to save context: \(error)")
        }
    }
    
    func saveRemoteDownloadLink(data: RemoteNetDisk, completion: ((SaveState) -> ())?) {
        if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "pageurl", value: data.pageurl) {
            print("------- netdisk exists ------ : \(data.pageurl)")
            completion?(.success)
            return
        }
        if let _ : NetDisk = DataBase.checkPropertyExist(entity: NetDisk.className(), property: "title", value: data.title) {
            print("------- netdisk exists ------ : \(data.title)")
            completion?(.success)
            return
        }
        let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into:  DataBase.share.managedObjectContext) as! NetDisk
        netdisk.creattime = Date()
        netdisk.fileName = ""
        netdisk.title = data.title
        netdisk.passwod = data.passwod
        netdisk.pageurl = data.pageurl
        netdisk.msk = data.msk
        netdisk.time = data.time
        netdisk.format = data.format
        netdisk.size = data.size
        netdisk.pic = nil
        netdisk.link = nil
        
        for sLink in data.links {
            if let exitLink : Link = DataBase.checkPropertyExist(entity: Link.className(), property: "link", value: sLink) {
                netdisk.addToLink(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Link", into: DataBase.share.managedObjectContext) as! Link
            link.creattime = Date()
            link.link = sLink
            link.addToLinknet(netdisk)
        }
        
        for sLink in data.pics {
            if let exitLink : Pic = DataBase.checkPropertyExist(entity: Pic.className(), property: "pic", value: sLink) {
                netdisk.addToPic(exitLink)
                continue
            }
            let link = NSEntityDescription.insertNewObject(forEntityName: "Pic", into: DataBase.share.managedObjectContext) as! Pic
            link.creattime = Date()
            link.pic = sLink
            link.addToPicnet(netdisk)
        }
        
        do {
            let context = DataBase.share.managedObjectContext
            if !context.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            }
            if context.hasChanges {
                try context.save()
            }
            completion?(.success)
        } catch {
            completion?(.failed)
            print("Failure to save context: \(error)")
        }
    }
}
