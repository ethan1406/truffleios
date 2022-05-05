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
    
    let clickableElement = ArButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    var playerLooper: AVPlayerLooper?
    var queuePlayer: AVQueuePlayer?
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        clickableElement.tag = 1
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
        
        updateQueue.async { [self] in
            
            let material = SCNMaterial()
            
            //video node
            guard let path = Bundle.main.path(forResource: "wedding_card", ofType:"mp4") else {
                debugPrint("wedding_card not found")
                return
            }
            let url = NSURL(fileURLWithPath: path)

            let asset = AVURLAsset(url: url as URL, options: nil)
            let playerItem = AVPlayerItem(asset: asset)
            self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
            guard let player = self.queuePlayer else { return }
            self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
            player.play()
        
            //let player = AVPlayer(url: URL(fileURLWithPath: path))
            let videoNode = SKVideoNode(avPlayer: player)
            
            // Sprit
            let planeGeometry = SCNPlane(width: referenceImage.physicalSize.width * 1.5,
                                     height: referenceImage.physicalSize.width * 1.5 * 720/1280)
            
            let spritescene = SKScene(size: CGSize(width: 1280, height: 720))
            videoNode.size.width = spritescene.size.width
            videoNode.size.height = spritescene.size.height
            videoNode.anchorPoint = CGPoint(x:0, y: 1)
            //videoNode.zRotation = CGFloat(Double.pi)
            videoNode.yScale = -1
            
            spritescene.addChild(videoNode)
        
            //4. Add The Clickable View As A Materil
            material.diffuse.contents = spritescene
            
            let planeNode2 = SCNNode(geometry: planeGeometry)
            planeNode2.geometry?.firstMaterial = material

            planeNode2.eulerAngles.x = -.pi / 2

            //6. Add It To The Scene
            node.addChildNode(planeNode2)
            
            
            
            
            
//            // Create a plane to visualize the initial position of the detected image.
//            let plane = SCNPlane(width: referenceImage.physicalSize.width,
//                                 height: referenceImage.physicalSize.height)
//            let planeNode = SCNNode(geometry: plane)
//            planeNode.opacity = 0.25
//
//            /*
//             `SCNPlane` is vertically oriented in its local coordinate space, but
//             `ARImageAnchor` assumes the image is horizontal in its local space, so
//             rotate the plane to match.
//             */
//            planeNode.eulerAngles.x = -.pi / 2
//
//            /*
//             Image anchors are not tracked after initial detection, so create an
//             animation that limits the duration for which the plane visualization appears.
//             */
//            planeNode.runAction(self.imageHighlightAction)
//
//            // Add the plane visualization to the scene.
//            //node.addChildNode(planeNode)
        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
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
}
