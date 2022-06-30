//
//  AttachmentView.swift
//  Truffle
//
//  Created by Ethan Chang on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct AttachmentViewConfig {
    let uiSize: TruffleSize
    let widthScaleToImageWidth: Float
    let position: TrufflePosition

    init(
        uiSize: TruffleSize,
        widthScaleToImageWidth: Float,
        position: TrufflePosition
    ) {
        self.uiSize = uiSize
        self.widthScaleToImageWidth = widthScaleToImageWidth
        self.position = position
    }

}
