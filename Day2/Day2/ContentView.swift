//
//  ContentView.swift
//  Day2
//
//  Created by HuiPuKui on 2024/5/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

// 显示 3D 模型

struct ContentView: View {
    
    private let url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    var body: some View {
        VStack { // 垂直堆叠
            Text("Show teapot")

            Model3D(url: url) { model in
                model
                    .resizable() // 设置可调整大小
                    .aspectRatio(contentMode: .fit) // 设置保持纵横比
                    .frame(width: 200, height: 200) // 设置尺寸
            } placeholder: {
                ProgressView() // 显示加载圆圈
            }
        }
        .padding()
    }
}

 // 预览
#Preview(windowStyle: .automatic) {
    ContentView()
}
