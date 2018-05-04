//
//  Array+SJ.swift
//  reitsyun
//
//  Created by Liu Yang on 12/4/2018.
//  Copyright © 2018年 Liu Yang. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }

}
