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

    init(
        transformationId: Int,
        attachments: [Attachment],
        attachmentViewConfig: AttachmentViewConfig
    ) {
        self.transformationId = transformationId
        self.attachments = attachments
        self.attachmentViewConfig = attachmentViewConfig
    }
}
