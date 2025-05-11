//
//
// SwiftAIChatGPT
// MessageInputView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
//

import SwiftUI
import SwiftData

struct MessageInputView: View {
    @Binding var text: String
       
       var body: some View {
           TextEditor(text: $text)
               .font(.system(size: 16))
               .scrollContentBackground(.hidden)
               .padding(.horizontal, 12)
               .padding(.vertical, 8)
               .frame(minHeight: 40, maxHeight: 200) // Grows from 1 line to ~10 lines
               .fixedSize(horizontal: false, vertical: true)
               .background(
                   ZStack {
                       RoundedRectangle(cornerRadius: 20)
                           .fill(Color(.systemGray6))
                       
                       if text.isEmpty {
                           HStack {
                               Text("Type a message...")
                                   .foregroundColor(.gray)
                                   .padding(.horizontal, 16)
                                   .padding(.top, 8)
                               Spacer()
                           }
                       }
                   }
               )
       }
   }
