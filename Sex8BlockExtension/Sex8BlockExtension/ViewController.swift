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
let UploadName = NSNotification.Name.init("UploadName")

var searchText : String?

class ViewController: NSViewController {
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var collectionView: NSView!
    @IBOutlet weak var head: TapImageView!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var userprofile: NSTextField!
    @IBOutlet weak var extenalText: NSTextField!
    @IBOutlet weak var searchArea: NSSearchField!
    
    let login = NSStoryboard(name: NSStoryboard.Name.init(rawValue: "LoginStoryboard"), bundle: Bundle.main).instantiateInitialController() as! NSWindowController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        unselect()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.select), name: SelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.unselect), name: UnSelectItemName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.stopFetch), name: StopFetchName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.showExtennalText(notification:)), name: ShowExtennalTextName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetSearchValue(notification:)), name: NSControl.textDidChangeNotification, object: nil)
        head.tapBlock = {
            image in
            let app = NSApp.delegate as! AppDelegate
            if let _ = app.user {
                
            }   else    {
                self.login.showWindow(nil)
            }
        }
        searchArea.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UnSelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: StopFetchName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowExtennalTextName, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSControl.textDidChangeNotification, object: nil)
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
        extract.title = "提取"
        self.extenalText.stringValue = "(已停止)" + self.extenalText.stringValue
        
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        NotificationCenter.default.post(name: DeleteActionName, object: nil)
    }
    
    @objc func select() {
        
    }
    
    @objc func unselect() {
        
    }
    @IBOutlet weak var upload: NSButton!
    
    @IBAction func uploadAction(_ sender: Any) {
        if upload.title == "上传" {
            upload.title = "停止"
            NotificationCenter.default.post(name: UploadName, object: nil)
        }   else    {
            upload.title = "上传"
            NotificationCenter.default.post(name: UploadName, object: 444)
        }
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

// MARK: - TextFieldDelegate
extension ViewController : NSSearchFieldDelegate {
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        print("start search!")
        
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
         print("end search")
    }
    
    @objc func resetSearchValue(notification: NSNotification?) {
        print("change text value \(searchArea.stringValue)")
        
    }
}
