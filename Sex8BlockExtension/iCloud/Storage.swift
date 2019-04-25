//
//  Storage.swift
//  S8Blocker
//
//  Created by virus1994 on 2018/5/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import CloudKit
import CommonCrypto

enum RecordType : String {
    case ndMovie = "NDMoive"
}

struct CloudData {
    var contentInfo: ContentInfo
    var site: String
}

struct RecordModal {
    var recordID: CKRecord.ID
    var href: String
    var isMet = false
}

typealias SaveCompletion = (CKRecord?, Error?) -> Void
typealias ValidateCompletion = (CKAccountStatus, Error?) -> Void
typealias QueryCompletion = (CKQueryOperation.Cursor?, Error?) -> Void
typealias FetchRecordCompletion = (CloudData) -> Void

protocol CloudSaver {
    
}

extension CloudSaver {
    /// 复制私有区域数据到公共区域
    ///
    /// - Parameter cursor: 若为nil。则说明是开始，否则是获取下一个batch
    func copyPrivateToPublic(cursor: CKQueryOperation.Cursor?) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateDatabase = container.privateCloudDatabase
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let operation = cursor == nil ? CKQueryOperation(query: query):CKQueryOperation(cursor: cursor!)
        operation.recordFetchedBlock = { (record) in
            let newRecord = CKRecord(recordType: record.recordType)
            newRecord.load(record: record)
            let publicDatabase = container.publicCloudDatabase
            publicDatabase.save(newRecord, completionHandler: { (recc, errr) in
                if let e = errr {
                    print(e)
                    return
                }
                print("Save OK \(recc!.recordID)")
            })
        }
        operation.queryCompletionBlock = { (records, err) in
            if let e = err {
                print(e)
                return
            }
            self.copyPrivateToPublic(cursor: records)
        }
        privateDatabase.add(operation)
    }
    
    /// 保存记录
    ///
    /// - Parameters:
    ///   - netDisk: 网盘数据模型
    ///   - completion: 执行回调
    func save(netDisk: CloudData, completion: @escaping SaveCompletion) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        let record = CKRecord(recordType: RecordType.ndMovie.rawValue)
        record.load(netDisk: netDisk)
        privateCloudDatabase.save(record, completionHandler: completion)
    }
    
    func save(datas: [CloudData], completion: @escaping SaveCompletion) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        let records = datas.map({ r -> CKRecord in
            let record = CKRecord(recordType: RecordType.ndMovie.rawValue)
            record.load(netDisk: r)
            return record
        })
        let opreration = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        privateCloudDatabase.add(opreration)
    }
    
    /// 查询所有网盘数据
    ///
    /// - Parameters:
    ///   - fetchBlock: 获取到一条记录回调
    ///   - completion: 获取请求完成回调
    ///   - site: 指定的版块
    func queryAllMovies(fetchBlock: @escaping FetchRecordCompletion, completion: @escaping QueryCompletion, site: String) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(format: "boradType = %@", site)
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let operation = CKQueryOperation(query: query)
        operation.recordFetchedBlock = { rd in
            fetchBlock(rd.convertModal())
        }
        operation.queryCompletionBlock = { (cursor, err) in
            completion(cursor, err)
        }
        privateCloudDatabase.add(operation)
    }
    
    /// 获取下一页网盘数据
    ///
    /// - Parameters:
    ///   - cursor: 上一页的位置指示
    ///   - fetchBlock: 获取一条记录的回调
    ///   - completion: 获取请求完成回调
    func queryNextPageMovies(cursor: CKQueryOperation.Cursor, fetchBlock: @escaping FetchRecordCompletion, completion: @escaping QueryCompletion) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        let operation = CKQueryOperation(cursor: cursor)
        operation.recordFetchedBlock = { rd in
            fetchBlock(rd.convertModal())
        }
        operation.queryCompletionBlock = { (csr, err) in
            completion(csr, err)
        }
        privateCloudDatabase.add(operation)
    }
    
    /// 将公有库中所有记录修改为指定版块
    ///
    /// - Parameters:
    ///   - boardType: 指定版块
    ///   - cursor: 上一个batch
    func add(boardType: String, cursor: CKQueryOperation.Cursor?) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        let operation = cursor == nil ? CKQueryOperation(query: query):CKQueryOperation(cursor: cursor!)
        let privateCloudDatabase = container.privateCloudDatabase
        operation.recordFetchedBlock = { (record) in
            record["boradType"] = boardType as NSString as CKRecordValue
            privateCloudDatabase.save(record, completionHandler: { (recc, errr) in
                if let e = errr {
                    print(e)
                    return
                }
                print("Save OK \(recc!.recordID)")
            })
        }
        operation.queryCompletionBlock = { csr, err in
            if let e = err {
                print(e)
                return
            }
            if let csr = csr {
                self.add(boardType: boardType, cursor: csr)
            }
        }
        privateCloudDatabase.add(operation)
    }
    
    /// 清空数据库内网盘记录
    ///
    /// - Parameter database: 数据库类型（私有、公有)
    func empty(database: CKDatabase) {
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        var records = [CKRecord.ID]()
        operation.recordFetchedBlock = { rd in
            print("Found : \(rd.recordID)")
            records.append(rd.recordID)
        }
        operation.queryCompletionBlock = { (cursor, err) in
            if let e = err {
                print(e)
                return
            }
        }
        operation.completionBlock = {
            if records.count > 0 {
                self.delete(records: records, database: database)
                self.empty(database: database)
            }
        }
        database.add(operation)
    }
    
    /// 批量删除记录
    ///
    /// - Parameters:
    ///   - records: 需要删除的记录ID
    ///   - database: 私有还是公有数据库
    func delete(records: [CKRecord.ID], database: CKDatabase, completion: (()->Void)? = nil) {
        var count = 0
        let datas = records.enumerated()
        while count < records.count {
            let bottom = count
            count += 400
            let batchs = datas.filter({ $0.offset < count && $0.offset >= bottom }).map({ $0.element })
            if batchs.count <= 0 {
                break
            }
            modifiy(saveRecords: [], deleteRecordsID: batchs, database: database) {
                print("Batchs \(bottom)")
            }
        }
    }
    
    func modifiy(saveRecords: [CKRecord], deleteRecordsID: [CKRecord.ID], database: CKDatabase, completion: (()->Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: saveRecords, recordIDsToDelete: deleteRecordsID)
        operation.modifyRecordsCompletionBlock = {(_, results, err) in
            if let e = err {
                print(e)
                return
            }
            
            if let results = results {
                results.forEach({ print("Delete ok: \($0.recordName)") })
            }
            
            completion?()
        }
        database.add(operation)
    }
    
    // 计算标题MD5值
    func remakerMD5(recall: (() -> Void)? = nil) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        var allRecords = [CKRecord]()
        
        func search(operation: CKQueryOperation?, cursor: CKQueryOperation.Cursor?, completion: @escaping ()->Void) {
            var op : CKQueryOperation!
            if operation != nil {
                op = operation!
            }   else if cursor != nil {
                op = CKQueryOperation(cursor: cursor!)
            }   else    {
                completion()
                return
            }
            var cur : CKQueryOperation.Cursor?
            var recs = [CKRecord]()
            op.recordFetchedBlock = { rd in
                recs.append(rd)
            }
            op.queryCompletionBlock = { c, err in
                if let e = err {
                    print(e)
                    return
                }
                cur = c
            }
            op.completionBlock = {
                allRecords += recs
                print("------- Fetch \(allRecords.count) records")
                search(operation: nil, cursor: cur, completion: completion)
            }
            privateCloudDatabase.add(op)
        }
        
        let predict = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predict)
        let operation = CKQueryOperation(query: query)
        search(operation: operation, cursor: nil, completion: {
            allRecords.forEach({
                $0["titleMD5"] = ($0["title"] as! String).md5()
            })
            self.batchSave(records: allRecords, database: privateCloudDatabase)
            recall?()
            print("Finished")
        })
    }
    
    func batchSave(records: [CKRecord], database: CKDatabase) {
        let group = DispatchGroup()
        var count = 0
        let datas = records.enumerated()
        while count < records.count {
            let bottom = count
            count += 400
            let batchs = datas.filter({ $0.offset < count && $0.offset >= bottom }).map({ $0.element })
            if batchs.count <= 0 {
                break
            }
            group.enter()
            modifiy(saveRecords: batchs, deleteRecordsID: [], database: database) {
                print("Batchs \(bottom)")
                group.leave()
            }
        }
        group.wait()
    }
    
    func check(href: String, completion: @escaping ([CKRecord.ID])->Void) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        let predict = NSPredicate(format: "%K = %@", "titleMD5", href)
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predict)
        let operation = CKQueryOperation(query: query)
        var recs = [CKRecord.ID]()
        operation.recordFetchedBlock = { rd in
            recs.append(rd.recordID)
        }
        operation.completionBlock = {
            completion(recs)
        }
        privateCloudDatabase.add(operation)
    }
    
    func check(titleMD5s: [String], recall: @escaping ([CKRecord])->Void) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        var allRecords = [CKRecord]()
        
        func search(operation: CKQueryOperation?, cursor: CKQueryOperation.Cursor?, completion: @escaping ()->Void) {
            var op : CKQueryOperation!
            if operation != nil {
                op = operation!
            }   else if cursor != nil {
                op = CKQueryOperation(cursor: cursor!)
            }   else    {
                completion()
                return
            }
            var cur : CKQueryOperation.Cursor?
            var recs = [CKRecord]()
            op.recordFetchedBlock = { rd in
                recs.append(rd)
            }
            op.queryCompletionBlock = { c, err in
                if let e = err {
                    print(e)
                    return
                }
                cur = c
            }
            op.completionBlock = {
                allRecords += recs
                print("------- Fetch \(allRecords.count) records")
                search(operation: nil, cursor: cur, completion: completion)
            }
            privateCloudDatabase.add(op)
        }
        
        let predictString = "titleMD5 IN { \(titleMD5s.map({ "'\($0)'" }).joined(separator: ", ")) }"
        print(">>>>>> presict: \(predictString)")
        let predict = NSPredicate(format: predictString)
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predict)
        let operation = CKQueryOperation(query: query)
        
        search(operation: operation, cursor: nil, completion: {
            recall(allRecords)
            print(">>>>>> Finished")
        })
    }
    
    /// 删除空记录
    func deleteEmptyRecord(recall: (() -> Void)? = nil) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        var allRecords = [CKRecord]()
        
        func search(operation: CKQueryOperation?, cursor: CKQueryOperation.Cursor?, completion: @escaping ()->Void) {
            var op : CKQueryOperation!
            if operation != nil {
                op = operation!
            }   else if cursor != nil {
                op = CKQueryOperation(cursor: cursor!)
            }   else    {
                completion()
                return
            }
            var cur : CKQueryOperation.Cursor?
            var recs = [CKRecord]()
            op.recordFetchedBlock = { rd in
                recs.append(rd)
            }
            op.queryCompletionBlock = { c, err in
                if let e = err {
                    print(e)
                    return
                }
                cur = c
            }
            op.completionBlock = {
                allRecords += recs
                print("------- Fetch \(allRecords.count) records")
                search(operation: nil, cursor: cur, completion: completion)
            }
            privateCloudDatabase.add(op)
        }
        
        let predict = NSPredicate(format: "title = %@", "")
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predict)
        let operation = CKQueryOperation(query: query)
        search(operation: operation, cursor: nil, completion: {
            self.delete(records: allRecords.map({ $0.recordID }), database: privateCloudDatabase) {
                recall?()
                print("Finished")
            }
        })
    }
    
    /// 删除重复记录，标题相同
    func deleteDuplicateRecord() {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let privateCloudDatabase = container.privateCloudDatabase
        var count = 0
        let groupNameKey = "title"
        var dictRecords = [String:Set<CKRecord.ID>]()
        
        func search(operation: CKQueryOperation?, cursor: CKQueryOperation.Cursor?, completion: @escaping ()->Void) {
            var op : CKQueryOperation!
            if operation != nil {
                op = operation!
            }   else if cursor != nil {
                op = CKQueryOperation(cursor: cursor!)
            }   else    {
                completion()
                return
            }
            var cur : CKQueryOperation.Cursor?
            var recs = [CKRecord]()
//            op.resultsLimit = 91
            op.recordFetchedBlock = { rd in
                recs.append(rd)
            }
            op.queryCompletionBlock = { c, err in
                if let e = err {
                    print(e)
                    return
                }
                cur = c
            }
            op.completionBlock = {
                if recs.count <= 0 {
                    return
                }
                count += recs.count
                print("------- Fetch \(count) records")
                var deleteItems = [String]()
                recs.forEach({
                    let key = $0[groupNameKey] as! String
                    if let _ = dictRecords[key] {
                        dictRecords[key]?.insert($0.recordID)
                        deleteItems.append(key)
                    }   else {
                        dictRecords[key] = Set<CKRecord.ID>()
                    }
                })
                print(deleteItems)
                search(operation: nil, cursor: cur, completion: completion)
            }
            privateCloudDatabase.add(op)
        }

        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: groupNameKey, ascending: false)]
        let operation = CKQueryOperation(query: query)
