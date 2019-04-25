//
//  ViewController.swift
//  CloudFetchBot
//
//  Created by virus1994 on 2018/6/6.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController {
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
    
    @IBOutlet weak var action: NSButton!
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    @IBAction func deletePrivate(_ sender: Any) {
        DispatchQueue.global().async {
            self.empty(database: CKContainer(identifier: "iCloud.com.ascp.S8Blocker").privateCloudDatabase)
        }
    }
    
    @IBAction func deleteDuplicateRecord(_ sender: Any) {
        DispatchQueue.global().async {
           self.deleteDuplicateRecord()
        }
    }
    
    @IBAction func deleteEmptyRecord(_ sender: Any) {
        DispatchQueue.global().async {
            self.deleteEmptyRecord()
        }
    }
    @IBAction func MD5maker(_ sender: Any) {
        DispatchQueue.global().async {
            self.remakerMD5(recall: { print("happy MD5!") })
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func start(_ sender: Any) {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [unowned self] (t) in
            self.action.isEnabled = false
            self.tor = self.menus.makeIterator()
            let bot = FetchBot.shareBot
            bot.delegate = self
            bot.startPage = self.startIndex
            bot.pageOffset = self.pageOffset
            self.site.categrory = self.tor?.next()
            DispatchQueue.global().async {
                 [unowned self] in
                bot.start(withSite: self.site)
            }
        })
        timer?.fire()
    }
    
}

// MARK: - FetchBot Delegate
extension ViewController : FetchBotDelegate, CloudSaver {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
        let message = "+++++++ 正在接收 \(index) 项数据..."
        print(message)
        DispatchQueue.main.async {
             [unowned self] in
            self.label.stringValue = message
        }
//        guard let s = site.categrory?.site  else {
//            return
//        }
//
//        check(href: content.titleMD5, completion: {[unowned self] (res) in
//            print(res)
//            if res.count <= 0 {
//                self.save(netDisk: CloudData(contentInfo: content, site: s)) { (rec, err) in
//                    if let e = err {
//                        print(e)
//                        return
//                    }
//                    if let rec = rec {
//                        self.newRecordCount += 1
//                        print(" ++++  ++++  ++++ \(rec.recordID) ++++  ++++  ++++ ")
//                    }
//                }
//            }   else    {
//                print(" **************** alreay save \(res.count) page ***************")
//            }
//        })
//
    }
    
    func bot(didStartBot bot: FetchBot) {
        startTime = Date()
        let message = "********* \(startTime.description)正在加载链接数据..."
        print(message)
        label.stringValue = message
    }
    
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
        let message = ">>>>>>>>>>>> 已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败, spend time: \(Date().timeIntervalSince(startTime))s"
        print(message)
        DispatchQueue.main.async { [unowned self] in
            self.label.stringValue = message
        }
        let bot = FetchBot.shareBot
        
        let legacyCategrory = site.categrory?.site
        site.categrory = tor?.next()
        guard let _ = site.categrory else {
            DispatchQueue.main.async {
                 [unowned self] in
                self.action.isEnabled = true
            }
            
            let datas = fetchRawData
            fetchRawData = [CloudData]()
            
            print(">>>>>> Fetch count \(datas.count)")
            self.batchCheck(items: datas)
            
            return
        }
        
        if let s = legacyCategrory {
            fetchRawData += contents.map({ CloudData(contentInfo: $0, site: s) })
        }
        
        DispatchQueue.global().async {
             [unowned self] in
            bot.start(withSite: self.site)
        }
    }
}
