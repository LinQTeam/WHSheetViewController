//
//  UIViewControllerExtension.swift
//  WHViewController
//
//  Created by shachi on 2023/05/29.
//

import UIKit

@available(iOS 13.0, *)
extension UIViewController {
    public var whViewController: WHSheetViewController? {
        var parent = self.parent
        while let currentParent = parent {
            if let sheetViewController = currentParent as? WHSheetViewController {
                return sheetViewController
            } else {
                parent = currentParent.parent
            }
        }
        return nil
    }
}
