//
//  ContentViewController.swift
//  PopverTest
//
//  Created by virus1993 on 2018/2/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa

class ContentViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var resultArrayContriller: NSArrayController!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}

extension ContentViewController : NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (resultArrayContriller.content as? [DownloadInfo])?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("com.ascp.contentcell"), owner: self) as? ContentCellView
        cell?.restartAction = {
            DispatchQueue.main.async {
                (cell?.objectValue as? DownloadInfo)?.status = .downloading
            }
        }
        cell?.cancelAction = {
            DispatchQueue.main.async {
                (cell?.objectValue as? DownloadInfo)?.status = .cancel
            }
        }
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 73
    }
}
