//
//  ContentCellView.swift
//  PopverTest
//
//  Created by virus1993 on 2018/2/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa
import WebShell_macOS

enum DownloadStatus : String {
    case downloading = "下载中"
    case downloaded = "完成"
    case waitting = "等待中"
    case cancel = "已取消"
    case errors = "失败"
    case abonden = "失效"
    static let statusColorPacks : [DownloadStatus:NSColor] = [.downloading:.green,
                                                              .downloaded:.blue,
                                                              .waitting:.lightGray,
                                                              .cancel:.darkGray,
                                                              .errors:.red,
                                                              .abonden:.brown]
}

extension WebHostSite {
    static let hostImagePack : [WebHostSite:NSImage] = [.feemoo:NSImage(named: "mofe_feemoo")!,
                                                        .pan666:NSImage(named: "mofe_666pan")!,
                                                        .cchooo:NSImage(named: "mofe_ccchooo")!,
                                                        .yousuwp:NSImage(named: "mofe_yousu")!,
                                                        .v2file:NSImage(named: "mofe_v4")!,
                                                        .xunniu:NSImage(named: "mofe_xunniu")!,
                                                        .xi:NSImage(named: "mofe_xi")!,
                                                        .unknowsite:NSImage(named: "mofe_feemoo")!]
}

/// 下载状态数据模型，用于视图数据绑定
class DownloadStateInfo : NSObject {
    var uuid = UUID()
    var status : DownloadStatus {
        didSet {
            update(newStatus: status)
        }
    }
    var hostType : WebHostSite {
        didSet {
            update(newSite: hostType)
        }
    }
    var originTask: PCDownloadTask?
    var mainURL : URL?
    weak var riffle: PCWebRiffle?
    @objc dynamic var name = ""
    @objc dynamic var progress = ""
    @objc dynamic var totalBytes = ""
    @objc dynamic var site = ""
    @objc dynamic var state = ""
    @objc dynamic var stateColor = NSColor.black
    @objc dynamic var isCanCancel : Bool = false
    @objc dynamic var isCanRestart : Bool = false
    @objc dynamic var isHiddenPrograss : Bool = false
    @objc dynamic var siteIcon : NSImage?
    override init() {
        status = .waitting
        hostType = .unknowsite
        super.init()
    }
    
    init(task: PCDownloadTask) {
        status = .downloading
        if let url = task.request.riffle?.mainURL {
            hostType = siteType(url: url)
        }   else    {
            hostType = .unknowsite
        }
        super.init()
        name = task.request.friendName
        let pros = task.pack.progress * 100.0
        let guts = Float(task.pack.totalBytes) / 1024.0 / 1024.0
        progress = String(format: "%.2f", pros)
        totalBytes = String(format: "%.2fM", guts)
        originTask = task
        mainURL = task.request.mainURL
        uuid = task.request.uuid
        update(newSite: hostType)
        update(newStatus: status)
    }
    
    init(riffle: PCWebRiffle) {
        status = .waitting
        hostType = riffle.host
        super.init()
        name = riffle.friendName.count <= 0 ? (riffle.mainURL?.absoluteString ?? "no url"):riffle.friendName
        mainURL = riffle.mainURL
        progress = "0"
        totalBytes = "0M"
        self.riffle = riffle
        uuid = riffle.uuid
        update(newSite: hostType)
        update(newStatus: status)
    }
    
    func update(newStatus: DownloadStatus) {
        state = newStatus.rawValue
        stateColor = DownloadStatus.statusColorPacks[status]!
        isCanCancel = status == .downloading || status == .waitting
        isCanRestart = status != .abonden && status != .waitting && status != .downloading
        isHiddenPrograss = status != .downloading
    }
    
    func update(newSite: WebHostSite) {
        siteIcon = WebHostSite.hostImagePack[newSite]!
    }
    
    override var description: String {
        return "status: \(status)\n hostType: \(hostType)\n name: \(name)\n uuid: \(uuid)\n progress: \(progress)\n" + "site: \(site)\n state: \(state)\n stateColor: \(stateColor)\n isCanCancel: \(isCanCancel)\n isCanRestart: \(isCanRestart)\n" + "isHiddenPrograss: \(isHiddenPrograss)\n siteIcon: \(String(describing: siteIcon))"
    }
}

class ContentCellView: NSTableCellView {
    @IBOutlet weak var thumbImage: NSImageView!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var prograssText: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var restart: NSButton!
    @IBOutlet weak var cancel: NSButton!
    weak var info : DownloadStateInfo?
    var restartAction : (()->())?
    var cancelAction : (()->())?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        restart.isHidden = true
        cancel.isHidden = true
//        restart.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tap(sender:))))
//        cancel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tap(sender:))))
    }
    
    @objc func tap(sender: NSClickGestureRecognizer) {
        guard let v = sender.view as? NSButton, v.isEnabled else { return }
        switch v {
        case self.restart:
            self.restartAction?()
            break
        case self.cancel:
            self.cancelAction?()
            break
        default:
            break
        }
    }
}
