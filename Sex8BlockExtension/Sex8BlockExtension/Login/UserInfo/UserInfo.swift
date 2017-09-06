//
//  UserInfo.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/4.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

struct BaseModal : Codable {
    
}

struct User : Codable {
    var id : String
    var name : String
    var power : String
    var info : String
    var tag : String
//    init(_ data : [String:String]) {
//        id = data["user_id"] ?? ""
//        name = data[""] ?? ""
//        power = data[""] ?? ""
//        info = data[""] ?? ""
//        tag = data[""] ?? ""
//    }
    enum CodingKeys : String, CodingKey {
        case id
        case name
        case power
        case info
        case tag
    }
}
