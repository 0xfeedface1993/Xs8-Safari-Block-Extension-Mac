//
//  FileManagerExtension.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2018/2/11.
//  Copyright © 2018年 ascp. All rights reserved.
//

import AppKit

extension FileManager {
    func loadSex8(pic: Pic) -> NSImage? {
        guard let url = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("sex8"),
            let netDisks = pic.picnet?.allObjects as? [NetDisk],
            let dir = netDisks.first?.title?.replacingOccurrences(of: "/", with: "|"),
            dir != "",
            let picName = pic.filename,
            FileManager.default.fileExists(atPath: url.appendingPathComponent(dir + "/" + picName).path),
            let image = NSImage(contentsOfFile: url.appendingPathComponent(dir + "/" + picName).path)  else {
                return nil
        }
        return image
    }
    
    func saveSex8(pic: Pic, data: Data) {
        do {
            let url = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("sex8")
            let netDisks = pic.picnet?.allObjects as? [NetDisk] ?? []
            for net in netDisks {
                let manager = FileManager.default
                let netName = net.title ?? UUID().uuidString
                let secondURL = url?.appendingPathComponent(netName.replacingOccurrences(of: "/", with: "|"))
                
                if !manager.fileExists(atPath: secondURL?.path ?? "") {
                    try manager.createDirectory(at: secondURL!, withIntermediateDirectories: true, attributes: nil)
                }
                
                guard let pictureDomain = secondURL?.path, let urlString = pic.pic, let imageURL = URL(string: urlString) else {
                    print("--- no pic url! ---")
                    continue
                }
                
                let imgData = data
                pic.filename = imageURL.lastPathComponent
                let file = pictureDomain + "/" + imageURL.lastPathComponent
                
                guard !manager.fileExists(atPath: file) else {
                    print("--- FILE: " + file + " EXSIST! ---")
                    continue
                }
                
                if manager.createFile(atPath: file, contents: imgData, attributes: nil) {
                    print("save image:" + file + " successful!")
                }   else    {
                    print("save image:" + file + " faild!")
                }
            }
            let app = NSApp.delegate as! AppDelegate
            app.saveAction(nil)
        } catch {
            fatalError("Failed to fetch employees: \(error.localizedDescription)")
        }
    }
}
