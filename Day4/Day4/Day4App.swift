//
//  Day4App.swift
//  Day4
//
//  Created by HuiPuKui on 2024/5/26.
//

/*
 沉浸式空间
 */
import SwiftUI
import RealityKit

@main
struct Day4App: App {
    
    // 使用@StateObject声明的变量，其内部的对象在视图首次创建时初始化，并且在视图的整个生命周期内一直存在。即使父视图更新并重新渲染子视图，或者配置发生改变导致视图重新创建，这个@StateObject的值也不会被重置。
    @StateObject var model = Day4ViewModel()
    
    var body: some SwiftUI.Scene {
        ImmersiveSpace {
            RealityView { content in
                content.add(model.setupContentEntity())
            }
            .task {
                await model.runSession()
            }
        }
    }
}
