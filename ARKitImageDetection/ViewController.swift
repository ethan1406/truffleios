/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import AVFoundation
import SceneKit
import SpriteKit
import UIKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")


    private let attachmentCollectionViewLayout = UICollectionViewFlowLayout()

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

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }

        // initialize collection view controller
        attachmentCollectionViewLayout.scrollDirection = .horizontal
        attachmentCollectionViewController = AttachmentCollectionViewController(collectionViewLayout: attachmentCollectionViewLayout)
        attachmentCollectionViewController.view.isOpaque = false
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage

        // create material
        let collectionViewMaterial = SCNMaterial()
        let videoMaterial = SCNMaterial()

        // create video player
        self.player = createVideoPlayer()
        guard let avPlayer = player else {
            return
        }
        avPlayer.play()


        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")

            // set material to custom views

            self.attachmentCollectionViewController.view.frame.size.height = 100
            self.attachmentCollectionViewController.view.frame.size.width = 650

            collectionViewMaterial.diffuse.contents = self.attachmentCollectionViewController.view
            videoMaterial.diffuse.contents = avPlayer

        }


        // Create a plane to visualize the initial position of the detected image.
        let imageWidth = referenceImage.physicalSize.width
        let imageHeight = referenceImage.physicalSize.height
        let attachmentPlaneGeometry = SCNPlane(width: imageWidth * 1.5,
                                               height: imageWidth / 5)

        let attachmentPlaneNode = SCNNode(geometry: attachmentPlaneGeometry)

        updateQueue.async { [self] in
            // Add video to the scene
            let videoPlaneGeometry = SCNPlane(width: referenceImage.physicalSize.width * 2,
                                     height: referenceImage.physicalSize.width * 2 * 720/1280)


            let videoPlaneNode = SCNNode(geometry: videoPlaneGeometry)
            videoPlaneNode.geometry?.firstMaterial = videoMaterial

            videoPlaneNode.eulerAngles.x = -.pi / 2

            node.addChildNode(videoPlaneNode)



            attachmentPlaneNode.geometry?.firstMaterial = collectionViewMaterial
            attachmentPlaneNode.geometry?.firstMaterial?.fillMode = .fill

            //planeNode.opacity = 0.25

            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            attachmentPlaneNode.eulerAngles.x = -.pi / 2
            attachmentPlaneNode.position = SCNVector3(x: 0, y: 0.005, z: Float(imageHeight) * 0.75)

            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
            //planeNode.runAction(self.imageHighlightAction)

            // Add the plane visualization to the scene.
            node.addChildNode(attachmentPlaneNode)
        }
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)

        return player
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: .zero, completionHandler: nil)
        }
    }
}
