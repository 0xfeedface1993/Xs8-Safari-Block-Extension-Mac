//
//  AutoFechTests.swift
//  AutoFechTests
//
//  Created by virus1993 on 2017/9/23.
//  Copyright © 2017年 ascp. All rights reserved.
//

import XCTest
@testable import AutoFech

class AutoFechTests: XCTestCase {
    var bot : FetchBot!
    private lazy var htmlString : String = {
        let url = Bundle.main.url(forResource: "test", withExtension: "html")!
        do {
            let content = try String(contentsOf: url)
            return content
        } catch {
            print("read html file error: \(error)")
            return ""
        }
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        bot = FetchBot()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //        testPageParser()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    /// 测试网盘页面链接抓取
    func testPageParser() {
        let link = ParserAttrubuteRule(key: "href")
        let rule = ParserTagRule(tag: "a", attrubutes: [link], inTagRegexString: " href=\"\\w+(\\-[\\d]+)+.\\w+\" \\w+=\"\\w+\\(\\w+\\)\" class=\"s xst\"", hasSuffix: true)
        let results = parse(string:htmlString, rule: rule)
        assert(results != nil && results?.count ?? 0 > 0)
    }
    
}
