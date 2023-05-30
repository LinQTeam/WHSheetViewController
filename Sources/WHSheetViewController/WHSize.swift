//
//  WHSize.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import CoreGraphics

public enum WHSize: Equatable {
    case intrinsic
    case fixed(CGFloat)
    case fullscreen
    case percent(Float)
    case marginFromTop(CGFloat)
}
