//
//  FetchBot.swift
//  S8Blocker
//
//  Created by virus1993 on 2018/1/15.
//  Copyright © 2018年 ascp. All rights reserved.
//

import Foundation
import Gzip

typealias ParserMaker = (String) -> ContentInfo
typealias AsyncFinish = () -> Void

enum Host: String {
    case dytt = "www.ygdy8.net"
    case sex8 = "mote8didi.info"
}


/// 演员导演信息
struct Creator {
    var name : String
    var english : String
}

/// 列表页面链接信息
struct FetchURL : Equatable {
    var site : String
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
struct ContentInfo : Equatable {
    var title : String
    var page : String
    var msk : String
    var time : String
    var size : String
    var format : String
    var passwod : String
    var titleMD5 : String {
        return title.md5()
    }
    var downloafLink : [String]
    var imageLink : [String]
    
    //    ◎译　　名　电锯惊魂8：竖锯/电锯惊魂8/夺魂锯：游戏重启(台)/恐惧斗室之狂魔再现(港)/电锯惊魂：遗产
    var translateName : String
    //    ◎片　　名　Jigsaw
    var movieRawName : String
    //    ◎年　　代　2017
    var releaseYear : String
    //    ◎产　　地　美国
    var produceLocation : String
    //    ◎类　　别　悬疑/惊悚/恐怖
    var styles : [String]
    //    ◎语　　言　英语
    var languages : [String]
    //    ◎字　　幕　中英双字幕
    var subtitle : String
    //    ◎上映日期　2017-10-27(美国)
    var showTimeInfo : String
    var fileFormart : String
    //    ◎文件格式　HD-RMVB
    var videoSize : String
    //    ◎视频尺寸　1280 x 720
    var movieTime : String
    //    ◎片　　长　91分钟
    var directes : [Creator]
    //    ◎导　　演　迈克尔·斯派瑞 Michael Spierig / 彼得·斯派瑞 Peter Spierig
    var actors : [Creator]
    //    ◎主　　演　马特·帕斯摩尔 Matt Passmore
    var _note : String
    var note : String {
        set {
            _note = newValue.replacingOccurrences(of: "</p>", with: "").replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "<br /><br />", with: "\n").replacingOccurrences(of: "<br />", with: "\n").replacingOccurrences(of: "<br", with: "") //.removingHTMLEntities
        }
        get {
            return _note
        }
    }
    
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
        
        translateName = ""
        movieRawName = ""
        releaseYear = ""
        produceLocation = ""
        styles = [String]()
        languages = [String]()
        subtitle = ""
        showTimeInfo = ""
        fileFormart = ""
        videoSize = ""
        movieTime = ""
        directes = [Creator]()
        actors = [Creator]()
        _note = ""
    }
    
    static func ==(lhs: ContentInfo, rhs: ContentInfo) -> Bool {
        return lhs.title == rhs.title && lhs.page == rhs.page
    }
    
    func contain(keyword: String) -> Bool {
        return title.contains(keyword) ||
            translateName.contains(keyword) ||
            movieRawName.contains(keyword) ||
            actors.filter({ $0.name.contains(keyword) || $0.english.contains(keyword) }).count > 0 ||
            directes.filter({ $0.name.contains(keyword) || $0.english.contains(keyword) }).count > 0
    }
}

struct Site {
    var host : Host
    var parentUrl : URL
    var categrory : ListCategrory?
    var listRule : ParserTagRule
    var contentRule : ParserTagRule
    var listEncode : String.Encoding
    var contentEncode : String.Encoding
    
    init(parentUrl: URL,
         listRule: ParserTagRule,
         contentRule: ParserTagRule,
         listEncode: String.Encoding,
         contentEncode: String.Encoding,
         hostName: Host) {
        self.host = hostName
        self.listRule = listRule
        self.contentRule = contentRule
        self.listEncode = listEncode
        self.contentEncode = contentEncode
        self.parentUrl = parentUrl
    }
    
