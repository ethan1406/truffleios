//
//  CardImage.swift
//  Truffle
//
//  Created by Ethan Chang on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import CoreGraphics

struct CardImage {
    let imageId: Int
    let imageUrl: String
    let imageName: String
    let physicalSize: TruffleSize


    init(
        imageId: Int,
        imageUrl: String,
        imageName: String,
        physicalSize: TruffleSize

    ) {
        self.imageId = imageId
        self.imageUrl = imageUrl
        self.imageName = imageName
        self.physicalSize = physicalSize
    }
}

struct CardCGImage {
    let imageId: Int
    let cgImage: CGImage
    let imageName: String
    let physicalSize: TruffleSize


    init(
        imageId: Int,
        cgImage: CGImage,
        imageName: String,
        physicalSize: TruffleSize

    ) {
        self.imageId = imageId
        self.cgImage = cgImage
        self.imageName = imageName
        self.physicalSize = physicalSize
    }
}
