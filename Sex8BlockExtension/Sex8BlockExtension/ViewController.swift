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
        let psc = app.persistentContainer.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
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
    }
    
    @IBAction func extract(_ sender: Any) {
        let app = NSApplication.shared().delegate as! AppDelegate
        let psc = app.persistentContainer
        let managedObjectContext = psc.viewContext
        
        let employeesFetch = NSFetchRequest<NetDisk>(entityName: "NetDisk")
        
        do {
            let fetchedEmployees = try managedObjectContext.fetch(employeesFetch)
            var str = ""
            for item in fetchedEmployees {
                str += "filename:\(item.fileName ?? "bad")\ntime:\(item.creattime ?? NSDate())\n"
            }
            label.stringValue = str
            print(str)
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
    }
    
    @IBOutlet weak var extract: NSButton!
    
}

