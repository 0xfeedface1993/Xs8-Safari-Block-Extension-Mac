//
//  JsonModal.swift
//  Sex8BlockExtension
//
//  Created by virus1994 on 2017/9/19.
//  Copyright © 2017年 ascp. All rights reserved.
//

import Foundation

//MARK: - Struct

struct ErrorResponse : Codable {
    var code : String
    var info : String
}

struct LoginResopnse : Codable {
    var id : String
    var name : String
    var info : String
}

struct MovieAddRespnse : Codable {
    var movieID : String
}

struct MovieModal : Codable {
    var title : String
    var page : String
    var pics : [String]
    var msk : String
    var time : String
    var format : String
    var size : String
    var downloads : [String]
}

//MARK: - Enum Type

enum CommandType {
    case page
    case detail
}

struct Command {
    var type : CommandType
    var script : String
    var url : URL
    var completion : ((Any?) -> ())?
}

struct APIResponse<T: Codable>: Codable {
    var code: Int
    var msg: String
    var data: T?
}

struct RegisterDeviceRequest: Codable {
    var userid : String
    var deviceid : String
    let _jsonobjid = "request-device-add"
}

struct DeviceNoticeAllRequest: Codable {
    let _jsonobjid = "request-device-notice-all"
    var title : String
    var content : String
    var image : String
}
