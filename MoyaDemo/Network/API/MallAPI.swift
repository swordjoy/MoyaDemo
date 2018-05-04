//
//  MallAPI.swift
//  MoyaDemo
//
//  Created by Liu Yang on 2018/5/4.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import Foundation
import Moya

enum MallAPI {
    case getMallHome
    case getGoodsList
}

extension MallAPI: TargetType, MoyaAddable {
    var path: String {
        switch self {
            case .getMallHome:
                return "home path"
            case .getGoodsList:
                return "goods list path"
        }
    }
    
    var method: Moya.Method {
        switch self {
            default:
                return .get
        }
    }
    
    var task: Task {
        var parameters: [String: Any] = [:]
        switch self {
            case .getMallHome:
                parameters = [:]
            case .getGoodsList:
                ()
        }
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var cacheKey: String? {
        switch self {
            case .getMallHome:
                return "mall home cache key"
            default:
                return nil
        }
    }
    
    var isShowHud: Bool {
        switch self {
            case .getMallHome:
                return true
            default:
                return false
        }
    }
}
