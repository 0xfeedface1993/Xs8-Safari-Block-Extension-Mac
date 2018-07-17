//
//  CloudFetchBotTests.swift
//  CloudFetchBotTests
//
//  Created by virus1994 on 2018/6/6.
//  Copyright © 2018年 ascp. All rights reserved.
//

import XCTest
@testable import CloudFetchBot

class CloudFetchBotTests: XCTestCase, CloudSaver {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDupliteInfo() {
        let sem = DispatchSemaphore(value: 0)
        check(href: "65db48651532a185352e16b007a1d71c") { (res) in
            XCTAssert(res.count > 0, "******** Found Same record, but failed to check *******")
            sem.signal()
        }
        sem.wait()
    }
    
    func testMD5Caculate() {
        let hash = "123".md5()
        XCTAssert(hash == "202cb962ac59075b964b07152d234b70", "******** Worng MD5 Caculation *******")
    }
    
}
