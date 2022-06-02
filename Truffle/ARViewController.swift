/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import Bugsnag
import ARKit
import AVFoundation
import AVKit
import FirebaseAnalytics
import SceneKit
import SpriteKit
import RecordButton
import SCNRecorder
import UIKit


class ArViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!

    // record button
    private var recordButton : RecordButton!
    var progressTimer : Timer?
    var progress : CGFloat! = 0
    var timeElapsed = 0.0
    private let maxDuration = CGFloat(15) // Max duration of the recordButton


    // video dimensions
    private let attachmentViewHeight: CGFloat = 100
    private let attachmentViewWidth: CGFloat = 260

    // effect dimensions
    private let effectHeight: CGFloat = 600
    private let effectWidth: CGFloat = 600

    // The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")


    private var attachmentCollectionViewController: AttachmentCollectionViewController!


    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }

    var player: AVPlayer?
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.prepareForRecording()

        setupRecordButton()

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }

        setupAttachmentCollectionView()

        FileManager.default.clearTmpVideos()

        setupObservers()
    }


	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the AR experience
        resetTracking()

        Analytics.logEvent("home_screen_viewed", parameters: [:])
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        /*
         when a view is attached to sceneview, a snapshot window is created. It doesn't go away even
         after the scene is dismissed and intercepts touch events in following screens. This is a hack
         to remove the created window:
         https://stackoverflow.com/questions/54658514/delete-scnsnapshotwindow-after-leaving-augmented-reality-view
         */

        UIApplication.shared.windows.forEach {
            if ($0.frame.width == attachmentViewWidth && $0.frame.height == attachmentViewHeight) || ($0.frame.width == effectWidth && $0.frame.height == effectHeight) {
                $0.isHidden = true
            }
        }

        player?.pause()
        session.pause()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        clearObservers()
    }

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        resetVideoPlayer()
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")

            // TODO bug snag tracking + return + display dialog
        }
        
        let configuration = ARImageTrackingConfiguration()

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            configuration.providesAudioData = true
        case .undetermined,
                .denied:
            configuration.providesAudioData = false
        @unknown default:
            configuration.providesAudioData = false
        }

        configuration.trackingImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let message = NSLocalizedString("Please place the card before the camera", comment: "")
        statusViewController.scheduleMessage(message, inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage

        // create materials
        let collectionViewMaterial = SCNMaterial()
        let videoMaterial = SCNMaterial()
        let effectMaterial = SCNMaterial()

        // create video player
        if (self.player == nil) {
            self.player = createVideoPlayer()
        }

        guard let avPlayer = player else {
            return
        }

        loopVideo()

        DispatchQueue.main.async { [self] in
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            let message = String(format: NSLocalizedString("Detected %@", comment: ""), "\(imageName)")
            self.statusViewController.showMessage(message)

            // set material to custom views
            self.attachmentCollectionViewController.view.frame.size.height = self.attachmentViewHeight
            self.attachmentCollectionViewController.view.frame.size.width = self.attachmentViewWidth

            collectionViewMaterial.diffuse.contents = self.attachmentCollectionViewController.view
            videoMaterial.diffuse.contents = avPlayer

            //
            let effectView = EffectView(frame: CGRect(x: 0, y: 0, width: effectWidth, height: effectHeight))
            effectMaterial.diffuse.contents = effectView
        }

        updateQueue.async { [self] in
            let videoWidth = referenceImage.physicalSize.width * 1.2
            node.addChildNode(createVideoNode(width: videoWidth, height: videoWidth * 720/1280, material: videoMaterial, position: SCNVector3(x: 0, y: 0, z: 0)))

            Analytics.logEvent("video_viewed", parameters: [
                "type": "local"
            ])


            let attachmentHeight = referenceImage.physicalSize.width/2.5
            node.addChildNode(createAttachmentNode(width: attachmentHeight * self.attachmentViewWidth/self.attachmentViewHeight, height : attachmentHeight, material: collectionViewMaterial, position: SCNVector3(x: 0, y: 0.01, z: Float(referenceImage.physicalSize.height) * 0.75)))

            Analytics.logEvent("attachment_links_viewed", parameters: [
                "type": "local",
                "count": self.attachmentCollectionViewController.attachments.count
            ])


            node.addChildNode(createEffectNode(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height, material:  effectMaterial, position: SCNVector3(x: 0, y: -0.005, z: Float(referenceImage.physicalSize.height) * -0.45)))
        }
    }


    private let opacityIncrementInterval = 0.70

    private var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: opacityIncrementInterval),
            .fadeOpacity(to: 0.35, duration: opacityIncrementInterval),
            .fadeOpacity(to: 0.55, duration: opacityIncrementInterval),
            .fadeOpacity(to: 0.75, duration: opacityIncrementInterval),
            .fadeOpacity(to: 0.95, duration: opacityIncrementInterval),
            .fadeOpacity(to: 1.00, duration: opacityIncrementInterval)
        ])
    }

    private func createVideoPlayer() -> AVPlayer? {
        //video node
        guard let path = Bundle.main.path(forResource: "wedding_card", ofType:"mp4") else {
            debugPrint("wedding_card not found")
            return nil
        }

        let url = NSURL(fileURLWithPath: path)

        let asset = AVURLAsset(url: url as URL, options: nil)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none

        return player
    }

    private func loopVideo() {
        guard let player = player else {
            return
        }

        clearVideoObserver()

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        player.play()
    }

    private func clearObservers() {
        clearVideoObserver()

        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func clearVideoObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }


    @objc private func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: .zero, completionHandler: nil)

            Analytics.logEvent("home_screen_video_restarting", parameters: [
                "type": "local"
            ])
        }
    }

    @objc func record() {
        var permissionStatus = ""
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionStatus = "granted"
            startRecording()
        case .denied:
            permissionStatus = "denied"
            startRecording()
        case .undetermined:
            permissionStatus = "undetermined"
            requestMicrophonePermission()
        @unknown default:
            break
        }

        Analytics.logEvent("start_recording", parameters: [
            "microphone_permission_status": permissionStatus
        ])
    }

    private func requestMicrophonePermission() {
        player?.pause()
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            self.player?.play()
            if !granted {
                self.displayMicrophonePermissionRequestMessage()
            }
        }
    }

    private func startRecording() {
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(ArViewController.updateProgress), userInfo: nil, repeats: true)
        do {
            try self.sceneView.startVideoRecording()
        } catch {
            Bugsnag.notifyError(error)
            DispatchQueue.main.async {
                let message = NSLocalizedString("Please try again.", comment: "")
                self.statusViewController.showMessage(message)
            }
        }
    }

    private func displayMicrophonePermissionRequestMessage() {
        let message = NSLocalizedString("Your microphone is disabled. Enable it in Settings.", comment: "")
        statusViewController.showMessage(message)

        Analytics.logEvent("status_message_viewed", parameters: [
            "type": "microphone_permission",
            "message": message,
        ])
    }

    @objc func updateProgress() {
        timeElapsed = timeElapsed + 0.02
        progress = progress + (CGFloat(0.02) / maxDuration)
        recordButton.setProgress(progress)

        if progress > 1 {
            stop()
        }
    }

    private func stopRecording(_ didEnterBackground: Bool) {
        Analytics.logEvent("stop_recording", parameters: [
            "didEnterBackground": didEnterBackground
        ])

        guard let progressTimer = progressTimer else {
            return
        }

        progressTimer.invalidate()

        if self.timeElapsed < 1 && !didEnterBackground {
            DispatchQueue.main.async {
                let message = NSLocalizedString("Press the button longer to record", comment: "")
                self.statusViewController.showMessage(message)
            }
            self.sceneView.cancelVideoRecording()
        } else if !didEnterBackground {
            self.sceneView.finishVideoRecording { (videoRecording) in
              /* Process the captured video. Main thread. */
                let controller = VideoPreviewController(videoURL: videoRecording.url)
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true)
            }
        }

        self.timeElapsed = 0
        self.progress = 0
        recordButton.buttonState = .idle
    }

    @objc func stop() {
        stopRecording(false)
    }

    private func setupRecordButton() {
        recordButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        recordButton.buttonColor = .white
        recordButton.progressColor = .red
        recordButton.closeWhenFinished = false
        recordButton.addTarget(self, action: #selector(ArViewController.record), for: .touchDown)
        recordButton.addTarget(self, action: #selector(ArViewController.stop), for: .touchUpInside)
        recordButton.center.x = self.view.center.x
        recordButton.center.y = self.view.bounds.maxY - 85
        self.view.addSubview(recordButton)
    }

    private func setupAttachmentCollectionView() {
        let attachmentCollectionViewLayout = UICollectionViewFlowLayout()
        attachmentCollectionViewLayout.scrollDirection = .horizontal
        
        attachmentCollectionViewController = AttachmentCollectionViewController(collectionViewLayout: attachmentCollectionViewLayout)
        attachmentCollectionViewController.view.isOpaque = false
    }


    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func appEnterToBackground() {
        stopRecording(true)
    }

    @objc func appEnterForeground() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if status == AVAuthorizationStatus.denied {
            requestVideoPermission()
        }
    }

    func resetVideoPlayer() {
        self.player?.pause()
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil
    }

    private func createVideoNode(width: CGFloat, height: CGFloat, material: SCNMaterial, position: SCNVector3) -> SCNNode {
        let videoPlaneGeometry = SCNPlane(width: width, height: height)
        let videoPlaneNode = SCNNode(geometry: videoPlaneGeometry)
        videoPlaneNode.eulerAngles.x = -.pi / 2
        videoPlaneNode.position = position
        videoPlaneNode.geometry?.firstMaterial = material

        videoPlaneNode.opacity = 0.25
        videoPlaneNode.runAction(self.imageHighlightAction)

        return videoPlaneNode
    }


    private func createEffectNode(width: CGFloat, height: CGFloat, material: SCNMaterial, position: SCNVector3) -> SCNNode {
        let effectPlane = SCNPlane(width: width, height: height)
        let effectPlaneNode = SCNNode(geometry: effectPlane)
        effectPlaneNode.eulerAngles.x = -.pi / 2
        effectPlaneNode.position = position
        effectPlaneNode.geometry?.firstMaterial = material

        return effectPlaneNode
    }

    private func createAttachmentNode(width: CGFloat, height: CGFloat, material: SCNMaterial, position: SCNVector3) -> SCNNode {
        let attachmentPlaneGeometry = SCNPlane(width: width, height: height)
        let attachmentPlaneNode = SCNNode(geometry: attachmentPlaneGeometry)
        attachmentPlaneNode.eulerAngles.x = -.pi / 2
        attachmentPlaneNode.position = position
        attachmentPlaneNode.geometry?.firstMaterial = material

        attachmentPlaneNode.opacity = 0.25
        attachmentPlaneNode.runAction(self.imageHighlightAction)

        return attachmentPlaneNode
    }
}
