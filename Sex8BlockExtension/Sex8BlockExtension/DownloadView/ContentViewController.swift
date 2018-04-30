//
//  ContentViewController.swift
//  PopverTest
//
//  Created by virus1993 on 2018/2/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import WebShell

class ContentViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var resultArrayContriller: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func add(riffle: PCWebRiffle) {
        let info = DownloadStateInfo(riffle: riffle)
        if let items = resultArrayContriller.content as? [DownloadStateInfo] {
            var newItems = items
            newItems.append(info)
            resultArrayContriller.content = newItems
        }   else    {
            resultArrayContriller.content = [info]
        }
    }
    
    func update(task: PCDownloadTask) {
        let info = DownloadStateInfo(task: task)
        if let items = resultArrayContriller.content as? [DownloadStateInfo], let index = items.index(where: { $0.uuid == info.uuid || $0.name == task.request.riffle?.mainURL?.absoluteString || $0.originTask?.request.url == info.originTask!.request.url}) {
            var newItems = items
            newItems[index] = info
            resultArrayContriller.content = newItems
        }   else    {
            resultArrayContriller.content = [info]
        }
    }
    
    func finished(task: PCDownloadTask) {
        let info = DownloadStateInfo(task: task)
        if let items = resultArrayContriller.content as? [DownloadStateInfo], let index = items.index(where: { $0.uuid == info.uuid || $0.name == task.request.riffle?.mainURL?.absoluteString || $0.originTask?.request.url == info.originTask!.request.url}) {
            print("found finished item!")
            var newItems = items
            info.status = .downloaded
            newItems[index] = info
            resultArrayContriller.content = newItems
        }   else    {
            print("Not found finished item \(info.name)!")
        }
    }
    
    func finished(riffle: PCWebRiffle) {
        if let items = resultArrayContriller.content as? [DownloadStateInfo], let index = items.index(where: { $0.riffle == riffle }) {
            print("found finished item!")
            var newItems = items
            newItems[index].status = .downloaded
            resultArrayContriller.content = newItems
        }   else    {
            print("Not found finished item \(riffle.mainURL?.absoluteString ?? "** no url **")!")
        }
    }
}

extension ContentViewController : NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (resultArrayContriller.content as? [DownloadStateInfo])?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("com.ascp.contentcell"), owner: self) as? ContentCellView
        cell?.restartAction = {
            if let riffle = (cell?.objectValue as? DownloadStateInfo)?.riffle {
                let pip = PCPipeline.share
                pip.remove(riffle: riffle)
                DispatchQueue.main.async {
                    if let items = self.resultArrayContriller.content as? [DownloadStateInfo] {
                        var newItems = items
                        newItems.remove(at: row)
                        self.resultArrayContriller.content = newItems
                    }
                    
                    guard let url = riffle.mainURL else {
                        print("Invalible mainURL!")
                        return
                    }
                    
                    riffle.seat?.restart(mainURL: url)
                }
                return
            }
            
            if let info = (cell?.objectValue as? DownloadStateInfo)?.originTask, let riffle = info.request.riffle {
                let pip = PCPipeline.share
                pip.remove(riffle: riffle)
                DispatchQueue.main.async {
                    if let items = self.resultArrayContriller.content as? [DownloadStateInfo] {
                        var newItems = items
                        newItems.remove(at: row)
                        self.resultArrayContriller.content = newItems
                    }
                    
                    guard let url = info.request.riffle?.mainURL else {
                        print("Invalible mainURL!")
                        return
                    }
                    
                    riffle.seat?.restart(mainURL: url)
                }
            }
        }
        cell?.cancelAction = {
            if let info = (cell?.objectValue as? DownloadStateInfo)?.originTask, let riffle = info.request.riffle {
                let pip = PCPipeline.share
                pip.remove(riffle: riffle)
            }   else if let riffle = (cell?.objectValue as? DownloadStateInfo)?.riffle {
                let pip = PCPipeline.share
                pip.remove(riffle: riffle)
            }
            DispatchQueue.main.async {
                (cell?.objectValue as? DownloadStateInfo)?.status = .cancel
            }
        }
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 73
    }
}
