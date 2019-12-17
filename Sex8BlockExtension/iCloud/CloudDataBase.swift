//
//  CloudDataBase.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2019/12/17.
//  Copyright © 2019 ascp. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class CloudDataBase {
    static let share = CloudDataBase()
    
    /// 删除所有本地云端数据存储测试数据
    func removeAllCPRecords() {
        let fetchRequest = NSFetchRequest<NDMoive>(entityName: "NDMoive")
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchRequest2 = NSFetchRequest<NDLink>(entityName: "NDLink")
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchRequest3 = NSFetchRequest<NDImage>(entityName: "NDImage")
        fetchRequest.predicate = NSPredicate(value: true)
        do {
            for i in [fetchRequest, fetchRequest2, fetchRequest3] {
                let results = try CloudDataBase.share.persistentContainer.viewContext.fetch(i as! NSFetchRequest<NSFetchRequestResult>)
                results.forEach({
                    CloudDataBase.share.persistentContainer.viewContext.delete($0 as! NSManagedObject)
                })
            }
            
            try CloudDataBase.share.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func testFetchOp() {
        let fetchRequest = NSFetchRequest<OPMovie>(entityName: "OPMovie")
        fetchRequest.predicate = NSPredicate(value: true)
        do {
            let results = try DataBase.share.persistentContainer.viewContext.fetch(fetchRequest)
            results.forEach({
                print($0.href ?? ">>>> oppps!")
            })
        } catch {
            print(error)
        }
    }
    
    /// 将本地数据库存储的记录复制到云端
    /// - Parameters:
    ///   - items: 本地数据库存储的所有数据
    ///   - completion: 执行回调
    func move(items: [OPMovie], completion: ((Result<Bool, Error>) -> ())?) {
        var count = 0
        let viewContext = CloudDataBase.share.persistentContainer.viewContext
        let transformer = StringArrayTransformer()
        items.forEach({
            let mov = NDMoive(context: viewContext)
            mov.title = $0.title
            mov.href = $0.href
            mov.boradType = $0.boradType
            mov.fileSize = $0.fileSize
            mov.password = $0.password
            mov.favorite = 0

            for i in transformer.transformedValue($0.images) as? [String] ?? [] {
                let img = NDImage(context: viewContext)
                img.pic = i
                viewContext.insert(img)
            }
            
            for i in transformer.transformedValue($0.downloads) as? [String] ?? [] {
                let link = NDLink(context: viewContext)
                link.url = i
                viewContext.insert(link)
            }

            viewContext.insert(mov)
            count += 1
            if count % 1000 == 0 {
                print(">>> Move count: \(count)")
            }
        })
        DispatchQueue.main.async {
            CloudDataBase.share.saveContext()
        }
        completion?(.success(true))
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "CloudData")
        let identifier = "iCloud.com.ascp.S8Blocker"
        
        let path = try! FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
        
        // Create a store description for a local store
        let localStoreLocation = URL(fileURLWithPath: path.appendingPathComponent("moviel.store").path)
        let localStoreDescription = NSPersistentStoreDescription(url: localStoreLocation)
        localStoreDescription.configuration = "Local"
        
        // Create a store description for a CloudKit-backed local store
        let cloudStoreLocation = URL(fileURLWithPath: path.appendingPathComponent("moviec.store").path)
        let cloudStoreDescription = NSPersistentStoreDescription(url: cloudStoreLocation)
        cloudStoreDescription.configuration = "Cloud"

        // Set the container options on the cloud store
        cloudStoreDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: identifier)
        
        // Update the container's list of store descriptions
        container.persistentStoreDescriptions = [
            cloudStoreDescription,
            localStoreDescription
        ]
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
