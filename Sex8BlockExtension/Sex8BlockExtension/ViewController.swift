//
//  ViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var collectionView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        unselect()
        NotificationCenter.default.addObserver(self, selector: #selector(select), name: SelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unselect), name: UnSelectItemName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UnSelectItemName, object: nil)
    }

    @IBOutlet weak var address: NSButton!
    @IBOutlet weak var images: NSButton!
    @IBOutlet weak var extract: NSButton!
    @IBOutlet weak var pageURL: NSButton!
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func save(_ sender: Any) {
        let app = NSApplication.shared.delegate as! AppDelegate
        app.resetAllRecords(in: "NetDisk")
    }
    
    @IBAction func extract(_ sender: Any) {
        NotificationCenter.default.post(name: TableViewRefreshName, object: nil)
    }
    @IBAction func deleteAction(_ sender: Any) {
        NotificationCenter.default.post(name: DeleteActionName, object: nil)
    }
    
    @IBAction func showPicture(_ sender: Any) {
        NotificationCenter.default.post(name: ShowImagesName, object: nil)
    }
    
    @IBAction func pageURLAction(_ sender: Any) {
        
    }
    
    @IBAction func addressShow(_ sender: Any) {
        NotificationCenter.default.post(name: ShowDonwloadAddressName, object: nil)
    }
    
    @objc func select(notification: NSNotification) {
        images.isEnabled = true
        address.isEnabled = true
        pageURL.isEnabled = true
    }
    
    @objc func unselect() {
        images.isEnabled = false
        address.isEnabled = false
        pageURL.isEnabled = false
    }
    
}

