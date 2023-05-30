//
//  UIColorExtension.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
extension UIColor {
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1, darkRed: CGFloat, darkGreen: CGFloat, darkBlue: CGFloat, darkAlpha: CGFloat = 1) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(red: darkRed, green: darkGreen, blue: darkBlue, alpha: darkAlpha)
            default:
                return UIColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }
    }

    convenience init(white: CGFloat, alpha: CGFloat = 1, black: CGFloat, darkAlpha: CGFloat = 1) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(white: black, alpha: darkAlpha)
            default:
                return UIColor(white: white, alpha: alpha)
            }
        }
    }

    convenience init(light: UIColor, dark: UIColor) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return light
            default:
                return dark
            }
        }
    }
}

@available(iOS 14.0, *)
extension List {
    func listBackground(_ color: Color) -> some View {
        UITableView.appearance().backgroundColor = UIColor(color)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(color)
        return self
    }
}
