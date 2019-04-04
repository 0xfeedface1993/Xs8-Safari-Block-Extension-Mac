//
//  ZoomImageViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

let ImagePickerNotification = Notification.Name("imagePicker")

class ZoomImageViewController: NSViewController {
    @IBOutlet weak var imageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let image = NSImage(named: "error")
        imageView.image = image
        NotificationCenter.default.addObserver(forName: ImagePickerNotification, object: nil, queue: OperationQueue.main, using: {
            notification in
            self.reciveImageData(notification: notification)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: ImagePickerNotification, object: nil)
    }
    
    func reciveImageData(notification: Notification)  {
        guard let image = notification.object as? NSImage else {
            return
        }
        imageView.image = image
        
        var size = NSSize(width: image.size.width, height: image.size.height)
        if size.width > NSScreen.main!.frame.size.width || size.height > NSScreen.main!.frame.size.width {
            size.width = NSScreen.main!.frame.size.width
            size.height = NSScreen.main!.frame.size.height
        }
        
        view.window?.setFrameOrigin(NSPoint(x: 0, y: 0))
        view.window?.setContentSize(NSSize(width: size.width, height: size.height))
    }
}
