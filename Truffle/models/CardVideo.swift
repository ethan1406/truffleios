//
//  CardVideo.swift
//  Truffle
//
//  Created by Ethan Chang on 7/2/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct CardVideo {

    let videoUrl: String
    let widthScaleToImageWidth: Float
    let videoWidthPx: Int
    let videoHeightPx: Int
    let position: TrufflePosition

    init (
        videoUrl: String,
        widthScaleToImageWidth: Float,
        videoWidthPx: Int,
        videoHeightPx: Int,
        position: TrufflePosition
    ) {
        self.videoUrl = videoUrl
        self.widthScaleToImageWidth = widthScaleToImageWidth
        self.videoWidthPx = videoWidthPx
        self.videoHeightPx = videoHeightPx
        self.position = position
    }
}
