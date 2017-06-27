//
//  ListTableViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/6/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

let TableViewRefreshName = NSNotification.Name(rawValue: "refreshTableView")
let DeleteActionName = NSNotification.Name(rawValue: "deleteNetDisk")
let SelectItemName = NSNotification.Name(rawValue: "selectItem")
let UnSelectItemName = NSNotification.Name(rawValue: "unSelectItem")
let ShowImagesName = NSNotification.Name(rawValue: "showImages")

class ListTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableview: NSTableView!
    let IdenitfierKey = "identifier"
    let TitleKey = "title"
    var datas = [NetDisk]()
    lazy var popver : NSPopover = {
        let pop = NSPopover()
        pop.animates = true
        pop.appearance = NSAppearance(named: NSAppearanceNameAqua)
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        let xpics = storyboard.instantiateController(withIdentifier: "PicsCollectionViewController") as! PicsCollectionViewController
        pop.contentViewController = xpics
        pop.contentSize = CGSize(width: 800, height: 600)
        return pop
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
            let coloum = NSTableColumn(identifier: item[IdenitfierKey]!)
            coloum.title = item[TitleKey]!
            coloum.width = 150
            tableview.addTableColumn(coloum)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView(notification:)), name: TableViewRefreshName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(delete(notification:)), name: DeleteActionName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showImages), name: ShowImagesName, object: nil)
        
        reloadTableView(notification: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: TableViewRefreshName, object: nil)
        NotificationCenter.default.removeObserver(self, name: DeleteActionName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowImagesName, object: nil)
    }
    
    //MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let coloum = tableColumn {
            switch coloum.identifier {
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
            switch coloum.identifier {
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
            let app = NSApplication.shared().delegate as! AppDelegate
            app.saveAction(nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        if let coloum = tableColumn {
            switch coloum.identifier {
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
                let data = datas[table.selectedRow].pic?.allObjects as? [Pic] ?? []
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
    func reloadTableView(notification: Notification?) {
        let app = NSApplication.shared().delegate as! AppDelegate
        let managedObjectContext = app.managedObjectContext
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        
        do {
            datas = try managedObjectContext.fetch(employeesFetch)
            tableview.reloadData()
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
    }
    
    // 删除
    func delete(notification: Notification) {
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
                case NSAlertFirstButtonReturn:
                    let index = self.tableview.selectedRow
                    let app = NSApplication.shared().delegate as! AppDelegate
                    let managedObjectContext = app.managedObjectContext
                    do {
                        managedObjectContext.delete(self.datas[index])
                        self.datas.remove(at: index)
                        try managedObjectContext.save()
                        self.tableview.reloadData()
                    } catch {
                        print ("There was an error: \(error)")
                    }
                    break
                case NSAlertSecondButtonReturn:
                    
                    break
                default:
                    break
                }
            })
        }
    }
    
    // 通知
    func showImages() {
        if popver.isShown  {
            popver.close()
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
    
    // 检查是否已经存在数据
    func checkPropertyExist<T: NSFetchRequestResult>(entity: String, property: String, value: String) -> T? {
        let fetch = NSFetchRequest<T>(entityName: entity)
        fetch.predicate = NSPredicate(format: "SELF.\(property) == '\(value)'")
        do {
            let app = NSApplication.shared().delegate as! AppDelegate
            let datas = try app.managedObjectContext.fetch(fetch)
            return datas.first
        } catch {
            fatalError("Failed to fetch \(property): \(error)")
        }
    }
    
}
