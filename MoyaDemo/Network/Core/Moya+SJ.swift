//
//  Moya+SJ.swift
//  NetworkDemo
//
//  Created by Liu Yang on 2018/4/24.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import Foundation
import Moya

protocol MoyaAddable {
    var cacheKey: String? { get }
    var isShowHud: Bool { get }
}

//参数统一处理
public extension TargetType {
    var baseURL : URL {
        return URL(string: "base url")!
    }
    
    var headers : [String : String]? {
        return nil
    }
    
    var sampleData : Data {
        return Data()
    }
}
