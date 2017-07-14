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
    }
    
}
