//
//  Response.swift
//  MoyaDemo
//
//  Created by Liu Yang on 2018/5/4.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import Foundation

// 分页
struct PageModel {
    
}

class BaseResponse {
    var code: Int {
        guard let temp = json["code"] as? Int else {
            return -1
        }
        return temp
    }
    
    var message: String? {
        guard let temp = json["msg"] as? String else {
            return nil
        }
        return temp
    }
    
    var jsonData: Any? {
        guard let temp = json["data"] else {
            return nil
        }
        return temp
    }
    
    let json: [String : Any]
    
    init?(data: Any) {
        guard let temp = data as? [String : Any] else {
            return nil
        }
        self.json = temp
    }
    
    func json2Data(_ object: Any) -> Data? {
        return try? JSONSerialization.data(withJSONObject: object, options: [])
    }
}

class ListResponse<T>: BaseResponse where T: Codable {
    var dataList: [T]? {
        guard code == 0,
            let jsonData = jsonData as? [String : Any],
            let listData = jsonData["list"],
            let temp = json2Data(listData) else {
                return nil
        }
        return try? JSONDecoder().decode([T].self, from: temp)
    }
    
    var page: PageModel? {
        // PageModel的解析
        return nil
    }
}

class ModelResponse<T>: BaseResponse where T: Codable {
    var data: T? {
        guard code == 0,
            let tempJSONData = jsonData,
            let temp = json2Data(tempJSONData)  else {
                return nil
        }
        return try? JSONDecoder().decode(T.self, from: temp)
    }
}
