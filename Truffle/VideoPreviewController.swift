//
//  VideoPreviewController.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import AVKit

final class VideoPreviewController: UIViewController {

    private let videoURL: URL

    private var looper: AVPlayerLooper? = nil
    private var player: AVPlayer? = nil


    // There's a bug that's causing first button tap to be intercepted by buttons in view controller. Using a counter as a hack for now.
    private var buttonTapCounter = 0

    private let dismissButton: UIButton = {
        let button = UIButton(configuration: createButtonConfiguration(imageName: "chevron.down"))

        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let shareButton: UIButton = {
        let button = UIButton(configuration: createButtonConfiguration(imageName: "square.and.arrow.up"))

        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        setupVideoPlayer()
        addButtons()

        NotificationCenter.default.addObserver(self, selector: #selector(appCameToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func appCameToForeground() {
        self.player?.play()
    }

    private func setupVideoPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        self.player = AVQueuePlayer()
        if let queuePlayer = self.player as? AVQueuePlayer {
            self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            let playerFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = queuePlayer
            playerViewController.view.frame = playerFrame
            playerViewController.showsPlaybackControls = false


            // add view to parent
            addChild(playerViewController)
            view.addSubview(playerViewController.view)
            playerViewController.didMove(toParent: self)

            queuePlayer.play()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }


    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isMovingFromParent {
            try? FileManager.default.removeItem(at: videoURL)
        }

        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func addButtons() {
        view.addSubview(dismissButton)
        view.addSubview(shareButton)

        configureDismissButton()
        configureShareButton()
    }


    private func configureShareButton() {
        shareButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
        shareButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        shareButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        shareButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
    }

    private func configureDismissButton() {
        dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
        dismissButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        dismissButton.addTarget(self, action: #selector(dismissScreen), for: .touchUpInside)
    }

    @objc func share() {
        present(
            UIActivityViewController(activityItems: [videoURL], applicationActivities: nil),
            animated: true,
            completion: nil
        )
    }

    @objc func dismissScreen() {
        dismiss(animated: true)
    }

    private static func createButtonConfiguration(imageName: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(named: "PrimaryColor")
        configuration.image = UIImage(systemName: imageName)
        configuration.cornerStyle = .capsule

        return configuration
    }
}
