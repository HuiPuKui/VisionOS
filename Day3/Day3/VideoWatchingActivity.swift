//
//  VideoWatchingActivity.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/23.
//

import Foundation
import GroupActivities
import CoreTransferable

/*
    一起观看视频结构体：遵守了 GroupActivity, Transferable 协议
    GroupActivity：用于定义和配置可以通过 SharePlay 在 FaceTime 调用中共享的群组活动的协议
    Transferable：用于声明数据可以跨设备或用户传输的协议
 */

struct VideoWatchingActivity: GroupActivity, Transferable {
    
    let video: Video
    
    var metadata: GroupActivityMetadata { // metadata 用于配制活动信息
        var metadata = GroupActivityMetadata()
        
        metadata.type = .watchTogether // 活动类型
        metadata.title = video.title // 活动标题
        metadata.supportsContinuationOnTV = true // 是否支持在电视上继续观看
        
        return metadata
    }
}
