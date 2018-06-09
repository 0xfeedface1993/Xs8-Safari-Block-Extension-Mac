//
//  Storage.swift
//  S8Blocker
//
//  Created by virus1994 on 2018/5/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import CloudKit

enum RecordType : String {
    case ndMovie = "NDMoive"
}

struct CloudData {
    var contentInfo: ContentInfo
    var site: String
}

struct RecordModal {
    var recordID: CKRecordID
    var href: String
    var isMet = false
}

typealias SaveCompletion = (CKRecord?, Error?) -> Void
typealias ValidateCompletion = (CKAccountStatus, Error?) -> Void
typealias QueryCompletion = (CKQueryCursor?, Error?) -> Void
typealias FetchRecordCompletion = (CloudData) -> Void

protocol CloudSaver {
    
}

extension CloudSaver {
    /// 复制私有区域数据到公共区域
    ///
    /// - Parameter cursor: 若为nil。则说明是开始，否则是获取下一个batch
    func copyPrivateToPublic(cursor: CKQueryCursor?) {
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
        let publicDatabase = container.publicCloudDatabase
        let record = CKRecord(recordType: RecordType.ndMovie.rawValue)
        record.load(netDisk: netDisk)
        publicDatabase.save(record, completionHandler: completion)
    }
    
    /// 查询所有网盘数据
    ///
    /// - Parameters:
    ///   - fetchBlock: 获取到一条记录回调
    ///   - completion: 获取请求完成回调
    ///   - site: 指定的版块
    func queryAllMovies(fetchBlock: @escaping FetchRecordCompletion, completion: @escaping QueryCompletion, site: String) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let publicDatabase = container.publicCloudDatabase
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
        publicDatabase.add(operation)
    }
    
    /// 获取下一页网盘数据
    ///
    /// - Parameters:
    ///   - cursor: 上一页的位置指示
    ///   - fetchBlock: 获取一条记录的回调
    ///   - completion: 获取请求完成回调
    func queryNextPageMovies(cursor: CKQueryCursor, fetchBlock: @escaping FetchRecordCompletion, completion: @escaping QueryCompletion) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let publicDatabase = container.publicCloudDatabase
        let operation = CKQueryOperation(cursor: cursor)
        operation.recordFetchedBlock = { rd in
            fetchBlock(rd.convertModal())
        }
        operation.queryCompletionBlock = { (csr, err) in
            completion(csr, err)
        }
        publicDatabase.add(operation)
    }
    
    /// 将公有库中所有记录修改为指定版块
    ///
    /// - Parameters:
    ///   - boardType: 指定版块
    ///   - cursor: 上一个batch
    func add(boardType: String, cursor: CKQueryCursor?) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        let operation = cursor == nil ? CKQueryOperation(query: query):CKQueryOperation(cursor: cursor!)
        let publicDatabase = container.publicCloudDatabase
        operation.recordFetchedBlock = { (record) in
            record["boradType"] = boardType as NSString as CKRecordValue
            publicDatabase.save(record, completionHandler: { (recc, errr) in
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
        publicDatabase.add(operation)
    }
    
    /// 清空数据库内网盘记录
    ///
    /// - Parameter database: 数据库类型（私有、公有)
    func empty(database: CKDatabase) {
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        var records = [CKRecordID]()
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
    func delete(records: [CKRecordID], database: CKDatabase, completion: (()->Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: records)
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
    
    func check(title: String, completion: @escaping ([CKRecordID])->Void) {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let publicCloudDatabase = container.publicCloudDatabase
        let predict = NSPredicate(format: "%K = %@", "href", title)
        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: predict)
        let operation = CKQueryOperation(query: query)
        var recs = [CKRecordID]()
        operation.recordFetchedBlock = { rd in
            recs.append(rd.recordID)
        }
        operation.completionBlock = {
            completion(recs)
        }
        publicCloudDatabase.add(operation)
    }
    
    func deleteDuplicateRecord() {
        let container = CKContainer(identifier: "iCloud.com.ascp.S8Blocker")
        let publicDatabase = container.publicCloudDatabase
        var allRecords = [CKRecord]()
        
        func search(operation: CKQueryOperation?, cursor: CKQueryCursor?, completion: @escaping ()->Void) {
            var op : CKQueryOperation!
            if operation != nil {
                op = operation!
            }   else if cursor != nil {
                op = CKQueryOperation(cursor: cursor!)
            }   else    {
                completion()
                return
            }
            var cur : CKQueryCursor?
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
                if recs.count <= 0 {
                    return
                }
                allRecords += recs
                print("------- Fetch \(allRecords.count) records")
                let records = findAndMove(records: recs.map({ RecordModal(recordID: $0.recordID, href: $0["title"] as! String, isMet: false) })).map({ $0.recordID })
                self.delete(records: records, database: publicDatabase)
                search(operation: nil, cursor: cur, completion: completion)
            }
            publicDatabase.add(op)
        }
        
        func findAndMove(records: [RecordModal]) -> [RecordModal] {
            guard let first = records.first else {
                return []
            }
            
            let href = first.href
            let removeGroup = records.filter({ href == $0.href })
            
            if removeGroup.count <= 1 {
                let reduceRecords = records.dropFirst()
                if reduceRecords.count <= 1 {
                    return []
                }
                return findAndMove(records: [RecordModal](reduceRecords))
            }   else    {
                let deleteRecords = [RecordModal](removeGroup.dropFirst())
                let reduceRecords = [RecordModal](records.drop(while: { href == $0.href }))
                return findAndMove(records: reduceRecords) + deleteRecords
            }
        }

        let query = CKQuery(recordType: RecordType.ndMovie.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false)]
        let operation = CKQueryOperation(query: query)
        search(operation: operation, cursor: nil, completion: {
            print("Finished")
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
