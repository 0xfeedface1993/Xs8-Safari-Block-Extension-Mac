//
//  FilePathSelectorViewController.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/7/16.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Cocoa

let ImageFilePathKey = "imageFilePath"

class FilePathSelectorViewController: NSViewController {
    @IBOutlet weak var filePath: NSTextField!
    let defaultSet = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        do {
            let url = try FileManager.default.url(for: .picturesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            filePath.stringValue = url.appendingPathExtension("sex8").path
//            readAllImageAndSave(specifcalURL: url)
        } catch {
            print("url fetch error!: \(error.localizedDescription)")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                let alert = NSAlert()
                alert.addButton(withTitle: "确定")
                alert.messageText = "图片路径读取失败"
                alert.informativeText = " \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.beginSheetModal(for: NSApplication.shared.keyWindow!, completionHandler: {
                    code in
                    switch code {
                    case NSApplication.ModalResponse.alertFirstButtonReturn:
                        self.view.window?.close()
                        break
                    default:
                        break
                    }
                })
            })
        }
        
//        if let dir = defaultSet.url(forKey: ImageFilePathKey) {
//            filePath.stringValue = dir.path
//        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
//        NSApp.stopModal()
    }
    
    @IBAction func modifyPath(_ sender: Any) {
//        let savePanel = NSSavePanel()
//        savePanel.message = "选择图片保存的路径"
//        savePanel.nameFieldLabel = "文件夹路径"
//        savePanel.allowedFileTypes = ["jpg", "jpeg", "png"]
//        savePanel.allowsOtherFileTypes = true
//        savePanel.canCreateDirectories = true
//        
//        savePanel.beginSheetModal(for: NSApplication.shared().keyWindow!, completionHandler: {
//            response in
//            if response == NSFileHandlingPanelOKButton, let dir = savePanel.directoryURL {
//                print(dir)
//                self.defaultSet.set(dir, forKey: ImageFilePathKey)
//                self.readAllImageAndSave(specifcalURL: dir)
//            }
//        })
        
//        let openPanel = NSOpenPanel()
//        openPanel.canChooseDirectories = true
//        openPanel.canChooseFiles = false
//        openPanel.allowsMultipleSelection = false
//        openPanel.canCreateDirectories = true
//        openPanel.beginSheetModal(for: NSApplication.shared().keyWindow!, completionHandler: {
//            response in
//            if response == NSFileHandlingPanelOKButton, let dir = openPanel.directoryURL {
//                print(dir)
//                self.defaultSet.set(dir, forKey: ImageFilePathKey)
//                self.readAllImageAndSave()
//            }
//        })
    }
    
    func readAllImageAndSave(specifcalURL: URL?) {
        let managedObjectContext = DataBase.share.managedObjectContext
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        let sort = NSSortDescriptor(key: "creattime", ascending: false)
        employeesFetch.sortDescriptors = [sort]
        
        do {
            let datas = try managedObjectContext.fetch(employeesFetch)
            let manager = FileManager.default
            if let pictureDomain = specifcalURL?.path {
                for net in datas {
                    let netName = net.title ?? UUID().uuidString
                    let netPath = pictureDomain + "/" + netName.replacingOccurrences(of: "/", with: "|")
                    if !manager.fileExists(atPath: netPath) {
                        try manager.createDirectory(atPath: netPath, withIntermediateDirectories: false, attributes: nil)
                    }
                    
                    for pic in net.pic?.allObjects as? [Pic] ?? [] {
                        if let img = pic.data, let urlString = pic.pic, let url = URL(string: urlString) {
                            let imgData = img as Data
                            let file = netPath + "/" + url.lastPathComponent
                            if !manager.fileExists(atPath: file), manager.createFile(atPath: file, contents: imgData, attributes: nil) {
                                print("save image:" + file)
                            }   else    {
                                print("save image:" + file + " faild!")
                            }
                        }
                    }
                    
                }
            }
            self.view.window?.close()
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
}
