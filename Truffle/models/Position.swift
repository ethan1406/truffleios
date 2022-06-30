//
//  Position.swift
//  Truffle
//
//  Created by Ethan Chang on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct TrufflePosition {
    let xScaleToImageWidth: Float
    let y: Float
    let zScaleToImageHeight: Float

    init(
        xScaleToImageWidth: Float,
        y: Float,
        zScaleToImageHeight: Float
    ) {
        self.xScaleToImageWidth = xScaleToImageWidth
        self.y = y
        self.zScaleToImageHeight = zScaleToImageHeight
    }

}
