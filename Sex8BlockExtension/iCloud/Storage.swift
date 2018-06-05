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

typealias SaveCompletion = (CKRecord?, Error?) -> Void
typealias ValidateCompletion = (CKAccountStatus, Error?) -> Void
typealias QueryCompletion = (CKQueryCursor?, Error?) -> Void
typealias FetchRecordCompletion = (NetDisk) -> Void

protocol CloudSaver {
    
}

extension CloudSaver {
    /// 复制私有区域数据到公共区域
    ///
    /// - Parameter cursor: 若为nil。则说明是开始，否则是获取下一个batch
    func copyPrivateToPublic(cursor: CKQueryCursor?) {
        let container = CKContainer.default()
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
    func save(netDisk: NetDiskModal, completion: @escaping SaveCompletion) {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        let record = CKRecord(recordType: RecordType.ndMovie.rawValue)
        record.load(netDisk: netDisk)
        privateDatabase.save(record, completionHandler: completion)
    }
    
    /// 查询所有网盘数据
    ///
    /// - Parameters:
    ///   - fetchBlock: 获取到一条记录回调
    ///   - completion: 获取请求完成回调
    ///   - site: 指定的版块
    func queryAllMovies(fetchBlock: @escaping FetchRecordCompletion, completion: @escaping QueryCompletion, site: String) {
        let container = CKContainer.default()
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
        let container = CKContainer.default()
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
        let container = CKContainer.default()
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
        operation.recordFetchedBlock = { rd in
            database.delete(withRecordID: rd.recordID, completionHandler: { (id, err) in
                if let e = err {
                    print(e)
                    return
                }
                print("Delete OK \(id!)")
            })
        }
        operation.queryCompletionBlock = { (cursor, err) in
            print("Fetch finished!")
        }
        database.add(operation)
    }
}


// MARK: - 模型和记录实例之间转换
extension CKRecord {
    /// 载入网盘信息到当前记录
    ///
    /// - Parameter netDisk: 网盘数据模型
    func load(netDisk: NetDiskModal) {
        self["title"]  = netDisk.title as NSString
        self["href"]  = netDisk.href as NSString
        self["password"]  = netDisk.password as NSString
        self["fileSize"]  = netDisk.fileSize as NSString
        self["downloads"]  = netDisk.downloads.map({ $0 as NSString }) as CKRecordValue
        self["images"]  = netDisk.images.map({ $0 as NSString }) as CKRecordValue
        self["boradType"] = netDisk.boradType as NSString
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
    func convertModal() -> NetDiskModal {
        var modal = NetDiskModal()
        modal.title = self["title"] as! String
        modal.href = self["href"] as! String
        modal.fileSize = self["fileSize"] as! String
        modal.password = self["password"] as! String
        modal.downloads = self["downloads"] as! [String]
        modal.images = self["images"] as! [String]
        modal.boradType = self["boradType"] as! String
        return modal
    }
}
