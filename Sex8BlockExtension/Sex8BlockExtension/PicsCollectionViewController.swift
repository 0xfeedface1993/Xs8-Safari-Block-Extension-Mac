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
    let defaultImage = NSImage(named: "watting")
    var downloadedImagesIndex = [Int]()
    var downloadingImagesIndex = [Int]()
    var downloadImages = [Int:NSImage]()
    var executingTask = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        collectionView.register(ImageCollectionItem.self, forItemWithIdentifier: ImageViewIdentifier)
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
        reloadImages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
    }
    
    //MARK: - NSCollectionViewDelegate
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ImageViewIdentifier, for: indexPath) as! ImageCollectionItem
        item.highImageView.image = downloadImages[indexPath.item]
//        if !downloadedImagesIndex.contains(indexPath.item), !downloadingImagesIndex.contains(indexPath.item) {
//            if let imageData = datas[indexPath.item].data, let image = NSImage(data: imageData as Data) {
//                self.downloadedImagesIndex.append(indexPath.item)
//                self.downloadImages[indexPath.item] = image
//                item.highImageView.image = downloadImages[indexPath.item]
//            }   else    {
//                item.highImageView.image = self.defaultImage
//                DispatchQueue.global().async {
//                    if let urlString = self.datas[indexPath.item].pic, let url = URL(string: urlString) {
//                        self.downloadingImagesIndex.append(indexPath.item)
//                        let task = URLSession.shared.downloadTask(with: url, completionHandler: {
//                            (url, response, error) in
//                            if error == nil, let datURL = url, let img = NSImage(contentsOf: datURL) {
//                                DispatchQueue.main.async {
//                                    item.highImageView.image = img
//                                    self.downloadedImagesIndex.append(indexPath.item)
//                                    self.downloadImages[indexPath.item] = img
//                                    if let indx = self.downloadingImagesIndex.index(of: indexPath.item) {
//                                        self.downloadingImagesIndex.remove(at: indx)
//                                    }
//                                    let app = NSApplication.shared().delegate as! AppDelegate
//                                    let pic = self.datas[indexPath.item]
//                                    pic.data = img.tiffRepresentation as NSData?
//                                    app.saveAction(nil)
//                                }
//                            }
//                        })
//                        self.executingTask.append(task)
//                        task.resume()
//                    }
//                }
//            }
//        }   else if downloadingImagesIndex.contains(indexPath.item) {
//            item.highImageView.image = self.defaultImage
//        }   else if downloadedImagesIndex.contains(indexPath.item) {
//            item.highImageView.image = downloadImages[indexPath.item]
//        }
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let item = downloadImages[indexPath.item]
        if let w = item?.size.width, let h = item?.size.height {
            let width = view.frame.size.width - 10
            let height = width / w * h
            return CGSize(width: width, height: height)
        }
        return CGSize(width: view.frame.size.width - 10, height: (view.frame.size.width - 10) / self.defaultImage!.size.width * self.defaultImage!.size.height)
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
                                    self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                                    
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
}
