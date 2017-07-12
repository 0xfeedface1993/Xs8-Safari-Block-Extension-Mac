//
//  AttributeViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/12.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class AttributeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var downloadAddress: NSTableView!
    @IBOutlet weak var pageAddress: NSTableView!
    var net:NetDisk?
    var links:[Link]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
    }
    
    //MARK: - NSTableView Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case downloadAddress:
            return links?.count ?? 0
        case pageAddress:
            return net != nil ? 1:0
        default:
            break
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        switch tableView {
        case downloadAddress:
            return links?[row].link
        case pageAddress:
            return net?.pageurl
        default:
            break
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableview = notification.object as! NSTableView
        switch tableview {
        case downloadAddress:
            if tableview.selectedRow >= 0 {
                let pasteBoard = NSPasteboard.general()
                pasteBoard.clearContents()
                let copysObjects = [links![tableview.selectedRow].link]
                pasteBoard.writeObjects(copysObjects as! [NSPasteboardWriting])
            }
            break
        case pageAddress:
            if tableview.selectedRow >= 0 {
                let pasteBoard = NSPasteboard.general()
                pasteBoard.clearContents()
                let copysObjects = [net!.pageurl]
                pasteBoard.writeObjects(copysObjects as! [NSPasteboardWriting])
            }
            break
        default:
            break
        }
    }
    
    // 获取数据更新视图
    func select(notification: NSNotification) {
        net = notification.object as? NetDisk
        links = net?.link?.allObjects as? [Link] ?? []
        pageAddress.reloadData()
        downloadAddress.reloadData()
    }
}
