//
//  PicsCollectionViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/6/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class PicsCollectionViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: NSCollectionView!
    let ImageViewIdentifier = "image"
    var datas = [Pic]()
    let defaultImage = NSImage(named: "watting.jpeg")
    var downloadedImagesIndex = [Int]()
    var downloadingImagesIndex = [Int]()
    var downloadImages = [Int:NSImage]()
    var executingTask = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        collectionView.register(ImageCollectionItem.self, forItemWithIdentifier: ImageViewIdentifier)
        let grid = NSCollectionViewFlowLayout()
        collectionView.collectionViewLayout = grid
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize(notification:)), name: NSNotification.Name.NSWindowDidResize, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
        reloadImages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSWindowDidResize, object: nil)
    }
    
    //MARK: - NSCollectionViewDelegate
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ImageViewIdentifier, for: indexPath) as! ImageCollectionItem
        item.maleImageView.image = downloadImages[indexPath.section]
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let item = downloadImages[indexPath.section]
        let padding : CGFloat = 20
        let width : CGFloat = view.bounds.size.width - padding
        if let w = item?.size.width, let h = item?.size.height {
            let size = CGSize(width: width, height: w >= view.bounds.size.width ? (width / w * h):h)
            return size
        }
        return CGSize(width: width, height: width / self.defaultImage!.size.width * self.defaultImage!.size.height)
    }
    
//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> EdgeInsets {
//        return NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
//
//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> NSSize {
        return NSSize(width: 0, height: 0)
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
                        self.downloadingImagesIndex.append(index)
                        let task = URLSession.shared.downloadTask(with: url, completionHandler: {
                            (url, response, error) in
                            if error == nil, let datURL = url, let img = NSImage(contentsOf: datURL) {
                                DispatchQueue.main.async {
                                    self.downloadedImagesIndex.append(index)
                                    self.downloadImages[index] = img
                                    if let indx = self.downloadingImagesIndex.index(of: index) {
                                        self.downloadingImagesIndex.remove(at: indx)
                                    }
                                    let app = NSApplication.shared().delegate as! AppDelegate
                                    let pic = self.datas[index]
                                    pic.data = img.tiffRepresentation as NSData?
                                    app.saveAction(nil)
                                    self.collectionView.reloadItems(at: [IndexPath(item: 0, section: index)])
                                    
                                }
                            }
                        })
                        self.executingTask.append(task)
                        task.resume()
                    }
                }
            }
        }
        collectionView.reloadData()
    }
    
    // 窗口事件
    func windowDidResize(notification: Notification) {
        collectionView.reloadData()
    }
}
