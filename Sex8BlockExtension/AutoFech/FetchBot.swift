//
//  FetchBot.swift
//  AutoFech
//
//  Created by virus1994 on 2017/9/25.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation


class FetchBot {
    var list = [ListItem]()
    var fullData = [PageData]()
    var runTasks = [URLSessionDataTask]()
    var fetchURL = FetchURL(site: "xbluntan.net", board: .netDisk, page: 1)
    private lazy var fetchJS : String = {
        let url = Bundle.main.url(forResource: "fetch", withExtension: "js")!
        do {
            let content = try String(contentsOf: url)
            return content
        } catch {
            print("read js file error: \(error)")
            return ""
        }
    }()
    private lazy var htmlString : String = {
        let url = Bundle.main.url(forResource: "test", withExtension: "html")!
        do {
            let content = try String(contentsOf: url)
            return content
//                .filter({ character -> Bool in
//                let badCharacters = ["\n", "\r"]
//                return badCharacters.filter({ $0.characters.first == character }).count == 0
//            })
        } catch {
            print("read html file error: \(error)")
            return ""
        }
    }()
    
    private var fetchRequest : URLRequest {
        var request = URLRequest(url: fetchURL.url)
        request.httpMethod = "GET"
        request.addValue(fetchURL.url.absoluteString, forHTTPHeaderField: "Referer")
        request.addValue("zh-CN,zh;q=0.8,en;q=0.6", forHTTPHeaderField: "Accept-Language")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Mozilla/5.0 (Windows; U; Windows NT 5.2) Gecko/2008070208 Firefox/3.0.1", forHTTPHeaderField: "User-Agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
        return request
    }
    
    func start() {
        let task = URLSession.shared.dataTask(with: fetchRequest) { (data, response, err) in
            guard let result = data else {
                if let e = err {
                    print(e)
                }
                return
            }
            print(String.init(data: result, encoding: .utf8) ?? "oh no")
        }
        task.resume()
        runTasks.append(task)
    }
    
    func readHTMLFile() {
//        print(htmlString)
        do {
            let prefix = "<a href=\"\\w+(\\-[\\d]+)+.\\w+\" \\w+=\"\\w+\\(\\w+\\)\" class=\"s xst\">"
            let suffix = "</a>"
            let regex = try NSRegularExpression(pattern: "\(prefix).*\(suffix)", options: .caseInsensitive)
            let result = regex.matches(in: htmlString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, htmlString.characters.count))
            if result.count > 0 {
                for checkingRes in result {
                    var range = checkingRes.range
                    range.length -= suffix.characters.count
                    let str = (htmlString as NSString).substring(with: range)
                    let titleRegex = try NSRegularExpression(pattern: prefix, options: .caseInsensitive)
                    let titleResult = titleRegex.matches(in: str, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, str.characters.count))
                    if let first = titleResult.first {
                        var subRange = range
                        subRange.location = first.range.length
                        subRange.length = str.count - subRange.location
                        print("Location:\(subRange.location), length:\(subRange.length), str: \((str as NSString).substring(with: subRange))")
                    }
                    
                    let linkRegex = try NSRegularExpression(pattern: "<a href=\"\\w+(\\-[\\d]+)+.\\w+\"", options: .caseInsensitive)
                    if let linkResult = linkRegex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, str.characters.count)) {
                        var subRange = linkResult.range
                        subRange.location += "<a href=\"".characters.count
                        subRange.length -= "<a href=\"\"".characters.count
                        print("link: \((str as NSString).substring(with: subRange))")
                    }
                }
            }else{
                print("未查找到")
            }
        } catch  {
            print(error)
        }
    }
    
    func test() {
        let link = ParserAttrubuteRule(key: "href")
        let rule = ParserTagRule(tag: "a", attrubutes: [link], inTagRegexString: " href=\"\\w+(\\-[\\d]+)+.\\w+\" \\w+=\"\\w+\\(\\w+\\)\" class=\"s xst\"", hasSuffix: true)
        parse(string:htmlString, rule: rule)
    }
    
    struct ParserTagRule {
        var tag : String
        var attrubutes : [ParserAttrubuteRule]
        var inTagRegexString : String
        var hasSuffix : Bool
        var prefix : String {
            return "<\(tag)\(inTagRegexString)>"
        }
        var suffix : String {
            return hasSuffix ? "</\(tag)>":""
        }
        var regex : String {
            return "\(prefix).*\(suffix)"
        }
    }
    
    struct ParserAttrubuteRule {
        var key : String
        var prefix : String {
            return "\(key)=\""
        }
        var suffix : String {
            return "\""
        }
        var regex : String {
            return "\(prefix)[^\"]*\(suffix)"
        }
    }
    
    func parse(string: String, rule: ParserTagRule) {
        do {
            let tagRegex = try NSRegularExpression(pattern: rule.regex, options: .caseInsensitive)
            let result = tagRegex.matches(in: string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, string.characters.count))
            if result.count > 0 {
                for checkingRes in result {
                    var range = checkingRes.range
                    range.length -= rule.suffix.characters.count
                    let str = (htmlString as NSString).substring(with: range)
                    
                    let titleRegex = try NSRegularExpression(pattern: rule.prefix, options: .caseInsensitive)
                    if let first = titleRegex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, str.characters.count)) {
                        var subRange = range
                        subRange.location = first.range.length
                        subRange.length = str.count - subRange.location
                        print("title: \((str as NSString).substring(with: subRange))")
                    }
                    
                    for attr in rule.attrubutes {
                        let attrRegex = try NSRegularExpression(pattern: attr.regex, options: .caseInsensitive)
                        if let attrResult = attrRegex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, str.characters.count)) {
                            var subRange = attrResult.range
                            subRange.location += attr.prefix.characters.count
                            subRange.length -= attr.prefix.characters.count + 1
                            print("Location:\(subRange.location), length:\(subRange.length), str: \((str as NSString).substring(with: subRange))")
                        }
                    }
                }
            }   else    {
                print("未查找到")
            }
        } catch  {
            print(error)
        }
    }
}
