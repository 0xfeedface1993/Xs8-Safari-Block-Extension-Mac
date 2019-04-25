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
//        check(titleMD5s: ["a5c4f3ee2a0ad287ff535d79c6f9aa18", "789dd1336930969635d459c527c2eccf", "fa63731d2e8b851aa2c0189700887845", "e47a21e6beb687dcc90c9430de1a4953", "3d55d9d2e65cb893108961269ac11fc5", "52e2f9e3d02b47c56fe557c466af9c7b", "19f0f90fc4be5d19b29ad219769a7d46", "b61cf87d796a5719ca8fbdf262694126", "aa1e4983188af8eb82dd008030851c05", "b955fea1b5ad4556fcff0a7fa1bd4431", "16353acbe480343f8b84a1aeb9c82daf", "86fecc75ef2d90c8ef6e5dff478a1a0e", "bb5b54198c54aedbef82627fe0bd04c2", "52309d48d836e514a9de422444093ff3", "68c0226b5fb9b91d6b3ed5367ab4389c", "ac348036512dbd1d369c264840c520be", "47332ec23339267216c938b68666a608", "7799ef8e34890d1549e213dcae329213", "ddd2af38e01f5dccc5e296dbc4170881", "30a6afaf9f2921f4677acd2aff057eec", "e68fdf02a8460e0331f7f68994a69a3e", "79e6c594347755a6627bd199d4b76bfd", "44905e1dd7d76e29249bb89b18181605", "a5c4f3ee2a0ad287ff535d79c6f9aa18", "5bf6e99ffc8dd6daa063b6161baabf3e", "3e65e86c8bf99deee14255ce335176b9", "c6f472146359d9667b40d2d9c65e59bb", "7d34f0b63b33301aeec6063f5daf5f49", "2edd0cb18cb6927f4994df4aa2f5f45c", "1126fc30113d9eb0ee5a01d6872c3d44", "9381fa59257b54f1869d225edc35bc0e", "ab014aef5b5770f742b045896baa3ac8", "033631fb5d50b876aa26c22a76252ac5", "4a1a32321edfc2198c21294b6c17758a", "2fa2a65c480bcc73a6ddf8b37d3c9368", "2298f529b7dbb4f3b5c6c4533fb0e850", "ee14cd92353d89ecdb41941dd0e64b74", "6ec52d3485bc94622eb4ed1983208ecf", "7adec2332418eab0b665496bc2e1b7e9", "0ef180eeb963a6caa802fae644cf06af", "a0dfca505946eb2169ca2031faf78dc4", "96abb2d0f20e060f5922a33e68b6b24e", "2f1a1f648707a8da9649fdb40162357d", "e75409d79aafa14c55b22384b06c0a6f", "0cb6d1baed843b1f46b2478f0a42952b", "616ceed101932ef2b42fc96c96892aed", "baf1009847d59e2803d7601b1006bd21", "899abbbc826f74d36dce2cd08707e49b", "eb24d2b413a8827fa2190cc565c30a76", "f63619a88ba479d23823569fd3d970ee", "77240d8607eee572d150b8e0772fd4d3", "9a5e81f99e0601d3adab282eb374187c", "d921cef111c79773a36d24308a36402b", "22b09333101167b1f3dc21d291266507", "42761c3aa99de828379c6e13b2db3ed0", "3984d43f53b0bad01f47bdc87353e305", "a5c4f3ee2a0ad287ff535d79c6f9aa18", "317844658c6415302f629c5aefeb6a9b", "e9c79044f1650852b5e3982587c73de3", "483d7c86317947ca8f57668e395ade35", "19fa0c56901bc94a1b4009f1150d3c5f", "b0f5539f0f9c57a735f86b9ac42a9ef7", "20aab2bbbe2f742a2a2ef9887c4534c4", "0c43d0dfdb88dedb4b6c43f280284daf", "50d44c0ea1a257edcfe55375e0616b97", "6b656b749492f9afbf0fdd08bcbf693f", "c28a2462141adc898230d1e03de4d77c", "558ea97e5cc6ee6d7d0eebedc54f5ea1", "4726c3a66e900c40c06f4bb51a412036", "3d86a89ffcc6333bef1363b999e1bec5", "7c96bcb485eaf235865dd84985811bef", "21d5ba057c7c2b3c8c39a76310f35aaa", "d4059567fdec9eb4df5ce84522bfc686", "673b78b6075fc2dce866e0107f6aee38", "b4126b33bd8cfc91dd3b952a0ce2f09c", "1876c24c7fe29b4f16f109b3d815fa2f", "961cdab2fa37c6223b2300918c2fe0a7", "2be854ebc5f26eaaf73c7120650ff006", "c744e5f5af8fa57a4497d7dc9cb8f6a1", "305affe61aa727a3c043786139ebc30b", "4e3883a7657dee2af42f2ec6b536d462", "05d7e381e1661343210a9f861703cc68", "98facc14db2aa4107d2040069af0673a", "5ae05328c6dff4b311fa45d519e4d2b3", "4994bd2a89f0e3813d1939c2b60f5ccd", "df838464b52188eb7982db118a031109", "935304685456b14e1227179c6ed9c4d1", "b476642ef0cf987effd8f6b53d428eac", "a5c4f3ee2a0ad287ff535d79c6f9aa18", "5052e19a19573bd6b399500748858c8f", "c9328e4031393e0549bfde3da36e65a8", "f7aa78a2b71b8a24e1baa06d43638d2b", "42761c3aa99de828379c6e13b2db3ed0", "5d82c2851a4fe59597d5e255df31e66f", "24c249bef78c6d104e3b4700afea2ad1", "f99b48797f88b40c01621af1ed16f079", "472aa3f21226b03c7a186616b996214d", "2e4a6e81cc42acf2780f0c71cf7ed359", "b479663815d761e4e39e4013dff58ffa", "86f233d76089868ddbadfd5eb6eea9c6", "0a5c4d26c01d2fe4cedbab747c67e3e7", "6017af0ab718af108bb3d07061c210c4", "7c8c25d142b5cc5e1acc9f6716e308f6", "2461f50ead010594d161e78ea0132681", "1d080a3ed4ba5647c315ac129b93463d", "bc9242f828543b3857fa5115311149b4", "be6093ffcd802da9100835d071a3f2e6", "4430f7c6c6db070b7d3a656638357da2", "f9a375ab1bd054c8a59e4fbcfd97e6b2", "539a9b5cf8f8f47283a757084b0b3a0a", "087c1ab05072681abe8c10bd63cad87e", "82fa50e0f2ab440364784a50e37d6771", "11acaafab092290f464835305f21c80c", "751fb66f50ab532295a6925ef289163f", "3c4cabd67eea862c8f18b28ece408602", "7a4d3f6e4b9dc735fa61529081dd8392", "37bf53a51d260c114a5e1d978ddc32bc", "cfdcd27b3847000fa2e10c0f911a800c", "d14c0f08d0a4290d50b4f3f6fe47a705", "9f75e45c9b1b99cd979bd3f6cd385d59", "2fd2b240d8a7cce109feab2814162f23", "5f767286c591131fed7af4c0621fe32f", "7d43218912be45b8e84412bdca5b7b23", "2cc7f06b5813c993a9b3da0355499826", "f25f5ac9b80ad03b71b9357671e52d6f", "a5c4f3ee2a0ad287ff535d79c6f9aa18", "9809f967832bb93da314d63acd601257", "8449c261c01d98fca2f50339656f81fe", "7b8ac70bc14e0931343bfbfae23b6b33", "286e08294f813cfbc3a5febab814ee32", "b66054655a20a594f39e89dfc4cba89b", "ea26543c3a25bb913c990d978eaa6b75", "b06822577580a1323a06070b0f056d1c"]) { (records) in
//            print(records)
//        }
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
            
            var datas = fetchRawData
            fetchRawData = [CloudData]()
            
            print(">>>>>> Fetch count \(datas.count)")
            //["789dd1336930969635d459c527c2eccf", "8dcffa32dce9e2369120d9263ef22a74", "e47a21e6beb687dcc90c9430de1a4953"]
            check(titleMD5s: datas.map({ $0.contentInfo.titleMD5 })) { (records) in
                let rds = records.map({ $0.convertModal() })
                datas = datas.filter({ i in
                    return !rds.contains(where: { j in
                        i.contentInfo.titleMD5 == j.contentInfo.titleMD5
                    })
                })
                print(">>>>>> Remain count \(datas.count)")
                do {
                    let request = DeviceNoticeAllRequest(title: "新帖子", content: "新增\(datas.count)片帖子, 快来看看有没有你感兴趣的！", image: "")
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
