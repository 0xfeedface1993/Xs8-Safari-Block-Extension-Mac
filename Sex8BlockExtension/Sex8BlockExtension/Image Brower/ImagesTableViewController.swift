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
    let defaultImage = NSImage(named: NSImage.Name(rawValue: "watting.jpeg"))
    let errorImage = NSImage(named: NSImage.Name(rawValue: "error"))
    var downloadedImagesIndex = [Int]()
    var downloadingImagesIndex = [Int]()
    var downloadImages = [Int:NSImage]()
    var executingTask = [URLSessionDownloadTask]()
    let ImageCellIdentifier = "ImageCell"
    let zoom = NSStoryboard(name: NSStoryboard.Name(rawValue: "ZoomStoryboard"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "ZoomKeeper")) as? NSWindowController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize(notification:)), name: NSWindow.didResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
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
        return datas.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ImageCellIdentifier), owner: self) as? ImageTableViewCell else {
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
        func downloadingImage(index: Int, pic: Pic) {
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
                                //                                    let app = NSApplication.shared().delegate as! AppDelegate
                                //                                    pic.data = img.tiffRepresentation as NSData?
                                //                                    app.saveAction(nil)
                                let pic = self.datas[index]
                                self.savePicInPictureDir(pic: pic, imageData: img.tiffRepresentation!)
                                self.tableView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                            }
                        })
                        self.executingTask.append(task)
                        task.resume()
                    }
                }
            }
        }
        
        for (index, pic) in datas.enumerated() {
            guard let url = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("sex8"),
                let netDisks = pic.picnet?.allObjects as? [NetDisk],
                let dir = netDisks.first?.title?.replacingOccurrences(of: "/", with: "|"),
                dir != "",
                let picName = pic.filename,
                FileManager.default.fileExists(atPath: url.appendingPathComponent(dir + "/" + picName).path),
                let image = NSImage(contentsOfFile: url.appendingPathComponent(dir + "/" + picName).path)  else {
                downloadingImage(index: index, pic: pic)
                continue
            }
            downloadedImagesIndex.append(index)
            downloadImages[index] = image
        }
        tableView.reloadData()
        tableView.scroll(CGPoint(x: 0, y: 0))
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let image = downloadImages[tableView.selectedRow]
        
        if tableView.selectedRow >= 0, image != defaultImage, image != errorImage {
            zoom?.showWindow(zoom)
            tableView.deselectRow(tableView.selectedRow)
            NotificationCenter.default.post(name: ImagePickerNotification, object: image)
        }
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
    @objc func select(notification: NSNotification) {
        datas = (notification.object as? NetDisk)?.pic?.allObjects as? [Pic] ?? []
        clearCacheImages()
        reloadImages()
    }
    
    // 窗口事件
    @objc func windowDidResize(notification: Notification) {
        tableView.reloadData()
    }
    
    func savePicInPictureDir(pic: Pic, imageData: Data) {
        do {
            let url = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("sex8")
            let netDisks = pic.picnet?.allObjects as? [NetDisk] ?? []
            for net in netDisks {
                let manager = FileManager.default
                let netName = net.title ?? UUID().uuidString
                let secondURL = url?.appendingPathComponent(netName.replacingOccurrences(of: "/", with: "|"))
                
                if !manager.fileExists(atPath: secondURL?.path ?? "") {
                    try manager.createDirectory(at: secondURL!, withIntermediateDirectories: true, attributes: nil)
                }
                
                guard let pictureDomain = secondURL?.path, let urlString = pic.pic, let imageURL = URL(string: urlString) else {
                    print("--- no pic url! ---")
                    continue
                }
                
                let imgData = imageData
                pic.filename = imageURL.lastPathComponent
                let file = pictureDomain + "/" + imageURL.lastPathComponent
                
                guard !manager.fileExists(atPath: file) else {
                    print("--- FILE: " + file + " EXSIST! ---")
                    continue
                }
                
                if manager.createFile(atPath: file, contents: imgData, attributes: nil) {
                    print("save image:" + file + " successful!")
                }   else    {
                    print("save image:" + file + " faild!")
                }
            }
            let app = NSApp.delegate as! AppDelegate
            app.saveAction(nil)
        } catch {
            fatalError("Failed to fetch employees: \(error.localizedDescription)")
        }
    }
}
