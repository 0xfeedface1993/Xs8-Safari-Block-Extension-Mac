//
//  ContentCellView.swift
//  PopverTest
//
//  Created by virus1993 on 2018/2/27.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Cocoa

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

public enum WebHostSite : Int {
    case feemoo
    case pan666
    case cchooo
    case unknowsite
    static let hostImagePack : [WebHostSite:NSImage] = [.feemoo:NSImage(named: NSImage.Name("mofe_feemoo"))!,
                                                        .pan666:NSImage(named: NSImage.Name("mofe_666pan"))!,
                                                        .cchooo:NSImage(named: NSImage.Name("mofe_ccchooo"))!,
                                                        .unknowsite:NSImage(named: NSImage.Name("mofe_feemoo"))!]
}

/// 下载状态数据模型，用于视图数据绑定
class DownloadInfo : NSObject {
    let uuid = UUID().uuidString
    var status : DownloadStatus {
        didSet {
            state = status.rawValue
            stateColor = DownloadStatus.statusColorPacks[status]!
            isCanCancel = status == .downloading || status == .waitting
            isCanRestart = status != .abonden && status != .waitting
            isHiddenPrograss = status != .downloading
        }
    }
    var hostType : WebHostSite {
        didSet {
            siteIcon = WebHostSite.hostImagePack[hostType]!
        }
    }
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
}

class ContentCellView: NSTableCellView {
    @IBOutlet weak var thumbImage: NSImageView!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var prograssText: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var status: NSTextField!
    @IBOutlet weak var restart: NSButton!
    @IBOutlet weak var cancel: NSButton!
    weak var info : DownloadInfo?
    var restartAction : (()->())?
    var cancelAction : (()->())?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        restart.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tap(sender:))))
        cancel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(tap(sender:))))
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
