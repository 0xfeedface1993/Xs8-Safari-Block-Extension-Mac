//
//  ViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

let StopFetchName = NSNotification.Name.init("stopFetching")
let ShowExtennalTextName = NSNotification.Name.init("showExtennalText")

class ViewController: NSViewController {
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var collectionView: NSView!
    @IBOutlet weak var head: TapImageView!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var userprofile: NSTextField!
    @IBOutlet weak var extenalText: NSTextField!
    
    let login = NSStoryboard(name: NSStoryboard.Name.init(rawValue: "LoginStoryboard"), bundle: Bundle.main).instantiateInitialController() as! NSWindowController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        unselect()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.select), name: SelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.unselect), name: UnSelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.stopFetch), name: StopFetchName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.showExtennalText(notification:)), name: ShowExtennalTextName, object: nil)
        head.tapBlock = {
            image in
            let app = NSApp.delegate as! AppDelegate
            if let _ = app.user {
                
            }   else    {
                self.login.showWindow(nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UnSelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: StopFetchName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowExtennalTextName, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    @IBOutlet weak var extract: NSButton!
    
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
        let fetchButton = sender as! NSButton
        if fetchButton.tag == 110 {
            stopFetch()
        }   else    {
            fetchButton.tag = 110
            fetchButton.title = "停止"
        }
        NotificationCenter.default.post(name: TableViewRefreshName, object: fetchButton)
    }
    
    @objc func stopFetch() {
        extract.tag = 112
        extract.title = "抓取数据"
        self.extenalText.stringValue = ""
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        NotificationCenter.default.post(name: DeleteActionName, object: nil)
    }
    
    @objc func select() {
        
    }
    
    @objc func unselect() {
        
    }
    
    @objc func showExtennalText(notification: NSNotification?) {
        if let text = notification?.object as? String {
            self.extenalText.stringValue = text
        }
    }
}

// MARK: - Login Fun
extension ViewController {
    
}

