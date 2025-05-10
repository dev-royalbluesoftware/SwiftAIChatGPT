//
//
// SwiftAIChatGPT
// ToastView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case error
        case warning
        case success
        
        var backgroundColor: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
            
            Text(message)
                .foregroundColor(.white)
                .font(.callout)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.backgroundColor)
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Toast modifier for views
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    ToastView(message: message, type: type)
                        .padding(.top, 50)
                    Spacer()
                }
                .animation(.spring(), value: isShowing)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastView.ToastType = .error, duration: TimeInterval = 3.0) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type, duration: duration))
    }
}

#Preview {
    VStack {
        ToastView(message: "Network connection lost", type: .error)
        ToastView(message: "Warning: Limited connectivity", type: .warning)
        ToastView(message: "Message sent successfully", type: .success)
    }
    .padding()
}
