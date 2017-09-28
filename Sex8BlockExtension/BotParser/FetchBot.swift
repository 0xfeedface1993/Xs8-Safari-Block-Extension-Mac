//
//  FetchBot.swift
//  AutoFech
//
//  Created by virus1994 on 2017/9/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

// struct
struct ListItem : Equatable {
    var title : String
    var href : String
    var previewImages : [String]
    init(data: [String:Any]) {
        title = data["title"] as? String ?? ""
        href = data["href"] as? String ?? ""
        previewImages = data["images"] as? [String] ?? []
    }
    
    static func ==(lhs: ListItem, rhs: ListItem) -> Bool {
        return lhs.title == rhs.title && lhs.href == rhs.href
    }
}

/// struct
enum FetchBoard : Int {
    case netDisk = 103
}

/// 列表页面链接信息
struct FetchURL : Equatable {
    var site : String
    var board : FetchBoard
    var page : Int
    var maker : (FetchURL) -> String
    var url : URL {
        get {
            return URL(string: maker(self))!;
        }
    }
    
    static func ==(lhs: FetchURL, rhs: FetchURL) -> Bool {
        return lhs.url == rhs.url
    }
}

/// 抓取内容页面信息模型
struct ContentInfo {
    var title : String
    var page : String
    var msk : String
    var time : String
    var size : String
    var format : String
    var passwod : String
    var downloafLink : [String]
    var imageLink : [String]
    init() {
        page = ""
        title = ""
        msk = ""
        time = ""
        size = ""
        format = ""
        passwod = ""
        downloafLink = [String]()
        imageLink = [String]()
    }
}

/// 内容信息正则规则选项
struct InfoRuleOption {
    /// 是否有码
    static let msk = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【是否有码】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    /// 影片时间
    static let time = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片时间】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：])+")
    /// 影片大小
    static let size = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片大小】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    /// 影片格式
    static let format = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片格式】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    /// 解压密码
    static let password = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【解壓密碼】)|(【解压密码】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    /// 下载链接
    static let downloadLink = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+\" \\w+=\"\\w+\"", hasSuffix: false, innerRegex: "\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+")
    /// 图片链接
    static let imageLink = ParserTagRule(tag: "img", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "file"), ParserAttrubuteRule(key: "href"), ParserAttrubuteRule(key: "src")], inTagRegexString: "(( \\w+=\"[\\w+\\(,\\)\\.\\s\\-]+\")|( \\w+=\"[\\w+:/\\.\\)\\(:;\\s\\-]*?\")){6,} /", hasSuffix: false, innerRegex: nil)
    /// 主内容标签
    static let main = ParserTagRule(tag: "td", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"t_f\" \\w+=\"postmessage_\\d+\"", hasSuffix: true, innerRegex: nil)
}

/// 列表页面正则规则选项
struct PageRuleOption {
    /// 内容页面链接
    static let link = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "href")], inTagRegexString: " href=\"\\w+(\\-[\\d]+)+.\\w+\" \\w+=\"\\w+\\(\\w+\\)\" class=\"s xst\"", hasSuffix: true, innerRegex: nil)
    static let content = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "<tbody id=\"separatorline\">", hasSuffix: false, innerRegex: "[\\s\\S]*")
}

/// 自动抓取机器人
class FetchBot {
    let backgroundQueue = DispatchQueue.global()
    let backgroundGroup = DispatchGroup()
    var delegate : FetchBotDelegate?
    var contentDatas = [ContentInfo]()
    var runTasks = [FetchURL]()
    var badTasks = [FetchURL]()
    var startPage: UInt = 1
    var pageOffset: UInt = 0
    var count : Int = 0
    var startTime : Date?
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - start: 开始页面，大于1
    ///   - offset: 结束页面 = start + offset
    init(start: UInt = 1, offset: UInt = 0) {
        self.startPage = start > 0 ? start:1
        self.pageOffset = offset
    }
    
