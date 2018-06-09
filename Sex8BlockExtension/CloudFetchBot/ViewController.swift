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
    @IBOutlet weak var action: NSButton!
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func start(_ sender: Any) {
        action.isEnabled = false
        tor = menus.makeIterator()
        let bot = FetchBot.shareBot
        bot.delegate = self
        bot.startPage = startIndex
        bot.pageOffset = pageOffset
        site.categrory = tor?.next()
        DispatchQueue.global().async {
            bot.start(withSite: self.site)
        }
    }
    
}

// MARK: - FetchBot Delegate
extension ViewController : FetchBotDelegate, CloudSaver {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
        let message = "+++++++ 正在接收 \(index) 项数据..."
        print(message)
        DispatchQueue.main.async {
            self.label.stringValue = message
        }
        guard let s = site.categrory?.site  else {
            return
        }
        
        check(title: content.page) { (res) in
            print(res)
            if res.count <= 0 {
                self.save(netDisk: CloudData(contentInfo: content, site: s)) { (rec, err) in
                    if let e = err {
                        print(e)
                        return
                    }
                    if let rec = rec {
                        print(" ++++  ++++  ++++ \(rec.recordID) ++++  ++++  ++++ ")
                    }
                }
            }   else    {
                print(" **************** alreay save \(res.count) page ***************")
            }
        }
        
    }
    
    func bot(didStartBot bot: FetchBot) {
        startTime = Date()
        let message = "********* \(startTime.description)正在加载链接数据..."
        print(message)
        label.stringValue = message
    }
    
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
        let message = ">>>>>>>>>>>> 已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败, spend time: \(Date().timeIntervalSince(startTime))"
        print(message)
        DispatchQueue.main.async {
            self.label.stringValue = message
        }
        let bot = FetchBot.shareBot
        site.categrory = tor?.next()
        guard let _ = site.categrory else {
            DispatchQueue.main.async {
                self.action.isEnabled = true
            }
            return
        }
        DispatchQueue.global().async {
            bot.start(withSite: self.site)
        }
    }
}
