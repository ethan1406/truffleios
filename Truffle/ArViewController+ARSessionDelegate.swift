/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Session status management for `ViewController`.
*/

import Bugsnag
import ARKit
import FirebaseAnalytics

extension ArViewController: ARSessionDelegate {
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            Analytics.logEvent("tracking", parameters: [
                "status": "unavailable"
            ])
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            Analytics.logEvent("tracking", parameters: [
                "status": "normal"
            ])
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        guard let arError = error as? ARError else { return }

        if arError.code == .cameraUnauthorized {
            requestVideoPermission()
        } else {
            Bugsnag.notifyError(error)

            let errorWithInfo = error as NSError
            let messages = [
                errorWithInfo.localizedDescription,
                errorWithInfo.localizedFailureReason,
                errorWithInfo.localizedRecoverySuggestion
            ]

            // Use `flatMap(_:)` to remove optional error messages.
            let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")

            DispatchQueue.main.async {
                let message = NSLocalizedString("Something went wrong.", comment: "")
                self.displayErrorMessage(title: message, message: errorMessage, shouldAddRestartAction: true)
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        resetVideoPlayer()

        blurView.isHidden = false
        let message = NSLocalizedString("Resetting Session", comment: "")
        statusViewController.showMessage(message, autoHide: false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        player?.pause()
        blurView.isHidden = true
        let message = NSLocalizedString("Resetting Session", comment: "")
        statusViewController.showMessage(message)
        
        restartExperience()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Error handling
    func displayErrorMessage(title: String, message: String, shouldAddRestartAction: Bool = false, shouldAddDismissAction: Bool = false) {

        let alertController = getAlertController(title: title, message: message, shouldAddRestartAction: shouldAddRestartAction, shouldAddDismissAction: shouldAddDismissAction)

        if presentedViewController == nil {
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }

            Analytics.logEvent("alert_dialog_viewed", parameters: [
                "type": "error",
                "title": title,
                "message": message
            ])
        }
    }

    func getAlertController(title: String, message: String, shouldAddRestartAction: Bool = false, shouldAddDismissAction: Bool = false) -> UIAlertController {
        // Blur the background.
        blurView.isHidden = false

        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if (shouldAddRestartAction) {
            let actionText = NSLocalizedString("Restart Session", comment: "")
            let restartAction = UIAlertAction(title: actionText, style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.blurView.isHidden = true
                self.resetTracking()

                Analytics.logEvent("alert_reset_button_tapped", parameters: [:])
            }
            alertController.addAction(restartAction)
        }

        if (shouldAddDismissAction) {
            let actionText = NSLocalizedString("Dismiss", comment: "")
            let dismissAction = UIAlertAction(title: actionText, style: .default) { _ in
                self.blurView.isHidden = true
                alertController.dismiss(animated: true, completion: nil)

                Analytics.logEvent("dismiss_button_tapped", parameters: [:])
            }
            alertController.addAction(dismissAction)
        }

        return alertController
    }

    // MARK: - Interface Actions
    
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        statusViewController.cancelAllScheduledMessages()
        
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }

    func requestVideoPermission() {
        if presentedViewController == nil {
            let message = NSLocalizedString("Oops!", comment: "")
            let description = NSLocalizedString("Truffle is a camera app! To continue, you'll need to allow Camera access in Settings", comment: "")
            let alertController = self.getAlertController(title: message, message: description)

            let actionText = NSLocalizedString("Enable access", comment: "")
            let enableAccessAction = UIAlertAction(title: actionText, style: .default) { _ in
                if let url = URL(string:UIApplication.openSettingsURLString) {
                    Analytics.logEvent("alert_camera_permission_button_tapped", parameters: [
                        "url": url
                    ])
                    UIApplication.shared.open(url)
                }
            }
            alertController.addAction(enableAccessAction)

            DispatchQueue.main.async {
                Analytics.logEvent("alert_dialog_viewed", parameters: [
                    "type": "camera_permission",
                    "title": message,
                    "message": description
                ])
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