    func page(bySuffix suffix: Int) -> URL {
        switch self.host {
        case .dytt:
            return parentUrl.appendingPathComponent("list_23_\(suffix).html")
        case .sex8:
            return parentUrl.appendingPathComponent("forum-\(categrory?.site ?? "103")-\(suffix).html")
        }
    }
    
    static let dytt = Site(parentUrl: URL(string: "http://www.ygdy8.net/html/gndy/dyzz")!,
                           listRule: PageRuleOption.mLink,
                           contentRule: PageRuleOption.mContent,
                           listEncode: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.HZ_GB_2312.rawValue))),
                           contentEncode: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))),
                           hostName: .dytt)
    
    static let netdisk = Site(parentUrl: URL(string: "https://mote8didi.info")!,
                              listRule: PageRuleOption.link,
                              contentRule: PageRuleOption.content,
                              listEncode: .utf8,
                              contentEncode: .utf8,
                              hostName: .sex8)
    
    var parserMaker: ParserMaker? {
        get {
            switch self.host {
            case .dytt:
                return { mainContent in
                    var info = ContentInfo()
                    
                    let titlesRule = InfoRuleOption.mainTitle
                    for result in parse(string:mainContent, rule: titlesRule) ?? [] {
                        info.title = result.innerHTML
                        print("**** title: \(result.innerHTML)")
                    }
                    
                    let actorsRule = InfoRuleOption.mainActor
                    for result in parse(string:mainContent, rule: actorsRule) ?? [] {
                        for resultx in parse(string:result.innerHTML, rule: InfoRuleOption.singleActor) ?? [] {
                            info.actors.append(Creator(name: resultx.innerHTML, english: ""))
                            print("*********** actor link: \(resultx.innerHTML)")
                        }
                    }
                    
                    let directorsRule = InfoRuleOption.mainDirector
                    for result in parse(string:mainContent, rule: directorsRule) ?? [] {
                        for resultx in parse(string:result.innerHTML, rule: InfoRuleOption.singleDirector) ?? [] {
                            info.directes.append(Creator(name: resultx.innerHTML, english: ""))
                            print("*********** director link: \(resultx.innerHTML)")
                        }
                    }
                    
                    let translateNameRule = InfoRuleOption.translateName
                    for result in parse(string:mainContent, rule: translateNameRule) ?? [] {
                        info.translateName = result.innerHTML
                        print("***** translateName: \(result.innerHTML)")
                    }
                    
                    let movieRawNameRule = InfoRuleOption.movieRawName
                    for result in parse(string:mainContent, rule: movieRawNameRule) ?? [] {
                        info.movieRawName = result.innerHTML
                        print("***** movieRawName: \(result.innerHTML)")
                    }
                    
                    let releaseYearRule = InfoRuleOption.releaseYear
                    for result in parse(string:mainContent, rule: releaseYearRule) ?? [] {
                        info.releaseYear = result.innerHTML
                        print("***** releaseYear: \(result.innerHTML)")
                    }
                    
                    let produceLocationRule = InfoRuleOption.produceLocation
                    for result in parse(string:mainContent, rule: produceLocationRule) ?? [] {
                        info.produceLocation = result.innerHTML
                        print("***** produceLocation: \(result.innerHTML)")
                    }
                    
                    let subtitleRule = InfoRuleOption.subtitle
                    for result in parse(string:mainContent, rule: subtitleRule) ?? [] {
                        info.subtitle = result.innerHTML
                        print("***** subtitle: \(result.innerHTML)")
                    }
                    
                    let showTimeInfoRule = InfoRuleOption.showTimeInfo
                    for result in parse(string:mainContent, rule: showTimeInfoRule) ?? [] {
                        info.showTimeInfo = result.innerHTML
                        print("***** showTimeInfo: \(result.innerHTML)")
                    }
                    
                    let fileFormartRule = InfoRuleOption.fileFormart
                    for result in parse(string:mainContent, rule: fileFormartRule) ?? [] {
                        info.fileFormart = result.innerHTML
                        print("***** fileFormart: \(result.innerHTML)")
                    }
                    
                    let movieTimeRule = InfoRuleOption.movieTime
                    for result in parse(string:mainContent, rule: movieTimeRule) ?? [] {
                        info.movieTime = result.innerHTML
                        print("***** movieTime: \(result.innerHTML)")
                    }
                    
                    let noteRule = InfoRuleOption.note
                    for result in parse(string:mainContent, rule: noteRule) ?? [] {
                        info.note = result.innerHTML
                        print("***** note: \(result.innerHTML)")
                    }
                    
                    let imageRule = InfoRuleOption.mainMovieImage
                    for result in parse(string:mainContent, rule: imageRule) ?? [] {
                        if let src = result.attributes["src"] {
                            info.imageLink.append(src)
                            print("*********** image: \(src)")
                        }
                    }
                    
                    let dowloadLinkRule = InfoRuleOption.movieDowloadLink
                    for linkResult in parse(string:mainContent, rule: dowloadLinkRule) ?? [] {
                        info.downloafLink.append(linkResult.innerHTML)
                        print("*********** download link: \(linkResult.innerHTML)")
                    }
                    
                    return info
                }
            case .sex8:
                return { mainContent in
                    var info = ContentInfo()
                    
                    for result in parse(string:mainContent, rule: InfoRuleOption.netdiskTitle) ?? [] {
                        info.title = result.innerHTML
                        print("*********** title: \(result.innerHTML)")
                    }
                    
                    for rule in [InfoRuleOption.downloadLink, InfoRuleOption.downloadLinkLi, InfoRuleOption.v4DownloadLink] {
                        for linkResult in parse(string:mainContent, rule: rule) ?? [] {
                            if InfoRuleOption.v4DownloadLink.regex == rule.regex {
                                info.downloafLink.append(linkResult.innerHTML.replacingOccurrences(of: "\"", with: ""))
                            }   else    {
                                info.downloafLink.append(linkResult.innerHTML)
                            }
                            
                            print("*********** download link: \(linkResult.innerHTML)")
                        }
                    }
                    
                    let imageLinkRule = InfoRuleOption.imageLink
                    for imageResult in parse(string:mainContent, rule: imageLinkRule) ?? [] {
                        for attribute in imageLinkRule.attrubutes {
                            if let item = imageResult.attributes[attribute.key] {
                                info.imageLink.append(item)
                                print("*********** image: \(item)")
                                break
                            }
                        }
                    }
                    
                    let mskRule = InfoRuleOption.msk
                    if let last = parse(string:mainContent, rule: mskRule)?.last {
                        info.msk = last.innerHTML
                        print("*********** msk: \(info.msk)")
                    }
                    
                    let timeRule = InfoRuleOption.time
                    if let last = parse(string:mainContent, rule: timeRule)?.last {
                        info.time = last.innerHTML
                        print("*********** time: \(info.time)")
                    }
                    
                    let sizeRule = InfoRuleOption.size
                    if let last = parse(string:mainContent, rule: sizeRule)?.last {
                        info.size = last.innerHTML
                        print("*********** size: \(info.size)")
                    }
                    
                    
                    let formatRule = InfoRuleOption.format
                    if let last = parse(string:mainContent, rule: formatRule)?.last {
                        info.format = last.innerHTML
                        print("*********** format: \(info.format)")
                    }
                    
                    let passwodRule = InfoRuleOption.password
                    if let last = parse(string:mainContent, rule: passwodRule)?.last {
                        info.passwod = last.innerHTML
                        print("*********** passwod: \(info.passwod)")
                    }
                    
                    return info
                }
            }
        }
    }
}

