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

    private let spinner = UIActivityIndicatorView(style: .large)

    // record button
    private var recordButton : RecordButton!
    var progressTimer : Timer?
    var progress : CGFloat! = 0
    var timeElapsed = 0.0
    private let maxDuration = CGFloat(15) // Max duration of the recordButton


    // video dimensions
    private var attachmentViewHeight: CGFloat = 100
    private var attachmentViewWidth: CGFloat = 260

    // effect dimensions
    private var effectHeight: CGFloat = 200
    private var effectWidth: CGFloat = 200

    private let cardLogic = CardTransformationLogic(transformationService: CardTransformationService())

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

        addSubviews()

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }

        setupAttachmentCollectionView()

        FileManager.default.clearTmpVideos()
        setupObservers()

        NetworkMonitor.shared.startMonitoring()
    }

    private func addSubviews() {
        addLoadingSpinnerView()
    }

    private func addLoadingSpinnerView() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }


	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

        // Start the AR experience
        resetTracking()
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

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
        NetworkMonitor.shared.stopMonitoring()
    }

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        resetVideoPlayer()

        startLoading(true)
        let message = NSLocalizedString("Please place the card before the camera", comment: "")
        statusViewController.scheduleMessage(message, inSeconds: 7.5, messageType: .contentPlacement)

        session.run(ARImageTrackingConfiguration())


        if (NetworkMonitor.shared.isReachable) {
            Task.init {
                do {
                    let result = try await cardLogic.getCardImages()

                    switch result {
                    case .success(let images):
                        loadArReferenceImages(images)
                    case .failure(.genericError):
                        let title = NSLocalizedString("Something went wrong.", comment: "")
                        let message = NSLocalizedString("Please restart the app.", comment: "")

                        self.displayErrorMessage(title: title, message: message, shouldAddDismissAction: true)
                    }

                } catch {
                    Bugsnag.notifyError(error)
                }
                
                startLoading(false)
            }
        } else {
            let title = NSLocalizedString("Make you that you have internet access", comment: "")
            let message = NSLocalizedString("Please restart the app.", comment: "")

            self.displayErrorMessage(title: title, message: message, shouldAddDismissAction: true)
        }
	}

    private func loadArReferenceImages(_ images: [CardCGImage]) {
        let referenceImages = images.map { image -> ARReferenceImage in
            let referenceImage = ARReferenceImage(image.cgImage, orientation: .up, physicalWidth: CGFloat(image.physicalSize.width))
            referenceImage.name = String(image.imageId)
            return referenceImage
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

        configuration.trackingImages = Set(referenceImages)

        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage

        guard let referenceImageName = referenceImage.name,
              let imageId = Int(referenceImageName),
              let transformation = cardLogic.getCardTransformation(imageId: imageId)
        else { return }

        Analytics.logEvent("image_detected", parameters: [
            "type": "remote",
            "image_id": imageId
        ])

        // create materials
        let collectionViewMaterial = SCNMaterial()
        let videoMaterial = SCNMaterial()
        let effectMaterial = SCNMaterial()

        // create video player
        if (self.player == nil) {
            self.player = createVideoPlayer(transformation.cardVideo.videoUrl)
        }

        guard let avPlayer = player else {
            return
        }

        loopVideo()

        configureSideViews(effectViewSize: transformation.animationEffectConfig.size, attachmentViewSize: transformation.attachmentViewConfig.uiSize)

        DispatchQueue.main.async { [self] in
            showDetectionMessage(imageName: transformation.cardImage.imageName)

            // set material to custom views
            self.attachmentCollectionViewController.view.frame.size.height = self.attachmentViewHeight
            self.attachmentCollectionViewController.view.frame.size.width = self.attachmentViewWidth

            collectionViewMaterial.diffuse.contents = self.attachmentCollectionViewController.view
            videoMaterial.diffuse.contents = avPlayer

            // create effect view
            effectMaterial.diffuse.contents = generateEffectView(
                transformation.animationEffectConfig,
                imageWidth: referenceImage.physicalSize.width,
                imageHeight: referenceImage.physicalSize.height
            )
            loadAttachmentLinks(transformation.attachments)
        }

        updateQueue.async { [self] in

            node.addChildNode(createVideoNode(imageWidth: referenceImage.physicalSize.width, imageHeight: referenceImage.physicalSize.height, material: videoMaterial, cardVideo: transformation.cardVideo))

            Analytics.logEvent("video_viewed", parameters: [
                "type": "remote",
                "url": transformation.cardVideo.videoUrl
            ])

            node.addChildNode(createAttachmentNode(imageWidth: referenceImage.physicalSize.width, imageHeight : referenceImage.physicalSize.height, material: collectionViewMaterial, config: transformation.attachmentViewConfig))

            Analytics.logEvent("attachment_links_viewed", parameters: [
                "type": "remote",
                "count": self.attachmentCollectionViewController.attachments.count
            ])


            node.addChildNode(createEffectNode(imageWidth: referenceImage.physicalSize.width, imageHeight: referenceImage.physicalSize.height, material:  effectMaterial, config: transformation.animationEffectConfig))
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

    private func configureTransformation() {

    }

    private func generateEffectView(_ config: AnimationEffectConfig, imageWidth: CGFloat, imageHeight: CGFloat) -> EffectView {
        let effectView = EffectView(
            frame: CGRect(
                x: imageWidth * CGFloat(config.position.xScaleToImageWidth),
                y: imageHeight * CGFloat(config.position.zScaleToImageHeight),
                width: effectWidth,
                height: effectHeight
            )
        )
        effectView.startAnimation(config.lottieUrl)
        return effectView
    }

    private func showDetectionMessage(imageName: String) {
        self.statusViewController.cancelAllScheduledMessages()
        let message = String(format: NSLocalizedString("Detected %@", comment: ""), "\(imageName)")
        self.statusViewController.showMessage(message)
    }

    private func configureSideViews(effectViewSize: TruffleSize, attachmentViewSize: TruffleSize) {
        attachmentViewHeight = CGFloat(attachmentViewSize.height)
        attachmentViewWidth = CGFloat(attachmentViewSize.width)

        effectWidth = CGFloat(effectViewSize.width)
        effectHeight = CGFloat(effectViewSize.height)
    }

    private func loadAttachmentLinks(_ attachments: [Attachment]) {
        attachmentCollectionViewController.attachments = attachments
        attachmentCollectionViewController.reloadData()
    }

    private func createVideoPlayer(_ videoUrlString: String) -> AVPlayer? {
        //video node

        guard let videoUrl = URL.init(string: videoUrlString) else { return nil }

        let player = AVPlayer(url: videoUrl)
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
                "type": "remote"
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

    private func createVideoNode(imageWidth: CGFloat, imageHeight: CGFloat, material: SCNMaterial, cardVideo: CardVideo) -> SCNNode {
        let videoWidth = imageWidth * CGFloat(cardVideo.widthScaleToImageWidth)
        let videoHeight = videoWidth * CGFloat(cardVideo.videoHeightPx)/CGFloat(cardVideo.videoWidthPx)

        let videoPlaneGeometry = SCNPlane(width: videoWidth, height: videoHeight)
        let videoPlaneNode = SCNNode(geometry: videoPlaneGeometry)
        videoPlaneNode.eulerAngles.x = -.pi / 2
        videoPlaneNode.position = SCNVector3(
            x: Float(imageWidth) * cardVideo.position.xScaleToImageWidth,
            y: cardVideo.position.y,
            z: Float(imageHeight) * cardVideo.position.zScaleToImageHeight
        )
        videoPlaneNode.geometry?.firstMaterial = material

        videoPlaneNode.opacity = 0.25
        videoPlaneNode.runAction(self.imageHighlightAction)

        return videoPlaneNode
    }


    private func createEffectNode(imageWidth: CGFloat, imageHeight: CGFloat, material: SCNMaterial, config: AnimationEffectConfig) -> SCNNode {
        let effectPlane = SCNPlane(width: imageWidth, height: imageHeight)

        let effectPlaneNode = SCNNode(geometry: effectPlane)
        effectPlaneNode.eulerAngles.x = -.pi / 2
        effectPlaneNode.position = SCNVector3(
            x: Float(imageWidth) * config.position.xScaleToImageWidth,
            y: config.position.y,
            z: Float(imageHeight) * config.position.zScaleToImageHeight
        )
        effectPlaneNode.geometry?.firstMaterial = material


        return effectPlaneNode
    }

    private func createAttachmentNode(imageWidth: CGFloat, imageHeight: CGFloat, material: SCNMaterial, config: AttachmentViewConfig) -> SCNNode {
        let width = imageWidth * CGFloat(config.widthScaleToImageWidth)
        let height = imageWidth * 0.4
        let attachmentPlaneGeometry = SCNPlane(width: width, height: height)
        let attachmentPlaneNode = SCNNode(geometry: attachmentPlaneGeometry)
        attachmentPlaneNode.eulerAngles.x = -.pi / 2
        attachmentPlaneNode.position = SCNVector3(
            x: Float(imageWidth) * config.position.xScaleToImageWidth,
            y: config.position.y,
            z: Float(imageHeight) * config.position.zScaleToImageHeight
        )
        attachmentPlaneNode.geometry?.firstMaterial = material

        attachmentPlaneNode.opacity = 0.25
        attachmentPlaneNode.runAction(self.imageHighlightAction)

        return attachmentPlaneNode
    }

    private func startLoading(_ shouldEnable: Bool) {
        if (shouldEnable) {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }
}
