//
//  WHTextField.swift
//  WHSheetViewController
//
//  Created by shachi on 2023/05/30.
//

import SwiftUI

@available(iOS 13.0, *)
struct WHTextField<V: Hashable>: UIViewRepresentable {
    @Binding var text: String
    var id: V
    @Binding var firstResponder: V?
    private var onReturn: () -> Void

    init(text: Binding<String>, id: V, firstResponder: Binding<V?>, onReturn: @escaping (() -> Void) = {}) {
        self.id = id
        _text = text
        _firstResponder = firstResponder
        self.onReturn = onReturn
    }

    func makeCoordinator() -> WHTextFieldCoordinator {
        WHTextFieldCoordinator(text: $text,
                               onStartEditing: startedEditing,
                               onEndEditing: finishedEditing,
                               onReturnTap: returnTap)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        setProperties(textField: textField)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        textField.delegate = context.coordinator
        setProperties(textField: textField)

        if id == firstResponder, textField.isFirstResponder == false {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
    }

    func setProperties(textField: UITextField) {
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func startedEditing() {
        if id != firstResponder {
            firstResponder = id
        }
    }

    func finishedEditing() {
        guard id == firstResponder else { return }
        firstResponder = nil
    }

    func returnTap() {
        self.onReturn()
    }
}

@available(iOS 13.0, *)
protocol WHTextFieldReturnKeyProtocol {
    func returnTapped()
}

@available(iOS 13.0, *)
class WHTextFieldCoordinator: NSObject, UITextFieldDelegate, WHTextFieldReturnKeyProtocol {
    @Binding private var text: String
    private let onStartEditing: (() -> Void)
    private let onEndEditing: (() -> Void)
    private let onReturnTap: (() -> Void)

    init(text: Binding<String>, onStartEditing: @escaping (() -> Void), onEndEditing: @escaping (() -> Void), onReturnTap: @escaping (() -> Void)) {
        _text = text
        self.onStartEditing = onStartEditing
        self.onEndEditing = onEndEditing
        self.onReturnTap = onReturnTap

        super.init()
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        DispatchQueue.main.async { [weak self] in
            self?.text = textField.text ?? ""
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        onStartEditing()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onEndEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnTapped()
        return true
    }

    @objc func returnTapped() {
        onReturnTap()
    }
}

@available(iOS 13.0, *)
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