/// 内容信息正则规则选项
struct InfoRuleOption {
    static let netdiskTitle = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "<span id=\"thread_subject\">", hasSuffix: nil, innerRegex: "[^<]*")
    /// 是否有码
    static let msk = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "((【是否有码】)|(【有碼無碼】)|(【影片说明】)|(【影片說明】)|(【是否有碼】)){1}[：:]{0,1}((&nbsp;)|(\\s))*", hasSuffix: nil, innerRegex: "([^<：:(&nbsp;)])+")
    /// 影片时间
    static let time = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "((【影片时间】)|(【影片時間】)|(【视频时间】)){1}[：:]{0,1}((&nbsp;)|(\\s))*", hasSuffix: nil, innerRegex: "([^<(&nbsp;)])+")
    /// 影片大小
    static let size = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "((【影片大小】)|(【视频大小】)){1}[：:]{0,1}((&nbsp;)|(\\s))*", hasSuffix: nil, innerRegex: "([^<：:(&nbsp;)])+")
    /// 影片格式
    static let format = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "((【影片格式】)|(【视频格式】)){1}[：:]{0,1}", hasSuffix: nil, innerRegex: "([^<：:])+")
    /// 解压密码
    static let password = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "((【解壓密碼】)|(【解压密码】)|(解壓密碼)|(解压密码)){1}[：:]{0,1}((&nbsp;)|(\\s))*", hasSuffix: nil, innerRegex: "([^<：:])+")
    /// 下载链接
    /// 下载地址[\\s\\S]+<a( \\w+=\"[^\"]+\")+>[^<]+</a>
    static let downloadLink = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+\" \\w+=\"\\w+\"", hasSuffix: nil, innerRegex: "\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+")
    /// 下载地址2
    static let downloadLinkLi = ParserTagRule(tag: "li", isTagPaser: true, attrubutes: [], inTagRegexString: "", hasSuffix: nil, innerRegex: "\\w+:\\/\\/[\\w+\\.]+[\\/\\-\\w\\.]+")
    /// 下载地址3
    static let v4DownloadLink = ParserTagRule(tag: "a", isTagPaser: false, attrubutes: [], inTagRegexString: "((下载链接)|(下載鏈接)|(下载地址)|(下載地址))[^\"]+", hasSuffix: nil, innerRegex: "\"[^\"]+\"")
    /// 图片链接
    static let imageLink = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [ParserAttrubuteRule(key: "file"), ParserAttrubuteRule(key: "href"), ParserAttrubuteRule(key: "src")], inTagRegexString: "<img([^>]+class=\"zoom\"[^>]+)|(((\\ssrc=\"\\w+:[^\"]+\")|(\\salt=\"\\w+\\.\\w+\")|(\\stitle=\"\\w+\\.\\w+\")){3})", hasSuffix: nil, innerRegex: nil)
    /// 主内容标签
    static let main = ParserTagRule(tag: "td", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"t_f\" \\w+=\"postmessage_\\d+\"", hasSuffix: nil, innerRegex: nil)
    
    /// ---- 电影天堂 ---
    /// 主演列表
    static let mainActor = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎主[\\s]+演", hasSuffix: "◎", innerRegex: "[^◎]+")
    /// 主演名称
    static let singleActor = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "\\s*", hasSuffix: "<", innerRegex: "[^>]+")
    
    /// 导演列表
    static let mainDirector = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎导[\\s]+演", hasSuffix: "◎", innerRegex: "[^◎]+")
    /// 导演名称
    static let singleDirector = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "\\s*", hasSuffix: "[<|\\/]+", innerRegex: "[^\\/]+")
    
    /// 类别列表
    static let mainStyle = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎类[\\s]+别", hasSuffix: "◎", innerRegex: "[^◎]+")
    /// 类别名称
    static let singleStyle = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "[\\s\\/]*", hasSuffix: nil, innerRegex: "[^\\/]+")
    
    /// 语言列表
    static let mainLanguage = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎语[\\s]+言", hasSuffix: "◎", innerRegex: "[^◎]+")
    /// 语言名称
    static let singleLanguage = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "[\\s\\/]*", hasSuffix: nil, innerRegex: "[^\\/]+")
    
    static let translateName = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎译[\\s]+名[\\s]+", hasSuffix: "<", innerRegex: "[^◎<]+")
    static let movieRawName = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎片[\\s]+名[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let releaseYear = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎年[\\s]+代[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let produceLocation = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎产[\\s]+地[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let subtitle = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎字[\\s]+幕[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let showTimeInfo = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎上映日期[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let fileFormart = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎文件格式[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let videoSize = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎视频尺寸[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    static let movieTime = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎片[\\s]+长[\\s]+", hasSuffix: "<", innerRegex: "[^<]+")
    
    //    static let note = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎简[\\s]+介\\s+[<br \\/>]+", hasSuffix: "<img ", innerRegex: "[\\s\\S]+")◎简\s+介[^◎]+(◎|(<img))
    static let note = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "◎简\\s+介\\s*[(<br />)|(</{0,1}p>)]+", hasSuffix: "(◎|(<img)|(<p><strong>))", innerRegex: "[^◎]+")
    /// 标题列表
    static let mainTitle = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "<div \\w+=\"\\w+\"><h1><font \\w+=#\\w+>", hasSuffix: "</font></h1></div>", innerRegex: "[\\s\\S]*")
    /// 标题名称
    static let singleTitle = ParserTagRule(tag: "font", isTagPaser: true, attrubutes: [], inTagRegexString: " \\w+=\"#\\w+\"", hasSuffix: nil, innerRegex: "[^<]+")
    
    /// 图片列表
    static let mainMovieImage = ParserTagRule(tag: "img", isTagPaser: false, attrubutes: [ParserAttrubuteRule(key: "src")], inTagRegexString: "<img[^>]+\\w+=\"\\w+:[^>]+", hasSuffix: ">", innerRegex: "[^>]+")
    
    /// 下载地址
    static let movieDowloadLink = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "thunderrestitle"), ParserAttrubuteRule(key: "src"), ParserAttrubuteRule(key: "aexuztdb"), ParserAttrubuteRule(key: "href")], inTagRegexString: " \\w+=\"\\w+:\\/\\/\\w+:\\w+@\\w+.\\w+.\\w+:\\w+\\/[^\"]+\"", hasSuffix: nil, innerRegex: "\\w+:\\/\\/\\w+:\\w+@\\w+.\\w+.\\w+:\\w+\\/[^<]+")
}

/// 列表页面正则规则选项
struct PageRuleOption {
    /// 内容页面链接
    static let link = ParserTagRule(tag: "a", isTagPaser: false, attrubutes: [ParserAttrubuteRule(key: "href")], inTagRegexString: "<a \\w+=\"[^\"]+\" \\w+=\"\\w+\\(\\w+\\)\" \\w+=\"s xst\">", hasSuffix: "</a>", innerRegex: "[^<]+")
    static let content = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "<tbody id=\"separatorline\">", hasSuffix: "下一页", innerRegex: "[\\s\\S]*")
    
    /// ---- 电影天堂 ---
    static let mLink = ParserTagRule(tag: "a", isTagPaser: true, attrubutes: [ParserAttrubuteRule(key: "href")], inTagRegexString: " href=\"[\\/\\w]+\\.\\w+\" class=\"ulink\"", hasSuffix: nil, innerRegex: nil)
    static let mContent = ParserTagRule(tag: "", isTagPaser: false, attrubutes: [], inTagRegexString: "<div class=\"co_area2\">", hasSuffix: nil, innerRegex: "[\\s\\S]*")
}

