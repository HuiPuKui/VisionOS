//
//  PlayerView.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/24.
//

import Foundation
import AVKit
import SwiftUI

struct PlayerView: View, UIViewControllerRepresentable {
    
    @Environment(PlayerModel.self) private var model
    
    // UIViewControllerRepresentable 协议所需
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = model.makePlayerViewController()
        controller.allowsPictureInPicturePlayback = true // 允许画中画
        return controller
    }
    
    // UIViewControllerRepresentable 协议所需
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        Task { @MainActor in
            uiViewController.contextualActions = []
        }
    }
}
