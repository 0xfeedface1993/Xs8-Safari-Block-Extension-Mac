//
//  PicsCollectionViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/6/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class PicsCollectionViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
    @IBOutlet weak var collectionView: NSCollectionView!
    let ImageViewIdentifier = "image"
    var datas = [Pic]()
    let defaultImage = NSImage(named: "watting")
    var downloadedImagesIndex = [IndexPath]()
    var downloadingImagesIndex = [IndexPath]()
    var downloadImages = [IndexPath:NSImage]()
    var executingTask = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        collectionView.register(ImageCollectionItem.self, forItemWithIdentifier: ImageViewIdentifier)
        let flow = collectionView.collectionViewLayout as! NSCollectionViewFlowLayout
        flow.itemSize = CGSize(width: view.frame.size.width - 10, height: view.frame.size.height - 10)
        flow.minimumLineSpacing = 5
        flow.minimumInteritemSpacing = 5
    }
    
    //MARK: - NSCollectionViewDelegate
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
//        datas.forEach({
//            item in
//            print(item.pic ?? "")
//        })
        return datas.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ImageViewIdentifier, for: indexPath) as! ImageCollectionItem
        
        if !downloadedImagesIndex.contains(indexPath), !downloadingImagesIndex.contains(indexPath) {
            if let imageData = datas[indexPath.item].data, let image = NSImage(data: imageData as Data) {
                self.downloadedImagesIndex.append(indexPath)
                self.downloadImages[indexPath] = image
                item.highImageView.image = downloadImages[indexPath]
            }   else    {
                item.highImageView.image = self.defaultImage
                DispatchQueue.global().async {
                    if let urlString = self.datas[indexPath.item].pic, let url = URL(string: urlString) {
                        self.downloadingImagesIndex.append(indexPath)
                        let task = URLSession.shared.downloadTask(with: url, completionHandler: {
                            (url, response, error) in
                            if error == nil, let datURL = url, let img = NSImage(contentsOf: datURL) {
                                DispatchQueue.main.async {
                                    item.highImageView.image = img
                                    self.downloadedImagesIndex.append(indexPath)
                                    self.downloadImages[indexPath] = img
                                    if let indx = self.downloadingImagesIndex.index(of: indexPath) {
                                        self.downloadingImagesIndex.remove(at: indx)
                                    }
                                    let app = NSApplication.shared().delegate as! AppDelegate
                                    let pic = self.datas[indexPath.item]
                                    pic.data = img.tiffRepresentation as NSData?
                                    app.saveAction(nil)
                                }
                            }
                        })
                        self.executingTask.append(task)
                        task.resume()
                    }
                }
            }
        }   else if downloadingImagesIndex.contains(indexPath) {
            item.highImageView.image = self.defaultImage
        }   else if downloadedImagesIndex.contains(indexPath) {
            item.highImageView.image = downloadImages[indexPath]
        }
        
        return item
    }
    
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
}