/// 自动抓取机器人
class FetchBot {
    private lazy var session : URLSession = {
        let config = URLSessionConfiguration.default
        let queue = OperationQueue.current
        let downloadSession = URLSession(configuration: config, delegate: nil, delegateQueue: queue)
        return downloadSession
    }()
    
    private static let _bot = FetchBot()
    static var shareBot : FetchBot {
        get {
            return _bot
        }
    }
    
    var delegate : FetchBotDelegate?
    var contentDatas = [ContentInfo]()
    var runTasks = [FetchURL]()
    var badTasks = [FetchURL]()
    var startPage: UInt = 1
    var pageOffset: UInt = 0
    var count : Int = 0
    var startTime : Date?
    
    var sem : DispatchSemaphore?
    private var isRunning = false
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - start: 开始页面，大于1
    ///   - offset: 结束页面 = start + offset
    init(start: UInt = 1, offset: UInt = 0) {
        self.startPage = start > 0 ? start:1
        self.pageOffset = offset
    }
    
    func start(withSite site: Site) {
        startTime = Date()
        runTasks.removeAll()
        badTasks.removeAll()
        count = 0
        contentDatas.removeAll()
        DispatchQueue.main.async {
            self.delegate?.bot(didStartBot: self)
        }
        fetchGroup(start: startPage, offset: pageOffset, site: site)
    }
    
