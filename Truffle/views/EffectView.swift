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

    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = false
        backgroundColor = UIColor.clear
        addAnimation()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    func addAnimation() {
        animationView.animation = Animation.named("starfall")
        animationView.contentMode = .scaleAspectFit

        animationView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(animationView)

        animationView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        animationView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true

        animationView.loopMode = .loop
        animationView.play()
    }
}
