//
//  JsonModal.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/19.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

struct ErrorResponse : Codable {
    var code : String
    var info : String
}

struct LoginResopnse : Codable {
    var id : String
    var name : String
    var info : String
}