    func stop(compliention: AsyncFinish) {
        if isRunning {
            sem = DispatchSemaphore(value: 0)
            sem?.wait()
            compliention()
            sem = nil
        }   else {
            compliention()
        }
    }
    
    private func fetchGroup(start: UInt, offset: UInt, site : Site) {
        isRunning = true
        
        let maker : (FetchURL) -> String = { (s) -> String in
            site.page(bySuffix: s.page).absoluteString
        }
        
        struct PageItem {
            var request : URLRequest
            var url : FetchURL
            var links : [ParserResult]
        }
        
        struct LinkItem {
            var link : String
            var title : String
        }
        
        let startIndex = Int(start)
        let radio = 5
        let splitGroupCount = Int(offset) / radio + 1
        
        var pages = [PageItem]()
        for x in 0..<splitGroupCount {
            if let _ = self.sem {
                print("************ Recive Stop Signal ************")
                break
            }
            let listGroup = DispatchGroup()
            for y in 0..<radio {
                if let _ = self.sem {
                    print("************ Recive Stop Signal ************")
                    break
                }
                let index = x * radio + y + startIndex
                if index >= Int(offset) + startIndex {
                    break
                }
                let fetchURL = FetchURL(site: site.host.rawValue, page: Int(index), maker: maker)
                let request = browserRequest(url: fetchURL.url, refer: site.host.rawValue)
                listGroup.enter()
                print(">>> enter \(index)")
                let task = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, err) in
                    defer {
                        listGroup.leave()
                    }
                    
                    if let _ = self.sem {
                        print("************ Recive Stop Signal ************")
                        return
                    }
                    
                    guard let html = data?.asiicCombineUTF8StringDecode() else {
                        if let e = err {
                            print(e)
                        }
                        print("---------- bad decoder, \(response?.description ?? "") ----------")
                        self.badTasks.append(fetchURL)
                        return
                    }
                    
                    if let _ = html.range(of: "<html>\r\n<head>\r\n<META NAME=\"robots\" CONTENT=\"noindex,nofollow\">") {
                        print("---------- robot detected! ----------")
                        self.badTasks.append(fetchURL)
                        return
                    }
                    
                    let rule = site.listRule
                    self.runTasks.append(fetchURL)
                    
                    print("---------- 开始解析 \(index) 页面 ----------")
                    
                    guard let links = parse(string:html, rule: rule) else {
                        return
                    }
                    
                    print("++++++ 解析到 \(links.count) 个内容链接")
                    
                    pages.append(PageItem(request: request, url: fetchURL, links: links))
                })
                task.resume()
            }
            listGroup.wait()
        }
        
        for page in pages {
            if let _ = self.sem {
                print("************ Recive Stop Signal ************")
                break
            }
            let pageSplitCount = page.links.count / radio + 1
            for x in 0..<pageSplitCount {
                if let _ = self.sem {
                    print("************ Recive Stop Signal ************")
                    break
                }
                var centenGroup = DispatchGroup()
                for y in 0..<radio {
                    if let _ = self.sem {
                        print("************ Recive Stop Signal ************")
                        break
                    }
                    let index = x * radio + y
                    if index >= Int(page.links.count) {
                        break
                    }
                    guard let href = page.links[index].attributes["href"] else {
                        continue
                    }
                    
                    self.count += 1
                    let linkMaker : (FetchURL) -> String = { (s) -> String in
                        URL(string: "https://\(s.site)")!.appendingPathComponent(href).absoluteString
                    }
                    let linkURL = FetchURL(site: site.host.rawValue, page: page.url.page, maker: linkMaker)
                    let request = browserRequest(url: linkURL.url, refer: site.host.rawValue)
                    
                    centenGroup.enter()
                    print("<<< enter \(index)")
                    let subTask = session.dataTask(with: request) { [unowned self] (data, response, err) in
                        defer {
                            centenGroup.leave()
                        }
                        
                        if let _ = self.sem {
                            print("************ Recive Stop Signal ************")
                            return
                        }
                        
                        
                        guard let html = data?.asiicCombineUTF8StringDecode() else {
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
                        
                        print("++++ \(page.url.page)页\(index)项 parser: \(href)")
                        if let xinfo = site.parserMaker?(html), !xinfo.title.isEmpty {
                            var info = xinfo
                            info.page = linkURL.url.absoluteString
                            self.contentDatas.append(info)
                            self.delegate?.bot(self, didLoardContent: info, atIndexPath: self.contentDatas.count)
                        }
                        self.runTasks.append(linkURL)
                    }
                    subTask.resume()
                }
                centenGroup.wait()
            }
        }
        
        self.delegate?.bot(self, didFinishedContents: self.contentDatas, failedLink: self.badTasks)
        
        isRunning = false
        if let s = sem {
            s.signal()
        }
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
func browserRequest(url : URL, refer: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("zh-CN,zh;q=0.8,en;q=0.6", forHTTPHeaderField: "Accept-Language")
    request.addValue("Refer", forHTTPHeaderField: refer)
    request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
    request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
    request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
    return request
}

extension Data {
    func asiicCombineUTF8StringDecode() -> String {
        var html = ""
        var index = 0
        self.withUnsafeBytes { (pointer) in
            repeat {
                let value = pointer.load(fromByteOffset: index, as: UInt8.self)
                if value < 192 {
                    index += 1
                    html += String(format: "%c", value)
                }   else    {
                    if value >= 252 {
                        let offset = 6
                        html += String.init(bytes: pointer[index..<(index + offset)], encoding: .utf8) ?? ""
                        index += offset
                    }   else if value >= 248 && value < 252 {
                        let offset = 5
                        html += String.init(bytes: pointer[index..<(index + offset)], encoding: .utf8) ?? ""
                        index += offset
                    }   else if value >= 240 && value < 248 {
                        let offset = 4
                        html += String.init(bytes: pointer[index..<(index + offset)], encoding: .utf8) ?? ""
                        index += offset
                    }   else if value >= 224 && value < 240 {
                        let offset = 3
                        html += String.init(bytes: pointer[index..<(index + offset)], encoding: .utf8) ?? ""
                        index += offset
                    }   else if value >= 192 && value < 224 {
                        let offset = 2
                        html += String.init(bytes: pointer[index..<(index + offset)], encoding: .utf8) ?? ""
                        index += offset
                    }   else {
                        index += 1
                    }
                }
            } while (index < self.count)
        }
        return html
    }
}
