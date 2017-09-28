//
//  ViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

let StopFetchName = NSNotification.Name.init("stopFetching")
let ShowExtennalTextName = NSNotification.Name.init("showExtennalText")
let UploadName = NSNotification.Name.init("UploadName")

class ViewController: NSViewController {
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var collectionView: NSView!
    @IBOutlet weak var head: TapImageView!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var userprofile: NSTextField!
    @IBOutlet weak var extenalText: NSTextField!
    
    let login = NSStoryboard(name: NSStoryboard.Name.init(rawValue: "LoginStoryboard"), bundle: Bundle.main).instantiateInitialController() as! NSWindowController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        unselect()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.select), name: SelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.unselect), name: UnSelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.stopFetch), name: StopFetchName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.showExtennalText(notification:)), name: ShowExtennalTextName, object: nil)
        head.tapBlock = {
            image in
            let app = NSApp.delegate as! AppDelegate
            if let _ = app.user {
                
            }   else    {
                self.login.showWindow(nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UnSelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: StopFetchName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowExtennalTextName, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    @IBOutlet weak var extract: NSButton!
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func save(_ sender: Any) {
        let app = NSApplication.shared.delegate as! AppDelegate
        app.resetAllRecords(in: "NetDisk")
    }
    
    @IBAction func extract(_ sender: Any) {
        let fetchButton = sender as! NSButton
        if fetchButton.tag == 110 {
            stopFetch()
        }   else    {
            fetchButton.tag = 110
            fetchButton.title = "停止"
        }
        NotificationCenter.default.post(name: TableViewRefreshName, object: fetchButton)
    }
    
    @objc func stopFetch() {
        extract.tag = 112
        extract.title = "提取"
        self.extenalText.stringValue = ""
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        NotificationCenter.default.post(name: DeleteActionName, object: nil)
    }
    
    @objc func select() {
        
    }
    
    @objc func unselect() {
        
    }
    @IBOutlet weak var upload: NSButton!
    
    @IBAction func uploadAction(_ sender: Any) {
        if upload.title == "上传" {
            upload.title = "停止"
            NotificationCenter.default.post(name: UploadName, object: nil)
        }   else    {
            upload.title = "上传"
            NotificationCenter.default.post(name: UploadName, object: 444)
        }
    }
    
    @objc func showExtennalText(notification: NSNotification?) {
        if let text = notification?.object as? String {
            self.extenalText.stringValue = text
        }
    }
}

// MARK: - Login Fun
extension ViewController {
    
}

//// MARK: - FetchBot Delegate
//extension ViewController : FetchBotDelegate {
//    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
//        let message = "正在接收 \(index) 项数据..."
//        print(message)
//    }
//    
//    func bot(didStartBot bot: FetchBot) {
//        let message = "正在加载链接数据..."
//        print(message)
//    }
//    
//    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
//        let message = "已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败"
//        print(message)
//        
//        let webservice = Webservice.share
//        let encoder = JSONEncoder()
//        for (index, data) in contents.enumerated() {
//            let links = data.downloafLink
//            let pics = data.imageLink
//            let title = data.title
//            let page = data.page
//            let dic = MovieModal(title: title, page: page, pics: pics, downloads: links)
//            do {
//                let json = try encoder.encode(dic)
//                let caller = WebserviceCaller<MovieAddRespnse>(baseURL: WebserviceBaseURL.main, way: WebServiceMethod.post, method: "addMovie", paras: nil, rawData: json, execute: { (result, err, response) in
//                    if index < contents.count - 1 {
//                        DispatchQueue.main.async {
//                            //                            self.showProgress(text: "已提交第 \(index)/\(self.datas.count) 项数据...")
//                            print("已提交第 \(index)/\(contents.count) 项数据...")
//                        }
//                    }   else    {
//                        DispatchQueue.main.async {
//                            //                            self.showProgress(text: "已提交 \(self.datas.count) 项数据")
//                            print("已提交 \(contents.count) 项数据")
//                        }
//                    }
//                    guard let message = result else {
//                        if let e = err {
//                            print("error: \(e)")
//                        }
//                        return
//                    }
//                    print("movieID: \(message.movieID)")
//                })
//                try webservice.read(caller: caller)
//            } catch {
//                print("upload faild: json error \(error)")
//            }
//        }
//    }
//}


