//
//  Coordinator.swift
//  CloudFetchBot
//
//  Created by god on 2019/8/6.
//  Copyright © 2019 ascp. All rights reserved.
//

import SwiftUI
import CoreData

class Coordinate {
    var timer : Timer?
    lazy var menus : [ListCategrory] = {
        guard let fileURL = Bundle.main.url(forResource: "categrory", withExtension: "plist") else {
            return [ListCategrory]()
        }
        
        do {
            let file = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            let plist = try decoder.decode([ListCategrory].self, from: file).filter({ $0.segue == "com.ascp.netdisk.list" })
            return plist
        }   catch {
            print(error)
            return [ListCategrory]()
        }
    }()
    var tor: IndexingIterator<[ListCategrory]>?
    var site = Site.netdisk
    var startIndex: UInt = 1
    let pageOffset: UInt = 1
    var startTime: Date!
    var fetchRawData = [CloudData]()
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [unowned self] (t) in
            self.tor = self.menus.makeIterator()
            let bot = FetchBot.shareBot
            bot.delegate = self
            bot.startPage = self.startIndex
            bot.pageOffset = self.pageOffset
            self.site.categrory = self.tor?.next()
            print(">>> Timer fire!!!")
            DispatchQueue.global().async {
                 [unowned self] in
                bot.start(withSite: self.site)
            }
        })
        timer?.fire()
    }
    
    func stop() {
        timer?.invalidate()
        let bot = FetchBot.shareBot
        self.tor = nil
        bot.stop {
            LogItem.log(message: "Stop Timer!")
        }
    }
    
    func batchCheck(items: [CloudData]) {
        let batch = 130
        let remaind = items.count % batch
        let group = items.count > batch ? ((items.count - remaind) / batch + (remaind > 0 ? 1:0)):1
        
        var remianItems = [CloudData]()
        
        for i in 0..<group {
            let minIndex = i * batch
            let maxIndex = (minIndex + batch) >= items.count ? items.count:(minIndex + batch)
            var datas = items[minIndex..<maxIndex]
            let sem = DispatchSemaphore(value: 0)
            check(titleMD5s: datas.map({ $0.contentInfo.titleMD5 })) { (records) in
                let rds = records.map({ $0.convertModal() })
                datas = datas.filter({ k in
                    return !rds.contains(where: { l in
                        k.contentInfo.titleMD5 == l.contentInfo.titleMD5
                    })
                })
                
                remianItems += datas
                sem.signal()
            }
            sem.wait()
        }
        
        guard remianItems.count > 0 else { return }
        
        save(datas: remianItems) { (rds, ids, err) in
            if let e = err {
                print("****** save faild: \(e.localizedDescription)")
                return
            }
            
            guard let rds = rds, rds.count > 0 else { return }
            
            print(">>>>>> save success: \(rds.count) items.")
            
            do {
                let request = DeviceNoticeAllRequest(title: "新帖子", content: "新增\(rds.count)片帖子, 快来看看有没有你感兴趣的！", image: "")
                let caller = WebserviceCaller<APIResponse<[String:String]>, DeviceNoticeAllRequest>(url: .debug, way: WebServiceMethod.post, method: .push)
                caller.paras = request
                caller.execute = { (result, err, response) in
                    print(result ?? "**** Empty result ****")
                }
                try Webservice.share.read(caller: caller)
            } catch {
                print("****** upload faild: json error \(error)")
            }
        }
        
        print(">>>>>> count: \(items.count), right: \(remianItems.count)")
    }
    
    /// 保存数据到数据库，重复数据不添加（标题或链接一样）
    /// - Parameter items: 数据列表缓存对象
    func add(_ items: [CloudData]) {
        var newItems = items
        for i in items {
            let request = NSFetchRequest<NDMoive>(entityName: "NDMoive")
            request.predicate = NSPredicate(format: "title == %@ OR href == %@", i.contentInfo.title, i.contentInfo.page)
            do {
                let count = try CloudDataBase.share.mainViewContext.count(for: request)
                if count <= 0 {
                    newItems.append(i)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        guard newItems.count > 0 else {
            LogItem.log(message: ">>> No New Record <<<")
            return
        }
        
        LogItem.log(message: ">>> Need Insert \(newItems.count) records.")
        CloudDataBase.share.add(data: newItems, test: false)
    }
}

// MARK: - FetchBot Delegate
extension Coordinate : FetchBotDelegate, CloudSaver {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
        let message = "+++++++ 正在接收 \(index) 项数据..."
        print(message)
        LogItem.log(message: message)
    }
    
    func bot(didStartBot bot: FetchBot) {
        startTime = Date()
        let message = "********* \(startTime.description)正在加载链接数据..."
        print(message)
        LogItem.log(message: message)
    }
    
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
        let message = ">>>>>>>>>>>> 已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败, spend time: \(Date().timeIntervalSince(startTime))s"
        print(message)
        LogItem.log(message: message)
        let bot = FetchBot.shareBot
        
        let legacyCategrory = site.categrory?.site
        site.categrory = tor?.next()
        guard let _ = site.categrory else {
            let datas = fetchRawData
            fetchRawData = [CloudData]()
            
            print(">>>>>> Fetch count \(datas.count)")
            LogItem.log(message: ">>>>>> Fetch count \(datas.count)")
//            self.batchCheck(items: datas)
//            self.add(datas)
            
            return
        }
        
        if let s = legacyCategrory {
            let values = contents.map({ CloudData(contentInfo: $0, site: s) })
            fetchRawData += values
            CloudDataBase.share.add(data: values, test: false)
        }
        
        DispatchQueue.global().async {
             [unowned self] in
            bot.start(withSite: self.site)
        }
    }
}

let coodinator = Coordinate()

extension Date {
    func formartYYYYMMDDHHMMSSSSS() -> String {
        let dateFormart = DateFormatter()
        dateFormart.dateFormat = "yyyy-MM-dd hh:MM:ss:SSS"
        return dateFormart.string(from: self)
    }
}
