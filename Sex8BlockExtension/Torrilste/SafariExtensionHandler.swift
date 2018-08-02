//
//  SafariExtensionHandler.swift
//  Torrilste
//
//  Created by virus1994 on 2017/6/18.
//  Copyright © 2017年 ascp. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
//        page.getPropertiesWithCompletionHandler { properties in
//            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
//        }
        switch messageName {
        case "CatchDownloadLinks":
            print("\(userInfo ?? [:])")
            saveDownloadLink(data: userInfo!, page: page)
            break
        case "getFullHtml":
            print("\(userInfo ?? [:])")
            if let body = userInfo?["body"] as? String, let title = userInfo?["title"] as? String, let link = userInfo?["link"] as? String {
                let images = userInfo?["images"] as? [String] ?? []
                parser(html: body, title: title, link: link, images:images, page: page)
            }
            break
        default:
            break
        }
    }
    
    func parser(html: String, title: String, link: String, images:[String], page: SFSafariPage) {
        var info = ContentInfo()
        info.title =  title
        
        let mainContent = html
        
        let dowloadLinkRule = InfoRuleOption.downloadLink
        let downloadLinkLiRule = InfoRuleOption.downloadLinkLi
        let linkRules = [dowloadLinkRule, downloadLinkLiRule, InfoRuleOption.v4DownloadLink]
        for rule in linkRules {
            for linkResult in parse(string:mainContent, rule: rule) ?? [] {
                if InfoRuleOption.v4DownloadLink.regex == rule.regex {
                    if let src = linkResult.attributes["href"] ?? linkResult.attributes["src"] {
                        info.downloafLink.append(src)
                    }
                }   else    {
                    info.downloafLink.append(linkResult.innerHTML)
                }
                // print("doenload link: \(linkResult.innerHTML)")
            }
        }
        
        //            info.imageLink = images
        let imageLinkRule = InfoRuleOption.imageLink
        for imageResult in parse(string:mainContent, rule: imageLinkRule) ?? [] {
            for attribute in imageLinkRule.attrubutes {
                if let item = imageResult.attributes[attribute.key] {
                    info.imageLink.append(item)
                    // print("image link: \(item)")
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
        
        info.page = link
        
        DataBase.share.saveFetchBotDownloadLink(data: info, completion: { (state) in
            switch state {
            case .failed:
                page.dispatchMessageToScript(withName: "notOK", userInfo: nil)
                print("保存失败")
                break
            case .success:
                page.dispatchMessageToScript(withName: "saveOK", userInfo: nil)
                print("保存成功")
                break
            }
        })
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
        window.getActiveTab(completionHandler: {
            tab in
            tab?.getActivePage(completionHandler: {
                page in
                page!.dispatchMessageToScript(withName: "getFullHtml", userInfo: ["b":"a"])
                print("post it!")
            })
        })
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    //MARK: - Core Data
    func saveDownloadLink(data: [String : Any], page: SFSafariPage) {
        let item = PageData(data: data)
        DataBase.share.saveDownloadLink(data: item, completion: { (state) in
            switch state {
            case .success:
                page.dispatchMessageToScript(withName: "saveOK", userInfo: nil)
                break
            case .failed:
                page.dispatchMessageToScript(withName: "notOK", userInfo: nil)
                break
            }
        })
    }
}
