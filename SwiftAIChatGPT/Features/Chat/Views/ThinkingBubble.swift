//
//
// SwiftAIChatGPT
// ThinkingBubble.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 

import SwiftUI
import SwiftData

struct ThinkingBubble: View {
    @State private var animationAmount = 1.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationAmount)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationAmount
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray5))
                )
            }
            Spacer()
        }
        .onAppear {
            animationAmount = 0.5
        }
    }
}
