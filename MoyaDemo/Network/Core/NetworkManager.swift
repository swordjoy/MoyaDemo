//
//  NetworkManager.swift
//  MoyaDemo
//
//  Created by Liu Yang on 2018/5/4.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import Foundation
import Moya

class NetworkManager<T> where T: Codable {
    /// 请求普通接口
    ///
    /// - Parameters:
    ///   - type: 根据Moya定义的接口
    ///   - test: 是否使用测试(几乎用不到)
    ///   - progressBlock: 进度返回闭包
    ///   - completion: 结束返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    func requestModel<R: TargetType & MoyaAddable>(
        _ type: R,
        test: Bool = false,
        progressBlock: ((Double) -> ())? = nil,
        completion: @escaping ((ModelResponse<T>?) -> ()),
        error: @escaping (NetworkError) -> () )
        -> Cancellable?
    {
        return request(type, test: test, progressBlock: progressBlock, modelComletion: completion, error: error)
    }
    
    /// 请求列表接口
    ///
    /// - Parameters:
    ///   - type: 根据Moya定义的接口
    ///   - test: 是否使用测试(几乎用不到)
    ///   - completion: 结束返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    @discardableResult
    func requestListModel<R: TargetType & MoyaAddable>(
        _ type: R,
        test: Bool = false,
        completion: @escaping ((ListResponse<T>?) -> ()),
        error: @escaping (NetworkError) -> () )
        -> Cancellable?
    {
        return request(type, test: test, modelListComletion: completion, error: error)
    }
    
    // 用来处理只请求一次的栅栏队列
    private let barrierQueue = DispatchQueue(label: "cn.tsingho.qingyun.NetworkManager", attributes: .concurrent)
    // 用来处理只请求一次的数组,保存请求的信息 唯一
    private var fetchRequestKeys = [String]()
}


extension NetworkManager {
    /// 请求基类方法
    ///
    /// - Parameters:
    ///   - type: 根据Moya定义的接口
    ///   - test: 是否使用测试(几乎用不到)
    ///   - progressBlock: 进度返回闭包
    ///   - modelComletion: 普通接口返回数据闭包
    ///   - modelListComletion: 列表接口返回数据闭包
    ///   - error: 错误信息返回闭包
    /// - Returns: 可以用来取消请求
    private func request<R: TargetType & MoyaAddable>(
        _ type: R,
        test: Bool = false,
        progressBlock: ((Double) -> ())? = nil,
        modelComletion: ((ModelResponse<T>?) -> ())? = nil,
        modelListComletion: ((ListResponse<T>?) -> () )? = nil,
        error: @escaping (NetworkError) -> () )
        -> Cancellable?
    {
        // 同一请求正在请求直接返回
        if isSameRequest(type) {
            return nil
        }
        
        let provider = createProvider(type: type, test: test)
        let cancellable = provider.request(type, callbackQueue: DispatchQueue.global(), progress: { (progress) in
            DispatchQueue.main.async {
                progressBlock?(progress.progress)
            }
        }) { (response) in
            let errorblock = { (e: NetworkError) in
                DispatchQueue.main.async {
                    error(e)
                }
            }
            
            // 请求完成移除
            self.cleanRequest(type)
            
            switch response {
            case .success(let successResponse):
                if let temp = modelComletion {
                    self.handleSuccessResponse(type, response: successResponse, modelComletion: temp, error: error)
                }
                if let temp = modelListComletion {
                    self.handleSuccessResponse(type, response: successResponse, modelListComletion: temp, error: error)
                }
            case .failure:
                errorblock(NetworkError.exception(message: "未连接到服务器"))
            }
        }
        return cancellable
    }
    
    //处理成功的返回
    private func handleSuccessResponse<R: TargetType & MoyaAddable>(
        _ type: R,
        response: Response,
        modelComletion: ((ModelResponse<T>?) -> ())? = nil,
        modelListComletion: ((ListResponse<T>?) -> () )? = nil,
        error: @escaping (NetworkError) -> ())
    {
        switch type.task {
        case .uploadMultipart, .requestParameters:
            do {
                if let temp = modelComletion {
                    let modelResponse = try handleResponseData(false, type: type, data: response.data)
                    DispatchQueue.main.async {
                        self.cacheData(type, modelComletion: temp, model: (modelResponse.0, nil))
                        temp(modelResponse.0)
                    }
                }
                
                if let temp = modelListComletion {
                    let listResponse = try handleResponseData(true, type: type, data: response.data)
                    temp(listResponse.1)
                    DispatchQueue.main.async {
                        self.cacheData(type, modelListComletion: temp, model: (nil, listResponse.1))
                        temp(listResponse.1)
                    }
                }
            } catch let NetworkError.serverResponse(message, code) {
                error(NetworkError.serverResponse(message: message, code: code))
            } catch let NetworkError.loginStateIsexpired(message) {
                // 登录状态变化清楚登录缓存信息
                error(NetworkError.loginStateIsexpired(message: message))
            } catch {
                #if Debug
                fatalError("未知错误")
                #endif
            }
        default:
            ()
        }
    }
    
