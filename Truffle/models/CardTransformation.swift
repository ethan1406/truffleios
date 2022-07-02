//
//  CardTransformation.swift
//  Truffle
//
//  Created by Ethan Chang on 6/29/22.
//  Copyright © 2022 Apple. All rights reserved.
//

struct CardTransformation {
    let transformationId: Int
    let attachments: [Attachment]
    let attachmentViewConfig: AttachmentViewConfig
    let animationEffectConfig: AnimationEffectConfig
    let cardImage: CardImage
    let cardVideo: CardVideo


    init(
        transformationId: Int,
        attachments: [Attachment],
        attachmentViewConfig: AttachmentViewConfig,
        animationEffectConfig: AnimationEffectConfig,
        cardImage: CardImage,
        cardVideo: CardVideo
    ) {
        self.transformationId = transformationId
        self.attachments = attachments
        self.attachmentViewConfig = attachmentViewConfig
        self.animationEffectConfig = animationEffectConfig
        self.cardImage = cardImage
        self.cardVideo = cardVideo
    }
}
