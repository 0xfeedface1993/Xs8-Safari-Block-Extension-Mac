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
    var datas = [Pic]()
    let defaultImage = NSImage(named: "watting.jpeg")
    let errorImage = NSImage(named: "error")
    var downloadedImagesIndex = [Int]()
    var downloadingImagesIndex = [Int]()
    var downloadImages = [Int:NSImage]()
    var executingTask = [URLSessionDownloadTask]()
    let ImageCellIdentifier = "ImageCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize(notification:)), name: NSNotification.Name.NSWindowDidResize, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        reloadImages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSWindowDidResize, object: nil)
    }
    
    // MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.make(withIdentifier: ImageCellIdentifier, owner: self) as? ImageTableViewCell else {
            return nil
        }
        cell.myPlayBoy.image = downloadImages[row]
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = downloadImages[row]
        let padding : CGFloat = 0
        let width : CGFloat = view.bounds.size.width - padding
        if let h = item?.size.height, let w = item?.size.width {
            let height = w >= view.bounds.size.width ? (width / w * h):h
//            print(height)
            return height
        }
        let height = width / self.defaultImage!.size.width * self.defaultImage!.size.height
        return height
    }
    
    // 重新获取数据
    func reloadImages() {
        for (index, pic) in datas.enumerated() {
            if let imageData = pic.data, let image = NSImage(data: imageData as Data) {
                downloadedImagesIndex.append(index)
                downloadImages[index] = image
            }   else    {
                downloadingImagesIndex.append(index)
                downloadImages[index] = defaultImage
                DispatchQueue.global().async {
                    if let urlString = pic.pic, let url = URL(string: urlString) {
                        print(url)
                        self.downloadingImagesIndex.append(index)
                        DispatchQueue.main.async {
                            let task = URLSession.shared.downloadTask(with: url, completionHandler: {
                                (url, response, error) in
                                self.downloadedImagesIndex.append(index)
                                if let indx = self.downloadingImagesIndex.index(of: index) {
                                    self.downloadingImagesIndex.remove(at: indx)
                                }
                                
                                if error != nil {
                                    self.downloadImages[index] = self.errorImage
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                                    }
                                    
                                    print("error : \(error.debugDescription)")
                                    return
                                }
                                
                                guard let datURL = url, let img = NSImage(contentsOf: datURL) else {
                                    self.downloadImages[index] = self.errorImage
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                                    }
                                    print("bad image data!")
                                    return
                                }
                                
                                self.downloadImages[index] = img
                                
                                DispatchQueue.main.async {
                                    let app = NSApplication.shared().delegate as! AppDelegate
                                    let pic = self.datas[index]
                                    pic.data = img.tiffRepresentation as NSData?
                                    app.saveAction(nil)
                                    self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                                }
                            })
                            self.executingTask.append(task)
                            task.resume()
                        }
                    }
                }
            }
        }
        tableView.reloadData()
        tableView.scroll(CGPoint(x: 0, y: 0))
    }
    
    // 清除缓存
    func clearCacheImages() {
        self.executingTask.forEach({
            task in
            if task.state == .running {
                task.cancel()
            }
        })
        self.downloadedImagesIndex.removeAll()
        self.downloadImages.removeAll()
        self.downloadingImagesIndex.removeAll()
        self.executingTask.removeAll()
    }
    
    // 获取数据更新视图
    func select(notification: NSNotification) {
        datas = notification.object as? [Pic] ?? []
        clearCacheImages()
        reloadImages()
    }
    
    // 窗口事件
    func windowDidResize(notification: Notification) {
        tableView.reloadData()
    }
}