    // 处理数据
    private func handleResponseData<R: TargetType & MoyaAddable>(_ isList: Bool, type: R, data: Data) throws -> (ModelResponse<T>?, ListResponse<T>?) {
        guard let jsonAny = try? JSONSerialization.jsonObject(with: data, options: []) else {
            throw NetworkError.jsonSerializationFailed(message: "JSON解析失败")
        }
        
        if isList {
            let listResponse: ListResponse<T>? = ListResponse(data: jsonAny)
            guard let temp = listResponse else {
                throw NetworkError.jsonToDictionaryFailed(message: "JSON转字典失败")
            }
            
            if temp.code != ResponseCode.successResponseStatus {
                try handleCode(responseCode: temp.code, message: temp.message)
            }
            
            return (nil, temp)
        }
        else {
            let response: ModelResponse<T>? = ModelResponse(data: jsonAny)
            guard let temp = response else {
                throw NetworkError.jsonToDictionaryFailed(message: "JSON转字典失败")
            }
            
            if temp.code != ResponseCode.successResponseStatus {
                try handleCode(responseCode: temp.code, message: temp.message)
            }
            
            return (temp, nil)
        }
    }
    
    // 处理错误信息
    private func handleCode(responseCode: Int, message: String?) throws {
        switch responseCode {
        case ResponseCode.forceLogoutError:
            throw NetworkError.loginStateIsexpired(message: message)
        default:
            throw NetworkError.serverResponse(message: message, code: responseCode)
        }
    }
    
    // 缓存
    private func cacheData<R: TargetType & MoyaAddable>(
        _ type: R,
        modelComletion: ((ModelResponse<T>?) -> ())? = nil,
        modelListComletion: ( (ListResponse<T>?) -> () )? = nil,
        model: (ModelResponse<T>?, ListResponse<T>?))
    {
        guard let cacheKey = type.cacheKey else {
            return
        }
        if modelComletion != nil, let temp = model.0 {
            // 缓存
        }
        if modelListComletion != nil, let temp = model.1 {
            // 缓存
        }
    }
    
    // 创建moya请求类
    private func createProvider<T: TargetType & MoyaAddable>(type: T, test: Bool) -> MoyaProvider<T> {
        let activityPlugin = NetworkActivityPlugin { (state, targetType) in
            switch state {
                case .began:
                    DispatchQueue.main.async {
                        if type.isShowHud {
                            //                    SVProgressHUD.showLoading()
                        }
                        self.startStatusNetworkActivity()
                    }
                case .ended:
                    DispatchQueue.main.async {
                        if type.isShowHud {
                            //                    SVProgressHUD.dismiss()
                        }
                        self.stopStatusNetworkActivity()
                    }
            }
        }
        let provider = MoyaProvider<T>(plugins: [activityPlugin, NetworkLoggerPlugin(verbose: false)])
        return provider
    }
    
    private func startStatusNetworkActivity() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    private func stopStatusNetworkActivity() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// 保证同一请求同一时间只请求一次
extension NetworkManager {
    private func isSameRequest<R: TargetType & MoyaAddable>(_ type: R) -> Bool {
        switch type.task {
        case let .requestParameters(parameters, _):
            let key = type.path + parameters.description
            var result: Bool!
            barrierQueue.sync(flags: .barrier) {
                result = fetchRequestKeys.contains(key)
                if !result {
                    fetchRequestKeys.append(key)
                }
            }
            return result
        default:
            // 不会调用
            return false
        }
    }
    
    private func cleanRequest<R: TargetType & MoyaAddable>(_ type: R) {
        switch type.task {
        case let .requestParameters(parameters, _):
            let key = type.path + parameters.description
            barrierQueue.sync(flags: .barrier) {
                fetchRequestKeys.remove(key)
            }
        default:
            // 不会调用
            ()
        }
    }
}
