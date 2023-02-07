//
//  Constants.swift
//  Example
//
//  Created by leven on 2023/1/9.
//

import Foundation
import UIKit

var safeBottomHeight: CGFloat {
    return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
}


var safeTopHeight: CGFloat {
    return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
}
