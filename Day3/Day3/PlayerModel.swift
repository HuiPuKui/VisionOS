//
//  PlayerModel.swift
//  Day3
//
//  Created by HuiPuKui on 2024/5/23.
//

import Foundation
import AVKit
import Combine
import Observation

@Observable class PlayerModel {
    
    private(set) var isPlaying = false // 视频是否正在播放
    private(set) var isPlaybackComplete = false // 视频是否播放完毕
    private(set) var currentItem: Video? = nil // 播放的视频
    private(set) var shouldProposeNextVideo = false // 是否应该提示播放下一个视频
    private var player = AVPlayer() // 播放器
    
    private var playerViewController: AVPlayerViewController? = nil // 播放视图控制器
    private var playerViewControllerDelegate: AVPlayerViewControllerDelegate? = nil // 播放视图控制器的委托
    
    private(set) var shouldAutoPlay = true // 是否应该自动播放
    
    private var coordinator: VideoWatchingCoordinator! = nil // 协调器
    
    private var timeObserver: Any? = nil // 进度条
    private var subscription = Set<AnyCancellable>() // 订阅者集合
    
    // 初始化
    init() {
        coordinator = VideoWatchingCoordinator(playbackCoordinator: player.playbackCoordinator)
        observePlayback()
        Task {
            await configureAudioSession()
            await observeSharedVideo()
        }
    }
    
    // 构造 PlayerViewController
    func makePlayerViewController() -> AVPlayerViewController {
        let delegte = PlayerViewControllerDelegate(player: self)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = delegte
        playerViewController = controller
        playerViewControllerDelegate = delegte
        return controller
    }
    
    private func observePlayback() {
        guard subscription.isEmpty else { return }
        
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] status in
                self?.isPlaying = status == .playing
            }
            .store(in: &subscription)
        
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchSerialQueue.main)
            .map { _ in true }
            .sink { [weak self] isPlaybackComplete in
                self?.isPlaybackComplete = isPlaybackComplete
            }
            .store(in: &subscription)
        
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let result = InterruptionResult(notification) else { return }
                if result.type == .ended && result.options == .shouldResume {
                    self?.player.play()
                }
            }
            .store(in: &subscription)
        
        addTimeObserver()
    }
    
    // 配置音频会话
    private func configureAudioSession() async {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Unable to configure audio session: \(error.localizedDescription)")
        }
    }
    
    // 使用发布-订阅模型实现共享视频的更改
    private func observeSharedVideo() async {
        let current = currentItem
        await coordinator.$sharedVideo
            .receive(on: DispatchQueue.main) // 主线程执行
            .compactMap { $0 }
            .filter { $0 != current } // 确保视频不同
            .sink { [weak self] video in
                guard let self else { return }
                loadVideo(video) // 加载新视频
            }
            .store(in: &subscription) // 将订阅加入集合
    }
    
    // 加载视频
    func loadVideo(_ video: Video, autoplay: Bool = true) {
        currentItem = video
        shouldAutoPlay = autoplay
        isPlaybackComplete = false
        replaceCurrentItem(with: video)
        configureAudioExperience()
    }
    
    // 更换当前播放的媒体项
    private func replaceCurrentItem(with video: Video) {
        let playerItem = AVPlayerItem(url: video.url)
        playerItem.externalMetadata = createMetadataItmes(for: video)
        player.replaceCurrentItem(with: playerItem)
        print("🍿 \(video.title) enqueued for playback.")
    }
    
    func reset() {
        currentItem = nil
        player.replaceCurrentItem(with: nil)
        playerViewController = nil
        playerViewControllerDelegate = nil
    }
    
    private func createMetadataItmes(for video: Video) -> [AVMetadataItem] {
        let mapping: [AVMetadataIdentifier: Any] = [
            .commonIdentifierTitle: video.title,
        ]
        return mapping.compactMap { createMetadataItem(for: $0, value: $1) }
    }
    
    // 创建元数据
    private func createMetadataItem(for identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
    
    private func configureAudioExperience() { // 配置音频会话的空间音频
        let experience: AVAudioSessionSpatialExperience
        experience = .headTracked(soundStageSize: .small, anchoringStrategy: .front) // 围绕头部
        try! AVAudioSession.sharedInstance().setIntendedSpatialExperience(experience)
    }
    
    // MARK: - Transport Control
    
    func play() { // 播放
        player.play()
    }
    
    func pause() { // 暂停
        player.pause()
    }
    
    func togglePlayback() { // 反转状态
        player.timeControlStatus == .paused ? play() : pause()
    }
    
    // MARK: - Time Observation
    
    private func addTimeObserver() { // 添加时间订阅，当时间在最后十秒范围内，准备提醒播放下一条
        removeTimeObserver()
        let timeInterval = CMTime(value: 1, timescale: 1)
        timeObserver = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time
            in
            guard let self = self, let duration = player.currentItem?.duration else { return }
            let isInProposalRange = time.seconds >= duration.seconds - 10.0
            if shouldProposeNextVideo != isInProposalRange {
                shouldProposeNextVideo = isInProposalRange
            }
        }
    }
    
    private func removeTimeObserver() { // 移除时间订阅
        guard let timeObserver = timeObserver else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
    
    /*
        final：不能被继承
        委托实现即将全屏模式即将结束时，在主线程异步的重置播放器
     */
    final class PlayerViewControllerDelegate: NSObject, AVPlayerViewControllerDelegate {
        let player: PlayerModel
        
        init(player: PlayerModel) {
            self.player = player
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
            Task { @MainActor in
                player.reset()
            }
        }
    }
}

// 封装音频会话中断相关信息
struct InterruptionResult {
    let type: AVAudioSession.InterruptionType
    let options: AVAudioSession.InterruptionOptions
    
    init?(_ notification: Notification) {
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType,
              let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? AVAudioSession.InterruptionOptions else {
            return nil
        }
        self.type = type
        self.options = options
    }
}
