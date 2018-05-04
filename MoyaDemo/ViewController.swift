//
//  ViewController.swift
//  MoyaDemo
//
//  Created by Liu Yang on 2018/5/4.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 仅仅是展示,api没有配置
        // just display, api not config
        
        NetworkManager<HomeModel>().requestModel(MallAPI.getMallHome, completion: { (response) in
            let home = response?.data
        }) { (error) in
            if let msg = error.message {
                print(msg)
            }
        }
        
        NetworkManager<GoodsModel>().requestListModel(MallAPI.getGoodsList, completion: { (response) in
            let goods = response?.dataList
            let page = response?.page
        }) { (error) in
            if let msg = error.message {
                print(msg)
            }
        }
    }
}

