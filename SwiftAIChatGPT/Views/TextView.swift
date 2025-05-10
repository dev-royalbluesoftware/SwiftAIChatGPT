//
//
// SwiftAIChatGPT
// TextView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI
import SwiftData

// UITextView wrapper for growing text input
struct TextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        updateHeight(uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateHeight(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        let newHeight = min(size.height, 200) // Max 10 lines approximately
        
        if height != newHeight {
            DispatchQueue.main.async {
                height = newHeight
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        
        init(_ parent: TextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.updateHeight(textView)
        }
    }
}
