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
    private var movieResultFetchController : NSFetchedResultsController<NDMoive>!
    private var imageResultFetchController : NSFetchedResultsController<NDImage>!
    private var linksResultFetchController : NSFetchedResultsController<NDLink>!
    
    init() {
        let sort = NSSortDescriptor(key: "", ascending: true)
        let fetchRequest = NSFetchRequest<NDMoive>(entityName: "NDMoive")
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchRequest2 = NSFetchRequest<NDLink>(entityName: "NDLink")
        fetchRequest2.predicate = NSPredicate(value: true)
        let fetchRequest3 = NSFetchRequest<NDImage>(entityName: "NDImage")
        fetchRequest3.predicate = NSPredicate(value: true)
        
//        movieResultFetchController = NSFetchedResultsController(fetchRequest: <#T##NSFetchRequest<_>#>, managedObjectContext: <#T##NSManagedObjectContext#>, sectionNameKeyPath: <#T##String?#>, cacheName: <#T##String?#>)
    }
    
    /// 删除所有本地云端数据存储测试数据
    func removeAllCPRecords() {
        let fetchRequest = NSFetchRequest<NDMoive>(entityName: "NDMoive")
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchRequest2 = NSFetchRequest<NDLink>(entityName: "NDLink")
        fetchRequest2.predicate = NSPredicate(value: true)
        let fetchRequest3 = NSFetchRequest<NDImage>(entityName: "NDImage")
        fetchRequest3.predicate = NSPredicate(value: true)
        let viewContext = CloudDataBase.share.backgroundViewContext
        do {
            for i in [fetchRequest, fetchRequest2, fetchRequest3] {
                try viewContext.setQueryGenerationFrom(.current)
                let results = try viewContext.fetch(i as! NSFetchRequest<NSFetchRequestResult>)
                while results.count > 0 {
                    viewContext.delete(results.first as! NSManagedObject)
                }
            }
            
            viewContext.perform {
                CloudDataBase.share.saveBacgroundContext()
                self.mainViewContext.perform {
                    CloudDataBase.share.saveMainContext()
                }
            }
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
    
    /// 查找并移除相同记录，根据名称判断是否相同
    func removeSameRecords() {
        let viewContext = DataBase.share.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<OPMovie>(entityName: "OPMovie")
        fetchRequest.predicate = NSPredicate(value: true)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            var records = [String:[OPMovie]]()
            for i in results {
                guard let title = i.title else {
                    continue
                }
                guard let items = records[title] else {
                    records[title] = [i]
                    continue
                }
                if items.contains(i) {
                    continue
                }
                
                records[title]?.append(i)
            }
            
            for i in records {
                if i.value.count <= 1 {
                    continue
                }
                print(">>> item: \(i.key), count: \(i.value.count)")
                for j in 1..<i.value.count {
                    print(">>> delete : \(i.value[j].title ?? "oops!")")
                    viewContext.delete(i.value[j])
                }
            }
            try DataBase.share.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func removeSameCDRecords() {
        let viewContext = backgroundViewContext
        let fetchRequest = NSFetchRequest<NDMoive>(entityName: "NDMoive")
        fetchRequest.predicate = NSPredicate(value: true)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            var records = [String:[NDMoive]]()
            for i in results {
                guard let title = i.title else {
                    continue
                }
                guard let items = records[title] else {
                    records[title] = [i]
                    continue
                }
                if items.contains(i) {
                    continue
                }
                
                records[title]?.append(i)
            }
            
            for i in records {
                if i.value.count <= 1 {
                    continue
                }
                print(">>> item: \(i.key), count: \(i.value.count)")
                for j in 1..<i.value.count {
                    print(">>> delete : \(i.value[j].title ?? "oops!")")
                    viewContext.delete(i.value[j])
                }
            }
            viewContext.perform {
                CloudDataBase.share.saveBacgroundContext()
                self.mainViewContext.perform {
                    CloudDataBase.share.saveMainContext()
                }
            }
        } catch {
            print(error)
        }
    }
    
    /// 将本地数据库存储的记录复制到云端
    /// - Parameters:
    ///   - items: 本地数据库存储的所有数据
    ///   - completion: 执行回调
    func move(items: [OPMovie], test: Bool = false, completion: ((Result<Bool, Error>) -> ())?) {
        var count = 0
        let viewContext = backgroundViewContext
        items.forEach({
            let mov = NDMoive(context: viewContext)
            mov.title = $0.title
            mov.href = $0.href
            mov.boradType = $0.boradType
            mov.fileSize = $0.fileSize
            mov.password = $0.password
            mov.favorite = 0

            if !test {
                let fetchRequest = NSFetchRequest<NDMoive>(entityName: "NDMoive")
                fetchRequest.predicate = NSPredicate(format: "title == %@", $0.title ?? "")
                
                do {
                    let count = try viewContext.count(for: fetchRequest)
                    guard count <= 0 else {
                        print(">>> Found \($0.title ?? "oops") movie: \(count)")
                        return
                    }
                    
                    viewContext.insert(mov)
                } catch {
                    print(error)
                }
            }
            count += 1
            if count % 1000 == 0 {
                print(">>> Move count: \(count)")
            }
        })
        
        if !test {
            viewContext.perform {
                CloudDataBase.share.saveBacgroundContext()
                self.mainViewContext.perform {
                    CloudDataBase.share.saveMainContext()
                }
            }
        }
        
        completion?(.success(true))
    }
    
    /// 测试获取相同图片和地址链接
    /// - Parameter items: 抓取原始数据
    func findSameImageLink(items: [OPMovie]) {
        let viewContext = DataBase.share.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<OPMovie>(entityName: "OPMovie")
        fetchRequest.predicate = NSPredicate(value: true)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            func getRecords(keyPath: AnyKeyPath) -> [String:Int] {
                var records = [String:Int]()
                let transformer = StringArrayTransformer()
                for i in results {
                    guard let v = i[keyPath: keyPath] as? NSData, let values = transformer.transformedValue(v) as? [String]  else {
                        continue
                    }
                    
                    for j in values {
                        guard let _ = records[j] else {
                            records[j] = 1
                            continue
                        }
                        
                        records[j]? += 1
                    }
                }
                return records
            }
            let images = getRecords(keyPath: \OPMovie.images)
            let links = getRecords(keyPath: \OPMovie.downloads)
            print(">>> images same items count: \(images.filter({ $0.value > 1 }).count)")
            print(">>> links same items count: \(links.filter({ $0.value > 1 }).count)")
            for i in images {
                if i.value <= 1 {
                    continue
                }
                print(">>> item: \(i.key), count: \(i.value)")
            }
            
            for i in links {
                if i.value <= 1 {
                    continue
                }
                print(">>> item: \(i.key), count: \(i.value)")
            }
            
        } catch {
            print(error)
        }
    }
    
    func moveImagesAndLinks(items: [OPMovie], test: Bool = false, completion: ((Result<Bool, Error>) -> ())?) {
        var count = 0
        let viewContext = backgroundViewContext
        let transformer = StringArrayTransformer()
        
        func saveBaby() {
            if viewContext.hasChanges {
                viewContext.performAndWait {
                    self.saveBacgroundContext()
                    self.mainViewContext.perform {
                        self.saveMainContext()
                    }
                    self.persistentContainer.viewContext.perform {
                        self.saveContext()
                    }
                }
            }
        }
        
        var start = Date()
        var flag = true
        for item in items {
            if flag {
                flag = false
                start = Date()
            }
            guard let href = item.href else { return }
            let request = NSFetchRequest<NDMoive>(entityName: "NDMoive")
            request.predicate = NSPredicate(format: "href == %@", href)
            
            do {
                guard let mov = try viewContext.fetch(request).first else { return }
                let images = (transformer.transformedValue(item.images) as? [String] ?? []).removeSameString()
                for i in images {
                    self.findImageObject(context: viewContext, pic: i) { result in
                        switch result {
                        case .success(let img):
                            if !test {
                                mov.addToImages(img)
                            }
                        case .failure(_):
                            print(">>> Error Accuce! <<<")
                        }
                    }
                }
                
                let links = (transformer.transformedValue(item.downloads) as? [String] ?? []).removeSameString()
                for i in links {
                    self.findLinkObject(context: viewContext, url: i) { result in
                        switch result {
                        case .success(let link):
                            if !test {
                                mov.addToDownloads(link)
                            }
                        case .failure(_):
                            print(">>> Error Accuce! <<<")
                        }
                    }
                }
                
                
                count += 1
                if count % 1000 == 0 {
                    print(">>> Move count: \(count)")
                    let end = Date()
                    print(">>> process take \(end.timeIntervalSince(start)) s")
                    flag = true
                }
                
                if !test {
                    saveBaby()
                }
            } catch {
                print(error)
            }
        }
//        items.forEach({
//            if flag {
//                flag = false
//                start = Date()
//            }
//            guard let href = $0.href else { return }
//            let request = NSFetchRequest<NDMoive>(entityName: "NDMoive")
//            request.predicate = NSPredicate(format: "href == %@", href)
//
//            do {
//                guard let mov = try viewContext.fetch(request).first else { return }
//                let images = (transformer.transformedValue($0.images) as? [String] ?? []).removeSameString()
//                for i in images {
//                    self.findImageObject(context: viewContext, pic: i) { result in
//                        switch result {
//                        case .success(let img):
//                            if !test {
//                                mov.addToImages(img)
//                            }
//                        case .failure(_):
//                            print(">>> Error Accuce! <<<")
//                        }
//                    }
//                }
//
//                let links = (transformer.transformedValue($0.downloads) as? [String] ?? []).removeSameString()
//                for i in links {
//                    self.findLinkObject(context: viewContext, url: i) { result in
//                        switch result {
//                        case .success(let link):
//                            if !test {
//                                mov.addToDownloads(link)
//                            }
//                        case .failure(_):
//                            print(">>> Error Accuce! <<<")
//                        }
//                    }
//                }
//
//
//                count += 1
//                if count % 1000 == 0 {
//                    print(">>> Move count: \(count)")
//                    let end = Date()
//                    print(">>> process take \(end.timeIntervalSince(start)) s")
//                    flag = true
//                }
//
//                if !test {
//                    saveBaby()
//                }
//            } catch {
//                print(error)
//            }
//        })
        
        completion?(.success(true))
    }
    
    /// 获取图像记录，若存在则从数据库查询返回, 否则创建新记录
    /// - Parameters:
    ///   - context: CoreData上下文
    ///   - pic: 图片链接
    ///   - completion: 结果回调，一般不会失败
    func findImageObject(context: NSManagedObjectContext, pic: String, completion: (Result<NDImage, Error>) -> ()) {
        let imageRequest = NSFetchRequest<NDImage>(entityName: "NDImage")
        imageRequest.predicate = NSPredicate(format: "pic == %@", pic)
        imageRequest.fetchLimit = 1
        do {
            guard let img = try context.fetch(imageRequest).first else {
                let img = NDImage(context: context)
                img.pic = pic
//                print(">>> Insert image item \(img.pic ?? "oops!")")
                return completion(.success(img))
            }
//            print(">>> Found image item \(img.pic ?? "oops!").")
            return completion(.success(img))
        } catch {
            print(error)
            return completion(.failure(error))
        }
    }
    
    /// 获取下载地址记录，若存在则从数据库查询返回, 否则创建新记录
    /// - Parameters:
    ///   - context: CoreData上下文
    ///   - url: 下载地址链接
    ///   - completion: 结果回调，一般不会失败
    func findLinkObject(context: NSManagedObjectContext, url: String, completion: (Result<NDLink, Error>) -> ()) {
        let imageRequest = NSFetchRequest<NDLink>(entityName: "NDLink")
        imageRequest.predicate = NSPredicate(format: "url == %@", url)
        imageRequest.fetchLimit = 1
        do {
            guard let img = try context.fetch(imageRequest).first else {
                let img = NDLink(context: context)
                img.url = url
//                print(">>> Insert link item \(img.url ?? "oops!")")
                return completion(.success(img))
            }
//            print(">>> Found link item \(img.url ?? "oops!").")
            return completion(.success(img))
        } catch {
            print(error)
            return completion(.failure(error))
        }
    }
    
    /// 添加或修改数据，存在则修改，不存在则插入新数据
    /// - Parameter data: 抓取的数据列表
    func add(data: [CloudData], test: Bool = false) {
        CloudDataBase.share.persistentContainer.performBackgroundTask({ viewContext in
            viewContext.mergePolicy = NSMergePolicy.overwrite
            func saveBaby() {
                if viewContext.hasChanges {
                    do {
                        try viewContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
            
            data.forEach({
                let request = NSFetchRequest<NDMoive>(entityName: "NDMoive")
                request.predicate = NSPredicate(format: "href == %@ OR title == %@", $0.contentInfo.page, $0.contentInfo.title)
                
                do {
                    try viewContext.setQueryGenerationFrom(.current)
                    let results = try viewContext.fetch(request)
                    let mov = results.first ?? NDMoive(context: viewContext)
                    mov.boradType = $0.site
                    mov.fileSize = mov.fileSize ?? $0.contentInfo.size
                    mov.href = mov.href ?? $0.contentInfo.page
                    mov.password = mov.password ?? $0.contentInfo.passwod
                    mov.title = mov.title ?? $0.contentInfo.title
                    
                    print("------------------ movie \(mov), \($0.contentInfo.page)")
                    for i in $0.contentInfo.imageLink {
                        self.findImageObject(context: viewContext, pic: i) { result in
                            switch result {
                            case .success(let img):
                                if !test {
                                    mov.addToImages(img)
                                }
                            case .failure(_):
                                print(">>> Error Accuce! <<<")
                            }
                        }
                    }
                    
                    for i in $0.contentInfo.downloafLink {
                        self.findLinkObject(context: viewContext, url: i) { result in
                            switch result {
                            case .success(let link):
                                if !test {
                                    mov.addToDownloads(link)
                                }
                            case .failure(_):
                                print(">>> Error Accuce! <<<")
                            }
                        }
                    }
                    
                    if results.count <= 0 {
                        if !test, results.count <= 0 {
                            viewContext.insert(mov)
                        }
                        print(">>> Insert new records. \(mov)")
                    }
                } catch {
                    print(error)
                }
            })
            if test {
                return
            }
            
            saveBaby()
            print(">>> Batch Add Done!")
        })
    }
    
    // MARK: - Core Data stack
    /// 主线程上下文，用于UI更新
    lazy var mainViewContext : NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = CloudDataBase.share.persistentContainer.persistentStoreCoordinator
        return context
    }()
    
    /// 默认上下文，用于操作数据，尽量不阻塞主线程
    lazy var backgroundViewContext : NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CloudDataBase.share.persistentContainer.viewContext
        return context
    }()
    
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
    
    func saveMainContext() {
        let context = mainViewContext
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func saveBacgroundContext() {
        let context = backgroundViewContext
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


extension Array where Element == String {
    func removeSameString() -> [String] {
        let sets = Set(self).map({ $0 })
        return sets
    }
}
