//
//  InitialTouchPanGestureRecognizer.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit.UIGestureRecognizerSubclass

class InitialTouchPanGestureRecognizer: UIPanGestureRecognizer {
    var initialTouchLocation: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialTouchLocation = touches.first?.location(in: view)
    }
}
