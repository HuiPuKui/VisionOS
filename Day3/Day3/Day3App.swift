//
//  Day3App.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/23.
//

import SwiftUI

@main
struct Day3App: App {
    
    @State private var player = PlayerModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
        }
    }
}
