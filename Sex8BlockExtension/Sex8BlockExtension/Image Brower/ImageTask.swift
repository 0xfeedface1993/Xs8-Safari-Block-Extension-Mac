//
//  ImageTask.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2018/2/11.
//  Copyright © 2018年 ascp. All rights reserved.
//

import AppKit

let defaultImage = NSImage(named: NSImage.Name(rawValue: "watting.jpeg"))!
let errorImage = NSImage(named: NSImage.Name(rawValue: "error"))!

/// 图片下载状态
///
/// - none: 初始状态
/// - downloaded: 下载完成
/// - downloading: 下载中
/// - cancel: 被取消下载
/// - failed: 下载失败
enum ImageDownloadState {
    case none
    case downloaded
    case downloading
    case cancel
    case failed
}

/// 图片下载人物管理
class ImageTask : Equatable {
    typealias FinishedCallBack = ((ImageTask) -> ())
    var pic : Pic
    var task : URLSessionDownloadTask?
    var state : ImageDownloadState
    var finishedAction : FinishedCallBack?
    private var _image : NSImage?
    var image : NSImage {
        get {
            switch state {
            case .none, .downloading:
                return defaultImage
            case .cancel, .failed:
                return errorImage
            case .downloaded:
                return _image ?? errorImage
            }
        }
    }
    
    func start() {
        guard let image = FileManager.default.loadSex8(pic: pic) else {
            downloadingImage()
            return
        }
        _image = image
        state = .downloaded
    }
    
    private func downloadingImage() {
        let picx = pic
        if let urlString = picx.pic, let url = URL(string: urlString) {
            print(url)
            state = .downloading
            let task = URLSession.shared.downloadTask(with: url, completionHandler: {
                (url, response, error) in
                if error != nil {
                    self.state = .failed
                    print("error : \(error.debugDescription)")
                    self.finishedAction?(self)
                    return
                }
                
                guard let datURL = url, let img = NSImage(contentsOf: datURL) else {
                    self.state = .failed
                    print("bad image data!")
                    self.finishedAction?(self)
                    return
                }
                
                self.state = .downloaded
                self._image = img
                FileManager.default.saveSex8(pic: picx, data: img.tiffRepresentation!)
                self.finishedAction?(self)
            })
            self.task = task
            task.resume()
        }   else    {
            state = .failed
            _image = nil
        }
    }
    
    func stop() {
        if let tk = task, tk.state == .running {
            tk.cancel()
            state = .cancel
            _image = nil
        }
    }
    
    func reset() {
        state = .none
        task = nil
        _image = nil
    }
    
    init(picture: Pic, finished: FinishedCallBack?) {
        self.pic = picture
        self.state = .none
        self.finishedAction = finished
    }
    
    static func ==(lhs: ImageTask, rhs: ImageTask) -> Bool {
        return lhs.pic == rhs.pic
    }
}
