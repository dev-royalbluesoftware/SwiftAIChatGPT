//
//
// SwiftAIChatGPT
// PermissionDeniedView.swift
//
// Created by rbs-dev
// Copyright © Royal Blue Software
// 


import SwiftUI

struct PermissionDeniedView: View {
    let permissionType: AppError.PermissionType?
    let onTryAgain: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: permissionType == .microphone ? "mic.slash" : "waveform.slash")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(permissionType?.rawValue ?? "Permission") Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("This feature requires \(permissionType?.rawValue.lowercased() ?? "microphone") access to work properly. Please enable it in Settings to continue.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: onTryAgain) {
                    Text("Try Again")
                        .frame(minWidth: 130)
                        .padding()
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .frame(minWidth: 130)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 50)
        }
    }
}
