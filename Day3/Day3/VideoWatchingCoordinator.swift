//
//  VideoWatchingCoordinator.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/23.
//

import Foundation
import Combine
import GroupActivities
import AVFoundation

actor VideoWatchingCoordinator {
    
    @Published private(set) var sharedVideo: Video? // 要共享的视频
    
    private var subscriptions = Set<AnyCancellable>() // 订阅者集合
    private var coordinatorDelegate = CoordinatorDelegate() // 协调器遵循的委托
    private var playbackCoordinator: AVPlayerPlaybackCoordinator // 协调器
    private var groupSession: GroupSession<VideoWatchingActivity>? {
        didSet { // 每次在 groupSession 的值发生变化之后执行
            guard let groupSession else { return } // 确保 groupSession 不为 nil
            playbackCoordinator.coordinateWithSession(groupSession) // 让协调器来协调该会话
        }
    }
    
    private class CoordinatorDelegate: NSObject, AVPlayerPlaybackCoordinatorDelegate {
        var video: Video?
        func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, identifierFor playerItem: AVPlayerItem) -> String {
            "\(video?.id ?? -1)"
        }
    }
    
    init(playbackCoordinator: AVPlayerPlaybackCoordinator) { // 初始化成员
        self.playbackCoordinator = playbackCoordinator
        self.playbackCoordinator.delegate = coordinatorDelegate
        Task {
            await startObservingSessions()
        }
    }
    
    private func startObservingSessions() async {
        for await session in VideoWatchingActivity.sessions() { // 异步：当session变化时触发
            cleanUpSession(groupSession)
            groupSession = session
            
            let stateListener = Task {
                await self.handleStateChanges(groupSession: session)
            }
            subscriptions.insert(.init { stateListener.cancel() })
            
            let activityListener = Task {
                await self.handlerActivityChanges(groupSession: session)
            }
            subscriptions.insert(.init { activityListener.cancel() })
            
            session.join()
        }
    }
    
    private func cleanUpSession(_ session: GroupSession<VideoWatchingActivity>?) { // 清空所有
        guard groupSession === session else { return }
        
        groupSession?.leave()
        groupSession = nil
        sharedVideo = nil
        subscriptions.removeAll()
    }
    
    private func handlerActivityChanges(groupSession: GroupSession<VideoWatchingActivity>) async { // 活动变化触发
        for await newActivity in groupSession.$activity.values {
            guard groupSession === self.groupSession else { return }
            updateSharedVideo(video: newActivity.video)
        }
    }
    
    private func handleStateChanges(groupSession: GroupSession<VideoWatchingActivity>) async { // 状态变化触发
        for await newState in groupSession.$state.values {
            if case .invalidated = newState {
                cleanUpSession(groupSession)
            }
        }
    }
    
    private func updateSharedVideo(video: Video) {
        coordinatorDelegate.video = video
        sharedVideo = video
    }
    
    func coordinatePlayback(of video: Video) async {
        guard video != sharedVideo else { return }
        let activity = VideoWatchingActivity(video: video)
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            do {
                _ = try await activity.activate()
            } catch {
                print("Unable to activate the activity: \(error)")
            }
        case .activationDisabled:
            sharedVideo = nil
        default:
            break
        }
    }
}
