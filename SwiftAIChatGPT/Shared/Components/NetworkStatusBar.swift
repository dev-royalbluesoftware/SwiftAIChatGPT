//
//
// SwiftAIChatGPT
// NetworkStatusBar.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import Foundation
import SwiftUI

struct NetworkStatusBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("No Internet Connection")
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }
}
