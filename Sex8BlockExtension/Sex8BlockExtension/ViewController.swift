//
//  ViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1993 on 2017/6/13.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa
import WebShell

let StopFetchName = NSNotification.Name.init("stopFetching")
let ShowExtennalTextName = NSNotification.Name.init("showExtennalText")
let UploadName = NSNotification.Name.init("UploadName")
let DownloadAddressName = NSNotification.Name.init("com.ascp.dowload.address.click")

var searchText : String?

class ViewController: NSViewController, UpdateProtocol {
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var collectionView: NSView!
    @IBOutlet weak var head: TapImageView!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var userprofile: NSTextField!
    @IBOutlet weak var extenalText: NSTextField!
    @IBOutlet weak var searchArea: NSSearchField!
    @IBOutlet weak var downloadButton: NSButton!
    
    lazy var downloadViewController : ContentViewController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "com.ascp.contenView")) as! ContentViewController
    
    lazy var popver : NSPopover = {
        let popver = NSPopover()
        popver.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        let vc = self.downloadViewController
        vc.view.wantsLayer = true
        vc.view.layer?.cornerRadius = 10
        popver.contentViewController = vc
        popver.behavior = .transient
        return popver
    }()
    
    var downloadURL : URL?
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(changeDownloadState(notification: )), name: DownloadAddressName, object: nil)
        head.tapBlock = {
            [weak self] image in
//            let app = NSApp.delegate as! AppDelegate
//            if let _ = app.user {
//
//            }   else    {
//                self.login.showWindow(nil)
//            }
            self?.popver.show(relativeTo: image.bounds, of: image, preferredEdge: .maxY)
        }
        searchArea.delegate = self
        upload.isHidden = true
//        extract.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: SelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: UnSelectItemName, object: nil)
        NotificationCenter.default.removeObserver(self, name: StopFetchName, object: nil)
        NotificationCenter.default.removeObserver(self, name: ShowExtennalTextName, object: nil)
        NotificationCenter.default.removeObserver(self, name: DownloadAddressName, object: nil)
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
        extract.title = "获取前十页"
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
    
    //MARK: - 下载
    @IBAction func download(_ sender: Any) {
        defer {
            downloadButton.isEnabled = false
        }
        
        guard let link = downloadURL else {
            print("dowloadURL is nil!")
            return
        }
        
        let pipline = PCPipeline.share
        pipline.delegate = self
        let app = NSApp.delegate as! AppDelegate
        let password = app.selectItem?.passwod ?? ""
        if let _ = pipline.add(url: link.absoluteString, password: password) {
//            riffle.downloadStateController = downloadViewController.resultArrayContriller
            view.toast("成功添加下载任务")
        }
    }
    
    @objc func changeDownloadState(notification: Notification) {
        guard let linkString = notification.object as? String else {
            print("none string object!")
            downloadButton.isEnabled = false
            downloadURL = nil
            return
        }
        
        guard let linkURL = URL(string: linkString) else {
            print("none URL string!")
            downloadButton.isEnabled = false
            downloadURL = nil
            return
        }
        
        downloadURL = linkURL
        downloadButton.isEnabled = true
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

extension ViewController : PCPiplineDelegate {
    func downloadVC() -> ContentViewController? {
        let windows = NSApplication.shared.windows
        return windows.first(where: { w in
            return w.contentViewController is ContentViewController
        })?.contentViewController as? ContentViewController
    }
    
//    func pipline(didAddRiffle riffle: PCWebRiffle) {
//        guard let vc = downloadVC() else { return }
//        print("found \(vc)")
//        vc.add(riffle: riffle)
//    }
//
//    func pipline(didBeginRiffle riffle: PCWebRiffle) {
//
//    }
//
//    func pipline(didFinishedRiffle riffle: PCWebRiffle) {
//
//    }
//
//    func pipline(didUpdateTask task: PCDownloadTask) {
//        guard let vc = downloadVC() else { return }
//        vc.update(task: task)
//    }
//
//    func pipline(didFinishedTask task: PCDownloadTask, withError error: Error?) {
//        guard let vc = downloadVC() else { return }
//        vc.finished(task: task)
//    }
    
    func pipline(didAddRiffle riffle: PCWebRiffle) {
        guard let vc = downloadVC() else { return }
        print("found \(vc)")
        vc.add(riffle: riffle)
    }
    
    func pipline(didUpdateTask task: PCDownloadTask) {
        guard let vc = downloadVC() else { return }
        vc.update(task: task)
    }
    
    func pipline(didFinishedTask task: PCDownloadTask) {
        guard let vc = downloadVC() else { return }
        vc.finished(task: task)
    }
    
    func pipline(didFinishedRiffle riffle: PCWebRiffle) {
        guard let vc = downloadVC() else { return }
        if let task = PCDownloadManager.share.allTasks.first(where: { $0.request.riffle == riffle }) {
            vc.finished(task: task)
        }   else    {
            vc.finished(riffle: riffle)
        }
    }
}
