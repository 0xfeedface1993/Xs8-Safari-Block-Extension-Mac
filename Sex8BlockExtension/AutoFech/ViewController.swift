//
//  ViewController.swift
//  AutoFech
//
//  Created by virus1993 on 2017/9/23.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa
import WebKit
let PageDataMessage = "pageData"

class ViewController: NSViewController {
    @IBOutlet weak var bg: NSView!
    @IBOutlet weak var fetchButton: NSButton!
    let userContentController = WKUserContentController()
    var webview : WKWebView!
    var list = [ListItem]()
    @IBOutlet weak var extenalText: NSTextField!
    @IBOutlet weak var extractButton: NSButton!
    @IBOutlet weak var extractBtn: NSButton!
    var fullData = [PageData]()
    @IBOutlet weak var searchArea: NSSearchField!
    var commands = [Command]()
    private lazy var fetchJS : String = {
        let url = Bundle.main.url(forResource: "fetch", withExtension: "js")!
        do {
            let content = try String(contentsOf: url)
            return content
        } catch {
            print("read js file error: \(error)")
            return ""
        }
    }()
    let bot = FetchBot(start: 1, offset: 2)
    var startTime : Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        userContentController.add(self, name: PageDataMessage)
//        userContentController.addUserScript(WKUserScript(source: fetchJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
//
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = userContentController
//
//        webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), configuration: configuration)
//        webview.translatesAutoresizingMaskIntoConstraints = false
//        webview.navigationDelegate = self
//        bg.addSubview(webview)
//
//        bg.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", options: [], metrics: nil, views: ["v":webview]))
//        bg.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", options: [], metrics: nil, views: ["v":webview]))
//
//        webview.isHidden = true
//
//        let fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: 1)
//        let command = Command(type: .page, script: "login();", url: fetchURL.url, completion: nil)
//        commands.append(command)
//        executeCommand()
        bot.delegate = self
        bot.start()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func fetchData(_ sender: Any) {
        if fetchButton.tag == 110 {
            fetchButton.tag = 112
            fetchButton.title = "抓取数据"
        }   else    {
            fetchButton.isEnabled = false
            fetchButton.tag = 110
            fetchButton.title = "停止"
            loadList()
            fetchButton.isEnabled = true
        }
    }
}

extension ViewController : WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.injectJS(command: commands.first)
    }
    
    func injectJS(command : Command?) {
        guard let com = command else {
            return
        }
        webview.evaluateJavaScript(com.script) { (result, err) in
            print("inject JS success! script: \(com.script), url: \(com.url.absoluteString)")
            if err == nil {
                com.completion?(result)
            }   else    {
                print("js error: \(err!)")
            }
            if self.fetchButton.tag == 110 {
                self.commands.remove(at: 0)
                self.executeCommand()
            }   else {
                self.commands.removeAll()
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Recv js message: " + message.name)
//        if message.name == PageDataMessage, let data = message.body as? [String:Any] {
//
//        }
    }
    
    func loadList() {
        list.removeAll()
        let maxPage = 1
        for i in 1...maxPage {
            let fetchURL = FetchURL(site: "www.mote8didi.info", board: .netDisk, page: i, maker: {
                item in
                return ""
            })
            let command = Command(type: .page, script: "readNetDiskList();", url: fetchURL.url, completion: { (result) in
                if let data = result as? [[String:Any]] {
                    for part in data {
                        let item = ListItem(data: part)
                        self.list.append(item)
                    }
//                    print(self.list)
                }
                if i == maxPage {
                    self.loadPageData()
                }
            })
            commands.append(command)
        }
        executeCommand()
    }
    
    func loadPageData() {
        fullData.removeAll()
        for (_, data) in list.enumerated() {
            if let url = URL(string: data.href) {
                let command = Command(type: .detail, script: "fetchData();", url: url, completion: {
                    result in
                    if let data = result as? [String:Any] {
                        let item = PageData(data: data)
                        self.fullData.append(item)
                        DataBase.share.saveDownloadLink(data: item, completion: { (state) in
                            switch state {
                            case .success:
                                print("saveOK: \(item.title)")
                                break
                            case .failed:
                                print("save faild: \(item.title), link: \(item.url)")
                                break
                            }
                        })
                    }
                })
                commands.append(command)
            }
        }
        executeCommand()
    }
    
    func executeCommand() {
        if commands.count > 0 {
            let first = commands.first!
            let request = URLRequest(url: first.url)
            webview.load(request)
        }
    }
}

// MARK: - FetchBot Delegate
extension ViewController : FetchBotDelegate {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
        let message = "正在接收 \(index) 项数据..."
        print(message)
    }
    
    func bot(didStartBot bot: FetchBot) {
        let message = "正在加载链接数据..."
        startTime = Date()
        print(message)
    }
    
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
        let message = "已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败, spend time: \(Date().timeIntervalSince(startTime))"
        print(message)
        
        let webservice = Webservice.share
        let encoder = JSONEncoder()
        for (index, data) in contents.enumerated() {
            let links = data.downloafLink
            let pics = data.imageLink
            let title = data.title
            let page = data.page
            let dic = MovieModal(title: title, page: page, pics: pics, downloads: links)
            do {
                let json = try encoder.encode(dic)
                let caller = WebserviceCaller<MovieAddRespnse>(baseURL: WebserviceBaseURL.main, way: WebServiceMethod.post, method: "addMovie", paras: nil, rawData: json, execute: { (result, err, response) in
                    if index < contents.count - 1 {
                        DispatchQueue.main.async {
//                            self.showProgress(text: "已提交第 \(index)/\(self.datas.count) 项数据...")
                            print("已提交第 \(index)/\(contents.count) 项数据...")
                        }
                    }   else    {
                        DispatchQueue.main.async {
//                            self.showProgress(text: "已提交 \(self.datas.count) 项数据")
                            print("已提交 \(contents.count) 项数据")
                        }
                    }
                    guard let message = result else {
                        if let e = err {
                            print("error: \(e)")
                        }
                        return
                    }
                    print("movieID: \(message.movieID)")
                })
                try webservice.read(caller: caller)
            } catch {
                print("upload faild: json error \(error)")
            }
        }
    }
}
