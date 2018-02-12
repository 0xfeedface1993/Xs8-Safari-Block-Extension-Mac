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
let SearchName = NSNotification.Name(rawValue: "search")
let PageDataMessage = "pageData"

class ListTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableview: NSTableView!
    let IdenitfierKey = "identifier"
    let TitleKey = "title"
    var datas = [NetDisk]()
    var isFetching = false
    
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
    let bot = FetchBot(start: 0, offset: 50)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableview.delegate = self
        tableview.dataSource = self
        
        tableview.removeTableColumn(tableview.tableColumns.first!)
        
        let coloums = [[TitleKey:"标题", IdenitfierKey:"title"],
                       [TitleKey:"解压密码", IdenitfierKey:"password"],
                       [TitleKey:"文件名", IdenitfierKey:"filename"],
                       [TitleKey:"是否有码", IdenitfierKey:"msk"],
                       [TitleKey:"时间", IdenitfierKey:"time"],
                       [TitleKey:"格式", IdenitfierKey:"format"],
                       [TitleKey:"大小", IdenitfierKey:"size"]]
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
        NotificationCenter.default.addObserver(self, selector: #selector(searchNotification(notification:)), name: NSControl.textDidChangeNotification, object: nil)
        reloadTableView(notification: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: TableViewRefreshName, object: nil)
        NotificationCenter.default.removeObserver(self, name: DeleteActionName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowImagesName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UploadName, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSControl.textDidChangeNotification, object: nil)
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
        var count = 0
        for (_, data) in datas.enumerated() {
            let links = (data.link?.allObjects as? [Link] ?? []).map({ $0.link! })
            let pics = (data.pic?.allObjects as? [Pic] ?? []).map({ $0.pic! })
            let title = data.title ?? UUID().uuidString
            let page = data.pageurl ?? ""
            let msk = data.msk ?? ""
            let time = data.time ?? ""
            let format = data.format ?? ""
            let size = data.size ?? ""
            let dic = MovieModal(title: title, page: page, pics: pics, msk: msk, time: time, format: format, size: size, downloads: links)
            
            do {
                let json = try encoder.encode(dic)
                let caller = WebserviceCaller<MovieAddRespnse>(baseURL: WebserviceBaseURL.main, way: WebServiceMethod.post, method: "addMovie", paras: nil, rawData: json, execute: { (result, err, response) in
                    count += 1
                    if count < self.datas.count {
                        DispatchQueue.main.async {
                            self.showProgress(text: "已提交第 \(count)/\(self.datas.count) 项数据...")
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
                return datas[row].passwod ?? "无密码"
                
            case "filename":
                return datas[row].fileName ?? "未知"
                
            case "careatetime":
                let calender = Calendar.current
                if let date = datas[row].creattime {
                    var comp = calender.dateComponents([.year, .month, .day, .hour, .minute], from: date as Date)
                    comp.timeZone = TimeZone(identifier: "Asia/Beijing")
                    let cool = "\(comp.year!)/\(comp.month!)/\(comp.day!) \(comp.hour!):\(comp.minute!)"
                    return cool
                }
            case "msk":
                return datas[row].msk ?? "未知"
            case "time":
                return datas[row].time ?? "未知"
            case "format":
                return datas[row].format ?? "未知"
            case "size":
                return datas[row].size ?? "未知"
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
            case "msk":
                datas[row].msk = object as? String
                break
            case "time":
                datas[row].time = object as? String
                break
            case "format":
                datas[row].format = object as? String
                break
            case "size":
                datas[row].size = object as? String
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
        
        print("reloadTableView:notification")
        
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
    
    
    /// 展示提示文字
    ///
    /// - Parameter text: 提示文字
    func showProgress(text: String) {
        NotificationCenter.default.post(name: ShowExtennalTextName, object: text)
    }
    
    func loadList() {
        bot.delegate = self
        DispatchQueue.global().async {
            self.bot.start()
        }
    }
}

// MARK: - FetchBot Delegate
extension ListTableViewController : FetchBotDelegate {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int) {
        let message = "正在接收 \(index) 项数据..."
        print(message)
        DispatchQueue.main.async {
            self.showProgress(text: message)
        }
    }
    
    func bot(didStartBot bot: FetchBot) {
        let message = "正在加载链接数据..."
        showProgress(text: message)
        print(message)
    }
    
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL]) {
        let message = "已成功接收 \(bot.count - failedLink.count) 项数据, \(failedLink.count) 项接收失败"
        print(message)
        isFetching = false
        
        DataBase.share.save(downloadLinks: contents) { (state) in
            switch state {
            case .success:
                print("保存 \(contents.count) 项成功")
                break
            case .failed:
                print("批量保存失败")
                break
            }
            DispatchQueue.main.async {
                self.showProgress(text: message)
                NotificationCenter.default.post(name: StopFetchName, object: nil)
                self.reloadTableView(notification: nil)
            }
        }
    }
}

extension ListTableViewController {
    @objc func searchNotification(notification: NSNotification?) {
        if let searchField = notification?.object as? NSSearchField {
            filiter(keyword: searchField.stringValue)
        }
    }
    
    func filiter(keyword: String) {
        let managedObjectContext = DataBase.share.managedObjectContext
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        let sort = NSSortDescriptor(key: "creattime", ascending: false)
        employeesFetch.sortDescriptors = [sort]
        
        do {
            datas = try managedObjectContext.fetch(employeesFetch)
            if keyword != "" {
                datas = datas.filter({ (disk) -> Bool in
                    return (disk.title ?? "").contains(keyword)
                })
            }
            tableview.reloadData()
            if datas.count > 0 {
                self.tableview.selectRowIndexes([0], byExtendingSelection: false)
                NotificationCenter.default.post(name: SelectItemName, object: self.datas[0])
            }   else    {
                NotificationCenter.default.post(name: SelectItemName, object: nil)
            }
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
}

