//
//  ImagesTableViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/2.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class ImagesTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!
    var tasks = [ImageTask]()
    
    let ImageCellIdentifier = "ImageCell"
    let zoom = NSStoryboard(name: "ZoomStoryboard", bundle: nil).instantiateController(withIdentifier: "ZoomKeeper") as? NSWindowController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize(notification:)), name: NSWindow.didResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
//        #if DEBUG
//        tableView.isHidden = true
//        #endif
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        reloadImages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: nil)
    }
    
    // MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ImageCellIdentifier), owner: self) as? ImageTableViewCell else {
            return nil
        }
        cell.myPlayBoy.image = tasks[row].image
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = tasks[row].image
        let padding : CGFloat = 0
        let width : CGFloat = view.bounds.size.width - padding
        let h = item.size.height
        let w = item.size.width
        let height = w > view.bounds.size.width ? (width / w * h):h
        return height
    }
    
    // 重新获取数据
    func reloadImages() {
        tasks.forEach({ task in
            task.start()
        })
        
        tableView.reloadData()
        tableView.scroll(CGPoint(x: 0, y: 0))
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow >= 0 {
            let image = tasks[tableView.selectedRow].image
            if tableView.selectedRow >= 0, image != defaultImage, image != errorImage {
                zoom?.showWindow(zoom)
                tableView.deselectRow(tableView.selectedRow)
                NotificationCenter.default.post(name: ImagePickerNotification, object: image)
            }
        }
    }
    
    // 清除缓存
    func clearCacheImages() {
        self.tasks.forEach({
            task in
            task.stop()
            task.reset()
        })
    }
    
    // 获取数据更新视图
    @objc func select(notification: NSNotification) {
        clearCacheImages()
        tasks = ((notification.object as? NetDisk)?.pic?.allObjects as? [Pic] ?? []).map({ ImageTask(picture: $0, finished: {
            tk in
            if let index = self.tasks.firstIndex(where: { tkx in return tkx == tk  }) {
                if !Thread.isMainThread {
                    DispatchQueue.main.async {
                        self.tableView.noteHeightOfRows(withIndexesChanged: [index])
                        self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                    }
                    return
                }
                self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
            }
        }) })
        reloadImages()
    }
    
    // 窗口事件
    @objc func windowDidResize(notification: Notification) {
        tableView.reloadData()
    }
}
