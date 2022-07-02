//
//  EffectView.swift
//  Truffle
//
//  Created by Ethan Chang on 5/21/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Lottie


class EffectView: UIView {

    var animationView = AnimationView()


    let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + "animationEffectQueue")

    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = false
        backgroundColor = UIColor.clear
        setupAnimationView()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    private func setupAnimationView() {
        self.animationView.contentMode = .scaleAspectFit

        self.animationView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.animationView)

        self.animationView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        self.animationView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }

    func startAnimation(_ lottieUrlString: String) {
        guard let lottieUrl = URL.init(string: lottieUrlString) else { return }

        queue.async { [self] in
            Animation.loadedFrom(url: lottieUrl, closure: { animation in
                DispatchQueue.main.async { [self] in
                    self.animationView.animation = animation

                    self.animationView.play { (finished) in
                        self.isHidden = true
                    }
                }

            }, animationCache: nil)
        }
    }
}
