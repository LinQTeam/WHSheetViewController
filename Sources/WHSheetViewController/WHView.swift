//
//  WHView.swift
//  
//
//  Created by shachi on 2023/05/28.
//

import UIKit

class WHView: UIView {
    weak var delegate: WHViewDelegate?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.delegate?.sheetPoint(inside: point, with: event) ?? true
    }
}
// delegate
protocol WHViewDelegate: AnyObject {
    func sheetPoint(inside point: CGPoint, with event: UIEvent?) -> Bool
}
