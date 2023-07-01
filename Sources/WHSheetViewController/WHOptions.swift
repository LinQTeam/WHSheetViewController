//
//  WHOptions.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit

public struct WHOptions {
    public static var `default` = WHOptions()

    public enum TransitionOverflowType {
        case color(color: UIColor)
        case view(view: UIView)
        case none
        case automatic
    }

    public var pullBarHeight: CGFloat = 24

    public var presentingViewCornerRadius: CGFloat = 12
    public var shouldExtendBackground = true
    public var setIntrinsicHeightOnNavigationControllers = true

    public var transitionAnimationOptions: UIView.AnimationOptions = [.curveEaseOut]
    public var transitionDampening: CGFloat = 0.7
    public var transitionDuration: TimeInterval = 0.2

    public var transitionVelocity: CGFloat = 0.4
    public var transitionOverflowType: TransitionOverflowType = .automatic

    public var pullDismissThreshod: CGFloat = 60.0

    public var useFullScreenMode = true
    public var shrinkPresentingViewController = true

    public var useInlineMode = false
    
    public var totalDuration: CGFloat = 0.2

    public var horizontalPadding: CGFloat = 0
    public var maxWidth: CGFloat?

    public var isRubberBandEnabled: Bool = false

    public static var shrinkingNestedPresentingViewControllers = false

    public init() { }
    public init(pullBarHeight: CGFloat? = nil,
                presentingViewCornerRadius: CGFloat? = nil,
                shouldExtendBackground: Bool? = nil,
                setIntrinsicHeightOnNavigationControllers: Bool? = nil,
                useFullScreenMode: Bool? = nil,
                shrinkPresentingViewController: Bool? = nil,
                useInlineMode: Bool? = nil,
                horizontalPadding: CGFloat? = nil,
                maxWidth: CGFloat? = nil,
                isRubberBandEnabled: Bool? = nil,
                totalDuration: CGFloat? = nil,
                transitionDuration: CGFloat? = nil,
                transitionVelocity: CGFloat? = nil) {
        let defaultOptions = WHOptions.default
        self.pullBarHeight = pullBarHeight ?? defaultOptions.pullBarHeight
        self.presentingViewCornerRadius = presentingViewCornerRadius ?? defaultOptions.presentingViewCornerRadius
        self.shouldExtendBackground = shouldExtendBackground ?? defaultOptions.shouldExtendBackground
        self.setIntrinsicHeightOnNavigationControllers = setIntrinsicHeightOnNavigationControllers ?? defaultOptions.setIntrinsicHeightOnNavigationControllers
        self.useFullScreenMode = useFullScreenMode ?? defaultOptions.useFullScreenMode
        self.shrinkPresentingViewController = shrinkPresentingViewController ?? defaultOptions.shrinkPresentingViewController
        self.useInlineMode = useInlineMode ?? defaultOptions.useInlineMode
        self.horizontalPadding = horizontalPadding ?? defaultOptions.horizontalPadding
        let maxWidth = maxWidth ?? defaultOptions.maxWidth
        self.maxWidth = maxWidth == 0 ? nil : maxWidth
        self.isRubberBandEnabled = isRubberBandEnabled ?? false
        self.totalDuration = totalDuration ?? defaultOptions.totalDuration
        self.transitionDuration = transitionDuration ?? defaultOptions.transitionDuration
        self.transitionVelocity = transitionVelocity ?? defaultOptions.transitionVelocity
    }
}
