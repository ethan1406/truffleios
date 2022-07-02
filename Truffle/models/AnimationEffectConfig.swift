//
//  AnimationViewConfig.swift
//  Truffle
//
//  Created by Ethan Chang on 7/2/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct AnimationEffectConfig {

    let lottieUrl: String
    let size: TruffleSize
    let position: TrufflePosition

    init(
        lottieUrl: String,
        size: TruffleSize,
        position: TrufflePosition
    ) {
        self.lottieUrl = lottieUrl
        self.size = size
        self.position = position
    }

}
