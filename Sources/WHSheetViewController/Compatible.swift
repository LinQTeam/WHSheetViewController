//
//  Compatible.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit

extension UIView {
    public var compatibleSafeAreaInsets: UIEdgeInsets {
        return self.safeAreaInsets
    }
}

extension CALayer {
    public var compatibleMaskedCorners: CACornerMask {
        get {
            return self.maskedCorners
        }
        set {
            self.maskedCorners = newValue
        }
    }
}

extension UIViewController {
    public var compatibleAdditionalSafeAreaInsets: UIEdgeInsets {
        get {
            return self.additionalSafeAreaInsets
        }
        set {
            self.additionalSafeAreaInsets = newValue
        }
    }
}
