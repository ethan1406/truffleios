//
//  VideoPreviewController.swift
//  ARKitImageDetection
//
//  Created by Ethan Chang on 5/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import AVKit

final class VideoPreviewController: AVPlayerViewController {

  let videoURL: URL

  init(videoURL: URL) {
    self.videoURL = videoURL
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    player = AVPlayer(url: videoURL)

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(share)
    )
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if isMovingFromParent {
      try? FileManager.default.removeItem(at: videoURL)
    }
  }

  @objc func share() {
    present(
      UIActivityViewController(activityItems: [videoURL], applicationActivities: nil),
      animated: true,
      completion: nil
    )
  }
}
