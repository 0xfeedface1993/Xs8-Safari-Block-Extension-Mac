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
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func save(_ sender: Any) {
//        guard let modelURL = Bundle.main.url(forResource: "NetdiskModel", withExtension:"momd") else {
//            fatalError("Error loading model from bundle")
//        }
//        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
//            fatalError("Error initializing mom from: \(modelURL)")
//        }
        let app = NSApplication.shared().delegate as! AppDelegate
        let managedObjectContext = app.managedObjectContext

        let netdisk = NSEntityDescription.insertNewObject(forEntityName: "NetDisk", into: managedObjectContext) as! NetDisk
        netdisk.creattime = NSDate()
        netdisk.fileName = "testfile-\(UUID().uuidString).rar"
        netdisk.title = "badboy"
        netdisk.passwod = "unlock"

        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
//        app.resetAllRecords(in: "NetDisk")
    }
    
    @IBAction func extract(_ sender: Any) {
        let app = NSApplication.shared().delegate as! AppDelegate
        let managedObjectContext = app.managedObjectContext
        
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        
        do {
            let fetchedEmployees = try managedObjectContext.fetch(employeesFetch)
            var str = ""
            let calender = Calendar.current
            for item in fetchedEmployees {
                var comp = calender.dateComponents([.year, .month, .day, .hour, .minute], from: item.creattime! as Date)
                comp.timeZone = TimeZone(identifier: "Asia/Beijing")
                let cool = "\(comp.year!)/\(comp.month!)/\(comp.day!) \(comp.hour!):\(comp.minute!)"
                str += "\n\n标题：\(item.title ?? "bad")\n文件名:\(item.fileName ?? "bad")\n解压密码：\(item.passwod ?? "bad")\n创建时间:\(cool)\n"
                
                for link in item.link?.allObjects as? [Link] ?? [] {
                    str += "下载地址：\(link.link ?? "bad")\n"
                }
                
                for link in item.pic?.allObjects as? [Pic] ?? [] {
                    str += "图片地址：\(link.pic ?? "bad")\n"
                }
            }
            label.stringValue = str
            print(str)
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    @IBOutlet weak var extract: NSButton!
    
    
}

