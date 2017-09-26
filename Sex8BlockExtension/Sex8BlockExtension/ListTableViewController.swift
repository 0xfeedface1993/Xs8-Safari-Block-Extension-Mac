//
//  ListTableViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/6/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa
import WebKit

let TableViewRefreshName = NSNotification.Name(rawValue: "refreshTableView")
let DeleteActionName = NSNotification.Name(rawValue: "deleteNetDisk")
let SelectItemName = NSNotification.Name(rawValue: "selectItem")
let UnSelectItemName = NSNotification.Name(rawValue: "unSelectItem")
let ShowImagesName = NSNotification.Name(rawValue: "showImages")
let ShowDonwloadAddressName = NSNotification.Name(rawValue: "showAddress")
let PageDataMessage = "pageData"

enum FetchBoard : Int {
    case netDisk = 103
}

struct FetchURL {
    var site : String
    var board : FetchBoard
    var page : Int
    var url : URL {
        get {
            let temp = URL(string: "http://\(site)/forum-\(board.rawValue)-\(page).html")!;
            return temp
        }
    }
}

struct ListItem : Equatable {
    var title : String
    var href : String
    var previewImages : [String]
    init(data: [String:Any]) {
        title = data["title"] as? String ?? ""
        href = data["href"] as? String ?? ""
        previewImages = data["images"] as? [String] ?? []
    }
    
    static func ==(lhs: ListItem, rhs: ListItem) -> Bool {
        return lhs.title == rhs.title && lhs.href == rhs.href
    }
}

enum CommandType {
    case page
    case detail
}

struct Command {
    var type : CommandType
    var script : String
    var url : URL
    var completion : ((Any?) -> ())?
}

class ListTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableview: NSTableView!
    let IdenitfierKey = "identifier"
    let TitleKey = "title"
    var datas = [NetDisk]()
    var list = [ListItem]()
    var fullData = [PageData]()
    var commands = [Command]()
    var isFetching = false
    private var webview : WKWebView!
    let userContentController = WKUserContentController()
    lazy var popver : NSPopover = {
        let pop = NSPopover()
        pop.animates = true
        pop.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: Bundle.main)
        let xpics = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "PicsCollectionViewController")) as! PicsCollectionViewController
        pop.contentViewController = xpics
        pop.contentSize = CGSize(width: 800, height: 600)
        return pop
    }()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableview.delegate = self
        tableview.dataSource = self
        
        tableview.removeTableColumn(tableview.tableColumns.first!)
        
        let coloums = [[TitleKey:"标题", IdenitfierKey:"title"],
                       [TitleKey:"解压密码", IdenitfierKey:"password"],
                       [TitleKey:"文件名", IdenitfierKey:"filename"],
                       [TitleKey:"创建时间", IdenitfierKey:"careatetime"]]
        for item in coloums {
            let coloum = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: item[IdenitfierKey]!))
            coloum.title = item[TitleKey]!
            coloum.width = 150
            tableview.addTableColumn(coloum)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(notification:isDelete:)), name: TableViewRefreshName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(delete(notification:)), name: DeleteActionName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showImages), name: ShowImagesName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showAddress), name: ShowDonwloadAddressName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uploadServer(notification:)), name: UploadName, object: nil)
        reloadTableView(notification: nil)
        
        userContentController.add(self, name: PageDataMessage)
        userContentController.addUserScript(WKUserScript(source: fetchJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        webview = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 300), configuration: configuration)
        webview.translatesAutoresizingMaskIntoConstraints = false
        webview.navigationDelegate = self
        view.addSubview(webview)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", options: [], metrics: nil, views: ["v":webview]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", options: [], metrics: nil, views: ["v":webview]))
        
        webview.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: TableViewRefreshName, object: nil)
        NotificationCenter.default.removeObserver(self, name: DeleteActionName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowImagesName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UploadName, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.view.window?.makeFirstResponder(self.tableview)
        }
    }
    
    @objc func uploadServer(notification: NSNotification?) {
        let webservice = Webservice.share
        if let flag = notification?.object as? Int, flag == 444 {
            webservice.cancelAllTask()
            return
        }
        let encoder = JSONEncoder()
        for (index, data) in datas.enumerated() {
            let links = (data.link?.allObjects as? [Link] ?? []).map({ $0.link! })
            let pics = (data.pic?.allObjects as? [Pic] ?? []).map({ $0.pic! })
            let title = data.title ?? UUID().uuidString
            let page = data.pageurl ?? ""
            let dic = MovieModal(title: title, page: page, pics: pics, downloads: links)
            do {
                let json = try encoder.encode(dic)
                let caller = WebserviceCaller<MovieAddRespnse>(baseURL: WebserviceBaseURL.main, way: WebServiceMethod.post, method: "addMovie", paras: nil, rawData: json, execute: { (result, err, response) in
                    if index < self.datas.count - 1 {
                        DispatchQueue.main.async {
                            self.showProgress(text: "已提交第 \(index)/\(self.datas.count) 项数据...")
                        }
                    }   else    {
                        DispatchQueue.main.async {
                            self.showProgress(text: "已提交 \(self.datas.count) 项数据")
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
    
    //MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let coloum = tableColumn, row < datas.count {
            switch coloum.identifier.rawValue {
            case "title":
                return datas[row].title
                
            case "password":
                return datas[row].passwod
                
            case "filename":
                return datas[row].fileName
                
            case "careatetime":
                let calender = Calendar.current
                if let date = datas[row].creattime {
                    var comp = calender.dateComponents([.year, .month, .day, .hour, .minute], from: date as Date)
                    comp.timeZone = TimeZone(identifier: "Asia/Beijing")
                    let cool = "\(comp.year!)/\(comp.month!)/\(comp.day!) \(comp.hour!):\(comp.minute!)"
                    return cool
                }
                
            default:
                break
            }
        }
        
        return "没有数据"
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if let coloum = tableColumn {
            switch coloum.identifier.rawValue {
            case "title":
                datas[row].title = object as? String
                break
            case "password":
                datas[row].passwod = object as? String
                break
            case "filename":
               datas[row].fileName = object as? String
                break
            default:
                break
            }
            let app = NSApplication.shared.delegate as! AppDelegate
            app.saveAction(nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        if let coloum = tableColumn {
            switch coloum.identifier.rawValue {
            case "careatetime":
                return false
            default:
                break
            }
        }
        return true
    }
    
    override func moveDown(_ sender: Any?) {
        super.moveDown(sender)
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
//        print((notification.object as! NSTableView).selectedRow)
        if let table = notification.object as? NSTableView {
            if tableview.selectedRow >= 0 {
                reloadImages(index: table.selectedRow)
                let data = datas[table.selectedRow]
                NotificationCenter.default.post(name: SelectItemName, object: data)
            }   else    {
                popver.close()
                NotificationCenter.default.post(name: UnSelectItemName, object: nil)
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        print(event.keyCode)
        
        switch event.keyCode {
        case 53:
            popver.close()
            break
        case 49:
            if popver.isShown {
                popver.close()
            }   else    {
                reloadImages(index: tableview.selectedRow)
            }
            
            return
        default:
            break
        }
        
        super.keyDown(with: event)
    }
    
    // 重新获取数据
    @objc func reloadTableView(notification: Notification?, isDelete: Int = 1) {
        if let btn = notification?.object as? NSButton {
            if btn.tag == 110 {
                if !isFetching {
                    loadList()
                }
                isFetching = true
                print("continute fetching !")
            }   else    {
                isFetching = false
                print("stop fetching !")
            }
        }
        
        let managedObjectContext = DataBase.share.managedObjectContext
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        let sort = NSSortDescriptor(key: "creattime", ascending: false)
        employeesFetch.sortDescriptors = [sort]
        
        do {
            let oldCount = datas.count
            datas = try managedObjectContext.fetch(employeesFetch)
            tableview.reloadData()
            if datas.count > 0 {
                if oldCount != datas.count {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                        self.tableview.selectRowIndexes([0], byExtendingSelection: false)
                        NotificationCenter.default.post(name: SelectItemName, object: self.datas[0])
                    })
                }   else    {
                    if isDelete == 2 {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                            let selectIndex = self.tableview.selectedRow > 0 && self.tableview.selectedRow < self.datas.count ? self.tableview.selectedRow:0
                            self.tableview.selectRowIndexes([selectIndex], byExtendingSelection: false)
                            NotificationCenter.default.post(name: SelectItemName, object: self.datas[selectIndex])
                        })
                    }
                }
            }   else    {
                NotificationCenter.default.post(name: SelectItemName, object: nil)
            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
    }
    
    // 删除
    @objc func delete(notification: Notification) {
        if tableview.selectedRow >= 0 {
            let alert = NSAlert()
            alert.addButton(withTitle: "删除")
            alert.addButton(withTitle: "取消")
            alert.messageText = "确定删除选中项？"
            alert.informativeText = "删除后不可恢复！"
            alert.alertStyle = .warning
            alert.beginSheetModal(for: view.window!, completionHandler: {
                code in
                switch code {
                case NSApplication.ModalResponse.alertFirstButtonReturn:
                    let index = self.tableview.selectedRow
                    let managedObjectContext = DataBase.share.managedObjectContext
                    do {
                        managedObjectContext.delete(self.datas[index])
                        self.datas.remove(at: index)
                        try managedObjectContext.save()
//                        if self.tableview.selectedRow >= 0 {
//                            self.tableview.deselectRow(self.tableview.selectedRow)
//                            self.tableview.reloadData()
//                        }
                        self.reloadTableView(notification: nil, isDelete: 2)
                    } catch {
                        print ("There was an error: \(error.localizedDescription)")
                    }
                    break
                case NSApplication.ModalResponse.alertSecondButtonReturn:
                    
                    break
                default:
                    break
                }
            })
        }
    }
    
    // 通知
    @objc func showImages() {
        if popver.isShown  {
            popver.close()
        }
    }
    
    @objc func showAddress(notification: Notification) {
        if tableview.selectedRow >= 0 {
            let data = datas[tableview.selectedRow].link?.allObjects as? [Link] ?? []
            print(data.map({
                item in
                return item.link ?? ""
            }))
        }
    }
    
    func reloadImages(index: Int) {
//        let pics = popver.contentViewController as! PicsCollectionViewController
//         let data = datas[index].pic?.allObjects as? [Pic] ?? []
//        let rect = parent?.view.frame
//        if !popver.isShown {
//            popver.show(relativeTo: rect!, of: tableview, preferredEdge: .maxX)
//        }
//        pics.clearCacheImages()
//        pics.collectionView.reloadData()
//        pics.collectionView.scroll(NSPoint(x: 0, y: 0))
//        NotificationCenter.default.post(name: SelectItemName, object: data)
    }
}

extension ListTableViewController : WKNavigationDelegate, WKScriptMessageHandler {
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
            if self.isFetching {
                self.commands.remove(at: 0)
                self.executeCommand()
            }   else {
                self.commands.removeAll()
                self.isFetching = false
                NotificationCenter.default.post(name: StopFetchName, object: nil)
                self.reloadTableView(notification: nil)
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
        print("start fatching!")
        list.removeAll()
        let maxPage = 30
        for i in 7...maxPage {
            let fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: i)
            let command = Command(type: .page, script: "readNetDiskList();", url: fetchURL.url, completion: { (result) in
                self.showProgress(text: "正在获取第\(i)页数据...")
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
        for (index, data) in list.enumerated() {
            if let url = URL(string: data.href) {
                let command = Command(type: .detail, script: "fetchData();", url: url, completion: {
                    result in
                    self.showProgress(text: "正在获取第 \(index)/\(self.list.count) 项数据...")
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
        }   else   {
            NotificationCenter.default.post(name: StopFetchName, object: nil)
        }
    }
    
    func showProgress(text: String) {
        NotificationCenter.default.post(name: ShowExtennalTextName, object: text)
    }
}
