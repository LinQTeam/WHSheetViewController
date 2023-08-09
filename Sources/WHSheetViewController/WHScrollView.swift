//
//  WHScrollView.swift
//
//
//  Created by shachi on 2023/08/08.
//
import SwiftUI

struct WHScrollView<Content: View>: UIViewRepresentable {
    private let scrollView = UIScrollView()
    private let content: UIView

    init(callback: (UIScrollView) -> Void, @ViewBuilder content: () -> Content) {
        self.content = UIHostingController(rootView: content()).view
        self.content.backgroundColor = .clear
        callback(scrollView)
    }

    func makeUIView(context: Context) -> UIView {
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        let constraints = [
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ]
        scrollView.addConstraints(constraints)
        return scrollView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
