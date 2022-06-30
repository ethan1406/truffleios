//
//  OnboardingViewController.swift
//  Truffle
//
//  Created by Ethan Chang on 6/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import FirebaseAnalytics
import UIKit
import AVKit

class OnboardingViewController: UIViewController {

    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var continueButton: UIButton!

    @objc func continueToAr() {
        Analytics.logEvent("continue_button_tapped", parameters: [:])

        let defaults = UserDefaults.standard
        defaults.set(true, forKey: hasOnboardedKey)

        performSegue(withIdentifier: "toArView", sender: nil)
    }

    private var looper: AVPlayerLooper? = nil
    private var player: AVPlayer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.init(named: "LightGray")
        setupVideoView()

        titleLabel.text = NSLocalizedString("Welcome to Truffle", comment: "")
        descriptionLabel.text = NSLocalizedString("Description label", comment: "")


        continueButton.setTitle(NSLocalizedString("Continue", comment: ""), for: .normal)
        continueButton.addTarget(self, action: #selector(continueToAr), for: .touchUpInside)

        Analytics.logEvent("onboarding_screen_viewed", parameters: [:])
    }

    private func setupVideoView() {
        let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "wedding_card_lighter_gray", withExtension: "mp4")!)
        self.player = AVQueuePlayer()
        if let queuePlayer = self.player as? AVQueuePlayer {
            self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = queuePlayer
            playerViewController.showsPlaybackControls = false
            playerViewController.view.backgroundColor = UIColor.init(named: "LightGray")

            self.addChild(playerViewController)
            playerView.addSubview(playerViewController.view)
            playerViewController.view.frame = playerView.bounds
            playerViewController.didMove(toParent: self)
            queuePlayer.play()
        }
    }
}
