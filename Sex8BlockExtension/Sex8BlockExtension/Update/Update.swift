//
//  Update.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2018/3/21.
//  Copyright © 2018年 ascp. All rights reserved.
//

import AppKit

struct UpdateInfo : Decodable {
    var version : String
    var description : String
    var dowloadLink : String
    func url() -> URL? {
        return URL(string: self.dowloadLink)
    }
}

/// 检查更新
protocol UpdateProtocol {
    
}

extension UpdateProtocol {
    func checkUpdate() {
        let url = URL(string: "http://p3im4gu21.bkt.clouddn.com/updatec.json")!
        let session = URLSession(configuration: URLSession.shared.configuration)
        session.configuration.urlCache = URLCache()
        session.configuration.urlCache?.removeAllCachedResponses()
        let task = session.downloadTask(with: url) { (filePath, response, err) in
            if let e = err {
                DispatchQueue.main.async {
                    NSApplication.shared.presentError(e)
                }
                return
            }
            
            guard let path = filePath else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.ascp.file.error", code: 101010, userInfo: ["description":"服务器数据错误"])
                    NSApplication.shared.presentError(error)
                }
                return
            }
            
            do {
                let data = try Data(contentsOf: path)
                let decoder = JSONDecoder()
                let json = try decoder.decode(UpdateInfo.self, from: data)
                DispatchQueue.main.async {
                    guard let keyWindow = NSApplication.shared.keyWindow else {  return }
                    if !Double(json.version)!.isLess(than: Double(Bundle.main.infoDictionary!["CFBundleVersion"] as! String) ?? 0)  {
                        let alert = NSAlert()
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "取消")
                        alert.addButton(withTitle: "下载")
                        alert.informativeText = json.description
                        alert.messageText = "发现新版本：\(json.version)"
                        alert.beginSheetModal(for: keyWindow, completionHandler: { (res) in
                            switch res {
                                case NSApplication.ModalResponse.alertFirstButtonReturn:
                                    break
                                default:
                                    if let url = json.url() {
                                       NSWorkspace.shared.open(url)
                                    }
                            }
                        })
                    }   else    {
                        let alert = NSAlert()
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.messageText = "已经是最新版本！"
                        alert.beginSheetModal(for: keyWindow, completionHandler: { (res) in
                            
                        })
                    }
                }
            }   catch   {
                DispatchQueue.main.async {
                    NSApplication.shared.presentError(error)
                }
            }
        }
        task.resume()
    }
}