    func start() {
        startTime = Date()
        runTasks.removeAll()
        badTasks.removeAll()
        count = 0
        contentDatas.removeAll()
        delegate?.bot(didStartBot: self)
        fetchGroup(start: startPage, offset: pageOffset)
//        DispatchQueue.global().async {
//            self.serialFetch(start: self.startPage, offset: self.pageOffset)
//        }
//        fetchMainContent(title: "aaaaaa", link: "thread-8748151-1-15.html", page: 0, index: 0)
    }
    
    func stop() {
        
    }
    
    private func serialFetch(start: UInt, offset: UInt) {
        let startTime = Date()
        let maker : (FetchURL) -> String = { (s) -> String in
            "http://\(s.site)/forum-\(s.board.rawValue)-\(s.page).html"
        }
        let topQueue = DispatchQueue(label: "com.ascp.top")
        let group = DispatchGroup()
        var sem = DispatchSemaphore(value: 0)
        var list = [ListItem]()
        
        for i in start...(start + offset) {
            let fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: Int(i), maker: maker)
            let request = browserRequest(url: fetchURL.url)
            topQueue.async(group: group, execute: DispatchWorkItem(block: {
                let semx = DispatchSemaphore(value: 0)
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
                    guard let result = data, let html = String(data: result, encoding: .utf8) else {
                        if let e = err {
                            print(e)
                        }
                        self.badTasks.append(fetchURL)
                        return
                    }
                    
                    if let _ = html.range(of: "<html>\r\n<head>\r\n<META NAME=\"robots\" CONTENT=\"noindex,nofollow\">") {
                        print("---------- robot detected! ----------")
                        self.badTasks.append(fetchURL)
                        return
                    }
                    self.runTasks.append(fetchURL)
                    let rule = PageRuleOption.link
                    if let pages = parse(string:html, rule: rule) {
                        print("+++ 解析到 \(pages.count) 个内容链接")
                        for (_, page) in pages.enumerated() {
                            let title = page.innerHTML
                            guard let href = page.attributes["href"] else {
                                continue
                            }
                            self.count += 1
                            list.append(ListItem(data: ["title":title, "href":href, "imagess":[]]))
                        }
                    }
                    semx.signal()
                })
                task.resume()
                semx.wait()
            }))
        }
        
        group.notify(queue: topQueue) {
            sem.signal()
        }
        
        sem.wait()
        print("links : \(list.count), spend time: \(Date().timeIntervalSince(startTime))")
        
        sem = DispatchSemaphore(value: 0)
        count = list.count
        let contentQueue = DispatchQueue(label: "com.ascp.content")
        let contentGroup = DispatchGroup()
        var items = [ContentInfo]()
        for (index, link) in list.enumerated() {
            let linkMaker : (FetchURL) -> String = { (s) -> String in
                "http://\(s.site)/\(link.href)"
            }
            let linkURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: 0, maker: linkMaker)
            let request = browserRequest(url: linkURL.url)
            contentQueue.async(group: contentGroup, execute: DispatchWorkItem(block: {
                let semx = DispatchSemaphore(value: 0)
                let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
                    guard let result = data, let html = String(data: result, encoding: .utf8) else {
                        if let e = err {
                            print(e)
                        }
                        self.badTasks.append(linkURL)
                        return
                    }
                    
                    if let _ = html.range(of: "<html>\r\n<head>\r\n<META NAME=\"robots\" CONTENT=\"noindex,nofollow\">") {
                        print("---------- robot detected! ----------")
                        self.badTasks.append(linkURL)
                        return
                    }
                    print("+++ 正在解析 \(index) 项 +++")
                    let rule = InfoRuleOption.main
                    if let mainContent = parse(string:html, rule: rule)?.first?.innerHTML {
                        var info = ContentInfo()
                        info.title =  link.title
                        
                        let dowloadLinkRule = InfoRuleOption.downloadLink
                        for linkResult in parse(string:mainContent, rule: dowloadLinkRule) ?? [] {
                            info.downloafLink.append(linkResult.innerHTML)
                        }
                        
                        let imageLinkRule = InfoRuleOption.imageLink
                        for imageResult in parse(string:mainContent, rule: imageLinkRule) ?? [] {
                            for attribute in imageLinkRule.attrubutes {
                                if let item = imageResult.attributes[attribute.key] {
                                    info.imageLink.append(item)
                                    break
                                }
                            }
                        }
                        
                        let mskRule = InfoRuleOption.msk
                        for mskResult in parse(string:mainContent, rule: mskRule) ?? [] {
                            info.msk = mskResult.innerHTML
                        }
                        
                        let timeRule = InfoRuleOption.time
                        for timeResult in parse(string:mainContent, rule: timeRule) ?? [] {
                            info.time = timeResult.innerHTML
                        }
                        
                        let sizeRule = InfoRuleOption.size
                        for sizeResult in parse(string:mainContent, rule: sizeRule) ?? [] {
                            info.size = sizeResult.innerHTML
                        }
                        
                        let formatRule = InfoRuleOption.format
                        for formatResult in parse(string:mainContent, rule: formatRule) ?? [] {
                            info.format = formatResult.innerHTML
                        }
                        
                        let passwodRule = InfoRuleOption.password
                        for passwodResult in parse(string:mainContent, rule: passwodRule) ?? [] {
                            info.passwod = passwodResult.innerHTML
                        }
                        items.append(info)
                        self.delegate?.bot(self, didLoardContent: info, atIndexPath: index)
                    }
                    self.runTasks.append(linkURL)
                    semx.signal()
                }
                task.resume()
                semx.wait()
            }))
        }
        
        contentGroup.notify(queue: contentQueue, execute: {
            sem.signal()
        })
        
        sem.wait()
        print("items : \(items.count), spend time: \(Date().timeIntervalSince(startTime))")
    }
    
    private func fetchGroup(start: UInt, offset: UInt) {
        let maker : (FetchURL) -> String = { (s) -> String in
            "http://\(s.site)/forum-\(s.board.rawValue)-\(s.page).html"
        }
        let topQueue = DispatchQueue(label: "com.ascp.top")
        let group = DispatchGroup()
        
        for i in start...(start + offset) {
            let fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: Int(i), maker: maker)
            let request = browserRequest(url: fetchURL.url)
            
            topQueue.async(group: group, execute: DispatchWorkItem(block: {
                let topSem = DispatchSemaphore(value: 0)
                
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, err) in
                    guard let result = data, let html = String(data: result, encoding: .utf8) else {
                        if let e = err {
                            print(e)
                        }
                        self.badTasks.append(fetchURL)
                        topSem.signal()
                        return
                    }
                    
                    if let _ = html.range(of: "<html>\r\n<head>\r\n<META NAME=\"robots\" CONTENT=\"noindex,nofollow\">") {
                        print("---------- robot detected! ----------")
                        self.badTasks.append(fetchURL)
                        topSem.signal()
                        return
                    }
                    
                    let rule = PageRuleOption.link
//                    let rulex = PageRuleOption.content
                    self.runTasks.append(fetchURL)
                    
                    print("---------- 开始解析 \(i) 页面 ----------")
                    
                    if let pages = parse(string:html, rule: rule) {
                        let contentQueue = DispatchQueue(label: "com.ascp.content")
                        let contentGroup = DispatchGroup()

                        print("+++ 解析到 \(pages.count) 个内容链接")

                        for (offset, page) in pages.enumerated() {
                            let title = page.innerHTML
                            guard let href = page.attributes["href"] else {
                                continue
                            }
                            self.count += 1
                            contentQueue.async(group: contentGroup, execute: DispatchWorkItem(block: {
                                self.fetchMainContent(title: title, link: href, page: fetchURL.page, index: offset)
                            }))
                        }

                        contentGroup.notify(queue: contentQueue, execute: {
                            topSem.signal()
                        })
                    }
                })
                
                task.resume()
                
                topSem.wait()
            }))
        }
        
        group.notify(queue: topQueue) {
            self.delegate?.bot(self, didFinishedContents: self.contentDatas, failedLink: self.badTasks)
        }
    }
    
    private func fetchMainContent(title: String, link: String, page: Int, index: Int) {
        let linkMaker : (FetchURL) -> String = { (s) -> String in
            "http://\(s.site)/\(link)"
        }
        let linkURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: page, maker: linkMaker)
        let request = browserRequest(url: linkURL.url)
        let sem = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
            guard let result = data, let html = String(data: result, encoding: .utf8) else {
                if let e = err {
                    print(e)
                }
                self.badTasks.append(linkURL)
                return
            }
            
            if let _ = html.range(of: "<html>\r\n<head>\r\n<META NAME=\"robots\" CONTENT=\"noindex,nofollow\">") {
                print("---------- robot detected! ----------")
                self.badTasks.append(linkURL)
                return
            }
            
            let rule = InfoRuleOption.main
            print("++++ \(page)页\(index)项 parser: \(link)")
            if let mainContent = parse(string:html, rule: rule)?.first?.innerHTML {
                var info = ContentInfo()
                info.title =  title
                
                let dowloadLinkRule = InfoRuleOption.downloadLink
                for linkResult in parse(string:mainContent, rule: dowloadLinkRule) ?? [] {
                    info.downloafLink.append(linkResult.innerHTML)
                }
                
                let imageLinkRule = InfoRuleOption.imageLink
                for imageResult in parse(string:mainContent, rule: imageLinkRule) ?? [] {
                    for attribute in imageLinkRule.attrubutes {
                        if let item = imageResult.attributes[attribute.key] {
                            info.imageLink.append(item)
                            break
                        }
                    }
                }
                
                let mskRule = InfoRuleOption.msk
                for mskResult in parse(string:mainContent, rule: mskRule) ?? [] {
                    info.msk = mskResult.innerHTML
                }
                
                let timeRule = InfoRuleOption.time
                for timeResult in parse(string:mainContent, rule: timeRule) ?? [] {
                    info.time = timeResult.innerHTML
                }
                
                let sizeRule = InfoRuleOption.size
                for sizeResult in parse(string:mainContent, rule: sizeRule) ?? [] {
                    info.size = sizeResult.innerHTML
                }
                
                let formatRule = InfoRuleOption.format
                for formatResult in parse(string:mainContent, rule: formatRule) ?? [] {
                    info.format = formatResult.innerHTML
                }
                
                let passwodRule = InfoRuleOption.password
                for passwodResult in parse(string:mainContent, rule: passwodRule) ?? [] {
                    info.passwod = passwodResult.innerHTML
                }
                
                info.page = linkURL.url.absoluteString
                
                self.contentDatas.append(info)
                self.delegate?.bot(self, didLoardContent: info, atIndexPath: self.contentDatas.count)
            }
            self.runTasks.append(linkURL)
            sem.signal()
        }
        task.resume()
        
        sem.wait()
    }
}

protocol FetchBotDelegate {
    func bot(_ bot: FetchBot, didLoardContent content: ContentInfo, atIndexPath index: Int)
    func bot(didStartBot bot: FetchBot)
    func bot(_ bot: FetchBot, didFinishedContents contents: [ContentInfo], failedLink : [FetchURL])
}


/// 模仿浏览器URL请求
///
/// - Parameter url: URL对象
/// - Returns: URLRequest请求对象
func browserRequest(url : URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("zh-CN,zh;q=0.8,en;q=0.6", forHTTPHeaderField: "Accept-Language")
    request.addValue("Refer", forHTTPHeaderField: "http://xbluntan.net")
    request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
    request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
    return request
}