//        operation.resultsLimit = 91
        search(operation: operation, cursor: nil, completion: {
            let deleteItems = dictRecords.flatMap({ $0.value })
            self.delete(records: deleteItems, database: privateCloudDatabase) {
                print("Finished")
            }
        })
    }
}


// MARK: - 模型和记录实例之间转换
extension CKRecord {
    /// 载入网盘信息到当前记录
    ///
    /// - Parameter netDisk: 网盘数据模型
    func load(netDisk: CloudData) {
        self["title"]  = netDisk.contentInfo.title as NSString
        self["href"]  = netDisk.contentInfo.page as NSString
        self["password"]  = netDisk.contentInfo.passwod as NSString
        self["fileSize"]  = netDisk.contentInfo.size as NSString
        self["downloads"]  = netDisk.contentInfo.downloafLink.map({ $0 as NSString }) as CKRecordValue
        self["images"]  = netDisk.contentInfo.imageLink.map({ $0 as NSString }) as CKRecordValue
        self["boradType"] = netDisk.site as NSString
        self["titleMD5"] = netDisk.contentInfo.titleMD5 as NSString
    }
    
    /// 复制记录实例到自身
    ///
    /// - Parameter record: 需要复制的记录
    func load(record: CKRecord) {
        self["title"] = record["title"]
        self["href"] = record["href"]
        self["fileSize"] = record["fileSize"]
        self["password"] = record["password"]
        self["downloads"] = record["downloads"]
        self["images"] = record["images"]
        self["boradType"] = record["boradType"]
        self["titleMD5"] = record["titleMD5"]
    }
    
    /// 记录失恋转换成网盘数据模型
    ///
    /// - Returns: 网盘数据模型
    func convertModal() -> CloudData {
        var content = ContentInfo()
        content.title = self["title"] as! String
        content.page = self["href"] as! String
        content.size = self["fileSize"] as! String
        content.passwod = self["password"] as! String
        content.downloafLink = self["downloads"] as! [String]
        content.imageLink = self["images"] as! [String]
        return CloudData(contentInfo: content, site: self["boradType"] as! String)
    }
}

// MD5
extension String {
    func md5() -> String {
        let data = self.cString(using: .utf8)!
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let results = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: length)
        CC_MD5(data, CC_LONG(self.lengthOfBytes(using: .utf8)), results)
        var hash = ""
        for i in 0..<length {
            hash += String(format: "%02x", results[i])
        }
        return hash
    }
} 
