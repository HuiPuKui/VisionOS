//
//  Video.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/23.
//

import Foundation

/*
    视频结构体：遵守 Identifiable, Hashable, Codable 协议
    Identifiable：该协议要求有一个可以唯一识别实例的属性
    Hashable：该协议使得结构体的实例可以被哈希化
    Codable：同时遵守了 Encodable 和 Decodable 协议，使得这个结构体可以很容易地转换成和从JSON、XML或其它外部表示格式转换数据。
 */

struct Video: Identifiable, Hashable, Codable {
    let id: Int
    let url: URL
    let title: String
}
