//
//  FetchBot.swift
//  AutoFech
//
//  Created by virus1994 on 2017/9/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

// struct
struct ContentInfo {
    var title : String
    var msk : String
    var time : String
    var size : String
    var format : String
    var passwod : String
    var downloafLink : [String]
    var imageLink : [String]
    init() {
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

struct InfoRuleOption {
    static let msk = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【是否有码】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    static let time = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片时间】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：])+")
    static let size = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片大小】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    static let format = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【影片格式】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    static let password = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "(【解壓密碼】)|(【解压密码】){1}[：:]{0,1}", hasSuffix: false, innerRegex: "([^<：:])+")
    static let downloadLink = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+\" \\w+=\"\\w+\"", hasSuffix: false, innerRegex: "\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+")
    static let imageLink = ParserTagRule(tag: "img", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "file"), ParserAttrubuteRule(key: "href")], inTagRegexString: " \\w+=\"\\w+\" \\w+=\"\\w+\\(\\w+, \\w+\\.\\w+, \\d+, \\d+, \\d+\\)\" \\w+=\"zoom\" \\w+=\"\\w+://[\\w\\.]+[/\\w\\-\\.]+\" \\w+=\"\\w+\\(\\w+\\)\" \\w+=\"\\d+\" \\w+=\"\\d+\" \\w+=\"\\w?\" /", hasSuffix: false, innerRegex: nil)
    static let main = ParserTagRule(tag: "td", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"t_f\" \\w+=\"postmessage_\\d+\"", hasSuffix: true, innerRegex: nil)
}

struct PageRuleOption {
    static let link = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "href")], inTagRegexString: " href=\"\\w+(\\-[\\d]+)+.\\w+\" \\w+=\"\\w+\\(\\w+\\)\" class=\"s xst\"", hasSuffix: true, innerRegex: nil)
}


/// 自动抓取机器人
class FetchBot {
    var contentDatas = [ContentInfo]()
    var runTasks = [FetchURL]() {
        didSet {
            if runTasks.count + badTasks.count == self.count {
                print("success \(runTasks.count), faild \(badTasks.count), count \(self.count), spend time: \(Date().timeIntervalSince(startTime!)) s")
//                print(contentDatas)
//                for item in contentDatas {
//                    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
//                    print(item)
//                }
            }
        }
    }
    var badTasks = [FetchURL]() {
        didSet {
            if runTasks.count + badTasks.count == self.count {
                print("success \(runTasks.count), faild \(badTasks.count), count \(self.count), spend time: \(Date().timeIntervalSince(startTime!)) s")
//                print(contentDatas)
//                for item in contentDatas {
//                    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
//                    print(item)
//                }
            }
        }
    }
    var startPage: UInt = 1
    var pageOffset: UInt = 0
    var count : Int = 0
    var startTime : Date?
    
    init(start: UInt = 1, offset: UInt = 0) {
        self.startPage = start
        self.pageOffset = offset
    }
    
    func start() {
        startTime = Date()
        fetchNetDiskPageLinkAndTitle(start: startPage, offset: pageOffset)
    }
    
    private func fetchNetDiskPageLinkAndTitle(start: UInt, offset: UInt) {
        var pages = [FetchURL]()
        let maker : (FetchURL) -> String = { (s) -> String in
            "http://\(s.site)/forum-\(s.board.rawValue)-\(s.page).html"
        }
        
        for i in start...(start + offset) {
            let fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: Int(i), maker: maker)
            pages.append(fetchURL)
        }
        
        pages.forEach { (fetchURL) in
            var request = URLRequest(url: fetchURL.url)
            request.httpMethod = "GET"
            request.addValue("zh-CN,zh;q=0.8,en;q=0.6", forHTTPHeaderField: "Accept-Language")
            request.addValue("Refer", forHTTPHeaderField: "http://xbluntan.net")
            request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
            request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
            request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, err) in
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
                
                let rule = PageRuleOption.link
                if let pages = parse(string:html, rule: rule) {
                    for page in pages {
                        let title = page.innerHTML
                        guard let href = page.attributes["href"] else {
                            continue
                        }
                        self.count += 1
                        self.fetchMainContent(title: title, link: href, page: fetchURL.page)
//                        print("find link: \(href)")
                    }
                }
                //self.runTasks.remove(at: self.runTasks.index(of: task))
                self.runTasks.append(fetchURL)
            }
            task.resume()
        }
    }
    
    private func fetchMainContent(title: String, link: String, page: Int) {
        let linkMaker : (FetchURL) -> String = { (s) -> String in
            "http://\(s.site)/\(link)"
        }
        let linkURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: page, maker: linkMaker)
        var request = URLRequest(url: linkURL.url)
        request.httpMethod = "GET"
        request.addValue("zh-CN,zh;q=0.8,en;q=0.6", forHTTPHeaderField: "Accept-Language")
        request.addValue("Refer", forHTTPHeaderField: "http://xbluntan.net")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
        
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
                
                self.contentDatas.append(info)
            }
            self.runTasks.append(linkURL)
        }
        task.resume()
//        runTasks.append(task)
    }
}
