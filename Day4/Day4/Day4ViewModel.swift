//
//  Day4ViewModel.swift
//  Day4
//
//  Created by HuiPuKui on 2024/5/26.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit

/*
    ObservableObject：协议用于创建可以被视图监控的对象
    @MainActor：所有函数默认在主线程上执行
 */

@MainActor class Day4ViewModel: ObservableObject {
    
    private let session = ARKitSession() // ARKit 会话
    private let worldTracking = WorldTrackingProvider() // 世界追踪
    private var contentEntity = Entity() // 实体
    
    func setupContentEntity() -> Entity { // 创建了一个包含立方体的实体
        let box = ModelEntity(mesh: .generateBox(width: 0.5, height: 0.5, depth: 0.5))
        contentEntity.addChild(box)
        return contentEntity
    }
    
    func runSession() async { // 启动 ARkit 会话
        print("WorldTrackingProvider.isSupported: \(WorldTrackingProvider.isSupported)") // 当前设备是否支持世界追踪功能
        print("PlaneDetectionProvider.isSupported: \(PlaneDetectionProvider.isSupported)") // 当前设备是否支持平面检测功能
        print("SceneReconstructionProvider.isSuupported: \(SceneReconstructionProvider.isSupported)") // 当前设备是否支持场景重建功能
        print("HandTrackingProvider.isSupported: \(HandTrackingProvider.isSupported)") // 当前设备是否支持手部追踪功能
        
        Task {
            let authorizationResult = await session.requestAuthorization(for: [.worldSensing]) // 请求权限
            
            // 请求的权限类型，请求的权限状态
            for (authorizationType, authorizationStatus) in authorizationResult {
                print("Authorization status for \(authorizationType) : \(authorizationStatus)")
                switch authorizationStatus {
                case .allowed: // 允许
                    break;
                case .denied: // 拒绝
                    // handle
                    break;
                case .notDetermined: // 未确定
                    break
                @unknown default:
                    break
                }
            }
        }
        
        Task {
            try await session.run([worldTracking])
            
            for await update in worldTracking.anchorUpdates {
                switch update.event {
                case .added, .updated:
                    print("Anchor position updated.")
                case .removed:
                    print("anchor position now unknown.")
                }
            }
        }
    }
}
