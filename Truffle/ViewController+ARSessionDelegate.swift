/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Session status management for `ViewController`.
*/

import ARKit

extension ViewController: ARSessionDelegate {
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
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
    
    func sessionWasInterrupted(_ session: ARSession) {
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
    
    func displayErrorMessage(title: String, message: String, shouldAddRestartAction: Bool = false) {

        let alertController = getAlertController(title: title, message: message, shouldAddRestartAction: shouldAddRestartAction)

        present(alertController, animated: true, completion: nil)
    }

    func getAlertController(title: String, message: String, shouldAddRestartAction: Bool = false) -> UIAlertController {
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
            }
            alertController.addAction(restartAction)
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
    
}
